# 第 45 章 Julia：级数收敛与三级数定理的机器账（固定种子）。
# ① 随机符号级数 ±k^(-alpha)：alpha > 1/2 时部分和收敛（增量方差账），
#    alpha < 1/2 时发散——三级数 (c) 的方差门槛；
# ② Kolmogorov 极大不等式的 MC 对账（频率 <= n/eps^2）；
# ③ Feller 弱律：重尾 Pareto beta=2 时中心化弱律成立、beta=1 时失败；
# ④ 截断阈值 d 的不敏感性（d=1 与 d=3 的三账同为收敛）。
println("==== 45 three_series")
using Random, Statistics

# ---------- ① 随机符号级数：方差门槛 ----------
println("① 随机符号级数 X_k = ±k^(-alpha)（2000 轨道，S_4000 - S_2000 的标准差）：")
rng = MersenneTwister(4501)
function increment_std(alpha, n1, n2, reps)
    t = [sum((rand(rng) < 0.5 ? 1 : -1) * k^(-alpha) for k in n1+1:n2) for _ in 1:reps]
    std(t)
end
for alpha in [0.4, 0.6]
    theory = sqrt(sum(k -> k^(-2 * alpha), 2001:4000))
    emp = increment_std(alpha, 2000, 4000, 2000)
    println("   alpha=", alpha, "：理论 sigma = ", round(theory, digits=3),
            "，经验 sigma = ", round(emp, digits=3),
            alpha > 0.5 ? "（收敛：增量波动被压扁）" : "（发散：波动不衰减）")
    @assert abs(emp - theory) < 0.15 * theory
end
@assert increment_std(0.6, 2000, 4000, 2000) < 0.5 * increment_std(0.4, 2000, 4000, 2000)

# ---------- ② Kolmogorov 极大不等式 ----------
println("② Kolmogorov 极大不等式（n=100 个 ±1，20000 轨道）：")
rng2 = MersenneTwister(4502)
for eps in [12.0, 14.0, 16.0]
    hits = 0
    for _ in 1:20000
        s = 0.0
        m = 0.0
        for _ in 1:100
            s += rand(rng2) < 0.5 ? 1 : -1
            m = max(m, abs(s))
            m >= eps && break
        end
        hits += m >= eps
    end
    emp = hits / 20000
    bound = 100 / eps^2
    println("   eps=", eps, "：P(max|S_k| >= eps) = ", round(emp, digits=4),
            " <= var/eps^2 = ", round(bound, digits=4))
    @assert emp <= bound + 0.02
end

# ---------- ③ Feller 弱律：重尾 ----------
println("③ Feller 弱律（iid，尾 P(|X|>x)=(1+x)^(-beta)，中心 c_n = n·E[X·1{|X|<=n}]）：")
function feller_trial(beta, n, reps, eps)
    cnt = 0
    for _ in 1:reps
        s = 0.0
        c = 0.0
        for _ in 1:n
            x = rand(rng) .^ (-1 / beta) - 1
            s += x
            abs(x) <= n && (c += x)
        end
        abs((s - c) / n) >= eps && (cnt += 1)
    end
    return cnt / reps
end
for beta in [2.0, 1.0]
    p100 = feller_trial(beta, 100, 2000, 0.1)
    p800 = feller_trial(beta, 800, 2000, 0.1)
    println("   beta=", beta, "：P(|(S_n-c_n)/n|>0.1)：n=100 时 ", round(p100, digits=3),
            " -> n=800 时 ", round(p800, digits=3),
            beta == 2.0 ? "（nP(|X|>n)->0，弱律成立）" : "（nP(|X|>n)->1，弱律失败）")
end
@assert feller_trial(2.0, 800, 2000, 0.1) < feller_trial(2.0, 100, 2000, 0.1)
@assert feller_trial(1.0, 800, 2000, 0.1) > 0.15

# ---------- ④ 阈值 d 的不敏感性 ----------
println("④ 三级数对 d 的不敏感性（稀疏跳跃序列，d=1 与 d=3 的三账部分和）：")
rng3 = MersenneTwister(4503)
function three_series(d, n)
    a = 0; b = 0.0; c = 0.0
    for k in 1:n
        x = rand(rng3) < 1 / k^2 ? (rand(rng3) < 0.5 ? 10.0 : -10.0) : 0.0
        if abs(x) >= d
            a += 1
        else
            b += x
            c += x * x
        end
    end
    (a, b, c)
end
a1, b1, c1 = three_series(1.0, 5000)
a3, b3, c3 = three_series(3.0, 5000)
println("   d=1：(a)=", a1, "，(b)=", round(b1, digits=3), "，(c)=", round(c1, digits=3))
println("   d=3：(a)=", a3, "，(b)=", round(b3, digits=3), "，(c)=", round(c3, digits=3))
@assert a1 >= a3 && abs(c1 - c3) < 1e-9
println("   （d 变大只把更多项记入 (a)，(b)(c) 截尾账不变——对某个 d 收敛即对一切 d 收敛）")
println("END ====")
