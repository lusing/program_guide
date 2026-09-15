; ============================================================
; 文件: 05_control_flow/loop.asm                           [macOS 版]
; 指令: LOOP
; 描述: 用 LOOP 累加 1+2+…+10 = 55
; 平台: macOS x86-64（Mach-O + System V AMD64）
; 汇编: nasm -I lib -f macho64 examples-macos/05_control_flow/loop.asm -o build/loop.o
; 链接: clang -arch x86_64 build/loop.o -o build/loop
; 对照: examples/05_control_flow/loop.asm
;
; LOOP label 等价于「ECX -= 1; if (ECX != 0) goto label」，
; 计数器固定用 ECX，没法换寄存器 —— 这是它最大的限制。
;
; 陷阱在两个平台上都成立，但踩法不同：
;   Windows 下 RCX 是 printf 的第 1 个参数寄存器，
;   macOS 下 RCX 是 printf 的第 4 个参数寄存器；
;   不管哪个，只要循环体里 call 一次 printf，计数器就没了。
; 所以正确做法是「循环里只做累加，循环结束后再一次性打印」。
; ============================================================
default rel

section .data
    fmt db "Sum 1+2+...+10 = %lld (LOOP with ECX=10)", 10, 0
    fmt_ecx db "循环结束后 ECX = %lld（LOOP 直接把它减到 0）", 10, 0

section .text
    global _main
    extern _printf

_main:
    push rbp
    mov rbp, rsp
    sub rsp, 16

    ; --------------------------------------------------------
    ; mov ecx, 10 会顺手把 RCX 高 32 位清零，所以 RCX = 10
    ; r10 是调用者保存寄存器，循环体里没有任何 call，可以放心当累加器
    ; --------------------------------------------------------
    mov ecx, 10                      ; 计数器
    xor r10d, r10d                   ; 累加器 = 0

.lp:
    add r10, rcx                     ; r10 += 当前计数值（10, 9, …, 1）
    loop .lp                         ; ECX -= 1，非 0 就跳回 .lp
    ; 此时 r10 = 55，RCX = 0

    mov [rbp-8], rcx                 ; 把 ECX 留个证据

    lea rdi, [fmt]
    mov rsi, r10
    xor eax, eax
    call _printf

    lea rdi, [fmt_ecx]
    mov rsi, [rbp-8]
    xor eax, eax
    call _printf

    xor eax, eax
    leave
    ret
