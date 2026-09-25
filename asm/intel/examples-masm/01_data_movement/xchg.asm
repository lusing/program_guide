; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    align 8
    var QWORD 111

    fmt_before  BYTE "寄存器交换前: rax=%lld, rbx=%lld", 10, 0
    fmt_after   BYTE "寄存器交换后: rax=%lld, rbx=%lld (xchg rax,rbx)", 10, 0
    fmt_m_before BYTE "内存交换前:   var=%lld, rax=%lld", 10, 0
    fmt_m_after  BYTE "内存交换后:   var=%lld, rax=%lld (xchg [var],rax)", 10, 0


.code

main PROC
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
    lea rcx, fmt_before
    mov rdx, r12
    mov r8, r13
    call printf
    lea rcx, fmt_after
    mov rdx, r14
    mov r8, r15
    call printf

    ; --- 寄存器与内存交换 ---
    mov QWORD PTR [var], 111
    mov rax, 222
    mov r12, QWORD PTR [var]            ; r12 = 交换前 var = 111
    mov r13, rax             ; r13 = 交换前 rax = 222
    xchg QWORD PTR [var], rax          ; 交换后 var=222, rax=111
    mov r14, QWORD PTR [var]            ; r14 = 交换后 var = 222
    mov r15, rax             ; r15 = 交换后 rax = 111
    lea rcx, fmt_m_before
    mov rdx, r12
    mov r8, r13
    call printf
    lea rcx, fmt_m_after
    mov rdx, r14
    mov r8, r15
    call printf

    xor ecx, ecx
    call ExitProcess
main ENDP
END
