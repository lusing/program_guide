# Julia 编程指南（Windows）

本教程按 `guide` 统一标准组织：**Markdown 文档 + 独立示例 + build 脚本 + 可执行验证**。  
示例目录：`examples/`，验证入口：`build.ps1`。

## 目录

1. [环境准备](#环境准备)
2. [Hello World](#hello-world)
3. [变量与类型](#变量与类型)
4. [流程控制](#流程控制)
5. [函数与多重派发](#函数与多重派发)
6. [数组与广播](#数组与广播)
7. [字典与集合](#字典与集合)
8. [结构体](#结构体)
9. [异常处理](#异常处理)
10. [文件 I/O](#文件-io)
11. [模块](#模块)
12. [迭代器](#迭代器)
13. [推导式](#推导式)
14. [线性代数](#线性代数)
15. [异步任务](#异步任务)
16. [测试风格](#测试风格)
17. [统一验证](#统一验证)

---

## 环境准备

- Julia 目录：`G:\scoop\apps\julia\current`
- 执行文件：`G:\scoop\apps\julia\current\bin\julia.exe`
- 教程目录：`G:\code\guide\julia`

检查版本：

```powershell
G:\scoop\apps\julia\current\bin\julia.exe --version
```

---

## Hello World

源码：`examples/01_hello.jl`  
展示最小程序与字符串插值。

## 变量与类型

源码：`examples/02_types_variables.jl`  
展示 `Int64/Float64/Bool/String` 与类型检查。

## 流程控制

源码：`examples/03_control_flow.jl`  
展示 `if/elseif/else`、`for`、`while`。

## 函数与多重派发

源码：`examples/04_functions_dispatch.jl`  
展示同名函数对不同参数类型的分派。

## 数组与广播

源码：`examples/05_arrays_broadcast.jl`  
展示向量运算、切片、广播 `.` 语法。

## 字典与集合

源码：`examples/06_dict_set.jl`  
展示 `Dict`、`Set` 的常见操作。

## 结构体

源码：`examples/07_structs.jl`  
展示不可变 `struct` 与可变 `mutable struct`。

## 异常处理

源码：`examples/08_error_handling.jl`  
展示 `try/catch/finally` 与显式错误返回。

## 文件 I/O

源码：`examples/09_file_io.jl`  
展示写文件、读文件、行遍历。

## 模块

源码：`examples/10_modules.jl`  
展示 `module`、`export` 与调用方式。

## 迭代器

源码：`examples/11_iterators.jl`  
展示 `iterate` 协议实现自定义迭代。

## 推导式

源码：`examples/12_comprehension.jl`  
展示列表推导、条件过滤、字典推导。

## 线性代数

源码：`examples/13_linear_algebra.jl`  
展示矩阵乘法、转置、行列式。

## 异步任务

源码：`examples/14_async_tasks.jl`  
展示 `@async`、`Channel`、`fetch`。

## 测试风格

源码：`examples/15_testing_style.jl`  
展示 `Test` 标准库断言与用例组织。

---

## 统一验证

全量验证：

```powershell
cd G:\code\guide\julia
.\build.ps1 -All
```

单文件：

```powershell
.\build.ps1 -File 14_async_tasks.jl
```

清理：

```powershell
.\build.ps1 -Clean
```

