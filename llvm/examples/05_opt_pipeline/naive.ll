; 第 5 章示例：故意写"笨"的 IR，观察各级优化
; 对照命令：
;   opt -O0 naive.ll -S -o naive.O0.ll   … 依次到 -O3
;   lli naive.O2.ll   （四级输出行为必须一致）
;
; 笨点清单（都是优化器的粮草）：
;   * acc/i 全走 alloca（mem2reg 可提升）
;   * %dead 永远用不到（死代码）
;   * %zero = mul x, 0（常量折叠）
;   * 每轮循环重算 %limit = add n, 0（循环不变量外提）

@.intfmt = private constant [4 x i8] c"%d\0A\00"
@.ok = private constant [16 x i8] c"==== 05 ok ====\00"

declare i32 @printf(ptr, ...)
declare i32 @puts(ptr)

define i32 @sum_to(i32 %n) {
entry:
  %i.addr = alloca i32
  %acc.addr = alloca i32
  %dead = alloca i32
  store i32 1, ptr %i.addr
  store i32 0, ptr %acc.addr
  store i32 999, ptr %dead
  %zero = mul i32 %n, 0
  br label %loop.cond

loop.cond:
  %i = load i32, ptr %i.addr
  %limit = add i32 %n, %zero
  %cond = icmp sle i32 %i, %limit
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
  %unused = load i32, ptr %dead
  ret i32 %r
}

define i32 @main() {
entry:
  %a = call i32 @sum_to(i32 100)
  %pf1 = call i32 (ptr, ...) @printf(ptr @.intfmt, i32 %a)   ; 5050
  %b = call i32 @sum_to(i32 1)
  %pf2 = call i32 (ptr, ...) @printf(ptr @.intfmt, i32 %b)   ; 1
  %pm = call i32 @puts(ptr @.ok)
  ret i32 0
}
