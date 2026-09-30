// ============================================================
// 25_gtk_widgets_signals —— GTK 控件全集、信号三范式与 Builder XML
//
// 读法：
//   1. 控件全集：Entry / DropDown / CheckButton / Switch /
//      Scale / SpinButton / ProgressBar——一张报名表单
//      （与 11 章 iced 报名表单同题对照）。
//   2. 信号三范式：connect_*（动作信号）、connect_*_notify
//      （属性变更，程序驱动靠它——GObject 保证 set 后必发）、
//      bind_property（声明式绑定，带 transform_to 换算）。
//   3. Builder XML（ui/form.ui）：界面即数据，include_str! 进
//      二进制，builder.object::<T>("id") 取句柄。
//   4. Scale 与 SpinButton 共享同一个 Adjustment——状态在模型、
//      视图只是投影（28 章 GListModel 的前奏）。
//   5. 无头测试同 24 章：直连 set_/emit_ 驱动 + 属性断言。
//
// 【坑】set_active 不发 toggled 信号（只保证发 notify::active）：
//      用户点击走 toggled、程序赋值走 notify——处理器写成幂等的
//      绝对赋值，两条路都稳。
//
// 官方参考：https://gtk-rs.org/gtk4-rs/git/book/widgets.html
// ============================================================

use gtk::{glib, prelude::*};

/// 报名表单：真窗口与无头测试共用（Builder 加载 + 同一套 wire）。
#[derive(Clone)]
struct Form {
    entry: gtk::Entry,
    dropdown: gtk::DropDown,
    check: gtk::CheckButton,
    dark_switch: gtk::Switch,
    adj: gtk::Adjustment,
    scale: gtk::Scale,
    spin: gtk::SpinButton,
    bar: gtk::ProgressBar,
    summary: gtk::Label,
    submit: gtk::Button,
}

impl Form {
    /// Builder XML → 句柄集合（一次加载，连同窗口一起交出——别加载两遍
    /// XML，那会实例化两个窗口）。object::<T>("id") 类型不符返回 None
    /// （不 panic），漏检 unwrap 就静默错——一律 expect 带名字。
    fn load() -> (Self, gtk::ApplicationWindow) {
        let b = gtk::Builder::from_string(include_str!("../ui/form.ui"));
        let get = |id: &str| -> glib::Object {
            b.object::<glib::Object>(id)
                .unwrap_or_else(|| panic!("XML 里没有 id={id}"))
        };
        let form = Self {
            entry: get("name-entry").downcast().unwrap(),
            dropdown: get("city-dropdown").downcast().unwrap(),
            check: get("subscribe-check").downcast().unwrap(),
            dark_switch: get("dark-switch").downcast().unwrap(),
            adj: gtk::Adjustment::new(0.0, 0.0, 100.0, 1.0, 10.0, 0.0),
            scale: get("count-scale").downcast().unwrap(),
            spin: get("count-spin").downcast().unwrap(),
            bar: get("progress-bar").downcast().unwrap(),
            summary: get("summary-label").downcast().unwrap(),
            submit: get("submit-button").downcast().unwrap(),
        };
        let win: gtk::ApplicationWindow = b.object("window").expect("window 在 XML 里");
        (form, win)
    }

    /// 信号接线：真窗口与无头测试共用。
    fn wire(&self) {
        let cities = gtk::StringList::new(&["北京", "上海", "深圳"]);
        self.dropdown.set_model(Some(&cities));

        // 状态在模型：Scale 与 SpinButton 共享同一个 Adjustment，
        // 任意一边动，另一边与进度条同步。
        self.scale.set_adjustment(&self.adj);
        self.spin.set_adjustment(&self.adj);

        // 声明式绑定：adjustment.value(0..100) → progress.fraction(0..1)。
        // transform_to 负责换算；sync_create 让初始值立即同步一次。
        self.adj
            .bind_property("value", &self.bar, "fraction")
            .transform_to(|_, v: &glib::Value| Some((v.get::<f64>().unwrap() / 100.0).to_value()))
            .sync_create()
            .build();

        // 处理器一律幂等（绝对赋值）：用户点击走 toggled、程序赋值走
        // notify，两路触发都收敛到同一状态。
        let f = self.clone();
        self.check.connect_toggled(move |_| f.refresh());
        let f = self.clone();
        self.check.connect_active_notify(move |_| f.refresh());
        let f = self.clone();
        self.dark_switch.connect_active_notify(move |_| f.refresh());
        let f = self.clone();
        self.dropdown.connect_selected_notify(move |_| f.refresh());
        let f = self.clone();
        self.adj.connect_value_changed(move |_| f.refresh());

        let f = self.clone();
        self.entry.connect_activate(move |_| f.refresh());
        let f = self.clone();
        self.submit.connect_clicked(move |_| f.refresh());
    }

    /// 真相直读：所有控件状态拼一行（断言与显示共用）。
    fn state_text(&self) -> String {
        let city = self
            .dropdown
            .selected_item()
            .and_then(|o| o.downcast::<gtk::StringObject>().ok())
            .map(|s| s.string().to_string())
            .unwrap_or_default();
        format!(
            "姓名：{} ｜ 城市：{} ｜ 订阅：{} ｜ 深色：{} ｜ 人数：{}",
            self.entry.text(),
            city,
            if self.check.is_active() { "是" } else { "否" },
            if self.dark_switch.is_active() {
                "开"
            } else {
                "关"
            },
            self.spin.value() as i32,
        )
    }

    fn refresh(&self) {
        self.summary.set_text(&self.state_text());
    }
}

fn main() -> glib::ExitCode {
    if std::env::args().nth(1).is_some_and(|a| a == "--selftest") {
        run_selftest();
        return glib::ExitCode::from(0);
    }

    let app = gtk::Application::builder()
        .application_id("org.rustgui.GtkWidgets")
        .build();
    app.connect_activate(|app| {
        let (form, win) = Form::load();
        form.wire();
        app.add_window(&win);
        win.present();
    });
    app.run()
}

/// 无头自检：填表（程序赋值）→ 排空 → 断言汇总；再走一遍
/// emit_clicked/emit_activate 的"用户路径"验证幂等收敛。
fn selftest_body() -> String {
    gtk::init().expect("gtk::init 失败（需要交互桌面会话）");

    let (f, _win) = Form::load(); // 窗口不 present——无头腿只动控件
    f.wire();

    // 程序赋值路径：set_* + notify（GObject 保证属性变更必发 notify）
    f.entry.set_text("李雷");
    f.entry.emit_activate();
    f.dropdown.set_selected(1);
    f.check.set_active(true);
    f.dark_switch.set_active(true);
    f.adj.set_value(55.0);

    let ctx = glib::MainContext::default();
    while ctx.pending() {
        ctx.iteration(false);
    }

    let expected = "姓名：李雷 ｜ 城市：上海 ｜ 订阅：是 ｜ 深色：开 ｜ 人数：55";
    assert_eq!(f.state_text(), expected);
    assert_eq!(
        f.summary.text().to_string(),
        expected,
        "notify 处理器应把汇总刷新到位"
    );
    assert_eq!(
        f.bar.fraction(),
        0.55,
        "bind_property + transform_to 换算 55/100"
    );
    assert_eq!(f.spin.value(), 55.0, "共享 Adjustment：驱动模型两边同步");

    // 用户路径：按钮再点一次 → 幂等（状态不变）
    f.submit.emit_clicked();
    while ctx.pending() {
        ctx.iteration(false);
    }
    assert_eq!(
        f.summary.text().to_string(),
        expected,
        "处理器幂等：重复触发收敛同一状态"
    );

    expected.to_string()
}

fn run_selftest() {
    println!("==== 25 gtk 控件与信号 开始 ====");
    let summary = selftest_body();
    println!("summary=\"{summary}\"");
    println!("==== 25 gtk 控件与信号 结束 ====");
}

#[cfg(test)]
mod tests {
    #[gtk::test]
    fn programmatic_and_user_paths_agree() {
        let s = super::selftest_body();
        assert_eq!(
            s,
            "姓名：李雷 ｜ 城市：上海 ｜ 订阅：是 ｜ 深色：开 ｜ 人数：55"
        );
    }
}
