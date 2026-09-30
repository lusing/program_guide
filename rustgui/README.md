# Rust GUI 编程指南（egui 0.36 / iced 0.14 / Slint 1.18）

一个目录，三种 Rust GUI 框架，三种界面范式。同一批"建窗口/控件事件/布局/输入/自绘/综合应用"
的任务在三个框架里各写一遍，**范式差异不是听来的、是手上写出来的、还是机器判卷的**（对齐
[cppgui](../cppgui/README.md) 的多框架哲学）。

> ⚠️ 三家在 2025–2026 都经历了断代：egui 0.34/0.35 大重构（`App::ui` 取代 `update`、统一
> `Panel` 体系）、iced 0.13 删 `Sandbox`（`Command`→`Task`）、Slint 1.18 移除 `slint::testing`。
> 网上大量教程已失效——本教程全部代码在 **rustc 1.98.1** 实测，按新版 API 写，每章坑位清单
> 收录新旧对照。

| 部分 | 框架 | 范式 | 章 |
|---|---|---|---|
| 一 | egui 0.36.2（+egui_kittest） | 即时模式（每帧重跑，返回值即事件） | 01–09 |
| 二 | iced 0.14.0（+iced_test） | Elm 架构（state/update/view 单向流） | 10–16 |
| 三 | Slint 1.18.1（+i-slint-backend-testing） | 声明式 DSL（.slint 语言 + 绑定反应） | 17–23 |
| 尾 | 横评 | 同一待办应用三份实现对照 + 选型决策树 | 24 |

## 目录结构

```text
rustgui/
├── Cargo.toml            根 workspace（members = examples/*，22 个示例共享 target/）
├── Cargo.lock            依赖锁定（730 包；TUNA 镜像配置见 .cargo/config.toml）
├── build.ps1             Windows 验证入口（-All / -Example NN_name / -Clean）
├── run-all.sh            POSIX 入口（同判定；WSL/macOS/Linux 用这个）
├── docs/                 24 章正文（NN-slug.md，01 → 24 顺序阅读）
├── examples/             22 个示例工程（章号 = 目录号；package 名不带数字）
│   ├── 02_egui_hello/    … 每章一个 cargo 工程，src/main.rs + （slint 章）ui/*.slint
│   └── 23_slint_app/
├── tools/check_docs.py   文档五关机器核查（build.ps1 -All 末尾自动跑）
├── build/                验证产物（.out/.err/.run.out，不入库）
└── CHEATSheet.md         三框架横向速查 + 坑位总索引
```

## 分章导航

**第一部分 egui 即时模式（02–09）**

1. [全景：Rust GUI 生态与三范式](docs/01-landscape.md)（无示例）
2. [egui 最小应用：即时模式与无头测试](docs/02-egui-hello.md)
3. [egui 控件全集：返回值即事件](docs/03-egui-widgets.md)
4. [egui 布局：统一 Panel 体系与两遍布局](docs/04-egui-layout.md)
5. [egui 自绘：Painter、进度环与逐帧动画](docs/05-egui-painter.md)
6. [egui 表格、曲线图与图像](docs/06-egui-tables.md)
7. [egui 中文字体与主题样式](docs/07-egui-fonts.md)
8. [egui 自定义控件、动画辅助与持久化](docs/08-egui-custom.md)
9. [egui 综合实战：待办管理器](docs/09-egui-app.md)

**第二部分 iced Elm 架构（10–16）**

10. [iced 计数器：Elm 架构三件套](docs/10-iced-counter.md)
11. [iced 表单控件与 id 定位](docs/11-iced-widgets.md)
12. [iced 布局：Length、Container 与坐标驱动](docs/12-iced-layout.md)
13. [iced 主题与样式系统](docs/13-iced-style.md)
14. [iced 订阅与异步 Task](docs/14-iced-subscription.md)
15. [iced Canvas：自绘进度环](docs/15-iced-canvas.md)
16. [iced 综合实战：待办管理器](docs/16-iced-app.md)

**第三部分 Slint 声明式 DSL（17–23）**

17. [Slint 最小应用：声明式 DSL](docs/17-slint-hello.md)
18. [Slint 状态、绑定与全局单例](docs/18-slint-state.md)
19. [Slint 布局系统](docs/19-slint-layout.md)
20. [Slint 状态动画与声明式自绘](docs/20-slint-animations.md)
21. [Slint 组件复用与 Rust 深度集成](docs/21-slint-components.md)
22. [Slint 模型与 ListView](docs/22-slint-models.md)
23. [Slint 综合实战：待办管理器](docs/23-slint-app.md)

**横评**

24. [三框架横评与选型](docs/24-comparison.md)（无独立示例）

速查与坑位总索引：[CHEATSheet.md](CHEATSheet.md)

## 工具链

| 件 | 版本/位置 | 说明 |
|---|---|---|
| rustc / cargo | 1.98.1（scoop） | edition 2024；egui 0.36 的 MSRV 1.95 |
| egui / eframe / egui_kittest | 0.36.2 | 注意 github master 领先已发布版，以 registry 源码为准 |
| egui_plot | 0.37 | 版本号与 egui 错位 +1（egui 0.36 ↔ plot 0.37） |
| iced / iced_test | 0.14.0 | canvas、tokio 是独立 feature（默认不含） |
| slint / slint-build | 1.18.1 | i-slint-backend-testing 用 ffi feature + 4 行官方同款 shim |
| 依赖源 | TUNA 镜像 | `.cargo/config.toml`（可删，不影响代码） |

- 首次全量构建 15–25 分钟（三棵依赖树，wgpu 双版本共存：eframe→30、iced→27），之后增量秒级。
- 07 章示例需要系统里有任意常见中文字体（simhei/msyh/PingFang/Noto，桌面系统都有）。

## 构建与验证

```powershell
cd G:\code\guide\rustgui
pwsh -ExecutionPolicy Bypass -File build.ps1 -All                 # 全部 22 个
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 02_egui_hello  # 单个
pwsh -ExecutionPolicy Bypass -File build.ps1 -Clean               # 清理 target
```

```bash
# macOS / Linux / WSL
cd rustgui && ./run-all.sh              # 全部
./run-all.sh 02_egui_hello              # 单个
```

单跑某个示例（每章标准学法）：

```bash
cd rustgui/examples/02_egui_hello
cargo run          # 打开真窗口（人工查看）
cargo run -- --selftest   # 无头自检（自动验证走的就是它）
cargo test         # 无头交互测试（与 selftest 同一通道）
```

## 验证判定（四层 + 三条）

每个示例：

1. `cargo fmt --check`
2. `cargo clippy --all-targets -- -D warnings`
3. `cargo test`——无头 UI 交互测试（kittest / iced_test / slint testing backend）
4. `cargo run -- --selftest`（60s 超时）——同一 harness 走 main 通道，exit 0
5. stdout 同时含 `==== NN ` 起 / ` 结束 ====` 止标记；stderr 空；无控制字符；**两跑逐字节一致**
   （时间戳/随机数禁止进 selftest 输出）

外加 `tools/check_docs.py` 五关：章号↔示例对齐（01/24 无示例白名单）、docs 的 ```text 输出块
对**当前二进制**现场重跑的顺序敏感子序列命中、每章坑位 ≥3、docs 链接有效、本 README 导航含
全部 24 章。

无头通道测不到字形（kittest 只走无障碍树、从不光栅化）：**真窗口层**用
`tools/gui-shots.ps1` 逐例启动真窗口截图（`tools/gui-contact-sheet.ps1` 拼总览图人工复核），
截到 `build/gui-shots/*.png`。

### 验证状态（2026-10-01）

- `build.ps1 -All` **22/22 全绿**（含三条无头通道 × 22 示例的交互测试）
- 三条无头通道均为官方设施：egui=egui_kittest（AccessKit 查询）、iced=iced_test（simulator）、
  slint=i-slint-backend-testing（ffi + ElementHandle 查询 + a11y 注入）
- 真窗口截图 22/22：首跑抓出 egui 08/09 缺 CJK 字体注册（无头全绿、真窗口满屏豆腐块——
  0.36.2 无系统字体回退），已修复并复验

## 相关教程

Rust 语言本体：[rust](../rust/README.md)；C++ GUI 四框架对照：[cppgui](../cppgui/README.md)；
速查见 [CHEATSheet.md](CHEATSheet.md)。
