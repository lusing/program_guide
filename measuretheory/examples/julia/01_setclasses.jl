println("==== 01 setclasses")

# 第 01 章：有限宇宙上的集类封闭性枚举实验。
# Ω = {1..6}，集类用子集的位掩码表示（UInt8）。

const Ω_N = 6
const FULL = UInt8(0b111111)

# 位掩码 <-> 区间集合（有限 Ω 上 (a..b] 型，a<b，端点 0..6）
function mask_interval(a, b)
    r = UInt8(0)
    for i in a+1:b
        r |= UInt8(2^(i-1))
    end
    r
end

# 区间半环 C = {∅} ∪ {(a,b] : 0≤a<b≤6}
intervals = UInt8[0]
for a in 0:Ω_N-1, b in a+1:Ω_N
    push!(intervals, mask_interval(a, b))
end
unique!(sort!(intervals))

inter(s::UInt8, t::UInt8) = s & t
union_(s::UInt8, t::UInt8) = s | t
diff(s::UInt8, t::UInt8) = s & ~t & FULL

inC(s) = s ∈ intervals

# --- 验证 1：区间族对交封闭（π-系）---
ok_pi = all(inC(inter(s, t)) for s in intervals, t in intervals)
@assert ok_pi "区间族应对交封闭"
println("区间族对交封闭（π-系）: OK，共 $(length(intervals)) 个成员")

# --- 验证 2：半环条件——差 = 有限不交并（区间最多裂成两片）---
function diff_decomposes(s::UInt8, t::UInt8)
    d = diff(s, t)
    d == UInt8(0) && return true
    # 枚举 C 中两两不交区间的不超过 2 元组拼 d
    for u in intervals, v in intervals
        (u & v == 0 && (u | v) == d) && return true
    end
    false
end
ok_semiring = all(diff_decomposes(s, t) for s in intervals, t in intervals if s != 0)
@assert ok_semiring "区间族的差应可分解为不交区间并"
println("半环条件（差≤2 片不交区间）: OK")

# --- 验证 3：不是环——{1,2} ∪ {4,5} 不是区间 ---
s = mask_interval(0, 2)   # {1,2}
t = mask_interval(3, 5)   # {4,5}
@assert !inC(union_(s, t)) "两个不交区间的并不是区间——半环不是环"
println("反例：{1,2} ∪ {4,5} ∉ C —— 区间半环不是环")

# --- 验证 4：闭包迭代——C_uf（有限不交并封闭）几步到不动点 ---
function closure_disjoint_union(C)
    S = Set(C)
    changed = true
    steps = 0
    while changed
        changed = false
        steps += 1
        for u in collect(S), v in collect(S)
            if (u & v) == 0 && !((u | v) ∈ S)
                push!(S, u | v)
                changed = true
            end
        end
    end
    S, steps
end
S1, steps1 = closure_disjoint_union(intervals)
println("C_uf 闭包：$(length(intervals)) → $(length(S1)) 个成员，$(steps1) 轮迭代到不动点")
@assert length(S1) == 2^Ω_N "有限 Ω 上区间的不交并闭包应穷尽全部子集（每个子集都是不交区间拼图）"

# --- 验证 5：对一般并封闭（环）需要更多步骤——先做 ∪ 闭包再对照 ---
function closure_union(C)
    S = Set(C)
    changed = true
    steps = 0
    while changed
        changed = false
        steps += 1
        for u in collect(S), v in collect(S)
            if !((u | v) ∈ S)
                push!(S, u | v)
                changed = true
            end
        end
    end
    S, steps
end
S2, steps2 = closure_union(intervals)
@assert S1 == S2 "同一生成系的不交并闭包与并闭包应一致（差可由交与补表出）"
println("∪ 闭包同样 $(length(S2)) 个成员（两闭包一致: OK）")

println("END ====")
