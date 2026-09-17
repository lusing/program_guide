# 22 · C 互操作

> 对应示例：`examples/22_ccall/`
>
> Julia 与 C 的边界几乎透明：`ccall` 是语言内置，不用绑定生成器起步。

## 22.1 类型映射表

| C 类型 | Julia 类型 | 说明 |
|---|---|---|
| `int` | `Cint`（Int32） | **固定宽度用 Cint/Cuint/Clonglong**；`Int` 平台相关别想当然 |
| `long long` | `Clonglong` | `Clong` 在 Win/Linux 宽度不同 |
| `double` / `float` | `Cdouble` / `Cfloat` | |
| `size_t` | `Csize_t` | |
| `char*`（只读） | `Cstring` | 字符串借用（UTF-8 直通） |
| `char**` | `Ptr{Cstring}` | |
| `void*` | `Ptr{Cvoid}` | 泛指针 |
| `T*` | `Ptr{T}` | 数组零拷贝互认 |

## 22.2 ccall：三件套

```julia
ccall((:strlen, "msvcrt"), Csize_t, (Cstring,), "hello")   # (符号, 库名), 返回类型, 参数类型元组, 实参
ccall((:fabs, "msvcrt"), Cdouble, (Cdouble,), -3.5)         # 3.5
```

库按名字加载（Windows 的 msvcrt/ucrtbase、Linux 的 libm/libc）——**跨平台库名分支**：

```julia
libm = Sys.iswindows() ? "msvcrt" : "libm"
ccall((:floor, libm), Cdouble, (Cdouble,), 2.7)    # 2.0
```

## 22.3 @ccall：内联 C 原型（1.5+）

```julia
@ccall "msvcrt".strlen(("hello"::Cstring))::Csize_t    # 参数名::类型，返回 ::类型
@ccall "msvcrt".atoi(("42"::Cstring))::Cint            # 42
```

三条实测规则：

1. **宏吞整条表达式**：`@assert (@ccall ...) == 5` 必须给 @ccall 加括号，否则 `== 5` 被当签名一部分报 "needs a return type"；
2. **`name::T` 传的是变量值**：变量必须已定义；字面量写 `("hello"::Cstring)`；
3. 返回类型注解 `::T` 缺一不可。

## 22.4 Windows API：x64 无需 stdcall

```julia
pid = ccall((:GetCurrentProcessId, "kernel32"), Cuint, ())
ticks = ccall((:GetTickCount, "kernel32"), Cuint, ())
```

32 位时代要声明的 `stdcall` 在 x64 只有一种调用约定——直接调。C++ 的名字粉碎（name mangling）绕不开：要么 C 接口（`extern "C"`），要么按粉碎名调用。

## 22.5 @cfunction：Julia 函数 → C 函数指针

```julia
# qsort 的比较器：int (*)(const void*, const void*)
int_comparator(p1::Ptr{Cvoid}, p2::Ptr{Cvoid})::Cint = begin
    a = unsafe_load(Ptr{Cint}(p1)); b = unsafe_load(Ptr{Cint}(p2))
    a < b ? Cint(-1) : a > b ? Cint(1) : Cint(0)
end

function qsort_ints(v::Vector{Cint})
    cfunc = @cfunction(int_comparator, Cint, (Ptr{Cvoid}, Ptr{Cvoid}))   # (函数, 返回类型, 参数类型)
    ccall((:qsort, "msvcrt"), Cvoid,
          (Ptr{Cvoid}, Csize_t, Csize_t, Ptr{Cvoid}),
          v, length(v), sizeof(Cint), cfunc)
    v
end
qsort_ints(Cint[5, 3, 9, 1, 7])    # Cint[1, 3, 5, 7, 9]——原地排序
```

C 的 qsort 直接排 Julia 数组内存——**零拷贝直通**。回调里的 Julia 代码由 GC 世界托管，`@cfunction` 保持引用防止被回收。

## 22.6 指针三招：unsafe_load / unsafe_store! / unsafe_wrap

```julia
v = Cint[10, 20, 30]
pv = pointer(v)
unsafe_load(pv, 2)          # 20——注意 1 起下标（C 指针上的 Julia 惯例）
unsafe_store!(pv, 99, 3)    # 写指针即写数组（同一内存）

# C 侧 malloc 的内存包装成 Julia 数组（零拷贝；生命周期契约人工保证）
p = ccall((:malloc, "msvcrt"), Ptr{Cint}, (Csize_t,), 3 * sizeof(Cint))
unsafe_store!(p, 7, 1); unsafe_store!(p, 8, 2); unsafe_store!(p, 9, 3)
wrapped = unsafe_wrap(Array, p, 3)      # [7, 8, 9]
```

`unsafe_` 前缀是诚实标注：**越界、悬垂、GC 移动**都在你手上。规则：C 返回的 `char*` 若指向 malloc 内存须按 C 约定 free；Julia 字符串不可变——C 侧写入 = 未定义行为。

## 22.7 何时用 C 互操作

- 现成 C 库（BLAS、SQLite、系统 API）——直接 ccall；
- 热点内核手写 C/SIMD——`@ccall` 回调进 C 循环；
- Fortran 遗产——同样 ccall（注意 Fortran 按引用传参：`Ref{T}`）；
- 更高层：Python 用 PythonCall.jl、R 用 RCall.jl——生态互认。

## 22.8 坑位清单

1. **@ccall 吞比较表达式**：外层断言先加括号（22.3 实测）；`name::T` 传变量值，未定义变量直接 UndefVarError。
2. **别裸用 `Int` 对 `long`**：Windows long 是 32 位——固定宽度走 Cint/Clonglong 家族（22.1）。
3. **`unsafe_load` 是 1 起下标**：C 的 `ptr[0]` 在 Julia 是 `unsafe_load(p, 1)`（22.6）。
4. **unsafe_wrap 的生命周期**：包装的 C 内存 GC 不管——谁 malloc 谁 free，或 `finalizer` 兜底（22.6）。
5. **回调必须保活**：`@cfunction` 结果在 C 侧使用期间，Julia 侧要有引用（局部变量即可），否则回调被回收（22.5）。
