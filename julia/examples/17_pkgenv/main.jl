# 17 包与环境 ⭐：以本目录 env/（环境）+ MathTools/（本地包）为例
# 运行（两个入口自动加 --project=env）：
#   julia --project=env main.jl       # env/Manifest.toml 已随仓库入库，直接跑即可
#   julia --project=env runtests.jl
# 只有 Manifest 缺失（首次从零解析）时才需要 Pkg.instantiate()：
#   julia --project=env -e 'using Pkg; Pkg.instantiate()'
# 注意：Project.toml 里的路径一律写正斜杠 /（反斜杠是非法 TOML 转义）

# ═══ 17.1 当前活动环境：--project=env 激活了谁
using Pkg
println("活动项目：", basename(dirname(Base.active_project())))
println("LOAD_PATH = ", LOAD_PATH)              # 环境栈：@（活动环境）→ 基础环境 → Core

# ═══ 17.2 Pkg.status：环境里有什么
Pkg.status()

# ═══ 17.3 using 本地包：源码在 ../MathTools，改动即时生效（无需重新 add）
using MathTools                              # [sources] 路径依赖 = 开发模式
using Statistics                             # 标准库也在 [deps] 里声明（1.11+ 必须显式声明）

data = [2.0, 4.0, 4.0, 4.0, 5.0, 5.0, 7.0, 9.0]
println("数据 = ", data)
println("MathTools.average = ", average(data), "  vs  Statistics.mean = ", mean(data))
println("MathTools.variance = ", variance(data), "  vs  Statistics.var = ", var(data))
@assert average(data) == mean(data)
@assert variance(data) ≈ var(data)

# ═══ 17.4 包 API：滑动平均与 z 分数（与 Statistics 交叉验证）
println("movavg(data, 3) = ", movavg(data, 3))
println("zscore(data) 前两个 = ", round.(zscore(data)[1:2]; digits = 3))
@assert movavg(data, 3)[1] == (2 + 4 + 4) / 3
@assert isapprox(sum(zscore(data)), 0; atol = 1e-12)   # @assert 不认 ≈ atol= 语法，用 isapprox
@assert length(movavg(data, 4)) == length(data) - 3

# ═══ 17.5 依赖解析的确定性：Manifest.toml 锁版本
# env/Manifest.toml 由 Pkg.instantiate() 生成：记录每个依赖的精确版本与来源，
# 团队协作时提交它 → 人人装出同一套环境（App 提交、库不提交是社区惯例）
println("Manifest 存在：", isfile(joinpath(@__DIR__, "env", "Manifest.toml")))

println("==== 17 结束 ====")
