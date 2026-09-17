# 22 C 互操作：ccall/@ccall、类型映射、Cstring/指针、@cfunction 回调、跨平台库名
# 运行：julia --startup-file=no main.jl

# ═══ 22.1 类型映射表：Julia 类型 ↔ C 类型（ABI 层面等价）
# C 类型     Julia 类型        说明
# int        Cint (Int32)      固定宽度用 Cint/Cuint 等，别用 Int（平台相关）
# long long  Clonglong         Clong/Clonglong 在 Windows/Linux 宽度不同——别想当然
# double     Cdouble           float → Cfloat
# size_t     Csize_t
# char*      Cstring           只读字符串；char** → Ptr{Cstring}
# void*      Ptr{Cvoid}        泛指针；具体指针 Ptr{Cint} 等
# T*         Ptr{T}

# ═══ 22.2 ccall 三件套：函数名（库名, 符号）、返回类型、参数类型元组
libm = Sys.iswindows() ? "msvcrt" : "libm"     # 跨平台库名：Windows 用 msvcrt（系统自带）
n = ccall((:strlen, "msvcrt"), Csize_t, (Cstring,), "hello")
@assert n == 5
@assert ccall((:fabs, libm), Cdouble, (Cdouble,), -3.5) == 3.5
@assert ccall((:floor, libm), Cdouble, (Cdouble,), 2.7) == 2.0

# ═══ 22.3 @ccall 宏：把签名写成"内联 C 原型"（1.5+，可读性更好）
# 注意 1：宏会吞掉整条比较表达式——外层断言必须先给 @ccall 加括号
# 注意 2：形如 name::Cstring 的参数是"传变量值"——变量必须已定义，字面量则加括号写 ("..."::Cstring)
@assert (@ccall "msvcrt".strlen(("hello"::Cstring))::Csize_t) == 5
@assert (@ccall "msvcrt".atoi(("42"::Cstring))::Cint) == 42
n2 = @ccall "msvcrt".strlen("Julia 中文"::Cstring)::Csize_t   # UTF-8 字节数！
@assert n2 == sizeof("Julia 中文")
# 传参时类型注解 + 返回类型注解缺一不可

# ═══ 22.4 字符串与内存：Cstring 是"借用"不是拷贝——别把指针留下来
s = "临时字符串"
p = Base.unsafe_convert(Cstring, s)           # 指向 Julia 字符串内部字节
@assert ccall((:strlen, "msvcrt"), Csize_t, (Cstring,), p) == sizeof(s)
# 危险常识：C 侧返回的 char* 若指向 malloc 内存，须按 C 侧约定 free；
# Julia 字符串是 UTF-8、不可变——C 侧不得写入（写入 = 未定义行为）

# ═══ 22.5 Windows API：stdcall 不用声明（x64 只有一种调用约定）
if Sys.iswindows()
    pid = ccall((:GetCurrentProcessId, "kernel32"), Cuint, ())
    ticks = ccall((:GetTickCount, "kernel32"), Cuint, ())
    @assert pid > 0 && ticks > 0
    println("kernel32：pid = ", pid, "，开机毫秒 = ", ticks)
end

# ═══ 22.6 @cfunction：把 Julia 函数变成 C 函数指针（回调）
# qsort 的比较器：int (*)(const void*, const void*)——解引用后按数值比较
int_comparator(p1::Ptr{Cvoid}, p2::Ptr{Cvoid})::Cint = begin
    a = unsafe_load(Ptr{Cint}(p1)); b = unsafe_load(Ptr{Cint}(p2))
    a < b ? Cint(-1) : a > b ? Cint(1) : Cint(0)
end
function qsort_ints(v::Vector{Cint})
    cfunc = @cfunction(int_comparator, Cint, (Ptr{Cvoid}, Ptr{Cvoid}))
    ccall((:qsort, "msvcrt"), Cvoid,
          (Ptr{Cvoid}, Csize_t, Csize_t, Ptr{Cvoid}),
          v, length(v), sizeof(Cint), cfunc)
    v
end
sorted2 = qsort_ints(Cint[5, 3, 9, 1, 7])
@assert sorted2 == Cint[1, 3, 5, 7, 9]        # C 的 qsort 原地排序：Julia 数组零拷贝直通

# ═══ 22.7 指针与数组：unsafe_load / unsafe_store! / unsafe_wrap（危险但高效）
function Libc_malloc_ints()                   # C 侧 malloc 一块并填 7,8,9
    p = ccall((:malloc, "msvcrt"), Ptr{Cint}, (Csize_t,), 3 * sizeof(Cint))
    for i in 1:3
        unsafe_store!(p, i + 6, i)
    end
    p
end
v = Cint[10, 20, 30]
pv = pointer(v)
@assert unsafe_load(pv, 2) == 20              # 1 起下标！（C 指针上的 Julia 惯例）
buf = Libc_malloc_ints()
wrapped = unsafe_wrap(Array, buf, 3)          # 零拷贝包装 C 内存
@assert wrapped == [7, 8, 9]

println("strlen(\"hello\") = ", n, "；qsort = ", collect(sorted2), "；wrapped = ", wrapped)
println("==== 22 结束 ====")
