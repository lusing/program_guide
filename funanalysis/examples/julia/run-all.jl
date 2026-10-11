# 泛函分析教程 · Julia 数值通道全量运行器
# 用法：julia --project=. run-all.jl        （在 examples/julia/ 下）
# 判定：每个 NN_*.jl 以 `==== NN ... END ====` 结束、中途 @assert 不爆即绿。

const here = @__DIR__()
const files = sort(filter(f -> occursin(r"^\d\d_.*\.jl$", f) && f != "run-all.jl",
    readdir(here)))

println(">>> 运行 ", length(files), " 个 Julia 示例：", join(files, ", "))

for f in files
    println()
    println("### INCLUDE ", f, " ###")
    include(joinpath(here, f))
end

println()
println(">>> 全部 Julia 示例运行完毕。")
