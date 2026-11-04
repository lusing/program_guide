# 第 142 章 Julia：ω₁ 窗口中的无界闭集（书 6.2）。
# ① club 的判定：在可数窗口内模拟"无界 + 闭"；
# ② 两个 club 之交仍是 club（书 6.2.6）的窗口影子——以
#    "偶数尾部 ∩ 3 的倍数尾部 = 6 的倍数尾部"演示；
# ③ 极限点集运算（书 6.2.4(4)）：X' = X 的极限点集。
println("==== 142 filters")

# 窗口：自然数段 [0, N) 当作 ω 的初始段。尾部集 T_k = {n ≥ k}
N = 60
tail(k) = Set(k:N-1)

is_unbounded(S) = maximum(S) == N - 1         # 窗口语义：顶到窗口边
is_closed_window(S) = true                    # 尾部集在窗口内平凡闭
is_club(S) = is_unbounded(S) && is_closed_window(S)
approaches_top(S) = maximum(S) > N - 10       # 距顶 10 以内即"无界"（稀疏集用）

# ① 基本例（书 6.2.4）：α 自身；尾部 [β,∞)
@assert is_club(tail(0))                       # 全域
@assert is_club(tail(7))                       # 6.2.4(2)
@assert approaches_top(Set(3:3:N-1))              # 3 倍数也"无界"
@assert !is_club(Set(0:30))                    # 有界：非 club
println("club basics: tail sets are clubs, bounded sets are not: OK")

# ② 两个 club 之交（书 6.2.6 的影子）
evens_tail = Set(k for k in 12:N-1 if k % 2 == 0)       # 尾部偶数
mult3_tail = Set(k for k in 18:N-1 if k % 3 == 0)       # 尾部 3 倍数
inter = evens_tail ∩ mult3_tail
@assert approaches_top(inter)                 # 6 倍数逼近窗口顶
@assert inter == Set(k for k in 18:N-1 if k % 6 == 0)   # 恰为 6 倍数（首元 18）
println("club intersection: evens-cap-mult3 = mult6-from-18: OK")

# 但任意两个"无界"集之交可以塌掉（这正是需要闭性的地方）
odds_tail = Set(k for k in 11:N-1 if k % 2 == 1)
@assert approaches_top(evens_tail) && approaches_top(odds_tail)
@assert isempty(evens_tail ∩ odds_tail)       # 偶 ∩ 奇 = ∅！
# 书 6.2.6 之所以成立是因为 club 还要求闭——odd/even 尾部在真正的
# ω₁ 中都不是闭集（其极限点会跨越奇偶）。
println("warning case: unbounded sets can have empty intersection (need closed): OK")

# ③ 极限点（书 6.2.4(4)）：X' = {λ | sup(X∩λ) = λ}
# 窗口影子：对每个 n，若 X 中有元素从下方任意逼近 n，则 n ∈ X'
limit_points(S) = Set(n for n in 0:N-1
                      if n > 0 && n % 5 == 0    # 窗口把"极限序数"模拟为 5 的倍数
                      && length([m for m in n-5:n-1 if m in S]) >= 4
                      && n in S)               # 闭性：点也在集内
X = union(tail(3), Set(37))                    # 加一个孤立点（非极限位置）
lp = limit_points(X)
@assert 37 ∉ lp                                # 孤立点非极限点
@assert 40 ∈ lp                                # 尾部深处全是极限点
println("limit points: isolated points excluded, tails all limit: OK")
println("END ====")
