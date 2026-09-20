# OCaml 编程指南

一本从零到能用的 OCaml 教程，31 章、26 个可运行示例。每一章的代码都可以在 OCaml 顶层解释器（ocaml）、字节码编译器（ocamlc）与原生编译器（ocamlopt）上直接运行；全书在 macOS 与 Windows（MSYS2 UCRT64，OCaml 5.4.1）双平台全量验证通过。

## OCaml 是什么

OCaml 是 Objective Caml 的缩写，是 Caml 语言家族的主要实现。它诞生于 1996 年的法国 INRIA 研究所，由 Xavier Leroy 等人开发。OCaml 在函数式编程的基础上融合了命令式和面向对象两种范式，形成了独特的「多范式函数式语言」定位。

OCaml 的核心特点可以概括为以下几点：

**多范式**：函数式是默认风格，但你可以随时使用 `ref`、`Array`、`Hashtbl` 等可变数据结构，也可以用对象和类做面向对象编程。它不强迫你用某一种范式，而是让你在不同场景选择最合适的工具。

**强静态类型 + 类型推断**：OCaml 的类型系统基于 Hindley-Milner 算法，能在几乎不需要类型标注的情况下推导出所有表达式的类型。类型检查在编译期完成，运行时没有类型信息的开销。

**模式匹配**：这是 OCaml 最强大的特性之一。你可以对变体、元组、记录、列表等几乎所有数据结构进行模式匹配，编译器还会帮你检查是否穷尽了所有情况，避免漏写分支。

**模块系统**：OCaml 的模块系统（module / signature / functor）是函数式语言中最强大的模块系统之一。`functor`（函子）是从模块到模块的函数，可以用来做参数化的抽象，而且这一切都在编译期完成，运行时零开销。

**性能接近 C**：`ocamlopt` 原生编译器生成的代码性能在函数式语言中属于第一梯队，通常能达到 C 的 1/3 到 1/2 的速度，在某些数值计算场景下甚至更快。这得益于高效的字节码表示、增量 GC 和成熟的编译优化。

### 与 SML / Haskell 的对比

| | OCaml | Standard ML | Haskell |
|---|---|---|---|
| 范式 | 函数式 + 命令式 + 面向对象 | 函数式 + 命令式 | 纯函数式 |
| 求值策略 | 严格求值 | 严格求值 | 惰性求值 |
| 类型系统 | HM + 行类型 + 类类型 | HM + 值限制 | HM + 类型类 |
| 模块系统 | module / signature / functor | signature / structure / functor | 无原生模块系统 |
| 副作用 | 自由使用，不隔离 | 自由使用 | 通过 Monad 隔离 |
| 字符串 | 字节串（bytes/string 分离） | 字节串 | Unicode 字符串 |
| 主要实现 | OCaml（单一参考实现） | SML/NJ、Poly/ML、MLton | GHC（事实上的标准） |

简单来说：OCaml 比 SML 更「实用主义」——它加了对象、加了可变数组、加了哈希表，让你写工程代码时不用硬凹纯函数式。它比 Haskell 更「接地气」——严格求值让性能模型简单直观，副作用不用绕 monad，上手门槛低。

## 目录

- [第 1 章 认识 OCaml](#第-1-章-认识-ocaml)
- [第 2 章 工具链与运行方式](#第-2-章-工具链与运行方式)
- [第 3 章 程序结构与求值](#第-3-章-程序结构与求值)
- [第 4 章 类型系统](#第-4-章-类型系统)
- [第 5 章 表达式与运算符](#第-5-章-表达式与运算符)
- [第 6 章 元组与记录](#第-6-章-元组与记录)
- [第 7 章 模式匹配](#第-7-章-模式匹配)
- [第 8 章 列表与高阶列表函数](#第-8-章-列表与高阶列表函数)
- [第 9 章 变体类型（代数数据类型）](#第-9-章-变体类型代数数据类型)
- [第 10 章 字符串与字符](#第-10-章-字符串与字符)
- [第 11 章 递归与尾递归](#第-11-章-递归与尾递归)
- [第 12 章 异常](#第-12-章-异常)
- 第 13 章 高阶函数与闭包
- 第 14 章 模块与签名
- 第 15 章 Functor（函子）
- 第 16 章 不透明约束与抽象数据类型
- 第 17 章 模块系统进阶：open / include / local
- 第 18 章 可变状态：ref / Array / Hashtbl
- 第 19 章 排序与经典算法
- 第 20 章 数值计算
- 第 21 章 解析：词法分析与递归下降
- 第 22 章 输入输出与文件
- 第 23 章 测试与断言
- 第 24 章 记录、对象与类
- 第 25 章 流与序列
- 第 26 章 综合实战：成绩 CSV 分析与报告
- 第 27 章 错误处理：option / result 与绑定运算符
- 第 28 章 GADT：广义代数数据类型
- 第 29 章 OCaml 5 并发：Domain 与 Effect
- 第 30 章 ocamllex：词法分析器生成器
- 第 31 章 坑清单与最佳实践

对应示例在 `examples/` 目录下，文件名前缀为两位编号（第 30 章
对应 `examples/26_ocamllex/` 子目录）。运行方式（macOS / Linux）：

```bash
ocaml examples/01_basics.ml          # 解释执行
ocamlc -w -24 examples/01_basics.ml -o 01_basics && ./01_basics   # 字节码编译
ocamlopt -w -24 examples/01_basics.ml -o 01_basics && ./01_basics # 原生编译
ocamlc -w -24 -I +unix unix.cma -o 15_algorithms examples/15_algorithms.ml  # 用到 Unix 时
```

用到 `Unix` 模块的示例（15/18/21/22/25）**必须显式写 `-I +unix`**：
OCaml 5 起不写会吐 `Alert ocaml_deprecated_auto_include`（属告警）。

Windows（MSYS2 UCRT64）下的等价命令与专属坑见第 2 章的
「2.8 在 Windows 上使用 OCaml（MSYS2 实战）」；macOS 的实测坑见
第 31.9 节。推荐统一用两个等价入口做编译与验证（跨平台）：

```powershell
pwsh ./build.ps1 -All            # 编译并运行全部示例（字节码）
pwsh ./build.ps1 -All -Native    # 追加原生通道
pwsh ./build.ps1 -All -Interp    # 追加顶层解释器通道
```

```bash
./run-all.sh                     # shell 入口，等价（字节码 + 原生）
./run-all.sh --interp            # 追加顶层解释器通道
```

---

## 第 1 章 认识 OCaml

### 1.1 OCaml 的定位

OCaml 不是一门学院派的玩具语言，也不是一门只适合写编译器的小众语言。它是一门**通用系统级编程语言**，在以下领域有成熟的工业界应用：

- **编译器与形式化工具**：Infer（Facebook 的静态分析工具）、Coq 证明助手、Frama-C（C 代码验证）
- **金融系统**：Jane Street 整套交易基础设施都用 OCaml 写
- **系统编程**：MirageOS（unikernel）、Xen 工具链
- **Web 开发**：Ocsigen/Eliom 全栈框架、Rescript（前身 BuckleScript）编译到 JavaScript

它的设计哲学很明确：**在保持函数式编程核心优势的同时，给程序员足够的「逃生舱」**。纯函数式写不出来或者写出来性能不够？那就用 `ref` 和循环。模块层级抽象不够？那就用 functor。需要面向对象的继承和子类型？那就用对象和类。

这种「多范式」不是简单的功能堆砌，而是有一套统一的类型系统把它们串起来。`ref` 不是特殊语法，它就是个带可变字段的记录；对象不是另一套类型系统，它是行类型（row type）的一种应用；甚至模块本身也有类型（signature）。

### 1.2 为什么是 OCaml 而不是别的函数式语言

如果你在找一门「能干活的函数式语言」，OCaml 有几个不可替代的优势：

**1. 学习曲线平缓**

相比 Haskell，OCaml 的入门门槛低很多。你不需要先理解 Monad、Functor（Haskell 那个，不是 OCaml 的模块函子）、惰性求值才能写第一个程序。你可以像写 Python 一样写 OCaml，然后逐步引入函数式的概念。

**2. 性能模型清晰**

严格求值意味着你看到的代码就是实际执行的顺序。不会有 thunk 堆积，不会有「为什么这段代码内存爆了」的困惑。配合 `ocamlopt` 的原生代码生成，性能通常在你预期之内。

**3. 编译速度快**

OCaml 的编译速度在静态类型语言中属于第一梯队。大型项目也能在几秒内完成编译，这对于开发体验至关重要。

**4. 模块系统强大且实用**

很多语言的「模块」就是个命名空间。OCaml 的模块是一等公民——你可以把模块当参数传给 functor，可以用 signature 约束模块，可以用不透明约束实现真正的封装。这是大型项目架构的利器。

### 1.3 OCaml 的语法直觉

如果你之前写过 C / Java / Python 这类语言，OCaml 的语法可能会让你一开始有点不适应。但它的语法其实非常有规律，核心就三条：

1. **函数调用用空格，不用括号和逗号**：`f x y` 是调用函数 `f`，参数是 `x` 和 `y`。
2. **几乎一切都是表达式**：`if`、`match`、`let` 都是表达式，都有返回值。没有「语句」这个概念（除了 `;` 连接的副作用序列）。
3. **`let` 是绑定，不是赋值**：`let x = 1` 的意思是「给值 1 起个名字叫 x」，x 不能被修改。要修改得用 `ref`。

记住这三条，你就能看懂 80% 的 OCaml 代码了。剩下的 20% 是模式匹配、变体类型、模块系统这些特性——它们才是 OCaml 的精华所在。

### 1.4 本章你会学到什么

本章是概念性的，没有代码。从第 2 章开始我们会接触实际的工具和代码。在进入下一章之前，请确保你理解了以下概念：

- OCaml 是一门多范式的函数式语言
- 它有强大的类型推断，不需要到处写类型标注
- 模式匹配是它的核心特性之一
- 模块系统（module / functor）是它区别于其他函数式语言的重要特征
- 它的原生编译器生成的代码性能很高

---

## 第 2 章 工具链与运行方式

对应示例：`examples/01_basics.ml`

### 2.1 三种运行方式

OCaml 提供了三种主要的运行方式，各有用途：

| 方式 | 命令 | 特点 | 适用场景 |
|---|---|---|---|
| 顶层解释器 | `ocaml` | 交互式 REPL，逐行求值 | 学习、调试、快速验证 |
| 字节码编译器 | `ocamlc` | 编译成字节码，跨平台 | 快速编译、开发调试 |
| 原生编译器 | `ocamlopt` | 编译成本地机器码，性能高 | 生产环境、性能敏感 |

**顶层解释器（ocaml）** 是一个 REPL（Read-Eval-Print Loop）。启动后你可以输入表达式，它会立即求值并打印结果。每个顶层表达式需要用 `;;` 结束。

```bash
$ ocaml
        OCaml version 4.14.0

# 1 + 2;;
- : int = 3
# let x = 42;;
val x : int = 42
```

输入 `#quit;;` 或按 Ctrl+D 退出。

**字节码编译器（ocamlc）** 把 OCaml 源码编译成字节码，然后由 OCaml 字节码解释器执行。字节码文件的后缀是 `.cmo`，多个 `.cmo` 可以链接成可执行文件。

```bash
ocamlc hello.ml -o hello
./hello
```

字节码编译速度很快，但运行速度大约是原生代码的 1/2 到 1/3。它的好处是跨平台——同一份字节码可以在任何有 OCaml 运行时的机器上运行。

**原生编译器（ocamlopt）** 直接生成目标平台的机器码。生成的可执行文件性能接近 C，启动也更快。

```bash
ocamlopt hello.ml -o hello
./hello
```

原生编译的产物包括 `.cmx`（编译单元）、`.o`（目标文件）和最终的可执行文件。

### 2.2 第一个程序

让我们写一个最简单的 OCaml 程序：

```ocaml
(* hello.ml *)
let () = print_endline "Hello, OCaml!"
```

三种方式运行它：

```bash
# 方式一：直接解释执行
ocaml hello.ml

# 方式二：字节码编译
ocamlc hello.ml -o hello && ./hello

# 方式三：原生编译
ocamlopt hello.ml -o hello && ./hello
```

三种方式都会输出：
```
Hello, OCaml!
```

注意 `let () = ...` 这个写法。它的意思是「把右边的表达式绑定到模式 `()` 上」。因为 `()` 是 unit 类型的唯一值，所以这个匹配一定会成功。这是 OCaml 中表达「程序入口」的惯用写法——它不是特殊语法，只是 `let` 模式匹配的一个应用。

### 2.3 utop：更好的顶层

`ocaml` 自带的顶层比较朴素，没有语法高亮、历史搜索、自动补全这些功能。社区常用 `utop` 作为替代品：

```bash
# 安装（需要 opam）
opam install utop

# 启动
utop
```

`utop` 支持：
- 语法高亮
-  Tab 自动补全
-  更好的输出格式（彩色、缩进）
-  行编辑（类似 readline）

本书的代码示例在 `ocaml` 和 `utop` 下都能运行，但为了保持通用性，我们以 `ocaml` 为准。

### 2.4 .ml 文件的结构

一个 `.ml` 文件就是一串顶层声明（toplevel declarations），从上到下依次求值。最常见的顶层声明是 `let` 绑定：

```ocaml
let x = 1 + 2
let y = x * 3
let () = print_int y
```

在 `.ml` 文件中，**`let` 之间不需要 `;;`**。`;;` 只在顶层交互环境中需要，用来告诉解释器「我输入完了，你求值吧」。

但是，如果你想在 `.ml` 文件中直接写一个表达式（不是 `let` 绑定），就需要用 `;;` 来分隔：

```ocaml
print_endline "hello";;   (* 直接的表达式，需要 ;; 结束 *)
let x = 1                 (* let 绑定，不需要 ;; *)
```

实际项目中，推荐的做法是**所有顶层代码都用 `let () = ...` 包裹**，这样就不需要 `;;` 了，代码也更整洁。

### 2.5 注释

OCaml 的注释用 `(* ... *)`，可以嵌套：

```ocaml
(* 这是外层注释
   (* 这是内层注释 —— 完全合法 *)
   外层继续
*)
```

这是一个小但实用的特性。你想临时注释掉一大段代码时，不用担心里面已经有注释会导致提前结束。

OCaml 没有单行注释语法。习惯上，单行注释也写成 `(* ... *)`。

### 2.6 opam：OCaml 的包管理器

`opam` 是 OCaml 的官方包管理器，类似于 Python 的 pip、Node.js 的 npm。它不仅能安装第三方库，还能管理多个 OCaml 编译器版本（通过「switch」）。

```bash
# 初始化
opam init

# 安装一个包
opam install base

# 创建一个新的 switch（独立的 OCaml 环境）
opam switch create 4.14.0

# 激活当前目录的环境
eval $(opam env)
```

本书的前半部分（第 1-12 章）只使用标准库，不需要安装任何额外的包。后面涉及第三方库的章节会说明安装方法。

### 2.7 dune：构建工具

对于超过一个文件的项目，你需要一个构建工具。`dune` 是 OCaml 社区的标准构建工具，类似于 Rust 的 cargo。

一个最简单的 `dune` 项目：

```
myproject/
├── dune-project
├── bin/
│   ├── dune
│   └── main.ml
```

`dune-project` 内容：
```
(lang dune 3.0)
```

`bin/dune` 内容：
```
(executable
 (name main))
```

构建并运行：
```bash
dune build
dune exec ./bin/main.exe
```

本书的示例都是单文件的，直接用 `ocaml` / `ocamlc` / `ocamlopt` 运行即可。但在实际项目中，你几乎一定会用到 `dune`。

### 2.8 在 Windows 上使用 OCaml（MSYS2 实战）

> 本节是本教程 2026 年在 Windows 11 + MSYS2 UCRT64
> （OCaml 5.4.1）上全量验证 26 个示例后总结的实战经验，
> 每一条坑都实际踩过、修过、复核过。

#### 安装

MSYS2 的 UCRT64 环境是目前 Windows 上最省心的原生 OCaml 发行渠道：

```bash
# 在 MSYS2 UCRT64 shell 里（或用 pacman 直接调）：
pacman -S mingw-w64-ucrt-x86_64-ocaml mingw-w64-ucrt-x86_64-flexdll
```

工具链位于 `<msys2根目录>\ucrt64\bin`（如 `C:\msys64\ucrt64\bin`；
经 scoop 安装的 MSYS2 在 `<scoop>\apps\msys2\current\ucrt64\bin`）。

#### 坑 1：从原生 shell 调用必须设 OCAMLLIB

在 MSYS2 自己的 shell 里一切正常；但从 PowerShell / CMD 直接调用
`ucrt64\bin` 里的编译器，会在**编译期**就报：

```
File "command line", line 1:
Error: Unbound module Stdlib
```

原因：MSYS2 版 OCaml 的编译器把标准库位置编译成了 MSYS 根的
POSIX 路径（`ocamlc -where` 打印 `/ucrt64/lib/ocaml`），原生
Windows 进程解析不了。解决办法——把 `OCAMLLIB` 指到真实位置：

```powershell
$ucrt = "C:\msys64\ucrt64"          # 换成你的 MSYS2 根
$env:Path      = "$ucrt\bin;$env:Path"
$env:OCAMLLIB  = "$ucrt\lib\ocaml"
```

本教程的 `build.ps1` 会自动发现编译器并推导 `OCAMLLIB`，免去手工设置。

#### 坑 2：ocamlopt 需要 flexlink，而 ocaml 包可能不带它

`ocamlopt`（原生编译）链接阶段调用 Windows 专用的 `flexlink`
（flexdll 工具）。实测 `mingw-w64-ucrt-x86_64-ocaml 5.4.1-2`
没有把它作为硬依赖装好，症状是：

```
'flexlink' is not recognized as an internal or external command
File "caml_startup", line 1:
Error: Error during linking (exit code 1)
```

装上 `mingw-w64-ucrt-x86_64-flexdll` 包即可。

#### 坑 3：字节码产物的命名与运行

- `ocamlc -o build/01_basics` 在 Windows 上生成的是**没有 `.exe`
  后缀的 PE 文件**。PowerShell 的 `& .\build\01_basics` 会拒绝执行
  （“无法在管道中间运行文档”），要么显式写 `-o xxx.exe`，
  要么用 `Start-Process`（CreateProcess 不在乎后缀）。
- 字节码可执行文件运行时要在 PATH 上找到 `ocamlrun`
  （否则报 `Cannot exec ocamlrun`）——PATH 前缀要保持挂着。
- 链接了 `unix` 等库的字节码程序运行时还要靠 `OCAMLLIB` 找到
  `stublibs` 里的 DLL（如 `dllunixbyt.dll`），否则直接
  `Fatal error` 退出。

#### 坑 4：数字开头的文件名不是合法模块名

`01_basics.ml` 会触发警告 24（bad-module-name）。对单文件示例
无伤大雅，本教程统一用 `-w -24` 静音。真正要注意的是**多文件
项目**：`ocamlc a.ml b.ml` 会把 `a.ml` 当作模块 `A` 链接，
文件名必须能映射到合法模块名（大写字母开头）——第 30 章的
ocamllex 示例因此把 `.mll` 放在 `26_ocamllex/` 子目录里、
用合法的 `ocamllex_expr.mll` 命名。

#### 坑 5：Unix 模块要手工链接

用到 `Unix.gettimeofday` / `Unix.stat` / `Unix.mkdir` 的文件，
裸 `ocamlc` 会报 `Unbound module Unix`（这在 macOS 上同样成立）。
需要显式链接：

```powershell
ocamlc -w -24 -I "$env:OCAMLLIB\unix" unix.cma -o build/15_algorithms.exe examples/15_algorithms.ml
ocamlopt -w -24 -I "$env:OCAMLLIB\unix" unix.cmxa -o build/15_algorithms_opt.exe examples/15_algorithms.ml
```

本教程 15/18/21/22/25 号示例用到 unix，`build.ps1` 已内置依赖表。

#### 坑 6：标准库的版本差异（5.4 实测）

- `Stream` 模块不在标准库发行里（`Unbound module Stream`，
  没有 stream.cma），教程示例用 Seq 实现了兼容层，见第 25 章。
- `Domain.cpu_count` 不存在，用 `Domain.recommended_domain_count`。
- `print_bool` 不存在（用 `print_string (string_of_bool b)`）。
- `Seq.nth`、`Seq.sort` 不存在。
- Printf 的 `%c` 不支持宽度修饰（`%9c` 是编译错）；
  Scanf 的 `'\n'` 是字面匹配而非“跳过任意空白”，`%s` 遇空白即停，
  想读到行尾用 `%s@\n`。

#### 一键验证

本教程所有示例在 Windows 上用一条命令完成“编译 + 运行 +
结束标记核对”：

```powershell
pwsh ./build.ps1 -All            # 26/26 全绿（字节码）
pwsh ./build.ps1 -All -Native    # 追加原生通道，51/51 全绿
```

---

## 第 3 章 程序结构与求值

对应示例：`examples/01_basics.ml`

### 3.1 let 绑定

OCaml 中最基本的构造是 `let` 绑定。它的形式是：

```ocaml
let name = expression
```

意思是「给 `expression` 的值起个名字叫 `name`」。这不是赋值——`name` 是不可变的，你不能后来再给它赋别的值。

```ocaml
let x = 42
let name = "OCaml"
let pi = 3.14159
```

`let` 也可以是局部的，用 `let ... in ...` 的形式：

```ocaml
let result =
  let x = 3 in
  let y = 4 in
  x * x + y * y
```

`let ... in ...` 是一个表达式，它的值是 `in` 后面那个表达式的值。上面的代码中，`result` 的值是 25。

### 3.2 let 和 = 的区别

初学者经常混淆 `let` 中的 `=` 和比较运算符 `=`。它们是完全不同的东西：

- `let x = e` 中的 `=` 是**绑定符号**，意思是「把名字 x 绑到 e 的值上」。它不是在做比较。
- `a = b` 中的 `=` 是**比较运算符**，返回 `bool`。它的意思是「a 和 b 相等吗？」。

```ocaml
let x = 5          (* 绑定：x 的值是 5 *)
let y = x = 5      (* 绑定：y 的值是 (x = 5) 的结果，即 true *)
```

第二行的解析是 `let y = (x = 5)`，因为 `=` 作为运算符的优先级比 `let` 中的 `=` 高。

### 3.3 顶层求值顺序

在一个 `.ml` 文件中，`let` 绑定按书写顺序从上到下依次求值。后面的绑定可以引用前面的绑定：

```ocaml
let a = 10
let b = a + 20     (* 可以引用 a，因为 a 已经求值了 *)
let c = b * 2      (* 可以引用 b *)
```

但前面的绑定不能引用后面的绑定：

```ocaml
let x = y + 1      (* 错误：Unbound value y *)
let y = 42
```

这是因为 OCaml 是严格求值的，而且顶层绑定是顺序求值的。

如果你需要定义递归的东西（函数或数据类型），需要用 `let rec` 或 `type rec`，见第 11 章。

### 3.4 let rec：递归绑定

普通的 `let` 绑定中，右边的表达式看不到左边的名字。要定义递归函数，需要用 `let rec`：

```ocaml
let rec factorial n =
  if n <= 1 then 1 else n * factorial (n - 1)
```

`rec` 的意思是「recursive」，它让 `factorial` 这个名字在函数体内也可见。

`let rec` 也可以同时定义多个互相递归的函数，用 `and` 连接：

```ocaml
let rec is_even n =
  if n = 0 then true else is_odd (n - 1)
and is_odd n =
  if n = 0 then false else is_even (n - 1)
```

`is_even` 和 `is_odd` 互相调用对方，所以必须用 `let rec ... and ...` 同时定义。这在第 11 章会详细讨论。

### 3.5 注释：不能嵌套？等一下

等一下——第 2 章说 OCaml 的注释可以嵌套，对吗？没错，OCaml 的 `(* ... *)` 注释**是可以嵌套的**。这和 SML 一样，但和 C / Java 不一样。

```ocaml
(* 外层
   (* 内层：完全没问题 *)
   外层继续
*)
```

这是一个很方便的特性。临时注释掉一大段代码时，里面原有的注释不会碍事。

代价是注释必须配平。如果你漏了一个 `*)`，后面的代码会全部被当成注释，而编译器报错的位置可能离真正的问题很远。

### 3.6 值限制简介

值限制（value restriction）是 OCaml 类型系统中一个容易让人困惑的概念。我们会在第 4 章详细讨论，这里先给个直觉。

OCaml 的类型推断会给表达式推导出最一般的（多态的）类型。比如：

```ocaml
let id x = x     (* 'a -> 'a，多态的 *)
```

但不是所有表达式都能被泛化成多态的。只有「语法上的值」才能被完全泛化。什么是语法值？简单来说就是不会产生副作用的、不可约的表达式：常量、函数、`let` 绑定、数据构造子等。

最经典的反例是函数调用的结果：

```ocaml
let f = (fun x -> x) []    (* 这不是语法值，不能完全泛化 *)
```

虽然 `(fun x -> x) []` 求值后就是 `[]`，但它在语法上是一个函数调用，不是值。值限制说的就是：**只有语法值才能被泛化**。

为什么要有这个限制？因为如果允许所有表达式都被泛化，可能会导致类型不安全——特别是涉及可变状态的时候。第 4 章会用具体的例子说明这个问题。

### 3.7 ; 与单位类型

`;` 用来按顺序执行多个表达式，并丢弃前一个的结果。它通常用于有副作用的表达式：

```ocaml
let () =
  print_endline "first";
  print_endline "second";
  print_endline "third"
```

`e1; e2` 的意思是「先求值 `e1`，丢掉它的结果，再求值 `e2`，`e2` 的值就是整个表达式的值」。

`e1` 的结果可以是任何类型，因为它被丢掉了。但习惯上，`e1` 应该返回 `unit` 类型（即 `()`），因为这明确表示「这个表达式只有副作用，返回值没用」。

`unit` 类型只有一个值：`()`。它类似于 C 语言的 `void`，但 `unit` 是一个真正的类型，`()` 是一个真正的值。你可以把它传来传去，也可以模式匹配它。

```ocaml
let print_hello () = print_endline "hello"
```

这里的 `()` 是一个模式，匹配 `unit` 类型的唯一值。这个函数接受一个 `unit` 参数，返回 `unit`。

### 3.8 本章小结

这一章的核心概念：

- `let` 是绑定，不是赋值
- `let ... in ...` 是局部绑定，是一个表达式
- `let rec` 用于递归定义
- `let rec ... and ...` 用于互递归
- 注释可以嵌套，但必须配平
- `;` 用于顺序执行副作用表达式
- `unit` 类型只有一个值 `()`，用于表示「没有有用的返回值」
- 值限制：只有语法值才能被完全泛化（第 4 章详解）

这些是理解后面所有内容的基础。如果有哪里没完全懂也没关系，随着后面章节的代码示例越来越多，你会逐渐熟悉的。

---

## 第 4 章 类型系统

对应示例：`examples/02_types.ml`

### 4.1 OCaml 的类型哲学

OCaml 的类型系统是它最核心的竞争力之一。它不是那种「到处写类型注解才能运行」的语言，也不是那种「运行时才发现类型错了」的语言。它走的是中间路线——**强静态类型 + 全局类型推断**。

强静态类型意味着：
- 所有表达式的类型在编译期就确定了
- 类型错误在编译期就被捕获，不会拖到运行时
- 没有隐式类型转换（`int` 不会自动变成 `float`，反之亦然）

全局类型推断意味着：
- 你几乎不需要写类型标注
- 编译器能推导出最一般的类型（principal type）
- 推断是全局的——一个函数的类型由它的所有使用方式共同决定

这套类型系统的理论基础是 **Hindley-Milner（HM）类型系统**，也叫 Damas-Milner 类型系统。它的核心性质是：**只要程序是类型良好的，就一定存在一个最一般的类型，而且算法一定能找到它**。

### 4.2 基础类型

OCaml 的基础类型包括：

| 类型 | 含义 | 字面量示例 |
|---|---|---|
| `int` | 有符号整数 | `42`, `-10`, `0xFF`, `0o77`, `0b1010` |
| `float` | 双精度浮点数 | `3.14`, `2.0`, `1.5e3`, `infinity`, `nan` |
| `bool` | 布尔值 | `true`, `false` |
| `char` | 单字节字符 | `'a'`, `'\n'`, `'\65'` |
| `string` | 不可变字节串 | `"hello"`, `"line1\nline2"` |
| `unit` | 单位类型 | `()` |

```ocaml
(* int：在 64 位平台上是 63 位有符号整数（1 位用于 GC 标记） *)
let zero = 0
let max_int = 4611686018427387903   (* 约 2^62 - 1 *)
let hex = 0xFF          (* 十六进制 255 *)
let oct = 0o77          (* 八进制 63 *)
let bin = 0b1010        (* 二进制 10 *)
let big = 1_000_000     (* 下划线分隔，提高可读性 *)

(* float：双精度 IEEE 754，与 C 的 double 相同 *)
let pi = 3.1415926535
let e = 2.71828
let inf = infinity
let not_a_number = nan

(* bool：只有两个值 *)
let t = true
let f = false

(* char：单字节，用单引号 *)
let c_a = 'a'
let c_newline = '\n'

(* string：不可变字节序列 *)
let s = "hello"

(* unit：只有一个值 () *)
let u = ()
```

关于 `int` 的大小需要特别注意：在 64 位平台上，OCaml 的 `int` 是 **63 位**的，不是 64 位。少的那 1 位是给垃圾回收器用的标记位。这意味着 `int` 的范围大约是 -2^62 到 2^62 - 1。如果你需要 64 位整数，应该用 `Int64` 模块。

### 4.3 int 与 float 的分离

OCaml 最让新手惊讶的设计之一是：**整数和浮点数使用完全不同的运算符**。

| 操作 | int 运算符 | float 运算符 |
|---|---|---|
| 加法 | `+` | `+.` |
| 减法 | `-` | `-.` |
| 乘法 | `*` | `*.` |
| 除法 | `/` | `/.` |
| 取模 | `mod` | `mod_float` |
| 幂 | （无） | `**` |

```ocaml
let int_sum = 3 + 4              (* int + int -> int *)
let float_sum = 3.0 +. 4.0       (* float +. float -> float *)

(* 错误：不能混用 *)
(* let bad = 3 + 4.0 *)          (* 类型错误 *)
```

为什么要这么设计？为什么不像 C 那样自动提升？

原因有两个：

**1. 类型推断的需要。** 如果 `+` 既能加 int 又能加 float，那 `fun x y -> x + y` 的类型是什么？在 HM 类型系统中，这需要「重载」的支持，而 HM 原生不支持重载。OCaml 的解决方案是干脆给不同类型用不同的运算符。这样类型推断简单干净，不需要类型类也不需要类型注解。

**2. 显式优于隐式。** 整数和浮点数的运算规则完全不同——整数除法截断，浮点数除法是精确的；整数不会溢出（但会回绕），浮点数有精度问题。让这些差异显式化，能避免很多隐蔽的 bug。

在实际代码中，你经常需要在 int 和 float 之间转换，用 `float_of_int` 和 `int_of_float`：

```ocaml
let average a b = float_of_int (a + b) /. 2.0
let round x = int_of_float (x +. 0.5)
```

### 4.4 类型别名

用 `type` 关键字可以给已有类型起一个新名字：

```ocaml
type name = string
type age = int
type point = float * float   (* 元组类型别名 *)
```

类型别名是**透明的**——`name` 和 `string` 是完全相同的类型，只是写法不同。编译器不会区分它们：

```ocaml
let (n : name) = "Alice"
let (s : string) = n         (* 没问题，name 就是 string *)
```

类型别名的作用是提高代码的可读性。当你看到一个函数接受 `name` 类型的参数时，你立刻知道这个参数的含义，而不只是它的底层类型。

如果想要真正的封装（让 `name` 和 `string` 成为不同的类型），需要用抽象数据类型（第 16 章）或私有类型。

### 4.5 多态类型

当一个函数不依赖具体类型时，它的类型是多态的（polymorphic）。多态类型用 `'a`、`'b`、`'c` 这样的类型变量表示（读作「alpha」「beta」，或者直接叫「tick a」）。

```ocaml
let id x = x                          (* 'a -> 'a *)
let const k _ = k                     (* 'a -> 'b -> 'a *)
let first (x, _) = x                  (* 'a * 'b -> 'a *)
let second (_, y) = y                 (* 'a * 'b -> 'b *)
```

`id` 函数的类型是 `'a -> 'a`，意思是「对于任意类型 'a，接受一个 'a 类型的参数，返回同类型的值」。你可以给它传 `int`，也可以传 `string`，还可以传 `int list`，都没问题。

多态不是「动态类型」。`id` 函数本身的类型是确定的（它是一个多态类型），但它可以被实例化成任何具体类型。每次调用时，类型变量都会被实例化成具体的类型。

```ocaml
let _ = id 42          (* 'a 实例化为 int *)
let _ = id "hello"     (* 'a 实例化为 string *)
```

### 4.6 类型推断是怎么工作的

类型推断的核心思想是**约束生成 + 约束求解**。编译器遍历代码时，会收集所有的类型约束（「这里 a 和 b 必须是同类型」「这里 f 必须是函数类型」等等），然后用合一（unification）算法解这些约束。

举个例子，考虑下面的函数：

```ocaml
let compose f g x = f (g x)
```

编译器的推断过程大致如下：

1. `f`、`g`、`x` 都是未知类型，先给它们分配类型变量：`f : 'a`，`g : 'b`，`x : 'c`
2. `g x` 是函数调用，所以 `g` 必须是函数类型，参数类型是 `x` 的类型。于是 `'b = 'c -> 'd`（`'d` 是返回类型的新变量）
3. `f (g x)` 也是函数调用，所以 `f` 必须是函数类型，参数类型是 `g x` 的类型。于是 `'a = 'd -> 'e`
4. 整个函数的返回类型是 `'e`

所以 `compose` 的类型是：
```
('d -> 'e) -> ('c -> 'd) -> 'c -> 'e
```

也就是我们熟悉的 `('a -> 'b) -> ('c -> 'a) -> 'c -> 'b`（变量名不重要，重要的是结构）。

这个过程完全是自动的，你不需要写任何类型标注。但如果代码有类型错误，编译器会告诉你哪里的约束冲突了。

### 4.7 值限制（value restriction）详解

值限制是 OCaml 类型系统中最让人困惑的概念之一。但它其实是一个非常简单的规则，用来保证类型安全。

**规则**：只有语法上是「值」的表达式才能被泛化（即获得多态类型）。

什么是「语法值」？简单来说：
- 常量（`42`、`"hello"`、`true`）是值
-  lambda 表达式（`fun x -> e`）是值
- 数据构造子应用于值（`Some 3`、`x :: rest`）是值
- `let` 绑定（如果右边是值）是值
- **函数调用不是值**，即使它的结果是一个多态值

最经典的例子：

```ocaml
let rev_empty = List.rev []          (* 可以泛化：'a list *)
let bad_poly = (fun x -> x) []       (* 不能泛化：弱类型变量 *)
```

第一行中，`List.rev []` 的结果是 `[]`，但因为 `List.rev []` 是函数调用（不是语法值），所以……等等，不对，`List.rev []` 确实能被泛化。让我换一个更准确的例子：

```ocaml
let id = fun x -> x                  (* 'a -> 'a，值，可以泛化 *)
let id' = id                         (* 'a -> 'a，也是值，可以泛化 *)

let f = ref (fun x -> x)             (* 弱类型变量，不能泛化 *)
```

`ref (fun x -> x)` 是一个函数调用（`ref` 是函数），所以它的结果不能被泛化。为什么这个限制是必须的？

考虑下面的代码（如果没有值限制会怎样）：

```ocaml
(* 假设这段代码能通过类型检查 *)
let r = ref None                     (* 'a option ref，多态的引用 *)
r := Some 42                         (* 把它当 int option ref 用 *)
let s = !r ^ "hello"                 (* 把它当 string option ref 用 *)
```

如果 `r` 是多态的 `'a option ref`，那我们就可以先往里面存 `int`，再读出来当 `string` 用——这就破坏了类型安全。

值限制通过禁止 `ref None` 被泛化来防止这个问题。`ref None` 是函数调用，不是语法值，所以它的类型不能被泛化，只能是某个具体的（但还不知道的）类型。编译器会用「弱类型变量」来表示，通常写成 `'_weak1`、`'_a` 等。

弱类型变量不是多态的——它表示「我现在还不知道具体是什么类型，但一旦确定了就不能改了」。

```ocaml
let r = ref None                     (* '_weak1 option ref *)
r := Some 42                         (* 现在 '_weak1 确定为 int *)
let _ = !r                           (* int option *)
```

在实践中，值限制很少咬人。最常见的触发场景是部分应用（partial application）返回的是一个多态函数。解决方案通常是 eta-expand（显式写出参数）：

```ocaml
(* 可能触发值限制 *)
let map_id = List.map (fun x -> x)   (* 可能是 '_a list -> '_a list *)

(* eta-expand 后就没问题了 *)
let map_id lst = List.map (fun x -> x) lst   (* 'a list -> 'a list *)
```

为什么 eta-expand 有用？因为 `let map_id lst = ...` 的右边是一个 lambda（显式的 `fun lst -> ...` 是语法糖），而 lambda 是语法值，可以被泛化。

### 4.8 本章小结

- OCaml 是强静态类型语言，基于 HM 类型系统做全局类型推断
- 基础类型：`int`（63位）、`float`、`bool`、`char`、`string`、`unit`
- int 和 float 用不同的运算符：`+` vs `+.`，`*` vs `*.` 等
- 类型别名是透明的，只是提高可读性
- 多态类型用 `'a`、`'b` 等类型变量表示
- 类型推断通过约束生成和合一算法完成
- 值限制：只有语法值才能被完全泛化，这是为了保证可变状态下的类型安全

---

## 第 5 章 表达式与运算符

对应示例：`examples/03_expressions.ml`

### 5.1 一切都是表达式

在 OCaml 中，几乎一切都是**表达式**（expression），而不是语句（statement）。表达式有值、有类型。

- `if e1 then e2 else e3` 是表达式，它的值是 `e2` 或 `e3` 的值
- `match e with ...` 是表达式，它的值是被选中分支的值
- `let x = e1 in e2` 是表达式，它的值是 `e2` 的值
- `e1; e2` 是表达式，它的值是 `e2` 的值

只有 `;` 序列稍微特殊一点——它的主要目的是按顺序执行副作用表达式。但即使是 `e1; e2`，它也是一个表达式，有值（`e2` 的值）和类型（`e2` 的类型）。

### 5.2 整数算术运算符

| 运算符 | 含义 | 示例 |
|---|---|---|
| `+` | 加法 | `3 + 4 = 7` |
| `-` | 减法 | `10 - 3 = 7` |
| `*` | 乘法 | `3 * 4 = 12` |
| `/` | 整数除法（截断向零） | `10 / 3 = 3` |
| `mod` | 取模 | `10 mod 3 = 1` |
| `~-` | 一元负号 | `~-5 = -5` |

```ocaml
let a = 10
let b = 3
let sum = a + b          (* 13 *)
let diff = a - b         (* 7 *)
let prod = a * b         (* 30 *)
let quot = a / b         (* 3 （截断向零）*)
let remainder = a mod b  (* 1 *)
let neg = ~-a            (* -10 *)
```

注意整数除法的行为：**截断向零**，而不是截断向下（floor）。这意味着负数除法的结果可能和你预期的不一样：

```ocaml
let _ = 10 / 3           (* 3 *)
let _ = -10 / 3          (* -3，不是 -4 *)
let _ = 10 / -3          (* -3，不是 -4 *)
let _ = -10 / -3         (* 3 *)
```

如果你需要 floor 除法（类似 Python 的 `//`），需要自己实现。

### 5.3 浮点数算术运算符

| 运算符 | 含义 | 示例 |
|---|---|---|
| `+.` | 加法 | `3.0 +. 4.0 = 7.0` |
| `-.` | 减法 | `10.0 -. 3.0 = 7.0` |
| `*.` | 乘法 | `3.0 *. 4.0 = 12.0` |
| `/.` | 除法 | `10.0 /. 3.0 ≈ 3.333` |
| `**` | 幂运算 | `2.0 ** 10.0 = 1024.0` |
| `~-.` | 一元负号 | `~-.5.0 = -5.0` |

```ocaml
let x = 10.0
let y = 3.0
let sum = x +. y          (* 13.0 *)
let diff = x -. y         (* 7.0 *)
let prod = x *. y         (* 30.0 *)
let quot = x /. y         (* 3.333... *)
let power = x ** y        (* 1000.0 *)
let neg = ~-.x            (* -10.0 *)
```

浮点数的一些特殊值：
- `infinity`：正无穷
- `neg_infinity`：负无穷
- `nan`：Not a Number（0.0 /. 0.0 的结果等）

`nan` 有一个反直觉的性质：**`nan = nan` 是 `false`**。这是 IEEE 754 标准规定的。要判断一个值是不是 nan，用 `Float.is_nan` 或 `classify_float`。

### 5.4 比较运算符

| 运算符 | 含义 |
|---|---|
| `=` | 结构相等 |
| `<>` | 结构不等 |
| `<` | 小于 |
| `>` | 大于 |
| `<=` | 小于等于 |
| `>=` | 大于等于 |
| `==` | 物理相等（指针相等） |
| `!=` | 物理不等 |

```ocaml
let _ = 3 = 3             (* true *)
let _ = 3 <> 4            (* true *)
let _ = 3 < 5             (* true *)
let _ = "abc" = "abc"     (* true *)
let _ = [1;2] = [1;2]     (* true *)
```

**结构相等**（`=`）会递归比较两个值的内容。对于不可变数据，你几乎总是应该用 `=`。

**物理相等**（`==`）比较的是两个值在内存中是否是同一个地址。对于整数、浮点数等基本类型，`=` 和 `==` 没有区别。但对于列表、记录、变体等复合类型，`==` 可能返回 `false` 即使内容完全相同（因为它们是不同的内存分配）。

```ocaml
let _ = [1;2] == [1;2]    (* false —— 两个不同的列表 *)
let lst = [1;2]
let _ = lst == lst        (* true —— 同一个列表 *)
```

**什么时候用 `==`？** 几乎不用。只有在你明确知道自己在做什么（比如做性能优化，想避免深比较）的时候才用。大多数情况下 `=` 才是你想要的。

### 5.5 逻辑运算符

| 运算符 | 含义 | 特点 |
|---|---|---|
| `&&` | 逻辑与 | 短路 |
| `\|\|` | 逻辑或 | 短路 |
| `not` | 逻辑非 | 函数，不是运算符 |

```ocaml
let _ = true && true       (* true *)
let _ = true && false      (* false *)
let _ = false || true      (* true *)
let _ = not true           (* false *)
```

`&&` 和 `||` 是**短路**运算符——如果左操作数已经能决定结果，右操作数就不会被求值。

```ocaml
(* 安全的：b 为 0 时，右边不会被求值 *)
let safe_div a b = b <> 0 && a / b > 0
```

如果 `&&` 不是短路的，上面的代码在 `b = 0` 时会抛出 `Division_by_zero` 异常。但因为短路，当 `b <> 0` 为 `false` 时，`a / b > 0` 根本不会被求值。

注意 `not` 是一个普通函数，不是运算符。它的类型是 `bool -> bool`。

### 5.6 if 是表达式

在 OCaml 中，`if` 是表达式，不是语句。它返回一个值。

```ocaml
let abs_int n = if n >= 0 then n else -n
```

`if e1 then e2 else e3` 中，`e2` 和 `e3` 必须有相同的类型。这是因为 `if` 表达式的类型必须是确定的——不管走哪个分支，返回值的类型必须一致。

```ocaml
(* 错误：两个分支类型不同 *)
(* let bad = if true then 42 else "hello" *)
```

如果省略 `else` 分支，默认的 `else` 是 `()`（unit 类型）。这意味着 `then` 分支也必须返回 `unit`，否则类型不匹配。

```ocaml
(* 合法：then 分支返回 unit，else 默认为 () *)
let print_if_positive n =
  if n > 0 then print_endline "positive"
```

这也是为什么你会看到这样的代码：

```ocaml
let () =
  if condition then begin
    do_something ();
    do_something_else ()
  end
```

`begin ... end` 和括号 `( ... )` 是等价的，只是用来把多个表达式包在一起。当 `if` 的分支里有多个 `;` 连接的表达式时，用 `begin end` 比括号更易读。

### 5.7 运算符优先级

OCaml 的运算符优先级从高到低大致如下：

| 优先级 | 运算符 | 说明 |
|---|---|---|
| 最高 | 函数应用 | `f x y` |
| | `!.` `!` | 引用解引用 |
| | `*.` `/.` `%` `mod` `land` `lor` `lxor` | 乘除、位运算 |
| | `+.` `-.` | 浮点加减 |
| | `+` `-` | 整数加减 |
| | `::` `@@` | cons、应用运算符 |
| | `@` `^` | 列表拼接、字符串拼接 |
| | `=` `<>` `==` `!=` `<` `>` `<=` `>=` | 比较运算 |
| | `&&` | 逻辑与 |
| | `\|\|` | 逻辑或 |
| | `,` | 元组构造 |
| | `<-` `:=` | 赋值 |
| | `if then else` | 条件表达式 |
| 最低 | `;` | 顺序执行 |

如果你不确定优先级，**加括号就对了**。加括号不会有任何性能损失，还能让代码更清晰。

有几个特别容易搞错的地方：

1. **函数应用优先级最高**：`f x + y` 是 `(f x) + y`，不是 `f (x + y)`。
2. **`::` 是右结合的**：`1 :: 2 :: 3 :: []` 是 `1 :: (2 :: (3 :: []))`。
3. **比较运算符优先级低于算术运算符**：`3 + 4 < 10` 是 `(3 + 4) < 10`，这符合直觉。
4. **`&&` 优先级高于 `||`**：`a || b && c` 是 `a || (b && c)`。

### 5.8 begin end

`begin ... end` 在 OCaml 中就是括号的另一种写法。它和 `( ... )` 完全等价。

```ocaml
(* 这两个完全一样 *)
let _ = begin 1 + 2 end * 3
let _ = (1 + 2) * 3
```

`begin end` 通常用在控制结构的分支中，比如 `if`、`when` 等，因为它比括号更易读：

```ocaml
let () =
  if x > 0 then begin
    print_endline "positive";
    print_int x;
    print_newline ()
  end else begin
    print_endline "non-positive"
  end
```

如果不用 `begin end` 也不用括号，`;` 的低优先级会导致解析出问题——`else` 会被错误地绑定到内层的某个东西上。所以只要分支里有多个 `;` 连接的表达式，就用 `begin end` 包起来。

### 5.9 本章小结

- OCaml 中几乎一切都是表达式
- int 和 float 用不同的运算符，不要搞混
- `=` 是结构相等，`==` 是物理相等，大多数时候用 `=`
- `&&` 和 `||` 是短路运算符
- `if` 是表达式，两个分支类型必须相同
- 不确定优先级就加括号，不会错
- `begin end` 就是括号，用于提高可读性

---

## 第 6 章 元组与记录

对应示例：`examples/04_tuples.ml`

### 6.1 元组：把多个值打包在一起

元组（tuple）是把多个值按顺序组合成一个值的方式。元组中的每个元素可以有不同的类型，长度是固定的。

```ocaml
let pair = (42, "answer")          (* int * string *)
let triple = (1, "two", 3.0)       (* int * string * float *)
let point = (3.0, 4.0)             (* float * float *)
```

元组的类型用 `*` 分隔各个元素的类型。`int * string` 的意思是「一个元组，第一个元素是 int，第二个是 string」。

元组用逗号构造。注意一个常见的坑：**逗号不是运算符，它是元组构造语法的一部分**。所以 `1, 2` 就是一个元组，括号不是必须的。但在大多数情况下，加括号会让代码更清晰。

```ocaml
let p = 1, 2            (* 也是元组，等价于 (1, 2) *)
let _ = fst p           (* 1 *)
```

### 6.2 元组的解构

元组最常用的操作是解构（destructuring）——用模式匹配把元组拆开，把各个元素绑到不同的名字上。

```ocaml
let (x, y) = (3.0, 4.0)
(* x = 3.0, y = 4.0 *)
```

这不是特殊语法——`let` 后面跟的是一个模式。元组模式 `(x, y)` 匹配元组值 `(3.0, 4.0)`，然后把 `x` 绑到 `3.0`，`y` 绑到 `4.0`。

解构也可以用在函数参数中：

```ocaml
let distance (x1, y1) (x2, y2) =
  sqrt ((x2 -. x1) ** 2.0 +. (y2 -. y1) ** 2.0)

let d = distance (0.0, 0.0) (3.0, 4.0)   (* 5.0 *)
```

这个函数的类型是 `float * float -> float * float -> float`。它接受两个元组参数，每个元组包含两个 float。

如果你只需要元组的一部分元素，可以用 `_` 通配符忽略不需要的部分：

```ocaml
let (first, _) = (100, "ignored")
(* first = 100 *)
```

对于二元组（pair），标准库还提供了 `fst` 和 `snd` 函数：

```ocaml
let _ = fst (1, "two")     (* 1 *)
let _ = snd (1, "two")     (* "two" *)
```

但 `fst` 和 `snd` 只能用于二元组。三元组及以上没有类似的内置函数，必须用模式匹配提取。

### 6.3 元组的常见用法

元组在 OCaml 中非常常用，典型场景包括：

**1. 函数返回多个值**

不像 C/Java 需要用输出参数或结构体，OCaml 中直接返回元组就行：

```ocaml
let div_rem a b = (a / b, a mod b)

let (q, r) = div_rem 10 3
(* q = 3, r = 1 *)
```

**2. 传递相关联的数据对**

比如键值对、坐标对、名字值对等：

```ocaml
let key_values = [("name", "Alice"); ("age", "30"); ("city", "Beijing")]
```

**3. 模式匹配中的组合**

当你需要同时匹配多个值时，可以把它们打包成元组一起匹配：

```ocaml
let compare_points (x1, y1) (x2, y2) =
  match (x1 = x2, y1 = y2) with
  | (true, true) -> "same point"
  | (true, false) -> "same x"
  | (false, true) -> "same y"
  | (false, false) -> "different"
```

### 6.4 记录：有名字的字段

元组很方便，但它的问题是：你得记住每个位置的含义。当元组的元素很多时，代码的可读性会急剧下降。

记录（record）解决了这个问题。记录是有名字的字段的集合：

```ocaml
type point2d = {
  x : float;
  y : float;
}

type person = {
  name : string;
  age : int;
  email : string;
}
```

创建记录：

```ocaml
let p = { x = 3.0; y = 4.0 }
let alice = { name = "Alice"; age = 30; email = "alice@example.com" }
```

访问字段用 `.` 语法：

```ocaml
let _ = p.x           (* 3.0 *)
let _ = alice.name    (* "Alice" *)
```

记录也可以模式匹配解构：

```ocaml
let { x = px; y = py } = p
(* px = 3.0, py = 4.0 *)
```

还有一个常用的简写：如果变量名和字段名相同，可以只写字段名：

```ocaml
let { x; y } = p
(* x = 3.0, y = 4.0 *)
```

这个简写在创建记录时也能用：

```ocaml
let x = 3.0
let y = 4.0
let p = { x; y }    (* 等价于 { x = x; y = y } *)
```

这叫做「字段名字面量简写」（field punning）。

### 6.5 记录的 with 语法

记录默认是不可变的。如果你想基于已有记录创建一个新记录，只修改部分字段，可以用 `with` 语法：

```ocaml
let p1 = { x = 1.0; y = 2.0 }
let p2 = { p1 with x = 10.0 }
(* p2 = { x = 10.0; y = 2.0 } *)
(* p1 保持不变 *)
```

`with` 语法不会修改原记录——它创建一个新记录。原记录的所有未在 `with` 中列出的字段都会被复制过来。

也可以同时修改多个字段：

```ocaml
let p3 = { p1 with x = 10.0; y = 20.0 }
```

对于嵌套记录，`with` 可以嵌套使用：

```ocaml
type rectangle = {
  top_left : point2d;
  bottom_right : point2d;
}

let move_rect dx dy rect =
  { rect with
    top_left = { rect.top_left with
      x = rect.top_left.x +. dx;
      y = rect.top_left.y +. dy
    }
  }
```

这看起来有点啰嗦，但它明确地表达了「函数式更新」的语义——原数据不被修改，总是创建新的。

### 6.6 可变字段（mutable）

记录的字段默认是不可变的。如果你需要可变的字段，用 `mutable` 关键字声明：

```ocaml
type counter = {
  mutable count : int;
  label : string;           (* 不可变字段 *)
}
```

修改可变字段用 `<-` 运算符：

```ocaml
let c = { count = 0; label = "clicks" }
let () =
  c.count <- c.count + 1;   (* count 变成 1 *)
  c.count <- c.count + 5    (* count 变成 6 *)
```

注意 `<-` 是赋值运算符，不是 `=`。`c.count <- c.count + 1` 的意思是「把 c.count 的值改成 c.count + 1」。

不可变字段不能被修改：
```ocaml
(* 错误：The field label is not mutable *)
(* c.label <- "new label" *)
```

什么时候用可变记录？当你需要封装一个有状态的对象时，可变记录非常方便。比如计数器、缓存、游戏中的玩家状态等。

一个完整的计数器例子：

```ocaml
type counter = {
  mutable count : int;
  mutable step : int;
}

let make_counter ?(step = 1) start =
  { count = start; step }

let next c =
  let current = c.count in
  c.count <- c.count + c.step;
  current

let reset c =
  c.count <- 0

let set_step c s =
  c.step <- s
```

注意 `make_counter` 用了可选参数（`?step`），这在第 13 章会详细讲。

### 6.7 记录的多态（参数化记录）

记录类型可以有类型参数，就像参数化变体一样：

```ocaml
type 'a labeled = {
  label : string;
  value : 'a;
}

let int_labeled = { label = "count"; value = 42 }
let str_labeled = { label = "name"; value = "Alice" }
let float_labeled = { label = "pi"; value = 3.14159 }
```

`'a labeled` 是一个参数化的记录类型，`value` 字段可以是任意类型。

### 6.8 嵌套解构

元组和记录可以任意嵌套，解构也可以嵌套进行：

```ocaml
type rectangle = {
  top_left : point2d;
  bottom_right : point2d;
}

let r = {
  top_left = { x = 0.0; y = 10.0 };
  bottom_right = { x = 20.0; y = 0.0 };
}

(* 嵌套记录解构 *)
let { top_left = { x = x1; y = y1 }; bottom_right = { x = x2; y = y2 } } = r
let width = x2 -. x1    (* 20.0 *)
let height = y1 -. y2   (* 10.0 *)
```

元组中也可以嵌套记录，记录中也可以嵌套元组：

```ocaml
let labeled = ("my rect", r)
let (name, { top_left = tl; _ }) = labeled
(* name = "my rect" *)
(* tl = { x = 0.0; y = 10.0 } *)
```

解构的嵌套深度没有限制。但如果嵌套太深，代码可读性会下降，这时候考虑写辅助函数来提取字段。

### 6.9 记录与元组的选择

什么时候用元组，什么时候用记录？简单的判断标准：

- **元素个数 ≤ 2，且含义明显**：用元组。比如 `(key, value)` 对、坐标对、返回两个值的函数。
- **元素个数 ≥ 3，或含义不明显**：用记录。给字段起名字能大大提高可读性。
- **可能会扩展字段**：用记录。给记录加字段比给元组加元素容易得多（不需要修改所有使用的地方）。

一个经验法则：**如果同一个类型的元组在代码中出现超过两次，就应该考虑把它改成记录。**

### 6.10 本章小结

- 元组用逗号构造，把多个不同类型的值打包在一起
- 元组解构用 `let (x, y) = tuple` 或函数参数模式
- `fst` 和 `snd` 只能用于二元组
- 记录有命名字段，用 `type name = { field : type; ... }` 定义
- 记录字段用 `.` 访问，也可以模式匹配解构
- `with` 语法基于已有记录创建新记录（函数式更新）
- `mutable` 字段用 `<-` 赋值
- 记录可以是参数化（多态）的
- 解构可以任意嵌套
- 简单场景用元组，复杂场景用记录

---

## 第 7 章 模式匹配

对应示例：`examples/05_patterns.ml`

### 7.1 模式匹配是 OCaml 的灵魂

如果说有一个特性定义了 OCaml 的编程风格，那一定是**模式匹配**（pattern matching）。模式匹配让你可以「根据数据的形状来选择代码路径」，而且编译器会帮你检查有没有漏掉情况。

你可能在其他语言里见过类似的东西（比如 switch/case），但 OCaml 的模式匹配要强大得多：

- 可以匹配任何数据类型：整数、浮点数、字符串、元组、记录、变体、列表……
- 可以嵌套匹配：模式里面可以再套模式
- 可以解构数据：匹配的同时把数据拆开，把各部分绑到变量上
- 编译器检查穷尽性：确保你覆盖了所有可能的情况
- 编译器检查冗余：提醒你哪些分支永远不会被执行

模式匹配的基本形式是 `match` 表达式：

```ocaml
match expr with
| pattern1 -> expr1
| pattern2 -> expr2
| ...
```

`match` 是一个表达式，它的值是第一个匹配的分支中 `->` 右边表达式的值。

### 7.2 通配模式与字面量模式

最简单的模式是**通配模式** `_`，它匹配任何值，但不绑定任何变量：

```ocaml
let describe n =
  match n with
  | 0 -> "zero"
  | 1 -> "one"
  | 2 -> "two"
  | _ -> "something else"
```

这里的 `0`、`1`、`2` 是**字面量模式**——它们匹配等于该字面量的值。`_` 是兜底分支，匹配所有剩下的情况。

字面量模式可以是整数、浮点数、字符、字符串等：

```ocaml
let greeting lang =
  match lang with
  | "en" -> "Hello"
  | "fr" -> "Bonjour"
  | "es" -> "Hola"
  | "zh" -> "Ni hao"
  | _ -> "Hi"
```

### 7.3 变体构造子模式

对于变体类型（第 9 章会详细讲），模式匹配可以解构构造子的参数：

```ocaml
type shape =
  | Circle of float
  | Rectangle of float * float
  | Square of float

let area s =
  match s with
  | Circle r -> 3.14159 *. r *. r
  | Rectangle (w, h) -> w *. h
  | Square side -> side *. side
```

`Circle r` 这个模式匹配所有 `Circle` 构造的值，同时把半径绑到变量 `r` 上。`Rectangle (w, h)` 匹配 `Rectangle` 构造的值，把宽和高分别绑到 `w` 和 `h` 上。

标准库的 `option` 类型就是一个常用的变体：

```ocaml
let opt_value default opt =
  match opt with
  | Some x -> x
  | None -> default
```

`Some x` 匹配 `Some` 构造的值，把里面的值绑到 `x` 上。`None` 匹配 `None`。

### 7.4 列表模式

列表也可以用模式匹配：

```ocaml
let rec sum lst =
  match lst with
  | [] -> 0
  | x :: rest -> x + sum rest
```

- `[]` 匹配空列表
- `x :: rest` 匹配非空列表，`x` 绑到第一个元素（头），`rest` 绑到剩下的列表（尾）

`::` 在模式中是构造子，就像它在表达式中一样。注意 `::` 是右结合的，所以 `x :: y :: rest` 匹配至少有两个元素的列表。

也可以用固定长度的列表模式：

```ocaml
let describe_list lst =
  match lst with
  | [] -> "empty"
  | [_] -> "one element"
  | [_; _] -> "two elements"
  | _ :: _ :: _ -> "three or more"
```

`[x; y; z]` 是 `x :: y :: z :: []` 的语法糖，在表达式和模式中都是如此。

### 7.5 元组与记录模式

我们在第 6 章已经见过元组和记录的模式匹配了，这里再强调一下：它们在 `match` 中同样适用，而且可以和其他模式组合使用。

```ocaml
let describe_pair (x, y) =
  match (x, y) with
  | (0, 0) -> "origin"
  | (0, _) -> "on y-axis"
  | (_, 0) -> "on x-axis"
  | (a, b) when a = b -> "on diagonal"
  | _ -> "somewhere else"
```

记录模式：

```ocaml
type point2d = { x : float; y : float }

let is_on_x_axis p =
  match p with
  | { y = 0.0 } -> true
  | _ -> false
```

记录模式中不需要列出所有字段——你只需要写你关心的那些。

### 7.6 as 模式

`as` 模式可以给匹配的子模式起一个名字：

```ocaml
let describe_list lst =
  match lst with
  | ([] | [_]) as short ->
      "short list, length = " ^ string_of_int (List.length short)
  | _ :: _ :: _ as long ->
      "long list, length = " ^ string_of_int (List.length long)
```

`([] | [_]) as short` 的意思是：如果匹配 `[]` 或 `[_]`，就把整个匹配的值绑到 `short` 上。

`as` 在嵌套模式中尤其有用，你既能解构内部结构，又能保留对整体的引用：

```ocaml
let first_point_x lst =
  match lst with
  | ((x, _) :: _) as points ->
      Printf.printf "First x of %d points: %f\n" (List.length points) x;
      x
  | [] -> 0.0
```

### 7.7 when 守卫

有时候光靠模式本身不足以表达分支条件。这时可以用 `when` 守卫（guard）：

```ocaml
let classify n =
  match n with
  | 0 -> "zero"
  | n when n > 0 -> "positive"
  | n when n < 0 -> "negative"
  | _ -> "unreachable"
```

`when` 后面跟一个布尔表达式。只有当模式匹配**且** `when` 条件为 `true` 时，该分支才会被选中。

`when` 守卫的作用是补充模式匹配表达不了的条件。但注意：**编译器不会检查 when 条件的穷尽性**。因为 `when` 条件可以是任意布尔表达式，编译器无法静态分析它覆盖了哪些情况。

所以上面的例子中，虽然逻辑上前三个分支已经覆盖了所有整数，但最后那个 `_` 分支还是需要的——不是因为穷尽性检查，而是因为 `when` 守卫不算入穷尽性检查。不过实际上，`n when n > 0` 中的 `n` 已经匹配了所有整数，所以从模式的角度看，第二个分支就已经是穷尽的了……这有点微妙。实际经验是：如果你用了 `when`，最好加一个兜底分支。

### 7.8 穷尽性检查

OCaml 编译器会检查模式匹配是否穷尽（exhaustive）——也就是是否覆盖了所有可能的输入。如果有遗漏，编译器会发出警告。

```ocaml
type color = Red | Green | Blue

(* 警告：非穷尽匹配，漏掉了 Blue *)
let string_of_color c =
  match c with
  | Red -> "Red"
  | Green -> "Green"
```

穷尽性检查是 OCaml 最有价值的特性之一。想象一下：你给一个变体类型加了一个新的构造子，然后编译器会告诉你所有需要更新的模式匹配——你永远不会忘记处理某个情况。

穷尽性检查是精确的，不是粗略的。它不会因为你有一个 `_` 兜底就不检查了——它会检查你显式列出的模式是否覆盖了所有情况。

还有一个相关的检查：**冗余模式检查**。如果某个分支永远不会被执行（因为前面的分支已经覆盖了所有情况），编译器也会警告你：

```ocaml
let f x =
  match x with
  | 0 -> "zero"
  | _ -> "other"
  | 1 -> "one"    (* 警告：这个匹配情况没用 *)
```

### 7.9 let 模式解构

`let` 本身就是模式匹配的一种形式。任何「一定能匹配」的模式都可以用在 `let` 中：

```ocaml
(* 元组模式 *)
let (a, b) = (10, 20)

(* 记录模式 *)
let { x; y } = { x = 3.5; y = 4.5 }

(* 变体模式（只有一个构造子时安全） *)
let Some v = Some 42
```

最后那个例子要小心：如果右边是 `None`，程序会在运行时崩溃（抛出 `Match_failure` 异常）。所以 `let` 模式只应该用在「肯定能匹配」的情况下。对于可能失败的匹配，用 `match`。

函数参数也可以用模式：

```ocaml
let add_pair (x, y) = x + y
let get_x { x } = x
let head (x :: _) = x      (* 不推荐：空列表会失败 *)
```

### 7.10 function 关键字

`function` 是一个语法糖，用来写只有一个参数且直接做模式匹配的函数：

```ocaml
(* 用 match 写 *)
let string_of_color c =
  match c with
  | Red -> "Red"
  | Green -> "Green"
  | Blue -> "Blue"

(* 用 function 写，等价 *)
let string_of_color = function
  | Red -> "Red"
  | Green -> "Green"
  | Blue -> "Blue"
```

`function` 隐式地引入了一个参数，然后立刻对它做模式匹配。当函数的主体就是一个 match 时，`function` 更简洁。

### 7.11 嵌套模式

模式可以任意嵌套。比如列表中嵌套元组，元组中嵌套变体，变体中嵌套记录……：

```ocaml
type 'a tree =
  | Leaf
  | Node of 'a * 'a tree * 'a tree

let rec leftmost tree =
  match tree with
  | Leaf -> None
  | Node (v, Leaf, _) -> Some v
  | Node (_, left, _) -> leftmost left
```

`Node (v, Leaf, _)` 是一个嵌套模式——外层是 `Node` 构造子模式，里面嵌套了 `Leaf` 模式（匹配左子树为空的情况）。

嵌套模式让你可以用一个模式表达复杂的结构条件，不需要多层嵌套的 match。

### 7.12 本章小结

- `match` 是模式匹配的基本形式，也是表达式
- 通配模式 `_` 匹配任何值但不绑定变量
- 字面量模式匹配具体的值
- 变体构造子模式可以解构带参数的变体
- 列表模式：`[]`、`x :: rest`、`[x; y; z]`
- `as` 模式给匹配的值起名字
- `when` 守卫给分支增加额外的条件
- 编译器做穷尽性检查和冗余检查
- `let` 和函数参数也可以用模式（但必须是穷尽的）
- `function` 是「单参数 + 直接 match」的语法糖
- 模式可以任意嵌套

---

## 第 8 章 列表与高阶列表函数

对应示例：`examples/06_lists.ml`

### 8.1 列表是函数式编程的面包和黄油

列表是函数式语言中最基本的数据结构。在 OCaml 中，列表是**单链表**，所有元素类型相同（同质）。

列表有两种构造方式：

- `[]`：空列表
- `x :: rest`：在列表 `rest` 的前面加上元素 `x`（`::` 读作 cons）

`[1; 2; 3]` 是 `1 :: 2 :: 3 :: []` 的语法糖。

```ocaml
let empty = []
let single = 42 :: []
let nums = 1 :: 2 :: 3 :: []
let nums2 = [1; 2; 3; 4; 5]
```

列表的类型是 `'a list`，其中 `'a` 是元素的类型。比如 `int list` 是整数列表，`string list` 是字符串列表。

**重要**：`::` 是 O(1) 操作——它只是创建一个新的链表节点，指向原来的列表。而列表拼接 `@` 是 O(n)，其中 n 是第一个列表的长度。

### 8.2 列表拼接 @

`@` 运算符把两个列表拼在一起：

```ocaml
let a = [1; 2; 3]
let b = [4; 5; 6]
let c = a @ b    (* [1; 2; 3; 4; 5; 6] *)
```

为什么 `@` 是 O(n)？因为列表是单链表，要拼接两个列表，必须把第一个列表完整复制一遍，让它的最后一个节点指向第二个列表。第二个列表不需要复制（共享）。

所以如果你要往列表前面加元素，用 `::`（O(1)）；往后面加，用 `@`（O(n)）。这也是为什么函数式代码通常先反向构建列表（不断往前面加），最后再 `List.rev` 翻转过来——这样总的时间复杂度还是线性的。

### 8.3 List.map：转换每个元素

`List.map` 可能是最常用的高阶列表函数。它的类型是：

```ocaml
val map : ('a -> 'b) -> 'a list -> 'b list
```

意思是：给我一个 `'a -> 'b` 的函数和一个 `'a list`，我给你一个 `'b list`——把函数应用到每个元素上，收集结果。

```ocaml
let nums = [1; 2; 3; 4; 5]
let squares = List.map (fun x -> x * x) nums
(* [1; 4; 9; 16; 25] *)

let strs = List.map string_of_int nums
(* ["1"; "2"; "3"; "4"; "5"] *)
```

`List.map` 是函数式编程的核心抽象之一。它把「对列表中每个元素做某事」这个模式封装起来，你只需要关心「做什么」，不需要关心「怎么遍历」。

自己实现 `map` 也很简单：

```ocaml
let rec my_map f lst =
  match lst with
  | [] -> []
  | x :: rest -> f x :: my_map f rest
```

这个实现是直接的，但它不是尾递归的（见第 11 章）。标准库的 `List.map` 在旧版本中也不是尾递归的，较新版本做了优化。

### 8.4 List.filter：选择元素

`List.filter` 保留满足谓词的元素，丢掉不满足的：

```ocaml
val filter : ('a -> bool) -> 'a list -> 'a list
```

```ocaml
let evens = List.filter (fun x -> x mod 2 = 0) nums
(* [2; 4] *)

let bigs = List.filter (fun x -> x > 3) nums
(* [4; 5] *)
```

谓词函数（返回 bool 的函数）也叫「判断」（predicate）。

### 8.5 fold：从列表中累积一个值

`fold`（折叠）是最通用的列表操作——`map` 和 `filter` 都可以用 `fold` 来实现。

OCaml 标准库有两个 fold 函数：`List.fold_left` 和 `List.fold_right`。

**List.fold_left**：

```ocaml
val fold_left : ('a -> 'b -> 'a) -> 'a -> 'b list -> 'a
```

从左到右遍历列表，用一个累积器（accumulator）累积结果。第一个参数是「累积函数」（接受累积器和当前元素，返回新的累积器），第二个参数是初始值，第三个是列表。

```ocaml
let sum = List.fold_left (fun acc x -> acc + x) 0 [1; 2; 3; 4; 5]
(* 15 *)

let product = List.fold_left ( * ) 1 [1; 2; 3; 4; 5]
(* 120 *)

let length lst = List.fold_left (fun acc _ -> acc + 1) 0 lst
```

`fold_left` 是尾递归的（见第 11 章），所以即使列表很长也不会栈溢出。

**List.fold_right**：

```ocaml
val fold_right : ('a -> 'b -> 'b) -> 'a list -> 'b -> 'b
```

从右到左遍历列表。注意参数顺序和 `fold_left` 不一样——列表在初始值前面。

```ocaml
let sum = List.fold_right (fun x acc -> x + acc) [1; 2; 3; 4; 5] 0
```

`fold_right` 不是尾递归的，所以长列表可能会栈溢出。但 `fold_right` 有时比 `fold_left` 更直观，特别是当你需要保持元素顺序的时候。

一个直观的对比：

```ocaml
let left_result = List.fold_left (fun acc x -> "(" ^ acc ^ "+" ^ string_of_int x ^ ")") "0" [1;2;3]
(* "((0+1)+2)+3" *)

let right_result = List.fold_right (fun x acc -> "(" ^ string_of_int x ^ "+" ^ acc ^ ")") [1;2;3] "0"
(* "(1+(2+(3+0)))" *)
```

**用 fold 实现 map 和 filter**：

```ocaml
let map_via_fold f lst =
  List.fold_right (fun x acc -> f x :: acc) lst []

let filter_via_fold p lst =
  List.fold_right (fun x acc -> if p x then x :: acc else acc) lst []
```

因为 `fold_right` 的顺序和 `::` 的构造顺序一致，所以用 `fold_right` 实现 map 和 filter 不需要翻转。

### 8.6 其他常用 List 函数

**List.init**：生成一个列表，第 i 个元素是 `f i`。

```ocaml
val init : int -> (int -> 'a) -> 'a list

let squares = List.init 10 (fun i -> i * i)
(* [0; 1; 4; 9; 16; 25; 36; 49; 64; 81] *)
```

**List.length**：列表长度。O(n) 时间，因为列表是链表，必须遍历才能知道长度。

```ocaml
val length : 'a list -> int
```

**List.rev**：反转列表。O(n) 时间。

```ocaml
val rev : 'a list -> 'a list
```

**List.nth**：取第 n 个元素（从 0 开始）。O(n) 时间。越界抛出 `Failure`。

```ocaml
val nth : 'a list -> int -> 'a
```

**List.find**：找到第一个满足谓词的元素。找不到抛出 `Not_found`。

```ocaml
val find : ('a -> bool) -> 'a list -> 'a

let first_even = List.find (fun x -> x mod 2 = 0) [1; 2; 3; 4]
(* 2 *)
```

**List.exists**：是否存在满足谓词的元素。

```ocaml
val exists : ('a -> bool) -> 'a list -> bool

let has_big = List.exists (fun x -> x > 10) [1; 2; 3]
(* false *)
```

**List.for_all**：是否所有元素都满足谓词。

```ocaml
val for_all : ('a -> bool) -> 'a list -> bool

let all_pos = List.for_all (fun x -> x > 0) [1; 2; 3]
(* true *)
```

**List.partition**：把列表分成两部分——满足谓词的和不满足的。

```ocaml
val partition : ('a -> bool) -> 'a list -> 'a list * 'a list

let (evens, odds) = List.partition (fun x -> x mod 2 = 0) [1; 2; 3; 4; 5]
(* evens = [2; 4], odds = [1; 3; 5] *)
```

**List.iter**：对每个元素执行一个副作用函数，返回 `unit`。

```ocaml
val iter : ('a -> unit) -> 'a list -> unit

List.iter print_int [1; 2; 3]
```

**List.sort**：排序。第一个参数是比较函数。

```ocaml
val sort : ('a -> 'a -> int) -> 'a list -> 'a list

let sorted = List.sort compare [3; 1; 4; 1; 5; 9; 2; 6]
(* [1; 1; 2; 3; 4; 5; 6; 9] *)
```

`compare` 是标准库的多态比较函数，返回 -1、0 或 1。

### 8.7 列表的不可变性与共享

OCaml 的列表是不可变的。`::` 和 `@` 都不会修改原列表——它们创建新的列表。

但「不可变」不意味着「每次都完全复制」。`::` 操作中，新列表的尾部和原列表是**共享**的：

```ocaml
let a = [2; 3]
let b = 1 :: a
```

这里 `b` 的第二个元素及之后和 `a` 是同一块内存。因为列表是不可变的，所以共享是安全的——没人能修改 `a`，所以 `b` 也不会意外改变。

这是函数式数据结构的核心优势：**不可变数据可以安全共享，不需要拷贝，也不需要加锁。**

### 8.8 什么时候不该用列表

列表是函数式编程的主力数据结构，但它不是万能的。以下场景考虑用其他数据结构：

- **需要随机访问**：列表的 `List.nth` 是 O(n)，用 `Array`（O(1) 访问）
- **需要键值对查找**：用 `Hashtbl` 或 `Map`
- **需要在两端高效操作**：用 `Queue` 或自定义的双向链表
- **元素数量很大且需要随机访问**：用 `Array`

列表最适合的场景是：顺序遍历、从前端添加/删除、函数式转换（map/filter/fold）。

### 8.9 本章小结

- 列表是单链表，用 `[]` 和 `::` 构造
- `::` 是 O(1)，`@` 是 O(n)
- `List.map` 转换每个元素
- `List.filter` 选择满足条件的元素
- `List.fold_left` / `List.fold_right` 累积一个值，是最通用的列表操作
- `List.fold_left` 是尾递归的，`List.fold_right` 不是
- `List.find` / `List.exists` / `List.for_all` / `List.partition` 用于查询
- `List.iter` 用于副作用遍历
- `List.sort` 用于排序
- 列表是不可变的，可以安全共享
- 列表不适合随机访问，那是数组的活

---

## 第 9 章 变体类型（代数数据类型）

对应示例：`examples/07_variants.ml`

### 9.1 什么是变体类型

变体类型（variant type），也叫代数数据类型（algebraic data type）、和类型（sum type），是 OCaml 类型系统中最强大的特性之一。

简单来说，变体类型是「或」类型——一个值可以是几种可能的形式之一。比如一个「形状」可以是圆形、矩形或正方形；一个「表达式」可以是数字、加法或乘法。

变体类型用 `type` 和 `|` 定义：

```ocaml
type color = Red | Green | Blue
```

这里 `color` 是类型名，`Red`、`Green`、`Blue` 是**构造子**（constructor）。构造子的首字母必须大写。

最简单的变体（所有构造子都不带参数）类似于 C 语言的 enum，但功能强大得多。

### 9.2 带参数的变体

构造子可以携带参数，这样每个变体值可以包含不同的数据：

```ocaml
type shape =
  | Circle of float           (* 半径 *)
  | Rectangle of float * float  (* 宽 * 高 *)
  | Square of float           (* 边长 *)
```

`Circle of float` 的意思是：`Circle` 是一个构造子，它接受一个 `float` 参数，产生一个 `shape` 类型的值。

创建变体值：

```ocaml
let c = Circle 5.0
let r = Rectangle (3.0, 4.0)
let s = Square 6.0
```

用模式匹配处理：

```ocaml
let area s =
  match s with
  | Circle r -> 3.14159 *. r *. r
  | Rectangle (w, h) -> w *. h
  | Square side -> side *. side
```

这就是代数数据类型的精髓：**数据是「或」的（shape 是 circle 或 rectangle 或 square），处理数据的代码也对应地用模式匹配分情况处理。**

### 9.3 表达式树：递归变体

变体类型可以递归引用自身。这让你可以定义树形结构，比如表达式树：

```ocaml
type expr =
  | Num of int
  | Add of expr * expr
  | Mul of expr * expr
```

一个 `expr` 要么是一个数字（`Num`），要么是两个表达式相加（`Add`），要么是两个表达式相乘（`Mul`）。

表示 `(2 + 3) * 4`：

```ocaml
let e = Mul (Add (Num 2, Num 3), Num 4)
```

求值：

```ocaml
let rec eval e =
  match e with
  | Num n -> n
  | Add (e1, e2) -> eval e1 + eval e2
  | Mul (e1, e2) -> eval e1 * eval e2
```

递归变体 + 模式匹配，是处理树形结构最自然的方式。每一种节点对应一个构造子，处理代码就是一个 match，每个分支对应一种节点的处理逻辑。

### 9.4 参数化变体（泛型变体）

变体类型可以有类型参数，也就是泛型：

```ocaml
type 'a my_option =
  | MyNone
  | MySome of 'a
```

`'a my_option` 是一个参数化的变体类型。`'a` 是类型参数，可以实例化为任何类型。

标准库的 `option` 就是这样定义的：

```ocaml
type 'a option =
  | None
  | Some of 'a
```

`option` 用来表示「可能有值也可能没有值」的情况。它比空指针安全得多——类型系统会强迫你处理 `None` 的情况。

列表也是参数化变体。简化版的列表定义：

```ocaml
type 'a my_list =
  | MyNil
  | MyCons of 'a * 'a my_list
```

`MyCons (x, rest)` 表示一个元素 `x` 后面跟着另一个列表 `rest`。这和 `x :: rest` 是一样的结构，只是 `::` 是中缀构造子。

### 9.5 递归类型的经典例子：二叉搜索树

让我们用递归的参数化变体来实现一个二叉搜索树（BST）：

```ocaml
type 'a bst =
  | Leaf
  | Node of 'a * 'a bst * 'a bst   (* 值 * 左子树 * 右子树 *)
```

`Leaf` 表示空树，`Node (v, left, right)` 表示一个节点，包含值 `v`、左子树 `left` 和右子树 `right`。

插入元素：

```ocaml
let rec insert x tree =
  match tree with
  | Leaf -> Node (x, Leaf, Leaf)
  | Node (v, left, right) ->
      if x < v then Node (v, insert x left, right)
      else if x > v then Node (v, left, insert x right)
      else tree   (* 重复值不插入 *)
```

注意：这是函数式的插入——它不修改原树，而是返回一棵新树。原树保持不变。

查找元素：

```ocaml
let rec mem x tree =
  match tree with
  | Leaf -> false
  | Node (v, left, right) ->
      if x = v then true
      else if x < v then mem x left
      else mem x right
```

中序遍历（得到有序列表）：

```ocaml
let rec inorder tree =
  match tree with
  | Leaf -> []
  | Node (v, left, right) -> inorder left @ [v] @ inorder right
```

这就是函数式编程的典型风格：用递归数据结构 + 模式匹配 + 递归函数，代码简洁且结构清晰。

### 9.6 构造子也是函数

带参数的构造子本身就是函数。你可以把它当函数用——传给高阶函数、部分应用等等。

```ocaml
(* Some 是 'a -> 'a option 函数 *)
let opts = List.map (fun x -> Some x) [1; 2; 3]
(* [Some 1; Some 2; Some 3] *)
```

注意：在 OCaml 中，构造子不能直接作为函数值传递（和 SML 不同）。你需要用 `fun x -> Some x` 这样的 lambda 来包装。

不过，对于只有一个参数的构造子，你也可以这样写：

```ocaml
let wrapped_list = List.map (fun x -> Wrapped x) [1; 2; 3]
```

### 9.7 多态变体（polymorphic variants）

OCaml 还有一种特殊的变体，叫**多态变体**（polymorphic variant）。它用反引号 `` ` `` 前缀标记构造子：

```ocaml
let describe n =
  match n with
  | 0 -> `Zero
  | 1 -> `One
  | _ -> `Many
```

多态变体和普通变体最大的区别是：**多态变体不需要预先声明类型**。你可以直接用 `` `Zero ``、`` `One `` 这些构造子，编译器会自动推断类型。

多态变体的类型写成 `` [> `Zero | `One | `Many ] `` 这样的形式。`>` 表示「至少包含这些构造子」（开放的）。

多态变体的优势是灵活——你不需要先声明类型就能用。它的劣势是：
- 类型更复杂，报错信息更难读
- 没有穷尽性检查（因为类型是开放的）
- 可能会意外地「兼容」本不该兼容的类型

什么时候用多态变体？一般来说：
- **大部分时候用普通变体**——它们更安全、更清晰
- **小范围的临时联合类型**可以用多态变体，比如函数返回两种不同的结果
- **当你需要「子类型」关系时**用多态变体（多态变体支持行类型的子类型）

### 9.8 变体与模式匹配的配合

变体类型和模式匹配是天作之合。变体定义了数据的形状，模式匹配按照数据的形状分派代码。

这种编程风格有几个好处：

**1. 编译器保证穷尽性**

你不会忘记处理某个情况。加了一个新的构造子？编译器会告诉你所有需要更新的 match。

**2. 解构和匹配一步完成**

你不需要先判断类型再强转——模式匹配同时做了这两件事。而且类型系统确保你不会搞错。

**3. 代码结构和数据结构对应**

数据有几种形式，代码就有几个分支。数据怎么嵌套，模式就怎么嵌套。读代码的时候，你看到模式就知道数据长什么样。

### 9.9 本章小结

- 变体类型是「或」类型，一个值可以是多种形式之一
- 构造子首字母大写，用 `|` 分隔
- 构造子可以带参数，携带不同的数据
- 变体可以递归，用来定义树形等递归数据结构
- 参数化变体（泛型变体）用 `'a` 等类型参数
- 标准库的 `option` 和 `list` 都是参数化变体
- 构造子本质上是函数（但需要包装后才能传递）
- 多态变体（`` `Tag ``）不需要预先声明，更灵活但安全性稍低
- 变体 + 模式匹配是函数式编程的核心组合拳

---

## 第 10 章 字符串与字符

对应示例：`examples/08_strings.ml`

### 10.1 字符串是不可变的字节序列

在 OCaml 中，`string` 是**不可变的字节序列**。注意是「字节」不是「字符」——历史上 OCaml 的 string 被设计成字节串，不是 Unicode 字符串。每个 `string` 元素是一个 8 位的字节（`char` 类型）。

```ocaml
let s = "Hello, World!"
let len = String.length s     (* 13 *)
let first = s.[0]             (* 'H' *)
```

字符串用 `s.[i]` 语法访问第 i 个字节（从 0 开始）。这是 `String.get s i` 的语法糖。

**字符串是不可变的**——你不能修改字符串中的某个字符。所有「修改」字符串的操作（比如 `String.capitalize_ascii`、`String.sub`）都返回新的字符串，原字符串保持不变。

如果你需要可变的字节缓冲区，用 `Bytes` 模块。`Bytes.t` 是可变的字节序列，和 `string` 之间可以互相转换：

```ocaml
let b = Bytes.of_string "hello"
let () = Bytes.set b 0 'H'     (* 原地修改 *)
let s = Bytes.to_string b      (* "Hello" *)
```

### 10.2 char 类型

`char` 是单字节字符类型，用单引号括起来：

```ocaml
let c1 = 'A'
let c2 = '\n'      (* 换行符 *)
let c3 = '\65'     (* 八进制转义，等于 'A' *)
```

`char` 和 `int` 之间可以互相转换：

```ocaml
let code = Char.code 'A'      (* 65 *)
let ch = Char.chr 97          (* 'a' *)
```

`Char` 模块还有一些常用函数：

- `Char.uppercase_ascii` / `Char.lowercase_ascii`：大小写转换（只处理 ASCII）
- `Char.compare`：比较两个字符

注意这些 `_ascii` 后缀的函数只正确处理 ASCII 范围（0-127）的字符。对于超出 ASCII 范围的字节，它们的行为是未定义的（实际上是按字节值处理的，对于 ISO-8859-1 也能工作）。

判断字符类型的常用方法是直接比较：

```ocaml
let is_digit c = c >= '0' && c <= '9'
let is_lower c = c >= 'a' && c <= 'z'
let is_upper c = c >= 'A' && c <= 'Z'
```

### 10.3 字符串拼接与子串

**拼接**：用 `^` 运算符拼接两个字符串：

```ocaml
let s = "Hello" ^ ", " ^ "World" ^ "!"
```

`^` 是右结合的，而且每次拼接都会创建新字符串。如果要拼接很多字符串，推荐用 `String.concat` 或 `Buffer` 模块，性能更好。

**String.concat**：用分隔符把字符串列表连起来：

```ocaml
val concat : string -> string list -> string

let words = ["apple"; "banana"; "cherry"]
let csv = String.concat ", " words     (* "apple, banana, cherry" *)
```

**String.sub**：取子串，参数是起始位置和长度：

```ocaml
val sub : string -> int -> int -> string

let s = "Hello, World!"
let hello = String.sub s 0 5      (* "Hello" *)
let world = String.sub s 7 5      (* "World" *)
```

如果起始位置或长度不合法（越界），`String.sub` 会抛出 `Invalid_argument` 异常。

### 10.4 字符串分割

`String.split_on_char` 按字符分割字符串：

```ocaml
val split_on_char : char -> string -> string list

let path = "/usr/local/bin/ocaml"
let parts = String.split_on_char '/' path
(* [""; "usr"; "local"; "bin"; "ocaml"] *)
```

注意开头的空字符串——因为第一个字符就是分隔符。

`split_on_char` 是最简单的分割函数。如果你需要更复杂的分割（比如按字符串分割、按正则表达式分割），需要自己实现或用第三方库（比如 `Str` 模块或 `Re` 库）。

### 10.5 字符串与列表互转

有时候你需要用列表操作来处理字符串。可以通过 `Seq`（序列）在字符串和列表之间转换：

```ocaml
(* 字符串 -> 字符列表 *)
let chars = s |> String.to_seq |> List.of_seq

(* 字符列表 -> 字符串 *)
let s = cl |> List.to_seq |> String.of_seq
```

利用这个转换，你可以用 `List.map` 来处理字符串中的每个字符：

```ocaml
let to_uppercase s =
  s |> String.to_seq |> Seq.map Char.uppercase_ascii |> String.of_seq
```

字符串反转也可以通过列表实现：

```ocaml
let reverse_string s =
  s |> String.to_seq |> List.of_seq |> List.rev |> List.to_seq |> String.of_seq
```

当然，对于大字符串，通过列表中转效率不高。实际项目中推荐用 `Buffer` 模块直接构建。

### 10.6 Printf 格式化输出

`Printf` 模块提供了类似 C 语言 `printf` 的格式化功能，但类型安全。

常用的格式说明符：

| 说明符 | 类型 | 说明 |
|---|---|---|
| `%d` | `int` | 十进制整数 |
| `%f` | `float` | 浮点数 |
| `%s` | `string` | 字符串 |
| `%c` | `char` | 字符 |
| `%b` | `bool` | 布尔值 |
| `%x` | `int` | 十六进制（小写） |
| `%X` | `int` | 十六进制（大写） |
| `%o` | `int` | 八进制 |
| `%Ld` | `int64` | 64 位整数 |
| `%.2f` | `float` | 保留两位小数 |
| `%10s` | `string` | 宽度 10，右对齐 |
| `%-10s` | `string` | 宽度 10，左对齐 |
| `%!` | - | 刷新缓冲区 |

```ocaml
Printf.printf "Name: %s, Age: %d, Height: %.2f\n" "Alice" 30 1.65
```

`Printf.sprintf` 返回格式化后的字符串，而不是打印出来：

```ocaml
let msg = Printf.sprintf "Result: %d + %d = %d" 3 4 (3 + 4)
(* "Result: 3 + 4 = 7" *)
```

`Printf` 的格式化函数是类型安全的。如果你用 `%d` 但传了一个 `string`，编译器会在编译期报错，而不是等到运行时才崩。这得益于 OCaml 的类型系统——格式化字符串不是普通的字符串，它有特殊的类型（格式标记类型）。

### 10.7 关于 Unicode

需要特别提醒：OCaml 标准库的 `string` 和 `char` 是面向字节的，不是面向 Unicode 字符的。

- `String.length "中文"` 返回的是字节数（6，因为每个汉字占 3 个 UTF-8 字节），不是字符数（2）
- `s.[0]` 返回的是第一个字节，不是第一个字符
- `Char.uppercase_ascii 'a'` 只处理 ASCII 字符，对中文无效

如果你需要正确处理 Unicode 文本，应该用第三方库：

- **`uutf` / `uunf` / `uucp`**：Unicode 字符处理的基础库
- **`sedlex`**：Unicode 词法分析器生成器
- **`Camomile`**：功能完整的 Unicode 库

在实际项目中，最常见的做法是：把字符串当 UTF-8 编码的字节串处理，需要字符级操作时用第三方库。

### 10.8 字符串的常用操作速查

| 操作 | 函数 / 运算符 | 复杂度 |
|---|---|---|
| 取长度 | `String.length s` | O(1) |
| 取第 i 个字节 | `s.[i]` / `String.get s i` | O(1) |
| 拼接两个字符串 | `s1 ^ s2` | O(n+m) |
| 用分隔符连接列表 | `String.concat sep lst` | O(总长度) |
| 取子串 | `String.sub s start len` | O(len) |
| 按字符分割 | `String.split_on_char c s` | O(n) |
| 转大写（ASCII） | `String.uppercase_ascii s` | O(n) |
| 转小写（ASCII） | `String.lowercase_ascii s` | O(n) |
| 首字母大写（ASCII） | `String.capitalize_ascii s` | O(n) |
| 比较 | `String.compare s1 s2` | O(min(n,m)) |
| 包含 | `String.contains s c` | O(n) |

### 10.9 本章小结

- OCaml 的 `string` 是不可变的字节序列，不是 Unicode 字符串
- `char` 是单字节类型，用 `Char.code` / `Char.chr` 和 int 互转
- 字符串拼接用 `^`，大量拼接用 `String.concat` 或 `Buffer`
- `String.sub` 取子串，`String.split_on_char` 按字符分割
- 字符串和列表可以通过 `Seq` 互转
- `Printf.printf` / `Printf.sprintf` 提供类型安全的格式化输出
- 需要 Unicode 处理时用第三方库（uutf、Camomile 等）
- `Bytes` 是可变的字节缓冲区

---

## 第 11 章 递归与尾递归

对应示例：`examples/09_recursion.ml`

### 11.1 递归是函数式编程的循环

在命令式语言中，你用 `for`、`while` 循环来重复执行代码。在函数式语言中，**递归是默认的重复手段**。

一个递归函数就是一个调用自身的函数。它通常包含两部分：

- **基准情形**（base case）：递归的终点，不再调用自身
- **递归情形**（recursive case）：调用自身，但问题规模缩小了

经典的阶乘例子：

```ocaml
let rec factorial n =
  if n <= 0 then 1              (* 基准情形：0! = 1 *)
  else n * factorial (n - 1)    (* 递归情形：n! = n * (n-1)! *)
```

注意 `rec` 关键字——OCaml 要求显式声明递归函数。这不是随意的设计：`let rec` 改变了名字的作用域规则——在 `let rec` 中，函数名在函数体内可见；在普通 `let` 中则不可见。

为什么默认不是递归的？因为有时候你想「重新定义」一个函数，同时在新定义中引用旧定义。如果默认都是 `rec`，你就没法这么做了。

### 11.2 朴素斐波那契与指数爆炸

斐波那契数列是递归的经典例子，但朴素实现的性能非常糟糕：

```ocaml
let rec fib n =
  if n = 0 then 0
  else if n = 1 then 1
  else fib (n - 1) + fib (n - 2)
```

这个实现的时间复杂度是 O(2^n)——指数级的。因为 `fib n` 会调用 `fib (n-1)` 和 `fib (n-2)`，而它们又会各自调用更小的 fib，导致大量重复计算。

比如计算 `fib 5`：
- `fib 5` 调用 `fib 4` 和 `fib 3`
- `fib 4` 调用 `fib 3` 和 `fib 2`
- `fib 3` 调用 `fib 2` 和 `fib 1`
- ……

`fib 3` 被算了两次，`fib 2` 被算了三次……随着 n 增大，重复计算的量爆炸式增长。`fib 40` 就已经能感觉到明显的延迟了。

这说明：**不是所有递归都是高效的**。递归只是一种编程模式，性能取决于具体的算法。

### 11.3 尾递归与累积器

**尾递归**（tail recursion）是一种特殊的递归——递归调用是函数的**最后一个操作**。尾递归的重要性在于：编译器可以把它优化成循环（尾调用优化，TCO），这样就不会消耗栈空间，也不会栈溢出。

怎么把普通递归改成尾递归？最常用的技巧是引入**累积器**（accumulator）——一个额外的参数，用来「累积」中间结果。

以阶乘为例：

```ocaml
(* 普通递归：不是尾递归 *)
let rec factorial n =
  if n <= 0 then 1
  else n * factorial (n - 1)
  (* 递归调用后还要做乘法，所以不是最后一个操作 *)

(* 尾递归版本：用累积器 *)
let factorial_tail n =
  let rec loop acc n =
    if n <= 0 then acc
    else loop (acc * n) (n - 1)
    (* 递归调用是最后一个操作 *)
  in
  loop 1 n
```

`loop` 函数中的递归调用 `loop (acc * n) (n - 1)` 是函数的最后一个操作——调用返回的值直接就是 `loop` 的返回值，不需要再做任何计算。这就是尾递归。

尾递归优化的原理很简单：既然递归调用是最后一个操作，那当前函数的栈帧（stack frame）已经没用了，可以直接复用。所以尾递归函数的栈空间是 O(1) 的，和循环一样。

### 11.4 尾递归斐波那契

用尾递归改写斐波那契，时间复杂度从 O(2^n) 降到 O(n)：

```ocaml
let fib_tail n =
  let rec loop a b n =
    (* a = fib(i), b = fib(i+1) *)
    if n = 0 then a
    else loop b (a + b) (n - 1)
  in
  loop 0 1 n
```

这里用了两个累积器 `a` 和 `b`，分别保存当前和下一个斐波那契数。每递归一步，就把这两个值往前推进一步。这本质上就是把迭代版本的循环变量变成了函数参数。

### 11.5 尾调用优化的原理与限制

**尾调用优化（Tail Call Optimization, TCO）** 的意思是：如果一个函数调用是「尾调用」（即调用的返回值直接被返回，不需要再做任何计算），那么编译器可以复用当前的栈帧，而不是创建新的栈帧。

不仅递归的尾调用可以优化，任何函数的尾调用都可以优化。比如：

```ocaml
let f x = g (x + 1)   (* g 的调用是尾调用，可以优化 *)
let f x = 1 + g x     (* 不是尾调用，因为 g 返回后还要加 1 *)
```

OCaml 的字节码编译器（ocamlc）和原生编译器（ocamlopt）都实现了尾调用优化。

**尾调用优化的限制**：

1. **必须是真正的尾调用**：递归调用必须是函数的最后一个操作。很多看起来像尾递归的代码，其实不是。比如 `List.fold_right` 就不是尾递归的——因为递归返回后还要做 `::` 操作。

2. **内联可能干扰**：如果编译器把函数内联了，尾调用可能就不存在了。不过这通常不影响正确性，只是可能栈使用和你预期的不一样。

3. **调试时可能丢失栈帧**：因为栈帧被复用了，调试器看到的调用栈可能不完整。

### 11.6 互递归（and 关键字）

有时候两个或多个函数需要互相调用对方。这就是**互递归**（mutual recursion）。

互递归需要用 `let rec ... and ...` 语法同时定义：

```ocaml
let rec is_even n =
  if n = 0 then true
  else is_odd (n - 1)
and is_odd n =
  if n = 0 then false
  else is_even (n - 1)
```

为什么需要 `and`？因为如果分开定义，第一个函数引用第二个函数时，第二个函数还没定义，会报 `Unbound value` 错误。`let rec ... and ...` 让这些函数同时进入作用域，这样它们就能互相引用了。

互递归在处理状态机、交替计算、树形结构遍历时很有用。

### 11.7 Ackermann 函数：深度递归的例子

Ackermann 函数是一个著名的递归函数，它定义简单但增长极快：

```
A(0, n) = n + 1
A(m, 0) = A(m-1, 1)
A(m, n) = A(m-1, A(m, n-1))
```

```ocaml
let rec ack m n =
  if m = 0 then n + 1
  else if n = 0 then ack (m - 1) 1
  else ack (m - 1) (ack m (n - 1))
```

Ackermann 函数不是尾递归的——它有很深的嵌套递归调用。`ack 4 2` 的结果已经是一个天文数字（约 2^65536）。

Ackermann 函数常用来测试编译器对深度递归的处理能力，也用来证明「不是所有递归函数都能轻易转换成迭代」。

### 11.8 汉诺塔问题

汉诺塔（Tower of Hanoi）是递归的经典教学案例。问题是：有三根柱子 A、B、C，A 柱上有 n 个盘子，大盘在下、小盘在上。要求把所有盘子从 A 移到 C，每次只能移动一个盘子，且大盘不能放在小盘上。

递归解法非常简洁：

```ocaml
let rec hanoi n source target aux =
  if n = 0 then []
  else
    let step1 = hanoi (n - 1) source aux target in
    let move = Printf.sprintf "Move disk %d from %s to %s" n source target in
    let step3 = hanoi (n - 1) aux target source in
    step1 @ [move] @ step3
```

思路是：
1. 把上面 n-1 个盘子从 source 移到 aux（用 target 做辅助）
2. 把第 n 个盘子从 source 移到 target
3. 把 n-1 个盘子从 aux 移到 target（用 source 做辅助）

汉诺塔的移动次数是 2^n - 1，指数级增长。64 个盘子的话，即使每秒移动一次，也需要约 5800 亿年。

### 11.9 什么时候该担心栈溢出

对于大多数日常编程，你不需要太担心栈溢出——OCaml 的默认栈大小足够处理几千层递归。

但以下情况需要注意：

1. **处理非常大的列表**：比如 `List.fold_right` 在百万级元素的列表上可能栈溢出。这时候应该用 `List.fold_left`（尾递归）。

2. **深度递归但不是尾递归**：比如对一棵非常不平衡的树做递归遍历。

3. **递归深度和输入大小成正比**：如果输入是 n，递归深度也是 n，而且不是尾递归，那 n 大了就会爆栈。

**判断是否尾递归的简单方法**：看递归调用的返回值是否直接被返回（不需要再做任何计算）。如果是，就是尾递归；如果不是，就不是。

### 11.10 本章小结

- 递归是函数式编程的「循环」
- 递归函数需要 `rec` 关键字显式声明
- 朴素斐波那契是 O(2^n)，因为有大量重复计算
- 尾递归：递归调用是最后一个操作，编译器优化为循环
- 累积器是把普通递归改成尾递归的常用技巧
- 互递归用 `let rec ... and ...` 语法
- Ackermann 函数展示了深度递归的威力
- 汉诺塔是递归思维的经典练习
- 大输入时要注意非尾递归可能导致栈溢出

---

## 第 12 章 异常

对应示例：`examples/10_exceptions.ml`

### 12.1 异常是什么

异常（exception）是一种非局部的控制流机制，用于处理错误和特殊情况。当异常被抛出（raise）时，程序会立刻「跳」到最近的捕获（try...with）处。

在 OCaml 中，异常是用 `exception` 关键字定义的：

```ocaml
exception MyError
exception InputOutOfRange of int * int
exception NegativeArgument of string * float
```

异常的定义看起来很像变体类型的构造子——实际上，**异常就是 `exn` 类型的构造子**，而 `exn` 是一个特殊的**可扩展变体**（extensible variant）。你可以随时添加新的异常构造子，这和普通变体类型不同（普通变体一旦定义就不能再加构造子了）。

抛出异常用 `raise` 函数：

```ocaml
let check_positive n =
  if n > 0 then n
  else raise MyError
```

### 12.2 try...with 捕获异常

用 `try ... with ...` 捕获异常：

```ocaml
let safe_div a b =
  try
    Some (a / b)
  with
  | Division_by_zero -> None
```

`try e with pat1 -> e1 | pat2 -> e2 | ...` 的工作方式：
1. 先求值 `e`
2. 如果 `e` 正常返回，就把它的值作为整个 try 表达式的值
3. 如果 `e` 抛出异常，就用异常值去匹配 `with` 后面的模式
4. 第一个匹配的分支的值就是整个 try 表达式的值
5. 如果没有匹配的模式，异常会继续向上传播

`with` 后面的模式就是普通的模式匹配——你可以用通配符、变体构造子模式、`when` 守卫等。

### 12.3 带参数的异常

异常可以携带参数，就像带参数的变体构造子一样：

```ocaml
exception InputOutOfRange of int * int   (* 最小值, 最大值 *)
exception FileError of string * string   (* 文件名, 错误信息 *)

let check_range n min max =
  if n < min || n > max then
    raise (InputOutOfRange (min, max))
  else n
```

捕获时可以解构参数：

```ocaml
try
  check_range 5 10 20
with
| InputOutOfRange (lo, hi) ->
    Printf.printf "Out of range [%d, %d]\n" lo hi;
    0
```

带参数的异常让错误信息可以包含上下文，方便调试和错误恢复。

### 12.4 exn 是可扩展变体类型

`exn` 类型是 OCaml 中一个特殊的类型——它是**可扩展变体**（extensible variant）。这意味着你可以在任何地方给它添加新的构造子（即定义新的异常）。

```ocaml
exception Foo of int    (* 给 exn 添加一个 Foo 构造子 *)
exception Bar of string (* 再添加一个 Bar 构造子 *)
```

这和普通变体类型不同——普通变体类型的构造子在定义时就固定了，不能后续添加。

可扩展变体的优势是灵活：每个库都可以定义自己的异常类型，不需要提前统一声明。劣势是没有穷尽性检查——因为异常类型是开放的，编译器不知道总共有多少种异常，所以 `try...with` 不会检查你是否覆盖了所有可能的异常。

这也是为什么 OCaml 的异常处理是「非类型安全」的——类型系统不会强迫你处理所有可能的异常。

### 12.5 标准库中的常用异常

OCaml 标准库定义了一些常用的异常：

| 异常 | 触发场景 |
|---|---|
| `Failure` | 通用失败，通常带错误信息 |
| `Invalid_argument` | 函数参数非法 |
| `Not_found` | 查找失败（如 `List.find`） |
| `Division_by_zero` | 除以零 |
| `Stack_overflow` | 栈溢出 |
| `Out_of_memory` | 内存不足 |
| `Match_failure` | 模式匹配失败（非穷尽 match 走到了没覆盖的情况） |
| `Sys_error` | 系统调用失败（如文件操作） |
| `End_of_file` | 读到文件末尾 |

`Failure` 和 `Invalid_argument` 都带一个 string 参数，通常是错误描述：

```ocaml
raise (Failure "something went wrong")
raise (Invalid_argument "negative length")
```

也有两个辅助函数：

```ocaml
failwith "message"          (* 等价于 raise (Failure "message") *)
invalid_arg "message"       (* 等价于 raise (Invalid_argument "message") *)
```

### 12.6 异常是不被类型系统追踪的副作用

这是一个重要的观点：**异常是一种副作用，而且是类型系统不追踪的副作用。**

一个函数的类型（比如 `int -> int`）只告诉你它接受 int 返回 int，但不会告诉你它可能抛出什么异常。你可以调用这个函数而完全不处理异常，编译器也不会警告你。

这和 `option` 形成对比。如果一个函数返回 `int option`，类型系统会强迫你处理 `None` 的情况（通过模式匹配）。但如果函数可能抛出异常，类型系统什么也不会说。

所以有一条经验法则：

- **预期内的、需要调用者处理的错误**：用 `option` 或 `result` 类型
- **预期外的、真正的异常情况**：用异常

比如 `List.find` 用 `Not_found` 异常，这是一个有争议的设计——很多人认为应该返回 `'a option`。但标准库的设计者认为「找不到」有时候是正常的，有时候是错误的，所以留了两种选择：你可以捕获异常，也可以先用 `List.exists` 检查。

### 12.7 异常与 option 的选择

什么时候用异常，什么时候用 `option`（或 `result`）？

**用 option / result 的情况：**

- 错误是预期内的、常见的
- 调用者几乎总是需要处理这个错误
- 你想让类型系统确保错误被处理
- 错误是「正常业务逻辑」的一部分

**用异常的情况：**

- 错误是罕见的、意外的
- 调用者通常不需要特别处理，让它往上冒就行
- 在深层嵌套中快速「跳出来」
- 错误处理的性能开销不重要（异常抛出/捕获的开销比返回 option 大）

实际项目中的常见模式是：**库的内部用异常，对外的 API 用 option/result 包装**。这样内部代码可以用异常快速跳出，而对外的接口保持类型安全。

### 12.8 异常的性能考虑

抛出和捕获异常的开销比返回一个 `option` 大。因为异常需要展开栈（unwind the stack）、查找匹配的处理程序等。

但如果异常真的是「异常」的（很少发生），那这点开销可以忽略。只有当异常被用作正常控制流（比如在循环中频繁抛出捕获）时，性能才会成为问题。

一个常见的反模式是：用异常来跳出深层循环或递归。这在功能上没问题，但如果发生得很频繁，应该考虑改用其他方式（比如用 `option` 返回、用可变标志位等）。

### 12.9 异常与资源清理

当异常抛出时，栈会展开，中间的函数会提前返回。这时候如果有需要清理的资源（比如打开的文件、分配的内存），就可能泄露。

OCaml 标准库没有 `finally` 或 `try-with-resources` 这样的语法。但你可以用 `Fun.protect`（OCaml 4.08+）来实现类似的功能：

```ocaml
let with_file filename f =
  let chan = open_in filename in
  Fun.protect
    ~finally:(fun () -> close_in chan)
    (fun () -> f chan)
```

`Fun.protect ~finally work` 会执行 `work ()`，无论它正常返回还是抛出异常，都会执行 `finally ()`。如果 `work ()` 抛出了异常，`finally ()` 执行完后异常会继续传播。

### 12.10 本章小结

- 异常用 `exception` 定义，用 `raise` 抛出，用 `try...with` 捕获
- 异常可以带参数，携带错误上下文信息
- `exn` 是可扩展变体类型，可以随时添加新异常
- 标准库定义了 `Failure`、`Invalid_argument`、`Not_found` 等常用异常
- `failwith s` 是 `raise (Failure s)` 的简写
- 异常是不被类型系统追踪的副作用
- 预期内的错误用 option/result，真正的异常情况用异常
- 异常的抛出/捕获有性能开销，但如果很少发生就没关系
- 用 `Fun.protect` 做资源清理


---

## 第 13 章 高阶函数与闭包

对应示例：`examples/11_higher_order.ml`

### 13.1 函数作为一等公民

在 OCaml 中，函数是**一等公民**（first-class）。这意味着函数可以像整数、字符串、列表一样：

- 作为参数传给其他函数
- 作为返回值从函数中返回
- 存储在数据结构中
- 绑定到变量上

接受函数作为参数，或者返回函数作为结果的函数，叫做**高阶函数**（higher-order function）。我们之前见过的 `List.map`、`List.filter`、`List.fold_left` 都是典型的高阶函数。

为什么高阶函数很重要？因为它让你可以把「计算的模式」抽象出来，把「具体做什么」作为参数传进去。比如 `List.map` 抽象了「对列表中每个元素做变换」这个模式，至于具体变换是什么，由调用者决定。

### 13.2 函数作为参数

我们先从一个简单的例子开始：写一个函数，它接受另一个函数和一个值，然后把函数应用两次。

```ocaml
let apply_twice f x = f (f x)
```

`apply_twice` 的类型是 `('a -> 'a) -> 'a -> 'a`。它的第一个参数是一个函数 `f`，类型是 `'a -> 'a`（输入输出同类型），第二个参数是 `x`，类型是 `'a`。

```ocaml
let double x = x * 2
let square x = x * x

let _ =
  print_int (apply_twice double 3);   (* 12: double(double(3)) = double(6) = 12 *)
  print_int (apply_twice square 3)    (* 81: square(square(3)) = square(9) = 81 *)
```

你也可以直接传匿名函数（lambda）：

```ocaml
apply_twice (fun x -> x + 1) 10   (* 12 *)
```

更实用的例子：写一个 `iterate` 函数，把函数 `f` 迭代应用 `n` 次。

```ocaml
let rec iterate f n x =
  if n <= 0 then x
  else iterate f (n - 1) (f x)

(* 计算 2 的 5 次方：把翻倍函数应用 5 次到 1 上 *)
let _ = iterate (fun x -> x * 2) 5 1   (* 32 *)
```

### 13.3 函数作为返回值

函数不仅可以作为参数，还可以作为返回值。这让你可以写「生成函数的函数」——也叫函数工厂（function factory）。

```ocaml
let make_adder n =
  fun x -> x + n
```

`make_adder` 的类型是 `int -> (int -> int)`。它接受一个整数 `n`，返回一个「加 n」的函数。

```ocaml
let add5 = make_adder 5
let add10 = make_adder 10

let _ =
  print_int (add5 3);    (* 8 *)
  print_int (add10 3)    (* 13 *)
```

注意 `add5` 和 `add10` 是两个不同的函数，它们各自「记住」了自己的 `n` 值（5 和 10）。这就是闭包的雏形——我们马上会详细讲。

再看一个更复杂的例子：生成比较器。

```ocaml
let make_comparison threshold =
  fun x ->
    if x > threshold then "above"
    else if x < threshold then "below"
    else "equal"

let compare_to_10 = make_comparison 10

let _ =
  print_endline (compare_to_10 15);   (* "above" *)
  print_endline (compare_to_10 5);    (* "below" *)
  print_endline (compare_to_10 10)    (* "equal" *)
```

### 13.4 柯里化（Currying）的原理

你可能已经注意到了，OCaml 中多参数函数的类型写法有点特别：

```ocaml
let add x y = x + y
(* val add : int -> int -> int *)
```

类型是 `int -> int -> int`，而不是 `(int * int) -> int`。这是因为箭头 `->` 是右结合的，`int -> int -> int` 实际上等价于 `int -> (int -> int)`。

换句话说，**每个多参数函数本质上都是一个单参数函数，它返回另一个接受剩余参数的函数**。这就是柯里化（currying），以数学家 Haskell Curry 命名。

我们可以用 lambda 来重写 `add`，看得更清楚：

```ocaml
let add = fun x -> fun y -> x + y
```

当你调用 `add 3 4` 时，实际上发生了两步：
1. 先调用 `add 3`，得到一个函数 `fun y -> 3 + y`
2. 再用 `4` 调用这个函数，得到 `7`

`add 3 4` 其实是 `(add 3) 4` 的简写——函数应用是左结合的。

### 13.5 偏应用（Partial Application）

柯里化的一个直接好处是偏应用（partial application）：你可以只传给函数一部分参数，得到一个接受剩余参数的新函数。

```ocaml
let add x y = x + y

(* 只传第一个参数，得到一个 "加 3" 的函数 *)
let add_three = add 3

let _ =
  print_int (add 3 4);        (* 7 *)
  print_int (add_three 4)     (* 7 *)
```

偏应用在实际编程中非常有用。比如你可以用 `List.map` 的偏应用来创建一个「翻倍整个列表」的函数：

```ocaml
let double_all = List.map (fun x -> x * 2)

let _ = double_all [1; 2; 3; 4; 5]   (* [2; 4; 6; 8; 10] *)
```

`List.map` 本来需要两个参数（函数和列表），我们只给了第一个参数（翻倍函数），就得到了一个新函数 `double_all`，它只需要一个列表参数。

再看一个例子，格式化消息：

```ocaml
let format_msg prefix suffix name =
  prefix ^ name ^ suffix

let greet = format_msg "Hello, " "!"
let farewell = format_msg "Goodbye, " "."

let _ =
  greet "Alice";      (* "Hello, Alice!" *)
  greet "Bob";        (* "Hello, Bob!" *)
  farewell "Alice"    (* "Goodbye, Alice." *)
```

**为什么 OCaml 默认就是柯里化的？** 这不是偶然的设计选择——柯里化让偏应用变得「免费」，你不需要额外的语法就能部分应用一个函数。这促进了函数的组合和复用。当然，柯里化也有代价——它让类型签名看起来有点绕，而且每个中间步骤都会产生一个闭包（不过编译器通常会优化掉不必要的闭包分配）。

### 13.6 闭包（Closure）：词法作用域 + 函数值

闭包是函数式编程中最核心的概念之一。简单来说，**闭包 = 函数 + 它捕获的环境（自由变量）**。

让我们用一个例子来理解：

```ocaml
let make_counter () =
  let count = ref 0 in
  fun () ->
    count := !count + 1;
    !count
```

`make_counter` 内部定义了一个引用 `count`，然后返回一个匿名函数。这个匿名函数引用了外部的 `count` 变量——`count` 对于这个匿名函数来说是一个「自由变量」（不是在它内部定义的）。

当 `make_counter ()` 被调用时，它创建了一个 `count` 引用，然后返回一个函数。这个返回的函数不仅仅是代码，它还「记住」了 `count` 这个变量——这就是闭包。

```ocaml
let c1 = make_counter ()
let c2 = make_counter ()

let _ =
  c1 ();  (* 1 *)
  c1 ();  (* 2 *)
  c1 ();  (* 3 *)
  c2 ();  (* 1 *)
  c2 ();  (* 2 *)
  c1 ()   (* 4 *)
```

注意 `c1` 和 `c2` 是两个完全独立的计数器。每次调用 `make_counter ()` 都会创建一个新的 `count` 引用，被新的闭包捕获。`c1` 和 `c2` 各自有自己的状态，互不干扰。

**词法作用域（lexical scoping）** 是闭包的基础。词法作用域的意思是：一个变量指向哪个绑定，由代码的书写位置（词法结构）决定，而不是由运行时的调用栈决定。这意味着函数可以「带走」它定义时所在环境中的变量，即使那个环境已经「退出」了。

你可能会问：`count` 是 `make_counter` 的局部变量，当 `make_counter` 返回后，它不应该被销毁了吗？在有闭包的语言中，答案是否定的——**被闭包捕获的变量会延长生命周期**，它们会存活在堆上，只要闭包还存在，它们就不会被回收。

### 13.7 闭包的实际用途

闭包不仅仅是一个学术概念，它有非常实际的用途。

**用途一：状态封装**

上面的计数器例子就是状态封装。你有一个状态（`count`），但外部不能直接访问它，只能通过你提供的函数接口来操作。这和面向对象中的「私有字段 + 公共方法」本质上是一样的——只不过用闭包实现更轻量。

**用途二：回调函数**

在 GUI 编程、事件处理、异步编程中，回调函数经常需要记住一些上下文信息。闭包可以捕获这些上下文，让回调函数在被调用时仍然能访问到。

**用途三：定制行为**

你可以写一个通用函数，然后通过闭包参数来定制它的行为。比如 `List.filter` 接受一个判断函数，这个判断函数可以捕获外部变量来决定过滤条件。

```ocaml
let greater_than n = List.filter (fun x -> x > n)

(* greater_than 10 返回一个函数，它过滤出大于 10 的元素 *)
let _ = greater_than 10 [5; 12; 8; 20; 3]   (* [12; 20] *)
```

### 13.8 函数组合（Compose）

函数组合是把两个函数「粘」在一起，形成一个新函数。数学中我们写 `f o g`，意思是先应用 g，再应用 f，即 `(f o g)(x) = f(g(x))`。

在 OCaml 中，我们可以自己定义组合运算符：

```ocaml
(* 数学顺序：先 g 后 f，即 f (g x) *)
let (<<) f g x = f (g x)

(* 管道顺序：先 f 后 g，即 g (f x) —— 和 |> 方向一致 *)
let (>>) f g x = g (f x)
```

`>>` 也叫「正向组合」或「管道组合」，因为它的数据流方向和 `|>` 操作符一致，更符合直觉。

```ocaml
let double x = x * 2
let square x = x * x
let inc x = x + 1

(* 先翻倍再平方：square(double(x)) = (2x)^2 = 4x^2 *)
let double_square = double >> square

(* 先平方再翻倍：double(square(x)) = 2x^2 *)
let square_double = square >> double

let _ =
  print_int (double_square 3);   (* 36 *)
  print_int (square_double 3)    (* 18 *)
```

多个函数也可以组合在一起，形成一个处理流水线：

```ocaml
let pipeline = inc >> double >> square
(* 先加一，再翻倍，再平方：square(double(inc(x))) *)

let _ = pipeline 3   (* 64: ((3+1)*2)^2 = 8^2 = 64 *)
```

一个更实用的例子：字符串处理流水线。

```ocaml
let trim s = String.trim s
let upper s = String.uppercase_ascii s
let add_exclaim s = s ^ "!"

let process = trim >> upper >> add_exclaim

let _ = process "  hello  "   (* "HELLO!" *)
```

**函数组合的意义**：它让你可以用小函数搭建大函数，而不需要到处写参数。组合是函数式编程的「胶水」——就像 Unix 的管道一样，把简单的工具连接起来完成复杂的任务。

### 13.9 函数操作符（@@ 和 |>）

OCaml 标准库提供了两个非常实用的函数操作符：`@@` 和 `|>`。

**`@@` 操作符（函数应用）**

`f @@ x` 等价于 `f x`。那为什么还要有这个操作符？因为它的优先级很低，而且是右结合的，可以用来代替括号。

```ocaml
(* 不用 @@ 的写法，需要括号 *)
print_endline (string_of_int (abs (-42)))

(* 用 @@ 的写法，不需要括号 *)
print_endline @@ string_of_int @@ abs (-42)
```

`f @@ g @@ h x` 等价于 `f (g (h x))`。右边的表达式先算，然后一层一层往左应用。

**`|>` 操作符（反向应用 / 管道）**

`x |> f` 等价于 `f x`。它把参数放在左边，函数放在右边。因为它是左结合的，所以可以形成链式调用：

```ocaml
let result =
  [1; 2; 3; 4; 5]
  |> List.map (fun x -> x * 2)
  |> List.filter (fun x -> x > 5)
  |> List.length
```

这段代码的意思是：先把列表每个元素翻倍，然后过滤出大于 5 的，最后求长度。数据从左往右「流」，每一步经过一个函数处理。

`|>` 是 OCaml 中最常用的操作符之一，因为它让代码的阅读顺序和执行顺序一致——你从左往右读，就知道数据是怎么一步步被处理的。这比嵌套的函数调用（`List.length (List.filter ... (List.map ...))`）可读性好太多了。

**`|>` 和 `>>` 的区别**：
- `|>` 是「值 |> 函数」，把一个值传给函数，得到一个新值
- `>>` 是「函数 >> 函数」，把两个函数组合成一个新函数

你可以把 `>>` 看作是「构建管道」，把 `|>` 看作是「把值放进管道」。

### 13.10 函数是一等公民：放进数据结构

既然函数是一等公民，你当然可以把它们放进列表、元组等数据结构中。

```ocaml
let transforms = [
  (fun x -> x * 2);        (* 翻倍 *)
  (fun x -> x * x);        (* 平方 *)
  (fun x -> x + 1);        (* 加一 *)
  (fun x -> 0 - x);        (* 取反 *)
]

(* 对同一个数依次应用所有变换 *)
let apply_all x fns = List.map (fun f -> f x) fns

let _ = apply_all 5 transforms   (* [10; 25; 6; -5] *)
```

这在设计模式中叫做「策略模式」——你有一组策略（函数），可以动态选择使用哪个或哪些策略。在面向对象语言中，你需要定义接口和实现类；在函数式语言中，直接传函数就行了。

### 13.11 本章小结

- 高阶函数是接受函数作为参数或返回函数的函数
- 柯里化：每个多参数函数本质上是返回函数的单参数函数
- 偏应用：只传部分参数，得到接受剩余参数的新函数
- 闭包 = 函数 + 捕获的环境（自由变量），基于词法作用域
- 闭包可以封装状态，每个闭包有独立的状态
- 函数组合（`>>`、`<<`）可以把小函数拼接成大函数
- `|>` 是管道操作符，`x |> f` 等价于 `f x`，左结合，适合链式调用
- `@@` 是低优先级函数应用，`f @@ x` 等价于 `f x`，右结合，可以代替括号
- 函数是一等公民，可以放进列表等数据结构中

---

## 第 14 章 模块与签名

对应示例：`examples/12_modules.ml`

### 14.1 为什么需要模块

当程序很小的时候，所有代码放在一个文件里、所有名字都在全局作用域里，这没什么问题。但当程序变大时，你就会遇到几个问题：

**命名冲突**：你想叫 `map` 的函数，别人也想叫 `map`。如果都在全局作用域，就冲突了。

**抽象不够**：你想对外暴露一些函数，但隐藏内部的辅助函数和数据表示。没有模块的话，所有东西都是公开的。

**组织混乱**：几十上百个函数和类型混在一起，找不到东西。

模块（module）就是用来解决这些问题的。模块提供了：
- **命名空间**：每个模块有自己的作用域，`List.map` 和 `String.map` 不冲突
- **抽象与封装**：通过签名控制哪些东西对外可见，哪些隐藏
- **代码组织**：相关的类型和函数放在一起，结构清晰

OCaml 的模块系统不仅仅是「命名空间」那么简单——它是一套完整的、有类型的模块语言。模块有自己的类型（签名），可以作为参数传给函子（functor），甚至可以作为值来传递（一等模块）。

### 14.2 module 定义结构

用 `module` 关键字定义模块结构（structure）：

```ocaml
module Stack = struct
  type 'a t = 'a list
  let empty = []
  let push x s = x :: s
  let pop = function
    | [] -> failwith "Stack.pop: empty stack"
    | x :: xs -> (x, xs)
  let is_empty s = s = []
  let size = List.length
end
```

模块名必须以大写字母开头。模块内部可以包含类型定义、值、函数、异常、子模块等。

访问模块中的内容用点号：

```ocaml
let s = Stack.empty
  |> Stack.push 1
  |> Stack.push 2
  |> Stack.push 3

let _ =
  Printf.printf "Stack size: %d\n" (Stack.size s)
```

每个 `.ml` 文件本身也是一个模块。比如 `foo.ml` 文件就对应一个名为 `Foo` 的模块，文件里的所有内容都是这个模块的成员。这是 OCaml 中最常见的模块定义方式——一个文件就是一个模块。

### 14.3 module type 定义签名

签名（signature）是模块的类型。就像 `int -> int` 描述了一个函数的接口一样，签名描述了一个模块的接口——它有哪些类型、哪些值、哪些函数，但不描述实现。

用 `module type` 定义签名：

```ocaml
module type STACK = sig
  type 'a t
  val empty : 'a t
  val push : 'a -> 'a t -> 'a t
  val pop : 'a t -> 'a * 'a t
  val is_empty : 'a t -> bool
  val size : 'a t -> int
end
```

签名中：
- `type 'a t` 声明了一个类型（可以是抽象的，也可以有具体定义）
- `val empty : 'a t` 声明了一个值
- `val push : 'a -> 'a t -> 'a t` 声明了一个函数（函数也是值）

`.mli` 文件就是对应 `.ml` 文件的签名。`foo.mli` 定义了 `Foo` 模块的对外接口。

### 14.4 签名约束（透明约束）

你可以用 `:` 给模块加上签名约束，就像给值加类型标注一样：

```ocaml
module AbstractStack : STACK = struct
  type 'a t = 'a list
  let empty = []
  let push x s = x :: s
  let pop = function
    | [] -> failwith "AbstractStack.pop: empty stack"
    | x :: xs -> (x, xs)
  let is_empty s = s = []
  let size = List.length
end
```

这里的 `:` 叫做**透明约束**（transparent constraint）。它的意思是「这个模块至少要实现签名中声明的东西」。

注意签名中的 `type 'a t` 没有给出具体定义——它是抽象的。当模块被加上这个签名约束后，外部就不知道 `'a t` 到底是什么了。你只能通过 `empty`、`push`、`pop` 等函数来操作它，不能直接把它当列表用。

```ocaml
let abs_s = AbstractStack.empty
  |> AbstractStack.push "hello"
  |> AbstractStack.push "world"

(* 可以通过接口操作 *)
let _ = Printf.printf "size: %d\n" (AbstractStack.size abs_s)

(* 但不能直接操作内部表示 —— 编译错误 *)
(* let _ : string list = abs_s   (* 错误：类型不匹配 *) *)
```

这就是抽象的力量——你可以改变内部实现（比如把列表改成数组、改成树）而不影响外部使用者，因为外部只依赖签名，不依赖实现。

**透明约束的「透明」体现在哪？** 如果签名中写了 `type t = int`（有具体定义），那么这个类型等式是可见的，外部知道 `t` 就是 `int`。只有当签名中类型是抽象的（只写 `type t`）时，类型才会被隐藏。

还有一种「不透明约束」用 `:>`，它会强制隐藏所有类型信息，我们会在第 16 章详细讲。

### 14.5 open 与局部 open

每次都写 `Stack.push`、`Stack.pop` 有点繁琐。你可以用 `open` 把模块的内容引入当前作用域：

```ocaml
open Stack

let s = empty |> push 1 |> push 2
```

但 `open` 要谨慎使用——它会污染命名空间，可能导致名字冲突。在实际项目中，推荐尽量少用全局 `open`，多用**局部 open**。

局部 open 有两种写法：

**写法一：`let open M in ...`**

```ocaml
let demo_local_open lst =
  let open List in
  map (fun x -> x * 2) lst
  |> filter (fun x -> x > 5)
  |> length
```

`List` 只在 `let open List in` 后面的表达式中可见。

**写法二：`M.( ... )`**

```ocaml
let demo lst =
  List.(map (fun x -> x + 1) lst |> rev)
```

这种写法更简洁，只在括号内打开模块。

局部 open 的好处是作用域明确——你知道哪些名字来自哪个模块，而且不会污染更大的作用域。

### 14.6 include 的使用

`include` 用于把另一个模块的所有内容包含到当前模块中。

```ocaml
module IntSet = struct
  type t = int list
  let empty = []
  let mem x s = List.mem x s
  let add x s = if mem x s then s else x :: s
  let elements s = List.sort compare s
end

module IntSetExtended = struct
  include IntSet                    (* 包含 IntSet 的所有内容 *)
  let of_list lst = List.fold_left (fun s x -> add x s) empty lst
  let union s1 s2 = List.fold_left (fun s x -> add x s) s1 s2
  let inter s1 s2 = List.filter (fun x -> mem x s2) s1
  let cardinal s = List.length (elements s)
end
```

`include` 和 `open` 的区别：
- `open` 只是把名字引入作用域，方便你少写前缀，模块之间还是独立的
- `include` 是把另一个模块的内容**复制**到当前模块中，被包含的内容成为当前模块的一部分

`include` 在签名中也可以使用，用来扩展签名：

```ocaml
module type SET_EXTENDED = sig
  include SET          (* 包含 SET 签名的所有声明 *)
  val of_list : 'a list -> 'a t
  val union : 'a t -> 'a t -> 'a t
end
```

### 14.7 子模块（嵌套模块）

模块内部可以定义子模块，形成层级结构。

```ocaml
module Math = struct
  module Basic = struct
    let add x y = x + y
    let sub x y = x - y
    let mul x y = x * y
    let div x y = x / y
  end

  module Advanced = struct
    let rec factorial n =
      if n <= 1 then 1 else n * factorial (n - 1)
    let rec fibonacci n =
      if n <= 1 then n else fibonacci (n - 1) + fibonacci (n - 2)
  end

  module Stats = struct
    let mean lst =
      let sum = List.fold_left (+) 0 lst in
      float_of_int sum /. float_of_int (List.length lst)
  end
end
```

访问子模块的内容用多层点号：

```ocaml
let _ =
  Math.Basic.add 3 4;           (* 7 *)
  Math.Advanced.factorial 5;    (* 120 *)
  Math.Stats.mean [1;2;3;4;5]   (* 3.0 *)
```

子模块是组织大型模块的常用方式。你可以把相关的功能分组到不同的子模块中，让层次更清晰。

### 14.8 一个签名两套实现

模块化编程的核心思想是「接口与实现分离」。同一个签名可以有多个不同的实现，调用者只依赖签名，不依赖具体实现。

我们来定义一个集合的签名，然后用两种不同的方式实现它。

```ocaml
module type SET = sig
  type 'a t
  val empty : 'a t
  val mem : 'a -> 'a t -> bool
  val add : 'a -> 'a t -> 'a t
  val remove : 'a -> 'a t -> 'a t
  val elements : 'a t -> 'a list
  val size : 'a t -> int
end
```

**实现一：基于列表的集合**

```ocaml
module ListSet : SET = struct
  type 'a t = 'a list
  let empty = []
  let mem = List.mem
  let add x s = if mem x s then s else x :: s
  let remove x s = List.filter (fun y -> y <> x) s
  let elements s = List.sort compare s
  let size = List.length
end
```

**实现二：基于二叉搜索树的集合**

```ocaml
module TreeSet : SET = struct
  type 'a t = Empty | Node of 'a t * 'a * 'a t

  let empty = Empty

  let rec mem x = function
    | Empty -> false
    | Node (left, v, right) ->
        let c = compare x v in
        if c = 0 then true
        else if c < 0 then mem x left
        else mem x right

  let rec add x = function
    | Empty -> Node (Empty, x, Empty)
    | Node (left, v, right) as node ->
        let c = compare x v in
        if c = 0 then node
        else if c < 0 then Node (add x left, v, right)
        else Node (left, v, add x right)

  let rec min_node = function
    | Empty -> raise Not_found
    | Node (Empty, v, _) -> v
    | Node (left, _, _) -> min_node left

  let rec remove x = function
    | Empty -> Empty
    | Node (left, v, right) ->
        let c = compare x v in
        if c < 0 then Node (remove x left, v, right)
        else if c > 0 then Node (left, v, remove x right)
        else
          match (left, right) with
          | (Empty, _) -> right
          | (_, Empty) -> left
          | _ ->
              let m = min_node right in
              Node (left, m, remove m right)

  let elements t =
    let rec loop acc = function
      | Empty -> acc
      | Node (left, v, right) ->
          loop (v :: loop acc right) left
    in loop [] t

  let rec size = function
    | Empty -> 0
    | Node (left, _, right) -> 1 + size left + size right
end
```

这两个模块有完全相同的签名 `SET`，但内部实现完全不同——一个用列表（简单但 O(n)），一个用二叉搜索树（高效但复杂）。

因为它们有相同的签名，你可以写一个通用的测试函数，不关心具体是哪个实现：

```ocaml
let test_set (type a) (module S : SET with type 'a t = 'a S.t) name =
  let open S in
  let s = empty
    |> add 3 |> add 1 |> add 4 |> add 1 |> add 5 |> add 9 |> add 2 |> add 6
  in
  Printf.printf "%s size: %d\n" name (size s);
  Printf.printf "%s elements: [%s]\n" name
    (String.concat ", " (List.map string_of_int (elements s)));
  Printf.printf "%s mem 5: %b\n" name (mem 5 s);
  let s' = remove 4 s in
  Printf.printf "%s after remove 4, size: %d\n" name (size s')

let _ =
  test_set (module ListSet) "ListSet";
  test_set (module TreeSet) "TreeSet"
```

（这里用到了一等模块 `(module S : SET)` 的语法，我们会在第 17 章介绍。）

**接口与实现分离的好处**：
1. 你可以先写好接口，然后多人并行实现
2. 你可以写一个简单版本（比如列表实现）快速验证，之后再换成高效版本
3. 调用者代码不需要改，只需要换模块就行
4. 便于单元测试——你可以用 mock 实现替换真实实现

### 14.9 本章小结

- 模块提供命名空间、抽象封装、代码组织三大功能
- `module M = struct ... end` 定义模块结构
- `module type S = sig ... end` 定义模块签名（接口）
- 签名约束 `:` 是透明约束——签名中抽象的类型会被隐藏，有定义的类型仍然可见
- `open` 把模块内容引入作用域，推荐用局部 open（`let open M in` 或 `M.(...)`）
- `include` 把另一个模块的内容包含进来，成为当前模块的一部分
- 模块可以嵌套，形成子模块层级
- 一个签名可以有多个实现，实现接口与实现分离
- 每个 `.ml` 文件对应一个模块，每个 `.mli` 文件对应该模块的签名

---

## 第 15 章 Functor（函子）

对应示例：`examples/13_functors.ml`

### 15.1 什么是 Functor

Functor（函子）是**从模块到模块的函数**。

如果说普通函数是 "值 -> 值"，那么 functor 就是 "模块 -> 模块"。你给它一个模块作为参数，它返回一个新的模块。

为什么需要 functor？想象一下：你写了一个通用的二叉搜索树模块，它需要知道元素的类型和比较函数才能工作。如果没有 functor，你就得为 `int` 写一份、为 `string` 写一份、为 `float` 写一份……代码大量重复。

有了 functor，你可以写一个 `MakeSet` 函子，它接受一个「有序类型」模块作为参数，返回一个针对该类型的集合模块。你只需要写一次算法逻辑，就能用在任意可比较的类型上。

这就是 functor 的核心价值：**参数化模块，代码复用**。

### 15.2 Functor 的定义语法

Functor 的定义语法是：

```ocaml
module FunctorName (Param : SIGNATURE) = struct
  (* ... 使用 Param 中的内容 ... *)
end
```

我们来看一个简单的例子。先定义一个签名作为参数类型：

```ocaml
module type PRINTABLE = sig
  type t
  val to_string : t -> string
end
```

`PRINTABLE` 签名说：任何实现了这个签名的模块，都必须有一个类型 `t` 和一个把 `t` 转成字符串的函数。

现在定义一个 functor，它接受一个 `PRINTABLE` 模块，返回一个带打印功能的模块：

```ocaml
module Printer (P : PRINTABLE) = struct
  let print x = print_endline (P.to_string x)
  let print_list lst =
    print_endline ("[" ^ String.concat "; " (List.map P.to_string lst) ^ "]")
end
```

在 functor 内部，我们通过参数名 `P` 来访问参数模块的内容。

### 15.3 Functor 的应用

应用 functor 就像调用函数一样——把参数传进去：

```ocaml
module IntPrintable = struct
  type t = int
  let to_string = string_of_int
end

module IntPrinter = Printer(IntPrintable)
```

`IntPrinter` 就是 `Printer` 函子作用在 `IntPrintable` 上得到的新模块。我们可以使用它：

```ocaml
let _ =
  IntPrinter.print 42;                    (* 42 *)
  IntPrinter.print_list [1; 2; 3; 4; 5]   (* [1; 2; 3; 4; 5] *)
```

再为 `string` 类型创建一个：

```ocaml
module StringPrintable = struct
  type t = string
  let to_string s = s
end

module StringPrinter = Printer(StringPrintable)

let _ =
  StringPrinter.print "hello world";
  StringPrinter.print_list ["foo"; "bar"; "baz"]
```

注意 `IntPrinter` 和 `StringPrinter` 是两个完全不同的模块——它们是同一个 functor 用不同参数实例化出来的结果，各自操作自己的类型。

### 15.4 更完整的例子：MakeSet

让我们看一个更有实际意义的例子——实现一个类似标准库 `Set.Make` 的 functor。

首先定义参数签名：元素必须是可比较的。

```ocaml
module type ORDERED = sig
  type t
  val compare : t -> t -> int
end
```

然后定义 functor：

```ocaml
module MakeSet (Elem : ORDERED) = struct
  type elem = Elem.t
  type t = Empty | Node of t * elem * t

  let empty = Empty

  let rec mem x = function
    | Empty -> false
    | Node (left, v, right) ->
        let c = Elem.compare x v in
        if c = 0 then true
        else if c < 0 then mem x left
        else mem x right

  let rec add x = function
    | Empty -> Node (Empty, x, Empty)
    | Node (left, v, right) as node ->
        let c = Elem.compare x v in
        if c = 0 then node
        else if c < 0 then Node (add x left, v, right)
        else Node (left, v, add x right)

  let rec elements = function
    | Empty -> []
    | Node (left, v, right) ->
        elements left @ [v] @ elements right

  let rec size = function
    | Empty -> 0
    | Node (l, _, r) -> 1 + size l + size r

  let of_list lst = List.fold_left (fun s x -> add x s) empty lst
end
```

关键点：
- 参数模块 `Elem` 提供了元素类型 `Elem.t` 和比较函数 `Elem.compare`
- 返回的模块中，`type elem = Elem.t` 把元素类型暴露出去
- 所有的比较操作都通过 `Elem.compare` 完成，不直接使用 `compare`

现在我们可以为不同类型实例化集合：

```ocaml
(* int 集合 *)
module IntSet = MakeSet(struct
  type t = int
  let compare = compare
end)

(* string 集合（按长度比较） *)
module StringByLenSet = MakeSet(struct
  type t = string
  let compare s1 s2 = compare (String.length s1) (String.length s2)
end)

let _ =
  let is = IntSet.of_list [5; 2; 8; 1; 9; 3] in
  Printf.printf "IntSet size: %d\n" (IntSet.size is);
  Printf.printf "IntSet elements: [%s]\n"
    (String.concat ", " (List.map string_of_int (IntSet.elements is)))
```

这就是标准库中 `Set.Make` 和 `Map.Make` 的基本原理——它们都是 functor，接受一个可比较的元素类型模块，返回一个针对该类型的集合/映射模块。

### 15.5 带签名约束的 Functor 参数

Functor 的参数可以带有丰富的签名，不仅仅是一个类型和一个函数。比如我们可以定义一个「数字类型」签名，然后基于它构造向量运算模块：

```ocaml
module type NUMERIC = sig
  type t
  val zero : t
  val one : t
  val add : t -> t -> t
  val mul : t -> t -> t
  val to_string : t -> string
end

module VectorOps (Num : NUMERIC) = struct
  type scalar = Num.t
  type vector = scalar list

  let add v1 v2 = List.map2 Num.add v1 v2
  let dot v1 v2 =
    List.fold_left2 (fun acc a b -> Num.add acc (Num.mul a b)) Num.zero v1 v2
  let scale s v = List.map (Num.mul s) v
  let to_string v =
    "[" ^ String.concat ", " (List.map Num.to_string v) ^ "]"
end
```

然后实例化为 int 向量和 float 向量：

```ocaml
module IntVector = VectorOps(struct
  type t = int
  let zero = 0
  let one = 1
  let add = (+)
  let mul = ( * )
  let to_string = string_of_int
end)

module FloatVector = VectorOps(struct
  type t = float
  let zero = 0.0
  let one = 1.0
  let add = (+.)
  let mul = ( *. )
  let to_string = string_of_float
end)
```

同一份向量运算代码，既能用于整数，也能用于浮点数——甚至可以用于任何满足 `NUMERIC` 接口的类型（比如有理数、复数）。

### 15.6 多参数 Functor

Functor 可以接受多个模块参数，就像函数可以有多个参数一样。

```ocaml
module type KEY = sig
  type t
  val compare : t -> t -> int
end

module type VALUE = sig
  type t
  val to_string : t -> string
end

module MakePrintMap (K : KEY) (V : VALUE) = struct
  type key = K.t
  type value = V.t
  type t = (key * value) list

  let empty = []

  let rec find k = function
    | [] -> raise Not_found
    | (k', v) :: rest ->
        if K.compare k k' = 0 then v else find k rest

  let add k v m =
    let rec loop = function
      | [] -> [(k, v)]
      | (k', v') :: rest ->
          if K.compare k k' = 0 then (k, v) :: rest
          else (k', v') :: loop rest
    in loop m

  let bindings m = m
end
```

使用时传入两个参数：

```ocaml
module StringIntMap = MakePrintMap
  (struct type t = string let compare = compare end)
  (struct type t = int let to_string = string_of_int end)
```

和函数类似，多参数 functor 也可以「柯里化」——只传第一个参数，得到一个接受剩余参数的 functor：

```ocaml
module MakeIntValueMap = MakePrintMap(struct
  type t = int
  let compare = compare
end)

module IntIntMap = MakeIntValueMap(struct
  type t = int
  let to_string = string_of_int
end)
```

这里 `MakeIntValueMap` 是一个「偏应用」的 functor——它已经有了键类型（int），还需要传入值类型模块才能得到完整的映射模块。

### 15.7 Functor 的返回签名约束

Functor 的返回结果也可以加上签名约束，用来隐藏内部实现细节。我们会在下一章（不透明约束）详细讨论这个话题，这里先看一个简单例子：

```ocaml
module type SAFE_SET = sig
  type elem
  type t
  val empty : t
  val mem : elem -> t -> bool
  val add : elem -> t -> t
  val elements : t -> elem list
  val size : t -> int
end

module MakeSafeSet (Elem : ORDERED) : SAFE_SET with type elem = Elem.t = struct
  (* ... 实现 ... *)
end
```

这里 `: SAFE_SET with type elem = Elem.t` 就是 functor 的返回签名约束。它说：返回的模块满足 `SAFE_SET` 签名，并且其中的 `elem` 类型等于参数中的 `Elem.t`。

`with type elem = Elem.t` 叫做**共享约束**（sharing constraint）——它告诉类型系统两个类型是相同的。没有这个约束的话，外部就不知道 `SafeIntSet.elem` 就是 `int`，就没法把 `int` 传给 `SafeIntSet.mem` 了。

### 15.8 应用场景：Set.Make 和 Map.Make 背后的原理

OCaml 标准库的 `Set.Make` 和 `Map.Make` 是 functor 最经典的应用。

```ocaml
module StringSet = Set.Make(String)
module IntMap = Map.Make(struct type t = int let compare = compare end)
```

`Set.Make` 是一个 functor，它接受一个模块参数（必须提供 `type t` 和 `val compare`），返回一个针对该类型的集合模块。内部可能用红黑树实现，但外部只看到抽象的 `Set.S` 签名。

为什么要这么设计？为什么不像 Java 那样直接用接口/type class？

因为 OCaml 的模块系统是**生成式**的——每次 functor 应用都会产生一个全新的抽象类型。`Set.Make(String)` 和 `Set.Make(struct type t = string let compare = compare end)` 产生的是不同的类型，即使底层都是 string 的集合。这确保了「不同用途的集合不会混用」——比如你有一个按字典序比较的字符串集合和一个按长度比较的字符串集合，它们的类型是不同的，不会意外混用。

### 15.9 本章小结

- Functor 是「模块 -> 模块」的函数，用于参数化模块
- 定义语法：`module F (P : SIG) = struct ... end`
- 应用语法：`module M = F(ArgModule)`
- Functor 参数是带有签名的模块，提供类型和操作
- 多参数 functor 支持柯里化和偏应用
- 返回值可以加签名约束，控制对外暴露的内容
- `with type ... = ...` 是共享约束，用于指定类型等价关系
- 标准库的 `Set.Make`、`Map.Make` 就是 functor 的典型应用
- Functor 让算法逻辑只写一次，就能复用到不同类型上

---

## 第 16 章 不透明约束与抽象数据类型

### 16.1 透明约束 vs 不透明约束

上一章我们提到了签名约束 `:`，它叫做**透明约束**（transparent constraint）。还有一种约束叫**不透明约束**（opaque constraint），用 `:>`。

它们的区别在于类型信息的可见性：

- **透明约束 `:`**：签名中给出定义的类型，其类型等式是可见的；签名中是抽象的（只写 `type t`），则是抽象的
- **不透明约束 `:>`**：所有在签名中声明的类型，**全部变成抽象的**，即使签名里写了 `type t = int`，外部也不知道

用一个例子来看：

```ocaml
module type COUNTER = sig
  type t
  val create : unit -> t
  val increment : t -> unit
  val get : t -> int
end
```

**透明约束版本**：

```ocaml
module TransparentCounter : COUNTER with type t = int ref = struct
  type t = int ref
  let create () = ref 0
  let increment r = r := !r + 1
  let get r = !r
end
```

透明约束下，`t = int ref` 是可见的。外部可以直接操作内部表示：

```ocaml
let tc = TransparentCounter.create ()
let _ =
  TransparentCounter.increment tc;
  tc := 999;   (* 直接绕过接口修改内部状态！ *)
  Printf.printf "%d\n" (TransparentCounter.get tc)   (* 999 *)
```

**不透明约束版本**：

```ocaml
module OpaqueCounter : COUNTER = struct
  type t = int ref
  let create () = ref 0
  let increment r = r := !r + 1
  let get r = !r
end
```

不透明约束下，`OpaqueCounter.t` 是完全抽象的——外部根本不知道它是 `int ref`。你只能通过 `create`、`increment`、`get` 这些接口来操作它。

```ocaml
let oc = OpaqueCounter.create ()
let _ =
  OpaqueCounter.increment oc;
  (* oc := 999   编译错误！外部不知道 t 是 int ref *)
  Printf.printf "%d\n" (OpaqueCounter.get oc)   (* 1 *)
```

这才是真正的封装。不透明约束保证了外部无法绕过你的接口直接操作内部数据。

### 16.2 什么是抽象数据类型（ADT）

**抽象数据类型**（Abstract Data Type，简称 ADT）是指：由它的操作（可以做什么）来定义，而不是由它的内部表示（怎么实现的）来定义的数据类型。

比如「栈」就是一个抽象数据类型——它由 push、pop、empty、is_empty 这些操作来定义。至于内部是用列表实现还是用数组实现，用户不关心，也不应该知道。

在 OCaml 中，抽象数据类型就是通过**不透明约束 + 签名**来实现的：

```ocaml
module type STACK = sig
  type 'a t          (* 抽象类型：栈的表示 *)
  val empty : 'a t
  val push : 'a -> 'a t -> 'a t
  val pop : 'a t -> 'a * 'a t
  val is_empty : 'a t -> bool
  val size : 'a t -> int
end

(* 用不透明约束封装 *)
module ListStack : STACK = struct
  type 'a t = 'a list
  (* ... 实现 ... *)
end
```

外部只知道 `'a ListStack.t` 是一个栈类型，可以 push/pop，但不知道它内部是列表。你随时可以把内部实现改成数组或者链表，而不需要修改任何使用它的代码。

### 16.3 不变量保护

不透明约束最重要的用途是**保护数据结构的内部不变量**（invariant）。

什么是不变量？就是数据结构必须始终满足的性质。比如：
- 二叉搜索树的不变量：左子树所有节点 < 根 < 右子树所有节点
- 有序列表的不变量：元素按顺序排列
- 日期类型的不变量：月份在 1-12 之间，日期在有效范围内

如果内部表示是公开的，用户就可能手动构造一个破坏不变量的值，导致后续操作出错。

来看一个日期的例子：

```ocaml
module type DATE = sig
  type t
  val create : int -> int -> int -> t   (* 年, 月, 日 *)
  val year : t -> int
  val month : t -> int
  val day : t -> int
  val to_string : t -> string
end

module Date : DATE = struct
  type t = { year : int; month : int; day : int }

  let is_valid y m d =
    m >= 1 && m <= 12 && d >= 1 && d <= 31  (* 简化版校验 *)

  let create y m d =
    if is_valid y m d then { year = y; month = m; day = d }
    else failwith "invalid date"

  let year d = d.year
  let month d = d.month
  let day d = d.day
  let to_string d = Printf.sprintf "%04d-%02d-%02d" d.year d.month d.day
end
```

因为用了不透明约束（`Date : DATE`），外部无法直接构造 `Date.t` 的值，只能通过 `Date.create` 来创建。而 `Date.create` 会做合法性检查——这就保证了**所有 `Date.t` 类型的值都是合法的日期**。

你不需要在每次使用日期时都检查它是否合法——只要你拿到了一个 `Date.t`，它就一定是合法的。这是一种非常强大的保证，叫做**「使非法状态不可表示」**（make illegal states unrepresentable）。

**这就是类型系统的力量**：让类型检查器帮你保证不变量，而不是靠文档和约定。

### 16.4 隐藏内部辅助函数

不透明约束还可以用来隐藏内部的辅助函数。你在模块内部定义了很多辅助函数，但只想对外暴露少数几个公共接口。

```ocaml
module type MATH_UTILS = sig
  val gcd : int -> int -> int
  val lcm : int -> int -> int
end

module MathUtils : MATH_UTILS = struct
  let rec gcd a b =
    if b = 0 then a else gcd b (a mod b)

  (* 内部辅助函数，不对外暴露 *)
  let abs x = if x < 0 then -x else x

  let lcm a b =
    if a = 0 || b = 0 then 0
    else abs (a * b) / gcd a b
end
```

外部只能使用 `gcd` 和 `lcm`，看不到 `abs` 辅助函数。这有几个好处：
- 减少命名空间污染
- 让接口更清晰，用户只看到他们需要的东西
- 内部实现可以自由重构，不用担心破坏外部代码

### 16.5 相等性与抽象类型

抽象类型有一个微妙的问题：相等性。

在 OCaml 中，结构相等（`=`）是多态的——它可以比较任意两个同类型的值。但对于抽象类型，外部不知道内部结构，`=` 还能用吗？

答案是可以的。`=` 操作符在运行时仍然会比较内部表示，不管类型是不是抽象的。类型抽象只影响编译期的类型检查，不影响运行时的行为。

但这里有一个设计问题：你应该允许用户用 `=` 比较你的抽象类型吗？

有时候不应该。比如对于你的集合类型，如果内部用列表实现，`=` 比较的是列表的结构相等——但两个列表顺序不同可能表示同一个集合（因为集合是无序的）。这时候 `=` 给出的结果在语义上就是错误的。

所以对于抽象类型，一个好的实践是：**在签名中提供自己的相等性函数**，并提醒用户不要直接用 `=`。

```ocaml
module type SET = sig
  type 'a t
  val equal : 'a t -> 'a t -> bool
  (* ... 其他操作 ... *)
end
```

当然，这只能靠约定——用户仍然可以用 `=`，你无法在类型层面阻止。但至少你提供了正确的比较方式。

### 16.6 多态抽象类型

抽象类型可以是多态的。比如栈、集合这些数据结构，它们可以装任意类型的元素。

```ocaml
module type STACK = sig
  type 'a t         (* 多态抽象类型 *)
  val empty : 'a t
  val push : 'a -> 'a t -> 'a t
  (* ... *)
end
```

`type 'a t` 表示 `t` 是一个带一个类型参数的抽象类型。外部看到的是 `'a Stack.t`，知道它是「装 'a 类型元素的栈」，但不知道内部表示。

### 16.7 Functor + 不透明约束的强大组合

Functor 和不透明约束结合起来，威力巨大。你可以用 functor 参数化地构造模块，同时用不透明约束封装内部实现。

标准库的 `Set.Make` 就是这样的：

```ocaml
(* Set.Make 的简化版本 *)
module Make (Ord : OrderedType) : S with type elt = Ord.t = struct
  type elt = Ord.t
  type t = Empty | Node of t * elt * t
  (* ... 实现 ... *)
end
```

返回的模块满足 `Set.S` 签名（不透明约束），但 `elt` 类型和参数模块的 `Ord.t` 共享（`with type elt = Ord.t`）。这意味着：
- 内部的树结构是隐藏的，外部无法直接构造或修改
- 但元素类型是已知的，用户可以用 `Ord.t` 类型的值去调用 `mem`、`add` 等函数

这种「大部分隐藏，选择性暴露」的模式非常常见。你通过不透明约束隐藏所有实现细节，然后通过 `with type ... = ...` 共享约束来暴露必要的类型等式。

### 16.8 本章小结

- 透明约束 `:`：签名中有定义的类型可见，抽象的类型不可见
- 不透明约束 `:>`：签名中所有类型都变成抽象的，完全隐藏
- 抽象数据类型（ADT）：由操作定义，不由内部表示定义
- 不透明约束可以保护数据结构的内部不变量
- 「使非法状态不可表示」是类型驱动设计的核心思想
- 不透明约束还可以隐藏内部辅助函数，保持接口简洁
- 抽象类型可以是多态的（`'a t`）
- Functor + 不透明约束 = 参数化 + 封装，是 OCaml 模块系统最强大的组合
- `with type ... = ...` 共享约束用于在不透明约束下选择性地暴露类型等式

---

## 第 17 章 模块系统进阶

### 17.1 open 的遮蔽规则

当你 `open` 一个模块时，它的名字会被引入当前作用域。如果当前作用域已经有同名的东西了呢？

答案是：**后打开的会遮蔽先打开的**。

```ocaml
let x = 1

module M = struct
  let x = 2
end

open M

let _ = print_int x   (* 输出 2，M.x 遮蔽了外层的 x *)
```

同样，如果打开两个模块，它们有同名的值，后打开的会遮蔽先打开的：

```ocaml
module A = struct let x = 1 end
module B = struct let x = 2 end

open A
open B

let _ = print_int x   (* 输出 2，B.x 遮蔽了 A.x *)
```

这就是为什么要谨慎使用全局 `open`——打开的模块多了，你可能意外地遮蔽了一些名字，导致难以调试的 bug。

**最佳实践**：
1. 尽量少用全局 `open`，多用局部 open
2. 如果你确实需要全局 open，先打开大的、通用的模块（比如 `Stdlib`），再打开小的、专用的模块
3. 对于只用到一两个名字的模块，直接写模块前缀，不要 open

### 17.2 include 在签名和结构中的使用

我们之前见过 `include` 在结构（`struct ... end`）中的使用，它也可以用在签名（`sig ... end`）中。

**在结构中使用 include**：

```ocaml
module Base = struct
  type t = int
  let zero = 0
  let add x y = x + y
end

module Extended = struct
  include Base
  let one = 1
  let mul x y = x * y
end
```

`Extended` 包含了 `Base` 的所有内容，再加上自己的 `one` 和 `mul`。

**在签名中使用 include**：

```ocaml
module type BASE = sig
  type t
  val zero : t
  val add : t -> t -> t
end

module type EXTENDED = sig
  include BASE
  val one : t
  val mul : t -> t -> t
end
```

`EXTENDED` 签名包含了 `BASE` 的所有声明，再加上 `one` 和 `mul`。

**include 和 open 的区别**：
- `open` 只是名字空间上的便捷——不改变模块的内容
- `include` 是真正的「复制粘贴」——被包含的内容成为当前模块/签名的一部分

**什么时候用 include？**
- 当你想扩展一个已有的模块或签名时
- 当你想混入（mixin）一组功能时
- 当多个模块共享一些公共定义时

但不要滥用 include。如果包含的东西太多，模块的内容来源就不清晰了，反而降低可读性。

### 17.3 module type of 的用法

有时候你想让一个模块的签名和另一个模块相同，但又不想手动写一遍签名。这时候可以用 `module type of`。

```ocaml
module M = struct
  type t = int
  let x = 42
  let f y = y + 1
end

(* 让 N 和 M 有相同的签名 *)
module type M_SIG = module type of M

module N : M_SIG = struct
  type t = int
  let x = 100
  let f y = y * 2
end
```

`module type of M` 会自动推断出 `M` 的签名，然后你可以把它用在别的地方。

这在几个场景下很有用：
- 你想给一个已有模块做一个替代实现，但保持相同的接口
- 你想让 functor 的返回签名和某个参考模块一致
- 你不想手动写冗长的签名

但要注意：`module type of` 推断出来的签名是「完全透明」的——所有类型定义都会暴露出来。如果你想要抽象类型，还是得手写签名。

### 17.4 私有类型别名（private type）

私有类型（private type）是介于「透明」和「不透明」之间的一种类型约束。

- 透明类型：外部可以直接构造、解构、模式匹配
- 不透明类型：外部完全不知道内部是什么，只能通过接口操作
- 私有类型：外部可以**读取**（模式匹配、解构），但不能**构造**

语法：`type t = private ...`

来看一个例子：

```ocaml
module type POSITIVE = sig
  type t = private int    (* 私有类型：底层是 int，但不能直接构造 *)
  val create : int -> t
  val value : t -> int
end

module Positive : POSITIVE = struct
  type t = int
  let create n =
    if n > 0 then n
    else failwith "Positive.create: must be positive"
  let value n = n
end
```

因为是 `private int`，外部可以：
- 用模式匹配解构：`let (Positive x) = p`（注：实际语法略有不同）
- 用 `:>` 强制转换回 `int`：`(p :> int)`

但外部不能：
- 直接构造：`(5 : Positive.t)` 不行
- 直接修改：只能通过 `create` 得到新值

私有类型的好处是：你可以享受模式匹配的便利，同时保持构造的控制权（保证不变量）。

不过私有类型在实际 OCaml 代码中用得不算多——大多数时候，要么完全透明（简单的类型别名），要么完全不透明（需要强封装）。私有类型处于中间地带，适用场景有限。

### 17.5 模块别名（module alias）

模块别名就是给一个已有的模块起另一个名字。

```ocaml
module S = String

let _ = S.length "hello"   (* 等价于 String.length *)
```

这看起来和 `let s = "hello"` 类似，但模块别名是在模块层面的。

模块别名有一个重要的性质：**类型共享**。如果 `S` 是 `String` 的别名，那么 `S.t` 和 `String.t` 是同一个类型。

```ocaml
module S = String
let s : S.t = "hello"
let _ : String.t = s   (* 没问题，S.t = String.t *)
```

模块别名的用途：
- 缩短长模块名：`module L = ListLabels`
- 重导出模块：在你的库模块中重新导出依赖的模块
- 版本切换：通过别名切换不同的实现模块

### 17.6 First-class Modules（一等模块）简介

普通的模块是「编译期的」——你在编译时定义模块、应用 functor，模块不能作为运行时的值来传递。

但 OCaml 也支持**一等模块**（first-class modules）——你可以把模块包装成一个值，在运行时传递、存储在列表中、作为函数参数等。

把模块包装成一等模块的语法是 `(module M : SIG)`：

```ocaml
module type SHOW = sig
  type t
  val show : t -> string
end

module IntShow = struct
  type t = int
  let show = string_of_int
end

(* 包装成一等模块 *)
let int_show : (module SHOW with type t = int) = (module IntShow : SHOW with type t = int)
```

解包一等模块用 `let module M = (module val x : SIG) in ...` 或者在模式匹配中：

```ocaml
let show_it (type a) (module S : SHOW with type t = a) (x : a) =
  S.show x

let _ = show_it (module IntShow) 42   (* "42" *)
```

> **实测坑**：package type（`module ... : SIG with type ...` 里的
> 类型方程部分）**不支持参数化类型方程**——`(module S : SET with
> type 'a t = 'a S.t)` 直接语法错（"invalid package type:
> parametrized types are not supported"）。想要“元素类型可约束的
> 首类模块”，把元素类型拆成独立的 `elt`（标准库 Set/Map 的设计），
> 再用简单的 `with type elt = a` 方程——示例 12 第 7 节就是这么改的。

一等模块让你可以在运行时动态选择模块实现。比如你可以写一个函数，根据配置返回不同的模块实现：

```ocaml
let get_set_impl use_tree =
  if use_tree then
    (module TreeSet : SET)
  else
    (module ListSet : SET)
```

不过一等模块是比较高级的特性，日常编程中用得不多。大多数时候，普通的模块和 functor 就足够了。一等模块主要用于需要运行时动态性的场景。

### 17.7 模块系统的设计哲学

OCaml 的模块系统设计有几个核心思想：

**1. 模块是独立的语言层级**

模块不是类型系统的附属品，而是一个独立的、有自己类型系统的层级。模块有自己的类型（签名），有自己的函数（functor），有自己的抽象机制（不透明约束）。

这种设计的好处是：模块层和核心语言层解耦。你可以用模块做大规模的架构设计，而不影响核心语言的简洁性。

**2. 生成性与抽象性**

Functor 是生成式的（generative）——每次应用都产生新的抽象类型。这确保了不同用途的相同表示不会混淆。

比如 `Set.Make(String)` 得到的集合类型，和另一个 `Set.Make(struct type t = string ... end)` 得到的集合类型是不同的，即使它们内部都是字符串的集合。这防止了意外混用。

**3. 显式优于隐式**

模块系统倾向于显式。你需要显式地 open、显式地包含、显式地应用 functor。这和 Haskell 的类型类（type class）的隐式解析形成对比。

显式的好处是可预测——你看代码就知道名字从哪来、模块怎么组合的。代价是可能稍微啰嗦一点。

**4. 编译期零开销**

模块系统的所有操作（定义、约束、functor 应用）都在编译期完成。运行时没有模块的概念，也没有任何开销。这和 C++ 的模板类似——都是编译期生成代码。

### 17.8 本章小结

- `open` 会引入名字，后打开的遮蔽先打开的
- `include` 可以用在结构和签名中，是真正的内容复制
- `module type of` 可以获取一个模块的签名类型
- 私有类型（private）介于透明和不透明之间：可读不可构造
- 模块别名给模块起别名，类型是共享的
- 一等模块可以把模块作为运行时值传递
- 模块系统是独立的语言层级，编译期零开销
- Functor 是生成式的，确保不同实例的类型不混淆

---

## 第 18 章 可变状态

对应示例：`examples/14_mutable.ml`

### 18.1 为什么 OCaml 提供可变状态

OCaml 是一门函数式语言，但它不是纯函数式的。它提供了完整的可变状态机制——引用、可变记录字段、数组、哈希表等等。

为什么一门函数式语言要提供可变状态？有几个原因：

**性能**：有些算法用可变数据结构实现效率高得多。比如数组的随机访问是 O(1)，而列表是 O(n)。在性能敏感的场景下，你需要这些工具。

**便利**：有些问题用命令式方式写更自然。比如累加器、计数器、状态机——当然用纯函数式也能写（用递归 + 参数传递状态），但有时候用可变变量写起来更直接。

**实用主义**：OCaml 的设计哲学是「函数式优先，但不教条」。它相信最好的程序员会根据场景选择最合适的范式。默认是不可变的（函数式），但当你需要可变状态时，语言提供了清晰、明确的工具。

记住这个原则：**优先使用不可变数据，只有在有充分理由时才使用可变状态。**

### 18.2 ref 引用类型

`ref` 是 OCaml 中最基本的可变数据结构。`ref 'a` 表示一个「指向 'a 类型值的可变引用」。

三个基本操作：
- `ref x`：创建一个引用，初始值为 `x`
- `!r`：读取引用 `r` 的当前值（解引用）
- `r := x`：将引用 `r` 的值设为 `x`（赋值）

```ocaml
let counter = ref 0        (* 创建一个引用，初始值为 0 *)
let _ =
  print_int !counter;      (* 0 —— 读取当前值 *)
  counter := 10;           (* 赋值为 10 *)
  print_int !counter       (* 10 *)
```

注意 `!` 不是逻辑非运算符（那是 `not`），而是解引用。`:=` 是赋值运算符。

标准库还提供了两个便捷函数：
- `incr r`：自增，等价于 `r := !r + 1`
- `decr r`：自减，等价于 `r := !r - 1`

```ocaml
let counter = ref 0
let _ =
  incr counter;   (* !counter = 1 *)
  incr counter;   (* !counter = 2 *)
  decr counter;   (* !counter = 1 *)
  Printf.printf "%d\n" !counter
```

`ref` 可以引用任意类型：

```ocaml
let name = ref "Alice"
let _ =
  print_endline !name;    (* "Alice" *)
  name := "Bob";
  print_endline !name     (* "Bob" *)
```

### 18.3 ref 的本质：一个只有一个可变字段的记录

`ref` 不是什么神奇的内置类型。它的定义非常简单：

```ocaml
type 'a ref = { mutable contents : 'a }
```

`ref` 就是一个只有一个字段的记录，而且这个字段是可变的（`mutable`）。

- `ref x` 就是 `{ contents = x }`
- `!r` 就是 `r.contents`
- `r := x` 就是 `r.contents <- x`

你可以自己验证一下：

```ocaml
let r = ref 42
let _ =
  print_int r.contents;     (* 42 —— 直接访问字段 *)
  r.contents <- 100;        (* 直接赋值给字段 *)
  print_int !r              (* 100 *)
```

知道 `ref` 的本质很重要——它帮助你理解 OCaml 的设计哲学：尽量用简单的机制来构造复杂的功能，而不是不断增加特殊语法。

### 18.4 可变记录字段

记录（record）中的字段默认是不可变的。你可以用 `mutable` 关键字声明可变字段。

```ocaml
type person = {
  name : string;           (* 不可变字段 *)
  age : int;               (* 不可变字段 *)
  mutable salary : float;  (* 可变字段 *)
}
```

不可变字段一旦创建就不能修改，可变字段可以随时修改。

```ocaml
let alice = { name = "Alice"; age = 30; salary = 50000.0 }

let _ =
  (* 读取字段 *)
  Printf.printf "%s earns %.2f\n" alice.name alice.salary;
  
  (* 修改可变字段 *)
  alice.salary <- 60000.0;
  Printf.printf "After raise: %.2f\n" alice.salary;
  
  (* 不可变字段不能修改 —— 编译错误 *)
  (* alice.age <- 31 *)
```

可变字段的赋值语法是 `record.field <- new_value`，用 `<-` 而不是 `:=`。

**什么时候用可变记录字段，什么时候用 ref？**

- 如果你有一个数据结构，其中只有一部分字段需要修改——用可变记录字段
- 如果你只需要一个单独的可变变量——用 ref
- 其实 ref 就是带一个可变字段的记录，两者本质上是一样的

### 18.5 Array 数组

列表是不可变的，而且随机访问是 O(n)。如果你需要高效的随机访问和原地修改，就需要数组（Array）。

**创建数组**：

```ocaml
let arr1 = [| 1; 2; 3; 4; 5 |]    (* 字面量语法 *)
let arr2 = Array.make 5 0          (* 长度为 5，初始值都是 0 *)
let arr3 = Array.init 5 (fun i -> i * i)   (* 用函数初始化：[| 0; 1; 4; 9; 16 |] *)
```

**访问元素**：

```ocaml
let arr = [| 10; 20; 30; 40; 50 |]
let _ =
  print_int arr.(0);    (* 10 —— 第一个元素，索引从 0 开始 *)
  print_int arr.(2)     (* 30 *)
```

数组访问用 `arr.(i)` 语法，这是 `Array.get arr i` 的语法糖。

**修改元素**：

```ocaml
let arr = [| 10; 20; 30 |]
let _ =
  arr.(1) <- 200;       (* 把索引 1 的元素改为 200 *)
  print_int arr.(1)     (* 200 *)
```

`arr.(i) <- x` 是 `Array.set arr i x` 的语法糖。

**常用函数**：

```ocaml
let arr = [| 5; 2; 8; 1; 9; 3 |]
let _ =
  Array.length arr;               (* 6 —— 数组长度 *)
  Array.iter print_int arr;       (* 遍历每个元素 *)
  Array.map (fun x -> x * 2) arr; (* 映射：每个元素翻倍 *)
  Array.fold_left (+) 0 arr;      (* 折叠：求和 *)
  Array.sort compare arr;         (* 原地排序：[| 1; 2; 3; 5; 8; 9 |] *)
  Array.to_list arr;              (* 转成列表 *)
  Array.of_list [1; 2; 3]         (* 列表转数组 *)
```

注意 `Array.sort` 是**原地排序**（in-place），它会直接修改数组，而不是返回新数组。这和 `List.sort` 不同——列表不可变，所以 `List.sort` 返回新列表。

### 18.6 Hashtbl 哈希表

哈希表（Hash table）是键值对的可变集合，提供平均 O(1) 的查找、插入、删除操作。

**创建哈希表**：

```ocaml
let table = Hashtbl.create 10    (* 初始容量为 10（只是提示，会自动扩容） *)
```

**添加和查找**：

```ocaml
let _ =
  Hashtbl.add table "alice" 95;    (* 添加键值对 *)
  Hashtbl.add table "bob" 87;
  Hashtbl.add table "charlie" 92;
  
  print_int (Hashtbl.find table "alice");   (* 95 —— 查找 *)
  (* Hashtbl.find table "dave"              找不到会抛出 Not_found 异常 *)
  
  print_bool (Hashtbl.mem table "bob");     (* true —— 检查是否存在 *)
  
  Hashtbl.replace table "alice" 98;         (* 替换（如果键已存在） *)
  Hashtbl.remove table "charlie";           (* 删除 *)
  
  Printf.printf "%d\n" (Hashtbl.length table)   (* 2 —— 元素个数 *)
```

注意 `Hashtbl.add` 和 `Hashtbl.replace` 的区别：
- `add` 是添加新绑定，旧绑定仍然存在（被遮蔽）
- `replace` 是替换已有绑定

大多数时候你应该用 `replace`，除非你特意想要「多层绑定」的行为。

**遍历哈希表**：

```ocaml
(* 遍历所有键值对 *)
Hashtbl.iter (fun k v -> Printf.printf "%s: %d\n" k v) table

(* 收集所有键 *)
let keys = Hashtbl.fold (fun k _ acc -> k :: acc) table []

(* 收集所有值 *)
let values = Hashtbl.fold (fun _ v acc -> v :: acc) table []
```

标准库的 `Hashtbl` 使用的是**结构相等**（`=`）和 `Hashtbl.hash` 作为默认的哈希函数。也就是说，两个内容相同的字符串会被认为是同一个键——这通常是你想要的行为。

### 18.7 Buffer 可变字符串缓冲

OCaml 中的字符串（`string`）是不可变的。如果你需要频繁拼接字符串，比如构建一个长文本，每次拼接都会分配新字符串，效率很低。

`Buffer` 模块提供了可变的字符串缓冲区，类似于 Java 的 `StringBuilder`。

```ocaml
let buf = Buffer.create 100      (* 创建一个初始容量为 100 的缓冲区 *)

let _ =
  Buffer.add_string buf "Hello";
  Buffer.add_char buf ' ';
  Buffer.add_string buf "world";
  Buffer.add_string buf "!";
  let s = Buffer.contents buf in  (* 获取最终字符串 *)
  print_endline s                 (* "Hello world!" *)
```

`Buffer` 的优势是：它内部用一个可扩容的字节数组来存储数据，追加操作是均摊 O(1) 的，比反复字符串拼接高效得多。

### 18.8 物理相等 vs 结构相等

OCaml 中有两种相等性比较，初学者很容易混淆。

**结构相等（=、<>）**：比较两个值的「内容」是否相同。

```ocaml
let _ =
  [1; 2; 3] = [1; 2; 3];    (* true —— 内容相同 *)
  "hello" = "hello";        (* true *)
  [| 1; 2 |] = [| 1; 2 |]   (* true —— 数组的内容相同 *)
```

**物理相等（==、!=）**：比较两个值是否存储在同一块内存地址上。

```ocaml
let _ =
  let a = [1; 2; 3] in
  let b = [1; 2; 3] in
  a == b;                   (* false —— 两个不同的列表对象 *)
  
  let c = a in
  a == c                    (* true —— 同一个对象 *)
```

对于不可变值（整数、字符串、列表），你几乎总是应该用结构相等（`=`）。物理相等（`==`）对于不可变值来说意义不大——因为值不可变，内容相同就够了，它们是不是同一个内存地址不重要。

对于可变值（ref、数组、记录的可变字段），物理相等和结构相等的区别就很重要了：

```ocaml
let _ =
  let r1 = ref 0 in
  let r2 = ref 0 in
  r1 = r2;     (* true —— 内容都是 0，结构相等 *)
  r1 == r2     (* false —— 是两个不同的引用，物理不等 *)
```

如果你想判断「这两个引用是不是同一个引用」（即修改 r1 会不会影响 r2），就用 `==`。如果你只是想判断「它们当前的值是否相同」，就用 `=`。

**Hashtbl 的键比较**：标准库的 `Hashtbl` 默认使用结构相等（`=`）和结构哈希。也就是说，两个内容相同的字符串会被认为是同一个键。这通常是你想要的。但如果你需要物理相等的哈希表（用对象的身份而不是内容做键），可以用 `Hashtbl.Make`  functor 自定义哈希函数。

### 18.9 闭包封装可变状态

第 13 章我们讲过闭包，现在结合可变状态，闭包可以实现更强大的状态封装。

```ocaml
let make_bank_account initial_balance =
  let balance = ref initial_balance in
  object
    method deposit amount =
      if amount > 0 then balance := !balance + amount
      else failwith "deposit amount must be positive"
    method withdraw amount =
      if amount > 0 && amount <= !balance then
        (balance := !balance - amount; amount)
      else failwith "insufficient funds or invalid amount"
    method get_balance = !balance
  end
```

（这个例子用了对象，我们还没讲对象系统，但核心思想是一样的——`balance` 被闭包捕获，外部只能通过方法来访问和修改。）

更简洁的版本，用闭包返回多个函数：

```ocaml
let make_counter () =
  let count = ref 0 in
  let increment () = incr count in
  let get () = !count in
  let reset () = count := 0 in
  (increment, get, reset)

(* 使用 *)
let inc, get, reset = make_counter ()
let _ =
  inc (); inc (); inc ();
  Printf.printf "%d\n" (get ());   (* 3 *)
  reset ();
  Printf.printf "%d\n" (get ())    (* 0 *)
```

这种模式的好处是：`count` 完全被封装在闭包内部，外部无法直接访问，只能通过你提供的接口函数来操作。这是一种轻量级的封装方式，不需要定义模块和签名。

### 18.10 为什么 OCaml 不鼓励可变状态但又提供它

你可能会问：既然函数式编程推崇不可变，为什么 OCaml 还要提供 `ref`、`Array`、`Hashtbl` 这些可变数据结构？

答案是**实用主义**。OCaml 的设计者认为：

1. **默认不可变是对的**：大多数代码用不可变数据写更清晰、更容易推理、更少 bug
2. **但有时候你确实需要可变**：性能、算法复杂度、与外部世界交互（I/O）
3. **让可变状态显式化**：可变的东西需要特殊语法（`:=`、`<-`、`!`），一眼就能看出来哪里有副作用

所以 OCaml 的策略是：默认不可变，可变需要明确写出来。你可以从代码中一眼看出哪些地方有副作用——那些 `:=`、`<-`、`!` 就是「危险信号」。

这和 Java 正好相反——Java 中默认是可变的，你需要加 `final` 才能让东西不可变。结果就是 Java 代码中到处都是可变状态，你根本不知道哪里会修改东西。

### 18.11 本章小结

- `ref` 是最基本的可变引用：`ref x` 创建，`!r` 读取，`r := x` 赋值
- `ref` 的本质是一个带可变字段的记录 `{ mutable contents : 'a }`
- 记录字段默认不可变，用 `mutable` 声明可变字段，赋值用 `<-`
- `Array` 提供 O(1) 随机访问和原地修改，用 `arr.(i)` 访问，`arr.(i) <- x` 修改
- `Hashtbl` 是可变的键值对集合，平均 O(1) 查找插入
- `Buffer` 是可变字符串缓冲，适合频繁拼接的场景
- 结构相等 `=` 比较内容，物理相等 `==` 比较内存地址
- 对于不可变值用 `=`，要判断是否是同一个可变对象时用 `==`
- 闭包可以封装可变状态，实现轻量级的信息隐藏
- OCaml 默认不可变，可变需要显式语法，让副作用一目了然

---

## 第 19 章 排序与经典算法

对应示例：`examples/15_algorithms.ml`

### 19.1 函数式算法的思考方式

学习算法时，OCaml 的函数式风格能让你更专注于「做什么」而不是「怎么做」。

命令式算法的典型模式是：初始化变量 -> 循环修改 -> 得到结果。你需要跟踪每一步的状态变化。

函数式算法的典型模式是：递归分解 -> 组合子问题的解 -> 得到结果。你需要思考的是问题的结构，而不是执行的步骤。

我们通过几个经典算法来体会这种差异。

### 19.2 插入排序

插入排序的思路很简单：把列表分成「已排序」和「未排序」两部分，依次把未排序的元素插入到已排序部分的正确位置。

**函数式版本**：

```ocaml
(* 将 x 插入到已排序列表 lst 的正确位置 *)
let rec insert x = function
  | [] -> [x]
  | h :: t as lst ->
      if x <= h then x :: lst
      else h :: insert x t

(* 插入排序主函数 *)
let rec insertion_sort = function
  | [] -> []
  | h :: t -> insert h (insertion_sort t)
```

这个版本非常简洁，几乎就是算法的数学定义：
- 空列表已经排序好了
- 对于非空列表，先排好尾部，然后把头部插入进去

时间复杂度是 O(n^2)，空间复杂度是 O(n)（因为每次都创建新列表）。

**命令式版本（使用数组）**：

```ocaml
let insertion_sort_array arr =
  let n = Array.length arr in
  for i = 1 to n - 1 do
    let key = arr.(i) in
    let j = ref (i - 1) in
    while !j >= 0 && arr.(!j) > key do
      arr.(!j + 1) <- arr.(!j);
      decr j
    done;
    arr.(!j + 1) <- key
  done;
  arr
```

命令式版本更长，你需要跟踪索引 i 和 j，需要手动移动元素。但它是原地排序，不需要额外空间。

**对比**：函数式版本更清晰地表达了算法的本质，但有额外的内存分配。命令式版本更高效，但代码更繁琐、更容易出错。

### 19.3 归并排序

归并排序是分治算法的经典例子。思路：
1. 把列表分成两半
2. 分别排序两半
3. 把两个有序列表合并成一个

```ocaml
(* 合并两个有序列表 *)
let rec merge a b =
  match (a, b) with
  | ([], _) -> b
  | (_, []) -> a
  | (x :: xs, y :: ys) ->
      if x <= y then x :: merge xs b
      else y :: merge a ys

(* 归并排序 *)
let rec merge_sort = function
  | [] -> []
  | [x] -> [x]
  | lst ->
      let rec split n lst =
        if n = 0 then ([], lst)
        else match lst with
          | [] -> ([], [])
          | h :: t ->
              let (left, right) = split (n - 1) t in
              (h :: left, right)
      in
      let half = List.length lst / 2 in
      let (left, right) = split half lst in
      merge (merge_sort left) (merge_sort right)
```

时间复杂度：O(n log n)，因为每次递归列表长度减半（log n 层），每层合并需要 O(n)。

归并排序的函数式实现非常优雅——它直接对应了算法的递归描述。缺点是需要额外的空间来存储中间结果（不像快速排序可以原地进行）。

### 19.4 快速排序

快速排序也是分治算法。思路：
1. 选一个基准元素（pivot）
2. 把小于等于 pivot 的放左边，大于 pivot 的放右边
3. 分别对左右两边排序

**函数式版本**：

```ocaml
let rec quick_sort = function
  | [] -> []
  | pivot :: rest ->
      let left = List.filter (fun x -> x <= pivot) rest in
      let right = List.filter (fun x -> x > pivot) rest in
      quick_sort left @ [pivot] @ quick_sort right
```

这个版本极其简洁——几乎就是快速排序的定义本身。

但它有几个问题：
1. 效率不高：两次遍历列表（两次 filter），而且 `@` 操作是 O(n) 的
2. 空间复杂度高：每次都创建新的列表
3. 基准选择简单：总是选第一个元素，如果输入已经有序，时间复杂度退化为 O(n^2)

**命令式版本（原地快速排序）**：

```ocaml
let quick_sort_array arr =
  let swap i j =
    let tmp = arr.(i) in
    arr.(i) <- arr.(j);
    arr.(j) <- tmp
  in
  let rec partition lo hi =
    let pivot = arr.(hi) in
    let i = ref (lo - 1) in
    for j = lo to hi - 1 do
      if arr.(j) <= pivot then (
        incr i;
        swap !i j
      )
    done;
    swap (!i + 1) hi;
    !i + 1
  in
  let rec qsort lo hi =
    if lo < hi then
      let p = partition lo hi in
      qsort lo (p - 1);
      qsort (p + 1) hi
  in
  qsort 0 (Array.length arr - 1);
  arr
```

命令式版本原地排序，空间复杂度 O(log n)（栈空间），平均时间复杂度 O(n log n)。但代码明显更长，而且更容易写错（索引边界、swap 逻辑等）。

**函数式 vs 命令式的取舍**：

函数式快速排序代码简洁、易于理解，但性能不如原地版本。在实际工程中：
- 如果数据量不大，用函数式版本完全没问题
- 如果数据量大且性能关键，用 `Array.sort`（标准库的原地排序）
- 大多数时候，你不需要自己写排序算法，直接用标准库的就行

### 19.5 二分查找

二分查找是在有序数组中查找元素的经典算法，时间复杂度 O(log n)。

```ocaml
let binary_search arr target =
  let rec search lo hi =
    if lo > hi then None
    else
      let mid = lo + (hi - lo) / 2 in   (* 防止溢出 *)
      if arr.(mid) = target then Some mid
      else if arr.(mid) < target then search (mid + 1) hi
      else search lo (mid - 1)
  in
  search 0 (Array.length arr - 1)
```

这个版本用递归实现，非常清晰。每一步比较中间元素，然后决定去左半边还是右半边找。

```ocaml
let arr = [| 1; 3; 5; 7; 9; 11; 13; 15 |]
let _ =
  binary_search arr 7;    (* Some 3 —— 找到了，索引是 3 *)
  binary_search arr 4     (* None —— 没找到 *)
```

注意计算 `mid` 用的是 `lo + (hi - lo) / 2` 而不是 `(lo + hi) / 2`。后者在 `lo + hi` 很大时可能溢出（虽然 OCaml 的 int 是任意精度的不会溢出，但这是一个好的编程习惯，在其他语言中很重要）。

### 19.6 埃拉托斯特尼筛法

埃拉托斯特尼筛法（Sieve of Eratosthenes）是求素数的经典算法。思路：从 2 开始，把每个素数的倍数都标记为合数，最后剩下的就是素数。

这个算法天然适合用数组（因为需要随机访问和原地修改）。

```ocaml
let sieve n =
  if n < 2 then [||]
  else
    let is_prime = Array.make (n + 1) true in
    is_prime.(0) <- false;
    is_prime.(1) <- false;
    let i = ref 2 in
    while !i * !i <= n do
      if is_prime.(!i) then
        (* 把 i 的倍数都标记为非素数，从 i*i 开始（更小的倍数已经被标记过了） *)
        let j = ref (!i * !i) in
        while !j <= n do
          is_prime.(!j) <- false;
          j := !j + !i
        done;
      incr i
    done;
    (* 收集所有素数 *)
    let primes = ref [] in
    for k = n downto 2 do
      if is_prime.(k) then primes := k :: !primes
    done;
    Array.of_list !primes
```

```ocaml
let _ =
  let primes = sieve 30 in
  Array.iter (Printf.printf "%d ") primes;   (* 2 3 5 7 11 13 17 19 23 29 *)
  print_newline ()
```

筛法是一个典型的「用可变数组更自然」的算法。你当然可以用纯函数式的方式实现（比如用列表或函数式的惰性序列），但代码会复杂得多，效率也更低。

### 19.7 gcd 与 lcm

**最大公约数（gcd）** 用欧几里得算法：

```ocaml
let rec gcd a b =
  if b = 0 then abs a
  else gcd b (a mod b)
```

这个算法的时间复杂度是 O(log(min(a, b)))，非常高效。

**最小公倍数（lcm）** 可以用 gcd 来算：

```ocaml
let lcm a b =
  if a = 0 || b = 0 then 0
  else abs (a * b) / gcd a b
```

注意 `a * b` 可能溢出——在 OCaml 中 int 是固定精度的（63 位或 31 位），如果 a 和 b 都很大，乘积可能超出范围。对于大数应该用 `Zarith` 库的任意精度整数。

### 19.8 记忆化（Memoization）

记忆化是一种优化技术：把函数的计算结果缓存起来，下次调用同样的参数时直接返回缓存的结果，避免重复计算。

我们用斐波那契数列来演示。朴素的递归版本是 O(2^n) 的，因为有大量重复计算：

```ocaml
let rec fib n =
  if n <= 1 then n
  else fib (n - 1) + fib (n - 2)
```

用 Hashtbl 实现记忆化：

```ocaml
let memo_fib =
  let cache = Hashtbl.create 100 in
  let rec fib n =
    match Hashtbl.find_opt cache n with
    | Some result -> result
    | None ->
        let result =
          if n <= 1 then n
          else fib (n - 1) + fib (n - 2)
        in
        Hashtbl.add cache n result;
        result
  in
  fib
```

```ocaml
let _ =
  memo_fib 10;    (* 55 —— 计算并缓存 *)
  memo_fib 10;    (* 55 —— 直接从缓存取 *)
  memo_fib 20     (* 6765 —— 可以算更大的数了 *)
```

记忆化后的斐波那契时间复杂度变成 O(n)（每个 n 只算一次），空间复杂度也是 O(n)（缓存了 n 个结果）。

**更通用的记忆化函数**：

我们可以写一个通用的 memoize 函数，给任意函数加上记忆化：

```ocaml
let memoize f =
  let cache = Hashtbl.create 100 in
  fun x ->
    match Hashtbl.find_opt cache x with
    | Some result -> result
    | None ->
        let result = f x in
        Hashtbl.add cache x result;
        result
```

但要注意：这个版本只能用于单参数函数。对于多参数函数，需要先把参数打包成元组。而且对于递归函数，直接 memoize 不会工作——因为递归调用的是原始函数，不是记忆化后的版本。要让递归函数也享受记忆化，需要用「不动点组合子」或者像上面的 `memo_fib` 那样手动在递归函数内部使用缓存。

### 19.9 算法的函数式思考方式

学习了这么多算法，我们来总结一下函数式算法的思考模式：

**1. 关注问题结构，而非执行步骤**

函数式编程中，你思考的是「这个问题可以分解成什么样的子问题」，而不是「第一步做什么、第二步做什么」。递归是这种思维方式的直接体现。

**2. 不可变性简化了推理**

纯函数式算法中，数据是不可变的。你不用担心某个值在别处被修改了——你创建的列表就是那个样子，不会变。这让代码更容易推理和调试。

**3. 用高阶函数抽象模式**

`map`、`filter`、`fold` 这些高阶函数本身就是算法模式的抽象。很多算法都可以用它们来组合实现，而不需要从头写递归。

**4. 什么时候用命令式**

当你真正需要性能时，或者当算法天然就是原地修改的（比如筛法、原地排序），就用可变数据结构。但要把可变的部分封装起来，对外暴露纯函数式的接口。

### 19.10 本章小结

- 插入排序：简单直观，O(n^2)，适合小规模数据
- 归并排序：分治思想，O(n log n)，函数式实现优雅
- 快速排序：平均 O(n log n)，原地版本更高效但代码更复杂
- 二分查找：O(log n)，需要有序数组，递归实现清晰
- 埃拉托斯特尼筛法：求素数的经典算法，天然适合用数组
- gcd 用欧几里得算法，lcm = a*b/gcd(a,b)
- 记忆化用 Hashtbl 缓存计算结果，把指数复杂度降到多项式
- 函数式算法关注问题结构，命令式算法关注执行步骤
- 优先用函数式写法，性能关键时再考虑可变数据结构

---

## 第 20 章 数值计算

对应示例：`examples/16_numeric.ml`

### 20.1 数值计算中的函数式思维

数值计算通常被认为是「命令式的领地」——到处都是循环、数组、原地修改。但 OCaml 的函数式风格同样可以用来写数值计算代码，而且往往更清晰。

关键在于：把每个计算步骤看作一个从输入到输出的纯函数，然后用函数组合和递归来搭建复杂的计算。

### 20.2 二分法求根

二分法（Bisection Method）是求函数零点的最简单、最可靠的方法。前提是函数在区间 [a, b] 上连续，且 f(a) 和 f(b) 异号（根据中间值定理，区间内至少有一个根）。

算法：
1. 取区间中点 c = (a+b)/2
2. 计算 f(c)
3. 如果 f(c) 和 f(a) 异号，根在 [a, c]，否则根在 [c, b]
4. 重复直到区间足够小

```ocaml
let bisection f a b tolerance =
  let rec loop a b fa fb =
    let c = (a +. b) /. 2.0 in
    let fc = f c in
    if abs_float (b -. a) < tolerance then c
    else if fa *. fc < 0.0 then
      loop a c fa fc
    else
      loop c b fc fb
  in
  loop a b (f a) (f b)
```

这是一个典型的尾递归实现。`loop` 函数维护当前的区间 [a, b] 和两端的函数值 fa、fb，每次迭代缩小区间一半。

```ocaml
(* 求 x^3 - x - 2 = 0 在 [1, 2] 之间的根 *)
let _ =
  let root = bisection (fun x -> x ** 3. -. x -. 2.) 1.0 2.0 1e-6 in
  Printf.printf "Root: %.6f\n" root   (* 约 1.521380 *)
```

### 20.3 牛顿法求根

牛顿法（Newton's Method）是一种更快的求根方法，它利用函数的导数来加速收敛。

迭代公式：x_{n+1} = x_n - f(x_n) / f'(x_n)

```ocaml
let newton_method f f' x0 tolerance max_iter =
  let rec loop x i =
    if i >= max_iter then x
    else
      let fx = f x in
      if abs_float fx < tolerance then x
      else
        let f'x = f' x in
        if abs_float f'x < 1e-12 then failwith "derivative too close to zero"
        else loop (x -. fx /. f'x) (i + 1)
  in
  loop x0 0
```

参数：
- `f`：目标函数
- `f'`：f 的导函数
- `x0`：初始猜测
- `tolerance`：精度要求
- `max_iter`：最大迭代次数（防止发散）

```ocaml
(* 同样求 x^3 - x - 2 = 0 的根 *)
let _ =
  let f x = x ** 3. -. x -. 2. in
  let f' x = 3. *. x ** 2. -. 1. in
  let root = newton_method f f' 2.0 1e-10 50 in
  Printf.printf "Newton root: %.10f\n" root   (* 约 1.5213797068 *)
```

牛顿法的收敛速度是二次的——每次迭代有效位数大约翻倍。但它需要你提供导数，而且初始值不好的话可能不收敛。

**数值微分**：如果你不想手动求导，可以用数值微分来近似：

```ocaml
let numerical_derivative f x h =
  (f (x +. h) -. f (x -. h)) /. (2.0 *. h)

let newton_numerical f x0 tolerance max_iter =
  let f' x = numerical_derivative f x 1e-6 in
  newton_method f f' x0 tolerance max_iter
```

数值微分简单但有精度问题——h 太小会有舍入误差，太大又有截断误差。

### 20.4 梯形积分法

积分的几何意义是函数曲线下的面积。梯形法（Trapezoidal Rule）用小梯形来近似每个区间的面积。

公式：∫_a^b f(x) dx ≈ (h/2) * [f(x_0) + 2f(x_1) + 2f(x_2) + ... + 2f(x_{n-1}) + f(x_n)]

其中 h = (b-a)/n，x_i = a + i*h。

```ocaml
let trapezoidal_integral f a b n =
  let h = (b -. a) /. float_of_int n in
  let rec loop i sum =
    if i >= n then sum
    else
      let x = a +. float_of_int i *. h in
      loop (i + 1) (sum +. f x)
  in
  let sum_middle = loop 1 0.0 in  (* 中间的点（x_1 到 x_{n-1}） *)
  h *. (0.5 *. f a +. sum_middle +. 0.5 *. f b)
```

```ocaml
(* 计算 ∫_0^1 x^2 dx = 1/3 ≈ 0.333333 *)
let _ =
  let result = trapezoidal_integral (fun x -> x *. x) 0.0 1.0 100 in
  Printf.printf "Trapezoidal integral: %.6f\n" result   (* 约 0.333350 *)
```

梯形法的误差是 O(h^2)，即把 n 翻倍，误差大约减少到 1/4。

### 20.5 辛普森积分法

辛普森法（Simpson's Rule）用抛物线近似函数曲线，精度比梯形法更高。

公式：∫_a^b f(x) dx ≈ (h/3) * [f(x_0) + 4f(x_1) + 2f(x_2) + 4f(x_3) + ... + 4f(x_{n-1}) + f(x_n)]

其中 n 必须是偶数。

```ocaml
let simpson_integral f a b n =
  if n mod 2 <> 0 then failwith "n must be even"
  else
    let h = (b -. a) /. float_of_int n in
    let rec loop i sum =
      if i >= n then sum
      else
        let x = a +. float_of_int i *. h in
        let weight = if i mod 2 = 0 then 2.0 else 4.0 in
        loop (i + 1) (sum +. weight *. f x)
    in
    let sum_middle = loop 1 0.0 in
    h /. 3.0 *. (f a +. sum_middle +. f b)
```

```ocaml
let _ =
  let result = simpson_integral (fun x -> x *. x) 0.0 1.0 100 in
  Printf.printf "Simpson integral: %.6f\n" result   (* 约 0.333333 —— 几乎精确 *)
```

辛普森法的误差是 O(h^4)，收敛快得多。对于光滑函数，辛普森法通常比梯形法高效很多。

### 20.6 克拉默法则解线性方程组

克拉默法则（Cramer's Rule）是解线性方程组的一种方法。对于方程组 Ax = b，解的每个分量是 x_i = det(A_i) / det(A)，其中 A_i 是把 A 的第 i 列换成 b 得到的矩阵。

先实现行列式计算（用递归展开）：

```ocaml
let rec determinant matrix =
  let n = Array.length matrix in
  if n = 0 then 1.0
  else if n = 1 then matrix.(0).(0)
  else if n = 2 then
    matrix.(0).(0) *. matrix.(1).(1) -. matrix.(0).(1) *. matrix.(1).(0)
  else
    let rec sum acc j =
      if j >= n then acc
      else
        (* 构造去掉第 0 行第 j 列的子矩阵 *)
        let sub = Array.make_matrix (n - 1) (n - 1) 0.0 in
        for i' = 1 to n - 1 do
          let col = ref 0 in
          for j' = 0 to n - 1 do
            if j' <> j then (
              sub.(i' - 1).(!col) <- matrix.(i').(j');
              incr col
            )
          done
        done;
        let sign = if j mod 2 = 0 then 1.0 else -1.0 in
        sum (acc +. sign *. matrix.(0).(j) *. determinant sub) (j + 1)
    in
    sum 0.0 0
```

然后用克拉默法则：

```ocaml
let cramer a b =
  let n = Array.length a in
  let det_a = determinant a in
  if abs_float det_a < 1e-12 then failwith "singular matrix"
  else
    let solution = Array.make n 0.0 in
    for i = 0 to n - 1 do
      (* 构造 A_i：把第 i 列换成 b *)
      let a_i = Array.make_matrix n n 0.0 in
      for row = 0 to n - 1 do
        for col = 0 to n - 1 do
          a_i.(row).(col) <-
            if col = i then b.(row) else a.(row).(col)
        done
      done;
      solution.(i) <- determinant a_i /. det_a
    done;
    solution
```

```ocaml
(* 解方程组：
   2x + y - z = 8
   -3x - y + 2z = -11
   -2x + y + 2z = -3
*)
let _ =
  let a = [|
    [| 2.0; 1.0; -1.0 |];
    [| -3.0; -1.0; 2.0 |];
    [| -2.0; 1.0; 2.0 |]
  |] in
  let b = [| 8.0; -11.0; -3.0 |] in
  let x = cramer a b in
  Printf.printf "Solution: x=%.2f, y=%.2f, z=%.2f\n" x.(0) x.(1) x.(2)
  (* 应该是 x=2, y=3, z=-1 *)
```

注意：克拉默法则虽然简洁，但时间复杂度是 O(n!)，只适用于非常小的方程组（n <= 3）。对于大规模方程组，应该用高斯消元法等 O(n^3) 的算法。

### 20.7 拉格朗日插值

拉格朗日插值（Lagrange Interpolation）是一种多项式插值方法：给定 n+1 个点 (x_0,y_0), ..., (x_n, y_n)，构造一个 n 次多项式经过所有这些点。

公式：L(x) = Σ_{i=0}^n y_i * l_i(x)，其中 l_i(x) = Π_{j≠i} (x - x_j) / (x_i - x_j)

```ocaml
let lagrange_interpolate xs ys x =
  let n = Array.length xs in
  let rec lagrange_basis i j prod =
    if j >= n then prod
    else if j = i then lagrange_basis i (j + 1) prod
    else
      let term = (x -. xs.(j)) /. (xs.(i) -. xs.(j)) in
      lagrange_basis i (j + 1) (prod *. term)
  in
  let rec sum i acc =
    if i >= n then acc
    else
      let li = lagrange_basis i 0 1.0 in
      sum (i + 1) (acc +. ys.(i) *. li)
  in
  sum 0 0.0
```

```ocaml
(* 已知 sin(0)=0, sin(π/6)=0.5, sin(π/2)=1
   用拉格朗日插值估计 sin(π/4) ≈ 0.7071 *)
let _ =
  let pi = 3.14159265358979 in
  let xs = [| 0.0; pi /. 6.0; pi /. 2.0 |] in
  let ys = [| 0.0; 0.5; 1.0 |] in
  let result = lagrange_interpolate xs ys (pi /. 4.0) in
  Printf.printf "Lagrange interpolation of sin(π/4): %.6f\n" result
```

### 20.8 浮点数的三大坑

浮点数看起来简单，但有很多陷阱。了解这些坑可以帮你避免很多难以调试的 bug。

**坑一：精度问题**

浮点数（IEEE 754 双精度）只有大约 15-17 位有效数字。不是所有的十进制小数都能精确表示。

```ocaml
let _ =
  0.1 +. 0.2 = 0.3     (* false！ *)
```

为什么？因为 0.1 和 0.2 在二进制浮点数中都是无限循环小数，存储时有舍入误差。加起来的结果和 0.3 的二进制表示不完全一样。

**坑二：舍入误差累积**

每次浮点运算都可能有一点点误差，这些误差会累积。

```ocaml
let rec sum_loop i acc =
  if i >= 10000 then acc
  else sum_loop (i + 1) (acc +. 0.1)

let _ =
  let result = sum_loop 0 0.0 in
  result = 1000.0    (* false！实际值略小于 1000.0 *)
```

加 10000 次 0.1，结果不是精确的 1000.0，因为每次加法都有一点点误差。

**坑三：比较的陷阱**

因为有精度问题，你几乎不应该用 `=` 直接比较两个浮点数是否相等。你应该用「近似相等」——检查它们的差是否在某个容差范围内。

```ocaml
let (~=.) a b =
  abs_float (a -. b) < 1e-9 *. max 1.0 (max (abs_float a) (abs_float b))
```

这个版本用了相对容差，对于大数和小数都比较合理。

### 20.9 OCaml 中浮点数的特殊值

OCaml 的浮点数遵循 IEEE 754 标准，有几个特殊值：

**nan（Not a Number）**：表示未定义的运算结果，比如 0.0 /. 0.0、sqrt (-1.0)。

```ocaml
let _ =
  0.0 /. 0.0;         (* nan *)
  sqrt (-1.0);        (* nan *)
  nan = nan;          (* false —— nan 不等于任何东西，包括它自己！ *)
  nan <> nan;         (* true  —— 对，nan 不等于自己 *)
```

nan 有一个非常反直觉的性质：**nan 不等于自己**。这是 IEEE 754 标准规定的。判断一个值是不是 nan，可以用 `Float.is_nan`（OCaml 4.07+）或者 `x <> x` 这个技巧。

**infinity 和 neg_infinity**：正无穷和负无穷。

```ocaml
let _ =
  1.0 /. 0.0;          (* infinity *)
  -1.0 /. 0.0;         (* neg_infinity *)
  infinity +. 1.0;     (* infinity *)
  1.0 /. infinity;     (* 0.0 *)
  infinity = infinity  (* true *)
```

### 20.10 浮点数比较的正确姿势

总结一下浮点数比较的最佳实践：

1. **永远不要用 `=` 比较浮点数是否相等**，除非你确切知道你在做什么
2. **用 epsilon 比较**：检查 `abs_float (a -. b) < epsilon`
3. **选择合适的 epsilon**：取决于你的应用场景，通常 1e-9 到 1e-12 对于双精度比较合适
4. **考虑相对误差**：对于很大的数，绝对误差可能不够；可以用 `abs_float (a -. b) < epsilon *. max (abs_float a) (abs_float b)`
5. **注意 nan**：任何和 nan 的比较都会返回 false（除了 `<>` 返回 true）
6. **用 `Float.compare` 而不是 `compare`**：`Float.compare` 对 nan 有明确定义

```ocaml
(* 一个比较完善的浮点数近似相等函数 *)
let approx_equal ?(epsilon = 1e-9) a b =
  if Float.is_nan a || Float.is_nan b then false
  else if a = b then true   (* 处理无穷大和精确相等的情况 *)
  else
    let diff = abs_float (a -. b) in
    if diff < epsilon then true
    else
      let max_val = max (abs_float a) (abs_float b) in
      diff < epsilon *. max_val
```

### 20.11 本章小结

- 二分法求根：简单可靠，需要区间端点异号，收敛速度线性
- 牛顿法求根：收敛速度快（二次），需要导数，初始值不好可能不收敛
- 梯形积分法：O(h^2) 误差，简单直观
- 辛普森积分法：O(h^4) 误差，对于光滑函数效率更高
- 克拉默法则：解线性方程组，简洁但复杂度高（O(n!)），只适合小型方程组
- 拉格朗日插值：构造经过给定点的多项式
- 浮点数三大坑：精度、舍入误差累积、比较
- 浮点数特殊值：nan（不等于自己）、infinity、neg_infinity
- 浮点数比较要用 epsilon，不要直接用 `=`

---

## 第 21 章 解析：词法分析与递归下降

对应示例：`examples/17_parsing.ml`

### 21.1 什么是解析

解析（parsing）是把一段文本（源代码、数据文件、配置文件等）转换成结构化数据的过程。它是编译器、解释器、数据处理工具的核心组件。

解析通常分为两个阶段：

1. **词法分析（Lexical Analysis）**：把输入字符串切分成一个个 token（标记）。比如把 `"1 + 2 * 3"` 切分成 `[NUM(1); PLUS; NUM(2); MUL; NUM(3)]`。

2. **语法分析（Syntactic Analysis）**：把 token 流按照语法规则组织成抽象语法树（AST）或直接计算出结果。

为什么要分成两步？因为这样每一步都更简单：
- 词法器只关心单个字符和简单模式（数字、标识符、运算符）
- 语法分析器只关心 token 之间的结构关系，不用管空白、注释、数字怎么解析

### 21.2 定义 Token 类型

我们用变体类型来定义 token。以算术表达式为例：

```ocaml
type token =
  | NUM of float       (* 数字字面量 *)
  | PLUS               (* + *)
  | MINUS              (* - *)
  | MUL                (* * *)
  | DIV                (* / *)
  | LPAREN             (* ( *)
  | RPAREN             (* ) *)
  | EOF                (* 输入结束 *)
```

每个变体构造子对应一种语法单位。`NUM` 携带一个 float 参数，表示具体的数值。`EOF` 标记输入结束，帮助解析器判断何时停止。

用变体类型定义 token 的好处：
- 编译器可以检查模式匹配是否穷尽
- 每个 token 的类型信息一目了然
- 添加新 token 很方便

### 21.3 手写词法器（Lexer）

词法器（也叫 tokenizer）的任务是把输入字符串转换成 token 列表。

基本思路：
- 维护一个当前位置指针
- 跳过空白字符（空格、制表符、换行）
- 根据当前字符判断是什么 token
- 数字：读入连续的数字和小数点，转成 float
- 运算符和括号：单个字符对应一个 token

```ocaml
let lex input =
  let n = String.length input in
  let pos = ref 0 in
  let tokens = ref [] in

  (* 跳过空白字符 *)
  let skip_whitespace () =
    while !pos < n && (input.[!pos] = ' ' || input.[!pos] = '\t' ||
                       input.[!pos] = '\n' || input.[!pos] = '\r') do
      incr pos
    done
  in

  (* 读取数字（整数或小数） *)
  let read_number () =
    let start = !pos in
    while !pos < n && (input.[!pos] >= '0' && input.[!pos] <= '9') do
      incr pos
    done;
    if !pos < n && input.[!pos] = '.' then begin
      incr pos;
      while !pos < n && (input.[!pos] >= '0' && input.[!pos] <= '9') do
        incr pos
      done
    end;
    let num_str = String.sub input start (!pos - start) in
    NUM (float_of_string num_str)
  in

  (* 主循环：逐个 token 读取 *)
  let rec tokenize () =
    skip_whitespace ();
    if !pos >= n then
      List.rev (EOF :: !tokens)
    else
      let c = input.[!pos] in
      let token =
        match c with
        | '0'..'9' -> read_number ()
        | '+' -> incr pos; PLUS
        | '-' -> incr pos; MINUS
        | '*' -> incr pos; MUL
        | '/' -> incr pos; DIV
        | '(' -> incr pos; LPAREN
        | ')' -> incr pos; RPAREN
        | _ -> failwith (Printf.sprintf "unexpected character '%c' at position %d" c !pos)
      in
      tokens := token :: !tokens;
      tokenize ()
  in
  tokenize ()
```

测试一下：

```ocaml
let _ =
  let tokens = lex "1 + 2 * 3" in
  (* [NUM 1.0; PLUS; NUM 2.0; MUL; NUM 3.0; EOF] *)
  List.iter (function
    | NUM n -> Printf.printf "NUM(%.1f) " n
    | PLUS -> print_string "PLUS "
    | MINUS -> print_string "MINUS "
    | MUL -> print_string "MUL "
    | DIV -> print_string "DIV "
    | LPAREN -> print_string "LPAREN "
    | RPAREN -> print_string "RPAREN "
    | EOF -> print_string "EOF\n"
  ) tokens
```

词法器用了可变状态（`pos` 引用、`tokens` 引用）来跟踪进度。这是一个典型的「用命令式风格实现更自然」的场景——词法分析本质上就是逐字符扫描、维护状态。

### 21.4 递归下降解析器的原理

递归下降（Recursive Descent）是手写解析器最常用的方法。它的思路很简单：

1. 为每个语法规则写一个函数
2. 函数之间可以互相调用（对应语法规则中的非终结符引用）
3. 函数自己调用自己（对应递归的语法规则）

算术表达式的语法规则（BNF 范式）：
```
expr   ::= term (('+' | '-') term)*
term   ::= factor (('*' | '/') factor)*
factor ::= NUM | '(' expr ')'
```

这个语法表达了运算符优先级：
- 乘除（`*`、`/`）的优先级高于加减（`+`、`-`）
- 括号可以改变优先级
- 同优先级从左到右结合

对应的递归下降解析器就有三个函数：`parse_expr`、`parse_term`、`parse_factor`，它们互相调用、自己调用自己。

### 21.5 手写递归下降求值器

我们来实现一个算术表达式求值器——它不构造 AST，而是边解析边计算结果。

首先，我们需要一个「当前 token 指针」的概念。解析器维护一个 token 列表和当前位置。

```ocaml
type parser_state = {
  tokens : token array;
  mutable pos : int;
}

let peek state = state.tokens.(state.pos)
let advance state = state.pos <- state.pos + 1
let expect state token msg =
  if peek state <> token then
    failwith (Printf.sprintf "expected %s, got %s at position %d"
                msg "?" state.pos)
  else advance state
```

然后按照语法规则写三个解析函数：

```ocaml
let rec parse_expr state =
  let left = parse_term state in
  parse_expr_rest state left

and parse_expr_rest state acc =
  match peek state with
  | PLUS ->
      advance state;
      let right = parse_term state in
      parse_expr_rest state (acc +. right)
  | MINUS ->
      advance state;
      let right = parse_term state in
      parse_expr_rest state (acc -. right)
  | _ -> acc

and parse_term state =
  let left = parse_factor state in
  parse_term_rest state left

and parse_term_rest state acc =
  match peek state with
  | MUL ->
      advance state;
      let right = parse_factor state in
      parse_term_rest state (acc *. right)
  | DIV ->
      advance state;
      let right = parse_factor state in
      if right = 0.0 then failwith "division by zero"
      else parse_term_rest state (acc /. right)
  | _ -> acc

and parse_factor state =
  match peek state with
  | NUM n ->
      advance state;
      n
  | LPAREN ->
      advance state;
      let result = parse_expr state in
      expect state RPAREN "')'";
      result
  | _ -> failwith "unexpected token in factor"
```

注意这个结构：
- `parse_expr` 先解析一个 term，然后循环解析后续的 `+ term` 或 `- term`
- `parse_term` 先解析一个 factor，然后循环解析后续的 `* factor` 或 `/ factor`
- `parse_factor` 处理最基本的单位：数字或括号表达式

这种「先解析一个左操作数，再循环处理右操作数」的模式叫做**尾递归消除左递归**。直接写左递归的语法（`expr ::= expr '+' term`）会导致无限递归，所以我们把它改成了右递归 + 累加的形式。

最后，一个入口函数：

```ocaml
let eval input =
  let tokens = lex input in
  let state = { tokens = Array.of_list tokens; pos = 0 } in
  let result = parse_expr state in
  if peek state <> EOF then
    failwith "unexpected tokens after expression"
  else result
```

测试：

```ocaml
let _ =
  Printf.printf "1 + 2 * 3 = %.2f\n" (eval "1 + 2 * 3");   (* 7.00 *)
  Printf.printf "(1 + 2) * 3 = %.2f\n" (eval "(1 + 2) * 3"); (* 9.00 *)
  Printf.printf "10 - 2 * 3 + 4 / 2 = %.2f\n" (eval "10 - 2 * 3 + 4 / 2") (* 6.00 *)
```

### 21.6 错误的捕获与报告

解析器需要处理各种错误情况：非法字符、语法错误、括号不匹配等等。

上面的实现用了 `failwith` 来抛出异常，这是最简单的做法。但错误信息不够友好——用户只知道「出错了」，但不知道具体在哪里、为什么。

一个更好的做法是定义专门的解析异常，携带位置信息：

```ocaml
exception Parse_error of int * string   (* 位置, 错误信息 *)

let parse_error state msg =
  raise (Parse_error (state.pos, msg))
```

然后在顶层捕获异常，给出友好的错误信息：

```ocaml
let eval_safe input =
  try
    let tokens = lex input in
    let state = { tokens = Array.of_list tokens; pos = 0 } in
    let result = parse_expr state in
    if peek state <> EOF then
      Error "unexpected tokens after expression"
    else Ok result
  with
  | Failure msg -> Error msg
  | Parse_error (pos, msg) ->
      Error (Printf.sprintf "parse error at position %d: %s" pos msg)
```

这里我们用 `result` 类型（`Ok` 或 `Error`）来表示成功或失败，而不是让异常向上传播——这是一种更函数式的错误处理方式。

### 21.7 实战：词频统计

我们来写一个更实用的解析任务：统计一段文本中每个单词出现的次数。

```ocaml
let word_frequency text =
  let table = Hashtbl.create 100 in
  let n = String.length text in
  let i = ref 0 in

  while !i < n do
    (* 跳过非字母字符 *)
    while !i < n && not (text.[!i] |> function
      | 'a'..'z' | 'A'..'Z' | '0'..'9' | '\'' -> true
      | _ -> false) do
      incr i
    done;
    if !i < n then begin
      let start = !i in
      (* 读取一个单词 *)
      while !i < n && (match text.[!i] with
        | 'a'..'z' | 'A'..'Z' | '0'..'9' | '\'' -> true
        | _ -> false) do
        incr i
      done;
      let word = String.sub text start (!i - start)
                 |> String.lowercase_ascii in
      (* 更新计数 *)
      let count = match Hashtbl.find_opt table word with
        | Some c -> c + 1
        | None -> 1
      in
      Hashtbl.replace table word count
    end
  done;
  table
```

```ocaml
let _ =
  let text = "The quick brown fox jumps over the lazy dog. The dog barks." in
  let freq = word_frequency text in
  Hashtbl.iter (fun word count ->
    Printf.printf "%s: %d\n" word count
  ) freq
```

词频统计是自然语言处理中最基础的任务之一，也是解析思维的应用——你需要识别「单词」这个单位，然后统计它们的分布。

### 21.8 实战：回文检测

回文（palindrome）是指正着读和倒着读一样的字符串，比如 "level"、"racecar"。

一个更复杂的版本：忽略大小写和非字母数字字符。

```ocaml
let is_palindrome s =
  let n = String.length s in
  let left = ref 0 in
  let right = ref (n - 1) in
  let is_alnum c =
    (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9')
  in
  let result = ref true in
  while !left < !right && !result do
    (* 左边跳过非字母数字 *)
    while !left < !right && not (is_alnum s.[!left]) do
      incr left
    done;
    (* 右边跳过非字母数字 *)
    while !left < !right && not (is_alnum s.[!right]) do
      decr right
    done;
    if !left < !right then begin
      if Char.lowercase_ascii s.[!left] <> Char.lowercase_ascii s.[!right] then
        result := false
      else begin
        incr left;
        decr right
      end
    end
  done;
  !result
```

```ocaml
let _ =
  print_bool (is_palindrome "racecar");            (* true *)
  print_bool (is_palindrome "hello");              (* false *)
  print_bool (is_palindrome "A man, a plan, a canal: Panama")   (* true *)
```

这个例子展示了双指针技术——同时从两端向中间扫描，跳过不需要的字符，比较有效字符。

### 21.9 本章小结

- 解析分为词法分析和语法分析两个阶段
- Token 用变体类型定义，每个构造子对应一种语法单位
- 词法器逐字符扫描输入，生成 token 列表
- 递归下降解析器：每个语法规则对应一个函数，函数间互相调用
- 语法规则的层次结构自然表达了运算符优先级
- 左递归需要转换成尾递归 + 累加的形式，防止无限递归
- 解析错误应该携带位置信息，方便定位问题
- 词频统计、回文检测是解析思维的常见应用

---

## 第 22 章 输入输出与文件

对应示例：`examples/18_io.ml`

### 22.1 基本输出

OCaml 标准库提供了一系列简单的输出函数：

```ocaml
let _ =
  print_endline "Hello, world!";      (* 输出字符串 + 换行 *)
  print_string "Hello";               (* 输出字符串，不换行 *)
  print_newline ();                   (* 输出一个换行 *)
  print_int 42;                       (* 输出整数 *)
  print_newline ();
  print_float 3.14;                   (* 输出浮点数 *)
  print_newline ();
  print_bool true;                    (* 输出布尔值 *)
  print_newline ();
  print_char 'A'                      (* 输出字符 *)
```

这些函数都输出到标准输出（stdout）。它们很简单，但功能有限——比如不能格式化输出（控制宽度、小数位数等）。

### 22.2 Printf 模块：类型安全的格式化输出

`Printf` 模块提供了类似 C 语言 `printf` 的格式化输出功能，但更安全——它是类型安全的。

```ocaml
let _ =
  Printf.printf "Hello, %s!\n" "world";
  Printf.printf "Integer: %d\n" 42;
  Printf.printf "Float: %.2f\n" 3.14159;
  Printf.printf "Boolean: %b\n" true;
  Printf.printf "Hex: 0x%x\n" 255;
  Printf.printf "Octal: 0o%o\n" 255
```

常用格式说明符：
- `%d` / `%i`：整数
- `%f`：浮点数
- `%s`：字符串
- `%c`：字符
- `%b`：布尔值
- `%x` / `%X`：十六进制
- `%o`：八进制
- `%%`：字面量 `%`

**类型安全**是什么意思？如果你格式符和参数类型不匹配，编译器会报错：

```ocaml
Printf.printf "%d" "hello"   (* 编译错误：类型不匹配 *)
```

这和 C 语言的 `printf` 不同——C 语言中这种错误只会导致运行时崩溃，编译器不会检查。OCaml 的 `Printf.printf` 不是普通函数，它是编译器特殊处理的，所以能检查格式字符串和参数类型是否匹配。

`Printf` 模块还提供了其他有用的函数：
- `Printf.sprintf`：返回格式化后的字符串，不输出
- `Printf.fprintf`：输出到指定的输出通道（文件）
- `Printf.eprintf`：输出到标准错误（stderr）

```ocaml
let message = Printf.sprintf "Hello, %s! You are %d years old." "Alice" 30
(* message = "Hello, Alice! You are 30 years old." *)
```

### 22.3 读取标准输入

从标准输入读取的基本函数：

```ocaml
let _ =
  print_string "What's your name? ";
  flush stdout;                      (* 刷新缓冲区，确保提示显示出来 *)
  let name = read_line () in
  Printf.printf "Hello, %s!\n" name;

  print_string "Enter a number: ";
  flush stdout;
  let n = read_int () in
  Printf.printf "You entered: %d, double is %d\n" n (n * 2)
```

常用输入函数：
- `read_line ()`：读取一行字符串（不包含换行符）
- `read_int ()`：读取一个整数
- `read_float ()`：读取一个浮点数

注意 `read_int` 和 `read_float` 会跳过开头的空白字符，然后读取数字。如果输入格式不对，会抛出 `Failure` 异常。

**关于 flush**：`print_string` 等输出函数通常是带缓冲的——它们不会立即输出，而是先存在缓冲区里，等缓冲区满了或者遇到换行才真正输出。所以如果你输出了一个不带换行的提示，需要手动调用 `flush stdout` 来确保它立即显示出来。

### 22.4 文件读取

读取文件需要先打开文件，得到一个「输入通道」（`in_channel`），然后从通道中读取数据，最后关闭通道。

```ocaml
let read_file filename =
  let ic = open_in filename in
  try
    let content = really_input_string ic (in_channel_length ic) in
    close_in ic;
    content
  with e ->
    close_in_noerr ic;
    raise e
```

这个函数一次性读取整个文件的内容。注意异常处理：如果读取过程中出错，也要确保关闭文件通道，否则会泄漏文件描述符。

**逐行读取**：

```ocaml
let read_lines filename =
  let ic = open_in filename in
  let lines = ref [] in
  try
    while true do
      lines := input_line ic :: !lines
    done;
    []   (* 永远不会执行到这里 *)
  with End_of_file ->
    close_in ic;
    List.rev !lines
```

`input_line` 每次读取一行，**不包含末尾的换行符**。读到文件末尾时会抛出 `End_of_file` 异常，我们捕获这个异常来结束读取。

这种「用异常来控制循环结束」的模式在 OCaml 中很常见——`End_of_file` 不是真正的错误，而是正常的终止信号。

**逐字符读取**：

```ocaml
let _ =
  let ic = open_in "input.txt" in
  let first_char = input_char ic in
  close_in ic
```

`input_char` 读取一个字符，同样在文件末尾抛出 `End_of_file`。

### 22.5 文件写入

写入文件和读取类似，只不过是「输出通道」（`out_channel`）。

```ocaml
let write_file filename content =
  let oc = open_out filename in
  output_string oc content;
  close_out oc
```

`open_out` 会创建一个新文件（如果文件已存在，会被截断为空）。`output_string` 向通道写入字符串。

也可以用 `Printf.fprintf` 来格式化写入：

```ocaml
let _ =
  let oc = open_out "output.txt" in
  Printf.fprintf oc "Name: %s\n" "Alice";
  Printf.fprintf oc "Age: %d\n" 30;
  Printf.fprintf oc "Score: %.2f\n" 95.5;
  close_out oc
```

**追加写入**：

如果想在文件末尾追加内容，而不是覆盖，需要用 `open_out_gen`：

```ocaml
let append_file filename content =
  let oc = open_out_gen [Open_append; Open_creat] 0o644 filename in
  output_string oc content;
  close_out oc
```

`open_out_gen` 的第一个参数是打开模式列表：
- `Open_append`：追加模式，写入时从文件末尾开始
- `Open_creat`：如果文件不存在则创建
- `Open_trunc`：如果文件存在则截断（清空）
- `Open_text`：文本模式（Windows 上有区别，Unix 上无影响）
- `Open_binary`：二进制模式

第二个参数是文件权限（当创建新文件时使用），`0o644` 表示所有者可读写，其他用户只读。

### 22.6 逐行处理文件的模式

处理文本文件最常见的模式是：逐行读取，对每行做处理。

```ocaml
let process_lines filename f =
  let ic = open_in filename in
  try
    let rec loop () =
      let line = input_line ic in
      f line;
      loop ()
    in
    loop ()
  with End_of_file ->
    close_in ic
```

使用示例：打印文件中所有包含 "error" 的行。

```ocaml
let _ =
  process_lines "logfile.txt" (fun line ->
    if String.contains line 'e' && 
       String.contains line 'r' &&
       String.contains line 'o' &&
       String.contains line 'r' then  (* 简化的检查 *)
      print_endline line
  )
```

或者用正则表达式（需要 `Str` 模块或第三方库）。

### 22.7 目录操作：Sys 模块

`Sys` 模块提供了一些系统相关的功能，包括目录操作。

```ocaml
let _ =
  (* 当前工作目录 *)
  let cwd = Sys.getcwd () in
  Printf.printf "Current directory: %s\n" cwd;

  (* 列出目录内容 *)
  let files = Sys.readdir "." in
  Array.sort String.compare files;
  Array.iter print_endline files;

  (* 检查文件是否存在 *)
  Printf.printf "exists: %b\n" (Sys.file_exists "test.txt");

  (* 检查是否是目录 *)
  Printf.printf "is_dir: %b\n" (Sys.is_directory ".");

  (* 文件大小 *)
  if Sys.file_exists "test.txt" then
    Printf.printf "size: %d bytes\n" (Sys.file_size "test.txt")
```

注意：`Sys.readdir` 返回的是文件名数组，不包含路径，而且顺序不确定（通常需要排序后再使用）。

### 22.8 环境变量与命令行参数

```ocaml
let _ =
  (* 环境变量 *)
  let home = Sys.getenv "HOME" in
  Printf.printf "HOME: %s\n" home;

  (* 命令行参数 *)
  let args = Sys.argv in
  Printf.printf "Number of arguments: %d\n" (Array.length args - 1);
  Array.iteri (fun i arg ->
    Printf.printf "argv[%d] = %s\n" i arg
  ) args
```

`Sys.argv` 是命令行参数数组，`argv.(0)` 是程序名，`argv.(1)` 开始是实际参数。

### 22.9 资源清理：with_file 模式

每次手动 `open_in` / `close_in` 容易出错——如果中间抛出异常，可能会忘记关闭文件。

更好的做法是使用「资源获取即初始化」（RAII）模式，也叫 `with_file` 模式：

```ocaml
let with_in_file filename f =
  let ic = open_in filename in
  Fun.protect
    ~finally:(fun () -> close_in_noerr ic)
    (fun () -> f ic)

let with_out_file filename f =
  let oc = open_out filename in
  Fun.protect
    ~finally:(fun () -> close_out_noerr oc)
    (fun () -> f oc)
```

`Fun.protect ~finally work` 会执行 `work ()`，无论它正常返回还是抛出异常，都会执行 `finally ()`。如果 `work ()` 抛出了异常，`finally ()` 执行完后异常会继续传播。

使用示例：

```ocaml
let _ =
  (* 读取文件 *)
  let content = with_in_file "input.txt" (fun ic ->
    really_input_string ic (in_channel_length ic)
  ) in
  print_endline content;

  (* 写入文件 *)
  with_out_file "output.txt" (fun oc ->
    Printf.fprintf oc "Hello, world!\n";
    Printf.fprintf oc "This is a test.\n"
  )
```

这种模式确保了资源一定会被释放，即使中间发生异常。它是处理 I/O 资源的最佳实践。

### 22.10 本章小结

- 基本输出函数：`print_endline`、`print_string`、`print_int` 等
- `Printf.printf` 提供类型安全的格式化输出
- 标准输入函数：`read_line`、`read_int`、`read_float`
- 文件读取：`open_in`、`input_line`、`input_char`，末尾抛出 `End_of_file`
- 文件写入：`open_out`、`output_string`、`Printf.fprintf`
- 追加写入：`open_out_gen [Open_append; Open_creat]`
- `input_line` 不包含换行符
- 输出是带缓冲的，必要时需要 `flush`
- `Sys` 模块提供目录操作、文件信息、环境变量、命令行参数
- `Fun.protect ~finally` 用于资源清理，确保异常时也能释放资源
- `with_file` 模式是处理文件资源的最佳实践

---

## 第 23 章 测试与断言

对应示例：`examples/19_testing.ml`

### 23.1 为什么需要测试

你写了一个函数，怎么知道它是对的？

「我试了几个例子，都对」——这不够。你可能漏掉了边界情况，可能你的例子恰好覆盖不到 bug。

测试是软件工程中保证质量的基本手段。它的核心价值：

1. **验证正确性**：确保代码按预期工作
2. **防止回归**：修改代码后，确保没有破坏已有的功能
3. **文档作用**：测试用例是代码行为的活文档
4. **设计反馈**：难以测试的代码往往设计也有问题

在函数式语言中，测试尤其重要——因为函数是纯的（相同输入总是产生相同输出），写测试非常自然。

### 23.2 简单断言函数的实现

断言（assertion）是测试的基本单元：检查一个条件是否为真，如果不为真就报错。

```ocaml
let assert_equal expected actual =
  if expected <> actual then
    failwith (Printf.sprintf "assertion failed: expected %s, got %s"
                (string_of_int expected) (string_of_int actual))
```

这个版本只能比较整数，而且错误信息很简陋。我们来改进一下。

更通用的方式是让调用者提供比较函数和打印函数：

```ocaml
let assert_equal ~equal ~to_string expected actual =
  if not (equal expected actual) then
    failwith (Printf.sprintf "assertion failed:\n  expected: %s\n  got:      %s"
                (to_string expected) (to_string actual))
```

使用方式：

```ocaml
let _ =
  assert_equal ~equal:(=) ~to_string:string_of_int 3 (1 + 2);
  assert_equal ~equal:(=) ~to_string:String.capitalize_ascii "Hello" (String.capitalize_ascii "hello")
```

这种方式灵活，但每次都要传 `equal` 和 `to_string` 有点繁琐。我们可以为常见类型写专用的断言函数。

### 23.3 各种类型的断言

为常用类型定义专用的断言函数，用起来更方便。

**整数断言**：

```ocaml
let check_int expected actual =
  if expected <> actual then
    failwith (Printf.sprintf "check_int failed: expected %d, got %d"
                expected actual)
```

**布尔断言**：

```ocaml
let check_bool expected actual =
  if expected <> actual then
    failwith (Printf.sprintf "check_bool failed: expected %b, got %b"
                expected actual)
```

**字符串断言**：

```ocaml
let check_string expected actual =
  if expected <> actual then
    failwith (Printf.sprintf "check_string failed:\n  expected: %S\n  got:      %S"
                expected actual)
```

**列表断言**：

```ocaml
let check_list ~equal expected actual =
  let rec loop a b =
    match (a, b) with
    | ([], []) -> true
    | (x :: xs, y :: ys) -> equal x y && loop xs ys
    | _ -> false
  in
  if not (loop expected actual) then
    failwith (Printf.sprintf "check_list failed: lists have different content or length")
```

**带 to_string 的列表断言**（更好的错误信息）：

```ocaml
let check_list_str ~to_string expected actual =
  let rec loop a b i =
    match (a, b) with
    | ([], []) -> ()
    | ([], _) ->
        failwith (Printf.sprintf "check_list failed at index %d: expected list is shorter" i)
    | (_, []) ->
        failwith (Printf.sprintf "check_list failed at index %d: actual list is shorter" i)
    | (x :: xs, y :: ys) ->
        if x <> y then
          failwith (Printf.sprintf "check_list failed at index %d:\n  expected: %s\n  got:      %s"
                      i (to_string x) (to_string y))
        else loop xs ys (i + 1)
  in
  loop expected actual 0
```

好的断言函数应该提供：
- 清晰的错误信息（哪个测试失败了）
- 期望值和实际值（方便对比）
- 位置信息（哪个索引、哪个字段出了问题）

### 23.4 浮点数断言的特殊性

浮点数不能直接用 `=` 比较，因为有精度问题。浮点数断言需要用 epsilon 比较。

```ocaml
let check_float ?(epsilon = 1e-9) expected actual =
  let diff = abs_float (expected -. actual) in
  if diff > epsilon && 
     diff > epsilon *. max (abs_float expected) (abs_float actual) then
    failwith (Printf.sprintf "check_float failed:\n  expected: %.10g\n  got:      %.10g\n  diff:     %.10g"
                expected actual diff)
```

这里用了「绝对误差 + 相对误差」的组合判断：
- 当数值很小时，用绝对误差（`diff > epsilon`）
- 当数值很大时，用相对误差（`diff > epsilon * max(|expected|, |actual|)`）

这比单纯的绝对误差更合理，因为浮点数的精度是相对的——大数的绝对误差大但相对误差可能很小。

还要注意 nan 的处理：nan 不等于任何东西，包括它自己。如果 expected 或 actual 是 nan，上面的比较会有问题。一个完善的浮点数断言应该单独处理 nan。

### 23.5 异常断言：检查是否抛出预期异常

有时候你想测试「这个函数在某种情况下应该抛出某个异常」。比如除法函数在除以零时应该抛出 `Division_by_zero`。

```ocaml
let check_raises expected_exn f =
  try
    let _ = f () in
    failwith "check_raises failed: no exception was raised"
  with exn ->
    if exn <> expected_exn then
      failwith (Printf.sprintf "check_raises failed: expected %s, got %s"
                  (Printexc.to_string expected_exn)
                  (Printexc.to_string exn))
```

使用方式：

```ocaml
let _ =
  (* 测试除以零应该抛出 Division_by_zero *)
  check_raises Division_by_zero (fun () -> 1 / 0);
  
  (* 测试 List.hd 空列表应该抛出 Failure *)
  check_raises (Failure "hd") (fun () -> List.hd [])
```

注意 `f` 是一个 `unit -> ...` 的函数——我们把要测试的表达式包在 `fun () -> ...` 里，这样 `check_raises` 可以控制什么时候执行它。如果直接写 `1 / 0`，表达式会在 `check_raises` 调用之前就求值并抛出异常了。

### 23.6 测试框架雏形

当测试越来越多时，你需要一个框架来组织和管理它们。我们来搭建一个简单的测试框架。

```ocaml
type test_case = {
  name : string;
  run : unit -> unit;   (* 抛出异常表示失败 *)
}

type test_suite = {
  suite_name : string;
  tests : test_case list;
}

let test name f = { name; run = f }

let suite name tests = { suite_name = name; tests }

let run_test t =
  try
    t.run ();
    (t.name, true, None)
  with exn ->
    (t.name, false, Some (Printexc.to_string exn))

let run_suite s =
  Printf.printf "\n=== %s ===\n" s.suite_name;
  let results = List.map run_test s.tests in
  let passed = List.filter (fun (_, ok, _) -> ok) results in
  let failed = List.filter (fun (_, ok, _) -> not ok) results in
  List.iter (fun (name, ok, err) ->
    if ok then
      Printf.printf "  PASS: %s\n" name
    else
      Printf.printf "  FAIL: %s\n    %s\n" name (Option.get err)
  ) results;
  Printf.printf "  Result: %d passed, %d failed, %d total\n"
    (List.length passed) (List.length failed) (List.length results);
  (List.length failed = 0)
```

使用示例：

```ocaml
let math_tests = suite "Math" [
  test "addition" (fun () ->
    check_int 5 (2 + 3)
  );
  test "subtraction" (fun () ->
    check_int (-1) (2 - 3)
  );
  test "multiplication" (fun () ->
    check_int 6 (2 * 3)
  );
]

let list_tests = suite "List" [
  test "length of empty" (fun () ->
    check_int 0 (List.length [])
  );
  test "length of cons" (fun () ->
    check_int 3 (List.length [1; 2; 3])
  );
  test "hd of empty raises" (fun () ->
    check_raises (Failure "hd") (fun () -> List.hd [])
  );
]

let _ =
  let ok1 = run_suite math_tests in
  let ok2 = run_suite list_tests in
  if ok1 && ok2 then
    print_endline "\nAll tests passed!"
  else
    print_endline "\nSome tests failed!"
```

这个简单的框架已经具备了基本功能：组织测试用例、运行测试、报告结果。

实际项目中，你应该使用成熟的测试框架，比如：
- **Alcotest**：轻量级测试框架，社区最常用
- **OUnit2**：另一个流行的测试框架
- **Crowbar**：属性测试框架

### 23.7 属性测试（Property-based Testing）简介

普通测试（也叫「基于示例的测试」）是这样的：你写几个具体的输入输出例子，然后验证函数对这些输入给出正确的输出。

属性测试（property-based testing）是另一种思路：你描述函数应该满足的**性质**，然后测试框架自动生成大量随机输入来验证这些性质。

比如，对于一个排序函数，你可以说：
- 性质 1：排序后的列表长度和原来相同
- 性质 2：排序后的列表是有序的（每个元素 <= 下一个元素）
- 性质 3：排序后的列表和原列表包含相同的元素（多重集相等）
- 性质 4：已经排序的列表再排序，结果不变（幂等性）

如果你的排序函数满足所有这些性质，那它很可能是对的——比你手动写三五个测试用例有说服力得多。

OCaml 生态中常用的属性测试库：
- **QCheck**：最流行的属性测试库，支持 Alcotest 和 OUnit
- **Crowbar**：基于 AFL 的模糊测试 + 属性测试

属性测试特别适合：
- 数据结构（验证不变量）
- 编解码（编码再解码应该得到原值）
- 数学函数（验证代数性质）
- 解析器（解析再打印应该得到等价的结果）

### 23.8 TDD 在函数式语言中的应用

测试驱动开发（Test-Driven Development，TDD）的流程是：
1. 先写一个会失败的测试
2. 写最少的代码让测试通过
3. 重构代码，保持测试通过

TDD 在函数式语言中特别自然，因为：
- 函数是纯的，测试不需要 setup/teardown
- 类型系统已经帮你保证了很多东西，测试可以集中在业务逻辑上
- 函数式代码通常更容易测试（依赖少、副作用少）

但 TDD 不是银弹。在函数式语言中，类型系统本身就是一种「编译时测试」——很多错误在类型检查阶段就被发现了，不需要写测试。

所以函数式语言中的测试策略通常是：
1. **先用类型系统保证正确**：让非法状态不可表示
2. **再测试核心业务逻辑**：写单元测试验证关键性质
3. **最后用属性测试加强信心**：对关键模块做属性测试

### 23.9 本章小结

- 测试是保证代码质量的基本手段
- 断言是测试的基本单元：检查条件是否满足
- 为常用类型提供专用断言函数（check_int、check_string 等）
- 浮点数断言要用 epsilon 比较，不能直接用 `=`
- 异常断言验证函数是否抛出预期的异常
- 测试框架用于组织测试用例、运行和报告结果
- 属性测试：描述性质，自动生成测试用例
- 在函数式语言中，类型系统是第一道防线，测试是第二道
- TDD 在函数式语言中很自然，但要结合类型系统的优势

---

## 第 24 章 记录、对象与类

对应示例：`examples/20_records.ml`

第 6 章讲过记录基础，第 18 章讲过可变状态。这一章把两条线接起来：先回顾记录的高级用法——参数位置解构、嵌套更新、参数化记录、函数字段，然后进入 OCaml 的对象系统：`object` 字面量、`class` 类、`inherit` 继承、结构子类型 `:>`。24.9 的「实测坑」是本教程在 `20_records.ml` 里真实修过的类型错误，值得细读。

### 24.1 记录高级用法回顾

```ocaml
type point = { x : float; y : float }

let p3 = { p1 with y = 5.0 }             (* 函数式更新，p1 不变 *)
let p4 = { p1 with x = 10.0; y = 20.0 }  (* 同时改多个字段 *)
```

一个实测细节：`p4` 把 `point` 的全部字段都列了出来，OCaml 5.x 会给 `Warning 23 [useless-record-with]`——都全量覆盖了，不如直接写 `{ x = 10.0; y = 20.0 }`。示例文件里有两处触发此警告（`p4` 和下面 `move_rect` 的内层更新），编译时能看到。

模式匹配可以直接在参数位置解构记录，比 `let ... in` 逐个拆干净：

```ocaml
let distance2 { x = x1; y = y1 } { x = x2; y = y2 } =
  sqrt ((x2 -. x1) ** 2. +. (y2 -. y1) ** 2.)
```

嵌套记录的函数式更新要层层 `with`：

```ocaml
type rectangle = { top_left : point; width : float; height : float }

let move_rect dx dy rect =
  { rect with
    top_left = { rect.top_left with
      x = rect.top_left.x +. dx;
      y = rect.top_left.y +. dy
    }
  }
```

记录类型可以带类型参数（参数化记录），一个类型多种用途：

```ocaml
type 'a labeled = {
  label : string;
  value : 'a;
}

let int_labeled = { label = "count"; value = 42 }
let str_labeled = { label = "name";  value = "Alice" }
```

这和第 4 章的值限制是一体两面：`{ value = 42 }` 是不可泛化的值，`int_labeled` 被钉死在 `int labeled`；只有函数（如示例的 `print_labeled`）能保持多态。

### 24.2 可变记录：封装状态的经典手法

字段加 `mutable` 就能用 `<-` 赋值。这是 OCaml 里「有状态的数据」最常用的形态——比 `ref` 清晰（多字段一个绑定搞定），比对象轻量：

```ocaml
type counter = {
  mutable count : int;
  mutable step : int;
}

let make_counter ?(step = 1) start = { count = start; step }

let next c =
  let current = c.count in
  c.count <- c.count + c.step;
  current
```

更典型的例子是玩家状态：不可变字段与可变字段混搭：

```ocaml
type player = {
  name : string;                          (* 不可变 *)
  mutable hp : int;                       (* 可变：生命值 *)
  mutable level : int; mutable exp : int; (* 可变：等级、经验 *)
  mutable inventory : string list;
}

let take_damage player amount =
  player.hp <- max 0 (player.hp - amount);
  player.hp = 0  (* 返回是否死亡 *)
```

示例里的 `gain_exp` 是这类代码的范式：先累加经验、比较阈值，够了一步扣减并升级——状态变化集中在一处，外部看到的仍然是普通记录值。

### 24.3 函数字段：让记录模拟对象

记录的字段可以是函数。把一组操作打包进记录，就得到「接口 + 闭包状态」的迷你对象，不需要任何对象语法：

```ocaml
type 'a stack_ops = {
  push : 'a -> unit;
  pop : unit -> 'a;
  is_empty : unit -> bool;
  size : unit -> int;
  to_list : unit -> 'a list;
}

let make_stack () =
  let data = ref [] in
  {
    push = (fun x -> data := x :: !data);
    pop = (fun () ->
      match !data with
      | [] -> failwith "Stack.pop: empty"
      | h :: t -> data := t; h);
    is_empty = (fun () -> !data = []);
    size = (fun () -> List.length !data);
    to_list = (fun () -> List.rev !data);
  }
```

（示例的接口还有 `peek : unit -> 'a`，实现与 `pop` 同构，这里略去。）

私有状态（`data`）被闭包捕获，外部只能通过六个函数字段访问——这就是封装。

更有说服力的是「一个接口、多种实现」。示例定义了 `('k, 'v) dict_ops`（字段为 `get`/`set`/`mem`/`remove`/`size`/`keys`），然后给了两个实现——基于关联表的 `make_alist_dict`：

```ocaml
let make_alist_dict () =
  let data = ref [] in
  {
    get = (fun k -> List.assoc k !data);
    set = (fun k v -> data := (k, v) :: List.remove_assoc k !data);
    mem = (fun k -> List.mem_assoc k !data);
    remove = (fun k -> data := List.remove_assoc k !data);
    size = (fun () -> List.length !data);
    keys = (fun () -> List.map fst !data);
  }
```

`make_hashtbl_dict` 结构完全相同，只是六个字段换成 `Hashtbl.find/replace/mem/remove/length/fold`。示例用同一个 `test_dict` 先后测试两种实现——它们类型一致，可随意替换。这正是第 15 章 functor 所解决问题的轻量版：接口小、只有一个类型参数时，函数字段记录通常比 functor 顺手。

### 24.4 对象字面量：object ... end

OCaml 有完整的对象系统。`object ... end` 直接创建对象值：`val`/`val mutable` 声明实例变量，`method` 声明方法，调用用 `#`：

```ocaml
let point_obj = object
  val mutable x = 0.0
  val mutable y = 0.0

  method get_x = x
  method get_y = y

  method move dx dy = x <- x +. dx; y <- y +. dy

  method distance_to other =
    let dx = x -. other#get_x in
    let dy = y -. other#get_y in
    sqrt (dx *. dx +. dy *. dy)

  method to_string = Printf.sprintf "(%.2f, %.2f)" x y
end
```

使用：`point_obj#move 3.0 4.0`、`point_obj#get_x`。注意实例变量赋值用 `<-`（与可变记录字段相同），方法调用用 `#`（不是 `.`）。

两个细节：

1. **实例变量与方法可以重名**。24.6 的 `rectangle_class` 里 `val width = w` 加 `method width = width`——方法体里的 `width` 指实例变量，对外暴露的是方法。
2. **`initializer`** 在对象构造完成时执行一次；外层函数的参数就是「构造参数」——每次调用产生一个新对象，各自独立：

```ocaml
let p2_obj = object
  val mutable x = 0.0
  val mutable y = 0.0
  method get_x = x
  method get_y = y
  initializer x <- 10.0; y <- 5.0
end
```

示例的 `bank_account` 是「函数即构造参数」的完整版：`let bank_account initial = object ... end`，`deposit`/`withdraw` 方法维护 `balance` 和 `transactions`（多态变体流水），每调用一次得到一个独立账户，`statement` 方法拼对账单。需要 `self`（方法里调自己的其他方法）时写 `object (self)`，24.6 的 `rectangle_class` 会用到。

### 24.5 对象类型与开放类型 `< ... ; .. >`

对象类型由「它有哪些方法」决定，与它是谁、从哪个类来无关（结构类型）。`point_obj` 的推断类型是：

```ocaml
< get_x : float; get_y : float;
  move : float -> float -> unit;
  distance_to : < get_x : float; get_y : float; .. > -> float;
  to_string : string >
```

注意 `distance_to` 的参数类型：`< get_x : float; get_y : float; .. >`。末尾的 `..` 是**开放类型**（row 变量），意思是「至少有 `get_x` 和 `get_y`，别的随便」。所以示例里 `point_obj#distance_to p2_obj` 成立——`p2_obj` 只有 `get_x`/`get_y` 两个方法，类型与 `point_obj` 并不相同，但结构上满足要求。这正是对象版的「鸭子类型」，而且由类型检查器静态验证。对单个函数参数，开放类型自动生效；24.8 会看到列表场景下为什么还需要显式 `:>`。

### 24.6 class：对象的模板

`object ... end` 每次写一遍太重复。`class` 把对象提炼成模板，`new` 实例化——类参数替代了「外层函数当构造参数」的技巧：

```ocaml
class point_class init_x init_y = object
  val mutable x = init_x
  val mutable y = init_y
  method get_x = x
  method get_y = y
  method move dx dy = x <- x +. dx; y <- y +. dy
  method to_string = Printf.sprintf "(%.2f, %.2f)" x y
end

let pt1 = new point_class 1.0 2.0
let pt2 = new point_class 4.0 6.0
```

`pt1#move 2.0 3.0` 之后 `pt2` 不受影响——每个实例有自己的实例变量。类参数还支持可选参数，注意可选参数后要跟一个 `()` 占位，否则无法确定取参何时结束（用法：`new counter_class ~init:100 ~step_val:10 ()`）：

```ocaml
class counter_class ?(init = 0) ?(step_val = 1) () = object
  val mutable count = init
  val mutable step = step_val

  method next =
    let current = count in
    count <- count + step;
    current

  method reset = count <- 0
  method get_count = count
end
```

类体里还可以 `new` 别的类做组合。矩形类内部持有一个点对象，把移动委托出去：

```ocaml
class rectangle_class x y w h = object (self)
  val top_left = new point_class x y
  val width = w
  val height = h

  method width = width          (* 实例变量与方法重名 *)
  method area = width *. height

  method move dx dy = top_left#move dx dy

  method contains : 'a. (< get_x : float; get_y : float; .. > as 'a) -> bool =
    fun pt ->
      let px = pt#get_x and py = pt#get_y in
      let tx = top_left#get_x and ty = top_left#get_y in
      px >= tx && px <= tx +. width &&
      py <= ty && py >= ty -. height

  method to_string =
    Printf.sprintf "Rect[top-left=%s, w=%.2f, h=%.2f, area=%.2f]"
      top_left#to_string width height self#area
end
```

`contains` 的方法标注先跳过，24.9 专门讲它为什么必须写成长这样。`to_string` 里的 `self#area` 则是 `object (self)` 的用途：类体里调自己的方法。

### 24.7 继承：inherit 与 super

`inherit` 让一个类获得另一个类的全部实例变量与方法：

```ocaml
class shape name = object (self)
  val name = name
  method name = name
  method area = 0.0  (* 子类会覆盖 *)
  method describe = Printf.sprintf "Shape '%s', area: %.2f" name self#area
end

class circle name radius = object (self)
  inherit shape name as super
  val radius = radius
  method area = 3.1415926535 *. radius *. radius
  method describe =
    Printf.sprintf "Circle '%s', radius: %.2f, area: %.2f" name radius self#area
end
```

要点：

1. **方法覆盖即重定义**。子类里重新写 `method area = ...` 就覆盖了父类版本，不需要任何关键字。
2. **`inherit ... as super` 给父类起别名**。`self#m` 是动态派发——按对象实际类型调用最终覆盖版；`super#m` 是静态派发——明确调父类版本。`movable_point` 两者配合实现动画步进（`rectangle_shape`、两层继承的 `square` 与此同构，完整代码见示例）：

```ocaml
class movable_point x y = object
  inherit point_class x y as super

  val mutable speed_x = 0.0
  val mutable speed_y = 0.0

  method set_speed sx sy = speed_x <- sx; speed_y <- sy

  method tick dt =
    super#move (speed_x *. dt) (speed_y *. dt)
end
```

最后补一个示例里没用到的语法：**虚方法**。`class virtual` 定义不能实例化的抽象类，`method virtual` 声明必须被子类实现的方法：

```ocaml
class virtual shape_base = object
  method virtual area : float
end

class real_shape name = object
  inherit shape_base
  method area = 3.0
end
```

`new shape_base` 直接报错；虚方法的类型必须显式标注——原因见下一节。

### 24.8 结构子类型与 `:>`

OCaml 的子类型是**结构性的**：不看血缘，只看方法集合。任何有 `area` 方法的对象都能传给下面这个函数，无论它继承自谁、甚至是不是类的实例：

```ocaml
let print_area obj =
  Printf.printf "  Area: %.2f\n" obj#area
```

`print_area s1`（circle）、`print_area s2`（rectangle_shape）、`print_area s3`（shape）全部成立——参数类型被推断为 `< area : float; .. >`，开放类型自动匹配，这就是行多态。

但列表是另一回事：列表所有元素必须类型**完全相同**，行多态帮不上忙。`circle` 的对象和 `rectangle_shape` 的对象互不为子类型，直接混装会报类型错误。这时用强制转换 `:>` 把它们弱化到公共类型：

```ocaml
let shapes : shape list = [
  (s1 :> shape);   (* circle           -> shape *)
  (s2 :> shape);   (* rectangle_shape  -> shape *)
  (s3 :> shape);
]

List.iter (fun s -> Printf.printf "  %s\n" s#describe) shapes
```

两条规则记牢：

- `:>` 的方向是「子到父」，只能丢方法、不能加方法；丢弃的方法在目标类型里不可见（本例丢掉了子类特有的 `radius`、`describe` 覆盖版等，列表里只剩 `shape` 的方法）。
- 目标必须是**闭合**的对象类型（如 `shape`，没有 `..`）。转成开放类型 `< area : float; .. >` 不允许——那是行多态该干的活，不需要转换。

### 24.9 实测坑：class 方法里的开放对象类型

这是 `20_records.ml` 开发时真实踩过、在 OCaml 5.4.1 下实测复现的编译错误。

**踩坑过程**。`rectangle_class` 的 `contains` 方法想接受「任何有 `get_x`/`get_y` 的对象」，最自然的写法是不加标注，让类型推断自己推出开放类型：

```ocaml
(* 错误写法 *)
method contains pt =
  let px = pt#get_x and py = pt#get_y in
  let tx = top_left#get_x and ty = top_left#get_y in
  px >= tx && px <= tx +. width &&
  py <= ty && py >= ty -. height
```

编译失败（原样照录，中间字段以 `...` 略）：

```text
Error: Some type variables are unbound in this type:
         class rectangle_class :
           float -> float -> float -> float ->
           object
             ...
             method contains : < get_x : float; get_y : float; .. > -> bool
           end
       The method contains has type
         (< get_x : float; get_y : float; .. > as 'a) -> bool
       where 'a is unbound
```

**原理**。错误信息最后两行是关键：推断出的方法类型是 `(< get_x : float; get_y : float; .. > as 'a) -> bool`，其中 `'a` 就是开放类型里那个 `..`（row 变量）的内部名字——一个未绑定的类型变量。

为什么普通 `let` 不报错、`method` 就报错？两者的泛化规则不同：

- **值绑定会自动泛化**。`let contains pt = ...` 满足值限制（是函数），类型检查器自动把 `'a` 全称量化成 `'a. (< ... ; .. > as 'a) -> bool`，开放类型合法。
- **class 定义不做这种隐式泛化**。类体作为整体定型，类类型里出现的方法类型必须闭合；多态方法必须由程序员显式写出全称量化的标注，否则其中的类型变量一律算 unbound。这个设计是为了避免类类型推断的歧义——类会被继承、被实例化多次，隐式泛化会让一个笔误扩散到所有子类。

**修法**。给方法加显式多态标注，把 row 变量用 `as 'a` 命名后交给 `'a.` 量化：

```ocaml
(* 正确写法（示例 20_records.ml 第 540 行起） *)
method contains : 'a. (< get_x : float; get_y : float; .. > as 'a) -> bool =
  fun pt ->
    let px = pt#get_x and py = pt#get_y in
    let tx = top_left#get_x and ty = top_left#get_y in
    px >= tx && px <= tx +. width &&
    py <= ty && py >= ty -. height
```

逐块拆开：

- `'a. (...)` —— 显式全称量化：「对所有可能的 `'a`」。这就是普通 `let` 自动帮你做的那一步。
- `< get_x : float; get_y : float; .. > as 'a` —— `as 'a` 把整个开放对象类型（含 `..`）绑定到名字 `'a`，使它可以被量化。没有 `as 'a`，`..` 仍是匿名变量，照样 unbound。
- 方法体要写成 `fun pt -> ...` —— 标注给出了方法的完整类型，等号右边就是该类型的值，参数由 `fun` 引入。

**同一错误的另一副面孔**。实测发现：把 `point_class` 里的 `move` 和 `to_string` 删掉（即没有任何 `+.`/`%.2f` 把 `init_x`/`init_y` 钉死为 `float`），class 本身就会报同一个 `Some type variables are unbound`（`The method get_x has type 'a where 'a is unbound`）——类参数保持完全多态，类类型里就出现未绑定变量。修法要么在用法里钉死类型（示例正是靠 `move` 里的 `+.` 把 `x` 定为 `float`），要么给类参数加标注（`class point_class (init_x : float) ...`）。**经验法则：写 class 时多写显式类型标注**——对象系统不像 `let` 那样替你泛化，标注是它要求的正常写法，不是画蛇添足。

### 24.10 对象、记录、模块：怎么选

OCaml 里表达「数据 + 操作」至少有三条路，选型建议：

| 场景 | 推荐 | 理由 |
|------|------|------|
| 纯数据，字段固定 | 记录 | 模式匹配、`with` 更新，类型推断最省事 |
| 有状态的小对象（计数器、缓存） | 可变记录 | 比 `ref` 清晰，比对象轻量（24.2） |
| 接口 + 多实现，状态简单 | 函数字段记录 | 一个 `make_xxx` 函数搞定（24.3） |
| 接口 + 多实现，类型抽象要求高 | 模块 + functor | 第 14-16 章的工具，能隐藏类型 |
| 深层继承、开放递归（`self`）、运行时异构集合 | class / object | 只有对象系统提供这些 |

实践中的倾向：OCaml 社区用对象很少，标准库里几乎没有（`Oo` 模块只是运行时支持），主要使用者是 lablgtk（GTK 绑定）、OCamlGraph 这类把对象模型映射过来的库。原因不难体会——对象让推断变弱（24.9 的标注负担）、方法调用比直接函数调用慢，而记录 + 模块能覆盖绝大多数需求。对象真正不可替代的是开放递归（子类覆盖方法后，父类里经 `self` 调用的也是新版本）和 24.8 的异构集合。判断标准：需要「多种运行时可互换的实现且要在集合里混装」时用对象；否则优先记录和模块。

### 24.11 本章小结

- 记录高级用法：参数位置解构、嵌套 `with` 层层更新、`'a` 参数化记录（与值限制一体两面）
- 可变记录是封装状态的首选：`mutable` 字段 + `<-` 赋值，不可变与可变字段可混搭
- 函数字段让记录模拟对象：闭包捕获私有状态，「一个接口、多种实现」的轻量方案
- `object ... end`：`val`/`val mutable` 状态、`method` 行为、`#` 调用、`initializer`、`object (self)`
- 对象类型是结构性的；开放类型 `< ... ; .. >` 是静态检查的鸭子类型，函数参数自动行多态
- `class` + `new`：类参数、可选参数（后跟 `()`）、`new` 组合；`inherit ... as super` 继承并覆盖方法，`self#` 动态派发、`super#` 静态派发；`class virtual`/`method virtual` 定义抽象
- 结构子类型 `:>` 只能把对象弱化到闭合类型，用于异构列表；日常参数匹配交给行多态
- 实测坑：class 方法里用开放对象类型报 `Some type variables are unbound`——class 不做隐式泛化，必须显式写 `'a. (< ... ; .. > as 'a) -> ...` 多态方法标注；类参数完全多态时同样触发
- 选型顺序：记录 → 函数字段记录 / 模块 → 对象；对象留给开放递归和运行时异构集合

---

## 第 25 章 流与序列

对应示例：`examples/21_streams_seq.ml`

### 25.1 列表够用吗：惰性求值与 Seq 的形态

第 8 章的列表有一个前提：所有元素在列表存在的那一刻就已经算好。`List.init 1_000_000 f` 会立刻分配一百万个节点，哪怕你最后只看前 10 个；「从 2 开始的所有自然数」这种无限数据，列表根本写不出来。

标准库的答案是 `Seq`（序列）：一个**按需产出**元素的惰性结构。概念上它的类型就是：

```ocaml
(* 概念上，'a Seq.t 等价于： *)
type 'a node = Nil | Cons of 'a * 'a t
and 'a t = unit -> 'a node
```

序列是一个函数：调用它（`s ()`），告诉你下一个元素是什么、剩下的序列是什么；不调用，就什么都不发生。元素只有在被消费时才计算。先看示例文件里 `print_seq` 的核心 `take`：

```ocaml
let rec take i s acc =
  if i <= 0 then List.rev acc
  else match s () with
    | Seq.Nil -> List.rev acc
    | Seq.Cons (x, rest) -> take (i - 1) rest (x :: acc)
```

关键在 `match s () with`：序列要先「调用」才得到 `Nil` 或 `Cons (x, rest)`，取够 3 个就停，剩下的 `rest` 原封不动——对无限序列也安全。示例把它包成 `print_seq label n seq`，末尾还用了一句 `Seq.is_empty (Seq.drop n seq)` 判断要不要补「...」：`drop` 是惰性的不消费，`is_empty` 只踩一步。

最基本的构造函数：

```ocaml
let s1 = List.to_seq [1; 2; 3; 4; 5]   (* 从列表创建序列 *)
let empty_seq = Seq.empty              (* 空序列 *)
let single = Seq.return 42             (* 单元素序列 *)
let s2 = Seq.cons 0 s1                 (* 序列前添加元素：0;1;2;3;4;5 *)
```

取头部没有 `Seq.hd`——这不是遗漏：序列的本质是 `unit -> node`，「取头部」就是调用一次函数加一个模式匹配（上面 `take` 里已经写过这个动作），不值得再包一层。

### 25.2 序列的生成：unfold 与它的同伴们

最通用的生成器是 `Seq.unfold`。它是一台状态机：给你初始状态，每步返回 `Some (产出元素, 新状态)`，返回 `None` 序列结束：

```ocaml
let count_up start =
  Seq.unfold (fun n -> Some (n, n + 1)) start
```

`count_up 1` 产出 1, 2, 3, ...。示例里的 Collatz（冰雹）序列就是靠 `None` 落地的：`Seq.unfold (fun n -> if n = 1 then None else Some (n, 下一步))`，走到 1 自然终止。

三个现成的生成器：

```ocaml
(* Seq.init : 按索引生成有限序列 *)
let s4 = Seq.init 10 (fun i -> i * i)      (* 0, 1, 4, 9, ..., 81 *)

(* Seq.ints : 无限自然数序列，本章所有管道的数据源头 *)
let nums = Seq.ints 0                      (* 0, 1, 2, 3, ... *)

(* Seq.forever : 反复调用函数生成无限序列 *)
let counter = ref 0
let counted = Seq.forever (fun () -> incr counter; !counter)
```

### 25.3 转换与组合：惰性管道的积木

序列上的变换函数与列表同名同义，但有一个本质区别：它们**不立即计算**，只把函数包进新序列，等消费时才逐个应用。

```ocaml
let nums = Seq.ints 0
let doubled = Seq.map (fun x -> x * 2) nums
let evens = Seq.filter (fun x -> x mod 2 = 0) nums
let first5 = Seq.take 5 nums      (* 前 5 个 *)
let from5 = Seq.drop 5 nums       (* 跳过前 5 个 *)
```

`doubled` 定义好的那一刻，一个乘法都没做。直到消费者出现：

```ocaml
let sum_first_10 = Seq.fold_left (+) 0 (Seq.take 10 nums)
```

`fold_left`、`iter`、`for_all`、`find` 这类是**消费者**——驱动序列真正前进；`map`、`filter`、`take` 是**变换者**——只负责组合。区分这两类，是写管道代码的基本功。

再看几个组合积木（摘自示例）：

```ocaml
(* append : 首尾连接 *)
let s_appended = Seq.append (Seq.init 3 (fun i -> i)) (Seq.init 3 (fun i -> i + 10))

(* flat_map : 每个元素展开成一个子序列；产出 (1,1) (1,2) (1,3) (2,1) (2,2) (2,3) *)
let pairs = Seq.flat_map (fun x ->
  Seq.map (fun y -> (x, y)) (Seq.take 3 (Seq.ints 1))
) (Seq.take 2 (Seq.ints 1))

(* zip : 两个序列压缩成元组序列，以短的一侧为准 *)
let zipped = Seq.zip (Seq.ints 1) (List.to_seq [ 'a'; 'b'; 'c'; 'd'; 'e' ])
```

序列与列表、数组的互转是日常操作（对无限序列只能朝「序列」的方向转，反方向会停不下来）：

```ocaml
let lst = List.of_seq (Seq.take 5 (Seq.ints 1))    (* [1; 2; 3; 4; 5] *)
let arr = Array.of_seq (Seq.take 5 (Seq.ints 10))  (* [|10; 11; 12; 13; 14|] *)
```

### 25.4 无限序列：斐波那契与素数筛

惰性最漂亮的应用是无限序列。斐波那契——注意定义里那个不起眼的 `()`：

```ocaml
let fibonacci =
  let rec fib a b () = Seq.Cons (a, fib b (a + b)) in
  fib 0 1
```

`fib a b` 返回的是**函数**（下一状态的序列），不是立刻递归展开。`Cons` 的第二个分量本来要的就是 `'a t`（即 `unit -> node`），`fib b (a + b)` 这个部分应用正好是它——递归被推迟到下一次调用。把这个 `()` 写丢（写成 `let rec fib a b = Seq.Cons (...)`）就成了无限递归，栈立刻爆掉。

素数的惰性筛法，结构同款：

```ocaml
let primes =
  let rec sieve s () =
    match s () with
    | Seq.Nil -> Seq.Nil
    | Seq.Cons (p, rest) ->
        Seq.Cons (p, sieve (Seq.filter (fun n -> n mod p <> 0) rest))
  in
  sieve (Seq.ints 2)
```

每取出一个素数 `p`，就把 `rest` 中所有 `p` 的倍数滤掉，剩下的序列递归地继续筛——滤掉「所有 2 的倍数」这件事，永远只对真正被取到的元素发生，这正是惰性的形状。示例文件里的 2 的幂、三角数、阶乘全是同一个模式。

一条纪律必须刻在脑子里：**无限序列只能被「取有限部分」地消费**。`Seq.take`、`Seq.find`、手写的 `match s ()` 都安全；`Seq.length`、`List.of_seq`、不带界的 `fold_left` 会一路走到天荒地老——程序不是错了，是不会停。

### 25.5 Stream 流：单步推进的消费模型

`Stream` 是 OCaml 的另一套流式数据结构，比 `Seq` 老得多，传统上是手写解析器的配套（ocamllex 时代的产物）。它和 `Seq` 的关键区别在消费方式：

- `Seq` 是纯函数式的：消费是调用一个函数，消费完序列还在；
- `Stream` 是**带游标的可变对象**：`next` 取出下一个元素并把游标推进一步，`peek` 只看不取，`junk` 只丢不取，消费过的地方回不去了。

单步推进 + 预读，恰好是手写解析器的形状。示例文件里兼容层的核心如下：

```ocaml
module Stream = struct
  type 'a t = { mutable data : 'a Seq.t }

  let of_seq s = { data = s }
  let of_list lst = of_seq (List.to_seq lst)
  let of_string s = of_seq (String.to_seq s)

  (* 原版 empty 在非空时抛 Stream.Failure；示例按 bool 谓词用，这里返回 bool *)
  let empty t = (t.data () = Seq.Nil)

  exception Failure

  let next t =
    match t.data () with
    | Seq.Cons (x, rest) -> t.data <- rest; x
    | Seq.Nil -> raise Failure

  let peek t =
    match t.data () with
    | Seq.Cons (x, _) -> Some x
    | Seq.Nil -> None

  let junk t =
    match t.data () with
    | Seq.Cons (_, rest) -> t.data <- rest
    | Seq.Nil -> ()
end
```

（示例的完整版还有 `from`——按「索引 -> 元素 option」构造流，内部就是一个计数 `ref` 加 `Seq.unfold`——以及 `iter`，共 40 余行。为什么平白多出一个 `module Stream`？见 25.9 坑 1：OCaml 5.x 发行里已没有 Stream 模块，示例为了让传统写法原样跑通，用 Seq 补了一个。）

消费一个流，看游标怎么走：

```ocaml
let stream1 = Stream.of_list [10; 20; 30; 40; 50];;
Printf.printf "Stream next: %d\n" (Stream.next stream1);;              (* 10，游标到 20 *)
Printf.printf "Stream next: %d\n" (Stream.next stream1);;              (* 20，游标到 30 *)
Printf.printf "Stream peek: %d\n" (Option.get (Stream.peek stream1));; (* 30，游标不动 *)
Printf.printf "Stream next: %d\n" (Stream.next stream1);;              (* 30 *)
Printf.printf "Stream empty? %b\n" (Stream.empty stream1)              (* false，还剩 40;50 *)
```

`peek` + `junk` 的组合在解析里最常见——先偷看下一个字符决定怎么办，再决定吃不吃它。示例里的整数解析器就是这个套路（简化版，完整版还带 `when` 守卫处理前导负号）：

```ocaml
let parse_int_stream s =
  let chars = Stream.of_string s in
  let buf = Buffer.create 16 in
  let rec parse () =
    match Stream.peek chars with
    | Some ('0'..'9' as c) ->
        Stream.junk chars;
        Buffer.add_char buf c;
        parse ()
    | _ ->
        if Buffer.length buf = 0 then failwith "parse_int: no digits"
        else int_of_string (Buffer.contents buf)
  in
  parse ()
```

`"99abc"` 解析出 99 后停在 `'a'` 前面——调用方可以继续消费剩下的流。这正是第 21 章递归下降解析器里字符级的处理方式。Seq 和 Stream 互转，最省事的路是列表中转：

```ocaml
let prime_stream =
  primes |> Seq.take 10 |> List.of_seq |> Stream.of_list
```

### 25.6 Seq 与 List：转换与性能的取舍

同一件事，两种写法。序列版（惰性，无中间结构）：

```ocaml
let seq_pipeline n =
  let s = Seq.ints 0 in
  let s1 = Seq.map (fun x -> x * 2) s in
  let s2 = Seq.filter (fun x -> x mod 3 = 0) s1 in
  let s3 = Seq.map (fun x -> x * x) s2 in
  let s4 = Seq.take 10 s3 in
  Seq.fold_left (+) 0 s4
```

列表版（每一步都完整物化一个新列表；示例为兼容旧版手写了 `init` 和 `take`，`List.take` / `List.drop` 自 OCaml 5.2 起已在标准库，5.4.1 实测可用，这里直接用）：

```ocaml
let list_pipeline_full n =
  let lst = List.init n (fun i -> i) in
  let mapped = List.map (fun x -> x * 2) lst in
  let filtered = List.filter (fun x -> x mod 3 = 0) mapped in
  let doubled = List.map (fun x -> x * x) filtered in
  List.fold_left (+) 0 (List.take 10 doubled)
```

两版结果相同，但内存画像完全不同：列表版构造了长度约为 n、n、n/3、n/3 的四个列表（示例里 n = 1_000_000），序列版从头到尾只有常数个节点在飞行。示例的计时输出差距悬殊——这并不奇怪：序列版只算到产出 10 个元素为止，列表版老老实实处理了全部一百万个。

内存与遍历特征，一表带走：

- List：所有元素同时驻留内存；Seq：遍历时一次只算一个，还装得下无限数据
- `List.length` 是 O(1)；`Seq.length` 是 O(n)（还得能终止）
- List 遍历多少次结果都一样；Seq 每次遍历**重新计算**

最后一条值得亲眼看看。示例用带副作用的序列做了实验：

```ocaml
let side_effect_counter = ref 0 in
let seq_with_side_effect =
  Seq.init 5 (fun i -> incr side_effect_counter; i * 10) in

side_effect_counter := 0;
let _ = Seq.find (fun _ -> true) (Seq.drop 2 seq_with_side_effect) in
Printf.printf "After Seq.nth 2: counter = %d\n" !side_effect_counter;

side_effect_counter := 0;
let _ = Seq.find (fun _ -> true) (Seq.drop 2 seq_with_side_effect) in
Printf.printf "After second Seq.nth 2: counter = %d (recomputed!)\n" !side_effect_counter
```

第一次取下标 2，只计算了 3 个元素（换成 `List.of_seq` 则 5 个全算完）——这就是惰性省下的钱。但第二次取同样的下标，前 3 个元素**被重新计算了**。惰性不等于记忆化（memoization）：`Seq` 只推迟计算，不缓存结果。

### 25.7 一次性（ephemeral）语义

「每次遍历都重算」意味着序列有两种截然不同的处境。

**纯函数式的序列**（`Seq.ints`、`Seq.map` 组合出来的）安全可重放：重算浪费一点 CPU，结果不变——上面的实验就是这种。

**建立在水性（ephemeral）来源上的序列是一次性的**。典型如文件逐行读出的序列：每读一行，文件指针前进一行；再遍历一次，得到空序列。25.5 的 `Stream` 兼容层也是——`next` 把游标推进去之后，数据就消费掉了，`t.data` 已指向尾部。

由此得到三条工程守则：拿不准来源是否可重放，就当它是一次性的；需要遍历多次（排序、分组、多次查询），先 `List.of_seq` / `Array.of_seq` 物化一次；序列从函数参数传进来时，文档里写清楚「消费后失效」，或者干脆在 API 里收 list、出 seq。

一次性不是缺陷，而是流式处理的本意：数据流过去就流过去了，谁也不欠谁一份拷贝。

### 25.8 管道式数据处理实战

序列与 `|>` 运算符是天作之合：数据从左边流进来，经过一串变换者，最后落进一个消费者。示例后段的管道，一条比一条像真实代码。

**管道 1：数字加工**——map、filter、take、fold 一气呵成：

```ocaml
let result1 =
  Seq.ints 1
  |> Seq.map (fun x -> x * x)           (* 平方 *)
  |> Seq.filter (fun x -> x mod 2 = 0)  (* 只保留偶数 *)
  |> Seq.take 10                        (* 取前 10 个 *)
  |> Seq.fold_left (+) 0                (* 求和 *)
```

它算出「前 10 个偶平方数之和」而不必知道第 10 个偶平方数是第几个自然数——无限源头，有限出口。

**管道 2：素数管道**——filter 的谓词本身又是一台序列机器（试除到平方根）：

```ocaml
let prime_pipeline n =
  Seq.ints 2
  |> Seq.filter (fun p ->
    Seq.ints 2
    |> Seq.take_while (fun d -> d * d <= p)
    |> Seq.for_all (fun d -> p mod d <> 0))
  |> Seq.take n
  |> List.of_seq
```

`take_while (fun d -> d * d <= p)` 保证每个 `p` 只试除到根号为止——惰性在这里同时承担了正确性与效率。

**管道 3：数据统计**——filter 后 fold 出四元组统计量（示例文件里 `data` 是 8 条学生记录，这里取前 4 条示意）：

```ocaml
type record = { name : string; age : int; score : float }

let data = [
  { name = "Alice"; age = 20; score = 95.5 };
  { name = "Bob"; age = 21; score = 87.3 };
  { name = "Charlie"; age = 19; score = 92.0 };
]

let stats =
  List.to_seq data
  |> Seq.filter (fun r -> r.score >= 80.0)
  |> Seq.map (fun r -> r.score)
  |> Seq.fold_left
       (fun (count, sum, min_s, max_s) s ->
         (count + 1, sum +. s, min min_s s, max max_s s))
       (0, 0.0, max_float, neg_infinity)
```

**管道 4：分组聚合**——fold 进 `Map`，再从 `Map` 流出来算均值：

```ocaml
module IntMap = Map.Make(Int)

let group_by_age records =
  List.to_seq records
  |> Seq.fold_left (fun map r ->
    let current = try IntMap.find r.age map with Not_found -> (0, 0.0) in
    let count, sum = current in
    IntMap.add r.age (count + 1, sum +. r.score) map
  ) IntMap.empty
  |> IntMap.to_seq
  |> Seq.map (fun (age, (count, sum)) ->
       (age, count, sum /. float_of_int count))
  |> List.of_seq
```

注意 `IntMap.to_seq` 的输出按 key 升序——`Map` 是有序平衡树，分组结果天然带排序，`List.sort` 都省了。这条管道也是「序列作粘合剂」的示范：List 进、Map 中转、Seq 贯穿、List 出，每个容器只用它最擅长的一面。

### 25.9 实测坑（OCaml 5.4.1，MSYS2 UCRT64 发行实测）

**坑 1：`Unbound module Stream`——Stream 模块已不随标准库发行**

在 OCaml 5.4.1（MSYS2 UCRT64 发行）下，任何 `Stream.of_list ...` 都过不了编译：

```text
Error: Unbound module Stream
```

原因：`Stream` 在 OCaml 4.14 被标记 deprecated，5.0 起从发行中移出、转入独立的 `camlp-streams` 包。实测确认本工具链的标准库目录里既没有 `stream.cmi` 也没有 `stream.cma`——连 `-I` 手动指路都无从指起。

三条出路：

1. **新代码一律用 `Seq`**（本教程的立场，也是官方建议）；
2. 旧项目必须保留 Stream/Genlex 的，`opam install camlp-streams`，dune 里加 `(libraries camlp-streams)`；
3. 教学需要跑通传统 Stream 代码的，像示例文件 `21_streams_seq.ml` 那样，用 Seq 加一个 `mutable` 记录自己实现兼容层（40 余行，见 25.5），`of_list` / `of_string` / `from` / `next` / `peek` / `junk` / `empty` / `iter` 全齐。

**坑 2：`Seq.nth` 和 `Seq.sort` 不存在**

直觉以为该有的两个函数，读本地 `seq.mli`（553 行接口）权威确认：都没有。这不是疏漏，而是设计使然：惰性结构上的「随机取第 n 个」和「全量排序」都注定要线性走到位，标准库不提供一步到位的假象，让你显式地做。

取第 n 个元素，惯用 `Seq.drop` 加一次强制求值：

```ocaml
(* drop n 本身还是惰性的，Seq.find 强制它走到位 *)
let nth_opt n s = Seq.find (fun _ -> true) (Seq.drop n s)

let nth n s =
  match Seq.drop n s () with
  | Seq.Cons (x, _) -> x
  | Seq.Nil -> raise Not_found
```

第二种写法更直接：`Seq.drop n s` 是序列（函数），调用一次得到 `node`，匹配 `Cons` 即得元素，越界抛 `Not_found`，语义对齐 `List.nth`。

排序则老老实实经列表中转：

```ocaml
let sort cmp s = s |> List.of_seq |> List.sort cmp |> List.to_seq
```

反正排序必须看到全部元素，物化成列表不冤枉。

**附带两个小坑**：

- `Seq.find` 的返回类型是 `'a option`，与 `List.find`（直接返回元素、找不到抛 `Not_found`）不同，用 `Option.get` 或模式匹配收尾；
- 对无限序列调用 `Seq.length`、`List.of_seq`、无界的 `Seq.fold_left` 不会报错——只会永远不返回，程序挂死时先想想源头是不是无限的。

### 25.10 本章小结

- `Seq.t` 本质是 `unit -> Nil | Cons (元素, 剩余)` 的函数：不调用不计算，这就是惰性
- 生成：`Seq.unfold`（状态机，`None` 终止）、`Seq.init`、`Seq.forever`、`Seq.ints`
- 变换者（`map` / `filter` / `take` / `append` / `flat_map` / `zip`）只组合不计算；消费者（`fold_left` / `iter` / `for_all` / `find`）驱动管道前进
- 无限序列靠 `take` / `take_while` / `find` 取有限部分；`Seq.length`、`List.of_seq` 是禁手；手写时 `let rec f a b () = Cons (...)` 里的 `()` 是推迟递归的关键，漏掉即爆栈
- `Stream` 是单步推进的可变游标流：`next` 消费、`peek` 预读、`junk` 丢弃，解析器的传统工具；OCaml 5.x 发行已移除，用 `camlp-streams` 包或直接改用 `Seq`
- Seq 与 List 的取舍：大数据量、单遍处理、无限源头用 Seq（免中间分配）；小数据、多次访问、需要 O(1) 的 `List.length` 用 List
- 惰性 ≠ 记忆化：序列每次遍历都重算；水性来源（文件、Stream 游标）上的序列是一次性的，复用前先物化
- `Seq.nth` / `Seq.sort` 不存在：前者 `Seq.find (fun _ -> true) (Seq.drop n s)` 或直接匹配 node，后者经 `List.of_seq` / `List.sort` 中转

---

---

## 第 26 章 综合实战：成绩 CSV 分析与报告

对应示例：`examples/22_project.ml`

### 26.1 项目需求分析

我们来做一个完整的小项目：读取学生成绩 CSV 文件，做统计分析，生成报告写回文件。

这个项目会用到前面学过的很多知识：
- 模块系统（组织代码）
- 可变状态（Hashtbl、累加器）
- 数值计算（平均值、标准差、最小二乘拟合）
- I/O 与文件（CSV 读写）
- 错误处理（缺失值、异常）
- 测试（结果校验）

具体需求：
1. 生成模拟的成绩 CSV 数据（方便测试）
2. 解析 CSV 文件，处理缺失值
3. 逐科统计：平均分、最高分、最低分、标准差
4. 计算每科的 Top-N 排名（处理并列情况）
5. 计算两科成绩的相关性（最小二乘线性拟合）
6. 生成统计报告，写入新的 CSV 文件
7. 校验：写回后再读回来，确认数据一致
8. 清理临时文件

### 26.2 CSV 格式介绍

CSV（Comma-Separated Values）是最简单的表格数据格式之一：
- 每行是一条记录
- 字段之间用逗号分隔
- 第一行通常是表头（列名）
- 字段如果包含逗号、引号或换行，需要用引号包裹

一个简单的成绩 CSV 示例：
```
name,id,math,chinese,english
Alice,S0001,95.5,88.0,92.0
Bob,S0002,78.0,85.5,80.0
Charlie,S0003,90.0,,95.0
```

注意 Charlie 的语文成绩是空的——这就是缺失值。

完整的 CSV 格式还有很多细节（引号转义、换行处理等），但为了保持代码简洁，我们实现一个简化版：假设字段不包含逗号和引号。

### 26.3 数据类型定义

首先定义数据类型：

```ocaml
type student = {
  name : string;
  id : string;
  math : float option;
  chinese : float option;
  english : float option;
  physics : float option;
  chemistry : float option;
}

type subject =
  | Math
  | Chinese
  | English
  | Physics
  | Chemistry

let all_subjects = [Math; Chinese; English; Physics; Chemistry]

let subject_name = function
  | Math -> "math"
  | Chinese -> "chinese"
  | English -> "english"
  | Physics -> "physics"
  | Chemistry -> "chemistry"
```

成绩用 `float option` 类型表示——`Some score` 表示有成绩，`None` 表示缺失。

用变体类型表示科目，而不是用字符串，这样类型系统可以帮我们检查是否漏掉了某些科目。

### 26.4 CSV 生成器

为了测试，我们先写一个 CSV 生成器，生成带缺失值的随机成绩数据。

```ocaml
let generate_csv filename n =
  Random.self_init ();
  let names = [|
    "Alice"; "Bob"; "Charlie"; "Diana"; "Eve";
    "Frank"; "Grace"; "Henry"; "Iris"; "Jack";
    "Karen"; "Leo"; "Mona"; "Nick"; "Olivia";
    "Peter"; "Queenie"; "Rose"; "Sam"; "Tina";
    "Uma"; "Victor"; "Wendy"; "Xavier"; "Yvonne";
    "Zack"; "Amy"; "Brian"; "Catherine"; "David"
  |] in
  let oc = open_out filename in
  (* 写表头 *)
  output_string oc "name,id,math,chinese,english,physics,chemistry\n";
  (* 生成 n 条记录 *)
  for i = 0 to n - 1 do
    let name = names.(i mod Array.length names) ^
               if i >= Array.length names then string_of_int (i / Array.length names)
               else "" in
    let id = Printf.sprintf "S%04d" (i + 1) in
    (* 生成成绩，10% 概率缺失 *)
    let score _ =
      if Random.float 1.0 < 0.1 then ""
      else string_of_float (60.0 +. Random.float 40.0)
    in
    Printf.fprintf oc "%s,%s,%s,%s,%s,%s,%s\n"
      name id
      (score ()) (score ()) (score ()) (score ()) (score ())
  done;
  close_out oc
```

### 26.5 CSV 解析器

接下来是 CSV 解析器。先实现一个简单的按逗号分割的函数：

```ocaml
let split_comma line =
  let n = String.length line in
  let rec loop start i acc =
    if i >= n then
      List.rev (String.sub line start (i - start) :: acc)
    else if line.[i] = ',' then
      loop (i + 1) (i + 1) (String.sub line start (i - start) :: acc)
    else
      loop start (i + 1) acc
  in
  loop 0 0 []
```

然后解析整个文件：

```ocaml
let parse_csv filename =
  let ic = open_in filename in
  try
    (* 读取并跳过表头 *)
    let header_line = input_line ic in
    let _headers = split_comma header_line in
    
    let students = ref [] in
    begin try
      while true do
        let line = input_line ic in
        let fields = split_comma line in
        match fields with
        | name :: id :: math_s :: chinese_s :: english_s :: physics_s :: chemistry_s :: _ ->
            let parse_score s =
              if String.trim s = "" then None
              else Some (float_of_string s)
            in
            let student = {
              name; id;
              math = parse_score math_s;
              chinese = parse_score chinese_s;
              english = parse_score english_s;
              physics = parse_score physics_s;
              chemistry = parse_score chemistry_s;
            } in
            students := student :: !students
        | _ ->
            Printf.eprintf "Warning: skipping malformed line: %s\n" line
      done
    with End_of_file -> () end;
    
    close_in ic;
    List.rev !students
  with e ->
    close_in_noerr ic;
    raise e
```

解析逻辑：
1. 打开文件，读取第一行作为表头（暂时忽略）
2. 逐行读取，按逗号分割字段
3. 把字符串成绩转成 `float option`——空字符串表示缺失
4. 遇到格式不对的行，打印警告并跳过
5. 读到文件末尾时结束，返回所有学生记录

### 26.6 缺失值处理策略

真实世界的数据经常有缺失。处理缺失值的常见策略：

1. **删除法**：直接丢弃有缺失的记录。简单但可能丢失大量数据
2. **填充法**：用某个值填充缺失，比如 0、平均分、中位数
3. **忽略法**：计算统计量时跳过缺失值，只使用有效值

我们的项目采用**忽略法**——计算每科的统计量时，只使用有成绩的学生。

一个辅助函数：提取某科的所有有效成绩。

```ocaml
let subject_score student = function
  | Math -> student.math
  | Chinese -> student.chinese
  | English -> student.english
  | Physics -> student.physics
  | Chemistry -> student.chemistry

let valid_scores students subject =
  List.filter_map (fun s -> subject_score s subject) students
```

`List.filter_map` 是 `filter` + `map` 的组合——它把列表中返回 `Some x` 的元素的 `x` 收集起来，返回 `None` 的被过滤掉。

### 26.7 逐科统计：平均分、最高分、最低分、标准差

现在来计算每科的统计量。

```ocaml
type subject_stats = {
  subject : subject;
  count : int;
  mean : float;
  max : float;
  min : float;
  std_dev : float;
}

let compute_stats students subject =
  let scores = valid_scores students subject in
  let n = List.length scores in
  if n = 0 then {
    subject; count = 0;
    mean = 0.0; max = 0.0; min = 0.0; std_dev = 0.0;
  } else
    let sum = List.fold_left (+.) 0.0 scores in
    let mean = sum /. float_of_int n in
    let sum_sq = List.fold_left (fun acc x -> acc +. (x -. mean) ** 2.0) 0.0 scores in
    let variance = sum_sq /. float_of_int n in   (* 总体标准差 *)
    let std_dev = sqrt variance in
    let max = List.fold_left max_float (List.hd scores) (List.tl scores) in
    let min = List.fold_left min_float (List.hd scores) (List.tl scores) in
    { subject; count = n; mean; max; min; std_dev }
```

标准差（Standard Deviation）衡量数据的离散程度：
- 标准差小：成绩集中在平均分附近
- 标准差大：成绩分布很分散

注意这里用的是**总体标准差**（除以 n），而不是样本标准差（除以 n-1）。因为我们把这批学生当作总体来看待。

### 26.8 Top-N 排名与并列规则

接下来计算每科的 Top-N 排名。

并列的处理：如果第 N 名和第 N+1 名分数相同，应该都算进 Top-N（也就是并列排名时，Top-N 可能多于 N 个人）。

```ocaml
type ranked_student = {
  name : string;
  score : float;
  rank : int;
}

let top_n students subject n =
  let scored =
    students
    |> List.filter_map (fun s ->
         match subject_score s subject with
         | None -> None
         | Some score -> Some (s.name, score))
    |> List.sort (fun (_, a) (_, b) -> compare b a)   (* 降序 *)
  in
  
  let rec assign_rank acc rank prev_score = function
    | [] -> List.rev acc
    | (name, score) :: rest ->
        let new_rank =
          if score = prev_score then rank
          else List.length acc + 1
        in
        if new_rank > n then List.rev acc
        else
          assign_rank ({ name; score; rank = new_rank } :: acc) new_rank score rest
  in
  match scored with
  | [] -> []
  | (name, score) :: rest ->
      assign_rank [{ name; score; rank = 1 }] 1 score rest
```

排名算法（标准的「并列同名次，跳过后续名次」方式）：
- 第 1 名是最高分
- 如果当前分数和上一名相同，排名相同
- 如果不同，排名 = 已处理人数 + 1
- 当排名超过 N 时停止

比如分数 [100, 95, 95, 90] 的排名是 [1, 2, 2, 4]——两个第 2 名，然后直接跳到第 4 名。

### 26.9 两科成绩相关性：最小二乘线性拟合

两科成绩有没有相关性？比如数学好的人物理也好吗？

我们用**最小二乘线性拟合**来求两科成绩的线性关系 y = ax + b，然后看拟合的好坏程度。

最小二乘的公式：
- a = (nΣxy - ΣxΣy) / (nΣx² - (Σx)²)
- b = (Σy - aΣx) / n

```ocaml
type linear_fit = {
  slope : float;       (* 斜率 a *)
  intercept : float;   (* 截距 b *)
  r_squared : float;   (* 决定系数 R² *)
}

let linear_regression students subj_x subj_y =
  (* 只取两科都有成绩的学生 *)
  let paired =
    List.filter_map (fun s ->
      match subject_score s subj_x, subject_score s subj_y with
      | Some x, Some y -> Some (x, y)
      | _ -> None
    ) students
  in
  let n = List.length paired in
  if n < 2 then { slope = 0.0; intercept = 0.0; r_squared = 0.0 }
  else
    let sum_x = ref 0.0 in
    let sum_y = ref 0.0 in
    let sum_xy = ref 0.0 in
    let sum_x2 = ref 0.0 in
    let sum_y2 = ref 0.0 in
    List.iter (fun (x, y) ->
      sum_x := !sum_x +. x;
      sum_y := !sum_y +. y;
      sum_xy := !sum_xy +. x *. y;
      sum_x2 := !sum_x2 +. x *. x;
      sum_y2 := !sum_y2 +. y *. y
    ) paired;
    
    let nf = float_of_int n in
    let denominator = nf *. !sum_x2 -. !sum_x *. !sum_x in
    if abs_float denominator < 1e-12 then
      { slope = 0.0; intercept = 0.0; r_squared = 0.0 }
    else
      let slope = (nf *. !sum_xy -. !sum_x *. !sum_y) /. denominator in
      let intercept = (!sum_y -. slope *. !sum_x) /. nf in
      
      (* 计算 R² *)
      let mean_y = !sum_y /. nf in
      let ss_tot = List.fold_left (fun acc (_, y) -> acc +. (y -. mean_y) ** 2.0) 0.0 paired in
      let ss_res = List.fold_left (fun acc (x, y) ->
        let y_pred = slope *. x +. intercept in
        acc +. (y -. y_pred) ** 2.0
      ) 0.0 paired in
      let r_squared =
        if ss_tot < 1e-12 then 1.0
        else 1.0 -. ss_res /. ss_tot
      in
      
      { slope; intercept; r_squared }
```

R²（决定系数）衡量拟合的好坏：
- R² = 1：完美拟合，所有点都在直线上
- R² = 0：拟合还不如直接取平均值
- R² 越接近 1，说明两科成绩的线性相关性越强

### 26.10 报告生成与写回

现在把所有统计结果整理成报告，写入 CSV 文件。

```ocaml
let write_report filename students =
  let oc = open_out filename in
  
  (* 1. 总体统计 *)
  Printf.fprintf oc "=== Subject Statistics ===\n";
  Printf.fprintf oc "Subject,Count,Mean,Max,Min,StdDev\n";
  List.iter (fun subj ->
    let stats = compute_stats students subj in
    Printf.fprintf oc "%s,%d,%.2f,%.2f,%.2f,%.2f\n"
      (subject_name subj) stats.count stats.mean stats.max stats.min stats.std_dev
  ) all_subjects;
  
  (* 2. Top-N 排名（每科 Top 5） *)
  Printf.fprintf oc "\n=== Top 5 Rankings ===\n";
  List.iter (fun subj ->
    Printf.fprintf oc "\n--- %s ---\n" (subject_name subj);
    Printf.fprintf oc "Rank,Name,Score\n";
    let top = top_n students subj 5 in
    List.iter (fun t ->
      Printf.fprintf oc "%d,%s,%.2f\n" t.rank t.name t.score
    ) top
  ) all_subjects;
  
  (* 3. 科目间相关性（数学 vs 物理、语文 vs 英语） *)
  Printf.fprintf oc "\n=== Correlation Analysis ===\n";
  Printf.fprintf oc "Subject_X,Subject_Y,Slope,Intercept,R_squared\n";
  let pairs = [(Math, Physics); (Chinese, English); (Math, Chemistry)] in
  List.iter (fun (sx, sy) ->
    let fit = linear_regression students sx sy in
    Printf.fprintf oc "%s,%s,%.4f,%.4f,%.4f\n"
      (subject_name sx) (subject_name sy)
      fit.slope fit.intercept fit.r_squared
  ) pairs;
  
  close_out oc
```

### 26.11 结果校验：写回后再读回来对比

为了确保我们的 CSV 生成和解析是正确的，做一个简单的校验：
1. 生成一个 CSV 文件
2. 读回来，对比数据是否一致

```ocaml
let validate_csv original_scores filename =
  let parsed = parse_csv filename in
  let rec compare a b =
    match (a, b) with
    | ([], []) -> true
    | (x :: xs, y :: ys) ->
        x.name = y.name && x.id = y.id &&
        x.math = y.math && x.chinese = y.chinese &&
        x.english = y.english && x.physics = y.physics &&
        x.chemistry = y.chemistry &&
        compare xs ys
    | _ -> false
  in
  compare original_scores parsed
```

在生产环境中，这种「读写一致性检查」是一种简单但有效的测试手段。

### 26.12 临时文件清理

测试过程中生成的临时文件，用完后应该清理掉。

```ocaml
let cleanup_temp_files filenames =
  List.iter (fun f ->
    if Sys.file_exists f then
      try Sys.remove f with _ -> ()
  ) filenames
```

`Sys.remove` 删除文件。用 `try...with` 包裹，防止删除失败导致程序崩溃——清理失败不是致命错误。

### 26.13 完整主程序

把所有部分串起来：

```ocaml
let () =
  let input_file = "scores.csv" in
  let report_file = "report.txt" in
  
  (* 生成测试数据 *)
  Printf.printf "Generating sample data...\n";
  generate_csv input_file 30;
  
  (* 解析 CSV *)
  Printf.printf "Parsing CSV file...\n";
  let students = parse_csv input_file in
  Printf.printf "Loaded %d students\n" (List.length students);
  
  (* 生成报告 *)
  Printf.printf "Generating report...\n";
  write_report report_file students;
  Printf.printf "Report written to %s\n" report_file;
  
  (* 输出一些摘要信息到终端 *)
  Printf.printf "\n--- Summary ---\n";
  List.iter (fun subj ->
    let stats = compute_stats students subj in
    Printf.printf "%s: avg=%.2f, max=%.2f, min=%.2f, std=%.2f (n=%d)\n"
      (subject_name subj) stats.mean stats.max stats.min stats.std_dev stats.count
  ) all_subjects;
  
  Printf.printf "\nDone!\n"
```

### 26.14 运行说明

运行方式：

```bash
cd /Users/xulun/code/programming/ocaml
ocaml examples/22_project.ml
```

运行后会生成两个文件：
- `scores.csv`：30 个学生的随机成绩数据
- `report.txt`：统计分析报告

你可以用文本编辑器打开 `report.txt` 查看详细的统计结果。

### 26.15 扩展练习

如果你想进一步练习，可以考虑这些扩展：

1. **CSV 解析器增强**：支持带引号的字段、引号转义、Windows 换行符
2. **更多统计量**：中位数、众数、四分位数
3. **总分排名**：计算每个学生的总分，生成总分排名
4. **等级划分**：把成绩分成 A/B/C/D/E 五个等级，统计各等级人数
5. **直方图**：用文本字符画成绩分布直方图
6. **导出为 JSON**：把统计结果导出为 JSON 格式
7. **命令行参数**：用 `Sys.argv` 让用户指定输入文件和输出文件

### 26.16 本章小结

- 完整的项目需要：数据类型定义、解析、计算、输出、校验、清理
- CSV 格式简单但细节多，生产环境建议用成熟的 CSV 库
- 缺失值处理策略：删除法、填充法、忽略法，各有适用场景
- 逐科统计：平均分、最高分、最低分、标准差
- Top-N 排名要处理并列情况（同名次，跳过后续排名）
- 最小二乘线性拟合可以衡量两科成绩的相关性
- R² 决定系数衡量拟合优度，越接近 1 越好
- 结果校验：写回后再读回来对比，确保读写一致
- 临时文件用完及时清理

---

## 第 27 章 错误处理：option / result 与绑定运算符

对应示例：`examples/23_error_handling.ml`

### 27.1 三种失败通道

OCaml 处理失败有三个层次：异常（不可见、易忘）、`option`
（失败无细节）、`result`（失败带原因、类型逼你处理）。第 12 章
讲过异常；本章讲后两者以及把它们写顺的语法——绑定运算符。

```ocaml
let safe_div a b = if b = 0 then None else Some (a / b)

let parse_int s =
  match int_of_string_opt s with
  | Some n -> Ok n
  | None -> Error (Printf.sprintf "not an int: %S" s)
```

### 27.2 嵌套 match 的痛苦与组合子

三层可能失败的操作套起来，手写 match 是三层缩进；用
`Option.bind` / `Option.map`（或 `Result.bind` / `Result.map`）
可以拉平一层。`Stdlib` 里两者都齐全，还有
`Result.product`（两个独立计算任一失败即失败）、
`Result.map_error`（只改错误信息）、
`Option.to_result ~none:...`（给 None 补上原因）。

### 27.3 绑定运算符的真相：let\* 是算子值，要自己接线

OCaml 4.08 引入了 `let*` / `and*` / `let+` / `and+` 绑定运算符，
让失败链可以“直着写”：

```ocaml
let word_len_times2 s =
  let open Option_syntax in
  let* parts = safe_head (String.split_on_char ' ' s) in
  let* n = int_of_string_opt parts in
  Some (n * 2)
```

**关键事实（很多人第一反应都错）**：`let*` 不是“脱糖后去查找
名为 `bind` 的函数”，而是脱糖为一个**字面名为 `( let* )` 的算子值**：

```ocaml
let* x = e in body    ≡    ( let* ) e (fun x -> body)
```

`Stdlib.Option` / `Stdlib.Result` 只提供了 `bind` / `map` /
`product` 函数，**并没有定义这些算子**——所以直接
`let open Result in let* ...` 会报：

```
Error: Unbound value ( let* )
```

想用绑定运算符，必须自己接线（算子名遵循普通作用域规则，
可以定义在顶层，也可以收进模块再 open）：

```ocaml
module Result_syntax = struct
  let ( let* ) = Result.bind
  let ( and* ) = Result.product
  let ( let+ ) r f = match r with Ok x -> Ok (f x) | Error e -> Error e
end
```

两个实测细节：

1. **`( let+ )` 的参数序是“值在前、函数在后”**，恰好与
   `Option.map` / `Result.map`（函数在前）相反，不能直接把
   `map` 赋给 `( let+ )`。
2. `Stdlib.Option` 连 `product` 都没有，`and*` 也要自己写。

### 27.4 and\* 的语义由实现说了算：fail-fast vs 累积

`and*` 脱糖到 `( and* )`——同一个写法，换个实现就是换种语义：

- `Result.product`：任一失败即失败（fail-fast）；
- 自制 `Validation` 模块：把两边错误列表 `@` 拼起来，**所有
  错误一起报**——表单校验最想要的形态。

示例 23 的第 6 节完整实现了 60 行不到的 `Validation`，
同一个 `validate_user`，错误全量列出：

```
all bad  : Error [name is empty; age too large (max 150); email missing '@']
```

### 27.5 选型法则

- 异常：编程错误、真正异常的路径（不出现在类型里）；
- option：失败没什么可说的（查找、除零、解析）；
- result：失败要带原因、调用方必须处理。

`try ... with Sys_error msg -> Error msg` 是把异常世界接进
result 世界的标准桥。

### 27.6 本章小结

- `let*`/`and*`/`let+` 是算子值，Stdlib 不自带，需自己接线；
- 接线时注意 `( let+ )` 值在前的参数序；
- `and*` 语义看实现：product 是 fail-fast，自制 Validation 可累积；
- 负数字面量作实参要加括号：`f "bob" (-1) "x"`。

---

## 第 28 章 GADT：广义代数数据类型

对应示例：`examples/24_gadts.ml`

### 28.1 让构造子决定类型参数

普通变体：所有构造子造出同一个 `t`。GADT：每个构造子
**声明自己造出什么类型**：

```ocaml
type _ value_kind =
  | KInt : int value_kind
  | KBool : bool value_kind
  | KString : string value_kind
```

于是能写出“一个函数、按构造子返回不同类型”的代码——
这在普通变体上不可能：

```ocaml
let default (type a) (k : a value_kind) : a =
  match k with
  | KInt -> 0
  | KBool -> false
  | KString -> ""
(* default KInt : int，default KBool : bool *)
```

### 28.2 类型安全的动态值（存在类型）

把值连同类型标签打包，取回时只有标签对得上才拿得到——
模式匹配的**类型细化**保证了安全：

```ocaml
type cell = Cell : 'a * 'a value_kind -> cell

let cell_to_int (c : cell) : int option =
  match c with
  | Cell (n, KInt) -> Some n      (* 这里 n 自动是 int *)
  | _ -> None
```

**实测坑（OCaml 5.4.1）**：存在类型的 GADT 模式匹配必须给
函数补**显式参数/返回类型标注**（如上面的 `(c : cell) : int option`），
否则报 `This instance of int is ambiguous: it would escape the
scope of its equation`。原则：凡是有存在类型参与的 match，
把边界类型写清楚。

### 28.3 招牌应用：well-typed by construction 的表达式 AST

```ocaml
type _ expr =
  | Const : int -> int expr
  | BoolConst : bool -> bool expr
  | Add : int expr * int expr -> int expr
  | Lt : int expr * int expr -> bool expr
  | If : bool expr * 'a expr * 'a expr -> 'a expr

let rec eval : type a. a expr -> a = function
  | Const n -> n
  | BoolConst b -> b
  | Add (x, y) -> eval x + eval y
  | Lt (x, y) -> eval x < eval y
  | If (c, t, e) -> if eval c then eval t else eval e
```

`Add (BoolConst true, Const 1)` 直接编译错误；`If` 的两个分支
类型不同也直接编译错误。求值器的类型是 `'a expr -> 'a`：
“这个 AST 求出来是什么类型”在构造时就定了，求值器不需要
任何运行期类型检查。

两个语法细节：

- 递归函数要写 `type a.`（显式全量多态标注），否则递归调用
  无法在不同类型实例上泛化；
- match 臂里的 GADT 类型标注要加括号：`| (Get : a Effect.t) -> ...`
  ——不带括号的 `| Get : a Effect.t ->` 在 5.4.1 是**语法错**
  （第 29 章效应匹配同此）。

### 28.4 类型相等见证

```ocaml
type (_, _) eq = Eq : ('a, 'a) eq
let cast : type a b. (a, b) eq -> a -> b = fun Eq x -> x
```

`Eq` 只能造出 `('a, 'a) eq`——拿到 `(a, b) eq` 就等于拿到
`a = b` 的证明，`cast` 里匹配 `Eq` 时编译器把 a、b 统一，转换
自然安全。`(int, string) eq` 的值无法构造，假证明被编译器挡死。

### 28.5 多态递归需要显式标注

```ocaml
type 'a nest = NNil | NCons of 'a * ('a * 'a) nest

let rec depth : 'a. 'a nest -> int = function
  | NNil -> 0
  | NCons (_, t) -> 1 + depth t
```

每往下一层元素类型都变成 `('a * 'a)`，普通推断会失败；
`'a. 'a nest -> int`（注意带点的形式）告诉编译器“对所有类型
实例都成立”。GADT 上的 `eval` 用 `type a.` 同理。

### 28.6 什么时候用 GADT

用：构造子蕴含类型信息（typed AST/DSL）、类型索引族、
安全转换。代价：类型推断变弱（标注变多）、穷尽性检查变弱、
学习曲线陡——先穷尽普通变体的可能性。

### 28.7 本章小结

- GADT = 构造子声明返回什么类型参数；
- 存在类型参与 match 时必须显式标注边界类型，否则 escape 报错；
- `type a.` / `'a.` 显式标注是多态递归的开关；
- match 臂的 GADT 标注要括号。

---

## 第 29 章 OCaml 5 并发：Domain 与 Effect

对应示例：`examples/25_domains_effects.ml`

OCaml 5 的两大新基元：**Domain**（真正的并行执行单元）与
**Effect**（可恢复的效应处理器）。字节码和原生码都支持。

### 29.1 Domain：spawn 与 join

```ocaml
let d = Domain.spawn (fun () -> 42) in
Domain.join d    (* 等待并取回结果；异常也会传到 join 处 *)
```

机器核数用 `Domain.recommended_domain_count ()`
（**实测坑**：5.4.1 没有 `Domain.cpu_count`）。

### 29.2 共享状态：Atomic 与 Mutex

- 普通 `ref` 跨 domain 并发更新会**丢更新**（读-改-写不原子）；
- `Atomic`（如 `Atomic.fetch_and_add`）适合单字计数——
  **只支持 int**；int64 计数要么换 int（OCaml 的 int 是 63 位），
  要么上锁；
- `Mutex.lock / unlock` 保护复合操作（先读后写、多字段一致）。

示例 25 用“分块 + Atomic 累加”做并行数组求和，与串行结果
逐位一致，可作模板。

### 29.3 Effect：声明、perform、处理

效应是“可恢复的异常”——往内置可扩展变体 `Effect.t` 里加构造子：

```ocaml
type _ Effect.t += Xchg : int -> int Effect.t

let comp1 () = Effect.perform (Xchg 0) + Effect.perform (Xchg 1)
```

OCaml 5.3+ 给深处理器（deep handler）提供了直接语法糖
（`effect` 是关键字，`k` 是被挂起的计算——delimited continuation）：

```ocaml
let demo () =
  let open Effect.Deep in
  try comp1 () with
  | effect (Xchg n), k -> continue k (n + 1)   (* = 3 *)
```

同一个 `comp1`，换处理器就是换语义（`continue k (-n)` 即取相反数）。
未被处理的效应在 perform 处以 `Effect.Unhandled` 异常爆出。
状态效应 Get/Set、以及官方手册的“控制反转”（把 `iter` 推模式
生产者变成 `Seq` 拉模式序列的 `invert`）都是几行处理器的功夫，
见示例第 6、7 节。

**实测坑（5.4.1）两连**：

1. 用记录式 `Effect.Deep.match_with` 时，`effc` 必须补显式返回
   类型标注（`((a, 'b) continuation -> 'b) option`），否则效应
   构造子的类型细化报 escape/ambiguous 错——`try ... with effect`
   语法糖则完全免标注，优先用糖；
2. 无参效应（如 `Get : int Effect.t`）的处理器里，被操作的值
   （如状态 `cell`）要显式标注（`let cell : int ref = ...`），
   否则同样 escape 报错。续延变量 `k` 在 effect 模式里**不允许
   标注**（"Invalid continuation pattern: only variables and _
   are allowed"）。

### 29.4 一次性续延纪律

OCaml 的续延是**一次性的**（linear）：每个捕获的 `k` 必须恰好
被 `continue` / `discontinue` 一次。恢复第二次当场抛
`Effect.Continuation_already_resumed`（示例第 8 节有受控复现）；
一次也不恢复则泄漏 fiber 内存与其持有的资源。

推论：**多解回溯不能靠“把 k 恢复两次”实现**——要么重跑计算
枚举答案，要么用建在这些基元上的搜索库。这也是 OCaml 选择
一次性续延的原因：便宜（无需拷栈帧）、不破坏套接字/文件描述符
等线性资源的纪律。

### 29.5 生态坐标

`Domain` + `Effect` 是基元层；实际写异步 IO 用 Eio（5.x 官方
推荐的 direct-style 并发库）或 Lwt/Async（monadic 风格）。
效应手册章节仍标注 experimental，API 可能微调。

### 29.6 本章小结

- Domain 是并行，Atomic/Mutex 护共享，fetch_and_add 只吃 int；
- 效应 = 可恢复异常；深处理器有 try-with-effect 语法糖；
- 记录式 match_with 要给 effc 补返回类型标注；
- 续延一次性：恰好 continue/discontinue 一次。

---

## 第 30 章 ocamllex：词法分析器生成器

对应示例：`examples/26_ocamllex/`（`ocamllex_expr.mll` + `main.ml`）

### 30.1 从手写到生成

第 21 章手写了词法器：一个字符一个字符地啃、一个状态一个
状态地维护。`ocamllex` 把正则部分自动化：你写“正则 → 动作”
的规则表，它生成一个快得多的表驱动词法器（本例 22 状态、
473 转移）。

### 30.2 .mll 文件的结构

```ocaml
{ (* header：原样拷进生成的 .ml *) }
let digit = ['0'-'9']        (* 命名正则片段 *)
rule token = parse
  | [' ' '\t' '\r']+      { token lexbuf }            (* 跳过 *)
  | '\n'                  { Lexing.new_line lexbuf; token lexbuf }
  | digit+ '.' digit* (('e'|'E') ('+'|'-')? digit+)? as lx
                          { FLOAT (float_of_string lx) }
  | digit+ as lx          { INT (int_of_string lx) }
  | ['a'-'z' 'A'-'Z'] ['a'-'z' 'A'-'Z' '0'-'9' '_']* as lx
                          { match lx with
                            | "let" -> LET | _ -> ID lx }
  | '+' { PLUS }
  | eof { EOF }
  | _ as c { error lexbuf (Printf.sprintf "unexpected %C" c) }
```

要点：

- `lexbuf` 是隐式参数，动作里调 `token lexbuf` 驱动下一轮；
- **最长匹配胜出**（maximal munch），同长才看声明顺序——
  所以 `3.14` 不会被整数规则截断；
- 换行动作里调 `Lexing.new_line`，`lex_curr_p.pos_lnum` 行号才准；
- `Lexing.from_string` / `from_channel` 造 lexbuf。

### 30.3 构建链与模块名陷阱

```bash
ocamllex ocamllex_expr.mll        # 生成 ocamllex_expr.ml
ocamlc -w -24 ocamllex_expr.ml main.ml -o 26_ocamllex.exe
```

**实测坑**：生成的模块名取自 `.mll` 文件名。本教程示例统一
`NN_名称.ml` 命名，而 `26_ocamllex.mll` 会生成非法模块名
（数字开头，引用它直接语法错）——所以 ocamllex 示例放在
`examples/26_ocamllex/` 子目录，用合法名 `ocamllex_expr.mll`，
`build.ps1` 内置了这条两段式构建链。

### 30.4 站在生成的词法器上写解析器

生成的 `token` 函数配上“一格 lookahead”（缓存 peek），
第 21 章的递归下降文法原样可用。示例 26 实现了带
`let` 绑定、`if-then-else`、四则/取余/幂（右结合）、
一元负号的表达式求值器，词法错误带行列定位：

```
lex error: line 2, col 5: unexpected character '$'
```

### 30.5 何时用 ocamllex

规则多、要行号定位、要性能时值得；几十行的玩具语言手写
词法器（第 21 章式）更直观。解析器生成器方面，社区标准是
menhir（`ocamlyacc` 的现代后继），本教程不展开。

### 30.6 本章小结

- .mll = header + 规则表；最长匹配；`Lexing.new_line` 记行号；
- 模块名来自文件名，避开数字开头；
- ocamllex 之后接手写递归下降是最实用的组合。

---

## 第 31 章 坑清单与最佳实践

本章按层次收集本教程全程（包括 2026 年 Windows 全量复验）
踩过的坑。前面各章的“实测坑”在这里汇总成速查表。

### 31.1 语法层的坑

**坑 1：int 和 float 运算符不同**

OCaml 的整数和浮点数有完全不同的运算符：
- 整数：`+`、`-`、`*`、`/`、`mod`
- 浮点数：`+.`、`-.`、`*.`、`/.`、`**`

```ocaml
1 + 2          (* 正确：整数加法 *)
1.0 +. 2.0     (* 正确：浮点数加法 *)
1 +. 2         (* 错误：整数和浮点数不能混加 *)
```

这是 OCaml 最常被吐槽的点之一，但它是有意为之的设计。OCaml 不做隐式类型转换，避免了很多因隐式转换导致的 bug。你需要什么类型，就显式地用什么类型。

**坑 2：注释不能嵌套？不，OCaml 的注释可以嵌套**

```ocaml
(* 外层注释
   (* 内层注释 —— 完全合法！ *)
   外层继续
*)
```

OCaml 的注释可以嵌套，这和 C、Java 等语言不同。临时注释掉一大段代码时很方便，不用担心里面的注释导致提前结束。

但要注意：很多其他 ML 语言（比如 Standard ML）的注释是不能嵌套的。如果你同时写多种 ML 方言，容易搞混。

**坑 3：if 表达式的两个分支类型必须一致**

```ocaml
if x > 0 then 1 else "negative"   (* 错误：分支类型不一致 *)
```

`if` 是表达式，它有返回值。两个分支必须返回同类型的值，否则类型不一致。

如果你确实需要返回不同类型的东西，用变体类型把它们包起来：

```ocaml
type result = Int of int | Str of string
let answer = if x > 0 then Int 1 else Str "negative"
```

**坑 4：match 的穷尽性警告不要忽视**

```ocaml
let head = function
  | x :: _ -> x
  (* 警告：这个 pattern-matching 不是穷尽的 *)
```

编译器会警告你没有覆盖所有情况（漏掉了 `[]`）。不要忽视这个警告——它通常意味着你的代码有 bug。

如果某个情况真的不可能发生，用 `assert false` 或 `failwith` 显式标记：

```ocaml
let head = function
  | x :: _ -> x
  | [] -> failwith "head: empty list"
```

**坑 5：函数参数之间不要加逗号**

```ocaml
f (x, y)     (* 这不是两个参数！这是一个元组参数 *)
f x y        (* 这才是两个参数 *)
```

很多初学者会写成 `f(x, y)`，这在 OCaml 中是合法的，但意思是「调用 f，参数是一个元组 (x, y)」，而不是「调用 f，两个参数 x 和 y」。

OCaml 的函数调用语法就是空格分隔参数，没有括号也没有逗号。

### 31.2 类型系统的坑

**坑 6：值限制（Value Restriction）**

```ocaml
let cache = ref None
(* 警告：此表达式的类型是 '_weak1 option ref，不是多态的 *)
```

值限制说的是：只有「语法上的值」（比如常量、函数、构造子）才能拥有多态类型。表达式（比如函数调用的结果）不能是多态的。

`ref None` 是一个表达式（`ref` 函数的调用结果），所以它不能是多态的——类型变量会被弱化成 `'_weak1`，意思是「这个类型还没确定，但一旦确定了就不能变了」。

解决方法：
- 如果知道具体类型，加上类型标注：`let cache : int option ref = ref None`
- 如果想要多态，改成函数：`let make_cache () = ref None`

**坑 7：弱化的多态类型变量（_weak1）**

`'_weak1` 这种类型变量叫做「弱多态变量」。它的特点是：第一次使用时会被实例化为具体类型，之后就固定了，不能再变。

```ocaml
let cache = ref None
!cache            (* 类型是 '_weak1 option *)
cache := Some 1;  (* 现在 '_weak1 被确定为 int *)
!cache            (* 类型是 int option *)
cache := Some "x" (* 错误：类型不匹配，已经是 int 了 *)
```

弱多态是值限制的产物。如果你看到 `'_weak1`，通常意味着你的代码某处多态性不够，需要检查一下。

**坑 8：记录字段名冲突**

```ocaml
type point2d = { x : float; y : float }
type point3d = { x : float; y : float; z : float }

let p = { x = 1.0; y = 2.0 }   (* 这是 point2d 还是 point3d？ *)
```

OCaml 中，记录字段名是全局的（在同一个模块内）。如果两个记录类型有相同的字段名，后定义的会遮蔽先定义的。

上面的代码中，`p` 的类型是 `point3d`，因为 `point3d` 后定义，它的字段名遮蔽了 `point2d` 的。

解决方法：
- 把不同的记录类型放在不同的模块里
- 使用变体类型代替
- 字段名加前缀（比如 `p2d_x`、`p3d_x`）

**坑 9：变体构造子的作用域**

```ocaml
type color = Red | Green | Blue
type traffic_light = Red | Yellow | Green

let x = Red   (* 这是哪个 Red？ *)
```

和记录字段一样，变体构造子的名字也是全局的。后定义的 `traffic_light` 的 `Red` 和 `Green` 会遮蔽 `color` 的。

如果需要同时使用两种类型，用模块命名空间来区分：

```ocaml
module Color = struct
  type t = Red | Green | Blue
end

module TrafficLight = struct
  type t = Red | Yellow | Green
end

let x = Color.Red
let y = TrafficLight.Red
```

### 31.3 模块系统的坑

**坑 10：透明约束会暴露内部类型**

```ocaml
module type S = sig
  type t
  val make : int -> t
end

module M : S = struct
  type t = int
  let make x = x
end

let _ = M.make 42 + 1   (* 能编译吗？ *)
```

答案是：不能。因为签名中 `type t` 是抽象的，透明约束下它仍然是抽象的。外部不知道 `M.t` 是 `int`，所以不能直接当 `int` 用。

但如果签名中写了 `type t = int`，透明约束下外部就知道了：

```ocaml
module type S = sig
  type t = int
  val make : int -> t
end

module M : S = struct
  type t = int
  let make x = x
end

let _ = M.make 42 + 1   (* 可以！透明约束下 t = int 可见 *)
```

**坑 11：Functor 是 applicative 还是 generative？**

OCaml 的 functor 是 applicative 的——用相同的参数调用同一个 functor，得到的模块的类型是相同的。

```ocaml
module S1 = Set.Make(String)
module S2 = Set.Make(String)

let s1 = S1.singleton "hello"
let s2 = S2.singleton "world"
let _ = S1.union s1 s2   (* 能编译吗？ *)
```

答案是：可以。因为 OCaml 的 functor 是 applicative 的，`Set.Make(String)` 两次应用得到的类型相同。

但如果参数是匿名模块（结构），情况就不一样了：

```ocaml
module S1 = Set.Make(struct type t = string let compare = compare end)
module S2 = Set.Make(struct type t = string let compare = compare end)
```

这两个 `S1.t` 和 `S2.t` 是不同的类型——因为两个 `struct ... end` 是不同的模块，即使它们的内容完全一样。

**坑 12：include 的使用时机**

`include` 看起来很方便，但要谨慎使用。过度使用 `include` 会让模块的内容来源变得不清晰——你不知道某个函数是模块自己定义的，还是从哪个地方 include 来的。

经验法则：
- 模块之间是「扩展」关系时，用 `include`（比如 `IntSetExtended` 扩展 `IntSet`）
- 模块之间是「使用」关系时，用普通的模块调用（`M.f x`）
- 不要为了少写几个前缀就 `include` 一个大模块

### 31.4 可变状态的坑

**坑 13：= 和 == 的区别**

- `=` 是结构相等：比较内容
- `==` 是物理相等：比较内存地址

```ocaml
let a = [1; 2; 3]
let b = [1; 2; 3]

a = b     (* true：内容相同 *)
a == b    (* false：不同的内存对象 *)
```

对于不可变值，你几乎总是应该用 `=`。`==` 主要用于可变值（ref、数组），判断两个引用是不是同一个。

**坑 14：ref 的比较**

```ocaml
let r1 = ref 0
let r2 = ref 0

r1 = r2     (* true 还是 false？ *)
r1 == r2    (* true 还是 false？ *)
```

答案：
- `r1 = r2` 是 `true`——结构相等，比较的是 ref 指向的内容
- `r1 == r2` 是 `false`——物理相等，比较的是引用本身是不是同一个

如果你想比较两个引用的内容，用 `=`。如果你想判断两个引用是不是同一个对象（修改 r1 会不会影响 r2），用 `==`。

**坑 15：Hashtbl 的键比较**

标准库的 `Hashtbl` 默认使用结构相等（`=`）和 `Hashtbl.hash`。也就是说，两个内容相同的字符串会被认为是同一个键。

但 `Hashtbl` 有一个参数化版本 `Hashtbl.Make`，你可以自定义相等函数和哈希函数。如果你用物理相等（`==`）作为键的比较方式，那行为就完全不同了——两个内容相同的对象可能被当作不同的键。

使用第三方库的哈希表时，一定要看清楚它的相等语义。

### 31.5 I/O 的坑

**坑 16：input_line 保留换行符吗？**

不保留。`input_line` 返回的字符串**不包含**末尾的换行符。

```ocaml
(* 假设文件内容是 "hello\nworld\n" *)
let line = input_line ic
(* line = "hello"，不是 "hello\n" *)
```

这意味着，如果你逐行读取再逐行写入，原始文件的换行符格式可能会改变（比如 Windows 的 `\r\n` 会变成 `\n`）。

如果需要保留原始格式，用 `really_input_string` 或 `input_char` 自己处理。

**坑 17：缓冲区刷新问题**

输出是带缓冲的。如果你调用了 `print_string` 但没看到输出，可能是因为缓冲区还没满，内容还没真正输出。

```ocaml
print_string "Thinking...";
(* 做一些耗时操作 *)
print_endline "done"
```

你可能期望先看到 "Thinking..."，然后过一会儿看到 "done"。但实际上，"Thinking..." 可能一直缓冲着，直到 "done" 才一起输出。

解决方法：在需要立即显示的输出后调用 `flush stdout`。

**坑 18：文件描述符泄漏**

如果打开了文件但忘记关闭，就会泄漏文件描述符。泄漏多了，程序会达到系统的文件描述符上限，无法再打开新文件。

最容易出问题的场景是异常：正常路径下有关闭文件的代码，但异常路径下漏掉了。

解决方法：用 `Fun.protect ~finally` 或 `with_file` 模式（见第 22 章），确保无论正常返回还是抛出异常，文件都会被关闭。

### 31.6 顶层结构与短语终结的坑（本教程实测重灾区）

本教程 12–22 号示例初版全部编译失败，病根就是这一节的内容——
这些坑**与平台无关**，macOS 上同样编译不过：

- **顶层不允许 `let ... in`**。`let x = e in ...` 是表达式，
  只能出现在函数体/`let () = ...` 块内部。顶层的语句链要包一层
  `let () = ...`。
- **定义后面紧跟“裸调用”必须补 `;;`**。反例：

  ```ocaml
  let section n title =
    Printf.printf "\n---- %d) %s ----\n" n title;
    print_endline (String.make 50 '-')     (* <- 少了 ;; *)
  (* 注释 *)
  section 1 "..."                          (* 被吞进应用链！ *)
  ```

  症状极具迷惑性：报错不在病灶处，而是 `The function
  print_endline has type string -> unit`（应用了过多参数）、
  `CamlinternalFormatBasics.End_of_format`（printf 吞了后面的
  原子）或某个孤儿的 `;;` 语法错。看到这三类错，优先往回找
  缺 `;;` 的定义。
- **定义后跟定义（`let`/`type`/`module`/`exception`）不需要 `;;`**：
  解析器能自行分辨。反过来，`;` 结尾的裸语句后面也不能直接跟
  新定义（要么 `;;`，要么并入同一个 `let () =` 块）。
- **跨块引用**：`let a = ... in ...;;` 里的 `a` 不进入后续短语
  的作用域。裸语句要用前面的变量，就合并进同一个 `let () =`。
- **用异常跳出多重循环**：`try` 必须包住整个 `while`，写在循环
  **后面**的 `(try () with Exit -> ())` 永远接不住（本教程
  优快排里真实修过的一个潜在运行时崩溃）。

### 31.7 绑定运算符、GADT 与 Effect 的坑（5.4.1 实测）

- `let*` / `and*` / `let+` 是**算子值**，Stdlib 没有自带，
  `let open Result in let* ...` 直接 `Unbound value ( let* )`——
  要自己接线（第 27 章）。
- `( let+ )` 参数序是值在前；`Option.map` / `Result.map` 是函数
  在前，不能直接赋给它。
- 负数字面量作实参加括号：`validate_user "bob" (-1) "x"`，
  否则 `-1` 按二元减号解析成部分应用。
- match 臂里的 GADT 类型标注**必须带括号**：
  `| (Get : a Effect.t) -> ...`；不带括号是语法错。
- 存在类型（GADT 打包值、效应构造子）参与的 match，函数边界
  要显式标注类型，否则 `int is ambiguous: it would escape the
  scope of its equation`。
- 记录式 `Effect.Deep.match_with` 的 `effc` 要补返回类型标注
  （`((a, 'b) continuation -> 'b) option`）；effect 模式里的续延
  变量 `k` 不允许标注。
- 一次性续延：同一个 `k` 恢复两次抛
  `Effect.Continuation_already_resumed`；多解回溯不能靠 resume
  两次。
- 首类模块的 package type 不支持参数化类型方程：
  `(module S : SET with type 'a t = 'a S.t)` 非法；把元素类型拆成
  独立的 `elt` 再 `with type elt = ...`（第 14 章示例 12 的修法）。
- class 方法里用开放对象类型 `< ...; .. >` 报 unbound type
  variables：值绑定会自动泛化而 class 不会，要写显式多态方法
  `method m : 'a. (< ...; .. > as 'a) -> ...`（第 24 章）。
- `Domain.cpu_count` 不存在（用 `recommended_domain_count`）；
  `Atomic.fetch_and_add` 只支持 int。
- `Stream` 模块不在 5.4 标准库发行里；`Seq.nth` / `Seq.sort` /
  `print_bool` 不存在（速查见第 2.8 节）。

### 31.8 Windows 平台的坑（MSYS2 UCRT64 实测）

详见第 2.8 节，速查：

- 从原生 shell 调用编译器要设 `OCAMLLIB`（否则
  `Unbound module Stdlib`）；
- `ocamlopt` 需要单独安装 `flexdll` 包（`flexlink` 不在 ocaml
  包的依赖里）；
- `ocamlc -o x` 生成**无后缀 PE**，PowerShell `&` 不肯执行——
  显式 `.exe`；字节码运行还要 PATH 上有 `ocamlrun`、链接了
  unix 的还要 `OCAMLLIB` 找 stublibs 的 DLL；
- `Unix` 模块要手工 `-I ... unix.cma` 链接（macOS 同样）；
- 数字开头文件名触发 Warning 24；多文件项目的模块名必须合法；
- 临时目录：`Filename.get_temp_dir_name ()` 取的是 `TMP` 而
  不是 `TEMP`（两者可能不同，检查残留时两个都要看）。

### 31.9 macOS 平台的坑（MacPorts + OCaml 5.5.0，2026-09-20 实测）

- **工具链不在 `/usr/bin`**：MacPorts 装在 `/opt/local/bin/ocamlc`
  （Homebrew 是 `/opt/homebrew/bin`），`ocamlc -where` 给出
  `/opt/local/lib/ocaml`。脚本按「环境变量 → PATH → 常见目录」三级探测。
- **`Unix` 模块必须显式 `-I +unix`**（不写也能编过，但会吐
  `Alert ocaml_deprecated_auto_include`，那是**告警**）：

  ```bash
  ocamlc -w -24 -I +unix unix.cma  -o build/15_algorithms     examples/15_algorithms.ml
  ocamlopt -w -24 -I +unix unix.cmxa -o build/15_algorithms_opt examples/15_algorithms.ml
  ```

  写 `-I "$(ocamlc -where)/unix"` 效果相同。
- **`ocamlopt` 开箱可用**，不需要 Windows 上那套 `flexdll`；代价是原生
  编译比字节码慢一个量级（全量 26 个示例 byte+native 约 3 分钟）。
- **中间产物会掉在源文件旁边**：`ocamlc x.ml` 把 `x.cmi` / `x.cmo`
  写在 `x.ml` 同一个目录里，直接编译 `examples/*.ml` 会污染源码目录。
  本教程的两个入口都先把源码复制一份到 `build/` 再编译，产物留在 `build/`。
- **「零告警」这条在 macOS 上真会咬人**。本机 5.5.0 实测报出两类：
  `Warning 26 [unused-var]`（`let x = ... in` 定义了却没人用）和
  `Warning 23 [useless-record-with]`（`{ r with ... }` 把字段列全了，
  `with` 是多余的）。教学代码里「定义完看都不看一眼」的写法最容易踩前者——
  要么把它打印出来（教程里更合适），要么写成 `let _ = ...`。

### 31.10 最佳实践

**实践 1：优先使用不可变数据**

默认用不可变数据结构（列表、元组、不可变记录），只有在有充分理由时才用可变数据。

不可变数据的好处：
- 更容易推理——值不会被别人修改
- 没有副作用——函数是纯的，测试简单
- 天然线程安全——不需要锁
- 可以安全共享——不用担心别名问题

**实践 2：用模式匹配代替 if**

```ocaml
(* 不推荐 *)
if l = [] then ... else ...

(* 推荐 *)
match l with
| [] -> ...
| x :: xs -> ...
```

模式匹配更具表达力，而且编译器会检查穷尽性——如果你漏掉了某个情况，编译器会警告你。`if l = []` 就没有这种保障。

同样，对于 `option` 和 `result`，优先用模式匹配处理，而不是 `Option.is_some` + `Option.get` 这种不安全的组合。

**实践 3：用 option / result 代替异常**

预期内的错误用 `option` 或 `result` 类型，让类型系统强迫调用者处理。异常留给真正意外的情况。

```ocaml
(* 不推荐：用异常 *)
let find key map =
  if not (mem key map) then raise Not_found
  else ...

(* 推荐：用 option *)
let find key map =
  if not (mem key map) then None
  else Some ...
```

`option` 让错误在类型中可见，调用者无法忽视。异常是隐式的，类型系统不追踪。

**实践 4：合理使用抽象类型保护不变量**

如果你的数据结构有不变量（比如有序列表必须有序、日期必须合法），用不透明约束把内部表示隐藏起来，只暴露能保证不变量的操作。

让类型系统帮你保证「非法状态不可表示」——只要你拿到了这个类型的值，它就一定是合法的。

**实践 5：让类型系统帮你写对代码**

类型系统不是阻碍，而是工具。你可以通过设计好的类型来减少 bug：

- 用变体类型表示「多种情况」，而不是用字符串或整数编码
- 用 `option` 表示可能不存在的值，而不是用特殊值（-1、空字符串等）
- 用 `result` 表示可能失败的操作，而不是用异常
- 用抽象类型保护不变量
- 用私有类型控制构造

**一个好的类型设计胜过 100 个单元测试。** 类型系统在编译时为你保证所有可能的值都是合法的，而测试只能覆盖有限的情况。

### 31.11 本章小结

语法层的坑：
- 整数和浮点数运算符不同，不能混用
- 注释可以嵌套（和 SML 不同）
- if 表达式的分支类型必须一致
- match 的穷尽性警告一定要重视
- 函数参数用空格分隔，不要加逗号

类型系统的坑：
- 值限制导致弱多态类型变量（`'_weak1`）
- 记录字段名在模块内是全局的，会互相遮蔽
- 变体构造子同理

模块系统的坑：
- 透明约束下，签名中抽象的类型仍然抽象
- Functor 是 applicative 的，但匿名结构每次都是新类型
- include 要慎用，避免来源不清

可变状态的坑：
- `=` 是结构相等，`==` 是物理相等
- ref 的 `=` 比较内容，`==` 比较引用本身
- Hashtbl 默认用结构相等，自定义的要看清

I/O 的坑：
- `input_line` 不保留换行符
- 输出是缓冲的，必要时手动 flush
- 用 `Fun.protect` 防止文件描述符泄漏

顶层结构的坑：
- 顶层不允许 `let ... in`，语句链包 `let () =`
- 定义后跟裸调用必须补 `;;`；三类怪错先怀疑它
- 用异常跳多重循环，try 要包住整个循环

绑定运算符/GADT/Effect 的坑：
- `let*` 是算子值，要自己接线；`( let+ )` 值在前
- GADT 标注带括号；存在类型参与时边界要标全
- effect 模式的 k 不可标注；续延一次性
- 5.4 无 `Domain.cpu_count` / `print_bool` / `Stream` 模块

Windows 的坑（MSYS2）：
- 原生 shell 要设 `OCAMLLIB`
- 原生编译要装 flexdll
- 产物加 `.exe` 后缀；字节码运行依赖 ocamlrun 在 PATH

最佳实践：
- 优先使用不可变数据
- 用模式匹配代替 if
- 用 option/result 代替异常
- 用抽象类型保护不变量
- 让类型系统帮你写对代码
- 失败链用绑定运算符直着写，语义随 `( and* )` 实现选
