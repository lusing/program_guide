//! 集成测试：完全像外部用户一样使用这个库（只能 use 公开项）。
//! 每个 tests/*.rs 都是独立二进制，与 src 内部单测分开编译运行。

use testing_demo::{add, checked_div};

#[test]
fn integration_add() {
    assert_eq!(add(20, 22), 42);
}

#[test]
fn integration_checked_div() {
    assert_eq!(checked_div(9, 3), Ok(3));
    assert!(checked_div(9, 0).is_err());
}
