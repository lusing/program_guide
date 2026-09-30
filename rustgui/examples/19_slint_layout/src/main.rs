// ============================================================
// 19_slint_layout —— 布局系统与几何断言
//
// 读法：
//   1. 三种布局盒：Vertical/Horizontal/Grid；子元素用
//      width（定值）/ horizontal-stretch（弹性权重）参与分配。
//   2. 与 egui 04 章对齐：布局不是"看起来对"，而是可断言的数字
//      ——ElementHandle::absolute_position 就是布局的考卷。
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

    let app = LayoutLab::new()?;
    app.on_click(|name| println!("clicked: {name}"));
    app.run()
}

/// 无头自检：三栏的弹性分配、网格的行列对齐、按钮点击回调。
fn selftest_body() -> (f32, f32, f32, f32, f32, f32, i32) {
    i_slint_backend_testing::init_no_event_loop();
    let app = LayoutLab::new().expect("testing backend 下创建组件失败");

    // 记录回调触发
    let hits = std::rc::Rc::new(std::cell::Cell::new(0));
    let hits2 = hits.clone();
    app.on_click(move |_name| hits2.set(hits2.get() + 1));

    // ---- 几何断言：三栏水平排布，x 单调递增 ----
    let left = testing::element_by_id(&app, "LayoutLab::left-pane");
    let center = testing::element_by_id(&app, "LayoutLab::center-pane");
    let right = testing::element_by_id(&app, "LayoutLab::right-pane");
    let (lx, cx, rx) = (
        left.absolute_position().x,
        center.absolute_position().x,
        right.absolute_position().x,
    );
    assert!(lx < cx && cx < rx, "三栏应水平递增：{lx} < {cx} < {rx}");

    // ---- 网格两行：label 同列对齐（x 相等）、field 同列对齐 ----
    let la = testing::element_by_id(&app, "LayoutLab::label-a");
    let lb = testing::element_by_id(&app, "LayoutLab::label-b");
    let fa = testing::element_by_id(&app, "LayoutLab::field-a");
    let fb = testing::element_by_id(&app, "LayoutLab::field-b");
    let (lax, lbx, fax, fbx) = (
        la.absolute_position().x,
        lb.absolute_position().x,
        fa.absolute_position().x,
        fb.absolute_position().x,
    );
    assert!(
        (lax - lbx).abs() < 0.5,
        "Grid 两行 label 应同列：{lax} vs {lbx}"
    );
    assert!(
        (fax - fbx).abs() < 0.5,
        "Grid 两行 field 应同列：{fax} vs {fbx}"
    );
    assert!(lax < fax, "label 列在 field 列左侧");

    // ---- 按钮回调（几何点击）----
    // std Button 也能按类型名查（match_type_name），拿真实几何再点
    use i_slint_backend_testing::ElementRoot;
    let button = app
        .root_element() // ElementRoot trait 提供 root_element
        .query_descendants()
        .match_type_name(String::from("Button"))
        .find_first()
        .expect("应能按类型名查到 Button");
    let bpos = button.absolute_position();
    testing::send_mouse_click(&app, bpos.x + 10.0, bpos.y + 10.0);
    let n = hits.get();

    drop(app);
    (lx, cx, rx, lax, lbx, fax - fbx, n)
}

fn run_selftest() {
    println!("==== 19 slint 布局系统 开始 ====");
    let (lx, cx, rx, lax, lbx, grid_dx, clicks) = selftest_body();
    println!("panes x: {lx:.1} < {cx:.1} < {rx:.1}");
    println!("grid label x: {lax:.1} vs {lbx:.1} (dx={grid_dx:.1})");
    println!("callback clicks = {clicks}");
    assert!(clicks >= 1, "居中按钮应能被几何点击命中");
    println!("==== 19 slint 布局系统 结束 ====");
}

#[cfg(test)]
mod tests {
    #[test]
    fn layout_geometry_and_callback() {
        let (lx, cx, rx, lax, lbx, grid_dx, clicks) = super::selftest_body();
        assert!(lx < cx && cx < rx);
        assert!((lax - lbx).abs() < 0.5 && grid_dx.abs() < 0.5);
        assert!(clicks >= 1);
    }
}
