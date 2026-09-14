# Flutter 开发指南示例集

本目录按照 `guide` 统一标准整理为“教程文档 + 独立示例工程 + 构建脚本”的结构，便于在本机 Flutter SDK 上实际编译和验证 Dart/Flutter 代码。

## 目录结构

```text
flutter/
├── README.md
├── Flutter开发指南.md
├── build.ps1
├── examples/
│   ├── 01_hello/
│   │   ├── lib/
│   │   ├── test/
│   │   └── pubspec.yaml
│   ├── 02_layout/
│   │   ├── lib/
│   │   ├── test/
│   │   └── pubspec.yaml
│   └── 03_state/
│       ├── lib/
│       ├── test/
│       └── pubspec.yaml
└── build/
```

## 构建工具链

- Flutter：`G:\scoop\apps\flutter\current\bin\flutter.bat`
- Dart：`G:\scoop\apps\flutter\current\bin\dart.bat`

## 编译与验证

```powershell
cd G:\code\guide\flutter
.\build.ps1 -All
```

单个示例：

```powershell
.\build.ps1 -Project 02_layout
```

清理：

```powershell
.\build.ps1 -Clean
```

## 说明

- Flutter 是 Google 推出的跨平台 UI 框架，可用于构建 Android、iOS、Web、Windows、macOS 和 Linux 应用。
- 本目录使用 Flutter 的真实桌面编译链 `flutter build windows --debug` 对示例工程进行编译验证，确保示例在当前本机环境中真实可构建。
- 示例覆盖了 Flutter 入门、布局、状态管理和交互式 UI 的基本思路。
