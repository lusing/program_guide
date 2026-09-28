# WinForms 编程指南（C# / F# / C++/CLI 三语言）

一套从零开始、面向初学者的 WinForms 系统教程：**20 章正文 + 19 章示例**，其中 02–18 章（17 章）每章都有 **C#、F#、C++/CLI 三份同功能实现**，收束于一个完整的客房管理系统实战。全部示例在本机 .NET 10 上编译验证并做过启动冒烟（55 个 exe 全过）。

主线按《WinForm程序设计与实践》（廉龙颖，清华，2018，扫描版 OCR 目录）的章节骨架重构：书的第 1–3 章（C# 语法/OOP）由 [csharp](../csharp/README.md) 教程认领，第 4–11 章的桌面开发部分全部落地在本教程，并用现代 .NET 重写（ADO.NET → SQLite + 参数化、GDI+ 验证码/柱形图原样保留、打包 → dotnet publish 三形态实测）。

## 快速开始

```powershell
cd G:\code\guide\winforms
pwsh -ExecutionPolicy Bypass -File build.ps1     # 构建全部（须 PowerShell 7 + VS 2026/2022 的 C++/CLI 组件）
pwsh -ExecutionPolicy Bypass -File smoke.ps1     # 冒烟：每个 exe 拉起 3 秒不崩即通过
```

单章 / 单语言：

```powershell
pwsh -ExecutionPolicy Bypass -File build.ps1 -Chapter 14_binding
pwsh -ExecutionPolicy Bypass -File build.ps1 -Lang cpp        # 只构建 C++/CLI
pwsh -ExecutionPolicy Bypass -File build.ps1 -Clean
```

## 三语言路线

| | C#（主线） | F# | C++/CLI |
|---|---|---|---|
| 工程文件 | `.csproj` | `.fsproj` | `.vcxproj`（VS MSBuild，v145） |
| 构建 | `dotnet build` | `dotnet build` | host.csproj → ProjectReference 连带 vcxproj |
| 产物 | exe | exe | **混合模式 DLL + C# 启动器 exe** |
| 事件接线 | `+= lambda` | `.Add(fun _)` | `gcnew EventHandler(this, &T::OnX)` |
| 特色章节 | 全部 | 11 章 Observable 流 | 17 章 Job 状态类、18 章混合方案 |

C++/CLI 路线的五条硬事实（只能产 DLL、引用要 HintPath 指目标包、/utf-8、属性名遮蔽枚举名、NuGet 不经 vcxproj 流动）见 [docs/01-overview.md](docs/01-overview.md) §5——全部实测。

## 目录结构

```text
winforms/
├── README.md               本文件
├── build.ps1 / smoke.ps1   构建 / 冒烟脚本（UTF-8 BOM，须 pwsh 7）
├── global.json             SDK 钉在 10.0.*
├── Cpp.Common.props        所有 vcxproj 的公共引用与开关
├── docs/                   20 章正文（01 → 20 顺序阅读）
└── examples/               19 章示例（章号 = 示例号）
    ├── 02_hello/           ┐
    │   ├── csharp/         │
    │   ├── fsharp/         ├─ 02–18 章每章三语言
    │   └── cpp/            │   （cpp 含 host/ 启动器；18 章另有 datalib/ C# 类库）
    │       └── host/       ┘
    ├── 19_publish/csharp/  发布演示（三形态实测见 docs/19）
    └── 20_project/csharp/  实战：客房管理系统（三层）
```

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [01 全景与三语言路线](docs/01-overview.md) | WinForms 是什么、C++/CLI 五条硬事实、工具链 | — |
| [02 第一个程序](docs/02-hello.md) | 消息循环、三语言骨架、Application 顺序铁律 | `02_hello` |
| [03 窗体与生命周期](docs/03-forms.md) | Load/Shown/Activated、模态与非模态、关闭确认 | `03_forms` |
| [04 布局](docs/04-layout.md) | Dock/Anchor/TableLayout/FlowLayout、DPI 缩放 | `04_layout` |
| [05 文本类控件](docs/05-controls-text.md) | TextBox/RichTextBox/NumericUpDown/LinkLabel | `05_text` |
| [06 选择类控件](docs/06-controls-selection.md) | RadioButton 互斥、ComboBox、CheckedListBox、TrackBar | `06_selection` |
| [07 容器与列表](docs/07-controls-lists.md) | TreeView/ListView/TabControl/SplitContainer | `07_lists` |
| [08 菜单工具栏](docs/08-menus.md) | MenuStrip/ContextMenuStrip/ToolStrip/StatusStrip | `08_menus` |
| [09 对话框](docs/09-dialogs.md) | 打开/保存/颜色/字体/文件夹、迷你编辑器 | `09_dialogs` |
| [10 SDI 与 MDI](docs/10-mdi.md) | MDI 容器、窗口菜单四件套、活动子窗体 | `10_mdi` |
| [11 事件与委托](docs/11-events.md) | 多播、解绑、三语言对照、F# Observable 流 | `11_events` |
| [12 GDI+ 基础](docs/12-gdi-basics.md) | OnPaint、Pen/Brush 家族、失效-重绘、双缓冲 | `12_gdi_basics` |
| [13 GDI+ 应用](docs/13-gdi-apps.md) | 柱形图、验证码、坐标变换、位图生命周期 | `13_gdi_apps` |
| [14 数据绑定](docs/14-binding.md) | DataBindings、INPC、BindingSource/BindingList | `14_binding` |
| [15 DataGridView](docs/15-datagridview.md) | 手工列、特殊列、校验、条件着色、主从联动 | `15_datagrid` |
| [16 UI 线程模型](docs/16-threading.md) | 卡死、Task.Run+IProgress、Invoke、两种 Timer | `16_threading` |
| [17 文件 IO 与加密](docs/17-io-crypto.md) | SHA256、AES+PBKDF2 文件保险箱 | `17_io_crypto` |
| [18 SQLite 与三层雏形](docs/18-data.md) | 参数化防注入、DataReader、C++/CLI 混合方案 | `18_data` |
| [19 发布与部署](docs/19-publish.md) | 三形态实测（0.2/117/111 MB）、Trim 警告 | `19_publish` |
| [20 实战：客房管理系统](docs/20-project.md) | 登录门卫、MDI 调度、入住退房闭环 | `20_project` |

## 学习路线

1. **01–04**：骨架与形——窗体、生命周期、布局（C++/CLI 读者重点啃 01 §5）
2. **05–10**：控件字典——输入、选择、列表、菜单、对话框、MDI（示例即查即用）
3. **11**：事件模型——三语言差异最大的一章，值得精读
4. **12–13**：GDI+ 自绘——从失效-重绘到验证码/图表
5. **14–15**：数据绑定——表单与表格的"魂"
6. **16–18**：工程化——线程安全、加密、数据库三层
7. **19–20**：毕业——发布三形态 + 完整项目

## 工具链

- .NET SDK 10（scoop `dotnet-sdk`，`global.json` 钉 10.0.*）
- VS 2026 Community（v145 工具集 + `Microsoft.VisualStudio.Component.VC.CLI.Support` 组件）——C++/CLI 必需；脚本经 vswhere 自动定位 MSBuild
- SQLite 经 NuGet `Microsoft.Data.Sqlite` 10.0.0（18/20 章）

## 验证状态

- `build.ps1`（全量）：**0 失败**（C# 19 工程 + F# 17 工程 + C++/CLI 17 套 vcxproj+host，含 18 章 datalib）
- `smoke.ps1`：**55 个 exe，0 失败**（拉起 3 秒不退出；16 章 C++ 版曾暴露 Timer 启动竞态，加 `IsHandleCreated` 守卫后 5/5 稳定）
- 17 章加密算法经 fsi 脚本独立验证：往返哈希一致、错口令拦截均 true
- 19 章三形态发布实测：框架依赖 5 文件 0.2 MB / 自包含 271 文件 117.2 MB / 单文件 110.7 MB（exe 可独立运行）
