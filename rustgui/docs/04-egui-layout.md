# 04 · egui 布局：统一 Panel 体系与两遍布局

> 对应示例：[examples/04_egui_layout](../examples/04_egui_layout)

## 4.1 面板即"空间谈判"

egui 的顶层布局靠**面板**：每块面板从剩余矩形里切走一条，剩下的给下一个。0.34 把原来的 `SidePanel`/`TopBottomPanel` 合并成一个 `egui::Panel`，四个方向只是构造函数不同：

```rust
// ═══ 4.1 顶栏 + 底栏 + 可拖宽的左侧栏 + 中央区 ═══
egui::Panel::top("top-bar")
    .exact_size(36.0)
    .show(ui, |ui| { /* 横向一条 */ });

egui::Panel::bottom("status-bar").exact_size(28.0).show(ui, |ui| {
    ui.label(format!("selected = {:?}", app.selected));
});

if app.side_open {
    egui::Panel::left("side")
        .resizable(true)       // 拖分隔条调宽
        .default_size(150.0)   // 首次打开的宽度（记住的是 egui Memory）
        .min_size(100.0)
        .show(ui, |ui| { /* 垂直一条 */ });
}

egui::CentralPanel::default().show(ui, |ui| { /* 剩余全部 */ });
```

三条铁律：

- **`show` 的第一个参数是 `&mut Ui`**，不再是 `&Context`（0.34 改的，0.35 删了旧的）。
- **顺序即嵌套**：先 show 的先分空间（更外层）。上面 top→bottom→left→central 的效果是：top 通栏，bottom 通栏，left 夹在两者之间，central 吃剩的。想要"left 通到顶"，把 left 挪到 top 前面。
- **CentralPanel 永远最后**——它是兜底的剩余空间持有者（带背景与内边距）。

`id_salt`（`"side"`、`"top-bar"`）是面板的身份：可拖宽度、开合记忆都挂在它上，只需在同一父 Ui 内唯一。

## 4.2 面板内部：三种排法

面板里的 `Ui` 自带布局方向（垂直为主），常用三种：

| 手段 | 用途 |
|---|---|
| `ui.horizontal(\|ui\| …)` | 局部横排（工具条、表单行） |
| `ui.columns(3, \|cols\| …)` | 等宽分列 |
| `egui::Grid::new(id).num_columns(n)` | 表格式对齐（跨行同列等宽） |

```rust
// ═══ 4.2 Grid：跨行对齐的 3x3 ═══
egui::Grid::new("demo-grid")
    .num_columns(3)
    .striped(true)
    .show(ui, |ui| {
        for r in 0..3 {
            for c in 0..3 {
                ui.label(format!("cell {r}-{c}"));
            }
            ui.end_row(); // Grid 必须显式换行
        }
    });
```

`Grid` 每列宽度取该列最宽单元格——跨行对齐它管，宽度自适应它管，但你要记得 `ui.end_row()`。

## 4.3 两遍布局（sizing pass）与 request_discard

egui 的布局是**两遍协商**（`Options::max_passes` 默认 2）：第一遍控件报告"我想要多大"，若与预分配不符，egui 调用 `Context::request_discard()` **丢弃这一遍结果**，按新尺寸再来一遍。`Grid`、`Window`、表格这类"尺寸依赖内容、内容又依赖尺寸"的控件全靠它。

体感层面的两条推论：

- **首帧布局可能"闪一下"再对齐**——那不是 bug，是 sizing pass 被丢弃重跑；
- **无头断言必须在 `harness.run()` 之后做**：`run()` 会跑到稳定，你看到的是最终布局。首帧就去查节点，查到的是中间态甚至空树。

## 4.4 无头断言：用 rect() 验证真实布局

```rust
// ═══ 4.3 面板真的被切出去了：Item 0 的左边缘 < 150 ═══
let item0 = harness.get_by_label("Item 0");
assert!(item0.rect().left() < 150.0);

// 收起侧栏 → 里面的控件整体消失于无障碍树
harness.get_by_label("Toggle side").click();
harness.run();
assert!(harness.query_by_label("Item 0").is_none());
```

`Node::rect()` 返回控件的逻辑坐标矩形——布局不是"看起来对了"，而是**可断言的数字**。`query_by_label`（Option 版）则用来断言"某控件不存在"：`get_by_label` 找不到会 panic，断言消失场景必须用 query 系。

## 4.5 运行与输出

```bash
cd G:\code\guide\rustgui
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 04_egui_layout
```

实测输出（`build/04_egui_layout.run.out`）：

```text
==== 04 egui 布局与面板 开始 ====
side_open=false show_grid=false selected=Some(2)
==== 04 egui 布局与面板 结束 ====
```

三个终值对应无头剧本的三步：选中 Item 2（底栏联动 `selected = item 2`）、收起侧栏、关掉 Grid。真窗口里再拖一拖左侧栏分隔条，宽度会被 egui 记住——重开应用还在（存在 app 数据目录的 egui Memory 里）。

## 坑位清单

- **show 参数换位**：`Panel::show(ui, …)` 接 Ui、`Window::show(ui.ctx(), …)` 接 Context——面板参与布局谈判，窗口是覆盖层。旧代码把 ctx 传给面板在 0.36 直接编译错。
- **CentralPanel 忘在最后**：先 show 中央区再 show 侧栏，侧栏只能从零宽矩形里切——界面"少了一块"但不报错。
- **Grid 忘 end_row()**：所有单元格挤在一行里。编译不报、运行不警告，纯布局事故。
- **断言抢先于 run()**：两遍布局 + 弹层稳定都需要帧推进，构建 Harness 后立刻查树可能拿到 sizing pass 的中间态。`build_eframe` 自带一次 `run_ok()`，但交互之后的新断言必须自己再 `run()`。
- **面板宽度不是你的字段**：`resizable` 的宽度记在 egui 的 Memory 里（持久化在 `app_id` 名下）。想要"宽度归我管"，用 `exact_size` 锁死。

---

上一章：[03 · egui 控件全集：返回值即事件](03-egui-widgets.md) ｜ 下一章：[05 · egui 自绘：Painter 与逐帧动画](05-egui-painter.md) ｜ 返回：[README](../README.md)
