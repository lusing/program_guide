# zig 教程重写设计（2026-09-17）

## 1. 背景与问题

`zig/` 目录现状：单个 2636 行 `README.md` 充当整份指南（19 大节"特性手册"式组织，
每节一两句定义 + 一段代码）；**代码是 Zig 0.13 时代 API，本机 0.16.0 上大量编译不过**
（`std.ArrayList(T).init(alloc)`、`std.io.getStdOut()`、不存在的 `std.fmt.print`、
假命令 `zig build-wasm`、编造的汇编标签 `.loop_{@panic}` 等）；`snippets/` 碎片
（bash/powershell/javascript/lldb/html 五类目录）从不参与编译；`examples/` 108 个
浅示例按类别目录 + 三位编号组织，与 docs 分章结构无关。Zig 特色内容（comptime、
显式分配器、构建系统与包管理、C 互操作、交叉编译）每样只有一两屏，讲不出深度。

与 cpp20/dotnet/fsharp/dart/flutter 教程标准（docs/ 分章 + 章号=示例 + 递进讲解 +
坑位清单 + 全量编译验证）差距大。

## 2. 目标与非目标

**目标**：重写为 24 章独立文档（每章 150–250 行，特色章节不压缩）、章号 = 示例目录号
（02–24 共 23 个示例）；定位"会编程（C/C++ 背景最佳）、初学 Zig，从零教到 0.16 现代写法"；
全部示例在 Zig 0.16.0 实测三层验证通过；第 24 章实战迷你 grep（与 cpp20 对齐：递归 +
多线程 + 高亮 + 测试）。

**非目标**：
- 不做 0.13→0.16 迁移指南（坑位清单点到即止）
- 不教 GUI（win32/mfc/wpf 教程已存在，交叉引用）
- 不引第三方包作主线（16 章包管理用本地路径依赖演示机制）
- wasm 只讲 freestanding/WASI 编译一节，不做浏览器 JS 互操作主线
- async/await 已从语言移除，正文一段话说明，不教
- 嵌入式/裸机只在一章带过

## 3. 已确认决策

| 决策点 | 结论 |
|---|---|
| 章节规模 | 24 章完整版（对齐 cpp20，24 = 实战迷你 grep） |
| 读者定位 | 会编程（C/C++ 背景最佳）、初学 Zig，0.16 现代写法为主线 |
| 实战项目 | 第 24 章迷你 grep（目录递归 + 多线程 + 高亮 + 测试） |
| 工具链 | `G:\scoop\apps\zig\current\zig.exe`（0.16.0，scoop 安装） |
| 示例形态 | 每章一个目录 `examples/NN_topic/main.zig`（16/24 为 build.zig 工程），章号=目录号 |
| 验证策略 | 三层：`zig fmt --check` + `zig test`（内置断言）+ `zig build-exe` 运行 exit 0 |
| 旧文件 | 删 `examples/`（108 个）、`snippets/`、旧 README、`build.sh`、旧 build.ps1 |
| 新增 | `docs/` 24 章、新 `examples/` 23 目录、新 `build.ps1`、`CHEATSheet.md`、新 `README.md` |
| 目录名 | 保留 `zig`（外部引用不破坏） |

## 4. 环境实测结论（2026-09-17，Zig 0.16.0 @ G:\scoop\apps\zig\current）

| 项 | 结果 |
|---|---|
| 新 main 入口 | `pub fn main(init: std.process.Init)` 可拿 `io`/`gpa`/`arena`/`minimal.args`/`environ_map` ✅ |
| stdout | `std.Io.File.stdout().writer(init.io, &buf)` + **必须 `flush()`**；`std.debug.print`（stderr）不变 ✅ |
| ArrayList | **unmanaged**：`var l: std.ArrayList(T) = .empty; try l.append(alloc, x)` ✅ |
| HashMap | `std.AutoHashMap(K,V).init(alloc)` 仍是 managed 风格 ✅ |
| 原子/线程 | `std.atomic.Value(T)`、`std.Thread.spawn` 不变 ✅ |
| `@cImport` | 0.16 仍可用，但**必须 `-lc`**（否则 "libc headers not available"）✅ |
| `zig test` | 独立可用，`std.testing.expect*` 正常 ✅ |
| build.zig | `b.addExecutable(.{.name, .root_module = b.createModule(...)})` 模式可用 ✅ |
| **坑** | Windows 下 `Init.minimal.args` 是 `[]const u16`（WTF-16），跨平台取参须 `Args.Iterator.initAllocator` |
| **坑** | `std.fs.File` 已移到 `std.Io.File`；`writer(io, buf)` 第一个参数是按值传递的 `Io` |

其余坑位（0.16 Io 模型细节、DebugAllocator、labeled switch、wasm 目标等）实施中边写边实测累积。

## 5. 章节结构（docs/，24 章，⭐ = 特色重点细讲）

| # | 文件 | 主题 | 示例 |
|---|---|---|---|
| 01 | `01-overview.md` | 全景：设计哲学（无隐藏控制流/显式分配器/comptime 替代宏）、0.16 现状与版本演进、工具链一览、学习方法 | — |
| 02 | `02-hello.md` | 第一个程序：zig run/build-exe/test、构建模式（Debug/Release*）、`std.debug.print`、`std.process.Init` 新入口、zig fmt | `02_hello` |
| 03 | `03-types.md` | 基础类型：const/var、任意位宽整数、溢出运算符 `+%=`、comptime_int/float、字面量、转型家族（@as/@intCast/@truncate/@bitCast/@floatCast） | `03_types` |
| 04 | `04-control.md` | 控制流：if/while/for 表达式语义、continue 表达式、label、switch 穷尽/range/捕获、labeled switch | `04_control` |
| 05 | `05-functions.md` | 函数：参数与返回、defer 作用域清理、anytype、无重载的补偿模式（comptime 参数/联合参数）、嵌套函数 | `05_functions` |
| 06 | `06-slices.md` | 数组切片字符串：`[N]T`、切片语义、哨兵切片 `[:0]u8`、多项指针 `[*]T` vs 单项 `*T`、字符串字面量真身 `*const [N:0]u8` | `06_slices` |
| 07 | `07-structs.md` | 结构体：字段/默认值、方法语法糖、命名空间、匿名 struct/tuple、声明惯用法 | `07_structs` |
| 08 | `08-enums.md` | 枚举与联合：enum 与 tag、tagged union + switch 捕获、非标记 union、packed struct、enum 方法 | `08_enums` |
| 09 | `09-optionals-errors.md` | 可选与错误 I：`?T`、orelse/.?/payload 捕获、error set、`!T`、try/catch、错误集合运算 | `09_errors1` |
| 10 | `10-errors-advanced.md` | 错误 II：errdefer、错误返回跟踪、`?!T` 组合模式、panic 与 @panic、Debug/ReleaseSafe 安全模式、std.log | `10_errors2` |
| 11 | `11-allocators.md` ⭐ | 分配器：显式传分配器哲学、stack/page/DebugAllocator(GPA)/Arena/FixedBuffer/SmpAllocator、defer free 模式、泄漏检测 | `11_allocators` |
| 12 | `12-collections.md` ⭐ | 集合：ArrayList（unmanaged API）、ArrayListManaged?/内存布局、AutoHashMap/StringHashMap、迭代与删除、排序 | `12_collections` |
| 13 | `13-comptime.md` ⭐ | comptime I：编译期求值规则、comptime 参数/var/块、comptime 与运行期的同一份代码、inline for/while | `13_comptime` |
| 14 | `14-generics.md` ⭐ | comptime II 泛型：`fn F(comptime T: type) type`、容器/泛型结构体、anytype + @TypeOf、@typeInfo 反射、@field、代码生成 | `14_generics` |
| 15 | `15-testing.md` ⭐ | 测试：test 块、std.testing 断言族、testing.allocator 泄漏检测、doc test（/// 注释代码块）、zig test 过滤 | `15_testing` |
| 16 | `16-build.md` ⭐ | 构建系统与包管理：build.zig/step/module、命令行约定、build.zig.zon、zig fetch --save、本地路径依赖 | `16_build`（工程） |
| 17 | `17-c-interop.md` ⭐ | C 互操作：extern fn/export、@cImport（-lc）、zig translate-c、链接 C 源码/DLL、extern struct 与 C ABI | `17_cinterop` |
| 18 | `18-cross.md` ⭐ | 交叉编译与 zig cc：-target 任意目标、aarch64-linux 实测、wasm32（freestanding/WASI）、zig cc/c++ 作为 C 编译器 | `18_cross`（含 hello.c） |
| 19 | `19-threads.md` | 并发：std.Thread、Mutex/Condition、atomic.Value 与内存序、WaitGroup、生产者-消费者 | `19_threads` |
| 20 | `20-files-io.md` | 文件与 IO：std.fs/Dir/File、0.16 新 Writer/Reader 接口、缓冲与 flush、argv 解析、std.json | `20_files` |
| 21 | `21-asm.md` | 内联汇编与底层：asm 语法（正确重写）、操作数约束、volatile、@bitCast、extern struct、calling convention | `21_asm` |
| 22 | `22-process.md` | 进程与系统编程：Init.args/environ、子进程 spawn、std.process.argsAlloc 替代品、路径处理、时间 | `22_process` |
| 23 | `23-debugging.md` | 调试与工具链：panic 栈跟踪、错误返回跟踪、LLDB、std.log、性能计时、zig fmt/doc/ast-check | `23_debug` |
| 24 | `24-minigrep.md` | 实战：迷你 grep（递归目录 + 多线程 + 高亮 + 测试，build.zig 工程） | `24_minigrep`（工程） |

吸收旧内容：版本管理（zigup/zvm）压缩进 01 章一小节；对比表（C/C++/Rust）进 01 章；
综合示例拆进各章；标准库参考取消独立章（融入 12/19/20/22）；调试章保留 LLDB 命令表。

## 6. 示例与验证

- 每个示例含 `pub fn main()`（演示输出 + 关键路径断言）与 `test` 块（std.testing 断言自检）。
- `build.ps1`（pwsh 7，无 BOM，参数 `-All/-Example NN_topic/-Clean`）三层验证：
  1. `zig fmt --check`（格式合规）
  2. `zig test main.zig`（test 块全过 = 自检断言）
  3. `zig build-exe` + 运行 exe 退出码 0
- 16/24 章：`zig build test` + `zig build run`；17 章 `-lc`；18 章另交叉编译
  aarch64-linux + wasm32-freestanding（编译通过即验证）+ `zig cc` 编 hello.c。
- build 产物统一移入 `build/`（源目录保持干净）。

## 7. 交付物清单

1. `zig/docs/01-overview.md` … `24-minigrep.md`（24 章）
2. `zig/examples/02_hello/` … `24_minigrep/`（23 个示例）
3. `zig/build.ps1`（重写）
4. `zig/CHEATSheet.md`（语法速查 + 坑位索引）
5. `zig/README.md`（重写：定位、目录结构、章节索引表、构建工具链、验证命令、相关教程）
6. 删除：`zig/examples/`（旧）、`zig/snippets/`、`zig/build.sh`
7. 根 `README.md` 若引用 zig 描述则微调
8. 记忆文件：`zig-tutorial-build.md`（0.16 实测坑位 + 结构）

## 8. 风险与对策

| 风险 | 对策 |
|---|---|
| 0.16 std API 仍在变动，写作中再遇破坏性差异 | 每章示例先实测再定稿正文；坑位即素材 |
| Io 接口（Threaded）复杂度溢出教程定位 | 20 章只教 File.reader/writer + buffer 用法，不展开 async 机制 |
| Windows 中文控制台输出 | std.debug.print/UTF-8 无 BOM 惯例；必要时 chcp 65001（build.ps1 代设） |
| 内联汇编示例易错 | 只写实测通过的最小 x86_64 示例，架构检查 comptime 守卫 |
| 旧文件删除不可逆 | git 历史保留；一次提交内完成删除 + 新结构，便于回溯 |
