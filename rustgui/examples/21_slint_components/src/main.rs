// ============================================================
// 21_slint_components —— 组件复用与 Rust 深度集成
//
// 读法：
//   1. 自定义组件 = 属性接口 + 回调出口；根组件转发嵌套回调
//      （生成代码只暴露根的接口面）。
//   2. invoke_from_event_loop：任意线程安全地摸 UI——后台线程的
//      标准姿势（weak upgrade + invoke + set 属性）。
//   3. 无头边界：init_no_event_loop 的 threading=false，
//      invoke_from_event_loop 走不通——集成测可测的部分，
//      事件循环专属路径留给真窗口（坑位有说明）。
//
// 官方参考：https://docs.slint.dev/latest/docs/slint/
// ============================================================

slint::include_modules!();

fn main() -> Result<(), slint::PlatformError> {
    let selftest = std::env::args().nth(1).is_some_and(|a| a == "--selftest");
    if selftest {
        run_selftest();
        return Ok(());
    }

    let app = CompLab::new()?;

    // 记录两个计数器的活动（Rust 侧 set_callback 挂根级转发回调）
    let log = std::rc::Rc::new(std::cell::RefCell::new(Vec::<&'static str>::new()));
    {
        let log = log.clone();
        app.on_bump_a(move || log.borrow_mut().push("a+"));
    }
    {
        let log = log.clone();
        app.on_reset_a(move || log.borrow_mut().push("a0"));
    }
    {
        let log = log.clone();
        app.on_bump_b(move || log.borrow_mut().push("b+"));
    }
    {
        let log = log.clone();
        app.on_reset_b(move || log.borrow_mut().push("b0"));
    }

    // ---- 后台线程 + invoke_from_event_loop：跨线程摸 UI 的正解 ----
    let weak = app.as_weak();
    std::thread::spawn(move || {
        for _ in 0..5 {
            std::thread::sleep(std::time::Duration::from_millis(400));
            // 在 UI 线程的事件循环里执行：weak 升级 + 改属性
            let weak = weak.clone();
            let _ = slint::invoke_from_event_loop(move || {
                if let Some(app) = weak.upgrade() {
                    let t = app.get_ticks();
                    app.set_ticks(t + 1);
                }
            });
        }
    });

    app.run()
}

/// 无头自检：组件独立性（A=2、B=10 互不干扰）、step 配置生效、
/// 回调转发链路。事件循环专属部分（invoke_from_event_loop）见坑位。
fn selftest_body() -> (i32, i32, Vec<&'static str>) {
    i_slint_backend_testing::init_no_event_loop();
    let app = CompLab::new().expect("testing backend 下创建组件失败");

    let log = std::rc::Rc::new(std::cell::RefCell::new(Vec::<&'static str>::new()));
    {
        let log = log.clone();
        app.on_bump_a(move || log.borrow_mut().push("a+"));
    }
    {
        let log = log.clone();
        app.on_bump_b(move || log.borrow_mut().push("b+"));
    }

    use i_slint_backend_testing::ElementRoot;
    // 找两个 LabeledCounter 实例（按类型名）
    let counters = app
        .root_element()
        .query_descendants()
        .match_type_name(String::from("LabeledCounter"))
        .find_all();
    assert_eq!(counters.len(), 2, "应有两个 LabeledCounter 实例");

    // 点每个实例里的 "+" 按钮：按类型名查 Button，几何推导分实例点击
    let buttons = app
        .root_element()
        .query_descendants()
        .match_type_name(String::from("Button"))
        .find_all();
    // 每个计数器两个按钮（+/清零）→ 共 4 个；DFS 序（A+ A清零 B+ B清零）
    assert_eq!(buttons.len(), 4, "应有 4 个按钮（每实例 +/清零）");
    let click = |b: &i_slint_backend_testing::ElementHandle| {
        let p = b.absolute_position();
        let adapter = i_slint_core::window::WindowInner::from_pub(app.window()).window_adapter();
        i_slint_backend_testing::testing_backend::send_mouse_click(p.x + 5.0, p.y + 5.0, &adapter);
    };
    click(&buttons[0]); // A 的 +
    click(&buttons[0]); // A 再 +
    click(&buttons[2]); // B 的 +（step=10）

    let va = app.get_value_a(); // 根级镜像读嵌套值
    let vb = app.get_value_b();
    assert_eq!(va, 2, "A 两次 +1 应为 2");
    assert_eq!(vb, 10, "B 一次 +10 应为 10——两个实例状态独立");

    let log_snapshot = log.borrow().clone();
    drop(app);
    (va, vb, log_snapshot)
}

fn run_selftest() {
    println!("==== 21 slint 组件与集成 开始 ====");
    let (a, b, log) = selftest_body();
    println!("value-a={a} value-b={b}（同组件不同配置，状态独立）");
    println!("callback log = {:?}", log);
    assert_eq!(log, vec!["a+", "a+", "b+"], "A 两次 + B 一次");
    println!("==== 21 slint 组件与集成 结束 ====");
}

#[cfg(test)]
mod tests {
    #[test]
    fn counters_independent_and_transitive() {
        let (a, b, log) = super::selftest_body();
        assert_eq!((a, b), (2, 10));
        assert_eq!(log, vec!["a+", "a+", "b+"]);
    }
}
