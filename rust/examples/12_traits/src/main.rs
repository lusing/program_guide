//! 12 · Trait ⭐：定义与实现、默认方法、约束、impl Trait、dyn Trait、关联类型、常用派生与标准 trait

use std::fmt;

// ---- 定义 trait：一组方法签名（可以有默认实现）----
trait Summary {
    fn headline(&self) -> String; // 必须实现

    fn preview(&self) -> String {
        // 默认实现：可整体覆盖，也可在覆盖里调用
        format!("（{}……）", self.headline())
    }
}

struct Article {
    title: String,
    author: String,
}

struct Weibo {
    username: String,
    text: String,
}

// ---- 为本地类型实现 trait ----
impl Summary for Article {
    fn headline(&self) -> String {
        format!("《{}》— {}", self.title, self.author)
    }
}

impl Summary for Weibo {
    fn headline(&self) -> String {
        format!("@{}：{}", self.username, self.text)
    }

    fn preview(&self) -> String {
        format!("@{} 发布了新微博", self.username) // 覆盖默认实现
    }
}

// ---- 孤儿规则：trait 或类型至少一个定义在本地 ----
// impl Display for Vec<i32> {}  // ← 编译错：两者都是外部的
// 但给本地类型实现外部 trait 完全合法：
impl fmt::Display for Article {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}（{} 著）", self.title, self.author)
    }
}

// ---- 运算符重载：实现 std::ops 里的 trait ----
use std::ops::Add;

#[derive(Debug, Clone, Copy, PartialEq)]
struct Vec2 {
    x: f64,
    y: f64,
}

impl Add for Vec2 {
    type Output = Vec2; // 关联类型：实现时固定

    fn add(self, rhs: Vec2) -> Vec2 {
        Vec2 {
            x: self.x + rhs.x,
            y: self.y + rhs.y,
        }
    }
}

// ---- 关联类型 vs 泛型参数：Iterator 用关联类型 ----
trait Counter {
    type Item; // 每个类型只有一种"计数方式"

    fn next_count(&mut self) -> Option<Self::Item>;
}

// From/Into 转换对的教学类型（模块级，测试里也要用）
struct Seconds(u32);

impl From<u32> for Seconds {
    fn from(v: u32) -> Self {
        Seconds(v)
    }
}

struct Countdown {
    remaining: u32,
}

impl Counter for Countdown {
    type Item = u32; // 关联类型在这里定死

    fn next_count(&mut self) -> Option<u32> {
        if self.remaining == 0 {
            None
        } else {
            self.remaining -= 1;
            Some(self.remaining)
        }
    }
}

// ---- 静态分发：impl Trait 参数（泛型的语法糖）----
fn notify(item: &impl Summary) -> String {
    format!("突发：{}", item.headline())
}

// 等价展开：
fn notify_explicit<T: Summary>(item: &T) -> String {
    format!("突发：{}", item.headline())
}

// ---- impl Trait 返回值：藏起具体类型（迭代器管线的标准姿势）----
fn top_headlines(items: &[Box<dyn Summary>]) -> impl fmt::Display {
    items
        .first()
        .map(|s| s.headline())
        .unwrap_or_else(|| "（空）".into())
}

// ---- 动态分发：dyn Trait（胖指针 = 数据指针 + vtable 指针）----
fn largest_preview(items: &[Box<dyn Summary>]) -> String {
    items
        .iter()
        .map(|s| s.preview())
        .max_by_key(|p| p.len())
        .unwrap_or_default()
}

// ---- trait 继承：组合优于继承的"行为复用"通道 ----
trait Page {
    fn set_page(&self, p: i32) {
        println!("  翻到第 {p} 页");
    }
}
trait PerPage {
    fn set_per_page(&self, n: i32) {
        println!("  每页 {n} 条");
    }
}
trait Paginate: Page + PerPage {
    // 继承两个父 trait；自带一个默认方法
    fn set_skip(&self, num: i32) {
        println!("  直接跳到第 {num} 页");
    }
}
struct Listing {
    total: u32,
}
impl Page for Listing {}
impl PerPage for Listing {}
impl<T: Page + PerPage> Paginate for T {} // blanket impl：一切"已分页"类型自动可跳页

// ---- 对象安全：泛型方法 vs where Self: Sized 隔离 ----
trait Factory {
    fn describe(&self) -> String; // 对象安全
    // fn make<T>(&self, x: T) -> T;          // ← 泛型方法：trait 因此不对象安全
    fn new() -> Self
    where
        Self: Sized, // 用 Sized 限定把"返回 Self"隔离开 → trait 保持对象安全
    {
        panic!("默认 new 仅供演示：具体类型应覆盖它")
    }
}
struct Widget;
impl Factory for Widget {
    fn describe(&self) -> String {
        "widget".into()
    }
    fn new() -> Self {
        Widget // 覆盖默认实现：返回具体类型
    }
}

// ---- 完全限定语法：同名方法的消歧义 ----
trait Animal {
    fn name(&self) -> String;
}
trait Pet {
    fn name(&self) -> String;
}
struct Dog;
impl Animal for Dog {
    fn name(&self) -> String {
        "Animal::Dog".into()
    }
}
impl Pet for Dog {
    fn name(&self) -> String {
        "Pet::Dog".into()
    }
}

fn main() {
    let article = Article {
        title: "Rust 1.99 发布".into(),
        author: "官方".into(),
    };
    let weibo = Weibo {
        username: "rustlang".into(),
        text: "所有权三原则速记".into(),
    };

    // 默认方法 vs 覆盖方法
    println!("{}", article.headline());
    println!("  预览：{}", article.preview()); // 默认实现
    println!("{}", weibo.headline());
    println!("  预览：{}", weibo.preview()); // 覆盖实现

    // Display（手写）
    println!("Display 输出：{article}");

    // 静态分发：编译期确定调用目标（单态化，零开销）
    println!("{}", notify(&article));
    println!("{}", notify_explicit(&weibo));

    // 动态分发：一个集合装多种类型，运行期查 vtable
    let feed: Vec<Box<dyn Summary>> = vec![Box::new(article), Box::new(weibo)];
    for item in &feed {
        println!("  [feed] {}", item.headline());
    }
    println!("最长预览：{}", largest_preview(&feed));
    println!("头条：{}", top_headlines(&feed));

    // trait 对象大小：&dyn / Box<dyn> 是胖指针（16 字节 = 数据 + vtable）
    println!(
        "sizeof &dyn Summary = {}",
        std::mem::size_of::<&dyn Summary>()
    );
    println!(
        "sizeof Box<dyn Summary> = {}",
        std::mem::size_of::<Box<dyn Summary>>()
    );

    // 运算符重载：+ 走我们实现的 Add
    let a = Vec2 { x: 1.0, y: 2.0 };
    let b = Vec2 { x: 3.0, y: 4.0 };
    println!("a + b = {:?}", a + b);

    // 关联类型的使用
    let mut c = Countdown { remaining: 3 };
    while let Some(n) = c.next_count() {
        print!("{n} ");
    }
    println!();

    // From/Into：转换 trait 对（实现 From 白送 Into）——Seconds 定义在模块级，见上
    let s: Seconds = 60u32.into(); // From 反推 Into
    let explicit = Seconds::from(90);
    println!("into = {}，from = {}", s.0, explicit.0);

    // 常用 derive 一览（详见 docs）：
    // Debug → {:?}；Clone → .clone()；Copy → 按位复制；
    // PartialEq/Eq → ==；Hash → HashMap 键；Default → Default::default()
    #[derive(Debug, Default, Clone, PartialEq)]
    struct Config {
        retries: u32,
        label: String,
    }
    let default_cfg = Config::default();
    let custom = Config {
        retries: 3,
        ..default_cfg.clone()
    };
    println!("{default_cfg:?} → {custom:?}");
    assert_ne!(default_cfg, custom);

    // trait 继承 + blanket impl：Listing 自动获得 set_skip
    let list = Listing { total: 100 };
    println!("Listing 共 {} 条", list.total);
    list.set_page(2);
    list.set_per_page(20);
    list.set_skip(5);

    // 对象安全：Box<dyn Factory> 合法（new 被 Sized 限定隔离，不能经 dyn 调用）
    let makers: Vec<Box<dyn Factory>> = vec![Box::new(Widget)];
    for m in &makers {
        println!("dyn Factory describe = {}", m.describe());
    }
    // new 只能经具体类型调用（Self: Sized 把"返回 Self"从 vtable 中隔离）
    let _w = Widget::new();

    // 完全限定语法：Dog 实现了 Animal 和 Pet，两者都有 name()
    let d = Dog;
    // d.name();  // ← 编译错：多个候选，无法消歧
    let n = <Dog as Pet>::name(&d); // 显式指定用 Pet 实现的 name
    let na = <Dog as Animal>::name(&d); // 或 Animal 的
    println!("完全限定语法：Pet = {n}，Animal = {na}");
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sample_article() -> Article {
        Article {
            title: "T".into(),
            author: "A".into(),
        }
    }

    #[test]
    fn default_method_used_unless_overridden() {
        assert_eq!(sample_article().preview(), "（《T》— A……）");
        let w = Weibo {
            username: "u".into(),
            text: "t".into(),
        };
        assert_eq!(w.preview(), "@u 发布了新微博");
    }

    #[test]
    fn static_dispatch_via_impl_trait() {
        assert_eq!(notify(&sample_article()), "突发：《T》— A");
    }

    #[test]
    fn dynamic_dispatch_via_box() {
        let feed: Vec<Box<dyn Summary>> = vec![
            Box::new(sample_article()),
            Box::new(Weibo {
                username: "u".into(),
                text: "t".into(),
            }),
        ];
        assert_eq!(feed.len(), 2);
        assert!(!largest_preview(&feed).is_empty());
    }

    #[test]
    fn operator_overload_via_add() {
        let a = Vec2 { x: 1.0, y: 2.0 };
        assert_eq!(a + a, Vec2 { x: 2.0, y: 4.0 });
    }

    #[test]
    fn associated_type_counter() {
        let mut c = Countdown { remaining: 2 };
        assert_eq!(c.next_count(), Some(1));
        assert_eq!(c.next_count(), Some(0));
        assert_eq!(c.next_count(), None);
    }

    #[test]
    fn from_into_pair() {
        let s: Seconds = 5u32.into();
        assert_eq!(s.0, 5);
        assert_eq!(Seconds::from(7).0, 7);
    }

    #[test]
    fn trait_inheritance_blanket_impl() {
        let list = Listing { total: 50 };
        list.set_page(1); // 父 trait 方法
        list.set_per_page(10); // 另一个父 trait 方法
        list.set_skip(3); // 子 trait 默认方法——blanket impl 白送
    }

    #[test]
    fn object_safe_with_sized_guard() {
        let makers: Vec<Box<dyn Factory>> = vec![Box::new(Widget)];
        assert_eq!(makers[0].describe(), "widget");
        // Widget::new() 只能经具体类型调用，不能过 dyn——这是 Sized 限定的含义
    }

    #[test]
    fn fully_qualified_syntax_disambiguates() {
        let d = Dog;
        assert_eq!(<Dog as Pet>::name(&d), "Pet::Dog");
        assert_eq!(<Dog as Animal>::name(&d), "Animal::Dog");
    }
}
