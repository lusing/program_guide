# Zig 教程书本扩充实施计划（2026-09-30）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 参考三本书（Learning Zig / Systems Programming with Zig / Zig Programming for Developers），把 `zig/` 从 24 章扩到 **34 章**（新增 25–34 共 10 章、10 个新示例），补齐二进制/编码/目录/文件监视/网络/HTTP/并发进阶/SQLite/解释器/缓存服务器十大缺口，全部在 Zig 0.16.0 实测。

**Architecture:** 先扩示例后写正文（沿用 2026-09-17 重写的流程）。每章 = `examples/NN_topic/`（main 演示 + test 自检，`// ═══ N.M` 分节）+ `docs/NN-topic.md`（150–250 行 + 坑位清单 + 章末导航）。最后统一更新 build.ps1 特判、README、CHEATSheet、根 README、24 章尾导航，全量终验。

**Tech Stack:** Zig 0.16.0（`G:\scoop\apps\zig\current\zig.exe`）、PowerShell 7、git。

**取材（已解包至 `zig/.books/`，git 已忽略）：**

| 书 | 版本基线 | 用途 |
|---|---|---|
| Systems Programming with Zig (Tsoukalos) | **0.16 / std.Io 同代**（echo 代码即 `std.process.Init` + `std.Io.net`） | 主料：ch3 二进制、ch4 流/编码、ch5 目录/监视、ch6 网络/HTTP、ch8 并发、ch10 缓存、ch11 SQLite、ch12 DSL |
| Learning Zig (Rios) | 0.13/0.14 旧 API（GPA/managed ArrayList） | 思想与结构：错误处理哲学、doctest（0.16 实测无→坑位）、mmap、comptime 反射、FileGuard 项目、build 深水 |
| Zig Programming for Developers (Sprinter) | 科普级、代码块极少 | 仅主题清单核对（并发/并行/元编程/嵌入式/Web 已被前两本+新章覆盖） |

## Global Constraints

- 编译器固定 `G:\scoop\apps\zig\current\zig.exe`（0.16.0）；所有代码实测通过才算数。
- 每个新示例三层验证：`zig fmt --check .` + `zig test main.zig`（32 章 + DLL 实参）+ `zig build-exe` 运行 **exit 0**。网络/服务器示例必须**自演**（自带客户端或子进程，跑完断言退出），不许挂住。
- 章号 = 示例目录号；正文摘录示例代码须与 `═══` 分节一致；输出示例来自真实运行。
- 正文中文；每章末尾坑位清单 3–6 条；上一章/下一章导航链接。
- `zig/.books/` 不入库（.gitignore 已建）。
- 提交信息末尾 `Co-Authored-By: Claude Code <noreply@anthropic.com>`。
- 计划内代码是最佳草案，执行时以实测为准修正，偏差记录到文末"执行勘误"。

## 已实测的 0.16 API 基线（本计划新增部分）

| 用法 | 结论 |
|---|---|
| TCP 服务端 | `IpAddress.parseIp4("127.0.0.1", port)` → `address.listen(io, .{})` → `Server`；`server.deinit(io)` |
| TCP 客户端 | `address.connect(io, .{})` → `Stream`；`stream.reader(io, &buf)` / `stream.writer(io, &buf)` |
| UDP | `address.bind(io, .{})` → `Socket`；`socket.send(io, &dest, data)`；`socket.receive(io, buf) → IncomingMessage`（`.address`/`.data`） |
| http | `std.http.Server.init(&in_reader, &out_writer).receiveHead()` → `request.head.target` → `request.respond(.{...})`（挂 TCP Stream 的 reader/writer 上） |
| SQLite 直链 | `zig build-exe main.zig C:\Windows\System32\winsqlite3.dll` ✅ 实测输出 3.51.1；winsqlite3.dll 常驻 System32（PATH 必达） |
| doctest | ❌ 0.16.0 编译器无 doctest（`zig test` 对文档注释示例 `All 0 tests passed`）→ 15 章坑位 |
| 目录监视 | std 无跨平台 watch，`std.os.windows` 无 ReadDirectoryChangesW 声明 → 手写 `extern "kernel32"`（28 章，17 章 extern 进阶） |
| 并发原语 | `std.Thread.Mutex/Condition/RwLock`（无 io 参数）与 `std.Io.Semaphore`（带 io）并存；无 WaitGroup（join 即同步，19 章已踩） |
| `@Vector` | SIMD 章素材：`@Vector(16, u8)` 比较 + `@reduce(.Add, ...)` |

---

### Task 1: 示例 25_binary + 26_encoding（纯逻辑批）

**Files:** Create `zig/examples/25_binary/`, `zig/examples/26_encoding/`

- [ ] 25_binary：extern struct（C ABI）/packed struct/`@bitCast`/`std.mem.bytesToValue`/`std.mem.readInt`（大小端）/comptime `@sizeOf` 断言；解析手工构造的 WAV(RIFF) 头 + 简化 ELF 魔数检查；坑位：对齐、packed 字段不可取址、extern 与普通 struct 布局差异。
- [ ] 26_encoding：`std.base64` 编解码 + 手写 base64 表（教学）/`std.fmt.bytesToHex`；分块流式（固定缓冲循环）对比一次性；`@Vector(16,u8)` SIMD 词/字符计数 vs 标量；roundtrip 测试。

### Task 2: 示例 27_tree + 28_watch（文件系统批）

**Files:** Create `zig/examples/27_tree/`, `zig/examples/28_watch/`

- [ ] 27_tree：递归遍历（`.iterate=true` 坑 24 章已踩）+ `File.Stat`（size/mtime）+ 通配符过滤 + du 汇总 + 排序输出；ztree 树形可视化；tmpDir 确定性测试。
- [ ] 28_watch：轮询核（扫描 path→(size,mtime) 快照求差集 → created/modified/removed 事件）+ Windows 原生 `extern ReadDirectoryChangesW` 变体；自演：watcher 线程 + writer 线程按脚本建/改/删文件，收齐预期事件数退出 0（总时长 ~1–2s）。

### Task 3: 示例 29_netecho + 30_http（网络批）

**Files:** Create `zig/examples/29_netecho/`, `zig/examples/30_http/`

- [ ] 29_netecho：TCP echo（server 线程 accept 循环 + 主线程客户端收发断言）+ UDP echo（bind/send/receive）；端口用 0 绑定取 `getPort()` 避冲突；优雅关停（flag + 连接数归零）。
- [ ] 30_http：TCP accept → `std.http.Server` 路由 `/`(HTML) `/api/rand`(JSON) `/api/info`(JSON)；`std.json.stringify` 响应；客户端用 `std.http.Client` 回环自取断言（若 Client API 0.16 形态不配合，回退裸 TCP 发 HTTP 请求文本——正文照实教）。

### Task 4: 示例 31_concurrency（并发进阶）

**Files:** Create `zig/examples/31_concurrency/`

- [ ] `std.atomic.Value`（fetchAdd/cmpxchgWeak/order 概念）/`RwLock` 读多写少/`Condition` 有界队列生产者-消费者/固定线程池 + 哨兵关停；演示"无锁计数丢更新 vs 原子修复"对照；确定性断言（结果排序后与串行基线一致）。

### Task 5: 示例 32_sqlite（C 互操作实战）

**Files:** Create `zig/examples/32_sqlite/`

- [ ] extern 声明 sqlite3_open_v2/prepare_v2/bind_*/step/column_*/finalize/close/errmsg/libversion；Zig 风格包装（error union + defer）；`:memory:` 单测不碰盘；comptime `@typeInfo` 行→struct 映射器；znote CLI（add/list/find/del）；build 特判加 winsqlite3.dll 实参。

### Task 6: 示例 33_zcalc + 34_zcache（实战工程批）

**Files:** Create `zig/examples/33_zcalc/`, `zig/examples/34_zcache/`

- [ ] 33_zcalc：手写 lexer → Pratt 解析器 → tagged union AST → 树遍求值 + 变量环境 + 内建函数；REPL（stdin 非 tty 时整读逐行 eval）；带位置的错误信息；纯逻辑全单测。
- [ ] 34_zcache：LRU（AutoHashMap + 侵入式双向链表）+ 容量淘汰 + TTL；TCP 文本协议（GET/SET/DEL/STATS）服务器线程 + 自带 bench/断言客户端；Mutex 保护共享态；e2e 断言退出 0。

### Task 7: docs/25–30 章

- [ ] 六章正文（各 150–250 行，结构对齐既有章：NN.0 需求效果 → NN.x 讲解摘码 → 坑位清单 → 导航）。

### Task 8: docs/31–34 章 + 存量章增补

- [ ] 四章正文。
- [ ] 15-testing.md 增补：doctest 书上有、0.16.0 实测无（附验证方法）；23-debugging 或 20 按需提 mmap 一句坑位（Learning Zig ch10 素材，std.Io mmap 0.16 形态实测后决定写不写）。
- [ ] 24-minigrep.md 尾部加"下一章：25"。

### Task 9: 验证脚本与导航收口

- [ ] build.ps1 / run-all.sh 登记新特判（32_sqlite DLL 实参；29/30/34 自演型按普通跑；默认分支已自动发现新目录）。
- [ ] README.md：结构描述 24→34、示例 23→33、章节索引补 10 行。
- [ ] CHEATSheet.md：新增网络/HTTP/SQLite/原子/解释器套路 + 新坑位索引。
- [ ] 根 README.md zig 行更新。

### Task 10: 终验 + 提交 + 记忆

- [ ] `pwsh build.ps1 -All` 全绿（34 个示例）。
- [ ] 一致性：章号=目录号、导航链接无断链、README 表齐、CHEATSheet 索引齐。
- [ ] 更新 auto-memory `zig-tutorial-build.md`。
- [ ] 分批提交（示例批 + 正文批 + 收口批），每批信息末尾 Co-Authored-By。

## 执行勘误（执行中追加）

1. **std.Io.net TCP 在 Windows 0.16.0 数据面坏**（最大发现）：UDP 回环全通；TCP 控制面通、数据面 recv 等不到/RESET。三组实验定位（同进程双线程 / 双进程 / 显式 protocol 均复现），社区已知 AFD 缺陷域。29/30/34 的 TCP 全部改 ws2_32 extern 直调，正文 29.0 节完整实录。
2. **std.Thread.Mutex/Condition/RwLock 在 0.16 已并入 std.Io**：31 章按新 API 重写；并在 std.testing.io 上实测锁等待挂死——测试只测原子/纯函数（19 章同款取舍，15 章补坑位）。
3. **doctest 0.16.0 编译器没有**：Learning Zig ch7 的 doctest 素材转为 15 章坑位（附验证方法）。
4. **extern 细节三坑**：符号名必须等于 DLL 导出名（自造前缀=链接失败）；`extern "sqlite3"` 自动 -lsqlite3 找导入库（无 .lib 即挂，去库名改传 DLL 对象）；callconv 用 `.winapi`（.win64 已删）。
5. **windows.BOOL 是枚举**：28 章 RDCW 的比较/传参用 .FALSE/.TRUE。
6. **DoublyLinkedList 方法名**：pushFront→prepend。
7. **CRLF 混合行尾炸旧示例**：终验时 11/21/22 三章 fmt --check 挂（文件混合行尾，autocrlf 检出所致）——zig fmt 归一并给 .gitattributes 加 `zig/**/*.zig text eol=lf`。
8. **27 章从仓库根跑 exe 踩 cwd 相对路径**：statFile("main.zig") 改为自含沙盒文件；其余新示例自查均自含。
9. **31 章持锁 join 自锁**：放哨兵后先解锁再 join（正文化与坑位双收录）。
10. **34 章 windows 下 winsqlite3.dll 版本 3.51.1**、`OPEN_MEMORY` 标志会静默吞掉文件库（改特殊文件名 :memory: 路线）。
11. **33 章 `var` 关键字**：AST 字段名改 variable；测试改 arena（AST 逐节点泄漏在 testing.allocator 下不可控）。
12. **30 章返回栈缓冲切片悬空**：dupe 进调用方 arena（坑位收录）。
13. **计划调整**：Sprinter 书（第三本）成色为科普级、代码块极少，仅作主题清单核对，未直接取材。
