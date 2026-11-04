# 第 02 章 集合论：Julia 通道。
# 有限论域上的并交补与德摩根律（穷举核验），以及索引族区间的
# 数值实验——无限并/交在机器上只能截断到有限 N，观察“极限点”
# 如何永远差一步。运行：julia --startup-file=no 02_sets.jl

println("==== 02 sets ====")

# --- 1. 有限论域 U = 1:9 上的集合运算 ------------------------------
U = Set(1:9)
A = Set([1, 3, 5, 7])
B = Set([2, 3, 4, 7])
comp(S) = setdiff(U, S)

# 定理 3.12 性质 1：A ⊆ A∪B，A∩B ⊆ A。
@assert issubset(A, A ∪ B)
@assert issubset(A ∩ B, A)

# 定理 3.12 性质 2/3：包含关系与并/交吸收的等价性。
@assert (issubset(A, B) == (A ∪ B == B))
@assert (issubset(A, B) == (A ∩ B == A))

# 分配律与德摩根律：对论域逐点（∈ 判定）穷举。
@assert A ∪ (B ∩ comp(A)) == (A ∪ B) ∩ (A ∪ comp(A))
@assert comp(A ∪ B) == comp(A) ∩ comp(B)
@assert comp(A ∩ B) == comp(A) ∪ comp(B)
println("finite-universe De Morgan and distributivity verified")

# 空集性质：空集与任何集合的交仍是空集，空集是任何集合的子集。
@assert isempty(Set{Int}() ∩ A)
@assert issubset(Set{Int}(), A)

# --- 2. 区间漏洞：(1,3) ∪ (3,5) ≠ (1,5) ---------------------------
# 用有理数端点模拟开区间，点 3 恰好是漏洞。
open_interval(a, b, xs) = Set(x for x in xs if a < x < b)
grid = collect(1:0.25:5)
@assert !(3.0 in open_interval(1, 3, grid) ∪ open_interval(3, 5, grid))
@assert 3.0 in open_interval(1, 5, grid)
println("open intervals: point 3 is the gap in (1,3) union (3,5)")

# --- 3. 索引族 A_n = (-1/(n+1), 1/(n+1))：递减族的并 ---------------
# 完整定理（无限并 = (-1,1)）在 Lean 通道证明；这里截断到 N 观察：
# 截断并始终等于最大的 A_0，嵌套结构一目了然。
Aseq(n) = (-1/(n+1), 1/(n+1))
N = 100
union_lo, union_hi = Aseq(0)
for n in 1:N
    lo, hi = Aseq(n)
    global union_lo, union_hi
    union_lo = min(union_lo, lo)
    union_hi = max(union_hi, hi)
end
@assert union_lo == -1.0 && union_hi == 1.0
println("A_n nested union truncated at N=$N: ($union_lo, $union_hi)")

# --- 4. 索引族 B_n = [0, 2 - 1/(n+1)]：递增族 ----------------------
# 截断并的右端点单调逼近 2 但永远到不了 2——机器上看得见“缺口”。
Bseq(n) = (0.0, 2 - 1/(n+1))
right_ends = [Bseq(n)[2] for n in 0:N]
@assert issorted(right_ends)                 # 递增
@assert maximum(right_ends) < 2.0            # 有限截断永远够不到 2
@assert isapprox(maximum(right_ends), 2 - 1/(N+1); atol=1e-12)
println("B_n truncated union supremum = $(maximum(right_ends)) < 2 (gap remains)")

# 截断交始终等于最小的 B_0 = [0,1]。
inter_hi = minimum(right_ends)
@assert inter_hi == Bseq(0)[2] == 1.0
println("B_n truncated intersection = [0, $inter_hi]")

# --- 5. 索引族德摩根律的有限影子 -----------------------------------
# 取三个具体集合，核验补(并) = 交(补)，对应 Lean 的 compl_iUnion。
E = [Set([1, 2]), Set([2, 3]), Set([4, 5])]
@assert comp(union(E...)) == intersect(comp.(E)...)
println("indexed-family De Morgan checked on 3 finite sets")

println("END ====")
