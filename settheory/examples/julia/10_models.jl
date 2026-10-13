# 第 10 章 模型：公式的 Gödel 编码与可满足性检查
#
# 1. 公式的算术化（Jech："identify symbols with HF sets"）：
#    符号→自然数编码（Gödel 编码的雏形）；
# 2. 有限结构上受限公式的可满足性检查（引理 10.1 的引擎侧）。

println("==== 10 模型：编码与可满足性")

# ---------- 一、公式的 Gödel 编码 ----------

"""符号编码：∈ ↦ 3、= ↦ 5、¬↦7、∧↦9、∃↦11、变元 n ↦ 2n（偶数留变元）"""
code(sym) = sym == :in ? 3 : sym == :eq ? 5 : sym == :not ? 7 :
            sym == :and ? 9 : sym == :ex ? 11 : sym == :all ? 13 :
            sym isa Int && sym >= 0 ? 2 * sym : error("bad symbol")

# 公式的树表示：atom(sym, i, j) 与 nand(p, q)、rex(i, p)、rall(i, p)
struct FAtom; sym::Symbol; i::Int; j::Int; end
struct FNand; p; q; end
struct FRex; i::Int; p; end     # ∃u ∈ x_i : p（u 占 0 号槽）
struct FRall; i::Int; p; end

"""公式的编码（结构递归 → 自然数）"""
function godel(f)
    f isa FAtom && return 2^code(1) * 3^f.i * 5^f.j
    f isa FNand  && return 7 * 2^godel(f.p) * 3^godel(f.q)
    f isa FRex   && return 11 * 2^f.i * 3^godel(f.p)
    f isa FRall  && return 13 * 2^f.i * 3^godel(f.p)
    error("bad formula")
end

f1 = FAtom(:in, 0, 1)
f2 = FNand(FAtom(:in, 0, 1), FAtom(:in, 0, 1))   # ¬(0∈1)
println("编码 atom(0∈1) = ", godel(f1))
println("编码 ¬(0∈1) = ", godel(f2))
@assert godel(f1) != godel(f2)

# ---------- 二、受限公式的有限结构求值 ----------

"""结构：域 0..N-1，∈ 解释为 members(x) 列表"""
struct Structure
    N::Int
    members::Vector{Vector{Int}}
end

nllookup(env, i) = env[i + 1]   # 0 号槽 = 环境头

function sat(M::Structure, f, env::Vector{Int})
    f isa FAtom && f.sym == :in && return nllookup(env, f.i) in M.members[nllookup(env, f.j) + 1]
    f isa FAtom && f.sym == :eq && return nllookup(env, f.i) == nllookup(env, f.j)
    f isa FNand && return !(sat(M, f.p, env) && sat(M, f.q, env))
    f isa FRex  && return any(u -> u in M.members[nllookup(env, f.i) + 1] &&
                                    sat(M, f.p, [u; env]), 0:M.N-1)
    f isa FRall && return all(u -> !(u in M.members[nllookup(env, f.i) + 1]) ||
                                    sat(M, f.p, [u; env]), 0:M.N-1)
    error("bad")
end

# 传递结构：members(x) ⊆ {0..N-1} 且闭包（成员的成员仍是成员——传递性）
M = Structure(4, [[1, 2], [2], [], [0]])       # 1,2 ∈ 0；2 ∈ 1；0 ∈ 3

r1 = sat(M, FAtom(:in, 1, 0), [0, 1])          # x_0=0, x_1=1：查 1∈0
r2 = sat(M, FNand(FAtom(:in, 1, 0), FAtom(:in, 1, 0)), [0, 1])   # ¬(1∈0)
println("\n1 ∈ 0 的真值 = $r1（成员表 {1,2}∈0 ✓）")
println("¬(1 ∈ 0) 的真值 = $r2")
@assert r1 && !r2

# 受限量词：∀u∈x_0 (u ∈ x_0 或 u = 2) 之类的公式
f3 = FRall(0, FNand(FAtom(:in, 0, 1), FAtom(:in, 0, 1)))  # ∀u∈x_0 : ¬(u∈x_0)
r3 = sat(M, f3, [0])
println("∀u∈x_0 ¬(u∈x_0) = $r3（x_0={1,2}：1∈x_0 成立 ⟹ ¬(1∈0) 假 ⟹ 全称假）")
@assert !r3

println("\n要点：受限公式的求值只访问 members(x_i)——")
println("  传递结构上模型内外的成员关系一致（引理 10.1 绝对性的引擎侧）。")

println("END ====")
