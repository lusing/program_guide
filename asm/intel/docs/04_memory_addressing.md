# 内存寻址模式

寻址模式（Addressing Mode）是指令获取操作数的方式。x86-64 支持丰富的寻址模式，本章从简到繁逐一介绍，所有示例采用 NASM 语法。

## 立即数寻址（Immediate Addressing）

操作数直接编码在指令中，是一个常数值。常用于给寄存器赋初值或参与运算。

```nasm
mov rax, 42          ; 将立即数 42 存入 RAX
add rbx, 1000        ; RBX += 1000
mov dword [rsp], 0   ; 将立即数 0 写入栈顶的 4 字节
```

> 立即数不能作为目的操作数（如 `mov 42, rax` 非法）。立即数最大为 32 位符号扩展至 64 位；若需 64 位立即数，NASM 会自动生成分步指令（`mov rax, 0x123456789ABCDEF0` 使用 10 字节编码）。

## 寄存器寻址（Register Addressing）

操作数全部位于寄存器中，不访问内存，速度最快。

```nasm
mov rax, rbx         ; RAX = RBX
add rcx, rdx         ; RCX += RDX
xor r8, r9           ; R8 ^= R9
```

## 直接寻址（Direct Memory Addressing）

操作数的内存地址以立即数形式直接写在指令中。访问全局变量时常用此模式（配合标签地址）。

```nasm
section .data
    counter dq 0          ; 定义一个 8 字节全局变量

section .text
    inc qword [counter]   ; counter += 1（直接以标签名寻址）
    mov rax, [0x10004000] ; 读取固定地址处的 8 字节（较少用）
```

> 在 64 位模式下直接寻址全局变量时，NASM 会自动使用 RIP 相对寻址（更高效且支持位置无关代码）。

## 寄存器间接寻址（Register Indirect Addressing）

操作数的内存地址存放在寄存器中，通过 `[reg]` 间接访问。常用于指针解引用、遍历数组。

```nasm
mov rax, [rbx]       ; 将 RBX 指向的内存处的 8 字节读入 RAX
mov [rcx], rdx       ; 将 RDX 写入 RCX 指向的内存
add rax, [r8]        ; RAX += [R8]
```

## 基址+偏移寻址（Base + Displacement）

在基址寄存器值的基础上加一个常量偏移（Displacement），访问结构体成员或局部变量时极为常用。

```nasm
mov rax, [rbx + 8]       ; 读取 RBX+8 处的 8 字节（结构体偏移 8 的成员）
mov [rbp - 16], rcx      ; 将 RCX 写入 RBP-16（局部变量区）
mov dword [rsp + 32], 0  ; 写入影子空间区域
```

> 偏移量可以是正数或负数。32 位偏移可省略前缀，64 位偏移较罕见。

## SIB 寻址（Base + Index × Scale + Displacement）

这是 x86 最强大也最复杂的寻址模式，完整公式为：

```
有效地址 = Base + Index × Scale + Displacement
```

| 组成 | 寄存器/值 | 说明 |
|------|----------|------|
| Base | 任意通用寄存器 | 基址（可为 RSP/RBP 等任意通用寄存器） |
| Index | 任意通用寄存器（RSP 除外） | 变址，用于数组下标 |
| Scale | 1, 2, 4, 8 | 比例因子，对应元素大小（字节/字/双字/四字） |
| Displacement | 常量 | 固定偏移 |

四个组成部分均可省略，组合出灵活的寻址方式。

```nasm
; 数组访问: 元素大小 8 字节，RCX 为基址，RDI 为下标
mov rax, [rcx + rdi*8]          ; array[i] → RAX

; 结构体数组: 基址 + 下标*结构体大小 + 成员偏移
mov rax, [rbx + rsi*16 + 8]     ; structs[i].field_at_offset_8

; 无基址，纯变址+偏移（等价于 index*scale + disp）
mov eax, [rdi*4 + array]        ; array[i] (array为标签地址)

; 带 RBP 的栈帧访问
mov rax, [rbp + rdi*8 - 32]     ; 访问栈上某偏移的参数/变量
```

### RIP 相对寻址（RIP-relative Addressing）

x86-64 新增的寻址模式，以 RIP（指令指针）为基址加偏移，专用于访问全局数据，生成位置无关代码（PIC）：

```nasm
lea rax, [rel msg]      ; 获取 msg 的运行时地址（推荐写法）
mov rax, [rel counter]  ; 读取全局变量 counter 的值
```

> NASM 中使用 `rel` 关键字显式声明 RIP 相对寻址。`-f win64` 和 `-f macho64` 下直接写 `[msg]` 通常也会自动生成 RIP 相对寻址，但显式写 `[rel msg]` 更清晰，也是**跨平台双份构建时最省心的写法**——两个格式都不会给你惊喜或惊吓。

## 寻址模式速查表

| 模式 | NASM 语法 | 典型用途 |
|------|----------|----------|
| 立即数 | `mov rax, 42` | 赋常量值 |
| 寄存器 | `mov rax, rbx` | 寄存器间数据传递 |
| 直接 | `mov rax, [counter]` | 访问全局变量 |
| 寄存器间接 | `mov rax, [rbx]` | 指针解引用 |
| 基址+偏移 | `mov rax, [rbx+8]` | 结构体成员、局部变量 |
| SIB | `mov rax, [rbx+rsi*8]` | 数组访问 |
| SIB+偏移 | `mov rax, [rbx+rsi*8+16]` | 结构体数组 |
| RIP 相对 | `lea rax, [rel msg]` | 位置无关的全局数据访问 |

### 注意事项

1. **RSP 不能作为 Index 寄存器**：`[rsp + rsp*2]` 非法。
2. **Scale 仅限 1/2/4/8**：不支持其他比例值。
3. **操作数大小需明确**：`mov [rbx], 0` 有歧义（写多少字节？），需用 `mov dword [rbx], 0` 指定大小。
4. **地址宽度**：64 位模式下默认使用 64 位地址，无需 `qword` 前缀修饰地址，但数据大小仍需明确。

---

> 上一章：[寄存器详解](03_registers.md) ｜ 下一章：[标志寄存器](05_flags.md) ｜ 返回：[README](../README.md)
