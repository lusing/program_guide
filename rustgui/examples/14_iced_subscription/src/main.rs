// ============================================================
// 14_iced_subscription —— 订阅流与异步 Task
//
// 读法：
//   1. Subscription = "外部世界持续喂消息"的通道：定时器、事件流、
//      传感器……builder 挂在 application 上，函数式返回
//      （State 不需要订阅时返回 Subscription::none()）。
//   2. 0.14 的定时订阅是 iced::time::every（旧 Subscription::tick 已删）。
//   3. Task::perform(异步块, 消息构造器)：一次性异步请求的标准姿势
//      （旧名 Command::perform）。消息回来时界面自动刷新。
//
// 【测试视角】simulator 不运行 subscription/Task——时间与执行器都
//      不存在。无头验证走"消息单元测试"：直接喂 Tick/Fetched 消息
//      断言 update 行为，异步核心抽成同步函数测。
//
// 官方参考：https://docs.rs/iced/latest/iced/
// ============================================================

use iced::widget::{button, column, progress_bar, text};
use iced::{Element, Subscription, Task};

#[derive(Clone, Debug)]
enum Message {
    ToggleClock,      // 开/关秒表
    Tick,             // time::every 每秒发一条
    FetchPressed,     // 请求一次"数据加载"
    Fetched(Vec<u8>), // 异步结果回来
}

#[derive(Clone)]
struct ClockApp {
    running: bool,
    ticks: u64,    // 自管理的计数（不存真实时间——确定性！）
    chunks: usize, // 已到的数据块
    fetching: bool,
}

impl ClockApp {
    fn new() -> Self {
        Self {
            running: false,
            ticks: 0,
            chunks: 0,
            fetching: false,
        }
    }

    /// 同步核心：数据块怎么算（异步壳包着它，测试直接测它）
    fn compute_chunks(bytes: &[u8]) -> usize {
        bytes.len() / 16
    }

    /// 模拟一次异步加载：产出 5 块 x 16 字节。
    /// 真项目里这里是网络请求；异步壳留给 Task::perform。
    fn fetch_payload() -> Vec<u8> {
        vec![0_u8; 5 * 16]
    }

    fn update(&mut self, message: Message) -> Task<Message> {
        match message {
            Message::ToggleClock => {
                self.running = !self.running;
                Task::none()
            }
            Message::Tick => {
                // 只有运行中才计数：subscription 配合 State 过滤，
                // 双保险防"关了还在走"
                if self.running {
                    self.ticks += 1;
                }
                Task::none()
            }
            Message::FetchPressed => {
                if self.fetching {
                    return Task::none();
                }
                self.fetching = true;
                // 一次性异步任务：跑完把结果包装成 Fetched 消息发回来
                Task::perform(async { Self::fetch_payload() }, Message::Fetched)
            }
            Message::Fetched(bytes) => {
                self.fetching = false;
                self.chunks = Self::compute_chunks(&bytes);
                Task::none()
            }
        }
    }

    /// 订阅：随 State 变化而变化——running=false 时退订（没有空转的定时器）
    fn subscription(&self) -> Subscription<Message> {
        if self.running {
            iced::time::every(iced::time::seconds(1)).map(|_| Message::Tick)
        } else {
            Subscription::none()
        }
    }

    fn view(&self) -> Element<'_, Message> {
        column![
            text(format!("ticks = {}", self.ticks)).size(32),
            button(if self.running { "停止" } else { "开始" }).on_press(Message::ToggleClock),
            // 进度条直接吃 ticks（0..=10 区间内演示）
            progress_bar(0.0..=10.0, (self.ticks.min(10)) as f32),
            button(if self.fetching {
                "加载中…"
            } else {
                "加载数据"
            })
            .on_press_maybe((!self.fetching).then_some(Message::FetchPressed)),
            text(format!("chunks = {}", self.chunks)),
        ]
        .spacing(14)
        .padding(24)
        .into()
    }
}

fn main() -> iced::Result {
    let selftest = std::env::args().nth(1).is_some_and(|a| a == "--selftest");
    if selftest {
        run_selftest();
        return Ok(());
    }

    iced::application(ClockApp::new, ClockApp::update, ClockApp::view)
        .title("14 iced subscription")
        .subscription(ClockApp::subscription)
        .window_size(iced::Size::new(360.0, 400.0))
        .run()
}

/// 无头自检：交互走 simulator（按钮消息真实产生），
/// 时间流与异步壳走"消息单元测试"（直接喂消息）。
fn selftest_body() -> Result<ClockApp, iced_test::Error> {
    use iced_test::simulator;

    let mut app = ClockApp::new();
    let mut ui = simulator(app.view());

    ui.click("开始")?; // ToggleClock -> running
    ui.click("加载数据")?; // FetchPressed（Task 不被 simulator 执行）
    for m in ui.into_messages() {
        let _ = app.update(m);
    }
    assert!(app.running);
    assert!(app.fetching, "simulator 不执行 Task，fetching 停在 true");

    // ---- 消息单元测试：时间流 ----
    for _ in 0..3 {
        let _ = app.update(Message::Tick);
    }
    assert_eq!(app.ticks, 3, "三条 Tick 消息 = 计数 3（确定性）");

    // 停止后 Tick 不再计数（subscription 已退订 + update 双保险）
    let _ = app.update(Message::ToggleClock);
    let _ = app.update(Message::Tick);
    assert_eq!(app.ticks, 3);

    // ---- 消息单元测试：异步结果路径 ----
    let _ = app.update(Message::Fetched(ClockApp::fetch_payload()));
    assert_eq!(app.chunks, 5);
    assert!(!app.fetching);

    Ok(app)
}

fn run_selftest() {
    println!("==== 14 iced 订阅与异步 开始 ====");
    let app = selftest_body().expect("iced_test 模拟交互失败");
    println!(
        "ticks={} chunks={} running={}",
        app.ticks, app.chunks, app.running
    );
    assert_eq!((app.ticks, app.chunks), (3, 5));
    println!("==== 14 iced 订阅与异步 结束 ====");
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn clock_and_fetch_flow() {
        let app = selftest_body().expect("iced_test 失败");
        assert_eq!((app.ticks, app.chunks, app.running), (3, 5, false));
    }

    #[test]
    fn compute_chunks_is_pure() {
        assert_eq!(ClockApp::compute_chunks(&[]), 0);
        assert_eq!(ClockApp::compute_chunks(&[0; 31]), 1);
        assert_eq!(ClockApp::compute_chunks(&[0; 64]), 4);
    }
}
