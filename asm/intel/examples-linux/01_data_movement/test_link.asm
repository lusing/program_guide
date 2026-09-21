; ============================================================
; 文件: 01_data_movement/test_link.asm                     [Linux 版]
; 描述: 验证「NASM 汇编 -> ELF 链接 -> 运行」整条流水线
; 平台: Linux x86-64（ELF + System V AMD64）
; 汇编: nasm -f elf64 examples-linux/01_data_movement/test_link.asm -o build/test_link.o
; 链接: ld build/test_link.o -o build/test_link
;
;       纯系统调用程序不需要 CRT 启动文件，GNU ld 默认入口就是
;       _start，所以一行参数都不用加（对照 macOS：那边可执行文件
;       必须动态链接，即使不调 libSystem 也要 -lSystem 带上加载信息）。
;
; 对照: examples/01_data_movement/test_link.asm（Windows 版走 Win32 的
;       GetStdHandle / WriteFile，不依赖 CRT 初始化）
;
; 本例完全不调用 libc，输出和退出都走 Linux 原生系统调用：
;   write = 1      exit = 60     （x86-64 专用编号，和其他架构不通用）
; 这与 macOS 的 BSD 类编号（要加上 0x2000000）完全不兼容，
; 也是两个平台汇编不可移植的主因之一。
; ============================================================
default rel

%define SYS_exit   60
%define SYS_write  1
%define STDOUT     1

global _start

section .data
    msg     db "NASM + ELF + ld pipeline OK!", 10
    msg_len equ $ - msg

section .text
_start:
    ; write(1, msg, msg_len)
    mov rax, SYS_write
    mov rdi, STDOUT
    lea rsi, [msg]
    mov rdx, msg_len
    syscall                      ; 返回值 rax = 实际写出的字节数

    ; 顺手把字节数转成退出码以外的东西不方便，这里直接 exit(0)
    ; 想验证 syscall 写入成功，可以在 shell 里看输出内容是否完整
    mov rax, SYS_exit
    xor rdi, rdi                 ; 退出码 0
    syscall
    ; 不会返回
