// ============================================================
// 37_ratatui_app —— Ratatui 综合实战：待办管理器（第五份同规格实现）
//
// 与 09（egui）/16（iced）/23（Slint）/30（GTK4）同一张考卷，六条规格：
//   列表显示 / 文本输入添加 / 勾选完成 / 删除条目 / 滚动列表 /
//   特色亮点（ANSI 样式完成态 + 完成趋势 Sparkline）。
//
// 读法：
//   1. TUI 键位状态机：Mode::{Normal, Insert}——同键双义（Normal 的 a
//      是命令、Insert 的 a 是文本），漏模式判断是最常见 bug。
//   2. 完成态 = Modifier::CROSSED_OUT + dim + 主题绿（34 章手法）；
//      趋势 = 每次变更记一笔的 Sparkline（35 章手法）。
//   3. 无头剧本与四份前卷同构：种子 → 勾选 → 输入添加 → 删除 →
//      边界 clamp → 样式断言，全部机器判卷。
//
// 【坑】删除选中项后 ListState 要 clamp——select 越界渲染会异常。
//
// 官方参考：examples/apps/todo-list（键位风格同源）
// ============================================================

use ratatui::{
    Frame,
    crossterm::event::{self, KeyCode, KeyEvent, KeyEventKind},
    layout::{Constraint, Layout},
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{Block, List, ListItem, ListState, Paragraph, Sparkline},
};
use std::io::IsTerminal;

#[derive(Debug, PartialEq)]
enum Mode {
    Normal,
    Insert,
}

struct App {
    quit: bool,
    mode: Mode,
    items: Vec<(String, bool)>,
    state: ListState,
    input: String,
    trend: Vec<u64>, // 完成数历史（每次变更记一笔）
}

impl App {
    fn new() -> Self {
        let mut state = ListState::default();
        state.select(Some(0));
        let mut app = Self {
            quit: false,
            mode: Mode::Normal,
            items: vec![
                ("读 ratatui 章节".into(), true),
                ("写第五个实战".into(), false),
            ],
            state,
            input: String::new(),
            trend: vec![1], // 初始完成 1
        };
        app.clamp_select();
        app
    }

    fn done_count(&self) -> u64 {
        self.items.iter().filter(|(_, d)| *d).count() as u64
    }

    fn record(&mut self) {
        self.trend.push(self.done_count());
    }

    /// 删除后选中索引 clamp（select 越界是渲染异常的源头）。
    fn clamp_select(&mut self) {
        if self.items.is_empty() {
            self.state.select(None);
        } else if self.state.selected().is_none_or(|i| i >= self.items.len()) {
            self.state.select(Some(self.items.len() - 1));
        }
    }
}

fn handle_key(app: &mut App, key: KeyEvent) {
    if key.kind != KeyEventKind::Press {
        return;
    }
    match (&app.mode, key.code) {
        (Mode::Insert, KeyCode::Char(c)) => app.input.push(c),
        (Mode::Insert, KeyCode::Backspace) => {
            app.input.pop();
        }
        (Mode::Insert, KeyCode::Enter) => {
            let text = app.input.trim().to_string();
            if !text.is_empty() {
                app.items.push((text, false));
                app.state.select(Some(app.items.len() - 1));
                app.record();
            }
            app.input.clear();
            app.mode = Mode::Normal;
        }
        (Mode::Insert, KeyCode::Esc) => {
            app.input.clear();
            app.mode = Mode::Normal;
        }
        (Mode::Normal, KeyCode::Char('q')) => app.quit = true,
        (Mode::Normal, KeyCode::Char('j')) => {
            if let Some(i) = app.state.selected() {
                let next = (i + 1).min(app.items.len().saturating_sub(1));
                app.state.select(Some(next));
            }
        }
        (Mode::Normal, KeyCode::Char('k')) => {
            if let Some(i) = app.state.selected() {
                app.state.select(Some(i.saturating_sub(1)));
            }
        }
        (Mode::Normal, KeyCode::Char(' ')) => {
            if let Some(i) = app.state.selected() {
                app.items[i].1 = !app.items[i].1;
                app.record();
            }
        }
        (Mode::Normal, KeyCode::Char('d')) => {
            if app.state.selected().is_some() {
                app.items.remove(app.state.selected().unwrap());
                app.clamp_select();
                app.record();
            }
        }
        (Mode::Normal, KeyCode::Char('a')) => app.mode = Mode::Insert,
        _ => {}
    }
}

fn render(frame: &mut Frame, app: &mut App) {
    let area = frame.area();
    let [stats, list, input, spark, hint] = area.layout(&Layout::vertical([
        Constraint::Length(1),
        Constraint::Fill(1),
        Constraint::Length(3),
        Constraint::Length(3),
        Constraint::Length(1),
    ]));

    frame.render_widget(
        Paragraph::new(Line::from(format!(
            "待办 · 已完成 {}/{}",
            app.done_count(),
            app.items.len()
        ))),
        stats,
    );

    let rows: Vec<ListItem> = app
        .items
        .iter()
        .map(|(text, done)| {
            if *done {
                ListItem::new(Line::from(Span::styled(
                    text.clone(),
                    Style::new()
                        .fg(Color::Green)
                        .add_modifier(Modifier::CROSSED_OUT | Modifier::DIM),
                )))
            } else {
                ListItem::new(text.clone())
            }
        })
        .collect();
    frame.render_stateful_widget(
        List::new(rows)
            .block(Block::bordered().title("j/k 移动 · 空格勾选 · d 删 · a 添加"))
            .highlight_symbol("> ")
            .highlight_style(Style::new().fg(Color::Blue).bold()),
        list,
        &mut app.state,
    );

    // 输入行：Insert 模式蓝框高亮，普通模式灰框
    let border = if app.mode == Mode::Insert {
        Style::new().fg(Color::Blue)
    } else {
        Style::new().fg(Color::DarkGray)
    };
    frame.render_widget(
        Paragraph::new(app.input.clone()).block(Block::bordered().title("输入").style(border)),
        input,
    );

    frame.render_widget(
        Sparkline::default()
            .data(&app.trend)
            .style(Style::new().fg(Color::Cyan))
            .block(Block::bordered().title("完成趋势")),
        spark,
    );
    frame.render_widget(
        Paragraph::new(match app.mode {
            Mode::Normal => "q 退出",
            Mode::Insert => "Enter 提交 · Esc 取消",
        }),
        hint,
    );
}

fn main() -> std::io::Result<()> {
    if std::env::args().nth(1).is_some_and(|a| a == "--selftest") {
        run_selftest();
        return Ok(());
    }
    if !std::io::stdout().is_terminal() {
        println!("37 ratatui app：请在真终端运行（cargo run）");
        return Ok(());
    }
    let mut app = App::new();
    ratatui::run(|terminal| -> std::io::Result<()> {
        while !app.quit {
            terminal.draw(|frame| render(frame, &mut app))?;
            if event::poll(std::time::Duration::from_millis(250))?
                && let Some(key) = event::read()?.as_key_press_event()
            {
                handle_key(&mut app, key);
            }
        }
        Ok(())
    })
}

/// 无头自检（与 09/16/23/30 同卷）：种子 → 勾选 → 输入添加 → 删除 →
/// 边界 clamp → 完成态样式 → 趋势。
fn selftest_body() -> String {
    use ratatui::{Terminal, backend::TestBackend};

    let mut app = App::new();
    assert_eq!((app.items.len(), app.done_count()), (2, 1));

    // j 到第 2 项 → 勾选：完成 2，趋势记一笔
    handle_key(&mut app, KeyEvent::from(KeyCode::Char('j')));
    handle_key(&mut app, KeyEvent::from(KeyCode::Char(' ')));
    assert_eq!(app.done_count(), 2);
    assert_eq!(*app.trend.last().unwrap(), 2);

    // 输入模式：逐字符（同键双义——Insert 里 'a' 是文本不是命令）
    handle_key(&mut app, KeyEvent::from(KeyCode::Char('a')));
    for c in "对照五框架".chars() {
        handle_key(&mut app, KeyEvent::from(KeyCode::Char(c)));
    }
    handle_key(&mut app, KeyEvent::from(KeyCode::Enter));
    assert_eq!(app.items.len(), 3, "Insert 输入后提交");
    assert_eq!(app.items.last().unwrap().0, "对照五框架");
    assert_eq!(app.mode, Mode::Normal);

    // 删除第 3 项 → clamp 回最后一项
    handle_key(&mut app, KeyEvent::from(KeyCode::Char('d')));
    assert_eq!(app.items.len(), 2);
    assert_eq!(app.state.selected(), Some(1), "删除后 clamp 到最后一项");

    // 边界：k 到顶再 k 不越界；j 到底再 j 不越界
    handle_key(&mut app, KeyEvent::from(KeyCode::Char('k')));
    handle_key(&mut app, KeyEvent::from(KeyCode::Char('k')));
    assert_eq!(app.state.selected(), Some(0));
    handle_key(&mut app, KeyEvent::from(KeyCode::Char('j')));
    handle_key(&mut app, KeyEvent::from(KeyCode::Char('j')));
    handle_key(&mut app, KeyEvent::from(KeyCode::Char('j')));
    assert_eq!(app.state.selected(), Some(1), "j 到底 clamp");

    // 渲染断言：完成行样式 + 统计行 + 高亮符
    let mut terminal = Terminal::new(TestBackend::new(40, 14)).expect("TestBackend");
    terminal
        .draw(|frame| render(frame, &mut app))
        .expect("draw");
    let buf = terminal.backend().buffer();
    let stats: String = (0..40u16)
        .filter_map(|x| buf.cell((x, 0)).map(|c| c.symbol().to_string()))
        .collect();
    assert!(
        stats.contains('2') && stats.contains('待'),
        "统计行：{stats}"
    );
    // 完成行样式断言用扫描法（不赌具体坐标）：buffer 里应存在
    // CROSSED_OUT + 主题绿的 cell（完成项文字），且 "> " 高亮符在第 2 项行
    let mut has_done_style = false;
    let mut highlight_row: Option<u16> = None;
    for y in 0..14u16 {
        for x in 0..40u16 {
            let Some(c) = buf.cell((x, y)) else { continue };
            let s = c.style();
            if s.add_modifier.contains(Modifier::CROSSED_OUT) && s.fg == Some(Color::Green) {
                has_done_style = true;
            }
            if c.symbol() == ">" {
                highlight_row = Some(y);
            }
        }
    }
    assert!(has_done_style, "完成行应划线+绿");
    assert!(highlight_row.is_some(), "选中项应有 > 高亮符");

    handle_key(&mut app, KeyEvent::from(KeyCode::Char('q')));
    assert!(app.quit);

    format!(
        "items=2 done=2 trend={} clamp=ok crossed-out=ok",
        app.trend.len()
    )
}

fn run_selftest() {
    println!("==== 37 ratatui 待办管理器 开始 ====");
    let evidence = selftest_body();
    println!("{evidence}");
    println!("==== 37 ratatui 待办管理器 结束 ====");
}

#[cfg(test)]
mod tests {
    #[test]
    fn todo_fifth_impl() {
        let s = super::selftest_body();
        assert!(s.starts_with("items=2 done=2"), "断言在 body 内完成");
        assert!(s.ends_with("clamp=ok crossed-out=ok"));
    }
}
