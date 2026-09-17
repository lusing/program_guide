# 16 性能 ⭐：全局变量之恶、类型稳定性、@code_warntype、计时计配额、@inbounds/@simd、视图
# 运行：julia --startup-file=no main.jl

# ═══ 16.1 @time 三段论：编译 + 执行；预热的正义
using InteractiveUtils                      # 脚本模式必须显式引入（REPL 才自动加载）——1.13 实测坑
function work(n)
    s = 0.0
    for i in 1:n
        s += sin(i)
    end
    s
end
@time work(100_000)                         # 第一次：编译 + 运行（时间主要是编译）
@time work(100_000)                         # 第二次：纯运行——这才是要比较的数字
@assert abs(work(10) - sum(sin, 1:10)) < 1e-12

# ═══ 16.2 类型稳定性：函数返回类型只由实参类型决定（与值无关）
stable(x::Float64) = x > 0 ? x : 0.0        # 两个分支同类型 → 返回 Float64
unstable(x::Float64) = x > 0 ? x : 0        # 分支类型不同 → 返回 Union{Float64, Int64}
@assert stable(1.0) == 1.0 && unstable(-1.0) == 0
# 用 code_typed 看编译器推断的返回类型（@code_warntype 在 REPL 高亮黄色警示）
rt_stable = Base.return_types(stable, (Float64,))
rt_unstable = Base.return_types(unstable, (Float64,))
@assert rt_stable == [Float64]                     # 干净的单一类型
@assert rt_unstable == [Union{Float64, Int64}]     # Union = 调用方要处理两种可能 → 慢
# 修复：统一分支类型
fixed_unstable(x::Float64) = x > 0 ? x : 0.0
@assert Base.return_types(fixed_unstable, (Float64,)) == [Float64]

# ═══ 16.3 全局变量：性能第一杀手（动态类型 = 每次访问都查类型）
global G = 100                                # 非 const 全局：函数里用它 = 动态查找
sum_global(n) = (s = 0.0; for i in 1:n; s += i + G; end; s)
const CONST_G = 100                           # const 全局：类型与值编译期锁定
sum_const(n) = (s = 0.0; for i in 1:n; s += i + CONST_G; end; s)
@assert sum_global(10) == sum_const(10)       # 结果一样
# 推断对比：全局版返回类型也可能不稳，const 版干净
@assert Base.return_types(sum_const, (Int,)) == [Float64]
@time sum_global(100_000)
@time sum_const(100_000)
# 结论：全局要么 const，要么当参数传进函数

# ═══ 16.4 计时与计配额：@elapsed / @allocated / BenchmarkTools
t1 = @elapsed work(1_000_000)                 # @elapsed 返回秒数
@assert t1 >= 0                               # 值不保证（机器负载），只演示用法
alloc_bad() = sum([i^2 for i in 1:1000])      # 中间数组
alloc_good() = sum(i^2 for i in 1:1000)       # generator：零中间数组
@assert alloc_bad() == alloc_good()
alloc_bad(); alloc_good()                     # 预热：把编译的分配排除在测量外
bytes_bad = @allocated alloc_bad()
bytes_good = @allocated alloc_good()
@assert bytes_bad > 0 && bytes_good == 0      # 这是确定性断言：generator 不分配
println("alloc 对比：comprehension $(bytes_bad) B vs generator $(bytes_good) B")
# 精确基准测试用 BenchmarkTools.@btime（第三方包，17 章装）；粗测 @elapsed 够用

# ═══ 16.5 @inbounds 与 @simd：消除安全检查（先写对，再加速）
function sum_inbounds(xs)
    s = 0.0
    @inbounds @simd for i in eachindex(xs)    # 越界检查关闭 + SIMD 向量化
        s += xs[i]
    end
    s
end
xs = rand(100_000)
@assert isapprox(sum_inbounds(xs), sum(xs); rtol = 1e-10)   # 结果必须仍对！
# build.ps1 的运行层带 --check-bounds=yes：@inbounds 也被强制恢复检查——安全网验证

# ═══ 16.6 视图 vs 拷贝：切片大数组时省一大笔
big = rand(1000, 1000)
function colsums_copy(m)                      # 每次切片都拷一整列
    s = 0.0
    for j in 1:size(m, 2)
        s += sum(m[:, j])
    end
    s
end
function colsums_view(m)                      # @views：零拷贝
    s = 0.0
    @views for j in 1:size(m, 2)
        s += sum(m[:, j])
    end
    s
end
@assert isapprox(colsums_copy(big), colsums_view(big))
println("colsums：copy 与 @views 结果一致 = ", isapprox(colsums_copy(big), colsums_view(big)))

# ═══ 16.7 类型稳定性实战：容器别装 Any
v_any = Any[1, 2.5, 3]                        # 元素类型 Any：每次取用都动态
v_real = Real[1, 2.5, 3]                      # 抽象元素类型：同样要动态派发
v_f = [1.0, 2.5, 3.0]                         # 具体元素类型：编译器全速
@assert sum(v_any) == sum(v_real) == sum(v_f)
@assert eltype(v_f) == Float64 && isconcretetype(eltype(v_f))
# convert 或 push! 前规划好元素类型；异构数据考虑 struct + Union 或分列存

println("rt_unstable = ", rt_unstable, "；sum_inbounds 正确 = ", isapprox(sum_inbounds(xs), sum(xs); rtol = 1e-10))
println("==== 16 结束 ====")
