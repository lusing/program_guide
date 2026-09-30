// ============================================================
// 17_slint_hello —— Slint 声明式 DSL 最小应用
//
// 读法：
//   1. 界面写在 ui/app.slint（独立 DSL），build.rs 用 slint_build
//      编译成 Rust 代码，slint::include_modules!() 引入。
//   2. Rust 侧只拿 handle：get_/set_ 属性、on_/invoke_ 回调。
//   3. 无头测试走官方 i-slint-backend-testing（slint 1.18 起旧
//      slint::testing 模块已移除）：init_no_event_loop() 安装
//      测试 backend，send_mouse_click 按坐标注入事件，无真实窗口。
//
// 【坑】init_no_event_loop 每进程只能成功一次——一个示例只保留
//      一个 #[test]（多测试并发会二次 set_platform 直接 panic）。
//
// 官方参考：https://docs.slint.dev/latest/docs/slint/
// ============================================================

mod testing;

slint::include_modules!();

fn main() -> Result<(), slint::PlatformError> {
    let selftest = std::env::args().nth(1).is_some_and(|a| a == "--selftest");
    if selftest {
        run_selftest();
        return Ok(());
    }

    let app = AppWindow::new()?;
    app.run()
}

/// 无头自检：测试 backend 下按坐标连点三次 TouchArea 条带，
/// 再从 Rust 侧读回属性断言。
fn selftest_body() -> i32 {
    i_slint_backend_testing::init_no_event_loop();

    let app = AppWindow::new().expect("testing backend 下创建组件失败");

    // 测试窗口默认 800x600；条带是布局第一个子元素：
    // padding 16px + height 40px → (50, 35) 稳定命中。
    testing::send_mouse_click(&app, 50.0, 35.0);
    testing::send_mouse_click(&app, 50.0, 35.0);
    testing::send_mouse_click(&app, 50.0, 35.0);

    app.get_click_count()
}

fn run_selftest() {
    println!("==== 17 slint 最小应用 开始 ====");
    let count = selftest_body();
    println!("count after 3 clicks = {count}");
    assert_eq!(count, 3, "点击三次 Increment 条带后计数应为 3");
    println!("==== 17 slint 最小应用 结束 ====");
}

#[cfg(test)]
mod tests {
    #[test]
    fn three_clicks_count_to_three() {
        assert_eq!(super::selftest_body(), 3);
    }
}
