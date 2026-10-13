# 02 · 序数与超穷归纳递归

> 序数是良序的"长度"：两个良序集同构当且仅当长度相同，
> 而长度本身就是一种集合。——von Neumann 的想法（Jech §2）

本章覆盖 Jech §2：良序、von Neumann 序数、超穷归纳与超穷递归、
序数算术、以及 ω×ω 的典范良序。序数是集合论的脊梁——第 03 章
的基数、第 09 章的秩层级、第 12 章的 L，全部踩在它上面。

## 2.1 良序：为什么"长度"是集合

线性序 < 良序化 P，若每个非空子集有最小元。良序集的三个
基本引理（Jech 引理 2.1-2.2、定理 1）值得完整过一遍，因为
它们是"序数存在"的逻辑前奏：

**引理 2.1** 良序集 (W, <) 上的增函数 f : W → W 满足 f(x) ≥ x
对一切 x。

*证明*：设 X = {x ∈ W : f(x) < x} 非空，取最小元 z。令 w = f(z)。
由 f 递增与 f(z) < z 得 f(w) < f(z) = w——即 w ∈ X 且 w < z，
与 z 最小矛盾。∎

**推论** 良序集的自同构只有恒等（f 与 f⁻¹ 都用引理 2.1）；
两个良序集之间的同构若存在则唯一。

**引理 2.2** 良序集不同构于自身的真前段。（前段 = {x ∈ W :
x < u}。若 ran(f) = {x : x < u}，则 f(u) < u 违反引理 2.1。）

**定理 1（三歧性）** 任意两个良序集 W₁、W₂，恰有其一：
(a) 同构；(b) W₁ 同构于 W₂ 的前段；(c) W₂ 同构于 W₁ 的前段。

*证明* 的想法是"逐步配对"：令 f = {(x, y) : W₁(x) ≅ W₂(y)}，
其中 W_i(u) 记 u 给出的前段。f 是保序单射；若 dom(f) = W₁ 且
ran(f) = W₂ 则 (a)；若 ran(f) 停在 y₀（W₂ − ran(f) 的最小元），
则 ran(f) = W₂(y₀) 而 dom(f) 必已耗尽 W₁（否则配对还能继续），
得 (b)；对称得 (c)。互斥来自引理 2.2。∎

**长度可以做集合**：把"同构"取等价关系，序数就是良序集的
等价类代表。von Neumann 的天才选择：让代表自己就是集合——

> **序数**是传递的且被 ∈ 良序化的集合：α = {β : β < α}，
> 而 α < β 定义为 α ∈ β。

传递集 T（∀x ∈ T, x ⊆ T）是"元素都是子集"的集合。引理 2.3
给出序数的基本代数：0 是序数；序数的元素是序数；α ⊆ β 蕴含
α ∈ β 或 α = β（两序数必可比）；ω 是最小非零极限序数。

**定理 2** 每个良序集同构于唯一的序数——"长度"落进集合世界。
超穷递归（定理 4）随后给出"按长度定义函数"的通行证：

> 给定类函数 G，存在唯一的 F : Ord → V 满足 F(α) = G(F↾α)。

第 09 章的秩函数、第 12 章的 L 层级、序数算术本身，都是这个
模式的实例。**超穷归纳**（定理 3）：若 C ⊆ Ord 满足 (i) 0 ∈ C，
(ii) α ∈ C → α+1 ∈ C，(iii) λ 极限且 ∀β < λ β ∈ C → λ ∈ C，
则 C = Ord。

## 2.2 机器化：六通道的序数

### Lean：官方锚点

`examples/lean/Settheory/Ch02Ordinals.lean` 机器化了四个锚点。
三歧性来自 `LinearOrder` 实例：

```lean
example (a b : Ordinal) : a < b ∨ a = b ∨ b < a :=
  lt_trichotomy a b
```

超穷归纳的官方形态是 `WellFoundedLT.induction`（注意
`Ordinal.induction` 已弃用——这是本通道的实测坑之一）：

```lean
theorem transfinite_induction_demo (P : Ordinal → Prop)
    (h : ∀ j, (∀ k, k < j → P k) → P j) : ∀ i, P i :=
  fun i => WellFoundedLT.induction i h
```

ω 与有限序数的吸收律是序数算术非交换性的名片：

```lean
example (n : ℕ) : (n : Ordinal) + ω = ω := Ordinal.natCast_add_omega0 n

example : (1 : Ordinal) + ω = ω := Ordinal.one_add_omega0
```

而反方向不塌缩——ω + 1 是真后继：

```lean
example : ω < ω + 1 := by
  rw [← Order.succ_eq_add_one]
  exact Order.lt_succ_iff.2 le_rfl
```

（`lt_succ_iff : a < succ b ↔ a ≤ b`，配合 `le_rfl`——succ ω 的
最小上界性质。）结合律与左分配律是 `add_assoc` 与 `mul_add`：

```lean
example (a b c : Ordinal) : (a + b) + c = a + (b + c) :=
  add_assoc a b c

example (a b c : Ordinal) : a * (b + c) = a * b + a * c :=
  mul_add a b c
```

**注意**：`ω` 是 `Ordinal` 命名空间的 scoped 记号，文件头要
`open scoped Ordinal`；这解释了为什么裸写 ω 会类型怪错。

### Isabelle/ZF：Ord 的库生态

`examples/isabelle/ST02/Ordinals.thy` 抽查 ZF 库：序数的定义
`Ord_is_Transset`（传递 + 良序）、三歧性 `Ord_linear_lt`、超穷
归纳 `Ord_induct`、自然数入 Ord（`nat_into_Ord`）。两个完整证明
示范"库如何用"：succ 的严格增大

```isabelle
lemma succ_increases: "i ∈ succ(i)"
  by (unfold succ_def, blast)
```

以及 Jech 引理 2.3(c) 的方向（子集序数 = 属于或相等）：

```isabelle
lemma ordinal_subset_mem:
  assumes "Ord(i)" "Ord(j)" "i ⊆ j"
  shows "i ∈ j ∨ i = j"
proof -
  from assms have "i ≤ j" by (blast intro: subset_imp_le)
  then consider "i < j" | "i = j" by (auto simp: le_iff)
  then show ?thesis
  proof cases
    case 1
    then show ?thesis by (blast dest: ltD)
  next
    case 2
    then show ?thesis by blast
  qed
qed
```

路线：`subset_imp_le`（ZF 的序数特产）+ `le_iff` 展开三叉 +
`ltD`（< 即 ∈）。

### Coq：强归纳作为超穷归纳的影子

浅嵌入里序数算术的三条款递归（α+0、α+(β+1)、极限取 sup）在
Coq 通道用 nat 上的有界版本演示（`examples/coq/Ch02_ordinals.v`）：

```coq
Fixpoint bounded_add (alpha beta : nat) : nat :=
  match beta with
  | O => alpha
  | S b => S (bounded_add alpha b)
  end.
```

两条递归条款是 definitional 的（`reflexivity` 直接关闭），结合律
则要归纳——这正预习了"超穷递归的条款有深浅之分"：

```coq
Lemma bounded_add_assoc : forall a b c,
  bounded_add (bounded_add a b) c = bounded_add a (bounded_add b c).
Proof.
  intros a b c. induction c as [|c IH].
  - reflexivity.
  - simpl. rewrite IH. reflexivity.
Qed.
```

更重要的是**强归纳法**——超穷归纳在 ω 上的化身，零公理：

```coq
Lemma strong_induction :
  forall P : nat -> Prop,
    (forall n, (forall m, m < n -> P m) -> P n) -> forall n, P n.
```

### Agda：von Neumann 序数的构造性验证

`examples/agda/Ch02_ordinals.agda` 定义有限序数与其隶属：

```agda
data VNO : Set where
  oz   : VNO                             -- 0 = ∅
  osuc : VNO -> VNO                      -- n+1 = n ∪ {n}

_∈o_ : VNO -> VNO -> Set
x ∈o oz     = ⊥
x ∈o osuc n = (x ≡ n) ⊎ (x ∈o n)
```

∈ 的传递性（Transset 的核心）逐字验证，osuc 的 inj₁ 分支上
`refl` 模式把统一变量粘合——这行代码就是"n+1 的元素都是 n 的
成员或 n 本身"的构造性内容：

```agda
∈-trans : ∀ x y z → x ∈o y → y ∈o z → x ∈o z
∈-trans x y oz     x∈y ()
∈-trans x y (osuc n) x∈y (inj₁ refl) = inj₂ x∈y
∈-trans x y (osuc n) x∈y (inj₂ y∈n) = inj₂ (∈-trans x y n x∈y y∈n)
```

具体的成员事实（2 ∈ 3、0 ∈ 3、0 ∉ 0）与传递性实例（0 ∈ 1 ∈ 3
⟹ 0 ∈ 3）都在文件尾部落了锚。

### Julia：CNF 序数计算器（本通道重头）

每个小于 ε₀ 的序数有唯一 **Cantor 范式**：

    α = ω^e₁·c₁ + ω^e₂·c₂ + … + ω^e_k·c_k + n    (e₁ > … > e_k, c_i ∈ ℕ⁺)

指数自身又是 CNF——递归的数据结构。`examples/julia/02_ordinals.jl`
实现完整的比较/加法/乘法/幂，验证 Jech §2 的全部经典不等式：

```julia
struct ON
    terms::Vector{Tuple{ON,Int}}   # ω^e·c 项，指数递降
    fin::Int                        # 尾部自然数
end

oz() = ON([], 0)
on_wexp(e::ON) = ON([(e, 1)], 0)      # ω^e
omega() = on_wexp(on_n(1))            # ω = ω^1
```

加法是"左吸收"结构——β 首项指数吃掉 α 的低段：

```julia
function oadd(a::ON, b::ON)
    isempty(b.terms) && return ON(a.terms, a.fin + b.fin)
    eb, cb = b.terms[1]
    keep = Tuple{ON,Int}[]
    for (e, c) in a.terms
        olt(eb, e) ? push!(keep, (e, c)) : break
    end
    # α 中指数恰为 eb 的项（若有）与 β 首项合并系数，更低项与 fin 被吞
    head_extra = 0
    if length(keep) < length(a.terms) && a.terms[length(keep)+1][1] == eb
        head_extra = a.terms[length(keep)+1][2]
    end
    newb = vcat([(eb, cb + head_extra)], b.terms[2:end])
    normalize_terms(vcat(keep, newb), b.fin)
end
```

注意注释标出的**系数合并**：ω + ω = ω·2 而不是 ω——首版实现
漏掉这一行时，程序"证明"了 ω+ω = ω（作者亲测的 bug：CNF 加法
不只是丢弃 α 的低段，等指数项要合并）。运行输出：

    1 + ω = ω
    ω + 1 = ω+1           （< ω+2）
    ω + ω = ω·2
    2 · ω = ω
    (ω+1)·2 = ω·2+1       （Jech：分配律反向的反例）
    ω · ω = ω(2)          （即 ω²）
    ω^ω = ω(ω)
    ε₀ 逼近：ω, ω(ω), ω(ω(ω)), …      （α ↦ ω^α 的幂塔）

乘法的规则浓缩在 `omul` 的主项：ω^ea·ca · ω^eb·cb = ω^(ea+eb)·cb
（β 首项指数非零时 α 的系数被吸收）；有限因子走 `omul_fin` 的
迭代加法。**结合律在计算器上随处可验，交换律处处崩塌**——两种
失败方式（1+ω 塌成 ω、(ω+1)·2 与 ω·2+1 的错位）都被断言捕获。

### Python：ω² 的坐标平面

`examples/python/02_ordinals.py` 换视角：ω² 内每个序数唯一写成
ω·a + b，序关系是**字典序**（第一坐标优先）：

```python
seq = [(1, 5), (2, 0), (0, 100), (1, 0), (2, 3)]
seq_sorted = sorted(seq, key=lambda t: key(*t))
assert seq_sorted == [(0, 100), (1, 0), (1, 5), (2, 0), (2, 3)]
```

关键观察：ω·1 + 0 **>** ω·0 + 100——第一坐标优先意味着 ω 吃掉
任何有限差。后继/极限的分类在坐标上一目了然（b ≥ 1 是后继，
b = 0 且 a ≥ 1 是极限），而 sup{ω·n : n < ω} = ω² 是"坐标无界
导致新指数层诞生"的数值体验。

### Prolog：有限序数推理机

`examples/prolog/02_ordinals.pl` 把有限 von Neumann 序数做成
两条子句的推理机：

```prolog
mem(o(N), o(s(N))).
mem(X, o(s(N))) :- mem(X, o(N)).
```

运行验证：0 ∈ 1、0 ∈ 2、1 ∈ 2、2 ∉ 1、传递性（0 ∈ 1 ∈ 2 ⟹
0 ∈ 2）、非自反（1 ∉ 1——查询失败即证明）、三歧性三例。**查询
失败就是否定证明**：Prolog 的 closed-world 语义在有限结构上
恰好匹配构造性推理。

## 2.3 定理 5 的预告：良基关系与秩

Jech 定理 5 把序数理论推广到任意**良基关系** E：每个元素获得
秩 ρE(x) = sup{ρE(y) + 1 : y E x}，ρE 的值域是初始段（长度
length(E)）。序数本身是 ∈ 在传递集上的特例；第 09 章将把 ρ
推广到全宇宙（秩层级 V = ⋃ V_α），第 41 章的 Baire 空间树
（well-founded tree 的补集 = 闭集）也要用到它。

## 2.4 习题精选

1. **（纸笔+机器）** 习题 2.9：α+0 = α、α+(β+1) = (α+β)+1、
   极限条款连续——三条递归条款。（Coq 的 `bounded_add` 与
   Julia 的 `oadd` 分别是条款的影子与实体。）
2. **（机器）** 验证 (ω+1)·2 = ω·2 + 1 而 2·(ω+1) = ω·2。
   （Julia 计算器：`omul(wp1, two)` 与 `omul(two, wp1)`。）
3. **（纸笔）** 习题 2.11：α 是极限 ⟺ α = ω·β 对某 β。
4. **（纸笔）** 习题 2.13：α^(β+γ) = α^β · α^γ 与 (α^β)^γ =
   α^(β·γ)——注意哪个方向成立、为什么。
5. **（纸笔）** 习题 2.14：γ(α)（α×α 的典范序型）满足
   γ(α+1) = γ(α) + α + (α+1)，于是 γ(α) ≤ ω^α 且 γ(ω^α) =
   ω^α——"每个无限序数的平方等于自己"的骨架。

---

上一章：[01 公理](docs/01-axioms.md) · 下一章：[03 基数：Hartogs、Cantor、Schröder-Bernstein](docs/03-cardinals.md)
