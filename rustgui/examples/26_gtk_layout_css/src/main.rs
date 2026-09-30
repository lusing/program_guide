// ============================================================
// 26_gtk_layout_css —— GTK 布局容器与 CSS 样式系统
//
// 读法：
//   1. 布局四件套全代码构建（对照 25 章的 Builder XML 路线）：
//      Box 线性 / Grid 网格（attach 列行宽高、跨列）/ FlowBox
//      流式换行 + 单选 / Revealer 显隐过渡。
//   2. CSS 是 GTK 的样式层：CssProvider + load_from_data +
//      style_context_add_provider_for_display 挂到全局；
//      控件级开关是 add_css_class/remove_css_class——样式类即
//      状态位（30 章完成态划线的地基）。
//   3. 无头边界：CSS 的"视觉效果"无头不可见（不渲染像素），
//      但"类挂没挂、结构对不对"是逻辑断言，可测。视觉裁决
//      在真窗口截图层。
//
// 【坑】Revealer 的过渡动画在无头里破坏确定性：测试时
//      set_transition_type(None)，动画终值才逐字节稳定。
//
// 官方参考：https://gtk-rs.org/gtk4-rs/git/book/css.html
// ============================================================

use gtk::{glib, prelude::*};

const CSS: &str = "
.accent { background: #3584e4; color: #ffffff; }
.chip   { border-radius: 14px; padding: 4px 12px; }
.strike { text-decoration: line-through; opacity: 0.55; }
";

/// 挂全局样式（display 级）：gtk::init() 之后默认 display 已存在。
fn apply_css() {
    let provider = gtk::CssProvider::new();
    provider.load_from_data(CSS);
    if let Some(display) = gtk::gdk::Display::default() {
        gtk::style_context_add_provider_for_display(
            &display,
            &provider,
            gtk::STYLE_PROVIDER_PRIORITY_APPLICATION,
        );
    }
}

/// 布局演练场：真窗口与无头测试共用。
struct Layouts {
    grid: gtk::Grid,
    cross: gtk::Label, // 跨两列的那个单元格，测 query_child 用
    flow: gtk::FlowBox,
    chips: Vec<gtk::FlowBoxChild>,
    revealer: gtk::Revealer,
    reveal_btn: gtk::Button,
    accent_btn: gtk::Button,
    strike_label: gtk::Label,
}

impl Layouts {
    fn new(headless: bool) -> Self {
        // ---- Grid：attach(列, 行, 宽, 高)——宽高就是跨列/跨行 ----
        let grid = gtk::Grid::new();
        grid.set_row_spacing(6);
        grid.set_column_spacing(6);
        let cross = gtk::Label::new(Some("我横跨两列"));
        cross.add_css_class("chip");
        grid.attach(&gtk::Label::new(Some("第 0 行 · 左")), 0, 0, 1, 1);
        grid.attach(&gtk::Label::new(Some("第 0 行 · 右")), 1, 0, 1, 1);
        grid.attach(&cross, 0, 1, 2, 1); // (列 0, 行 1, 宽 2, 高 1)

        // ---- FlowBox：流式布局 + 单选（城市芯片）----
        let flow = gtk::FlowBox::new();
        flow.set_selection_mode(gtk::SelectionMode::Single);
        let chips: Vec<gtk::FlowBoxChild> = ["北京", "上海", "深圳", "杭州", "成都", "西安"]
            .iter()
            .map(|city| {
                let label = gtk::Label::new(Some(city));
                label.add_css_class("chip");
                let child = gtk::FlowBoxChild::new();
                child.set_child(Some(&label));
                flow.insert(&child, -1);
                child
            })
            .collect();

        // ---- Revealer：显隐过渡（无头里关动画保确定性）----
        let revealer = gtk::Revealer::new();
        let hidden = gtk::Label::new(Some("隐藏设置区：展开后才可见"));
        revealer.set_child(Some(&hidden));
        revealer.set_transition_type(if headless {
            gtk::RevealerTransitionType::None // 动画终值才确定
        } else {
            gtk::RevealerTransitionType::SlideDown
        });
        let reveal_btn = gtk::Button::with_label("展开/收起");
        {
            let r = revealer.clone();
            reveal_btn.connect_clicked(move |_| r.set_reveal_child(!r.reveals_child()));
        }

        // ---- CSS 样式类演示 ----
        let accent_btn = gtk::Button::with_label("重点按钮");
        accent_btn.add_css_class("accent");
        let strike_label = gtk::Label::new(Some("这条会被 CSS 划掉"));
        strike_label.add_css_class("strike");

        Self {
            grid,
            cross,
            flow,
            chips,
            revealer,
            reveal_btn,
            accent_btn,
            strike_label,
        }
    }

    /// 装进窗口的纵向盒（真窗口用）。
    fn root_box(&self) -> gtk::Box {
        let vbox = gtk::Box::new(gtk::Orientation::Vertical, 12);
        vbox.set_margin_top(14);
        vbox.set_margin_bottom(14);
        vbox.set_margin_start(14);
        vbox.set_margin_end(14);
        vbox.append(&gtk::Label::new(Some("Grid 网格")));
        vbox.append(&self.grid);
        vbox.append(&gtk::Label::new(Some("FlowBox 流式单选")));
        vbox.append(&self.flow);
        vbox.append(&self.reveal_btn);
        vbox.append(&self.revealer);
        vbox.append(&self.accent_btn);
        vbox.append(&self.strike_label);
        vbox
    }
}

fn main() -> glib::ExitCode {
    if std::env::args().nth(1).is_some_and(|a| a == "--selftest") {
        run_selftest();
        return glib::ExitCode::from(0);
    }

    let app = gtk::Application::builder()
        .application_id("org.rustgui.GtkLayoutCss")
        .build();
    app.connect_activate(|app| {
        let layouts = Layouts::new(false);
        apply_css();
        let win = gtk::ApplicationWindow::new(app);
        win.set_title(Some("26 gtk layout css"));
        win.set_default_size(420, 520);
        win.set_child(Some(&layouts.root_box()));
        win.present();
    });
    app.run()
}

/// 无头自检：结构断言（Grid 位置 / FlowBox 选中 / Revealer 终值）
/// + 样式类开关断言（类挂没挂是逻辑事实，不依赖渲染）。
fn selftest_body() -> String {
    gtk::init().expect("gtk::init 失败（需要交互桌面会话）");
    let l = Layouts::new(true);
    apply_css();

    // Grid：跨两列的那个单元格局数为 (0,1,2,1)
    let (col, row, w, h) = l.grid.query_child(&l.cross);
    assert_eq!((col, row, w, h), (0, 1, 2, 1), "跨两列单元格的布局元数据");

    // FlowBox：选中第 1 个芯片 → 上海，且只有一个选中
    l.flow.select_child(&l.chips[1]);
    let ctx = glib::MainContext::default();
    while ctx.pending() {
        ctx.iteration(false);
    }
    let selected = l.flow.selected_children();
    assert_eq!(selected.len(), 1, "单选模式只应有一个选中");
    let text = selected[0]
        .child()
        .and_then(|c| c.downcast::<gtk::Label>().ok())
        .expect("芯片里应是 Label")
        .text()
        .to_string();
    assert_eq!(text, "上海");

    // Revealer：点"展开" → 过渡类型 None 时终值立即可断言
    assert!(!l.revealer.is_child_revealed(), "初始应隐藏");
    l.reveal_btn.emit_clicked();
    while ctx.pending() {
        ctx.iteration(false);
    }
    assert!(l.revealer.is_child_revealed(), "点击后应展开");

    // 样式类开关：挂上/摘下是逻辑事实
    assert!(l.accent_btn.has_css_class("accent"));
    assert!(l.strike_label.has_css_class("strike"));
    l.strike_label.remove_css_class("strike");
    assert!(!l.strike_label.has_css_class("strike"));
    l.strike_label.add_css_class("strike"); // 恢复，供截图对照

    format!("grid=({col},{row},{w},{h}) selected={text} revealed=true accent=true")
}

fn run_selftest() {
    println!("==== 26 gtk 布局与 CSS 开始 ====");
    let evidence = selftest_body();
    println!("{evidence}");
    println!("==== 26 gtk 布局与 CSS 结束 ====");
}

#[cfg(test)]
mod tests {
    #[gtk::test]
    fn layout_and_css_class_facts() {
        let s = super::selftest_body();
        assert_eq!(s, "grid=(0,1,2,1) selected=上海 revealed=true accent=true");
    }
}
