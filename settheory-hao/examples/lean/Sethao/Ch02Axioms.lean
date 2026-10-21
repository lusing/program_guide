import Mathlib.SetTheory.ZFC.Basic
import Mathlib.SetTheory.ZFC.Class

/-!
# 第 02 章 ZFC 公理（Lean）

mathlib 在 `SetTheory.ZFC` 里维护着一个真正的 ZFC 宇宙：`PSet`
（前置集）经"相同元素"等价关系取商得到 `ZFSet`。书的九条公理
在那里不是公理而是定理——本单元把每条公理的影子逐一点名，
最后对照两张地基图：ZFC 的九条 vs Lean 逻辑的三条。
-/

/-! ## 公理 0-2：存在、外延、分离 -/

/-- 公理 0+分离造出空集：∃x ∀y, y ∉ x。-/
example : ∃ x : ZFSet, ∀ y, y ∉ x :=
  ⟨∅, fun y => ZFSet.notMem_empty y⟩

/- 公理 1 外延：集合由元素决定。商结构本身就是外延的化身：
"有相同元素"（`PSet.Equiv`）被定义为相等。 -/
#check @ZFSet.eq
#check @ZFSet.exact

/-- 公理 2 分离：`sep` 把性质限制在已有集合内，只能裁剪不能扩大。 -/
example (p : ZFSet → Prop) (x : ZFSet) : x.sep p ⊆ x := ZFSet.sep_subset

#check @ZFSet.mem_sep

/-! ## 公理 3-5：对集、并集、幂集 -/

/-- 公理 3 对集：{a, b} 的隶属刻画。 -/
example (a b c : ZFSet) : c ∈ ({a, b} : ZFSet) ↔ c = a ∨ c = b := ZFSet.mem_pair

/-- 公理 4 并集：⋃X 的隶属刻画。 -/
example (x y : ZFSet) : y ∈ ZFSet.sUnion x ↔ ∃ z ∈ x, y ∈ z := ZFSet.mem_sUnion

/-- 公理 5 幂集：∅ ⊆ ∅ 所以 ∅ ∈ P(∅)。 -/
example : (∅ : ZFSet) ∈ ZFSet.powerset ∅ :=
  ZFSet.mem_powerset.2 (ZFSet.empty_subset _)

#check @ZFSet.mem_powerset

/-! ## 公理 6-8：无穷、基础、替换 -/

/-- 公理 6 无穷：ω 含 ∅ 且对后继 S(x) = x ∪ {x} 封闭——
与书 1.3 中无穷公理的形式逐字对应。 -/
example : (∅ : ZFSet) ∈ ZFSet.omega := ZFSet.omega_zero

example (n : ZFSet) (h : n ∈ ZFSet.omega) : insert n n ∈ ZFSet.omega :=
  ZFSet.omega_succ h

/-- 公理 7 基础的结论形态：x ∈ y → y ∉ x。
取 y := x 立得书 1.3.11 定理"任何集合不属于自身"。 -/
example (x : ZFSet) : x ∉ x := fun h => ZFSet.mem_asymm h h

/- 公理 8 替换：可定义（`Definable₁`）函数的像仍是集合——
`Definable₁` 约束正是替换模式中"公式"条件的化身。 -/
#check @ZFSet.image
#check @ZFSet.mem_image

/-! ## 真类：V 与罗素类 -/

/- 所有集合的类 V 与罗素类 R = {x | x ∉ x} 作为 `Class` 存在，
但 V 是真类——`Class` 层没有"V : ZFSet"。 -/
#check @Class.univ
#check @Class.sep

/-! ## 两张地基图 -/

/- ZFSet 的每条定理最终落在 Lean 逻辑的哪几条公理上？
（答案：mem_asymm 只用 propext 与 Quot.sound，不碰 choice。） -/
#print axioms ZFSet.mem_asymm

/- 选择公理在 Lean 地基中的形态（排中律也是它的后代）。 -/
#check @Classical.choice
#print axioms Classical.em
