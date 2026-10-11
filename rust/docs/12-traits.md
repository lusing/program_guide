# 12 · Trait ⭐

> 对应示例：`examples/12_traits/`
>
> Trait 是 Rust 的接口、也是运算符重载入口、也是多态机制、也是抽象的通用货币。
> 一个概念身兼四职——这就是为什么它值一整章加一颗星。
> 本章深度参考《Rust 编程之道》第 3 章 trait 部分，按 edition 2024 重写并实测。

## 12.1 定义与实现

```rust
trait Summary {
    fn headline(&self) -> String;                  // 必须实现

    fn preview(&self) -> String {                  // 默认实现（可覆盖）
        format!("（{}……）", self.headline())
    }
}

struct Article { title: String, author: String }

impl Summary for Article {
    fn headline(&self) -> String {
        format!("《{}》— {}", self.title, self.author)
    }        // preview 不写 → 用默认
}
```

实现可以调默认方法，默认方法可以调必须方法——模板方法模式免费送。

**trait 的四种用法**（《Rust 编程之道》的框架，本章逐一展开）：

| 用法 | 是什么 | 本章 |
|---|---|---|
| 接口抽象 | 对类型行为的统一约束（上例） | 12.1 |
| 泛型约束 | 把泛型的能力限定在 trait 圈内 | 12.2 |
| 抽象类型 | trait 对象 / impl Trait，运行期或编译期的"间接类型" | 12.3 |
| 标签 trait | 空 trait 作编译器标记（Sized/Copy/Send/Sync） | 12.8 |

**孤儿规则（orphan rule）**：`impl Trait for Type` 中，trait 或 type 至少一个定义在当前 crate。`impl Display for Vec<i32>` ✘（都是外来的）；给自己的类型实现 `Display`/`Debug`/`From` ✔。这避免了全局命名空间里的实现冲突——生态共存的基石。

## 12.2 trait 约束：泛型的合同

```rust
fn notify(item: &impl Summary) { ... }     // 语法糖
fn notify<T: Summary>(item: &T) { ... }    // 等价展开（需要引用 T 本身时用这个）
fn top(item: &(impl Summary + Display)) { ... }   // 多约束
fn all<T>(items: &[T]) where T: Summary + Clone { ... }   // where 子句
```

**impl Trait 参数 = 静态分发**：编译期单态化（11 章），每个具体类型一份代码，调用直连、可内联。

**impl Trait 返回值**——藏具体类型：

```rust
fn top_headlines(items: &[Box<dyn Summary>]) -> impl Display { ... }
// 迭代器管线的标准姿势（15 章）：
fn ids(v: &[u32]) -> impl Iterator<Item = u32> + '_ {
    v.iter().copied().filter(|x| x % 2 == 0)
}
```

限制：只能返回**单一**具体类型（不能按分支返回两种不同闭包/迭代器），调用方不知道真名只能用声明的 trait 方法。多个参数各自写 `impl Trait` 时**彼此独立**（`fn f(a: impl X, b: impl X)` 允许 a、b 是不同类型）——这点和泛型 `<T: X>(a: T, b: T)` 不同，后者强制同型。

## 12.3 dyn Trait：动态分发与胖指针

```rust
let feed: Vec<Box<dyn Summary>> = vec![
    Box::new(article),     // 不同具体类型
    Box::new(weibo),       // 装进同一个集合
];
for item in &feed { item.headline(); }   // 运行期查 vtable
```

- `dyn Trait` 是**不定大小类型（DST）**，必须藏在指针后：`&dyn`、`Box<dyn>`；
- `&dyn Trait` 是**胖指针**：数据指针 + vtable 指针（16 字节，03 章 3.6），方法调用走表。

**trait 对象的内存布局**（原书第 3 章的图解，文字版）：

```text
&dyn Summary（16 字节）
├── data:   *mut ()   ──→  Article 实例（堆或栈）
└── vtable: *mut ()   ──→ [drop_in_place, size, align, headline(), preview(), ...]
                           ↑ 每个实现该 trait 的具体类型，编译器生成一张
```

运行期调用 `item.headline()` 的真实过程：取胖指针的 vtable 字段 → 按方法在 trait 定义中的序号查表 → 间接跳转到 `Article::headline`，并把 data 指针作为 self 传入。这就是"动态分发"的全部魔法——与 C++ 虚表同构，但**显式**（必须写 `dyn`）且受对象安全规则约束。

| | `impl Trait`（静态） | `Box<dyn Trait>`（动态） |
|---|---|---|
| 分发时机 | 编译期（单态化） | 运行期（vtable） |
| 每型一份代码 | 是（编译慢、二进制大） | 否（一份） |
| 调用开销 | 零（可内联） | 一次间接跳转 |
| 异构集合 | ✘ | ✔ |
| 条件返回不同类型 | ✘ | ✔ |

经验法则：**库的公开 API 优先泛型/impl Trait**（给调用方留优化空间），应用内部图省事可以 dyn。

## 12.4 关联类型：每个实现一份"输出类型"

```rust
trait Counter {
    type Item;
    fn next_count(&mut self) -> Option<Self::Item>;
}

impl Counter for Countdown {
    type Item = u32;                    // 实现时定死
    fn next_count(&mut self) -> Option<u32> { ... }
}
```

与泛型参数的差别：泛型 trait（`trait C<Item>`）允许一个类型多种实现；关联类型表达"**每个类型只有一种自然方式**"——`Iterator` 用关联类型（一个类型只有一种迭代元素），`Add<Rhs>` 用泛型参数（不同右操作数可以不同实现）。

**标准库的教科书案例——`Add`**：加法抽象要表达"右操作数类型"和"结果类型"，标准库选择了"泛型参数 + 关联类型"的混合：

```rust
pub trait Add<RHS = Self> {        // 泛型参数带默认值：不写就是 Self
    type Output;                   // 关联类型：结果类型每个实现只有一种
    fn add(self, rhs: RHS) -> Self::Output;
}

impl Add for u32 {                 // 等价于 Add<u32>
    type Output = u32;
    fn add(self, other: u32) -> u32 { self + other }
}
impl Add<&str> for String {        // String + &str 是另一种合法组合
    type Output = String;
    fn add(mut self, other: &str) -> String { self.push_str(other); self }
}
```

于是 `a + b` 在编译期被翻译成 `Add::add(a, b)`——**运算符就是 trait 方法**（`+` 对应 `#[lang = "add"]` 的 Add）。这也解释了 06 章的坑：`String + String` 不存在，因为标准库只为 `String` 实现了 `Add<&str>`。

## 12.5 标准库高频 trait 速览

| trait | 带来什么 | 手写/derive |
|---|---|---|
| `Display`/`Debug` | `{}` / `{:?}` 打印 | Display 手写，Debug derive |
| `Clone`/`Copy` | 显式/隐式复制 | derive（04 章） |
| `PartialEq`/`Eq` | `==` | derive；语义自定义时手写 |
| `Hash` | HashMap 键 | derive |
| `Default` | `Default::default()` | derive 或手写 |
| `From<T>`/`Into<T>` | 转换：**实现 From 白送 Into** | 手写或 derive |
| `Add`/`Mul`/`Index`… | 运算符重载 | 手写（见下） |
| `Iterator` | for 循环 + 全套适配器 | 手写（15 章） |
| `Drop` | 析构 | 手写（04 章） |
| `Deref`/`DerefMut` | 解引用强转 | 智能指针用（18 章） |
| `Send`/`Sync` | 跨线程标记（自动） | 几乎从不手写（22 章） |

运算符重载实例——给 Vec2 实现 `Add`：

```rust
impl Add for Vec2 {
    type Output = Vec2;                 // 关联类型指定结果
    fn add(self, rhs: Vec2) -> Vec2 { Vec2 { x: self.x + rhs.x, y: self.y + rhs.y } }
}
let c = a + b;      // 走的是刚才那个 impl
```

能重载的运算符固定一张表（std::ops），不能发明新符号、不能重载 `&&`/`||`（短路语义不可侵犯）。

## 12.6 blanket impl 与 trait 的组合力

```rust
impl<T: Into<String>> From<T> for Name { ... }   // 对一切能转 String 的类型生效

// 标准库真例：实现 From 自动获得 Into
impl<T, U> Into<U> for T where U: From<T> { ... }
```

Blanket impl（对满足约束的所有类型批量实现）是 std 泛型生态的粘合剂——你的 trait 也能这么长尾。

**trait 继承**是组合的另一面：`trait Paginate: Page + PerPage` 表示"要实现 Paginate 必须先实现 Page 和 PerPage"——子 trait 自动获得父 trait 的方法。Rust 没有类型层面的继承（结构体不能继承结构体），**组合优于继承**是语言级立场：行为复用走 trait 继承 + blanket impl，数据复用走字段。

```rust
trait Page { fn set_page(&self, p: i32) { ... } }
trait PerPage { fn set_per_page(&self, n: i32) { ... } }
trait Paginate: Page + PerPage {          // 同时继承两个父 trait
    fn set_skip(&self, num: i32) { ... }
}
impl<T: Page + PerPage> Paginate for T {}  // 一切"已分页"类型自动可跳页
```

## 12.7 对象安全（object safety）：dyn 的准入线

不是每个 trait 都能做 `dyn Trait`。规则（满足其一即**不**对象安全）：

- 方法带**泛型参数**（vtable 里没法存"无穷多实例化"）；
- 方法返回 `Self` 或参数含 `Self`（调用方拿到的是未知类型，无法安置）；
- 方法要求 `Self: Sized`（与 dyn 的 DST 本性冲突）；
- trait 含关联常量（同理无法按类型定型）。

补救姿势——把对象不安全的方法用 `where Self: Sized` 隔离：

```rust
trait Foo {
    fn bad<T>(&self, x: T);                    // 泛型方法 → 对象不安全
    fn new() -> Self where Self: Sized;        // 返回 Self，但加 Sized 限定 → 安全
}
// 现在 Box<dyn Foo> 合法；只是 new 不能通过 trait 对象调用
```

`Iterator` 就不是对象安全的（`collect<B>` 是泛型方法）——所以 15 章的"自定义迭代器装箱"需要技巧。日常判断：报错 "the trait `X` is not object safe" 时，按上面四条对号入座。

## 12.8 标签 trait（marker trait）：编译器的隐形印章

std::marker 里有一组**空 trait**——没有方法，纯作类型系统的标记：

| trait | 标记什么 | 谁实现 |
|---|---|---|
| `Sized` | 编译期大小可知 | 几乎所有类型自动（DST 除外） |
| `Copy` | 按位复制安全 | 标量 + 显式 derive 的类型 |
| `Send` | 值可跨线程 move | 编译器按字段自动推导 |
| `Sync` | `&T` 可跨线程共享 | 同上 |
| `Unpin`/`Pin` 相关 | 移动安全性（23 章 async 的地基） | 几乎全自动 |

它们都是 `unsafe trait`（Send/Sync 手动实现是 unsafe——你在向编译器担保线程安全）或语言项（`#[lang = "sized"]` 等），编译器特殊对待。`?Sized`（11 章）就是"解除 Sized 默认约束"的语法。

## 12.9 完全限定语法：消歧义的最后手段

当一个类型实现了多个 trait、它们有同名方法时，编译器可能无法推断你想调哪个。完全限定语法（fully qualified syntax）就是显式指明"用哪个 trait 的哪个方法"：

```rust
trait Animal { fn name(&self) -> String; }
trait Pet { fn name(&self) -> String; }

struct Dog;
impl Animal for Dog { fn name(&self) -> String { "Animal::Dog".into() } }
impl Pet for Dog { fn name(&self) -> String { "Pet::Dog".into() } }

let d = Dog;
// d.name();  // ← 编译错：name 有多个候选，编译器无法消歧
let n = <Dog as Pet>::name(&d);   // 显式：用 Dog 的 Pet 实现里的 name
assert_eq!(n, "Pet::Dog");
```

通用形式是 `<Type as Trait>::method(&receiver, args)`。方法调用时 Rust 允许省略能从上下文推导的部分——只有当同名方法存在多个实现且编译器无法区分时，才需要这种显式语法。对关联函数（无 self），形式是 `<Type as Trait>::assoc_fn(args)`。

## 12.10 坑位清单

1. **`dyn Trait` 作参数要装箱或借引用**：`fn f(x: dyn Trait)` 编译错（Sized 未满足）——`&dyn` / `Box<dyn>`。
2. **对象安全四规则**：泛型方法 / Self 出现在签名 / `Self: Sized` 方法 / 关联常量——报错 "not object safe" 时按条对号（12.7）。
3. **impl Trait 返回不能条件分叉类型**：`if c { it_a } else { it_b }` 两个不同迭代器类型 → 编译错；Box<dyn Iterator> 才行。
4. **默认方法与覆盖方法的选择在编译期定**：无法运行期替换——那是 dyn 的场景。
5. **孤儿规则卡住时**：newtype 包装（`struct MyVec(Vec<i32>)`）是标准解法，零成本。
6. **derive 的 PartialEq 字段序敏感**：按声明顺序逐字段比较，(a,b) ≠ (b,a) 的序会有不同等于语义——自定义相等手写。
7. **Display 手写容易忘返回类型**：签名是 `fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result`——抄标准库。
8. **关联类型使用处要限定**：`fn sum<C: Counter>(c: C)` 里拿 `C::Item` 需要额外 `C::Item: Display` 之类的约束才能用。
9. **`fn f(a: impl X, b: impl X)` 允许不同类型**：要强制同型请写回泛型 `<T: X>(a: T, b: T)`——两个 impl Trait 是**各自独立**的匿名类型参数。
10. **`String + String` 不存在**：`Add<&str> for String` 是唯一实现（12.4）——`s1 + &s2` 里那个 `&` 不是风格，是签名要求。

---

上一章：[11 泛型](11-generics.md) · 下一章：[13 生命周期](13-lifetimes.md)
