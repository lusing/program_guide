# Free Pascal 编程指南示例集

本目录按 `guide` 统一结构组织 Free Pascal / Lazarus 教程与可验证示例。

## 目录结构

```text
freepascal/
├── README.md
├── Free Pascal编程指南.md
├── build.ps1
├── examples/
│   ├── 01_hello.pas
│   ├── 02_variables.pas
│   ├── 03_arithmetic.pas
│   ├── 04_if_case.pas
│   ├── 05_loops.pas
│   ├── 06_procedures.pas
│   ├── 07_records.pas
│   ├── 08_arrays.pas
│   ├── 09_strings_sets.pas
│   ├── 10_pointers.pas
│   ├── 11_file_io.pas
│   └── 12_classes.pas
└── build/
```

## 构建工具链

- Free Pascal 安装目录：`G:\scoop\apps\freepascal\current`
- 编译器路径：`G:\scoop\apps\freepascal\current\bin\i386-win32\fpc.exe`
- IDE：`G:\scoop\apps\lazarus\current\lazarus.exe`

## 编译/验证

```powershell
cd G:\code\guide\freepascal
.\build.ps1 -All
```

单文件验证：

```powershell
.\build.ps1 -File 08_arrays.pas
```

清理：

```powershell
.\build.ps1 -Clean
```

## 说明

- Free Pascal 是经典 Pascal 语言的现代实现，适合学习结构化编程、过程式编程和面向对象编程。
- 本目录的示例兼容 Windows 平台本地编译器，并以最小运行验证方式确认代码可执行。
- 对于 Lazarus，通常适合用于 GUI 组件与 IDE 相关学习；本目录主要聚焦语言核心与可编译示例。
