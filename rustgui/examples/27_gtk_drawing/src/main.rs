// ============================================================
// 27_gtk_drawing —— GTK 自绘：cairo 进度环（四框架第四只环）
//
// 读法：
//   1. GTK 4.16 起 DrawingArea 的 draw 回调拿的是 &cairo::Context
//      （gtk4 0.11.5 手动层签名实证；官方书 4.12 时代的 snapshot
//      示例已代际更替——照书抄编译不过，这是本部分最典型的断代坑）。
//   2. 绘制抽成纯函数 draw_ring(cr, w, h, frac)：尺寸参数化、
//      不碰 widget——无头测试直接喂 cairo::ImageSurface 断言像素
//      （四条无头通道里唯一的"真·像素级"验证，比 kittest 还硬）。
//   3. 文字归布局层：中心百分比是 Overlay 里的 Label，cairo 只画
//      图形——绘制与文字各司其职（对照 05/15/20 章的环）。
//   4. 动画：glib::timeout_add_local(Duration, || ControlFlow)，
//      只在真窗口开；selftest 不装定时器（两跑一致性铁律）。
//
// 【坑】cairo 的 stroke() 在 cairo-rs 0.22 返回 Result——绘制路径
//      别 unwrap（渲染期 panic 最难查），let _ = 吞掉状态错误。
//
// 官方参考：https://docs.gtk.org/gtk4/class.DrawingArea.html
// ============================================================

use gtk::{cairo, glib, prelude::*};
use std::cell::Cell;
use std::rc::Rc;
use std::time::Duration;

/// 纯函数：270° 缺口进度环。frac ∈ [0,1]；到 1.0 换"完成绿"。
/// 起点 135°（左下）、顺时针扫 3/4 圈，缺口朝下——与 05/15/20 章同规格。
fn draw_ring(cr: &cairo::Context, w: f64, h: f64, frac: f64) {
    let (cx, cy) = (w / 2.0, h / 2.0);
    let radius = w.min(h) / 2.0 - 10.0;
    let start = 135.0_f64.to_radians();
    let sweep = 270.0_f64.to_radians();

    cr.set_line_width(10.0);
    cr.set_line_cap(cairo::LineCap::Round);

    // 背景轨道（整圈 3/4）
    cr.set_source_rgba(0.85, 0.85, 0.85, 1.0);
    cr.arc(cx, cy, radius, start, start + sweep);
    let _ = cr.stroke();

    // 前景弧（按 frac 比例）——蓝为进行中，绿为完成
    if frac > 0.0 {
        if frac >= 1.0 {
            cr.set_source_rgba(0.30, 0.77, 0.35, 1.0);
        } else {
            cr.set_source_rgba(0.21, 0.52, 0.92, 1.0);
        }
        cr.arc(cx, cy, radius, start, start + sweep * frac);
        let _ = cr.stroke();
    }
}

/// 无头像素证据：80×80 的 ARgb32 面上画环，数"前景色像素"
/// （非中性色——蓝为进行、绿为完成，背景灰轨道天然排除）
/// 与中心点 alpha。
fn ring_pixel_facts(frac: f64) -> (u32, u8) {
    let mut surface =
        cairo::ImageSurface::create(cairo::Format::ARgb32, 80, 80).expect("无头创建 ImageSurface");
    {
        let cr = cairo::Context::new(&surface).expect("无头创建 cairo Context");
        draw_ring(&cr, 80.0, 80.0, frac);
    } // Context 不释放，data() 会报 NonExclusive（cairo 的"占用中"保护）

    let stride = surface.stride() as usize; // 先取 stride，再独占借出像素
    let data = surface.data().expect("读像素");
    let mut colored = 0u32;
    for y in 0..80usize {
        for x in 0..80usize {
            let i = y * stride + x * 4; // ARGB32 预乘：字节序 B,G,R,A（小端）
            // 前景判定＝"非中性"：蓝（进行中）或绿（完成）相对红色通道
            // 拉开差距；背景轨道是中性灰（R=G=B），天然被排除。
            let (b, g, r, a) = (data[i], data[i + 1], data[i + 2], data[i + 3]);
            if a > 0 && (b.abs_diff(r) > 40 || g.abs_diff(r) > 40) {
                colored += 1;
            }
        }
    }
    let center = data[40 * stride + 40 * 4 + 3]; // 圆心应在环的空心区
    (colored, center)
}

struct Ring {
    frac: Rc<Cell<f64>>,
    label: gtk::Label,
    area: gtk::DrawingArea,
}

impl Ring {
    fn new() -> Self {
        let frac = Rc::new(Cell::new(0.3));
        let label = gtk::Label::new(Some("30%"));
        label.set_halign(gtk::Align::Center);
        label.set_valign(gtk::Align::Center);

        let area = gtk::DrawingArea::new();
        area.set_content_width(180);
        area.set_content_height(180);
        {
            let frac = frac.clone();
            area.set_draw_func(move |_, cr, w, h| draw_ring(cr, w as f64, h as f64, frac.get()));
        }

        Self { frac, label, area }
    }

    /// Overlay：中心文字叠在画布上（文字归布局层，cairo 只画图形）。
    fn overlay(&self) -> gtk::Overlay {
        let overlay = gtk::Overlay::new();
        overlay.set_child(Some(&self.area));
        overlay.add_overlay(&self.label);
        overlay
    }

    /// 接线完成的 -/+ 按钮：真窗口与无头测试共用同一份接线
    /// （selftest 点的就是这些按钮，验证的是真实闭包）。
    fn step_buttons(&self) -> (gtk::Button, gtk::Button) {
        let minus = gtk::Button::with_label("-10%");
        {
            let frac = self.frac.clone();
            let label = self.label.clone();
            let area = self.area.clone();
            minus.connect_clicked(move |_| Self::apply(&frac, &label, &area, -0.1));
        }
        let plus = gtk::Button::with_label("+10%");
        {
            let frac = self.frac.clone();
            let label = self.label.clone();
            let area = self.area.clone();
            plus.connect_clicked(move |_| Self::apply(&frac, &label, &area, 0.1));
        }
        (minus, plus)
    }

    /// "自动"按钮：装 16ms 定时器循环推进（只在真窗口点）。
    fn auto_button(&self) -> gtk::Button {
        let auto = gtk::Button::with_label("自动");
        {
            let frac = self.frac.clone();
            let label = self.label.clone();
            let area = self.area.clone();
            auto.connect_clicked(move |_| {
                // 外层是 Fn 闭包，不能被内层 move 偷走捕获——再 clone 一层
                // （这正是 glib::clone! 宏要解决的样板）。
                let frac = frac.clone();
                let label = label.clone();
                let area = area.clone();
                glib::timeout_add_local(Duration::from_millis(16), move || {
                    let next = frac.get() + 0.01;
                    let v = if next > 1.0 { 0.0 } else { next };
                    Self::apply(&frac, &label, &area, v - frac.get());
                    glib::ControlFlow::Continue
                });
            });
        }
        auto
    }

    fn apply(frac: &Rc<Cell<f64>>, label: &gtk::Label, area: &gtk::DrawingArea, delta: f64) {
        let clamped = (frac.get() + delta).clamp(0.0, 1.0);
        frac.set(clamped);
        label.set_text(&format!("{}%", (clamped * 100.0).round() as i32));
        area.queue_draw();
    }
}

fn main() -> glib::ExitCode {
    if std::env::args().nth(1).is_some_and(|a| a == "--selftest") {
        run_selftest();
        return glib::ExitCode::from(0);
    }

    let app = gtk::Application::builder()
        .application_id("org.rustgui.GtkDrawing")
        .build();
    app.connect_activate(|app| {
        let ring = Ring::new();
        let (minus, plus) = ring.step_buttons();
        let auto = ring.auto_button();

        let row = gtk::Box::new(gtk::Orientation::Horizontal, 8);
        row.set_halign(gtk::Align::Center);
        row.append(&minus);
        row.append(&plus);
        row.append(&auto);

        let vbox = gtk::Box::new(gtk::Orientation::Vertical, 10);
        vbox.set_margin_top(14);
        vbox.set_margin_bottom(14);
        vbox.set_margin_start(14);
        vbox.set_margin_end(14);
        vbox.append(&ring.overlay());
        vbox.append(&row);

        let win = gtk::ApplicationWindow::new(app);
        win.set_title(Some("27 gtk drawing"));
        win.set_default_size(260, 320);
        win.set_child(Some(&vbox));
        win.present();
    });
    app.run()
}

/// 无头自检：
///   a) 像素级——纯函数直测：0% 无前景、25%<50%<100% 单调、圆心透明；
///   b) 状态级——emit_clicked 走真实接线闭包，断言 frac 与中心文字。
fn selftest_body() -> String {
    gtk::init().expect("gtk::init 失败（需要交互桌面会话）");

    // a) 像素证据（不碰任何 widget）
    let (a0, c0) = ring_pixel_facts(0.0);
    let (a25, c25) = ring_pixel_facts(0.25);
    let (a50, c50) = ring_pixel_facts(0.5);
    let (a100, c100) = ring_pixel_facts(1.0);
    assert_eq!(a0, 0, "0% 时不应有前景像素");
    assert!(
        a25 > 0 && a50 > a25 && a100 > a50,
        "前景像素应随 frac 单调增：a25={a25} a50={a50} a100={a100}"
    );
    assert_eq!(
        (c0, c25, c50, c100),
        (0, 0, 0, 0),
        "圆心必须始终透明（空心环）"
    );

    // b) 状态驱动：按钮路径（点的是 step_buttons 装好线的真按钮）
    let ring = Ring::new();
    let (minus, plus) = ring.step_buttons();
    let ctx = glib::MainContext::default();

    plus.emit_clicked();
    plus.emit_clicked();
    while ctx.pending() {
        ctx.iteration(false);
    }
    assert_eq!(ring.frac.get(), 0.5);
    assert_eq!(ring.label.text().to_string(), "50%", "30% + 10% + 10%");

    minus.emit_clicked();
    while ctx.pending() {
        ctx.iteration(false);
    }
    assert_eq!(ring.frac.get(), 0.4, "回退一步");

    for _ in 0..8 {
        plus.emit_clicked();
    }
    while ctx.pending() {
        ctx.iteration(false);
    }
    assert_eq!(ring.frac.get(), 1.0, "clamp 顶在 100%");
    assert_eq!(ring.label.text().to_string(), "100%");

    format!("px 0/25/50/100 = {a0}/{a25}/{a50}/{a100} center-a=0 frac=1.00 label=100%")
}

fn run_selftest() {
    println!("==== 27 gtk 自绘进度环 开始 ====");
    let evidence = selftest_body();
    println!("{evidence}");
    println!("==== 27 gtk 自绘进度环 结束 ====");
}

#[cfg(test)]
mod tests {
    #[gtk::test]
    fn ring_pixels_and_state() {
        let s = super::selftest_body();
        assert!(s.starts_with("px 0/25/50/100 = 0/"), "0% 无前景像素是前提");
        assert!(s.ends_with("center-a=0 frac=1.00 label=100%"));
    }
}
