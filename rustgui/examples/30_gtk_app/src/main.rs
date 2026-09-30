// ============================================================
// 30_gtk_app —— GTK 综合实战：待办管理器（第四份同规格实现）
//
// 与 09（egui）/16（iced）/23（Slint）同一张考卷，六条规格：
//   列表显示 / 文本输入添加 / 勾选完成 / 删除条目 /
//   综合组件（滚动列表）/ 特色亮点。
//
// GTK 的答卷特色：
//   1. TodoItem 是自定义 GObject（#[derive(Properties)]——29 章
//      子类化的进阶：属性由宏生成 get/set/notify）；
//   2. 模型 = gio::ListStore<TodoItem> + ListBox::bind_model 造行，
//      行样式随 item 的 notify::done 自动刷新；
//   3. 亮点 A：CSS 完成态——.done 类划线 + 半透明（26 章的地基），
//      apply_done_style 纯函数化，无头断言类开关；
//   4. 亮点 B：Gio SimpleAction 清空动作 + <Ctrl>D 快捷键——
//      action.activate() 无头可直测（app 级注册在真窗口腿）；
//   5. 持久化：serde_json 落 temp 目录（对齐 16/23 的 saved=N bytes）。
//
// 【坑】GSettings 在 Windows 是 memory 后端不落盘——持久化别指望
//      它，JSON 自己写（book 第 7/8 章的方案在 Windows 是空中楼阁）。
//
// 官方参考：https://gtk-rs.org/gtk4-rs/git/book/todo_1.html
//           https://gtk-rs.org/gtk4-rs/git/book/actions.html
// ============================================================

use gtk::{glib, prelude::*};
use serde::{Deserialize, Serialize};
use std::rc::Rc;

const CSS: &str = "
.done { text-decoration: line-through; opacity: 0.55; }
";

fn save_path() -> std::path::PathBuf {
    std::env::temp_dir().join("30_gtk_todo.json")
}

// ------------------------------------------------------------
// TodoItem：自定义 GObject，属性由宏生成
// ------------------------------------------------------------
mod imp {
    use gtk::glib::{self, Properties};
    use gtk::prelude::*;
    use gtk::subclass::prelude::*;
    use std::cell::RefCell;

    #[derive(Properties, Default)]
    #[properties(wrapper_type = super::TodoItem)]
    pub struct TodoItem {
        #[property(name = "text", get, set)]
        pub text: RefCell<String>,
        #[property(name = "done", get, set)]
        pub done: RefCell<bool>,
    }

    #[glib::object_subclass]
    impl ObjectSubclass for TodoItem {
        const NAME: &'static str = "RustGuiTodoItem";
        type Type = super::TodoItem;
    }

    #[glib::derived_properties]
    impl ObjectImpl for TodoItem {}
}

glib::wrapper! {
    pub struct TodoItem(ObjectSubclass<imp::TodoItem>);
}

impl TodoItem {
    fn new(text: &str, done: bool) -> Self {
        glib::Object::builder()
            .property("text", text)
            .property("done", done)
            .build()
    }
}

// ------------------------------------------------------------
// 持久化：平行 serde 结构（GObject 不 derive serde——对齐 23 章）
// ------------------------------------------------------------
#[derive(Serialize, Deserialize, Default)]
struct Snapshot {
    items: Vec<ItemSnap>,
}

#[derive(Serialize, Deserialize)]
struct ItemSnap {
    text: String,
    done: bool,
}

// ------------------------------------------------------------
// 样式：完成态划线（纯函数，无头可断言类开关）
// ------------------------------------------------------------
fn apply_done_style(label: &gtk::Label, done: bool) {
    if done {
        label.add_css_class("done");
    } else {
        label.remove_css_class("done");
    }
}

// ------------------------------------------------------------
// 应用状态：模型 + 统计 + 持久化
// ------------------------------------------------------------
struct Todos {
    store: gtk::gio::ListStore,
    stats: gtk::Label,
}

impl Todos {
    fn new() -> Self {
        let store = gtk::gio::ListStore::new::<TodoItem>();
        let stats = gtk::Label::new(Some("待办 · 已完成 0/0"));
        let t = Self { store, stats };
        t.refresh_stats();
        t
    }

    fn n_items(&self) -> u32 {
        self.store.n_items()
    }

    fn done_count(&self) -> u32 {
        (0..self.store.n_items())
            .filter(|i| {
                self.store
                    .item(*i)
                    .unwrap()
                    .downcast_ref::<TodoItem>()
                    .unwrap()
                    .done()
            })
            .count() as u32
    }

    fn refresh_stats(&self) {
        self.stats.set_text(&format!(
            "待办 · 已完成 {}/{}",
            self.done_count(),
            self.n_items()
        ));
    }

    fn add(&self, text: &str) {
        self.store.append(&TodoItem::new(text, false));
        self.refresh_stats();
    }

    /// 造一行：勾选框 + 文字 + 删按钮（bind_model 的 create 闭包用）。
    /// 样式刷新挂在 item 的 notify::done 上——属性变了行自动换装。
    fn make_row(&self, item: &TodoItem) -> gtk::Widget {
        let check = gtk::CheckButton::new();
        check.set_active(item.done()); // set_active 不发 toggled——初值直设
        let label = gtk::Label::new(Some(&item.text()));
        label.set_halign(gtk::Align::Start);
        label.set_hexpand(true);
        apply_done_style(&label, item.done());

        // 用户勾选 → 翻属性；属性 notify → 一个处理器同时刷样式与统计
        {
            let item = item.clone();
            check.connect_toggled(move |c| item.set_done(c.is_active()));
        }
        {
            let label = label.clone();
            let stats = self.stats.clone();
            let store = self.store.clone();
            // connect_notify 要求闭包 Send+Sync（Label 不是）——UI 侧用
            // connect_notify_local（对照 25 章：处理器别跨线程就选 local 版）
            item.connect_notify_local(Some("done"), move |it, _| {
                let done = it.downcast_ref::<TodoItem>().unwrap().done();
                apply_done_style(&label, done);
                Todos::refresh_stats_with(&stats, &store);
            });
        }

        let del = gtk::Button::with_label("删");
        {
            let store = self.store.clone();
            let victim = item.clone();
            let stats = self.stats.clone();
            del.connect_clicked(move |_| {
                if let Some(pos) = store.find(&victim) {
                    store.remove(pos);
                    Todos::refresh_stats_with(&stats, &store);
                }
            });
        }

        let row = gtk::Box::new(gtk::Orientation::Horizontal, 8);
        row.append(&check);
        row.append(&label);
        row.append(&del);
        row.upcast()
    }

    fn refresh_stats_with(stats: &gtk::Label, store: &gtk::gio::ListStore) {
        let done = (0..store.n_items())
            .filter(|i| {
                store
                    .item(*i)
                    .unwrap()
                    .downcast_ref::<TodoItem>()
                    .unwrap()
                    .done()
            })
            .count();
        stats.set_text(&format!("待办 · 已完成 {}/{}", done, store.n_items()));
    }

    // ---- 持久化 ----
    fn save(&self) -> usize {
        let snap = Snapshot {
            items: (0..self.n_items())
                .map(|i| {
                    // item() 返回 owned Object——先绑定再 downcast_ref，
                    // 链到底会让 &TodoItem 悬在临时值上（E0716）
                    let obj = self.store.item(i).unwrap();
                    let it = obj.downcast_ref::<TodoItem>().unwrap();
                    ItemSnap {
                        text: it.text().to_string(),
                        done: it.done(),
                    }
                })
                .collect(),
        };
        let json = serde_json::to_string(&snap).unwrap_or_default();
        let len = json.len();
        let _ = std::fs::write(save_path(), json);
        len
    }

    fn load(&self) {
        let Ok(json) = std::fs::read_to_string(save_path()) else {
            return;
        };
        let Ok(snap) = serde_json::from_str::<Snapshot>(&json) else {
            return;
        };
        self.store.remove_all();
        for it in snap.items {
            self.store.append(&TodoItem::new(&it.text, it.done));
        }
        self.refresh_stats();
    }
}

/// 清空动作：Gio SimpleAction。无头用 action.activate 直测；
/// 真窗口挂到 Application 上并绑 <Ctrl>D。
fn make_clear_action(t: &Rc<Todos>) -> gtk::gio::SimpleAction {
    let action = gtk::gio::SimpleAction::new("clear", None);
    {
        let t = t.clone();
        action.connect_activate(move |_, _| {
            t.store.remove_all();
            Todos::refresh_stats_with(&t.stats, &t.store);
        });
    }
    action
}

fn main() -> glib::ExitCode {
    if std::env::args().nth(1).is_some_and(|a| a == "--selftest") {
        run_selftest();
        return glib::ExitCode::from(0);
    }

    let app = gtk::Application::builder()
        .application_id("org.rustgui.GtkApp")
        .build();
    app.connect_activate(|app| {
        let provider = gtk::CssProvider::new();
        provider.load_from_data(CSS);
        if let Some(display) = gtk::gdk::Display::default() {
            gtk::style_context_add_provider_for_display(
                &display,
                &provider,
                gtk::STYLE_PROVIDER_PRIORITY_APPLICATION,
            );
        }

        let todos = Rc::new(Todos::new());
        todos.load();
        if todos.n_items() == 0 {
            todos.add("读 gtk 章节");
            let first = todos
                .store
                .item(0)
                .unwrap()
                .downcast_ref::<TodoItem>()
                .unwrap()
                .clone();
            first.set_done(true);
            todos.refresh_stats();
            todos.add("写第四个实战");
        }

        // app 级 action + 快捷键（<Ctrl>D 清空）
        let clear = make_clear_action(&todos);
        app.add_action(&clear);
        app.set_accels_for_action("app.clear", &["<Ctrl>D"]);

        let entry = gtk::Entry::new();
        entry.set_placeholder_text(Some("新待办…"));
        {
            let t = todos.clone();
            entry.connect_activate(move |e| {
                let text = e.text().trim().to_string();
                if !text.is_empty() {
                    t.add(&text);
                    e.set_text("");
                }
            });
        }
        let add_btn = gtk::Button::with_label("添加");
        {
            let t = todos.clone();
            let entry = entry.clone();
            add_btn.connect_clicked(move |_| {
                let text = entry.text().trim().to_string();
                if !text.is_empty() {
                    t.add(&text);
                    entry.set_text("");
                }
            });
        }

        let listbox = gtk::ListBox::new();
        listbox.set_selection_mode(gtk::SelectionMode::None);
        {
            let t = todos.clone();
            listbox.bind_model(Some(&todos.store), move |obj| {
                let item = obj.clone().downcast::<TodoItem>().unwrap();
                t.make_row(&item)
            });
        }

        let scrolled = gtk::ScrolledWindow::new();
        scrolled.set_child(Some(&listbox));
        scrolled.set_vexpand(true);
        scrolled.set_min_content_height(220);

        let input_row = gtk::Box::new(gtk::Orientation::Horizontal, 8);
        entry.set_hexpand(true);
        input_row.append(&entry);
        input_row.append(&add_btn);

        let vbox = gtk::Box::new(gtk::Orientation::Vertical, 8);
        vbox.set_margin_top(10);
        vbox.set_margin_bottom(10);
        vbox.set_margin_start(12);
        vbox.set_margin_end(12);
        vbox.append(&todos.stats);
        vbox.append(&input_row);
        vbox.append(&scrolled);
        vbox.append(&gtk::Label::new(Some("Ctrl+D 清空 · 关闭自动保存")));

        let win = gtk::ApplicationWindow::new(app);
        win.set_title(Some("30 gtk app"));
        win.set_default_size(400, 420);
        win.set_child(Some(&vbox));
        win.present();

        // 窗口关闭时保存（简化：每次 save 手动调；此处演示 save 挂钩）
        {
            let t = todos.clone();
            win.connect_close_request(move |_| {
                t.save();
                glib::Propagation::Proceed
            });
        }
    });
    app.run()
}

/// 无头自检（对齐 09/16/23 的旅程：添加 → 勾选 → 删除 → 清空 → 持久化往返）。
fn selftest_body() -> String {
    gtk::init().expect("gtk::init 失败（需要交互桌面会话）");
    let _ = std::fs::remove_file(save_path());

    let todos = Todos::new();
    todos.add("读 gtk 章节");
    todos
        .store
        .item(0)
        .unwrap()
        .downcast_ref::<TodoItem>()
        .unwrap()
        .set_done(true);
    todos.add("写第四个实战");
    assert_eq!(todos.n_items(), 2);
    assert_eq!(todos.done_count(), 1);

    // 添加（模型直打——Entry 路径与 25 章同构，不再重复）
    todos.add("对照四框架横评");
    assert_eq!(todos.n_items(), 3);

    // 删除：store.find 定位
    let victim = todos
        .store
        .item(2)
        .unwrap()
        .downcast_ref::<TodoItem>()
        .unwrap()
        .clone();
    let pos = todos.store.find(&victim).expect("find 应定位到");
    todos.store.remove(pos);
    todos.refresh_stats();
    assert_eq!(todos.n_items(), 2);

    // 样式纯函数：类开关（CSS 渲染归真窗口）
    let probe = gtk::Label::new(Some("文字"));
    apply_done_style(&probe, true);
    assert!(probe.has_css_class("done"));
    apply_done_style(&probe, false);
    assert!(!probe.has_css_class("done"));

    // GAction：activate 直测（无头可测的 Gio 动作机制）
    let t = Rc::new(todos);
    t.store.append(&TodoItem::new("再来一条", false)); // 3 条
    let clear = make_clear_action(&t);
    clear.activate(None);
    assert_eq!(t.n_items(), 0, "clear 动作应清空");
    let action_ok = t.n_items() == 0;

    // 持久化往返
    t.add("持久化探针");
    t.store
        .item(0)
        .unwrap()
        .downcast_ref::<TodoItem>()
        .unwrap()
        .set_done(true);
    let bytes = t.save();
    assert!(bytes > 0);
    let t2 = Todos::new();
    t2.load();
    assert_eq!(t2.n_items(), 1);
    let first = t2.store.item(0).unwrap().downcast::<TodoItem>().unwrap(); // owned downcast
    assert_eq!(
        (first.text().to_string().as_str(), first.done()),
        ("持久化探针", true)
    );
    let _ = std::fs::remove_file(save_path());

    format!("items=0 saved={bytes}B roundtrip=1 action-clear={action_ok} style-done=ok")
}

fn run_selftest() {
    println!("==== 30 gtk 待办管理器 开始 ====");
    let evidence = selftest_body();
    println!("{evidence}");
    println!("==== 30 gtk 待办管理器 结束 ====");
}

#[cfg(test)]
mod tests {
    #[gtk::test]
    fn todo_journey_model_style_action_persist() {
        let s = super::selftest_body();
        assert!(s.contains("roundtrip=1"), "持久化往返是前提");
        assert!(s.ends_with("action-clear=true style-done=ok"));
    }
}
