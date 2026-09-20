; 第 4 章示例（下）：alloca 风格——clang 前端生成 IR 的典型形态
; 运行：lli allocastyle.ll（结果与 phi.ll 完全一致）
; 然后看 mem2reg 把它变回 phi：
;   opt -passes=mem2reg allocastyle.ll -S

@.intfmt = private constant [4 x i8] c"%d\0A\00"
@.ok = private constant [16 x i8] c"==== 04 ok ====\00"

declare i32 @printf(ptr, ...)
declare i32 @puts(ptr)

; 可变变量 = 栈槽（alloca）+ load/store。mem2reg 能自动把它提升为 SSA
define i32 @sum_to(i32 %n) {
entry:
  %i.addr = alloca i32                 ; int i 的栈槽
  %acc.addr = alloca i32               ; int acc 的栈槽
  store i32 1, ptr %i.addr             ; i = 1
  store i32 0, ptr %acc.addr           ; acc = 0
  br label %loop.cond

loop.cond:
  %i = load i32, ptr %i.addr           ; 每次用 i 都要重新 load
  %cond = icmp sle i32 %i, %n
  br i1 %cond, label %loop.body, label %loop.end

loop.body:
  %acc = load i32, ptr %acc.addr
  %acc.next = add i32 %acc, %i
  store i32 %acc.next, ptr %acc.addr   ; acc += i
  %i.next = add i32 %i, 1
  store i32 %i.next, ptr %i.addr       ; i++
  br label %loop.cond

loop.end:
  %r = load i32, ptr %acc.addr
  ret i32 %r
}

define i32 @main() {
entry:
  %a = call i32 @sum_to(i32 100)
  %pf1 = call i32 (ptr, ...) @printf(ptr @.intfmt, i32 %a)   ; 5050
  %b = call i32 @sum_to(i32 0)
  %pf2 = call i32 (ptr, ...) @printf(ptr @.intfmt, i32 %b)   ; 0
  %pm = call i32 @puts(ptr @.ok)
  ret i32 0
}
