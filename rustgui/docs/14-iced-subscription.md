# 14 · iced 订阅与异步 Task

> 对应示例：[examples/14_iced_subscription](../examples/14_iced_subscription)

## 14.1 两条"从外面进来的消息"通道

Elm 架构里用户的点击是消息的一半来源；另一半来自**外部世界**——时间、网络、文件、传感器。iced 给了两条通道，语义边界清晰：

| 通道 | 语义 | 触发次数 | 典型用途 |
|---|---|---|---|
| `Task<Message>` | **一次性**请求 | update 里发起，完成发一条消息 | 网络请求、读文件、弹对话框 |
| `Subscription<Message>` | **持续性**监听 | 挂在 application 上，随 State 变化 | 定时器、键盘事件流、WebSocket |

## 14.2 Task::perform：一次性异步

```rust
// ═══ 14.1 update 返回 Task（旧名 Command 已废）═══
fn update(&mut self, message: Message) -> Task<Message> {
    match message {
        Message::FetchPressed => {
            if self.fetching {
                return Task::none(); // 防重入
            }
            self.fetching = true;
            // 异步块跑在执行器上；完成时结果被包成 Fetched 消息发回 update
            Task::perform(async { Self::fetch_payload() }, Message::Fetched)
        }
        Message::Fetched(bytes) => {
            self.fetching = false;
            self.chunks = Self::compute_chunks(&bytes);
            Task::none()
        }
        // ...
    }
}
```

`Task::perform(future, 构造器)` 的第二个参数是 `FnOnce(输出) -> Message`——异步结果**必须**翻译成消息回到 update，不允许异步代码直接改 State。这条纪律保证了"改状态只发生在 update"的架构不变式。`Task` 还有一整套组合子：`batch`（并发跑一批）、`then/chain`（单子链）、`discard`、`future/stream` 直挂。

**feature 门**：`iced::time` 的定时订阅（下节）需要异步运行时 feature——默认 feature 一个运行时都不带，必须显式开 `tokio` 或 `smol`（本例 `features = ["tokio"]`）。不带运行时时 `Task` 用的是默认线程池执行器，任务照跑。

## 14.3 订阅：随 State 变化的监听

```rust
// ═══ 14.2 挂在 builder 上；running=false 时退订 ═══
iced::application(ClockApp::new, ClockApp::update, ClockApp::view)
    .subscription(ClockApp::subscription) // fn(&State) -> Subscription<Message>
    .run();

impl ClockApp {
    fn subscription(&self) -> Subscription<Message> {
        if self.running {
            iced::time::every(iced::time::seconds(1)).map(|_| Message::Tick)
        } else {
            Subscription::none() // 退订：没有空转的定时器
        }
    }
}
```

- **`Subscription::tick` 不存在**——定时订阅是 `iced::time::every(duration)`（返回 `Subscription<Instant>`，`.map` 成自己的消息）；
- 订阅是**每帧重算的函数**：State 变了订阅就变（内部按 hash 识别订阅身份，重启不重不漏）。"暂停秒表"不用任何取消 API——条件分支退订即可；
- 事件类订阅：`iced::keyboard::listen()`（键盘事件流）、`iced::event::listen`（原始事件流）；自定义流走 `Subscription::run(fn_ptr)`——builder **必须是非捕获 fn 指针**，要带数据用 `run_with(data, fn)`（data: Hash）。

## 14.4 无头测试：simulator 不跑时间和执行器

`iced_test` 的 simulator 只驱动 view+update 的消息环——**没有时钟、没有执行器**，subscription 与 Task 一律不执行。无头验证的对应策略：

```rust
// ═══ 14.3 时间流与异步壳的消息单元测试 ═══
// 交互（按钮消息）照旧走 simulator：
ui.click("开始")?;
ui.click("加载数据")?;
for m in ui.into_messages() { let _ = app.update(m); }
assert!(app.fetching, "Task 未被执行器跑完——状态停在 fetching=true");

// 时间流：直接喂 Tick 消息（update 是纯函数，喂三条 = 走三秒）
for _ in 0..3 { let _ = app.update(Message::Tick); }
assert_eq!(app.ticks, 3);

// 异步壳：结果消息手动送达（同步核心 compute_chunks 另有专门单测）
let _ = app.update(Message::Fetched(ClockApp::fetch_payload()));
assert_eq!(app.chunks, 5);
```

配套两条工程纪律：**计数值自管理**（`ticks += 1`，不存 `Instant::now()`——确定性！）；**异步核心抽同步函数**（`compute_chunks(&[u8]) -> usize` 可以单独表驱动测试）。这与 egui 09 章"fast_worker 不 sleep"是同一个思想的三种方言。

## 14.5 运行与输出

```bash
cd G:\code\guide\rustgui
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 14_iced_subscription
```

实测输出（`build/14_iced_subscription.run.out`）：

```text
==== 14 iced 订阅与异步 开始 ====
ticks=3 chunks=5 running=false
==== 14 iced 订阅与异步 结束 ====
```

真窗口里点"开始"看秒表一秒一跳、进度条随 ticks 爬升；点"加载数据"看按钮变"加载中…"再落回——subscription 与 Task 在真实运行时里的样子。

## 坑位清单

- **`Subscription::tick` 已删**：定时用 `iced::time::every(duration)`；而且**必须开 tokio/smol feature**（默认一个运行时都不带），报"cannot find function `every`"先查 Cargo.toml。
- **`Subscription::run` 只收非捕获 fn 指针**：闭包直接类型不合；要捕获数据用 `run_with(data, fn)`，data 必须实现 `Hash`（订阅身份按它算）。
- **simulator 不执行 Task/Subscription**：无头断言"fetching 停在 true"是常态而非 bug；异步路径的消息要手动喂，同步核心抽函数单测。
- **`Instant::now()` 进 State = 告别确定性**：时间要么来自订阅消息（`time::every` 的回调给你 `Instant`），要么自计数。测试要的就是"喂三条 Tick = 计三秒"。
- **防重入要自己写**：连点两次"加载"会发两个 Task——update 里 `if self.fetching { return Task::none() }` 或用 `on_press_maybe(None)` 把按钮置灰（本例两招都用了）。

---

上一章：[13 · iced 主题与样式系统](13-iced-style.md) ｜ 下一章：[15 · iced Canvas 自绘：进度环](15-iced-canvas.md) ｜ 返回：[README](../README.md)
