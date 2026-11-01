# 第 117 章：荟萃塔 II——有限投影表示、两种树表示与临界点小表。
# 与 Python 独立对拍；有限穷举不证明无限荟萃塔或 Woodin 定理。
function main()
    println("==== 117")
    U = (0, 1, 2)
    funs = [(a, b, c) for a in U for b in U for c in U]
    mark(k) = k
    proj(k, x) = k == 0 ? 0 : k == 1 && x == 2 ? 1 : x
    feval(f, x) = f isa Tuple ? f[x + 1] : f(x)
    lift(k, f) = x -> feval(f, proj(k, x))
    rep(k, f) = feval(f, mark(k))

    pairs = ((0, 1), (0, 2), (1, 2))
    reps_ok = all(rep(l, lift(k, f)) == feval(f, k)
                  for (k, l) in pairs for f in funs)
    comp_ok = all(lift(l, lift(k, f))(x) == lift(k, f)(x)
                  for (k, l) in pairs for f in funs for x in U)
    restrict_ok = all(lift(1, f)(x) == feval(f, x)
                      for f in funs for x in (0, 1))
    println("[投影表示] 27 函数×3 层对: 代表值保持 ", reps_ok,
            "；复合兼容 ", comp_ok, "；低支撑复原 ", restrict_ok)

    # 同一 A⊆U 的两种树表示：带标签前缀树与特征分支表。
    word(A) = ntuple(n -> Int((n - 1) in A), 3)
    prefix_tree(A) = let w = word(A)
        ntuple(n -> w[1:n-1], 4)
    end
    branch_table(A) = let w = word(A)
        ntuple(n -> (n - 1, w[n]), 3)
    end
    from_prefix(T) = Set(x for x in U if T[x + 2][x + 1] == 1)
    from_branch(B) = Set(x for (x, b) in B if b == 1)
    subsets = [Set(x for x in U if (m >> x) & 1 == 1) for m in 0:7]
    trees_ok = all(from_prefix(prefix_tree(A)) == A &&
                   from_branch(branch_table(A)) == A &&
                   from_prefix(prefix_tree(A)) == from_branch(branch_table(A))
                   for A in subsets)
    trees_injective = length(unique(prefix_tree(A) for A in subsets)) == 8 &&
                      length(unique(branch_table(A) for A in subsets)) == 8
    println("[两树表示] 8 个子集: 前缀树/分支表复原一致 ", trees_ok,
            "；表示各自单射 ", trees_injective)

    # crit=1、目标=2 的小模型表：低于临界点不动，临界点被移动。
    jfin(x) = x < 1 ? x : x + 1
    crit_table = [(x, jfin(x)) for x in U]
    crit_ok = jfin(0) == 0 && jfin(1) == 2 && jfin(1) != 1
    println("[临界点表] ", crit_table, "；固定下方并移动临界点 ", crit_ok)
    witness = x -> (2, 0, 1)[x + 1]
    println("[见证提升] f=(2,0,1), 0→2 层代表值: ",
            rep(0, witness) == 2, "→", rep(2, lift(0, witness)))

    @assert reps_ok && comp_ok && restrict_ok && trees_ok && trees_injective && crit_ok
    println("三级投影表示/复合；前缀树↔分支表；临界点表与见证提升")
    println("END ====")
end

main()
