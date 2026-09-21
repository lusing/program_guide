# WPF 编程指南

一套从零开始、面向初学者的 WPF 系统教程：**25 章正文 + 21 个可编译运行的示例**（章号与示例号对应），收束于一个完整实战项目。所有示例在本机 .NET 10 SDK 上编译验证并做过启动冒烟测试，发布三模式（框架依赖/自包含/单文件）均实测过产物体积。

## 快速开始

```powershell
cd G:\code\guide\wpf
.\build.ps1        # 构建全部 21 个示例（dotnet build，含还原依赖）
.\smoke.ps1        # 冒烟测试：每个 exe 拉起 3 秒不崩即通过
```

产物在 `examples\<示例名>\bin\Debug\net10.0-windows\` 下，对应的 exe 可直接运行。

## 目录结构

```text
wpf/
├── README.md            # 本文件
├── build.ps1            # 一键构建脚本（21 个项目）
├── smoke.ps1            # 启动冒烟测试脚本
├── docs/                # 教程正文（25 章，章号=示例号）
│   ├── 01-overview.md            # WPF 概述与架构
│   ├── 02-app-lifecycle.md       # 应用骨架与生命周期
│   ├── 03-xaml-basics.md         # XAML 语言基础
│   ├── 04-markup-extensions-dp.md# 标记扩展与依赖属性
│   ├── 05-layout.md              # 布局系统
│   ├── 06-layout-lab.md          # 布局实战（滚动/缩放/共享尺寸）
│   ├── 07-controls.md            # 核心控件一览
│   ├── 08-routed-events.md       # 路由事件
│   ├── 09-binding.md             # 数据绑定基础
│   ├── 10-binding-advanced.md    # 绑定进阶（INPC/集合/转换器）
│   ├── 11-mvvm.md                # MVVM 模式
│   ├── 12-commands.md            # 命令系统
│   ├── 13-styles-resources.md    # 资源与样式
│   ├── 14-triggers.md            # 触发器
│   ├── 15-templates.md           # 模板（ControlTemplate/DataTemplate）
│   ├── 16-validation.md          # 数据验证
│   ├── 17-listview-datagrid.md   # ListView 与 DataGrid
│   ├── 18-treeview.md            # TreeView 与层级数据
│   ├── 19-drawing.md             # 绘图与变换
│   ├── 20-animation.md           # 动画
│   ├── 21-async.md               # 异步与线程模型
│   ├── 22-dialogs-files.md       # 对话框与文件 IO
│   ├── 23-navigation.md          # 窗口与页面导航
│   ├── 24-publishing.md          # 部署与发布
│   └── 25-notepad-plus.md        # 实战项目：WPF 记事本+
└── examples/            # 每章示例（可独立编译运行）
    ├── 03_hello_wpf/           # 最小 WPF 应用骨架
    ├── 05_layout/              # Grid/StackPanel/DockPanel 组合
    ├── 06_layout_lab/          # 共享尺寸/Viewbox/ScrollViewer
    ├── 07_controls_gallery/    # 控件画廊（事件汇到状态栏）
    ├── 08_routed_events/       # 隧道/冒泡传播可视化
    ├── 09_binding/             # ElementName 绑定直觉实验
    ├── 10_binding_advanced/    # INPC + ObservableCollection + 转换器
    ├── 11_mvvm/                # MVVM 版任务清单
    ├── 12_commands/            # CanExecute 与按钮置灰闭环
    ├── 13_styles/              # Style 与 BasedOn
    ├── 14_triggers/            # 四类触发器对照
    ├── 15_templates/           # 圆角按钮模板 + PersonCard 三处复用
    ├── 16_validation/          # INotifyDataErrorInfo 表单
    ├── 17_datagrid/            # ListView 排序 + DataGrid 编辑
    ├── 18_treeview/            # 文件树 + HierarchicalDataTemplate
    ├── 19_drawing/             # Shape/画刷/变换小场景
    ├── 20_animation/           # 缓动对比与永续动画
    ├── 21_async_progress/      # async/await + 进度绑定 + 取消
    ├── 22_file_dialogs/        # OpenFileDialog/SaveFileDialog
    ├── 23_navigation/          # Frame + Page 页面导航
    └── 25_notepad_plus/        # 实战项目：WPF 记事本+（MVVM 多模块）
```

## 工具链

- .NET SDK: `G:\scoop\apps\dotnet-sdk\current\dotnet.exe`（.NET 10，含 Windows Desktop）
- 目标框架: `net10.0-windows`，`UseWPF=true`
- 编译方式: `dotnet build`（不需要 Visual Studio）

## 学习路线

按章顺序走，核心四连是 09-10 绑定 → 11-12 MVVM/命令：

1. **01~04**：WPF 是什么、程序骨架、XAML 与依赖属性——把"界面即对象"想通
2. **05~08**：布局、控件、路由事件——界面的"形"
3. **09~12**：数据绑定与 MVVM——界面的"魂"，**全书重点**
4. **13~15**：样式、触发器、模板——外观定制三部曲
5. **16~20**：验证、列表数据、树、绘图、动画——专题扩展
6. **21~24**：异步、对话框、导航、部署——工程化必备件
7. **25**：实战项目"记事本+"，把全部知识串进一个 MVVM 应用

每章开头有「本章你将学会 + 前置章节」，结尾有「自测」；建议自测答不上来就回读对应小节。

## 实战项目：WPF 记事本+

`25_notepad_plus` 是一个完整的 MVVM 文本编辑器：编码识别（BOM/UTF-8/GB18030）、异步文件读写、脏标记与退出确认、最近文件列表（JSON 持久化）、非模态查找替换、命令驱动的菜单与快捷键。详见 [docs/25-notepad-plus.md](docs/25-notepad-plus.md)。
