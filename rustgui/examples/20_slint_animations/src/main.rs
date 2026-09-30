// ============================================================
// 20_slint_animations —— 状态、动画与声明式 Path 自绘
//
// 读法：
//   1. animate 是属性的附属品；states 把"一组属性值"命名成状态。
//   2. changed 回调让反应式链跨过语言边界（progress 变 →
//      update-arc 回调 → Rust 算 SVG 弧 → arc-commands 绑定重绘）。
//   3. mock_elapsed_time 是动画测试的钥匙：测试 backend 里
//      动画不跟真实时间走，推一毫秒它动一毫秒——完全确定。
//
// 官方参考：https://docs.slint.dev/latest/docs/slint/
// ============================================================

slint::include_modules!();

/// 270° 进度环的 SVG 弧命令（viewbox 180x180，中心 90,90，半径 70）。
/// slint 表达式没有 sin/cos，数值计算留给 Rust——声明式也有边界。
fn arc_commands(progress: f32) -> String {
    let (cx, cy, r) = (90.0_f32, 90.0_f32, 70.0_f32);
    let start_deg = 135.0_f32;
    let sweep_deg = 270.0_f32 * progress.clamp(0.0, 1.0);
    let (sx, sy) = (
        cx + r * start_deg.to_radians().cos(),
        cy + r * start_deg.to_radians().sin(),
    );
    let end_deg = start_deg + sweep_deg;
    let (ex, ey) = (
        cx + r * end_deg.to_radians().cos(),
        cy + r * end_deg.to_radians().sin(),
    );
    // 大弧标志：扫过 >180° 时置 1
    let large = u8::from(sweep_deg > 180.0);
    // SVG A 命令：A rx ry x-rot large-arc sweep x y（sweep=1 顺时针）
    format!("M {sx:.2} {sy:.2} A {r} {r} 0 {large} 1 {ex:.2} {ey:.2}")
}

fn main() -> Result<(), slint::PlatformError> {
    let selftest = std::env::args().nth(1).is_some_and(|a| a == "--selftest");
    if selftest {
        run_selftest();
        return Ok(());
    }

    let app = AnimLab::new()?;

    // 反应式链的 Rust 半边：progress 一变就算弧命令写回
    {
        let weak = app.as_weak();
        app.on_update_arc(move || {
            let app = weak.upgrade().unwrap();
            let p = app.get_progress();
            app.set_arc_commands(arc_commands(p).into());
        });
    }
    app.set_progress(0.55); // 触发 changed → update-arc → 弧命令就位

    app.run()
}

/// 无头自检：changed 链路、动画推进（mock 时间）、几何查询滑块。
fn selftest_body() -> (f32, f32, String) {
    use slint::ComponentHandle;

    i_slint_backend_testing::init_no_event_loop();
    let app = AnimLab::new().expect("testing backend 下创建组件失败");

    // Rust 半边的反应式链（与 main 相同接线；真窗口里由 changed 触发，
    // 无头环境 changed 依赖事件循环不刷新——测试里成对设置，见坑位）
    {
        let weak = app.as_weak();
        app.on_update_arc(move || {
            let app = weak.upgrade().unwrap();
            let p = app.get_progress();
            app.set_arc_commands(arc_commands(p).into());
        });
    }

    // ---- 弧命令链路（无头：成对设置；绑定重绘是同步反应式的）----
    app.set_progress(0.5);
    app.invoke_update_arc(); // 直接调用回调（真窗口里由 changed progress 触发）
    let cmds = app.get_arc_commands().to_string();
    assert!(cmds.starts_with("M "), "弧命令应已就位：{cmds}");

    // ---- 动画语义的实测课 ----
    // animate 作用在属性上：翻转后从 20 向 120 插值。中途读到的值取决于
    // 动画驱动状态（时序敏感，不硬断言）；推进 250ms 模拟时间后动画必然
    // 走完——终值断言是确定性的。
    let x_before = app.get_knob_x(); // 初始：off -> 20
    app.set_on(true);
    assert!((x_before - 20.0).abs() < 0.5, "初始滑块应在 20：{x_before}");

    let t0 = i_slint_backend_testing::get_mocked_time();
    i_slint_backend_testing::mock_elapsed_time(std::time::Duration::from_millis(260));
    let t1 = i_slint_backend_testing::get_mocked_time();
    assert!(t1 >= t0 + 260, "模拟时间应精确推进：{t0} -> {t1}");

    let x_final = app.get_knob_x(); // 250ms 时长 < 260ms 推进：动画已走完
    assert!(
        (x_final - 120.0).abs() < 0.5,
        "动画走完后应到位 120：{x_final}"
    );

    (x_before, x_final, cmds)
}

fn run_selftest() {
    println!("==== 20 slint 动画与 Path 开始 ====");
    let (x0, x1, cmds) = selftest_body();
    println!("knob-x: {x0:.1} -> {x1:.1} (mock +260ms 后到位)");
    println!("arc(0.5) = {cmds}");
    println!("==== 20 slint 动画与 Path 结束 ====");
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn animation_advances_and_arc_updates() {
        let (x0, x1, cmds) = selftest_body();
        assert!((x0 - 20.0).abs() < 0.5 && (x1 - 120.0).abs() < 0.5);
        assert!(cmds.contains("A 70"));
    }

    #[test]
    fn arc_math_is_pure() {
        // 0%：扫 0°，大弧标志 0；100%：扫 270° > 180°，大弧标志 1
        assert!(!arc_commands(0.0).contains("0 1 1"));
        assert!(arc_commands(1.0).contains("0 1 1"));
    }
}
