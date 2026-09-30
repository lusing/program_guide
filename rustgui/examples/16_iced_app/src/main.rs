// ============================================================
// 16_iced_app —— 综合实战：待办管理器（iced 版）
//
// 统一规格（09/16/23 三章同一应用）：
//   [1] 列表显示  [2] 文本输入添加  [3] 勾选完成
//   [4] 删除       [5] 综合组件（滚动列表）
// iced 特色亮点：自动保存——time::every 订阅触发节流保存 +
//   serde 持久化到磁盘，启动时恢复（boot 函数读档）。
//
// 官方参考：https://docs.rs/iced/latest/iced/
// ============================================================

use iced::widget::{button, checkbox, column, row, scrollable, text, text_input};
use iced::{Element, Subscription, Task};
use serde::{Deserialize, Serialize};

/// 一条待办（serde 派生 = 持久化的全部准备）
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
struct Todo {
    text: String,
    done: bool,
}

#[derive(Clone, Debug)]
enum Message {
    InputChanged(String),
    AddPressed,
    ToggleDone(String), // 按文本定位条目（消息即语义）
    DeletePressed(String),
    Autosave,     // 订阅每 2 秒发一条
    Saved(usize), // 保存完成回执（字节数）
}

#[derive(Clone)]
struct Todos {
    items: Vec<Todo>,
    input: String,
    dirty: bool,        // 有未落盘的修改
    saved_bytes: usize, // 最近一次保存的大小（证据）
    save_path: std::path::PathBuf,
}

impl Todos {
    fn new(save_path: std::path::PathBuf) -> Self {
        // 读档：文件不存在则全新开始（boot 的"恢复"半边）
        let items = std::fs::read_to_string(&save_path)
            .ok()
            .and_then(|json| serde_json::from_str::<Vec<Todo>>(&json).ok())
            .unwrap_or_default();
        Self {
            items,
            input: String::new(),
            dirty: false,
            saved_bytes: 0,
            save_path,
        }
    }

    fn done_count(&self) -> usize {
        self.items.iter().filter(|t| t.done).count()
    }

    fn update(&mut self, message: Message) -> Task<Message> {
        match message {
            Message::InputChanged(s) => self.input = s,
            Message::AddPressed => {
                let text = self.input.trim().to_owned();
                if !text.is_empty() {
                    self.items.push(Todo { text, done: false });
                    self.input.clear();
                    self.dirty = true;
                }
            }
            Message::ToggleDone(text) => {
                if let Some(t) = self.items.iter_mut().find(|t| t.text == text) {
                    t.done = !t.done;
                    self.dirty = true;
                }
            }
            Message::DeletePressed(text) => {
                self.items.retain(|t| t.text != text);
                self.dirty = true;
            }
            Message::Autosave => {
                if !self.dirty {
                    return Task::none(); // 节流：没改动不写盘
                }
                // 保存交给一次性 Task：异步壳 + 同步核心
                let path = self.save_path.clone();
                let json = serde_json::to_string(&self.items).unwrap_or_default();
                self.dirty = false;
                return Task::perform(async move { write_file(&path, &json) }, Message::Saved);
            }
            Message::Saved(n) => self.saved_bytes = n,
        }
        Task::none()
    }

    fn subscription(&self) -> Subscription<Message> {
        // 自动保存心跳：始终订阅（内部用 dirty 节流，避免空转写盘）
        iced::time::every(iced::time::seconds(2)).map(|_| Message::Autosave)
    }

    fn view(&self) -> Element<'_, Message> {
        column![
            text(format!(
                "待办 · {}/{} 已完成",
                self.done_count(),
                self.items.len()
            ))
            .size(24),
            row![
                text_input("新待办…", &self.input)
                    .id("new-todo")
                    .on_input(Message::InputChanged)
                    .on_submit(Message::AddPressed)
                    .width(iced::Length::Fixed(220.0)),
                button("添加").on_press(Message::AddPressed),
            ]
            .spacing(8),
            scrollable(
                column(self.items.iter().map(|t| {
                    row![
                        // on_toggle 收闭包（FnOnce(bool) -> Message）；
                        // on_press 只收消息值——两种形态别搞混
                        checkbox(t.done).label(t.text.clone()).on_toggle({
                            let text = t.text.clone();
                            // on_toggle 的闭包是 Fn（可能被调多次），值要 clone 着给
                            move |_| Message::ToggleDone(text.clone())
                        }),
                        button(text(format!("删除 {}", t.text)).size(12))
                            .on_press(Message::DeletePressed(t.text.clone())),
                    ]
                    .spacing(8)
                    .into()
                }))
                .spacing(6),
            )
            .height(iced::Length::Fill),
            text(format!(
                "saved={} bytes {}",
                self.saved_bytes,
                if self.dirty {
                    "（有未保存修改）"
                } else {
                    ""
                }
            )),
        ]
        .spacing(12)
        .padding(16)
        .into()
    }
}

/// 同步核心：写盘（异步壳里跑，测试直接测）
fn write_file(path: &std::path::PathBuf, json: &str) -> usize {
    match std::fs::write(path, json) {
        Ok(()) => json.len(),
        Err(_) => 0,
    }
}

fn default_save_path() -> std::path::PathBuf {
    // 教程用临时目录；真产品用 directories 之类的 app-data 目录
    std::env::temp_dir().join("16_iced_todo.json")
}

fn main() -> iced::Result {
    let selftest = std::env::args().nth(1).is_some_and(|a| a == "--selftest");
    if selftest {
        run_selftest();
        return Ok(());
    }

    let path = default_save_path();
    iced::application(
        move || Todos::new(path.clone()), // boot：读档在构造里完成
        Todos::update,
        Todos::view,
    )
    .title("16 iced todo · 待办管理器")
    .subscription(Todos::subscription)
    .window_size(iced::Size::new(480.0, 520.0))
    .run()
}

/// 无头自检：完整用户旅程 + 持久化往返（独立临时文件，先删保证干净）。
fn selftest_body() -> Todos {
    use iced_test::selector::id;
    use iced_test::simulator;

    let path = std::env::temp_dir().join("16_iced_todo_selftest.json");
    let _ = std::fs::remove_file(&path); // 干净起跑

    let mut app = Todos::new(path);
    let mut ui = simulator(app.view());

    // [2] 输入 + 添加
    ui.click(id("new-todo")).expect("定位输入框");
    ui.typewrite("写 iced 实战");
    ui.click("添加").expect("点添加");
    for m in ui.into_messages() {
        let _ = app.update(m);
    }

    // [3] 勾选完成：checkbox 的 label 可被 &str 命中
    {
        let mut ui = simulator(app.view());
        ui.click("写 iced 实战").expect("勾选新条目");
        for m in ui.into_messages() {
            let _ = app.update(m);
        }
    }
    assert_eq!(app.done_count(), 1);

    // [4] 删除：按钮文本带条目名，唯一可点
    {
        let mut ui = simulator(app.view());
        ui.click("删除 写 iced 实战").expect("点删除");
        for m in ui.into_messages() {
            let _ = app.update(m);
        }
    }
    assert!(app.items.iter().all(|t| t.text != "写 iced 实战"));

    // 再添加两条（含初始两条 = 3 条），走一次保存
    let _ = app.update(Message::InputChanged("持久化条目".into()));
    let _ = app.update(Message::AddPressed);
    assert!(app.dirty);

    // [6] 自动保存：Autosave 消息单元测试（Task 不被 simulator 执行，
    //     直接调同步核心验证写盘，再从磁盘读回对账）
    {
        let json = serde_json::to_string(&app.items).unwrap();
        let n = write_file(&app.save_path, &json);
        assert!(n > 0, "写盘应有字节");
    }
    let restored: Vec<Todo> =
        serde_json::from_str(&std::fs::read_to_string(&app.save_path).expect("文件应存在"))
            .expect("读回应可反序列化");
    assert_eq!(restored, app.items, "序列化往返应一致");

    // boot 恢复路径：新实例从盘上拿到同样数据
    let rebooted = Todos::new(app.save_path.clone());
    assert_eq!(rebooted.items, app.items);

    app
}

fn run_selftest() {
    println!("==== 16 iced 待办管理器 开始 ====");
    let app = selftest_body();
    println!(
        "items={} done={} saved={} bytes",
        app.items.len(),
        app.done_count(),
        serde_json::to_string(&app.items)
            .map(|s| s.len())
            .unwrap_or(0)
    );
    println!("==== 16 iced 待办管理器 结束 ====");
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn todo_journey_and_persistence_roundtrip() {
        let app = selftest_body();
        assert!(!app.items.is_empty());
        assert!(app.items.iter().any(|t| t.text == "持久化条目"));
    }
}
