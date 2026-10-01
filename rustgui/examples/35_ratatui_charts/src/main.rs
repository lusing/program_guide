// ============================================================
// 35_ratatui_charts —— 图表与画布：字符即像素
//
// 读法：
//   1. Chart：数据坐标系（Dataset + Axis bounds/labels +
//      GraphType::Line/Scatter + Marker::Dot/Braille/HalfBlock）——
//      braille 一格 2x4 子像素，是 TUI 里最精细的"抗锯齿"。
//   2. BarChart 分类柱状图；Sparkline 轻量趋势条（▁▂▃▄▅▆▇█）。
//   3. Canvas 自绘画布：x_bounds/y_bounds 世界坐标 → 网格映射，
//      ctx.draw(&Points/&Line/&Circle) + ctx.print；y 轴向上、
//      终端行向下——print 要 y 取负翻转。
//   4. 数据一律固定（预计算 sin 表），无头断言天然确定。
//
// 【坑】Axis 不显式 bounds 时按数据范围自动定标——浮点边界微差会让
//      braille 换格、断言必炸：断言图必锁 bounds。
//
// 官方参考：https://ratatui.rs/widgets/chart/ 与 examples/apps/canvas
// ============================================================

use ratatui::{
    Frame,
    crossterm::event::{self, KeyCode, KeyEvent, KeyEventKind},
    layout::{Constraint, Layout},
    style::{Color, Style},
    symbols::Marker,
    widgets::{
        Axis, Bar, BarChart, Block, Chart, Dataset, GraphType, Paragraph,
        canvas::{Canvas, Line, Points},
    },
};
use std::io::IsTerminal;

/// 固定 sin 数据（0..=10，步长 0.25）——确定性数据源，不联网不随机。
fn sin_data() -> Vec<(f64, f64)> {
    (0..=40)
        .map(|i| {
            let x = i as f64 * 0.25;
            (x, (x * 0.9).sin())
        })
        .collect()
}

struct App {
    quit: bool,
}

fn handle_key(app: &mut App, key: KeyEvent) {
    if key.kind == KeyEventKind::Press && key.code == KeyCode::Char('q') {
        app.quit = true;
    }
}

fn render(frame: &mut Frame, _app: &App) {
    let area = frame.area();
    let [chart, bars_area, spark, hint] = area.layout(&Layout::vertical([
        Constraint::Fill(1),
        Constraint::Length(8),
        Constraint::Length(4),
        Constraint::Length(1),
    ]));

    // Chart：显式锁 bounds（断言图的前提）；data 先绑定（临时值借用即释放）
    let data = sin_data();
    let datasets = vec![
        Dataset::default()
            .name("sin")
            .marker(Marker::Braille)
            .graph_type(GraphType::Line)
            .style(Style::new().fg(Color::Blue))
            .data(&data),
    ];
    frame.render_widget(
        Chart::new(datasets)
            .block(Block::bordered().title("Chart：sin（braille）"))
            .x_axis(Axis::default().bounds([0.0, 10.0]).labels(["0", "5", "10"]))
            .y_axis(Axis::default().bounds([-1.0, 1.0]).labels(["-1", "0", "1"])),
        chart,
    );

    // BarChart：三根带中文标签的柱
    let bars = vec![
        Bar::default().label("一").value(6),
        Bar::default().label("二").value(11),
        Bar::default().label("三").value(4),
    ];
    frame.render_widget(
        BarChart::new(bars) // Vec<Bar> 直收（BarGroup 用于分组场景）
            .block(Block::bordered().title("BarChart"))
            .bar_width(5)
            .bar_style(Style::new().fg(Color::Green)),
        bars_area,
    );

    // Sparkline：固定脉冲
    frame.render_widget(
        ratatui::widgets::Sparkline::default()
            .data([3, 8, 5, 12, 6, 9, 2, 7, 10, 4])
            .style(Style::new().fg(Color::Cyan))
            .block(Block::bordered().title("Sparkline")),
        spark,
    );

    frame.render_widget(Paragraph::new("q 退出"), hint);
}

fn main() -> std::io::Result<()> {
    if std::env::args().nth(1).is_some_and(|a| a == "--selftest") {
        run_selftest();
        return Ok(());
    }
    if !std::io::stdout().is_terminal() {
        println!("35 ratatui charts：请在真终端运行（cargo run）");
        return Ok(());
    }
    let mut app = App { quit: false };
    ratatui::run(|terminal| -> std::io::Result<()> {
        while !app.quit {
            terminal.draw(|frame| render(frame, &app))?;
            if event::poll(std::time::Duration::from_millis(250))?
                && let Some(key) = event::read()?.as_key_press_event()
            {
                handle_key(&mut app, key);
            }
        }
        Ok(())
    })
}

/// 无头自检：轴标签整行 + 柱/脉冲特征字符 + Canvas 的 print 文字。
fn selftest_body() -> String {
    use ratatui::{Terminal, backend::TestBackend};

    // a) 整屏 50x24：布局 Chart y0-10 / BarChart y11-18 / Spark y19-22 / hint y23
    let mut terminal = Terminal::new(TestBackend::new(50, 24)).expect("TestBackend");
    let app = App { quit: false };
    terminal.draw(|frame| render(frame, &app)).expect("draw");
    let buf = terminal.backend().buffer();
    let bottom: String = (0..50u16)
        .filter_map(|x| buf.cell((x, 9u16)).map(|c| c.symbol().to_string()))
        .collect();
    assert!(
        bottom.contains('0') && bottom.contains('5'),
        "轴标签行：{bottom}"
    );
    // braille 特征：图表区应出现盲文点阵字符（U+28xx）
    let has_braille = (1..49u16).any(|x| {
        buf.cell((x, 5u16)).is_some_and(|c| {
            c.symbol()
                .chars()
                .next()
                .is_some_and(|ch| ('\u{2800}'..='\u{28FF}').contains(&ch))
        })
    });
    assert!(has_braille, "Chart 应有 braille 点阵");

    // b) BarChart：扫柱底行（y=15 柱体末段，三根柱都在）
    let bar_rows: Vec<String> = (0..50u16)
        .map(|x| {
            buf.cell((x, 15u16))
                .map(|c| c.symbol().to_string())
                .unwrap_or_default()
        })
        .collect();
    let solid = bar_rows
        .iter()
        .filter(|s| s == &"█" || s == &"▇" || s == &"▆")
        .count();
    assert!(solid >= 10, "BarChart 柱底行应有三根柱的块字符：{solid}");

    // c) Canvas：固定线段 + 两点 + print 文字（y 翻转：print 用 -y）
    let mut t2 = Terminal::new(TestBackend::new(30, 8)).expect("TestBackend");
    t2.draw(|f| {
        let canvas = Canvas::default()
            .marker(Marker::Braille)
            .x_bounds([-10.0, 10.0])
            .y_bounds([-5.0, 5.0])
            .paint(|ctx| {
                ctx.draw(&Points {
                    coords: &[(0.0, 0.0), (5.0, 3.0)],
                    color: Color::Red,
                });
                ctx.draw(&Line {
                    // canvas::Line 字段是 x1/y1/x2/y2（起点/终点），不是 x0/y0
                    x1: -8.0,
                    y1: -4.0,
                    x2: 8.0,
                    y2: 4.0,
                    color: Color::Blue,
                });
                ctx.print(0.0, 0.0, "原点");
            });
        f.render_widget(canvas, f.area());
    })
    .expect("draw");
    let cbuf = t2.backend().buffer();
    let mut flat = String::new();
    for y in 0..8u16 {
        for x in 0..30u16 {
            if let Some(c) = cbuf.cell((x, y)) {
                flat.push_str(c.symbol());
            }
        }
    }
    assert!(
        flat.contains('原') && flat.contains('点'),
        "Canvas print 的文字应出现"
    );

    format!("chart-axis=0/5 braille=ok bars-solid={solid} canvas=原点")
}

fn run_selftest() {
    println!("==== 35 ratatui 图表画布 开始 ====");
    let evidence = selftest_body();
    println!("{evidence}");
    println!("==== 35 ratatui 图表画布 结束 ====");
}

#[cfg(test)]
mod tests {
    #[test]
    fn charts_and_canvas() {
        let s = super::selftest_body();
        assert!(
            s.starts_with("chart-axis=0/5 braille=ok"),
            "断言在 body 内完成"
        );
        assert!(s.ends_with("canvas=原点"));
    }
}
