# Rust 编程指南（1.98 / edition 2024）

面向**会编程（C/C++ 背景最佳）、初学 Rust** 的读者：从零教到现代 Rust——edition **2024**、`scoped threads`、let-else、迭代器管道从对应章节就是默认姿势，老写法（`extern` 块不加 unsafe、`#[no_mangle]` 裸写、`static mut` 取引用）只在坑位清单里教"认得"。**Rust 特色全部独立成章细讲**：所有权（04）、借用（05）、字符串（06）、错误处理（10）、泛型与 Trait（11/12）、生命周期（13）、闭包与迭代器（14/15）、宏（16）、Cargo 工程化（17）、unsafe/FFI（19）、测试（21）、线程（22）、async（23）。每章"读讲解 → 跑示例 → 改代码再跑"，全部 23 个示例**四层验证**通过（fmt + clippy `-D warnings` + test + 运行 exit 0）。

> ⚠️ 网上教程版本混杂：2018/2021 edition 的写法在 2024 里 `extern`、`#[no_mangle]`、`static mut` 三处直接编译错。本教程所有代码在 **rustc/cargo 1.98.1** 实测，每章坑位清单收录版本差异。

## 目录结构

```text
rust/
├── README.md       本文件
├── docs/           24 章教程（01 → 24 顺序阅读）
├── examples/       23 个示例工程（章号 = 目录号；均为 cargo 工程）
│   ├── …           21 个普通示例（根 workspace 成员，共享 target/）
│   ├── 17_cargo/   多 crate workspace 工程（独立构建）
│   └── 24_minigrep/ 实战项目（lib + bin + 集成测试，独立构建）
├── build.ps1       PowerShell 入口（四层：fmt + clippy + test + run）
├── run-all.sh      等价的 shell 入口（macOS / Linux 用这个）
├── .cargo/         只放一条 macOS 链接告警的抵消项，见下面「macOS 上的兼容性」
│   └── config.toml
├── Cargo.toml      根 workspace（members = examples/*，exclude 两个独立工程）
├── build/          验证产物（每个示例的 .out / .err，不入库）
└── CHEATSheet.md   语法速查 + 坑位索引
```

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [01 全景](docs/01-overview.md) | 三根支柱、C++/Zig/Go 对照、edition 与工具链 | — |
| [02 第一个程序](docs/02-hello.md) | cargo 全流程、Cargo.toml、println! 占位符全家 | `02_hello` |
| [03 变量类型控制流函数](docs/03-basics.md) | 遮蔽、溢出四策略、as 截断、一切皆表达式 | `03_basics` |
| [04 ⭐所有权](docs/04-ownership.md) | move/Clone/Copy、Drop、函数边界、所有权流向图 | `04_ownership` |
| [05 ⭐借用与引用](docs/05-borrowing.md) | 两条铁律、NLL、切片、报错速查表 | `05_borrowing` |
| [06 ⭐切片与字符串](docs/06-strings.md) | String/&str 二分、UTF-8 三层次、索引为什么没有 | `06_strings` |
| [07 结构体](docs/07-structs.md) | 三形态、impl、关联函数、derive 全表、vs C++ class | `07_structs` |
| [08 枚举与模式匹配](docs/08-enums.md) | 带数据 enum、match 穷尽、守卫/@ 绑定/let-else | `08_enums` |
| [09 集合](docs/09-collections.md) | Vec/HashMap entry/BTreeMap/HashSet/VecDeque | `09_collections` |
| [10 错误处理](docs/10-errors.md) | panic 边界、? 与 From、自定义错误四件套、thiserror 风格 | `10_errors` |
| [11 泛型](docs/11-generics.md) | 约束与 where、默认类型参数、单态化、vs C++ 模板 | `11_generics` |
| [12 ⭐Trait](docs/12-traits.md) | 静态/动态分发、关联类型、运算符重载、对象安全 | `12_traits` |
| [13 ⭐生命周期](docs/13-lifetimes.md) | 省略三规则、结构体持引用、'static 两义 | `13_lifetimes` |
| [14 ⭐闭包](docs/14-closures.md) | 捕获三方式、Fn/FnMut/FnOnce、move、返回闭包 | `14_closures` |
| [15 ⭐迭代器](docs/15-iterators.md) | 三种来源、适配器×消费器、惰性、自定义迭代器 | `15_iterators` |
| [16 宏系统](docs/16-macros.md) | macro_rules!、片段类型、重复模式、卫生性、过程宏概览 | `16_macros` |
| [17 模块与 Cargo](docs/17-cargo.md) | mod/pub、依赖、feature、workspace、每日命令 | `17_cargo`（工程） |
| [18 智能指针](docs/18-smartptr.md) | Box/Rc/RefCell/Weak、Deref 链、选型总表 | `18_smartptr` |
| [19 unsafe 与 FFI](docs/19-unsafe-ffi.md) | 裸指针、安全封装、extern "C"、static mut 新规 | `19_unsafe_ffi` |
| [20 文件与序列化](docs/20-files.md) | fs/OpenOptions/Path、serde 派生、serde_json 全流程 | `20_files` |
| [21 ⭐测试](docs/21-testing.md) | 单元/集成/文档三件套、should_panic、表驱动 | `21_testing` |
| [22 ⭐并发](docs/22-threads.md) | scoped threads、mpsc、Arc<Mutex>、毒锁、Send/Sync | `22_threads` |
| [23 ⭐async/await](docs/23-async.md) | Future 心智模型、join/select/spawn、tokio、取消安全 | `23_async` |
| [24 ⭐实战：迷你 grep](docs/24-minigrep.md) | lib/bin 分层、参数解析、递归搜索、退出码、系统级测试 | `24_minigrep`（工程） |

## 构建工具链

| 平台 | 安装方式 | 位置 |
|---|---|---|
| Windows | scoop 独立版 | `G:\scoop\apps\rust\current\bin\` |
| Windows | rustup（官方默认） | `%USERPROFILE%\.cargo\bin\` |
| macOS | MacPorts | `/opt/local/bin/`（cargo / rustc / cargo-clippy / rustfmt 全套） |
| macOS / Linux | rustup（官方默认） | `~/.cargo/bin/` |

- Rust **1.98.1 / cargo 1.98.0** 实测（macOS 上是 MacPorts 的 `x86_64-apple-darwin`，
  Windows 上是 scoop 的独立版，**同一版本、同一套示例、四层结论一致**）。
- edition **2024**（1.85+ 起默认）；版本不符先看 [01 章](docs/01-overview.md)的 edition 对照表。
- 两个入口都不硬编码路径：`build.ps1` 只在 Windows 上试 scoop 位置、否则走 `Get-Command cargo`；
  `run-all.sh` 走 `CARGO` 环境变量 → `PATH`。
- Windows 控制台中文乱码先 `chcp 65001`（build.ps1 已代设 UTF-8）；macOS / Linux 终端默认 UTF-8。
- 20/23 章示例用 crates.io 依赖（serde / tokio）——首次构建需联网。

## 验证命令

```bash
# macOS / Linux
cd <仓库>/rust
./run-all.sh                 # 全部 23 个：fmt + clippy + test + run
./run-all.sh 12_traits       # 单个示例
./run-all.sh --clean         # 清理全部 target 目录
```

```powershell
# Windows（PowerShell）
cd G:\code\guide\rust
pwsh -ExecutionPolicy Bypass -File build.ps1 -All                 # 全部
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 12_traits   # 单个
pwsh -ExecutionPolicy Bypass -File build.ps1 -Clean               # 清理
```

两条入口做**同一套**判定（四层 + 三条运行期断言），结果必须一致。

单跑某个示例（每章标准学法）——改代码后重跑：

```bash
cd rust/examples/05_borrowing
cargo run        # 看输出
cargo test       # 跑断言（故意改坏代码，看哪条测试红）
```

## 验证判定（本目录的四层 + 三条）

1. `cargo fmt --check` 通过
2. `cargo clippy --all-targets -- -D warnings` 零告警
3. `cargo test` 全绿（单元 + 集成 + 文档测试）
4. `cargo run` 退出码 0
5. **stderr 为空** —— 抓「编译/链接告警」这类只在 stderr 露头的毛病
6. **stdout 非空** —— 抓「进程根本没执行到业务代码、退出码却仍是 0」的假阳性
7. stdout 无多余控制字符（字节 0..31，TAB/LF/CR 除外）

**第 5 条有两个例外**：`02_hello`（演示 `eprintln!`，就是教你区分两个流）和
`22_threads`（演示锁中毒，必须真的 panic 一次）——它们**故意**往 stderr 写，
名单写在两个入口的 `STDERR_ALLOW` / `$stderrAllow` 里，加新示例时别顺手往里塞。

**本目录不用「结束标记」那条判定**：示例是 cargo 工程，崩了退出码就非 0，
而第 5 条已经能抓住中途失败，再加标记是重复。

## macOS 上的兼容性（2026-09-18 实测于 macOS 12.7 + MacPorts rustc 1.98.1）

全部 23 个示例在 macOS 上四层验证通过，**示例代码本身一处都不用改**（它们一律用
`std::env::temp_dir()`、无平台分支）。需要处理的只有工具链与脚本：

| 问题 | 现象 | 修法 |
|---|---|---|
| `build.ps1` 拼了 `G:\` 盘符 | `Join-Path` 在 macOS 上抛 `Cannot find drive. A drive with the name 'G' does not exist`（**不是**返回 `$false`，所以原来的 PATH 回退根本走不到） | 先判 `$IsWindows` 再拼路径；非 Windows 用 `cargo` 而不是 `cargo.exe` |
| 链接告警刷屏 | 每个示例的 `cargo test`/`run` 都刷 `was built for newer macOS version (12.0) than being linked (10.12)` | `.cargo/config.toml` 把 `MACOSX_DEPLOYMENT_TARGET` 抬到 12.0（stderr 8 行 → 0 行） |
| 只有 PowerShell 入口 | macOS 上也能跑 pwsh，但仓库惯例要两条通道互证 | 新增 `run-all.sh` |

`cargo clippy` 用的是 check 语义、**不链接**，所以照不出上面第二条 —— 这类告警只有
真的 `test` / `run` 才暴露。**只做 clippy 等于没做运行期验证。**

换机器后若 std rlib 的目标版本更高（看告警里的 `built for newer macOS version (X.Y)`），
把 `.cargo/config.toml` 里的值同步改掉即可（设的是 `force = false`，你自己 export 过就以你的为准）。

## 相关教程

系统语言对照：[cpp20（C++20/23）](../cpp20/README.md)、[zig（0.16）](../zig/README.md)、[go（1.27）](../go/README.md)、[dlang](../dlang/README.md)；速查见 [CHEATSheet.md](CHEATSheet.md)。
