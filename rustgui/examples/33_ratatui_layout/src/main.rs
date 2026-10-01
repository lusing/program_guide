// ============================================================
// 33_ratatui_layout —— 约束求解布局：Constraint 全家与 Flex
//
// 读法：
//   1. ratatui 的布局是 cassowary 约束求解：声明"我要什么"
//      （Length/Min/Max/Percentage/Ratio/Fill），求解器算"摆哪里"——
//      第五种布局答案（对照 egui Panel 谈判/iced Length/Slint 布局盒/
//      GTK 容器）。
//   2. Flex 是多余空间的分配策略（Legacy/Start/End/Center/SpaceBetween/
//      SpaceAround/SpaceEvenly），'f' 键真终端轮换观察。
//   3. 两种分割写法：Layout::split（返回 Rc<[Rect]>）与
//      area.layout::<N>(&layout)（新，const 泛型——数量不匹配编译期炸）。
//   4. popup = Clear（先清底层像素）+ Rect::centered 居中矩形：'p' 切换。
//
// 【坑】Flex::SpaceAround 的语义在 0.30 变了（中间 spacer 是两端的
//      两倍，旧观感改用 SpaceEvenly）——老教程截图对不上。
//
// 官方参考：https://ratatui.rs/concepts/layout/
// ============================================================

use ratatui::{
    Frame,
    crossterm::event::{self, KeyCode, KeyEvent, KeyEventKind},
    layout::{Constraint, Flex, Layout, Margin, Position},
    text::Line,
    widgets::{Block, Clear, Paragraph},
};
use std::io::IsTerminal;

const FLEXES: [(&str, Flex); 7] = [
    ("Legacy", Flex::Legacy),
    ("Start", Flex::Start),
    ("End", Flex::End),
    ("Center", Flex::Center),
    ("SpaceBetween", Flex::SpaceBetween),
    ("SpaceAround", Flex::SpaceAround),
    ("SpaceEvenly", Flex::SpaceEvenly),
];

struct App {
    quit: bool,
    flex_index: usize,
    popup: bool,
}

impl App {
    fn new() -> Self {
        Self {
            quit: false,
            flex_index: 1,
            popup: false,
        } // 默认 Start
    }
}

/// 键处理纯函数（真终端与无头共用）：f 轮换 Flex、p 切弹层、q 退出。
fn handle_key(app: &mut App, key: KeyEvent) {
    if key.kind != KeyEventKind::Press {
        return;
    }
    match key.code {
        KeyCode::Char('f') => app.flex_index = (app.flex_index + 1) % FLEXES.len(),
        KeyCode::Char('p') => app.popup = !app.popup,
        KeyCode::Char('q') => app.quit = true,
        _ => {}
    }
}

/// 三窗格骨架：标题(3) / 主体(Fill) / 状态栏(1)；主体水平两块 + 可选弹层。
fn render(frame: &mut Frame, app: &App) {
    let area = frame.area();
    // 新式分割：area.layout::<N>(&layout) 直接解构成 N 元数组
    // （split 返回 Rc<[Rect]>，try_into 数组在 0.30 编不过）
    let [title, body, status] = area.layout(&Layout::vertical([
        Constraint::Length(3),
        Constraint::Fill(1),
        Constraint::Length(1),
    ]));

    frame.render_widget(
        Paragraph::new(Line::from("布局演练：f 换 Flex · p 弹层 · q 退出")),
        title,
    );

    let (name, flex) = FLEXES[app.flex_index];
    let [left, right] = body
        .layout(&Layout::horizontal([Constraint::Length(16), Constraint::Length(12)]).flex(flex));
    frame.render_widget(Block::bordered().title("左 16"), left);
    frame.render_widget(Block::bordered().title(format!("右 12 · {name}")), right);
    frame.render_widget(Paragraph::new("状态栏"), status);

    // popup：Clear 清掉底层再画——顺序反了内容会"透"出来
    if app.popup {
        let popup = area.centered(Constraint::Percentage(60), Constraint::Percentage(30));
        frame.render_widget(Clear, popup);
        frame.render_widget(Block::bordered().title("弹出层"), popup);
        let inner = popup.inner(Margin::new(2, 2));
        frame.render_widget(Paragraph::new("按 p 关闭弹层"), inner);
    }
}

fn main() -> std::io::Result<()> {
    if std::env::args().nth(1).is_some_and(|a| a == "--selftest") {
        run_selftest();
        return Ok(());
    }
    if !std::io::stdout().is_terminal() {
        println!("33 ratatui layout：请在真终端运行（cargo run）");
        return Ok(());
    }
    let mut app = App::new();
    ratatui::run(|terminal| -> std::io::Result<()> {
        while !app.quit {
            terminal.draw(|frame| render(frame, &app))?;
            if event::poll(std::time::Duration::from_millis(250))?
                && let Some(key) = event::read()?.as_key_press_event()
            {
                handle_key(&mut app, key); // as_key_press_event 返回值（KeyEvent 是 Copy）
            }
        }
        Ok(())
    })
}

/// 无头自检：
///   a) Flex 矩阵：同一对 Length(16)+Length(12) 在 40 宽终端的 7 种 Flex
///      下，左右两块边框之间的间隙列数逐个实测（间隙分布随 Flex 变化）；
///   b) popup：Clear 清底层 + 60% 宽居中弹层的边框角坐标断言。
fn selftest_body() -> String {
    use ratatui::{Terminal, backend::TestBackend};

    // a) Flex 矩阵：body 区域 40x6，找左右块竖边框的列号，间隙 = 列差-1
    let mut evidence = String::from("flex:");
    for (name, flex) in FLEXES {
        let mut terminal = Terminal::new(TestBackend::new(40, 10)).expect("TestBackend");
        terminal
            .draw(|frame| {
                let body = ratatui::layout::Rect {
                    x: 0,
                    y: 3,
                    width: 40,
                    height: 6,
                };
                let [l, r] = body.layout(
                    &Layout::horizontal([Constraint::Length(16), Constraint::Length(12)])
                        .flex(flex),
                );
                frame.render_widget(Block::bordered().title("L"), l);
                frame.render_widget(Block::bordered().title("R"), r);
            })
            .expect("draw");
        let buf = terminal.backend().buffer();
        // 每块 bordered 有两条竖边框：第 1/2 条是左块的左右边框，第 3 条是
        // 右块左边框——间隙 = 第3条 − 第2条 − 1（与两块各自的位置无关）
        let bars = collect_cols(buf, 5, "│", 40, 3);
        assert_eq!(bars.len(), 3, "{name} 应有 3 条竖边框：{bars:?}");
        let gap = bars[2] - bars[1] - 1;
        evidence.push_str(&format!("{name}={gap} "));
    }
    // 40-28=12 列空闲的分配实测：前四种两块紧贴（gap=0，余量在头/尾）；
    // SpaceBetween 全塞中间；SpaceAround 0.30 新语义（中间=两端×2）：3+6+3；
    // SpaceEvenly 三等分 4+4+4
    for (frag, why) in [
        ("Legacy=0 ", "Legacy 两块紧贴"),
        ("Start=0 ", "Start 两块紧贴"),
        ("End=0 ", "End 头部垫空两块仍紧贴"),
        ("Center=0 ", "Center 头尾均分两块仍紧贴"),
        ("SpaceBetween=12 ", "SpaceBetween 全部塞进中间"),
        ("SpaceAround=6 ", "SpaceAround 新语义中间 6（两端各 3）"),
        ("SpaceEvenly=4 ", "SpaceEvenly 三段均分"),
    ] {
        assert!(evidence.contains(frag), "{why}：{evidence}");
    }

    // b) popup：开弹层后 60% 宽居中——(40-24)/2 = 第 8 列左上角
    let mut terminal = Terminal::new(TestBackend::new(40, 10)).expect("TestBackend");
    let mut app = App::new();
    handle_key(&mut app, KeyEvent::from(KeyCode::Char('p')));
    terminal.draw(|frame| render(frame, &app)).expect("draw");
    let buf = terminal.backend().buffer();
    // 宽 60%=24 起 x=8；高 30%=3，居中 (10-3)/2=3.5 → centered 取整到 y=4
    assert_eq!(
        buf.cell(Position { x: 8, y: 4 })
            .map(|c| c.symbol())
            .unwrap_or("?"),
        "┌",
        "60%x30% 居中弹层左上角在 (8,4)——3.5 奇数半行会取整上移"
    );

    format!("{evidence}popup=(8,4)")
}

/// 在 buf 的 row 行收集前 want 个指定符号的列号。
fn collect_cols(
    buf: &ratatui::buffer::Buffer,
    row: u16,
    ch: &str,
    width: u16,
    want: usize,
) -> Vec<u16> {
    let mut out = Vec::with_capacity(want);
    for x in 0..width {
        if buf
            .cell(Position { x, y: row })
            .is_some_and(|c| c.symbol() == ch)
        {
            out.push(x);
            if out.len() == want {
                break;
            }
        }
    }
    out
}

fn run_selftest() {
    println!("==== 33 ratatui 布局 开始 ====");
    let evidence = selftest_body();
    println!("{evidence}");
    println!("==== 33 ratatui 布局 结束 ====");
}

#[cfg(test)]
mod tests {
    #[test]
    fn flex_matrix_and_popup() {
        let s = super::selftest_body();
        assert!(s.starts_with("flex:"), "断言在 body 内完成");
    }
}
