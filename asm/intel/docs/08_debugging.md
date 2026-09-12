# 调试方法

汇编程序由于贴近硬件，错误往往难以直接定位。本章介绍常用的调试工具与方法，帮助你高效排查问题。

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

## NASM 调试信息（-g）

默认情况下 NASM 不生成调试信息，调试器中只能看到机器码与地址。添加 `-g` 参数可生成 CodeView 格式调试信息，让调试器显示源码行号与符号：

```powershell
# 汇编时生成调试信息
nasm -f win64 -g example.asm -o example.obj

# 链接时也生成调试信息（PDB 文件）
link /subsystem:console /entry:main /debug example.obj msvcrt.lib legacy_stdio_definitions.lib kernel32.lib
```

> NASM 的 `-g` 配合 `-F` 可指定调试格式。win64 目标默认使用 CV8（CodeView 8）。生成的 PDB 文件可被 x64dbg 和 WinDbg 加载，关联源代码行。

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

---

> 上一篇：[栈和栈帧](07_stack_frames.md) ｜ 返回 [首页](../README.md)
