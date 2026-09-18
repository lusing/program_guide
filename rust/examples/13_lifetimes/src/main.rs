//! 13 · 生命周期 ⭐：防悬垂引用的标注体系、省略规则、结构体持有引用、'static
//!
//! 生命周期标注不改变任何引用的实际寿命——它只是给编译器看的
//! "约束说明书"，编译器据此验证借用不悬垂。

// 悬垂引用，编译器直接拒绝：
// fn dangle() -> &str { let s = String::from("x"); &s }
//            ^ 编译错：返回引用指向已释放的局部变量

// ---- 显式标注：返回值的寿命与两个入参中较短的那个对齐 ----
// 读法：'a 是 x、y、返回值三者的公共存活区间下界。
// 有了这条约束，调用方不可能拿着返回值活得比 x/y 更久。
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() { x } else { y }
}

// 只有一个入参参与决定返回值寿命时，不需要第二个参数出现在约束里：
fn first_word(s: &str) -> &str {
    s.split_whitespace().next().unwrap_or("")
}

// ---- 结构体持有引用：必须声明 lifetime，编译器保证结构体不死在引用之后 ----
struct Excerpt<'a> {
    part: &'a str, // Excerpt 实例不能活过它借用的文本
}

impl<'a> Excerpt<'a> {
    // 省略规则同样适用于方法：self 的 lifetime 传播到返回值
    fn announce(&self, msg: &str) -> &str {
        println!("注意：{msg}");
        self.part
    }

    fn longest_inside(&self, other: &'a str) -> &'a str {
        longest(self.part, other)
    }
}

// ---- 泛型 + 生命周期 + trait 约束可以叠加 ----
fn longest_with_announcement<'a, T>(x: &'a str, y: &'a str, ann: T) -> &'a str
where
    T: std::fmt::Display,
{
    println!("公告：{ann}");
    longest(x, y)
}

// ---- 'static：整个程序运行期间都有效 ----
fn static_str() -> &'static str {
    "编译进二进制的字面量" // 字符串字面量天然 'static
}

static GREETING: &str = "静态项里的 &str 也是 &'static str";

fn main() {
    let s1 = String::from("长长的字符串");
    // ---- 借用检查器的实际拦截 ----
    let result;
    {
        let s2 = String::from("短");
        result = longest(s1.as_str(), s2.as_str());
        println!("内层使用 longest = {result}"); // OK：s2 还活着
    } // s2 在此 drop
    // println!("{result}"); // ← 编译错：result 的寿命被约束到 s2 的区间内
    //                          （注释掉上面内层的 println 后此行能通过——NLL 按使用点判定）

    // 换个活得更久的实参，返回值就能活得更久（'a 取交集）
    let s3 = String::from("中等");
    let r = longest(s1.as_str(), s3.as_str());
    println!("外层使用 = {r}");

    // ---- 结构体持有引用 ----
    // Excerpt 借用 novel 的第一句；ex（和它借出的引用）都不能活得比 novel 久
    let novel = String::from("很久以前。后面还有一大段。");
    let ex = Excerpt {
        part: novel.split('。').next().unwrap(),
    };
    let first_sentence = ex.announce("我借用 novel 的片段");
    println!("摘录：{first_sentence}");
    // 试试把 novel 在这里 drop、之后再用 first_sentence —— 编译器会拒绝

    // ---- 方法定义里的生命周期（多半被省略规则覆盖）----
    let ex = Excerpt { part: "片段ABC" };
    println!("longest_inside = {}", ex.longest_inside("更长的片段"));

    // ---- 泛型+生命周期+约束叠加 ----
    let w = longest_with_announcement("苹果", "香蕉", 42);
    println!("announce 版 = {w}");

    // ---- 'static ----
    println!("{} / {} / 字面量也是", static_str(), GREETING);
    println!("省略规则下的 first_word：{:?}", first_word("a b c"));

    // 'static 也常出现在约束里：T: 'static 表示"T 不含非 static 借用"
    fn boxed_copy<T: Clone + 'static>(v: T) -> Box<T> {
        // 拥有数据的 Box 可以活得比当前栈帧久，所以要求 T 不携带短命引用
        Box::new(v.clone())
    }
    let b = boxed_copy(String::from("拥有型数据"));
    println!("boxed = {b}");
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn longest_picks_longer() {
        assert_eq!(longest("ab", "abc"), "abc");
        assert_eq!(longest("abcd", "ab"), "abcd");
        assert_eq!(longest("等长", "一样长"), "一样长"); // 等长时走 else 分支返回 y
    }

    #[test]
    fn lifetime_is_the_intersection() {
        let s1 = String::from("长字符串活在外层");
        let out;
        {
            let s2 = String::from("短");
            out = longest(&s1, &s2);
            assert!(!out.is_empty()); // 必须在 s2 死亡前用完
        }
        // out 在这里使用就是编译错——生命周期标注的作用正是让编译器知道这点
    }

    #[test]
    fn excerpt_cannot_outlive_source() {
        let novel = String::from("第一句。第二句。");
        let ex = Excerpt {
            part: novel.split('。').next().unwrap(),
        };
        assert_eq!(ex.part, "第一句");
        // 如果把 novel drop 掉再使用 ex，编译不过——这就是结构体上 'a 的意义
    }

    #[test]
    fn elision_covers_simple_cases() {
        // 这两个函数都不需要显式标注（省略规则），但显式写也等价
        assert_eq!(first_word("a b"), "a");
        assert_eq!(first_word("  "), "");
    }

    #[test]
    fn static_outlives_everything() {
        let s: &'static str = static_str();
        assert!(!s.is_empty());
        let moved = s; // 'static 引用可以随意复制
        assert_eq!(moved, s);
    }
}
