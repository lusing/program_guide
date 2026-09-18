# 17 · 模块、crate 与 Cargo

> 对应示例：`examples/17_cargo/`（独立 workspace 工程：`crates/geometry` + `crates/report`）
>
> 从"单个 main.rs"到"多 crate 工程"：模块系统的心智模型、依赖管理、
> feature 门控、workspace——以及你每天都会敲的 cargo 命令。

## 17.1 三层结构：crate → module → item

```text
crate（编译单元，一个 Cargo.toml）
 ├── src/main.rs        二进制 crate 的根（crate root）
 ├── src/lib.rs         库 crate 的根
 └── mod（模块，按需嵌套）
      ├── mod item / pub fn / pub struct …（条目）
```

**模块是"文件树 + 关键字"的双轨制**：

```rust
// 方式一：内联模块
mod network {
    pub mod tcp {          // 嵌套：路径 network::tcp
        pub fn connect() {}
    }
    pub fn listen() {}
}

// 方式二：分文件（src/network.rs 或 src/network/mod.rs）
mod network;               // 声明后，文件内容成为该模块
```

分文件规则：`mod network;` 找 `src/network.rs`（现代首选）或 `src/network/mod.rs`。子模块继续下钻目录：`network::tcp` → `src/network/tcp.rs`。

## 17.2 可见性：默认私有，pub 按需放行

```rust
mod network {
    pub fn listen() {}        // pub：全可见
    fn internal() {}          // 默认：仅本模块及子模块可见
    pub(crate) fn shared() {} // crate 内可见（内部 API 的黄金粒度）
    pub(in crate::net) fn narrow() {}  // 限定路径（少用）
}

network::listen();            // 路径用 :: 逐级
use network::tcp::connect;    // use 引入作用域（可 as 别名）
use network::{listen, tcp};   // 花括号成组
use network::tcp::*;          // glob（慎用）
```

与 C++/Java 的包可见性对照：Rust 的默认私有+`pub(crate)` 组合把"内部实现藏起来、公共 API 面积最小化"做成了制度。**库 crate 的 pub 条目 = 公共 API**，改动要当破坏性变更对待（1.0 之前随意）。

## 17.3 依赖管理

```toml
[dependencies]
serde = { version = "1", features = ["derive"] }     # 版本 + feature
serde_json = "1"                                     # 简写 = ^1（>=1.0 <2.0）
geometry = { path = "../geometry" }                  # 本地路径依赖（monorepo/内部库）
tokio = { version = "1", features = ["rt", "macros", "time"] }

[dev-dependencies]                                   # 仅测试/示例用
tempfile = "3"
```

```powershell
cargo add serde            # 自动写入最新兼容版（推荐起手式）
cargo update               # 锁文件内升级
cargo tree                 # 依赖树（查谁引了谁）
cargo build / test / doc --open
```

版本号是**语义化版本约束**：`"1"` = `^1`（兼容范围内的最新）。`Cargo.lock` 锁定具体版本——**应用工程提交 lock，库工程不提交**（社区惯例）。

## 17.4 feature：编译期开关

```toml
# crates/geometry/Cargo.toml
[features]
advanced = []          # 开关型：无额外依赖
```

```rust
#[cfg(feature = "advanced")]
pub mod advanced {     // 只有开启该 feature 才编译进产物
    pub fn polygon_area(points: &[(f64, f64)]) -> f64 { ... }
}
```

```toml
# 使用方按需开启
geometry = { path = "../geometry", features = ["advanced"] }
```

feature 是 Rust 生态的**条件编译**标准姿势（不是 #ifdef）：零成本裁剪、按需付编译时间。标准 feature 名约定：`std`、`default`、`full`。标准库里的 `cfg!(debug_assertions)`、`#[cfg(test)]` 是同一机制的内置条件（21 章测试用后者）。

## 17.5 workspace：多 crate 一个屋檐

```toml
# 工程根 Cargo.toml（17_cargo 示例，本教程 rust/ 根也是这个形态）
[workspace]
resolver = "3"
members = ["crates/*"]

[workspace.dependencies]        # 集中声明，成员用 workspace = true 继承
geometry = { path = "crates/geometry" }

[profile.release]               # 全成员生效的构建配置
lto = true
```

```toml
# 成员 crates/report/Cargo.toml
[dependencies]
geometry = { workspace = true, features = ["advanced"] }   # 继承 + 追加 feature
```

收益：**一个 target/ 目录**（增量编译共享，省时省盘）、**版本一处改**（workspace.dependencies）、命令全仓粒度（`cargo test --workspace`）。

> 本教程仓库的两层 workspace：`rust/` 根 workspace 管全部章节示例；`17_cargo` 与 `24_minigrep` 自带 `[workspace]`，在根的 `exclude` 里登记后独立自治——**嵌套 workspace 必须显式 exclude，否则报 "multiple workspace roots"**（实测坑）。

## 17.6 每日 cargo 命令

| 命令 | 干什么 |
|---|---|
| `cargo run [-p 名] [-- args]` | 编译+运行（-p 选成员，-- 传参） |
| `cargo build [--release]` | 编译 |
| `cargo check` | 只查错（最快反馈，IDE 后端） |
| `cargo test [-p 名] [过滤串]` | 测试（21 章） |
| `cargo clippy [--fix]` | lint（--fix 自动修） |
| `cargo fmt [--check]` | 格式化 |
| `cargo doc --open` | 生成 API 文档并打开浏览器 |
| `cargo tree -p 名` | 依赖树 |
| `cargo add 依赖名` | 添加依赖 |
| `cargo clean` | 清 target |

## 17.7 发布（了解）

```powershell
cargo login --registry crates-io    # API token（一次性）
cargo publish --dry-run -p geometry # 干跑：校验清单、打包
cargo publish -p geometry           # 真发布（不可撤销/覆盖）
```

crates.io 名字先到先得、版本只进不退。发布前自查：README/license/description、`cargo package --list` 看打进包里的文件。

## 17.8 坑位清单

1. **mod 声明不能省**：文件放进 src/ 不等于存在——`mod network;` 必须写（在 main.rs/lib.rs 或父模块里）。
2. **嵌套 workspace 必须 exclude**：子目录自带 `[workspace]` 又被父 members 包含 → "multiple workspace roots found"（本教程根 Cargo.toml 的 exclude 就是解法）。
3. **路径依赖的 feature 要在使用方开**：`path` 依赖不自动继承 feature——谁要谁写 `features = [...]`。
4. **dev-dependencies 不进正式构建**：测试工具放这里，别让运行时背着 tempfile。
5. **同名 crate 的 bin 与 lib**：包名 hello 时 bin 也叫 hello；`src/lib.rs` + `src/main.rs` 共存时 main 里 `use hello::...` 引用自己包的库（24 章实战这么干）。
6. **workspace 成员包名必须唯一**：目录名可以带 `02_` 前缀，但 `name = "hello"` 才是身份——本教程示例目录名 ≠ 包名（包名不能以数字开头）。
7. **Cargo.toml 的 `[features]` 默认聚合**：`default = ["a"]` 时不开 default 反而要 `default-features = false`——依赖多时容易绕晕，写注释。

---

上一章：[16 宏系统](16-macros.md) · 下一章：[18 智能指针](18-smartptr.md)
