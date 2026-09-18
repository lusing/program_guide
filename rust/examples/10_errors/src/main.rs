//! 10 · 错误处理：panic vs Result、? 运算符、From 转换、自定义错误、main 返回 Result

use std::fmt;
use std::num::ParseIntError;

/// 应用级错误枚举：thiserror 风格（手写等价物见下）
#[derive(Debug)]
enum AppError {
    EmptyInput,
    Parse(ParseIntError), // 包装底层错误，保留错误链
    OutOfRange { value: i32, min: i32, max: i32 },
}

// 手写 Display + Error —— 实际项目用 thiserror 一个属性搞定（见 docs）
impl fmt::Display for AppError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            AppError::EmptyInput => write!(f, "输入为空"),
            AppError::Parse(e) => write!(f, "解析失败：{e}"),
            AppError::OutOfRange { value, min, max } => {
                write!(f, "{value} 超出 [{min}, {max}]")
            }
        }
    }
}

impl std::error::Error for AppError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            AppError::Parse(e) => Some(e), // 错误链：上层能挖到根因
            _ => None,
        }
    }
}

// From 让 ? 自动把 ParseIntError 转成 AppError
impl From<ParseIntError> for AppError {
    fn from(e: ParseIntError) -> Self {
        AppError::Parse(e)
    }
}

/// 业务函数：返回 Result，错误沿调用链上抛
fn parse_score(s: &str) -> Result<i32, AppError> {
    let s = s.trim();
    if s.is_empty() {
        return Err(AppError::EmptyInput);
    }
    let n: i32 = s.parse()?; // ? = match { Ok(v)=>v, Err(e)=>return Err(From::from(e)) }
    if !(0..=100).contains(&n) {
        return Err(AppError::OutOfRange {
            value: n,
            min: 0,
            max: 100,
        });
    }
    Ok(n)
}

fn main() {
    // ---- unwrap 家族：原型可以用，生产要收殓 ----
    // 这些方法都按值消费 Result（self），一串演示各自取新值；
    // 字面量 Ok/Err 会被 clippy 看穿（unnecessary_literal_unwrap），用 parse 造运行期的值
    println!("unwrap：{}", "1".parse::<i32>().unwrap());
    println!("unwrap_or：{}", "abc".parse::<i32>().unwrap_or(0));
    println!(
        "unwrap_or_else：{}",
        "abc"
            .parse::<i32>()
            .unwrap_or_else(|e| e.to_string().len() as i32) // 闭包要用到错误本身
    );
    println!(
        "unwrap_or_default：{}",
        "abc".parse::<i32>().unwrap_or_default()
    );
    // bad.unwrap();          // ← panic：called `Result::unwrap()` on an `Err` value
    // bad.expect("说明信息"); // ← panic，但带自定义信息，排错更快

    // ---- map / and_then：不离开 Result 世界 ----
    let doubled = parse_score("88").map(|n| n * 2);
    let grade = parse_score("88").and_then(|n| {
        if n >= 60 {
            Ok("及格")
        } else {
            Err(AppError::OutOfRange {
                value: n,
                min: 60,
                max: 100,
            })
        }
    });
    println!("doubled = {doubled:?}，grade = {grade:?}");

    // ---- 处理错误的三种姿态 ----
    match parse_score("105") {
        Ok(n) => println!("分数 {n}"),
        Err(e) => println!("match 捕获：{e}"),
    }
    if let Ok(n) = parse_score("66") {
        println!("if let：{n} 分");
    }
    println!("is_ok/iter：{:?}", parse_score("x").is_err());

    // ---- panic 的边界：不可恢复的契约破裂才用它 ----
    // assert_eq!(1, 2);      // ← panic：断言失败
    // panic!("直接爆炸");     // ← panic
    // Option 上用 expect 表达"这里绝不可能是 None"：
    let opt: Option<i32> = "5".parse().ok(); // 运行期才知道的 Option
    let v = opt.expect("按约定这里必有值");
    println!("expect 解包：{v}");

    // ---- 展示完整错误链 ----
    for input in ["42", "", "3.14", "150"] {
        match parse_score(input) {
            Ok(n) => println!("输入 {input:?} → {n} 分"),
            Err(e) => {
                print!("输入 {input:?} → 错误：{e}");
                if let Some(src) = std::error::Error::source(&e) {
                    print!("（根因：{src}）");
                }
                println!();
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn happy_path() {
        assert_eq!(parse_score(" 88 ").unwrap(), 88);
        assert_eq!(parse_score("0").unwrap(), 0);
    }

    #[test]
    fn error_kinds() {
        assert!(matches!(parse_score(""), Err(AppError::EmptyInput)));
        assert!(matches!(parse_score("abc"), Err(AppError::Parse(_))));
        assert!(matches!(
            parse_score("150"),
            Err(AppError::OutOfRange { value: 150, .. })
        ));
    }

    #[test]
    fn display_is_human_readable() {
        let e = parse_score("150").unwrap_err();
        assert_eq!(e.to_string(), "150 超出 [0, 100]");
        let e = parse_score("").unwrap_err();
        assert_eq!(e.to_string(), "输入为空");
    }

    #[test]
    fn error_chain_reaches_root() {
        let e = parse_score("abc").unwrap_err();
        assert!(std::error::Error::source(&e).is_some()); // ParseIntError 在链上
    }

    #[test]
    fn from_powers_question_mark() {
        // "abc".parse::<i32>() 产生 ParseIntError，? 借助 From 转成 AppError
        fn f(s: &str) -> Result<i32, AppError> {
            Ok(s.parse::<i32>()?)
        }
        assert!(matches!(f("1"), Ok(1)));
        assert!(matches!(f("x"), Err(AppError::Parse(_))));
    }

    #[test]
    #[should_panic(expected = "按约定")]
    fn expect_panics_with_message() {
        let none: Option<i32> = "abc".parse().ok(); // 解析失败 → None
        let _ = none.expect("按约定这里必有值");
    }
}
