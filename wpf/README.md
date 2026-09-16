# WPF 编程指南

一套从零开始的 WPF 实用教程：12 章正文 + 10 个可编译运行的示例 + 1 个实战项目。所有示例在本机 .NET 10 SDK 上编译验证，实战项目做了启动冒烟测试。

## 快速开始

```powershell
cd G:\code\guide\wpf
.\build.ps1        # 构建全部示例（dotnet build，含还原依赖）
```

产物在 `examples\<示例名>\bin\Debug\net10.0-windows\` 下，对应的 exe 可直接运行。

## 目录结构

```text
wpf/
├── README.md            # 本文件
├── build.ps1            # 一键构建脚本（dotnet build）
├── docs/                # 教程正文（按章组织）
│   ├── 01-overview.md          # WPF 概述与架构
│   ├── 02-app-lifecycle.md     # 应用骨架与生命周期
│   ├── 03-xaml.md              # XAML 语言
│   ├── 04-layout.md            # 布局系统
│   ├── 05-controls.md          # 核心控件与路由事件
│   ├── 06-binding.md           # 数据绑定
│   ├── 07-mvvm-commands.md     # MVVM 与命令
│   ├── 08-styles.md            # 样式、触发器与模板
│   ├── 09-async.md             # 异步与后台任务
│   ├── 10-dialogs-files.md     # 对话框与文件 IO
│   ├── 11-navigation.md        # 窗口与页面导航
│   └── 12-notepad-plus.md      # 实战项目：WPF 记事本+
└── examples/            # 每章示例（可独立编译运行）
    ├── 01_hello_wpf/           # 最小 WPF 应用骨架
    ├── 02_binding/             # ElementName 绑定与控件联动
    ├── 03_mvvm/                # INotifyPropertyChanged + ICommand
    ├── 04_layout/              # Grid/StackPanel/DockPanel 组合
    ├── 05_styles/              # Style/Trigger/ControlTemplate
    ├── 06_commands/            # CanExecute 与按钮置灰闭环
    ├── 07_async_progress/      # async/await + 进度绑定
    ├── 08_file_dialogs/        # OpenFileDialog/SaveFileDialog
    ├── 09_navigation/          # Frame + Page 页面导航
    └── 10_notepad_plus/        # 实战项目：WPF 记事本+（MVVM 多模块）
```

## 工具链

- .NET SDK: `G:\scoop\apps\dotnet-sdk\current\dotnet.exe`（.NET 10，含 Windows Desktop）
- 目标框架: `net10.0-windows`，`UseWPF=true`
- 编译方式: `dotnet build`（不需要 Visual Studio）

## 学习路线

按章顺序走，核心三连是 04 布局 → 06 绑定 → 07 MVVM：

1. **01~03**：WPF 是什么、程序骨架、XAML 语法——把对象树和分部类机制想清楚
2. **04~05**：布局协商（Measure/Arrange）与控件内容模型——界面的"形"
3. **06~07**：数据绑定与 MVVM——界面的"魂"，全书重点
4. **08~11**：样式模板、异步、对话框、导航——工程化必备件
5. **12**：实战项目"记事本+"，把全部知识串进一个 MVVM 应用

## 实战项目：WPF 记事本+

`10_notepad_plus` 是一个完整的 MVVM 文本编辑器：编码识别（BOM/UTF-8/GB18030）、异步文件读写、脏标记与退出确认、最近文件列表（JSON 持久化）、非模态查找替换、命令驱动的菜单与快捷键。详见 [docs/12-notepad-plus.md](docs/12-notepad-plus.md)。
