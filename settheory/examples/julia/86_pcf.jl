# 第 86 章 · 谢旯 pcf 理论（冯琦第二卷 §1.3）。
# 有限正则集合 A={3,5,7}：标尺、主超滤子、生成元与传递性。

println("==== 86")

const A = [3, 5, 7]

le_pw(f, g) = all(f[n] <= g[n] for n in A)
lt_pw(f, g) = le_pw(f, g) && any(f[n] < g[n] for n in A)

const scale0 = Dict(3 => 0, 5 => 0, 7 => 0)
const scale1 = Dict(3 => 1, 5 => 1, 7 => 1)
const scale2 = Dict(3 => 2, 5 => 2, 7 => 2)

principal(a, X) = a in X
generator(lam) = [x for x in A if x <= lam]

function generator_transitive(mu, lam)
    mu in generator(lam) || return false
    return all(x in generator(lam) for x in generator(mu))
end

function reduced_product_cf(sets)
    for a in A
        if all(a in X for X in sets)
            return a
        end
    end
    return nothing
end

@assert lt_pw(scale0, scale1)
@assert lt_pw(scale1, scale2)
@assert le_pw(scale0, scale2)

@assert principal(3, [3])
@assert reduced_product_cf([[3], [3, 5]]) == 3

@assert generator(3) == [3]
@assert generator(5) == [3, 5]
@assert generator(7) == [3, 5, 7]

for lam in A
    for mu in generator(lam)
        @assert generator_transitive(mu, lam)
    end
end

pcf_A = copy(A)
@assert pcf_A == A

println("scale length 3")
println("generators ", Dict(lam => generator(lam) for lam in A))
println("transitive ok")
println("pcf toy idempotent")
println("END ====")
