# 10 · 错误处理

> 对应示例：`examples/10_errors/`
>
> Rust 没有 null（几乎）、没有异常（真的没有）。错误是**普通的值**，
> 由类型系统强制你表态：处理、上抛、或者明确地炸。

## 10.1 两条轨道：panic 与 Result

| | panic | `Result<T, E>` |
|---|---|---|
| 语义 | 不可恢复的契约破裂 | 可预期的失败（文件不存在、解析失败…） |
| 机制 | 栈展开（默认），进程/线程终止 | 普通返回值 |
| 什么时候用 | bug、违反不变量、"到这里就是逻辑错了" | 一切外部输入、IO、解析、业务规则 |
| 类比 | assert/C assert | Go 的 error / C++ 的 expected |

`Option<T>`（值可能缺席）与 `Result<T, E>`（操作可能失败）是同一对思想的两个 enum：

```rust
enum Option<T> { Some(T), None }
enum Result<T, E> { Ok(T), Err(E) }
```

没有 null 指针、没有 NPE——"可能没有"在**类型里**，编译器逼你拆包后才能用值。

## 10.2 ? 运算符：错误界的管道

```rust
fn parse_score(s: &str) -> Result<i32, AppError> {
    let s = s.trim();
    if s.is_empty() { return Err(AppError::EmptyInput); }
    let n: i32 = s.parse()?;          // ← ? 的全部魔法
    if !(0..=100).contains(&n) {
        return Err(AppError::OutOfRange { value: n, min: 0, max: 100 });
    }
    Ok(n)
}
```

`expr?` 展开就是：

```rust
match expr {
    Ok(v) => v,
    Err(e) => return Err(From::from(e)),   // 注意 From：自动转换错误类型！
}
```

- 只能用在返回 `Result`/`Option`/... 的函数里；
- 错误类型不匹配时，靠 `From` 实现自动转换（10.4）；
- `Option` 世界里也有 `?`（None 即早退）；两者不能混用（`Result` 上 `?` 进 `Option` 函数不行，除非 `.ok()?` 转换）。

## 10.3 处理与组合：不离开 Result 世界

```rust
r.unwrap()                  // Err → panic（原型期专用）
r.expect("为什么不可能错")  // 同上，但带你的话（排错快 10 倍）
r.unwrap_or(0)              // 失败给默认
r.unwrap_or_else(|e| ...)   // 失败给计算值
r.unwrap_or_default()       // 失败给 Default
r.map(|v| v * 2)            // 改 Ok 里的值
r.and_then(|v| f(v))        // 链式（可能失败的 map，≈ monadic bind）
r.or_else(|e| ...)          // 换一个尝试
r.is_ok() / r.is_err() / r.ok()  // → Option
```

**unwrap 家族都按值消费 Result（self）**——示例实测：`bad.unwrap_or(0)` 之后 `bad` 已 move，再用就是 E0382。这也是为什么演示代码每条都新造一个。

风格纪律（本教程零 clippy 警告实测）：

- 字面量 `Ok(1).unwrap()` 会被 clippy `unnecessary_literal_unwrap` 抓——演示也要用运行期来源（`"abc".parse::<i32>()`）；
- `unwrap_or_else(|_| 恒定值)` 会被建议改 `unwrap_or`——闭包真的用到 e 才留 or_else。

## 10.4 自定义错误类型：手写 thiserror 等价物

生产代码的标准姿势（库 crate 尤其）——错误是 enum：

```rust
#[derive(Debug)]
enum AppError {
    EmptyInput,
    Parse(ParseIntError),                       // 包装底层错误
    OutOfRange { value: i32, min: i32, max: i32 },
}

impl fmt::Display for AppError { /* 每个变体一句话（给人看） */ }
impl std::error::Error for AppError {
    fn source(&self) -> Option<&(dyn Error + 'static)> {
        match self { AppError::Parse(e) => Some(e), _ => None }  // 错误链
    }
}
impl From<ParseIntError> for AppError {
    fn from(e: ParseIntError) -> Self { AppError::Parse(e) }     // 给 ? 用
}
```

四件套：`Debug`（derive）+ `Display`（人读）+ `Error::source`（错误链根因）+ `From`（让 `?` 自动包装）。手写一遍是为了懂原理；**实际项目用 `thiserror` 一个属性搞定全部**：

```rust
#[derive(Debug, thiserror::Error)]
enum AppError {
    #[error("输入为空")]
    EmptyInput,
    #[error("解析失败：{0}")]
    Parse(#[from] ParseIntError),    // from 自动生成
}
```

## 10.5 main 也可以返回 Result

```rust
fn main() -> Result<(), Box<dyn std::error::Error>> {
    let cfg = std::fs::read_to_string("config.toml")?;   // 满屏 ? 而不 unwrap
    Ok(())
}
```

Err 时运行时打印 Debug 并以非零码退出——**小工具的黄金写法**。`Box<dyn Error>` 是"任意错误"的逃生门；追求精细错误处理的应用用 `anyhow`（应用侧）+ `thiserror`（库侧）的生态惯例。

## 10.6 panic 的边界（什么时候可以炸）

允许 panic 的场景：数组下标越界（你是调用方， invariant 你负责）、`Option::expect`（按约定不可能 None）、断言（`assert_eq!` 测试里）、第三方库的 panic。

要 recover：线程边界能接住 panic（`JoinHandle` 返回 Err，22 章）；同线程内 `catch_unwind` 是逃生舱不是 try/catch（不保证清理、不是控制流工具）。

**规则：库代码不 panic（返回 Result），应用代码边界处 assert。**

## 10.7 错误报告的层次

```text
error（出了什么错，给人读）→ source（根因链）→ backtrace（RUST_BACKTRACE=1）
```

`anyhow` 的 `{:?}` 打印会整链展开 + backtrace。调试期记得开 `RUST_BACKTRACE=1`——三个 shell 写法不一样：

```bash
# macOS / Linux
RUST_BACKTRACE=1 cargo run
```

```powershell
# Windows PowerShell
$env:RUST_BACKTRACE="1"; cargo run
```

```bat
:: Windows cmd
set RUST_BACKTRACE=1 && cargo run
```

## 10.8 坑位清单

1. **unwrap 消费所有权**：`r.unwrap()` 之后 r 已 move——连环演示每条新造一个。
2. **`?` 在 main 里也要返回类型匹配**：main 返回 `()` 的旧签名里用 `?` 编译错——改成 `Result<(), Box<dyn Error>>`。
3. **From 没实现时 ? 报错晦涩**："the trait `From<X>` is not implemented"——指错误转换缺失，不是 ? 语法问题。
4. **Option 与 Result 不能同一个 ? 链**：用 `.ok()`/`.ok_or(err?)` 在两者间换轨。
5. **expect 的信息写"约定"而不是"程序崩了"**：好信息 = 为什么这里不可能失败。
6. **unwrap_or_else 参数是闭包**：传函数名要小写约定一致；恒定值会被 clippy 劝退到 unwrap_or。
7. **库 panic 会传染调用方**：API 文档写明 panic 条件（`# Panics` 段落），或干脆返回 Result。
8. **吞错误是反模式**：`let _ = fallible();` 连日志都没有——至少 `if let Err(e) = ... { log(e) }`。

---

上一章：[09 集合](09-collections.md) · 下一章：[11 泛型](11-generics.md)
