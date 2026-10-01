# 32 · Ratatui 最小应用：buffer 心智与 TestBackend

> 对应示例：[examples/32_ratatui_hello](../examples/32_ratatui_hello)

## 32.1 第五范式：终端里的 immediate mode

Ratatui 是 TUI（终端 UI）框架——**终端就是一块"像素网格"，只是像素是 cell**
（一个字符 + 一套样式）。范式上它与 egui 同门：immediate mode——draw 闭包
每帧全量重画，状态全在你的结构体里，渲染函数是状态的纯投影。前四部分的
窗口框架各带一棵 GPU 依赖树；Ratatui 是**纯 cargo、零系统依赖、零 GPU**——
`Cargo.toml` 只需一行：

```toml
# ═══ 32.1 唯一的依赖：门面 crate（默认 feature 已含 crossterm 后端）═══
[dependencies]
ratatui = "0.30.2"
```

版本纪律（本部分的老规矩）：**0.30 是大断代点**——workspace 拆成门面
`ratatui` + `ratatui-core`/`ratatui-crossterm`/`ratatui-widgets`/`ratatui-macros`
四个子 crate（普通应用只依赖门面）、`assert_buffer_eq!` 宏废弃、Key 事件
必须按 kind 过滤。本地仓库 G:\github\rust\ratatui 的 tag `ratatui-v0.30.2`
与 crates.io 精确对齐，一切 API 以它为准。

## 32.2 官方骨架：run / draw / poll

```rust
// ═══ 32.2 真终端腿：官方 hello-world 骨架 ═══
fn main() -> std::io::Result<()> {
    if /* --selftest 分流 */ { run_selftest(); return Ok(()); }
    if !std::io::stdout().is_terminal() {
        println!("请在真终端运行");   // 误启动防御（CI/管道环境）
        return Ok(());
    }
    ratatui::run(run)               // init + alternate screen + panic hook
}

fn run(terminal: &mut DefaultTerminal) -> std::io::Result<()> {
    let mut app = App { quit: false, presses: 0 };
    while !app.quit {
        terminal.draw(|frame| render(frame, &app))?;  // 每帧全量重画
        if event::poll(Duration::from_millis(250))?
            && let Event::Key(key) = event::read()?
        {
            handle_key(&mut app, key);  // 输入不是回调：主循环里取队列
        }
    }
    Ok(())
}
```

`ratatui::run` 一站式装好 raw mode + alternate screen + panic hook（旧教程
十几行的 `enable_raw_mode + execute!(EnterAlternateScreen) + 手动 restore`
全部退役）。与 egui 对照读：`draw 闭包 ↔ App::ui 每帧函数`、
`poll/read ↔ 控件返回值即事件`、`request_repaint ↔ poll 超时兜底帧`。

## 32.3 TestBackend：最硬的无头通道

TUI 的渲染边界就在 **buffer**——框架的职责止于把 cell 网格填对，ANSI
转义、字体、颜色渲染属于终端模拟器（相当于 GTK 部分的运行时 DLL）。所以
官方 `TestBackend`（纯内存后端）的断言**就是真·渲染输出断言**——不需要
init、不需要事件循环、不需要窗口，比四条 GUI 通道都干净：

```rust
// ═══ 32.3 无头腿：TestBackend 纯内存渲染 + buffer 逐行断言 ═══
fn selftest_body() -> (u32, bool) {
    use ratatui::{Terminal, backend::TestBackend};
    let mut terminal = Terminal::new(TestBackend::new(24, 5)).expect("纯内存");
    terminal.draw(|frame| render(frame, &app)).expect("无头 draw");
    terminal.backend().assert_buffer_lines([
        "你好，Ratatui！        ", // 16 + 8 = 24
        "presses: 2              ",
        "按 q 退出 · 空格计数    ", // 20 + 4 = 24（'·' 是 1 列！）
        "                        ",
        "                        ",
    ]);
    // …KeyEvent 直喂 handle_key…
}
```

**双宽口径**（本部分 selftest 的命门，实测口径）：

1. 期望行补尾空格到**恰等于 backend 宽**（Buffer 的 PartialEq 含 area）；
2. 中文每字 **2 列**、ASCII 1 列；**`·`（U+00B7，East Asian Ambiguous）是
   1 列**——别按全角算（本章实测：按 2 算直接差 4 列炸断言）；
3. 双宽字符的"后半 cell"由框架自动置空，**断言 diff 会标注
   `hidden by multi-width symbols`**——读失败输出就能定位列错位；
4. `Buffer::with_lines` 的宽取各行显示宽的最大值，行数必须等于 backend 高。

## 32.4 事件驱动纯函数化

crossterm 的 `KeyEvent` 是纯数据——手工构造直喂 `handle_key`，无头测试
**绝不碰 `event::poll/read`**（无 tty 时行为不定，60s 超时杀手就是为它
准备的）。kind 过滤在纯函数里做：

```rust
// ═══ 32.4 kind 过滤：Release/Repeat 不当按键（0.29 起的经典坑）═══
fn handle_key(app: &mut App, key: KeyEvent) {
    if key.kind == KeyEventKind::Press {
        match key.code {
            KeyCode::Char('q') => app.quit = true,
            KeyCode::Char(' ') => app.presses += 1,
            _ => {}
        }
    }
}

// selftest 里连反例一起验：Release 的空格不计数
handle_key(&mut app, KeyEvent::new_with_kind(
    KeyCode::Char(' '), KeyModifiers::NONE, KeyEventKind::Release));
```

（`as_key_press_event()` 是 **Event** 级的过滤 helper——返回
`Option<&KeyEvent>`；拿到 KeyEvent 后判断 `kind` 字段是等价写法。）

## 32.5 视觉层的边界论证

GUI 部分每例有真窗口截图层；TUI 的对应物是什么？**答案就在 32.3 的论证
里**：ratatui 的"渲染"= 填 buffer，TestBackend 断言的就是渲染输出的全部；
真终端里多出来的东西（字体形状、配色、ANSI 效果）属于终端模拟器，不是
框架的行为。本教程曾实测官方录像工具 vhs（ttyd + 无头浏览器链）：Windows
的 ConPTY 与浏览器击键注入两层都不稳定（GitHub issues #721/#437），且它
验证的同样是"终端模拟器"而非框架——**放弃录像工具链，buffer 断言即视觉
验证**，真终端体验交给读者的 `cargo run`。

## 32.6 运行与输出

```bash
cd G:\code\guide\rustgui
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 32_ratatui_hello
```

实测输出（`build/32_ratatui_hello.run.out`）：

```text
==== 32 ratatui 最小应用 开始 ====
presses=3 quit=true buffer=24x5-asserted
==== 32 ratatui 最小应用 结束 ====
```

真终端（`cargo run`）：三行文字 + 空格计数 + q 退出。

## 坑位清单

- **`as_key_press_event()` 是 Event 的方法不是 KeyEvent 的**：E0599 报 no method——拿到 KeyEvent 后用 `key.kind == KeyEventKind::Press` 判断；旧教程 `if let Event::Key(key) = read()?` 不过滤 kind，Release/Repeat 全当按键（0.29 起 KeyEvent 有 kind 字段）。
- **`·` 等 East Asian Ambiguous 字符显示宽是 1 列**：中文按 2 列补空格时别把它算全角——断言 diff 的 `hidden by multi-width symbols` 标注是定位列错位的利器。
- **期望行宽必须恰等于 backend 宽**：Buffer PartialEq 含 area；`Buffer::with_lines` 取最大行宽当 buffer 宽，补多补少都炸（报 `buffer areas not equal` 并把期望/实际并排打印）。
- **selftest 禁用 `event::poll/read`**：无 tty 环境行为不定（阻塞/报错），事件一律手工构造 KeyEvent 直喂。
- **clippy 会合并 poll+read 的嵌套 if**：edition 2024 的 let 链（`if a && let ... = b {}`）一次写对，省一轮 -D warnings。

---

上一章：[31 · 四框架横评与选型](31-comparison.md) ｜ 下一章：[33 · Ratatui 布局：Constraint 与 Flex](33-ratatui-layout.md) ｜ 返回：[README](../README.md)
