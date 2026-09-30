# 16 · iced 综合实战：待办管理器

> 对应示例：[examples/16_iced_app](../examples/16_iced_app)

## 16.1 同一规格的 iced 答卷

09 章的六条规格在 iced 下的对应物：

| 规格 | egui（09） | iced（本章） |
|---|---|---|
| 列表显示 | ScrollArea + 每行 horizontal | `scrollable(column(...))`（急切布局） |
| 输入添加 | TextEdit + Enter/按钮 | `text_input(...).id("new-todo").on_submit(..)` |
| 勾选完成 | `ui.checkbox(&mut done, text)` | `checkbox(done).label(text).on_toggle(..)` |
| 删除 | 自查父行找"删"按钮 | `button(format!("删除 {text}")).on_press(值)` |
| 持久化 | ——（08 章单独讲） | **本章亮点**：订阅心跳 + serde 落盘 |
| 特色 | 趋势图 + 后台线程 | 自动保存 |

```rust
// ═══ 16.1 状态与消息：Elm 架构的完整形态 ═══
#[derive(Clone, Debug, Serialize, Deserialize)]
struct Todo { text: String, done: bool }

enum Message {
    InputChanged(String),
    AddPressed,
    ToggleDone(String),   // 消息带语义载荷（哪一条被勾了）
    DeletePressed(String),
    Autosave,             // 订阅每 2 秒发一条
    Saved(usize),         // 异步保存完成回执
}
```

注意 egui 版"勾选"直接改 `&mut done`（状态就地改），iced 版必须把意图翻译成 `ToggleDone(text)` 消息走 update——同一功能的两种哲学，24 章详细对账。

## 16.2 消息带载荷：按文本定位条目

iced 没有控件句柄，`on_toggle`/`on_press` 闭包捕获条目文本构造消息：

```rust
// ═══ 16.2 每行：checkbox + 唯一命名的删除按钮 ═══
row![
    checkbox(t.done).label(t.text.clone()).on_toggle({
        let text = t.text.clone();
        move |_| Message::ToggleDone(text.clone())  // Fn 闭包：值要 clone 着给
    }),
    button(text(format!("删除 {}", t.text)).size(12))
        .on_press(Message::DeletePressed(t.text.clone())),  // on_press 收值不收闭包
]
```

删除按钮的文本带上条目名（"删除 买牛奶"）——既是给用户看的确认，也让无头测试能**唯一点名**（09 章同样的思路用在了查询端）。副作用清单都进了坑位。

## 16.3 自动保存：订阅心跳 + Task 落盘

```rust
// ═══ 16.3 心跳常在，写盘节流 ═══
fn subscription(&self) -> Subscription<Message> {
    iced::time::every(iced::time::seconds(2)).map(|_| Message::Autosave)
}

fn update(&mut self, message: Message) -> Task<Message> {
    match message {
        Message::Autosave => {
            if !self.dirty { return Task::none(); }  // 节流：没改动不写
            let path = self.save_path.clone();
            let json = serde_json::to_string(&self.items).unwrap_or_default();
            self.dirty = false;
            return Task::perform(async move { write_file(&path, &json) }, Message::Saved);
        }
        Message::Saved(n) => self.saved_bytes = n,   // 回执也是一条消息
        // ...
    }
}
```

三层设计各有讲究：**订阅常开**（退订/重订的抖动不如内部节流省心）；**dirty 标志**挡掉空写；**写盘进 Task**（异步壳包同步核心 `write_file`，UI 线程零阻塞）。启动恢复在 boot 构造里：`Todos::new(path)` 读文件，失败即全新开始。

## 16.4 无头剧本：与 09 章同一张考卷

```rust
// ═══ 16.4 输入→添加→勾选→删除→持久化往返 ═══
ui.click(id("new-todo"))?;      // id 定位输入框（11 章手法）
ui.typewrite("写 iced 实战");
ui.click("添加")?;
// ... into_messages 喂 update ...

ui.click("写 iced 实战")?;        // checkbox 的 label 可 &str 命中 → 勾选
ui.click("删除 写 iced 实战")?;   // 唯一命名的删除按钮

// 持久化：同步核心直测 + 磁盘往返 + boot 恢复
let json = serde_json::to_string(&app.items).unwrap();
write_file(&app.save_path, &json);
let restored: Vec<Todo> = serde_json::from_str(&fs::read_to_string(..)?)?;
assert_eq!(restored, app.items);          // 序列化往返一致
assert_eq!(Todos::new(app.save_path.clone()).items, app.items); // 重启读档一致
```

与 09 章逐条对读：egui 用"focus→run→type→run"节奏打字，iced 用"click(id)+typewrite"；egui 勾选后 `record_trend()` 当场记账，iced 的 `ToggleDone` 要等 update 转一圈。**同一张考卷，两份答卷的笔迹差异就是范式差异**。

## 16.5 运行与输出

```bash
cd G:\code\guide\rustgui
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 16_iced_app
```

实测输出（`build/16_iced_app.run.out`）：

```text
==== 16 iced 待办管理器 开始 ====
items=1 done=0 saved=41 bytes
==== 16 iced 待办管理器 结束 ====
```

真窗口里加几条待办、等两秒看底栏的 `saved=… bytes` 跳动（自动保存心跳）、关掉重开——条目还在（boot 读档）。

## 坑位清单

- **on_press 收值、on_toggle 收闭包**：载荷型回调（on_toggle/on_input/on_change）是 `Fn(..) -> Message` 闭包；`on_press` 只收消息值。闭包塞给 on_press 会在宏展开处炸出泛型错——看懂错误位置比看懂错误文本快。
- **Fn 闭包里的 String 要 clone 着给**：`move |_| Msg(text)` 第二次调用就 move 出错（E0507）；`move |_| Msg(text.clone())` 才是 Fn。
- **Autosave 的 Task 不被 simulator 执行**：无头验证写盘 = 直接调同步核心 `write_file` + 读回对账 + `Todos::new(path)` 重启读档。真实执行器行为留给真窗口。
- **selftest 的存档文件先删再跑**：读档是 boot 逻辑，上一次跑残留的文件会让初始状态不确定——`remove_file` 干净起跑（两跑逐字节一致全靠它）。
- **教程用 temp_dir 存档**：真产品用 `directories` 之类的 app-data 目录（每 OS 规范位置），别学这里图省事。

---

上一章：[15 · iced Canvas：自绘进度环](15-iced-canvas.md) ｜ 下一章：[17 · Slint 最小应用：声明式 DSL](17-slint-hello.md) ｜ 返回：[README](../README.md)
