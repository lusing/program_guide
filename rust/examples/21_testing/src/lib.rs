//! 21 · 测试 ⭐（被测库）：单元测试 + 文档测试的所在地
//!
//! 三种测试的位置：
//! - 单元测试：`#[cfg(test)] mod`，与被测代码同文件，可测私有函数
//! - 集成测试：`tests/` 目录，只能用公开 API（本例 tests/integration.rs）
//! - 文档测试：`///` 注释里的 ```rust 块——示例永远是编译过的、跑过的

/// 加法。
///
/// # Examples
///
/// ```
/// use testing_demo::add;
/// assert_eq!(add(2, 3), 5);
/// assert_eq!(add(-1, 1), 0);
/// ```
pub fn add(a: i32, b: i32) -> i32 {
    a + b
}

/// 除法：除零 panic（契约的一部分，用 should_panic 测）
///
/// # Panics
///
/// 除数为零时 panic。
pub fn div(a: i32, b: i32) -> i32 {
    if b == 0 {
        panic!("除数为零：{a} / {b}");
    }
    a / b
}

/// 不 panic 的版本：失败进 Result，让测试可以返回 Result 断言错误
pub fn checked_div(a: i32, b: i32) -> Result<i32, String> {
    if b == 0 {
        Err(format!("除数为零：{a} / {b}"))
    } else {
        Ok(a / b)
    }
}

/// 私有函数：集成测试摸不到，但单元测试随便测。
/// 仅被 #[cfg(test)] 使用时，非测试构建会报 dead_code——用属性豁免并注明原因。
#[cfg_attr(not(test), allow(dead_code))]
fn internal_normalize(s: &str) -> String {
    s.split_whitespace().collect::<Vec<_>>().join(" ")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn add_works() {
        assert_eq!(add(2, 2), 4);
    }

    #[test]
    fn div_works() {
        assert_eq!(div(7, 2), 3);
    }

    #[test]
    #[should_panic(expected = "除数为零")]
    fn div_by_zero_panics_with_message() {
        div(1, 0);
    }

    // 测试也可以返回 Result：可以用 ? 传播错误，失败即测试失败
    #[test]
    fn result_style_test() -> Result<(), String> {
        let q = checked_div(10, 2)?;
        assert_eq!(q, 5);
        assert!(checked_div(1, 0).is_err());
        Ok(())
    }

    #[test]
    fn private_fn_testable() {
        assert_eq!(internal_normalize("  多个   空格  "), "多个 空格");
    }

    // 慢测试默认跳过：cargo test -- --included-ignored 单独跑
    #[test]
    #[ignore = "占位演示：需要外部资源的慢测试"]
    fn slow_integration() {
        std::thread::sleep(std::time::Duration::from_millis(50));
        assert_eq!(add(1, 1), 2);
    }
}
