; ============================================================
; 02_pm32.asm - 第二阶段：从实模式进入 32 位保护模式
; ============================================================
; 由 stage1 加载到 0000:8000 并跳转过来（此时仍是实模式）。
;
; 流程：
;   1. 打开 A20 地址线（fast A20，端口 0x92）
;   2. 在 0xC000 构造 GDT（空描述符 + 代码段 + 数据段，平坦模型）
;   3. LGDT 加载 GDTR
;   4. CR0 置 PE 位 → 远跳转刷新 CS（进入 32 位保护模式）
;   5. 重载 DS/ES/SS 为数据段选择子，设置 ESP
;   6. 32 位代码继续用串口打印：CR0、GDTR、CS 选择子、CPL
;
; 预期串口输出（在 stage1 的消息之后）：
;   S2: A20 on, GDT at 0xC000, switching to PM...
;   [PM32] Hello from 32-bit protected mode!
;   [PM32] CR0=00000011  (PE=1, PG=0)
;   [PM32] GDTR: base=0000C000 limit=00000017
;   [PM32] CS=0008 (CPL=0)  DS=0010  ESP=0000FFF0
;   [PM32] segment base=0 limit=4GB -> flat model works
; ============================================================

        org 0x8000
        bits 16

GDT_ADDR   equ 0xc000              ; GDT 放在 stage2 代码（≤0xC000）之后
STACK_TOP  equ 0xfff0              ; 32 位栈顶（1MB 以内的传统空闲区）

start:
        ; ---- 实模式收尾：开 A20、建 GDT、报告进度 ----
        call uart_init16

        ; fast A20：端口 0x92 的 bit1
        in al, 0x92
        or al, 0x02
        and al, 0xfe               ; bit0 是 fast reset，必须保持 0
        out 0x92, al

        ; 构造 GDT：3 个描述符 × 8 字节，写在 0xC000
        mov word [GDT_ADDR], 0x0000        ; 空描述符（全 0）
        mov word [GDT_ADDR+2], 0x0000
        mov word [GDT_ADDR+4], 0x0000
        mov word [GDT_ADDR+6], 0x0000

        ; 代码段：基址 0，限长 4GB（G=1, S=1, Type=1010b 可读可执行）
        mov word [GDT_ADDR+8+0], 0xFFFF    ; limit[15:0]
        mov word [GDT_ADDR+8+2], 0x0000    ; base[15:0]
        mov byte [GDT_ADDR+8+4], 0x00      ; base[23:16]
        mov byte [GDT_ADDR+8+5], 0x9A      ; P=1 DPL=00 S=1 Type=1010
        mov byte [GDT_ADDR+8+6], 0xCF      ; G=1 D=1 limit[19:16]=F
        mov byte [GDT_ADDR+8+7], 0x00      ; base[31:24]

        ; 数据段：同基址同限长，Type=0010b 可读写
        mov word [GDT_ADDR+16+0], 0xFFFF
        mov word [GDT_ADDR+16+2], 0x0000
        mov byte [GDT_ADDR+16+4], 0x00
        mov byte [GDT_ADDR+16+5], 0x92     ; P=1 DPL=00 S=1 Type=0010
        mov byte [GDT_ADDR+16+6], 0xCF
        mov byte [GDT_ADDR+16+7], 0x00

        ; GDTR：limit = 3*8-1 = 23，base = 0xC000
        mov word [GDT_ADDR-6], 23
        mov dword [GDT_ADDR-4], GDT_ADDR   ; 注意：base 是 4 字节
        lgdt [GDT_ADDR-6]

        mov si, msg_switch
        call puts16

        ; ---- 关中断、置 PE、远跳刷新流水线 ----
        cli
        mov eax, cr0
        or eax, 1                   ; CR0.PE = 1
        mov cr0, eax
        jmp 0x08:pm_entry           ; 远跳转：CS = 代码段选择子

; ============================================================
; 32 位保护模式从这里开始
; ============================================================
        bits 32
pm_entry:
        mov ax, 0x10                ; 数据段选择子
        mov ds, ax
        mov es, ax
        mov ss, ax
        mov esp, STACK_TOP

        call uart_init32

        mov esi, msg_hello
        call puts32

        ; ---- 打印 CR0 ----
        mov esi, msg_cr0
        call puts32
        mov eax, cr0
        call hex32
        mov esi, msg_pe
        call puts32
        call crlf32

        ; ---- 打印 GDTR ----
        ; SGDT 写入 6 字节：16 位 limit 在前、32 位 base 在后（+2 处）
        mov esi, msg_gdtr
        call puts32
        sub esp, 8
        sgdt [esp]
        mov eax, [esp+2]            ; base（未对齐读取，x86 允许）
        call hex32
        mov esi, msg_gdtr2
        call puts32
        movzx eax, word [esp]       ; limit
        call hex32
        add esp, 8
        call crlf32

        ; ---- 打印 CS 选择子与 CPL ----
        mov esi, msg_cs
        call puts32
        mov ax, cs
        movzx eax, ax
        call hex32
        mov esi, msg_cpl
        call puts32
        mov ax, cs                  ; CPL = CS 选择子的低 2 位
        and eax, 3
        add eax, '0'
        call putc32
        mov esi, msg_ds
        call puts32
        mov ax, ds
        movzx eax, ax
        call hex32
        mov esi, msg_esp
        call puts32
        mov eax, esp
        call hex32
        call crlf32

        ; ---- 平坦模型的证明：用 32 位寻址写读 0x7C00 处的 stage1 ----
        mov esi, msg_flat
        call puts32
        mov al, [0x7c00]            ; stage1 第一字节 = CLI (0xFA)
        call hex8
        mov esi, msg_flat2
        call puts32
        call crlf32

.halt:
        cli
        hlt
        jmp .halt

; ------------------------------------------------------------
; 16 位串口例程（进入 PM 之前用）
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
; 32 位串口例程（缓冲式打印：数字先转成字符串再整体输出）
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
        lodsb                       ; DS:ESI（平坦段 = 线性地址）
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

; hex32: 以 8 位十六进制打印 EAX（缓冲式）
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

; hex8: 以 2 位十六进制打印 AL
hex8:
        pushad
        movzx eax, al
        mov edi, hexbuf32 + 1
        mov ecx, 2
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
        mov byte [hexbuf32 + 2], 0
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
msg_hello db "[PM32] Hello from 32-bit protected mode!", 13, 10, 0
msg_cr0   db "[PM32] CR0=", 0
msg_pe    db "  (PE=1, PG=0)", 0
msg_gdtr  db "[PM32] GDTR: base=", 0
msg_gdtr2 db " limit=", 0
msg_cs    db "[PM32] CS=", 0
msg_cpl   db " (CPL=", 0
msg_ds    db ")  DS=", 0
msg_esp   db "  ESP=", 0
msg_flat  db "[PM32] byte at 0x7C00 (stage1 CLI) = 0x", 0
msg_flat2 db ", flat model works", 0
