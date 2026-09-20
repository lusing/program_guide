; 第 6 章示例的测试输入：三个函数 + main
; 经 hello-pass 处理后必须原样可运行（PreservedAnalyses::all() 的承诺）

@.intfmt = private constant [4 x i8] c"%d\0A\00"
@.ok = private constant [16 x i8] c"==== 06 ok ====\00"

declare i32 @printf(ptr, ...)
declare i32 @puts(ptr)

define i32 @square(i32 %x) {
entry:
  %r = mul i32 %x, %x
  ret i32 %r
}

define i32 @quad(i32 %x) {
entry:
  %s = call i32 @square(i32 %x)
  %r = mul i32 %s, %s
  ret i32 %r
}

define i32 @cube(i32 %x) {
entry:
  %q = call i32 @quad(i32 %x)
  %c = mul i32 %q, %x
  ret i32 %c
}

define i32 @main() {
entry:
  %a = call i32 @cube(i32 3)
  %pf1 = call i32 (ptr, ...) @printf(ptr @.intfmt, i32 %a)
  %pm = call i32 @puts(ptr @.ok)
  ret i32 0
}
