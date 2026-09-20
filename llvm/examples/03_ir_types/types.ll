; 第 3 章示例：IR 类型系统与聚合数据
; 运行：lli types.ll

; ---- 命名结构体：之后可直接用 %Point 指代 ----
%Point = type { i32, double }

; ---- 全局变量 / 常量 ----
@table = global [4 x i32] [i32 10, i32 20, i32 30, i32 40]      ; 可变全局（数组）
@origin = constant %Point zeroinitializer                        ; 只读全局（零初始化语法）
@name = private constant [6 x i8] c"hello\00"                    ; 字符串本质是 i8 数组
@counter = global i64 0, align 8                                 ; 显式对齐

; ---- printf 格式串 ----
@.intfmt = private constant [4 x i8] c"%d\0A\00"
@.dblfmt = private constant [4 x i8] c"%f\0A\00"
@.strfmt = private constant [4 x i8] c"%s\0A\00"
@.ok = private constant [16 x i8] c"==== 03 ok ====\00"

declare i32 @printf(ptr, ...)
declare i32 @puts(ptr)

; ---- 结构体的构造：insertvalue 逐字段填充 ----
define %Point @make_point(i32 %x, double %y) {
entry:
  %p0 = insertvalue %Point undef, i32 %x, 0     ; 第 0 个字段（i32）
  %p1 = insertvalue %Point %p0, double %y, 1    ; 第 1 个字段（double）
  ret %Point %p1
}

; ---- 数组求和：getelementptr（GEP）寻址 ----
define i32 @sum_table() {
entry:
  %g0 = getelementptr [4 x i32], ptr @table, i64 0, i64 0   ; &table[0]
  %v0 = load i32, ptr %g0
  %g1 = getelementptr [4 x i32], ptr @table, i64 0, i64 1   ; &table[1]
  %v1 = load i32, ptr %g1
  %g2 = getelementptr [4 x i32], ptr @table, i64 0, i64 2   ; &table[2]
  %v2 = load i32, ptr %g2
  %g3 = getelementptr [4 x i32], ptr @table, i64 0, i64 3   ; &table[3]
  %v3 = load i32, ptr %g3
  %s01 = add i32 %v0, %v1
  %s23 = add i32 %v2, %v3
  %s = add i32 %s01, %s23
  ret i32 %s                                  ; 10+20+30+40 = 100
}

; ---- 读结构体字段：GEP 走到字段再 load ----
define double @point_y(ptr %p) {
entry:
  %f = getelementptr %Point, ptr %p, i32 0, i32 1   ; 第 1 个字段（double）
  %y = load double, ptr %f
  ret double %y
}

define i32 @bump() {
entry:
  %old = load i64, ptr @counter
  %new = add i64 %old, 1
  store i64 %new, ptr @counter
  %trunc = trunc i64 %new to i32
  ret i32 %trunc
}

define i32 @main() {
entry:
  ; 数组求和
  %s = call i32 @sum_table()
  %pf1 = call i32 (ptr, ...) @printf(ptr @.intfmt, i32 %s)        ; 100

  ; 结构体：构造 → 存到栈上 → 读字段
  %pt = call %Point @make_point(i32 7, double 2.5)
  %buf = alloca %Point                       ; 栈上开一块空间放结构体
  store %Point %pt, ptr %buf
  %y = call double @point_y(ptr %buf)
  %pf2 = call i32 (ptr, ...) @printf(ptr @.dblfmt, double %y)     ; 2.500000

  ; 全局可变状态 + 类型转换
  %c1 = call i32 @bump()
  %c2 = call i32 @bump()
  %csum = add i32 %c1, %c2
  %pf3 = call i32 (ptr, ...) @printf(ptr @.intfmt, i32 %csum)     ; 1+2 = 3

  ; 字符串就是 i8 数组
  %ps = call i32 (ptr, ...) @printf(ptr @.strfmt, ptr @name)      ; hello

  %pm = call i32 @puts(ptr @.ok)
  ret i32 0
}
