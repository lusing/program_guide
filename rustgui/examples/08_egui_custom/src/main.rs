// ============================================================
// 08_egui_custom —— 自定义控件、动画辅助与持久化
//
// 读法：
//   1. 自定义控件 = impl Widget for X：allocate 要矩形 → 画 →
//      返回 Response。一个 iOS 风格开关走完全流程。
//   2. ctx.animate_bool_with_time：给布尔过渡做缓动插值，
//      egui 自动预约重绘（kittest 里动画时长为 0，瞬时到位）。
//   3. 持久化：eframe "persistence" feature + App::save 挂钩，
//      退出/定期自动序列化到 app 数据目录；启动时从 cc.storage 恢复。
//
// 官方参考：https://docs.rs/egui/latest/egui/（Widget trait / Context::animate_bool_with_time）
// ============================================================

/// iOS 风格拨动开关：完全自绘的自定义控件
struct ToggleSwitch {
    on: bool,
    /// 无障碍标签：自绘控件也得在无障碍树里"报户口"（空标签过不了
    /// kittest 的 accessibility check，键盘/读屏用户也点不准）
    label: &'static str,
}

impl egui::Widget for ToggleSwitch {
    fn ui(self, ui: &mut egui::Ui) -> egui::Response {
        // ---- 1) 布局：要一块 2:1 的矩形 ----
        let height = ui.spacing().interact_size.y;
        let size = egui::vec2(2.0 * height, height);
        let (rect, mut response) = ui.allocate_exact_size(size, egui::Sense::click());

        // ---- 2) 交互：点击即翻转（状态仍归调用方，控件只报告） ----
        if response.clicked() {
            response.mark_changed();
        }

        // ---- 3) 动画：布尔缓动（0.15s 滑块滑移；测试环境瞬时到位） ----
        let how_on = ui.ctx().animate_bool_with_time(response.id, self.on, 0.15);

        // ---- 4) 绘制 ----
        let visuals = ui.style().interact(&response); // 悬停/按下的视觉状态自动带上
        let off_color = egui::Color32::from_gray(80);
        let on_color = egui::Color32::from_rgb(52, 200, 122);
        // 颜色手工插值（Color32 没有现成 lerp_rgb）
        let mix = |a: u8, b: u8| (a as f32 + (b as f32 - a as f32) * how_on).round() as u8;
        let bg = egui::Color32::from_rgb(
            mix(off_color.r(), on_color.r()),
            mix(off_color.g(), on_color.g()),
            mix(off_color.b(), on_color.b()),
        );
        let corner = egui::CornerRadius::same((height / 2.0) as u8);
        ui.painter().rect(
            rect,
            corner,
            bg,
            egui::Stroke::NONE,
            egui::StrokeKind::Middle,
        );

        let radius = height * 0.40;
        let thumb_x = egui::lerp(
            (rect.left() + radius + 1.0)..=(rect.right() - radius - 1.0),
            how_on,
        );
        let thumb_color = visuals.bg_fill; // 跟随主题的滑块色
        ui.painter().circle(
            egui::pos2(thumb_x, rect.center().y),
            radius,
            thumb_color,
            egui::Stroke::NONE,
        );

        // ---- 5) 无障碍身份 ----
        response.widget_info(|| {
            egui::WidgetInfo::selected(
                egui::WidgetType::Checkbox, // 0.36.2 是 WidgetType（github master 已改 Role，未发布）
                ui.is_enabled(),
                self.on,
                self.label,
            )
        });

        response
    }
}

/// 需要跨启动保存的状态（serde 序列化）
#[derive(Clone, Default, serde::Serialize, serde::Deserialize)]
struct Persist {
    lamp: bool,
    clicks: u64,
}

#[derive(Clone, Default)]
struct CustomApp {
    state: Persist,
}

const STORAGE_KEY: &str = "egui_custom_state";

impl CustomApp {
    fn new(cc: &eframe::CreationContext<'_>) -> Self {
        // 启动恢复：persistence feature 开启时 eframe 会带着上次的存储调进来
        let state = cc
            .storage
            .and_then(|s| s.get_string(STORAGE_KEY))
            .and_then(|json| serde_json::from_str(&json).ok())
            .unwrap_or_default();
        Self { state }
    }

    fn ui_body(ui: &mut egui::Ui, app: &mut CustomApp) {
        egui::CentralPanel::default().show(ui, |ui| {
            ui.heading("自定义控件与持久化");

            ui.horizontal(|ui| {
                ui.label("台灯");
                // 调用方持有状态：控件的 changed() 报告"该翻面了"
                let sw = ui.add(ToggleSwitch {
                    on: app.state.lamp,
                    label: "台灯开关",
                });
                if sw.changed() {
                    app.state.lamp = !app.state.lamp;
                    app.state.clicks += 1;
                }
                ui.label(if app.state.lamp { "亮" } else { "灭" });
            });

            ui.separator();

            // ---- 持久化：退出时 eframe 自动调 App::save 落盘，
            //      下次启动 new(cc) 里从 cc.storage 恢复（见上方 new）----
            ui.label(format!("clicks = {}", app.state.clicks));
            ui.small("关掉窗口再启动，这个数字还在（persistence feature）");
        });
    }

    /// 序列化当前状态（save 挂钩与单元测试共用）
    fn save_to_string(app: &CustomApp) -> String {
        serde_json::to_string(&app.state).expect("序列化不应失败")
    }
}

impl eframe::App for CustomApp {
    fn ui(&mut self, ui: &mut egui::Ui, _frame: &mut eframe::Frame) {
        Self::ui_body(ui, self);
    }

    /// eframe 在退出/每 30 秒调用这里：把状态写进存储
    fn save(&mut self, storage: &mut dyn eframe::Storage) {
        storage.set_string(
            STORAGE_KEY,
            serde_json::to_string(&self.state).unwrap_or_default(),
        );
    }
}

fn main() -> eframe::Result {
    let selftest = std::env::args().nth(1).is_some_and(|a| a == "--selftest");
    if selftest {
        run_selftest();
        return Ok(());
    }

    let options = eframe::NativeOptions {
        viewport: egui::ViewportBuilder::default().with_inner_size([400.0, 300.0]),
        ..Default::default()
    };
    eframe::run_native(
        "08_egui_custom",
        options,
        Box::new(|cc| Ok(Box::new(CustomApp::new(cc)))),
    )
}

/// 无头自检：自绘开关可点击、动画瞬时到位、存/读档往返一致。
fn selftest_body() -> (bool, u64, bool) {
    use egui_kittest::kittest::Queryable;

    let mut harness = egui_kittest::Harness::builder().build_eframe(|cc| CustomApp::new(cc));
    harness.run();

    // 自绘开关带了无障碍标签，直接按标签点击（widget_info 里报的类型是 Checkbox）
    let sw = harness.get_by_label("台灯开关");
    sw.click();
    harness.run();
    let lamp1 = harness.state().state.lamp;
    let clicks1 = harness.state().state.clicks;

    // 序列化往返：save -> 反序列化 == 原状态
    let json = CustomApp::save_to_string(harness.state());
    let restored: Persist = serde_json::from_str(&json).expect("反序列化不应失败");
    let roundtrip_ok = restored.lamp == lamp1 && restored.clicks == clicks1;

    (lamp1, clicks1, roundtrip_ok)
}

fn run_selftest() {
    println!("==== 08 egui 自定义控件 开始 ====");
    let (lamp, clicks, roundtrip_ok) = selftest_body();
    println!("lamp={} clicks={} roundtrip={roundtrip_ok}", lamp, clicks);
    assert!(lamp && clicks == 1 && roundtrip_ok);
    println!("==== 08 egui 自定义控件 结束 ====");
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn switch_clicks_and_roundtrip() {
        let (lamp, clicks, ok) = selftest_body();
        assert!((lamp, clicks, ok) == (true, 1, true));
    }

    #[test]
    fn persistence_serialization_roundtrip() {
        let p = Persist {
            lamp: true,
            clicks: 42,
        };
        let json = serde_json::to_string(&p).unwrap();
        let back: Persist = serde_json::from_str(&json).unwrap();
        assert_eq!((back.lamp, back.clicks), (true, 42));
    }
}
