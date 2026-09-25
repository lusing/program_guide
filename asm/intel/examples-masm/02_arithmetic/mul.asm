; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    align 8
    fmt8  BYTE "8位 mul:   255 * 10        => AX = %d (0x%x)", 10, 0
    fmt16 BYTE "16位 mul:  1000 * 100      => DX:AX = %lld", 10, 0
    fmt32 BYTE "32位 mul:  4000000000 * 2  => EDX:EAX = %llu", 10, 0
    fmt64 BYTE "64位 mul:  0xFFFFFFFFFFFFFFFF * 2 => RDX:RAX = 0x%016llx%016llx", 10, 0


.code

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; 8位: mul bl -> AX = AL * BL
    mov al, 255
    mov bl, 10
    mul bl                      ; AX = 2550
    movzx edx, ax
    lea rcx, fmt8
    mov r8d, edx                ; 用于 %x
    call printf

    ; 16位: mul bx -> DX:AX = AX * BX
    mov ax, 1000
    mov bx, 100
    mul bx                      ; DX:AX = 100000
    movzx rdx, dx               ; 高16位
    shl rdx, 16
    movzx r9, ax                ; 低16位
    or rdx, r9                  ; rdx = 100000
    lea rcx, fmt16
    call printf

    ; 32位: mul ebx -> EDX:EAX = EAX * EBX
    mov eax, 4000000000         ; 0EE6B2800h
    mov ebx, 2
    mul ebx                     ; EDX:EAX = 8000000000
    shl rdx, 32                 ; 高32位移到高位
    or rdx, rax                 ; rdx = 完整64位结果
    lea rcx, fmt32
    call printf

    ; 64位: mul rbx -> RDX:RAX = RAX * RBX
    mov rax, 0FFFFFFFFFFFFFFFFh
    mov rbx, 2
    mul rbx                     ; RDX=1, RAX=0FFFFFFFFFFFFFFFEh
    mov r8, rax                 ; 低64位 (第二个参数)
    ; rdx 已是高64位 (第一个参数)
    lea rcx, fmt64
    call printf

    xor ecx, ecx
    call ExitProcess
main ENDP
END
