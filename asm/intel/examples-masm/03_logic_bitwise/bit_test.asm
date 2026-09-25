; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    fmt_bt3   BYTE "BT   rax, 3  -> CF=%lld  (bit 3 of 0x08 = 1)", 10, 0
    fmt_bt5   BYTE "BT   rax, 5  -> CF=%lld  (bit 5 of 0x08 = 0)", 10, 0
    fmt_bts   BYTE "BTS  rax, 5  -> CF=%lld, rax = 0x%llx  (set bit 5)", 10, 0
    fmt_btr   BYTE "BTR  rax, 5  -> CF=%lld, rax = 0x%llx  (clear bit 5)", 10, 0
    fmt_btc   BYTE "BTC  rax, 3  -> CF=%lld, rax = 0x%llx  (toggle bit 3)", 10, 0


.code

main PROC
    push rbp
    mov rbp, rsp
    and rsp, -16             ; 确保16字节栈对齐
    sub rsp, 32              ; shadow space

    ; --- BT: 测试第3位 (08h = 0b1000, bit 3 = 1) ---
    ; BT 将指定位复制到 CF，不修改操作数
    mov rax, 08h
    xor rdx, rdx             ; 先清零 rdx (不影响后续 BT 的 CF)
    bt rax, 3                ; CF = bit 3 = 1
    setc dl                  ; dl = CF (0 or 1), rdx 已清零
    lea rcx, fmt_bt3
    call printf

    ; --- BT: 测试第5位 (08h, bit 5 = 0) ---
    mov rax, 08h
    xor rdx, rdx
    bt rax, 5                ; CF = bit 5 = 0
    setc dl                  ; rdx = 0
    lea rcx, fmt_bt5
    call printf

    ; --- BTS: 测试并设置第5位 ---
    ; CF = 旧值(bit5=0), 然后 bit5 置1 → rax = 28h
    mov rax, 08h
    xor rdx, rdx
    bts rax, 5               ; CF=0, rax bit5 → 1
    setc dl                  ; rdx = 0 (旧 CF)
    mov r8, rax              ; r8 = 28h (修改后的值)
    lea rcx, fmt_bts
    call printf

    ; --- BTR: 测试并清除第5位 ---
    ; 从 28h 开始, CF = 旧值(bit5=1), 然后 bit5 清0 → rax = 08h
    mov rax, 28h
    xor rdx, rdx
    btr rax, 5               ; CF=1, rax bit5 → 0
    setc dl                  ; rdx = 1 (旧 CF)
    mov r8, rax              ; r8 = 08h
    lea rcx, fmt_btr
    call printf

    ; --- BTC: 测试并翻转第3位 ---
    ; 从 08h 开始, CF = 旧值(bit3=1), 然后 bit3 翻转 → rax = 00h
    mov rax, 08h
    xor rdx, rdx
    btc rax, 3               ; CF=1, rax bit3 → 0
    setc dl                  ; rdx = 1 (旧 CF)
    mov r8, rax              ; r8 = 00h
    lea rcx, fmt_btc
    call printf

    xor ecx, ecx             ; exit code = 0
    call ExitProcess
main ENDP
END
