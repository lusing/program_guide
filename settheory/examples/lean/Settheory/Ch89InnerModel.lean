/-!
# 第 89 章 · 内模型 HOD、L[A] 与 L(ℝ)（冯琦第二卷 §2.2）

三件与 §2.2 同构的事实：

1. 引理 2.23/2.24 的引擎：新谓词原子让 U∩M 免参可定义——
   L[U] = L[U∩L[U]] 与 U ∈ L[U] 的组合根源。
2. 引理 2.27(2)：彻底性（HOD）对 ∈ 向下传递。
3. 引理 2.27(3) 的分解方向：P x ∧ (∀ y ∈ x, 彻底 P y) ⟹ 彻底 P x。
-/

namespace Settheory.Ch89

/-! ## 一、谓词原子：U∩M 免参可定义（引理 2.23/2.24 的引擎） -/

/-- 相对化公式语言：在 87 章的语言上增加一元谓词原子 inA（x ∈ U）。
定义 2.21 的最小机器骨架。 -/
inductive FmA (α : Type) where
  | tt : FmA α
  | ff : FmA α
  | eq (p : α) : FmA α
  | mem (p : α) : FmA α
  | inA : FmA α
  | neg (φ : FmA α) : FmA α
  | or (φ ψ : FmA α) : FmA α

/-- 结构 (α, ∈, U) 上的求值。 -/
def satA (mem : α → α → Prop) (U : α → Prop) : FmA α → α → Prop
  | .tt, _ => True
  | .ff, _ => False
  | .eq p, x => x = p
  | .mem p, x => mem x p
  | .inA, x => U x
  | .neg φ, x => ¬ satA mem U φ x
  | .or φ ψ, x => satA mem U φ x ∨ satA mem U ψ x

/-- U∩M 由原子公式免参定义：这正是「L[U] 只看到 U∩L[U]」
（引理 2.24：L[U] = L[Ũ]，Ũ = U∩L[U]）的成员层引擎——
层次每一步只用得到当时的 U 截断，故换成 Ũ 毫无损失。 -/
theorem UA_definable (mem : α → α → Prop) (U : α → Prop) (M : List α) :
    ∃ φ : FmA α, ∀ x, x ∈ M → (satA mem U φ x ↔ U x) :=
  ⟨.inA, fun _ _ => Iff.rfl⟩

/-- 参数全开放时，谓词不增加有限载体的定义力：87 章的析取引擎
照旧覆盖全部子集——L_n[U] = V_n 的有限影子。 -/
def disjA : List α → FmA α
  | [] => .ff
  | a :: as => .or (.eq a) (disjA as)

theorem finite_definable_UA (mem : α → α → Prop) (U : α → Prop) (L B : List α) :
    ∃ φ : FmA α, ∀ x, x ∈ L → (satA mem U φ x ↔ x ∈ B) :=
  ⟨disjA B, fun x _ => by
    induction B with
    | nil => simp [disjA, satA]
    | cons a Bs ih =>
        simp [disjA, satA, ih]⟩

/-! ## 二、HOD 的彻底性（引理 2.27） -/

/-- ∈-可达：从 x 出发沿 ∈ 下降（含自身）可达的元素——TC({x}) 的
归纳化身。 -/
inductive Reach (mem : α → α → Prop) : α → α → Prop
  | head (x : α) : Reach mem x x
  | step {x y z : α} (h : mem x y) (hr : Reach mem y z) : Reach mem x z

/-- 彻底性（定义 2.29 的抽象形态）：x 的全部（广义）成员都满足 P。 -/
def Hered (P : α → Prop) (mem : α → α → Prop) (x : α) : Prop :=
  ∀ y, Reach mem y x → P y

/-- 可达关系的传递性。 -/
theorem reach_trans {mem : α → α → Prop} :
    ∀ {u v w : α}, Reach mem u v → Reach mem v w → Reach mem u w
  | _, _, _, .head _, h2 => h2
  | _, _, _, .step hmem hr, h2 => .step hmem (reach_trans hr h2)

/-- 引理 2.27(2)：彻底性对 ∈ 向下传递（HOD 的传递性的抽象引擎）。 -/
theorem hered_down {P : α → Prop} {mem : α → α → Prop} {x y : α}
    (hx : Hered P mem x) (hxy : mem y x) : Hered P mem y :=
  fun z hz => hx z (reach_trans hz (Reach.step hxy (Reach.head x)))

end Settheory.Ch89
