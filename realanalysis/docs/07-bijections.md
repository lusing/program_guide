# 第 07 章 双射

> 对应原书第 7 章。拓扑学关心集合与元素的关系；可数性又要用“能否
> 与自然数一一对应”来分类无限集。本章把函数写回集合语言：定义域与
> 上域、像与原像、逆、满射/单射/双射，并证明双射恰好就是可逆映射。
> 下一章用这些工具区分可数与不可数。

## 7.1 定义 7.1：函数

**定义。** 若集合 $A$ 的每个元素 $x$ 都在集合 $B$ 中有**唯一**对应的
$f(x)$ ，则关系 $f$ 是函数（映射），记作

$$f : A \to B,\qquad f : x \mapsto f(x).$$

$A$ 叫定义域，$B$ 叫上域（codomain）。只写 $f(x)=x^2$ 而不写定义域与
上域会产生歧义：它可能是 $\mathbb{R}\to\mathbb{R}$ ，也可能是
$\{1,2,3\}\to\{1,4,9\}$ 。

两个常见反例帮助钉住“唯一对应”：

- 图上一个点连向 $B$ 的两个不同点——不是函数。
- “$f(x)=\sqrt{x}$ 同时取正负根”不是函数；分别规定
  $+\sqrt{x}$ 与 $-\sqrt{x}$ 才各自是函数。

形式化通道里，类型系统已经强制“每个输入恰好一个输出”：Lean / Isabelle /
Coq / Agda 的 `A → B` 本身就是函数。需要另写的是像、原像与单满性。

## 7.2 像、值域与原像

**定义 7.3.** 对 $E\subset A$ ，像

$$f(E)=\{f(x)\mid x\in E\}.$$

值域是 $f(A)$ 。注意值域是上域的子集，不一定等于上域。

**例。** $f(x)=x^2$ ，$E=(-3,3)$ ，则 $f(E)=[0,9)$ ；值域是
$[0,\infty)$ 。常值 $f(x)=1$ （定义域 $\mathbb{N}$ ）把 $\{1,2,3\}$ 映成
$\{1\}$ ，值域也是 $\{1\}$ 。

Lean（`examples/lean/Realanalysis/Ch07Bijections.lean`）用集合像算子
`''`：

```lean
example : ((fun _ : ℕ => (1 : ℕ)) '' ({1, 2, 3} : Set ℕ)) = ({1} : Set ℕ) := by
  ext y; simp
```

Isabelle 的 `` ` ``、Coq / 计算通道对有限列表做 `map`，同一事实。

**定义 7.5.** 对 $G\subset B$ ，原像

$$f^{-1}(G)=\{x\in A\mid f(x)\in G\}.$$

对单点 $y\in B$ ，写作 $f^{-1}(y)=\{x\in A\mid f(x)=y\}$ ——这是一个
**集合**，不一定是单点。

**例。** $f:\mathbb{Z}\to\mathbb{N}\cup\{0\}$ ，$f(x)=x^2$ 。则
$f^{-1}(\{16\})=\{4,-4\}$ 。单点被映回两个点，所以把“$f^{-1}$ 当成
$B\to A$ 的函数”在这里失败——这正是下一节“可逆”要排除的情形。

Lean：

```lean
example : (fun x : ℤ => x ^ 2) ⁻¹' ({16} : Set ℤ) = ({4, -4} : Set ℤ) := by
  ext x
  simp [mem_preimage, mem_singleton_iff, mem_insert_iff]
  constructor
  · intro h
    have : x ^ 2 = (4 : ℤ) ^ 2 := by norm_num [h]
    exact (sq_eq_sq_iff_eq_or_eq_neg).mp this
  · intro h
    rcases h with rfl | rfl <;> norm_num
```

Isabelle `sq_preimage_16`、Python / Julia / Prolog 在 $\{-5,\ldots,5\}$
上穷举，得到同一集合 $\{4,-4\}$ 。

## 7.3 逆、满射、单射

**定义 7.7.** 若关系 $f^{-1}:B\to A$ 本身是函数，则称它为 $f$ 的逆，
并称 $f$ 可逆。

- $f(x)=x^2$ （$\mathbb{R}\to\mathbb{R}$ ）不可逆：正数有两个平方根。
- $f(x)=2x$ （$\mathbb{R}\to\mathbb{R}$ ）可逆，逆是 $y\mapsto y/2$ 。
- 把 $2x$ 的定义域缩成 $\mathbb{N}$ 后，逆把 $3$ 送到 $3/2\notin\mathbb{N}$ ，
  又不可逆——可逆性依赖定义域与上域的选取。

**定义 7.9（满射 / 映上）。** 每个 $y\in B$ 的原像至少含一个点，即
$f(A)=B$ 。

**定义 7.11（单射 / 一对一）。** 每个 $y\in B$ 的原像至多含一个点，即
$x_1\neq x_2\Rightarrow f(x_1)\neq f(x_2)$ 。

两个方向的“必要但不充分”：

| 情形 | 例子 | 满？ | 单？ | 可逆？ |
|------|------|------|------|--------|
| 满但不单 | $\{1,2\}\to\{1\}$ ，常值 $1$ | 是 | 否 | 否 |
| 单但不满 | $\{1\}\to\{1,2\}$ ，$1\mapsto 1$ | 否 | 是 | 否 |
| 又单又满 | $\mathbb{R}\to\mathbb{R}$ ，$x\mapsto 2x$ | 是 | 是 | 是 |

非满射不可逆（逆对某些 $y$ 无定义）；非单射也不可逆（逆把一点送到
两点）。反过来，满射或单射单独都不够。

Lean 用有限类型把上表钉死：

```lean
example : Surjective (fun _ : Fin 2 => (0 : Fin 1)) := fun y => ⟨0, Subsingleton.elim _ y⟩
example : ¬ Injective (fun _ : Fin 2 => (0 : Fin 1)) := by
  intro h
  have h01 : (0 : Fin 2) ≠ 1 := by decide
  exact h01 (h rfl)

example : Injective (fun _ : Unit => (0 : Fin 2)) := injective_of_subsingleton _
example : ¬ Surjective (fun _ : Unit => (0 : Fin 2)) := by
  intro h
  rcases h (1 : Fin 2) with ⟨_, hf⟩
  cases hf
```

Agda 用 `Bool → ⊤` 与 `⊤ → Bool` 写同一对反例；Isabelle 用
`bool → unit` 与 `unit → bool`；计算通道在有限集合上穷举
`is_injective` / `is_surjective`。

平方非单射、加倍为单射：

```lean
example : ¬ Injective (fun x : ℝ => x ^ 2) := by
  intro h
  have := h (by norm_num : (2 : ℝ) ^ 2 = (-2 : ℝ) ^ 2)
  linarith

example : Injective (fun x : ℝ => (2 : ℝ) * x) := fun _ _ h => by linarith
```

## 7.4 定义 7.13 与定理 7.15–7.16：双射即是可逆

**定义 7.13.** 双射 = 既满射又单射。上域每个点恰好被定义域一个点命中。

**定理 7.15.** $f:A\to B$ 是双射，当且仅当 $f$ 可逆。

证明（→）：满射保证每个 $y\in B$ 至少有一个原像，单射保证至多一个，
于是 $f^{-1}(y)$ 恰好一个点，关系 $f^{-1}$ 是函数。（←）：可逆则
$f^{-1}$ 处处有定义 ⇒ 满射；且 $f^{-1}$ 是函数 ⇒ 每个 $y$ 至多一个
原像 ⇒ 单射。

Lean 把“可逆”写成存在双边逆：

```lean
example {α β : Type*} (f : α → β) :
    Bijective f ↔ ∃ g : β → α, LeftInverse g f ∧ Function.RightInverse g f :=
  bijective_iff_has_inverse
```

加倍与减半：

```lean
example : LeftInverse (fun y : ℝ => y / 2) (fun x : ℝ => (2 : ℝ) * x) := by
  intro x; field_simp
example : Function.RightInverse (fun y : ℝ => y / 2) (fun x : ℝ => (2 : ℝ) * x) := by
  intro y; field_simp
```

**定理 7.16.** 若 $f$ 是双射，则 $f^{-1}$ 也是双射。

填写原书填空的思路：单射 ⇒ 逆是函数且“至多一对一”方向给出逆的
单射性；满射 ⇒ 逆的定义域是整个 $B$ ，且 $A$ 落在逆的值域里；再交换
角色即得逆也是满射。Lean 用 `Equiv.mulLeft₀ 2` 的 `symm.bijective`
给出加倍逆仍是双射；Agda 对布尔否定 `notB` 证明 `notB ∘ notB = id`
且 `notB` 本身双射。

## 7.5 定义 7.17：复合

**定义。** $f:A\to B$ ，$g:B\to C$ ，则

$$(g\circ f)(x)=g(f(x)).$$

复合要求 $f$ 的上域等于 $g$ 的定义域。$f(x)=2x$ ，$g(x)=x^2$ 时
$(g\circ f)(x)=4x^2$ 。双射对复合封闭；函数与其逆按任一顺序复合都是
恒等映射。

```lean
example : (fun x : ℝ => x ^ 2) ∘ (fun x : ℝ => (2 : ℝ) * x) =
    fun x => (4 : ℝ) * x ^ 2 := by
  funext x; dsimp; ring

example {α β γ : Type*} {f : α → β} {g : β → γ}
    (hf : Bijective f) (hg : Bijective g) : Bijective (g ∘ f) :=
  Bijective.comp hg hf

example : (fun y : ℝ => y / 2) ∘ (fun x : ℝ => (2 : ℝ) * x) = id := by
  funext x; dsimp; field_simp
```

Coq 的 `bij_comp`、Agda 的 `bij-comp`、Isabelle 的 `bij_comp` 都是
“单射复合仍单射、满射复合仍满射”的直接展开。计算通道断言
`compose(g,f)` 与 `compose(f,g)` 在样本集上等于恒等。

## 7.6 七通道对照

| 主题 | Lean | Isabelle | Coq | Agda | 计算三通道 |
|------|------|----------|-----|------|------------|
| 像 / 原像 | `''` / `⁻¹'` | `` ` `` / `-`` | 列表 `image`/`preimage` | — | 集合/列表穷举 |
| 单 / 满 / 双 | `Injective` 等 | `inj`/`surj`/`bij` | 自写谓词 | 自写谓词 | 有限穷举 |
| 满不单 / 单不满 | `Fin 2`/`Unit` | `bool`/`unit` | `bool`/`unit` | `Bool`/`⊤` | `{1,2}`/`{1}` |
| 双射⇔可逆 | `bijective_iff_has_inverse` | `inv` + `bij_imp_inv` | 显式 `/2` | `notB` 自逆 | 双边逆断言 |
| 复合封闭 | `Bijective.comp` | `bij_comp` | `bij_comp` | `bij-comp` | `(sq∘mul2)(x)=4x²` |

## 7.7 本章验证清单

- `examples/lean/Realanalysis/Ch07Bijections.lean`：像与原像、单满双、
  双边逆、`Equiv` 逆仍双射、复合与恒等。
- `examples/isabelle/RA07/Bijections.thy`：同上。
- `examples/coq/Ch07_bijections.v`：有限影子 + 命题版单满双与复合。
- `examples/agda/Ch07_bijections.agda`：有限类型上的构造性单满双。
- `examples/julia/07_bijections.jl`、`examples/python/07_bijections.py`、
  `examples/prolog/07_bijections.pl`：有限集合穷举。

复验：`pwsh -NoProfile -Command '& ./build.ps1 -Chapter 07'`。

## 7.8 接下来

双射给出“一样大”的精确定义。下一章引入等价关系与势：有限集的势就是
元素个数；无限集则分成可数与不可数——$\mathbb{Q}$ 可数，$\mathbb{R}$
不可数（Cantor 对角线）。

上一章：[06 复数与欧几里得空间](06-complex.md) · 下一章：[08 可数性](08-countability.md) · [返回目录](../README.md)
