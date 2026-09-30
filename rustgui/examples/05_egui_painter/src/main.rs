// ============================================================
// 05_egui_painter —— Painter 自绘：进度环与逐帧动画
//
// 读法：
//   1. 自绘三步：allocate_exact_size 要一块矩形 → painter 画 →
//      返回的 Response 照常参与交互（hover/click）。
//   2. 弧线没有现成 API：官方 spinner 的画法就是手算 sin/cos
//      点列 + Shape::line —— 我们照此画 270° 进度环。
//   3. 动画驱动力：状态每帧 +delta，然后 ctx.request_repaint()
//      请求下一帧。kittest 里 animation_time=0（动画辅助函数瞬时
//      到位），所以这里用"每帧固定步进"的写法保证可测。
//
// 官方参考：https://docs.rs/egui/latest/egui/（Painter / Shape）
// ============================================================

/// 进度环圆弧跨度：270°（从 -225° 起到 -45° 止，缺口朝下）
const SWEEP: f32 = 270.0;
/// 起始角（度）：使缺口对称朝下
const START_DEG: f32 = 135.0;

#[derive(Clone, Default)]
struct RingApp {
    progress: f32, // 0.0..=1.0
    running: bool,
    frames: u64, // 运行期间累计的帧数（selftest 证据）
}

impl RingApp {
    fn new() -> Self {
        Self {
            progress: 0.0,
            running: false,
            frames: 0,
        }
    }

    /// 在 rect 里画一枚进度环：灰底环 + 彩色进度弧 + 中心百分比
    fn paint_ring(ui: &mut egui::Ui, rect: egui::Rect, progress: f32) {
        let painter = ui.painter();
        let center = rect.center();
        let radius = rect.size().min_elem() * 0.5 - 8.0;
        let width = 10.0_f32;

        // 底环：整圆描边
        painter.circle_stroke(
            center,
            radius,
            egui::Stroke::new(width, egui::Color32::from_gray(60)),
        );

        // 进度弧：手算点列（官方 spinner 同款技法）
        let sweep_rad = SWEEP.to_radians();
        let start_rad = START_DEG.to_radians();
        let n = 48; // 弧线离散点数
        let end = start_rad + sweep_rad * progress.clamp(0.0, 1.0);
        let points: Vec<egui::Pos2> = (0..=n)
            .map(|i| {
                let t = i as f32 / n as f32;
                let angle = start_rad + (end - start_rad) * t;
                center + radius * egui::vec2(angle.cos(), angle.sin())
            })
            .collect();
        painter.add(egui::Shape::line(
            points,
            egui::Stroke::new(width, egui::Color32::from_rgb(74, 158, 255)),
        ));

        // 中心文字：painter 也能排版文字（FontId + Align2）
        painter.text(
            center,
            egui::Align2::CENTER_CENTER,
            format!("{:.0}%", progress.clamp(0.0, 1.0) * 100.0),
            egui::FontId::proportional(22.0),
            ui.visuals().strong_text_color(),
        );
    }

    fn ui_body(ui: &mut egui::Ui, app: &mut RingApp) {
        egui::CentralPanel::default().show(ui, |ui| {
            ui.heading("Progress Ring");

            // ---- 自绘三步：要矩形 → 画 → 得到 Response ----
            let (rect, _response) =
                ui.allocate_exact_size(egui::vec2(160.0, 160.0), egui::Sense::hover());
            Self::paint_ring(ui, rect, app.progress);

            ui.add_enabled_ui(app.progress < 1.0, |ui| {
                let label = if app.running { "Pause" } else { "Run" };
                if ui.button(label).clicked() {
                    app.running = !app.running;
                }
            });

            // ---- 动画驱动力：运行中每帧步进并请求重绘 ----
            if app.running {
                app.frames += 1;
                app.progress = (app.progress + 0.05).min(1.0);
                if app.progress >= 1.0 {
                    app.running = false; // 跑满自动停
                }
                ui.ctx().request_repaint(); // "我还要下一帧"
            }
        });
    }
}

impl eframe::App for RingApp {
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
        viewport: egui::ViewportBuilder::default().with_inner_size([320.0, 340.0]),
        ..Default::default()
    };
    eframe::run_native(
        "05_egui_painter",
        options,
        Box::new(|_cc| Ok(Box::new(RingApp::new()))),
    )
}

/// 无头自检：点 Run，让 harness 逐帧跑到稳定（环跑满自动停转、
/// 不再请求重绘），断言进度满格、帧数确定。
fn selftest_body() -> RingApp {
    use egui_kittest::kittest::Queryable;

    // 持续 request_repaint 的 UI 会撞默认 max_steps=4 —— 调大并观察
    let mut harness = egui_kittest::Harness::builder()
        .with_max_steps(64)
        .build_eframe(|_cc| RingApp::new());

    harness.get_by_label("Run").click();
    let steps = harness.run(); // 逐帧前进直到不再请求重绘（环满自停）

    let app = harness.state().clone();
    assert_eq!(app.progress, 1.0, "步进 0.05/帧，跑到稳定应为满格");
    assert!(!app.running, "跑满应自动暂停");
    assert_eq!(app.frames, 20, "0.0 -> 1.0 每帧 +0.05 恰好 20 帧");
    println!("settled in {steps} steps (20 animation frames + 收尾帧)");
    app
}

fn run_selftest() {
    println!("==== 05 egui 自绘进度环 开始 ====");
    let app = selftest_body();
    println!(
        "progress={:.0}% frames={}",
        app.progress * 100.0,
        app.frames
    );
    println!("==== 05 egui 自绘进度环 结束 ====");
}

#[cfg(test)]
mod tests {
    #[test]
    fn ring_runs_to_completion() {
        let app = super::selftest_body();
        assert_eq!((app.progress, app.frames), (1.0, 20));
    }
}
