// ============================================================
// 29_gtk_custom_async —— CompositeTemplate 子类化 + gio 异步腿
//
// 读法：
//   1. GObject 子类化完整仪式：mod imp（#[glib::object_subclass] +
//      class_init/instance_init）+ glib::wrapper!——GTK 一切自定义
//      控件的底座（对照 08 章 egui impl Widget 的五步）。
//   2. CompositeTemplate：#[derive(Default, gtk::CompositeTemplate)]
//      + #[template(file = "ui/task_card.ui")]（编译期读文件）+
//      #[template_child] 把 XML 里的 id 变成 Rust 字段——
//      init_template 在构造时就跑，无头测试不需要窗口 realize。
//   3. 异步腿（官方书 main_event_loop 章同款）：gio::spawn_blocking
//      干重活 + async-channel 跨线程 + glib::spawn_future_local 在
//      UI 线程收——对照 09 章 mpsc+request_repaint、14 章 iced
//      Subscription、21 章 slint invoke_from_event_loop。
//
// 【坑】glib 0.22 没有 MainContext::channel——通道用 async-channel
//      crate（worker 侧 send_blocking，UI 侧 recv().await）。
//
// 官方参考：https://gtk-rs.org/gtk4-rs/git/book/composite_templates.html
//           https://gtk-rs.org/gtk4-rs/git/book/main_event_loop.html
// ============================================================

use gtk::{glib, prelude::*, subclass::prelude::*};
use std::cell::Cell;
use std::rc::Rc;
use std::time::Duration;

// ------------------------------------------------------------
// TaskCard：模板复合控件（标题 + 状态 + 进度条）
// ------------------------------------------------------------
mod imp {
    use gtk::{glib, subclass::prelude::*};

    /// 私有结构：#[template_child] 字段的 id 必须与 XML 一致。
    /// file 路径相对**本源文件**（src/）——注意不是 Cargo.toml 目录。
    #[derive(Default, gtk::CompositeTemplate)]
    #[template(file = "../ui/task_card.ui")] // 编译期读入（≈ include_str!）
    pub struct TaskCard {
        #[template_child]
        pub title: gtk::TemplateChild<gtk::Label>,
        #[template_child]
        pub status: gtk::TemplateChild<gtk::Label>,
        #[template_child]
        pub progress: gtk::TemplateChild<gtk::ProgressBar>,
    }

    #[glib::object_subclass]
    impl ObjectSubclass for TaskCard {
        const NAME: &'static str = "RustGuiTaskCard"; // = XML 里 template class
        type Type = super::TaskCard;
        type ParentType = gtk::Box;

        fn class_init(klass: &mut Self::Class) {
            klass.bind_template(); // 模板 + 全部 child 一次绑好
        }
        fn instance_init(obj: &glib::subclass::InitializingObject<Self>) {
            obj.init_template(); // 实例构造时实例化模板（忘写 = 运行时 panic）
        }
    }

    impl ObjectImpl for TaskCard {}
    impl WidgetImpl for TaskCard {}
    impl BoxImpl for TaskCard {}
}

glib::wrapper! {
    pub struct TaskCard(ObjectSubclass<imp::TaskCard>)
        @extends gtk::Box, gtk::Widget,
        @implements gtk::Buildable, gtk::ConstraintTarget, gtk::Orientable;
}

impl TaskCard {
    fn new() -> Self {
        glib::Object::new()
    }

    fn title(&self) -> String {
        self.imp().title.text().to_string()
    }

    fn set_status(&self, s: &str) {
        self.imp().status.set_text(s);
    }

    fn status(&self) -> String {
        self.imp().status.text().to_string()
    }

    fn set_progress(&self, f: f64) {
        self.imp().progress.set_fraction(f);
    }

    fn fraction(&self) -> f64 {
        self.imp().progress.fraction()
    }
}

// ------------------------------------------------------------
// 异步腿：spawn_blocking 干活 → channel → spawn_future_local 收
// ------------------------------------------------------------
/// 启动后台任务（4 块），返回"已收块数"观察哨（selftest 断言用）。
fn run_task(card: &TaskCard) -> Rc<Cell<u32>> {
    let (tx, rx) = async_channel::bounded::<u32>(4);
    gtk::gio::spawn_blocking(move || {
        for i in 1..=4u32 {
            let _ = tx.send_blocking(i); // worker 线程的阻塞发（UI 侧才 await）
        }
    }); // JoinHandle<T>：不 .await 就是"发射后不管"（UI 侧靠通道收）

    let card = card.clone();
    let received = Rc::new(Cell::new(0u32));
    let got = received.clone();
    glib::spawn_future_local(async move {
        while let Ok(i) = rx.recv().await {
            // 通道关闭（worker 结束）→ Err → 收尾
            got.set(i);
            card.set_progress(i as f64 / 4.0);
            card.set_status(&format!("块 {i}/4"));
        }
        card.set_progress(1.0);
        card.set_status("完成");
    });
    received
}

/// 条件排空：轮询主循环 + 给外部线程一点推进时间（上限约 3s）。
fn pump_until(pred: impl Fn() -> bool) {
    let ctx = glib::MainContext::default();
    for _ in 0..600 {
        while ctx.pending() {
            ctx.iteration(false);
        }
        if pred() {
            return;
        }
        std::thread::sleep(Duration::from_millis(5)); // 等 worker 线程推进
    }
}

fn main() -> glib::ExitCode {
    if std::env::args().nth(1).is_some_and(|a| a == "--selftest") {
        run_selftest();
        return glib::ExitCode::from(0);
    }

    let app = gtk::Application::builder()
        .application_id("org.rustgui.GtkCustomAsync")
        .build();
    app.connect_activate(|app| {
        let card = TaskCard::new();
        let start = gtk::Button::with_label("开始任务");
        {
            let card = card.clone();
            start.connect_clicked(move |_| {
                run_task(&card);
            });
        }

        let vbox = gtk::Box::new(gtk::Orientation::Vertical, 12);
        vbox.set_margin_top(14);
        vbox.set_margin_bottom(14);
        vbox.set_margin_start(14);
        vbox.set_margin_end(14);
        vbox.append(&card);
        vbox.append(&start);

        let win = gtk::ApplicationWindow::new(app);
        win.set_title(Some("29 gtk custom async"));
        win.set_default_size(340, 200);
        win.set_child(Some(&vbox));
        win.present();
    });
    app.run()
}

/// 无头自检：
///   a) 模板控件：构造即 init_template（不需要窗口 realize），
///      template_child 直读直写；
///   b) 异步腿：spawn_blocking → channel → future_local，
///      条件排空到终态，断言块数/进度/状态文字。
fn selftest_body() -> String {
    gtk::init().expect("gtk::init 失败（需要交互桌面会话）");

    // a) 模板控件（零窗口）
    let card = TaskCard::new();
    assert_eq!(card.title(), "任务卡", "XML 里的 title_label");
    assert_eq!(card.status(), "待启动", "XML 里的 status_label 初值");
    assert_eq!(card.fraction(), 0.0);
    card.set_status("预热");
    assert_eq!(card.status(), "预热", "template_child 直写生效");

    // b) 异步腿
    card.set_status("待启动"); // 复位
    let received = run_task(&card);
    pump_until(|| received.get() == 4 && card.status() == "完成");

    assert_eq!(received.get(), 4, "四块数据全收到");
    assert_eq!(card.fraction(), 1.0);
    assert_eq!(card.status(), "完成");

    // status 已断言为"完成"，写进证据行保持与 selftest 输出对账稳定
    format!("title={} chunks=4 fraction=1.00 status=完成", card.title())
}

fn run_selftest() {
    println!("==== 29 gtk 模板与异步 开始 ====");
    let evidence = selftest_body();
    println!("{evidence}");
    println!("==== 29 gtk 模板与异步 结束 ====");
}

#[cfg(test)]
mod tests {
    #[gtk::test]
    fn template_children_and_async_pipeline() {
        let s = super::selftest_body();
        assert_eq!(s, "title=任务卡 chunks=4 fraction=1.00 status=完成");
    }
}
