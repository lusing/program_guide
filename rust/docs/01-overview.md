# 01 · 全景：Rust 是什么、工具链与学习路线

> 本章无示例代码。装好工具链、建立正确的预期，比多写两百行代码重要。

## 1.1 三句话讲清 Rust

**系统级语言，无 GC，但内存安全由编译期保证。** C/C++ 的性能与控制力，加上"悬垂指针、use-after-free、数据竞争在安全代码里写不出来"的强约束。代价是：**编译器会拒绝你写出它无法证明安全的代码**——初学阶段 80% 的挫败感来自这里，80% 的忠诚度也来自这里。

Rust 的三根支柱：

| 支柱 | 靠什么实现 | 对应本教程 |
|---|---|---|
| 内存安全 | 所有权 + 借用检查（无 GC，释放时机编译期确定） | 04/05/13 章 |
| 可靠性 | 类型系统：`Option`/`Result` 取代 null/异常，错误是值 | 08/10 章 |
| 无畏并发 | `Send`/`Sync` 自动标注——数据竞争在**编译期**不存在 | 22/23 章 |

## 1.2 与 C++/Zig/Go 对照

| 维度 | Rust | C++ | Zig | Go |
|---|---|---|---|---|
| 内存管理 | 所有权/借用，编译期确定 | 手动 + RAII + 智能指针 | 显式分配器 + 手动 free | GC |
| 安全保证 | 安全子集内内存+并发安全 | 无（UB 常客） | Debug 检查一部分 | GC 保证 |
| 抽象成本 | 零成本（单态化、无虚表默认） | 零成本原则 | 零成本 + comptime | 有 GC/调度开销 |
| 错误处理 | `Result` 值 + `?` | 异常 / expected | 错误联合 `!T` | error 值 |
| 泛型 | trait 约束 + 单态化 | 模板 + concepts | comptime 类型参数 | 类型参数 + 约束 |
| 编译速度 | 慢（公认痛点，增量可缓解） | 慢 | 极快 | 快 |
| 学习曲线 | 陡（借用检查器） | 陡（全语言） | 中 | 平 |

**选型直觉**：要 C++ 级性能又想睡好觉 → Rust；极致简洁可控、肯手动管内存 → Zig；服务端快速交付 → Go。

## 1.3 版本与 Edition（2026 年现状）

- Rust 每 **6 周**发一个稳定版（1.x 递增，无大版本断裂）。本教程实测 **rustc 1.98.1**（2026-09）。
- **Edition** 是"允许小幅不兼容"的语言版本开关，目前有 2015 / 2018 / 2021 / **2024**（2024 于 1.85 稳定，现为 `cargo new` 默认）。旧代码可逐 crate 升级，`cargo fix --edition` 自动迁移大半。
- 本教程全程 **edition 2024**。与旧教程差异最大的几处（各章坑位清单还会展开）：

| 旧写法（2021 及以前） | edition 2024 |
|---|---|
| `extern "C" { fn abs(x: i32) -> i32; }` | `unsafe extern "C" { ... }`（extern 块标注 unsafe） |
| `#[no_mangle] pub extern "C" fn ...` | `#[unsafe(no_mangle)] pub extern "C" fn ...` |
| `static mut` 可以取引用 | 只允许 unsafe 块内整体读写，`&MUT` 直接拒绝 |
| `gen` 等成为保留字 | `gen`/`raw` 不能当标识符 |

> ⚠️ 网上大量教程停留在 2018/2021 edition；照抄进 2024 工程会在上述位置编译失败。报错信息通常**直接给出改法**——先读报错再搜索。

## 1.4 工具链一览

| 工具 | 作用 | 备注 |
|---|---|---|
| `rustc` | 编译器 | 日常不直接用，cargo 代劳 |
| `cargo` | 构建/包管理/测试/文档 一体 | 生态中心，crates.io 索引 |
| `cargo clippy` | 静态 lint（比编译器更挑剔） | 本教程验证层之一，`-- -D warnings` 当错误 |
| `cargo fmt` | 格式化 | 本教程验证层之一，`--check` 只检查 |
| `cargo test` | 单元/集成/文档测试三合一 | 21 章细讲 |
| `cargo doc --open` | 由 `///` 注释生成 API 文档 | 文档即测试 |
| `rust-analyzer` | LSP（VS Code/RustRover 内核） | 补全、内联类型、重构 |
| `rustup` | 工具链版本管理器 | Windows 上也可能用 scoop 装的独立版 |

### 本机安装位置（三平台）

| 平台 | 典型安装方式 | 位置 | 验证 |
|---|---|---|---|
| Windows | scoop 独立版 | `G:\scoop\apps\rust\current\bin\` | `rustc --version` |
| Windows | rustup（官方默认） | `%USERPROFILE%\.cargo\bin\` | 同上 |
| macOS | MacPorts | `/opt/local/bin/`（`cargo`/`rustc`/`cargo-clippy`/`rustfmt` 全套） | 同上 |
| macOS / Linux | rustup（官方默认） | `~/.cargo/bin/` | 同上 |

本教程按 **rustc 1.98.1 / cargo 1.98.0** 实测（三平台同一版本）：
macOS 上是 MacPorts 装的 `x86_64-apple-darwin`，Windows 上是 scoop 装的独立版，
两边 `cargo fmt --check` + `clippy -D warnings` + `test` + `run` 四层结论完全一致。

```bash
# macOS / Linux
rustc --version && cargo --version && cargo clippy --version && cargo fmt --version
```

```powershell
# Windows（PowerShell）
rustc --version; cargo --version; cargo clippy --version; cargo fmt --version
```

> macOS 注意：MacPorts 的 rustc 自带 std rlib 是为 macOS 12.0 编的，而 ld 默认
> `-mmacosx-version-min=10.12`，于是每次链接测试二进制都会刷一屏
> `was built for newer macOS version (12.0) than being linked (10.12)`。
> 本教程在 `rust/.cargo/config.toml` 里把 `MACOSX_DEPLOYMENT_TARGET` 抬到 12.0 抵消它
> （实测 stderr 从 8 行降到 0 行）。`cargo clippy` 用的是 check 语义、不链接，所以照不出这条。
> 换机器后如果告警里的版本变了，同步改那个值即可。

## 1.5 cargo 五分钟上手（02 章展开）

```powershell
cargo new hello          # 生成 hello/Cargo.toml + hello/src/main.rs
cargo run                # 编译 + 运行（增量编译，秒级）
cargo build --release    # 优化构建，产物在 target/release/
cargo test               # 跑全部测试
cargo clippy             # lint
```

本教程不直接用 rustc 编单文件——**cargo 是 Rust 的一部分**，脱离 cargo 学 Rust 等于脱离 go 学 Golang。

## 1.6 学习路线与本教程结构

24 章分四段，难度的"Wall of Borrowing"集中在第二段：

```text
基础（02-03）      → 1 天    变量/类型/控制流/函数：C/C++ 老手快速过
核心（04-16）⭐     → 1-2 周  所有权/借用/字符串/错误/泛型/trait/生命周期/闭包/迭代器/宏
工程（17-21）      → 3 天    cargo 工程化/智能指针/unsafe/文件与序列化/测试
并发与实战（22-24）⭐ → 3 天   线程/async/迷你 grep
```

每章学法（与 zig/go 教程一致）：**读讲解 → 跑示例 → 改代码再跑**。

```bash
# macOS / Linux
cd <仓库>/rust/examples/05_borrowing
cargo run       # 看输出
cargo test      # 跑断言（改坏代码，看哪条测试红）
```

```powershell
# Windows（PowerShell）
cd G:\code\guide\rust\examples\05_borrowing
cargo run
cargo test
```

## 1.7 心法：编译器是盟友，不是敌人

1. **读完整条报错**。rustc 报错是全语言最好的一档：错误码、原因、改法建议、文档链接全给。
2. **borrow checker 拒绝的是"它证明不了安全"，不是"你不安全"**。给出更多约束（作用域收窄、克隆、重构所有权流向），它就放行。
3. 初学三板斧：**先 clone、先 unwrap、先 `Vec<String>`**——跑通再优化。所有权问题在能运行的代码上重构，远比在空白文件里设计容易。
4. `unsafe` 不是逃生舱口而是责任书（19 章）；遇到借用死结，先问"我到底想让谁拥有这份数据"。

## 1.8 坑位清单

1. **Rust 不像看起来那么接近 C++**：运算符重载、拷贝语义、引用都换了内核（move 默认、`Copy` 需显式、`&` 受借用规则约束）。
2. **网上的 edition 旧语法**：`extern` 块、`#[no_mangle]`、`static mut` 用法在 2024 全变了（见 1.3 表）。
3. **中文路径/编码**：源文件一律 UTF-8（无 BOM）；Windows PowerShell 控制台中文乱码先 `chcp 65001`（build.ps1 已代设）。macOS / Linux 终端默认 UTF-8，一般不必管。
4. **`cargo run` 慢**：首次要编译依赖（20 章 serde、23 章 tokio 还得联网下 crate），之后增量秒级。别用"编译慢"判断语言快慢。
5. **直接搜到的代码常缺上下文**：crate 版本、feature 开关没写全就编译不过——先看该 crate 文档的"Getting started"。
6. **macOS 上的链接告警刷屏**：见 1.4 的提示框，根因是 std rlib 与 ld 默认部署目标不一致，不是你的代码有问题。

---

下一章：[02 第一个程序](02-hello.md)
