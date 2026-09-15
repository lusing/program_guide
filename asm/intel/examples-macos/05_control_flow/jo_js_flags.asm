; ============================================================
; 文件: 05_control_flow/jo_js_flags.asm                    [macOS 版]
; 指令: JO / JS / JP（溢出、符号、奇偶标志跳转）
; 描述: 直接盯着 OF / SF / PF 三个标志位做判断
; 平台: macOS x86-64（Mach-O + System V AMD64）
; 汇编: nasm -I lib -f macho64 examples-macos/05_control_flow/jo_js_flags.asm -o build/jo_js_flags.o
; 链接: clang -arch x86_64 build/jo_js_flags.o -o build/jo_js_flags
; 对照: examples/05_control_flow/jo_js_flags.asm
;
;   JO : OF=1（有符号运算溢出）
;   JS : SF=1（结果为负）
;   JP : PF=1（结果的低 8 位里有偶数个 1）
; 标志位是「上一条运算指令」留下的痕迹，跳转指令只是去读它。
; 中间只要插进一条 printf，痕迹就没了 —— 这是新手最常见的困惑来源。
; 本例把每次运算后的标志位快照也用 pushfq 取出来打一遍，方便对照。
; ============================================================
default rel

section .data
    fmt_of  db "OF: 127 + 1 -> Overflow (JO taken, OF=1)", 10, 0
    fmt_sf  db "SF: 0 - 1 -> Negative (JS taken, SF=1)", 10, 0
    fmt_pf  db "PF: 3 (0b00000011, two 1s) -> Even parity (JP taken, PF=1)", 10, 0
    fmt_ovf db "  快照（127+1 之后）：", 10, 0
    fmt_neg db "  快照（0-1 之后）：", 10, 0
    fmt_par db "  快照（test al,al  之后，AL=3）：", 10, 0

section .text
    global _main
    extern _printf

_main:
    push rbp
    mov rbp, rsp
    sub rsp, 16

    ; --------------------------------------------------------
    ; OF：AL = 127（8 位有符号最大值）+ 1 = 0x80 = -128，溢出 -> OF=1
    ; --------------------------------------------------------
    mov al, 127
    add al, 1
    pushfq
    pop r10
    mov [rbp-8], r10
    jo .of_detected
    jmp .after_of
.of_detected:
    lea rdi, [fmt_of]
    xor eax, eax
    call _printf
.after_of:
    lea rdi, [fmt_ovf]
    xor eax, eax
    call _printf
    mov rdi, [rbp-8]
    call m_putflags
    call m_nl

    ; --------------------------------------------------------
    ; SF：0 - 1 = -1 = 0xFFFFFFFF，最高位是 1 -> SF=1
    ; --------------------------------------------------------
    xor eax, eax
    sub eax, 1
    pushfq
    pop r10
    mov [rbp-8], r10
    js .sf_detected
    jmp .after_sf
.sf_detected:
    lea rdi, [fmt_sf]
    xor eax, eax
    call _printf
.after_sf:
    lea rdi, [fmt_neg]
    xor eax, eax
    call _printf
    mov rdi, [rbp-8]
    call m_putflags
    call m_nl

    ; --------------------------------------------------------
    ; PF：AL = 3 = 0b00000011，低 8 位里有 2 个 1（偶数）-> PF=1
    ; TEST AL,AL 的结果就是 AL 本身，PF 只看结果低 8 位的奇偶性
    ; --------------------------------------------------------
    mov al, 3
    test al, al
    pushfq
    pop r10
    mov [rbp-8], r10
    jp .pf_detected
    jmp .after_pf
.pf_detected:
    lea rdi, [fmt_pf]
    xor eax, eax
    call _printf
.after_pf:
    lea rdi, [fmt_par]
    xor eax, eax
    call _printf
    mov rdi, [rbp-8]
    call m_putflags
    call m_nl

    xor eax, eax
    leave
    ret

%include "mac_io.inc"
