# 第 22 章 Suslin 问题：Aronszajn 树的数值侧影
println("==== 22 Suslin 问题")

# ---------- 一、树的基本概念 ----------

println("树：偏序集，每个前驱集良序。")
println("  第 α 层 = {x : ot(x) = α}；height = sup{ot(x)+1}")
println("  分支 = 极大链；反链 = 两两不可比")

# ---------- 二、Aronszajn 树的构造骨架 ----------

"""有理数递增序列（Aronszajn 树的节点）"""
function rational_seq(n::Int)
    """第 n 个节点的序列：用 1/(k+1) 的部分和"""
    return [sum(1/(k+1) for k in 0:i) for i in 0:n]
end

println("\nAronszajn 树（引理 22.3）：ZFC 中存在！")
println("  节点 = 有界递增有理数序列；层 = 序列长度")
println("  每层可数（有理数序列的初始段可数）")
println("  无不可数分支（R 中的递增序列有可数 cofinal 子集）")
for n in [0, 2, 4]
    println("  层 $(n+1) 样本：前 3 项 = ", round.(rational_seq(n)[1:min(3,n+1)], digits=3))
end

# ---------- 三、Suslin vs Aronszajn ----------

println("\nSuslin 树 vs Aronszajn 树：")
println("  Aronszajn：height=ω₁ + 层可数 + 无不可数分支（ZFC ✓）")
println("  Suslin：Aronszajn + 反链可数（ZFC 独立！）")
println("  Tennenbaum-Jech（定理 48）：可数正规树的力迫")

println("END ====")
