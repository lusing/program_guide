# 第 132 章 Julia：对角线法与康托集的数值面。
# ① [0,1]^N 不可数（书 3.6.2）：任给 0-1 序列的列表，翻转对角线
#    得到漏网之鱼——确定性"伪列表"上可执行；
# ② 康托集（书 3.6.3）：三进地址 f: {0,1}^N → C 的数值计算；
#    首差异在第 n 位的两个地址映射后至少相距 3^{-(n+1)}；
# ③ 地址 (0,1,1,1,…) 映到 1/3 = 0.0222…₃——三进展开的双重表示
#    只涉及数字 1，恰好落在地址系统之外，f 才得以单射。
println("==== 132 uncountable")

# ① 对角线：伪列表 α_n(k) = (n*k + n + k) mod 2，翻转对角线
alpha(n, k) = (n * k + n + k) % 2
beta(k) = 1 - alpha(k, k)
for k in 0:50
    @assert beta(k) != alpha(k, k)                    # 与第 k 行在第 k 位不同
    @assert beta(k) != alpha(k, k)                    # ⟹ β 不在列表中
end
println("diagonal: flipped diagonal beta misses every listed row: OK")

# ② 三进地址映射：f(α) = Σ 2α(k)·3^{-(k+1)}（左 0 / 右 1）
faddr(a, depth) = sum(Rational{Int}(2 * a[k]) // BigInt(3)^(k) for k in 1:depth)
#   注：a[k] 是第 k−1 位；尾部补 0 的地址有有限三进表示

α1 = [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]    # 0.0222…₃
α2 = [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]    # 0.2000…₃
α3 = [0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0]
@assert faddr(α1, 15) == 1 // 3 - 1 // BigInt(3)^15   # 截断恒等式：前 d 项和 = 1/3 − 3^{-d}
@assert faddr(α2, 15) == 2 // 3                       # 0.2000…₃ = 2/3
@assert faddr(α1, 15) != faddr(α3, 15)                # 不同地址不同点

# 单射的数值审计：首差异在第 n 位的两地址至少相距 3^{-(n+1)}
for (a, b, n) in ((α1, α3, 2), (α2, α1, 1), (α3, α1, 2))
    d = abs(faddr(a, 15) - faddr(b, 15))
    @assert d >= 1 // BigInt(3)^(n + 1)
end
println("cantor addresses: f(0111..) = 1/3, first-gap >= 3^{-(n+1)}: OK")

# ③ 区间套（书 3.6.1 的实例）：沿地址嵌套的闭区间长度 3^{-n} → 0
function nest(a, depth)
    lo, hi = 0 // 1, 1 // 1
    for k in 1:depth
        third = (hi - lo) // 3
        if a[k] == 0
            hi = lo + third
        else
            lo = hi - third
        end
    end
    (lo, hi)
end
for depth in 1:12
    lo, hi = nest(α1, depth)
    @assert hi - lo == 1 // BigInt(3)^depth           # 区间长度精确 3^{-n}
    x = faddr(α1, depth)
    @assert lo <= x <= hi                              # f(α) 始终落在区间内
end
lo, hi = nest(α1, 12)
@assert lo == 1 // 3 - 1 // BigInt(3)^12 && abs(float(hi - 1 // 3)) < 1e-6
println("nested intervals: length 3^{-n} shrinking, f stays inside: OK")
println("END ====")
