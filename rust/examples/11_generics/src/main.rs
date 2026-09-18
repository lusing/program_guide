//! 11 · 泛型：泛型函数/结构体/枚举/方法、trait 约束、where 子句、单态化

use std::fmt::Display;

/// 泛型函数：类型参数 T 必须满足 PartialOrd 才能比较
/// （没有约束时 T 只能用"所有类型都有"的操作，比如 drop）
fn largest<T: PartialOrd>(items: &[T]) -> &T {
    let mut max = &items[0];
    for it in &items[1..] {
        if it > max {
            max = it;
        }
    }
    max
}

/// 多类型参数 + 多约束（+ 连接）
fn print_pairs<K: Display, V: Display>(pairs: &[(K, V)]) {
    for (k, v) in pairs {
        println!("  {k} → {v}");
    }
}

/// 约束复杂时用 where 子句，签名保持清爽
fn summary<T, U>(items: &[T], extra: U) -> String
where
    T: Display + Clone,
    U: Display,
{
    let joined: Vec<String> = items.iter().map(|x| x.to_string()).collect();
    format!("[{}]（附加：{extra}）", joined.join(", "))
}

/// 泛型结构体：字段类型可以是不同的 T、U
#[derive(Debug)]
struct Pair<T, U = i32> {
    // U = i32：默认类型参数（运算符重载常见，业务代码少用）
    first: T,
    second: U,
}

impl<T: Display + PartialEq, U: Display> Pair<T, U> {
    fn new(first: T, second: U) -> Self {
        Self { first, second }
    }

    fn show(&self) {
        println!("Pair({}, {})", self.first, self.second);
    }

    /// 方法可以利用 T 的约束做比较
    fn same_as(&self, other: &Self) -> bool {
        self.first == other.first && self.second.to_string() == other.second.to_string()
    }
}

/// 泛型枚举 —— Option<T>/Result<T, E> 就是这么定义的，自己写一个：
#[derive(Debug)]
enum Either<L, R> {
    Left(L),
    Right(R),
}

impl<L: Display, R: Display> Either<L, R> {
    fn text(&self) -> String {
        match self {
            Either::Left(l) => format!("左：{l}"),
            Either::Right(r) => format!("右：{r}"),
        }
    }
}

/// impl 块可以只为"部分具体化"的类型实现方法：
/// 只给 Pair<f64, f64> 加计算能力
impl Pair<f64, f64> {
    fn distance(&self) -> f64 {
        (self.first * self.first + self.second * self.second).sqrt()
    }
}

fn main() {
    // 泛型函数：一套代码，多型调用（编译器按调用点单态化）
    let nums = [34, 50, 12, 87, 42];
    let words = ["milk", "bread", "avocado"];
    let floats = [1.5, 0.25, 9.0];
    println!("最大整数 {}", largest(&nums));
    println!("最大单词 {}", largest(&words));
    println!("最大浮点 {}", largest(&floats));

    // 显式 turbofish（多数时候可省，靠推断）
    println!("turbofish = {}", largest::<i32>(&[3, 1, 2]));

    print_pairs(&[("a", 1), ("b", 2)]);
    print_pairs(&[(1, "一"), (2, "二")]); // 两次调用是两份单态化副本

    println!("{}", summary(&[1, 2, 3], "共 3 个"));
    println!("{}", summary(&["x", "y"], 0));

    // 泛型结构体
    let p1 = Pair::new(3, 4.5);
    let p2 = Pair::new(3, 4);
    p1.show();
    p2.show();
    println!("{p1:?}");
    println!("same_as = {}", p1.same_as(&Pair::new(3, 4.0))); // 类型必须同为 Pair<i32, f64>

    // 部分具体化的方法只对那类实例存在
    let point = Pair::new(3.0, 4.0);
    println!("距离 = {}", point.distance());
    // p1.distance(); // ← 编译错：p1 是 Pair<i32, f64>，没有 distance

    // 泛型枚举
    let e1: Either<i32, &str> = Either::Left(7);
    let e2: Either<i32, &str> = Either::Right("seven");
    println!("{} | {}", e1.text(), e2.text());

    // 零成本抽象：largest::<i32> 和手写 i32 版本生成的机器码一致
    // （单态化 = 按具体类型复制一份代码编译，无虚调用、无装箱）
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn largest_works_for_many_types() {
        assert_eq!(*largest(&[34, 50, 12]), 50);
        assert_eq!(*largest(&["b", "z", "a"]), "z");
        assert_eq!(*largest(&[9.9, 0.1]), 9.9);
        assert!(*largest(&[true, false])); // bool 也能比（PartialOrd）
    }

    #[test]
    fn default_type_param() {
        let p: Pair<&str> = Pair {
            first: "只指定 T",
            second: 42, // U 落到默认 i32
        };
        assert_eq!(p.second, 42);
    }

    #[test]
    fn either_carries_one_of_two() {
        let e: Either<u8, char> = Either::Left(65);
        assert!(matches!(e, Either::Left(65)));
        let e: Either<u8, char> = Either::Right('A');
        assert!(matches!(e, Either::Right('A')));
    }

    #[test]
    fn where_clause_bounds() {
        assert_eq!(summary(&[1, 2], "！"), "[1, 2]（附加：！）");
    }

    #[test]
    fn impl_for_specific_types_only() {
        let p = Pair::new(6.0, 8.0);
        assert!((p.distance() - 10.0).abs() < 1e-9);
    }
}
