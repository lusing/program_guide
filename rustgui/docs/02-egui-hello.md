# 02 · egui 最小应用：即时模式与无头测试

> 对应示例：[examples/02_egui_hello](../examples/02_egui_hello)

## 2.1 即时模式：界面是函数，不是对象

传统 GUI（wxWidgets、Qt、WinForms）是**保留模式**：控件树常驻内存，你注册回调、框架在事件到来时调用你。egui 反其道而行——**界面是每帧重新执行的函数**：

| | 保留模式（wx/Qt） | 即时模式（egui） |
|---|---|---|
| 控件生命周期 | 创建后常驻，直到销毁 | 每帧"重建"，函数返回即消失 |
| 事件 | 回调注册（`Bind(wxEVT_BUTTON, …)`） | 返回值（`ui.button(..).clicked()`） |
| 状态归属 | 控件内部（`GetValue()/SetValue()`） | **你的结构体**，控件只是状态的临时投影 |
| 重绘时机 | 系统事件驱动 | 状态变了就整帧重跑（默认连续重绘也可调成按需） |

这套模型源自游戏引擎的调试覆盖层（Dear ImGui 一脉），Rust 里 egui 是事实标准：零 unsafe、同一份代码跑在原生（wgpu/glow）和 WebAssembly 上。

**版本警告（读旧教程前必看）**：egui 在 0.34（2026-03）做了"The More `Ui`, the less `Context`"大重构，0.35（2026-06）把所有旧 API **物理删除**。网上大量教程还停在 0.31 及以前的写法，在 0.36 上直接编译失败。三个最典型的断点：

- `App::update(&mut self, ctx, frame)` → **`App::ui(&mut self, ui, frame)`**；
- `SidePanel`/`TopBottomPanel`/`CentralPanel::show(ctx, …)` → 统一的 **`egui::Panel`** 体系，`show` 第一个参数是 **`&mut Ui`** 而不是 `&Context`（04 章细讲）；
- `eframe::run_simple_native` → **已删除**，只剩 `run_native`。

本教程全部按 0.36.2 写。

## 2.2 工程与入口

```toml
# ═══ 2.1 依赖清单（examples/02_egui_hello/Cargo.toml）═══
[dependencies]
eframe = "0.36"        # 应用框架：窗口 + 事件循环 + 渲染后端
egui = "0.36"          # 界面库本体（eframe 也 re-export 了它）
egui_kittest = { version = "0.36", features = ["eframe"] }  # 无头测试（见 2.5）
```

```rust
// ═══ 2.2 main：run_native 三件套 ═══
fn main() -> eframe::Result {
    let options = eframe::NativeOptions {
        viewport: egui::ViewportBuilder::default().with_inner_size([320.0, 200.0]),
        ..Default::default()
    };
    eframe::run_native(
        "02_egui_hello",   // 应用名（也是持久化存储的默认 key）
        options,
        Box::new(|_cc| Ok(Box::new(CounterApp::new()))),
    )
}
```

三处 0.36 的"新姿势"：

1. **`AppCreator` 返回 `Result`**——闭包是 `Box<dyn FnOnce(&CreationContext) -> Result<Box<dyn App>, DynError>>`，所以写作 `Ok(Box::new(...))`。`CreationContext` 里有字体、样式、持久化数据，`App::new(cc)` 接住它。
2. 窗口标题、尺寸、图标都在 `NativeOptions::viewport`（`ViewportBuilder`）里设，不再是 `Settings` 结构。
3. `main` 返回 `eframe::Result`——启动失败（比如没有可用的渲染适配器）会把错误交还给你，而不是直接 panic。

## 2.3 App trait：每帧调用的 ui()

```rust
// ═══ 2.3 应用状态 + App 实现 ═══
struct CounterApp {
    count: i64,
}

impl CounterApp {
    fn ui_body(ui: &mut egui::Ui, count: &mut i64) {
        ui.heading("Hello egui!");
        ui.label(format!("count: {count}"));
        if ui.button("Increment").clicked() {
            *count += 1;
        }
    }
}

impl eframe::App for CounterApp {
    fn ui(&mut self, ui: &mut egui::Ui, _frame: &mut eframe::Frame) {
        egui::CentralPanel::default().show(ui, |ui| Self::ui_body(ui, &mut self.count));
    }
}
```

四个要点：

- **`fn ui(&mut self, ui: &mut egui::Ui, frame)`** 是 0.34 起的唯一必须方法（旧名 `update` 已删）。eframe 每帧把一个**根 `Ui`** 递给你——它没有边距、没有背景，惯例是先包一层 `CentralPanel`。
- `ui_body` 抽成关联函数、状态以参数进出：真窗口（`App::ui`）和无头测试（2.5 的 kittest）喂的是**同一份代码**，测试与生产永不漂移。
- `ui.button("Increment").clicked()`——事件就是返回值。这一帧用户点了，`clicked()` 是 `true`，你当场改状态；下一帧界面自动反映新状态。**没有回调、没有监听器、没有信号槽。**
- `count` 存在你的结构体里而不是控件里。即时模式里"控件"只是一段每帧执行的绘制+交互代码，**状态永远在你手里**——这是全章最重要的一句话。

## 2.4 无头测试：egui_kittest

GUI 教程最常见的尴尬：示例"能跑"全靠作者口说。本教程每个示例都有一条**无头验证通道**——不开窗口、不要 GPU、`cargo test` 就能真实点击控件并断言状态。egui 这条通道是官方的 `egui_kittest`（基于 AccessKit 无障碍树做查询）：

```rust
// ═══ 2.4 kittest：驱动完整 eframe::App ═══
fn selftest_body() -> i64 {
    use egui_kittest::kittest::Queryable; // get_by_label 等查询方法的 trait

    let mut harness = egui_kittest::Harness::builder()
        .build_eframe(|_cc| CounterApp::new());

    let button = harness.get_by_label("Increment");
    button.click();
    button.click();
    button.click();
    harness.run(); // 处理排队的事件，直到界面稳定

    harness.state().count // state 就是 CounterApp 本身
}
```

- `Harness::builder().build_eframe(...)` 直接驱动你的 `eframe::App`——`harness.state()` 就是应用实例，可以随便断言。
- `get_by_label("Increment")` 按 AccessKit 无障碍标签查节点：`ui.button("X")` 的标签就是 `"X"`。查询 API 由 `Queryable` trait 提供（`get_by_label`/`get_by_role`/`query_by_label`…），**trait 必须显式 `use` 进来**，否则编译器报"no method named get_by_label"。
- `click()` 只是入队事件，`harness.run()` 把事件跑到界面稳定（默认最多 4 步——持续动画的 UI 会撞上限，05 章讲 `run_steps`）。
- 同一个 `selftest_body()` 被 `#[test]` 和 `--selftest` 两条入口复用——这就是本仓库验证协议的第 3、4 层。

## 2.5 运行与输出

```bash
cd G:\code\guide\rustgui
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 02_egui_hello
```

实测输出（`build/02_egui_hello.run.out`）：

```text
==== 02 egui 最小应用 开始 ====
count after 3 clicks = 3
==== 02 egui 最小应用 结束 ====
```

不带参数的 `cargo run` 打开真实窗口：点几下 Increment，看看每帧重跑的世界。改代码后重跑 `build.ps1 -Example 02_egui_hello`，四层验证（fmt → clippy → test → selftest）一轮过才算数。

## 坑位清单

- **旧教程全灭三连**：`App::update(ctx, …)`、`SidePanel::left("id").show(ctx, …)`、`eframe::run_simple_native` 在 0.36 **全部不存在**（0.34 引入新 API，0.35 物理删除旧的）。看到这三样的教程，参照本章/04 章的对应新写法翻译。
- **根 Ui 是"裸"的**：`App::ui` 给你的 Ui 没有边距没有背景，直接往里放控件会顶着窗口边缘。先包 `CentralPanel::default().show(ui, …)`。
- **`eframe::Frame` ≠ `egui::Frame`**：前者是 `ui()` 的第三个参数（运行环境句柄），后者是带边距/圆角/背景的容器装饰。同名纯历史原因，报错信息里分不清时看 import。
- **Queryable/NodeT 不导入就没方法**：`get_by_label` 来自 `kittest::Queryable` trait、`accesskit_node()` 来自 `kittest::NodeT` trait，都要显式 `use`，编译器只提示"similar name"。
- **AppCreator 闭包要返回 Result**：`Box::new(|cc| Ok(Box::new(MyApp::new(cc))))`——少写 `Ok` 时错误信息一大屏泛型对不上，先检查这一处。

---

上一章：[01 · 全景：Rust GUI 生态与三范式](01-landscape.md) ｜ 下一章：[03 · egui 控件全集：返回值即事件](03-egui-widgets.md) ｜ 返回：[README](../README.md)
