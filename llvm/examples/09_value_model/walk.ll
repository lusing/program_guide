; 第 9 章示例的输入：walker 工具解析它、遍历它、做一次 RAUW 手术

@.intfmt = private constant [4 x i8] c"%d\0A\00"
@.ok = private constant [16 x i8] c"==== 09 ok ====\00"

declare i32 @printf(ptr, ...)
declare i32 @puts(ptr)

define i32 @square(i32 %x) {
entry:
  %r = mul i32 %x, %x
  ret i32 %r
}

; 3-4-5 直角三角形：square(3) + square(4) = 25
define i32 @hypot_sq(i32 %a, i32 %b) {
entry:
  %s1 = call i32 @square(i32 %a)
  %s2 = call i32 @square(i32 %b)
  %t = add i32 %s1, %s2
  ret i32 %t
}

define i32 @main() {
entry:
  %h = call i32 @hypot_sq(i32 3, i32 4)
  %pf = call i32 (ptr, ...) @printf(ptr @.intfmt, i32 %h)
  %pm = call i32 @puts(ptr @.ok)
  ret i32 0
}
