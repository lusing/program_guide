//! 15 · 迭代器：三种来源、适配器管道、惰性求值、自定义迭代器

fn main() {
    let v = [1, 2, 3, 4, 5]; // 定长数据用数组（迭代器方法全都一样）

    // ---- 三种来源：iter() / iter_mut() / into_iter() ----
    for x in v.iter() {
        print!("{x} "); // 借用元素（&T），v 完好
    }
    println!();

    let mut w = vec![1, 2, 3];
    for x in w.iter_mut() {
        *x *= 10; // 可变借用元素（&mut T）
    }
    println!("iter_mut 后 {w:?}");

    let owned = vec![String::from("a"), String::from("b")];
    for x in owned.into_iter() {
        print!("[{x}] "); // 拿走元素（T），循环后 owned 不可用
    }
    println!();

    // for 循环语法糖：IntoIterator —— 数组、Range、&Vec、HashMap 都实现了
    for x in [7, 8, 9] {
        print!("{x} ");
    }
    println!();

    // ---- 适配器（返回新迭代器，惰性）× 消费器（真正驱动求值）----
    let doubled: Vec<i32> = v.iter().map(|x| x * 2).collect();
    let evens: Vec<i32> = v.iter().filter(|x| *x % 2 == 0).copied().collect();
    let sum: i32 = v.iter().sum();
    // fold：万能聚合器（比 sum/product 更通用——这里折成 CSV 字符串）
    let csv: String = v.iter().fold(String::new(), |acc, x| format!("{acc}{x},"));
    println!("map→{doubled:?}  filter→{evens:?}  sum={sum}  fold={csv:?}");

    // 惰性演示：不接消费器，map 里的代码一次都不会执行
    let lazy = v.iter().map(|x| {
        println!("  处理 {x}（现在才跑）");
        x * 10
    });
    println!("（上面没有输出：lazy 尚未消费）");
    let _collected: Vec<i32> = lazy.collect(); // 消费器触发遍历

    // ---- 常用适配器全家 ----
    let names = ["alpha", "beta", "gamma"];
    for (i, n) in names.iter().enumerate() {
        print!("{i}:{n} ");
    }
    println!();
    let zipped: Vec<(i32, &str)> = v
        .iter()
        .copied()
        .zip(names.iter().copied()) // copied：把 &&str 解成 &str，对齐元素类型
        .collect();
    println!("zip {zipped:?}");
    let chained: Vec<i32> = [1, 2].into_iter().chain([3, 4]).collect();
    let first2: Vec<&i32> = v.iter().take(2).collect();
    let skipped: Vec<&i32> = v.iter().skip(3).collect();
    println!("chain {chained:?}  take {first2:?}  skip {skipped:?}");
    let flat: Vec<i32> = vec![vec![1, 2], vec![3]].into_iter().flatten().collect();
    let flat_map: Vec<char> = ["ab", "c"].iter().flat_map(|s| s.chars()).collect();
    println!("flatten {flat:?}  flat_map {flat_map:?}");

    // ---- 查找与判定 ----
    println!(
        "find {:?}  position {:?}",
        v.iter().find(|x| **x > 3),
        v.iter().position(|x| *x == 3)
    );
    println!(
        "any={} all={} count={}",
        v.iter().any(|x| *x > 4),
        v.iter().all(|x| *x < 10),
        v.iter().filter(|x| **x % 2 == 1).count()
    );
    println!("max {:?}  min {:?}", v.iter().max(), v.iter().min());

    // ---- collect 的多态目标：turbofish 或标注 ----
    let set: std::collections::HashSet<i32> = v.iter().copied().collect();
    let text: String = ['r', 'u', 's', 't'].into_iter().collect(); // String 也实现 FromIterator
    println!("collect 成 String：{text}");
    let s = v
        .iter()
        .map(|x| x.to_string())
        .collect::<Vec<_>>()
        .join("-");
    println!("set.len={} joined={s}", set.len());

    // 反向与 peekable
    let rev: Vec<i32> = v.iter().rev().copied().collect();
    println!("rev {rev:?}");
    let mut peek = v.iter().peekable();
    let ahead = peek.peek().copied(); // 先看一眼（borrow 及时结束），不消耗元素
    println!("peek {ahead:?} 然后 {:?}", peek.next()); // ……再真正取走

    // ---- 自定义迭代器：实现 Iterator trait（关联类型 Item + next 方法）----
    struct Fib {
        a: u64,
        b: u64,
        left: u32,
    }
    impl Iterator for Fib {
        type Item = u64;
        fn next(&mut self) -> Option<u64> {
            if self.left == 0 {
                return None; // None 即"结束"
            }
            self.left -= 1;
            let out = self.a;
            (self.a, self.b) = (self.b, self.a + self.b);
            Some(out)
        }
    }
    let fibs: Vec<u64> = Fib {
        a: 0,
        b: 1,
        left: 10,
    }
    .collect();
    println!("斐波那契前 10 项：{fibs:?}");
    // 自定义迭代器白送全套适配器：
    let even_fibs: Vec<u64> = Fib {
        a: 0,
        b: 1,
        left: 20,
    }
    .filter(|x| x % 2 == 0)
    .collect();
    println!("其中的偶数：{even_fibs:?}");

    // ---- 迭代器 vs 手写循环：惯用优先级 ----
    // Rust 惯用法：能用迭代器管道就不用索引循环（无边界检查、组合性强）
    let words = ["apple", "banana", "cherry"];
    let upper_long: Vec<String> = words
        .iter()
        .filter(|w| w.len() > 5)
        .map(|w| w.to_uppercase())
        .collect();
    println!("长单词大写：{upper_long:?}");
}

#[cfg(test)]
mod tests {
    #[test]
    fn adapt_and_consume() {
        let v: Vec<i32> = (1..=10).map(|x| x * x).filter(|x| x % 2 == 0).collect();
        assert_eq!(v, vec![4, 16, 36, 64, 100]);
    }

    #[test]
    fn fold_aggregates() {
        let words = ["a", "bb", "ccc"];
        let total: usize = words.iter().map(|w| w.len()).sum();
        assert_eq!(total, 6);
        let joined = words.iter().fold(String::new(), |acc, w| acc + w);
        assert_eq!(joined, "abbccc");
    }

    #[test]
    fn enumerate_and_zip() {
        let names = ["x", "y", "z"];
        let pairs: Vec<(usize, &str)> = names.iter().enumerate().map(|(i, s)| (i, *s)).collect();
        assert_eq!(pairs, vec![(0, "x"), (1, "y"), (2, "z")]);
        let sums: Vec<i32> = [1, 2, 3]
            .into_iter()
            .zip([10, 20, 30])
            .map(|(a, b)| a + b)
            .collect();
        assert_eq!(sums, vec![11, 22, 33]);
    }

    #[test]
    fn search_helpers() {
        let v = [5, 8, 13, 21];
        assert_eq!(v.iter().find(|x| **x % 2 == 0), Some(&8));
        assert_eq!(v.iter().position(|x| *x == 21), Some(3));
        assert!(v.iter().all(|x| *x > 0));
        assert!(v.iter().any(|x| *x > 20));
        assert_eq!(v.iter().max(), Some(&21));
    }

    #[test]
    fn iterators_are_lazy() {
        use std::cell::Cell;
        let taps = Cell::new(0);
        let it = (0..5).inspect(|_| taps.set(taps.get() + 1)); // inspect：纯副作用钩子
        assert_eq!(taps.get(), 0); // 未消费：零执行
        let collected: Vec<i32> = it.collect();
        assert_eq!(collected.len(), 5);
        assert_eq!(taps.get(), 5); // 消费：恰好执行 5 次
    }

    struct Countdown(u32);
    impl Iterator for Countdown {
        type Item = u32;
        fn next(&mut self) -> Option<u32> {
            if self.0 == 0 {
                None
            } else {
                self.0 -= 1;
                Some(self.0)
            }
        }
    }

    #[test]
    fn custom_iterator_gets_adapters_free() {
        let all: Vec<u32> = Countdown(5).collect();
        assert_eq!(all, vec![4, 3, 2, 1, 0]);
        let evens: Vec<u32> = Countdown(10).filter(|x| x % 2 == 0).take(2).collect();
        assert_eq!(evens, vec![8, 6]); // Countdown(10) 产出 9..0，取前两个偶数
        assert_eq!(Countdown(0).count(), 0);
    }
}
