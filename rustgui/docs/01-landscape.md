# 01 · 全景：Rust GUI 生态与四范式

> 本章无独立示例——它是四个 GUI 部分（egui 02–09 / iced 10–16 / Slint 17–23 / GTK4 24–30）加 TUI 支线（Ratatui 32–37）的地图。

## 1.1 Rust GUI 生态一页

Rust 的 GUI 之争远未收敛，2026 年的活跃阵营：

| 阵营 | 代表 | 一句话 |
|---|---|---|
| 即时模式 | **egui**、Makepad、**Ratatui**(TUI) | 界面是每帧重跑的函数，工具链友好、快出活（Ratatui 是它的终端投影，37.3 对照） |
| Elm 架构 | **iced**、Relm4(gtk) | 状态-消息-视图单向流，架构纪律最强 |
| 声明式 DSL | **Slint** | 界面是一门编译期语言，设计师/预览器/多语言宿主 |
| 系统原生绑定 | **GTK4（gtk4-rs）**、wxRust | 直接用成熟 C 工具箱，平台生态全套白拿 |
| Web 壳 | Tauri、Dioxus | 前端技术栈 + Rust 后端，包体小 |

本教程选前四家的理由：**它们恰好代表四种根本不同的界面范式**，且都能自动
验证（对齐 [cppgui](../../cppgui/README.md) 的多框架哲学）——"同一批任务写
四遍"配上"每条通道都能判卷"，范式差异不是听来的、是手上写出来的、还是
机器复核的。

## 1.2 四范式心智模型

同一颗按钮在四个世界里的样子：

| | egui（02 章） | iced（10 章） | Slint（17 章） | GTK4（24 章） |
|---|---|---|---|---|
| 界面定义 | Rust 函数，每帧执行 | Rust 构造的组件值树 | `.slint` 文件，编译期生成 | 持久控件树（代码/Builder XML） |
| 点击之后 | `if ui.button(..).clicked() { 改状态 }` | 按钮发 `Message` → `update` 改 State | TouchArea 的 `clicked =>` 触发回调 | 控件 `connect_clicked` 挂信号 |
| 界面更新 | 下一帧整帧重算 | 消息触发 view 重算 | 依赖跟踪的绑定即时更新 | 属性 `notify` 驱动监听者刷新 |
| 状态归属 | 你的结构体 | State + update 单点 | 属性/模型 + global | GObject 属性 + ListModel |
| "写界面"的感觉 | 画脚本 | 搭积木 + 立规矩 | 写配置 + 挖好接口 | 接线 + 定属性 |

没有最好的范式，只有匹配场景的范式——31 章会用同一个待办应用的四份实现给出量化对照。

## 1.3 版本断代史：为什么旧教程全失效

本教程编写时（2026-10）四个稳定版都刚经历断层，网上多数教程停在断点之前：

| 框架 | 本教程版本 | 断层 | 典型失效写法 |
|---|---|---|---|
| egui | 0.36.2 | 0.34 大重构（"More Ui, less Context"）、0.35 删除旧 API | `App::update(ctx, frame)`、`SidePanel::show(ctx, ..)`、`run_simple_native` |
| iced | 0.14.0 | 0.13 删 Sandbox/Application、Command→Task、样式系统重构 | `impl Sandbox for App`、`Command::perform`、`impl StyleSheet` |
| Slint | 1.18.1 | 1.18 移除 `slint::testing` 模块（换 i-slint-backend-testing） | `slint::testing::send_mouse_click(&handle, x, y)` |
| GTK4 | gtk4 0.11.5 | GTK 4.16 起 DrawingArea 回调 cairo 化；官方书停在 4.12 时代 | 照书的 snapshot 画法、`MainContext::channel` |

每章的坑位清单会精确收录这些断点的翻译对照。**判定教程新旧的第一眼**：看它的事件循环入口长什么样。

## 1.4 无头测试：五条通道

GUI 教程最难的不是写示例，是**验证示例**。本教程每章示例都有一条不开窗口的自动验证通道：

| | egui | iced | Slint | GTK4 | Ratatui(TUI) |
|---|---|---|---|---|---|
| 设施 | `egui_kittest`（官方） | `iced_test`（0.14 新增） | `i-slint-backend-testing`（官方） | `#[gtk::test]` + 直连句柄 | `TestBackend`（官方） |
| 查询 | AccessKit 无障碍树 | Text/TextInput/Id/Point 候选 | ElementHandle（元素 id/类型/无障碍） | **不需要查——句柄在手** | **不需要查——buffer 全量在手** |
| 注入 | click/type_text/key 事件 | click/typewrite/tap_key/simulate | 坐标点击 + a11y set_value + mock 时间 | `emit_*` 直发信号 + 属性赋值 | `KeyEvent` 纯数据直喂 |
| 断言面 | 节点 toggled/value + 应用状态 | 屏幕文本 find + 状态 | 属性/模型 + 几何 + mock 时间 | 控件属性/模型直读（27 章另有 cairo 像素级） | buffer 逐行/逐 cell（渲染输出本身） |

五家的通道哲学分三派：egui/iced/slint"构建 UI 后从外面查进来"（无障碍树/模拟器/元素查询），GTK 是 retained 模式送的大礼——控件本来就是持久对象、测试直接握句柄读写；Ratatui 更进一步——渲染边界就在 buffer，断言的就是渲染输出本身（TUI 的"像素"就是字符 cell）。共同点是都要**判卷纪律**：确定性
剧本、禁时间戳、两跑逐字节一致（各章 selftest 的共同铁律）。

无障碍树同时是测试接口——**可访问性和可测试性是同一件事**，这是前三家用
不同方式共同验证的结论；GTK 则证明另一条路：句柄即接口。

## 1.5 怎么读这本教程

- **顺序读**：四个 GUI 部分独立成线（02→09 / 10→16 / 17→23 / 24→30），TUI 支线（32–37）随时可读——与 egui 同范式，37.3 有两端对照；但同一任务的多份实现互为镜像——读过 egui 09 再读 16/23/30，范式差异会自己跳出来；
- **每章三步**：读讲解 → `pwsh -ExecutionPolicy Bypass -File build.ps1 -Example NN_xxx` 跑验证 → 改代码再跑看哪条断言红；
- **真窗口**：示例不带参数 `cargo run` 都开真窗口（自动验证走 `--selftest` 无头通道）；
- **首章速查**：各部分第一篇（02/10/17/24/32）把该框架的"无头通道"一次讲透，后面各章直接复用。

## 1.6 工具链与依赖

| 件 | 版本 | 备注 |
|---|---|---|
| rustc/cargo | 1.98.1 | edition 2024；egui 0.36 的 MSRV 是 1.95 |
| egui/eframe/egui_kittest | 0.36.2 | 与 crates.io 一致；注意 github master 领先已发布版 |
| egui_plot | 0.37 | **版本号与 egui 错位 +1**（配 egui 0.36 的是 0.37） |
| iced/iced_test | 0.14.0 | canvas/tokio 是独立 feature |
| slint/slint-build | 1.18.1 | i-slint-backend-testing 的 `internal` feature 在 1.18.1 有打包 bug，用 `ffi` + shim |
| gtk4（crate `gtk`） | 0.11.5 | 配 GTK 4.22（gvsbuild 2026.8.0）；第四部分环境三步见 24.1 |
| 依赖源 | TUNA 镜像 | `rustgui/.cargo/config.toml`（可删） |

首次全量构建约 15–30 分钟（egui+wgpu、iced+wgpu、slint+femtovg 三棵 GPU 树
+ GTK 的 26 包轻树），之后增量秒级——workspace 共享一个 `target/`。GTK 部分
在 Windows 需要 gvsbuild 运行时（24 章有完整安装步骤；Linux/macOS 用系统
包管理器装 gtk4 即可）。

## 坑位清单

- **网上教程先验版本再看内容**：2026 年的 Rust GUI 教程大面积停留在断点之前（egui 0.31-、iced 0.12-、slint::testing 时代、GTK 4.12 时代）。看到 `App::update(ctx, ..)` / `impl Sandbox` / `slint::testing` / DrawingArea 的 snapshot 画法四样之一，直接翻本教程对应章的新写法。
- **文档三态：docs.rs = crates.io = 本机 registry 源码 < github master**：github master 领先已发布版（egui 的 `Role`/`corner_radius`、gtk-rs 的 0.12.0-alpha 都是实例）——抄 master 代码会在稳定版上编译错。以 docs.rs 为准，必要时翻 registry 源码（路径见各章）。
- **egui_plot 版本号错位 +1**：配 egui 0.36 的是 egui_plot **0.37**。装错不报版本错，报的是"两份 egui 共存"的玄学类型不匹配（06 章有完整过程）。
- **iced 的 feature 门是默认关的**：`canvas`、`tokio`（time::every 要）、`image`、`svg` 都要显式开——"找不到这个控件/函数"九成是 feature 没开而不是代码错。
- **Slint 测试设施两处坑**：`slint::testing` 已移除（1.18）；i-slint-backend-testing 的 `internal` feature 在 1.18.1 发布包编译不过（打包 bug）。正解 = `ffi` feature + 4 行官方同款 shim（17.3 节）。
- **GTK 部分的环境前置**：Windows 上 GTK 栈不是 cargo 下载的——gvsbuild zip 解压 + 两个环境变量（24.1 三步），pkg-config 找不到 gtk4.pc 时九成是 `PKG_CONFIG_PATH` 没设。构建脚本已自动探测 `G:\gtk`/`C:\gtk`，装别处的读者看 24.1。

---

下一章：[02 · egui 最小应用：即时模式与无头测试](02-egui-hello.md) ｜ 返回：[README](../README.md)


