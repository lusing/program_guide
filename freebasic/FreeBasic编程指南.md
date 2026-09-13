# FreeBASIC 编程指南（Windows）

本教程按统一标准组织：**Markdown 文档 + 独立源码 + build 脚本 + 编译验证**。  
示例目录：`examples/`，构建入口：`build.ps1`。

## 目录

1. [环境准备](#环境准备)
2. [Hello World](#hello-world)
3. [变量与类型](#变量与类型)
4. [流程控制](#流程控制)
5. [函数与过程](#函数与过程)
6. [数组](#数组)
7. [字符串](#字符串)
8. [自定义类型](#自定义类型)
9. [枚举与 Select Case](#枚举与-select-case)
10. [指针基础](#指针基础)
11. [文件读写](#文件读写)
12. [随机数与数学函数](#随机数与数学函数)
13. [时间与计时](#时间与计时)
14. [模块化风格](#模块化风格)
15. [错误处理风格](#错误处理风格)
16. [简单菜单程序](#简单菜单程序)
17. [IDE：FBIDE 快速使用](#idefbide-快速使用)
18. [统一编译验证](#统一编译验证)

---

## 环境准备

- FreeBASIC：`G:\scoop\apps\freebasic\current`
- 编译器：`G:\scoop\apps\freebasic\current\fbc.exe`
- FBIDE（可选）：`G:\scoop\apps\fbide\current\fbide.exe`
- 教程目录：`G:\code\guide\freebasic`

检查编译器：

```powershell
G:\scoop\apps\freebasic\current\fbc.exe -version
```

---

## Hello World

源码：`examples/01_hello.bas`  
演示 `Print` 与程序结构。

## 变量与类型

源码：`examples/02_types_variables.bas`  
演示 `Integer/Long/Double/String/Boolean` 和常量。

## 流程控制

源码：`examples/03_control_flow.bas`  
演示 `If...ElseIf...Else`、`For...Next`、`Do...Loop`。

## 函数与过程

源码：`examples/04_functions_subs.bas`  
演示 `Function`、`Sub`、参数传递与返回值。

## 数组

源码：`examples/05_arrays.bas`  
演示定长数组、动态数组、遍历和求和。

## 字符串

源码：`examples/06_strings.bas`  
演示连接、切片、大小写转换、搜索。

## 自定义类型

源码：`examples/07_user_type.bas`  
演示 `Type`、成员函数、结构化数据。

## 枚举与 Select Case

源码：`examples/08_enum_select.bas`  
演示 `Enum` 和多分支判断。

## 指针基础

源码：`examples/09_pointers.bas`  
演示 `Ptr`、取地址 `@`、解引用 `*`。

## 文件读写

源码：`examples/10_file_io.bas`  
演示 `Open/Print/Input/Close` 文件操作。

## 随机数与数学函数

源码：`examples/11_random_math.bas`  
演示 `Randomize/Rnd/Sqr/Abs/Sin`。

## 时间与计时

源码：`examples/12_datetime_timer.bas`  
演示 `Date/Time/Timer` 与耗时统计。

## 模块化风格

源码：`examples/13_module_style.bas`  
演示把业务逻辑拆成多个 `Function`/`Sub`。

## 错误处理风格

源码：`examples/14_error_style.bas`  
演示通过返回状态值表示成功/失败。

## 简单菜单程序

源码：`examples/15_simple_menu.bas`  
演示命令行菜单与输入分发逻辑。

---

## IDE：FBIDE 快速使用

FBIDE 路径：`G:\scoop\apps\fbide\current\fbide.exe`

建议流程：

1. 打开 FBIDE，设置编译器路径为 `G:\scoop\apps\freebasic\current\fbc.exe`
2. 新建或打开 `.bas` 文件
3. 使用 “Build / Compile” 编译
4. 使用 “Run” 运行
5. 用断点 + 单步调试检查变量值

说明：
- 本教程的自动验证基于 `build.ps1` + `fbc.exe`，与 IDE 独立。
- IDE 主要用于日常编辑、调试和快速试验。

---

## 统一编译验证

全量：

```powershell
cd G:\code\guide\freebasic
.\build.ps1 -All
```

单文件：

```powershell
.\build.ps1 -File 07_user_type.bas
```

清理：

```powershell
.\build.ps1 -Clean
```

