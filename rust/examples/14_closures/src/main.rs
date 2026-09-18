//! 14 · 闭包 ⭐：语法、捕获方式、Fn/FnMut/FnOnce 三兄弟、move、闭包作参数/返回值

use std::collections::HashMap;

fn main() {
    // ---- 语法：|参数| 表达式，多数类型可推断 ----
    let add1 = |x: i32| x + 1;
    let add_v2 = |x: i32| -> i32 { x + 1 }; // 带块和返回类型的形式
    println!("{} {}", add1(1), add_v2(2));

    // 无参闭包：惰性求值的名场面向量
    let give_me_a = || 42;
    println!("{}", give_me_a());

    // ---- 捕获环境：闭包能"看见"定义处的变量 ----
    let factor = 10;
    let scale = |x: i32| x * factor; // 不可变捕获（借用 factor）
    println!("scale(4) = {}", scale(4));
    // factor 仍然可用（只读借用）
    println!("factor = {factor}");

    let mut count = 0;
    let mut bump = || count += 1; // 可变捕获（独占借用 count）
    bump();
    bump();
    println!("count = {count}");
    // bump 存活期间，其他任何借用都不行：
    // let r = &count; println!("{r}"); // ← 编译错（bump 还持有 &mut count）

    // ---- move：把所有权搬进闭包（线程场景标配，22 章实战）----
    let owned = String::from("搬进闭包");
    let consume = move || println!("闭包拥有：{owned}");
    consume();
    // println!("{owned}"); // ← 编译错：owned 已被 move 进闭包
    let keep = move || println!("再印一次也没问题：闭包还拥有它");
    keep();

    // ---- Fn / FnMut / FnOnce：按捕获方式递进的三个 trait ----
    // FnOnce：消耗捕获值，最多调用一次（按值捕获）
    // FnMut ：可变借用捕获，可多次调用
    // Fn    ：共享借用捕获，可多次调用（最宽松的约束满足前两者）
    fn call_fn<F: Fn(i32) -> i32>(f: F, v: i32) -> i32 {
        f(v)
    }
    fn call_fn_mut<F: FnMut(i32) -> i32>(mut f: F, v: i32) -> i32 {
        f(v)
    }
    fn call_fn_once<F: FnOnce(i32) -> i32>(f: F, v: i32) -> i32 {
        f(v)
    }
    let pure = |x| x + 1; // Fn
    let mut base = 100;
    // 注意：闭包本身是 FnMut，但绑定不需要 mut——只有"通过绑定调用"才需要
    let accumulate = move |x| {
        base += x; // FnMut
        base
    };
    println!("Fn  → {}", call_fn(pure, 1));
    println!("FnMut → {}", call_fn_mut(accumulate, 5));
    println!("FnOnce → {}", call_fn_once(pure, 9));

    // 非闭包函数项也能当 Fn 用（fn 指针实现了 Fn）
    fn double(x: i32) -> i32 {
        x * 2
    }
    println!("fn 指针 → {}", call_fn(double, 21));

    // ---- 闭包在标准库中的位置 ----
    let mut nums = vec![5, 2, 8, 1];
    nums.sort_by_key(|n| -n); // 降序（闭包决定排序键）
    println!("降序 {nums:?}");
    let evens: Vec<i32> = nums.iter().filter(|n| **n % 2 == 0).copied().collect();
    println!("偶数 {evens:?}");

    // ---- 返回闭包：impl Trait 或 Box<dyn Fn> ----
    fn make_adder(n: i32) -> impl Fn(i32) -> i32 + 'static {
        move |x| x + n // move 进去，闭包才能活得比 make_adder 的栈帧久
    }
    let add10 = make_adder(10);
    println!("make_adder(10)(5) = {}", add10(5));

    fn make_counter_boxed() -> Box<dyn FnMut() -> i32> {
        // 闭包有状态（改 n）→ 只实现 FnMut；装进 Box<dyn FnMut> 需要可变调用
        let mut n = 0;
        Box::new(move || {
            n += 1;
            n
        })
    }
    let mut counter = make_counter_boxed();
    println!("boxed counter：{} {} {}", counter(), counter(), counter());

    // ---- 应用：记忆化（memoize）----
    let mut cache: HashMap<u32, u32> = HashMap::new();
    let mut fib = |n: u32| -> u32 {
        if let Some(&hit) = cache.get(&n) {
            return hit;
        }
        let (mut a, mut b) = (0u32, 1u32);
        for _ in 0..n {
            (a, b) = (b, a + b);
        }
        cache.insert(n, a);
        a
    };
    println!("fib(10) = {}，fib(40) = {}", fib(10), fib(40));
    println!("缓存命中：{} 项", cache.len());
}

#[cfg(test)]
mod tests {
    #[test]
    fn capture_by_reference() {
        let factor = 3;
        let scale = |x: i32| x * factor;
        assert_eq!(scale(4), 12);
        assert_eq!(factor, 3); // 所有权没动
    }

    #[test]
    fn closure_moves_with_move_keyword() {
        let s = String::from("data");
        let owned = move || s.len();
        assert_eq!(owned(), 4);
        // s 已 move；闭包可以反复调用（只读）——Fn
        assert_eq!(owned(), 4);
    }

    #[test]
    fn fn_once_consumes_capture() {
        let s = String::from("一次性");
        let consume = move || drop(s); // 消耗 s
        consume();
        // consume(); // ← 编译错：FnOnce 闭包只能调用一次
    }

    #[test]
    fn three_traits_hierarchy() {
        // Fn 满足 FnMut 满足 FnOnce 的位置要求
        fn takes_fn_once<F: FnOnce() -> i32>(f: F) -> i32 {
            f()
        }
        let pure = || 7;
        assert_eq!(takes_fn_once(pure), 7); // Fn 可以传给 FnOnce 参数
    }

    #[test]
    fn sort_by_key_with_closure() {
        let mut words = vec!["banana", "kiwi", "apple"];
        words.sort_by_key(|w| w.len());
        assert_eq!(words, vec!["kiwi", "apple", "banana"]);
    }

    #[test]
    fn factory_returns_closure() {
        let add5 = {
            let n = 5;
            move |x: i32| x + n
        };
        assert_eq!(add5(10), 15);
    }

    #[test]
    fn boxed_counter_state() {
        let mut c = {
            let mut n = 0;
            Box::new(move || {
                n += 1;
                n
            }) as Box<dyn FnMut() -> i32> // 有状态闭包 → FnMut
        };
        assert_eq!(c(), 1);
        assert_eq!(c(), 2);
    }
}
