// ============================================================
// 03_egui_widgets —— 控件全集、返回值即事件、菜单/弹窗/浮动窗口
//
// 读法：
//   1. 即时模式的事件形态：ui.button(..).clicked() / ui.checkbox(..)
//      / ui.add(Slider..) 的返回值 Response——没有回调注册这回事。
//   2. ID 机制：同名控件在同一父 Ui 里会撞 Id（状态互相污染），
//      ui.push_id 手工分区是标准解法。
//   3. 菜单栏 MenuBar + Popup::menu + 浮动 Window——即时模式下
//      这些"有状态"的控件全靠 Id 跨帧记状态。
//
// 【坑】02-06 章 UI 文本保持 ASCII：egui 0.36 内置字体无 CJK，
//      缺字形只画替换符（豆腐块），无头测试与真窗口都不报错
//      （07 章注册中文字体后放开）。
//
// 官方参考：https://docs.rs/egui/latest/egui/
// ============================================================

/// 本章演示的城市列表（ComboBox 选项）
const CITIES: [&str; 3] = ["Beijing", "Shanghai", "Shenzhen"];

#[derive(Clone, Default)]
struct WidgetsApp {
    count: i64,     // 按钮 + DragValue
    sauce: bool,    // 复选框
    variant: usize, // 单选（0=Alpha 1=Beta 2=Gamma）
    volume: f32,    // 滑块（0.0..=100.0）
    name_a: String, // 两个同名输入框：靠 push_id 区分
    name_b: String,
    city: usize,       // 下拉框
    window_open: bool, // 浮动窗口开关
    last_menu: String, // 最近一次菜单动作（供无头断言）
}

impl WidgetsApp {
    fn new() -> Self {
        Self {
            volume: 40.0,
            ..Default::default()
        }
    }

    /// 界面主体：真窗口与无头测试共用
    fn ui_body(ui: &mut egui::Ui, app: &mut WidgetsApp) {
        // ---- 菜单栏（0.36 新 API：egui::MenuBar + ui.menu_button）----
        egui::MenuBar::new().ui(ui, |ui| {
            ui.menu_button("Actions", |ui| {
                if ui.button("Reset all").clicked() {
                    *app = WidgetsApp::new();
                    app.last_menu = "reset".into();
                    ui.close(); // 点击菜单项后收起整个菜单树（0.32+ 新 API）
                }
                if ui.button("Open window").clicked() {
                    app.window_open = true;
                    app.last_menu = "open".into();
                    ui.close();
                }
            });
        });

        egui::CentralPanel::default().show(ui, |ui| {
            ui.heading("Widgets Gallery");

            // ---- 按钮与标签：返回值即事件 ----
            ui.horizontal(|ui| {
                if ui.button("Increment").clicked() {
                    app.count += 1;
                }
                ui.label(format!("count = {}", app.count));
                // DragValue：可拖拽/输入的数值微调器
                ui.add(egui::DragValue::new(&mut app.count).range(0..=99));
            });

            // ---- 复选框 / 单选 ----
            ui.checkbox(&mut app.sauce, "Enable extra sauce");
            ui.horizontal(|ui| {
                for (i, name) in ["Alpha", "Beta", "Gamma"].into_iter().enumerate() {
                    ui.radio_value(&mut app.variant, i, name);
                }
            });

            // ---- 滑块：f32 字面量直接给区间 ----
            ui.add(
                egui::Slider::new(&mut app.volume, 0.0..=100.0)
                    .text("volume")
                    .fixed_decimals(0),
            );

            // ---- 文本输入 × 2：ID 冲突的正解 ----
            // 两个 TextInput 在同一父 Ui 里自动 Id 相同（同一个 "name"），
            // 光标/焦点/IME 状态会互相污染。push_id 显式分区：
            ui.horizontal(|ui| {
                ui.push_id("name-a", |ui| {
                    ui.text_edit_singleline(&mut app.name_a);
                });
                ui.push_id("name-b", |ui| {
                    ui.text_edit_singleline(&mut app.name_b);
                });
            });

            // ---- 下拉框 ----
            egui::ComboBox::from_label("City")
                .selected_text(CITIES[app.city])
                .show_ui(ui, |ui| {
                    for (i, c) in CITIES.iter().enumerate() {
                        ui.selectable_value(&mut app.city, i, *c);
                    }
                });

            // ---- 进度条：滑块值直接驱动 ----
            ui.add(
                egui::ProgressBar::new(app.volume / 100.0)
                    .show_percentage()
                    .text("progress"),
            );

            // ---- 浮动窗口开关 ----
            ui.checkbox(&mut app.window_open, "Floating window");
        });

        // ---- 浮动窗口：show 挂在 Context 上（跨面板的覆盖层） ----
        // 注意与 02 章 CentralPanel::show(ui, ..) 的对比：Window 是
        // Area 系（浮在所有面板之上），第一参数是 &Context。
        egui::Window::new("Floating")
            .open(&mut app.window_open)
            .resizable(false)
            .show(ui.ctx(), |ui| {
                ui.label("I am a floating window");
            });
    }
}

impl eframe::App for WidgetsApp {
    fn ui(&mut self, ui: &mut egui::Ui, _frame: &mut eframe::Frame) {
        Self::ui_body(ui, self);
    }
}

fn main() -> eframe::Result {
    let selftest = std::env::args().nth(1).is_some_and(|a| a == "--selftest");
    if selftest {
        run_selftest();
        return Ok(());
    }

    let options = eframe::NativeOptions {
        viewport: egui::ViewportBuilder::default().with_inner_size([420.0, 520.0]),
        ..Default::default()
    };
    eframe::run_native(
        "03_egui_widgets",
        options,
        Box::new(|_cc| Ok(Box::new(WidgetsApp::new()))),
    )
}

/// 无头自检：把每种控件都真实操作一遍，终值即证据。
fn selftest_body() -> WidgetsApp {
    use egui_kittest::kittest::{NodeT, Queryable};

    let mut harness = egui_kittest::Harness::builder().build_eframe(|_cc| WidgetsApp::new());

    // 按钮 ×2
    let inc = harness.get_by_label("Increment");
    inc.click();
    inc.click();
    harness.run();

    // 复选框：读 AccessKit 的 toggled 状态
    let cb = harness.get_by_label("Enable extra sauce");
    assert_eq!(
        cb.accesskit_node().toggled(),
        Some(egui::accesskit::Toggled::False)
    );
    cb.click();
    harness.run();

    // 单选 Beta
    harness.get_by_label("Beta").click();
    harness.run();

    // 两个输入框都是 TextInput 角色：get_* 要求唯一匹配，多节点用 get_all_。
    // type_text 只把 Event::Text 发给【当前焦点】控件——必须先 focus 再输入，
    // 且 run() 之后无障碍树会刷新，节点要重新查询（直接复用旧节点是常见坑）。
    harness
        .get_all_by_role(egui::accesskit::Role::TextInput)
        .next()
        .expect("至少应有第一个输入框")
        .focus();
    harness.run();
    harness
        .get_all_by_role(egui::accesskit::Role::TextInput)
        .next()
        .expect("focus 之后再查第一个输入框")
        .type_text("Ada");
    harness.run();

    // 第二个输入框：push_id 分区后是独立节点，同样的 focus → run → type 节奏
    harness
        .get_all_by_role(egui::accesskit::Role::TextInput)
        .nth(1)
        .expect("push_id 分区后应有第二个独立输入框")
        .focus();
    harness.run();
    harness
        .get_all_by_role(egui::accesskit::Role::TextInput)
        .nth(1)
        .expect("focus 之后再查第二个输入框")
        .type_text("Lin");
    harness.run();

    // 下拉框：点开菜单再点选项（弹出层也在无障碍树里）
    harness.get_by_label("City").click();
    harness.run();
    harness.get_by_label("Shenzhen").click();
    harness.run();

    // 菜单：Actions -> Open window
    harness.get_by_label("Actions").click();
    harness.run();
    harness.get_by_label("Open window").click();
    harness.run();

    // 浮动窗口已出现（query_by_label 返回 Option，找不到不 panic）
    assert!(harness.query_by_label("I am a floating window").is_some());

    harness.state().clone()
}

fn run_selftest() {
    println!("==== 03 egui 控件全集 开始 ====");
    let app = selftest_body();
    println!(
        "count={} sauce={} variant={} volume={:.0} city={}",
        app.count, app.sauce, app.variant, app.volume, app.city
    );
    println!("name_a={} name_b={}", app.name_a, app.name_b);
    println!(
        "window_open={} last_menu={}",
        app.window_open, app.last_menu
    );
    assert_eq!(app.count, 2, "Increment 点击两次");
    assert!(app.sauce, "复选框应已勾选");
    assert_eq!(app.variant, 1, "单选应停在 Beta");
    assert_eq!(app.city, 2, "下拉框应选中 Shenzhen");
    assert_eq!(app.name_a, "Ada");
    assert_eq!(app.name_b, "Lin");
    assert!(app.window_open, "菜单应已打开浮动窗口");
    assert_eq!(app.last_menu, "open");
    println!("==== 03 egui 控件全集 结束 ====");
}

#[cfg(test)]
mod tests {
    #[test]
    fn widget_tour_ends_in_expected_state() {
        let app = super::selftest_body();
        assert_eq!((app.count, app.variant, app.city), (2, 1, 2));
        assert!(app.sauce && app.window_open);
    }
}
