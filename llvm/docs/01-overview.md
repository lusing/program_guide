# 01 · LLVM 全景与工具链就位

> 对应示例：`examples/01_overview/`（hello.c → IR → 运行）

这一章解决三件事：LLVM 到底是什么、它和 clang 的关系、以及**在你这台 Windows 机器上用哪套工具**。LLVM 教程最大的劝退点不是概念，而是环境——网上教程假设你在 Linux 用包管理器一条命令装好全家桶，而 Windows 上你可能同时装着三五个互相不认识的 clang。所以本章先把工具链钉死，后面 23 章都不再纠结环境问题。

## 1.1 LLVM 是什么

一句话：**LLVM 是一个"编译器零件库"，核心资产是一套中立的中间表示（IR）和围绕它的全套加工机器**。

传统编译器（如 GCC）是一体机：前端（词法/语法/语义）+ 中端（优化）+ 后端（生成机器码）焊死在一个流程里。LLVM 的设计把三段拆开：

```text
 源语言前端                LLVM 中端/后端                 目标平台
┌──────────┐   LLVM IR   ┌───────────────────┐   机器码   ┌──────────┐
│ clang(C) │ ──────────▶ │ 优化管线 → 代码生成 │ ────────▶ │ x86-64   │
│ flang(F) │   文本/位码  │ (libLLVM 全家桶)   │  .s/.o    │ ARM/RISC-V│
│ Rust     │             │                   │           │ WebAssembly│
│ Swift    │             │                   │           │ …几十个   │
│ 你的语言  │             │                   │           │           │
└──────────┘             └───────────────────┘           └──────────┘
```

关键设计决策：**IR 是唯一的接口契约**。任何语言只要翻译成 LLVM IR，就免费获得：

- 一整套工业级优化（`-O0` 到 `-O3`、向量化、内联、循环变换……）
- 几十个目标的代码生成（x86、ARM、RISC-V、WASM……）
- 链接器 lld、调试器 lldb、JIT 执行引擎 ORC

这就是"喂鱼不如授渔"的编译器版：你写前端（把你的语言翻译成 IR），LLVM 包办剩下的一切。第 12 章起我们会亲手做一个这样的前端（玩具语言 MiniLang），第 24 章收官时它能编出真正的 `.exe`。

### LLVM 和 clang 的关系

- **LLVM**：库和工具的集合（`libLLVM`、`opt`、`llc`、`lli`……），本教程的主角。
- **clang**：LLVM 官方的 C/C++ 前端，"LLVM 生态里最大的一个客户"。
- **lld / lldb**：链接器 / 调试器，同样是"用 LLVM 库造出来的工具"。

日常说"装 LLVM"常常实际装的是 clang 工具集——这是本章 1.3 节第一个坑的来源。

## 1.2 生态地图（谁在用 LLVM 干活）

| 项目 | 身份 | 用 LLVM 干什么 |
|---|---|---|
| clang | C/C++/ObjC 前端 | C 系语言 → IR |
| flang | Fortran 前端 | Fortran → IR |
| Rust (rustc) | Rust 编译器 | Rust → IR（借用检查后） |
| Swift | Swift 编译器 | Swift → IR |
| Zig | Zig 编译器 | 自带 LLVM 后端生成机器码 |
| Julia | 科学计算语言 | JIT：边运行边把 IR 编成机器码 |
| MLIR | LLVM 的"IR 生成器" | 多层 IR 基础设施（AI 编译器的底座） |
| CUDA / ISPC / … | GPU 语言 | 设备代码 → IR → 目标指令 |
| 本教程第 12-24 章 | MiniLang | 你自己的语言 → IR |

看到规律了吗——**"做一个语言"的捷径就是对接 LLVM**。想理解 Rust 的性能从哪来、Julia 为什么能快，都绕不开 IR 这一层的知识。

## 1.3 本机工具链盘点（Windows 实况）

本教程在你这台机器上实测，涉及三套资源。**它们不平等，分工如下**：

| 资源 | 版本 | 内容 | 在本教程中的角色 |
|---|---|---|---|
| MSYS2 UCRT64 的 LLVM | 22.1.8 | **完整版**：opt/llc/lli/llvm-as/dis/FileCheck/llvm-config + libLLVM 静态库/动态库 + 全部 C++ 头文件 | **主线**，所有实操 |
| scoop 的 LLVM | 23.1.1 | **精简版**：只有 clang/clang++/clang-cl/lld/lldb/clangd/clang-tidy 等前端工具，**没有 opt/lli/llvm-config，也没有开发库和头文件** | 第 22 章 clang 工具链专题 |
| `G:\github\lang\llvm-project` 源码 | monorepo 主干（≥24 时代检出） | 完整源码树（llvm/clang/lld/lldb/mlir 同仓） | 第 23 章源码导览的阅读材料（带新旧版本差异对照表） |

> **实测坑（重要）**：scoop 装的 `llvm` 包是官方 Windows 发行版的精简形态——`bin` 里没有 `opt.exe`、`lli.exe`、`llc.exe`、`llvm-config.exe`，`lib` 里没有 `lib\cmake\llvm` 开发配置，`include` 里没有完整的 `llvm/IR/*.h`。**它只能当 clang 前端工具集用，做不了 IR 实验和库开发**。本教程主线必须用 MSYS2 UCRT64 里的完整 LLVM。网上说"装好 LLVM 就有 opt"的教程，在 Windows+scoop 组合下不成立。
>
> 另一个连带坑：PATH 里第一个 `clang` 可能来自 Swift 工具链（本机如此），`clang --version` 和你以为的那个未必是同一个。**动手前先跑下面的就位检查**。

### 就位检查（每台新机器先跑这个）

```powershell
# 1. 找到 MSYS2 UCRT64 根目录（本机是 G:\scoop\apps\msys2\current\ucrt64，通过 scoop 安装）
$uc = 'G:\scoop\apps\msys2\current\ucrt64\bin'

# 2. 逐个点名，全部存在才齐活
foreach ($t in 'opt','lli','llc','llvm-as','llvm-dis','llvm-config','FileCheck','g++','clang') {
    Test-Path "$uc\$t.exe"     # 应该输出 9 个 True
}

# 3. 确认版本
& "$uc\llvm-config.exe" --version
& "$uc\clang.exe" --version
```

（实测输出）：

```text
22.1.8
clang version 22.1.8 (https://github.com/msys2/MINGW-packages ...)
Target: x86_64-w64-windows-gnu
```

### macOS 上的同一件事（本机实况）

换到 macOS，**不要去找"22.1.8 这个版本"**——MacPorts 上只有 19.1.7 / 21.1.8 / 23.1.0。选 **23**，判据是**头文件布局**：

```bash
ls /opt/local/libexec/llvm-21/include/llvm/Plugins/     # 不存在：21 还是老位置
ls /opt/local/libexec/llvm-23/include/llvm/Plugins/     # PassPlugin.h：与 22 一致
ls /opt/local/libexec/llvm-21/include/llvm/Passes/PassPlugin.h   # 老位置
```

第 6/7 章的插件第一件事就是 `#include "llvm/Plugins/PassPlugin.h"`，21 上直接编不过。其余用到的 API（`Triple` 对象、`parseIR(MemoryBufferRef)`、`getProcessSymbolsJITDylib`）在 23 上行为一致；唯一要改的是 `OptimizationLevel`（23 变成裸 enum，见 7.3）。

三个 macOS 专属的安装/使用要点：

1. `sudo port install llvm-23 clang-23` 之后，工具在 `/opt/local/libexec/llvm-23/bin`，**不在 PATH 上**。
2. **MacPorts 的 llvm-23 不装 FileCheck 可执行文件**——`port contents llvm-23` 里只有 `libLLVMFileCheck.a` 和 `llvm/FileCheck/FileCheck.h`。第 21 章的做法是用官方那份库自己链一个驱动（`tools/filecheck_main.cpp`，`run-all.sh` 会自动构建），语义和真的 FileCheck 一致。
3. **clang 要显式 `-isysroot $(xcrun --show-sdk-path)`**：MacPorts 的 clang 不认 Xcode 的隐式 SDK 查找，少了它连 `stdio.h` 都找不到（C++ 侧表现为 libc++ 报 `mbstate_t`/`EOF` 未声明）。

验证入口是 `./run-all.sh`（build.ps1 的 shell 镜像），判定项与 build.ps1 逐项对齐，另加两条："编译日志必须为空"（即零告警）和"shared/static 双通道输出逐字节一致"。

### 为什么是 UCRT64 而不是别的 MSYS2 环境

MSYS2 有多个子系统：`mingw64`（gcc，msvcrt）、`ucrt64`（gcc，UCRT 运行时）、`clang64`（clang）、`msys`（POSIX 模拟层）。本教程选 UCRT64：

- LLVM 官方包在 MSYS2 仓库里以 ucrt64 为主力维护；
- UCRT 是 Windows 10+ 自带的现代 C 运行库，和系统无缝；
- 本仓库其他教程（OCaml 等）也用 UCRT64，环境复用。

> **实测坑**：三套 LLVM **不能混用**。scoop 的 clang 23 目标是 `x86_64-pc-windows-msvc`（MSVC ABI），MSYS2 的 LLVM 22 目标是 `x86_64-w64-windows-gnu`（MinGW ABI）。用 scoop clang 编译的程序**不能链接** MSYS2 的 libLLVM 库，反之亦然。IR 文本（`.ll`）倒是可以跨版本流通（见 1.5 节末尾）。

## 1.4 工具箱速览：接下来 23 章会反复用到的工具

| 工具 | 干什么 | 一句话记忆 |
|---|---|---|
| `clang -S -emit-llvm` | C/C++ → 文本 IR | "看 clang 怎么翻译" |
| `llvm-as` / `llvm-dis` | 文本 IR ↔ 位码 bitcode | "IR 的汇编器/反汇编器" |
| `lli` | 直接解释/JIT 执行 IR | "IR 的解释器，秒验正确性" |
| `opt` | 跑优化 pass 管线 | "IR 的加工机床" |
| `llc` | IR → 目标平台汇编/目标文件 | "后端入口" |
| `FileCheck` | 按模式匹配校验输出 | "编译器人的断言库" |
| `llvm-config` | 报出编译 LLVM 程序所需的旗标 | "库用户的贴心小棉袄" |
| `llvm-nm` / `llvm-readobj` | 看目标文件符号/结构 | "产物验尸" |
| `lld` / `clang`（驱动） | 链接 | "最后一公里" |

## 1.5 第一个实验：亲眼看到 IR

`examples/01_overview/hello.c` 是一个普通的 C 程序（递归 fib + printf）。三步走：

```powershell
$ex = 'G:\code\guide\llvm\examples\01_overview'
$uc  = 'G:\scoop\apps\msys2\current\ucrt64\bin'

# ① C → 文本 IR（-O1 让输出可读性最好；-O0 会满是 alloca 细节，第 4 章讲）
& "$uc\clang.exe" -S -emit-llvm -O1 -target x86_64-pc-windows-gnu "$ex\hello.c" -o hello.ll

# ② 用 lli 直接执行 IR——不经过任何传统编译
& "$uc\lli.exe" hello.ll

# ③ 对照：正常原生编译运行
& "$uc\clang.exe" "$ex\hello.c" -o hello_native.exe
.\hello_native.exe
```

（实测输出，①②③的输出完全一致）：

```text
fib(10) = 55
==== 01 ok ====
```

打开 `hello.ll`（节选，完整文件在 `build/01_overview/hello.ll`）：

```llvm
; ModuleID = 'G:\...\hello.c'
target datalayout = "e-m:w-p270:32:32-..."     ; 目标内存布局（第 10 章细讲）
target triple = "x86_64-pc-windows-gnu"        ; 目标三元组（第 10 章细讲）

@.str = private unnamed_addr constant [14 x i8] c"fib(10) = %d\0A\00"   ; 字符串常量

define dso_local noundef i32 @main() ... {     ; int main(void)
  %1 = tail call fastcc i32 @fib(i32 noundef 10)
  %2 = tail call i32 (ptr, ...) @printf(ptr ... @.str, i32 noundef %1)
  %3 = tail call i32 @puts(ptr ... @str)
  ret i32 0
}

define internal fastcc i32 @fib(i32 noundef range(i32 0, 11) %0) ... {
  br label %2
2:                                                ; preds = %6, %1
  %3 = phi i32 [ 0, %1 ], [ %10, %6 ]            ; ← 注意：没有递归调用！
  %4 = phi i32 [ %0, %1 ], [ %9, %6 ]
  %5 = icmp samesign ult i32 %4, 2
  br i1 %5, label %11, label %6
6:
  %7 = add nsw i32 %4, -1
  %8 = tail call fastcc i32 @fib(i32 noundef %7) ; 累加 fib(n-1)
  %9 = add nsw i32 %4, -2
  %10 = add nsw i32 %3, %8                       ; fib(n-2) 转成了迭代累加
  br label %2
11:
  %12 = add nsw i32 %3, %4
  ret i32 %12
}
```

第一次看不用全懂，有三个观察点就够了：

1. **IR 是文本文件**。你手写的 `.ll` 和 clang 生成的 `.ll` 是同一种语言——第 2 章你就要手写一个。
2. **递归 fib 被优化成了循环**（`phi` 那几行就是循环变量，第 4 章讲）。C 里写的 `fib(n-1) + fib(n-2)`，到 IR 里只剩一个递归调用。优化器不尊重你的写法，只尊重语义。
3. **`%1`、`%3` 这类无名值**：IR 里每个指令结果都是"值"（SSA，第 4 章重点），没起名字就自动编号。

### IR、bitcode、机器码的关系

```text
                    文本 .ll（人读人写）
                       │  llvm-as          llvm-dis
                       ▼                      │
                    位码 .bc（紧凑二进制，可当"中间产物缓存"）
                       │  opt（优化仍在 IR 层）
                       ▼
                    优化后 IR
                       │  llc / clang
                       ▼
              .s 汇编 / .o 目标文件 → lld/clang 链接 → .exe
                       │  或 lli / ORC JIT
                       ▼
                    直接在内存里执行
```

`llvm-as`/`llvm-dis` 做的就是第一层互换（本章 build 脚本已验证往返无损）。

> **版本互通实测**：IR 文本可以跨版本流通——用 scoop clang 23（加 `-target x86_64-pc-windows-gnu` 指定成 MinGW 目标）生成的 `.ll`，MSYS2 的 lli 22 能直接执行、opt 22 能正常加工（第 22 章有专门实验）。但库与工具本体不能混用（见 1.3 节 ABI 坑）。

## 1.6 本教程怎么学

每章三步：**读讲解 → 跑示例 → 改代码再跑**。示例全部可复现：

```powershell
cd G:\code\guide\llvm
pwsh -ExecutionPolicy Bypass -File build.ps1 -All              # 全部示例
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 02_first_ir   # 单章
```

判定标准：每步命令退出码 0，且每个可运行示例打印自己的结束标记（`==== NN ok ====`）。

路线图（⭐ = 本教程特色重点章）：

- **IR 层**（02-05）：手写 IR、类型系统、SSA/phi、优化管线
- **Pass 层**（06-07⭐）：写自己的优化/分析 pass（新 PassManager）
- **C++ API 层**（08-11⭐）：用程序生成 IR、Value 对象模型、代码生成、ORC JIT
- **实战**（12-20⭐⭐）：MiniLang 从词法分析一路长成能编 `.exe` 的完整编译器
- **工程化**（21-23）：FileCheck 测试、clang 工具链、LLVM 源码导览
- **收官**（24⭐⭐）：MiniLang v1.0 + 全书坑清单

## 1.7 本章小结

- LLVM = IR + 围绕 IR 的加工机器；前端各自造，中后端全家共享。
- 本机三套资源：**MSYS2 UCRT64 LLVM 22 是主线**（完整版），scoop LLVM 23 是前端工具精简版（第 22 章用），`G:\github\lang\llvm-project` 源码是现代 monorepo 检出（第 23 章导览，附新旧版本差异对照表）。
- `clang -S -emit-llvm` 看翻译，`lli` 秒验，`opt` 加工，`llc` 出机器码。
- 三套 ABI 不互通；IR 文本可跨版本。

### 坑位清单（各章还会展开）

| 坑 | 一句话 | 详见 |
|---|---|---|
| scoop LLVM 没有 opt/lli/llvm-config | 只能当前端工具集 | 1.3 |
| PATH 里的 clang 可能来自 Swift 工具链 | 动手前先 `--version` 点名 | 1.3 |
| MSVC 与 MinGW ABI 不互通 | 编译/链接同一套 | 1.3 |
| 旧教材的 `i32*` 指针写法已废弃 | LLVM 15+ 只认不透明指针 `ptr` | 2.7 |
| 网上 Kaleidoscope 教程的 `llvm/Passes/PassPlugin.h` 已搬家 | 22 里在 `llvm/Plugins/PassPlugin.h` | 6 章 |
| macOS 没有 LLVM 22，且 llvm-21 还是老头文件位置 | MacPorts 选 23：Plugins/PassPlugin.h 与 22 一致 | 1.3 |
| MacPorts 的 llvm-2x 不装 FileCheck 可执行文件 | 用 libLLVMFileCheck 自己链驱动（tools/） | 1.3 / 21 章 |
| MacPorts 的 clang 找不到 stdio.h / 链接报 library 'System' not found | 显式 `-isysroot $(xcrun --show-sdk-path)` | 1.3 |
