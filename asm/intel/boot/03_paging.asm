; ============================================================
; 03_paging.asm - 第二阶段：32 位两级分页
; ============================================================
; 在 02（进入保护模式）的基础上：
;   1. 在 0x10000 建页目录（4KB）、0x11000 建页表（4KB），先清零
;   2. 页目录项[0]     -> 页表 0x11000：物理 0~4MB 恒等映射
;      页目录项[768]   -> 同一张页表：0xC0000000 起也映射到物理 0 起
;      （一张页表复用于两个虚拟地址区间——证明「虚拟地址 -> 物理地址」的翻译）
;   3. CR3 = 页目录物理地址，CR0.PG = 1 开启分页
;   4. 验证：经 0xC0000100 写魔数，从 0x100（恒等映射）读回
;
; 预期串口输出（节选）：
;   [PG32] Hello from 32-bit protected mode!
;   [PG32] PD at 0x10000, PT at 0x11000 (identity 0-4MB, high 0xC0000000)
;   [PG32] CR3=00010000
;   [PG32] Paging enabled. CR0=80000011 (PG=1)
;   [PG32] write [0xC0000100]=DEADBEEF, read [0x0100]=DEADBEEF -> read back OK
; ============================================================

        org 0x8000
        bits 16

GDT_ADDR   equ 0xc000
PAGE_DIR   equ 0x10000             ; 页目录（4KB，4 字节对齐即可，4KB 天然对齐）
PAGE_TAB   equ 0x11000             ; 页表（4KB）
STACK_TOP  equ 0xfff0
MAGIC      equ 0xdeadbeef

start:
        call uart_init16

        in al, 0x92
        or al, 0x02
        and al, 0xfe
        out 0x92, al

        ; ---- GDT（与 02 相同的平坦模型）----
        mov word [GDT_ADDR+8+0], 0xFFFF
        mov word [GDT_ADDR+8+2], 0x0000
        mov byte [GDT_ADDR+8+4], 0x00
        mov byte [GDT_ADDR+8+5], 0x9A
        mov byte [GDT_ADDR+8+6], 0xCF
        mov byte [GDT_ADDR+8+7], 0x00
        mov word [GDT_ADDR+16+0], 0xFFFF
        mov word [GDT_ADDR+16+2], 0x0000
        mov byte [GDT_ADDR+16+4], 0x00
        mov byte [GDT_ADDR+16+5], 0x92
        mov byte [GDT_ADDR+16+6], 0xCF
        mov byte [GDT_ADDR+16+7], 0x00

        mov word [GDT_ADDR-6], 23
        mov dword [GDT_ADDR-4], GDT_ADDR
        lgdt [GDT_ADDR-6]

        mov si, msg_switch
        call puts16

        cli
        mov eax, cr0
        or eax, 1
        mov cr0, eax
        jmp 0x08:pm_entry

; ============================================================
        bits 32
pm_entry:
        mov ax, 0x10
        mov ds, ax
        mov es, ax
        mov ss, ax
        mov esp, STACK_TOP

        call uart_init32

        mov esi, msg_hello
        call puts32

        ; ---- 清零页目录和页表 ----
        mov edi, PAGE_DIR
        mov ecx, 1024
        xor eax, eax
        rep stosd
        mov edi, PAGE_TAB
        mov ecx, 1024
        xor eax, eax
        rep stosd

        ; ---- 填页表：1024 项 -> 物理 0~4MB，属性 P=1 RW=1 US=0 ----
        mov edi, PAGE_TAB
        mov eax, 0x00000003              ; 物理地址 0 | P | RW
        mov ecx, 1024
.fill_pt:
        mov [edi], eax
        add eax, 0x1000                  ; 下一个 4KB 页
        add edi, 4
        loop .fill_pt

        ; ---- 填页目录：PDE[0] 与 PDE[768] 指向同一张页表 ----
        mov eax, PAGE_TAB
        or eax, 3                        ; P | RW
        mov [PAGE_DIR + 0*4], eax        ; 虚拟 0x00000000~
        mov [PAGE_DIR + 768*4], eax      ; 虚拟 0xC0000000~（768 = 0xC0000000>>22）

        mov esi, msg_layout
        call puts32

        ; ---- 开启分页 ----
        mov eax, PAGE_DIR
        mov cr3, eax
        mov esi, msg_cr3
        call puts32
        mov eax, cr3
        call hex32
        call crlf32

        mov eax, cr0
        or eax, 0x80000000               ; PG = 1
        mov cr0, eax                     ; 从这条指令之后，所有地址都是虚拟地址

        mov esi, msg_pgon
        call puts32
        mov eax, cr0
        call hex32
        mov esi, msg_pgon2
        call puts32
        call crlf32

        ; ---- 验证 1：高端地址读物理 0 ----
        mov esi, msg_v1a
        call puts32
        mov eax, [0xc0000000]
        call hex32
        mov esi, msg_v1b
        call puts32
        mov eax, [0x00000000]
        call hex32
        mov esi, msg_v1c
        call puts32
        call crlf32

        ; ---- 验证 2：高端写、低端读（同一物理页）----
        mov dword [0xc0000100], MAGIC
        mov esi, msg_v2a
        call puts32
        mov eax, [0x00000100]
        call hex32
        mov esi, [0x00000100]
        cmp esi, MAGIC
        jne .fail
        mov esi, msg_v2ok
        call puts32
        call crlf32
        jmp .halt
.fail:
        mov esi, msg_v2bad
        call puts32
        call crlf32

.halt:
        cli
        hlt
        jmp .halt

; ------------------------------------------------------------
; 16 位串口例程
; ------------------------------------------------------------
        bits 16
UART_BASE equ 0x3f8
uart_init16:
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
puts16:
        lodsb
        test al, al
        jz .done
        call putc16
        jmp puts16
.done:
        ret
putc16:
        push dx
        push ax
        mov dx, UART_BASE + 5
.wait:
        in al, dx
        test al, 0x20
        jz .wait
        pop ax
        mov dx, UART_BASE
        out dx, al
        pop dx
        ret

; ------------------------------------------------------------
; 32 位串口例程
; ------------------------------------------------------------
        bits 32
uart_init32:
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
putc32:
        push dx
        push ax
        mov dx, UART_BASE + 5
.wait:
        in al, dx
        test al, 0x20
        jz .wait
        pop ax
        mov dx, UART_BASE
        out dx, al
        pop dx
        ret
puts32:
        lodsb
        test al, al
        jz .done
        call putc32
        jmp puts32
.done:
        ret
crlf32:
        mov al, 13
        call putc32
        mov al, 10
        call putc32
        ret

hexbuf32 times 9 db 0
hex32:
        pushad
        mov edi, hexbuf32 + 7
        mov ecx, 8
.next:
        mov dl, al
        and dl, 0x0f
        cmp dl, 10
        jb .digit
        add dl, 'A' - 10
        jmp .store
.digit:
        add dl, '0'
.store:
        mov [edi], dl
        dec edi
        shr eax, 4
        loop .next
        mov byte [hexbuf32 + 8], 0
        mov esi, hexbuf32
        call puts32
        popad
        ret

; ------------------------------------------------------------
; 数据
; ------------------------------------------------------------
        bits 16
msg_switch db "S2: A20 on, GDT at 0xC000, switching to PM...", 13, 10, 0

        bits 32
msg_hello  db "[PG32] Hello from 32-bit protected mode!", 13, 10, 0
msg_layout db "[PG32] PD at 0x10000, PT at 0x11000 (identity 0-4MB, high 0xC0000000)", 13, 10, 0
msg_cr3    db "[PG32] CR3=", 0
msg_pgon   db "[PG32] Paging enabled. CR0=", 0
msg_pgon2  db " (PG=1)", 0
msg_v1a    db "[PG32] high[0xC0000000]=", 0
msg_v1b    db " low[0x00000000]=", 0
msg_v1c    db " (same phys page)", 0
msg_v2a    db "[PG32] write [0xC0000100]=DEADBEEF, read [0x0100]=", 0
msg_v2ok   db " -> read back OK", 0
msg_v2bad  db " -> MISMATCH", 0
