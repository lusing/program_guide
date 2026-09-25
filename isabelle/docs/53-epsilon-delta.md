# 53 · ε-δ 分析基础

对应示例：`../examples/T53_epsilon_delta.thy`

## 53.1 一句话概括

第 46 章用滤子一行一个极限定理；本章反其道而行——**剥掉滤子**，
用裸的 ε-N/ε-δ 定义手工证收敛与连续。这是 Cauchy/Weierstraß
的原教旨分析；看清"一行滤子 = 十行 ε-δ"后，46 章的抽象就不玄了。

## 53.2 收敛的 ε-定义与滤子定义的等价

```isabelle
definition converges_to (infixl "⟿" 50) where
  "s ⟿ L ⟷ (∀e > 0. ∃N. ∀n ≥ N. ¦s n - L¦ < e)"

lemma conv_iff_tendsto: "(s ⟿ L) ⟷ ((s ⟶ L) sequentially)"
  unfolding converges_to_def by (simp add: LIMSEQ_iff)
```

## 53.3 和的极限：ε/2 拼接

```isabelle
lemma conv_add_eps:
  assumes "s ⟿ L" and "t ⟿ M"
  shows "(λn. s n + t n) ⟿ L + M"
```

证明的体力全在拼接：两个 N 取 `max N1 N2`，三角不等式
`abs_triangle_ineq` 把 `¦(s n + t n) - (L+M)¦` 拆成两个
`< e/2` 的和。乘法情形换 `min d1 d2` + 常数界估计——
同一模板的变奏。

## 53.4 一点处连续：ε-δ 的裸形

```isabelle
definition cont_at_eps where
  "cont_at_eps f a ⟷
     (∀e > 0. ∃d > 0. ∀x. ¦x - a¦ < d ⟶ ¦f x - f a¦ < e)"
```

与 `continuous (at a) f` 的等价要过 dist = abs 的化简
（实数上 `dist_real_def`）。46.3 的 `continuous_intros`
内部走的正是这条路的自动化版。

## 53.5 坑位清单（实测）

1. ε-δ 手工证的体力在三角不等式拼接——e/2 拆法对每个算子不同。
2. `LIMSEQ_iff` 这类展开定理的名字在版本间漂移过；
   报 undefined 先 `find_theorems eventually sequentially`。
3. 等价证明在实数上要过 dist=abs 化简。
4. `max N1 N2`（拼"足够大"）与 `min d1 d2`（拼"足够近"）
   是对偶动作，别用反。

## 53.6 与其他章的接口

- 第 46 章 HOL-Analysis：本章是其定义层的展开。
- 第 11 章 nat 算术：∀n≥N 的下标算术是它的远亲。
- 第 50 章：ε-δ 证明是 ND 框架在分析上的实例。
