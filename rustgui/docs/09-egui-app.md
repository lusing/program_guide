# 09 · egui 综合实战：待办管理器

> 对应示例：[examples/09_egui_app](../examples/09_egui_app)

## 9.1 统一规格：同一个应用写三遍

本章是 egui 部分的收官，也是 16 章（iced）、23 章（Slint）的对照基准——**同一个待办管理器**，六条共同规格：

1. 列表显示 2. 文本输入添加 3. 勾选完成 4. 删除条目 5. 综合组件（滚动列表）6. 框架特色亮点

egui 的亮点选了两样最能体现即时模式精髓的：**完成趋势迷你图**（egui_plot）和**后台线程 + mpsc + request_repaint 唤醒**。24 章会把三个实现并排比较——范式差异不是听来的，是同一任务写三遍写出来的。

## 9.2 状态：单一事实源

```rust
// ═══ 9.1 全部业务状态（界面是它的每帧投影）═══
struct Todos {
    items: Vec<Todo>,
    input: String,
    trend: Vec<[f64; 2]>,                        // 完成度历史
    worker_rx: Option<mpsc::Receiver<WorkerMsg>>, // 后台任务
    loaded_chunks: usize,
    fast_worker: bool,   // selftest 模式：worker 不 sleep（帧序确定）
}
```

没有控制器、没有 ViewModel、没有双向绑定——即时模式的架构就是"**一个结构体 + 一个每帧执行的 ui 函数**"。添加/勾选/删除都是三五行的事：

```rust
// ═══ 9.2 添加：Enter 或按钮，两条路汇进同一个 add() ═══
let input_resp = ui.add(
    egui::TextEdit::singleline(&mut app.input).hint_text("新待办…").desired_width(220.0),
);
let add = input_resp.lost_focus() && ui.input(|i| i.key_pressed(egui::Key::Enter));
if add || ui.button("添加").clicked() {
    app.add(); // 清 input、push 条目、记趋势点
}
```

注意 `hint_text`/`desired_width` 是 **TextEdit 构建器**的链式方法，必须在 `ui.add` 之前链——`ui.add` 返回的 `Response` 上没有它们（03 章坑位的进阶版）。

## 9.3 后台线程：mpsc + request_repaint

GUI 线程不能阻塞（卡一帧都看得见），耗时活丢给 `std::thread`，结果经 `mpsc` 流回来。egui 侧的模式是**每帧排空通道，有事则预约下一帧**：

```rust
// ═══ 9.3 worker：4 块数据 + Done ═══
fn start_worker(&mut self) {
    let (tx, rx) = std::sync::mpsc::channel::<WorkerMsg>();
    let fast = self.fast_worker;
    std::thread::spawn(move || {
        for i in 1..=4 {
            if !fast { std::thread::sleep(Duration::from_millis(60)); }
            if tx.send(WorkerMsg::Chunk(i)).is_err() { return; } // 接收端没了
        }
        let _ = tx.send(WorkerMsg::Done);
    });
    self.worker_rx = Some(rx);
}

// 每帧帧尾排空；借用拆开：先收进 Vec（rx 只读），再动 &mut self
fn drain_worker(&mut self, ctx: &egui::Context) {
    let messages = { /* 收空通道 */ };
    for msg in messages { /* Chunk -> 加条目记趋势；Done -> 收工 */ }
    if self.worker_rx.is_some() {
        ctx.request_repaint(); // 任务没完：约下一帧继续收
    }
}
```

另一个方向是 `ctx.request_repaint_from`——worker 线程发完消息**主动**唤醒 UI 线程，省去轮询帧。两者选一即可；本例轮询足够（任务运行时顶栏反正有 spinner，它本身就在请求重绘）。

## 9.4 列表与趋势图

```rust
// ═══ 9.4 列表：倒序遍历 + 局部标志位解开借用 ═══
for i in (0..app.items.len()).rev() {
    let mut toggled = false;
    let mut remove = false;
    ui.horizontal(|ui| {
        let todo = &mut app.items[i];
        // 复选框以待办文本为无障碍标签：可读屏、可点名点击
        if ui.checkbox(&mut todo.done, todo.text.clone()).changed() { toggled = true; }
        if ui.small_button("删").clicked() { remove = true; }
    });
    if toggled { app.record_trend(); }
    if remove { app.items.remove(i); }
}

// 趋势图：完成数随事件序号的折线
let line = egui_plot::Line::new("done", app.trend.clone());
egui_plot::Plot::new("trend").height(200.0).show(ui, |plot| plot.line(line));
```

两个细节：**倒序遍历**让"边遍历边删"不跳元素；闭包内只做交互、把 `&mut app` 的修改挪到闭包外，绕开 borrow checker（闭包借用 `items[i]` 时外层再借 `app` 会撞）。

## 9.5 无头剧本：完整用户旅程

```rust
// ═══ 9.5 相对查询点名"删"：get_all 的节点序是逆文档序，别赌顺序 ═══
let cb = harness.get_by_label("写综合实战");        // 条目复选框
let row = cb.parent().expect("条目应在一行里");     // NodeT::parent 上溯
let del = row.get_by_label("删");                   // 行内再定位删按钮
del.click();
```

selftest 剧本：输入"写综合实战"→添加→勾选→**按相对查询**删除→点"后台加载"→跑到稳定（Done 后不再请求重绘）→断言 4 块数据全部变成条目。这条剧本在 16/23 章会原样复刻——三种范式的同一张考卷。

## 9.6 运行与输出

```bash
cd G:\code\guide\rustgui
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 09_egui_app
```

实测输出（`build/09_egui_app.run.out`）：

```text
==== 09 egui 待办管理器 开始 ====
items=6 done=1 trend-points=8 chunks=4
==== 09 egui 待办管理器 结束 ====
```

数字对账：初始 2 条 − 删 1 条 + 手动添加 1 条 + 后台 4 块 = **items 6**；trend 初始 2 点 + 添加 1 + 勾选 1 + 后台 4 = **8 点**。真窗口里点"后台加载"看 spinner 转四块数据依次落进列表、趋势图同步爬升。

## 坑位清单

- **`get_all_by_label` 的节点序是逆文档序**（实测）：`.last()` 拿到的是**第一**行的按钮。跨行定位用相对查询：`node.parent()` 上到行、行内 `get_by_label` 再下钻——既稳又是更真实的用户视角。
- **TextEdit 的构建器方法在 `ui.add` 之前链**：`ui.text_edit_singleline(..)` 返回的 Response 上没有 `hint_text`/`desired_width`。
- **闭包里借了 items 就别再借 app**：勾选回调里直接 `app.record_trend()` 会 E0502。惯例是闭包内摆 `toggled/remove` 标志位，闭包外统一处理。
- **mpsc::Receiver 不能 Clone**：`Todos` 不能 derive Clone，selftest 用 `snapshot()` 拆出可 Clone 的证据字段。
- **worker 的 sleep 破坏帧确定性**：真窗口里 60ms/块合理，无头里消息必须"发完即达"。`fast_worker` 标志一刀切开两种节奏，测试与产品共用全部逻辑。

---

上一章：[08 · egui 自定义控件、动画与持久化](08-egui-custom.md) ｜ 下一章：[10 · iced 计数器：Elm 架构](10-iced-counter.md) ｜ 返回：[README](../README.md)
