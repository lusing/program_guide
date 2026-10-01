// ============================================================
// 36_ratatui_async —— EventStream 与 tokio::select 异步腿
//
// 读法：
//   1. TUI 主循环天然 async 友好：帧时钟 + 键盘事件 + 数据流三路
//      消息用 tokio::select! 多路复用（官方 async-github 同款骨架，
//      数据源换本地模拟——零联网）。
//   2. 可测纯核：一切状态变迁收进 step(app, Msg) -> bool 纯函数——
//      selftest 腿零 async（消息序列是常量数组），#[tokio::test] 腿
//      才碰真异步壳（先 send 后 recv，无竞争窗口）。
//   3. EventStream 只准出现在真终端 run() 里——无 tty 环境行为不定。
//
// 【坑】event-stream 是 crossterm 的 feature 不是 ratatui 的；版本必须
//      钉 0.29 与 ratatui 内部统一。
//
// 官方参考：examples/apps/async-github（骨架同源）
// ============================================================

use crossterm::event::{Event, EventStream, KeyCode, KeyEvent, KeyEventKind};
use ratatui::{
    Frame,
    layout::{Constraint, Layout},
    style::{Color, Style},
    text::Line,
    widgets::{Block, List, ListItem, Paragraph},
};
use std::io::IsTerminal;
use std::time::Duration;
use tokio_stream::StreamExt as _; // EventStream 的 next()

/// 消息：三路事件统一成纯数据（async-github 的 Msg 模式）。
enum Msg {
    Key(KeyEvent),
    Tick,
    Data(u32),
}

struct App {
    quit: bool,
    ticks: u32,
    received: Vec<u32>,
}

impl App {
    fn new() -> Self {
        Self {
            quit: false,
            ticks: 0,
            received: Vec::new(),
        }
    }
}

/// 纯核：处理一条消息，返回 should_quit。selftest 与真终端共用。
fn step(app: &mut App, msg: Msg) -> bool {
    match msg {
        Msg::Key(key) if key.kind == KeyEventKind::Press => match key.code {
            KeyCode::Char('q') => {
                app.quit = true;
                true
            }
            _ => false,
        },
        Msg::Tick => {
            app.ticks += 1;
            false
        }
        Msg::Data(n) => {
            app.received.push(n);
            false
        }
        Msg::Key(_) => false, // Release/Repeat
    }
}

fn render(frame: &mut Frame, app: &App) {
    let [list, hint] = frame.area().layout(&Layout::vertical([
        Constraint::Fill(1),
        Constraint::Length(1),
    ]));
    let rows: Vec<ListItem> = app
        .received
        .iter()
        .map(|n| ListItem::new(Line::from(format!("数据块 {n}"))))
        .collect();
    frame.render_widget(
        List::new(rows)
            .block(Block::bordered().title(format!("数据流（tick={}）", app.ticks)))
            .highlight_style(Style::new().fg(Color::Blue)),
        list,
    );
    frame.render_widget(Paragraph::new("q 退出"), hint);
}

fn main() -> std::io::Result<()> {
    if std::env::args().nth(1).is_some_and(|a| a == "--selftest") {
        run_selftest();
        return Ok(());
    }
    if !std::io::stdout().is_terminal() {
        println!("36 ratatui async：请在真终端运行（cargo run）");
        return Ok(());
    }
    tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .build()
        .expect("tokio runtime")
        .block_on(async {
            let r = run().await;
            ratatui::restore(); // 统一在异步腿结束后恢复终端
            r
        })
}

/// 真终端腿：三路 select!——EventStream 只在这里出现。
async fn run() -> std::io::Result<()> {
    let mut terminal = ratatui::init(); // 返回 DefaultTerminal（非 Result）
    let mut app = App::new();
    let mut events = EventStream::new();
    let mut interval = tokio::time::interval(Duration::from_millis(400));
    let (data_tx, mut data_rx) = tokio::sync::mpsc::channel::<u32>(8);

    // 模拟数据源（async-github 的 octocrab 换本地生成器）
    tokio::spawn(async move {
        for n in 1..=20u32 {
            tokio::time::sleep(Duration::from_millis(300)).await;
            if data_tx.send(n).await.is_err() {
                return;
            }
        }
    });

    loop {
        terminal.draw(|frame| render(frame, &app))?;
        let msg = tokio::select! {
            _ = interval.tick() => Msg::Tick,
            Some(Ok(ev)) = events.next() => match ev {
                Event::Key(key) => Msg::Key(key),
                _ => Msg::Tick, // 其它事件当空拍（保 select 分支类型一致）
            },
            Some(n) = data_rx.recv() => Msg::Data(n),
        };
        if step(&mut app, msg) {
            return Ok(());
        }
    }
}

/// 无头自检：a) 纯核——常量消息序列直喂；b) 异步壳——#[tokio::test]。
fn selftest_body() -> String {
    let mut app = App::new();
    // 常量剧本：两块数据 + 一次 tick + 无关键 + Release 反例 + q
    for msg in [
        Msg::Data(1),
        Msg::Data(2),
        Msg::Tick,
        Msg::Key(KeyEvent::from(KeyCode::Char('x'))),
        Msg::Key(crossterm::event::KeyEvent::new_with_kind(
            KeyCode::Char('q'),
            crossterm::event::KeyModifiers::NONE,
            KeyEventKind::Release,
        )),
    ] {
        assert!(!step(&mut app, msg), "只有 q 的 Press 才退出");
    }
    assert_eq!((app.received.len(), app.ticks), (2, 1));
    assert!(step(&mut app, Msg::Key(KeyEvent::from(KeyCode::Char('q')))));

    // 纯核 + TestBackend 渲染一行证据
    use ratatui::{Terminal, backend::TestBackend};
    let mut terminal = Terminal::new(TestBackend::new(30, 8)).expect("TestBackend");
    terminal.draw(|frame| render(frame, &app)).expect("draw");
    // 内容区 y=1 是首行（y=0 是边框+标题）；双宽 hidden cell 混进逐格收集串，
    // 断言按字符命中而非连续子串
    let collect_row = |y: u16| -> String {
        (1..29u16)
            .filter_map(|x| {
                terminal
                    .backend()
                    .buffer()
                    .cell((x, y))
                    .map(|c| c.symbol().to_string())
            })
            .collect()
    };
    let row1 = collect_row(1);
    assert!(
        row1.contains('数') && row1.contains('1'),
        "首行应是数据块 1：{row1}"
    );
    let row2 = collect_row(2);
    assert!(row2.contains('2'), "第二行是数据块 2：{row2}");

    format!(
        "received={} ticks={} quit=true row=数据块1",
        app.received.len(),
        app.ticks
    )
}

fn run_selftest() {
    println!("==== 36 ratatui 异步 开始 ====");
    let evidence = selftest_body();
    println!("{evidence}");
    println!("==== 36 ratatui 异步 结束 ====");
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn pure_core_step() {
        let s = selftest_body();
        assert_eq!(s, "received=2 ticks=1 quit=true row=数据块1");
    }

    /// 异步壳验证：同一 step 核在 current_thread runtime 里跑对
    /// （mpsc 先 send 完再 recv——顺序确定，无竞争窗口）。
    #[tokio::test]
    async fn step_core_in_async_shell() {
        let (tx, mut rx) = tokio::sync::mpsc::channel::<u32>(4);
        for n in 1..=3u32 {
            tx.send(n).await.expect("先 send：缓冲 4 足够，不阻塞");
        }
        drop(tx);

        let mut app = App::new();
        while let Some(n) = rx.recv().await {
            assert!(!step(&mut app, Msg::Data(n)));
        }
        assert_eq!(app.received, vec![1, 2, 3], "通道关闭退出循环，顺序确定");
    }
}
