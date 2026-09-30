// ============================================================
// 10_iced_counter —— Elm 架构最小应用：state / update / view 三件套
//
// 读法：
//   1. iced 是 The Elm Architecture：State 持数据，view(State) 产界面，
//      界面发 Message，update(State, Message) 改 State——单向数据流。
//   2. 0.13 起 Sandbox/Application trait 已删除，入口是
//      iced::application(new, update, view) builder（0.12 及更早教程全部失效）。
//   3. selftest_body() 用 iced_test::simulator 无窗口驱动：
//      click → into_messages → update → find 断言，全程 CPU 渲染。
//
// 官方参考：https://docs.rs/iced/latest/iced/
// 本地源码：G:\github\rust\iced（tag 0.14.0 与 crates.io 一致）
// ============================================================

/// 状态：Elm 架构里唯一可变的东西。所有变化都只能经 update() 发生。
#[derive(Default)]
struct Counter {
    value: i64,
}

/// 消息：界面能产生的全部"意图"。按钮只是产生消息的来源之一。
#[derive(Debug, Clone)]
enum Message {
    Increment,
    Decrement,
}

impl Counter {
    fn new() -> Self {
        Self { value: 0 }
    }

    /// update：唯一允许修改 State 的地方（返回 Task 可发起异步，本章不用）。
    fn update(&mut self, message: Message) {
        match message {
            Message::Increment => self.value += 1,
            Message::Decrement => self.value -= 1,
        }
    }

    /// view：纯函数式的界面声明。状态怎么变，界面就长什么样。
    fn view(&self) -> iced::Element<'_, Message> {
        use iced::widget::{button, column, row, text};

        column![
            text(format!("value: {}", self.value)).size(40),
            row![
                button("Increment").on_press(Message::Increment),
                button("Decrement").on_press(Message::Decrement),
            ]
            .spacing(10),
        ]
        .spacing(20)
        .padding(20)
        .into()
    }
}

fn main() -> iced::Result {
    let selftest = std::env::args().nth(1).is_some_and(|a| a == "--selftest");
    if selftest {
        run_selftest();
        return Ok(());
    }

    iced::application(Counter::new, Counter::update, Counter::view)
        .title("10 iced counter")
        .window_size(iced::Size::new(360.0, 240.0))
        .run()
}

/// 无头自检：官方 counter 模式——
/// simulator 点按钮 → into_messages 喂 update → 重建 view 用 find 断言。
fn selftest_body() -> Result<i64, iced_test::Error> {
    let mut counter = Counter { value: 0 };
    let mut ui = iced_test::simulator(counter.view());

    ui.click("Increment")?; // &str 选择器按按钮文本定位
    ui.click("Increment")?;
    ui.click("Decrement")?;

    for message in ui.into_messages() {
        counter.update(message);
    }

    // 重建 view，确认屏幕上真的显示了 1。
    // 注意 &str 选择器按【全等】匹配整个文本——显示的是 "value: 1"，
    // 就得找 "value: 1"，找 "1" 会 SelectorNotFound（高频坑，11 章细讲）。
    let mut ui = iced_test::simulator(counter.view());
    ui.find("value: 1")?;

    Ok(counter.value)
}

fn run_selftest() {
    println!("==== 10 iced 计数器 开始 ====");
    let value = selftest_body().expect("iced_test 模拟交互失败");
    println!("value after +1 +1 -1 = {value}");
    assert_eq!(value, 1, "两次 Increment 一次 Decrement 后应为 1");
    println!("==== 10 iced 计数器 结束 ====");
}

#[cfg(test)]
mod tests {
    #[test]
    fn clicks_flow_through_update() {
        // iced_test::Error 未实现 PartialEq，断言前先 expect 解包
        assert_eq!(super::selftest_body().expect("iced_test 模拟交互失败"), 1);
    }
}
