# 02 · 工具链与运行方式

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
> （OCaml 5.4.1）上全量验证示例后总结的实战经验，
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

---
上一章：[01 · 认识 OCaml](overview.md) ｜ 下一章：[03 · 程序结构与求值](structure.md) ｜ 返回：[README](../README.md)
