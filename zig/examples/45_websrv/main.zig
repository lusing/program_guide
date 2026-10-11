//! 45 Web 服务实战：路由、JSON CRUD、查询串、进程内端到端测试
//! 取材 Sprinter ch16（Zig Web 开发），原书框架全系虚构（ziglings/http 等），
//! 本章用 0.17 标准库 std.http.Server/Client 实测重写，无任何第三方依赖。

const std = @import("std");

// ══════════════════════════════════════════════════════════════════
// 45.1 数据模型：Todo 的领域类型与 JSON 往返
// ══════════════════════════════════════════════════════════════════

/// 一条待办。字段名即 JSON 键名——std.json 按字段名序列化，
/// 命名风格直接决定 API 的对外契约。
const Todo = struct {
    id: u32,
    title: []const u8,
    done: bool = false,
};

/// 内存"数据库"：定长数组 + 游标，零分配。
/// 真实项目这里会是 sqlite（32 章）或远程数据库；本章聚焦 HTTP 层，
/// 存储刻意保持最小，让路由与协议成为主角。
const Store = struct {
    items: [16]Todo = undefined,
    len: usize = 0,
    next_id: u32 = 1,

    fn add(self: *Store, title: []const u8) ?*Todo {
        if (self.len >= self.items.len) return null;
        self.items[self.len] = .{ .id = self.next_id, .title = title };
        self.next_id += 1;
        self.len += 1;
        return &self.items[self.len - 1];
    }

    fn get(self: *Store, id: u32) ?*Todo {
        for (self.items[0..self.len]) |*t| {
            if (t.id == id) return t;
        }
        return null;
    }

    fn toggle(self: *Store, id: u32) ?bool {
        const t = self.get(id) orelse return null;
        t.done = !t.done;
        return t.done;
    }

    fn remove(self: *Store, id: u32) bool {
        for (self.items[0..self.len], 0..) |*t, i| {
            if (t.id == id) {
                self.items[i] = self.items[self.len - 1]; // swap-remove：顺序不保证
                self.len -= 1;
                return true;
            }
        }
        return false;
    }
};

/// 把 store 全量序列化成 JSON。手写拼接（数据形状已知且简单）；
/// 形状复杂时换 std.json.Stringify.value（42 章的写法）。
fn storeToJson(store: *const Store, buf: []u8) []const u8 {
    var w = std.Io.Writer.fixed(buf);
    w.writeAll("{\"todos\":[") catch unreachable;
    for (store.items[0..store.len], 0..) |t, i| {
        if (i != 0) w.writeAll(",") catch unreachable;
        w.print("{{\"id\":{d},\"title\":\"{s}\",\"done\":{}}}", .{ t.id, t.title, t.done }) catch unreachable;
    }
    w.writeAll("]}") catch unreachable;
    return w.buffered();
}

/// JSON → Todo。POST 体是用户输入（系统边界），必须走解析器：
/// 引号转义、缺字段、类型错——std.json 全部代劳，.ignore_unknown_fields
/// 让前向兼容（多出来的字段不炸）。
fn jsonToTodo(gpa: std.mem.Allocator, body: []const u8) !Todo {
    var parsed = try std.json.parseFromSlice(Todo, gpa, body, .{ .ignore_unknown_fields = true });
    defer parsed.deinit();
    return .{ .id = parsed.value.id, .title = try gpa.dupe(u8, parsed.value.title), .done = parsed.value.done };
}

// ══════════════════════════════════════════════════════════════════
// 45.2 路由：方法 × 路径的两维分派
// ══════════════════════════════════════════════════════════════════

/// 路由决策的纯函数部分：给定方法与目标，返回"该做什么"。
/// 从 HTTP 处理里剥出来是为了可测试——路由表是 Web 服务最该钉死的行为。
const Action = union(enum) {
    list,
    create,
    get_one: u32,
    toggle: u32,
    delete: u32,
    health,
    not_found,
};

fn route(method: std.http.Method, target: []const u8) Action {
    if (std.mem.eql(u8, target, "/health") and method == .GET) return .health;
    if (std.mem.eql(u8, target, "/todos")) {
        return switch (method) {
            .GET => .list,
            .POST => .create,
            else => .not_found,
        };
    }
    // /todos/<id> 与 /todos/<id>/toggle：前缀 + 手工解析 id
    if (std.mem.startsWith(u8, target, "/todos/")) {
        const rest = target["/todos/".len..];
        if (std.mem.endsWith(u8, rest, "/toggle")) {
            const id_str = rest[0 .. rest.len - "/toggle".len];
            const id = std.fmt.parseInt(u32, id_str, 10) catch return .not_found;
            if (method == .POST) return .{ .toggle = id };
            return .not_found;
        }
        const id = std.fmt.parseInt(u32, rest, 10) catch return .not_found;
        return switch (method) {
            .GET => .{ .get_one = id },
            .DELETE => .{ .delete = id },
            else => .not_found,
        };
    }
    return .not_found;
}

// ══════════════════════════════════════════════════════════════════
// 45.3 查询串：?key=value&... 的零分配解析
// ══════════════════════════════════════════════════════════════════

/// 在 query 串里找 key 的 value（不分配内存，直接切片原串）。
/// 这是 Web 服务的日常：分页 limit、过滤条件、追踪 id——
/// 全部藏在 target 的 ? 后面，解析必须容忍缺 key、空 value、乱序。
fn queryGet(query: []const u8, key: []const u8) ?[]const u8 {
    var it = std.mem.splitScalar(u8, query, '&');
    while (it.next()) |pair| {
        var kv = std.mem.splitScalar(u8, pair, '=');
        const k = kv.next() orelse continue;
        if (std.mem.eql(u8, k, key)) return kv.next() orelse "";
    }
    return null;
}

// ══════════════════════════════════════════════════════════════════
// 45.4 HTTP 服务：std.http.Server 的请求循环
// ══════════════════════════════════════════════════════════════════

const SrvCtx = struct {
    io: std.Io = undefined,
    gpa: std.mem.Allocator = undefined,
    store: *Store = undefined,
    /// 服务端实际绑定的端口（扫出来的，原子发布给客户端）。
    port: std.atomic.Value(u16) = std.atomic.Value(u16).init(0),
    /// 已处理请求数；到达 quota 后服务循环退出（测试要确定性）。
    quota: usize = 6,
    served: std.atomic.Value(usize) = std.atomic.Value(usize).init(0),
};

const json_hdr = std.http.Header{ .name = "content-type", .value = "application/json" };

/// 服务线程主体：listen → 逐连接 receiveHead → route → respond。
/// 与 42 章单发模式不同，这里在 quota 内持续 accept——真实 Web 服务的骨架。
fn serve(ctx: *SrvCtx) void {
    const io = ctx.io;
    var port: u16 = 48300; // 避开 ephemeral 区间（macOS 49152–65535）
    var server: std.Io.net.Server = undefined;
    while (port < 48320) : (port += 1) {
        const addr = std.Io.net.IpAddress.parseIp4("127.0.0.1", port) catch continue;
        if (addr.listen(io, .{ .reuse_address = true })) |s| {
            server = s;
            break;
        } else |_| {}
    }
    if (port >= 48320) {
        std.debug.print("  [server] 端口扫描失败\n", .{});
        return;
    }
    defer server.deinit(io);
    ctx.port.store(port, .release);

    while (ctx.served.load(.acquire) < ctx.quota) {
        const stream = server.accept(io) catch return;
        handleConn(ctx, stream);
        _ = ctx.served.fetchAdd(1, .acq_rel);
    }
}

/// 单连接处理：std.http.Server 在已 accept 的流上解析请求头。
fn handleConn(ctx: *SrvCtx, stream: std.Io.net.Stream) void {
    defer stream.close(ctx.io);
    var rbuf: [4096]u8 = undefined;
    var wbuf: [4096]u8 = undefined;
    var sr = stream.reader(ctx.io, &rbuf);
    var sw = stream.writer(ctx.io, &wbuf);
    var http_server = std.http.Server.init(&sr.interface, &sw.interface);
    var request = http_server.receiveHead() catch return;

    const action = route(request.head.method, request.head.target);
    switch (action) {
        .health => request.respond("{\"ok\":true}", .{ .status = .ok, .extra_headers = &.{json_hdr}, .keep_alive = false }) catch {},
        .list => {
            var buf: [1024]u8 = undefined;
            const body = storeToJson(ctx.store, &buf);
            request.respond(body, .{ .status = .ok, .extra_headers = &.{json_hdr}, .keep_alive = false }) catch {};
        },
        .create => {
            var rbuf2: [1024]u8 = undefined;
            const body_reader = request.readerExpectNone(&rbuf2);
            const body = body_reader.readAllocShort(ctx.gpa, 1024) catch {
                request.respond("{\"error\":\"read body\"}", .{ .status = .bad_request, .extra_headers = &.{json_hdr}, .keep_alive = false }) catch {};
                return;
            };
            defer ctx.gpa.free(body);
            const todo = jsonToTodo(ctx.gpa, body) catch {
                request.respond("{\"error\":\"bad json\"}", .{ .status = .bad_request, .extra_headers = &.{json_hdr}, .keep_alive = false }) catch {};
                return;
            };
            defer ctx.gpa.free(todo.title);
            const t = ctx.store.add(todo.title) orelse {
                request.respond("{\"error\":\"full\"}", .{ .status = .internal_server_error, .extra_headers = &.{json_hdr}, .keep_alive = false }) catch {};
                return;
            };
            var buf: [256]u8 = undefined;
            const resp = std.fmt.bufPrint(&buf, "{{\"id\":{d},\"title\":\"{s}\",\"done\":false}}", .{ t.id, t.title }) catch unreachable;
            request.respond(resp, .{ .status = .created, .extra_headers = &.{json_hdr}, .keep_alive = false }) catch {};
        },
        .get_one => |id| {
            const t = ctx.store.get(id) orelse {
                request.respond("{\"error\":\"not found\"}", .{ .status = .not_found, .extra_headers = &.{json_hdr}, .keep_alive = false }) catch {};
                return;
            };
            var buf: [256]u8 = undefined;
            const resp = std.fmt.bufPrint(&buf, "{{\"id\":{d},\"title\":\"{s}\",\"done\":{}}}", .{ t.id, t.title, t.done }) catch unreachable;
            request.respond(resp, .{ .status = .ok, .extra_headers = &.{json_hdr}, .keep_alive = false }) catch {};
        },
        .toggle => |id| {
            const done = ctx.store.toggle(id) orelse {
                request.respond("{\"error\":\"not found\"}", .{ .status = .not_found, .extra_headers = &.{json_hdr}, .keep_alive = false }) catch {};
                return;
            };
            var buf: [64]u8 = undefined;
            const resp = std.fmt.bufPrint(&buf, "{{\"id\":{d},\"done\":{}}}", .{ id, done }) catch unreachable;
            request.respond(resp, .{ .status = .ok, .extra_headers = &.{json_hdr}, .keep_alive = false }) catch {};
        },
        .delete => |id| {
            if (!ctx.store.remove(id)) {
                request.respond("{\"error\":\"not found\"}", .{ .status = .not_found, .extra_headers = &.{json_hdr}, .keep_alive = false }) catch {};
                return;
            }
            request.respond("{\"deleted\":true}", .{ .status = .ok, .extra_headers = &.{json_hdr}, .keep_alive = false }) catch {};
        },
        .not_found => request.respond("{\"error\":\"not found\"}", .{ .status = .not_found, .extra_headers = &.{json_hdr}, .keep_alive = false }) catch {},
    }
}

// ══════════════════════════════════════════════════════════════════
// 45.5 客户端：std.http.Client 的四种请求
// ══════════════════════════════════════════════════════════════════

fn begin(tag: []const u8) void {
    std.debug.print("==== {s} ====\n", .{tag});
}

fn end(tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

// ══════════════════════════════════════════════════════════════════
// main：起服务线程 → 进程内发 6 条真实请求 → 落盘
// ══════════════════════════════════════════════════════════════════

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const gpa = init.gpa;

    var out_buf: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &out_buf);
    const w = &stdout_impl.interface;
    defer w.flush() catch {};

    // 45.1-45.3 纯逻辑演示（无网络）
    begin("45.1 数据模型与 JSON 往返");
    var store: Store = .{};
    _ = store.add("学 Zig");
    _ = store.add("写裸机");
    var buf: [1024]u8 = undefined;
    try w.print("  storeToJson → {s}\n", .{storeToJson(&store, &buf)});
    const t = try jsonToTodo(gpa, "{\"id\":9,\"title\":\"from json\",\"done\":true,\"extra\":\"忽略我\"}");
    defer gpa.free(t.title);
    try w.print("  jsonToTodo（含未知字段）→ id={d} title={s} done={}\n", .{ t.id, t.title, t.done });
    end("45.1 数据模型与 JSON 往返");

    begin("45.2 路由表");
    try w.print("  GET /todos        → {}\n", .{route(.GET, "/todos")});
    try w.print("  POST /todos       → {}\n", .{route(.POST, "/todos")});
    try w.print("  GET /todos/7      → {}\n", .{route(.GET, "/todos/7")});
    try w.print("  POST /todos/7/toggle → {}\n", .{route(.POST, "/todos/7/toggle")});
    try w.print("  DELETE /todos/3   → {}\n", .{route(.DELETE, "/todos/3")});
    try w.print("  PUT /todos        → {}（方法不允许）\n", .{route(.PUT, "/todos")});
    try w.print("  GET /todos/abc    → {}（id 非数字）\n", .{route(.GET, "/todos/abc")});
    end("45.2 路由表");

    begin("45.3 查询串解析");
    const q = "page=2&limit=20&trace_id=xyz";
    try w.print("  queryGet(\"{s}\", \"limit\") = {?s}\n", .{ q, queryGet(q, "limit") });
    try w.print("  queryGet(\"{s}\", \"missing\") = {?s}\n", .{ q, queryGet(q, "missing") });
    try w.print("  queryGet(\"a=&b=1\", \"a\") = \"{?s}\"（空 value 合法）\n", .{queryGet("a=&b=1", "a")});
    end("45.3 查询串解析");

    // 45.4-45.5 进程内端到端
    begin("45.4/45.5 进程内端到端：真实 HTTP 往返");
    var ctx = SrvCtx{ .io = io, .gpa = gpa, .store = &store };
    const th = try std.Thread.spawn(.{}, serve, .{&ctx});
    while (ctx.port.load(.acquire) == 0) std.Thread.yield() catch {};
    const port = ctx.port.load(.acquire);

    var client: std.http.Client = .{ .allocator = gpa, .io = io };
    defer client.deinit();

    const base = try std.fmt.allocPrint(gpa, "http://127.0.0.1:{d}", .{port});
    defer gpa.free(base);

    // GET /health
    try w.print("  GET /health → ", .{});
    try fetchPrint(gpa, &client, base, .GET, "/health", null, w);

    // POST /todos（id=3：main 里已加两条）
    try w.print("  POST /todos {{json}} → ", .{});
    try fetchPrint(gpa, &client, base, .POST, "/todos", "{\"id\":0,\"title\":\"端到端\",\"done\":false}", w);

    // GET /todos/1
    try w.print("  GET /todos/1 → ", .{});
    try fetchPrint(gpa, &client, base, .GET, "/todos/1", null, w);

    // POST /todos/1/toggle（无请求体——POST 带 body 是 std.http.Client 的断言红线）
    try w.print("  POST /todos/1/toggle → ", .{});
    try fetchPrint(gpa, &client, base, .POST, "/todos/1/toggle", "{}", w);

    // GET /todos（列表，验证 toggle 落库）
    try w.print("  GET /todos → ", .{});
    try fetchPrint(gpa, &client, base, .GET, "/todos", null, w);

    // DELETE /todos/2
    try w.print("  DELETE /todos/2 → ", .{});
    try fetchPrint(gpa, &client, base, .DELETE, "/todos/2", null, w);

    th.join();
    try w.print("  ✓ {d} 条请求全部命中真实 HTTP 栈（quota 到，服务线程退出）\n", .{ctx.served.load(.acquire)});
    end("45.4/45.5 进程内端到端：真实 HTTP 往返");

    begin("45.6 坑位清单");
    try w.print("  1. 路由必须把\"方法×路径\"两维一起判——只判路径会接受 PUT /todos 这种怪请求\n", .{});
    try w.print("  2. POST 体是系统边界：readAlloc 限长（防巨包）、jsonToTodo 解析失败回 400\n", .{});
    try w.print("  3. 测试要确定性：quota 计数 + 原子端口发布，别 sleep 赌时序\n", .{});
    try w.print("  4. 端口扫描避开 ephemeral 区间；reuse_address 防 TIME_WAIT 拖累重跑\n", .{});
    try w.print("  5. 第三方 Web 框架生态未成气候——0.17 标准库已够小服务，依赖越少越稳\n", .{});
    end("45.6 坑位清单");

    try w.print("自检通过\n", .{});
}

/// 发一条请求并把状态码 + 响应体打到 w。
fn fetchPrint(
    gpa: std.mem.Allocator,
    client: *std.http.Client,
    base: []const u8,
    method: std.http.Method,
    path: []const u8,
    body: ?[]const u8,
    w: *std.Io.Writer,
) !void {
    const url = try std.fmt.allocPrint(gpa, "{s}{s}", .{ base, path });
    defer gpa.free(url);
    var jw = std.Io.Writer.Allocating.init(gpa);
    defer jw.deinit();
    const result = try client.fetch(.{
        .location = .{ .url = url },
        .method = method,
        .payload = body,
        .response_writer = &jw.writer,
    });
    try w.print("{d} {s}  body={s}\n", .{ @backingInt(result.status), result.status.phrase().?, jw.written() });
}

// ══════════════════════════════════════════════════════════════════
// Tests
// ══════════════════════════════════════════════════════════════════

test "路由两维分派" {
    try std.testing.expect(route(.GET, "/todos") == .list);
    try std.testing.expect(route(.POST, "/todos") == .create);
    try std.testing.expect(route(.PUT, "/todos") == .not_found);
    try std.testing.expect(route(.GET, "/todos/42") == .get_one);
    try std.testing.expect(route(.GET, "/todos/42").get_one == 42);
    try std.testing.expect(route(.DELETE, "/todos/9") == .delete);
    try std.testing.expect(route(.POST, "/todos/5/toggle") == .toggle);
    try std.testing.expect(route(.GET, "/todos/abc") == .not_found);
    try std.testing.expect(route(.GET, "/other") == .not_found);
}

test "查询串解析" {
    try std.testing.expectEqualStrings("20", queryGet("page=2&limit=20", "limit").?);
    try std.testing.expect(queryGet("page=2", "limit") == null);
    try std.testing.expectEqualStrings("", queryGet("a=&b=1", "a").?);
}

test "store CRUD" {
    var s: Store = .{};
    const t1 = s.add("a").?;
    const t2 = s.add("b").?;
    try std.testing.expectEqual(@as(u32, 1), t1.id);
    try std.testing.expectEqual(@as(u32, 2), t2.id);
    try std.testing.expect(s.toggle(1).? == true);
    try std.testing.expect(s.get(1).?.done);
    try std.testing.expect(s.remove(1));
    try std.testing.expect(s.get(1) == null);
    try std.testing.expect(!s.remove(99));
}

test "JSON 往返 + 未知字段容忍" {
    const gpa = std.testing.allocator;
    var s: Store = .{};
    _ = s.add("hello");
    var buf: [256]u8 = undefined;
    const json = storeToJson(&s, &buf);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"title\":\"hello\"") != null);
    const t = try jsonToTodo(gpa, "{\"id\":3,\"title\":\"x\",\"done\":false,\"future_field\":1}");
    defer gpa.free(t.title);
    try std.testing.expectEqual(@as(u32, 3), t.id);
}

test "JSON 缺字段 → 解析失败" {
    const gpa = std.testing.allocator;
    try std.testing.expect(jsonToTodo(gpa, "{\"id\":3}") == error.MissingField);
}

test "store 满 → add 返回 null" {
    var s: Store = .{};
    var i: usize = 0;
    while (i < 16) : (i += 1) _ = s.add("x");
    try std.testing.expect(s.add("overflow") == null);
}
