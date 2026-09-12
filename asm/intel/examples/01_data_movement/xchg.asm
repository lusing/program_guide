; ============================================================
; 文件: 01_data_movement/xchg.asm
; 指令: XCHG
; 描述: XCHG交换指令 - 寄存器间/寄存器与内存交换
; 编译: nasm -f win64 xchg.asm -o xchg.obj
; 链接: link /subsystem:console /entry:main xchg.obj msvcrt.lib kernel32.lib
; ============================================================
default rel

section .data
    align 8
    var dq 111

    fmt_before  db "寄存器交换前: rax=%lld, rbx=%lld", 10, 0
    fmt_after   db "寄存器交换后: rax=%lld, rbx=%lld (xchg rax,rbx)", 10, 0
    fmt_m_before db "内存交换前:   var=%lld, rax=%lld", 10, 0
    fmt_m_after  db "内存交换后:   var=%lld, rax=%lld (xchg [var],rax)", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; --- 寄存器间交换 ---
    ; 用非易失寄存器(r12-r15)保存交换前/后的值, 避免 printf 破坏
    mov rax, 10
    mov rbx, 20
    mov r12, rax              ; r12 = 交换前 rax = 10
    mov r13, rbx             ; r13 = 交换前 rbx = 20
    xchg rax, rbx            ; 交换后 rax=20, rbx=10
    mov r14, rax             ; r14 = 交换后 rax = 20
    mov r15, rbx             ; r15 = 交换后 rbx = 10
    lea rcx, [fmt_before]
    mov rdx, r12
    mov r8, r13
    call printf
    lea rcx, [fmt_after]
    mov rdx, r14
    mov r8, r15
    call printf

    ; --- 寄存器与内存交换 ---
    mov qword [var], 111
    mov rax, 222
    mov r12, [var]            ; r12 = 交换前 var = 111
    mov r13, rax             ; r13 = 交换前 rax = 222
    xchg [var], rax          ; 交换后 var=222, rax=111
    mov r14, [var]            ; r14 = 交换后 var = 222
    mov r15, rax             ; r15 = 交换后 rax = 111
    lea rcx, [fmt_m_before]
    mov rdx, r12
    mov r8, r13
    call printf
    lea rcx, [fmt_m_after]
    mov rdx, r14
    mov r8, r15
    call printf

    xor ecx, ecx
    call ExitProcess
