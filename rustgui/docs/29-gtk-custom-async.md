# 29 · GTK 模板控件与异步

> 对应示例：[examples/29_gtk_custom_async](../examples/29_gtk_custom_async)

## 29.1 GObject 子类化：自定义控件的底座

GTK 里"自定义控件"不是实现某个 Rust trait（对照 08 章 egui 的 `impl
Widget`），而是**派生一个新 GObject 类型**。完整仪式三件套：私有结构 +
`#[glib::object_subclass]` + `glib::wrapper!`：

```rust
// ═══ 29.1 子类化三件套（ParentType = gtk::Box）═══
mod imp {
    #[derive(Default, gtk::CompositeTemplate)]
    #[template(file = "../ui/task_card.ui")]   // 路径相对本源文件！
    pub struct TaskCard {
        #[template_child]
        pub title: gtk::TemplateChild<gtk::Label>,
        #[template_child]
        pub status: gtk::TemplateChild<gtk::Label>,
        #[template_child]
        pub progress: gtk::TemplateChild<gtk::ProgressBar>,
    }

    #[glib::object_subclass]
    impl ObjectSubclass for TaskCard {
        const NAME: &'static str = "RustGuiTaskCard";   // = XML 的 template class
        type Type = super::TaskCard;
        type ParentType = gtk::Box;
        fn class_init(klass: &mut Self::Class) { klass.bind_template(); }
        fn instance_init(obj: &glib::subclass::InitializingObject<Self>) {
            obj.init_template();   // 忘写 = 运行时 panic
        }
    }
    impl ObjectImpl for TaskCard {}
    impl WidgetImpl for TaskCard {}
    impl BoxImpl for TaskCard {}
}

glib::wrapper! {
    pub struct TaskCard(ObjectSubclass<imp::TaskCard>)
        @extends gtk::Box, gtk::Widget,
        @implements gtk::Buildable, gtk::ConstraintTarget, gtk::Orientable;
}
```

模板 XML 用 `<template class="RustGuiTaskCard" parent="GtkBox">` 声明自身，
child 的 **id 必须与 `#[template_child]` 字段名一致**（不一致时运行时
`Gtk-CRITICAL: Unable to retrieve child object 'progress'` + panic——三个
id 错一个就炸在第一个）。

`init_template` 在**构造时**就执行——所以无头测试不需要窗口 realize，
`TaskCard::new()` 完 `imp()` 拿到的 child 就能直读直写。这是模板路线对
无头测试最友好的一点。

## 29.2 异步腿：spawn_blocking + channel + spawn_future_local

官方书 `main_event_loop` 章的标准范式（对照 09 章 egui 的 mpsc +
request_repaint、14 章 iced 的 `time::every`、21 章 Slint 的
`invoke_from_event_loop`）：

```rust
// ═══ 29.2 worker 干重活，UI 线程收 ═══
fn run_task(card: &TaskCard) -> Rc<Cell<u32>> {
    let (tx, rx) = async_channel::bounded::<u32>(4);      // glib 0.22 没有
    gtk::gio::spawn_blocking(move || {                     // MainContext::channel！
        for i in 1..=4u32 {
            let _ = tx.send_blocking(i);   // worker 侧阻塞发；UI 侧才 await
        }
    });

    let card = card.clone();
    let received = Rc::new(Cell::new(0u32));
    let got = received.clone();
    glib::spawn_future_local(async move {
        while let Ok(i) = rx.recv().await {   // async-channel 的 recv 返回 Result
            got.set(i);
            card.set_progress(i as f64 / 4.0);
            card.set_status(&format!("块 {i}/4"));
        }
        card.set_progress(1.0);               // 通道关闭（worker 结束）→ 收尾
        card.set_status("完成");
    });
    received   // 观察哨：selftest 的断言抓手
}
```

三个要点：**glib 0.22 没有 `MainContext::channel`**（通道用 async-channel
crate）；worker 侧用 `send_blocking`、UI 侧 `recv().await`（**recv 返回
`Result`**，通道关闭是 `Err`——正好当循环出口）；`spawn_future_local` 只能
在拥有默认 MainContext 的线程跑（`gtk::init()` 已经 acquire，主线程直接用）。

## 29.3 无头剧本：终态断言 + 条件排空

异步自带时序，无头断言只打**终态**（不测中间帧），排空用"条件 + 上限"：

```rust
// ═══ 29.3 条件排空：轮询主循环 + 给 worker 线程推进时间 ═══
fn pump_until(pred: impl Fn() -> bool) {
    let ctx = glib::MainContext::default();
    for _ in 0..600 {                       // 上限约 3s
        while ctx.pending() { ctx.iteration(false); }
        if pred() { return; }
        std::thread::sleep(Duration::from_millis(5));  // 等 worker 推进
    }
}

// selftest：模板初值 → 异步终态
assert_eq!(card.status(), "待启动");         // init_template 的 XML 初值
let received = run_task(&card);
pump_until(|| received.get() == 4 && card.status() == "完成");
assert_eq!((received.get(), card.fraction()), (4, 1.0));
```

`sleep` 只等**外部线程**推进、不看时钟读数，selftest 输出依旧两跑逐字节
一致（sleep 不进输出）。

## 29.4 运行与输出

```bash
cd G:\code\guide\rustgui
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 29_gtk_custom_async
```

实测输出（`build/29_gtk_custom_async.run.out`）：

```text
==== 29 gtk 模板与异步 开始 ====
title=任务卡 chunks=4 fraction=1.00 status=完成
==== 29 gtk 模板与异步 结束 ====
```

真窗口（`cargo run`）："任务卡 / 待启动 / 空进度条 / 开始任务"。点按钮看
进度条按 25% 步进四次、"块 1/4"→"完成"。截图（368×229）核对初始态一致。

## 坑位清单

- **`#[template(file)]` 的路径相对源文件**：`src/main.rs` 里写 `"../ui/x.ui"`（不是相对 Cargo.toml）；官方例程的 imp.rs 与 .ui 同目录所以书里是裸文件名——照书抄路径差一层。
- **XML id ≠ 字段名 → 运行时才炸**：`Gtk-CRITICAL: Unable to retrieve child object 'x' ... while building`，随后 `init_template` 里 panic 且**不可 unwind**（abort）。字段名与 id 保持一致，或 `#[template_child(id = "x_id")]` 显式指定。
- **wrapper! 的 @implements 里 `gtk::Accessible` 在 0.11.5 bin target 下 E0425**：删掉即可——接口已由父类链（gtk::Box → gtk::Widget）继承实现，功能无损（`Buildable/ConstraintTarget/Orientable` 保留）。官方例程带 v4_10 feature 编过，零 feature 下实测过不了。
- **glib 0.22 没有 `MainContext::channel`**：用 async-channel crate；worker 侧 `send_blocking`、UI 侧 `recv().await`，且 recv 返回 `Result`（`while let Ok(i)`，关闭即出口）——书里 if let Some 的旧形态是 futures-channel 时代的。
- **`gio::spawn_blocking` 返回 `JoinHandle`**：不是 Result，没有 `.expect`；"发射后不管"就不碰它，UI 侧靠通道闭合收尾。
- **`imp()` 在 `subclass::prelude`**：顶层只 `use gtk::prelude::*` 时报 "no method named imp"——补 `use gtk::subclass::prelude::*`。

---

上一章：[28 · GTK 模型与列表](28-gtk-models.md) ｜ 下一章：[30 · GTK 综合实战：待办管理器](30-gtk-app.md) ｜ 返回：[README](../README.md)
