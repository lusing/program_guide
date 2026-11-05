# 第 21 章 收官

> 原书停在第 20 章。这一章是教程自己的收官。
> 它给出一条阅读路线，并让七个通道沿这条路线再核对四个标记：精确的有理数、超过任意实数的自然数、可以拆开再拼回的误差，以及作为序列的几何级数。
> 连续性、导数、积分和函数序列仍然留在后面的课里。

## 21.1 三条地基

整套教程站在三样东西上。实数带来上确界、阿基米德性质和完备性。拓扑用邻域、开闭集和紧集说话。序列用 $\varepsilon$ - $N$ 定义极限，柯西序列、子序列和上极限都从这里长出来。级数是部分和组成的序列，所以它用的仍是序列的定理，再添上比较和凝聚这两件级数自己的工具。

读的时候按这个顺序走：先让实数站稳，再让空间里的开集和紧集有定义，然后才谈序列，最后把级数看成一种序列。跳过前面直接背级数判别法，判别法里的 $\varepsilon$ 会没有着落。

## 21.2 阅读路线

二十二篇按这个顺序读。每篇自包含，文末可以回到目录。

预备三篇对应原书第 1 章到第 3 章。00 说明浮点为什么不够，分析要从实数的定义开始。01 是命题、量词，以及反例、逆否、反证、归纳和直接证明。02 是子集、并交补和德摩根律。

实数三篇对应原书第 4 章和第 5 章。03 是上界、上确界和最小上界性。04 是域公理和只靠公理推出的算术，这是原书第 5 章的前半。05 是阿基米德性质、有理数稠密和正数开方，这是后半。

空间与拓扑对应原书第 6 章到第 13 章，教程章号与原书相同。06 是复数，以及 $\mathbb{R}^k$ 的内积与范数。07 是单射、满射和双射。08 是可数与不可数。09 是度量、邻域、极限点、开集与闭包。10 是开集和闭集的运算。11 是紧集。12 是海涅–博雷尔定理：在 $\mathbb{R}^k$ 中，紧当且仅当闭且有界。13 是完备集、康托尔集和区间的连通性。

序列与级数对应原书第 14 章到第 19 章。14 是 $\varepsilon$ - $N$ 收敛。15 是极限的四则运算、子序列和 Bolzano–Weierstrass 定理。16 是柯西准则和单调有界则收敛。17 是发散到正负无穷，以及上极限和下极限。18 是夹逼定理，以及 $\frac{1}{n^p}$ 、 $n^{1/n}$ 和 $|x|<1$ 时的 $x^n$ 。19 是部分和、比较判别、几何级数、凝聚判别和 p 级数。

20 把每一章后来反复用的那一条技巧收在一处，从要证的结论往回推。原书正文到那里结束。

已经熟悉集合的读者可以从 03 进入。想直接看序列，仍然要先有 03 到 05 的实数，以及 09 的邻域，然后从 14 读到 19。20 适合在全部读完之后当作检索。根值判别、比值判别、数 $e$ 、 $\pi$ 和泰勒级数，原书只点了名字，教程没有证明。

## 21.3 四个标记

收官再走四个已经证过的事实。它们按阅读顺序排列：先离开浮点，再确认自然数够用，然后把一个 $\varepsilon$ 拆开，最后把一条级数算完。

第一个标记回到导言里的对照。浮点把 $0.1+0.2$ 算成一个靠近 $0.3$ 的数。有理数不舍入。三个 $\frac{1}{3}$ 加起来就是 $1$ 。

```lean
theorem thirds : (1 : ℝ) / 3 + 1 / 3 + 1 / 3 = 1 := by
  norm_num
```

`(1 : ℝ)` 把 $1$ 放进实数。三次除以 $3$ 再相加， `norm_num` 得到右边的 $1$ 。

```isabelle
lemma thirds: "(1::real) / 3 + 1 / 3 + 1 / 3 = 1"
  by simp
```

Isabelle 用 `simp` 做同一件算术。Coq 把等式交给 `lra` 。

```coq
Lemma thirds : 1 / 3 + 1 / 3 + 1 / 3 = 1.
Proof.
  lra.
Qed.
```

Python 用 `Fraction` ，三次 `Fraction(1, 3)` 相加等于整数 $1$ 。Julia 写成 `1//3 + 1//3 + 1//3 == 1//1` 。Prolog 每次相加都用新的有理数， `rdiv(1, 3)` 算三次，分别叫 `T1` 、 `T2` 、 `T3` ，和放在 `Sum3` 里，与 $1$ 比较。这四个名字只出现在这一次 `verify` 中。

Agda 这一章停留在自然数。三个 $1$ 相加等于 $3$ ，这是三个三分之一的分子在相加，还不是有理数等式本身。

```agda
thirds : 1 + 1 + 1 ≡ 3
thirds = refl
```

`refl` 表示两边按自然数加法的定义已经相同。

第二个标记是阿基米德性质里最常用的那句：任意实数后面还有自然数。这里的实数是 $5$ ，见证是 $6$ 。

```lean
theorem past_five : ∃ n : ℕ, (5 : ℝ) < n :=
  exists_nat_gt 5
```

`exists_nat_gt` 对每个实数给出一个更大的自然数。Isabelle 的名字是 `reals_Archimedean2` ， `of_nat` 把自然数送进实数。

```isabelle
lemma past_five: "\<exists>n::nat. (5::real) < of_nat n"
  by (rule reals_Archimedean2)
```

Coq 只核对 $5<6$ 。Agda 用后继： `n<1+n 5` 就是 $5<6$ 。Python、Julia、Prolog 打印 `6 is past 5` 。Prolog 里的变量叫 `Six` 和 `Five` 。

第三个标记是误差预算。收敛定义对每一个正数都成立，所以 $\varepsilon$ 可以换成 $\frac{\varepsilon}{2}$ 。两半加回去仍是 $\varepsilon$ 。

```lean
theorem eps_split (ε : ℝ) : ε / 2 + ε / 2 = ε := by
  ring
```

`ring` 只做算术。用进收敛定义时，再要求 $\varepsilon>0$ ，于是每一半仍是正数。Coq 把 $\varepsilon$ 取成 $1$ ，证明 $\frac{1}{2}+\frac{1}{2}=1$ 。Agda 用自然数 $1+1=2$ ， `halves = refl` 。Prolog 用 `Half` 和 `Whole` ： `rdiv(1, 2)` 加两次等于 $1$ 。

第四个标记是级数。公比 $\frac{1}{2}$ 从 $n=0$ 加起，和是 $\frac{1}{1-\frac{1}{2}}=2$ 。这个闭式是部分和极限算出来的结果。

```lean
theorem geometric_sum : ∑' n : ℕ, ((1 : ℝ) / 2) ^ n = 2 :=
  Realanalysis.Ch19.half_series
```

`half_series` 是第 19 章已经证过的几何级数求和。这里再调用一次，确认收官时这条级数仍然是那条序列。

```isabelle
lemma geometric_sum: "suminf (\<lambda>n. ((1::real) / 2) ^ n) = 2"
proof -
  have "suminf (\<lambda>n. ((1::real) / 2) ^ n) = 1 / (1 - 1 / 2)"
    by (rule suminf_geometric) simp
  then show ?thesis by simp
qed
```

`suminf_geometric` 要求公比的范数小于 $1$ 。 `simp` 确认 $\left|\frac{1}{2}\right|<1$ ，并给出 $\frac{1}{1-\frac{1}{2}}$ ，下一步化成 $2$ 。Coq 直接证明这个闭式等于 $2$ 。Python 写 `1 / (1 - Fraction(1, 2))` 。Prolog 的变量叫 `Geo` ，写成 `rdiv(1, rdiv(1, 1) - rdiv(1, 2))` 。

## 21.4 七通道对照

| 标记 | Lean | Isabelle | Coq | Agda | 计算三通道 |
|------|------|----------|-----|------|------------|
| 三个 $\frac{1}{3}$ | `norm_num` | `simp` | `lra` | $1+1+1=3$ | 有理数等于 $1$ |
| 超过 $5$ | `exists_nat_gt` | `reals_Archimedean2` | $5<6$ | `n<1+n` | $6>5$ |
| 两半拼回 | `ring` | `simp` | $\frac{1}{2}+\frac{1}{2}=1$ | $1+1=2$ | 有理数相加 |
| 公比 $\frac{1}{2}$ | `half_series` | `suminf_geometric` | $\frac{1}{1-\frac{1}{2}}=2$ | — | 同一闭式 |

Agda 没有做几何闭式。三个自然数相加是分子的核对，有理数等式在 Lean、Isabelle、Coq 和三个计算通道里。

## 21.5 本章验证清单

- `examples/lean/Realanalysis/Ch21Wrapup.lean`：四个标记，几何级数调用第 19 章。
- `examples/isabelle/RA21/Wrapup.thy`：同一批四个等式，几何和先写成 $\frac{1}{1-\frac{1}{2}}$ 。
- `examples/coq/Ch21_wrapup.v`：四个等式都交给 `lra` 。
- `examples/agda/Ch21_wrapup.agda`： $1+1+1=3$ ， $5<6$ ， $1+1=2$ 。
- `examples/julia/21_wrapup.jl`、`examples/python/21_wrapup.py`、`examples/prolog/21_wrapup.pl`：四个标记的有理数核对。Prolog 用 `rdiv` 。

复验：`pwsh -NoProfile -Command '& ./build.ps1 -Chapter 21'`。

## 21.6 教程到这里写完

原书没有第 21 章。二十二篇教程到这里为止。后面若要读连续性，入口仍是实数、邻域和序列。

上一章：[20 总结](20-summary.md) · [返回目录](../README.md)
