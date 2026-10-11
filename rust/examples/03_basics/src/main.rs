//! 03 · 变量、类型、控制流与函数：Rust 与 C/C++ 的同与不同
//!
//! 对 C/C++ 读者的速览 + Rust 特有细节。官方书 TRB 也是把这一整块
//! 放在同一章（Common Programming Concepts）——熟悉的部分快速过，
//! 坑位慢慢看。

fn main() {
    // ============ 一切皆表达式：语句与表达式 ============
    // 语句两种：声明语句（let/fn/use）与表达式语句（表达式 + 分号，值丢弃成 ()）。
    // 块 { ... } 本身是表达式：块末无分号的表达式就是块的值。
    let block_val = {
        let a = 40;
        let b = 2;
        a + b // 块的值 = 42（无分号！）
    };
    println!("块表达式的值 = {block_val}");

    // 位置表达式 vs 值表达式：位置表达式（变量/解引用/索引/字段）出现在
    // 赋值号右边的"值上下文"里，会把内存位置让渡出去——这就是 move（04 章）。
    let place1 = "hello"; // &str：Copy 类型，让渡的是副本
    let place2 = "hello".to_string(); // String：move 语义
    let other = place1; // 按位复制，place1 仍可用
    let other2 = place2; // move：内存位置让渡给 other2
    // println!("{place2}"); // ← 编译错：value used here after move
    println!("place1={other}（Copy 仍在），place2 → {other2}（已 move）");

    // 值表达式不能出现在位置上下文（赋值号左边）：
    // make_value() = 3; // ← 编译错：invalid left-hand side expression
    // 但 & 可以为值表达式锚定临时存储：let r = &42 合法
    let anchored = &42;
    println!("&42 锚定临时存储 → {anchored}");

    // ============ 类型大小的三种形态（03 章 3.6 表格的实测）============
    println!(
        "size_of &[u8;5]={} &[u8]={} &str={} ()={}",
        std::mem::size_of::<&[u8; 5]>(),
        std::mem::size_of::<&[u8]>(),
        std::mem::size_of::<&str>(),
        std::mem::size_of::<()>()
    ); // 8 / 16 / 16 / 0 —— 普通引用 vs 胖指针 vs ZST

    // DST 当参数类型直接编译错（fn f(arr: [u32]) 报 size 未知）——
    // 参数要写 [u32; 5] 或 &[u32]（胖指针）。这里只演示合法形态：
    fn _takes_slice(_s: &[u32]) {}
    // _takes_slice 不调用：演示签名即可（调用会触发 dead_code 之外的告警噪音）

    // 推断没收敛时编译器给出占位类型名 {integer}——补标注即可：
    // let a = 0;
    // a.is_positive(); // ← 报错：no method named `is_positive` on type `{integer}`
    let a: i32 = 0;
    println!("标注收敛后 is_positive = {}", a.is_positive());

    // ============ 变量：绑定而非赋值 ============
    let x = 42; // 默认不可变（编译期强制，不是君子协定）
    let mut count = 0; // mut 才能改
    count += 1;
    println!("x = {x}，count = {count}");

    // 遮蔽（shadowing）：同名新绑定，可换类型——与 mut 完全不同
    let spaces = "   "; // &str
    let spaces = spaces.len(); // usize，同名不同类型，合法
    println!("spaces = {spaces}");

    // ============ 标量类型 ============
    let _a: i8 = -128; // 有符号 8..128 位：i8/i16/i32/i64/i128/isize
    let _b: u8 = 255; // 无符号：u8/u16/u32/u64/u128/usize
    let _f: f64 = 3.5; // f32/f64（浮点没有隐式转换，运算两边必须同型）
    let ok: bool = true; // 没有"整数当布尔"这种事：if 1 {} 编译不过
    let c = '中'; // char 是 4 字节 Unicode 标量值，不是 1 字节！
    println!("{ok} {c}，'中' 占 {} 字节（UTF-8）", '中'.len_utf8());
    let n: usize = 10; // isize/usize 与指针等宽，做下标用
    println!("usize = {n}");

    // ============ 复合类型 ============
    let t: (i32, f64, char) = (500, 6.4, 'z'); // 元组：异构定长
    let (q, _w, e) = t; // 解构
    println!("t.0 = {}，解构 {q} {e}", t.0);

    let arr: [u8; 5] = [1, 2, 3, 4, 5]; // 数组：同构定长，栈上
    let zeros = [0u8; 8]; // 重复初始化
    let [first, .., last] = arr; // 切片模式解构
    println!("first={first} last={last} zeros={zeros:?}");
    // 越界在安全代码里 panic（不产生未定义行为）：
    // arr[10]; // ← 编译期已知长度时直接编译错；运行期确定时 panic

    // ============ 推断、标注与转换 ============
    let parsed = "42".parse::<i32>().unwrap(); // turbofish 指定目标类型
    let parsed2: i64 = "42".parse().unwrap(); // 标注让推断收敛
    let sum = parsed as i64 + parsed2; // Rust 没有隐式数值转换，必须显式 as
    println!("sum = {sum}");
    println!("300 as u8 = {}（取低 8 位）", 300i32 as u8); // 44
    println!("2.9 as i32 = {}（朝零截断，非四舍五入）", 2.9f64 as i32); // 2

    // ============ 溢出：Debug panic / Release 环绕，显式策略四选一 ============
    let (m, one) = (u8::MAX, 1u8);
    println!("checked_add: {:?}", m.checked_add(one)); // None（Option）
    println!("wrapping_add: {}", m.wrapping_add(one)); // 0
    println!("saturating_add: {}", m.saturating_add(one)); // 255
    println!("overflowing_add: {:?}", m.overflowing_add(one)); // (0, true)

    // ============ 常量、静态与别名 ============
    const MAX_POINTS: u32 = 100_000; // 编译期求值，必须标类型
    static NAME: &str = "guide"; // 'static 生命周期，固定地址
    type Kilometers = i32; // 类型别名
    let km: Kilometers = 5;
    println!("const={MAX_POINTS} static={NAME} km={km}");

    // ============ 控制流：一切都是表达式 ============
    let n = 6;
    let parity = if n % 2 == 0 { "偶" } else { "奇" }; // if 有值
    println!("{n} 是{parity}数");

    let mut counter = 0;
    let result = loop {
        // loop + break 带值（C 的 while(true)+flag 写法的替代）
        counter += 1;
        if counter == 10 {
            break counter * 2;
        }
    };
    println!("loop 结果 = {result}");

    let mut fuel = 3;
    while fuel > 0 {
        fuel -= 1;
    }
    println!("燃料余量 {fuel}");

    for i in 0..5 {
        print!("{i} "); // 0 1 2 3 4（半开区间）
    }
    print!("| ");
    for i in 1..=5 {
        print!("{i} "); // 1 2 3 4 5（闭区间 ..=）
    }
    print!("| ");
    for i in (0..4).rev() {
        print!("{i} "); // 3 2 1 0
    }
    print!("| ");
    for ch in "你好a".chars() {
        print!("{ch}/"); // 按字符，不按字节
    }
    println!();

    let nums = [10, 20, 30];
    for (i, v) in nums.iter().enumerate() {
        println!("  arr[{i}] = {v}"); // iter() 借用视图，不搬所有权
    }

    // 标签：break/continue 指定层级
    let mut hits = 0;
    'outer: for x in 0..5 {
        for y in 0..5 {
            if x * y > 6 {
                break 'outer;
            }
            hits += 1;
        }
    }
    println!("hits = {hits}");

    // match 一瞥（08 章细讲）：必须穷尽
    let code = 4200;
    let region = match code {
        4000..=4999 => "东部",
        1000..=1999 => "总部",
        _ => "其他",
    };
    println!("区号 {code} → {region}");

    // ============ 函数 ============
    println!("add(3, 4) = {}", add(3, 4));
    println!("sign(-5) = {}", sign(-5));
    log("基础篇演示完毕");
}

/// 参数类型必须显式；返回类型用 ->。
/// 块末无分号 → 块的值就是返回值（无需 return）。
fn add(a: i32, b: i32) -> i32 {
    a + b
}

/// 提前返回才用 return（惯用于守卫子句）
fn sign(x: i32) -> i32 {
    if x == 0 {
        return 0;
    }
    if x > 0 { 1 } else { -1 }
}

/// 无返回值其实返回单元类型 ()
fn log(msg: &str) {
    println!("[log] {msg}");
}

/// 发散函数 `!`：永不返回（panic/无限循环），可 coerce 成任何类型。
/// 只被测试调用，非测试构建按 dead_code 豁免。
#[cfg_attr(not(test), allow(dead_code))]
fn die() -> ! {
    panic!("致命错误");
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn place_vs_value_expressions() {
        // 位置表达式出现在值上下文：Copy 复制、非 Copy move
        let s = String::from("move 我");
        let moved = s;
        // s 已不可用；这里只断言新绑定拿到了值
        assert_eq!(moved, "move 我");
        // 块表达式有值
        let v = {
            let x = 1;
            let y = 2;
            x + y
        };
        assert_eq!(v, 3);
    }

    #[test]
    fn type_size_three_forms() {
        // Sized 引用 8 字节；胖指针（DST 视图）16 字节；ZST 0 字节
        assert_eq!(std::mem::size_of::<&[u8; 5]>(), 8);
        assert_eq!(std::mem::size_of::<&[u8]>(), 16);
        assert_eq!(std::mem::size_of::<&str>(), 16);
        assert_eq!(std::mem::size_of::<()>(), 0);
    }

    #[test]
    fn inference_placeholder_needs_annotation() {
        let a: i32 = 0; // 不标注时 a.is_positive() 报 {integer} 无此方法
        assert!(!a.is_positive());
    }

    #[test]
    fn overflow_strategies() {
        assert_eq!(u8::MAX.checked_add(1), None);
        assert_eq!(u8::MAX.wrapping_add(1), 0);
        assert_eq!(u8::MAX.saturating_add(1), 255);
        assert_eq!(u8::MAX.overflowing_add(1), (0, true));
    }

    #[test]
    fn casts_truncate() {
        assert_eq!(300i32 as u8, 44); // 300 = 0b1_0010_1100，低 8 位
        assert_eq!(2.9f64 as i32, 2);
        assert_eq!((-2.9f64) as i32, -2);
    }

    #[test]
    fn shadowing_changes_type() {
        let s = "123";
        let s: i32 = s.parse().unwrap(); // 同名遮蔽成 i32
        assert_eq!(s, 123);
    }

    #[test]
    fn tuple_array_destructuring() {
        let t = (1, "two", 3.0);
        assert_eq!(t.1, "two");
        let arr = [1, 2, 3, 4];
        let [a, .., d] = arr;
        assert_eq!((a, d), (1, 4));
    }

    #[test]
    fn control_flow_expressions() {
        let mut n = 0;
        let v = loop {
            n += 1;
            if n * n >= 100 {
                break n;
            }
        };
        assert_eq!(v, 10);
        let parity = if 4 % 2 == 0 { "偶" } else { "奇" };
        assert_eq!(parity, "偶");
        let total: i32 = (1..=5).sum();
        assert_eq!(total, 15);
    }

    #[test]
    fn functions_and_unit() {
        assert_eq!(add(3, 4), 7);
        assert_eq!(sign(-5), -1);
        assert_eq!(sign(0), 0);
        log("hi"); // 返回 ()——单元值无需绑定
    }

    #[test]
    #[should_panic(expected = "致命错误")]
    fn diverging_function_panics() {
        die();
    }
}
