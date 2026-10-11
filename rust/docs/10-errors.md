# 10 · 错误处理

> 对应示例：`examples/10_errors/`
>
> Rust 没有 null（几乎）、没有异常（真的没有）。错误是**普通的值**，
> 由类型系统强制你表态：处理、上抛、或者明确地炸。

## 10.1 分层错误处理：四条轨道

Rust 的错误处理不是"异常 vs 返回值"二选一，而是**四层分级**，每层有明确的适用场景：

| 层 | 工具 | 适用场景 |
|---|---|---|
| 1 | `Option<T>` | 有/无：HashMap 查不到键、队列取空——不是错误，是正常状态 |
| 2 | `Result<T, E>` | 可合理解决的失败：文件不存在、权限被拒、解析出错 |
| 3 | panic | 无法合理解决的 bug：违反不变量、索引越界、逻辑错误 |
| 4 | abort | 灾难性后果：显式调 `std::process::abort`，不做任何清理 |

这套方案源自函数式语言（Haskell 的 Maybe/Either），用和类型（sum type）做基于返回值的错误处理——粒度更细、更优雅。Rust 中"线程恐慌"就是其他语言的"异常"，但它是**最后一道防线**，不是控制流工具。

`Option<T>` 与 `Result<T, E>` 是同一思想的两个粒度：

```rust
enum Option<T> { Some(T), None }
enum Result<T, E> { Ok(T), Err(E) }
```

`Option<T>` 可以看作"忽略了错误类型的 `Result<T, ()>`"——两者可以互转（`.ok()`、`.ok_or(e)`）。没有 null 指针、没有 NPE——"可能没有"在**类型里**，编译器逼你拆包后才能用值。

`Result` 类型带 `#[must_use]` 属性：**对返回的 Result 不处理，编译器会警告**。这是"错误不能被静默吞掉"的编译期强制——比 C 检查返回值、Go 检查 error 的君子协定硬得多。

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

### 错误链：把根因一层层包起来

真实系统的错误很少是单层的——读文件失败 → 因为解析配置失败 → 因为某行格式错。`Error::source` 就是给这个链条准备的：每一层错误都把**下一层**装进来，打印时逐层下钻到根因。手写模式：

```rust
use std::error::Error;
use std::fmt;

#[derive(Debug)]
enum ConfigError {
    Io(std::io::Error),                          // 第 1 层：IO 失败
    Parse { line: usize, source: ParseIntError }, // 第 2 层：解析失败（带位置）
}

impl fmt::Display for ConfigError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            ConfigError::Io(e) => write!(f, "读取配置文件失败: {e}"),
            ConfigError::Parse { line, .. } => write!(f, "第 {line} 行解析失败"),
        }
    }
}

impl Error for ConfigError {
    fn source(&self) -> Option<&(dyn Error + 'static)> {
        match self {
            ConfigError::Io(e) => Some(e),               // 链到 io::Error
            ConfigError::Parse { source, .. } => Some(source), // 链到 ParseIntError
        }
    }
}
```

`source` 返回 `Option` 的原因：链尾的错误（如 `ParseIntError`）没有更底层的根因，返回 `None`。打印端用 `{:?}`（`anyhow` 的默认格式）会自动沿 `source` 链展开成：

```text
读取配置文件失败: 第 3 行解析失败
Caused by: 第 3 行解析失败
Caused by: invalid digit found in string
```

一层 `Caused by:` 对应一次 `source` 下钻——错误链让"哪一步、为什么、根因是什么"一目了然。

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

panic 的默认行为是**栈展开**（stack unwind）：沿调用栈反向遍历，清理每个函数的局部数据。这需要二进制里存储额外的清理信息。如果你需要让二进制更小（比如嵌入式），可以在 Cargo.toml 里切换为**直接中止**（abort）——不做任何清理，由操作系统回收内存：

```toml
[profile.release]
panic = 'abort'    # 默认是 'unwind'；切换后二进制更小，但无法 catch_unwind
```

要 recover：线程边界能接住 panic（`JoinHandle` 返回 Err，22 章）；同线程内 `catch_unwind` 是逃生舱不是 try/catch（不保证清理、不是控制流工具）。注意 `panic = 'abort'` 时 `catch_unwind` 也失效——进程直接终止。

`catch_unwind` 的签名有个容易忽略的约束：

```rust
pub fn catch_unwind<F: FnOnce() -> R + UnwindSafe, R>(f: F) -> Result<R, Box<dyn Any + Send>>
```

`UnwindSafe` 是一个自动实现的标记 trait——大多数类型自动满足，但 `&mut T`、`RefCell` 这类"内部可变且非原子"的类型**不是** `UnwindSafe`：panic 展开时它们可能留下半修改状态，接住 panic 继续跑会读到不一致数据。真需要传闭包捕获 `&mut` 时，显式 `AssertUnwindSafe` 包装是"我知道风险"的签字：

```rust
use std::panic::{catch_unwind, AssertUnwindSafe};

let mut log = Vec::new();
let result = catch_unwind(AssertUnwindSafe(|| {
    log.push("步骤1");
    panic!("模拟崩溃");
}));
// result 是 Err——panic 被接住了，log 可能只推到一半（这正是 UnwindSafe 担心的）
assert!(result.is_err());
```

`AssertUnwindSafe` 不是 unsafe——它是"我审阅过这个闭包的 panic 安全性"的显式声明。测试框架（`cargo test`）内部就是用 `catch_unwind` 让每个测试独立崩溃、互不影响。

### panic safety：从 C++ 异常安全到 Rust

panic safety 是 C++ 异常安全（exception safety）的 Rust 版。C++ 定义了四层保证：no-throw（内部全处理）、strong（失败可回滚到初始状态）、basic（不泄漏资源）、none（无保证）。Rust 标准库的目标是：**即使发生 panic，也不产生内存不安全或线程不安全**。

标准库 `Box<[T]>` 的 `Clone` 实现是 panic safety 的教科书案例：

```rust
// 标准库源码（简化）——为什么引入 BoxBuilder 中间类型？
impl<T: Clone> Clone for Box<[T]> {
    fn clone(&self) -> Self {
        let mut new = BoxBuilder {
            data: RawVec::with_capacity(self.len()),
            len: 0,
        };
        for item in self.iter() {
            unsafe {
                std::ptr::write(new.data.ptr().add(new.len), item.clone());
                // ↑ item.clone() 可能 panic！T 是泛型，谁保证 clone 不 panic？
                new.len += 1;
            }
        }
        unsafe { new.into_box() }
    }
}

struct BoxBuilder<T> { data: RawVec<T>, len: usize }

impl<T> Drop for BoxBuilder<T> {
    fn drop(&mut self) {
        // panic 时：RAII 保证这个析构被调用
        // 只 drop 已初始化的前 len 个元素
        unsafe {
            for i in 0..self.len {
                std::ptr::drop_in_place(self.data.ptr().add(i));
            }
        }
    }
}
```

如果不用 `BoxBuilder` 直接在 `clone()` 里写循环，`item.clone()` panic 时——部分元素已写入 RawVec，但 RawVec 不知道它们存在（`len` 没更新），不会 drop 它们——**泄漏 + 潜在的双重释放**（如果 RawVec 的析构又尝试清理）。`BoxBuilder` 用 RAII 保证：无论正常结束还是 panic 中途退出，`Drop` 都会执行，只清理已初始化的部分。

这个模式在标准库中反复出现（`Vec::extend_with`、`String::insert` 等）——**写 unsafe 容器时，假设一切外部回调都可能 panic，并保持数据结构在任何 panic 点都合法**。

### Mutex poison：panic safety 的运行时防线

22 章提到 Mutex 的毒锁机制——这里是完整故事。如果持锁线程在临界区 panic，数据结构可能处于半修改状态（比如 Vec 只 push 了一半）。Mutex 检测到这种情况后标记自己为 **poisoned**——后续 `lock()` 返回 `Err(PoisonError)` 而不是 `Ok(guard)`：

```rust
use std::sync::{Arc, Mutex};
use std::thread;

let data = Arc::new(Mutex::new(vec![1, 2, 3]));
let d = Arc::clone(&data);

let handle = thread::spawn(move || {
    let mut v = d.lock().unwrap();
    v.push(4);
    panic!("模拟崩溃");    // 持锁 panic → Mutex 被标记 poisoned
});

let _ = handle.join();     // 子线程 panic，join 返回 Err

// 主线程再 lock：返回 Err（不是 Ok）
match data.lock() {
    Ok(mut v) => println!("正常: {v:?}"),
    Err(poisoned) => {
        // poisoned.into_inner() 可以拿到数据——但你要自己判断数据是否可信
        let mut v = poisoned.into_inner();
        println!("毒锁恢复: {v:?}");   // [1, 2, 3, 4]——push 在 panic 前已完成
    }
}
```

poison 的设计意图：**宁可拒绝服务，也不给调用方一个可能损坏的数据**。`into_inner()` 是显式声明"我检查过数据一致性，愿意承担风险"。服务型代码常用 `lock().unwrap_or_else(|e| e.into_inner())` 加日志——继续服务，但留下审计痕迹。

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
