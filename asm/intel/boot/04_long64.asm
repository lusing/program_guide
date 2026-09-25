; ============================================================
; 04_long64.asm - 第二阶段：完整 16→32→64 引导链
; ============================================================
; 从实模式一路进入 64 位长模式（IA-32e）：
;   1. 实模式：开 A20，建 GDT（含 64 位代码段描述符，L=1）
;   2. CR0.PE=1 → 32 位保护模式（过渡用）
;   3. 构造 4 级分页表（2MB 大页，恒等映射低 1GB）：
;        PML4  @0x10000   PML4[0]  -> PDPT
;        PDPT  @0x11000   PDPT[0]  -> PD
;        PD    @0x12000   PD[0..511] 每个 = 2MB 页（PS=1）
;   4. CR4.PAE=1 → CR3=PML4 → EFER.LME=1（MSR 0xC0000080）→ CR0.PG=1
;      （顺序不能乱：进长模式前必须先开 PAE 并装好 CR3）
;   5. 远跳到 64 位代码段（L=1）→ 64 位模式
;   6. 64 位演示：64 位寄存器、RIP 相对寻址、rdmsr 读回 EFER
;
; 预期串口输出（节选）：
;   [LM64] Hello from 64-bit long mode!
;   [LM64] RAX=123456789ABCDEF0  (64-bit register works)
;   [LM64] RIP=0000000000008Dxx  (RIP-relative LEA)
;   [LM64] EFER=00000500  (LMA=1, bit10)
;   [LM64] paging still active: CR3=0000000000010000
; ============================================================

        org 0x8000
        bits 16

GDT_ADDR   equ 0xc000
PML4       equ 0x10000
PDPT       equ 0x11000
PD         equ 0x12000
STACK_TOP  equ 0xfff0

start:
        call uart_init16

        in al, 0x92
        or al, 0x02
        and al, 0xfe
        out 0x92, al

        ; ---- GDT：空 + 32位代码 + 数据 + 64位代码 ----
        mov word [GDT_ADDR+8+0], 0xFFFF
        mov word [GDT_ADDR+8+2], 0x0000
        mov byte [GDT_ADDR+8+4], 0x00
        mov byte [GDT_ADDR+8+5], 0x9A          ; 32 位代码段（过渡用）
        mov byte [GDT_ADDR+8+6], 0xCF
        mov byte [GDT_ADDR+8+7], 0x00

        mov word [GDT_ADDR+16+0], 0xFFFF
        mov word [GDT_ADDR+16+2], 0x0000
        mov byte [GDT_ADDR+16+4], 0x00
        mov byte [GDT_ADDR+16+5], 0x92         ; 数据段
        mov byte [GDT_ADDR+16+6], 0xCF
        mov byte [GDT_ADDR+16+7], 0x00

        mov word [GDT_ADDR+24+0], 0x0000       ; 64 位代码段：limit 无意义
        mov word [GDT_ADDR+24+2], 0x0000
        mov byte [GDT_ADDR+24+4], 0x00
        mov byte [GDT_ADDR+24+5], 0x9A         ; L=1 D=0 在下一字节
        mov byte [GDT_ADDR+24+6], 0x20         ; L=1, D=0, G=0, limit=0
        mov byte [GDT_ADDR+24+7], 0x00

        mov word [GDT_ADDR-6], 31              ; 4 个描述符
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
; 32 位保护模式：构造 4 级分页，然后激活长模式
; ============================================================
        bits 32
pm_entry:
        mov ax, 0x10
        mov ds, ax
        mov es, ax
        mov ss, ax
        mov esp, STACK_TOP

        call uart_init32

        ; ---- 清零三张表（每张 4KB）----
        mov edi, PML4
        mov ecx, 1024
        xor eax, eax
        rep stosd
        mov edi, PDPT
        mov ecx, 1024
        xor eax, eax
        rep stosd
        mov edi, PD
        mov ecx, 1024
        xor eax, eax
        rep stosd

        ; ---- PML4[0] -> PDPT ----
        mov eax, PDPT
        or eax, 3                        ; P | RW
        mov [PML4], eax

        ; ---- PDPT[0] -> PD ----
        mov eax, PD
        or eax, 3
        mov [PDPT], eax

        ; ---- PD[0..511]：每个 2MB 大页，共 1GB 恒等映射 ----
        mov edi, PD
        mov eax, 0x83                    ; PS=1(bit7) | P | RW，物理地址 0 起
        mov ecx, 512
.fill_pd:
        mov [edi], eax
        add eax, 0x200000                ; 下一个 2MB
        add edi, 8                       ; 长模式表项是 8 字节
        loop .fill_pd

        mov esi, msg_tables
        call puts32

        ; ---- 开 PAE，装 CR3 ----
        mov eax, cr4
        or eax, 0x20                     ; CR4.PAE = 1
        mov cr4, eax
        mov eax, PML4
        mov cr3, eax

        ; ---- EFER.LME = 1（MSR 0xC0000080 的 bit8）----
        mov ecx, 0xc0000080
        rdmsr                            ; EDX:EAX = EFER
        or eax, 0x100                    ; LME
        wrmsr

        ; ---- 开分页：从这一刻起 LMA=1，进入 IA-32e ----
        mov eax, cr0
        or eax, 0x80000000               ; PG = 1
        mov cr0, eax

        mov esi, msg_lma
        call puts32

        ; ---- 远跳到 64 位代码段（L=1）----
        jmp 0x18:lm_entry

; ============================================================
; 64 位长模式
; ============================================================
        bits 64
lm_entry:
        mov ax, 0x10                     ; 数据段选择子（基址被忽略）
        mov ds, ax
        mov es, ax
        mov ss, ax
        mov rsp, STACK_TOP

        call uart_init64

        mov rsi, msg_hello
        call puts64

        ; ---- 64 位寄存器演示 ----
        mov rax, 0x123456789abcdef0
        mov rsi, msg_rax
        call puts64
        call hex64
        mov rsi, msg_rax2
        call puts64
        call crlf64

        ; ---- RIP 相对寻址（64 位新增的标配寻址方式）----
        mov rsi, msg_rip
        call puts64
        lea rax, [rel .here]             ; RIP 相对：与位置无关
.here:
        call hex64
        call crlf64

        ; ---- 读回 EFER：LMA(bit10) 应为 1 ----
        mov rsi, msg_efer
        call puts64
        mov ecx, 0xc0000080
        rdmsr                            ; EDX:EAX = EFER
        and eax, 0xFFFF
        call hex64
        mov rsi, msg_efer2
        call puts64
        call crlf64

        ; ---- 分页仍然有效 ----
        mov rsi, msg_cr3
        call puts64
        mov rax, cr3
        call hex64
        call crlf64

        mov rsi, msg_done
        call puts64

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
puts32:
        lodsb
        test al, al
        jz .done
        push esi
        call putc32
        pop esi
        jmp puts32
.done:
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

; ------------------------------------------------------------
; 64 位串口例程
; ------------------------------------------------------------
        bits 64
uart_init64:
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
putc64:
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
puts64:
        push rax
.l:     lodsb
        test al, al
        jz .done
        call putc64
        jmp .l
.done:
        pop rax                     ; 保存 RAX：调用方常把待打印值放在 RAX
        ret
crlf64:
        mov al, 13
        call putc64
        mov al, 10
        call putc64
        ret

hexbuf64 times 17 db 0
hex64:
        push rax
        push rcx
        push rdi
        lea rdi, [rel hexbuf64 + 15]
        mov rcx, 16
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
        mov [rdi], dl
        dec rdi
        shr rax, 4
        loop .next
        mov byte [hexbuf64 + 16], 0
        lea rsi, [rel hexbuf64]     ; 64 位惯用 RIP 相对寻址
        call puts64
        pop rdi
        pop rcx
        pop rax
        ret

; ------------------------------------------------------------
; 数据
; ------------------------------------------------------------
        bits 16
msg_switch db "S2: A20 on, GDT ready (incl. 64-bit code seg), switching to PM...", 13, 10, 0

        bits 32
msg_tables db "[LM32] PML4@0x10000 PDPT@0x11000 PD@0x12000, 512x2MB identity", 13, 10, 0
msg_lma    db "[LM32] PAE=1 CR3 loaded EFER.LME=1 PG=1 -> IA-32e active", 13, 10, 0

        bits 64
msg_hello  db "[LM64] Hello from 64-bit long mode!", 13, 10, 0
msg_rax    db "[LM64] RAX=", 0
msg_rax2   db "  (64-bit register works)", 0
msg_rip    db "[LM64] RIP=", 0
msg_efer   db "[LM64] EFER=", 0
msg_efer2  db "  (bit10 LMA=1)", 0
msg_cr3    db "[LM64] paging still active: CR3=", 0
msg_done   db "[LM64] full chain done: real -> PM32 -> paging -> long mode", 13, 10, 0
