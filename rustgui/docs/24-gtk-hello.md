# 24 · GTK4 最小应用：retained 模式与直连测试通道

> 对应示例：[examples/24_gtk_hello](../examples/24_gtk_hello)

## 24.1 环境：Windows 上的 GTK 从哪来

GTK 是四家里唯一的"C 库 + Rust 绑定"架构：控件、信号、主循环都在 C 库里，
gtk4 crate（0.11.5，本教程钉版）只是 gir 生成的安全封装。Windows 上没有系统
包管理器可用，官方书《GUI development with Rust and GTK 4》的 Windows 章首选
**gvsbuild** 路线——gvsbuild 项目在 GitHub Releases 提供用 MSVC 预编译的全栈 zip，
解压即用，与本仓库的 rustc（纯 MSVC）天然配套：

```
三步装好（一次性）：
  1. 下载 gvsbuild release zip（如 GTK4_Gvsbuild_2026.8.0_x64.zip，含 GTK 4.22）
     → 解压到 G:\gtk（bin/ lib/ include/ 平铺在根；zip 自带 pkg-config.exe）
  2. 用户环境变量：PATH 追加 G:\gtk\bin；PKG_CONFIG_PATH 追加 G:\gtk\lib\pkgconfig
  3. 验证：pkg-config --modversion gtk4   → 4.22.4
```

之后 cargo 侧一切照常——gtk4-sys 的构建脚本经 system-deps 调 pkg-config
（MSVC 目标自动加 `--msvc-syntax`，输出 `/libpath:G:/gtk/lib` 这类 MSVC 形态）。
依赖树轻得惊人：**新增仅 26 个包**（glib/gio/gdk/gsk/cairo/pango/graphene 全家
+ sys 层 + system-deps 工具链），没有 wgpu、没有 GPU 树——对照第一部分 egui 的
700 包基线，这是"C 库绑定"路线的直接红利。本仓库的 `build.ps1` /
`tools/gui-shots.ps1` 会自动探测 `G:\gtk`（或 `C:\gtk`）注入环境，装在别处的
读者把两个变量设进系统即可。

```toml
# ═══ 24.1 Cargo.toml：package 重命名是官方惯例（cargo add gtk4 --rename gtk）═══
[dependencies]
gtk = { package = "gtk4", version = "0.11.5" }
```

注意版本纪律：gtk-rs 的 github master（0.12.0-alpha）领先已发布版，且官方书按
GTK 4.12 时代撰写——本部分一切 API 以 **crates.io 0.11.5** 编译结果为准（与
egui 部分"以 registry 为准、别照 master 抄"同一条铁律）。

## 24.2 第四种范式：retained 模式

前三部分见过三种范式：egui 每帧重跑（即时）、iced 单向数据流（Elm）、Slint
声明式 DSL。GTK 是第四种——**retained 模式**：控件树建立后持久存在，框架持有
它、负责重绘，你只持有控件句柄、在信号回调里改状态。最小真窗口：

```rust
// ═══ 24.2 Application/activate/run：真窗口腿（官方 basics 同款）═══
fn main() -> glib::ExitCode {
    if std::env::args().nth(1).is_some_and(|a| a == "--selftest") {
        run_selftest();
        return glib::ExitCode::from(0);
    }
    let app = gtk::Application::builder()
        .application_id("org.rustgui.GtkHello")
        .build();
    app.connect_activate(build_ui);
    app.run()   // 进主循环；startup 时自动完成 gtk 初始化
}
```

`run()` 进了 GTK 主循环就出不来了——所以它只属于"真窗口腿"。无头腿不建
Application、不 `run()`，走 `gtk::init()` + 直接构造控件。两条腿共用同一个
`Counter` 构造函数（同一张考卷，和 02/10/17 章的约定一致）。

## 24.3 GObject 心智模型：句柄与引用计数

GTK 的每个控件背后是一个 GObject——引用计数的 C 对象。Rust 侧的 `gtk::Button`
是**句柄**不是本体：`clone()` 只是引用 +1（纳秒级），不是深拷贝。事件回调要求
`'static`，惯例就是闭包捕获 clone：

```rust
// ═══ 24.3 闭包捕获 clone：计数器状态与标签的联动 ═══
let count = Rc::new(Cell::new(0));
let label = gtk::Label::new(Some("count: 0"));
let button = gtk::Button::with_label("Increment");
{
    let count = count.clone();
    let label = label.clone();
    button.connect_clicked(move |_| {
        count.set(count.get() + 1);
        label.set_text(&format!("count: {}", count.get()));
    });
}
```

对照三家的"状态放哪"：egui 状态在 App 结构体（每帧借给 UI）、iced 状态在
Message 驱动的 model、Slint 状态在 .slint 属性；GTK 的状态可以**就在控件里**
（label 的 text 属性），也可以在 `Rc<Cell<T>>` / 自定义 GObject 属性里——本例
两者并存，`count` 是真相源、label 是投影。属性还有通用通道
`widget.property::<String>("text")` / `set_property()`，25 章展开。

## 24.4 无头测试通道：直连驱动 + 直连断言

GTK4 没有 kittest/simulator 那样的官方无头设施（官方 CI 靠 Linux 的 Xvfb 虚拟
显示器，Windows 无等价物）。但 retained 模式送了一份大礼：**测试根本不需要查询
UI 树——手里本来就攥着 Button/Label 本尊**。通道三步定式：

```rust
// ═══ 24.4 驱动：emit_* 直发信号 → 排空主循环 → 属性断言 ═══
fn selftest_body() -> (i32, String) {
    gtk::init().expect("gtk::init 失败（需要交互桌面会话）");
    let c = Counter::new();
    assert_eq!(c.text(), "count: 0");

    c.button.emit_clicked();   // 直连驱动：同步派发 connect_clicked 回调
    c.button.emit_clicked();
    c.button.emit_clicked();

    let ctx = glib::MainContext::default();   // 排空挂起的 idle/回调
    while ctx.pending() {
        ctx.iteration(false);
    }
    (c.value(), c.text())
}
```

`cargo test` 通道用官方 **`#[gtk::test]`** 属性（替代裸 `#[test]`）：它把测试
放进一个独占单线程池，池线程上自动 `gtk::init()`，所有测试串行——这是 gtk4-rs
为"GTK 单线程 + Rust 测试多线程"这对矛盾准备的官方解法：

```rust
#[cfg(test)]
mod tests {
    #[gtk::test]
    fn three_clicks_count_to_three() {
        let (clicks, text) = super::selftest_body();
        assert_eq!((clicks, text.as_str()), (3, "count: 3"));
    }
}
```

四条通道对照（01 章总表的补全）：

| 框架 | 通道 | 查找控件 | 驱动方式 |
|---|---|---|---|
| egui | egui_kittest | 无障碍树查询 `get_by_label` | 坐标点击/键入 |
| iced | iced_test | 文本选择器 `click("文本")` | 模拟点击→收消息 |
| Slint | testing backend | ElementHandle（id 查询） | 坐标注入/属性注入 |
| **GTK4** | **`#[gtk::test]` + 直连** | **不需要查——持有句柄** | **`emit_*` 直发信号** |

诚实边界：这条通道**不渲染任何像素**（比 kittest 还彻底），样式与字形的最终
裁决在真窗口截图层（`tools/gui-shots.ps1`，见 24.6）。

## 24.5 中文：免费的一餐

egui 部分 07 章为中文注册字体费了大劲（0.36.2 无系统回退，08/09 曾满屏豆腐块）。
GTK 经 Pango 走系统字体栈，**中文直接可写**——本例窗口第三行就是一条中文标签，
零配置：

```rust
// ═══ 24.5 对照 egui 07：这里没有 install_cjk_font，也不需要 ═══
let caption = gtk::Label::new(Some("GTK 自带系统字体回退：中文直接可写"));
```

真窗口截图逐字验证通过（见 24.6）。这不是 GTK 更"高级"，而是架构差异的副产品：
成熟 C 库把字体协商、回退、整形都做在了框架层——横评章（31）会回到这点。

## 24.6 运行与输出

```bash
cd G:\code\guide\rustgui
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 24_gtk_hello
```

实测输出（`build/24_gtk_hello.run.out`）：

```text
==== 24 gtk 最小应用 开始 ====
clicks=3 label="count: 3"
==== 24 gtk 最小应用 结束 ====
```

真窗口（`cargo run`）：标题 `24 gtk hello`，`count: 0` + `Increment` 按钮 +
中文说明行。点击按钮计数增长；`tools/gui-shots.ps1` 的截图里中文说明行逐字
渲染正确（`build/gui-shots/24_gtk_hello.png`，422×215）。

## 坑位清单

- **`gtk::init()` 跨线程二次初始化直接 panic**：GTK 是单线程库，测试构建下从第二个线程 init 会报 `Use #[gtk::test] instead of #[test]`。每个示例只留一个测试函数且用 `#[gtk::test]` 包；`--selftest` 走 main 线程显式 `init()`（同线程幂等，`rt.rs` 源码实证）。
- **GTK4 没有 `gtk::main()`/`gtk_main_iteration`**：GTK3 的老接口全删了，排空主循环只能写 glib 的 `MainContext::default()` + `pending()`/`iteration(false)` 循环。照 GTK3 教程抄这两处的代码编译不过。
- **`app.run()` 会占住线程**：真窗口腿和无头腿必须分开写。selftest 里构造 Application 但不 `run()`，startup 钩子不触发、控件构造会因未初始化 panic——无头腿第一行永远是 `gtk::init()`。
- **`set_title` 吃 `Option<&str>`**：0.11.5 里是 `win.set_title(Some("..."))`；旧版绑定/旧书是裸 `&str`，混抄报类型错。
- **依赖找不到时的报错在 build script 里**：`PKG_CONFIG_PATH` 没设对时 gtk4-sys 报 `pkg-config exited with failure`，而且 MSVC 目标要求 pkg-config 支持 `--msvc-syntax`（本机 perl 版的 pkg-config.bat 不支持，gvsbuild zip 自带的 pkg-config.exe 才是正解）。
- **GitHub master ≠ crates.io（又一次）**：gtk-rs master 是 0.12.0-alpha，官方书按 GTK 4.12 撰写；DrawingArea 回调签名等已随 GTK 4.16 改过（27 章实录）。一律以 0.11.5 编译为准。

---

上一章：[23 · Slint 综合实战：待办管理器](23-slint-app.md) ｜ 下一章：[25 · GTK 控件、信号与 Builder](25-gtk-widgets-signals.md) ｜ 返回：[README](../README.md)
