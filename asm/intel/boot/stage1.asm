; ============================================================
; stage1.asm - 共享的两段式引导加载器（扇区 0，512 字节）
; ============================================================
; 职责：
;   1. 初始化实模式环境（段寄存器、栈）
;   2. 用 BIOS 扩展读（INT 13h AH=42h，LBA 寻址）把磁盘上
;      LBA 1 起的 32 个扇区（16KB）读到 0000:8000
;   3. 远跳转到 0000:8000 执行第二阶段（02/03/04 示例）
;
; 串口会先打印 "S1: loaded 32 sectors, jumping to 0x8000"
; ============================================================

        org 0x7c00
        bits 16

start:
        cli
        xor ax, ax
        mov ds, ax
        mov es, ax
        mov ss, ax
        mov sp, 0x7c00
        sti

        call uart_init

        ; ---- BIOS 扩展读：DAP（磁盘地址包）描述要读什么、读到哪 ----
        mov si, dap
        mov ah, 0x42             ; 扩展读功能号
        mov dl, 0x80             ; 第一块硬盘（QEMU 的 raw 镜像）
        int 0x13
        jc .disk_err

        mov si, msg_ok
        call puts
        jmp 0x0000:0x8000        ; 远跳转进入第二阶段

.disk_err:
        mov si, msg_err
        call puts
.hang:
        hlt
        jmp .hang

; ------------------------------------------------------------
; 串口例程（与 01_mbr_hello 相同）
; ------------------------------------------------------------
UART_BASE equ 0x3f8
puts:
        lodsb
        test al, al
        jz .done
        call putc
        jmp puts
.done:
        ret
uart_init:
        mov dx, UART_BASE + 1
        xor al, al
        out dx, al
        mov dx, UART_BASE + 3
        mov al, 0x80
        out dx, al
        mov dx, UART_BASE
        mov al, 1
        out dx, al
        mov dx, UART_BASE + 1
        xor al, al
        out dx, al
        mov dx, UART_BASE + 3
        mov al, 0x03
        out dx, al
        ret
putc:
        push dx
        push ax
        push cx
        mov dx, UART_BASE + 5
.wait:
        in al, dx
        test al, 0x20
        jz .wait
        mov cx, 200              ; 轮询通过后稍等再写（QEMU 实测需要）
.dly:
        loop .dly
        pop cx
        pop ax
        mov dx, UART_BASE
        out dx, al
        pop dx
        ret

; ------------------------------------------------------------
; 数据
; ------------------------------------------------------------
msg_ok  db "S1: loaded 32 sectors, jumping to 0x8000", 13, 10, 0
msg_err db "S1: disk read error, halting", 13, 10, 0

; DAP：磁盘地址包（16 字节）
dap:
        db 0x10, 0               ; 包大小 16 字节
        dw 32                    ; 读 32 个扇区（16KB，第二阶段上限）
        dw 0x0000, 0x0800        ; 目标地址 0800:0000 = 0x8000
        dq 1                     ; 起始 LBA = 1（扇区 0 是本加载器）

        times 510-($-$$) db 0
        dw 0xaa55
