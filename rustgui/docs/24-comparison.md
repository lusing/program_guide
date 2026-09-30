# 24 · 三框架横评与选型

> 本章无独立示例——素材全部来自 09/16/23 三份同规格实现与前 22 章的实测。

## 24.1 同一应用，三种范式

待办管理器的六条共同规格在三家的落点：

| 规格 | egui（09） | iced（16） | Slint（23） |
|---|---|---|---|
| 列表显示 | ScrollArea（急切） | scrollable（急切） | ListView（**虚拟化**） |
| 输入添加 | TextEdit + Enter | `text_input.on_submit` | LineEdit `accepted` |
| 勾选完成 | checkbox 就地改 | checkbox → 消息 | 点行 TouchArea |
| 删除条目 | 相对查询找按钮 | 唯一命名按钮 | `for todo[i]` 索引回调 |
| 持久化 | ——（08 章另讲） | 订阅心跳节流 + Task | 回调即时落盘 |
| 特色亮点 | 趋势图 + 后台线程唤醒 | 自动保存订阅 | 划线过渡动画 |

三份代码加起来一千行不到，但**架构形态完全不同**：egui 版是一个结构体加一个每帧函数；iced 版是 State/Message/update/view 四件套；Slint 版是 .slint 声明加 Rust 半边的数据搬运。读三份代码比读十篇对比文更直观。

## 24.2 技术维度横评

| 维度 | egui 0.36 | iced 0.14 | Slint 1.18 |
|---|---|---|---|
| 心智模型 | pull：每帧重跑 | push：消息驱动 | declare：绑定反应 |
| 状态管理 | 全在你的结构体 | State + update 单点 | 属性/模型/global 三层 |
| 布局 | 布局流 + Panel 谈判 | 弹性盒（Length） | 约束式布局盒 + stretch |
| 样式 | Visuals/Style 每帧可改 | Theme 枚举 + Catalog 闭包 | 属性绑定 + global 主题 |
| 自绘 | Painter（命令式点列） | canvas::Program（函数式 Frame） | Path（SVG 命令字符串） |
| 异步/并发 | 后台线程 + mpsc + request_repaint | Task + Subscription | invoke_from_event_loop |
| 无头测试 | egui_kittest（AccessKit） | iced_test（simulator） | i-slint-backend-testing |
| 中文字体 | 需注册字体（07 章） | 系统字体（默认） | 系统字体（默认） |
| 大列表 | 表格虚拟化 | 急切布局 | ListView 虚拟化 |
| 版本稳定性 | 0.34/0.35 两轮大断层 | 0.13 大断层 | semver 承诺 + 三许可 |
| 许可 | MIT/Apache-2.0 | MIT | **GPL / royalty-free / 商业** 三选一 |

**Slint 的许可必须单独强调**：免费线走 GPL（或 Royalty-free 条款），闭源商业产品需要商业许可——这是选型时的一票否决项，先查许可再写代码。egui/iced 都是 MIT 系，无此顾虑。

## 24.3 三组最小代码并排

**组一：按钮点击 → 计数**（03 / 11 / 18 的最小内核）

```rust
// egui：返回值即事件，当场改状态
if ui.button("Increment").clicked() { self.count += 1; }
```

```rust
// iced：按钮产消息，update 才改状态
button("Increment").on_press(Message::Increment),
// fn update: Message::Increment => self.count += 1
```

```rust
// Slint（.slint）：回调出口，Rust 半边挂实现
callback increment();
increment() => { root.click-count += 1; }   // 纯 UI 逻辑可全在 DSL 内
```

**组二：同一只进度环**（05 / 15 / 20）

```rust
// egui：painter 直接画，点列手算（Shape::line）
painter.circle_stroke(center, radius, Stroke::new(10.0, gray));
painter.add(egui::Shape::line(arc_points, Stroke::new(10.0, blue)));
```

```rust
// iced：draw 函数返回 Geometry，配 Cache 增量
let mut frame = canvas::Frame::new(renderer, bounds.size());
frame.stroke(&arc_path, canvas::Stroke::default().with_width(10.0).with_color(blue));
vec![frame.into_geometry()]
```

```rust
// Slint：Path 吃 SVG 命令字符串，Rust 只算字符串
// .slint: Path { commands: root.arc-commands; stroke: #4a9eff; stroke-width: 10px; }
format!("M {sx} {sy} A {r} {r} 0 {large} 1 {ex} {ey}")
```

**组三：同一张无头考卷**（02 / 10 / 17 的 harness）

```rust
// egui：AccessKit 查询 + click + run 到稳定
harness.get_by_label("Increment").click();
harness.run();
assert_eq!(harness.state().count, 3);
```

```rust
// iced：simulator 点击 → 消息喂 update → find 屏幕文本
ui.click("Increment")?;
for m in ui.into_messages() { counter.update(m); }
simulator(counter.view()).find("value: 1")?;
```

```rust
// Slint：元素查询 → 几何/属性断言（坐标注入或 a11y 通道）
element_by_id(&app, "AppWindow::touch").absolute_position();
send_mouse_click(&app, x, y);
assert_eq!(app.get_click_count(), 3);
```

## 24.4 量化指标

采集环境：Windows 11 / i7-12700F / rustc 1.98.1 / 本仓库 workspace（共享 target，依赖并集 730 包）。行数含注释与 selftest 代码（三个示例的验证代码量相当，对比公平）；包体为 release 单文件 exe。

| 指标 | egui（09） | iced（16） | Slint（23） |
|---|---|---|---|
| 业务代码行数（.rs） | 319 | 249 | 217（+86 行 .slint） |
| release 二进制 | 14.4 MB | 11.4 MB | 14.4 MB |
| 冷构建（Clean 后全量 22 示例） | 1404s ≈ 23 min（三框架共享一次编译） | （同左） | （同左） |

- 冷构建基线：**1404s ≈ 23 分钟**（Phase 0 首测：`-Clean` 后全量 `-All`，含三框架全部依赖编译 + 22 示例四层验证 + 经镜像下载依赖；网络快时的纯编译约为其 2/3，单框架项目约为其 1/3）
- 采集命令（读者可复现）：

```bash
cd G:\code\guide\rustgui
pwsh -ExecutionPolicy Bypass -File build.ps1 -Clean
Measure-Command { pwsh -ExecutionPolicy Bypass -File build.ps1 -All }   # 冷构建
cargo build --release -p egui_app -p iced_app -p slint_app              # 包体
Get-Item target/release/{egui_app,iced_app,slint_app}.exe | Select Name, Length
```

**注意**：wgpu 在本 workspace 双版本共存（eframe→wgpu 30、iced→wgpu 27）——三框架并存的代价；只做一个框架的项目不会重复。

## 24.5 同一个变更，三处改动

需求：给待办加一个"优先级"字段（低/中/高），列表要显示优先级色点。

- **egui（09）**：`Todo` 结构体加字段 + 渲染行加一个色点绘制——**2 处**，都在同一片代码里，改完即生效；
- **iced（16）**：`Todo` 加字段、Message 不变（Toggle/Delete 载荷不变）、view 行渲染加色点——**2 处**，但分居 update 与 view 两个函数；
- **Slint（23）**：`TodoRow`（serde 载体）+ `Todo`（生成结构体）各加字段、`.slint` 行模板加色点 Rectangle、`From` 转换补一行——**3 处**、跨两种语言。

改动面 egui 最小、Slint 最大——但反过来读：Slint 的界面改动**不需要动 Rust 逻辑**（.slint 热重载即可预览），设计师可以独立完成；egui 的一切改动都是程序员的事。**改动成本取决于"谁来做这次改动"**——这是 DSL 存在的根本理由。

## 24.6 选型决策树

```
需要闭源商业发布且不想付许可费？
├─ 是 → 排除 Slint 免费线（GPL/royalty-free）→ egui 或 iced
└─ 否 ↓
目标含嵌入式 MCU / 需要 C++ 复用同一份 UI？
├─ 是 → Slint（嵌入式渲染器 + 多语言宿主是独门）
└─ 否 ↓
GPU 受限或老机器 / 工具类小快灵？
├─ 是 → egui（即时模式出活最快，软件渲染可用）
└─ 否 ↓
团队有 Web/Elm/Redux 背景 / 看重架构纪律？
├─ 是 → iced（单向流 + 强类型消息）
└─ 否 ↓
要设计师协作 / 界面复杂且频繁改版？
├─ 是 → Slint（DSL + 实时预览）
└─ 犹豫 → 从 egui 开始（学习曲线最平），范式不对再迁
```

三条默认建议：**工具/调试器/内部仪表盘**选 egui；**正经产品应用**选 iced；**界面密集 + 嵌入式**选 Slint。都不合适时再看看 Tauri（Web 前端）与 gtk-rs（GNOME 生态）。

## 24.7 结语

三框架三章实战走完，最值得带走的不是 API（它们会继续变），而是三件事：

1. **范式感**：pull / push / declare 三种界面更新机制各有其美，也各有其税；
2. **无头验证的习惯**：无障碍树即测试接口，三家殊途同归——你以后写任何 GUI 都该问"这条界面能不能自动判卷"；
3. **断代免疫力**：这次三家的断层你都亲手翻译过（update→ui、Sandbox→builder、slint::testing→backend-testing），下次任何一家再断代，你知道怎么读 changelog 重建心智。

## 坑位清单

- **先查许可再写代码**：Slint 免费线是 GPL/royalty-free——闭源商业产品要么买商业许可要么换框架。egui/iced 的 MIT 系没有这道闸。
- **量化数字有语境**：本章包体/行数来自 debug 经验的三份待办实现（含等量的 selftest 代码）；你项目的数字会随依赖 feature（wgpu 后端、图像解码器）与代码风格漂移——**自己跑一遍 24.4 的采集命令**再下结论。
- **"最快的框架"取决于改什么**：24.5 的结论反过来也成立——逻辑改动 egui 最省、纯界面改版 Slint 最省（不动 Rust 就能热预览）。拿单一维度选框架是选型最常见的坑。
- **别用"冷构建时长"吓自己**：16 分钟是三框架并存且共享一次编译的全量成本；单框架项目首次 3–8 分钟、之后增量秒级。开发体验由增量决定，不由冷启动决定。

---

上一章：[23 · Slint 综合实战：待办管理器](23-slint-app.md) ｜ 返回：[README](../README.md)
