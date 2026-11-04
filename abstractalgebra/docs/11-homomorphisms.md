# 11 群同态

**对应原书 §2.5（pp. 112-120）。**

---

## 11.1 保持运算的映射

> **定义** f : G → H 是**群同态**，若 f(a b) = f(a) f(b) 对一切
> a, b ∈ G。双射的同态称**同构**，记 G ≅ H。

同态是"把一个群翻译成另一个群而不失运算结构"的翻译器。三个立即的
身份（原书引理 2.89）：

> f(1_G) = 1_H，f(a⁻¹) = f(a)⁻¹。

**例清单**（值得逐一在脑内验证）：
- det : GL(2, ℝ) → (ℝ*, ·)：det(AB) = det(A)det(B)——线性代数送来的
  天然同态。
- sgn : S_n → {±1}（第 08 章定理 2.39）："乘法保持"正是同态定义——
  我们早已见过同态而不自知。
- f : (ℤ, +) → (ℤ/mℤ, +)，k ↦ [k]：模 m 是加法同态。
- 指数映射 t ↦ e^{it}：ℝ → S¹。
- **共轭**（命题 2.94）：固定 g ∈ G，映射 γ_g : x ↦ g x g⁻¹ 是 G 到
  自身的同构；x ↦ g x g⁻¹ 与 y ↦ h y h⁻¹ 的复合是 xy ↦ (gh) y (gh)⁻¹
  ——共轭们自己又构成群（内自同构群，第 13 章回访）。

## 11.2 核与像

> **定义** ker f = {a ∈ G : f(a) = 1}；im f = f(G)。

> **命题 2.93** (i) ker f ≤ G 且对一切 g：g(ker f)g⁻¹ = ker f；
> (ii) f 单 ⟺ ker f = {1}；(iii) im f ≤ H。

(ii) 的证明一行：f(a) = f(b) ⟺ f(b⁻¹a) = 1 ⟺ b⁻¹a ∈ ker f。"核平凡
⟺ 单射"是此后一切"检查单射"的标准姿势。命题 2.93(i) 中"共轭不变"的
子群性质下章升格为**正规子群**的定义——商群的门票。

**第一同构定理的雏形**（原书在本节证明、下章正式表述）：f 诱导
G/ker f ≅ im f。直觉：ker f 恰好是"被 f 粘在一起的元素"，商掉它，
剩下的与像一一对应。

**欧拉定理的群论重述**：f : (ℤ, +) → (ℤ/mℤ)*，k ↦ [a]^k 是满同态
（当 gcd(a,m)=1），ker = φ(m)ℤ——所以 (ℤ/mℤ)* 的每个元素都是 a 的幂
的像，阶整除 φ(m)。

## 11.3 指数 2 与正规性预告

> **命题 2.97** 指数为 2 的子群必"共轭不变"（下章的正规子群）：
> g H g⁻¹ = H 对一切 g。

证明漂亮：g ∈ H 时显然；g ∉ H 时陪集 G = H ⊔ gH = H ⊔ Hg（指数 2
只有两块），比较两式得 gH = Hg，即 gHg⁻¹ = H。∎ 所以 S_n ⊇ A_n
（指数 2）自动"正规"——商群 S_n/A_n 一定可以造，且同构 {±1}。

## 11.4 机器验证一：Lean——MonoidHom 与核

**文件：`examples/lean/Abstractalgebra/Ch11Homomorphisms.lean`。**
mathlib 的同态是 `MonoidHom G H`（记号 G →* H），核与像有现成构造：

```lean
-- 引理 2.89 的机器版
example {G H : Type*} [Group G] [Group H] (f : G →* H) : f 1 = 1 := f.map_one
example {G H : Type*} [Group G] [Group H] (f : G →* H) (a : G) :
    f a ⁻¹ = (f a) ⁻¹ := f.map_inv a
example {G H : Type*} [Group G] [Group H] (f : G →* H) (a b : G) :
    f (a * b) = f a * f b := f.map_mul a b

-- det 是同态（矩阵乘积行列式）
example (A B : Matrix (Fin 2) (Fin 2) ℝ) :
    (A * B).det = A.det * B.det := Matrix.det_mul A B

-- ZMod.castHom：m ∣ n 时的自然同态 ZMod n →+* ZMod m
noncomputable example : (ZMod 6) →+* (ZMod 3) :=
  ZMod.castHom (by decide : (3 : ℕ) ∣ 6) (ZMod 3)

-- 核 = {[0], [3]}：恰两个元素映到 0
example : Fintype.card {x : ZMod 6 // x.val % 3 = 0} = 2 := by decide
```

具体轨道即最后一行：**|G| = |ker|·|im|** 的第一次显形（6 = 2 × 3，
第一同构定理的数值预告），文件还断言 (a+b) mod 3 的良定义性
（`ZMod.val_add` + omega）。sign 同态则以 `Equiv.Perm.sign` 的正式化
呈现（第 08 章已用其乘法性）。

## 11.5 机器验证二：Julia——同态检查器

**文件：`examples/julia/11_homomorphisms.jl`** 用凯莱表实现：

```julia
"""f（元素下标数组）是否是 G → H 的同态：逐对查 f(xy) = f(x)f(y)。"""
is_hom(tblG, tblH, f) =
    all(tblH[f[tblG[x, y]], f[x]*0 + f[y]] == f[tblG[x, y]]
        for x in 1:size(tblG, 1), y in 1:size(tblG, 1))
```

（实际实现按元素编号对查 `tblH[f[x], f[y]] == f[tblG[x,y]]`。）
断言组：(1) det 同态：GL(2, ℤ₅)（(|GL| = (25−1)(25−5) = 480，随机抽样
200 对）上 det(AB) = det(A)det(B)，核 = SL(2, ℤ₅) 大小 120 =
480/4——|G| = |ker|·|im| 在这里 = 480 = 120·4；(2) sgn : S₄ → {±1}：
576 对全部 sgn(αβ) = sgn(α)sgn(β)，核 = A₄ 恰 12 元，|S₄| = 12·2；
(3) f : ℤ₆ → ℤ₃ 核与像同 Lean；(4) 非同态反例：ℤ₄ → ℤ₄ 的 f(x) = x²
不是同态（f(1+1) = 2 ≠ f(1)+f(1) = 0+0… 实算核对）；(5) **共轭是自同构**
（命题 2.94）：D₄ 中对每个 g，x ↦ gxg⁻¹ 的表置换是凯莱表自同构。

## 11.6 机器验证三：Python 与 Prolog

**文件：`examples/python/11_homomorphisms.py`**：复算 Julia 断言；加做
**枚举全部同态** ℤ₄ → ℤ₃ / ℤ₄ → ℤ₂ / S₃ → ℤ₂（同态由生成元的像决定：
ℤ₄ 循环，f(1) 的像必须满足 4·f(1) = 0；S₃ 的 f(α), f(b) 必须满足关系
α³=b²=(αb)²=1）——个数恰为 gcd 的因子数，全部逐一验证乘法保持。

**文件：`examples/prolog/11_homomorphisms.pl`**：

```prolog
% 同态检查：全部元素对 f(xy) = f(x)f(y)
homomorphism(G, H, F) :-
    forall((elem(G, X), elem(G, Y), op(G, X, Y, XY),
            map(F, X, FX), map(F, Y, FY), op(H, FX, FY, FXY),
            map(F, XY, FXY)),
           true).
```

文件枚举 ℤ₆ → ℤ₃ 的全部映射（3⁶ = 729 个），筛出全部同态（恰 3 个：
f(k) = [ck]₃，c = 0,1,2），对每个断言核 = {[0],[3]} 或全群或 {[0]}，
验证 |G| = |ker|·|im|；并对 S₃ → {±1} 枚举 2⁶ = 64 个映射，筛出
恰 2 个同态（平凡与 sgn），sgn 的核恰为 A₃ = {1, (123), (132)}。

## 11.7 要点回顾

1. 同态 = 保持运算；同构 = 双射同态；f(1) = 1 与 f(a⁻¹) = f(a)⁻¹ 免费。
2. det、sgn、mod-m、指数映射、共轭——同态无处不在；"乘法保持"是
   它们的共同指纹。
3. ker f 是子群且共轭不变；单射 ⟺ 核平凡（命题 2.93）——此后检查
   单射的 standard 动作。
4. |G| = |ker f|·|im f|（第一同构定理的数值投影）。
5. 指数 2 的子群自动正规（命题 2.97）——A_n 在 S_n 中的地位由此而来。

*对应示例：`examples/lean/Abstractalgebra/Ch11Homomorphisms.lean`、
`examples/julia/11_homomorphisms.jl`、`examples/python/11_homomorphisms.py`、
`examples/prolog/11_homomorphisms.pl`。*

---

上一章：[10 子群与拉格朗日定理](10-subgroups-lagrange.md) · 下一章：[12 商群](12-quotient-groups.md)
