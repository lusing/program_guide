// ============================================================
// 18_slint_state —— 双向数据流：绑定、TouchArea 与全局单例
//
// 读法：
//   1. 属性是状态、绑定是反应式更新：km 变 → miles 文本自动变。
//   2. TouchArea 是输入事件的入口（clicked/pressed/moved），
//      LineEdit 的 edited(text) 回调带载荷回 Rust 世界门口。
//   3. global 单例 = 跨组件共享状态，Rust 侧 Settings::get() 读写。
//   4. 无头通道：坐标点 LineEdit 聚焦 → 键盘序列注入 → 断言属性。
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

    let app = UnitConverter::new()?;
    app.run()
}

/// 无头自检：按 id 查元素 → 点击聚焦 → 键盘注入 → 断言属性联动；
/// 再点 TouchArea 翻转全局主题。
fn selftest_body() -> (f32, f32, bool) {
    i_slint_backend_testing::init_no_event_loop();

    let app = UnitConverter::new().expect("testing backend 下创建组件失败");

    // 元素查询：注意 id 带组件前缀（组件名::元素名）。
    // 文本输入走 a11y 通道：set_accessible_value 等价于读屏的 set_value，
    // 内部直连 LineEdit 的 accessible-value <=> text 并触发 edited 回调
    // ——比"点击聚焦再打字"少两步、且不依赖布局。
    let input = testing::element_by_id(&app, "UnitConverter::km-input");
    input.set_accessible_value("42");

    let km = app.get_km();
    let miles = app.get_miles();

    // 主题条 TouchArea：几何查询 + 坐标点击（单点即验）
    let toggle = testing::element_by_id(&app, "UnitConverter::dark-toggle");
    testing::click_element(&app, &toggle);
    let dark_after_one = Settings::get(&app).get_dark();
    testing::click_element(&app, &toggle); // 再点一次 = 回到 false
    let dark = Settings::get(&app).get_dark();
    assert!(dark_after_one, "TouchArea 第一次点击应翻转 Settings.dark");

    (km, miles, dark)
}

fn run_selftest() {
    println!("==== 18 slint 状态与绑定 开始 ====");
    let (km, miles, dark) = selftest_body();
    println!("km={km} miles={miles:.3} dark={dark}");
    assert!((km - 42.0).abs() < 1e-3, "键盘注入应写入 km=42");
    assert!((miles - 26.0976).abs() < 1e-2, "换算联动应为 26.098");
    assert!(!dark, "主题条点击两次应回到 false");
    println!("==== 18 slint 状态与绑定 结束 ====");
}

#[cfg(test)]
mod tests {
    #[test]
    fn typing_converts_and_global_toggles() {
        let (km, miles, dark) = super::selftest_body();
        assert!((km - 42.0).abs() < 1e-3);
        assert!((miles - 26.0976).abs() < 1e-2);
        assert!(!dark);
    }
}
