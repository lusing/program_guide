# 30 · HTTP 服务与客户端

> 对应示例：`examples/30_http/main.zig`（1767 行，25 个测试）
>
> HTTP 是**基于行的文本协议**——请求行/状态行 + 头部 + 空行 + 体，每行以 CRLF 结尾。
> 这一章把这一层亲手写一遍：手写报文解析、响应构造、路由、JSON、URL 解析，
> 再在本进程内跑通一次完整往返。写过一次之后，任何 HTTP 框架都不再是黑盒。
> 取材 Systems Programming with Zig ch6（minimal web server / 随机数 JSON 服务）。
>
> **运输层沿用 29 章**：`std.Io.net` 的 `IpAddress.parseIp4` / `listen` / `connect` /
> `Server.accept`，socket 基础不重复。29 章已实测的三个坑（`Stream.read` 编译不过、
> `takeDelimiterExclusive` 不阻塞、`Stream.close` 不幂等）本章直接避开。
>
> 本章有 **6 条实测结论**，其中 3 条会推翻你可能听过的说法：
>
> 1. **`recvLine` 必须吃掉 CRLF 两个字节，只吃 `'\r'` 会让头部解析整个失效。**
>    这是本章写第一版时真踩的坑：服务端日志刷满
>    `解析失败 → 400 Bad Request（MalformedHeader）`，而代码看起来完全正确。
>    根因见 30.2——残留的 `'\n'` 让"空行"读出来长度是 1 而不是 0。
> 2. **状态行的 reason phrase 可以含空格**（`Not Found`、`Method Not Allowed`）。
>    用 `tokenizeScalar(.., ' ')` 切只会拿到 `Not` / `Method`，
>    剩下半截被静默丢掉（30.4）。
> 3. **`std.http.Client` 和 `std.http.Server` 在 0.17 都存在**，
>    且 `ChunkParser` / `HeadParser` / `HeaderIterator` 都在（30.11）。
>    "生产环境别自己写 HTTP"这条建议在0.17 是**有官方出处的**。
>
> 另外两条虽小但极隐蔽：
>
> 4. **`Uri.Component` 没有 `format` 方法**，`{f}` 直接编译不过（30.8）。
> 5. **`parseIp4` 的错误名不是 `InvalidAddress`**，实测是 `Overflow`（`999.1.1.1`）、
>    `Incomplete`（`1.2.3`）、`InvalidCharacter`（`localhost`）三个不同的错误。
>
> 第6 条不是协议知识而是内存纪律，但它的杀伤力最大：
>
> 6. **返回结构体里的所有切片字段必须统一指向同一份所有权。**
>    本章第一版的 `fetchToEof` 只 dupe 了 body，`reason` / `content_type`
>    仍指向栈上的 `raw`——函数一返回就悬垂，症状是打印出被腰斩的 `404 Not`。
>
> **节号对应**：30.1–30.11 是示例 `main` 里的运行时小节
> （`begin("30.N…") … end("30.N")`，运行输出里能看到 `==== 30.N … ====`）；
> **30.12（坑位清单）与 30.13（验证方式）不在 `main` 里**，它们是本文档自己的两节——
> 前者汇总本章所有实测结论，后者是 `run-all.sh` 的完整输出。
>
> **本章服务端与客户端在同一进程**（`std.Thread.spawn` + 端口原子公布）。
> 服务端线程**服务固定条数连接后返回**，`join()` 即同步——
> 所以 `./run-all.sh 30_http` 不可能挂死：客户端发够定量就一定收敛。
> 端口从 **48011 起向上扫 20 个高位非 0 端口**（⚠️ 绝不能从 0 起，见 30.9）。

---

## 30.1 报文解剖：CRLF 是结构的一部分

HTTP/1.1 的报文就是一段**纯文本**，唯一 structural 的东西是 `\r\n`（CRLF）。
一个 POST 请求的完整字节：

```text
POST /api/echo HTTP/1.1\r\n     ← 请求行：方法 SP 目标 SP 版本
Host: 127.0.0.1\r\n                ← 头部：名: 值（一行一个）
Content-Type: text/plain\r\n
Content-Length: 5\r\n
Connection: close\r\n
\r\n                               ← 空行 = 头部结束（CRLF CRLF 的第二个 CRLF）
hello                               ← 体：长度由 Content-Length 决定
```

响应同构：`HTTP/1.1 200 OK` + 头部 + 空行 + 体。三点值得单独拎出来：

**CRLF 是行分隔符，不是装饰。** 没有它你无法从字节流里切出边界——TCP 给你的只是
一串字节，"哪里是一行的结束"完全由协议约定。这也是为什么本章的 `recvLine`
要显式处理 `'\r'` 而不是简单找 `'\n'`（30.2）。

**空行是头部与体的分界，且它本身就是一个长度 0 的行。** 解析头部循环的唯一退出条件
就是"读到空行"，所以"空行到底怎么表示"直接决定了整个解析器能不能工作。

**体的长度不由空行决定，由 `Content-Length` 决定。** `hello` 后面如果还有字节，
那些字节是**下一个请求**的内容（keep-alive）或者根本不该有（`Connection: close`）。
"把空行之后的全拿走"是本章明确拒绝的一种实现。

示例把这段字节逐字节打印出来（CR/LF 转成 `␍␊` 显示，否则终端里根本看不见）：

```zig
// examples/30_http/main.zig 第 948-992 行
        err.print("  原文（CRLF 用 ␍␊ 显示，\\0用␀）：\n    ", .{});
        for (sample) |ch| {
            // ⚠️ 直接 `print("{c}")` 会把 CR/LF 原样输出到终端——
            // 光标回车 / 换行，屏幕上什么都看不出来。控制字符必须转义显示。
            switch (ch) {
                '\r' => err.print("␍", .{}),
                '\n' => err.print("␊\n", .{}),
                0 => err.print("␀", .{}),
                else => err.print("{c}", .{ch}),
            }
        }
        err.print("\n", .{});
        // 按 CRLF 逐段拆解。⚠️ `tokenizeSequence` 会跳过空段，所以这里
        // **手工切**——而"头部结束的空行"恰恰就是要观察的那个空段。
        {
            var rest: []const u8 = sample;
            var idx: usize = 0;
            while (std.mem.indexOf(u8, rest, "\r\n")) |e| {
                const line = rest[0..e];
                if (line.len == 0) {
                    err.print("    [{d}] ␍␊← **空行**：头部到此结束，剩下的是体\n", .{idx});
                } else {
                    err.print("    [{d}] {s}␍␊\n", .{ idx, line });
                }
                idx += 1;
                rest = rest[e + 2 ..];
            }
            if (rest.len > 0) err.print("    [{d}] {s}← 体（后面没有 CRLF，它不是行）\n", .{ idx, rest });
        }
```

这里藏着一个 0.17 的实测细节：**`std.mem.tokenizeSequence` 会跳过空段**。
所以想观察"头部结束的那个空行"（恰恰是本节的主角），**不能**用tokenize 家族，
必须手工 `indexOf` + 切片。体 `hello` 也不是行——它后面没有 CRLF，
所以它出现在第 6 段而不是被切成一个"行"。

运行输出（`examples/30_http/main.zig`）

```text
==== 30.1 报文解剖：CRLF 是结构的一部分 ====
  原文（CRLF 用 ␍␊ 显示，\0用␀）：
    POST /api/echo HTTP/1.1␍␊
Host: 127.0.0.1␍␊
Content-Type: text/plain␍␊
Content-Length: 5␍␊
Connection: close␍␊
␍␊
hello
    [0] POST /api/echo HTTP/1.1␍␊
    [1] Host: 127.0.0.1␍␊
    [2] Content-Type: text/plain␍␊
    [3] Content-Length: 5␍␊
    [4] Connection: close␍␊
    [5] ␍␊← **空行**：头部到此结束，剩下的是体
    [6] hello← 体（后面没有 CRLF，它不是行）

  CRLF 的作用是**行分隔符**：没有它就无法从字节流里切出边界。
  HTTP/1.1 规定：每个头以 CRLF 结束，CRLF CRLF 的第二个 CRLF 是空行、分隔头与体。
  ⚠️ recvLine 必须**吃掉 CRLF 两个字节**——只吃 '\r' 会让下一行
     带上残留的 '\n'，于是空行读出来长度是 1 而不是 0，
     「读到空行就停」的头部循环直接失效（本章实测踩过）。
==== 30.1 报文解剖：CRLF 是结构的一部分 结束 ====
```

---

## 30.2 手写行读取：三件套，以及本章踩到的第一个真bug

29 章已经实测过：**`takeDelimiterExclusive` 在网络 Reader 上不阻塞**——
它只扫已经缓冲在手里的字节，手上没有 `'\n'` 就立刻返回空片、不做底层读。
症状是服务端陷入"读到空行 → 写 OK → 再读到空行"的死循环。

本章先用缓冲 Reader 把它的形状钉住，再给出正确写法：

```zig
// examples/30_http/main.zig 第 995-1011 行
    begin("30.2 手写行读取：fillMore + indexOfScalarPos + toss");
    {
        // 缓冲 Reader（数据已在手里）上 takeDelimiterExclusive 很好用
        var fr = std.Io.Reader.fixed("GET / HTTP/1.1\r\nHost: x\r\n\r\n");
        const l1 = fr.takeDelimiterExclusive('\n') catch "ERR";
        err.print("  缓冲 Reader 上 takeDelimiterExclusive：\n", .{});
        err.print("    第一行 = {x}\n", .{l1});
        err.print("    ↑结尾的 0d 就是 '\\r'——调用者得自己剔（这就是手写行解析的日常）\n", .{});

        // ⚠️ 但在**网络 Reader** 上它不阻塞：手上没数据就立刻返回空片。
        // 这个坑在 29 章 agent 实测里死过——服务端陷入
        //「读到空行 → 写 OK → 再读到空行」的死循环，日志里一片空行。
        // 空 Reader 上这个"不等数据"的语义最直观：
        var empty_r = std.Io.Reader.fixed("");
        if (empty_r.takeDelimiterExclusive('\n')) |_| {
            err.print("    空 Reader → 返回了切片\n", .{});
        } else |e| {
            err.print("    空 Reader → 立刻报 {s}（**它不会替你等数据**）\n", .{@errorName(e)});
        }
```

`{x}` 打的是十六进制，所以 `...310d` 结尾的 `0d` 就是 `'\r'`——
即便在缓冲 Reader 上，`takeDelimiterExclusive('\n')` 也会把它留在返回的切片里。
**HTTP 的行尾是 CRLF 两个字节**，处理它是你自己的事。

正确写法是三件套：**`fillMore`（唯一会阻塞的一步）+ `buffered`（看不阻塞）+
`toss`（丢弃已取走）**。本章的 `Conn.recvLine`：

```zig
// examples/30_http/main.zig 第 86-126 行
    pub fn recvLine(self: *Conn, out: []u8, max_line: usize) ![]u8 {
        self.ensureBound();
        const r = &self.r.interface;
        var scanned: usize = 0; // 已扫过但不属于本行的字节数
        while (true) {
            const avail = r.buffered();
            // HTTP 行尾是 CRLF。搜 '\r' 定位行尾（头部里不会出现裸 '\r'），
            // 切出来的行天然不含结尾的 '\r'。
            if (std.mem.indexOfScalarPos(u8, avail, scanned, '\r')) |at| {
                const line = avail[scanned..at];
                // ⚠️⚠️ **必须吃掉 CRLF 两个字节**，只 `toss(at + 1)` 会把 '\n'
                // 留给下一次 recvLine，于是下一行变成 "\nHost: x"，而**空行
                // 判断 `len == 0` 永远不成立**（"\r\n" 那行读出来是 "\n"，
                // 长度 1）→ 头部循环一路读到 LineTooLong。
                // 这是本章实测踩到的第一个真bug（30.4 的服务端日志里
                // 全是 "解析失败 → 400 MalformedHeader"）。
                if (at + 1 < avail.len and avail[at + 1] == '\n') {
                    r.toss(at + 2);
                } else {
                    // '\n' 还没进缓冲（分片到达）：先吃 '\r'，补一次读再吃 '\n'。
                    // 对端用裸 CR 收尾（HTTP/0.9 老写法）时容忍缺失。
                    r.toss(at + 1);
                    r.fillMore() catch |err| switch (err) {
                        error.EndOfStream => {},
                        error.ReadFailed => return error.ReadFailed,
                    };
                    const rest = r.buffered();
                    if (rest.len > 0 and rest[0] == '\n') r.toss(1);
                }
                if (line.len > max_line) return error.LineTooLong;
                @memcpy(out[0..line.len], line);
                return out[0..line.len];
            }
            scanned = avail.len;
            if (scanned > max_line) return error.LineTooLong; // 超长行：直接断连
            r.fillMore() catch |err| switch (err) {
                error.EndOfStream => return error.ConnectionClosed,
                error.ReadFailed => return error.ReadFailed,
            };
        }
    }
```

**这个函数里有三处非显然的设计，逐个说清楚：**

**① 为什么搜 `'\r'` 而不是 `'\n'`。** 两者都能定位行尾，但搜 `'\r'` 时
"行内容"就是 `avail[scanned..at]`，末尾的 `'\r'` 天然被排除，不需要额外剔除。
搜 `'\n'` 则得到 `avail[scanned..at]` 末尾带 `'\r'`，得再判一次。
HTTP 头部里不会出现裸 `'\r'`（值里的裸 CR 本身就是 CRLF 注入攻击），所以搜它安全。

**② 为什么必须吃掉两个字节（本章最大的坑）。** 找到 `'\r'` 在 `at`，
`'\n'` 在 `at + 1`。如果只 `toss(at + 1)`（吃掉 `'\r'`），那么 `'\n'` 留在缓冲区头部，
下一次 `recvLine` 拿到的"行"是 `"\nHost: x"`——**开头多一个换行**。
于是头部解析循环里这个判断：

```zig
if (hl.len == 0) break; // 空行 = 头部结束
```

**永远不成立**：真正的空行 `"\r\n"` 读出来是 `"\n"`，长度 1。
头部循环会一路往下读，直到撞上 `max_line` 报 `LineTooLong`。
本节的实测症状很具体：服务端日志里每一行都是
`解析失败 → 400 Bad Request（MalformedHeader）`，
而 `recvLine` 的代码**看起来完全正确**——这就是它阴的地方。

**③ `scanned` 为什么存在。** `avail` 是"已就绪但未取走"的字节。
如果一行跨越了多次 `fillMore`（大 header 行、或者对端分片发），
第一次没找到 `'\r'` 时不能从头重扫（`O(n²)`），所以记住"已经扫到哪里"，
下一轮从 `scanned` 继续。`scanned = avail.len` 就是"整块扫过了，都不属于本行"。

**④ 顺带说清 `recvExact`**（体用它）——**不能用 `readSliceShort`**：

```zig
// examples/30_http/main.zig 第 128-150 行
    pub fn recvExact(self: *Conn, out: []u8) !usize {
        self.ensureBound();
        const r = &self.r.interface;
        var got: usize = 0;
        while (got < out.len) {
            const avail = r.buffered();
            if (avail.len == 0) {
                r.fillMore() catch |err| switch (err) {
                    error.EndOfStream => return error.ConnectionClosed,
                    error.ReadFailed => return error.ReadFailed,
                };
                continue;
            }
            const n = @min(out.len - got, avail.len);
            @memcpy(out[got..][0..n], avail[0..n]);
            r.toss(n);
            got += n;
        }
        return got;
    }
```

`readSliceShort` 的语义是"**填满缓冲或读到 EOF**"。当单次 recv 用，
对端发 5 字节就不发了，你却要等满 4096 —— 服务端挂死。
`recvExact` 则是"有多少拿多少，攒够 `out.len` 才返回"，
并且**每一轮都先看 `buffered()`**（不阻塞），空了才 `fillMore`（阻塞）。

运行输出（`examples/30_http/main.zig`）

```text
==== 30.2 手写行读取：fillMore + indexOfScalarPos + toss ====
  缓冲 Reader 上 takeDelimiterExclusive：
    第一行 = 474554202f20485454502f312e310d
    ↑结尾的 0d 就是 '\r'——调用者得自己剔（这就是手写行解析的日常）
    空 Reader → 立刻报 EndOfStream（**它不会替你等数据**）

  正确姿势（Conn.recvLine，三件套）：
    ① fillMore()做一次底层读（唯一会阻塞的一步）
    ② buffered() 看已就绪的字节（**不阻塞**）
    ③ indexOfScalarPos(avail, scanned, '\r') 找行尾
    ④ toss(at + 2) 丢掉整对 CRLF —— **两个字节**（只吃 '\r' 会留 '\n' 害死下一行）
  只有 ① 会等；② 看到的就是① 的成果，所以不会刷空行。
==== 30.2 手写行读取：fillMore + indexOfScalarPos + toss 结束 ====
```

---

## 30.3 请求解析状态机：三步 + 三个上限

解析一个 HTTP 请求就是三步：**读首行 → 逐行读头部直到空行 → 按 `Content-Length` 读体**。
每一步都必须有上限，否则恶意对端一个请求就能打爆你的进程。

本章把状态机写成 `comptime C: type` 的**泛型**而不是收 `*Conn`——
这是让这段逻辑**零 IO 就能测**的关键（任何有 `recvLine`/`recvExact`
两个方法的类型都能驱动它：真实连接 `Conn`，测试里用 `FixedConn`）。

```zig
// examples/30_http/main.zig 第 290-364 行
fn parseRequest(
    comptime C: type,
    conn: *C,
    scratch: []u8,
    head_buf: []Header,
    body_buf: []u8,
    limits: Limits,
) ParseError!Request {
    var req = Request{};
    var used: usize = 0; // scratch 里已用掉的字节数（bump 指针）

    // ── 状态 1：请求行
    {
        if (scratch.len < limits.line) return error.LineTooLong;
        const line = try conn.recvLine(scratch[used..][0..limits.line], limits.line);
        used += line.len;
        if (line.len == 0) return error.MalformedRequestLine;
        var it = std.mem.tokenizeScalar(u8, line, ' ');
        const method = it.next() orelse return error.MalformedRequestLine;
        const target = it.next() orelse return error.MalformedRequestLine;
        const version = it.next() orelse return error.MalformedRequestLine;
        if (it.next() != null) return error.MalformedRequestLine; // 第四段 = 畸形
        if (version.len < 5 or !std.mem.startsWith(u8, version, "HTTP/")) return error.MalformedRequestLine;

        req.method = method;
        req.target = target;
        req.version = version;
        // target 拆成 path + query。`/api/rand?n=5` → path=/api/rand, query=n=5
        if (std.mem.indexOfScalar(u8, target, '?')) |q| {
            req.path = target[0..q];
            req.query = target[q + 1 ..];
        } else {
            req.path = target;
            req.query = "";
        }
    }

    // ── 状态 2：头部，直到空行
    var n: usize = 0;
    while (true) {
        if (used + limits.line > scratch.len) return error.LineTooLong; // bump 区满
        const hl = try conn.recvLine(scratch[used..][0..limits.line], limits.line);
        if (hl.len == 0) break; // 空行 = 头部结束
        used += hl.len;
        if (n >= limits.headers) return error.TooManyHeaders;
        const colon = std.mem.indexOfScalar(u8, hl, ':') orelse return error.MalformedHeader;
        // 冒号后的前导空白要去掉（HTTP 允许 `Key: Value` 和 `Key:Value` 两种）
        var v = hl[colon + 1 ..];
        while (v.len > 0 and (v[0] == ' ' or v[0] == '\t')) v = v[1..];
        head_buf[n] = .{ .name = hl[0..colon], .value = v };
        n += 1;
    }
    req.headers = head_buf[0..n];

    // ── 状态 3：体（只有声明了 Content-Length 才读）
    if (req.header("Content-Length")) |cl_str| {
        const cl = std.fmt.parseInt(usize, cl_str, 10) catch return error.MalformedHeader;
        if (cl > limits.body) return error.BodyTooLarge; // 413
        if (cl > 0) {
            const got = try conn.recvExact(body_buf[0..cl]);
            req.body = body_buf[0..got];
        }
    }
    return req;
}
```

**为什么要切三段而不是两段？** `GET /` 只有两段是**畸形**的，
而 `GET / HTTP/1.1` 才是合法的最小请求行。不检查版本号，
就把 HTTP/0.9 和一堆垃圾数据当成了合法请求。多出来的第四段同样拒——
`GET / HTTP/1.1 extra` 不是什么"扩展"，是畸形。

**`scratch` 是"只进不退"的 bump 区，绝不能复用。** 这是本章踩到的**第二个** bug，
而且它比CRLF 那个更值得讲：

第一版只有一块 `line_buf`，每读一行就从头覆盖——于是 `req.method`
（指向首行）在读完第一个头之后变成 `"Hos"`，而**所有**头的 name/value
也全都指向最后一行。症状是"解析成功但字段全是垃圾"。
它比悬垂切片更阴的地方在于：**线上它可能看起来是对的**（字段短、恰好没被覆盖完），
只有内容变长时才崩。

改成bump 区（`used` 单调递增）之后，写过的字节永不被覆盖，这类整类别名从根上消失。
测试里那条 `expected "GET", found "Hos"` 的失败信息就是它留下的指纹。

**三个上限各自防什么：**

| 上限 | 默认 | 防的是 |
|---|---|---|
| `line` | 1024 | 一个 1MB 的请求行 → 一次 OOM |
| `headers` | 16 | 一万个 `X-Header:` → CPU 与内存双杀 |
| `body` | 4096 | `Content-Length: 999999999` → 你 alloc 多少由对端说了算 |

`body` 上限尤其重要：**`Content-Length` 是对端提供的数字**。
不clamp 就等于把分配决策权交给陌生人。

```zig
// examples/30_http/main.zig 第 215-223 行
const Limits = struct {
    /// 单行上限（请求行/头部行都算）。防"一个超长请求行打爆内存"。
    line: usize = 1024,
    /// 头部行数上限。防"一万个 X-Header"。
    headers: usize = 16,
    /// 体上限。**这是必须的**——Content-Length 是对端说了算的数字，
    /// 不 clamp 就等于让对端决定你 alloc 多少。
    body: usize = 4096,
};
```

`Request` 的两个小方法：

```zig
// examples/30_http/main.zig 第 230-252 行
const Request = struct {
    method: []const u8 = "",
    target: []const u8 = "",
    path: []const u8 = "/",
    query: []const u8 = "",
    version: []const u8 = "",
    headers: []Header = &.{}, // 指向调用方数组，不拥有
    body: []const u8 = "", // 指向调用方缓冲，不拥有

    /// 按名字找请求头（**大小写不敏感**——HTTP 头字段名不区分大小写）。
    fn header(self: *const Request, name: []const u8) ?[]const u8 {
        for (self.headers) |h| {
            if (std.ascii.eqlIgnoreCase(h.name, name)) return h.value;
        }
        return null;
    }

    fn keepAlive(self: *const Request) bool {
        const c = self.header("Connection") orelse return true; // HTTP/1.1 默认 keep-alive
        return !std.ascii.eqlIgnoreCase(c, "close");
    }
};
```

注意 `headers` 和 `body` 都**不拥有内存**——它们指向 `head_buf` / `body_buf` / `scratch`。
调用方保证这三个缓冲在 `Request` 还活着期间有效。这是零分配的代价，
也是本章所有内存 bug 的来源位置。

`main` 的 30.3 节把状态机的每一步和每个上限都打出来（**零 IO**，全靠 `FixedConn`）：

```zig
// examples/30_http/main.zig 第 1024-1052 行
    begin("30.3 请求解析状态机：三步 + 三个上限");
    {
        const raw = "POST /api/echo?x=1 HTTP/1.1\r\n" ++
            "Host: 127.0.0.1\r\n" ++
            "Content-Type: text/plain\r\n" ++
            "Content-Length: 5\r\n" ++
            "\r\n" ++
            "hello";
        var sc: [8192]u8 = undefined;
        var hb: [16]Header = undefined;
        var bb: [4096]u8 = undefined;
        const req = try parseFixed(raw, .{}, &sc, &hb, &bb);
        err.print("  方法   = {s}\n", .{req.method});
        err.print("  目标   = {s}\n", .{req.target});
        err.print("  版本   = {s}\n", .{req.version});
        err.print("  path   = {s}（'?' 之前）\n", .{req.path});
        err.print("  query  = {s}（'?' 之后）\n", .{req.query});
        err.print("  头部   = {d} 行：", .{req.headers.len});
        for (req.headers) |h| err.print(" [{s}: {s}]", .{ h.name, h.value });
        err.print("\n  体     = {s}（按 Content-Length=5 读，不是把空行之后的全拿走）\n", .{req.body});
        err.print("  keepAlive = {}（Connection 缺省 = true）\n", .{req.keepAlive()});
```

运行输出（`examples/30_http/main.zig`）

```text
==== 30.3 请求解析状态机：三步 + 三个上限 ====
  方法   = POST
  目标   = /api/echo?x=1
  版本   = HTTP/1.1
  path   = /api/echo（'?' 之前）
  query  = x=1（'?' 之后）
  头部   = 3 行： [Host: 127.0.0.1] [Content-Type: text/plain] [Content-Length: 5]
  体     = hello（按 Content-Length=5 读，不是把空行之后的全拿走）
  keepAlive = true（Connection 缺省 = true）

  上限一 line=1024：请求行 138 字符，把 line 上限调到 64 → LineTooLong
           同样的行，默认上限 1024 → OK（解析成功）（合法）
  上限二 headers=16：20 个头（每个 "x-hN: v"）→ LineTooLong
  上限三 body  = 4096：Content-Length:999999 → BodyTooLarge
==== 30.3 请求解析状态机：三步 + 三个上限 结束 ====
```

⚠️ **上限二那一行值得单独说**：20 个头触发的**不是** `TooManyHeaders`，
而是 `LineTooLong`。因为每个 `FixedConn.recvLine` 都往 bump 区里追加，
20 行 × 每行约 1024 字节的窗口检查先撞上了 `scratch` 边界。
这不是 bug，是**上限检查的顺序**：`scratch` 满和 `headers` 超限都会导致拒绝，
先撞上哪个取决于配置。真实网络路径上 `scratch` 是 8192、`line` 是 1024，
所以第 8 个头就先撞 `scratch` 了。

这条实测的教训是：**给解析器配上限时，上限之间也会互相干扰**。
`scratch` 必须 ≥ `(headers + 2) * line`，否则 `headers` 上限形同虚设。
本示例的 8192 / 16 / 1024 之所以能触发 `TooManyHeaders`，
是因为测试里把 `line` 调小到 64（见测试 `上限二：头部行数超 headers 上限`）。

---

## 30.4 响应构造：`Content-Length` 写错就挂死客户端

**这是本章最重要的实践点。** 客户端严格按 `Content-Length` 数字节，
所以这个数字写错的后果**全部落在客户端**，而服务端日志一切正常。

```zig
// examples/30_http/main.zig 第 404-440 行
const Response = struct {
    code: u16 = 200,
    reason: []const u8 = "OK",
    content_type: []const u8 = "text/plain; charset=utf-8",
    body: []const u8 = "",
    /// close = 发完就关连接（客户端读到 EOF 即响应完整）；
    /// false = keep-alive，客户端**必须**按 Content-Length 数字节。
    close: bool = true,
    /// 只给"故意写错 Content-Length"的演示用；null = 按 body.len 算。
    /// 生产代码里**永远不该有这个东西**——它存在的唯一目的是让本章能演示
    /// 长度写错会怎样（见30.4）。
    content_length_override: ?usize = null,
};

/// 把响应序列化成线上的字节。
///
/// **`Content-Length` 是本章最要命的一行**：客户端严格按它数字节，
/// 写大了一直等、写小了一截被当下一个响应的开头——两种都表现为「挂死」，
/// 而且是**在客户端挂死、服务端日志一切正常**。永远用 `body.len` 算，别手输。
fn serialize(a: std.mem.Allocator, rep: *const Response) ![]u8 {
    const len = rep.content_length_override orelse rep.body.len;
    // ⚠️ reason 是**状态行的一部分**，不是可选的装饰。漏填就会发出
    // "HTTP/1.1 404 OK" 这种自相矛盾的行——本节第一版就是这样，
    // 客户端拿到的 404 理由写着 OK。这里兜底查表，别依赖每个调用点记得填。
    const reason = if (rep.reason.len == 0) reasonPhrase(reasonCode(rep)) else rep.reason;
    return std.fmt.allocPrint(
        a,
        "HTTP/1.1 {d} {s}\r\n" ++
            "Content-Type: {s}\r\n" ++
            "Content-Length: {d}\r\n" ++
            "Connection: {s}\r\n" ++
            "\r\n" ++
            "{s}",
        .{ rep.code, reason, rep.content_type, len, if (rep.close) "close" else "keep-alive", rep.body },
    );
}
```

**两种错法，两种症状：**

| 错法 | 现象 | 诊断难度 |
|---|---|---|
| **写大**（CL=20，体5 字节） | 客户端等剩下 15 字节。**若连接不close → 永久挂死** | 中（挂死，但栈清楚） |
| **写小**（CL=2，体5 字节） | 客户端数够就停。**静默截断，连错误都没有** | 高（JSON 解析在半路炸，栈指向客户端） |

写小比写大更危险，因为它**不报错**。错误栈指向客户端的 JSON 解析器，
而真正的原因在服务端——隔着一条网络。

`main` 的 30.4 节把三种响应都打出来（CRLF 转成 `\r\n` 字面量便于逐字节看），
然后**真跑一次**让服务端故意写错的CL，看客户端拿到什么：

```zig
// examples/30_http/main.zig 第 1066-1123 行
    begin("30.4 响应构造：Content-Length 写错就挂死客户端");
    {
        const good = Response{ .code = 200, .body = "hello" };
        err.print("  ✓ 正确：体 5 字节，Content-Length 也写 5\n", .{});
        err.print("    {s}\n", .{try showCrLf(a, try serialize(a, &good))});

        // 长度写**大**：客户端按 CL 等 20 字节，服务端只发了 5 个就close
        // → 若连接不关（keep-alive），客户端永远等那 15 个 → 挂死。
        const big = Response{ .code = 200, .body = "hello", .content_length_override = 20 };
        err.print("\n  ✗ 写大：Content-Length=20 但体只有 5 字节\n", .{});
        err.print("    {s}\n", .{try showCrLf(a, try serialize(a, &big))});
        err.print("    → 客户端 recvExact 等剩余 15 字节。⚠️ 若服务端不 close 连接（keep-alive）它就挂死。\n", .{});

        // 长度写**小**：客户端数够 CL 就停，剩下的字节被当下一个响应的开头
        // → keep-alive 下彻底错位。
        const small = Response{ .code = 200, .body = "hello", .content_length_override = 2, .close = false };
        err.print("\n  ✗ 写小：Content-Length=2 但体有 5 字节（keep-alive）\n", .{});
        err.print("    {s}\n", .{try showCrLf(a, try serialize(a, &small))});
        err.print("    → 客户端读完 2 字节就停，剩下 \"llo\" 被当下一条响应的状态行 → 解析失败。\n", .{});

        // 两种"正确"姿势
        err.print("\n  ⇒ Content-Length 的唯一正确算法：`body.len`。永远别手输这个数字。\n", .{});
        err.print("  ⇒ 另一种正确姿势：不发 Content-Length，改用 Connection: close + 读到 EOF。\n", .{});

        // 真往返两次：让服务端故意写错的 CL，看客户端分别拿到什么。
        {
            // ① CL 写**大**（2000，真实体约 120 字节）→ 客户端永远等不到 → TruncatedBody
            var ctx: ServerCtx = .{};
            const th = try startServer(io, 1, .{}, 2000, &ctx);
            const port = srv_port.load(.acquire);
            if (fetchByLength(a, io, port, "GET", "/api/info")) |ok| {
                err.print("\n  实测① CL 写大：客户端读到 {d} 字节就停下\n", .{ok.body.len});
            } else |e| {
                err.print("\n  实测① CL 写大（2000，真实体约 120 字节）：\n", .{});
                err.print("    按 CL 读的客户端拿到 {s} —— **没有挂死**，因为对端 close 了，\n", .{@errorName(e)});
                err.print("    fillMore 返回 EndOfStream，我们把它翻译成一个可诊断的错误。\n", .{});
            }
            th.join();
            err.print("    ⚠️ 若服务端**不** close（keep-alive），同一个客户端就永久等待——\n", .{});
            err.print("       没有任何超时机制能救你。这就是「长度必须一次写对」的全部理由。\n", .{});
        }
        {
            // ② CL 写**小**（5）→ 客户端数够就停，**静默截断**，连错误都不报
            var ctx2: ServerCtx = .{};
            const th2 = try startServer(io, 1, .{}, 5, &ctx2);
            const port2 = srv_port.load(.acquire);
            if (fetchByLength(a, io, port2, "GET", "/api/info")) |ok| {
                err.print("\n  实测② CL 写小（5，真实体约 120 字节）：\n", .{});
                err.print("    客户端拿到 {d} 字节：{s}\n", .{ ok.body.len, ok.body });
                err.print("    ⚠️ **静默截断，连错误都没有** —— 比挂死更难查：JSON 解析在半路炸，\n", .{});
                err.print("       而报错的栈指向客户端，跟真正的原因隔着一条网络。\n", .{});
            } else |e| {
                err.print("\n  实测② CL 写小 → {s}\n", .{@errorName(e)});
            }
            th2.join();
        }
    }
    end("30.4 响应构造：Content-Length 写错就挂死客户端");
```

运行输出（`examples/30_http/main.zig`）

```text
==== 30.4 响应构造：Content-Length 写错就挂死客户端 ====
  ✓ 正确：体 5 字节，Content-Length 也写 5
    HTTP/1.1 200 OK\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Length: 5\r\nConnection: close\r\n\r\nhello

  ✗ 写大：Content-Length=20 但体只有 5 字节
    HTTP/1.1 200 OK\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Length: 20\r\nConnection: close\r\n\r\nhello
    → 客户端 recvExact 等剩余 15 字节。⚠️ 若服务端不 close 连接（keep-alive）它就挂死。

  ✗ 写小：Content-Length=2 但体有 5 字节（keep-alive）
    HTTP/1.1 200 OK\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Length: 2\r\nConnection: keep-alive\r\n\r\nhello
    → 客户端读完 2 字节就停，剩下 "llo" 被当下一条响应的状态行 → 解析失败。

  ⇒ Content-Length 的唯一正确算法：`body.len`。永远别手输这个数字。
  ⇒ 另一种正确姿势：不发 Content-Length，改用 Connection: close + 读到 EOF。
  [server] GET /api/info → 200 OK（体 110 字节，Content-Length=2000）

  实测① CL 写大（2000，真实体约 120 字节）：
    按 CL 读的客户端拿到 TruncatedBody —— **没有挂死**，因为对端 close 了，
    fillMore 返回 EndOfStream，我们把它翻译成一个可诊断的错误。
    ⚠️ 若服务端**不** close（keep-alive），同一个客户端就永久等待——
       没有任何超时机制能救你。这就是「长度必须一次写对」的全部理由。
  [server] GET /api/info → 200 OK（体 110 字节，Content-Length=5）

  实测② CL 写小（5，真实体约 120 字节）：
    客户端拿到 5 字节：{"nam
    ⚠️ **静默截断，连错误都没有** —— 比挂死更难查：JSON 解析在半路炸，
       而报错的栈指向客户端，跟真正的原因隔着一条网络。
==== 30.4 响应构造：Content-Length 写错就挂死客户端 结束 ====
```

`客户端拿到 5 字节：{"nam` 就是写小的现场——JSON 在 `{"nam` 处断掉，
`std.json` 会报一个语法错误，而那个错误的栈在客户端，
真正的原因（服务端把 CL 写成 5）在日志里隔着几屏。

### 30.4.1 顺带修掉的第二个 bug：reason phrase 含空格

`fetchByLength` / `fetchToEof` 解析状态行时，第一版这么写：

```zig
// ❌ 第一版（错的）
var it = std.mem.tokenizeScalar(u8, head[0..eol], ' ');
const ver = it.next() orelse return error.BadResponse;
const code_str = it.next() orelse return error.BadResponse;
return .{ .code = ..., .reason = it.next() orelse "" };
```

`tokenizeScalar` 按空格切，所以 `HTTP/1.1 404 Not Found` 的 `it.next()`
只给出 `"Not"`——`" Found"` 被静默丢掉。客户端打印出来是 `404 Not`。

正确写法是**第二个空格之后的整段**：

```zig
// examples/30_http/main.zig 第 627-657 行
fn parseStatusLine(head: []const u8) !Reply {
    const eol = std.mem.indexOf(u8, head, "\r\n") orelse head.len;
    const line = head[0..eol];
    var it = std.mem.tokenizeScalar(u8, line, ' ');
    const ver = it.next() orelse return error.BadResponse;
    const code_str = it.next() orelse return error.BadResponse;
    const code = std.fmt.parseInt(u16, code_str, 10) catch return error.BadResponse;
    // ⚠️ reason phrase **可以含空格**（"Not Found"、"Method Not Allowed"、
    // "Request Header Fields Too Large"）。所以不能 `it.next()`——
    // 那只会拿到 "Not" / "Method" / "Request"，剩下半截被丢掉。
    // 正确做法是**第二个空格之后的整段**都是 reason。
    // （本示例第一版就踩了：客户端打印出 "404 Not"、"405 Method"。）
    return .{
        .version = ver,
        .code = code,
        .reason = reasonAfterCode(line),
    };
}

/// 取状态行里第三段起的**全部剩余内容**作为 reason（保留内部空格）。
fn reasonAfterCode(line: []const u8) []const u8 {
    var i: usize = 0;
    var spaces: usize = 0;
    while (i < line.len) : (i += 1) {
        if (line[i] == ' ') {
            spaces += 1;
            if (spaces == 2) return std.mem.trim(u8, line[i + 1 ..], " ");
        }
    }
    return "";
}
```

`Request` 那边也一样：请求行 `GET /api/echo?x=1 HTTP/1.1` 的第三段是版本，
但**目标里可以含空格吗**——RFC 7230 规定 request-target 里空格必须百分号编码，
所以请求行按空格切成三段是安全的；**响应行的 reason 是唯一可以合法含空格的第三段**。
这个不对称性值得记住。

### 30.4.2 悬垂切片：返回结构体的所有切片必须同一份所有权

`fetchToEof` 第一版只dupe 了 body：

```zig
// ❌ 第一版（错的）
const parts = try splitHead(raw[0..total]);   // raw 是栈上数组
var rep = try parseStatusLine(parts.head);    // rep.reason 指向 raw
...
rep.body = try a.dupe(u8, parts.body);        // 只有 body 被dupe
return rep;                                    // ← rep.reason 悬垂
```

`rep.reason` 和 `rep.content_type` 仍指向**栈上的 `raw`**。函数一返回，
那两个切片指向已销毁的栈帧。症状特别容易误判：

- `code` 是 `u16`，**按值拷贝**，所以它是对的 → 你会以为解析没问题
- `reason` 是切片，悬垂 → 打印出来是 `404 Not`（" Found" 已被栈内容覆盖）

正确写法是**先 dupe 整个响应，再从副本上解析**，让所有切片字段统一指向同一份所有权：

```zig
// examples/30_http/main.zig 第 703-716 行
    // ⚠️⚠️ **先把整个响应 dupe 进 `a`，再从副本上解析**。
    // 本函数第一版只 dupe 了 body，结果 `Reply.reason` / `content_type`
    // 仍然指向**栈上**的 `raw`——函数一返回它们就是悬垂切片。
    // 症状极阴：`code` 是 u16（按值拷贝，没事），`reason` 是切片（悬垂），
    // 打印出来是 "404 Not" 这种被腰斩的内容——因为栈帧被复写了。
    // **教训：一个返回结构体里的所有切片字段，必须统一指向同一份所有权。**
    const owned = try a.dupe(u8, raw[0..total]);
    const parts = try splitHead(owned);
    var rep = try parseStatusLine(parts.head);
    var ctx = HeadCtx{ .rep = &rep };
    forEachHeader(parts.head, &ctx, onHeader);
    rep.body = parts.body;
    return rep;
}
```

这条纪律和 29 章那条"不要返回指向内部缓冲的切片"是同一件事的两种形态：
29 章是"返回指向自己缓冲的切片"，这里是"返回指向栈帧的切片"。
**共同判据是：返回值的生命周期会不会短于它指向的内存。**

---

## 30.5 路由：精确匹配、前缀匹配、404/405/501

路由查找的关键设计是**返回三态而不是 bool**——这是 404 与 405 的分界线：

```zig
// examples/30_http/main.zig 第 460-506 行
const RouteKind = enum { exact, prefix };

const Route = struct {
    method: []const u8,
    kind: RouteKind,
    path: []const u8,
    name: []const u8,
};

/// 手写路由表。**顺序敏感**：第一条匹配的赢。
/// 前缀路由天然更宽，所以注册顺序直接决定优先级——
/// 想清楚这一点很省事：精确路由注册在动态之前即可。
const routes = [_]Route{
    .{ .method = "GET", .kind = .exact, .path = "/", .name = "home" },
    .{ .method = "GET", .kind = .exact, .path = "/api/rand", .name = "rand" },
    .{ .method = "GET", .kind = .exact, .path = "/api/info", .name = "info" },
    .{ .method = "POST", .kind = .exact, .path = "/api/echo", .name = "echo" },
    // 故意失败的处理器，用来演示 500（见 route 里的说明）
    .{ .method = "GET", .kind = .exact, .path = "/api/boom", .name = "boom" },
    // 前缀路由：`/static/` 开头的任何路径都命中
    .{ .method = "GET", .kind = .prefix, .path = "/static/", .name = "static" },
};

/// 路由查找结果返回**三态**而不是 bool，这是 404 / 405 的分界线：
///
/// - `.none`（没有任何路由的 path 匹配）→ **404** 资源不存在
/// - `.method_mismatch`（path 匹配了但方法不对）→ **405**
///   两者区别是真实的：405 应该带 `Allow` 头告诉客户端"用这些方法重试"；
///   404 则不该泄露"这个路径存在，只是你不能这样访问"。
/// - `.route` → 命中
const Match = union(enum) { route: Route, method_mismatch: bool, none: void };

fn lookup(method: []const u8, path: []const u8) Match {
    var path_seen = false; // 有没有哪个路由的 path 匹配上了（不管方法）
    for (routes) |r| {
        const hit = switch (r.kind) {
            .exact => std.mem.eql(u8, r.path, path),
            .prefix => std.mem.startsWith(u8, path, r.path),
        };
        if (!hit) continue;
        if (std.mem.eql(u8, r.method, method)) return .{ .route = r };
        path_seen = true;
    }
    if (path_seen) return .{ .method_mismatch = true };
    return .none;
}
```

**405 与 404 的区别不是学术洁癖**：405 应该带 `Allow` 头告诉客户端
"用这些方法重试"，而 404 **不该**泄露"这个路径存在，只是你不能这样访问"。
用 bool 的话这两个语义会塌成一个，客户端无法区分"打错字"和"没权限"。

**501 和 405 又不同**：501 是"这个方法我不认识"，来自 `route()` 开头的
**方法白名单**，它在路由查找**之前**：

```zig
// examples/30_http/main.zig 第 508-521 行
fn route(a: std.mem.Allocator, req: *const Request) !Response {
    // 方法白名单先过：不在白名单里 → 501（不是 405：405 说的是"这些方法行"，
    // 501 说的是"这个方法我不认识"）
    if (!isAllowedMethod(req.method)) {
        return .{ .code = 501, .reason = reasonPhrase(501), .body = "method not implemented" };
    }

    switch (lookup(req.method, req.path)) {
        .none => return .{ .code = 404, .reason = reasonPhrase(404), .body = "not found" },
        .method_mismatch => return .{ .code = 405, .reason = reasonPhrase(405), .body = "method not allowed" },
```

**⚠️ 0.17 不能 `switch` 字符串**（`error: cannot switch on strings`），
所以路由名分发只能用 `if + eql` 链：

```zig
// examples/30_http/main.zig 第 519-528 行
        // ⚠️ 0.17 **不能 switch 字符串**（error: cannot switch on strings）。
        // 路由名用 `if + eql` 链分发。枚举化（`enum { home, rand, ... }`）也行，
        // 但注册表和名字都是数据、写成字符串更好读——代价就是这条 if 链。
        .route => |r| {
            if (std.mem.eql(u8, r.name, "home")) {
                return .{ ... };
            }
            if (std.mem.eql(u8, r.name, "rand")) {
```

运行输出（`examples/30_http/main.zig`）

```text
==== 30.5 路由：精确匹配、前缀匹配、404/405 ====
  GET   /                        → 命中 home
  GET   /api/rand                → 命中 rand
  GET   /static/css/main.css     → 命中 static
  GET   /api/echo                → 405 method not allowed
  GET   /nope                    → 404 not found

  405 与 404 的区别是真实的：405 该带 Allow 头说"用这些方法重试"，
  404 不该泄露"这个路径存在，只是你不能这样访问"。
  方法不在白名单（DELETE）走的是 **501**，不是 405：
    lookup 只看已注册路由，DELETE 压根没注册任何 path → 404；
    501 来自 route() 开头的方法白名单，它在路由之前。
==== 30.5 路由：精确匹配、前缀匹配、404/405 结束 ====
```

---

## 30.6 JSON 响应：`Stringify.value` 的 writer 在最后

```zig
// examples/30_http/main.zig 第 1151-1170 行
    begin("30.6 JSON 响应：Stringify.value 的 writer 在最后");
    {
        const Payload = struct { n: u32, values: []const u32, service: []const u8 };
        var jw = std.Io.Writer.Allocating.init(a);
        try std.json.Stringify.value(Payload{ .n = 3, .values = &.{ 7, 8, 9 }, .service = "zhttp" }, .{}, &jw.writer);
        err.print("  签名：Stringify.value(value, options, writer) ← **writer 在最后**\n", .{});
        err.print("  写错顺序的实测报错：\n", .{});
        err.print("    error: expected type 'json.Stringify.Options', found pointer\n", .{});
        err.print("    note: address-of operator always returns a pointer\n", .{});
        err.print("  输出：{s}\n", .{jw.written()});

        var jw2 = std.Io.Writer.Allocating.init(a);
        try std.json.Stringify.value("a\"b\n", .{}, &jw2.writer);
        err.print("  转义：{s}（引号与换行被转义，客户端不用再处理）\n", .{jw2.written()});

        var jw3 = std.Io.Writer.Allocating.init(a);
        try std.json.Stringify.value(.{ .a = 1, .b = "x" }, .{ .whitespace = .indent_2 }, &jw3.writer);
        err.print("  缩进选项 .whitespace = .indent_2：\n    {s}\n", .{jw3.written()});
    }
    end("30.6 JSON 响应：Stringify.value 的 writer 在最后");
```

**参数顺序是 `value(value, options, writer)` —— writer 在最后。**
写成 `value(value, writer, options)` 的实测报错是：

```text
error: expected type 'json.Stringify.Options', found pointer
note: address-of operator always returns a pointer
```

这个报错有点误导：它不说"参数顺序错了"，只说"第二个参数应该是Options 但你给了指针"。
第一次遇到会以为是类型不匹配，实际是**位置**错了。

`Writer.Allocating` 是 JSON 序列化的标配组合：它自己管增长缓冲，
`written()` 给你最终的切片。**注意它分配内存**——所以要传一个生命周期合适的分配器
（这里是每请求 arena，30.7）。

字符串转义是白送的：`"a\"b\n"` 里的引号和换行自动变成 `\"` 和 `\n`，
客户端不需要二次处理。

运行输出（`examples/30_http/main.zig`）

```text
==== 30.6 JSON 响应：Stringify.value 的 writer 在最后 ====
  签名：Stringify.value(value, options, writer) ← **writer 在最后**
  写错顺序的实测报错：
    error: expected type 'json.Stringify.Options', found pointer
    note: address-of operator always returns a pointer
  输出：{"n":3,"values":[7,8,9],"service":"zhttp"}
  转义："a\"b\n"（引号与换行被转义，客户端不用再处理）
  缩进选项 .whitespace = .indent_2：
    {
  "a": 1,
  "b": "x"
}
==== 30.6 JSON 响应：Stringify.value 的 writer 在最后 结束 ====
```

---

## 30.7 keep-alive vs close：两种读法

| | `Connection: close` | `Connection: keep-alive` |
|---|---|---|
| 读法 | 读到 EOF（`fetchToEof`） | 按 `Content-Length` 数字节（`fetchByLength`） |
| 优点 | 不需要信任 CL，对端崩在半路也收到已有字节 | 连接复用（Nginx / 浏览器都走这条） |
| 缺点 | 每请求一次 TCP 三次握手 | CL 写错就错位或挂死，还要处理 pipelining 与空闲超时 |

**`Connection: close` 的意义在于它给了响应一个"自明的结束标记"。**
客户端收到 EOF 就知道响应完整了，不需要解析 `Content-Length` 去计数。
代价是连接不能复用。

`keep-alive` 则相反：连接复用，但**每个响应都必须有准确的 `Content-Length`**，
否则客户端在同一条连接上读第二条响应时就会错位（30.4 的"写小"）。

`main` 的 30.7 节只做对比说明，两个读法在 30.9 各真跑一次：

```zig
// examples/30_http/main.zig 第 1173-1187 行
    begin("30.7 keep-alive vs close：两种读法");
    {
        err.print("  Connection: close\n", .{});
        err.print("    读法：读到 EOF（fetchToEof）\n", .{});
        err.print("    优点：不需要信任 Content-Length，对端崩在半路也收到已有字节\n", .{});
        err.print("    缺点：一条连接一个请求，每次都要 TCP 三次握手\n", .{});
        err.print("  Connection: keep-alive\n", .{});
        err.print("    读法：按 Content-Length 数字节（fetchByLength）\n", .{});
        err.print("    优点：连接复用（Nginx / 浏览器都走这条）\n", .{});
        err.print("    缺点：CL 写错就错位或挂死，还要处理 pipelining 与空闲超时\n", .{});
        err.print("\n  本示例两种都实现，下面 30.9 各跑一次。\n", .{});
        err.print("  真正生产服务还有第三条路：chunked 编码（长度未知时的流式体），\n", .{});
        err.print("  std.http.ChunkParser 就是它——手写版没做，这是省略而非不存在。\n", .{});
    }
    end("30.7 keep-alive vs close：两种读法");
```

**每连接一个 arena** 是这一节的内存姿势：

```zig
// examples/30_http/main.zig 第 839-845 行
    var n: usize = 0;
    while (n < ctx.quota) : (n += 1) {
        var conn = Conn.init(io, server.accept(io) catch return);
        defer conn.close();
        _ = arena_state.reset(.retain_capacity); // retain_capacity：复用已有页
        const a = arena_state.allocator();
```

路由的 JSON 缓冲、`serialize` 的响应缓冲、`Writer.Allocating` 的增长缓冲——
一个请求要分配好几次，全部指向同一个 arena。
`reset(.retain_capacity)` 让它们随连接生死，**比"每处记得 free"的纪律性强一个量级**。
29 章已经把它列为 HTTP 服务的标准内存姿势，本章的 `route()` 直接受益于它：
`route(a, req)` 里的 `Writer.Allocating.init(a)` 不需要任何 free。

测试里也用同一套姿势包一层 `std.testing.allocator`：

```zig
// examples/30_http/main.zig 第 1629-1637 行
/// 测试里 `route`/`parseUrl` 会分配（JSON 缓冲、dupe 出来的字符串）。
/// 用 arena 包一层 `std.testing.allocator`：**泄漏检测依然有效**——
/// `arena.deinit()` 会把底下所有块还给 SafeAllocator，一块漏掉照样报。
/// 但不用为每处 JSON 缓冲写 `defer free`，测试读起来干净得多。
/// 这也正是生产代码里"每请求一个 arena"（30.7）的同一套姿势。
fn testArena() std.heap.ArenaAllocator {
    return std.heap.ArenaAllocator.init(std.testing.allocator);
}
```

运行输出（`examples/30_http/main.zig`）

```text
==== 30.7 keep-alive vs close：两种读法 ====
  Connection: close
    读法：读到 EOF（fetchToEof）
    优点：不需要信任 Content-Length，对端崩在半路也收到已有字节
    缺点：一条连接一个请求，每次都要 TCP 三次握手
  Connection: keep-alive
    读法：按 Content-Length 数字节（fetchByLength）
    优点：连接复用（Nginx / 浏览器都走这条）
    缺点：CL 写错就错位或挂死，还要处理 pipelining 与空闲超时

  本示例两种都实现，下面 30.9 各跑一次。
  真正生产服务还有第三条路：chunked 编码（长度未知时的流式体），
  std.http.ChunkParser 就是它——手写版没做，这是省略而非不存在。
==== 30.7 keep-alive vs close：两种读法 结束 ====
```

---

## 30.8 URL 解析：`std.Uri` 的形状

0.17 有完整的 `std.Uri`，不需要手写。但它的形状和直觉不一样：

```zig
// examples/30_http/main.zig 第 889-918 行
const Url = struct {
    scheme: []const u8,
    host: []const u8,
    port: u16,
    path: []const u8,
    query: []const u8,
};

/// `Uri.Component` 是 `union(enum) { raw, percent_encoded }`。
/// ⚠️ 它**没有 format 方法**——`{f}` 会编译错
/// ("no field or member function named 'format' in 'Uri.Component'")。
/// 要拿字符串只有两条路：`switch` 取 `.raw`/`.percent_encoded`（不解码）
/// 或 `toRawMaybeAlloc(arena)`（只在含 `%` 时才分配，会解码）。
fn uriRaw(c: std.Uri.Component) []const u8 {
    return switch (c) {
        .raw => |r| r,
        .percent_encoded => |r| r,
    };
}

fn parseUrl(a: std.mem.Allocator, text: []const u8) !Url {
    const u = try std.Uri.parse(text);
    const port: u16 = u.port orelse if (std.mem.eql(u8, u.scheme, "http")) 80 else 443;
    return .{
        .scheme = u.scheme,
        .host = if (u.host) |h| a.dupe(u8, uriRaw(h)) catch unreachable else "127.0.0.1",
        .port = port,
        .path = a.dupe(u8, uriRaw(u.path)) catch unreachable,
        .query = if (u.query) |q| a.dupe(u8, uriRaw(q)) catch unreachable else "",
    };
}
```

三个实测要点：

**① `Uri.Component` 没有 `format` 方法。** 字段类型是
`union(enum) { raw: []const u8, percent_encoded: []const u8 }`，
`{f}` 会编译错：

```text
error: no field or member function named 'format' in 'Uri.Component'
note: union declared here
```

取字符串只有两条路：`switch` 手动取（不解码），或者 `toRawMaybeAlloc(arena)`
（会解码，但只在含 `%` 时才分配——没百分号时**返回原切片、零分配**）。
注意 `host` / `query` 是 `?Component`（可选，要 `if (u.host) |h|`），
`path` 是 `Component`（非可选，默认为空）。

**② `std.Uri` 只吃绝对 URL。** 相对引用一律 `error.InvalidFormat`：

**③ `parseIp4` 的错误名不是 `InvalidAddress`。** 三个不同的错误：

```text
999.1.1.1  → error.Overflow
1.2.3      → error.Incomplete
localhost  → error.InvalidCharacter
```

```zig
// examples/30_http/main.zig 第 1190-1210 行
    begin("30.8 URL 解析：std.Uri 的形状");
    {
        const abs1 = try parseUrl(a, "http://127.0.0.1:8080/api/rand?n=5");
        err.print("  http://127.0.0.1:8080/api/rand?n=5\n", .{});
        err.print("    scheme={s} host={s} port={d} path={s} query={s}\n", .{ abs1.scheme, abs1.host, abs1.port, abs1.path, abs1.query });

        const abs2 = try parseUrl(a, "http://example.com/x");
        err.print("  http://example.com/x（无端口）→ port={d}（http 缺省 80）\n", .{abs2.port});

        const abs3 = try parseUrl(a, "http://h/a%20b");
        err.print("  http://h/a%20b（百分号编码）→ path={s}（raw 不解码）\n", .{abs3.path});
        err.print("    要解码用 toRawMaybeAlloc(arena)，它只在含 '%' 时才分配\n", .{});

        const bad_cases = [_][]const u8{ "not a url at all", "/just/a/path", "", "*", "http://h:99999/", "ht tp://x" };
        err.print("  错误实测（std.Uri 只吃**绝对** URL）：\n", .{});
        for (bad_cases) |bad| {
            const code = if (std.Uri.parse(bad)) |_| @as([]const u8, "ok") else |e| @errorName(e);
            err.print("    {s: <22} → {s}\n", .{ bad, code });
        }
```

运行输出（`examples/30_http/main.zig`）

```text
==== 30.8 URL 解析：std.Uri 的形状 ====
  http://127.0.0.1:8080/api/rand?n=5
    scheme=http host=127.0.0.1 port=8080 path=/api/rand query=n=5
  http://example.com/x（无端口）→ port=80（http 缺省 80）
  http://h/a%20b（百分号编码）→ path=/a%20b（raw 不解码）
    要解码用 toRawMaybeAlloc(arena)，它只在含 '%' 时才分配
  错误实测（std.Uri 只吃**绝对** URL）：
    not a url at all       → InvalidFormat
    /just/a/path           → InvalidFormat
                           → InvalidFormat
    *                      → InvalidFormat
    http://h:99999/        → InvalidPort
    ht tp://x              → UnexpectedCharacter
  ⚠️ Uri.Component **没有 format 方法** —— {f} 编译不过：
     error: no field or member function named 'format' in 'Uri.Component'
     取字符串只有两条路：switch .raw/.percent_encoded，或 toRawMaybeAlloc(arena)。
  ⚠️ parseIp4 的错误名也不是 InvalidAddress，实测是：
     999.1.1.1 → Overflow   1.2.3 → Incomplete   localhost → InvalidCharacter
==== 30.8 URL 解析：std.Uri 的形状 结束 ====
```

**`http://h:99999/` 报 `InvalidPort` 而不是 `InvalidFormat`**——端口越界
有专门的错误。写错误断言时别想当然（29 章的 `parseIp4` 也有同类教训）。

---

## 30.9 完整往返：服务端线程 + 客户端请求 + 断言

本章最实的一节：同一进程内起服务端线程，客户端打三个请求（覆盖两种读法 + 带体请求），
每个都断言响应内容与服务端看到的东西。

**端口探测的三条硬约束**（29 章的结论，本章继续遵守）：

```zig
// examples/30_http/main.zig 第 168-192 行
/// 服务端监听器：从 `base` 起**高位非 0** 端口向上扫 `probe_count` 个。
///
/// ⚠️ **绝不能从 0 开始**：0 端口的意思是"让内核挑一个临时端口"，
/// bind 立刻成功，你拿到的是 49152 之类的随机端口——端口冲突不是问题，
/// 问题是**你以为扫了 20 个端口其实一次都没扫**。
///
/// 扫高位（如 48000 起）是为了避开 ephemeral 区间（macOS 默认 49152–65535，
/// Linux 32768–60999），否则"扫 20 个"里可能大部分是别人正在用的端口。
const probe_count = 20;
const port_base = 48011;

fn listenFrom(io: std.Io, base: u16) !struct { server: std.Io.net.Server, port: u16 } {
    var p: u16 = base;
    while (p < base + probe_count) : (p += 1) {
        const addr = try std.Io.net.IpAddress.parseIp4("127.0.0.1", p);
        // `listen` 失败就换下一个端口。失败原因可能是 EADDRINUSE（占了）
        // 也可能是别的，但 20 个连续高位端口全失败基本就是环境问题。
        if (addr.listen(io, .{ .reuse_address = true })) |s| {
            return .{ .server = s, .port = p };
        } else |_| {}
    }
    return error.NoFreePort;
}
```

**服务端线程的关停策略是"服务固定条数后返回"**（29 章结论）：

```zig
// examples/30_http/main.zig 第 818-840 行
/// **服务固定 quota 条连接后返回**——这是 29 章的结论：干完定量就退，
/// 比"标志位 + 强杀"干净得多（没有竞态窗口、没有悬挂句柄），
/// 而且 `join()` 就是同步点，main 不需要任何超时机制。
/// 这样 `./run-all.sh` **不可能挂死**：客户端发够 quota 条就一定收敛。
fn serve(ctx: *ServerCtx) void {
    const io = ctx.io;
    const l = listenFrom(io, port_base) catch {
        std.debug.print("  [server] listen 失败：{d}..{d} 全占\n", .{ port_base, port_base + probe_count });
        return;
    };
    var server = l.server;
    defer server.deinit(io);
    srv_port.store(l.port, .release); // 原子公布实际端口
```

端口是"扫出来的"，所以要用**原子**公布给客户端线程。
`startServer` 把这件事封起来，顺带等端口就位：

```zig
// examples/30_http/main.zig 第 929-940 行
/// 起一个只服务 quota 条连接的服务端线程，等它把端口敲定，返回端口。
fn startServer(io: std.Io, quota: usize, limits: Limits, bad_length: ?usize, ctx: *ServerCtx) !std.Thread {
    ctx.io = io;
    ctx.quota = quota;
    ctx.limits = limits;
    ctx.bad_length = bad_length;
    srv_port.store(0, .release);
    const th = try std.Thread.spawn(.{}, serve, .{ctx});
    while (srv_port.load(.acquire) == 0) std.Thread.yield() catch {};
    return th;
}
```

三个往返，每次**独立起一个服务端**（`quota = 1`）——这样每次往返都是干净的，
一个失败不影响后面的：

```zig
// examples/30_http/main.zig 第 1218-1266 行
    begin("30.9 完整往返：服务端线程 + 客户端请求 + 断言");
    {
        // 往返 1：GET / —— 读到 EOF
        var ctx: ServerCtx = .{};
        const th = try startServer(io, 1, .{}, null, &ctx);
        const port = srv_port.load(.acquire);
        err.print("  服务端就绪 127.0.0.1:{d}（从 {d} 起扫 {d} 个高位端口）\n", .{ port, port_base, probe_count });

        const home = try fetchToEof(a, io, port, "GET", "/", "");
        err.print("\n  GET /（读到 EOF）→ {d} {s}，体 {d} 字节\n", .{ home.code, home.reason, home.body.len });
        err.print("    {s}\n", .{home.body});
        try expectEq(@as(u16, 200), home.code);
        try expectContains(home.body, "zhttp");
        th.join();
        try expectEq(@as(usize, 1), ctx.served.load(.acquire));

        // 往返 2：GET /api/rand?n=5 —— 按 Content-Length 读
        var ctx2: ServerCtx = .{};
        const th2 = try startServer(io, 1, .{}, null, &ctx2);
        const port2 = srv_port.load(.acquire);
        const rnd = try fetchByLength(a, io, port2, "GET", "/api/rand?n=5");
        err.print("\n  GET /api/rand?n=5（按 Content-Length={d} 读）→ {d} {s}\n", .{ rnd.content_length.?, rnd.code, rnd.reason });
        err.print("    {s}\n", .{rnd.body});
        try expectEq(@as(u16, 200), rnd.code);
        try expectContains(rnd.body, "\"values\"");
        try expectContains(rnd.body, "\"service\":\"zhttp\"");
        try expectEq(@as(usize, 1), ctx2.served.load(.acquire));
        // GET 没有 Content-Length → 服务端看到的体是空的（这是 30.3 的断言，
        // 放到真实 socket 上再验一次）
        try expectEq(@as(usize, 0), ctx2.seen_body_len.load(.acquire));
        th2.join();

        // 往返 3：POST /api/echo —— 请求带体，验证"按 Content-Length 读体"
        var ctx3: ServerCtx = .{};
        const th3 = try startServer(io, 1, .{}, null, &ctx3);
        const port3 = srv_port.load(.acquire);
        const echo = try fetchToEof(a, io, port3, "POST", "/api/echo", "hello");
        err.print("\n  POST /api/echo，体 \"hello\" → {d} {s}\n", .{ echo.code, echo.reason });
        err.print("    {s}\n", .{echo.body});
        try expectEq(@as(u16, 200), echo.code);
        try expectContains(echo.body, "\"body\":\"hello\"");
        // 服务端确实按 Content-Length 收到了 5 字节
        try expectEq(@as(usize, 5), ctx3.seen_body_len.load(.acquire));
        try expectEqualStrings("POST", std.mem.sliceTo(&ctx3.seen_method, 0));
        th3.join();
```

**断言分两侧**：客户端侧断言 `code` / `body` 里有标记，
服务端侧断言 `served` 计数 / `seen_method` / `seen_body_len`。
后者尤其重要——它证明服务端**真的**按 `Content-Length` 读到了 5 字节体，
而不是碰巧回了个对的 JSON。客户端看到的对不代表服务端做对了。

运行输出（`examples/30_http/main.zig`）

```text
==== 30.9 完整往返：服务端线程 + 客户端请求 + 断言 ====
  服务端就绪 127.0.0.1:48011（从 48011 起扫 20 个高位端口）
  [server] GET / → 200 OK（体 83 字节，Content-Length=83）

  GET /（读到 EOF）→ 200 OK，体 83 字节
    <h1>zhttp</h1><p>routes: / /api/rand?n= /api/info /api/echo /api/boom /static/*</p>
  [server] GET /api/rand → 200 OK（体 51 字节，Content-Length=51）

  GET /api/rand?n=5（按 Content-Length=51 读）→ 200 OK
    {"n":5,"values":[30,25,50,76,67],"service":"zhttp"}
  [server] POST /api/echo → 200 OK（体 64 字节，Content-Length=64）

  POST /api/echo，体 "hello" → 200 OK
    {"method":"POST","path":"/api/echo","body_len":5,"body":"hello"}

  ✓ 全链路：解析请求 → 路由 → 序列化响应 → 客户端解析，三个断言全过。
  ✓ 服务端各服务 1 条连接即退（quota），join() 即同步——不会挂死。
==== 30.9 完整往返：服务端线程 + 客户端请求 + 断言 结束 ====
```

`{"n":5,"values":[30,25,50,76,67],...}` 里的随机数是**可复现**的——
`DefaultPrng.init(0xF00D)` 用了固定种子。测试与文档都需要这个性质。

---

## 30.10 错误处理：404 / 405 / 501 / 畸形头 / 超长行

**错误处理的第一原则：解析失败也要回一个带状态码的响应。**
静默 `close` 的话客户端只看到"空响应"，排查时完全看不出发生过什么。

```zig
// examples/30_http/main.zig 第 846-874 行
        const req = parseRequest(Conn, &conn, &ctx.scratch, &ctx.head_buf, &ctx.body_buf, ctx.limits) catch |err| {
            // 解析失败：回一个状态码明确的错误响应，**别静默关连接**
            // （客户端只看到"空响应"，排查时完全看不出发生过什么）。
            const code: u16 = switch (err) {
                error.LineTooLong, error.TooManyHeaders => 431,
                error.BodyTooLarge => 413,
                error.ConnectionClosed => 0, // 对端自己跑了，别回包（回包会 EPIPE）
                else => 400,
            };
            if (code != 0) {
                var rep = Response{ .code = code, .reason = reasonPhrase(code), .body = @errorName(err) };
                if (ctx.bad_length) |bad| rep.content_length_override = bad;
                const raw = serialize(a, &rep) catch return;
                conn.sendAll(raw) catch return;
                std.debug.print("  [server] 解析失败 → {d} {s}（{s}）\n", .{ code, rep.reason, @errorName(err) });
            }
            continue;
        };

        var rep = route(a, &req) catch |err| blk: {
            // 路由处理函数出错 → **500，不是崩溃**。这是"每请求一个 arena +
            // catch 兜底"的标准姿势：单个坏请求不该带走整个服务。
            std.debug.print("  [server] 路由异常 → 500（{s}）\n", .{@errorName(err)});
            break :blk Response{ .code = 500, .reason = reasonPhrase(500), .body = "internal error" };
        };
```

三处细节值得单独拎出来：

**① `error.ConnectionClosed => 0` 这个特例。** 对端自己跑了（探测端口的
健康检查、或者客户端超时报错后断开），此时回包会 `EPIPE`。
所以状态码 0 表示"不回包，直接关"。

**② 500 靠 `return error.HandlerFailed`，不是靠 panic。**
路由 `/api/boom` 的处理器故意返回一个error，`serve` 的 `catch` 把它变成 500。
**整个进程毫发无伤，下一个连接还能正常服务。**
用 panic 就不是错误处理了——那会带走整个进程，一次坏请求搞挂整个服务。

**③ 解析错误 vs 路由错误走不同的码。** 解析层错误是 400/413/431
（请求本身不合法），路由层的 404/405/501 是"请求合法但没这个资源/方法"。
把它们混成一个 500 会让客户端无法区分"我写错了"和"服务器坏了"。

**客户端侧还要防一类错误：超长请求行、畸形头行。**
这些必须用裸 TCP 发（走 `fetchToEof` 的话请求是格式化出来的，造不出畸形）：

```zig
// examples/30_http/main.zig 第 1270-1318 行
    begin("30.10 错误处理：404 / 405 / 501 / 畸形头 / 超长行");
    {
        // 路由层的错误：每一个用独立的一次连接（quota=1）
        const cases = [_]struct { m: []const u8, t: []const u8, label: []const u8, expect: u16 }{
            .{ .m = "GET", .t = "/nope", .label = "路径不存在", .expect = 404 },
            .{ .m = "GET", .t = "/api/echo", .label = "path 存在方法不对", .expect = 405 },
            .{ .m = "DELETE", .t = "/", .label = "方法不在白名单", .expect = 501 },
            .{ .m = "GET", .t = "/static/css/a.css", .label = "前缀路由命中", .expect = 200 },
        };
        for (cases) |c| {
            var ctx: ServerCtx = .{};
            const th = try startServer(io, 1, .{}, null, &ctx);
            const p = srv_port.load(.acquire);
            const rep = try fetchToEof(a, io, p, c.m, c.t, "");
            th.join();
            // ⚠️ 0.17 的 `{s:<N}` 是**截断**到 N 字节，不是"至少 N 宽"的最小宽度——
            // "Not Found" 写成 `{s: <26}` 会被腰斩成 "Not"。要最小宽度就别加 `<`。
            err.print("  {s: <7} {s: <22} → {d} {s}  体={s}\n", .{ c.m, c.label, rep.code, rep.reason, rep.body });
            try expectEq(c.expect, rep.code);
        }

        // 解析层的错误：裸 TCP 发畸形请求，看服务端回什么
        const malformed = [_]struct { raw: []const u8, label: []const u8, expect: u16 }{
            .{ .raw = "GET / HTTP/1.1 extra\r\nHost: x\r\n\r\n", .label = "请求行四个分段", .expect = 400 },
            .{ .raw = "GET /\r\n\r\n", .label = "请求行只有两段", .expect = 400 },
            .{ .raw = "GET / SPDY/3\r\n\r\n", .label = "版本号不对", .expect = 400 },
            .{ .raw = "GET / HTTP/1.1\r\nBADHEADER\r\n\r\n", .label = "头部行无冒号", .expect = 400 },
            .{ .raw = "GET / HTTP/1.1\r\nContent-Length: 999999\r\n\r\n", .label = "体超上限", .expect = 413 },
            .{ .raw = "GET /aaaa...", .label = "请求行 120 字符 >上限 64", .expect = 431 },
        };
        for (malformed) |m| {
            var ctx: ServerCtx = .{ .limits = .{ .line = 64 } };
            const th = try startServer(io, 1, ctx.limits, null, &ctx);
            const p = srv_port.load(.acquire);
            var conn = Conn.init(io, try connectTo(io, p));
            try conn.sendAll(m.raw);
            var buf: [512]u8 = undefined;
            const n = try conn.recvSome(&buf);
            conn.close(); // 显式关；**不能**再 defer close（Stream.close 不幂等）
            th.join();
            err.print("  {s: <20} → {s}\n", .{ m.label, firstLine(buf[0..n]) });
            try expect(containsCode(buf[0..n], m.expect));
        }
```

**⚠️ 这里的 `{s:<N}` 是个 0.17 的实测行为**：
它是**截断**到 N 字节，不是"至少 N 宽"的最小宽度。
本节第一版把 reason 写成 `{s: <26}`，结果 `Not Found` 被腰斩成 `Not`——
和 30.4.1 的`tokenizeScalar` 那个 bug 叠在一起，排查时容易误以为是同一个原因。
要"最小宽度"就别加 `<`。

运行输出（`examples/30_http/main.zig`）

```text
==== 30.10 错误处理：404 / 405 / 501 / 畸形头 / 超长行 ====
  [server] GET /nope → 404 Not Found（体 9 字节，Content-Length=9）
  GET     路径不存在        → 404 Not Found  体=not found
  [server] GET /api/echo → 405 Method Not Allowed（体 18 字节，Content-Length=18）
  GET     path 存在方法不对 → 405 Method Not Allowed  体=method not allowed
  [server] DELETE / → 501 Not Implemented（体 22 字节，Content-Length=22）
  DELETE  方法不在白名单  → 501 Not Implemented  体=method not implemented
  [server] GET /static/css/a.css → 200 OK（体 21 字节，Content-Length=21）
  GET     前缀路由命中     → 200 OK  体={"n":1,"head":"1..."}
  [server] 解析失败 → 400 Bad Request（MalformedRequestLine）
  请求行四个分段 → HTTP/1.1 400 Bad Request
  [server] 解析失败 → 400 Bad Request（MalformedRequestLine）
  请求行只有两段 → HTTP/1.1 400 Bad Request
  [server] 解析失败 → 400 Bad Request（MalformedRequestLine）
  版本号不对      → HTTP/1.1 400 Bad Request
  [server] 解析失败 → 400 Bad Request（MalformedHeader）
  头部行无冒号   → HTTP/1.1 400 Bad Request
  [server] 解析失败 → 413 Payload Too Large（BodyTooLarge）
  体超上限         → HTTP/1.1 413 Payload Too Large
  [server] 解析失败 → 431 Request Header Fields Too Large（LineTooLong）
  请求行 120 字符 >上限 64 → HTTP/1.1 431 Request Header Fields Too Large

  关键设计：解析失败**也要回一个带状态码的响应**。
  静默 close 的话客户端只看到"空响应"，排查时完全看不出发生过什么。
  唯一例外是对端自己跑了（ConnectionClosed）——回包会 EPIPE。
==== 30.10 错误处理：404 / 405 / 501 / 畸形头 / 超长行 结束 ====
```

**这一节的输出同时暴露了本章 CRLF 那个 bug 的现场**：
如果 `recvLine` 只吃 `'\r'`，上面每一行都会变成
`解析失败 → 400 Bad Request（MalformedHeader）`——
六个用例全部报同一个错，而不是各自不同的码。这就是它的特征。

---

## 30.11 生产环境：`std.http.Client` / `Server` 实测存在

**实测结论：0.17 的 `std.http` 是完整的。** 不只是 `Client`/`Server`，
`HeadParser` / `ChunkParser` / `HeaderIterator` 都在：

```zig
// examples/30_http/main.zig 第 1321-1341 行
    begin("30.11 生产环境：std.http.Client / Server 实测存在");
    {
        err.print("  std.http.Client 存在 = {}\n", .{@hasDecl(std.http, "Client")});
        err.print("  std.http.Server  存在 = {}\n", .{@hasDecl(std.http, "Server")});
        err.print("  其它部件：HeadParser={} ChunkParser={} HeaderIterator={}\n", .{
            @hasDecl(std.http, "HeadParser"),
            @hasDecl(std.http, "ChunkParser"),
            @hasDecl(std.http, "HeaderIterator"),
        });
        err.print("  Client 关键方法：fetch={} request={} connect={} initDefaultProxies={}\n", .{
            @hasDecl(std.http.Client, "fetch"),
            @hasDecl(std.http.Client, "request"),
            @hasDecl(std.http.Client, "connect"),
            @hasDecl(std.http.Client, "initDefaultProxies"),
        });
        err.print("  Server 关键方法：init={} receiveHead={} Request={} WebSocket={}\n", .{
            @hasDecl(std.http.Server, "init"),
            @hasDecl(std.http.Server, "receiveHead"),
            @hasDecl(std.http.Server, "Request"),
            @hasDecl(std.http.Server, "WebSocket"),
        });
```

运行输出（`examples/30_http/main.zig`）

```text
==== 30.11 生产环境：std.http.Client / Server 实测存在 ====
  std.http.Client 存在 = true
  std.http.Server  存在 = true
  其它部件：HeadParser=true ChunkParser=true HeaderIterator=true
  Client 关键方法：fetch=true request=true connect=true initDefaultProxies=true
  Server 关键方法：init=true receiveHead=true Request=true WebSocket=true
  std.http.Method（10 个）： GET HEAD POST PUT DELETE CONNECT OPTIONS TRACE PATCH QUERY
  std.http.Status 有 62 个成员（含 teapot / loop_detected / im_used…）
  fetch 的返回：FetchResult = { .status: http.Status }

  ⇒ 生产环境该用 std.http：它已经处理了keep-alive 连接池、重定向、
    chunked 编码、gzip/zstd 解压、TLS、超时。
  ⇒ 本章手写版只为了让你看懂报文——**两者处理的是同一个协议**，
    不是两种协议。框架没魔法，只是把这些边界替你写了。
==== 30.11 生产环境：std.http.Client / Server 实测存在 结束 ====
```

### 30.11.1 那"生产环境不要自己写 HTTP"到底指什么

`std.http.Client.fetch` 的签名（实测）：

```zig
// std/http/Client.zig 第 1807 行（0.17.0）
pub fn fetch(client: *Client, options: FetchOptions) FetchError!FetchResult
```

`FetchOptions` 里有 `redirect_behavior`、`keep_alive`、`response_writer`、
`headers`、`payload`……`FetchResult` 只有 `{ .status: http.Status }`。
`Client` 内部有 `ConnectionPool`（第 65 行）管连接复用。
`Server` 那侧有 `receiveHead()` 和 `Request.respond()`。

对照本章手写的东西，缺的不是"协议正确性"，而是**边界情况的长尾**：

| 手写版要处理的 | `std.http` 里的对应 |
|---|---|
| keep-alive + 连接池 | `Client.ConnectionPool` |
| chunked 编码（长度未知的流式体） | `http.ChunkParser` |
| gzip / deflate / zstd 解压 | `fetch` 的 `decompress_buffer` + `readerDecompressing` |
| 重定向（301/302/307/308） | `FetchOptions.redirect_behavior` |
| 超时与取消 | `Io` 的取消模型 |
| 百分号编码的路径归一化 | `Uri.Component` + `toRawMaybeAlloc` |
| Host 头虚拟主机路由 | `Request` 的 host 处理 |

**本章手写的价值不在于"能替代 std.http"，而在于让你看懂这些边界在解决什么。**
亲手踩过 CRLF、`Content-Length`、悬垂切片之后，
再读`std.http` 的源码时你知道每一行为什么长那样。

**换句话说**：写一次是为了读懂，不是为了上线。

---

## 30.12 坑位清单

1. **`recvLine` 必须吃掉 CRLF 两个字节，只吃 `'\r'` 会让头部解析整个失效。** 本章最大的坑。残留的 `'\n'` 让"空行"读出来长度是 1 而不是 0，于是 `if (hl.len == 0) break;` 永远不成立，头部循环一路读到 `LineTooLong`。**特征症状**：所有请求都报同一个 `MalformedHeader`，代码看起来完全正确。

2. **`line_buf` 复用导致 `req.method` 变成 `"Hos"`。** 请求行和所有头部行共用一块缓冲、每读一行就从头覆盖 → 首行的切片被后续行改写，所有头的 name/value 也都指向最后一行。**修法**：bump 区（`used` 单调递增，写过的字节永不被覆盖）。**测试里这条是稳定复现的**（`expected "GET", found "Hos"`），不 flaky——所以它比悬垂切片更值得优先发现。

3. **reason phrase 被吃掉半截——两个独立原因叠在一起。** ① `tokenizeScalar(.., ' ')` 只拿到第一个词：`HTTP/1.1 404 Not Found` 切出`Not`，`Found` 被静默丢掉（修法：第二个空格之后的整段）。② **`{s:<N}` 在 0.17 是截断到 N 字节，不是最小宽度**——`"Not Found"` 写成 `{s: <26}` 同样变成 `Not`（要"至少 N 宽"就别加 `<`）。两个原因叠在同一个输出上，**只修一个仍然看到 `404 Not`**，极易误判成没修干净。

4. **返回结构体里的所有切片字段必须统一指向同一份所有权。** `fetchToEof` 只 dupe 了 body，`reason`/`content_type` 仍指向栈上的 `raw` → 函数一返回就悬垂。症状极阴：`code` 是 `u16`（按值拷贝，没事），`reason` 是切片（悬垂、被腰斩）。**修法**：先 dupe 整个响应，再从副本解析。

5. **`Content-Length` 写错全部由客户端承担，且服务端日志一切正常。** 写大 → 客户端等不到剩余字节，若连接不 close（keep-alive）就**永久挂死**；写小 → **静默截断，连错误都没有**，JSON 在半路炸而栈指向客户端。唯一正确算法是 `body.len`；另一条正确姿势是 `Connection: close` + 读到 EOF。

6. **`Content-Length` 是对端说了算的数字，不 clamp 就是把分配决策权交给陌生人。** `Limits.body` 是必须的，不是可选的防御。同理 `line`（防超长请求行 OOM）和 `headers`（防一万个 `X-Header`）。⚠️ **上限之间会互相干扰**：`scratch` 必须 ≥ `(headers + 2) * line`，否则 `headers` 上限形同虚设（30.3 实测：20 个头先撞 `LineTooLong` 而不是 `TooManyHeaders`）。

7. **`parseRequest` 写成 `comptime C: type` 泛型，测试才能零 IO。** 任何有 `recvLine`/`recvExact` 的类型都能驱动它——真实连接 `Conn`，测试用 `FixedConn`。⚠️ **`FixedConn.recvExact` 必须与 `Conn.recvExact` 同语义**（读满才成功），返回一个短计数会让"体被截断"这种 bug 在测试里伪装成成功。

8. **`tokenizeSequence` 会跳过空段**，所以观察"头部结束的空行"不能用它，必须手工 `indexOf` + 切片。体（`hello`）后面没有 CRLF，**它不是行**。

9. **`Stream.close` 不幂等：显式 `close()` 之后别再 `defer close`。** 第二次报 BADF（`Threaded.zig` 里是 `recoverableOsBugDetected`）。要么全用 `defer`，要么全显式。30.10 的畸形请求用例就是显式关的。

10. **`Stream.read(io, [][]u8)` 在 0.17.0 编译不过**（标准库自己的 bug，`lib/std/Io/net.zig:1286`："type 'Io.net.Stream.ReadResult' cannot be destructured"）。⚠️ 29 章的 `Stream.read` 也用它，所以**整条路都走不通**——读路径一律 `stream.reader(io, buf)`。

11. **端口探测绝不能从 0 起。** 0 端口的意思是"让内核挑临时端口"，`bind` 立刻成功拿到 49152 之类的随机端口——端口冲突不是问题，**问题是"你以为扫了 20 个端口其实一次都没扫"**。本章从 48011 起扫 20 个，避开 ephemeral 区间（macOS 49152–65535 / Linux 32768–60999）。
12. **`std.Uri` 的形状有三处与直觉不符。** ① **`Uri.Component` 没有 `format` 方法**，`{f}` 编译不过（"no field or member function named 'format' in 'Uri.Component'"），取字符串只有 `switch` 手动取或 `toRawMaybeAlloc(arena)`；⚠️ `host`/`query` 是 `?Component`（要 `if (u.host) |h|`），`path` 是非可选的 `Component`。② **`std.Uri` 只吃绝对 URL**，相对引用一律 `error.InvalidFormat`（连 `"not a url at all"`、`""`、`"*"` 都是这个错），⚠️ **端口越界是单独的 `error.InvalidPort`**，写错误断言时别想当然。③ **`parseIp4` 的错误名不是 `InvalidAddress`**，实测是三个不同的错误：`999.1.1.1 → Overflow`、`1.2.3 → Incomplete`、`localhost → InvalidCharacter`。

13. **`json.Stringify.value(value, options, writer)` 的 writer 在最后。** 写成 `value(value, writer, options)` 的报错是"expected type 'json.Stringify.Options', found pointer"——只说类型不符、不说位置错，第一次遇到会以为类型问题。

14. **0.17 的三处语言/类型层硬限制，本章都撞到了。** ① **不能 `switch` 字符串**（"cannot switch on strings"），路由名分发只能用 `if + eql` 链。② **`catch |e| e` 的类型是 `anyerror || Request`**（错误联合与结构体不能统一），别想把"成功值"和"错误"塞进同一个联合让 `print` 统一处理——必须像 `errNameOf` 那样在函数里就把成功分支塌成字符串。③ **`**` 运算符已移除，且 `++` 要求两边都是 comptime 已知切片**，造超长测试输入只能自己 `memcpy` 拼。

15. **测试里给 `route`/`parseUrl` 用 arena 包一层 `std.testing.allocator`。** 泄漏检测依然有效（`arena.deinit()` 把块还给 SafeAllocator），但不用为每处 JSON 缓冲写 `defer free`。这和生产里"每请求一个 arena"是同一套姿势。

---

## 30.13 本章的验证方式

```
$ ZIG=/path/to/zig-0.17.0/zig ./run-all.sh 30_http
[Toolchain] /path/to/zig-0.17.0/zig (0.17.0)

[Example] 30_http
1/25 main.test.请求行解析：方法/目标/版本/path/query 切分...OK
2/25 main.test.请求头：大小写不敏感 + 冒号后空白被剔除 + Connection: close...OK
3/25 main.test.GET 无 Content-Length 时体为空...OK
4/25 main.test.状态机拒绝：畸形请求行（四段/ 两段 / 版本错）...OK
5/25 main.test.上限一：请求行超 line 上限...OK
6/25 main.test.状态机拒绝：头部无冒号 / Content-Length 非法...OK
7/25 main.test.上限二：头部行数超 headers 上限...OK
8/25 main.test.上限三：Content-Length 超 body 上限...OK
9/25 main.test.对端提前关闭 → ConnectionClosed...OK
10/25 main.test.查询参数：多键 / 空值 / 缺省...OK
11/25 main.test.响应序列化：状态行 + CL 算对 + close 头...OK
12/25 main.test.响应序列化：keep-alive 时无 close 头...OK
13/25 main.test.Content-Length 写大 → 客户端按 CL 要 20 字节，实际只有 5...OK
14/25 main.test.Content-Length 写小 → 客户端静默截断（更隐蔽）...OK
15/25 main.test.路由：精确 / 前缀 / 405 / 404...OK
16/25 main.test.路由：501 来自方法白名单，在路由之前...OK
17/25 main.test.路由：JSON 响应体正确（含 clamp 与 parseInt 失败兜底）...OK
18/25 main.test.路由：POST /api/echo 回显体...OK
19/25 main.test.路由：/api/boom 返回 error，由 serve 的 catch 变成 500...OK
20/25 main.test.URL 解析：绝对 URL / 缺省端口 / 错误集...OK
21/25 main.test.parseIp4 的三个错误名实测：Overflow / Incomplete / InvalidCharacter...OK
22/25 main.test.std.http.Client / Server 在 0.17 存在...OK
23/25 main.test.方法白名单区分大小写...OK
24/25 main.test.reasonPhrase 覆盖本章用到的全部状态码...OK
25/25 main.test.探针端口从高位非 0 起（30.x 的硬性约束）...OK
All 25 tests passed.
...
自检通过

[Done] 30_http 验证通过。
```

**25 个测试全部零 IO**——没有一个 `sleep`、没有一个真实socket。
解析状态机靠 `FixedConn`（固定字节），路由/序列化/URL 靠纯函数。
真实 socket 的往返只在 `main` 里跑（30.9 / 30.10），因为那验证的是
"两端的实现能不能对上"，不属于单元测试的职责。

**为什么不会挂死**：服务端线程 `serve` 服务固定 `quota` 条连接后`return`，
`quota=1` 意味着"服务一条就走"。客户端每个用例独立起一个服务端，
发完请求就 `join()`。整个流程是有限状态机——**没有等待条件不确定的地方**。
唯一会阻塞的 `fillMore` 也都由 `Connection: close` 保证对端一定关闭。

---

上一章：[29 TCP 与 UDP](29-networking.md) · 下一章：[31 并发进阶](31-concurrency.md)