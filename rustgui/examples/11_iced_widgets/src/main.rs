// ============================================================
// 11_iced_widgets —— 链式控件、表单三件套与 id 定位
//
// 读法：
//   1. iced 控件全是"函数构造 + 链式 builder"：
//      text_input(placeholder, value).on_input(Msg).id("name")
//      —— 与 0.12 及以前的一次性传参签名完全不同。
//   2. 每个交互控件配一个 Message 变体，update 里 match。
//   3. iced_test 扩展集：selector::id 定位输入框、typewrite 打字、
//      tap_key 回车、pick_list 点选项。
//
// 官方参考：https://docs.rs/iced/latest/iced/
// ============================================================

use iced::Element;
use iced::widget::{button, checkbox, column, row, slider, text, text_input};

/// 城市选项（分段按钮组；radio 版本见正文——其标签进不了测试选择器树）
const CITIES: [&str; 3] = ["北京", "上海", "深圳"];

#[derive(Clone, Debug, PartialEq)]
enum Message {
    NameChanged(String),
    Subscribed(bool),
    TicketsChanged(u32),
    CitySelected(&'static str),
    Submit,
}

#[derive(Clone)]
struct Form {
    name: String,
    subscribed: bool,
    tickets: u32,
    city: Option<&'static str>,
    submitted: bool,
}

impl Form {
    fn new() -> Self {
        Self {
            name: String::new(),
            subscribed: false,
            tickets: 2,
            city: None,
            submitted: false,
        }
    }

    fn update(&mut self, message: Message) {
        match message {
            Message::NameChanged(s) => self.name = s,
            Message::Subscribed(b) => self.subscribed = b,
            Message::TicketsChanged(n) => self.tickets = n,
            Message::CitySelected(c) => self.city = Some(c),
            Message::Submit => self.submitted = true,
        }
    }

    fn view(&self) -> Element<'_, Message> {
        let mut col = column![
            text("报名表单").size(28),
            // 文本输入：placeholder + 当前值，on_input 把每次击键变成消息
            text_input("姓名", &self.name)
                .id("name") // widget Id：测试与 focus 操作的定位锚
                .on_input(Message::NameChanged)
                .on_submit(Message::Submit), // 回车也提交
            // 复选框（0.13 起签名改组：先状态后链式）
            checkbox(self.subscribed)
                .label("订阅通知")
                .on_toggle(Message::Subscribed),
            // 滑块：RangeInclusive + 当前值 + 回调
            row![
                text(format!("票数：{}", self.tickets)),
                slider(1..=9, self.tickets, Message::TicketsChanged).step(1_u32),
            ]
            .spacing(8),
            // 城市选择：分段按钮组。radio/pick_list 的标签是控件自绘的，
            // 不进 iced_test 的候选树（&str 点不到）——按钮的文本是子 Text，
            // 永远可点。radio 写法见正文，pick_list 坐标定位法见 12 章。
            row(CITIES.iter().map(|c| {
                // 选中态文字加色（正式样式系统 13 章讲；闭包只能有一个，
                // 条件捕获成 bool——两个分支各写一个闭包类型对不上）
                let selected = self.city == Some(*c);
                button(text(*c).style(move |_theme| text::Style {
                    color: selected.then(|| iced::Color::from_rgb(0.1, 0.5, 1.0)),
                }))
                .on_press(Message::CitySelected(c))
                .into()
            }))
            .spacing(8),
            button("提交").on_press(Message::Submit),
        ]
        .spacing(12)
        .padding(20);

        if self.submitted {
            col = col.push(text(format!(
                "已提交：{} / {} 张 / {} / 订阅={}",
                if self.name.is_empty() {
                    "（无名）"
                } else {
                    &self.name
                },
                self.tickets,
                self.city.unwrap_or("（未选）"),
                if self.subscribed { "是" } else { "否" }
            )));
        }

        col.into()
    }
}

fn main() -> iced::Result {
    let selftest = std::env::args().nth(1).is_some_and(|a| a == "--selftest");
    if selftest {
        run_selftest();
        return Ok(());
    }

    iced::application(Form::new, Form::update, Form::view)
        .title("11 iced widgets · 报名表单")
        .window_size(iced::Size::new(420.0, 480.0))
        .run()
}

/// 无头自检：typewrite 打名、回车提交前先勾订阅/选城市/调票数，
/// 全链路走完断言终态。
fn selftest_body() -> Result<Form, iced_test::Error> {
    use iced::keyboard;
    use iced_test::selector::id;
    use iced_test::simulator;

    let mut form = Form::new();
    let mut ui = simulator(form.view());

    // 输入框按 widget Id 定位（点它拿焦点，再打字）
    ui.click(id("name"))?;
    // typewrite 返回 event::Status（事件是否被控件捕获），不是 Result
    ui.typewrite("张三");

    // 勾选订阅（&str 选择器按控件文本全等匹配）
    ui.click("订阅通知")?;

    // 滑块：iced_test 不模拟拖拽——票数保持默认 2，
    // 拖拽交互留给真窗口人工验证（见正文）
    // 城市分段按钮：按钮文本是子 Text，&str 选择器直接点
    ui.click("深圳")?;

    // 回车提交（text_input 的 on_submit）。注意：中途点过按钮，焦点已经
    // 不在输入框上——先重新聚焦（再点一次输入框）再回车。
    ui.click(id("name"))?;
    ui.tap_key(keyboard::Key::Named(keyboard::key::Named::Enter));

    for message in ui.into_messages() {
        form.update(message);
    }

    Ok(form)
}

fn run_selftest() {
    println!("==== 11 iced 表单控件 开始 ====");
    let form = selftest_body().expect("iced_test 模拟交互失败");
    println!(
        "name={} subscribed={} tickets={} city={:?} submitted={}",
        form.name, form.subscribed, form.tickets, form.city, form.submitted
    );
    assert_eq!(form.name, "张三");
    assert!(form.subscribed);
    assert_eq!(form.tickets, 2);
    assert_eq!(form.city, Some("深圳"));
    assert!(form.submitted, "Enter 应触发 on_submit");
    println!("==== 11 iced 表单控件 结束 ====");
}

#[cfg(test)]
mod tests {
    #[test]
    fn form_fills_and_submits() {
        let form = super::selftest_body().expect("iced_test 失败");
        assert_eq!(form.name, "张三");
        assert!(form.submitted);
    }
}
