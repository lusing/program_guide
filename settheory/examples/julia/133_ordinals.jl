# 第 133 章 Julia：ω^ω 窗口内的序数形态。
# 表示：序数 = 系数向量 [c0, c1, ..., ck]（低位在前），
#   α = c0 + c1·ω + ... + ck·ω^k（康托正则形式 4.4.14 的窗口版）。
# ① 规范形与比较（右字典序——高位优先）；
# ② 后继 = c0 加一；
# ③ sup/inf（书 4.2.8：sup = ⋃ 取最大、inf = ⋂ 取最小）；
# ④ 样本审计：α < α+1 跨有穷/极限序数；自然数恰是有穷序数。
println("==== 133 ordinals")

function canon(v)
    i = findlast(!=(0), v)
    i === nothing ? Int[] : v[1:i]     # [0] 规范化为空向量（序数 0）
end

function olt(a, b)
    a, b = canon(a), canon(b)
    n = max(length(a), length(b))
    a = vcat(a, zeros(Int, n - length(a)))
    b = vcat(b, zeros(Int, n - length(b)))
    for k in n:-1:1
        a[k] != b[k] && return a[k] < b[k]
    end
    false
end

function osucc(a)
    a = canon(a)
    isempty(a) && return [1]
    a[1] += 1
    a
end

w = [0, 1]            # ω = 第一个极限序数
w1 = [1, 1]           # ω + 1
w2 = [0, 2]           # ω·2
w2p3 = [3, 2]         # ω·2 + 3
w_sq = [0, 0, 1]      # ω²

@assert olt([5], w)                          # 5 < ω
@assert olt(w, w1)                           # ω < ω+1
@assert olt(w, w2)                           # ω < ω·2
@assert olt(w1, w2)                          # ω+1 < ω·2
@assert olt(w_sq, [1, 0, 1])                 # ω² < ω²+1
@assert !olt(w, w) && !olt(w1, w)            # 反对称的样本
println("order: 5 < w < w+1 < w*2 < w^2 (right-lex on CNF): OK")

osup(list) = reduce((x, y) -> olt(x, y) ? y : x, list)
oinf(list) = reduce((x, y) -> olt(x, y) ? x : y, list)
@assert osup([[5], w, w1]) == w1             # sup{5, ω, ω+1} = ω+1
@assert oinf([w2p3, w2]) == w2               # inf{ω·2+3, ω·2} = ω·2（取小）
@assert osup([w, w_sq, w1]) == w_sq
println("sup/inf: union=max, intersection=min on samples: OK")

samples = [[1], [3], w, w1, w2, w_sq, [1, 2, 1]]
for a in samples
    @assert olt(a, osucc(a))                 # α < α+1（超穷归纳可证命题的审计）
end
println("successor: alpha < alpha+1 across finite/limit samples: OK")

@assert all(olt([n], w) for n in 0:100)      # 每个自然数 < ω
@assert !olt(w, [10^6])
println("finite ordinals: every n < w, w is the first limit: OK")
println("END ====")
