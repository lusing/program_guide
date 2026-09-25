; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    fmt_ja    BYTE "JA:  255 > 1 (unsigned)  -> Above (JA taken)", 10, 0
    fmt_jb    BYTE "JB:  1 < 255 (unsigned)  -> Below (JB taken)", 10, 0
    fmt_ja_u  BYTE "Unsigned: 0xFFFFFFFF > 1 -> Above (JA taken)", 10, 0
    fmt_jl_s  BYTE "Signed:   0xFFFFFFFF < 1 -> Less  (JL taken)", 10, 0
    fmt_key   BYTE "Key: Same CMP, different jumps interpret flags differently!", 10, 0


.code

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 32              ; shadow space

    ; -------------------------------------------------------
    ; JA: 无符号大于跳转
    ; 比较 255 和 1 (32位): 255 > 1 (无符号), JA 跳转
    ; CMP 计算 EAX - EDX = 255 - 1 = 254, CF=0, ZF=0
    ; JA 条件: CF=0 且 ZF=0 -> 跳转
    ; -------------------------------------------------------
    mov eax, 255
    mov edx, 1
    cmp eax, edx
    ja mainja_taken             ; 无符号: 255 > 1, 跳转
    ; 不会执行到这里
    jmp mainafter_ja
mainja_taken:
    lea rcx, fmt_ja
    call printf
mainafter_ja:

    ; -------------------------------------------------------
    ; JB: 无符号小于跳转
    ; 比较 1 和 255 (32位): 1 < 255 (无符号), JB 跳转
    ; CMP 计算 1 - 255: 需要借位, CF=1
    ; JB 条件: CF=1 -> 跳转
    ; -------------------------------------------------------
    mov eax, 1
    mov edx, 255
    cmp eax, edx
    jb mainjb_taken            ; 无符号: 1 < 255, 跳转
    ; 不会执行到这里
    jmp mainafter_jb
mainjb_taken:
    lea rcx, fmt_jb
    call printf
mainafter_jb:

    ; -------------------------------------------------------
    ; 关键演示: 同一个CMP，不同的跳转指令给出不同结果！
    ;
    ; 0FFFFFFFFh 作为32位值的两种解读:
    ;   无符号: 4294967295 (32位最大无符号数) -> 大于 1
    ;   有符号: -1                                      -> 小于 1
    ;
    ; CMP EAX, EDX 计算 0FFFFFFFFh - 1 = 0FFFFFFFEh:
    ;   CF=0 (无借位, 4294967295 >= 1)
    ;   SF=1, OF=0 (有符号: 结果为负, 无溢出)
    ;
    ; 因此:
    ;   JA (读CF): CF=0 且 ZF=0 -> 跳转 (无符号大于)
    ;   JL (读SF/OF): SF!=OF -> 跳转 (有符号小于)
    ;   两个跳转都会被执行！
    ; -------------------------------------------------------

    ; --- 测试1: JA (无符号) 对 0FFFFFFFFh vs 1 ---
    mov eax, 0FFFFFFFFh       ; 32位: 无符号=4294967295, 有符号=-1
    mov edx, 1
    cmp eax, edx              ; 设置标志位
    ja mainunsigned_above        ; 无符号: 4294967295 > 1, 跳转
    ; 会跳转，不会执行到这里
mainunsigned_above:
    lea rcx, fmt_ja_u
    call printf

    ; --- 测试2: JL (有符号) 对同样的 0FFFFFFFFh vs 1 ---
    ; 注意: 必须重新执行 CMP，因为上面的 printf 调用改变了标志位
    mov eax, 0FFFFFFFFh
    mov edx, 1
    cmp eax, edx              ; 重新设置标志位
    jl mainsigned_less          ; 有符号: -1 < 1, 跳转
    ; 会跳转，不会执行到这里
mainsigned_less:
    lea rcx, fmt_jl_s
    call printf

    ; --- 打印关键结论 ---
    lea rcx, fmt_key
    call printf

    ; --- 退出进程 ---
    xor ecx, ecx             ; exit code = 0
    call ExitProcess
main ENDP
END
