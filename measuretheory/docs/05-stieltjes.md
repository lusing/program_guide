# 05 欧氏空间中的 Lebesgue-Stieltjes 测度

**对应严书 §1.5（pp. 22-24）。**

---

## 5.1 一维的统一框架：分布函数即测度

第 04 章的流水线需要一个"半环上的预测度"作为原料。本章给出最优雅的
原料：**单调右连续函数**。设 F : ℝ → ℝ 单调增、右连续，定义

  μ_F((a, b]) = F(b) − F(a)

区间长度只是 F(x) = x 的特例。奇迹在于：只要 F 单调右连续，这个
"区间赋值"就满足半环上的有限可加性，从而经 Carathéodory 流水线
产出一个完整的测度 μ_F——**Lebesgue-Stieltjes 测度**。反过来（第 06
章的唯一性定理将严格化），ℝ 上每个有限 Borel 测度都长这样。

这就是概率论的字典：**分布函数 ↔ 概率测度**。离散随机变量的分布函数
是阶梯（原子测度），连续型是绝对连续（密度），Cantor 分布是第三种
存在——奇异连续：连续却不绝对连续，支撑还是零测集。

**为什么右连续？** μ((a,b]) = F(b) − F(a) 型的测度把"点的质量"记在
区间右端：μ({b}) = F(b) − F(b−)。右连续性保证 F 在跳点取"跳完后"
的值，与 (a, b] 的半开结构严丝合缝。若改用左连续 F 与 [a, b) 型区间，
整套理论平移对称——教材选择不同，测量结果相同。

## 5.2 构造的核对清单

正文给出完整证明，这里列核对要点：

1. **有限可加**：(a, b] 与 (b, c] 拼成 (a, c]，值相加——平凡；
   关键是不交分解的**唯一性**（半环结构，1.3.5 引理）。
2. **σ-有限**：ℝ = ⋃(−n, n]，每段有限——第 06 章唯一性的入场券。
3. **点的质量**：μ_F({x}) = F(x) − F(x−)（左极限），F 连续处为零。
4. **总质量**：μ_F(ℝ) = F(+∞) − F(−∞)（单调函数的端点极限总存在）。

## 5.3 高维：盒半环与随机向量的分布函数

严书 §1.5 的构造其实开在 **ℝⁿ** 上。记 a = (a₁,…,aₙ) ≤ b 若各坐标
aᵢ ≤ bᵢ；半开**盒** (a, b] = (a₁,b₁] × ⋯ × (aₙ,bₙ]，赋**体积**

  μ((a, b]) = ∏ᵢ (bᵢ − aᵢ)。

**引理（严书 1.5.1）** 盒族 C 是 ℝⁿ 上的半环，且 μ 有限可加、
半 σ-可加——于是由第 04 章工序一（命题 1.4.4），μ σ-可加，
Carathéodory 流水线产出 **ℝⁿ 上的 Lebesgue 测度**。

半 σ-可加的证明值得看一眼，它是"紧性抵消 ε"的模板：设盒 I 被
可数个盒 Iⱼ 覆盖，把 I 略缩成紧盒 I′（体积差 < ε），把每个 Iⱼ
略胀成开盒 Iⱼ′（体积差配 ε/2ʲ）；Heine-Borel 从开覆盖抽出有限
子覆盖，剩下的是**有限**个体积不等式相加——ε 全部摊进膨胀预算。
第 04 章 Lebesgue 构造核对单第 3 步是它的一维版。

**LS 测度**：对每个坐标方向配一个单调右连续 Fᵢ，或整体上取
F(a) = μ((−∞, a])，同样的流水线给出 ℝⁿ 上一般的 LS 测度。严书
定理 1.5.2 指出：每个有限 LS 测度都来自这样的 F（证明从略，但
**概率够用的特例**完整：μ((−∞,a]) < ∞ 时 F(a) := μ((−∞,a])
就是要找的增函数）。

高维字典比一维**费劲**在一处：n ≥ 2 时"单调"不够——F : ℝⁿ → ℝ
要成为某个测度的分布函数，除各坐标单调、右连续外，还须对盒体积
非负：

  Δ_a^b F := Σ_{ε∈{0,1}ⁿ} (−1)^{|ε|} F(c(ε)) ≥ 0，
  其中 c(ε)ᵢ = εᵢ=1 ? bᵢ : aᵢ。

（二维即 F(b₁b₂) − F(a₁b₂) − F(b₁a₂) + F(a₁a₂) ≥ 0。）各坐标
边缘单调**推不出**这个联合容度条件——它正是第 17 章乘积 σ-代数
与第 21 章 Kolmogorov 相容性定理登场的入口：多维/无穷维分布的存在
性不是"逐维单调"的自动结论。

习题 1.5.1 还给了一个前瞻：ℝⁿ 上任何 LS 测度满足**内紧外开正则**

  μ(B) = sup{μ(K) : K ⊆ B 紧} = inf{μ(G) : B ⊆ G 开}，

这是第 25 章正则测度的种子，也是 Heine-Borel 在流水线里的回响。

## 5.4 Lean：mathlib 的 StieltjesFunction

mathlib 打包了整个构造（`Ch05Stieltjes.lean`）。结构体
`StieltjesFunction R` = 单调 + 右连续的实函数；核心引理：

```lean
theorem StieltjesFunction.measure_Ioc (a b : R) :
    f.measure (Ioc a b) = ENNReal.ofReal (f b - f a)
```

我们用恒等函数走一遍（它生成的测度就是 Lebesgue 测度）：

```lean
noncomputable def idStieltjes : StieltjesFunction ℝ where
  toFun := fun x => x
  mono' := monotone_id
  right_continuous' := fun _ => continuous_id.continuousWithinAt

example (a b : ℝ) : idStieltjes.measure (Set.Ioc a b)
    = ENNReal.ofReal (b - a) := idStieltjes.measure_Ioc a b
```

相邻区间的可加性是被机器**纠正过**的一例：初稿陈述没有假设
a ≤ b ≤ c，而 ENNReal.ofReal 把负数截断为 0，无序区间上等式**不成立**
（如 a=1, b=0：左端 ofReal(−1) + ofReal(1) = 1，右端 ofReal(0) = 0）。
修正后的陈述加上有序性：

```lean
example (a b c : ℝ) (hab : a ≤ b) (hbc : b ≤ c) :
    idStieltjes.measure (Set.Ioc a b) + idStieltjes.measure (Set.Ioc b c)
      = idStieltjes.measure (Set.Ioc a c) := by
  rw [idStieltjes.measure_Ioc, idStieltjes.measure_Ioc, idStieltjes.measure_Ioc]
  simp only [idStieltjes]
  have h1 : ENNReal.ofReal ((b - a) + (c - b))
      = ENNReal.ofReal (b - a) + ENNReal.ofReal (c - b) :=
    ENNReal.ofReal_add (by linarith) (by linarith)
  have hsum : (c - a : ℝ) = (b - a) + (c - b) := by ring
  rw [hsum, ← h1]
```

注意 `ENNReal.ofReal_add` 带**两个**非负性前提（2026 版签名）——
只给一个会留下悬空的 side condition。这是"机器抓数学错误"的第三次
入账：**截断算术下的恒等式，前提比看起来多**。

## 5.5 数值实验：三种分布函数的全家福

Julia（`05_stieltjes.jl`）把三类分布函数放在同一框架 μ(a,b] = F(b)−F(a)
下体检：

**原子型**（整数点各 1/4 质量）：F(x) = #{k ≤ x}/4：

```
原子分布 F：F(0.5)=0.0，F(1)=0.25，F(4)=1.0（右连续）
原子测度：μ(0.5,3.5] = 0.75；单点质量均为 1/4
```

单点质量用 μ{k} = F(k) − F(k−ε) 数值逼近（ε=1e-9），四个原子全对。

**绝对连续型**（F = id）：μ(0.2,0.7] = 0.5，区间可加性成立——这就是
Lebesgue 测度本人。

**奇异连续型**（Cantor 分布）：Cantor 函数的数值实现走三进制数位：

```julia
function cantor_F(x, depth = 40)
    x <= 0 && return 0.0
    x >= 1 && return 1.0
    acc = 0.0
    y = x
    for i in 1:depth
        y *= 3
        d = floor(Int, y)
        if d == 1
            return acc + 2.0^(-i)   # 中段常值：左端值 + 半位
        end
        d == 2 && (acc += 2.0^(-i))
        y -= d
    end
    acc
end
```

读法：把 x 的三进制展开逐位读出；遇到数字 1 就落在被挖空的中段，
函数值冻结为"左端值 + 半个二进位"；数字 0/2 分别贡献二进制的 0/1。
这份实现的第一个版本在端点 x=1 处翻车（floor(3.0) = 3 被当成数字
2 处理，F(1) 算成 0.5）——端点特判是区间数学的永恒课题。

体检结果：

```
Cantor F：单调 OK；F(0)=0.0，F(1)=1.0
Cantor 测度：μ[0,1/3] = 0.5（自相似半质量），中段质量 0.0（零）
Cantor 测度无原子：5 个测试点单点质量均 < 1e-6（奇异连续）
Cantor 抽样 2 万点：前 1/3 频率 0.4978（理论 0.5），中段频率 0.0
```

"无原子"一栏也有个数值教训：单点质量的逼近 ε 不能取 1e-7——
Cantor 函数的局部斜率无界（第 i 层的坡度是 (3/2)^i），固定 ε 会把
陡坡的增量误报成原子；ε 收到 1e-12 后 5 个测试点全部干净。
**逼近"左极限"的 ε 必须小于被测点的最小尺度**。

抽样部分用 Cantor 逆映射（二进均匀 → 三进 0/2 位填空）造出 2 万个
精确分布样本，前 1/3 频率 0.4978 印证 μ[0,1/3] = 1/2 的自相似，中段
频率 0.0 印证挖空——分布函数、测度、随机抽样三个视角在同一对象上
对齐。

Python（`05_stieltjes.py`）用 `Fraction` 把块结构与自相似方程做成
**精确**版本：深度 6 的 64 块、每块长度 1/729、质量 1/64，总质量
精确为 1，前一半块（16 块）质量精确 1/2；Cantor 函数与抽样另用浮点
独立复算，与 Julia 逐项一致。

## 5.6 要点回顾

1. 单调右连续函数 ↔ ℝ 上的有限 Borel 测度（LS 测度），字典的三行：
   阶梯↔原子、绝对连续↔密度、Cantor↔奇异连续。
2. 右连续与 (a,b] 型区间配套；点的质量 = F(x) − F(x−)。
3. ℝⁿ 版：盒半环 + 体积（1.5.1），紧性抵消 ε 的半可加性模板；
   高维分布函数需要**联合容度条件**（盒差分非负），这是乘积理论与
   Kolmogorov 相容性的入口。
4. 截断算术（ofReal）下的恒等式需要有序性前提——机器抓错的常客。
5. Cantor 分布是"连续 + 支撑零测 + 无原子"的三合一标本，三个性质
   都可数值验证，但逼近尺度要选对。

*对应示例（可选）：`examples/lean/Measuretheory/Ch05Stieltjes.lean`、
`examples/julia/05_stieltjes.jl`、`examples/python/05_stieltjes.py`。*

---

上一章：[04 外测度与测度的扩张](04-extension.md) · 下一章：[06 测度的逼近](06-approximation.md)
