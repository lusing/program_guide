# Rust 速查表（1.98 / edition 2024）

语法速查 + 坑位索引。详细讲解见对应章（表中 N.M = 第 N 章 M 节）。

## 1. 命令速查（02/17）

```bash
cargo new/run/build/check/test        # 日常五件套
cargo run -- args                     # -- 之后传程序参数
cargo build --release                 # 优化构建 → target/release/
cargo test 名字片段                   # 按名过滤；-- --nocapture 看 stdout
cargo clippy --all-targets -- -D warnings   # lint 当错误（本教程纪律）
cargo fmt [--check]                   # 格式化 / 只检查
cargo add serde                       # 加依赖（自动写 feature）
cargo doc --open                      # 生成并浏览 API 文档
cargo tree -p 包名                    # 依赖树
cargo test -p 包名                    # workspace 里限定包
```

## 2. 变量与类型（03）

```rust
let x = 5;  let mut y = 0;      // 默认不可变；mut 才能改
let s = "3";  let s: i32 = s.parse().unwrap();   // 遮蔽可换类型
let t = (1, 2.0);  let a = [1u8; 4];   // 元组/数组
x as u8                             // 显式转换（截断！300→44）
u8::try_from(300)                   // 安全转换（Result）
"42".parse::<i32>()                 // turbofish
(n).checked_add(1) / wrapping / saturating / overflowing  // 溢出四策略
const C: u32 = 1;  static S: &str = "s";  type Km = i32;
```

| 坑 | 解法 |
|---|---|
| 整数溢出 Debug panic | 写明策略：checked/wrapping/saturating（03.7） |
| `as` 静默截断 | 边界转换用 try_from（03.6） |
| `if 1 {}` 编译不过 | 条件必须 bool（03.3） |

## 3. 所有权与借用（04/05）⭐

```rust
let s2 = s1;                  // move（String 等堆类型）；s1 此后不可用
let s2 = s1.clone();          // 显式深拷贝
let r = &s;  let w = &mut s;  // 共享借用（多个）/独占借用（仅一个）
fn f(s: &str)                 // 参数黄金法则：只读收 &T（字符串用 &str）
fn g(s: &mut T)               // 就地改
fn h(s: T)                    // 消耗/存储
```

| 报错 | 意思 | 常见解法 |
|---|---|---|
| borrow of moved value | 值已转移 | clone / 改借用 / 重排 |
| cannot borrow as mutable ... also borrowed | 读写借用并存 | 缩短借用（NLL）/ 拆字段 / RefCell(18) |
| second mutable borrow | 两个 &mut | 顺序化使用 |
| does not live long enough | 引用比数据活得久 | 返回值而非引用 / 延长 owner |

## 4. 字符串（06）⭐

```rust
let lit = "字面量";                 // &'static str
let owned = String::from("堆上");    // 或 "x".to_string()
let view: &str = &owned;             // 免费
let back: String = lit.to_string();  // 分配
s.push('c'); s.push_str("追加");     // &mut String
let s = format!("{a}-{b}");          // 拼接首选（+ 吃左操作数！）
"你好".len()          // 6：字节数
"你好".chars().count() // 2：字符数
s.get(0..3)           // Option<&str>：边界安全
s.chars().nth(1)      // 第 n 个字符
b"ascii"              // 字节串仅限 ASCII；中文用 "中文".as_bytes()
```

## 5. 枚举与匹配（08）

```rust
enum E { Quit, Move { x: i32 }, Write(String) }
match e {
    E::Move { x } if x > 0 => "正向",   // 绑定 + 守卫
    E::Write(s) => s,
    _ => "其他",                        // 必须穷尽
}
if let Some(v) = opt { }                // 单分支
let Some(c) = it.next() else { return }; // let-else：失败必须发散
matches!(opt, Some(n) if n > 5)          // 布尔判定
```

## 6. 错误处理（10）

```rust
fn f() -> Result<T, E> { expr? }        // ? = Ok取值 / Err 上抛(From 转换)
r.unwrap() / r.expect("为什么")          // 原型期；生产收殓
r.unwrap_or(0) / unwrap_or_else(|e| ..) / unwrap_or_default()
r.map(..) / r.and_then(..)              // 组合子
fn main() -> Result<(), Box<dyn Error>> // main 也能 ?
// 自定义错误四件套：Debug + Display + Error(source) + From
// 实际项目：thiserror(库) / anyhow(应用)
```

## 7. 泛型与 Trait（11/12）⭐

```rust
fn f<T: PartialOrd>(xs: &[T]) -> &T
fn g<K, V>(k: K) where K: Display, V: Clone   // where 子句
fn h(x: &impl Summary)                  // 静态分发语法糖
fn i() -> impl Iterator<Item=u32>       // 返回具体类型（藏名）
Vec<Box<dyn Summary>>                   // 动态分发（胖指针+vtable）
impl Add for Vec2 { type Output = Vec2; ... }  // 运算符重载
impl<T, U> Into<U> for T where U: From<T>      // blanket impl
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Default)]
```

| 坑 | 解法 |
|---|---|
| dyn Trait 直接做参数/字段 | &dyn / Box<dyn>（12.3） |
| trait 不 object-safe | 有泛型方法/返回 Self → 不能 dyn（12.7） |
| 孤儿规则拒绝 impl | newtype 包装（12.7） |

## 8. 生命周期（13）⭐

```rust
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str   // 取交集
struct Excerpt<'a> { part: &'a str }                 // 结构体持引用
fn first_word(s: &str) -> &str                       // 省略规则覆盖
let s: &'static str = "字面量";
fn f<T: Clone + 'static>(v: T)                       // 'static = 不含短命借用
```

## 9. 闭包与迭代器（14/15）⭐

```rust
let f = |x: i32| x + 1;        // Fn：只读捕获
let mut g = || { count += 1 }; // FnMut：改捕获（绑定也要 mut）
let h = move || drop(owned);   // FnOnce：消耗捕获（move 搬所有权）
fn apply<F: Fn(i32)->i32>(f: F, v: i32) -> i32
fn make() -> impl Fn(i32)->i32 + 'static { move |x| x + n }
// 迭代器三来源
for x in &v { }    // iter()：&T
for x in &mut v { } // iter_mut()：&mut T
for x in v { }      // into_iter()：T（消耗容器）
v.iter().filter(|x| **x > 0).map(|x| x*2).collect::<Vec<_>>()
.filter_map / .enumerate / .zip / .chain / .take / .skip
.flatten / .flat_map / .rev / .peekable / .inspect
.sum() / .fold(init, f) / .count / .max / .find / .position / .any / .all
impl Iterator for Fib { type Item = u64; fn next(&mut self) -> Option<u64> }
```

| 坑 | 解法 |
|---|---|
| filter 闭包收到 `&T` | `*x` 或先 `.copied()`（15.8） |
| collect 不执行 | 惰性——接消费器（15.2） |
| `collect::<i32>()` 不存在 | 用 `.sum()`（15.4） |
| 有状态闭包装 `Box<dyn Fn>` | 换 `Box<dyn FnMut>`（14.8） |

## 10. 并发与 async（22/23）⭐

```rust
let h = thread::spawn(move || work());  // move 必须
h.join().unwrap();                       // panic 以 Err 回来
thread::scope(|s| { s.spawn(|| 借用局部()); });   // scoped：免 Arc
let (tx, rx) = mpsc::channel();          // drop(tx) 后 rx 迭代终止
let c = Arc::new(Mutex::new(0));         // lock() 的 guard RAII 释放
let r = RwLock::new(x);                  // read 多写一
h.fetch_add(1, Ordering::Relaxed);       // AtomicUsize
// async
#[tokio::main] async fn main() { f().await; }
tokio::join!(a, b);   tokio::select! { x = a => .., _ = b => .. }
tokio::spawn(async move { .. });          // Send + 'static
tokio::task::spawn_blocking(|| 阻塞活);   // 阻塞/CPU 密集丢这里
timeout(dur, fut).await                   // Err(Elapsed)
```

| 坑 | 解法 |
|---|---|
| async 里 thread::sleep / std 锁 | tokio 版或 spawn_blocking（23.10） |
| spawn 借用局部变量 | move / Arc / scoped（23.10） |
| rx 死等 | 忘 drop(tx)（22.8） |
| guard 跨 await | 换 tokio::sync::Mutex（23.10） |

## 11. edition 2024 迁移坑位索引（01/19）

| 旧写法 | 2024 写法 | 章 |
|---|---|---|
| `extern "C" { fn f(); }` | `unsafe extern "C" { fn f(); }` | 19 |
| `#[no_mangle] pub extern "C" fn` | `#[unsafe(no_mangle)] pub extern "C" fn` | 19 |
| `static mut` 可取引用 | 只许 unsafe 块内整体读写；`&MUT` 拒绝 | 19 |
| `gen`/`raw` 当标识符 | 保留字，改名 | 01 |
| `cargo fix --edition` | 官方自动迁移大半 | 01 |

## 12. clippy 高频提醒（本教程零警告实测）

| lint | 场景 | 处置 |
|---|---|---|
| `unnecessary_literal_unwrap` | 对字面量 Ok/Err 调 unwrap 家族 | 用运行期来源（10.3） |
| `print_literal` | `println!("{}", "字面量")` | 写进格式串或先绑定变量（02.6） |
| `uninlined_format_args` | `println!("{}", x)` | 改 `{x}` 内联（02.3） |
| `vec_init_then_push` | new 后连环 push | 用 vec![] 或教学豁免注明（16.8） |
| `useless_vec` | 定长数据用 vec![] | 改数组（09.9） |
| `manual_range_patterns` | `1 | 2 | 3` | 改 `1..=3`（08.7） |
| `unnecessary_map_or` | `map_or(false, p)` | 改 `is_ok_and(p)`（24.10） |
| `approx_constant` | 手写 3.14159 | 用 `std::f64::consts::PI`（02 实测） |
| `redundant_pattern_matching` | `matches!(x, None)` | 改 `is_none()`（08 实测） |
| `len() == 0` | 长度判零 | `is_empty()`（09/13 实测） |

## 13. 格式化占位符（02）

| 占位 | 用途 |
|---|---|
| `{}` `{x}` `{0}` `{name=v}` | Display / 内联 / 位置 / 命名 |
| `{:?}` `{:#?}` | Debug 单行 / 多行 |
| `{:<8}` `{:>8}` `{:^8}` | 左/右/中对齐 |
| `{:05.2}` | 补零宽度 5、精度 2 |
| `{:#x}` `{:#o}` `{:#b}` | 0x / 0o / 0b 前缀 |
| `{:.3}` `{e}` | 精度 / 科学计数（f64） |
