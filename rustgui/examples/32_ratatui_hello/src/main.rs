// ============================================================
// 32_ratatui_hello —— Ratatui 最小 TUI：buffer 心智与 TestBackend
//
// 读法：
//   1. 终端也是一块"像素网格"，只是像素是 cell（符号+样式）；
//      immediate mode 与 egui 同构——draw 闭包每帧全量重画，
//      状态全在 App、render(frame, &app) 是纯函数。
//   2. 官方骨架：ratatui::run(run) + terminal.draw(render) +
//      event::poll/read().as_key_press_event()（hello-world 同款）。
//   3. 无头通道 = 官方 TestBackend：纯内存渲染 + assert_buffer_lines
//      直接断言"渲染输出"——TUI 的渲染边界就在 buffer，这条通道
//      比四条 GUI 通道都硬（不需要 init、不需要事件循环）。
//   4. 事件驱动纯函数化：selftest 里手工构造 KeyEvent 直喂
//      handle_key——crossterm 运行时 API（poll/read）绝不进无头腿。
//
// 【坑】旧教程（0.26–0.29）大断代：0.30 起 workspace 拆分
//      （门面 ratatui + core/crossterm/widgets/macros）、
//      assert_buffer_eq! 宏废弃、Key 事件必须 as_key_press_event()
//      过滤（否则 Release/Repeat 也当按键）。详见本章坑位清单。
//
// 官方参考：https://ratatui.rs（网站）/ docs.rs/ratatui
// ============================================================

use ratatui::{
    DefaultTerminal, Frame,
    crossterm::event::{self, Event, KeyCode, KeyEvent, KeyEventKind},
    text::Line,
    widgets::Paragraph,
};
use std::io::IsTerminal;

/// 应用状态：immediate mode 的"单一事实源"，render 是它的纯投影。
struct App {
    quit: bool,
    presses: u32,
}

/// 键处理纯函数：真终端与无头测试共用（事件 = 数据，直喂即可）。
/// kind 过滤在这里做——`Event::as_key_press_event()` 是 Event 级的过滤
/// helper，拿到 KeyEvent 后判断 kind 字段是等价写法（Release/Repeat
/// 不当按键，0.29 起的经典坑）。
fn handle_key(app: &mut App, key: KeyEvent) {
    if key.kind == KeyEventKind::Press {
        match key.code {
            KeyCode::Char('q') => app.quit = true,
            KeyCode::Char(' ') => app.presses += 1,
            _ => {}
        }
    }
}

/// 渲染纯函数：真终端 draw 闭包与 TestBackend 无头腿共用。
fn render(frame: &mut Frame, app: &App) {
    let text = vec![
        Line::from("你好，Ratatui！"),
        Line::from(format!("presses: {}", app.presses)),
        Line::from("按 q 退出 · 空格计数"),
    ];
    frame.render_widget(Paragraph::new(text), frame.area());
}

fn main() -> std::io::Result<()> {
    if std::env::args().nth(1).is_some_and(|a| a == "--selftest") {
        run_selftest();
        return Ok(());
    }
    if !std::io::stdout().is_terminal() {
        // gui-shots 等误启动的防御：不开终端就别跑 TUI
        println!("32 ratatui hello：请在真终端运行（cargo run）");
        return Ok(());
    }
    ratatui::run(run)
}

/// 真终端主循环：draw → poll/read（官方 hello-world 骨架）。
fn run(terminal: &mut DefaultTerminal) -> std::io::Result<()> {
    let mut app = App {
        quit: false,
        presses: 0,
    };
    while !app.quit {
        terminal.draw(|frame| render(frame, &app))?;
        if event::poll(std::time::Duration::from_millis(250))?
            && let Event::Key(key) = event::read()?
        {
            handle_key(&mut app, key);
        }
    }
    Ok(())
}

/// 无头自检：TestBackend 纯内存渲染 + 中文双宽行断言 + KeyEvent 直喂。
fn selftest_body() -> (u32, bool) {
    use ratatui::{Terminal, backend::TestBackend};

    // a) 渲染断言：24x5 的 cell 网格，中文每字占 2 列
    //    （"你好，Ratatui！" = 4+2+1+7+2 = 16 显示宽，补 8 空格到 24）
    let mut terminal = Terminal::new(TestBackend::new(24, 5)).expect("TestBackend 纯内存");
    let app = App {
        quit: false,
        presses: 2,
    };
    terminal
        .draw(|frame| render(frame, &app))
        .expect("无头 draw");

    // 双宽口径（实测）：期望行补尾空格到恰等于 backend 宽 24；
    // 中文每字 2 列、'·'（U+00B7，East Asian Ambiguous）是 **1 列**——
    // "按 q 退出 · 空格计数" 的显示宽 = 20，补 4 空格。
    terminal.backend().assert_buffer_lines([
        "你好，Ratatui！        ",  // 16 + 8 = 24
        "presses: 2              ", // 10 + 14 = 24
        "按 q 退出 · 空格计数    ", // 20 + 4 = 24
        "                        ",
        "                        ",
    ]);

    // b) 事件驱动：手工构造 KeyEvent（纯数据），绝不碰 poll/read
    let mut app = App {
        quit: false,
        presses: 0,
    };
    for _ in 0..3 {
        handle_key(&mut app, KeyEvent::from(KeyCode::Char(' ')));
    }
    // Release 事件不当按键（kind 过滤的反例验证）
    handle_key(
        &mut app,
        KeyEvent::new_with_kind(
            KeyCode::Char(' '),
            ratatui::crossterm::event::KeyModifiers::NONE,
            KeyEventKind::Release,
        ),
    );
    handle_key(&mut app, KeyEvent::from(KeyCode::Char('x'))); // 无关键：不计数
    handle_key(&mut app, KeyEvent::from(KeyCode::Char('q')));
    (app.presses, app.quit)
}

fn run_selftest() {
    println!("==== 32 ratatui 最小应用 开始 ====");
    let (presses, quit) = selftest_body();
    assert_eq!((presses, quit), (3, true));
    println!("presses={presses} quit={quit} buffer=24x5-asserted");
    println!("==== 32 ratatui 最小应用 结束 ====");
}

#[cfg(test)]
mod tests {
    #[test]
    fn buffer_and_keys() {
        let (presses, quit) = super::selftest_body();
        assert_eq!((presses, quit), (3, true));
    }
}
