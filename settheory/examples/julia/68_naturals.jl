# 第 68 章：自然数与第一递归定义定理（冯琦 §1.3）
# 递归三段式（有限近似+和谐+取并）；鸽子笼枚举；雪崩映射名次表。
println("==== 68")

# ---------- 一、定理 1.12 三段式：有限近似 + 和谐系统 + 取并 ----------

# 引理 1.2：长度 m+1 的有限近似 f: {0..m} → A
approx(m; a, g) = begin
    f = [a]                        # f(0) = a
    for n in 0:m-1
        push!(f, g(f[end], n))     # f(n+1) = g(f(n), n)
    end
    f
end

# 引理 1.3：近似两两和谐（公共定义域上一致）
harmonious(fs) = begin
    n = length(fs)
    all(1:n) do i
        all(i+1:n) do j
            fi, fj = fs[i], fs[j]
            all(fi[k] == fj[k] for k in 1:min(length(fi), length(fj)))
        end
    end
end

g_step = (x, n) -> x * (n + 2)     # 例：f(n) = (n+1)!
fs = [approx(m; a = 1, g = g_step) for m in 0:6]
println("近似序列长度: ", [length(f) for f in fs],
        "   两两和谐（引理 1.3）: ", harmonious(fs))
println("取并后的整体函数 f(0..6) = ", approx(6; a = 1, g = g_step),
        "   （= (n+1)! 逐项）")

# ---------- 二、鸽子笼（定理 1.10 枚举验证） ----------
maps(n, m) = Iterators.product(ntuple(_ -> 0:m-1, n)...)
is_inj(v) = length(unique(collect(v))) == length(collect(v))
is_surj3(v) = issetequal(collect(v), 0:2)
inj33 = [v for v in maps(3, 3) if is_inj(v)]
inj43 = [v for v in maps(4, 3) if is_inj(v)]
println("3→3 单射数 = ", length(inj33), "，且全部满射 = ",
        all(is_surj3, inj33), "（定理 1.10 前半）")
println("4→3 单射数 = ", length(inj43), "（定理 1.10 后半：恒为 0）")

# ---------- 三、雪崩映射（定理 1.11）：名次 = 此前 X 的元素个数 ----------
rankin(X, k) = count(<(k), X)
isprime(n) = n >= 2 && all(d -> n % d != 0, 2:isqrt(n))
primes = filter(isprime, 2:100)
Xs = Dict("偶数集" => collect(2:2:20),
          "素数集(前8)" => primes[1:8],
          "平方数集" => [i * i for i in 1:8])
for (name, X) in Xs
    head = X[1:min(5, end)]
    list = [rankin(X, k) for k in X[1:min(8, end)]]
    println("X = ", name, head, "…  自然列表 = ", list)
end
X = collect(2:2:40)
@assert all(rankin(X, X[i]) < rankin(X, X[j])
            for i in 1:length(X) for j in i+1:length(X))
@assert rankin(X, 40) == 19   # 2..38 共 19 个偶数小于 40
println("名次函数严格保序且满到 20：π_X 是 ∈-同构（定理 1.11）✓")

println("END ====")
