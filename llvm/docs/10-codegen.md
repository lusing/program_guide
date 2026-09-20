# 10 · 代码生成：llc 与目标三元组

> 对应示例：`examples/10_codegen/`（demo.ll）

IR 到机器码的最后一级台阶。`llc` 是 LLVM 后端的命令行入口——clang 编 `.o`、rustc 出机器码、第 20 章 MiniLang 编 `.exe`，走的都是这条通路。本章弄清三件事：**目标三元组**（为谁生成）、**DataLayout**（目标内存长什么样）、以及**交叉编译**为什么在 LLVM 里只是换个参数。

## 10.1 llc 基本功

```powershell
$uc = 'G:\scoop\apps\msys2\current\ucrt64\bin'
$ex = 'G:\code\guide\llvm\examples\10_codegen'
$out = 'G:\code\guide\llvm\build\10_codegen'

& "$uc\llc.exe" "$ex\demo.ll" -o "$out\demo.s"                          # IR → 汇编
& "$uc\llc.exe" "$ex\demo.ll" -filetype=obj -o "$out\demo.o"            # IR → 目标文件
& "$uc\clang.exe" "$out\demo.o" -o "$out\demo.exe"                      # 目标文件 → exe
& "$out\demo.exe"
```

（实测输出）：

```text
385          ; sum_squares(10) = 1+4+9+...+100
==== 10 ok ====
```

`demo.ll` 里有 `square`（一次乘法）和一个调用它的 alloca 风格循环。看 x86-64 汇编里的关键行（AT&T 语法，`源, 目标`）：

```text
demo.s:18:   imull   %ecx, %eax       # square 的乘法实打实在
```

> **注意**：`llc` 出的 `.o` 不含 C 运行库——直接双击不能跑，得由 `clang`（驱动）补上 crt、libc 和链接器（这就是上面第三行的意义；第 20 章拆解完整链路）。`-filetype=asm` 是默认；`-filetype=obj` 走 MC 直接出目标文件（不经过文本汇编，快且无语法歧义）。

## 10.2 目标三元组：IR 里的"收件地址"

每个模块头部都有：

```llvm
target triple = "x86_64-pc-windows-gnu"
```

四段式 `<arch>-<vendor>-<os>-<abi>`，常见样本：

| 三元组 | 含义 |
|---|---|
| `x86_64-pc-windows-gnu` | 64 位 Windows，MinGW ABI（本教程主线） |
| `x86_64-pc-windows-msvc` | 64 位 Windows，MSVC ABI（scoop clang 的默认） |
| `aarch64-linux-gnu` | 64 位 ARM Linux |
| `wasm32-unknown-emscripten` | WebAssembly |

它的作用是让**后端**选对指令集、**中端**应用目标相关变换（比如 32 位 int 的大小）。`llc --mtriple=...` 可以**覆盖**模块里的三元组——这就是交叉编译的全部秘密：

```powershell
# 同一份 IR，交叉到 ARM64 Linux
& "$uc\llc.exe" --mtriple=aarch64-linux-gnu "$ex\demo.ll" -o "$out\demo.aarch64.s"
```

（实测产物节选）：

```text
demo.aarch64.s:9:   mul   w0, w0, w0     # square 的乘法，ARM 语法（目标在前）
demo.aarch64.s:38:  bl    square         # 函数调用 = branch-with-link
```

**没有交叉工具链、没有配置，一个参数就跨过去了**——LLVM 后端全家桶都在一个二进制里。查本机 llc 认识哪些目标：

```powershell
& "$uc\llc.exe" --version        # Registered Targets 一长串
```

（实测节选）：aarch64 / amdgcn / arm / arm64 …（MSYS2 构建开了全部主流目标；scoop 精简版没有 llc 可用，见 01 章）。

## 10.3 DataLayout：目标的"物理常数表"

```llvm
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
```

念法（挑重点）：

- `e`——小端（little-endian）；
- `m:w`——符号名修饰（mangling）风格：Windows；
- `i64:64`——i64 自然对齐 64 位；
- `f80:128`——x87 长双精度占 128 位对齐；
- `n8:16:32:64`——原生整数宽度集合（向量化器用来挑向量元素）；
- `S128`——栈对齐 128 位。

中端优化会**直接消费**这张表：结构体布局、GEP 常量折叠、向量化宽度……所以**给 JIT/llc 的模块如果 DataLayout 和目标不一致，要么报错要么生成错码**。实战规则：模块的 DataLayout 一律以后端为准（`clang -emit-llvm` 自动带、IRBuilder 的模块交给 `J->getDataLayout()` 回填——第 11 章实测过这条规则）。

## 10.4 看懂产物：三件工具

```powershell
& "$uc\llvm-readobj.exe" --file-headers "$out\demo.o"    # COFF 头：Machine、节表
& "$uc\llvm-nm.exe" "$out\demo.o"                        # 符号表：谁 exported 谁 undefined
Get-Content "$out\demo.s"                                # 直接读汇编
```

（`llvm-nm` 实测节选）：

```text
                 U __stack_chk_guard     ← undefined：链接期从运行库找
0000000000000000 T square                ← text 段已定义
0000000000000020 T sum_squares
```

`U`（undefined）列表就是**这个模块向 linker 开的采购单**——第 20 章链接失败排查全靠它。

## 10.5 -O 级别与调度器

llc 也有优化级别，但和 opt 的 -O2 是**两回事**：

- `opt -O2`（中端）：IR→IR 变换，平台无关；
- `llc -O2`（后端）：指令选择、调度、寄存器分配质量。默认 O2。

常用后端旋钮：

```powershell
& "$uc\llc.exe" --mcpu=x86-64-v3 demo.ll -o -            # 认 AVX2 等新指令集
& "$uc\llc.exe" --debug-only=isel demo.ll -o nul 2>&1 | Select-String 'SelectionDAG'   # 看指令选择（debug 版才有）
```

> **实测坑**：`--mcpu=native`（自动探测本机）在虚拟机/新 CPU 上偶有误判；教学产物要可移植就固定 `x86-64`，要演示向量再显式 `x86-64-v3`。

## 10.6 本章小结

- `llc` = IR→汇编/目标文件；`-filetype=obj` 直出 `.o`；链接靠 clang 驱动补运行库。
- 三元组 = IR 的收件地址；`--mtriple` 一键交叉；DataLayout 是目标的物理常数表，以后端为准。
- `llvm-readobj`/`llvm-nm` 验尸产物；`U` 符号 = 给 linker 的采购单。
- llc 的 -O 是后端质量（调度/分配），与 opt 的中端 -O 分层不混淆。

| 坑 | 解法 |
|---|---|
| llc 出的 .o 不能直接跑 | 链接缺 crt/libc，用 clang 驱动链接 |
| 模块 DataLayout 与目标不符 | 以后端为准回填（clang 自动 / JIT 用 J->getDataLayout()） |
| 想看交叉汇编没有工具链 | llc 本来就能交叉，--mtriple 即可 |
| --debug-only 无输出 | release 构建 stripped，只有带 assert 的构建有 |

下一章是"不走 llc 也能跑"的另一半世界：ORC JIT。
