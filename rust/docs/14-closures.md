# 14 · 闭包 ⭐

> 对应示例：`examples/14_closures/`
>
> 语法十分钟；难点在捕获方式与 Fn/FnMut/FnOnce 三兄弟——
> 它们决定闭包能存哪、能被调几次。迭代器（15 章）与线程（22 章）全程依赖这里。

## 14.1 语法：能省的都省了

```rust
let add1 = |x: i32| x + 1;                 // 参数类型通常可推断
let add2 = |x: i32| -> i32 { x + 1 };      // 显式返回类型
let unit = || println!("无参闭包");          // 无参：||
let pair = |a, b| (a, b);                  // 多参
```

闭包 = 匿名函数 + **捕获环境**。类型推断比 fn 函数激进（首次调用即定型，两种类型调用同一个闭包会编译错）。

## 14.2 捕获三种方式（编译器自动选最小权限）

```rust
let factor = 10;
let scale = |x| x * factor;        // 只读 → 借用 &factor
println!("{factor}");              // factor 仍可用 ✔

let mut count = 0;
let mut bump = || count += 1;      // 要修改 → 独占 &mut count
bump(); bump();
// let r = &count;                 // ← 编译错：bump 还活着，独占借用未释放

let owned = String::from("数据");
let consume = move || drop(owned); // move：把所有权搬进闭包
// println!("{owned}");            // ← 编译错：owned 已 move
```

编译器按"闭包体怎么用捕获变量"自动选择最小权限：

- 只读 → `&T` 共享借用（Fn）
- 修改 → `&mut T` 独占借用（FnMut）
- 消耗（move 关键字或类型需要）→ 按值转移所有权（FnOnce）

**`move` 关键字**：强制按值捕获（最常用的场景：把数据交给线程——闭包必须活得比当前栈帧久，借用局部变量是不可能的，22 章实战）。`move` 与捕获方式正交：`move || x + 1` 按值捕获但只读（仍是 Fn）。

## 14.3 Fn / FnMut / FnOnce：能力递减链

Rust 的闭包不是语言内建类型——它是**编译器自动生成的结构体 + trait 实现**。每个闭包表达式对应一个匿名结构体，捕获的变量是它的字段；调用语法 `f(x)` 被脱糖为 trait 方法调用：

```rust
// 标准库源码（简化）——三个 trait 的继承关系一目了然
pub trait FnOnce<Args> {
    type Output;
    fn call_once(self, args: Args) -> Self::Output;      // 消耗 self
}
pub trait FnMut<Args>: FnOnce<Args> {
    fn call_mut(&mut self, args: Args) -> Self::Output;  // 可变借用
}
pub trait Fn<Args>: FnMut<Args> {
    fn call(&self, args: Args) -> Self::Output;          // 共享借用
}
```

| trait | 调用方式 | 捕获 | 可调用次数 | 典型 |
|---|---|---|---|---|
| `Fn` | `call(&self)` | 共享引用（只读） | 无限 | `x * factor` |
| `FnMut` | `call_mut(&mut self)` | 可变引用（要改环境） | 多次（需 mut 绑定） | `count += 1` |
| `FnOnce` | `call_once(self)` | 按值（消耗捕获物） | **恰好一次** | `drop(owned)` |

继承链：**Fn ⊃ FnMut ⊃ FnOnce**（满足 Fn 的自动满足 FnMut/FnOnce——只读闭包哪里都能去，反方向不行）。编译器按闭包体自动实现**最宽松可能**的那个。

这套设计叫**非装箱闭包（Unboxed Closure）**：早期 Rust 把捕获变量装箱到堆上，LLVM 难以内联优化；改成"结构体字段 + trait 调用"后，单态化让一切发生在编译期，零运行期开销——这是 Rust 零成本抽象哲学的又一次体现。

### 编译器到底生成了什么

闭包的脱糖可以手动模拟——这解释了为什么 FnOnce 只能调一次、为什么 move 闭包可以多次调用。以两个闭包为例：

```rust
// 闭包 1：消耗捕获变量
let v: Vec<i32> = vec![];
let c = || drop(v);    // drop 按值收参 → v 被 move 捕获
c();
// c();                // ← 编译错：use of moved value

// 闭包 2：只读捕获（move 版）
let v2 = vec![1, 2, 3];
let c2 = move || v2.len();   // move 按值捕获，但调用时只读
c2(); c2();                   // ✔ 可以多次调用
```

编译器对闭包 1 的展开近似于：

```rust
struct ClosureEnv { v: Vec<i32> }   // 捕获变量是字段，不是引用

impl FnOnce<()> for ClosureEnv {
    type Output = ();
    extern "rust-call" fn call_once(self, _: ()) {   // self 按值传入
        drop(self.v);                                 // v 的所有权随 self 一起被消耗
    }
}
// 注意：无法为 ClosureEnv 实现 FnMut——call_mut 只给 &mut self，
// 但函数体需要 move self.v 出去，&mut 权限不够。编译器因此只实现 FnOnce。

let c = ClosureEnv { v };
c.call_once();    // c 被 move 进 call_once——此后 c 不可用
// c.call_once(); // ← 编译错：c 已 move
```

闭包 2 的展开：

```rust
struct ClosureEnv2 { v2: Vec<i32> }   // move 捕获，字段是拥有的 Vec

impl Fn<()> for ClosureEnv2 {          // 注意：实现了 Fn，不是 FnOnce！
    extern "rust-call" fn call(&self, _: ()) -> usize {
        self.v2.len()                   // 只读 → &self 足够
    }
}
// move 只影响"捕获方式"（按值 vs 借用），不影响"调用方式"（Fn/FnMut/FnOnce）。
// 决定调用方式的是闭包体怎么用 self：只读 → Fn，改字段 → FnMut，消耗字段 → FnOnce。
```

关键洞察：**move 关键字和 Fn/FnMut/FnOnce 是正交的两个维度**。move 管"捕获时拿所有权还是拿引用"；Fn 家族管"调用时要什么权限"。`move || v.len()` 按值捕获但只读调用——两个维度自由组合。

函数项/函数指针实现了 Fn——普通函数能传给一切收闭包的参数。

## 14.4 闭包作参数

```rust
fn call_fn<F: Fn(i32) -> i32>(f: F, v: i32) -> i32 { f(v) }
fn call_fn_mut<F: FnMut(i32) -> i32>(mut f: F, v: i32) -> i32 { f(v) }  // 注意 mut f
fn call_fn_once<F: FnOnce(i32) -> i32>(f: F, v: i32) -> i32 { f(v) }
```

**参数约束 = 使用声明**：只调用一次就写 FnOnce（接受面最大）；要反复调就 Fn/FnMut。标准库大量这么分层（`map` 收 FnOnce MutBoot……）。闭包是匿名的，但每个有独一无二的**编译期类型**——所以泛型参数 F 按具体类型单态化，零开销。

### 函数指针 `fn`：闭包的"无捕获亲戚"

除了闭包 trait，Rust 还有一个具体的**函数指针类型** `fn(i32) -> i32`（小写 fn，是类型不是关键字 trait）：

```rust
fn add_one(x: i32) -> i32 { x + 1 }
fn do_twice(f: fn(i32) -> i32, arg: i32) -> i32 { f(f(arg)) }

do_twice(add_one, 5);        // 传函数本身，不用包闭包
```

函数指针实现了**全部三种** Fn trait（Fn + FnMut + FnOnce）——所以任何收闭包的泛型函数也自动收函数指针。反过来不成立：函数指针不能捕获环境。选型：**需要捕获 → 闭包；不需要 → 两种都行，函数指针更直白**（`unwrap_or_else(Vec::new)` 就是传函数指针的实例）。枚举构造器也是函数指针：`Some`、`Ok` 可以直接当参数传。

## 14.5 闭包作返回值

```rust
// impl Trait：静态分发（推荐）
fn make_adder(n: i32) -> impl Fn(i32) -> i32 + 'static {
    move |x| x + n            // move 必须：n 必须进闭包，才能活得过 make_adder 的栈帧
}

// Box<dyn>：动态分发（需要装进同一集合/跨trait 时）
fn make_counter() -> Box<dyn FnMut() -> i32> {
    let mut n = 0;
    Box::new(move || { n += 1; n })     // 有状态 → FnMut！
}
let mut counter = make_counter();       // 调用方也要 mut
counter(); counter();
```

两个实测坑：返回闭包忘了 `move` → 借用局部变量编译错；**有状态闭包装箱要 `Box<dyn FnMut>`**——装成 `Box<dyn Fn>` 是 E0525（expected Fn, found FnMut）。

## 14.6 标准库里的闭包

```rust
nums.sort_by_key(|n| -n);                       // 排序键
words.iter().filter(|w| w.len() > 5)            // 过滤
v.iter().map(|x| x * 2).fold(0, |acc, x| acc + x)  // 变换/聚合
nums.iter().max_by_key(|x| x * x)               // 选最
```

15 章的迭代器管道就是"闭包流"。写出接受闭包的 API（如 `set_timeout(30, || ...)`）的语法到这里就齐了。

## 14.7 应用：记忆化

```rust
let mut cache: HashMap<u32, u32> = HashMap::new();
let mut fib = |n: u32| -> u32 {
    if let Some(&hit) = cache.get(&n) { return hit; }
    let (mut a, mut b) = (0u32, 1u32);
    for _ in 0..n { (a, b) = (b, a + b); }
    cache.insert(n, a);
    a
};
fib(10); fib(40);        // 闭包与环境双向绑定（读缓存 + 写缓存）
```

闭包借用 cache 且要修改 → FnMut → 绑定声明 `let mut fib`。类型系统把"这个闭包会改环境"如实转达给了每个使用者。

## 14.8 坑位清单

1. **调用 FnMut 闭包的绑定也要 mut**：`let mut f = ...; f(x)`——闭包自身状态在环境里，调用是"修改它"。
2. **move 闭包并非 FnOnce**：`move || x.len()` 是 move + Fn（只读）——move 只管捕获方式，Fn/FnMut/FnOnce 由"怎么用捕获物"决定。
3. **FnOnce 只能调一次**：第二次调用直接编译错（示例 consume 闭包实测）——消费型 API（`Option::unwrap_or_else` 收 FnOnce）因此只能用一次。
4. **返回闭包忘 + 'static**：`impl Fn() -> i32` 不带 `+ 'static` 时若闭包无捕获没事；一旦 move 进非 static 数据，需要显式标注。
5. **同表达式两次借用 peekable/迭代器**（15 章关联坑）：`println!("{:?}", p.peek(), p.next())` 双可变借用——拆两句。
6. **闭包类型每个独一无二**：两个"长得一样"的闭包不能互相赋值/放进同一个 `Vec<F>`——需要异构集合时 Box<dyn Fn>。
7. **递归闭包写不出来**：闭包没有名字可自引用——用 fn 或改设计（真需要时 Y 组合子/Box 分配是下策）。

---

上一章：[13 生命周期](13-lifetimes.md) · 下一章：[15 迭代器](15-iterators.md)
