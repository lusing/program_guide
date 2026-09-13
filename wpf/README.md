# WPF 编程指南示例集

本目录按类似 `asm/intel` 的方式整理了 WPF 教程中的可编译示例，并使用已安装的 .NET SDK 进行验证。

## 目录结构

```text
wpf/
├── README.md
├── build.ps1
├── WPF编程指南.md
├── examples/
│   ├── 01_hello_wpf/
│   ├── 02_binding/
│   ├── 03_mvvm/
│   ├── 04_layout/
│   ├── 05_styles/
│   ├── 06_commands/
│   ├── 07_async_progress/
│   ├── 08_file_dialogs/
│   └── 09_navigation/
└── build/
```

## 工具链

- .NET SDK: `G:\scoop\apps\dotnet-sdk\current\dotnet.exe`
- WPF 运行时: .NET Windows Desktop
- 编译方式: `dotnet build`

## 快速构建

```powershell
cd G:\code\guide\wpf
.\build.ps1
```

## 示例说明

- `01_hello_wpf`：最小 WPF 应用程序骨架，展示 `Window`、`Button` 和事件处理。
- `02_binding`：演示 `TextBox`、`Slider` 与数据绑定。
- `03_mvvm`：展示 `INotifyPropertyChanged`、命令和 MVVM 风格代码分离。
- `04_layout`：展示 `Grid`、`StackPanel`、`DockPanel` 等布局容器组合方式。
- `05_styles`：演示基于 `Style`、`Trigger` 和资源字典的统一界面风格。
- `06_commands`：展示 `ICommand` 与 `RelayCommand` 的绑定与执行流程。
- `07_async_progress`：演示 `async/await`、`IProgress<T>` 和长任务状态更新。
- `08_file_dialogs`：演示 `OpenFileDialog`、`SaveFileDialog` 和文件路径处理。
- `09_navigation`：展示 `Frame` + `Page` 的页面导航与窗口切换。

这些示例都经过 `dotnet build` 编译验证，确保与当前安装的 .NET 10/Windows Desktop 工具链兼容。

## 教程扩展说明

本目录不仅保留了基础入门代码，还增加了以下实战主题：

- 布局与控件组合：适合学习 WPF 里 `Grid`、`StackPanel`、`DockPanel` 的组合方式。
- 样式与资源：适合学习统一主题、颜色、触发器和模板。
- 命令系统：适合学习 UI 事件与业务逻辑解耦。
- 异步与进度：适合学习后台任务、状态同步和用户体验优化。
- 对话框与文件操作：适合学习常见桌面应用交互。
- 页面导航：适合学习多页面应用的结构组织。

这些示例可以直接作为独立教学案例，配合 [WPF编程指南.md](./WPF编程指南.md) 中对应章节阅读。
