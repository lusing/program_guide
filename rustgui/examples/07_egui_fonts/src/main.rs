// ============================================================
// 07_egui_fonts —— 中文字体注册、主题与样式定制
//
// 读法：
//   1. egui 内置字体只有拉丁字符——中文要么靠 eframe 的
//      system_font_fallback（运行时系统回退，真窗口有效），
//      要么自己 FontDefinitions 换血（本例，测试环境也有效）。
//   2. 运行时从系统字体目录读文件：零字节资源入库、无许可问题；
//      生产上要绝对可控则 include_bytes! 打包 OFL 字体（07.3 节）。
//   3. 主题 = Visuals（亮/暗）+ Style（间距/控件外观），
//      都是"每帧可改"的普通数据。
//
// 【坑】02-06 章 UI 文本保持 ASCII 的原因到这里揭晓：默认字体
//      无 CJK 字形，kittest 的 MissingGlyphPolicy::Panic 会在
//      文本整形阶段直接 panic。本章注册字体后放开中文。
//
// 官方参考：https://docs.rs/egui/latest/egui/
// ============================================================

/// 各平台常见中文字体（ttf 优先于 ttc——单字体文件解析最稳）
const CJK_CANDIDATES: &[&str] = &[
    "C:\\Windows\\Fonts\\simhei.ttf",     // Windows 黑体
    "C:\\Windows\\Fonts\\msyh.ttc",       // Windows 微软雅黑
    "/System/Library/Fonts/PingFang.ttc", // macOS
    "/System/Library/Fonts/STHeiti Light.ttc",
    "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc", // Linux
    "/usr/share/fonts/noto-cjk/NotoSansCJK-Regular.ttc",
];

/// 从系统里找到一个可用的中文字体（返回 字体名 + 字节）
fn load_cjk_font() -> Option<(&'static str, Vec<u8>)> {
    for path in CJK_CANDIDATES {
        if let Ok(bytes) = std::fs::read(path) {
            let name = path.rsplit(['/', '\\']).next().unwrap_or(path);
            return Some((name, bytes));
        }
    }
    None
}

#[derive(Clone)]
struct FontsApp {
    font_name: String, // 已加载的中文字体名（空 = 没找到）
    dark: bool,
}

impl FontsApp {
    fn new(cc: &eframe::CreationContext<'_>) -> Self {
        let mut font_name = String::new();
        if let Some((name, bytes)) = load_cjk_font() {
            font_name = name.to_owned();

            // ---- FontDefinitions 换血：值是 Arc<FontData>，直接操作两个 map ----
            let mut fonts = egui::FontDefinitions::default();
            fonts.font_data.insert(
                "cjk".into(),
                std::sync::Arc::new(egui::FontData::from_owned(bytes)),
            );
            // insert(0, ..)：插到队首 = 最高优先级；原有拉丁字体垫后做回退
            fonts
                .families
                .entry(egui::FontFamily::Proportional)
                .or_default()
                .insert(0, "cjk".into());
            fonts
                .families
                .entry(egui::FontFamily::Monospace)
                .or_default()
                .push("cjk".into()); // 等宽家族追加在尾部即可
            cc.egui_ctx.set_fonts(fonts);
        }

        // 主题也可以在创建期就定（默认跟随系统）
        cc.egui_ctx.set_visuals(egui::Visuals::dark());
        Self {
            font_name,
            dark: true,
        }
    }

    fn ui_body(ui: &mut egui::Ui, app: &mut FontsApp) {
        egui::CentralPanel::default().show(ui, |ui| {
            ui.heading("中文字体与主题");
            ui.label(format!(
                "已加载：{}",
                if app.font_name.is_empty() {
                    "（未找到系统字体）"
                } else {
                    &app.font_name
                }
            ));
            ui.label("天地玄黄，宇宙洪荒。0123 ABC。—— 中文不再是豆腐块");

            ui.separator();

            // ---- 主题切换：set_visuals 立即生效 ----
            if ui
                .button(if app.dark {
                    "切换到亮色"
                } else {
                    "切换到暗色"
                })
                .clicked()
            {
                app.dark = !app.dark;
                ui.ctx().set_visuals(if app.dark {
                    egui::Visuals::dark()
                } else {
                    egui::Visuals::light()
                });
            }

            // ---- 样式微调：spacing 是每帧可改的普通数据 ----
            ui.add_space(8.0);
            ui.horizontal(|ui| {
                let style = ui.style_mut();
                style.spacing.item_spacing = egui::vec2(14.0, 10.0);
                // 0.36.2 字段名是 corner_radius（github master 已改名 rounding，未发布）
                style.visuals.widgets.inactive.corner_radius = egui::CornerRadius::same(12);
            });
            let _ = ui.button("圆角加宽间距的按钮");
            ui.small("small 字号");
        });
    }
}

impl eframe::App for FontsApp {
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
        viewport: egui::ViewportBuilder::default().with_inner_size([420.0, 320.0]),
        ..Default::default()
    };
    eframe::run_native(
        "07_egui_fonts",
        options,
        Box::new(|cc| Ok(Box::new(FontsApp::new(cc)))),
    )
}

/// 无头自检：中文字体已注册（中文标签能进树且整形不 panic）、
/// 主题切换真实生效。
fn selftest_body() -> FontsApp {
    use egui_kittest::kittest::Queryable;

    let mut harness = egui_kittest::Harness::builder().build_eframe(|cc| FontsApp::new(cc));
    harness.run();

    // 中文标签能查到 == 字体注册成功（否则 MissingGlyphPolicy::Panic 早就炸了）
    assert!(
        harness.query_by_label("中文字体与主题").is_some(),
        "中文字体未加载：UI 含中文但无 CJK 字形"
    );

    // 切到亮色
    let app_before = harness.state().clone();
    assert!(app_before.dark);
    let btn_label = if app_before.dark {
        "切换到亮色"
    } else {
        "切换到暗色"
    };
    harness.get_by_label(btn_label).click();
    harness.run();

    // 主题已翻转的可观察证据：按钮文案换成了反向邀请
    assert!(
        harness.query_by_label("切换到暗色").is_some(),
        "切到亮色后按钮应显示『切换到暗色』"
    );

    harness.state().clone()
}

fn run_selftest() {
    println!("==== 07 egui 中文字体与主题 开始 ====");
    let app = selftest_body();
    println!("font={} dark={}", app.font_name, app.dark);
    println!("==== 07 egui 中文字体与主题 结束 ====");
}

#[cfg(test)]
mod tests {
    #[test]
    fn chinese_labels_reachable_and_theme_toggles() {
        let app = super::selftest_body();
        assert!(!app.font_name.is_empty(), "本机应能找到系统中文字体");
        assert!(!app.dark);
    }
}
