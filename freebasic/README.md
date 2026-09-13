# FreeBASIC 编程指南示例集

本目录按 `guide` 统一结构组织 FreeBASIC 教程与可编译示例。

## 目录结构

```text
freebasic/
├── README.md
├── FreeBasic编程指南.md
├── build.ps1
└── examples/
    ├── 01_hello.bas
    ├── 02_types_variables.bas
    ├── 03_control_flow.bas
    ├── 04_functions_subs.bas
    ├── 05_arrays.bas
    ├── 06_strings.bas
    ├── 07_user_type.bas
    ├── 08_enum_select.bas
    ├── 09_pointers.bas
    ├── 10_file_io.bas
    ├── 11_random_math.bas
    ├── 12_datetime_timer.bas
    ├── 13_module_style.bas
    ├── 14_error_style.bas
    └── 15_simple_menu.bas
```

## 构建工具链

- FreeBASIC：`G:\scoop\apps\freebasic\current`
- 编译器：`G:\scoop\apps\freebasic\current\fbc.exe`
- IDE（可选）：`G:\scoop\apps\fbide\current\fbide.exe`

## 编译验证

```powershell
cd G:\code\guide\freebasic
.\build.ps1 -All
```

单文件编译：

```powershell
.\build.ps1 -File 10_file_io.bas
```

清理：

```powershell
.\build.ps1 -Clean
```

