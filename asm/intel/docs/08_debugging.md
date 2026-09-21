# 调试方法

汇编程序由于贴近硬件，错误往往难以直接定位。本章介绍常用的调试工具与方法，帮助你高效排查问题。

- **Windows**：x64dbg（图形界面，适合入门）、WinDbg（内核与崩溃分析）
- **macOS**：lldb（随 Xcode Command Line Tools 提供）
- 两平台通用的排查清单见 [常见错误排查](#常见错误排查)，其中第 7–10 条是 macOS 特有的坑。

## x64dbg 使用简介

[x64dbg](https://x64dbg.com/) 是一款开源的 Windows 64 位用户态调试器，界面直观，适合汇编初学者。

### 基本流程

1. **打开程序**：`File → Open` 选择 `.exe`，或在命令行 `x64dbg.exe path\to\program.exe`。
2. **加载符号**：程序加载后停在入口点（Entry Point），可在反汇编窗口查看指令。
3. **设置断点**：在反汇编窗口左侧双击地址行，或按 `F2` 设置/取消断点（INT3 断点）。
4. **单步执行**：
   - `F7`（Step Into）：单步进入，遇 `CALL` 跟踪进入函数内部。
   - `F8`（Step Over）：单步越过，遇 `CALL` 不进入，直接执行完整个函数。
   - `F9`（Run）：运行至下一断点。
5. **查看状态**：
   - 右侧寄存器面板实时显示所有寄存器与标志位（变化的寄存器会高亮红色）。
   - 下方内存窗口可输入地址查看内存内容。
   - 栈窗口显示 RSP 附近的数据，便于跟踪调用链。

### 常用快捷键

| 快捷键 | 功能 |
|--------|------|
| F2 | 设置/取消断点 |
| F7 | 单步进入（Step Into） |
| F8 | 单步越过（Step Over） |
| F9 | 运行（Run） |
| Ctrl+F9 | 运行到返回（Run to Return） |
| Ctrl+G | 跳转到地址/表达式 |
| Ctrl+F2 | 重启调试 |

## WinDbg 基本命令

[WinDbg](https://learn.microsoft.com/windows-hardware/drivers/debugger/) 是微软官方调试器，功能强大，适合调试复杂问题与崩溃转储（Crash Dump）。

### 启动与附加

```powershell
# 启动并调试程序
windbg program.exe

# 附加到正在运行的进程（PID=1234）
windbg -p 1234
```

### 常用命令

| 命令 | 说明 |
|------|------|
| `g` | 继续运行（Go） |
| `t` | 单步进入（Step Into，Trace） |
| `p` | 单步越过（Step Over） |
| `bp <addr>` | 在地址处设置断点，如 `bp 0x00007FF6A1234000` |
| `bp <module>!<symbol>` | 按符号设断点，如 `bp program!main` |
| `bc *` | 清除所有断点 |
| `r` | 显示所有寄存器 |
| `r rax` | 显示/修改 RAX，如 `r rax=42` |
| `u <addr>` | 反汇编，如 `u program!main L20`（显示20条） |
| `d <addr>` | 显示内存，如 `dq rsp L8`（以8字节显示栈顶8个值） |
| `dq rsp L8` | 以四字（8字节）格式显示内存 |
| `k` | 显示调用栈（Call Stack） |
| `~` | 列出所有线程 |
| `!analyze -v` | 分析崩溃原因（自动诊断） |
| `q` | 退出调试器 |

> 示例：`bp program!main` 在 main 函数处下断点，然后 `g` 运行，命中后用 `t` 单步，`r` 查看寄存器变化。

## lldb（macOS）

macOS 上汇编调试用 `lldb`（LLVM 调试器），随 Xcode Command Line Tools 一起提供，路径 `/usr/bin/lldb`。

### 启动

```bash
# 汇编时带 DWARF 调试信息
nasm -I lib -f macho64 -g examples-macos/05_control_flow/cmov.asm -o build/cmov.o
clang -arch x86_64 -g build/cmov.o -o build/cmov

# 非交互式：跑一遍，崩溃了直接看回溯
lldb -b -o "run" -o "bt" -o "quit" ./build/cmov

# 交互式
lldb ./build/cmov
```

### 常用命令

| 命令 | 作用 | Windows 对应 |
|------|------|-------------|
| `run` / `r` | 运行 | `g` |
| `bt` | 打印调用栈 | `k` |
| `register read rip rsp rbp rax rbx` | 看指定寄存器 | `r rax` |
| `register read --all` | 看全部寄存器 | `r` |
| `x/8gx $rsp` | 以 8 字节十六进制看栈顶 8 项 | `dq rsp L8` |
| `memory read --format x --size 8 --count 4 $rsp` | 同上（lldb 原生命令式） | `d` |
| `si` | 单步进入（step instruction） | `t` |
| `ni` | 单步越过（next instruction） | `p` |
| `c` | 继续 | `g` |
| `disassemble` | 反汇编当前函数 | `u` |
| `b _main` | 按符号下断点 | `bp program!main` |
| `b *0x100001234` | 按地址下断点 | `bp 0x...` |
| `p $rax` | 打印寄存器 | `r rax` |
| `register write rax 42` | 修改寄存器 | `r rax=42` |
| `quit` / `q` | 退出 | `q` |

### 崩溃诊断的典型套路

```
(lldb) run
Process 12345 stopped
* thread #1, stop reason = EXC_BAD_ACCESS (code=1, address=0x900065050)
    frame #0: 0x00007ff81523d730 libvDSP.dylib`...
(lldb) bt
(lldb) register read rip rsp rbp rax rbx r12 r13
```

根据 `frame #0` 的位置可以快速缩小范围：

| `frame #0` 落在 | 基本可以断定 |
|----------------|-------------|
| `dyld` / `_dyld_start` | 破坏了被调用者保存寄存器（`rbx`/`r12`–`r15`），`_main` 返回后 dyld 用到坏值 |
| `_platform_strlen` / `_strlen` / `_vfprintf` | `printf` 的参数与格式串字段错位，某个数字被当成指针 |
| 某个 `andps` / `movaps` / `maxps` 指令上 | SSE 的内存操作数没做 16 字节对齐 |
| `libsystem_malloc` / `free` | 写越界把堆元数据踩坏了 |

## gdb（Linux）

Linux 上汇编调试用 `gdb`（GNU 调试器），由发行版包管理器安装（`pacman -S gdb` / `apt install gdb` / `dnf install gdb`）。

### 启动

```bash
# 汇编时带 DWARF 调试信息（-g -F dwarf；elf64 目标 -g 默认就是 DWARF）
nasm -I lib -f elf64 -g -F dwarf examples-linux/05_control_flow/cmov.asm -o build/cmov.o
gcc -no-pie -g build/cmov.o -o build/cmov

# 非交互式：跑一遍，崩溃了直接看回溯
gdb -batch -ex run -ex bt -ex quit ./build/cmov

# 交互式
gdb ./build/cmov
```

### 常用命令

| 命令 | 作用 | WinDbg 对应 |
|------|------|-------------|
| `run` / `r` | 运行 | `g` |
| `bt` | 打印调用栈 | `k` |
| `info registers rip rsp rbp rax rbx` | 看指定寄存器 | `r rax` |
| `info registers` | 看全部寄存器 | `r` |
| `x/8gx $rsp` | 以 8 字节十六进制看栈顶 8 项 | `dq rsp L8` |
| `stepi` / `si` | 单步进入（step instruction） | `t` |
| `nexti` / `ni` | 单步越过（next instruction） | `p` |
| `c` | 继续 | `g` |
| `disas` | 反汇编当前函数 | `u` |
| `b main` | 按符号下断点 | `bp program!main` |
| `b *0x401234` | 按地址下断点 | `bp 0x...` |
| `p/x $rax` | 打印寄存器（十六进制） | `r rax` |
| `set $rax = 42` | 修改寄存器 | `r rax=42` |
| `quit` / `q` | 退出 | `q` |

### 崩溃诊断的典型套路

```
(gdb) run
Program received signal SIGSEGV, Segmentation fault.
0x00007ffff7e3a2b4 in __libc_start_main () from /usr/lib/libc.so.6
(gdb) bt
(gdb) info registers rip rsp rbp rbx r12 r13
```

根据栈顶（`bt` 的 `#0` 帧）的位置可以快速缩小范围：

| `#0` 帧落在 | 基本可以断定 |
|-------------|-------------|
| `__libc_start_main` / `_start` | 破坏了被调用者保存寄存器（`rbx`/`r12`–`r15`），`main` 返回后 libc 启动代码用到坏值 |
| `strlen` / `_IO_vfprintf` / `vfprintf` | `printf` 的参数与格式串字段错位，某个数字被当成指针 |
| 某个 `andps` / `movaps` / `maxps` 指令上 | SSE 的内存操作数没做 16 字节对齐 |
| `malloc` / `free` | 写越界把堆元数据踩坏了 |

这些和 macOS 上是同一组病根，只是「崩溃现场」从 dyld/libSystem 换成了 `__libc_start_main`/libc：第 7 节「段错误 139，崩溃点在 dyld 里」在 Linux 上就是「崩溃点在 `__libc_start_main` 里」，修法完全相同。

## NASM 调试信息（-g）

默认情况下 NASM 不生成调试信息，调试器中只能看到机器码与地址。添加 `-g` 参数可生成调试信息，让调试器显示源码行号与符号：

```powershell
# Windows：CodeView 8（CV8）格式
nasm -f win64 -g example.asm -o example.obj
link /subsystem:console /entry:main /debug example.obj msvcrt.lib legacy_stdio_definitions.lib kernel32.lib
```

```bash
# macOS：DWARF 格式
nasm -I lib -f macho64 -g example.asm -o example.o
clang -arch x86_64 -g example.o -o example
```

```bash
# Linux：DWARF 格式
nasm -I lib -f elf64 -g -F dwarf example.asm -o example.o
gcc -no-pie -g example.o -o example
```

> NASM 的 `-g` 配合 `-F` 可指定调试格式：win64 目标默认 CV8（生成 PDB，可被 x64dbg / WinDbg 加载），macho64 目标默认 DWARF（直接内嵌在 `.o` 里，lldb 原生读取，不需要额外文件），elf64 目标默认 DWARF（gdb 原生读取；显式写 `-F dwarf` 更保险）。

## 常见错误排查

### 1. 栈未对齐导致崩溃（最常见）

**现象**：调用 C 库函数（如 `printf`）或 Windows API 时程序崩溃，错误码为访问违例（0xC0000005）。

**原因**：`CALL` 时 RSP 未 16 字节对齐。许多库函数内部使用 `movaps` 等 SSE 指令要求 16 字节对齐。

**排查**：在调用前检查 RSP 末位。x64dbg 中观察 RSP 值，确保 `RSP % 16 == 0`（CALL 前）。

**修复**：分配影子空间时补足对齐：

```nasm
; 错误：32字节影子空间，但 RSP 此时 %16==8，CALL后失衡
sub rsp, 32
call printf        ; 可能崩溃!

; 正确：32影子 + 8对齐 = 40
sub rsp, 40
call printf        ; 安全
add rsp, 40
```

### 2. 影子空间未分配

**现象**：调用 Windows API 或库函数后返回值异常或崩溃。

**原因**：未分配 32 字节影子空间，被调用方保存寄存器参数时覆盖了调用者的栈数据。

**修复**：即使参数少于 4 个，调用前也必须 `sub rsp, 32`（并考虑对齐）。

### 3. 忘记保存非易失性寄存器

**现象**：函数返回后，调用者的变量值被意外修改。

**原因**：使用了 RBX/RBP/R12-R15 等非易失性寄存器但未 PUSH/POP 保存。

**修复**：

```nasm
my_func:
    push rbx            ; 使用前保存
    ; ... 使用 RBX ...
    pop  rbx            ; 返回前恢复
    ret
```

### 4. 段错误（访问违例）

**现象**：读写内存时触发 0xC0000005 异常。

**常见原因**：
- 解引用空指针或未初始化的寄存器作为地址
- 越界访问数组
- 操作数大小不匹配（如用 `mov [rbx], rax` 但未声明 `qword`，实际写入了错误字节数）

**排查**：x64dbg 中查看异常发生地址，检查该指令涉及的内存地址与寄存器值是否合法。

### 5. RET 跳转到错误地址

**现象**：函数返回时跳到随机地址，程序立即崩溃。

**原因**：栈失衡——`PUSH` 与 `POP` 数量不等，或手动调整 RSP 后未恢复，导致 `RET` 弹出的不是正确的返回地址。

**排查**：x64dbg 栈窗口检查 `[RSP]` 是否为合理的代码地址（应指向 CALL 的下一条指令）。

### 6. 操作数大小歧义

**现象**：汇编报错 `error: operation size not specified`。

**原因**：`mov [rbx], 0` 无法确定写入 1/2/4/8 字节。

**修复**：用大小关键字明确：

```nasm
mov byte  [rbx], 0     ; 1 字节
mov word  [rbx], 0     ; 2 字节
mov dword [rbx], 0     ; 4 字节
mov qword [rbx], 0     ; 8 字节
```

### 7. 段错误 139，崩溃点在 dyld 里（macOS 特有）

**现象**：程序从 `_main` 正常走到 `ret` 之后才崩，退出码 139（SIGSEGV），`lldb` 的 `bt` 显示 `frame #0` 在 `dyld` 里，形如：

```
dyld`dyld4::start(...) + 465: movq 0x8(%rbx), %rax
EXC_BAD_ACCESS (code=1, address=0x...)
```

**原因**：破坏了**被调用者保存寄存器**（`rbx`、`r12`–`r15`）。Windows 版用 `/entry:main` 把 `main` 当进程入口，里面直接 `call ExitProcess`，所以破坏了也看不出来；macOS 的 `_main` 是被 libSystem call 进来的，`ret` 之后 dyld 会继续用它，于是立刻崩。

**修法**：进函数先备份到栈帧，退场前还原。

```asm
_main:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    mov [rbp-8],  rbx          ; 备份
    mov [rbp-16], r12
    ...
    mov rbx, [rbp-8]           ; 还原
    mov r12, [rbp-16]
    xor eax, eax
    leave
    ret
```

### 8. 输出一个莫名其妙的巨大数字（macOS 特有）

**现象**：本来算好的值，打印出来是个离谱的大数。

**原因**：`printf` 的**返回值**（打印字符数）就放在 `eax` 里，把 `rax` 冲掉了。紧接着再用 `rax` 就会用到垃圾。

```asm
    mov rax, 0x123456789ABCDEF0
    bswap rax
    call _printf               ; ← eax 变成「打印了几个字符」
    bswap rax                  ; ← 转的是垃圾
```

**修法**：要么把值放 `rbx`/`r12`–`r15`（记得备份还原），要么用之前重新装一遍。

### 9. `EXC_BAD_ACCESS` 且栈里有 `_platform_strlen`（macOS 特有）

**现象**：`lldb` 显示崩溃在 `_platform_strlen` 里，访问地址是个很小的数（例如 `0x60`）。

**原因**：`printf` 的**格式串字段顺序与参数寄存器顺序不匹配**。格式串里的 `%s` 拿到的是本该给 `%lld` 的那个数字，libc 就把它当指针去解引用了。

**修法**：严格按 `rdi`（格式串）、`rsi`、`rdx`、`rcx`、`r8`、`r9` 的顺序逐字段对照。SysV 里浮点和整数各自编号，不要按 Windows 的「位置序号」习惯去想。

### 10. `andps` / `movaps` 上崩溃

**现象**：崩溃点落在这类 SSE 指令上。

**原因**：`MOVAPS`、`ANDPS`、`ORPS`、`XORPS`、`MAXPS`…… 这些指令的**内存操作数必须 16 字节对齐**，否则 `#GP`。

**修法**：

- 常量前面写 `align 16`；
- 「错位加载」（例如用偏移 4 字节的地址做有限差分）一律用 `movups`，不能用 `movaps`；
- 注意 `align` 只对紧随其后的那一个标号/数据生效：

```asm
section .data
    align 16
    v_one    dd 1.0, 1.0, 1.0, 1.0      ; 16 字节对齐
    align 16                            ; 每块都要单独写
    v_mask   dd 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF
```

---

> 上一章：[栈和栈帧](07_stack_frames.md) ｜ 下一章：[Intel 混合架构（P核/E核）](09_hybrid_architecture.md) ｜ 返回：[README](../README.md)
