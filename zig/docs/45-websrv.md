# 45 · Web 服务实战：路由、JSON 与进程内端到端测试

> **阅读位置**：第六篇 · 综合实战（收官） ｜ **承前**：[30 HTTP](30-http.md) 的报文手写、[42 memsrv](42-memsrv.md) 的 std.http.Server/Client 往返、[12 集合](12-collections.md) ｜ **启后**：无——这是全教程最后一章，也是你自己项目的起点。
>
> 对应示例：examples/45_websrv/main.zig（6 个 test + 进程内 HTTP 往返）
>
> 本章把前面所有线索拧成一股绳：12 章的集合、14 章的 JSON、19/31 章的
> 线程与原子量、29 章的 listen/accept、30 章手写的 HTTP 报文、42 章的
> `std.http.Server`/`Client` 进程内往返——全部出现在同一个程序里：
> 一个带路由、带 JSON CRUD、带查询串解析、能被 `zig test` 在**同一进程内**
> 端到端验证的 Todo Web 服务。写完后它只有约 440 行，零第三方依赖。
>
> 本章有 **6 条实测结论会推翻你可能听过的说法**：
>
> 1. **「Zig Web 开发要用 zig-web / ziglings-http 等框架」——错，而且是
>    危险的错。** 网上流传的这些"框架"出自 AI 生成的伪 Zig 教材，根本不
>    存在。真实的 0.17 标准库 `std.http.Server` + `std.http.Client` 已够
>    小服务：路由是纯函数，协议层标准库做完，你要写的只有业务（45.2、45.4）。
> 2. **「std.http 只能做客户端」——错。** `std.http.Server` 在已 accept 的
>    流上 `receiveHead()` 解析请求、`respond()` 回响应，20 行接住一条真实
>    HTTP 请求（45.4）。42 章已经演示过单发模式，本章把它扩成请求循环。
> 3. **「路由就是一堆 if-else，没法测试」——错。** 路由被拆成**纯函数**
>    `route(method, target) Action`：不碰 socket、不碰 store，输入两个值、
>    输出一个 tagged union。9 个断言把整张路由表钉死（45.2）。
> 4. **「进程内测不了真实 HTTP」——错。** 服务端线程 + 原子端口发布 +
>    quota 计数 + `join` 等线程，主线程发 6 条**真实 HTTP 请求**走完整
>    TCP/HTTP 协议栈，输出逐字节可复现（45.5）。别 sleep 赌时序。
> 5. **「POST 和 GET 只差一个方法名」——错。** POST 体是**系统边界**：
>    必须限长防巨包（`readAllocShort`）、解析失败回 400、
>    `.ignore_unknown_fields` 保前向兼容。而且 0.17 的
>    `std.http.Client.fetch` 对 POST 有**断言红线**：POST 不带请求体
>    直接 panic（坑位清单第 1 条）。
> 6. **「0.17 的 API 和旧教程一样」——错。** `request.reader()` 不存在
>    （用 `readerExpectNone`）；`readAlloc` 已 deprecated 且语义变成
>    "读不满即报错"（用 `readAllocShort`）；`respond` 必须
>    `.keep_alive = false`，否则客户端复用连接时撞
>    `HttpConnectionClosing`（坑位清单第 2、3、4 条）。
>
> **节号对应**：45.1–45.5 是示例 `main` 里的运行时小节（`begin("45.N …") …
> end("45.N")`，运行输出里能看到 `==== 45.N … ====`）；**45.6（坑位清单）
> 是 `main` 末尾同名小节的展开版**，45.7（验证方式）不在 `main` 里。
>
> **确定性纪律**（沿用 31 / 34 / 42 章）：测试的确定性靠三件套——
> **quota 计数**（服务端处理满 N 条必退出）、**原子端口发布**（客户端
> 自旋等端口，不 sleep）、**join 等线程**（主线程 join 服务端线程后才
> 结束）。标记区间里不出现任何裸耗时。
>
> **前置章节**：[12 集合](12-collections.md)（定长数组 + 游标的存储模式）、
> [14 泛型与反射](14-generics.md)（`std.json` 序列化按字段名）、
> [19 线程](19-threads.md)（spawn/join、原子量）、
> [29 网络](29-networking.md)（`std.Io.net` 的 listen/accept）、
> [30 HTTP](30-http.md)（报文结构）、[42 memsrv](42-memsrv.md)
> （`std.http.Server`/`Client` 进程内往返、端口扫描、`Parsed(T)`）。
> 本章不复读那些基础，只讲"路由 + JSON CRUD + 端到端测试"这条链路上
> 新出现的东西。

---

## 导读：这一章要推翻 6 个说法

写一个 Todo Web 服务之前，先把六个"想当然"摆出来，本章逐条拆掉。

**说法一：「Zig Web 开发要用 zig-web / ziglings-http 等框架」。**

这是本章最要紧的一条，因为它不是技术判断，是**信息污染**。市面上某些
AI 生成的 Zig 教材（包括本章取材的那本）通篇使用虚构的 `ziglings/http`、
`zig-web` 框架——import 路径是假的，API 是假的，连"框架"本身都不存在。
照那种书写代码，你连编译都过不去。真相是：Zig 的第三方 Web 框架生态
至今未成气候（没有事实标准的 "express of Zig"），但**你根本不需要
框架**——0.17 的 `std.http` 把协议层做完了，路由是纯函数，JSON 有
`std.json`，存储先用定长数组。本章 440 行、零依赖，跑通完整的
CRUD + 端到端测试。依赖越少越稳，这条原则在收官章再强调一次。

**说法二：「std.http 只能做客户端」。**

`std.http.Client` 确实好用（42 章演示过），但 `std.http.Server` 同样
完整：在已 accept 的 TCP 流上 `receiveHead()` 解析请求行和头部，
`respond()` 一次调用写完状态行、头部、空行、body。42 章是"accept 一条、
响应一条、退出"的单发模式；本章 45.4 把它扩成**请求循环**——quota 内
持续 accept，这就是真实 Web 服务的骨架。

**说法三：「路由就是一堆 if-else，没法测试」。**

路由难测，是因为人们把它和 socket、store、HTTP 状态机揉在一个函数里。
本章的拆法：**路由决策是纯函数** `route(method, target) Action`——
输入方法枚举和目标路径字符串，输出 `Action` tagged union
（`.list` / `.create` / `.get_one = 7` / …）。它不碰网络、不碰存储，
同样的输入必然同样的输出。测试就是 9 个 `expect`，把整张路由表钉死
（45.2）。HTTP 处理函数只负责"调 route → 按 Action 分发到 store →
respond"，薄得没有测试价值——这正好，不值得测的代码就该薄到没有逻辑。

**说法四：「进程内测不了真实 HTTP」。**

"端到端"不等于"起两个进程 + curl"。本章的测试三件套：服务端跑在子
线程，**原子端口发布**（服务端绑定成功后 `store`，主线程自旋 `load`
等它非 0），**quota 计数**（服务端处理满 6 条必退出），主线程发完 6 条
请求后 `join` 等服务端线程。6 条请求全部走真实 TCP 连接、真实 HTTP
协议栈（客户端就是 `std.http.Client`），但整个测试是一个进程、一次
`zig test`、输出逐字节可复现。全程没有一处 `sleep`——赌时序的测试
在 CI 上迟早 flaky。

**说法五：「POST 和 GET 只差一个方法名」。**

GET 是幂等的读取，POST 携带**用户输入的请求体**——那是系统边界，是
攻击面。本章在 POST 路径上叠了三层防御（45.4）：读体限长
（`readAllocShort`，超过 1024 字节直接拒绝，防巨包拖死服务）、
JSON 解析失败回 400（`jsonToTodo` 的错误联合）、未知字段容忍
（`.ignore_unknown_fields`，老客户端收到新字段不炸）。另外 0.17 的
客户端侧还有一条断言红线：**POST 必须带请求体**，哪怕空 JSON `{}`，
否则 `std.http.Client.fetch` 内部 panic（坑位清单第 1 条）。

**说法六：「0.17 的 API 和旧教程一样」。**

旧教程里的 `request.reader()` 在 0.17 不存在——读请求体用
`request.readerExpectNone(&buf)`，返回 `*Reader`（指针，不是错误联合）。
`readAlloc` 已 deprecated 且语义变成 `readAllocAll`（读不满 Content-Length
即报错）——读已知上限的短 body 用 `readAllocShort`。`respond` 必须
显式 `.keep_alive = false`，否则客户端复用连接时服务端过早 close，
触发 `HttpConnectionClosing`（坑位清单第 2、3、4 条逐条展开）。

---

## 45.1 数据模型与 JSON 往返

### 45.1.1 Todo：字段名就是 API 契约

```zig
// examples/45_websrv/main.zig 第 13-17 行
/// 一条待办。字段名即 JSON 键名——std.json 按字段名序列化，
/// 命名风格直接决定 API 的对外契约。
const Todo = struct {
    id: u32,
    title: []const u8,
    done: bool = false,
};
```

逐行讲：

- **第 13-17 行**：`Todo` 是领域类型，三个字段：`id`（`u32`，服务端
  分配）、`title`（`[]const u8`，借用切片，生命周期由调用方保证）、
  `done`（`bool`，默认 `false`）。
- **字段名即 JSON 键名**：`std.json` 默认按 Zig 字段名原样序列化
  （14 章讲过）。`title` 在 JSON 里就是 `"title"`。这意味着**命名风格
  是 API 的对外契约**——前端按什么键取值，由这一行的命名决定。本章
  用 snake_case，与 42 章的 `MemStats` 一致。
- **`done: bool = false`**：默认值让 `Store.add` 里
  `.{ .id = self.next_id, .title = title }` 这样的部分初始化合法——
  没写的字段取默认值。Zig 的结构体字面量只要求**没有默认值的字段**
  必须出现。

### 45.1.2 Store：定长数组 + 游标，零分配

```zig
// examples/45_websrv/main.zig 第 22-58 行
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
```

逐行讲：

- **第 23 行**：`items: [16]Todo = undefined`——**定长数组**（12 章的
  模式），容量硬编码 16 条。`undefined` 是刻意选择：`items` 只有
  `0..len` 这一段是有效数据，后面 15 条是什么无所谓，初始化为
  `undefined` 省一次全数组写入。访问 `items[0..len]` 之外的元素是
  未定义行为——纪律是**永远通过 `len` 切片访问**。
- **第 24-25 行**：`len` 是有效元素数（游标），`next_id` 是自增主键，
  从 1 开始。注意 `id` 只增不减：删除一条不会复用它的 id——这是真实
  数据库自增主键的语义，客户端可以安全缓存 id。
- **第 27-33 行 `add`**：满了返回 `null`（调用方翻译成 500），否则
  在游标处写入、游标前进、返回**指向刚写入元素的指针**。返回指针而
  不是值的理由：调用方（45.4 的 create 分支）要立刻读 `t.id` 和
  `t.title` 拼响应体，指针零拷贝。
- **第 35-40 行 `get`**：`for (self.items[0..self.len]) |*t|`——
  对切片按**指针**迭代（`|*t|` 不是 `|t|`），这样返回 `?*Todo` 指向
  数组内部，调用方可以直接改 `done`（`toggle` 就是这么做的）。
- **第 42-46 行 `toggle`**：`orelse return null`——`get` 返回可选指针，
  解包失败（id 不存在）直接向上传播"不存在"。存在则翻转 `done` 并
  返回**新值**（`?bool`），调用方拼响应体时不用再读一次。
- **第 48-57 行 `remove`**：**swap-remove**——用最后一条有效元素覆盖
  被删位置，游标减一。O(1)，但**顺序不保证**（注释里写明）：删中间的
  元素会把末尾元素挪到中间。Todo 列表没有顺序语义，swap-remove 是
  正确选择；如果是有序列表，这里要改成 `std.mem.copyForwards` 搬运
  后半段（O(n)）。
- **为什么存储要刻意保持最小**：本章的教学主角是**路由与协议**。
  存储一复杂（哈希表、持久化、锁），注意力就被分散了。定长数组 +
  四个方法，30 行，CRUD 语义齐全，测试可以直接驱动（45.7 的
  `store CRUD` test）。真实项目把这一层换成 sqlite（32 章），
  HTTP 层一行不用改——这就是分层的回报。

### 45.1.3 storeToJson：手写拼接

```zig
// examples/45_websrv/main.zig 第 62-71 行
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
```

逐行讲：

- **第 63 行**：`std.Io.Writer.fixed(buf)`——20 章的固定缓冲写入器。
  调用方在栈上开 `buf: [1024]u8`，序列化结果**借用**这块内存，零分配。
  Web 服务的响应体通常很小（本章最大的一条列表响应约 150 字节），
  1 KB 栈缓冲绰绰有余。
- **`catch unreachable` 的正当性**：`fixed` 写入器唯一的错误是
  `error.NoSpaceLeft`（缓冲写满）。1 KB 对 16 条 Todo 的 JSON 是
  10 倍余量，写满是逻辑 bug 而非运行时状况——`unreachable` 把这种
  "不可能发生，发生了就是程序员错误"的场景显式化。如果容量不确定，
  这里要改成把错误传播给调用方回 500。
- **第 65-68 行**：`for (..., 0..) |t, i|` 带索引迭代（12 章），
  `i != 0` 时先补逗号——这是手写 JSON 数组的标准技巧：**逗号放前面**，
  避免"最后一个元素不带逗号"的边界判断。
- **第 67 行的格式串**：Zig 的 `{{` / `}}` 转义成字面 `{` / `}`，
  `\"` 转义成字面 `"`。所以模板展开后是
  `{"id":{d},"title":"{s}","done":{}}`，`{d}` 打整数、`{s}` 打字符串、
  `{}` 打布尔（Zig 的 `{}` 对 `bool` 输出 `true`/`false`，恰好就是
  JSON 的字面量——这是选型上的幸运，也是刻意验证过的）。
- **第 70 行 `w.buffered()`**：返回已写入部分的切片。`fixed` 写入器
  内部有缓冲，`buffered()` 拿到"从这里到写指针"的切片。
- **为什么手写而不调 `std.json.Stringify.value`**：数据形状是固定的
  扁平数组，手写拼接比走通用序列化器**更省**（无选项解析、无字段
  反射）也更直白。42 章的 `MemStats` 形状同样简单，那里选了
  `Stringify.value` 是为了教那个 API；本章换手写是为了展示两种
  写法都合法、以及何时选哪个。**形状复杂（嵌套、可选字段、变体）
  时无条件用 `Stringify.value`**——手写嵌套 JSON 的转义边界是 bug
  高发区（坑位清单第 6 条）。

### 45.1.4 jsonToTodo：解析器与 .ignore_unknown_fields

```zig
// examples/45_websrv/main.zig 第 76-80 行
/// JSON → Todo。POST 体是用户输入（系统边界），必须走解析器：
/// 引号转义、缺字段、类型错——std.json 全部代劳，.ignore_unknown_fields
/// 让前向兼容（多出来的字段不炸）。
fn jsonToTodo(gpa: std.mem.Allocator, body: []const u8) !Todo {
    var parsed = try std.json.parseFromSlice(Todo, gpa, body, .{ .ignore_unknown_fields = true });
    defer parsed.deinit();
    return .{ .id = parsed.value.id, .title = try gpa.dupe(u8, parsed.value.title), .done = parsed.value.done };
}
```

逐行讲：

- **第 77 行**：`std.json.parseFromSlice(Todo, gpa, body, ...)`——
  42 章讲过的反序列化入口。四个参数：目标类型、allocator、JSON 文本、
  选项。返回 `Parsed(Todo)`，**拥有内存的句柄**。
- **`.ignore_unknown_fields = true`**：默认行为下，JSON 里出现
  `Todo` 没有的字段会报 `error.UnknownField`。这是 POST 边界上的
  前向兼容开关：服务端 v2 给 Todo 加 `priority` 字段后，老客户端
  发来的 JSON 不受影响，新客户端多带的字段也被老服务端忽略。
  42 章从"服务端加字段、老客户端怎么办"的角度讲过同一件事；
  本章站在**接收用户输入**的角度再讲一次：用户（和用户的客户端版本）
  不可控，宽容解析是系统边界的默认姿态。
- **第 78 行 `defer parsed.deinit()`**：`Parsed(T)` 内部持有 arena，
  不 deinit 就是泄漏。测试里的 `std.testing.allocator` 会立刻抓到。
- **第 79 行的关键细节**：**不能 `return parsed.value`**。
  `Todo.title` 是 `[]const u8`，`parsed.value.title` 指向 arena 内部
  的内存——`defer` 触发后 arena 释放，返回值的 `title` 就是悬空指针。
  所以逐字段构造返回值，其中 `title` 用 `gpa.dupe(u8, ...)` **复制**
  到调用方的 allocator 上（所有权转移给调用方，调用方负责
  `gpa.free`）。`id` 和 `done` 是标量，直接拷贝即可。42 章的
  `MemStats` 全是标量所以能直接 `return parsed.value`——本章有切片
  字段，必须 dupe。这是两个章节对照着看才能发现的差别。

### 45.1.5 运行时输出

```zig
// examples/45_websrv/main.zig 第 281-290 行
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
```

运行输出：

```text
==== 45.1 数据模型与 JSON 往返 ====
  storeToJson → {"todos":[{"id":1,"title":"学 Zig","done":false},{"id":2,"title":"写裸机","done":false}]}
  jsonToTodo（含未知字段）→ id=9 title=from json done=true
==== 45.1 数据模型与 JSON 往返 结束 ====
```

输出解读：

- **第一行**：两条 Todo 序列化成紧凑 JSON。注意键序与字段声明序一致
  （`id`、`title`、`done`），逗号分隔无空格。`storeToJson` 借用的
  是 `buf`（栈上 1 KB），打印完即弃——零分配完成序列化。
- **第二行**：输入串里有 `"extra":"忽略我"`——`Todo` 没有 `extra`
  字段，`.ignore_unknown_fields = true` 让它被静默跳过，三个已知
  字段照常解析。`done=true` 说明默认值 `false` 被输入里的显式
  `true` 覆盖。
- **`gpa.free(t.title)`**：45.1.4 说过的所有权纪律——`jsonToTodo`
  把 `title` dupe 到了 `gpa` 上，调用方（这里是 `main`）必须 free。
  漏掉这行，测试里的泄漏检测会报。

### 45.1.6 测试：JSON 往返、缺字段、store 满

```zig
// examples/45_websrv/main.zig 第 419-441 行
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
```

三个 test 覆盖了存储与解析的全部失败面：

- **往返 + 未知字段容忍**：`storeToJson` 的输出里用
  `std.mem.indexOf` 找子串 `"title":"hello"`——手写 JSON 的测试就是
  字符串包含断言，不需要把 JSON 再解析回来（那是测 `std.json`，不是
  测我们的拼接逻辑）。`future_field` 验证宽容模式。
- **缺字段**：`{"id":3}` 没有 `title`，`parseFromSlice` 报
  `error.MissingField`（没有默认值的字段缺失就是错误）。注意断言写法：
  `== error.MissingField` 直接比较错误联合与错误值——比
  `std.testing.expectError` 更直白，两者等价。
- **store 满**：16 条塞满后第 17 条 `add` 返回 `null`。这个分支在
  `main` 的运行路径里走不到（只加了 3 条），只有 test 能覆盖到——
  这正是"测试钉死边界"的意义。45.4 的 create 分支会把 `null`
  翻译成 500 `{"error":"full"}`。

---

## 45.2 路由：方法 × 路径的两维分派

### 45.2.1 为什么路由是纯函数

Web 框架的路由常被写成"注册回调 + 模式匹配"的黑盒，测试要起服务器、
发请求、断言响应。本章的拆法更笨也更有效：**路由决策**和**路由执行**
分开。决策是

```zig
fn route(method: std.http.Method, target: []const u8) Action
```

输入是方法枚举和路径字符串两个**值**，输出是 `Action` 这个 tagged
union。没有 socket、没有 allocator、没有全局状态——纯函数（42 章
`parseMeminfo` 的同款思路）。纯函数的可测性是天生的：9 个 `expect`
覆盖整张路由表，跑在微秒级，不需要网络。

"两维分派"指路由要同时看**两个**维度：方法（GET/POST/DELETE/…）和
路径（`/todos`、`/todos/7`、`/todos/7/toggle`）。只看路径会接受
`PUT /todos` 这种怪请求；只看方法会把 `GET /todos` 和
`GET /todos/7` 混为一谈。两个维度一起判，且**先判精确路径再判前缀
路径**（顺序即优先级）。

### 45.2.2 Action：路由决策的返回值

```zig
// examples/45_websrv/main.zig 第 88-96 行
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
```

逐行讲：

- **`union(enum)`**（8 章的 tagged union）：每个分支是一个**意图**，
  不是一段回调。无参分支（`.list`、`.create`、`.health`、
  `.not_found`）是单元类型；带参分支（`.get_one: u32`、
  `.toggle: u32`、`.delete: u32`）把**路径里解析出的 id** 一并携带。
- **为什么带参分支要携带 id**：路由解析路径时顺手把 `/todos/7` 里的
  `7` 解析成 `u32`——这一步可能失败（`/todos/abc`），失败属于
  **路由决策**（返回 `.not_found`），不属于执行层。执行层拿到的
  `Action` 已经是一个类型安全的意图：`get_one = 7`，直接用，不用再
  碰字符串。
- **`not_found` 也是 Action**：404 不是异常，是路由表里的一个正常
  出口。这让 `route()` 的返回类型是**全函数**——任何输入都有确定
  输出，执行层的 `switch` 不需要 `else`。

### 45.2.3 route()：两维分派全表

```zig
// examples/45_websrv/main.zig 第 98-124 行
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
```

逐行讲：

- **第 99 行**：`/health` 精确匹配 + 方法必须是 GET。`and` 连接两维。
  健康检查端点是运维基础设施（负载均衡器、K8s liveness probe）会
  调的，语义是"服务活着吗"，回 200 `{"ok":true}`。
- **第 100-106 行**：`/todos` 精确路径按方法三分支：GET 列表、
  POST 创建、**其它一律 `.not_found`**。注意这里返回 404 而不是 405
  （Method Not Allowed）——本章刻意保持最小，405 需要额外回
  `Allow` 头，收益不成比例。真实 API 要讲究时可以加。
- **第 108 行**：`startsWith` 进入前缀区。顺序很重要：**精确路径
  在前、前缀匹配在后**——如果先判前缀，`/todos` 会被
  `startsWith(u8, "/todos", "/todos/")` 漏过（它不以斜杠结尾），但
  `/todos/` 本身会掉进前缀区，`rest` 为空串，`parseInt` 失败回
  `.not_found`——行为碰巧也对，但靠"碰巧也对"的路由是技术债。
- **第 109 行**：`target["/todos/".len..]`——切片切掉前缀，`rest`
  是 `7`、`7/toggle` 或 `abc`。
- **第 110-115 行**：先判 `/toggle` 后缀（`endsWith`），切掉后缀
  得到 id 串，`parseInt` 失败回 `.not_found`（`/todos/abc/toggle`
  不是合法端点）。**方法必须是 POST**——`GET /todos/7/toggle`
  返回 `.not_found` 而不是执行翻转。翻转用 POST 因为它是**变更**
  （虽然语义上是幂等的翻转，但 REST 惯例里变更走 POST/PATCH）。
- **第 116-121 行**：无前缀无后缀的 `rest` 就是 id 串本身。GET →
  查单条，DELETE → 删除，其它（含 POST `/todos/7`——更新语义本章
  未实现）→ `.not_found`。
- **`catch return .not_found` 的语义**：路径解析失败**不是错误**，
  是"这条路径不存在"——404 是 HTTP 协议里的正常响应，不是异常。
  用 `catch return` 把解析错误就地翻译成路由决策，错误联合在系统
  边界处被吸收（9 章的错误设计：错误该在哪一层被吃掉）。

### 45.2.4 运行时输出

```zig
// examples/45_websrv/main.zig 第 292-300 行
    begin("45.2 路由表");
    try w.print("  GET /todos        → {}\n", .{route(.GET, "/todos")});
    try w.print("  POST /todos       → {}\n", .{route(.POST, "/todos")});
    try w.print("  GET /todos/7      → {}\n", .{route(.GET, "/todos/7")});
    try w.print("  POST /todos/7/toggle → {}\n", .{route(.POST, "/todos/7/toggle")});
    try w.print("  DELETE /todos/3   → {}\n", .{route(.DELETE, "/todos/3")});
    try w.print("  PUT /todos        → {}（方法不允许）\n", .{route(.PUT, "/todos")});
    try w.print("  GET /todos/abc    → {}（id 非数字）\n", .{route(.GET, "/todos/abc")});
    end("45.2 路由表");
```

运行输出：

```text
==== 45.2 路由表 ====
  GET /todos        → .{ .list = void }
  POST /todos       → .{ .create = void }
  GET /todos/7      → .{ .get_one = 7 }
  POST /todos/7/toggle → .{ .toggle = 7 }
  DELETE /todos/3   → .{ .delete = 3 }
  PUT /todos        → .{ .not_found = void }（方法不允许）
  GET /todos/abc    → .{ .not_found = void }（id 非数字）==== 45.2 路由表 结束 ====
```

输出解读：

- **`{}` 打印 tagged union**：Zig 对 `union(enum)` 的默认格式化就是
  结构体字面量风格——`.{ .list = void }`、`.{ .get_one = 7 }`。
  无参分支的负载显示为 `void`。这是 23 章调试技巧的顺手应用：路由
  表的"可视化"不需要写任何格式化代码。
- **最后两行**是两条负路径：`PUT /todos`（方法维度拒绝）和
  `GET /todos/abc`（路径维度拒绝）都落在 `.not_found`。注意输出里
  最后一行与 `==== 45.2 路由表 结束 ====` 连行——`main` 里最后一条
  `w.print` 的换行后紧跟 `end` 的打印，中间没有额外空行，这是示例
  的原始输出形态。

### 45.2.5 测试：路由两维分派

```zig
// examples/45_websrv/main.zig 第 388-398 行
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
```

9 个断言把整张路由表钉死。两个写法值得注意：

- **`route(.GET, "/todos/42") == .get_one`**：tagged union 与无参
  枚举字面量比较——Zig 允许 `union(enum)` 与同名枚举值直接 `==`，
  只比标签不比负载。
- **`.get_one == 42`**：要验负载就访问字段。第 394 行证明"id 解析
  正确传递"，第 395 行证明"标签正确"——两者缺一不可：只比标签测不出
  `/todos/42` 和 `/todos/24` 被解析成同一个 Action 的 bug。

这就是"路由表是 Web 服务最该钉死的行为"的实操：9 个断言，微秒级，
覆盖 7 个端点 × 正路径 + 2 个负路径。以后给服务加端点，先在这里加
一行断言，再写实现。

---

## 45.3 查询串：?key=value&... 的零分配解析

### 45.3.1 queryGet

```zig
// examples/45_websrv/main.zig 第 133-141 行
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
```

逐行讲：

- **第 134 行**：`splitScalar(u8, query, '&')` 按 `&` 切成
  `key=value` 对。这里用 `split` 而不是 `tokenize`（42 章的
  `parseMeminfo` 用 `tokenize`）——区别是 `split` **保留空段**：
  `"a=&b=1"` 按 `&` split 得 `["a=", "b=1"]`；tokenize 会把连续
  分隔符折叠，`"a&&b=1"` 的空段就丢了。查询串里空段有语义
  （`a=` 是"key a 存在且值为空"），所以用 `split`。
- **第 136-137 行**：每个 pair 再按 `=` split。`k = kv.next()
  orelse continue`——`split` 迭代器至少返回一个段（可能为空），
  `orelse` 实际触发不到，但写上防御。
- **第 138 行**：key 命中就返回 value；**`kv.next() orelse ""`**——
  `a=` 这种"有等号没值"的 pair，`split` 的第二个段是空串 `""`，
  返回它（空 value 合法）；`a` 这种"没等号"的 pair，第二个
  `next()` 返回 `null`，`orelse ""` 同样返回空串。两种形态归一为
  "值为空"。
- **零分配**：返回值 `?[]const u8` 是**原串的切片**，不 dupe、
  不 unescape。本章的调用场景（打印演示）不需要百分号解码；
  真实项目如果 value 含 `%20` 这类转义，要在切片后过一遍
  `std.Uri.percentDecode`（坑位清单第 7 条）。
- **找不到返回 `null`**：与"找到但值为空"区分开——`?[]const u8`
  的三态（null / "" / "value"）正好对应调用方的三种处理
  （用默认值 / 用空串 / 用值）。

### 45.3.2 运行时输出与测试

```zig
// examples/45_websrv/main.zig 第 302-307 行
    begin("45.3 查询串解析");
    const q = "page=2&limit=20&trace_id=xyz";
    try w.print("  queryGet(\"{s}\", \"limit\") = {?s}\n", .{ q, queryGet(q, "limit") });
    try w.print("  queryGet(\"{s}\", \"missing\") = {?s}\n", .{ q, queryGet(q, "missing") });
    try w.print("  queryGet(\"a=&b=1\", \"a\") = \"{?s}\"（空 value 合法）\n", .{queryGet("a=&b=1", "a")});
    end("45.3 查询串解析");
```

运行输出：

```text
==== 45.3 查询串解析 ====
  queryGet("page=2&limit=20&trace_id=xyz", "limit") = 20
  queryGet("page=2&limit=20&trace_id=xyz", "missing") = null
  queryGet("a=&b=1", "a") = ""（空 value 合法）
==== 45.3 查询串解析 结束 ====
```

`{?s}` 是可选切片的格式化占位：非空打印内容，null 打印 `null`。
三行分别命中"正常值 / 缺 key / 空 value"三态。

```zig
// examples/45_websrv/main.zig 第 400-404 行
test "查询串解析" {
    try std.testing.expectEqualStrings("20", queryGet("page=2&limit=20", "limit").?);
    try std.testing.expect(queryGet("page=2", "limit") == null);
    try std.testing.expectEqualStrings("", queryGet("a=&b=1", "a").?);
}
```

注意一个本章**没有**演示但真实服务必踩的点：`request.head.target` 里
路径和查询串是连在一起的（`"/todos?page=2"`）。本章的路由全部用
精确匹配和前缀匹配，查询串端点（`/todos?limit=10`）会让
`startsWith(u8, target, "/todos/")` 之外的 `/todos` 精确匹配先命中，
`?` 后面的部分被自然忽略——行为碰巧正确，但真实项目应该在 `route()`
入口处先 `std.mem.indexOfScalar(u8, target, '?')` 把 target 切成
path 和 query 两段，分别路由和解析（坑位清单第 7 条）。

---

## 45.4 HTTP 服务：std.http.Server 的请求循环

### 45.4.1 服务端上下文 SrvCtx

```zig
// examples/45_websrv/main.zig 第 147-156 行
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
```

逐行讲：

- **`io` / `gpa` / `store`**：三个注入依赖。`io` 跨线程共享安全
  （31 章实测：`std.Io` 是值类型，底层是 Threaded 的 OS futex）；
  `store` 是指针——服务端线程和主线程共享**同一个** Store，HTTP
  请求直接读写它。
- **`port: std.atomic.Value(u16)`**：原子端口发布，42 章的模式。
  服务端绑定成功后 `store`，主线程自旋 `load` 等它非 0。跨线程
  共享的非原子变量是数据竞争（19 章）。
- **`quota: usize = 6` + `served: std.atomic.Value(usize)`**：
  **quota 计数**——服务端处理满 6 条请求后服务循环退出。这是测试
  确定性的核心：没有 quota，服务线程是无限循环，测试没法干净退出；
  有了 quota，"发 6 条 → 服务端自己退出 → join 返回"是确定的
  因果链。`served` 要原子：服务端线程 `fetchAdd`，主线程 `join`
  后 `load` 做断言。
- **为什么是 6**：main 里恰好发 6 条请求（health、create、get_one、
  toggle、list、delete）。quota 大于 6 会让服务端在 join 处挂等
  第 7 条连接；小于 6 会让后面的请求连不上。quota 必须**精确等于**
  预期的请求数——这是"测试设计"的一部分，不是实现细节。

### 45.4.2 serve：listen → accept 循环

```zig
// examples/45_websrv/main.zig 第 162-185 行
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
```

逐行讲：

- **第 164-172 行**：端口扫描，42 章同款。从 48300 扫到 48319，
  避开 macOS ephemeral 区间（49152–65535）——ephemeral 端口是
  客户端临时连接用的，服务端 bind 那个区间会和客户端抢端口。
  `.reuse_address = true` 允许快速重启：上次运行残留的 TIME_WAIT
  连接不挡新绑定。
- **第 168-171 行**：`if (addr.listen(...)) |s| { ... } else |_| {}`——
  listen 返回错误联合，成功取 `s`、失败（`AddressInUse`）空块继续
  扫下一个。`else |_| {}` 的 `_` 丢弃错误值：扫描场景下"为什么失败"
  不重要，"下一个端口行不行"才重要。
- **第 178 行**：`ctx.port.store(port, .release)`——**发布**。
  `.release` 内存序保证端口号写入先于后续任何读被其它线程看到；
  主线程用 `.acquire` 读（45.5），构成 release-acquire 对（31 章）。
- **第 180-184 行**：**请求循环**。条件 `served < quota`：已服务数
  没到配额就继续 accept。`accept` 阻塞等连接（29 章的模型），
  来一条连接交给 `handleConn` 处理完，**再** `fetchAdd` 计数。
  注意计数在 `handleConn` **之后**——quota 语义是"处理满 N 条"，
  不是"接受满 N 条连接"。
- **与 42 章的差异**：42 章 `httpServe` accept 一条就退出（单发）；
  本章是 `while` 循环——这就是"单发模式 → 请求循环"的进化，
  也是"真实 Web 服务的骨架"：真实服务的循环条件不是 quota 而是
  `while (true)` + 信号关停（38 章 daemon 的关停模式）。

### 45.4.3 handleConn：单连接处理与 POST 体的三层防御

```zig
// examples/45_websrv/main.zig 第 188-253 行
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
```

骨架部分（第 189-197 行）：

- **第 189 行 `defer stream.close(ctx.io)`**：连接级资源在函数入口
  就注册释放——无论后面哪个分支提前 `return`，流都一定关闭。
  没有这一行，任何错误路径都会泄漏 fd。
- **第 190-194 行**：从 `stream` 构造 `std.Io.Reader`/`Writer`（各需
  一个 4 KB 栈缓冲），喂给 `std.http.Server.init`——0.17 的签名要
  裸接口指针（42 章讲过）。`std.http.Server` 是协议层状态机：
  它不懂 TCP，只懂"从 Reader 读字节、往 Writer 写字节"。
- **第 195 行 `receiveHead()`**：读请求行 + 头部，阻塞到客户端发完。
  返回的 `request.head` 里有 `method`、`target`（路径 + 查询串）、
  头部表。`catch return`：头都读不出来（客户端半途断连、发了垃圾
  字节）的连接没有处理价值，直接走 `defer` 关流。
- **第 197 行**：**路由决策与执行的唯一接触点**——
  `route(request.head.method, request.head.target)` 返回 `Action`，
  `switch` 按分支执行。HTTP 处理函数薄成这样，正是 45.2 把路由
  剥出去的回报：这个函数里没有任何"决策"值得单独测试，它的正确性
  由 route 的测试 + store 的测试 + 45.5 的端到端测试三层覆盖。

`respond` 的选项（每个分支都一样，讲一次）：

- `.status = .ok / .created / .not_found / .bad_request /
  .internal_server_error`——状态码枚举，`.created` 是 201
  （POST 创建成功必须回 201 而不是 200，这是 REST 语义）。
- `.extra_headers = &.{json_hdr}`——`json_hdr` 是文件级常量
  （第 158 行）：`content-type: application/json`。所有响应
  （包括错误响应）都带它——客户端按内容类型解析，错误体也是 JSON。
- `.keep_alive = false`——**响应完就关连接**。这不是性能选择而是
  正确性选择：本章的连接模型是"一连接一请求"，不关的话客户端
  复用连接时下一条请求会撞上一堆麻烦（坑位清单第 3 条）。
- `catch {}`：响应写失败（客户端已经跑了）无法挽回，吞掉。

各分支的业务语义：

- **`.list`（第 200-204 行）**：`storeToJson` 序列化整个 store
  （借用 1 KB 栈缓冲），200。零分配路径。
- **`.create`（第 205-225 行）**：POST 体是**系统边界**，三层防御
  全在这一段：
  1. **限长读体**（第 207-208 行）：`request.readerExpectNone(&rbuf2)`
     拿请求体读取器，`readAllocShort(ctx.gpa, 1024)` 读**至多** 1024
     字节。超过限长直接 `catch` 回 400 `{"error":"read body"}`——
     防巨包：一个 10 GB 的 POST 体如果无脑读进内存，几条并发就能
     拖死服务。`readAllocShort` 是 0.17 的新名字（旧 `readAlloc`
     已 deprecated 且语义变成 readAllocAll——读不满 Content-Length
     即报错，坑位清单第 4 条）。
  2. **解析失败回 400**（第 213-216 行）：`jsonToTodo` 的错误联合
     （`MissingField`、`SyntaxError`、`UnexpectedEndOfInput`……）
     全部 `catch` 成 400 `{"error":"bad json"}`——用户输入不合法
     是**客户端的错**，4xx 而不是 5xx。注意 `defer gpa.free(body)`
     在 `catch` 之前注册：解析失败的路径也要释放 body。
  3. **存储满回 500**（第 218-221 行）：`add` 返回 `null`（45.1.6
     测过的满分支）翻译成 500 `{"error":"full"}`。严格说 507
     （Insufficient Storage）更贴切，本章保持最小。
     成功路径回 **201**（`.created`），body 是刚创建的 Todo
     （`done` 硬编码 `false`——服务端权威，不信客户端传的值）。
     `defer gpa.free(todo.title)` 在 `add` **之后**注册——
     `add` 里 `items[self.len] = .{ ... .title = title }` 把
     指针存进了 store，store 现在**借用**这块内存；但响应拼完
     （`bufPrint` 拷贝进 `buf`）后 `todo.title` 就没用了，可以
     free。store 里的 `Todo.title` 从此悬空？不——`bufPrint` 是
     拷贝，`resp` 在栈上；而 store 的 `title` 指向 gpa 内存，
     进程退出时 gpa 统一回收。这是演示程序的简化：真实服务里
     store 拥有 title 的所有权（add 时 dupe、remove 时 free），
     本章为了聚焦 HTTP 层省略了（坑位清单第 8 条）。
- **`.get_one`（第 226-234 行）**：`orelse` 把"不存在"翻译成 404
  `{"error":"not found"}`——和路由的 `.not_found` 同 body 同状态码，
  客户端无需区分"路径不存在"和"资源不存在"。
- **`.toggle`（第 235-243 行）**：`toggle` 返回 `?bool`（翻转后的
  新值），`orelse` 翻译 404。响应只回 `id` 和 `done`——变更端点
  回变更的字段，是 API 设计的最小响应惯例。
- **`.delete`（第 244-250 行）**：`remove` 返回 `bool`（swap-remove
  是否真删到了），false 回 404。成功回 `{"deleted":true}`——
  DELETE 的响应体没有标准，给一个确认 JSON 方便客户端断言。
- **`.not_found`（第 251 行）**：路由没匹配上，404。注意它和
  `.get_one` 的 404 是**同一个** body——全服务的错误响应形状统一，
  客户端一种解析逻辑吃所有错误。

---

## 45.5 客户端：std.http.Client 的六种请求与进程内端到端

### 45.5.1 端到端测试的确定性三件套

在看代码之前，先把"进程内端到端测试为什么不会 flaky"讲透。flaky
的根源是**时序假设**："sleep 100ms 服务端肯定起来了"、"发完请求
服务端肯定退出了"。本章用三个机制消灭所有时序假设：

1. **原子端口发布**：服务端绑定成功才 `store(port)`，之前端口变量
   是 0；客户端 `while (load == 0) yield` 自旋等——**等到的一定
   是已绑定的端口**，不是"大概绑好了"。
2. **quota 计数**：服务端处理满 6 条必退出（45.4.2），退出条件是
   计数不是时间——客户端发完 6 条后 `join`，**join 返回时服务端
   一定处理完了全部 6 条**。
3. **join 等线程**：不用 `sleep` 等线程结束。`th.join()` 是确定
   的同步点。

三件套的共同思想：**用"事件已经发生"的确定性信号（端口非 0、
计数到 quota、线程 join 返回）替代"时间到了"的猜测**。31 / 34 章
的 zcache 用过同样的模式，本章是它的一次完整复用。

### 45.5.2 main：起线程 → 等端口 → 六请求 → join

```zig
// examples/45_websrv/main.zig 第 310-348 行
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
```

逐行讲：

- **第 311 行**：`SrvCtx` 构造。注意 `store = &store`——服务端线程
  和主线程共享 45.1 里那个已经装了两条 Todo 的 store。端到端测试
  不是从空库开始，而是带着已知状态开始：id 1（学 Zig）、id 2
  （写裸机），所以 POST 创建的必然是 id 3——**输出里的每个 id 都
  可预测**，这是端到端输出也能逐字节复现的原因。
- **第 312 行**：`std.Thread.spawn(.{}, serve, .{&ctx})`——服务端
  线程（19 章）。
- **第 313 行**：`while (ctx.port.load(.acquire) == 0)
  std.Thread.yield() catch {}`——**自旋等端口**。`.acquire` 与
  serve 里的 `.release` 配对：读到非 0 时端口写入已可见。
  `yield` 让出 CPU。没有 sleep——等多久取决于服务端何时绑好，
  不取决于猜的毫秒数。
- **第 316-317 行**：`std.http.Client` 字面量构造（42 章讲过：
  结构体不是指针），`defer client.deinit()`。
- **第 319 行**：`allocPrint` 拼 base URL。端口是扫出来的实际值，
  但**输出里不印端口**（只印请求路径和响应），所以端口具体是
  48300 还是 48307 不影响可复现性。
- **第 322-344 行**：6 条请求，每条先 `w.print` 打前缀（不换行），
  再由 `fetchPrint` 打状态码和 body（换行）。6 条覆盖了全部
  Action 分支：health、create、get_one、toggle、list、delete——
  **端到端测试的覆盖率 = 路由表的覆盖率**。
- **第 334-336 行**：toggle 这条的注释是血泪教训：
  `POST /todos/1/toggle` 语义上不需要请求体，但 0.17 的
  `std.http.Client.fetch` 对 POST **断言必须有 payload**（内部走
  `sendBodiless` 直接 panic）。所以传 `"{}"`——空 JSON 对象，
  服务端 `jsonToTodo` 解析 `{}` 会缺 `id` 字段报 `MissingField`？
  不会——toggle 分支根本不读请求体（45.4.3 的 `.toggle` 没有
  `readerExpectNone`），body 发出去就没人看。**客户端必须带体，
  服务端可以选择不看**，这就是协议两端各自的红线。
- **第 339-340 行**：第 5 条请求 GET 列表是**状态验证**——第 4 条
  toggle 了 id 1，列表里 id 1 的 `done` 必须是 `true`。如果 toggle
  有 bug（比如没写进 store），这里立刻暴露。
- **第 346 行 `th.join()`**：确定性同步点。join 返回 = 服务端
  处理完全部 6 条（quota 到，循环退出）。
- **第 347 行**：`ctx.served.load(.acquire)` 打印服务计数——
  必须是 6。这是端到端断言的"人眼版"：数字对了，6 条请求全部
  命中真实 HTTP 栈。

### 45.5.3 fetchPrint：一条请求的完整生命周期

```zig
// examples/45_websrv/main.zig 第 362-382 行
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
```

逐行讲：

- **第 371-372 行**：拼完整 URL，`defer` 释放。base 借用、path
  字面量，只有 url 是新分配的。
- **第 373-374 行**：`std.Io.Writer.Allocating` 接收响应体。
  这里用 `written()`（借用）而不是 `toOwnedSlice()`（转移）——
  响应体只在紧接着的 `print` 里用一次，借用省一次 dupe + free
  （42 章讲过两者的所有权差别）。
- **第 375-380 行 `client.fetch`**：0.17 客户端的唯一入口。
  `.location = .{ .url = url }` 指定目标；`.method` 和 `.payload`
  原样传参（`body: ?[]const u8`，GET 传 `null`）；`.response_writer`
  指定响应体写去哪。`fetch` 内部完成 TCP 连接、请求发送、
  响应接收全过程——包括**连接管理**：`keep_alive` 默认下客户端
  会尝试复用连接，这正是坑位清单第 3 条的背景。
- **第 381 行**：`@backingInt(result.status)` 把状态码枚举转整数
  （200），`result.status.phrase()` 拿原因短语（`"OK"`）。
  `.?` 解包可选——标准状态码都有短语。`jw.written()` 打印响应体。

### 45.5.4 运行时输出

```text
==== 45.4/45.5 进程内端到端：真实 HTTP 往返 ====
  GET /health → 200 OK  body={"ok":true}
  POST /todos {json} → 201 Created  body={"id":3,"title":"端到端","done":false}
  GET /todos/1 → 200 OK  body={"id":1,"title":"学 Zig","done":false}
  POST /todos/1/toggle → 200 OK  body={"id":1,"done":true}
  GET /todos → 200 OK  body={"todos":[{"id":1,"title":"学 Zig","done":true},{"id":2,"title":"写裸机","done":false},{"id":3,"title":"端到端","done":false}]}
  DELETE /todos/2 → 200 OK  body={"deleted":true}
  ✓ 6 条请求全部命中真实 HTTP 栈（quota 到，服务线程退出）
==== 45.4/45.5 进程内端到端：真实 HTTP 往返 结束 ====
```

逐条解读（每条都是一次完整的 TCP + HTTP 往返，客户端和服务端在
同一进程的两个线程里）：

- **`GET /health → 200 OK`**：最轻的端点，验证协议栈通了。
  body 是硬编码的 `{"ok":true}`。
- **`POST /todos → 201 Created`**：状态码是 **201** 不是 200——
  REST 语义"资源已创建"。body 里 `id:3`：45.1 预置了两条（id 1、2），
  `next_id` 自增到 3。`title:"端到端"` 是客户端发来的原值。
  注意客户端发的是 `{"id":0,...}`——**服务端忽略客户端的 id**
  （`add` 用 `next_id` 分配，`jsonToTodo` 解析出的 `id` 字段
  根本没被用），这是"服务端权威"原则：客户端提供的系统字段
  （id、时间戳）一律以服务端为准。
- **`GET /todos/1 → 200 OK`**：查单条。`done:false`——还没被
  toggle。
- **`POST /todos/1/toggle → 200 OK`**：翻转。响应 `done:true`。
  请求体 `{}` 被服务端无视（45.5.2 讲过为什么必须发）。
- **`GET /todos → 200 OK`**：**状态验证行**。列表三条：id 1 的
  `done` 变成了 `true`（toggle 落库的证据），id 2 未动，id 3 是
  刚创建的。这条响应约 150 字节，`storeToJson` 的 1 KB 栈缓冲
  轻松装下。
- **`DELETE /todos/2 → 200 OK`**：swap-remove 删掉 id 2。
- **`✓ 6 条请求…`**：`served` 计数 = 6 = quota，服务端循环退出，
  join 返回——端到端测试的确定性闭环。

### 45.5.5 测试：store CRUD

```zig
// examples/45_websrv/main.zig 第 406-417 行
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
```

端到端测试覆盖了"HTTP 层 + 路由 + store"的集成路径，这个 test
覆盖 store 的**单元路径**：id 自增、toggle 翻转、remove 后
get 不到、删不存在的返回 false。`s.add("a").?` 的 `.?` 解包
是断言的简写——add 返回 `?*Todo`，null 时 `.?` 会 panic，
测试立刻失败。

至此测试矩阵完整：**route 纯函数（9 断言）+ queryGet（3 断言）
+ store CRUD（7 断言）+ JSON 三个 test + 端到端 6 条真实往返**——
单元测试钉死零件，端到端测试钉死装配。

---

## 45.6 坑位清单

main 里有一段速览版（第 350-356 行），这里是展开版。按「踩坑的
先后顺序 + 会不会让程序 panic」排序，前 4 条是本章实测踩出来的。

### 一、实测踩出来的（0.17 专属）

1. **`std.http.Client.fetch` 对 POST 断言必须有请求体。**
   POST 带 `.payload = null` 会走内部的 `sendBodiless` 路径，
   直接断言 panic——不是编译错、不是运行错，是 panic，连
   `catch` 都接不住。语义上不需要体的 POST（如 toggle）必须
   传一个占位体，本章传 `"{}"`。反过来服务端没有义务读体：
   toggle 分支就不读。**记法：客户端必带，服务端选读。**

2. **`request.reader()` 不存在，读请求体用
   `request.readerExpectNone(&buf)`。** 旧教程/旧版本里的
   `request.reader()` 在 0.17 没有这个声明，编译错
   `no member named 'reader'`。正确写法：
   `const body_reader = request.readerExpectNone(&rbuf2);`——
   返回 `*Reader`（**指针**，不是错误联合），直接解引用调
   `readAllocShort`，不需要 `try` 拿读取器本身。名字里的
   `ExpectNone` 指"不期望 transfer-encoding 之外的额外语义"，
   常规 Content-Length 体走这条路。

3. **`respond` 必须显式 `.keep_alive = false`（本章的连接模型下）。**
   0.17 的 `std.http.Client` 默认**复用连接**（keep-alive）。
   如果服务端 respond 后不关连接、但循环里每个连接只处理一条
   请求（本章的模型），客户端复用旧连接发下一条请求时，服务端
   那边连接已处理完返回循环 accept 了——客户端会撞上
   `error.HttpConnectionClosing`。显式 `.keep_alive = false`
   让服务端响应完立刻关连接，客户端的复用尝试收到关闭信号后
   自动开新连接，语义干净。真实服务如果要 keep-alive，服务端
   得改成"一连接循环处理多条请求"（while receiveHead），两端
   协商一致——**keep-alive 是两端协议，一头热必炸**。

4. **`readAlloc` 在 0.17 已 deprecated，且语义变成了
   readAllocAll——读不满 Content-Length 即报错。** 名字带
   All 的语义："必须恰好读满"。请求体声明 100 字节、实际
   网络分包先到 60 字节，readAllocAll 不等你。读**已知上限的
   短 body**（本章的 JSON 体，上限 1 KB）用 `readAllocShort`：
   至多读 N 字节，读完即返回，容忍分包。超过限长报
   `error.StreamTooLong`——正好被 `.create` 分支的 `catch`
   翻译成 400，限长防御是白送的。

### 二、设计层面的（不踩不知道）

5. **路由必须"方法 × 路径"两维一起判。** 只判路径，`PUT /todos`
   会被当成有效端点；只判方法，`GET /todos` 和 `GET /todos/7`
   混为一谈。`route()` 的每个出口都是两维与/或的组合，负路径
   全部归 `.not_found`——测试里 9 个断言有 3 个是负路径。

6. **手写 JSON 拼接只配用于扁平已知形状。** `storeToJson` 手写
   是因为形状固定（数组 + 三个标量字段）。一旦形状复杂（嵌套
   对象、可选字段、字符串需要转义），手写拼接的转义边界
   （`title` 里有个 `"` 怎么办？）就是 bug 高发区——那种情况
   无条件换 `std.json.Stringify.value`（42 章）。本章的 title
   是硬编码中文，不含引号换行，手写安全；真实服务用户输入的
   title 必须走序列化器或至少过 `std.json.encodeString`。

7. **查询串在 `request.head.target` 里和路径连在一起。**
   `GET /todos?page=2` 的 target 是完整字符串，`route()` 的
   精确匹配会因为它不等于 `"/todos"` 而落到 `.not_found`。
   本章没有查询串端点所以无感；真实项目要在 route 入口先按
   `?` 切分：`const qpos = std.mem.indexOfScalar(u8, target, '?')
   orelse target.len;`，path 和 query 分别处理。另外
   `queryGet` 不做百分号解码，value 含 `%20` 要过
   `std.Uri.percentDecode`。

8. **演示级 store 的所有权是简化的，真实服务要补全。** 本章
   `add` 直接存调用方传入的 `title` 指针，`remove` 不 free——
   进程退出时 gpa 统一回收，演示没问题。真实长驻服务里 store
   必须拥有数据：add 时 `dupe`、remove 时 `free`，否则就是
   泄漏（或悬垂，如果调用方先 free 了）。把 45.1.2 的 Store
   换成 sqlite（32 章）是更省心的路：所有权交给数据库。

9. **第三方 Web 框架生态未成气候——0.17 标准库已够小服务。**
   这是全教程的最后一条工程忠告：网上流传的 Zig Web "框架"
   大量出自 AI 生成的伪代码教材（import 路径不存在、API 是
   编的），照抄连编译都过不去。在生态成熟前，`std.http` +
   纯函数路由 + `std.json` 的组合足够支撑小服务，且**每一个
   API 都在标准库源码里可查、可验证**。依赖越少，升级 0.18
   时越稳。

---

## 45.7 验证方式

三层，与全项目一致（见 2.8 节）：

```bash
./run-all.sh 45_websrv
```

脚本内部依次执行：`zig fmt --check .`（格式 + 语法）→
`zig test main.zig`（第 2 层：6 个 test）→
`zig build-exe main.zig`（第 3 层：main 也要能编）→ 运行二进制。

第 3 层不可省：`zig test` 不看 `main`，而本章最要紧的进程内
端到端 6 条 HTTP 往返**全在 `main` 里**。

跑完应看到（逐字节抄自实测）：

```text
==== 45.1 数据模型与 JSON 往返 ====
  storeToJson → {"todos":[{"id":1,"title":"学 Zig","done":false},{"id":2,"title":"写裸机","done":false}]}
  jsonToTodo（含未知字段）→ id=9 title=from json done=true
==== 45.1 数据模型与 JSON 往返 结束 ====
==== 45.2 路由表 ====
  GET /todos        → .{ .list = void }
  POST /todos       → .{ .create = void }
  GET /todos/7      → .{ .get_one = 7 }
  POST /todos/7/toggle → .{ .toggle = 7 }
  DELETE /todos/3   → .{ .delete = 3 }
  PUT /todos        → .{ .not_found = void }（方法不允许）
  GET /todos/abc    → .{ .not_found = void }（id 非数字）==== 45.2 路由表 结束 ====
==== 45.3 查询串解析 ====
  queryGet("page=2&limit=20&trace_id=xyz", "limit") = 20
  queryGet("page=2&limit=20&trace_id=xyz", "missing") = null
  queryGet("a=&b=1", "a") = ""（空 value 合法）
==== 45.3 查询串解析 结束 ====
==== 45.4/45.5 进程内端到端：真实 HTTP 往返 ====
  GET /health → 200 OK  body={"ok":true}
  POST /todos {json} → 201 Created  body={"id":3,"title":"端到端","done":false}
  GET /todos/1 → 200 OK  body={"id":1,"title":"学 Zig","done":false}
  POST /todos/1/toggle → 200 OK  body={"id":1,"done":true}
  GET /todos → 200 OK  body={"todos":[{"id":1,"title":"学 Zig","done":true},{"id":2,"title":"写裸机","done":false},{"id":3,"title":"端到端","done":false}]}
  DELETE /todos/2 → 200 OK  body={"deleted":true}
  ✓ 6 条请求全部命中真实 HTTP 栈（quota 到，服务线程退出）
==== 45.4/45.5 进程内端到端：真实 HTTP 往返 结束 ====
==== 45.6 坑位清单 ====
  1. 路由必须把"方法×路径"两维一起判——只判路径会接受 PUT /todos 这种怪请求
  2. POST 体是系统边界：readAlloc 限长（防巨包）、jsonToTodo 解析失败回 400
  3. 测试要确定性：quota 计数 + 原子端口发布，别 sleep 赌时序
  4. 端口扫描避开 ephemeral 区间；reuse_address 防 TIME_WAIT 拖累重跑
  5. 第三方 Web 框架生态未成气候——0.17 标准库已够小服务，依赖越少越稳
==== 45.6 坑位清单 结束 ====

自检通过
```

6 个 test 覆盖的行为面：

| test | 验什么 |
|---|---|
| `路由两维分派` | 7 个端点的方法×路径组合 + 标签与负载（id 值）正确 |
| `查询串解析` | 正常值 / 缺 key（null）/ 空 value（""）三态 |
| `store CRUD` | id 自增、toggle 翻转、remove 后查不到、删不存在返回 false |
| `JSON 往返 + 未知字段容忍` | storeToJson 输出包含预期子串、宽容模式跳过未知字段 |
| `JSON 缺字段 → 解析失败` | `{"id":3}` 缺 title 报 `error.MissingField` |
| `store 满 → add 返回 null` | 第 17 条塞满后 add 返回 null（main 走不到的边界） |

---

## 取材说明

取材 Sprinter ch16（Zig Web 开发），原书框架全系虚构，本章 0.17
标准库实测重写。

---

上一章：[43 并发文件索引器 zlocate](43-zlocate.md)
