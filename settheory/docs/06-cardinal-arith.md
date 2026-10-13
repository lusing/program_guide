# 06 · 基数算术：κ^λ、连续统假设与 König

> 加法与乘法是平凡的；一切戏剧性都在幂运算。——Jech §6

本章覆盖 Jech §6：无穷和与积（引理 6.3-6.4）、König 定理与
四大推论、连续统函数与 Easton 定理、Bukovský-Hechler、gimel
函数三分支、Hausdorff 公式与定理 19（ℵ_α^ℵ_β 的归纳计算）。

## 6.1 无穷和与积：定义即公理账单

Σᵢ κᵢ = |⋃ Xᵢ|（两两不交族）；Πᵢ κᵢ = |Π Xᵢ|（函数族）。
Coq 通道（`examples/coq/Ch06_cardarith.v`）把"积"直接落在类型论
的依赖函数类型上，并分离了构造性方向与公理方向：

```coq
Definition card_prod {I : Type} (X : I -> Type) : Type :=
  forall i : I, X i.

Lemma prod_empty_if {I : Type} (X : I -> Type) :
  (exists i, X i -> False) -> (card_prod X -> False).
Proof.
  intros [i Hi] f. apply Hi. apply f.
Qed.

(* 反方向（全非空 ⟹ 积非空）就是选择公理 *)
```

"某因子空则积空"是构造性的（把 f 喂给空因子）；反方向
"全非空则积非空"**就是 AC 的积形式**——数学家随手写
"Π Xᵢ ≠ ∅"时付出的公理账单。

引理 6.3（无穷和的坍缩）：λ 无穷、κᵢ > 0 时 Σᵢ<λ κᵢ =
λ · sup κᵢ。推论——**奇异基数的刻画**：κ 奇异 ⟺ κ =
Σᵢ<λ κᵢ（λ < κ，每个 κᵢ < κ）。引理 6.4（非降序列的积）：
Πᵢ<λ κᵢ = (sup κᵢ)^λ——证明用 λ×λ ≈ λ 的划分（第 03 章
γ 配对函数再现）。

## 6.2 König 定理：不等式的总引擎

**定理 17（König）** κᵢ < λᵢ（i ∈ I）⟹ Σκᵢ < Πλᵢ。

*证明*：取 τᵢ 使 |τᵢ| = λᵢ。任何 Zi ⊆ Πτᵢ（|Zi| ≤ κᵢ）
的**投影** Si = {f(i) : f ∈ Zi} 都是真子集（|Zi| < |τᵢ|）。
取 f(i) ∉ Sᵢ 逐坐标逃逸——f 不属于任何 Zi，故 ⋃Zi ≠ Πτᵢ。∎

**四大推论**：
1. Cantor（κ < 2^κ）：取 κᵢ = 1、λᵢ = 2；
2. **cf(2^ℵα) > ℵα**（对角线的共尾形式）；
3. cf(ℵ_ω₁... 型的推广）；
4. **κ^cf κ > κ**（第 03 章定理 9 的升级）。

机器化分工。**Coq** 给出有限版的完整证明（零公理）：

```coq
Lemma konig_finite_shadow :
  forall (a b : nat -> nat) (n : nat),
    (forall i, i < n -> a i < b i) ->
    (forall i, i < n -> 1 < b i) ->
    1 <= n ->
    sum a n < prodb b n.
```

证明分两支（部分和为零/为正），为正支用归纳假设 + 乘法单调
放大收尾。注意前提 bᵢ ≥ 2 不可去：Jech 指出 1+1 > 1·1 失败
（有限域的边界案例）。**Prolog** 通道把对角逃逸做成可执行
程序（`examples/prolog/06_konig.pl`）：

```prolog
escape(X1, X2, X3) :-
    dom1(X1), dom2(X2), dom3(X3),
    \+ cover1(X1).
```

三个坐标（b=[2,3,4]）、每坐标部分覆盖（a=[1,2,3] 的投影），
逃逸点 18 个——"Πb − Πa 的差集里每个点都是某个覆盖到达不了
的"。**Julia** 验证有限版不等式（Σ=6 < Π=24 等）。

**Lean** 锚点（`examples/lean/Settheory/Ch06CardArith.lean`）：

```lean
example {n : ℕ} (hn : 2 ≤ n) : (n : Cardinal) ^ ℵ₀ = 𝔠 :=
  Cardinal.nat_power_aleph0 hn

example : ℵ₀ ^ ℵ₀ = 𝔠 := Cardinal.aleph0_power_aleph0

example : 𝔠 ^ ℵ₀ = 𝔠 := Cardinal.continuum_power_aleph0
```

指数律的三个稳态：n^ℵ₀ = ℵ₀^ℵ₀ = 𝔠^ℵ₀ = 𝔠——连续统在
可数幂下封闭（习题 6.3-6.5 的官方形态）。König 推论 4 的
可证特例：

```lean
example : ℵ₀ < ℵ₀ ^ ℵ₀ := by
  rw [Cardinal.aleph0_power_aleph0]
  simpa using Cardinal.cantor ℵ₀
```

**Isabelle/ZF** 的 CardinalArith 生态（`ST06/CardArith.thy`）：
cadd/cmult 的交换结合分配 + 定理 8 的等势版：

```isabelle
thm InfCard_square_eqpoll    (* InfCard(K) ⟹ K × K ≈ K *)

lemma countable_square: "nat × nat ≈ nat"
  by (rule InfCard_square_eqpoll [OF InfCard_nat])
```

（实测坑：ZF 库的"κ·κ = κ"以**等势**形态 `K × K ≈ K` 存在，
基数码 `K ⊗ K = K` 的形态不存在——`⊗` 需要良序假设的翻译。）

## 6.3 连续统函数：Easton 的自由度

Cantor 给下界（2^κ > κ），König 给共尾下界（cf(2^κ) > κ），
单调性 (6.11) 给第三条。**Easton 定理**：对正则基数，这三条
就是 ZFC 能证明的全部限制——正则域上的连续统函数可以"几乎
任意"（只需满足单调 + cf 条件）。奇异基数的情形深刻得多
（Jensen 覆盖引理：若 0# 不存在，奇异处的值被正则值决定——
第 33 章伏笔）。

Julia 通道做了 Easton 自由度的数值体验（`06_cardarith.jl`）：
候选一 F(κ) = 2^κ（CH 模式）与候选二 F(κ) = 4^κ（暴走模式）
**同样合法**——单调性检查通过即可。"ZFC 证明不了其他限制"
的机器侧影就是：任何满足检查的候选都对应某个力迫扩张
（第 25 章的正题）。

**Bukovský-Hechler（定理 18）**：奇异 κ 处若连续统函数终常值
（2^γ = 2^γ₀ 对 γ₀ ≤ γ < κ），则 2^κ = 2^γ₀。引理 6.5 的
公式 2^κ = (2^<κ)^cf κ 配合 cf κ ≤ γ₀ 即得。**gimel 函数**
☞(κ) = κ^cf κ 是全部戏剧的主角：(6.15) 三分支说连续统函数
完全由 ☞ 决定。Agda 通道（`Ch06_gimel.agda`）给出 ☞ 的有限
侧影——有限序数 cf 恒 1，gimel 退化为恒等（κ^1 = κ）；
无穷域的必然膨胀（κ < κ^cf κ）与有限域的免费坍缩恰成对照。

## 6.4 幂运算：Hausdorff 链与定理 19

正则 κ 的幂：λ < κ 时 κ^λ = sup{μ^λ : μ < κ}（每个函数
有界）。后继基数的 **Hausdorff 公式**（6.18）。一般情形由
定理 19 的归纳三分支收尾。Python 通道（`06_cardarith.py`）
实现了分支判定的规则引擎：ℵ_α^ℵ_β 依 (α ≤ β)、
sup{ℵ_γ^ℵ_β} 与 ℵ_α 的关系走 (i)/(ii)/(iii)，并演算
Hausdorff 链的实例（ℵ_1^ℵ_0 = ℵ_1、ℵ_2^ℵ_1 = ℵ_2、
ℵ_ω^ℵ_0 = ℵ_ω、ℵ_ω^ℵ_1 走分支 iii）。附带一个元教训：
cf(2^κ) > κ 的有限代理（倍增逼近 2^n 需 log n 步 ≤ n）与
无穷断言方向**相反**——有限直觉在这里系统性地误导。

**GCH**（2^ℵ_α = ℵ_{α+1}）在此正式定义。它与 CH 一样独立
于 ZFC（Gödel 的 L 满足 GCH——第 13 章；Cohen/Easton 破坏
它——第 20、25 章）。

## 6.5 习题精选

1. **（纸笔）** 习题 6.1/6.2：无穷和/积对载体选择的独立性
   （AC 的使用点）。
2. **（机器）** König 有限版的边界：取 b = [1, 2]（含 1）
   验证 1+1 > 1·1 失败——前提 bᵢ ≥ 2 的必要性（Coq/Julia）。
3. **（纸笔）** 习题 6.3-6.5：ℵ₀^ℵ₀ = n^ℵ₀ = 2^ℵ₀ 的互推。
4. **（纸笔）** 习题 6.6：2^ℵ_α = ℵ_{α+β} 对一切 α ⟹ β < ω
   （Bukovský-Hechler 的应用）。
5. **（机器）** gimel 表：对 ℵ_ω、ℵ_{ω₁} 计算 ☞ 的分支归属
   （Python 规则引擎）。

---

上一章：[05 选择公理](docs/05-choice.md) · 下一章：[07 滤子与理想、club 与静止集](docs/07-filters.md)
