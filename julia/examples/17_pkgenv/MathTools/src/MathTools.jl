module MathTools

export average, variance, movavg, zscore

"""算术平均（手动实现，零依赖）"""
average(v::AbstractVector{<:Real}) = sum(v) / length(v)

"""样本方差（corrected=true 用 n-1，即统计学无偏估计）"""
function variance(v::AbstractVector{<:Real}; corrected::Bool = true)
    m = average(v)
    s = sum((x - m)^2 for x in v)
    d = corrected ? length(v) - 1 : length(v)
    s / d
end

"""滑动窗口平均：窗口 k 从左向右滑动，返回 length(v)-k+1 个值"""
function movavg(v::AbstractVector{<:Real}, k::Integer)
    k > 0 || throw(ArgumentError("窗口必须为正"))
    length(v) >= k || throw(ArgumentError("数据长度须不小于窗口"))
    ki = Int(k)
    [sum(v[i-ki+1:i]) / ki for i in ki:length(v)]
end

"""z 分数标准化：(x - 均值) / 样本标准差"""
function zscore(v::AbstractVector{<:Real})
    sd = sqrt(variance(v))
    sd > 0 || throw(ArgumentError("常数序列无法标准化"))
    [(x - average(v)) / sd for x in v]
end

end # module
