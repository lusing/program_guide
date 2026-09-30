// ============================================================
// 24_gtk_hello —— GTK4 最小应用：retained 模式与直连测试通道
//
// 读法：
//   1. GTK 是 retained 模式：控件是持久对象，Rust 侧直接持有句柄。
//      与前三种范式最大的不同——测试不需要"查询 UI 树"，手里
//      本来就攥着 Button/Label 本尊。
//   2. 真窗口走 Application/activate/run（官方 basics 例程同款）。
//   3. 无头测试 = 官方 #[gtk::test]：独占单线程池 + 自动 gtk::init，
//      所有测试串行；emit_clicked 直连驱动、属性直断言，零渲染。
//      main --selftest 通道里则显式 gtk::init()（同线程幂等）。
//   4. GTK 经 Pango 自带系统字体回退——中文直接可写（对照 egui
//      07 章的手动注册，这是 gtk 的"免费午餐"）。
//
// 【坑】gtk::init() 从第二个不同线程调用会 panic（测试构建下报
//      "Use #[gtk::test] instead of #[test]"）——一个示例只留一个
//      测试函数，用 #[gtk::test] 包。
//
// 官方参考：https://gtk-rs.org/gtk4-rs/git/book/
// ============================================================

use gtk::{glib, prelude::*};
use std::cell::Cell;
use std::rc::Rc;

/// 计数器：真窗口与无头测试共用同一份控件构造（同一张考卷）。
struct Counter {
    count: Rc<Cell<i32>>,
    label: gtk::Label,
    button: gtk::Button,
}

impl Counter {
    fn new() -> Self {
        let count = Rc::new(Cell::new(0));
        let label = gtk::Label::new(Some("count: 0"));
        let button = gtk::Button::with_label("Increment");
        {
            let count = count.clone();
            let label = label.clone();
            button.connect_clicked(move |_| {
                count.set(count.get() + 1);
                label.set_text(&format!("count: {}", count.get()));
            });
        }
        Self {
            count,
            label,
            button,
        }
    }

    fn value(&self) -> i32 {
        self.count.get()
    }

    fn text(&self) -> String {
        self.label.text().to_string()
    }
}

fn main() -> glib::ExitCode {
    if std::env::args().nth(1).is_some_and(|a| a == "--selftest") {
        run_selftest();
        return glib::ExitCode::from(0);
    }

    let app = gtk::Application::builder()
        .application_id("org.rustgui.GtkHello")
        .build();
    app.connect_activate(build_ui);
    app.run()
}

fn build_ui(app: &gtk::Application) {
    let counter = Counter::new();
    let caption = gtk::Label::new(Some("GTK 自带系统字体回退：中文直接可写"));

    let vbox = gtk::Box::new(gtk::Orientation::Vertical, 12);
    vbox.set_margin_top(16);
    vbox.set_margin_bottom(16);
    vbox.set_margin_start(16);
    vbox.set_margin_end(16);
    vbox.append(&counter.label);
    vbox.append(&counter.button);
    vbox.append(&caption);

    let win = gtk::ApplicationWindow::new(app);
    win.set_title(Some("24 gtk hello"));
    win.set_default_size(380, 160);
    win.set_child(Some(&vbox));
    win.present();
}

/// 无头自检：构造计数器 → emit_clicked 直连驱动三次 → 排空主循环
/// → 从控件属性读回断言。不建窗口、不进 run()、零渲染。
fn selftest_body() -> (i32, String) {
    gtk::init().expect("gtk::init 失败（桌面会话才可用；服务会话不行）");

    let c = Counter::new();
    assert_eq!(c.text(), "count: 0");

    c.button.emit_clicked();
    c.button.emit_clicked();
    c.button.emit_clicked();

    // 直连信号是同步派发的；排空主循环兜底处理挂起的 idle/回调
    // （确定性：本例没有定时器，排空后即静止）。
    let ctx = glib::MainContext::default();
    while ctx.pending() {
        ctx.iteration(false);
    }

    (c.value(), c.text())
}

fn run_selftest() {
    println!("==== 24 gtk 最小应用 开始 ====");
    let (clicks, text) = selftest_body();
    assert_eq!((clicks, text.as_str()), (3, "count: 3"));
    println!("clicks={clicks} label=\"{text}\"");
    println!("==== 24 gtk 最小应用 结束 ====");
}

#[cfg(test)]
mod tests {
    #[gtk::test]
    fn three_clicks_count_to_three() {
        let (clicks, text) = super::selftest_body();
        assert_eq!((clicks, text.as_str()), (3, "count: 3"));
    }
}
