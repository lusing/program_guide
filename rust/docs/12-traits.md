# 12 · Trait ⭐

> 对应示例：`examples/12_traits/`
>
> Trait 是 Rust 的接口、也是运算符重载入口、也是多态机制、也是抽象的通用货币。
> 一个概念身兼四职——这就是为什么它值一整章加一颗星。

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

限制：只能返回**单一**具体类型（不能按分支返回两种不同闭包/迭代器），调用方不知道真名只能用声明的 trait 方法。

## 12.3 dyn Trait：动态分发与胖指针

```rust
let feed: Vec<Box<dyn Summary>> = vec![
    Box::new(article),     // 不同具体类型
    Box::new(weibo),       // 装进同一个集合
];
for item in &feed { item.headline(); }   // 运行期查 vtable
```

- `dyn Trait` 是**不定大小类型（DST）**，必须藏在指针后：`&dyn`、`Box<dyn>`；
- `&dyn Trait` 是**胖指针**：数据指针 + vtable 指针（16 字节），方法调用走表；
- 需要"运行期才决定类型 / 一个集合装多种类型 / 插件式架构"时用它。

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

## 12.5 标准库高频 trait 速览

| trait | 带来什么 | 手写/derive |
|---|---|---|
| `Display`/`Debug` | `{}` / `{:?}` 打印 | Display 手写，Debug derive |
| `Clone`/`Copy` | 显式/隐式复制 | derive（07 章） |
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

## 12.7 坑位清单

1. **`dyn Trait` 作参数要装箱或借引用**：`fn f(x: dyn Trait)` 编译错（Sized 未满足）——`&dyn` / `Box<dyn>`。
2. **对象安全（dyn 兼容）限制**：trait 有泛型方法/返回 `Self`（非指针形态）/Sized 约束方法时不能做 dyn——报错 "the trait ... is not object safe"。Iterator 就不是对象安全的（有泛型方法 `collect<B>`）。
3. **impl Trait 返回不能条件分叉类型**：`if c { it_a } else { it_b }` 两个不同迭代器类型 → 编译错；Box<dyn Iterator> 才行。
4. **默认方法与覆盖方法的选择在编译期定**：无法运行期替换——那是 dyn 的场景。
5. **孤儿规则卡住时**：newtype 包装（`struct MyVec(Vec<i32>)`）是标准解法，零成本。
6. **derive 的 PartialEq 字段序敏感**：按声明顺序逐字段比较，(a,b) ≠ (b,a) 的序会有不同等于语义——自定义相等手写。
7. **Display 手写容易忘返回类型**：签名是 `fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result`——抄标准库。
8. **关联类型使用处要限定**：`fn sum<C: Counter>(c: C)` 里拿 `C::Item` 需要额外 `C::Item: Display` 之类的约束才能用。

---

上一章：[11 泛型](11-generics.md) · 下一章：[13 生命周期](13-lifetimes.md)
