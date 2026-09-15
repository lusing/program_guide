; ============================================================
; 文件: 01_data_movement/test_link.asm                     [macOS 版]
; 描述: 验证「NASM 汇编 -> Mach-O 链接 -> 运行」整条流水线
; 平台: macOS x86-64（Mach-O + System V AMD64）
; 汇编: nasm -f macho64 examples-macos/01_data_movement/test_link.asm -o build/test_link.o
; 链接: clang -arch x86_64 build/test_link.o -o build/test_link
;
;       不用 clang 也可以，直接用苹果的 ld（不调用 libSystem，纯系统调用）。
;       macOS 的可执行文件必须动态链接，所以即使一个库函数都不调，
;       也要用 -lSystem 把加载信息带上，否则 ld 会报
;       "dynamic executables or dylibs must link with libSystem.dylib"：
;       SDK=$(xcrun --show-sdk-path)
;       ld -arch x86_64 -macosx_version_min 11.0 -e _main build/test_link.o \
;          -o build/test_link -lSystem -syslibroot "$SDK" -L"$SDK/usr/lib"
;
; 对照: examples/01_data_movement/test_link.asm（Windows 版走 Win32 的
;       GetStdHandle / WriteFile，不依赖 CRT 初始化）
;
; 本例完全不调用 libSystem，输出和退出都走 BSD 系统调用。
; macOS 上系统调用号要加上 0x2000000（BSD 系统调用类），例如：
;   0x2000001 = exit      0x2000004 = write
; 这与 Linux 的 syscall 编号完全不兼容，也是两个平台汇编不可移植的主因之一。
; ============================================================
default rel

%define SYS_exit   0x2000001
%define SYS_write  0x2000004
%define STDOUT     1

global _main

section .data
    msg     db "NASM + Mach-O + ld/clang pipeline OK!", 10
    msg_len equ $ - msg

section .text
_main:
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
