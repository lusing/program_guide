# 第 61 章：有限概率的机器化（Makinson Ch6）
# 骰子对条件概率 + 辛普森 + 贝叶斯 + 期望 + 蒙特卡洛复核
println("==== 61")

using Random

# ---------- 一、骰子对：条件概率（精确计数） ----------
S = [(a, b) for a in 1:6, b in 1:6]
B = filter(p -> p[1] + p[2] == 5, S)
A = filter(p -> p[1] == 3 || p[2] == 3, S)
AB = filter(p -> (p[1] + p[2] == 5) && (p[1] == 3 || p[2] == 3), S)
println("  骰子对：#B = $(length(B))，#A = $(length(A))，#A∩B = $(length(AB))")
println("    p(A|B) = $(length(AB))/$(length(B)) = $(length(AB)//length(B))")
println("    p(B|A) = $(length(AB))/$(length(A)) = $(length(AB)//length(A))（不可交换）")

# ---------- 二、辛普森悖论（精确比值） ----------
println("  辛普森（26 申请者）：")
println("    女 CS 2/8 = ", 2//8, " > 男 CS 1/5 = ", 1//8 == 1//8 ? "" : "", 1//5)
println("    女数学 4/5 = ", 4//5, " > 男数学 6/8 = ", 6//8)
println("    合计 女 6/13 = ", 6//13, " < 男 7/13 = ", 7//13, "（反转！）")

# ---------- 三、贝叶斯 ----------
bayes(pc, pPC, pPnC) = pPC * pc / (pPC * pc + pPnC * (1 - pc))
println("  癌症检查：p(C|P) = ", round(bayes(0.01, 1.0, 0.2), digits=4),
    "（丢基础率的直觉给 0.83）")
println("  HIV 先验 0.15：", round(bayes(0.15, 0.9, 0.03), digits=3))
println("  HIV 先验 0.60：", round(bayes(0.60, 0.9, 0.03), digits=3), "（先验抬高后验抬高）")
println("  接线员：Clarice 后验 = ",
    round(0.9 * 0.3 / (0.6 * 0.33 + 0.7 * 0.37 + 0.9 * 0.3), digits=3))

# ---------- 四、期望三马 ----------
p = [0.1, 0.3, 0.6]; f = [12, -1, -1]
mu = sum(f .* p)
println("  期望 μ = 12·0.1 − 1·0.3 − 1·0.6 = ", mu, "（正 → 值得长期赌）")
println("  简单平均 = ", sum(f) / 3, "（≠ μ：概率加权 vs 等权）")

# ---------- 五、蒙特卡洛复核条件概率 ----------
function mc_conditional(trials = 200_000)
    n = 0; d = 0
    for _ in 1:trials
        s = (rand(1:6), rand(1:6))
        if s[1] + s[2] == 5
            d += 1
            (s[1] == 3 || s[2] == 3) && (n += 1)
        end
    end
    n / d
end
println("  蒙特卡洛（20 万次）：p(A|B) ≈ ", round(mc_conditional(), digits=4),
    "（真值 0.5）")

println("END ====")
