# 第 67 章：传递集合与形式理论（冯琦 引言+§1.1-1.2）
# 量词交错的语义翻转 + 康托尔对角线有限预演 + 有序对 + 同一律。
using Random
println("==== 67")

# ---------- 一、量词交错：交换会翻车（1.1.1 末尾） ----------
# P(x,y) = (x ≠ y)："每个人都能找到别人"真，"存在一个不是任何人的旁观者"假
quant_swap() = begin
    D = 1:3
    ne = (x, y) -> x != y
    fa = all(x -> any(y -> ne(x, y), D), D)
    af = any(y -> all(x -> ne(x, y), D), D)
    println("∀x∃y(x≠y) = ", fa, "    ∃y∀x(x≠y) = ", af)
end
quant_swap()

# 欧几里得式：素数"任意大"的两种读法
isprime(n) = n >= 2 && all(d -> n % d != 0, 2:isqrt(n))
euclid_frame() = begin
    bounded = all(n -> any(p -> isprime(p) && p > n, 2:50), 1:40)
    # "比所有自然都大的素数"：对每个素数 p，取 n := p 即可反驳（见证自己）
    self_refute = all(p -> !(p > p), filter(isprime, 2:100))
    println("有界版 ∀n∃p>n 素数 = ", bounded,
            "    ∃p∀n(p>n) 素数 = ", !self_refute ? "假" : "真")
end
euclid_frame()

# ---------- 二、康托尔对角线（定理 1.4 有限预演） ----------
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
pair_check() = begin
    ok = true
    for a in 1:3, b in 1:3, u in 1:3, v in 1:3
        ok &= (pair(a, b) == pair(u, v)) == ((a == u) && (b == v))
    end
    ok
end
println("(a,b)=(u,v) ⟺ a=u ∧ b=v（81 组全检）：", pair_check(),
        "   投影 (1,2)₀=", first(pair(1, 2)), " (1,2)₁=", second(pair(1, 2)))

# ---------- 四、同一律（命题 1.1）：相等 ⟺ 双包含 ----------
ext_check() = begin
    Random.seed!(67)
    ok = true
    for _ in 1:200
        A = Set(rand(1:10, 3)); B = Set(rand(1:10, 3))
        ok &= ((A == B) == (issubset(A, B) && issubset(B, A)))
    end
    ok
end
println("随机集合 200 次：A==B ⟺ A⊆B ∧ B⊆A：", ext_check())

println("END ====")
