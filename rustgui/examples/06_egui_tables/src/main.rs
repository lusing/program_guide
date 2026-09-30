// ============================================================
// 06_egui_tables —— 虚拟化表格、曲线图与程序化纹理
//
// 读法：
//   1. egui_extras::TableBuilder：大数据量的正解是 body.rows 的
//      "虚拟化"——只布局视口内的行，200 行和 20 万行首帧成本
//      一样（本例 200 行，第 199 行不在视口里就查无此节点）。
//   2. egui_plot 0.36（已迁出主仓库）：Plot + Line 两层，数据是
//      PlotPoints。
//   3. 程序化纹理：ColorImage 逐像素生成 + ctx.load_texture，
//      不需要任何图片资源文件，也就完全可复现。
//
// 官方参考：https://docs.rs/egui_extras / https://docs.rs/egui_plot
// ============================================================

/// 表格行数：多于视口能容纳的数量，演示虚拟化
const N_ROWS: usize = 200;

/// 每行的"业务值"：确定性公式，无随机
fn row_value(i: usize) -> i64 {
    (i as i64 * 7) % 100
}

#[derive(Clone, Default)]
struct TableApp {
    /// 曲线数据（构造一次，渲染只读）
    series: Vec<[f64; 2]>,
    /// 程序化纹理（首帧懒加载）
    texture: Option<egui::TextureHandle>,
}

impl TableApp {
    fn new() -> Self {
        let series = (0..32)
            .map(|i| {
                let x = i as f64 * 0.25;
                [x, (x * 2.0).sin() * 10.0 + x * 1.5]
            })
            .collect();
        Self {
            series,
            texture: None,
        }
    }

    /// 64x64 对角渐变纹理：纯代码生成，零资源文件
    fn gradient_image() -> egui::ColorImage {
        let n = 64_usize;
        // ColorImage 持平铺的像素数组：先算好再构造
        let pixels: Vec<egui::Color32> = (0..n * n)
            .map(|i| {
                let (x, y) = (i % n, i / n);
                let v = ((x + y) * 255 / (2 * n - 2)) as u8;
                egui::Color32::from_rgb(v, 64, 255 - v)
            })
            .collect();
        // source_size：矢量图的建议尺寸（位图填 Vec2::ZERO）
        egui::ColorImage {
            size: [n, n],
            pixels,
            source_size: egui::Vec2::ZERO,
        }
    }

    fn ui_body(ui: &mut egui::Ui, app: &mut TableApp) {
        egui::CentralPanel::default().show(ui, |ui| {
            ui.heading("Data Table");

            // ---- 虚拟化表格 ----
            use egui_extras::{Column, TableBuilder};
            TableBuilder::new(ui)
                .striped(true)
                .resizable(true)
                .min_scrolled_height(160.0)
                .column(Column::exact(70.0))
                .column(Column::remainder())
                .header(24.0, |mut header| {
                    header.col(|ui| {
                        ui.strong("ID");
                    });
                    header.col(|ui| {
                        ui.strong("Value");
                    });
                })
                .body(|body| {
                    // row.col 要 &mut self —— 闭包参数记得 mut
                    body.rows(22.0, N_ROWS, |mut row| {
                        let i = row.index();
                        row.col(|ui| {
                            ui.label(format!("row-{i}"));
                        });
                        row.col(|ui| {
                            ui.label(row_value(i).to_string());
                        });
                    });
                });

            ui.add_space(8.0);

            // ---- 曲线图（egui_plot 0.36）----
            let line = egui_plot::Line::new("sin ramp", app.series.clone());
            egui_plot::Plot::new("series-plot")
                .height(140.0)
                .show(ui, |plot_ui| plot_ui.line(line));

            ui.add_space(8.0);

            // ---- 程序化纹理 ----
            let tex = app
                .texture
                .get_or_insert_with(|| {
                    // 0.36 的 load_texture 三参：名字 + 图 + 采样选项
                    ui.ctx().load_texture(
                        "gradient",
                        Self::gradient_image(),
                        egui::TextureOptions::LINEAR,
                    )
                })
                .clone();
            ui.horizontal(|ui| {
                ui.add(egui::Image::from_texture(&tex).fit_to_exact_size(egui::vec2(64.0, 64.0)));
                ui.label("Procedural texture");
            });
        });
    }
}

impl eframe::App for TableApp {
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
        viewport: egui::ViewportBuilder::default().with_inner_size([520.0, 680.0]),
        ..Default::default()
    };
    eframe::run_native(
        "06_egui_tables",
        options,
        Box::new(|_cc| Ok(Box::new(TableApp::new()))),
    )
}

/// 无头自检：表头/首行存在、虚拟化生效（视口外的行不在树里）、
/// 曲线数据就绪、纹理已生成、图像节点可查。
fn selftest_body() -> TableApp {
    use egui_kittest::kittest::Queryable;

    let mut harness = egui_kittest::Harness::builder().build_eframe(|_cc| TableApp::new());
    harness.run(); // 表格/图的两遍布局 settling

    // 表头与首行
    assert!(harness.query_by_label("ID").is_some());
    assert!(harness.query_by_label("Value").is_some());
    assert!(harness.query_by_label("row-0").is_some(), "首行应在视口内");
    assert!(harness.query_by_label("0").is_some(), "row-0 的值 0 应可见");

    // 虚拟化证据：第 199 行远在视口外，无障碍树里查无此节点
    assert!(
        harness.query_by_label("row-199").is_none(),
        "虚拟化生效：视口外的行不应被布局"
    );

    // 图像节点存在（Role::Image）
    let images = harness
        .get_all_by_role(egui::accesskit::Role::Image)
        .count();
    assert!(images >= 1, "应有至少一个图像节点");

    let app = harness.state().clone();
    assert_eq!(app.series.len(), 32, "曲线应有 32 个点");
    assert!(app.texture.is_some(), "程序化纹理应已懒加载");
    app
}

fn run_selftest() {
    println!("==== 06 egui 表格与曲线 开始 ====");
    let app = selftest_body();
    println!("rows={} series={} texture=loaded", N_ROWS, app.series.len());
    println!("row 7 value = {}", row_value(7));
    println!("==== 06 egui 表格与曲线 结束 ====");
}

#[cfg(test)]
mod tests {
    #[test]
    fn table_virtualized_and_series_ready() {
        let app = super::selftest_body();
        assert_eq!(app.series.len(), 32);
        assert!(app.texture.is_some());
    }
}
