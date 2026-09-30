# 10 · iced 计数器：Elm 架构三件套

> 对应示例：[examples/10_iced_counter](../examples/10_iced_counter)

## 10.1 Elm 架构：state / update / view 单向流

iced 的世界观与 egui 完全相反：不是"每帧重跑一切"，而是**消息驱动的单向数据环**——

```text
        ┌──────────────────────────────────┐
        │                                  │
        ▼                                  │
   view(State) ──界面──▶ 用户交互产生 Message ──▶ update(State, Message) 改 State
```

- **State**：一个结构体，唯一可变的数据源；
- **Message**：枚举，界面能表达的全部意图；
- **update**：唯一改 State 的函数，收一条消息改一次；
- **view**：纯函数，State 长什么样界面就长什么样。

没有每帧轮询、没有回调注册——界面只在"有消息"时重算。这个模型直接来自 Elm 语言，Rust 生态里 iced 是它的旗舰实现。

**版本警告**：0.13（2025 年中）把 `Sandbox`/`Application` trait **删除**，入口改为函数式 builder；0.12 及更早教程的 `impl Sandbox for App { fn new/title/update/view }` 全部失效。另外 `Command` 已改名 `Task`。本教程按 0.14 写。

## 10.2 最小应用：application() 三件套

```rust
// ═══ 10.1 状态与消息 ═══
#[derive(Default)]
struct Counter { value: i64 }

#[derive(Debug, Clone)]
enum Message {
    Increment,
    Decrement,
}

impl Counter {
    fn update(&mut self, message: Message) {
        match message {
            Message::Increment => self.value += 1,
            Message::Decrement => self.value -= 1,
        }
    }

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
```

要点：

- `button("Increment").on_press(Message::Increment)`——按钮只是**消息发生器**，`on_press` 挂的是消息不是回调；
- `view` 返回 `Element<'_, Message>`：四泛型 `Element<'a, Message, Theme, Renderer>` 的后两个有默认，业务代码只写前两个；`Column` 经 `.into()` 转换（`impl Into<Element>`）；
- `column![...]`/`row![...]` 是声明式宏，逗号分隔子元素，`.spacing()/.padding()` 链在后面。

```rust
// ═══ 10.2 入口：boot/update/view 三个函数 + builder 链 ═══
fn main() -> iced::Result {
    iced::application(Counter::new, Counter::update, Counter::view)
        .title("10 iced counter")
        .window_size(iced::Size::new(360.0, 240.0))
        .run()
}
```

`iced::application(boot, update, view)` 的第一参数是 **boot 函数**（返回 State；需要启动时发一个异步请求就返回 `(State, Task)`）。builder 上还能挂 `.theme()/.subscription()/.style()` 等，14 章用上 `subscription`。

## 10.3 无头测试：iced_test 的 counter 模式

0.14 的官方新增能力——`iced_test` 在**无窗口、纯 CPU（tiny-skia）**下驱动界面。counter 模式四步：**模拟器 → 点控件 → 消息喂 update → 重建 view 断言**：

```rust
// ═══ 10.3 counter 模式（官方示例同款）═══
fn selftest_body() -> Result<i64, iced_test::Error> {
    let mut counter = Counter { value: 0 };
    let mut ui = iced_test::simulator(counter.view());

    ui.click("Increment")?;   // &str 选择器：按文本定位按钮
    ui.click("Increment")?;
    ui.click("Decrement")?;

    for message in ui.into_messages() {  // 交互积累的消息
        counter.update(message);         // 喂给 update——和真运行完全同一条路
    }

    let mut ui = iced_test::simulator(counter.view()); // 用新 State 重建界面
    ui.find("value: 1")?;               // 屏幕上真的显示了 1
    Ok(counter.value)
}
```

两个思维转换：

- **消息不是立即处理的**——`click` 把交互翻译成消息攒着，`into_messages()` 一次性交给你，由你喂 `update`。这恰好就是 iced 运行时的真实语义（消息队列 + 逐条 update）。
- **断言"屏幕"要重建 view**——simulator 持有的是旧 State 的界面；改完 State 后用 `find("value: 1")` 在新界面上找文本。

## 10.4 与 egui 对照

| | egui（02 章） | iced（本章） |
|---|---|---|
| 事件 | 返回值：`ui.button(..).clicked()` | 消息：`on_press(Message::X)` → `update` |
| 状态变更时机 | ui 函数内当场改 | 只在 `update` 里 |
| 界面重建 | 每帧无条件 | 收到消息才重算 view |
| 测试断言点 | `harness.state().count`（直接读状态） | `find("value: 1")`（读屏幕）+ 状态 |

同一个计数器，egui 版"逻辑长在界面代码里"，iced 版"界面只是 State 的投影"——两种范式在最小应用上已经分岔。

## 10.5 运行与输出

```bash
cd G:\code\guide\rustgui
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 10_iced_counter
```

实测输出（`build/10_iced_counter.run.out`）：

```text
==== 10 iced 计数器 开始 ====
value after +1 +1 -1 = 1
==== 10 iced 计数器 结束 ====
```

真窗口里点按钮，注意与 egui 的体感差别：界面只在点击瞬间重绘（消息驱动），不做无谓工作。

## 坑位清单

- **Sandbox/Application trait 已删（0.13）**：入口只剩 `iced::application(boot, update, view)` builder（或 State: Default 时的 `iced::run(update, view)`）。旧教程的 `impl Sandbox` 整段作废。
- **`Command` → `Task`**：0.13 起 update 的返回值叫 `Task<Message>`（本例返回 `()`——`Into<Task>` 的宽松写法）。看到 `Command::perform` 请翻译成 `Task::perform`（14 章）。
- **&str 选择器是全等匹配**：`find("1")` 匹配不到 `value: 1`——要找整串 `find("value: 1")`。动态文本用 `format!` 精确构造目标串。
- **iced_test::Error 不实现 PartialEq**：断言写 `assert_eq!(body().expect(..), 1)`，不能 `assert_eq!(body(), Ok(1))`。
- **simulator 不是运行时**：它不执行 Task/Subscription（副作用一律没有），只测 view+update 的消息环。要测副作用链路得用 `Emulator`（本教程不展开）。

---

上一章：[09 · egui 综合实战：待办管理器](09-egui-app.md) ｜ 下一章：[11 · iced 表单控件与 id 定位](11-iced-widgets.md) ｜ 返回：[README](../README.md)
