// ============================================================
// 28_gtk_models —— GListModel 生态：模型链、factory 与双视图
//
// 读法：
//   1. GTK 列表的心智模型：数据住 ListModel 链（StringList →
//      FilterListModel → SortListModel → SingleSelection），
//      视图（ListBox/ListView）只是链尾投影——25 章共享
//      Adjustment 的"状态在模型"是它的缩影，这里是完全体。
//   2. 两条视图路线：ListBox::bind_model（闭包造行，简单列表）
//      与 ListView + SignalListItemFactory（setup 造壳 / bind
//      填数据两段式，22 章同规格的 GTK 形态）。
//   3. 三层无头断言：模型层（n_items/条目）、表达式层
//      （PropertyExpression 直接求值，零 UI）、视图层——
//      factory 的 bind 由"窗口 realize"驱动，纯无窗永不触发：
//      隐形窗口（opacity 0 + present + test_widget_wait_for_draw）
//      是让它跑起来的关键技巧；bind 日志是 ListView 的查询接口。
//
// 【坑】中文排序走 g_utf8_collate（locale 相关）：断言只保证
//      "是原集合的排列"，首行文字打印出来交给同机重跑对账。
//
// 官方参考：https://gtk-rs.org/gtk4-rs/git/book/list_widgets.html
// ============================================================

use gtk::{glib, prelude::*};
use std::cell::RefCell;
use std::rc::Rc;

const CITIES: &[&str] = &[
    "北京", "上海", "深圳", "杭州", "成都", "广州", "西安", "苏州",
];

fn string_expr() -> gtk::PropertyExpression {
    gtk::PropertyExpression::new(
        gtk::StringObject::static_type(),
        None::<&gtk::PropertyExpression>,
        "string",
    )
}

/// 模型链 + 双视图 + bind 日志。真窗口与无头测试共用同一套装配。
struct CityList {
    store: gtk::StringList, // 真相源
    filter: gtk::StringFilter,
    sorter: gtk::StringSorter,
    sort_model: gtk::SortListModel,
    selection: gtk::SingleSelection,    // ListView 要 SelectionModel
    listbox: gtk::ListBox,              // 视图 A：bind_model 路线
    listview: gtk::ListView,            // 视图 B：factory 路线
    bind_log: Rc<RefCell<Vec<String>>>, // factory bind 的查询接口
}

impl CityList {
    fn new() -> Self {
        let store = gtk::StringList::new(CITIES);
        let expr = string_expr();

        // 链：store → filter（初始不过滤）→ sort（初始不排序）→ selection
        // 注意新式构造器吃 Option<impl IsA>（owned 引用计数 clone），
        // 而 bind_model/set_sorter 是 Option<&impl IsA>——两种形态并存。
        let filter = gtk::StringFilter::new(Some(expr.clone()));
        let filter_model = gtk::FilterListModel::new(Some(store.clone()), Some(filter.clone()));
        let sorter = gtk::StringSorter::new(Some(expr));
        let sort_model =
            gtk::SortListModel::new(Some(filter_model.clone()), None::<gtk::StringSorter>);
        let selection = gtk::SingleSelection::new(Some(sort_model.clone()));

        // 视图 A：ListBox + bind_model——一行闭包造行
        let listbox = gtk::ListBox::new();
        listbox.set_selection_mode(gtk::SelectionMode::Single);
        listbox.bind_model(Some(&sort_model), |obj| {
            let s = obj.downcast_ref::<gtk::StringObject>().unwrap().string();
            gtk::Label::new(Some(&s)).upcast::<gtk::Widget>()
        });

        // 视图 B：ListView + SignalListItemFactory——setup 造壳 / bind 填数据
        let bind_log = Rc::new(RefCell::new(Vec::new()));
        let factory = gtk::SignalListItemFactory::new();
        factory.connect_setup(|_, item| {
            let item = item.downcast_ref::<gtk::ListItem>().unwrap();
            let label = gtk::Label::new(None);
            label.set_halign(gtk::Align::Start);
            item.set_child(Some(&label));
        });
        {
            let log = bind_log.clone();
            factory.connect_bind(move |_, item| {
                let item = item.downcast_ref::<gtk::ListItem>().unwrap();
                let so = item
                    .item()
                    .unwrap()
                    .downcast::<gtk::StringObject>()
                    .unwrap();
                let text = so.string().to_string();
                item.child()
                    .and_then(|c| c.downcast::<gtk::Label>().ok())
                    .expect("setup 装的应是 Label")
                    .set_text(&text);
                log.borrow_mut().push(text);
            });
        }
        let listview = gtk::ListView::new(Some(selection.clone()), Some(factory));

        Self {
            store,
            filter,
            sorter,
            sort_model,
            selection,
            listbox,
            listview,
            bind_log,
        }
    }

    /// 链尾可见条目（排序后顺序）。
    fn visible(&self) -> Vec<String> {
        (0..self.sort_model.n_items())
            .map(|i| {
                self.sort_model
                    .item(i)
                    .unwrap()
                    .downcast::<gtk::StringObject>()
                    .unwrap()
                    .string()
                    .to_string()
            })
            .collect()
    }
}

/// 排空 + 推一帧，直到 bind 日志达到 want 条（条件驱动，不 sleep）。
fn pump_until_binds(log: &Rc<RefCell<Vec<String>>>, want: usize, win: &gtk::Window) {
    let ctx = glib::MainContext::default();
    for _ in 0..100 {
        while ctx.pending() {
            ctx.iteration(false);
        }
        if log.borrow().len() >= want {
            return;
        }
        gtk::test_widget_wait_for_draw(win); // 推一帧（无渲染断言，只等帧走完）
    }
}

fn main() -> glib::ExitCode {
    if std::env::args().nth(1).is_some_and(|a| a == "--selftest") {
        run_selftest();
        return glib::ExitCode::from(0);
    }

    let app = gtk::Application::builder()
        .application_id("org.rustgui.GtkModels")
        .build();
    app.connect_activate(|app| {
        let c = CityList::new();

        let sort_btn = gtk::ToggleButton::with_label("排序");
        {
            let m = c.sort_model.clone();
            let s = c.sorter.clone();
            sort_btn.connect_toggled(move |b| {
                if b.is_active() {
                    m.set_sorter(Some(&s));
                } else {
                    m.set_sorter(None::<&gtk::StringSorter>);
                }
            });
        }
        let filter_btn = gtk::ToggleButton::with_label("过滤：含「州」");
        {
            let f = c.filter.clone();
            filter_btn.connect_toggled(move |b| {
                f.set_search(if b.is_active() { Some("州") } else { None });
            });
        }
        let add_btn = gtk::Button::with_label("加：徐州");
        {
            let s = c.store.clone();
            add_btn.connect_clicked(move |_| s.append("徐州"));
        }
        let del_btn = gtk::Button::with_label("删：第一项");
        {
            let s = c.store.clone();
            del_btn.connect_clicked(move |_| s.remove(0));
        }

        let left = gtk::ScrolledWindow::new();
        left.set_child(Some(&c.listbox));
        left.set_vexpand(true);
        let right = gtk::ScrolledWindow::new();
        right.set_child(Some(&c.listview));
        right.set_vexpand(true);
        let views = gtk::Box::new(gtk::Orientation::Horizontal, 8);
        views.append(&left);
        views.append(&right);

        let btns = gtk::Box::new(gtk::Orientation::Horizontal, 8);
        btns.append(&sort_btn);
        btns.append(&filter_btn);
        btns.append(&add_btn);
        btns.append(&del_btn);

        let vbox = gtk::Box::new(gtk::Orientation::Vertical, 8);
        vbox.set_margin_top(10);
        vbox.set_margin_bottom(10);
        vbox.set_margin_start(10);
        vbox.set_margin_end(10);
        vbox.append(&views);
        vbox.append(&btns);

        let win = gtk::ApplicationWindow::new(app);
        win.set_title(Some("28 gtk models"));
        win.set_default_size(460, 380);
        win.set_child(Some(&vbox));
        win.present();
    });
    app.run()
}

/// 无头自检：模型层 → 表达式层 → 过滤排序 → 增删投影 → 视图层（隐形窗口）。
fn selftest_body() -> String {
    gtk::init().expect("gtk::init 失败（需要交互桌面会话）");
    let c = CityList::new();

    // ---- a) 模型层：无过滤无排序时全量透传 ----
    assert_eq!(c.store.n_items(), 8);
    assert_eq!(c.selection.n_items(), 8);

    // ---- b) 表达式层：PropertyExpression 直接求值（零 UI）----
    let expr = string_expr();
    let first = c
        .store
        .item(0)
        .unwrap()
        .downcast::<gtk::StringObject>()
        .unwrap();
    let v: String = expr
        .evaluate_as::<String, gtk::StringObject>(Some(&first))
        .unwrap();
    assert_eq!(v, "北京", "表达式应取出 StringObject 的 string 属性");

    // ---- c) 过滤：含「州」（保序：杭州/广州/苏州）----
    c.filter.set_search(Some("州"));
    assert_eq!(c.selection.n_items(), 3);
    assert_eq!(c.visible(), vec!["杭州", "广州", "苏州"]);

    // ---- d) 排序：collate 顺序只断言"是排列"，不断言 locale 顺序 ----
    c.sort_model.set_sorter(Some(&c.sorter));
    let sorted = c.visible();
    let mut bag = sorted.clone();
    bag.sort();
    let mut expect = vec!["苏州".to_string(), "广州".to_string(), "杭州".to_string()];
    expect.sort();
    assert_eq!(bag, expect, "排序后应是原可见集合的排列");
    assert_eq!(c.store.n_items(), 8, "过滤/排序不动真相源");

    // ---- e) 视图层：隐形窗口 realize 驱动两个视图的行装配 ----
    let sw_l = gtk::ScrolledWindow::new();
    sw_l.set_child(Some(&c.listbox));
    let sw_r = gtk::ScrolledWindow::new();
    sw_r.set_child(Some(&c.listview));
    let row = gtk::Box::new(gtk::Orientation::Horizontal, 8);
    row.append(&sw_l);
    row.append(&sw_r);
    let ghost = gtk::Window::new();
    ghost.set_default_size(460, 380);
    ghost.set_child(Some(&row));
    ghost.set_opacity(0.0); // 渲染上隐形；布局与 realize 照常发生
    ghost.present();
    pump_until_binds(&c.bind_log, 3, &ghost);

    // ListBox：行已实现，第一行文字 = 链尾第一项（同机 locale 确定）
    let row0 = c
        .listbox
        .row_at_index(0)
        .expect("隐形窗口 realize 后应有第一行");
    let row0_text = row0
        .child()
        .and_then(|ch| ch.downcast::<gtk::Label>().ok())
        .expect("bind_model 的行是 Label")
        .text()
        .to_string();
    assert_eq!(row0_text, sorted[0], "ListBox 行序 = 链尾模型序");

    // ListView：bind 日志应覆盖全部 3 条可见项
    for city in &sorted {
        assert!(
            c.bind_log.borrow().contains(city),
            "ListView 应已 bind：{city}"
        );
    }

    // ---- f) 增删打真相源，链上投影自动更新 ----
    c.filter.set_search(None); // 清过滤：8 条全可见
    assert_eq!(c.selection.n_items(), 8);
    c.store.append("徐州");
    assert_eq!((c.store.n_items(), c.selection.n_items()), (9, 9));
    c.store.remove(0); // 删北京
    assert_eq!((c.store.n_items(), c.selection.n_items()), (8, 8));
    let vis = c.visible();
    assert!(!vis.contains(&"北京".to_string()) && vis.contains(&"徐州".to_string()));

    format!("expr=北京 filtered=杭州|广州|苏州 first_row={row0_text} store=8 selection=8")
}

fn run_selftest() {
    println!("==== 28 gtk 模型与列表 开始 ====");
    let evidence = selftest_body();
    println!("{evidence}");
    println!("==== 28 gtk 模型与列表 结束 ====");
}

#[cfg(test)]
mod tests {
    #[gtk::test]
    fn model_chain_filter_sort_and_views() {
        let s = super::selftest_body();
        assert!(s.starts_with("expr=北京"), "表达式求值是前提");
        assert!(s.ends_with("store=8 selection=8"));
    }
}
