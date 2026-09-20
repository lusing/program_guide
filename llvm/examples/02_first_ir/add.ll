; 第 2 章示例：第一个手写 LLVM IR
; 运行：lli add.ll     （lli 执行模块里的 @main，返回值即退出码）
; 汇编：llvm-as add.ll -o add.bc   （文本 IR → 位码 bitcode）

; ---- 全局数据区 ----
; 字符串常量：类型是 [N x i8]，末尾必须自己补 \00（C 风格终止符）
; "%d\n" = 3 个字符 + 1 个 NUL = 4 字节
@.intfmt = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1
; 输出标记（printf 的 %s 打印它；puts 也可以）
@.ok = private unnamed_addr constant [16 x i8] c"==== 02 ok ====\00", align 1

; ---- 函数声明（外部函数只要声明签名，链接器/JIT 负责找实现）----
declare i32 @printf(ptr, ...)     ; 变参函数：省略号写在参数表里
declare i32 @puts(ptr)            ; puts 自带换行

; ---- 函数定义 ----
; 两数相加。%a %b 是带名字的参数（SSA 值），不带名字就叫 %0 %1
define i32 @add(i32 %a, i32 %b) {
entry:
  %sum = add i32 %a, %b           ; 每条指令的结果都产出一个新的 SSA 值
  ret i32 %sum
}

define i32 @main() {
entry:
  %r1 = call i32 @add(i32 3, i32 4)
  %pf1 = call i32 (ptr, ...) @printf(ptr @.intfmt, i32 %r1)   ; 打印 7
  %r2 = call i32 @add(i32 %r1, i32 100)
  %pf2 = call i32 (ptr, ...) @printf(ptr @.intfmt, i32 %r2)   ; 打印 107
  %pm = call i32 @puts(ptr @.ok)
  ret i32 0
}
