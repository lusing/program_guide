; 第 7 章示例的测试输入：既有内存操作也有调用，供 MemOpAnalysis 数数

@.intfmt = private constant [4 x i8] c"%d\0A\00"
@.ok = private constant [16 x i8] c"==== 07 ok ====\00"

declare i32 @printf(ptr, ...)
declare i32 @puts(ptr)

; alloca 风格的累加（第 4 章）：load/store 多，正是 MemOpAnalysis 的猎物
define i32 @sum_to(i32 %n) {
entry:
  %i.addr = alloca i32
  %acc.addr = alloca i32
  store i32 1, ptr %i.addr
  store i32 0, ptr %acc.addr
  br label %loop.cond

loop.cond:
  %i = load i32, ptr %i.addr
  %cond = icmp sle i32 %i, %n
  br i1 %cond, label %loop.body, label %loop.end

loop.body:
  %acc = load i32, ptr %acc.addr
  %acc.next = add i32 %acc, %i
  store i32 %acc.next, ptr %acc.addr
  %i.next = add i32 %i, 1
  store i32 %i.next, ptr %i.addr
  br label %loop.cond

loop.end:
  %r = load i32, ptr %acc.addr
  ret i32 %r
}

define i32 @main() {
entry:
  %a = call i32 @sum_to(i32 10)
  %pf1 = call i32 (ptr, ...) @printf(ptr @.intfmt, i32 %a)
  %pm = call i32 @puts(ptr @.ok)
  ret i32 0
}
