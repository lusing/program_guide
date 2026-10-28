# 第 94 章：有限超滤穷举与主超幂退化（位掩码实现）。
println("==== 94")

function subsets(n)
    return [[((mask >> (i-1)) & 1) == 1 for i in 1:n]
            for mask in 0:(2^n-1)]
end

function is_ultrafilter(family, ss, n)
    empty = first(ss)
    full = last(ss)
    empty ∉ family || return false
    full ∈ family || return false
    for a in family, b in family
        (a .& b) ∈ family || return false
    end
    for a in family, b in ss
        all(.!a .| b) || continue
        b ∈ family || return false
    end
    for a in ss
        (a ∈ family || .!a ∈ family) || return false
    end
    return true
end

function ultrafilters(n)
    ss = subsets(n)
    result = Vector{Vector{Vector{Bool}}}()
    for mask in 0:(2^length(ss)-1)
        family = [ss[i] for i in eachindex(ss) if ((mask >> (i-1)) & 1) == 1]
        is_ultrafilter(family, ss, n) && push!(result, family)
    end
    return result
end

for n in (2, 3)
    ufs = ultrafilters(n)
    ss = subsets(n)
    @assert length(ufs) == n
    for focus in 1:n
        principal = [s for s in ss if s[focus]]
        @assert length(principal) == 2^(n-1)
        @assert principal ∈ ufs
    end
end

# 坐标 2 的主超幂：一致类由函数在坐标 2 的值唯一决定。
functions = [[x, y, z] for x in (false,true) for y in (false,true) for z in (false,true)]
classes = Dict{Bool,Vector{Vector{Bool}}}()
for f in functions
    push!(get!(classes, f[2], Vector{Vector{Bool}}()), f)
end
@assert length(classes) == 2 && all(length(v) == 4 for v in values(classes))
@assert all(all(f[2] == value for f in fs) for (value,fs) in classes)
println("Julia：2/3 元素集的有限超滤数恰为 2/3，全部为主超滤")
println("主超幂：8 个二值函数按焦点值分成 2 类，每类 4 个代表 ✓")
println("END ====")
