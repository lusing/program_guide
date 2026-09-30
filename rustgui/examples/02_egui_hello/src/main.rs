// ============================================================
// 02_egui_hello —— eframe 骨架：即时模式最小应用
//
// 读法：
//   1. App trait 的 ui() 方法（0.34 起取代旧 update(ctx, frame) 签名）
//      每帧被调用一次，里面"重新声明"整个界面——这就是即时模式。
//   2. ui.button(...).clicked() 返回值即事件：没有回调、没有监听器。
//   3. run_selftest() 用 egui_kittest 在无窗口环境下驱动同一套 UI，
//      cargo test 与 cargo run -- --selftest 走的是同一条通道。
//
// 【坑】0.34/0.35 大重构：SidePanel/TopBottomPanel/Context::run/
//      run_simple_native 等旧 API 在 0.36 已物理删除，旧教程代码
//      直接编译失败。本章起全部按 0.36 新 API 写。
//
// 官方参考：https://docs.rs/egui/latest/egui/
// 本地源码：G:\github\rust\egui（与 crates.io 0.36.2 完全一致）
// ============================================================

/// 应用状态。即时模式里它是"唯一活着的"东西——界面每帧重建，
/// 状态却跨帧存活：这是理解 egui 的第一把钥匙。
struct CounterApp {
    count: i64,
}

impl CounterApp {
    fn new() -> Self {
        Self { count: 0 }
    }

    /// 界面主体抽成关联函数：run_native（真窗口）与 kittest（无头测试）
    /// 两个入口喂进来的 Ui 调用的是同一份代码——测试与生产永不漂移。
    fn ui_body(ui: &mut egui::Ui, count: &mut i64) {
        ui.heading("Hello egui!");
        ui.label(format!("count: {count}"));
        if ui.button("Increment").clicked() {
            *count += 1;
        }
    }
}

impl eframe::App for CounterApp {
    /// 0.36 的 App trait：fn ui(&mut self, ui: &mut egui::Ui, frame)。
    /// 根 Ui 没有边距和背景，惯例是自己包一层 CentralPanel。
    fn ui(&mut self, ui: &mut egui::Ui, _frame: &mut eframe::Frame) {
        egui::CentralPanel::default().show(ui, |ui| Self::ui_body(ui, &mut self.count));
    }
}

fn main() -> eframe::Result {
    let selftest = std::env::args().nth(1).is_some_and(|a| a == "--selftest");
    if selftest {
        run_selftest();
        return Ok(());
    }

    let options = eframe::NativeOptions {
        viewport: egui::ViewportBuilder::default().with_inner_size([320.0, 200.0]),
        ..Default::default()
    };
    eframe::run_native(
        "02_egui_hello",
        options,
        Box::new(|_cc| Ok(Box::new(CounterApp::new()))),
    )
}

/// 无头自检：kittest Harness 驱动完整 eframe::App，
/// 点击按钮三次后核对状态。cargo test 调用同一函数。
fn selftest_body() -> i64 {
    use egui_kittest::kittest::Queryable; // get_by_label 等 Queryable 方法需显式引入

    let mut harness = egui_kittest::Harness::builder().build_eframe(|_cc| CounterApp::new());

    let button = harness.get_by_label("Increment");
    button.click();
    button.click();
    button.click();
    harness.run(); // 处理排队的事件直到界面稳定

    harness.state().count // state 就是 CounterApp 本身
}

fn run_selftest() {
    println!("==== 02 egui 最小应用 开始 ====");
    let count = selftest_body();
    println!("count after 3 clicks = {count}");
    assert_eq!(count, 3, "点击三次 Increment 后计数应为 3");
    println!("==== 02 egui 最小应用 结束 ====");
}

#[cfg(test)]
mod tests {
    #[test]
    fn three_clicks_count_to_three() {
        assert_eq!(super::selftest_body(), 3);
    }
}
