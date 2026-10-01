# 36 · Ratatui 异步事件流

> 对应示例：[examples/36_ratatui_async](../examples/36_ratatui_async)

## 36.1 三路消息与 select!

TUI 主循环天然 async 友好——把"帧时钟 + 键盘事件 + 数据流"统一成消息，
`tokio::select!` 多路复用（官方 async-github 的骨架，数据源换本地模拟，
零联网）。对照 14 章（iced Subscription）/21 章（slint invoke）/29 章
（gtk channel）：第五种"后台数据到达 UI"的通道：

```rust
// ═══ 36.1 真终端腿：EventStream 只出现在这里 ═══
let msg = tokio::select! {
    _ = interval.tick() => Msg::Tick,
    Some(Ok(ev)) = events.next() => match ev {
        Event::Key(key) => Msg::Key(key),
        _ => Msg::Tick,          // 其它事件当空拍（保分支类型一致）
    },
    Some(n) = data_rx.recv() => Msg::Data(n),
};
if step(&mut app, msg) { return Ok(()); }
```

前置条件两件：`event-stream` 是 **crossterm 的 feature**（写在示例自己
的 crossterm 依赖上，版本钉 0.29 与 ratatui 内部统一）；`EventStream` 的
`.next()` 需要 `StreamExt`（crossterm 只实现 Stream，补 `tokio-stream`）。

## 36.2 可测纯核：step(Msg)

异步的时序不可复现，但**消息处理是纯函数**——一切状态变迁收进
`step(app, Msg) -> bool`，selftest 与真终端共用同一核：

```rust
// ═══ 36.2 纯核：消息是数据，序列是常量 ═══
enum Msg { Key(KeyEvent), Tick, Data(u32) }
fn step(app: &mut App, msg: Msg) bool { /* 状态变迁 + should_quit */ }

// selftest 腿：零 async，两跑天然逐字节一致
for msg in [Msg::Data(1), Msg::Data(2), Msg::Tick,
            Msg::Key(KeyEvent::from(KeyCode::Char('x'))),
            Msg::Key(/* Release 反例 */)] {
    assert!(!step(&mut app, msg));
}
assert!(step(&mut app, Msg::Key(KeyEvent::from(KeyCode::Char('q')))));
```

异步执行器面单独一条 `#[tokio::test]`：current_thread runtime +
**mpsc 先 send 完再 recv**（缓冲足够则顺序确定、无竞争窗口），验证同一
step 核在真异步壳里也正确——不引入时间虚拟化（interval/sleep 不进
selftest 任何路径）。

## 36.3 init/restore 与 runtime 的装配

`ratatui::run` 是同步闭包包装，异步骨架要自己装配——init 在 run 内、
restore 在收尾统一：

```rust
// ═══ 36.3 runtime 装配：init 进 run、restore 收尾 ═══
tokio::runtime::Builder::new_multi_thread().enable_all().build()?
    .block_on(async {
        let r = run().await;      // run() 内：ratatui::init() 拿 DefaultTerminal
        ratatui::restore();       // 统一恢复终端（非 Result 的 init）
        r
    })
```

## 36.4 运行与输出

```bash
cd G:\code\guide\rustgui
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 36_ratatui_async
```

实测输出（`build/36_ratatui_async.run.out`）：

```text
==== 36 ratatui 异步 开始 ====
received=2 ticks=1 quit=true row=数据块1
==== 36 ratatui 异步 结束 ====
```

真终端（`cargo run`）：数据块每 300ms 落一条进列表、tick 计数走表头、
q 退出。

## 坑位清单

- **`event-stream` 是 crossterm 的 feature**：写在示例自己的 `crossterm = { version = "0.29", features = ["event-stream"] }` 上——版本必须与 ratatui 内部统一（0.29），否则双版本共存、事件类型转换在编译期就炸（良性暴露，但报错难读）。
- **`EventStream.next()` 报 no method**：缺 `StreamExt`——`use tokio_stream::StreamExt as _;`（crossterm 只实现 Stream trait，next 是扩展方法）。
- **`ratatui::init()` 返回 `DefaultTerminal` 不是 Result**（0.30 便捷 API）；panic hook 自带，但异步骨架里 restore 要自己兜底收尾。
- **select! 的分支类型要一致**：非 Key 事件（Resize/Focus）也得映射成某分支的 Msg——映射成空拍 Tick 是最省事的写法（文档点明语义）。
- **双宽字符别用连续子串断言**：逐格收集的字符串里中文后跟 hidden 空格 cell——`contains("数据块 1")` 永远不中；按字符命中（`contains('数') && contains('1')`）或用 32 章的整行断言。

---

上一章：[35 · Ratatui 图表与画布](35-ratatui-charts.md) ｜ 下一章：[37 · Ratatui 综合实战：待办管理器](37-ratatui-app.md) ｜ 返回：[README](../README.md)
