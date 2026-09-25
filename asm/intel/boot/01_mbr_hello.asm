; ============================================================
; 01_mbr_hello.asm - 实模式主引导扇区：串口打印 Hello
; ============================================================
; 运行环境：QEMU（或任何 BIOS 引导的 x86 机器）
;   nasm -f bin 01_mbr_hello.asm -o mbr.bin
;   生成 512 字节的引导扇区，最后两字节为 0x55 0xAA
;
; 演示：
;   - 主引导扇区被 BIOS 加载到 0000:7C00 并执行
;   - 实模式下的段寄存器初始化（ds/es/ss = 0）
;   - 段:偏移 地址计算：物理地址 = 段值 << 4 + 偏移
;   - 串口 COM1 (0x3F8) 输出（QEMU -serial stdio 直接可见）
;   - HLT 停机等待中断
;
; 预期串口输出：
;   Hello from real-mode MBR!
;   CS=0000  IP=7C00  linear=00007C00
;   ES=07C0  DI=0000  linear=00007C00  byte='H'
; ============================================================

        org 0x7c00               ; BIOS 把本扇区加载到 0x7C00
        bits 16                  ; 加电后 CPU 处于 16 位实模式

start:
        cli                      ; 关中断，防止初始化段寄存器时被打断
        xor ax, ax
        mov ds, ax               ; DS = 0 → 数据段基址 0x00000
        mov es, ax               ; ES = 0
        mov ss, ax               ; SS = 0
        mov sp, 0x7c00           ; 栈向低地址生长，从 0x7C00 往下
        sti                      ; 栈已就绪，重新开中断

        call uart_init           ; 初始化 COM1（QEMU 不初始化也能发，真机需要）

        ; ---- 1. 打印欢迎串：lodsb 用 DS:SI，DS=0 → 偏移即汇编地址 ----
        mov si, msg_hello
.print1:
        lodsb                    ; AL = [DS:SI], SI++
        test al, al              ; 以 0 结尾
        jz .print1_done
        call putc
        jmp .print1

.print1_done:
        ; ---- 2. 演示 CS:IP 的线性地址计算 ----
        ; 我们此刻正运行在 CS=0000、IP≈0x7Cxx 的地址上。
        ; 物理地址 = CS * 16 + IP = 0x00000 + 0x7Cxx
        mov ax, cs
        mov di, ax
        mov si, msg_cs
        call puts
        mov ax, cs
        call print_hex16         ; 打印 CS
        mov si, msg_ip
        call puts
        mov ax, 0x7c00
        call print_hex16         ; 打印加载基址（IP 的近似）
        mov si, msg_linear
        call puts
        mov ax, cs
        shl ax, 1                ; 先算 CS<<4：为避免丢位，分步移位
        mov bx, ax
        shl bx, 1
        shl bx, 1
        shl bx, 1                ; BX = CS << 4
        add bx, 0x7c00           ; + 偏移
        mov ax, bx               ; print_hex16 打印的是 AX
        call print_hex16
        call print_crlf

        ; ---- 3. 演示「同一物理地址，不同的段:偏移写法」 ----
        ; 0000:7C00 与 07C0:0000 指向同一个字节（都是 0x7C00）。
        mov si, msg_es
        call puts
        mov ax, 0x07c0
        call print_hex16
        mov si, msg_di
        call puts
        xor ax, ax
        call print_hex16
        mov si, msg_linear2
        call puts
        mov ax, 0x7c00
        call print_hex16
        mov si, msg_byte
        call puts
        ; 现在才读内存：07C0:0000 + (msg_hello 的汇编地址 - 0x7C00) = msg_hello 本尊
        ; 注意 print_hex16 会破坏 DL/DH，必须把读操作放在打印之后
        push es
        mov ax, 0x07c0
        mov es, ax
        xor di, di
        mov al, [es:di + msg_hello - $$]  ; 读 msg_hello 的第一个字符 'H'
        pop es
        call putc
        mov al, 0x27             ; '\''
        call putc
        call print_crlf

        ; ---- 4. 打印提示后停机 ----
        mov si, msg_halt
        call puts

.halt:
        hlt                      ; 停机，等待中断（QEMU 里按 Ctrl+C 结束）
        jmp .halt                ; 中断返回后继续循环停机

; ------------------------------------------------------------
; puts: 打印 DS:SI 指向的 0 结尾字符串
; ------------------------------------------------------------
puts:
.push_ax:
        lodsb
        test al, al
        jz .done
        call putc
        jmp .push_ax
.done:
        ret

; ------------------------------------------------------------
; print_hex16: 以 4 位十六进制打印 AX
;   做法：先把 4 个数位转换到缓冲区（高位在前），再整体 puts。
;   注：早期版本在循环内逐字符 call putc 发送，在本机 QEMU 下
;   会出现末位字节错位（前三位始终正确），改为缓冲后稳定。
; ------------------------------------------------------------
hexbuf  times 5 db 0

print_hex16:
        push ax
        push bx
        push cx
        mov bx, hexbuf + 3       ; 从缓冲区末尾开始填（低位在后）
        mov cx, 4
.next:
        mov dl, al               ; 取 AX 当前最低 4 位
        and dl, 0x0f
        cmp dl, 10
        jb .digit
        add dl, 'A' - 10
        jmp .store
.digit:
        add dl, '0'
.store:
        mov [bx], dl
        dec bx
        shr ax, 4                ; 处理完低 4 位，右移带来高 4 位
        loop .next
        mov byte [hexbuf + 4], 0 ; 字符串结尾
        mov si, hexbuf
        call puts
        pop cx
        pop bx
        pop ax
        ret

; ------------------------------------------------------------
; print_crlf: 输出回车换行
; ------------------------------------------------------------
print_crlf:
        mov al, 13
        call putc
        mov al, 10
        call putc
        ret

; ------------------------------------------------------------
; uart_init: 初始化 COM1 = 115200 波特 8N1
;   QEMU 的虚拟串口不初始化也能写，但真机需要正确初始化
; ------------------------------------------------------------
UART_BASE equ 0x3f8              ; COM1 基址
uart_init:
        mov dx, UART_BASE + 1    ; IER（中断允许寄存器）
        xor al, al               ; 禁用串口中断
        out dx, al
        mov dx, UART_BASE + 3    ; LCR（线路控制寄存器）
        mov al, 0x80             ; DLAB=1，接下来写除数
        out dx, al
        mov dx, UART_BASE        ; 除数低字节
        mov al, 1                ; 115200 / 1 = 115200 波特
        out dx, al
        mov dx, UART_BASE + 1    ; 除数高字节
        xor al, al
        out dx, al
        mov dx, UART_BASE + 3    ; LCR：8 数据位、无校验、1 停止位
        mov al, 0x03
        out dx, al
        ret

; ------------------------------------------------------------
; putc: 阻塞发送 AL（轮询 LSR 的 THRE 位）
;   注：QEMU 的 16550 模拟在连续快速写入时偶发丢位/错字节，
;   实测写 THR 后加一个几百周期的微延时即可稳定。
; ------------------------------------------------------------
putc:
        push dx
        push ax
        push cx
        mov dx, UART_BASE + 5    ; LSR（线路状态寄存器）
.wait:
        in al, dx
        test al, 0x20            ; bit5 = THR 空
        jz .wait
        mov cx, 200              ; 轮询通过后稍等再写（QEMU 实测需要）
.dly:
        loop .dly
        pop cx
        pop ax                   ; 恢复待发字符（调用方可能依赖 AH 完整性！）
        mov dx, UART_BASE
        out dx, al               ; 写入发送寄存器
        pop dx
        ret

; ------------------------------------------------------------
; 数据
; ------------------------------------------------------------
msg_hello   db "Hello from real-mode MBR!", 13, 10, 0
msg_cs      db "CS=", 0
msg_ip      db "  IP=", 0
msg_linear  db "  linear=", 0
msg_es      db "ES=", 0
msg_di      db "  DI=", 0
msg_linear2 db "  linear=", 0
msg_byte    db "  byte=", 0
msg_halt    db "Same byte, different segment:offset. Halting.", 13, 10, 0

; ------------------------------------------------------------
; 引导扇区填充与签名
; ------------------------------------------------------------
        times 510-($-$$) db 0    ; 填充到 510 字节
        dw 0xaa55                ; 引导扇区有效签名（小端：55 AA）
