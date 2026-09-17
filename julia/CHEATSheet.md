# Julia 1.13 速查表

语法速查 + 1.13 坑位索引。详细讲解见对应章（表中 N.M = 第 N 章 M 节）。

## 1. 命令速查

```bash
julia                        # REPL（] pkg 模式；? 帮助；; shell）
julia script.jl args...      # 跑脚本（参数进 ARGS）
julia -e 'code'              # 一行代码
julia -t 4                   # 4 线程（默认 1！）
julia -t 4,1                 # 默认池 4 + 交互池 1
julia --project=env          # 激活环境
julia --startup-file=no      # 干净启动（教程默认）
julia --check-bounds=yes     # 强制边界检查（build.ps1 验证层）
julia --track-allocation=user  # 逐行分配统计
julia --code-coverage=user     # 行覆盖
julia --heap-size-hint=2G      # 内存上限提示 GC
```

## 2. 数值（03）

```julia
typemax(Int64) + 1            # 环绕不抛错
big"2" ^ 100                  # 任意精度
7 / 2 == 3.5                  # / 永远浮点
7 ÷ 2 == 3 && fld(-7, 2) == -4 && cld(7, 2) == 4
rem(-7, 2) == -1              # 与被除数同号
mod(-7, 2) == 1               # 与除数同号
1 // 3 + 1 // 6 == 1 // 2     # 有理数（// 不是注释！）
(1 + 2im) * (1 - 2im) == 5 + 0im
trunc(Int, 3.99) == 3         # Int(3.99) 抛 InexactError！
round(Int, 2.5) == 2          # ties to even
```

| 坑 | 解法 |
|---|---|
| `Int(3.99)` InexactError | 用 trunc/floor/ceil/round（03.5） |
| `typemax(Float64) == Inf` | 最大有限值 `floatmax`（03.2） |
| `//` 当注释 | 注释只有 `#`（03.1） |

## 3. 控制流与作用域（04）

```julia
parity = if cond "偶" else "奇" end      # if 是表达式
cond && action                           # 短路当控制流
for i in 1:2:9 ... end                   # start:step:stop
for (i, row) in enumerate(eachrow(m))    # 带下标
hasneg && return i                       # 双重循环跳出→抽函数（无 labeled break）
@label loop ... @goto loop               # 仅函数体内
```

| 坑 | 解法 |
|---|---|
| 顶层循环 `+=` 全局 → UndefVarError | 写进函数（soft scope，04.7） |
| `@goto` 在顶层 | 只能函数体内（04.5） |

## 4. 函数（05）

```julia
f(a; kw = 默认) = ...             # 分号后是关键字参数
g(x, y = 2) = ...                 # 位置默认值
h(args...) = sum(args; init = 0)  # 变长 + 空 reduce 必须 init
map(x -> x^2, v)  /  reduce(+, v)
1:10 |> sum |> sqrt               # 管道
f = exp ∘ log                      # 复合（\circ）
open(path, "w") do io ... end     # do 块自动 close；do 把函数插到第一参数位
sort(v; by = length, lt = (a,b) -> a < b)   # sort 不吃 do 块！
```

## 5. 派发与类型（06/07/08）

```julia
f(x::Integer, y::Integer) = ...   # 按全部实参选方法
which(f, (Int, Int))  /  methods(f)  /  @which f(1)
Base.:+(a::T, b::T) = ...         # 扩展 Base
Base.show(io::IO, x::T) = print(io, "...")

Int <: Integer <: Real <: Number <: Any
Bool <: Integer                   # ！
Union{Int, Float64}; Union{}; typejoin/promote_type/typeintersect
missing == 1 === missing          # 传染！判等 isequal、判缺 ismissing
sort([2, missing, 1])             # missing 排最后
Vector{Int} <: Vector{Integer}    # false！协变写 Vector{<:Integer}

struct P; x::Float64; end         # 不可变（isbits 值语义）
mutable struct C; n::Int; end     # 身份语义（== 默认 ===）
Base.@kwdef struct S; port = 8080; end
struct Box{T}; v::T; end          # 参数化（不变）
```

## 6. 数组与广播（09/10）

```julia
[1 2; 3 4]                    # 空格并排、分号换行；列主序
a[[1,3]] / a[a .> 6]          # 花式 / 掩码
@view m[:, 1]                 # 视图（切片默认拷贝）
push!/pop!/append!/deleteat!  # ! = 就地
A * b  /  A \ b               # 矩阵乘 / 解方程（\ 优先于 inv）
sqrt.(v)  /  v .+ 1           # 广播
@. sqrt(w) + 1                # 整条加点（比较要留在括号外！）
y .= x .* 2                   # 就地零分配
[1,2] .+ [10 20]              # 维度扩展：向量对齐第一维（与 NumPy 相反！）
Base.broadcastable(x::T) = Ref(x)   # 自定义标量参与广播
```

## 7. 集合与字符串（11/12）

```julia
get(d, k, 默认) / get!(d, k, 默认) / pop!(d, k) / merge(d1, d2)
sort(xs; by =, lt =, rev =) / sort! / sortperm / partialsort
[x^2 for x in 1:5]            # comprehension
[x for x in v if cond]        # 过滤
sum(x^2 for x in 1:n)         # generator 零分配
split/join/strip/lpad/replace/occursin
match(r"(\w+)@(\w+)", s).captures
@sprintf("%.3f", x)           # using Printf
```

| 坑 | 解法 |
|---|---|
| `$var` + 全角标点/`!` | 统一 `$(var)`（02.4） |
| Dict 顺序不保证 | `sort(collect(keys(d)))`（11.2） |
| `"a" + "b"` | 拼接是 `*`（12.2） |
| 多字节下标 StringIndexError | 用迭代，别用字节下标猜（12.1） |

## 8. 异常（13）

```julia
throw(ArgumentError("...")) / error("...")
try ... catch e ... finally ... end
e isa Target || rethrow()
stacktrace(Base.current_exceptions()[end][2])   # 抛错点栈（1.13）
DomainError/InexactError/BoundsError/MethodError/KeyError/DivideError
```

## 9. 元编程（14）

```julia
ex = :(1 + 2 * 3)            # Expr(head, args...)
macro m(ex); :($ex + $ex); end
$(esc(x))                    # 调用者的表达式要 esc（卫生）
@m a b                       # 多参空格分隔（逗号版传元组！）
Base.invokelatest(f)         # 世界年龄桥接（@eval 新定义）
```

## 10. 性能（16）

```julia
Base.return_types(f, (T,))   # [Float64] 稳 / [Union{...}] 不稳
const G = 100                # 全局必须 const（否则 130× 慢）
@elapsed / @allocated        # 计时/计配额（先预热！）
@inbounds @simd for ...       # 先写对再加速
@views m[:, j]               # 大切片零拷贝
具体类型容器：Float64[] ✅   Real[] ❌（装箱）
```

## 11. Pkg 与测试（17/18）

```text
pkg> activate env / add Pkg / status / instantiate / dev path / test Pkg
```

```toml
[sources]
MyPkg = { path = "../MyPkg" }   # 路径依赖写进 Project.toml（用 / 不用 \）
```

```julia
@testset "名" begin @test x ≈ y atol=1e-12 end
@test_throws DomainError f()   # 顶层失败 → exit 1
@test_broken / @test_skip / @test_nowarn / @test_logs
Random.seed!(42)               # 可复现
```

## 12. 并发（20/21）

```julia
t = @async work()             # 协作任务（单线程）
fetch(t)                      # 取结果（失败抛 TaskFailedException，原始在 .task.exception）
ch = Channel{Int}(4)          # 缓冲通道
put!(ch, x) / take!(ch) / close(ch)
for x in Channel(producer)    # 生产者通道可直接迭代
Threads.@threads for ...      # 需 -t N
Threads.@spawn f(x)           # 任务级并行（数组推导里加括号！）
Threads.Atomic{Int}(0) / atomic_add!
lock(ReentrantLock()) do ... end   # Base.lock 的 do 形式
分块聚合 > 锁 > 原子           # 性能排序
```

## 13. C 互操作（22）

```julia
ccall((:strlen, "msvcrt"), Csize_t, (Cstring,), "hello")
@ccall "msvcrt".strlen(("hello"::Cstring))::Csize_t   # 断言里加括号！
@cfunction(f, Cint, (Ptr{Cvoid}, Ptr{Cvoid}))          # 回调
unsafe_load(p, 1)   # 1 起下标；unsafe_wrap(Array, p, n)
Cint/Cdouble/Csize_t/Ptr{T}/Cstring                     # 映射表
```

## 14. 调试（23）

```julia
stacktrace(Base.current_exceptions()[end][2])   # 1.13 抛错点栈（catch_stacktrace 已删）
sprint(showerror, e)  /  @show x  /  Base.@locals
using Profile; @profile f(); Profile.fetch()
using InteractiveUtils  # @code_warntype 脚本模式必须显式！
```

生态：BenchmarkTools(@btime)、JET、Debugger、Infiltrator、Cthulhu、Aqua、Documenter、Revise。
