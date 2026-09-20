; 第 4 章示例（上）：手写 SSA——用 phi 求和 1..n
; 运行：lli phi.ll
; 对照：allocastyle.ll 用 alloca/load/store 写同一个循环

@.intfmt = private constant [4 x i8] c"%d\0A\00"
@.ok = private constant [16 x i8] c"==== 04 ok ====\00"

declare i32 @printf(ptr, ...)
declare i32 @puts(ptr)

; SSA 风格：循环变量 i 和累加器 acc 都是 phi 节点
define i32 @sum_to(i32 %n) {
entry:
  br label %loop.head

loop.head:
  ;      来源值        来自哪个块
  %i   = phi i32 [ 1, %entry    ], [ %i.next,   %loop.body ]
  %acc = phi i32 [ 0, %entry    ], [ %acc.next, %loop.body ]
  %cond = icmp sle i32 %i, %n          ; i <= n ?
  br i1 %cond, label %loop.body, label %exit

loop.body:
  %acc.next = add i32 %acc, %i
  %i.next = add i32 %i, 1
  br label %loop.head

exit:
  ret i32 %acc
}

define i32 @main() {
entry:
  %a = call i32 @sum_to(i32 100)
  %pf1 = call i32 (ptr, ...) @printf(ptr @.intfmt, i32 %a)   ; 5050
  %b = call i32 @sum_to(i32 0)
  %pf2 = call i32 (ptr, ...) @printf(ptr @.intfmt, i32 %b)   ; 0（一次都不进循环体）
  %pm = call i32 @puts(ptr @.ok)
  ret i32 0
}
