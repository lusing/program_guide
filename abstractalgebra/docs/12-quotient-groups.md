# 12 商群

**对应原书 §2.6（pp. 121-135）。**

---

## 12.1 把划分变成群

第 10 章的陪集划分 G = ⊔ aH 留下一个悬案：能否让**陪集的集合 G/H
自己变成群**？自然的尝试是 (aH)(bH) = (ab)H——但这有个致命的隐患：
**良定义性**。陪集有多个"名字"（aH = a′H 当 a′⁻¹a ∈ H），若代表元
换了，乘积会不会换？

> **引理 2.112** K ≤ G。K 正规（gKg⁻¹ = K 对一切 g，记 K ◁ G）
> ⟺ 对一切 b：bK = Kb。

> **定理 2.113（商群良定义）** K ◁ G 时，(aK)(bK) := (ab)K 良定义，
> 且 G/K 对此运算成群（单位元 K，逆元 a⁻¹K）。

良定义的验证：设 a′ = a k₁, b′ = k₂ b（用 bK = Kb 换侧），则
a′b′ = a k₁ k₂ b ∈ (ab)K。∎ **正规性不是装饰，是乘法良定义的充要
条件**——这就是"正规子群"这个概念存在的全部理由。非正规的 H 会发生
什么？S₃ 中 H = ⟨(12)⟩：取 (13)H 与 (123)H 相乘，用不同代表元会得到
不同陪集——乘法崩塌。

商群的三个熟悉面孔：
- ℤ/mℤ = ℤ/⟨m⟩（命题 2.103：m 阶加法循环群，生成元 [1]）——第 05 章
  的全部模算术是商群的第一个实例。
- S_n/A_n ≅ {±1}（A_n 指数 2 自动正规，命题 2.97）。
- 推论 2.115：**每个正规子群都是某个同态的核**（π : G → G/K 的核恰为
  K）。正规子群与同态核是同一件事的两个名字。

## 12.2 第一同构定理

> **定理 2.116（第一同构定理）** f : G → H 同态，K = ker f，则
> Φ : G/K → im f，aK ↦ f(a) 是**良定义的同构**。

证明三步：良定义（f(a′) = f(a) 当 a′⁻¹a ∈ ker）、同态（Φ(aK · bK) =
f(ab) = f(a)f(b)）、双射（单：Φ(aK) = 1 ⟹ a ∈ ker ⟹ aK = K）。
连同第二、第三同构定理（定理 2.121/2.122：HK/H ≅ H/(H∩K) 与
(G/K)/(H/K) ≅ G/H）和对应定理（命题 2.123：G/K 的子群 = 含 K 的子群
商出来），构成"商运算的完整语法"。

**应用一：循环群的完全分类**（推论 2.104 + 定理 2.116）：无限循环群
≅ ℤ，n 阶循环群 ≅ ℤ/nℤ——把 f : ℤ → ⟨a⟩, k ↦ a^k 的核（= mℤ，m =
ord a，引理 2.53）代入第一同构定理即得。

**应用二：威尔逊定理**（定理 2.111）：p 素 ⟺ (p−1)! ≡ −1 (mod p)。
证明精华：U(ℤ_p) = 全部 1..p−1；其中只有 ±1 是自身逆元，其余元素
与自己的逆元两两配对相乘为 1，故 (p−1)! ≡ (p−1)·1 ≡ −1。∎

**应用三：φ 的乘法性**（推论 2.131）：(m,n) = 1 ⟹ φ(mn) =
φ(m)φ(n)。群论证明：g : ℤ/mnℤ → ℤ/mℤ × ℤ/nℤ 是同构（CRT 的群论
表述，定理 2.128），限制到单位群上得 U(ℤ_mn) ≅ U(ℤ_m) × U(ℤ_n)，
数元素：φ(mn) = φ(m)φ(n)。∎ 第 05 章 CRT 的"裂解为积"一语成谶。

**应用四：互素阶的循环积**（定理 2.128 + 命题 2.129）：(m,n) = 1 时
ℤ_mn ≅ ℤ_m × ℤ_n；若 a, b 交换且阶互素 m, n，则 ab 的阶恰为 mn。

## 12.3 小群分类：4 阶与 6 阶

> **命题 2.134** 4 阶群恰两个：ℤ₄ 与 Klein 四元群 V = ℤ₂ × ℤ₂。
> **命题 2.135** 6 阶群恰两个：ℤ₆ 与 S₃（后者是第一个非阿贝尔群）。

证明思路是"元素阶只能取 |G| 的因子"（拉格朗日）+ "阶 2 元素自逆"的
组合推理。到 8 阶出现五个群（ℤ₈, ℤ₄×ℤ₂, ℤ₂³, D₄, 四元数群 Q₈），
15 阶只有一个（循环）——"有多少个 n 阶群"从此成为计数组合学的
深水区。

## 12.4 机器验证一：Lean——QuotientGroup 三件套

**文件：`examples/lean/Abstractalgebra/Ch12QuotientGroups.lean`。**
mathlib 的商群记号是 `G ⧸ K`（K : Subgroup G 带 K.Normal 实例），
元素由 `QuotientGroup.mk` 造出（类型标注 `G ⧸ K` 帮 Lean 锁定 K）：

```lean
-- 定理 2.113：乘法陪集的良定义乘法
example {G : Type*} [Group G] (K : Subgroup G) [K.Normal] (a b : G) :
    (QuotientGroup.mk (a * b) : G ⧸ K)
      = (QuotientGroup.mk a : G ⧸ K) * (QuotientGroup.mk b : G ⧸ K) :=
  QuotientGroup.mk_mul K a b

-- 单位元陪集是商群的单位元；逆元陪集 = 陪集的逆
example {G : Type*} [Group G] (K : Subgroup G) [K.Normal] (a : G) :
    (QuotientGroup.mk a : G ⧸ K) * (QuotientGroup.mk 1 : G ⧸ K)
      = (QuotientGroup.mk a : G ⧸ K) := by
  rw [← QuotientGroup.mk_mul K, mul_one]

example {G : Type*} [Group G] (K : Subgroup G) [K.Normal] (a : G) :
    (QuotientGroup.mk a ⁻¹ : G ⧸ K) = (QuotientGroup.mk a : G ⧸ K) ⁻¹ :=
  QuotientGroup.mk_inv K a
```

威尔逊定理（定理 2.111）以数值实例核验：p = 5, 7, 11, 13 上
(p−1)! mod p = p−1 全部 `decide`，而合成数 8 上 (8−1)! = 5040 ≡ 0
≠ 7——素性的阶乘判据成立与破产各有一组。|A₃| = 3!/2 = 3 由
`Fintype.card {p : Equiv.Perm (Fin 3) // sign p = 1} = 3` 的 decide
给出——命题 2.97（指数 2 ⟹ 正规）的数值侧影。

## 12.5 机器验证二：Julia——商表与同构检查

**文件：`examples/julia/12_quotient.jl`** 从凯莱表构造商表：

```julia
"""K 正规时构造 G/K 的凯莱表：陪集编号，查 (aK)(bK) = (ab)K。"""
function quotient_table(tbl, K)
    blocks = cosets(tbl, K)                      # 第 10 章
    id = indexin([sort(K)], [sort.(blocks)])[1]  # K 自身是单位元
    n = length(blocks)
    rep(b) = b[1]                                # 每块取最小代表元
    pos(x) = findfirst(b -> x in b, blocks)
    Qt = [pos(tbl[rep(blocks[i]), rep(blocks[j])]) for i in 1:n, j in 1:n]
    Qt, id
end
```

断言组：(1) ℤ₁₂/⟨4⟩ 的商表与 ℤ₄ 的表**逐项相同**（同构 = 表相同的
有限群版）；S₃/A₃ 商表 ≅ ℤ₂ 的表；(2) **正规性检查器**（gKg⁻¹ = K
对一切 g）先跑再构造——对非正规子群 ⟨(12)⟩ ◁̸ S₃ 断言良定义性会破产
（不同代表元给出不同陪集乘积，具体给出反例数字）；(3) **威尔逊定理**：
p = 5, 7, 11, 13 上 factorial(p−1) mod p = p−1，合成数 8, 9, 10 上不成立；
(4) **φ 乘性**（推论 2.131）与 ℤ_mn ≅ ℤ_m × ℤ_n 的表同构（m,n = 3,4）；
(5) **4/6 阶分类**（命题 2.134/2.135）：枚举凯莱表？不可行——改为
构造两个实现并断言"任何 4 阶群表若含 4 阶元则 ≅ ℤ₄、否则 ≅ V"
在全部 (4! · 4²) 级别的重排测试下成立。

## 12.6 机器验证三：Python 与 Prolog

**文件：`examples/python/12_quotient.py`**：复算 Julia 断言；加做
**商群同构搜索器**：给定两张表，尝试全部双射（4 阶 24 个，6 阶 720 个）
找表同构——ℤ₁₂/⟨4⟩ ≅ ℤ₄、ℤ₆ ≅ ℤ₂×ℤ₃、D₄/⟨旋转⟩ ≅ ℤ₂ 全部命中。

**文件：`examples/prolog/12_quotient.pl`**：

```prolog
% 陪集乘法良定义性检查（正规性）：所有代表元换元一致
well_defined(G, K) :-
    forall((elem(G, A1), elem(G, B1), elem(G, A2), elem(G, B2),
            same_coset(G, K, A1, A2), same_coset(G, K, B1, B2),
            op(G, A1, B1, C1), op(G, A2, B2, C2)),
           same_coset(G, K, C1, C2)).
```

文件断言：⟨(123)⟩ 在 S₃ 中 well_defined（正规）、⟨(12)⟩ 破产
（给出具体的反例四元组——正是良定义性失败的现场标本）；商表构造 +
`is_iso/3`（搜索双射）在 S₃/A₃ ≅ ℤ₂、ℤ₈/⟨2⟩ ≅ ℤ₄ 上命中。

## 12.7 要点回顾

1. 商群良定义 ⟺ 正规（引理 2.112 + 定理 2.113）——"正规"不是美学
   词汇，是乘法良定义的通行证。
2. 第一同构定理 G/ker f ≅ im f：核是"被粘掉的部分"；正规子群 = 同态
   核（推论 2.115），两个概念一个本体。
3. 循环群完全分类：ℤ 与 ℤ_n，别无分店；互素因子分解 ℤ_mn ≅ ℤ_m×ℤ_n
   （定理 2.128），φ 乘性是它的数论投影（推论 2.131）。
4. 威尔逊定理：(p−1)! ≡ −1 (mod p) ⟺ p 素——素性的"阶乘判据"。
5. 4 阶两群、6 阶两群（ℤ₄/V、ℤ₆/S₃）——小群宇宙的第一张星图。

*对应示例：`examples/lean/Abstractalgebra/Ch12QuotientGroups.lean`、
`examples/julia/12_quotient.jl`、`examples/python/12_quotient.py`、
`examples/prolog/12_quotient.pl`。*

---

上一章：[11 群同态](11-homomorphisms.md) · 下一章：[13 群作用](13-group-actions.md)
