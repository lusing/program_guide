# 第 67 章：传递集合与形式理论（冯琦 引言+§1.1-1.2）
# 量词交错的语义翻转 + 康托尔对角线有限预演 + 有序对 + 同一律。
println("==== 67")

# ---------- 一、量词交错：交换会翻车（1.1.1 末尾） ----------
U = 1:6
le = (x, y) -> x < y
forallx_existy = all(x -> any(y -> le(x, y), U), U)   # ∀x∃y(x<y)：总有更大的
existsy_allx = any(y -> all(x -> le(x, y), U), U)     # ∃y∀x(x<y)：有最大元
println("∀x∃y(x<y) = ", forallx_existy, "    ∃y∀x(x<y) = ", existsy_allx)

# 欧几里得式（有界版）：素数无穷的两种读法
isprime(n) = n >= 2 && all(d -> n % d != 0, 2:isqrt(n))
euclid = all(n -> any(p -> p > n && isprime(p), 2:100), 1:50)
swapped = any(p -> all(n -> p > n, 1:50) && isprime(p), 2:100)
println("∀n∃p>n 素数 = ", euclid, "    ∃p∀n(p>n) 素数 = ", swapped)

# ---------- 二、康托尔对角线（定理 1.4 有限预演） ----------
# 任何 f : {1..6} → 幂集，对角集 D = {a | a ∉ f(a)} 总不在像里
cantor_diag(f) = begin
    n = 6
    F = [f(i) for i in 1:n]
    D = Bool[!F[i][i] for i in 1:n]           # D 的特征向量
    !any(i -> F[i] == D, 1:n)
end
f1 = i -> Bool[j == i for j in 1:6]            # a ↦ {a}
f2 = i -> Bool[j != i for j in 1:6]            # a ↦ 补单点
f3 = i -> Bool[(i + j) % 2 == 0 for j in 1:6]  # 奇偶格
println("对角集在三个映射的像中缺席：", cantor_diag(f1) && cantor_diag(f2) && cantor_diag(f3))

# ---------- 三、有序对（库拉托夫斯基，定理 1.2） ----------
pair(a, b) = [[a], [a, b]]                     # (a,b) = {{a},{a,b}}
first(z) = z[1][1]
second(z) = length(z[2]) == 1 ? z[2][1] : z[2][2]
ok = true
for a in 1:3, b in 1:3, u in 1:3, v in 1:3
    eq = pair(a, b) == pair(u, v)
    want = (a == u) && (b == v)
    ok &= (eq == want)
end
println("(a,b)=(u,v) ⟺ a=u ∧ b=v（81 组全检）：", ok,
        "   投影 (1,2)₀=$(first(pair(1,2))) (1,2)₁=$(second(pair(1,2)))")

# ---------- 四、同一律（命题 1.1）：相等 ⟺ 双包含 ----------
using Random
Random.seed!(67)
issub(A, B) = issubset(A, B)
ok2 = true
for _ in 1:200
    A = Set(rand(1:10, 3)); B = Set(rand(1:10, 3))
    ok2 &= ((A == B) == (issub(A, B) && issub(B, A)))
end
println("随机集合 200 次：A==B ⟺ A⊆B ∧ B⊆A：", ok2)

println("END ====")
