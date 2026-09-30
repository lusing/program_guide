# 11 · iced 表单控件与 id 定位

> 对应示例：[examples/11_iced_widgets](../examples/11_iced_widgets)

## 11.1 控件全家：函数构造 + 链式 builder

0.13 起所有 iced 控件统一为"函数构造、链式配置"，与 0.12 的一次性传参签名完全不同。一张报名表单收齐常用控件：

```rust
// ═══ 11.1 表单四件套的当前签名 ═══
text_input("姓名", &self.name)        // (placeholder, value)
    .id("name")                        // widget Id：定位锚
    .on_input(Message::NameChanged)    // 每次击键 → 消息
    .on_submit(Message::Submit),       // 回车 → 消息

checkbox(self.subscribed)              // 先状态（旧版是 (label, state, cb)）
    .label("订阅通知")
    .on_toggle(Message::Subscribed),

slider(1..=9, self.tickets, Message::TicketsChanged).step(1_u32),

button("提交").on_press(Message::Submit),
```

注意 `on_input`/`on_toggle` 收的是**函数**（`Fn(String) -> Message`），不是消息值——因为它们带载荷；`on_press` 收消息值（无载荷）。`text` 更宽松：`text(3)` 直接渲染数字（`IntoFragment`）。

## 11.2 Message 设计：一个交互一个变体

```rust
// ═══ 11.2 表单的消息族 ═══
enum Message {
    NameChanged(String),      // 带载荷：Fn(String) -> Message
    Subscribed(bool),
    TicketsChanged(u32),
    CitySelected(&'static str),
    Submit,
}
```

Elm 架构的纪律：**界面上每一个能表达"意图"的地方，Message 里就有对应变体**；update 里逐条 match。表单越复杂，枚举越长——这是 iced 的"税"，换来的是全部交互集中一处可审查。

## 11.3 无头测试扩展集：id 定位与打字

10 章的 &str 选择器按文本找控件；输入框没有可点的文本（placeholder 不是），要用 **widget Id**：

```rust
// ═══ 11.3 iced_test 的进阶剧本 ═══
use iced_test::selector::id;

ui.click(id("name"))?;            // 按 widget Id 点输入框（拿焦点）
ui.typewrite("张三");              // 逐字输入（返回 event::Status，非 Result）

ui.click("订阅通知")?;             // checkbox 的 label 可被 &str 匹配
ui.click("深圳")?;                 // 分段按钮组的按钮文本可点

ui.click(id("name"))?;            // 回车前先回到输入框（见坑 3）
ui.tap_key(keyboard::Key::Named(keyboard::key::Named::Enter)); // 触发 on_submit

for message in ui.into_messages() {
    form.update(message);
}
```

- `text_input(...).id("name")` 与 `selector::id("name")` 隔空握手——业务代码与测试共享同一个锚点字符串；
- `typewrite`/`tap_key` 返回 `event::Status`（事件是否被控件捕获），不是 Result——别写 `?`；
- Enter 前的 `click(id("name"))` 是**重新聚焦**：中途点过按钮后焦点在按钮上，回车会落在按钮而不是输入框。

## 11.4 radio / pick_list 为什么点不到（重要）

iced_test 的 &str 选择器只匹配两类候选：**Text** 控件和 **TextInput** 的内容。按钮能点是因为 `button("文本")` 内部有一个 Text 子控件；checkbox 的 label 恰好暴露为 Text。而：

- **radio**：标签自绘，不进候选树——`click("深圳")` 对 radio 版直接 `SelectorNotFound`；
- **pick_list**：选中文本/占位文本同样自绘——`&str` 点不到。

三条出路（本例选第一条）：**分段按钮组**（文本即子 Text，永远可点，本例的城市选择）；**Point 坐标选择器**（12 章演示，按几何位置点）；**键盘流**（Tab 切焦点 + Enter，脆弱不推荐）。radio 的正规写法留档：

```rust
// ═══ 11.4 radio 的正规写法（真窗口可用；测试点不到其标签）═══
use iced::widget::radio;
CITIES.iter().map(|c| radio(*c, *c, self.city, Message::CitySelected).into())
```

## 11.5 运行与输出

```bash
cd G:\code\guide\rustgui
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 11_iced_widgets
```

实测输出（`build/11_iced_widgets.run.out`）：

```text
==== 11 iced 表单控件 开始 ====
name=张三 subscribed=true tickets=2 city=Some("深圳") submitted=true
==== 11 iced 表单控件 结束 ====
```

一行终值覆盖五个控件：打字进输入框、勾选、滑块保持默认 2、城市选中深圳、回车提交成功。真窗口里拖一拖滑块（iced_test 不模拟拖拽）、点一点分段按钮看选中态变色。

## 坑位清单

- **radio/pick_list 标签点不到**：&str 选择器只认 Text 子控件与 TextInput 内容，这两家的文本是自绘的。表单要做无头测试就用按钮组/checkbox/带 id 的输入框，或 12 章的 Point 坐标法。
- **on_input 是函数不是消息**：`on_input(Message::NameChanged)` 传的是枚举**构造器**（`Fn(String) -> Message`）；`on_press` 才收消息值。载荷型回调 (`on_toggle`/`on_change`) 同理。
- **回车落在哪取决于焦点**：点过按钮后输入框失焦，`tap_key(Enter)` 触发的是按钮而不是 `on_submit`。回车剧本前先 `click(id(..))` 重聚焦。
- **闭包只能写一个**：`style(if a { closure1 } else { closure2 })` 两个闭包类型对不上（`implementation of FnOnce is not general enough`）——把条件捕获进单个闭包（`let selected = ..; move |_t| Style { color: selected.then(..) }`）。
- **row() 构造器收 Element**：`row(iter.map(|c| widget))` 里 widget 要手动 `.into()`；`row![]` 宏会自动转，两者别混着记。

---

上一章：[10 · iced 计数器：Elm 架构三件套](10-iced-counter.md) ｜ 下一章：[12 · iced 布局：容器、弹性与坐标定位](12-iced-layout.md) ｜ 返回：[README](../README.md)
