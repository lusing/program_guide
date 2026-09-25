# 46 · HOL-Analysis 入门

对应示例：`../examples/T46_analysis_intro.thy`

## 46.1 一句话概括

分析世界的正门是 `Complex_Main`（HOL 镜像自带，零额外构建成本
——实测 7 秒通过）。通用语是**滤子**（filter）：极限、连续、
导数全部用 `(f ⟶ L) F` 一个动词表达。

## 46.2 极限入门双例

```isabelle
lemma const_lim: "((λn. (5::real)) ⟶ 5) sequentially"
  by (rule tendsto_const)

lemma poly_lim: "((λx. x * x) ⟶ a * a) (at a)"
  by (intro tendsto_intros)
```

`at x`（邻域）、`sequentially`（自然数滤子）、`at_right`、
`at_infinity` 是常用滤子四大件。

## 46.3 连续

```isabelle
lemma sq_cont: "continuous_on UNIV sq"
  unfolding sq_def by (intro continuous_intros)
```

`continuous_on A f`（集合上）与 `continuous (at x) f`（一点处）
是两个谓词，桥接用 `at_within`。

## 46.4 导数

```isabelle
lemma sq_deriv: "DERIV sq x :> 2 * x"
  unfolding sq_def by (metis DERIV_ident mult_2 DERIV_mult)
```

`derivative_intros` 对多层复合好用；裸乘积 `x * x` 有时推不动
（实测 `auto intro!` 失败），metis 配 `DERIV_mult`/`DERIV_ident`
是稳兜底（注意 metis 可能慢——本例秒级，复杂目标换手搓）。

## 46.5 IVT

```isabelle
lemma crosses_zero:
  assumes "continuous_on {0..1} f" "f 0 ≤ 0" "0 ≤ f 1"
  shows "∃x∈{0..1}. f x = (0::real)"
  using assms by (meson IVT')
```

带撇号家族分方向：`IVT'` 要求 `f a ≤ 0 ≤ f b`。

## 46.6 实测边界：Complex_Main ≠ 全量 Analysis

`find_theorems has_integral` 在 Complex_Main 里**零结果**——
Henstock–Kurzweil 积分住在 **HOL-Analysis 会话**
（`ident_has_integral`、`integral_unique`），不在导入宇宙里。
要用积分：理论放 HOL-Analysis 父会话（多一次堆构建），或像
本教程在 Complex_Main 内完成极限/连续/导数主线。
滤子/拓扑/连续的基础设施两边共享。

## 46.7 坑位清单（实测）

1. 类型不写 `real` 就没有分析：`1 / n` 在 nat 上是整除。
2. `continuous_on` vs `continuous (at _)`：混用点 `at_within` 桥接。
3. `DERIV` 的 `:>` 三件套是一个语法单元。
4. IVT 撇号分方向，拿 `IVT` 硬套方向反了证不出。
5. 积分不在 Complex_Main（46.6）——以为随手就有，实测 undefined。
6. 长箭头 `\<longlongrightarrow>` 是语法；ASCII 环境写转义。

## 46.8 与其他章的接口

- 第 53 章 ε-δ：滤子定义的裸展开。
- 第 45 章 HOL-Library：Complex_Main 也从那里借了不少。
- 第 15 章良基：`wf` 在拓扑侧的表亲是紧性（文档节）。
