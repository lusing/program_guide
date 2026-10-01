// ============================================================
// 34_ratatui_widgets —— 控件全集与样式系统
//
// 读法：
//   1. 文本三层：Span（带样式片段）→ Line → Text；String/&str 也
//      impl Widget（直接 render）。
//   2. 有状态控件（List）走 render_stateful_widget + ListState——
//      StatefulWidget 是独立 trait，忘用就永远没有选中态。
//   3. 样式：Style/Stylize 链式（.fg/.bg/.bold/.crossed_out）三层
//      patch 合成（widget < item < span）；主题 = 集中定义的样式结构体
//      （demo2/theme.rs 的做法）。
//   4. 无头断言两面：整行断言（样式随期望行写进 Span::styled）与
//      cell 级抽查（buffer().cell(pos).style() 的 fg/modifier）。
//
// 【坑】Paragraph::scroll 参数是 (y, x)——先纵后横，写反是经典坑。
//
// 官方参考：https://ratatui.rs/widgets/overview/
// ============================================================

use ratatui::{
    Frame,
    crossterm::event::{self, KeyCode, KeyEvent, KeyEventKind},
    layout::{Constraint, Layout},
    style::{Color, Style},
    text::{Line, Span},
    widgets::{Block, Gauge, HighlightSpacing, List, ListItem, ListState, Paragraph, Tabs},
};
use std::io::IsTerminal;

/// 主题：集中定义、全局引用（demo2/theme.rs 的结构体做法）。
struct Theme {
    accent: Color,
    done: Color,
}

impl Theme {
    const fn new() -> Self {
        Self {
            accent: Color::Blue,
            done: Color::Green,
        }
    }
}

struct App {
    quit: bool,
    items: Vec<(String, bool)>, // (文本, 完成)
    state: ListState,           // 选中态住在 state，不住 List
    tab: usize,
}

impl App {
    fn new() -> Self {
        let mut state = ListState::default();
        state.select(Some(0));
        Self {
            quit: false,
            items: vec![
                ("读 ratatui 章节".into(), true),
                ("写第五个实战".into(), false),
                ("对照四框架".into(), false),
            ],
            state,
            tab: 0,
        }
    }

    /// 行渲染：完成项划线变灰（Modifier::CROSSED_OUT——37 章待办复用）。
    fn row_line(theme: &Theme, (text, done): &(String, bool)) -> Line<'static> {
        if *done {
            Line::from(Span::styled(
                text.clone(),
                Style::new().fg(theme.done).crossed_out().dim(),
            ))
        } else {
            Line::from(text.clone())
        }
    }
}

fn handle_key(app: &mut App, key: KeyEvent) {
    if key.kind != KeyEventKind::Press {
        return;
    }
    let len = app.items.len();
    match key.code {
        KeyCode::Char('q') => app.quit = true,
        KeyCode::Char('j') => app
            .state
            .select(app.state.selected().map(|i| (i + 1) % len)),
        KeyCode::Char('k') => {
            app.state
                .select(app.state.selected().map(|i| (i + len - 1) % len));
        }
        KeyCode::Char(' ') => {
            if let Some(i) = app.state.selected() {
                app.items[i].1 = !app.items[i].1;
            }
        }
        KeyCode::Tab => app.tab = (app.tab + 1) % 2,
        _ => {}
    }
}

fn render(frame: &mut Frame, app: &mut App) {
    let theme = Theme::new();
    let area = frame.area();
    let [tabs, list, gauge, hint] = area.layout(&Layout::vertical([
        Constraint::Length(3),
        Constraint::Fill(1),
        Constraint::Length(3),
        Constraint::Length(1),
    ]));

    frame.render_widget(
        Tabs::new(vec!["清单", "关于"])
            .select(app.tab)
            .highlight_style(Style::new().fg(theme.accent).bold()),
        tabs.inner(ratatui::layout::Margin::new(1, 1)),
    );

    // 有状态控件：render_stateful_widget + &mut ListState
    let rows: Vec<ListItem> = app
        .items
        .iter()
        .map(|it| ListItem::new(App::row_line(&theme, it)))
        .collect();
    frame.render_stateful_widget(
        List::new(rows)
            .block(Block::bordered().title("清单：j/k 移动 · 空格勾选"))
            .highlight_symbol("> ")
            .highlight_style(Style::new().fg(theme.accent).bold())
            .highlight_spacing(HighlightSpacing::Always),
        list,
        &mut app.state,
    );

    let done = app.items.iter().filter(|(_, d)| *d).count();
    frame.render_widget(
        Gauge::default()
            .percent(done as u16 * 100 / app.items.len() as u16)
            .gauge_style(Style::new().fg(theme.accent))
            .label("完成度"),
        gauge,
    );
    frame.render_widget(Paragraph::new("Tab 换页 · q 退出"), hint);
}

fn main() -> std::io::Result<()> {
    if std::env::args().nth(1).is_some_and(|a| a == "--selftest") {
        run_selftest();
        return Ok(());
    }
    if !std::io::stdout().is_terminal() {
        println!("34 ratatui widgets：请在真终端运行（cargo run）");
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

/// 无头自检：四个 widget 场景各自独立断言（TestBackend + cell 级抽查）。
fn selftest_body() -> String {
    use ratatui::{Terminal, backend::TestBackend};
    let theme = Theme::new();

    // a) List：j 移动后高亮符号跟随；完成行带 crossed_out + dim
    // 布局（30x12）：Tabs y0-2 / List y3-7（边框，内容 y4-6）/ Gauge y8-10 / hint y11
    let mut terminal = Terminal::new(TestBackend::new(30, 12)).expect("TestBackend");
    let mut app = App::new();
    handle_key(&mut app, KeyEvent::from(KeyCode::Char('j'))); // 选中 1
    terminal
        .draw(|frame| render(frame, &mut app))
        .expect("draw");
    let buf = terminal.backend().buffer();
    // j 之后选中 1 → "> " 高亮符号到第二项（y=5），第一项行（y=4）是空
    assert_eq!(
        buf.cell((1u16, 5u16)).map(|c| c.symbol()).unwrap_or("?"),
        ">",
        "j 之后高亮符号应到第二行"
    );
    assert_eq!(
        buf.cell((1u16, 4u16)).map(|c| c.symbol()).unwrap_or("?"),
        " "
    );
    // 第 0 行（完成项）样式抽查：crossed_out + dim + fg 绿
    let s = buf.cell((3u16, 4u16)).map(|c| c.style()).unwrap();
    assert!(
        s.add_modifier
            .contains(ratatui::style::Modifier::CROSSED_OUT)
    );
    assert!(s.add_modifier.contains(ratatui::style::Modifier::DIM));
    assert_eq!(s.fg, Some(theme.done), "主题色应染到完成行");

    // b) Gauge：3 项 1 完成 → 33%；断言行内含块字符（y=9 是 Gauge 中线）
    let gauge_row: String = (0..30u16)
        .filter_map(|x| buf.cell((x, 9u16)).map(|c| c.symbol().to_string()))
        .collect();
    assert!(
        gauge_row.contains('█') || gauge_row.contains('▉'),
        "Gauge 应有块字符：{gauge_row}"
    );

    // c) Paragraph.scroll 是 (y, x)：滚 1 行后首行消失
    let mut t2 = Terminal::new(TestBackend::new(20, 3)).expect("TestBackend");
    t2.draw(|f| {
        let p = Paragraph::new(vec![Line::from("第一行"), Line::from("第二行")]).scroll((1, 0));
        f.render_widget(p, f.area());
    })
    .expect("draw");
    t2.backend().assert_buffer_lines([
        "第二行              ",
        "                    ",
        "                    ",
    ]);

    // d) Tabs 高亮断言用扫描法（与 padding/divider 位置无关）：
    //    主题色染到的字符应恰是选中标签那一个
    handle_key(&mut app, KeyEvent::from(KeyCode::Tab));
    let tab_highlight = |sel: char| -> (String, bool) {
        let mut t = Terminal::new(TestBackend::new(20, 3)).expect("TestBackend");
        let tabs = Tabs::new(vec!["A", "B"])
            .select(if sel == 'B' { 1 } else { 0 })
            .highlight_style(Style::new().fg(theme.accent).bold());
        t.draw(|f| f.render_widget(tabs, f.area())).expect("draw");
        let buf = t.backend().buffer();
        let mut symbols = String::new();
        let mut all_bold = true;
        for x in 0..20u16 {
            let Some(cell) = buf.cell((x, 0)) else {
                continue;
            };
            let s = cell.style();
            if s.fg == Some(theme.accent) {
                symbols.push_str(cell.symbol());
                all_bold &= s.add_modifier.contains(ratatui::style::Modifier::BOLD);
            }
        }
        (symbols, all_bold)
    };
    let (sym, bold) = tab_highlight('B');
    assert_eq!(sym, "B", "选中 B 时主题色只应染到 B 本身：{sym:?}");
    assert!(bold, "选中标签应加粗");
    let (sym0, _) = tab_highlight('A');
    assert_eq!(sym0, "A", "选中 A 时染 A");

    "list-j=>row1 style-done=ok gauge=33% scroll=(1,0) tabs=hl+bold".to_string()
}

fn run_selftest() {
    println!("==== 34 ratatui 控件与样式 开始 ====");
    let evidence = selftest_body();
    println!("{evidence}");
    println!("==== 34 ratatui 控件与样式 结束 ====");
}

#[cfg(test)]
mod tests {
    #[test]
    fn widgets_and_styles() {
        let s = super::selftest_body();
        assert_eq!(
            s,
            "list-j=>row1 style-done=ok gauge=33% scroll=(1,0) tabs=hl+bold"
        );
    }
}
