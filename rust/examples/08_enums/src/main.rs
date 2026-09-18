//! 08 · 枚举与模式匹配：带数据的 enum、match 穷尽性、绑定/守卫/if let/let-else

#[derive(Debug)]
enum Shape {
    Circle { radius: f64 }, // 结构体式变体（命名字段）
    Rect(f64, f64),         // 元组式变体（位置字段）
    Point,                  // 无数据变体
}

#[derive(Debug)]
enum Message {
    Quit,
    Move { x: i32, y: i32 },
    Write(String),
    ChangeColor(u8, u8, u8),
}

impl Message {
    /// match 是表达式：每个分支产出同类型的值
    fn summarize(&self) -> String {
        match self {
            Message::Quit => "退出".to_string(),
            // 模式绑定：把字段值解构出来用
            Message::Move { x, y } => format!("移动到 ({x}, {y})"),
            Message::Write(text) => format!("写入 {text:?}"),
            Message::ChangeColor(r, g, b) => format!("改色 #{r:02x}{g:02x}{b:02x}"),
        }
    }
}

fn area(s: &Shape) -> f64 {
    let pi = std::f64::consts::PI;
    match s {
        Shape::Circle { radius } => pi * radius * radius,
        Shape::Rect(w, h) => w * h,
        Shape::Point => 0.0, // 少这一支编译不过：match 必须穷尽
    }
}

fn main() {
    // ---- enum = 带数据的标签联合（tagged union）----
    let shapes = [
        Shape::Circle { radius: 1.0 },
        Shape::Rect(3.0, 4.0),
        Shape::Point,
    ];
    for s in &shapes {
        println!("{s:<18?} 面积 {:>8.4}", area(s));
    }

    // ---- match 全家桶 ----
    let msgs = [
        Message::Quit,
        Message::Move { x: 3, y: -4 },
        Message::Write("你好".into()),
        Message::ChangeColor(0xFF, 0x80, 0x00),
    ];
    for m in &msgs {
        println!("  {}", m.summarize());
    }

    // 字面量 + 范围模式 + 守卫（guard）
    let n = 42;
    let desc = match n {
        0 => "零",
        1 | 7 => "幸运",           // 或模式（不连续值；连续值用 1..=3 范围模式更短）
        4..=9 => "中",             // 范围模式
        x if x % 2 == 0 => "偶大", // 守卫：附加布尔条件
        _ => "奇大",               // 兜底
    };
    println!("{n} → {desc}");

    // 嵌套解构：match 一层挖到底
    let pairs = [(1, 2), (0, 5), (3, 3)];
    for &(a, b) in &pairs {
        let label = match (a, b) {
            (0, y) => format!("a 是零，b = {y}"),
            (x, 0) => format!("a = {x}，b 是零"),
            (x, y) if x == y => format!("相等 {x}"),
            (x, y) => format!("普通 ({x}, {y})"),
        };
        println!("  {label}");
    }

    // ---- 绑定 @：既匹配又捕获 ----
    let age = 30u32;
    match age {
        n @ 0..=17 => println!("未成年（{n}）"),
        n @ 18..=65 => println!("劳动年龄（{n}）"),
        n => println!("退休年龄（{n}）"),
    }

    // ---- if let：只关心一种分支时的简写 ----
    let favorite = Some(7);
    if let Some(n) = favorite {
        println!("最喜欢 {n}");
    } else {
        println!("没有偏爱");
    }

    // ---- let else：解构失败必须发散（return/break/panic/continue）----
    let maybe: Option<i32> = None;
    let _ = maybe; // 也许没有值
    fn first_char(s: &str) -> Option<char> {
        let Some(c) = s.chars().next() else {
            return None; // else 分支必须发散，不能"继续往下走"
        };
        Some(c) // 此后 c 已解包，直接用
    }
    println!("first_char(\"中\") = {:?}", first_char("中文"));
    println!("first_char(\"\")   = {:?}", first_char(""));

    // ---- matches! 宏：只要布尔判定 ----
    assert!(matches!(Some(9), Some(n) if n > 5));
    assert!(matches!(Shape::Point, Shape::Point));

    // ---- Option/Result 是标准库 enum，同一套匹配规则 ----
    let divided: Result<i32, String> = divide(10, 3);
    match divided {
        Ok(q) => println!("10/3 = {q} 余 …"),
        Err(e) => println!("错误：{e}"),
    }
    println!("10/0 = {:?}", divide(10, 0));
}

fn divide(a: i32, b: i32) -> Result<i32, String> {
    if b == 0 {
        Err("除数为零".to_string())
    } else {
        Ok(a / b)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn match_is_exhaustive() {
        assert_eq!(area(&Shape::Circle { radius: 1.0 }), std::f64::consts::PI);
        assert_eq!(area(&Shape::Rect(3.0, 4.0)), 12.0);
        assert_eq!(area(&Shape::Point), 0.0);
    }

    #[test]
    fn variants_carry_data() {
        let m = Message::Write("数据".into());
        assert_eq!(m.summarize(), "写入 \"数据\"");
        assert_eq!(Message::Quit.summarize(), "退出");
    }

    #[test]
    fn guards_and_ranges() {
        let classify = |n: i32| match n {
            1 | 3 => "小",
            4..=9 => "中",
            x if x < 0 => "负",
            _ => "大",
        };
        assert_eq!(classify(2), "大"); // 2 不在 1|3，也不在 4..=9 → 兜底
        assert_eq!(classify(7), "中");
        assert_eq!(classify(-1), "负");
        assert_eq!(classify(100), "大");
    }

    #[test]
    fn if_let_and_matches() {
        let x: Option<u8> = Some(3);
        if let Some(v) = x {
            assert_eq!(v, 3);
        }
        assert!(matches!(x, Some(3)));
        assert!(!x.is_none()); // 判 None 直接用 is_none()（clippy 对 matches!(x, None) 的建议）
    }

    #[test]
    fn let_else_unwraps_or_diverges() {
        // let-else 的 else 分支可以做比 ? 更复杂的事（构造错误信息、记录日志……）
        fn parse_pair(s: &str) -> Result<(i32, i32), String> {
            let Some((a, b)) = s.split_once(',') else {
                return Err(format!("缺少逗号：{s:?}"));
            };
            match (a.trim().parse::<i32>(), b.trim().parse::<i32>()) {
                (Ok(a), Ok(b)) => Ok((a, b)),
                _ => Err(format!("无法解析为整数：{s:?}")),
            }
        }
        assert_eq!(parse_pair("3, 4"), Ok((3, 4)));
        assert!(parse_pair("坏数据").is_err());
        assert!(parse_pair("3,x").is_err());
    }

    #[test]
    fn result_matching() {
        assert_eq!(divide(10, 2), Ok(5));
        assert!(divide(1, 0).is_err());
    }
}
