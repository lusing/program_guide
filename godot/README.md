# Godot 开发指南示例集

本目录按照 `guide` 统一标准整理为“教程文档 + 独立示例工程 + 构建脚本”的结构，便于在本机 Godot 工具链上实际验证 GDScript 代码与场景脚本。

## 目录结构

```text
godot/
├── README.md
├── Godot开发指南.md
├── build.ps1
├── examples/
│   ├── 01_hello/
│   │   ├── project.godot
│   │   └── main.gd
│   ├── 02_variables/
│   │   ├── project.godot
│   │   └── main.gd
│   ├── 03_functions/
│   │   ├── project.godot
│   │   └── main.gd
│   ├── 04_signals/
│   │   ├── project.godot
│   │   └── main.gd
│   └── 05_input_and_loop/
│       ├── project.godot
│       └── main.gd
└── build/
```

## 构建工具链

- Godot：`G:\scoop\apps\godot\current\godot.console.exe`

## 编译与验证

```powershell
cd G:\code\guide\godot
.\build.ps1 -All
```

单个示例：

```powershell
.\build.ps1 -Project 02_variables
```

清理：

```powershell
.\build.ps1 -Clean
```

## 说明

- Godot 是一个开源的跨平台 2D/3D 游戏引擎，适合快速原型设计、教学场景、独立游戏开发和交互式应用。
- 本目录使用 Godot 4 的 GDScript 语法，并通过 `--headless --path --script` 的方式在本机面向命令行环境执行脚本，确保示例能够真实运行并验证。
- 示例覆盖了 GDScript 的基本语法、变量、函数、集合、信号和输入循环等核心知识点。
