# 第 60 章：计数的机器化（Makinson Ch5）
# 四式选取枚举 + 排列组合公式 + 重排计数 + 容斥
println("==== 60")

# ---------- 一、四式选取：5 选 2 ----------
pool = 1:5
pairs = collect(Iterators.product(pool, pool))[:]
println("  5 选 2 的四模式（O±R±）：")
println("    O+R+（全部序对）：", length(pairs), " = 5²")
println("    O+R−（去对角）：", count(p -> p[1] != p[2], pairs), " = P(5,2)")
println("    O−R+（无序含等）：", count(p -> p[1] <= p[2], pairs), " = C(6,2)")
println("    O−R−（无序严格）：", count(p -> p[1] < p[2], pairs), " = C(5,2)")

# ---------- 二、排列与组合公式表 ----------
P(n, k) = factorial(n) ÷ factorial(n - k)
C(n, k) = factorial(n) ÷ (factorial(k) * factorial(n - k))
println("  P(6,0..6) = ", [P(6, k) for k in 0:6])
println("  C(6,0..6) = ", [C(6, k) for k in 0:6], "（杨辉三角第 6 行）")
println("  P(10,6) = ", P(10, 6), "；C(10,6) = ", C(10, 6), "（书本子委员会例）")
println("  15 领带 5 天不重样：", P(15, 5), " 周 ≈ ", P(15, 5) ÷ 52, " 年")

# ---------- 三、重复选取 ----------
println("  重复组合（隔板法）：10 人 6 任务 = C(15,6) = ", C(15, 6))
println("  冰淇淋两种读法：155（有序）vs ",
    sum(C(5 + k - 1, k) for k in 1:3), "（无序）")

# ---------- 四、重排 ----------
rearrangements(word) = factorial(length(word)) ÷ prod(factorial(count(==(c), word)) for c in unique(word))
for w in ("banana", "Turramurra", "Mississippi", "Ouagadougou", "Woolloomooloo")
    println("  ", rpad(w, 14), " 重排数 = ", rearrangements(w))
end
println("    （书本 Woolloomooloo 记 4324320，按实拼写 o:8,l:3 计则为 25740——书本字母账有出入）")
# banana 枚举复核（自写排列生成，避免外部包）
function perms(l)
    (isempty(l) && return [[]])
    out = []
    for i in eachindex(l)
        rest = l[setdiff(1:end, i)]
        for p in perms(rest)
            push!(out, [l[i]; p])
        end
    end
    out
end
banana_perms = unique(join(p) for p in perms(collect("banana")))
println("  banana 枚举复核（720 排列去重）：", length(banana_perms), " = 6!/3!2! ✓")

# ---------- 五、容斥 ----------
println("  三人电话（容斥）：5+10+7−3−2−2+1 = ", 5 + 10 + 7 - 3 - 2 - 2 + 1)

println("END ====")
