# 07 · 滤子与理想：club 与静止集

> 静止集的哲学：它们大得任何闭无界集都躲不开，却又瘦得可以被
> 拆成 κ 块。——§7 的戏剧

本章覆盖 Jech §7：滤子与理想的公理与对偶、主滤子/Fréchet/
超滤（Tarski 定理 21）、κ-完备性、约化积、闭无界集（club）、
对角交（引理 7.5）、静止集、Fodor 定理（定理 22）、Solovay
分裂（引理 7.6）、Mahlo 基数。

## 7.1 滤子：公理与三例

滤子 F ⊆ P(S)（Jech (7.1)）：S ∈ F；∅ ∉ F；对交封闭；对
（S 内的）超集封闭。理想是对偶概念（0 ∈ I；对并封闭；对子集
封闭）；F 与 I = {S − X : X ∈ F} 互为**对偶**。

三例：平凡滤子 {S}；**主滤子** {X ⊆ S : X₀ ⊆ X}；**Fréchet
滤子** {X ⊆ S : S−X 有限}（非主）。Coq 通道（`examples/coq/Ch07_filters.v`）
把公理做成谓词族的 Record：

```coq
Definition Filter_axioms {A : Type} (F : (A -> Prop) -> Prop) : Prop :=
  (forall X, F X -> forall Y, F Y -> F (fun a => X a /\ Y a))
  /\ (forall X Y, (forall a, X a -> Y a) -> F X -> F Y).

Definition principal {A : Type} (X0 : A -> Prop) : (A -> Prop) -> Prop :=
  fun X => forall a, X0 a -> X a.
```

主滤子与"两滤子的交仍是滤子"（引理 7.1a 的两元版）都被完整
验证——注意第二个分支的教训：`apply HF2` 时函数变量 X 无法从
目标反推，必须显式 `apply (HF2 X Y HXY)`。

Prolog 通道（`examples/prolog/07_filter.pl`）是**判定器**：
4 元论域上枚举全部子集（`subseq` 的有限生成——无限生成器是
栈爆陷阱），逐条检查公理：

```prolog
filter_axioms(F) :-
    universe(S),
    all_subsets(F, S),
    contains(F, S),                  % S ∈ F
    \+ contains(F, []),              % ∅ ∉ F
    forall((member(X, F), member(Y, F)),
           (inter(X, Y, Z), contains(F, Z))),   % 交封闭
    forall((member(X, F), subseq(Y, S), subsum(X, Y)),
           contains(F, Y)).                      % 超集封闭
```

运行结果的教学点：主滤子 {X : a ∈ X} 是滤子且是超滤（有限域
上主超滤）；而 {X : |X| ≥ 3} **不是**滤子——{a,b,c}∩{a,b,d}
= {a,b} 掉了出去。**余有限滤子只在无限域成立**：Fréchet 的家
在无穷那边。

Isabelle/ZF 侧（`ST07/Filters.thy`）在 ZF 内核手工构建滤子
理论（ZF 库没有——它是 HOL 的资产）：`IsFilter` 的定义性
验证（主滤子 `principal_is_filter`）与对偶理想的完整 Isar 证明
（`dual_ideal_is_ideal`——三个分量逐个攻破，其中"A ⊆ S−Y"
的元素级证明展示了闭包推理的实态）。

## 7.2 超滤：Tarski 定理与 Zorn

**超滤**：∀X ⊆ S，X 或 S−X 恰一在 U 中（(7.9)）。**引理 7.2**
超滤 ⟺ 极大滤子；**定理 21（Tarski）**：每个滤子可扩成超滤
——对滤子的包含链用 Zorn（链并是滤子=上界）。

Lean 通道（`examples/lean/Settheory/Ch07Filters.lean`）用
mathlib 官方：

```lean
example {s : Set ℕ} : s ∈ (cofinite : Filter ℕ) ↔ sᶜ.Finite :=
  mem_cofinite

example {α : Type} (f : Filter α) [f.NeBot] :
    ∃ u : Ultrafilter α, (u : Filter α) ≤ f :=
  f.exists_ultrafilter_le

example {α : Type} (u : Ultrafilter α) (X : Set α) :
    X ∈ (u : Filter α) ∨ Xᶜ ∈ (u : Filter α) :=
  u.mem_or_compl_mem X
```

三行分别是 Fréchet 的刻画（cofinite 滤子）、Tarski 的机器
形态（`exists_ultrafilter_le`：Zorn 的滤子版）、超滤两分性。
注意 mathlib 的滤子约定：`u ≤ f` 表示 u **更细**——与集合论
的"扩张"方向相反，这是两个社区的历史分歧。

非主超滤的存在：扩展 Fréchet 滤子的超滤必非主。**可数完备
非主超滤**是否存在是集合论的深渊——它蕴含不可达基数（第 29
章正题：可测基数）。习题 7.14 提示了 ω 上的不可能性：f(n+1)
= n 是 regressive 的，正规滤子在 ω 上不存在。

## 7.3 club：闭无界集的运算

κ 正则不可数。C ⊆ κ **闭无界**（club）：对长度 < κ 的递增
序列封闭（闭）；在 κ 中无界。三个层次的封闭性：

- **引理 7.3** 两个 club 的交是 club——交替提升构造（α₀ <
  β₁ ∈ C, β₁ < β₂ ∈ D, …的极限双属于）；
- **引理 7.4** < κ 个 club 的交是 club——κ-完备性（正则性
  在此进场：序列的极限仍在 κ 内）；
- **引理 7.5** **对角交** Δ{C_α} = {ξ : ξ ∈ C_α ∀α < ξ} 是
  club——club 滤子的**正规性**。

club 滤器（club 生成的滤器）是 κ-完备正规滤子，包含所有尾段
——且是最小的（引理 7.7）。Julia 通道（`examples/julia/07_club.jl`）
跑交替提升与对角交的数值引擎：

```julia
function alternating_limit(C::Vector{Int}, D::Vector{Int}, alpha::Int, steps::Int)
    x = alpha
    for n in 1:steps
        x = minimum(filter(c -> c > x, C))   # 跳进 C
        x = minimum(filter(d -> d > x, D))   # 再跳进 D
    end
    return x
end
```

10 倍数与 7 倍数的交替提升 8 步到 84——本轮终于 D（7 的
倍数），**无穷交替的极限点才双属于 C∩D**（引理 7.3 的精确
语义）。对角交用尾段化构造（C_α = [1,α] ∪ (α:3:100)），Δ
非空且趋于全 3 倍数层。

Agda 通道（`examples/agda/Ch07_club.agda`）实现**闭性检查器**
（club 的可判定内核）：

```agda
member? : ℕ → List ℕ → Bool
member? n [] = false
member? n (x ∷ xs) with (n ≟ x)
... | yes _ = true
... | no  _ = member? n xs

is-closed-in : List ℕ → ℕ → Bool
```

断言 `{奇数} 在 [0,10) 不闭 ≡ false` 由 `refl` 直接验证——
偶数 2 被 1、3 逼近而缺席，检查器报警。**闭性是可判定的，
无界性与平稳性是超穷的**——club 概念的可计算边界。

## 7.4 静止集与 Fodor

S ⊆ κ **静止**（stationary）：与每个 club 相交。等价：S 在
club 滤器中"正测度"。例：{α < κ : cf α = ω} 静止。

**定理 22（Fodor）** 平稳集上的 regressive 函数（f(α) < α）
在某平稳子集上常数。

*证明*：反证每条纤维 {α : f(α) = γ} 都 thin，取 club C_γ
避开它；对角交 C = Δ{C_γ} 是 club，S₀ ∩ C 非空——但其中的
α 满足 f(α) ≠ γ 对一切 γ < α，即 f(α) ≥ α，与 regressive
矛盾。∎

Fodor 的数值影子（Julia）：f(n) = 最大素因子（regressive，
因为最大素因子 ≤ n/2 当 n 合成），纤维高度集中——f(n)=13 的
纤维 81 个（素因子集中于小值域）。"regressive ⟹ 大常数段"
的离散前兆。

**引理 7.6（Solovay 分裂）** 每个正则不可数 κ 是 κ 个两两
不交平稳集的并。构造：W = {α : cf α = ω}，每个 α 配收敛
序列 (aⁿ_α)；关键步：存在固定 n 使 {α : aⁿ_α ≥ γ} 对一切
γ 平稳（否则对角化矛盾）；然后 f(α) = aⁿ_α regressive，Fodor
给出平稳常数段 S_γ'，不同 γ' 的段不交，κ 个 γ' ⟹ κ 块。
Python 通道（`examples/python/07_fodor.py`）演练分裂内核：
按最小素因子分片时，片 2 占了压倒性多数——不同素因子的片
两两不交，正是 Solovay 构造的形状。

club 滤器**不是**超滤：{α : cf α = ω} 与 {α : cf α = ω₁}
都平稳（κ > ω₁ 时）；κ = ω₁ 的分裂需要 AC（习题：无 AC 时
ω₁ 的分裂不成立——大基数的伏笔）。

## 7.5 Mahlo 基数

不可数不可分 κ 之下，强极限基数集是 club（1, 2^λ, 2^(2^λ)…
的极限链）；若 κ 是最小不可达，其下全部强极限都奇异（正则者
稀薄）。**Mahlo**：正则基数之下平稳——比"第 κ 个不可达"
严格更强（习题 7.16：最小的"自己是第 κ 个"不可达不是 Mahlo，
f(α) = 第 α 个不可达 是 regressive 的）。Mahlo 是大基数阶梯
的第一级（第 29 章续）。

## 7.6 习题精选

1. **（纸笔）** 习题 7.1：有限集上的滤子皆主。
2. **（纸笔）** 习题 7.6：超滤对并的素性（X ∪ Y ∈ U ⟹ X ∈
   U 或 Y ∈ U）。
3. **（机器）** Prolog 判定器的扩展：加入 κ-完备性检查
   （对 < κ 个成员的交封闭）。
4. **（纸笔）** 习题 7.8/7.9：正规函数的不动点集是 club；
   f"α ⊆ α 的点集是 club（Fodor 的"安全岛"形态）。
5. **（纸笔）** 习题 7.14：ω 上无非主正规滤子（f(n+1)=n
   的反例）。

---

上一章：[06 基数算术](docs/06-cardinal-arith.md) · 下一章：[08 奇异基数、共尾性与不可达](docs/08-singular.md)
