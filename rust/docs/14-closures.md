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

**`move` 关键字**：强制按值捕获（最常用的场景：把数据交给线程——闭包必须活得比当前栈帧久，借用局部变量是不可能的，22 章实战）。`move` 与捕获方式正交：`move || x + 1` 按值捕获但只读（仍是 Fn）。

## 14.3 Fn / FnMut / FnOnce：能力递减链

| trait | 捕获 | 可调用次数 | 典型 |
|---|---|---|---|
| `Fn` | 共享引用（只读） | 无限 | `x * factor` |
| `FnMut` | 可变引用（要改环境） | 多次（需 mut 绑定） | `count += 1` |
| `FnOnce` | 按值（消耗捕获物） | **恰好一次** | `drop(owned)` |

继承链：**Fn ⊃ FnMut ⊃ FnOnce**（满足 Fn 的自动满足 FnMut/FnOnce——只读闭包哪里都能去，反方向不行）。编译器按闭包体自动实现**最宽松可能**的那个。

函数项/函数指针实现了 Fn——普通函数能传给一切收闭包的参数。

## 14.4 闭包作参数

```rust
fn call_fn<F: Fn(i32) -> i32>(f: F, v: i32) -> i32 { f(v) }
fn call_fn_mut<F: FnMut(i32) -> i32>(mut f: F, v: i32) -> i32 { f(v) }  // 注意 mut f
fn call_fn_once<F: FnOnce(i32) -> i32>(f: F, v: i32) -> i32 { f(v) }
```

**参数约束 = 使用声明**：只调用一次就写 FnOnce（接受面最大）；要反复调就 Fn/FnMut。标准库大量这么分层（`map` 收 FnOnce MutBoot……）。闭包是匿名的，但每个有独一无二的**编译期类型**——所以泛型参数 F 按具体类型单态化，零开销。

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
