# 21 · 随机与统计 ⭐

> 对应示例：`examples/21_randomstats/`（全程固定种子——输出可复现、断言可确定）
>
> 科学计算的第二条腿：`Random` + `Statistics` 都是标准库。本章覆盖 RNG 子流、描述统计、蒙特卡洛、中心极限定理与置信区间——统计模拟的完整最小闭环。

## 21.1 Random：RNG 对象与可复现子流

```julia
rng = Xoshiro(20260918)       # Julia 默认 RNG 类型（1.7+）；一个对象 = 一条独立"子流"
a = rand(rng, 5)
b = rand(rng, 5)
a != b                        # 同一 rng 顺序推进
Xoshiro(20260918) |> (r -> rand(r, 5)) == a   # 同种子新建 → 逐位复现
```

**库代码传 `rng`、不碰全局**：`Random.seed!(n)` 只该出现在脚本/REPL 顶层；函数签名带 `rng` 参数让调用方控制复现——这是可复现科学的纪律（测试里 18 章的 seed 惯例由此而来）。

```julia
rand(rng, 2, 3)               # 形状：2×3 矩阵
rand(rng, Float32, 2)         # 类型：Float32 向量
randn(rng, 1000)              # 标准正态
2 .+ rand(rng, 3)             # 区间 [2,3)：线性变换 a + (b-a)·U（区间采样通用姿势）
rand!(rng, v)                 # 原地重填（零分配）
shuffle(rng, collect(1:10))   # 洗牌
```

## 21.2 Statistics：描述统计

```julia
data = [2, 4, 4, 4, 5, 5, 7, 9]
mean(data) == 5.0 && median(data) == 4.5
var(data) ≈ 32 / 7                        # 样本方差（n-1 修正，默认——统计推断用）
var(data; corrected = false) ≈ 4.0        # 总体方差（描述整个总体时用）
std(data) ≈ sqrt(32 / 7)
quantile(data, 0.5) == 4.5
cor([1, 2, 3], [2, 4, 6]) ≈ 1.0           # 相关系数
cov([1, 2, 3], [2, 4, 6]) ≈ 2.0           # 样本协方差
mean(M; dims = 1)                          # 按维统计：每列均值 → 1×n 矩阵
```

中位数 vs 均值（实测）：`[1, 2, 3, 4, 100]` 的 median = 3、mean = 22——离群点拉飞均值，报告里两个都给。

## 21.3 蒙特卡洛 I：投点算 π

```julia
function mc_pi(n, rng)
    hits = 0
    for _ in 1:n
        x, y = rand(rng), rand(rng)
        x * x + y * y <= 1 && (hits += 1)
    end
    4 * hits / n
end
# 实测：N=1e4 → 3.1512，N=1e6 → 3.14120
```

MC 的收敛律是 **1/√N**：样本 ×100 只换一位精度（实测误差比 ≈ 10~25，期望 10）——慢而普适，是"没有更好办法时的底线方法"。同种子结果逐位相同；不同种子各自收敛。

## 21.4 蒙特卡洛 II：期望式积分

```julia
mc_int(f, n, rng) = sum(f(rand(rng)) for _ in 1:n) / n   # E[f(U)] ≈ ∫₀¹ f
mc_int(exp, 1_000_000, rng)     # 实测 1.71828（精确 ℯ-1 = 1.71828…）
```

`∫₀¹f(x)dx = E[f(U)]`——积分变期望，期望用样本均值估。高维积分时 MC 依旧 1/√N，而网格法指数爆炸——维数灾难的解药。

## 21.5 逆变换采样 + 中心极限定理

```julia
exp_sample(rng, n; θ = 1.5) = [-θ * log(rand(rng)) for _ in 1:n]   # U → 指数分布：X = -θ·ln U
# 实测 1 万样本：mean ≈ 1.5（= θ）、std ≈ 1.5（指数分布均值标准差都是 θ）
means = [mean(exp_sample(rng, 50)) for _ in 1:5000]
std(means) ≈ 1.5 / sqrt(50)      # 实测 0.2153 vs 理论 0.2121——CLT 的定量形态
```

CLT 说的是：**样本均值的标准差 = σ/√n**——σ=1.5、n=50，均值族的离散度缩到 0.21。这解释了"为什么重复实验取平均能压噪声"，也是下一节置信区间的全部理论基础。

## 21.6 置信区间覆盖率：模拟验证统计方法

```julia
function coverage(rng; trials = 1000, n = 100, θ = 1.5)
    hits = 0
    for _ in 1:trials
        s = exp_sample(rng, n; θ = θ)
        m, se = mean(s), std(s) / sqrt(n)
        abs(m - θ) <= 1.96 * se && (hits += 1)   # m ± 1.96·se 是否盖住真值
    end
    hits / trials
end
# 实测覆盖率 0.935 ≈ 95%
```

"95% 置信区间"的含义用模拟直接看清：**重复一千次实验，约 950 次的区间盖住真值**。任何统计方法都可以这样"模拟体检"——这是蒙特卡洛在方法论层面的用法（比算 π 更重要）。

## 21.7 随机游走：方差线性增长

```julia
walk_ends = [sum(randn(rng, 1000)) for _ in 1:2000]
std(walk_ends) ≈ sqrt(1000)      # 实测 30.81 vs 理论 31.62：n 步游走末端 std = √n
cumsum(randn(rng, 10_000))       # 轨迹本身——布朗运动/扩散的离散骨架
```

## 21.8 坑位清单

1. **循环里新建同种子 rng = 拿到同一个样本**：`[f(Xoshiro(11)) for _ in 1:n]` 全是同一批数（std≈0 暴露问题）——rng 提到循环外（实测踩过）。
2. **`var` 默认 n-1 修正**：描述总体加 `corrected = false`；混用会让方差对不上（21.2）。
3. **`rand(2.0..3.0)` 不存在**：`..` 不是 Base 运算符——区间采样写 `a .+ (b-a) .* rand(rng, n)`（21.1 实测）。
4. **MC 断言留统计余量**：1/√N 收敛有随机性——误差比断言 (2, 50) 而不是 ≈10；覆盖率断言 (0.92, 0.98) 而不是 0.95（21.3/21.6，18 章性质测试的分寸）。
5. **`ℯ` 才是 Base 的欧拉数**：`MathConstants.e` 要先 `using MathConstants`——直接写 `ℯ`（\euler 补全）或 `exp(1)`（21.4 实测）。
6. **全局 seed 是脚本的事**：库里写 `Random.seed!` 会污染调用方的随机状态——签名带 `rng`（21.1）。
