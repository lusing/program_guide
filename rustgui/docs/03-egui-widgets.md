# 03 · egui 控件全集：返回值即事件

> 对应示例：[examples/03_egui_widgets](../examples/03_egui_widgets)

## 3.1 Response：所有控件的统一返回值

egui 里几乎每个控件调用都返回 `Response`——它是这一帧里"这个控件发生了什么"的完整答卷：

| Response 成员/方法 | 含义 |
|---|---|
| `.clicked()` | 本帧被左键点中（按钮语义） |
| `.dragged()` / `.drag_delta()` | 正在拖拽（滑块语义） |
| `.changed()` | 控件改了绑定的值（TextEdit/Slider/CheckBox 语义） |
| `.hovered()` / `.contains_pointer()` | 悬停/指针落在矩形上 |
| `.request_focus()` / `.has_focus()` | 焦点操作与查询 |
| `.on_hover_text("…")` | 悬停提示（链式，返回自身） |
| `.labelled_by(id)` | 把说明标签挂到控件上（无障碍） |

同一颗 `Response` 同时服务于交互处理与样式反馈——这就是"返回值即事件"的全部。本章示例把常用控件各放一个，并用无头测试逐一真实操作。

## 3.2 状态控件四件套：checkbox / radio / slider / DragValue

```rust
// ═══ 3.1 按钮、复选、单选、滑块、数值微调 ═══
ui.horizontal(|ui| {
    if ui.button("Increment").clicked() {
        app.count += 1;
    }
    ui.label(format!("count = {}", app.count));
    ui.add(egui::DragValue::new(&mut app.count).range(0..=99));
});

ui.checkbox(&mut app.sauce, "Enable extra sauce");

ui.horizontal(|ui| {
    for (i, name) in ["Alpha", "Beta", "Gamma"].into_iter().enumerate() {
        ui.radio_value(&mut app.variant, i, name);
    }
});

ui.add(
    egui::Slider::new(&mut app.volume, 0.0..=100.0)
        .text("volume")
        .fixed_decimals(0),
);
```

- `checkbox`/`radio_value` 直接吃 `&mut` 你的字段——改值发生在控件内部，但**值在你结构体里**。
- `Slider::new(&mut f32, 0.0..=100.0)`：0.35 起所有 `impl Into<f32>` 参数被移除，区间必须写明 f32 字面量（写 `0..=100` 会推断成 i32 直接编译错）。
- `ui.add(widget)` 是万能插槽：所有 `Widget`（Slider/DragValue/ProgressBar/自定义控件）都从这进。

## 3.3 文本输入与 ID 冲突：push_id 正解

```rust
// ═══ 3.2 两个输入框 + push_id 分区 ═══
ui.horizontal(|ui| {
    ui.push_id("name-a", |ui| {
        ui.text_edit_singleline(&mut app.name_a);
    });
    ui.push_id("name-b", |ui| {
        ui.text_edit_singleline(&mut app.name_b);
    });
});
```

egui 靠 **Id** 跨帧记住"这是哪个控件"（焦点、光标、弹层开合、动画进度全挂在 Id 上）。Id 由**控件类型 + 所在 Ui 的 Id** 自动推导——于是两个 `text_edit_singleline` 放在同一个父 Ui 里会拿到**同一个 Id**：光标互串、焦点互抢、输入法状态互相污染，而且 egui 只在日志里告警一声，界面照样跑。

`ui.push_id("name-a", |ui| …)` 给子 Ui 换一个独立的 Id 前缀，是标准解法。经验法则：**同名控件出现第二次时，必用 push_id**。

## 3.4 ComboBox 与 ProgressBar

```rust
// ═══ 3.3 下拉框：selected_text + selectable_value ═══
egui::ComboBox::from_label("City")
    .selected_text(CITIES[app.city])
    .show_ui(ui, |ui| {
        for (i, c) in CITIES.iter().enumerate() {
            ui.selectable_value(&mut app.city, i, *c);
        }
    });

ui.add(
    egui::ProgressBar::new(app.volume / 100.0)
        .show_percentage()
        .text("progress"),
);
```

ComboBox 是"有内在状态"的控件（弹层开/合要跨帧记住），egui 内部就是用 Id 存的——你不用管，但要知道它为什么不丢状态。`from_label("City")` 同时给了无障碍标签，无头测试就靠它定位（见 3.6）。

## 3.5 菜单栏、弹窗与浮动窗口

```rust
// ═══ 3.4 菜单栏（0.32+ 新 API）+ 浮动窗口 ═══
egui::MenuBar::new().ui(ui, |ui| {
    ui.menu_button("Actions", |ui| {
        if ui.button("Reset all").clicked() {
            *app = WidgetsApp::new();
            app.last_menu = "reset".into();
            ui.close(); // 点完菜单项收起整个菜单树
        }
        if ui.button("Open window").clicked() {
            app.window_open = true;
            app.last_menu = "open".into();
            ui.close();
        }
    });
});

egui::Window::new("Floating")
    .open(&mut app.window_open)   // 开合状态存你的字段里
    .resizable(false)
    .show(ui.ctx(), |ui| {
        ui.label("I am a floating window");
    });
```

两个体系要分清：

- **Panel 系**（`CentralPanel`/`egui::Panel`，02/04 章）：参与主布局、互相挤压，`show(ui, …)` 挂在 **Ui** 上。
- **Area 系**（`Window`、`Popup`、`Tooltip`）：浮在一切之上的覆盖层，挂在 **Context** 上（`ui.ctx()`）。0.32 起菜单/弹窗/提示整体重写为 `MenuBar` + `ui.menu_button` + `Popup::menu(&response)`；点击菜单项后要 `ui.close()`，否则菜单不收。

`Window::open(&mut bool)` 把开合状态外置到你的字段——即时模式不给控件留藏私房钱的地方，一切都归你。

## 3.6 无头测试扩展集：角色查询与打字节奏

```rust
// ═══ 3.5 kittest：把每种控件真实操作一遍 ═══
use egui_kittest::kittest::{NodeT, Queryable};

let cb = harness.get_by_label("Enable extra sauce");
assert_eq!(cb.accesskit_node().toggled(), Some(egui::accesskit::Toggled::False));
cb.click();
harness.run();

// 两个输入框：get_* 要求唯一匹配，多节点用 get_all_ 的迭代器
harness.get_all_by_role(egui::accesskit::Role::TextInput).next().unwrap().focus();
harness.run();                                   // focus 生效
harness.get_all_by_role(egui::accesskit::Role::TextInput).next().unwrap().type_text("Ada");
harness.run();

// 下拉框：弹出层也在无障碍树里，直接点选项文本
harness.get_by_label("City").click();
harness.run();
harness.get_by_label("Shenzhen").click();
harness.run();
```

- `get_by_label` 按**无障碍标签**精确匹配；`get_by_role(Role::TextInput)` 按角色查；`query_by_label` 返回 `Option`（找不到不 panic）。
- `type_text` 只把 `Event::Text` 发给**当前焦点控件**——先 `.focus()` 再 `harness.run()`，然后**重新查询节点**再 `type_text`。少跑一步 run 或复用旧节点，文字就悄悄进了虚空。
- 复选框状态读 `accesskit_node().toggled()`（`NodeT` trait），这是无障碍树给出的权威答案，不依赖控件内部。

## 3.7 运行与输出

```bash
cd G:\code\guide\rustgui
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 03_egui_widgets
```

实测输出（`build/03_egui_widgets.run.out`）：

```text
==== 03 egui 控件全集 开始 ====
count=2 sauce=true variant=1 volume=40 city=2
name_a=Ada name_b=Lin
window_open=true last_menu=open
==== 03 egui 控件全集 结束 ====
```

这五行是每一种控件被真实操作后的终值：按钮 ×2、复选、单选 Beta、两个输入框各打一字段、下拉选 Shenzhen、菜单打开浮动窗口——全部发生在无头环境。

## 坑位清单

- **type_text 白打**：`type_text` 只发 `Event::Text` 给焦点控件。必须 `focus()` → `harness.run()` → 重查节点 → `type_text` → `harness.run()`。跳过中间的 run 是最常见的静默失败（测试照样绿，因为断言没查那个字段）。
- **run() 之后节点失效**：无障碍树每帧刷新，`run()` 前查到的 `Node` 不要复用——重新查询。官方 README 的示例也是每步重查。
- **get_* 系列唯一匹配 panic**：两个同名 TextInput 用 `get_by_role` 直接 panic（"Found two or more nodes"）。多节点场景一律 `get_all_by_*`（迭代器）或 `query_*`（Option）。
- **同名控件撞 Id**：两个 `text_edit_singleline` 同父放置共享 Id——焦点互抢、光标互串，只在你日志里留一条 warning。`push_id` 分区是唯一正解。
- **Window 挂 Context、Panel 挂 Ui**：`Window::show(ui.ctx(), …)` vs `CentralPanel::show(ui, …)`，参数传错编译器会教你做人。demo 里 `Window.show(ui, …)` 能编是因为 `&mut Ui` 可 Deref 强转成 `&Context`——自己写代码建议显式 `ui.ctx()`。

---

上一章：[02 · egui 最小应用：即时模式与无头测试](02-egui-hello.md) ｜ 下一章：[04 · egui 布局与统一 Panel 体系](04-egui-layout.md) ｜ 返回：[README](../README.md)
