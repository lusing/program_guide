# WPF 编程指南（C# / F# / C++/CLI 三语言）

一套从零开始、面向初学者的 WPF 系统教程：**25 章正文 + 21 个示例章节**（章号与示例号对应），其中 03–23 章每章都有 **C#、F#、C++/CLI 三份同功能实现**，收束于一个完整实战项目。全部示例在本机 .NET 10 上编译验证并做过启动冒烟（61 个 exe 全过），发布三模式（框架依赖/自包含/单文件）均实测过产物体积。

骨架参考《WPF 编程基础》（刘晋钢主编，清华，2018，扫描版经 RapidOCR 提取目录）的 12 章体系：XAML / 布局 / 控件 / 数据 / 路由事件 / 图形（含 3D）/ 动画与媒体 / 命令与触发器 / 资源 / 样式与换肤 / MVVM——全部落地并按现代 .NET 10 重写，另扩充验证、DataGrid、Tree、异步、导航、部署等工程化章节。

## 快速开始

```powershell
cd G:\code\guide\wpf
pwsh -ExecutionPolicy Bypass -File build.ps1     # 构建全部（须 PowerShell 7 + C++/CLI 需 VS 2026/2022）
pwsh -ExecutionPolicy Bypass -File smoke.ps1     # 冒烟：每个 exe 拉起 3 秒不崩即通过
```

单章 / 单语言：

```powershell
pwsh -ExecutionPolicy Bypass -File build.ps1 -Chapter 15_templates
pwsh -ExecutionPolicy Bypass -File build.ps1 -Lang cpp        # 只构建 C++/CLI
pwsh -ExecutionPolicy Bypass -File build.ps1 -Clean
```

## 三语言路线

一句话分野：**XAML 是 C# 的专属红利**——XAML 编译器只生成 C# 分部类，F# 与 C++/CLI 走"纯代码 UI"路线，三份实现殊途同归地搭出同一棵对象树。

| | C#（主线） | F# | C++/CLI |
|---|---|---|---|
| 工程文件 | `.csproj` | `.fsproj` | `.vcxproj`（VS MSBuild，v145） |
| 构建 | `dotnet build` | `dotnet build` | host.csproj → ProjectReference 连带 vcxproj |
| 产物 | exe | exe | **混合模式 DLL + C# 启动器 exe** |
| 界面描述 | XAML + 代码后置 | 纯代码（对象初始化器） | 纯代码（gcnew 三步） |
| 事件接线 | `+= lambda` | `.Add(fun _ -> …)` | `gcnew RoutedEventHandler(this, &T::OnX)` |
| 特色章节 | 全部 | 11 章（命令即函数值） | 17 章（Tag 传状态）、21 章（无 async 的三连等价物） |

C++/CLI 路线的五条硬事实（只能产 DLL / 引用 HintPath 指目标包且要 System.Xaml / /utf-8 / 属性名遮蔽类型名 / 无 lambda 捕获）见 [docs/01-overview.md](docs/01-overview.md) §8——全部实测。

## 目录结构

```text
wpf/
├── README.md               本文件
├── build.ps1 / smoke.ps1   构建 / 冒烟脚本（UTF-8 BOM，须 pwsh 7）
├── global.json             SDK 钉在 10.0.*
├── Cpp.Common.props        所有 vcxproj 的公共引用（WPF 四引用 + /utf-8）
├── docs/                   25 章正文（01 → 25 顺序阅读）
└── examples/               示例（章号 = 示例号）
    ├── 03_hello_wpf/       ┐
    │   ├── csharp/         │ C# + XAML
    │   ├── fsharp/         ├─ 03–23 章每章三语言
    │   └── cpp/            │   （cpp 含 host/ 启动器）
    │       └── host/       ┘
    └── 25_notepad_plus/    实战项目（C# 专属，F# 接手思路见 docs/25）
```

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [01 全景与三语言路线](docs/01-overview.md) | WPF 是什么、C++/CLI 五条硬事实、工具链 | — |
| [02 应用骨架与生命周期](docs/02-app-lifecycle.md) | App/Window/Shutdown、Dispatcher 一瞥 | — |
| [03 XAML 基础](docs/03-xaml-basics.md) | 最小程序、三语言骨架对照 | `03_hello_wpf` |
| [04 标记扩展与依赖属性](docs/04-markup-extensions-dp.md) | Binding/StaticResource、DP 系统 | — |
| [05 布局系统](docs/05-layout.md) | Grid/StackPanel/DockPanel、UniformGrid（教材 3.2.5） | `05_layout` |
| [06 布局实战](docs/06-layout-lab.md) | SharedSizeGroup/Viewbox/滚动折行/星号比例 | `06_layout_lab` |
| [07 核心控件](docs/07-controls.md) | 控件画廊、菜单工具栏（教材 4.2）、手写/日期 | `07_controls_gallery` |
| [08 路由事件](docs/08-routed-events.md) | 隧道/冒泡、自定义路由事件（教材 6.3） | `08_routed_events` |
| [09 绑定基础](docs/09-binding.md) | ElementName/Path、代码绑定的 Source 直连 | `09_binding` |
| [10 绑定进阶](docs/10-binding-advanced.md) | INPC/集合/转换器/MultiBinding | `10_binding_advanced` |
| [11 MVVM](docs/11-mvvm.md) | 三件套、RelayCommand 三语言形态 | `11_mvvm` |
| [12 命令系统](docs/12-commands.md) | CanExecute、命令库 ApplicationCommands（教材 9.2.5） | `12_commands` |
| [13 资源与样式](docs/13-styles-resources.md) | Style/BasedOn、动态资源换肤（教材 10/11.3.5） | `13_styles` |
| [14 触发器](docs/14-triggers.md) | 属性/多条件/数据/事件四类 | `14_triggers` |
| [15 模板](docs/15-templates.md) | ControlTemplate/DataTemplate、TargetName 部件 | `15_templates` |
| [16 数据验证](docs/16-validation.md) | INotifyDataErrorInfo、错误模板 | `16_validation` |
| [17 ListView 与 DataGrid](docs/17-listview-datagrid.md) | GridView 排序、五种列型 | `17_datagrid` |
| [18 TreeView](docs/18-treeview.md) | HierarchicalDataTemplate、批量展开 | `18_treeview` |
| [19 绘图与变换](docs/19-drawing.md) | Shape/画刷/变换、**3D 一瞥（教材 7.3）** | `19_drawing` |
| [20 动画](docs/20-animation.md) | 缓动/永续、**路径动画（教材 8.2.3）** | `20_animation` |
| [21 异步与线程](docs/21-async.md) | task/Dispatcher、C++ 无 async 的三连等价物 | `21_async_progress` |
| [22 对话框与文件 IO](docs/22-dialogs-files.md) | 打开/保存对话框 | `22_file_dialogs` |
| [23 导航](docs/23-navigation.md) | Frame + Page | `23_navigation` |
| [24 部署与发布](docs/24-publishing.md) | 三模式实测（226KB/142MB/131MB） | — |
| [25 实战：记事本+](docs/25-notepad-plus.md) | MVVM 多模块文本编辑器 | `25_notepad_plus` |

## 学习路线

1. **01–04**：骨架与形——三语言路线 + XAML 与依赖属性（C++/CLI 读者重点啃 01 §8）
2. **05–08**：布局、控件、路由事件——界面的"形"（示例即查即用）
3. **09–12**：绑定与 MVVM——界面的"魂"，**全书重点**（三语言差异最大的四连章）
4. **13–15**：样式、触发器、模板——外观定制三部曲
5. **16–20**：验证、列表数据、树、绘图（含 3D）、动画（含路径动画）
6. **21–24**：异步、对话框、导航、部署——工程化必备件
7. **25**：实战项目"记事本+"

## 工具链

- .NET SDK 10（scoop `dotnet-sdk`，`global.json` 钉 10.0.*）
- VS 2026 Community（v145 工具集 + `Microsoft.VisualStudio.Component.VC.CLI.Support` 组件）——C++/CLI 必需；脚本经 vswhere 自动定位 MSBuild

## 验证状态

- `build.ps1`（clean 全量重建）：**0 失败**（C# 21 + F# 20 + C++/CLI 20 套 vcxproj+host）
- `smoke.ps1`：**61 个 exe，0 失败**（20 章 × 3 语言 + 实战项目）
- 24 章三形态发布实测：框架依赖 226KB / 自包含 142MB / 单文件 131MB
