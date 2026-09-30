// ============================================================
// 04_egui_layout —— 统一 Panel 体系、面板嵌套与 Grid
//
// 读法：
//   1. 0.34 起 SidePanel/TopBottomPanel 合并为统一 egui::Panel：
//      Panel::left(id_salt).resizable(..).default_size(..).show(ui, ..)
//      —— show 的第一个参数是 Ui，不再是 Context。
//   2. 面板顺序 = 声明顺序：先 show 的先分走空间（外层），
//      CentralPanel 永远最后（吃掉剩余全部）。
//   3. 两遍布局（sizing pass）：Grid 等控件首帧先量尺寸再真正布局，
//      无头断言必须在 harness.run() 之后做。
//
// 官方参考：https://docs.rs/egui/latest/egui/
// ============================================================

#[derive(Clone, Default)]
struct LayoutApp {
    side_open: bool,
    show_grid: bool,
    selected: Option<usize>,
}

impl LayoutApp {
    fn new() -> Self {
        Self {
            side_open: true,
            show_grid: true,
            selected: None,
        }
    }

    fn ui_body(ui: &mut egui::Ui, app: &mut LayoutApp) {
        // ---- 顶栏：先声明，横向铺满，从父矩形顶部切走一条 ----
        egui::Panel::top("top-bar")
            .exact_size(36.0)
            .show_separator_line(true)
            .show(ui, |ui| {
                ui.horizontal_centered(|ui| {
                    if ui.button("Toggle side").clicked() {
                        app.side_open = !app.side_open;
                    }
                    ui.checkbox(&mut app.show_grid, "Grid");
                });
            });

        // ---- 底栏：第二个声明，贴底部（注意它排在 left 之前 → 更外层）----
        egui::Panel::bottom("status-bar")
            .exact_size(28.0)
            .show(ui, |ui| {
                ui.horizontal(|ui| {
                    ui.label(format!(
                        "selected = {}",
                        match app.selected {
                            Some(i) => format!("item {i}"),
                            None => "none".to_owned(),
                        }
                    ));
                });
            });

        // ---- 左侧栏：可拖拽调宽；id_salt 只需在同一父 Ui 内唯一 ----
        if app.side_open {
            egui::Panel::left("side")
                .resizable(true)
                .default_size(150.0)
                .min_size(100.0)
                .show(ui, |ui| {
                    ui.heading("Side");
                    for i in 0..6 {
                        ui.selectable_value(&mut app.selected, Some(i), format!("Item {i}"));
                    }
                });
        }

        // ---- 中央区：永远最后声明 ----
        egui::CentralPanel::default().show(ui, |ui| {
            if app.show_grid {
                // Grid：两遍布局的代表——首帧 sizing，次帧定宽
                egui::Grid::new("demo-grid")
                    .num_columns(3)
                    .striped(true)
                    .show(ui, |ui| {
                        for r in 0..3 {
                            for c in 0..3 {
                                ui.label(format!("cell {r}-{c}"));
                            }
                            ui.end_row();
                        }
                    });
            } else {
                ui.label("Center (grid off)");
            }
        });
    }
}

impl eframe::App for LayoutApp {
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
        viewport: egui::ViewportBuilder::default().with_inner_size([480.0, 360.0]),
        ..Default::default()
    };
    eframe::run_native(
        "04_egui_layout",
        options,
        Box::new(|_cc| Ok(Box::new(LayoutApp::new()))),
    )
}

/// 无头自检：面板开合、选中联动、Grid 开关都真实走一遍。
fn selftest_body() -> LayoutApp {
    use egui_kittest::kittest::Queryable;

    let mut harness = egui_kittest::Harness::builder().build_eframe(|_cc| LayoutApp::new());
    harness.run(); // Grid 的 sizing pass 完成后再断言

    // Grid 已出现：9 个 cell（用 label_contains 前缀匹配）
    let cells = harness
        .get_all_by_label_contains("cell ")
        .collect::<Vec<_>>()
        .len();
    assert_eq!(cells, 9, "3x3 Grid 应有 9 个单元格");

    // 侧栏在左：Item 0 的左边缘应落在默认宽度 150 之内（面板真被切出去了）
    let item0 = harness.get_by_label("Item 0");
    assert!(
        item0.rect().left() < 150.0,
        "左面板默认 150px，Item 0 应在其中（实际 left={}）",
        item0.rect().left()
    );

    // 选中 Item 2 → 底栏状态联动
    harness.get_by_label("Item 2").click();
    harness.run();
    assert!(harness.query_by_label("selected = item 2").is_some());

    // 收起侧栏 → Item 全部消失，中央区吃满
    harness.get_by_label("Toggle side").click();
    harness.run();
    assert!(harness.query_by_label("Item 0").is_none(), "侧栏应收起");

    // 关掉 Grid → 中央区切换到占位文本
    harness.get_by_label("Grid").click();
    harness.run();
    assert!(harness.query_by_label("Center (grid off)").is_some());

    harness.state().clone()
}

fn run_selftest() {
    println!("==== 04 egui 布局与面板 开始 ====");
    let app = selftest_body();
    println!(
        "side_open={} show_grid={} selected={:?}",
        app.side_open, app.show_grid, app.selected
    );
    assert!(!app.side_open && !app.show_grid);
    assert_eq!(app.selected, Some(2));
    println!("==== 04 egui 布局与面板 结束 ====");
}

#[cfg(test)]
mod tests {
    #[test]
    fn panel_toggles_flow() {
        let app = super::selftest_body();
        assert_eq!(
            (app.side_open, app.show_grid, app.selected),
            (false, false, Some(2))
        );
    }
}
