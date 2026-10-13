# 16 · 偏序、稠密集与泛型扩张的骨架

> 添加一个泛型集合就像向一个域添加一个超越元——除了这里
> 的"域"是整个集合论宇宙。 ——Cohen 1963 的想法

本章覆盖 Jech §16：力迫条件、稠密集、泛型滤波器、
引理 16.1（Rasiowa-Sikorski）、定理 39/40 的陈述、
Cohen 泛型实数。

## 16.1 力迫条件与偏序

固定传递 ZFC 模型 𝔐（地面模型）与 𝔐 中的偏序集 (P, <)。
**力迫条件** p ∈ P 是"关于泛型集的有限信息片段"；p < q 意为
p **更强**（给出更多约束）。Cohen 例（崩塌 ω₁）：P = ω₁ 的
有限序列；p ⊑ q = p 延伸 q。

**相容**：p、q 有共同延伸 r ≤ p, r ≤ q。**滤波器**
(16.2)：非空 + 向上封闭 + 有向。**泛型** (16.3)：滤波器 +
击中 𝔐 的每个稠密集。**稠密集** D：∀p∃q∈D (q ≤ p)。

Prolog（`examples/prolog/16_generic.pl`）把这些定义做成
可执行谓词（有限 0/1 序列偏序上的稠密/滤波/泛型判定）：
链 [∅,[0],[0,1]] 是滤波器 ✓；[0],[1] 不相容——非滤波器 ✓。
（实测坑：稠密的 `prefix` 方向要与"更强"约定一致。）

## 16.2 Rasiowa-Sikorski：塔构造

**引理 16.1** 若 ℰ = {D₁, D₂, ...} 可数（每个 Dₙ 稠密），
则存在 ℰ-泛型滤波器 G（含任意指定 p₀）。

*证明*：塔构造——p₀ ≥ p₁ ≥ p₂ ≥ ...（pₙ₊₁ ∈ Dₙ₊₁ 且
pₙ₊₁ ≤ pₙ）；G = {q : q ≥ pₙ 对某 n}。∎

这是力迫存在性的可数骨架——泛型集合在可数模型中**可以
构造性地获得**。计算通道把这个塔做成了**可执行程序**：

Julia（`examples/julia/16_generic.jl`）：

```julia
function rs_tower(p0, D, n)
    p = p0
    for i in 1:n
        p = first_above(p, D[i])
    end
    return p
end
```

`first_above` 线性扫描 D 中第一个延伸当前条件的元素。
5 层塔后条件长度逐步增长——"每层命中一个更长的条件"。

Python（`examples/python/16_generic.py`）同构实现 +
**(16.2) 三公理的机器验证**：非空 ✓、链性（两两前缀可比）✓、
有向性（min(i,j) 是共同下方）✓；**(16.3)(ii) 泛型性**：
塔链的每层命中对应稠密集 ✓。

Coq（`examples/coq/Ch16_generic.v`）做 **Cohen 偏序的
形式化骨架**：`prefixb`（前缀判定 Fixpoint）+ `prefixb_refl`
（自反性）+ `first_above`（线性扫描 Fixpoint）+ `tower`
（塔构造 Fixpoint）。`prefixb_refl` 的证明对序列结构归纳、
`andb` 的 `true∧true=true` 收尾。（实测坑：嵌套 `andb` 的
`simpl` 产生 `if eqb x x then ...` 而非直接 `true`——
需对 bool case split。）

Agda（`examples/agda/Ch16_generic.agda`）的 `prefixb-refl`
（cong 版）与 Julia/Coq 同构。

Lean（`examples/lean/Settheory/Ch16Generic.lean`）给出
**泛型滤波器的定义性骨架**：

```lean
structure IsFilter (F : Set P) : Prop where
  nonempty : F.Nonempty
  up_closed : ∀ {p q : P}, p ∈ F → p ≤ q → q ∈ F
  directed : ∀ p ∈ F, ∀ q' ∈ F, ∃ r ∈ F, r ≤ p ∧ r ≤ q'

def GenericOver (F : Set P) (ℰ : Set (Set P)) : Prop :=
  IsFilter P F ∧ ∀ D ∈ ℰ, Dense P D → (F ∩ D).Nonempty
```

Dense/IsFilter/GenericOver 三层定义——Jech (16.2)-(16.3)
的逐字机器化。

## 16.3 泛型模型定理与力迫定理

**定理 39** G 泛型 ⟹ 存在传递模型 𝔐[G] ⊨ ZFC，
𝔐 ⊆ 𝔐[G]，G ∈ 𝔐[G]，Ord^𝔐 = Ord^𝔐[G]，且 𝔐[G] 是
含 G 的最小传递模型。

**定理 40** σ 是力迫语言的句子 ⟹
𝔐[G] ⊨ σ ⟺ (∃p ∈ G) p ⊩ σ。

力迫关系 ⊩ 在**地面模型内定义**——它是"泛型扩张中真值
的预言器"。(16.6)-(16.8) 的规则（q ≤ p 增强、∧/¬ 分解）
是第四篇（§18 布尔值模型）的正题。

**力迫语言**：包含 𝔐 的每个元素的名字 + G 的标准名。
**P-名**的递归定义与 𝔐[G] 的构造在 §18 展开。

## 16.4 Cohen 泛型实数

P = 2^{<ω}（有限 0/1 序列）。G 泛型 ⟹ f = ⋃G : ω → {0,1}
是**新实数**。关键论证：D_g = {p : ∃n, p(n) ≠ g(n)} 稠密
（对任何地面模型的 g），G ∩ D_g ≠ ∅ ⟹ f ≠ g。

要加 ω₂ 个泛型实数（违反 CH）：P = Fn(ω₂ × ω, 2)——
dom(p) 是 ω₂ × ω 的有限子集。f = ⋃G 给出 ⟨f_α : α < ω₂⟩
的两两不同的实数族。要证 ω₂ 不被崩塌需要链条件（§21）。

## 16.5 Isabelle 通道

Isabelle/ZF 未形式化力迫（依赖极重——第三篇的核心但
需要大量绝对性基础设施）。ST16 锚定偏序的 ZF 库形态
（`part_ord_def`）+ 稠密集的语义注释。完整的力迫形式化
不在任何主流证明助手的官方库中——这是集合论教程的
"讲义+计算"模式的典型场景。

## 16.6 习题精选

1. **（纸笔）** 习题 16.1：滤波器定义中"有向"可弱化为
   "两两相容"。
2. **（纸笔）** 习题 16.2-16.5：泛性的等价形态（below-p
   稠密 / 开稠密 / 覆盖 / 分割）。
3. **（机器）** 塔构造器的扩展：支持不同偏序（Julia/Python）。
4. **（纸笔）** 习题 16.6：P 的每个条件有两个不相容延伸 ⟹
   G ∉ 𝔐。

---

上一章：[15 OD/HOD](docs/15-OD.md) · 下一章：[17 完备布尔代数](docs/17-boolean.md)
