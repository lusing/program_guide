# 10 积分的构造与基本性质

**对应严书 §3.1（pp. 45-49）。**

---

## 10.1 为什么需要新积分

Riemann 积分把定义域切成小区间，对"振动剧烈"的函数力不从心
（Dirichlet 函数处处不 Riemann 可积，尽管简单至极）。Lebesgue 的
翻转是**按函数值分层**：先把只取有限多个值的函数（简单函数）的
积分写成显然的有限和，再对一般函数用单调极限撑上去。这个次序
（先值域后定义域）与测度论的 σ-代数机器严丝合缝——第 07 章的
简单函数逼近定理（2.1.8）正是为此埋的伏笔。

本章按严书 3.1 的三步构造走：**简单函数 → 非负函数 → 一般函数**，
每一步只做一件最小的事，且每一步的良定义性都有明确的代价与支付。

## 10.2 第一步：S⁺ 上的积分

设 (Ω, 𝓕, μ) 为测度空间。S⁺ = 非负简单可测函数全体。对
f = Σᵢ aᵢ I_{Aᵢ}（标准表示：aᵢ ≥ 0 两两不同，Aᵢ = f⁻¹({aᵢ})
构成 Ω 的可测划分），定义

  μ(f) := ∫ f dμ := Σᵢ aᵢ·μ(Aᵢ)。

**良定义性**：值 0·∞ = 0 的约定（第 03 章埋下）使零系数配上无限
测度不再产生歧义；标准表示的唯一性（值域划分唯一）免掉了表示
依赖问题。注意一个初学者常忽略的事实：**μ(f) < ∞ ⟹ μ([f > 0])
< ∞**（非负简单函数的支撑是有限测度集）——严书 3.1.3 注特别
强调它**不能**推广到一般非负可测函数（f = 1 在无限测度空间上
处处正、积分无限；而 f 可积但支撑无限测度的例子在第 12 章的
密度函数里俯拾皆是）。

S⁺ 上的七条基本律（严书 3.1.2）：μ(I_A) = μ(A)；正齐次 μ(af) =
aμ(f)；可加 μ(f+g) = μ(f)+μ(g)；单调 f ≤ g ⟹ μ(f) ≤ μ(g)；
有限差 fₙ ↓ f、μ(f₁) < ∞ ⟹ μ(fₙ) ↓ μ(f)；单调升 fₙ ↑ f ⟹
μ(fₙ) ↑ μ(f)。**最后两条在 S⁺ 内部已经需要测度的连续性**——
可加性的证明用第 03 章的公共加细分解，升列用下方连续。

## 10.3 第二步：非负可测函数

对 f ≥ 0 可测，任取 S⁺ 中的逼近列 fₙ ↑ f（第 07 章 2.1.8 保证
存在），定义

  μ(f) := limₙ μ(fₙ)。

**良定义性**是本步的全部技术内容：若另有 gₙ ↑ f，必须
lim μ(fₙ) = lim μ(gₙ)。关键引理（严书 3.1.2 的 (6) 推广）：
**截断交换**——对任意 m 与 S⁺ 中的 h ≤ f，有
μ(h) = limₙ μ(h ∧ fₙ)（h 被逐步"削顶"到自己的水平）。把 h 取
成 gₘ 再令 m → ∞，两边夹出相等。这个"h ∧ fₙ"的削顶技巧是
S⁺ 内部自洽的核心，机器通道把它逐行验证。

等价的另一刻画：μ(f) = sup{μ(h) : h ∈ S⁺, h ≤ f}——上确界
形式不再需要选择逼近列，且对**任意**非负可测 f（不必 σ-有限
支撑）直接良定义。mathlib 的 `lintegral` 就取这个定义
（`Integral/Lebesgue/Basic.lean:48`，irreducible_def——定义体
不透明，一切性质按 API 调用，正是"良定义性已封箱"的形式化姿态）。

## 10.4 第三步：一般函数与"可积"

f = f⁺ − f⁻（正负部，第 07 章格运算）。若 μ(f⁺) 与 μ(f⁻)
至少一个有限，称 f 的**积分存在**，μ(f) := μ(f⁺) − μ(f⁻)
（∞−∞ 被排除在"存在"之外）。两者皆有限时称 f **可积**，
等价于 μ(|f|) < ∞。复值按 f + ig 分实虚部定义，可积 ⟺ 实虚部
皆可积。

"积分存在但不可积"的缝隙是 ∞−∞ 的避让所：f = 1 − I_{[0,∞)}
型函数在 ℝ 上正负部皆 ∞——任何对它谈"积分值"的企图都是伪装的
∞−∞。全书凡是逐项求和、换序的定理（第 11 章），可积性假设的
全部工作就是堵住这个缝隙。

**a.e. 语义**：积分对 a.e. 相等完全钝感（f = g a.e. ⟹ 两者同时
可积且积分相等）——先对非负情形由 μ 的零测集失明直接验证，一般
情形经正负部继承。反过来，f ≥ 0、μ(f) = 0 ⟹ f = 0 a.e.
（[f > 0] = ⋃ₖ [f > 1/k] 各为零测）。完备化 σ-代数 𝓕_μ 下同样
可积分（a.e. 可测函数有可测版本），严书用"μ-可测"一词统一处理。

## 10.5 基本性质与两件武器

线性与单调性（严书 3.1.6）：αf、f+g（a.e. 有意义时）积分存在且
线性保持；f ≤ g a.e. ⟹ ∫_A f ≤ ∫_A g 对一切 A ∈ 𝓕（**带 A 的
版本**是第 11 章定理的接口形态）。**序反射**（3.1.8）：若
∫_A f ≤ ∫_A g 对一切 A 成立，f、g 可积（或 μ σ-有限），则
f ≤ g a.e.——证明取 A = [f > g] 并用 σ-有限穷竭把 ∞ 拆成有限块，
反例（可数-余可数 σ-代数上的计数式测度）说明 σ-有限不可省。

两件贯穿全书的武器：

1. **Markov 不等式**：f ≥ 0 可测、a > 0，则
   a·μ([f ≥ a]) ≤ μ(f)。（[f ≥ a] 上逐点 a ≤ f，两边积分。）
   概率版 P(X ≥ a) ≤ E[X]/a；p 次版是第 13 章 Chebyshev 的母体
   （mathlib 的 `ChebyshevMarkov.lean` 就是这个家族）。
2. **绝对连续性**：f 可积 ⟹ 对 ε > 0 存在 δ，μ(A) < δ ⟹
   ∫_A |f| < ε。证明用截断：f·I_{[|f| ≤ M]} 有界部分误差 ≤ M·μ(A)
   （选 M 使尾部 ∫_{[|f|>M]} |f| < ε/2），再取 δ = ε/(2M)。
   "积分对小集合钝感"是第 18 章 Fubini 与第 38 章一致可积的
   公共前提。

**习题 3.1.7（L⁰ 距离，通向第 09 章的回桥）**：有限测度空间上，
令 d(f, g) = μ(|f − g| ∧ 1)，则**按此距离收敛 ⟺ 依测度收敛**。
（⟸：μ(|fₙ−f| ≥ ε) ≤ μ(|fₙ−f| ∧ 1 ≥ min(ε,1)) → 0；⟹：对
δ < 1，μ(|fₙ−f| ≥ ε) ≤ (1/min(ε,1))·∫|fₙ−f|∧1——Markov 不等式
的又一次即时应用。）这给依测度收敛装上了**度量骨架**：L⁰ 是
（等价类意义下的）完备度量空间，第 31 章弱收敛的 Portmanteau
检验与第 38 章 Vitali 定理都在这个骨架上工作。"∧ 1"的作用是
把距离截断在有限值——可积性从未被假设，截断承担了一切。

## 10.6 Lean：lintegral 的三步链

mathlib 的 `lintegral`（ℝ≥0∞ 值，`Integral/Lebesgue/Basic.lean:48`
irreducible_def——定义体不透明，一切性质走 API）与 `integral`
（Banach 值 Bochner 积分，第 16 章主角；文件里先 `#check` 正名）
就是三步构造的封箱。`Ch10Integral.lean` 的对齐件（节选）：

```lean
-- S⁺ 的常值元：∫ c dμ = c·μ(Ω)（0·∞ = 0 约定已封箱）
example (c : ℝ≥0∞) : ∫⁻ _, c ∂μ = c * μ Set.univ := lintegral_const c

-- 非负可加：本版 mathlib 已把双边可测的 lintegral_add 降级为内部件，
-- 主推 lintegral_add_left——只需左边可测
example (hf : Measurable f) (g : α → ℝ≥0∞) :
    ∫⁻ x, f x + g x ∂μ = ∫⁻ x, f x ∂μ + ∫⁻ x, g x ∂μ :=
  lintegral_add_left hf g

-- 单调与 a.e. 无关
example (hfg : f ≤ g) : ∫⁻ x, f x ∂μ ≤ ∫⁻ x, g x ∂μ := lintegral_mono hfg
example (h : f =ᵐ[μ] g) : ∫⁻ x, f x ∂μ = ∫⁻ x, g x ∂μ := lintegral_congr_ae h
```

Markov 不等式做**手作**（两行内核）：逐点估计
a·I_{[f≥a]} ≤ f（成员处 a ≤ f、非成员处 0 ≤ f），`lintegral_indicator`
把左边精确积分出来（指示积分 = restrict 上的常值积分 = a·μs），
`lintegral_mono` 收口：

```lean
example (hf : Measurable f) (a : ℝ≥0∞) :
    a * μ {x | a ≤ f x} ≤ ∫⁻ x, f x ∂μ := by
  -- hset : {x | a ≤ f x} = f⁻¹'(Ici a) 可测；hpt : 逐点 a·I ≤ f
  calc a * μ {x | a ≤ f x}
      = ∫⁻ x, {y | a ≤ f y}.indicator (fun _ => a) x ∂μ := by
        rw [lintegral_indicator hset (fun _ => a), lintegral_const,
          Measure.restrict_apply_univ]
    _ ≤ ∫⁻ x, f x ∂μ := lintegral_mono hpt
```

实弹例：[0,1] 上常值 1 的积分恰为 1（`lintegral_const` +
`Real.volume_Ioc` + `restrict_apply_univ` 三连）。写文件踩的坑：
本版 mathlib 的 `Set.indicator_of_not_mem` 已不存在——非成员分支
交给 `simp [hx]`，成员分支 `Set.indicator_of_mem hx` 仍在；以及
`Real.volume` 不是常量名（volume 是 MeasureSpace 记号），取限制
测度要写 `(volume : Measure ℝ).restrict …`。

## 10.7 Isabelle：有限格上的精确账

`MT10/T10_Integral.thy` 在 count_space {0,1} 上把三步构造的账目
逐项算清。第一步的钥匙是 **`nn_integral_indicator`（simp 引理：
指示函数积分 = 测度）**——与 mathlib 的 `lintegral_indicator`
互为镜像：

```isabelle
lemma lintegral_indicator_count:
  "(\<integral>\<^sup>+x. indicator {1::nat} x \<partial>count_space {0,1}) = 1"
  by simp
```

线性与 Markov 件同构：`nn_integral_add`/`nn_integral_cmult` 摊开
组合指示，偏差集 {x. a ≤ I{1} x} = {1} 先手算再入账（0 < a ≤ 1
时的 case 分解，`indicator_def` + if_splits）。初稿在这里翻过
一次心算车（2·1 + 3·1 写成 3，机器报 False）——Isabelle 的
simp 不会替你算算术，只会如实揭发。

## 10.8 数值与逻辑实验

**Julia（`10_integral.jl`）**在原子测度 μ = Σ 2⁻ᵏ δₖ（第 03 章
老朋友）上把三步构造完整复刻：

- S⁺ 层：随机生成 100 个简单函数（随机划分 × 随机权值），验证
  线性（μ(af+bg) = aμ(f)+bμ(g) 精确）与单调；
- 非负层：f(k) = k/2^k 的积分 = Σ k·2⁻ᵏ·2⁻ᵏ = Σ k·4⁻ᵏ = 4/9
  ——截断到 40 项与解析值吻合到 1e-12；比较两种逼近（截断列
  f·I_{k≤n} 与二进削顶列）殊途同归（良定义性的数值版）；
- 一般层：f = f⁺ − f⁻ 分解后差值正确；∫|f| 与可积判据；
- Markov：随机阈值 a 上验 a·μ([f ≥ a]) ≤ μ(f)，记录最紧的一对；
- 绝对连续性：δ-ε 表格（μ(A) < δ ⟹ 尾部积分 < ε），截断阈值 M
  的选取过程可见。

**Python（`10_integral.py`）**：Fraction 精确版同题——Σ k·4⁻ᵏ
算到**精确** 4/9（等比-差分列求和公式核对），Markov 与削顶全部
零舍入；"支撑有限测度 ⟸ 积分有限"在 S⁺ 层的精确验证与在非负层
的**反例**（f ≡ 1/2ᵏ）同台对照。

**Prolog（`10_integral.pl`）**：q(N,D) 有理数算术下的 S⁺ 七条
基本律全套（含两个单调极限条目的有限截断版），交叉相乘做分数
断言。

## 10.9 要点回顾

1. 三步构造各自的技术内核：S⁺ 公共加细；非负层削顶交换
   （μ(h) = lim μ(h ∧ fₙ)）；一般层 f⁺−f⁻ 与 ∞−∞ 避让。
2. "积分存在 ≠ 可积"；a.e. 语义完备；μ(f)=0 ⟹ f=0 a.e.（非负）。
3. 带集合 A 的序反射（σ-有限反例）、Markov 不等式、绝对连续性
   ——后两件是后文大定理的通用弹药。
4. mathlib 侧：lintegral 不可约定义 + API 纪律；integrable_iff_
   lintegral 打通两套积分。

*对应示例：`examples/lean/Measuretheory/Ch10Integral.lean`、
`examples/julia/10_integral.jl`、`examples/python/10_integral.py`、
`examples/prolog/10_integral.pl`。*
