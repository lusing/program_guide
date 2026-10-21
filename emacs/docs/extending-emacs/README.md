# Emacs 扩展开发指南

一份从零到能写出可用扩展的 Emacs Lisp 教程。每一章都对应 `../../examples/` 里一个可以真跑起来的文件，文中引用的输出都是**在本机实际运行得到的**，不是手写的示意。

> 本目录是《Emacs 扩展开发指南》的分章版本：一章一文件，章末有「上一章 ｜ 下一章 ｜ 返回」导航。想学「怎么用 Emacs」（而不是写扩展），请看隔壁的 [使用 Emacs 教程](../using-emacs/README.md)。

## 这份指南怎么用

Emacs 的扩展开发有个特点：语言（Elisp）本身很小，但它的**运行环境**（buffer、point、keymap、hook、face）是独一份的。所以本指南分两部分交替推进——先把语言讲透，再讲这几个环境对象，最后用它们拼出真正的扩展。

读书方式建议是**边读边在 Emacs 里跑**。每章的示例都是自包含的，直接打开加载即可（命令在仓库的 `emacs/` 目录下执行）：

```bash
# 跑单个示例（-Q 表示不加载任何配置文件，保证结果可复现）
emacs -Q --batch -l examples/01-hello.el

# 跑全部 54 个示例，逐个核对判定标准
./run-all.sh
```

```powershell
# Windows 侧等价入口
.\build.ps1 -All
```

## 环境

本指南在 **GNU Emacs 31.1** 上编写和验证。示例只用内置库（`seq`、`cl-lib`、`ert`、`package`），不依赖任何第三方包，任何 Emacs 27 以上的版本都应该能跑，差异点会在正文里注明。

判定标准（四条，缺一不可）与 `princ`/`message` 的约定，见 [00 · 先跑起来](00-setup.md)。

## 起步

| 章 | 主题 | 示例 |
|---|---|---|
| [00 · 先跑起来：环境、运行方式与验证标准](00-setup.md) | 环境、运行方式与验证标准 | — |

## 第 1 部分 · 语言基础

把 Elisp 当作一门普通编程语言学完。语法极简——全是括号前缀表达式——真正的坑都在**求值规则**和**相等性**这类语义细节上。

| 章 | 主题 | 示例 |
|---|---|---|
| [01 · 第一个程序：输出与 quote](01-hello.md) | 第一个程序：输出与 quote | `01-hello.el` |
| [02 · 类型与值](02-types.md) | 类型与值 | `02-types.el` |
| [03 · 变量与绑定](03-variables.md) | 变量与绑定 | `03-variables.el` |
| [04 · 函数](04-functions.md) | 函数 | `04-functions.el` |
| [05 · 控制流](05-control-flow.md) | 控制流 | `05-control-flow.el` |
| [06 · 相等性：eq / eql / = / equal](06-equality.md) | 相等性：eq / eql / = / equal | `06-equality.el` |
| [07 · 列表与关联结构](07-lists.md) | 列表与关联结构 | `07-lists.el` |
| [08 · 字符串与正则](08-strings-regexp.md) | 字符串与正则 | `08-strings-regexp.el` |
| [09 · 序列与 cl-lib](09-sequences.md) | 序列与 cl-lib | `09-sequences.el` |

## 第 2 部分 · 编辑器数据结构

Emacs 的三个核心对象——**buffer**、**文本属性/overlay**、**文件**。它们有状态、有生命周期、有「当前」的概念，是写扩展和写普通 Lisp 程序的分界。

| 章 | 主题 | 示例 |
|---|---|---|
| [10 · buffer 与 point](10-buffers.md) | buffer 与 point | `10-buffers.el` |
| [11 · 文本属性与 overlay](11-text-properties.md) | 文本属性与 overlay | `11-text-properties.el` |
| [12 · 文件与目录](12-files.md) | 文件与目录 | `12-files.el` |

## 第 3 部分 · 扩展的接入点

怎么把代码**挂进 Emacs**：命令（`interactive`）、按键（keymap）、模式（mode）、事件（hook）、选项（`defcustom`）、包装已有函数（advice）。一章一个接入点。

| 章 | 主题 | 示例 |
|---|---|---|
| [13 · 交互式命令](13-interactive.md) | 交互式命令 | `13-interactive.el` |
| [14 · keymap 与按键绑定](14-keymaps.md) | keymap 与按键绑定 | `14-keymaps.el` |
| [15 · minor mode](15-minor-mode.md) | minor mode | `15-minor-mode.el` |
| [16 · major mode](16-major-mode.md) | major mode | `16-major-mode.el` |
| [17 · hook](17-hooks.md) | hook | `17-hooks.el` |
| [18 · 可定制选项 defcustom](18-custom.md) | 可定制选项 defcustom | `18-custom.el` |
| [19 · advice：不改源码改行为](19-advice.md) | advice：不改源码改行为 | `19-advice.el` |

## 第 4 部分 · 与外部世界

调用外部工具、处理时间、优雅地失败——分别对应 `process`、`timer` 和错误处理。

| 章 | 主题 | 示例 |
|---|---|---|
| [20 · 子进程](20-processes.md) | 子进程 | `20-processes.el` |
| [21 · 定时器](21-timers.md) | 定时器 | `21-timers.el` |
| [22 · 错误处理](22-errors.md) | 错误处理 | `22-errors.el` |

## 第 5 部分 · 工程化

怎么写一个正经的包：宏（好用的接口）、模块与加载（组织代码）、测试（保证它一直能用）。

| 章 | 主题 | 示例 |
|---|---|---|
| [23 · 宏](23-macros.md) | 宏 | `23-macros.el` |
| [24 · 模块、加载与打包](24-packages.md) | 模块、加载与打包 | `24-packages.el` |
| [25 · 测试](25-tests.md) | 测试 | `25-tests.el` |

## 第 6 部分 · 把一切串起来

前 25 章都是零件，这一章把零件拼成一个**可用的扩展**。

| 章 | 主题 | 示例 |
|---|---|---|
| [26 · 完整示例：一个 todo 扩展](26-todo-demo.md) | 完整示例：一个 todo 扩展 | `26-todo-demo.el` |

## 第 7 部分 · 跟随 eintr：内存模型与递归

从这部分起，我们跟随 GNU 经典教材《An Introduction to Programming in Emacs Lisp》（Robert J. Chassell 著，简称 **eintr**）的后半程走一遍：原书用 Emacs 22 时代的写法，这里全部**提炼、重写并升级到 Emacs 31**，每章照旧配一个可验证的示例。先补两块语言深水区：列表在内存里的真实形状，以及递归的几种固定模式。

| 章 | 主题 | 示例 |
|---|---|---|
| [27 · cons 单元与列表的内存模型](27-cons-cells.md) | cons 单元与列表的内存模型 | `27-cons-cells.el` |
| [28 · 递归：让函数调用自己](28-recursion.md) | 递归：让函数调用自己 | `28-recursion.el` |

## 第 8 部分 · 跟随 eintr：读懂真实代码

eintr 最有价值的部分：**读 Emacs 自带的真实源码**。这一部分解剖了 buffer 三命令、kill ring、正则推进，最后照着 eintr 的路子写出两个完整的扩展（词频统计、带坐标的柱状图在第 9 部分）。

| 章 | 主题 | 示例 |
|---|---|---|
| [29 · 读懂真实函数：三个 buffer 命令的走查](29-read-source.md) | 读懂真实函数：三个 buffer 命令的走查 | `29-read-source.el` |
| [30 · kill ring：剪切与粘贴的实现](30-kill-ring.md) | kill ring：剪切与粘贴的实现 | `30-kill-ring.el` |
| [31 · 正则驱动的文本推进：forward-sentence 与 forward-paragraph](31-forward-sentence.md) | 正则驱动的文本推进 | `31-forward-sentence.el` |
| [32 · 词频统计：从 count-words 到一个完整的扩展](32-count-words.md) | 词频统计：从 count-words 到一个完整的扩展 | `32-count-words.el` |

## 第 9 部分 · 跟随 eintr：调试与收尾项目

收尾三件事：调试（eintr 的 Debugging 一章，在 `--batch` 下用实测数据讲透）、初始化文件与 mode line（你的代码住哪、屏幕最下面那条线怎么定制）、以及全书的收尾项目——打印一张带坐标的柱状图。

| 章 | 主题 | 示例 |
|---|---|---|
| [33 · 调试：debug-on-entry、edebug 与 batch 下的排查](33-debugging.md) | 调试：debug-on-entry、edebug 与 batch 下的排查 | `33-debugging.el` |
| [34 · 初始化文件与 mode line](34-init-mode-line.md) | 初始化文件与 mode line | `34-init-mode-line.el` |
| [35 · 收尾项目：打印一张带坐标的柱状图](35-graph.md) | 收尾项目：打印一张带坐标的柱状图 | `35-graph.el` |

## 第 10 部分 · 对照参考手册补齐的主题

前 9 部分是「从零写出一个扩展」的主线。主线走完之后，回头对照《Emacs Lisp 参考手册》的目录，还有一批**主线没覆盖到、但写扩展迟早会撞上**的主题：数字与位运算、符号的四个格子、求值与 backquote、哈希表、读取与打印、minibuffer 输入、字节编译、marker、窗口与框架、语法表。这一部分补齐它们，体例照旧：一章一个可跑的示例，结论全部来自实测。

| 章 | 主题 | 示例 |
|---|---|---|
| [36 · 数字：整除、取整、bignum 与位运算](36-numbers.md) | 整除、取整、bignum 与位运算 | `36-numbers.el` |
| [37 · 符号：四个格子、属性表与 obarray](37-symbols.md) | 符号的四个格子、属性表与 obarray | `37-symbols.el` |
| [38 · 求值：quote、backquote 与 eval](38-evaluation.md) | 求值：quote、backquote 与 eval | `38-evaluation.el` |
| [39 · 哈希表：测试函数、遍历与弱引用](39-hash-tables.md) | 哈希表：测试函数、遍历与弱引用 | `39-hash-tables.el` |
| [40 · 读取与打印：read、prin1、princ 与 print-* 开关](40-reading-printing.md) | 读取与打印：read、prin1、princ 与 print-* 开关 | `40-reading-printing.el` |

## 第 11 部分 · 跟随 CL 手册：Common Lisp 扩展

这一部分跟随《GNU Emacs Common Lisp Emulation》手册（简称 **CL 手册**），把 cl-lib 按手册章节系统讲一遍：从来历与命名约定讲起，依次覆盖参数列表、宏工具、广义变量、作用域与控制流、`cl-loop`、序列与列表，最后收在类型系统、结构、断言与 `cl-print`。体例照旧：一章一个可跑的示例，结论全部来自 Emacs 31.1 实测。

| 章 | 主题 | 示例 |
|---|---|---|
| [41 · cl-lib 是什么：来历、加载、命名与移植](41-cl-lib-overview.md) | cl-lib 是什么：来历、加载、命名与移植 | `41-cl-lib-overview.el` |
| [42 · 参数列表：cl-defun、cl-defmacro 与 &key](42-argument-lists.md) | 参数列表：cl-defun、cl-defmacro 与 &key | `42-argument-lists.el` |
| [43 · 写宏的工具：cl-eval-when、cl-once-only 与 compiler macro](43-macro-tools.md) | 写宏的工具：cl-eval-when、cl-once-only 与 compiler macro | `43-macro-tools.el` |
| [44 · 广义变量：setf、cl-letf 与就地修改](44-generalized-variables.md) | 广义变量：setf、cl-letf 与就地修改 | `44-generalized-variables.el` |
| [45 · 作用域与控制流：cl-flet、cl-block 与多值](45-scoping-control.md) | 作用域与控制流：cl-flet、cl-block 与多值 | `45-scoping-control.el` |
| [46 · cl-loop：Loop 宏的完整语法](46-loop-facility.md) | cl-loop：Loop 宏的完整语法 | `46-loop-facility.el` |
| [47 · 序列与列表：cl-map、cl-reduce 与列表构造](47-sequences-lists.md) | 序列与列表：cl-map、cl-reduce 与列表构造 | `47-sequences-lists.el` |
| [48 · 类型与结构：cl-defstruct、cl-assert 与 cl-print](48-types-structs.md) | 类型与结构：cl-defstruct、cl-assert 与 cl-print | `48-types-structs.el` |

## 第 12 部分 · 跟随 EIEIO 手册：Emacs 面向对象编程

这一部分跟随 GNU 官方《EIEIO 手册》，把 Emacs 内置的面向对象层系统讲一遍：`defclass` 定义类、`cl-defgeneric`/`cl-defmethod` 写泛型与方法、限定符与方法链、五个预定义基类（named、singleton、tracker、inheritor、persistent）、内省与废弃清单。手册里的 Emacs 23 时代写法（`:name` initarg、`:tracker-symbol`、`defgeneric`/`defmethod`、`object-print` 等）全部提炼、重写并升级到 Emacs 31.1，体例照旧：一章一个可跑的示例，结论全部来自实测。

| 章 | 主题 | 示例 |
|---|---|---|
| [49 · EIEIO 快速上手：defclass、构造、泛型与方法](49-eieio-quickstart.md) | EIEIO 快速上手：defclass、构造、泛型与方法 | `49-eieio-quickstart.el` |
| [50 · defclass 详解：槽选项与类选项](50-eieio-defclass.md) | defclass 详解：槽选项与类选项 | `50-eieio-defclass.el` |
| [51 · 槽与访问：slot-value、oref 与绑定状态](51-eieio-slots.md) | 槽与访问：slot-value、oref 与绑定状态 | `51-eieio-slots.el` |
| [52 · 方法与调用：特化、限定符与方法链](52-eieio-methods.md) | 方法与调用：特化、限定符与方法链 | `52-eieio-methods.el` |
| [53 · 预定义基类：named、singleton、tracker、inheritor 与 persistent](53-eieio-base-classes.md) | 预定义基类：named、singleton、tracker、inheritor 与 persistent | `53-eieio-base-classes.el` |
| [54 · 内省与工具：谓词族、object-assoc 与废弃清单](54-eieio-introspection.md) | 内省与工具：谓词族、object-assoc 与废弃清单 | `54-eieio-introspection.el` |

## 附录

| 附录 | 内容 |
|---|---|
| [附录 A · 常见坑速查](appendix-a-pitfalls.md) | 常见坑速查（按症状查） |
| [附录 B · 命令与变量速查](appendix-b-cheatsheet.md) | 命令与变量速查 |
