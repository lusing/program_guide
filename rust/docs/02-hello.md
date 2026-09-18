# 02 · 第一个程序：cargo 全流程与格式化输出

> 对应示例：`examples/02_hello/`
>
> 学完本章你能：创建并运行一个 cargo 工程、看懂 Cargo.toml、
> 用 `println!` 打印任何东西、知道去哪看产物。

## 2.1 工程骨架：cargo new 干了什么

```text
02_hello/
├── Cargo.toml      # 工程清单：名字、版本、依赖
└── src/
    └── main.rs     # 二进制入口
```

```toml
[package]
name = "hello"          # 包名（crates.io 上唯一；本地仅标识）
version = "0.1.0"       # 语义化版本：主.次.修订
edition = "2024"        # 语言版本开关（01 章）

[dependencies]          # 依赖清单（20/23 章会往这里加 serde/tokio）
```

```rust
fn main() {
    println!("Hello, world!");
}
```

四条日常命令：

| 命令 | 作用 | 产物/位置 |
|---|---|---|
| `cargo run` | 增量编译 + 运行 | `target/debug/hello.exe`（macOS / Linux 上是 `target/debug/hello`，**没有后缀**） |
| `cargo build` | 只编译 | 同上；`--release` 进 `target/release/` |
| `cargo test` | 编译并跑测试 | 测试二进制在 `target/debug/deps/` |
| `cargo check` | 只查类型不产码 | 最快的"语法检查"，IDE 内部就用它 |

> 一个目录里有 `Cargo.toml` 就是一个 crate（编译单元）。crate 类型由入口决定：有 `src/main.rs` 是**二进制**，有 `src/lib.rs` 是**库**，可以两者皆有（24 章实战就这么分层）。

## 2.2 println! 是宏，不是函数

`println!("x = {x}")` 的 `!` 暴露了它的身份。为什么做成宏：**格式串在编译期被解析**——占位符数量、参数类型、变量是否存在全部编译期检查，拼错直接编译错而不是运行期崩溃。这也是 `format!`、`vec!`、`panic!` 共同的设计动机。

## 2.3 占位符全家

```rust
let lang = "Rust";
let ver = 1.98;
println!("{} {}", lang, ver);      // 顺序占位（最基础）
println!("{lang} {ver}");          // 内联参数：变量名即占位名（1.58+，现代默认）
println!("{0}×{1} = {2}", 2, 3, 6);// 位置参数：可复用 {0}
let (name, v) = ("四", 16);
println!("{name} 的平方是 {v}");   // 命名参数：先绑定，占位用名字
```

**宽度、对齐、补零、精度**（和 Python format 同一套语法）：

```rust
println!("[{l:<8}|{r:>8}|{c:^8}]", l="左", r="右", c="中"); // 左/右/中对齐，宽 8
println!("{:06.2}", 13.37);   // 宽 6 补零、2 位小数 → 013.37
println!("{:#x} {:#o} {:#b}", 255u32, 8u32, 5u32); // 0xff 0o10 0b101
println!("{}", 1_000_000u32); // 数字下划线，纯可读性
```

**Debug 输出**：`{:?}` 单行、`{:#?}` 多行缩进——需要类型实现 `Debug`（大多数标准类型有；自己的类型加 `#[derive(Debug)]`，07 章）：

```rust
println!("{:?}", vec![1, 2, 3]);     // [1, 2, 3]
println!("{:#?}", vec![1, 2, 3]);    // 多行展开，调试大结构用
```

**其它三个常客**：

```rust
print!("不带换行");
eprintln!("进 stderr");   // 调试日志惯例：stdout 给数据，stderr 给日志
let s = format!("拼成 {lang} 字符串"); // 返回 String，不打印
```

stderr 的好处：`cargo run > out.txt` 时日志不污染 out.txt（`2>` 单独重定向）。

## 2.4 跑起来

```bash
# macOS / Linux
cd <仓库>/rust/examples/02_hello
cargo run     # 观察各种占位符输出
cargo test    # 两个断言测试：format! 的行为写进了测试
```

```powershell
# Windows（PowerShell）
cd G:\code\guide\rust\examples\02_hello
cargo run
cargo test
```

改动实验（本章标准学法）：

1. 把 `println!("{0}×{1} = {2}", 2, 3, 6)` 的参数删一个 → 看编译期报错长什么样；
2. 给 `println!("{:?}", 3.14)` 换成 `{}` → f32/f64 是例外，`{}` 可用；再试试数组 `[1,2]` 用 `{}` → 编译错（数组只实现了 Debug）；
3. `cargo test` 里故意改错一个期望值 → 看测试失败输出。

## 2.5 Cargo.toml 依赖速览（预告）

```toml
[dependencies]
serde = { version = "1", features = ["derive"] }  # 20 章用
tokio = { version = "1", features = ["rt", "macros", "time"] }  # 23 章用
```

`cargo add serde` 自动写入并选好 feature——比手写稳。版本号 `1` 指 `>=1.0, <2.0`（语义化版本约束，17 章细讲）。

## 2.6 坑位清单

1. **`{}` 打印数组/Vec 报错**：`Display` 没实现，用 `{:?}`。报错信息会明说 "cannot be formatted with the default formatter"。
2. **打印中文乱码**：Windows 控制台先 `chcp 65001`；源文件保持 UTF-8 无 BOM。
3. **clippy 的 `print_literal`/`uninlined_format_args`**：`println!("{}", "字符串字面量")` 会被建议直接写进格式串——本教程对这类风格告警零容忍（验证层 `-D warnings`），写示例时留意。
4. **`cargo run` 第一次慢**：在编译依赖。加 `--quiet` 少刷屏；怀疑缓存坏了删 `target/` 重来。
5. **`target/` 不要进版本库**：体积大且平台相关。`.gitignore` 已配（仓库根有全局规则）。
6. **`println!` 的 `!` 不能省**：`println("hi")` 是"把 println 当函数"的典型笔误，报错会让人生疑——先检查 `!`。

---

下一章：[03 变量、类型、控制流与函数](03-basics.md)
