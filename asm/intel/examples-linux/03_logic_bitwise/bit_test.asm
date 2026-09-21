; ============================================================
; 文件: 03_logic_bitwise/bit_test.asm                      [Linux 版]
; 指令: BT / BTS / BTR / BTC
; 描述: 位测试与「测试并修改」指令
; 平台: Linux x86-64（ELF + System V AMD64）
; 汇编: nasm -I lib -f elf64 examples-linux/03_logic_bitwise/bit_test.asm -o build/bit_test.o
; 链接: gcc -no-pie build/bit_test.o -o build/bit_test
; 对照: examples/03_logic_bitwise/bit_test.asm
;
; 四条指令都把「指定位的旧值」送进 CF，区别在于随后做什么：
;   BT   不动     BTS 置 1     BTR 清 0     BTC 翻转
; 配合 SETC + MOVZX 就能把 CF 取成 0/1 整数。
; 注意走内存操作数时 BT 系指令的偏移量是「位数」而不是字节数，
; 可以一次访问超过一个机器字，这是它比「SHL+SHR」高明的地方。
; ============================================================
default rel

section .data
    align 8
    fmt_bt3 db "BT   rax,3  -> CF=%lld  (0x08 的 bit 3 = 1)", 10, 0
    fmt_bt5 db "BT   rax,5  -> CF=%lld  (0x08 的 bit 5 = 0)", 10, 0
    fmt_bts db "BTS  rax,5  -> CF=%lld, rax = 0x%llx  (置 bit 5)", 10, 0
    fmt_btr db "BTR  rax,5  -> CF=%lld, rax = 0x%llx  (清 bit 5)", 10, 0
    fmt_btc db "BTC  rax,3  -> CF=%lld, rax = 0x%llx  (翻转 bit 3)", 10, 0

section .text
    global main
    extern printf

main:
    push rbp
    mov rbp, rsp
    sub rsp, 16

    ; --- BT: 测试第 3 位（0x08 = 0b1000，bit3 = 1） ---
    ; 注意顺序：xor esi,esi 会把 CF 清掉，所以必须先清零再执行 BT。
    mov rax, 0x08
    xor esi, esi
    bt rax, 3
    setc sil                         ; sil = CF
    lea rdi, [fmt_bt3]
    xor eax, eax
    call printf

    ; --- BT: 测试第 5 位（0x08 的 bit5 = 0） ---
    mov rax, 0x08
    xor esi, esi
    bt rax, 5
    setc sil
    lea rdi, [fmt_bt5]
    xor eax, eax
    call printf

    ; --- BTS: 测试并置位第 5 位 ---
    ; CF = 旧值（bit5 = 0），随后 bit5 变 1 => rax = 0x28
    mov rax, 0x08
    xor esi, esi
    bts rax, 5
    setc sil                          ; CF 里是旧值
    lea rdi, [fmt_bts]
    mov rdx, rax                      ; rax 已经变了，先放进 rdx
    xor eax, eax
    call printf

    ; --- BTR: 测试并清位第 5 位 ---
    ; 从 0x28 开始，CF = 旧值（bit5 = 1），随后 bit5 变 0 => rax = 0x08
    mov rax, 0x28
    xor esi, esi
    btr rax, 5
    setc sil
    lea rdi, [fmt_btr]
    mov rdx, rax
    xor eax, eax
    call printf

    ; --- BTC: 测试并翻转第 3 位 ---
    ; 从 0x08 开始，CF = 旧值（bit3 = 1），随后 bit3 翻转 => rax = 0x00
    mov rax, 0x08
    xor esi, esi
    btc rax, 3
    setc sil
    lea rdi, [fmt_btc]
    mov rdx, rax
    xor eax, eax
    call printf

    xor eax, eax
    leave
    ret
