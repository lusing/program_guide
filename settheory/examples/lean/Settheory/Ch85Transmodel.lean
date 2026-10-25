/-!
# 第 85 章 · 传递模型与内在模型论（冯琦第二卷 §1.2）

两件与 §1.2 同构的事实：

1. 例 1.7：载体若传递，相对化后的同一律就是外延公理本身。
2. 定理 1.22：子载体若对每一个存在公式都含有见证，则它与原结构初等。
-/

namespace Settheory.Ch85

variable {S : Type}

def update (e : Nat → S) (i : Nat) (x : S) : Nat → S :=
  fun k => if k = i then x else e k

theorem update_same (e : Nat → S) (i : Nat) (x : S) : update e i x i = x := by
  simp [update]

theorem update_other (e : Nat → S) {i k : Nat} (x : S) (h : k ≠ i) :
    update e i x k = e k := by
  simp [update, h]

/-- 例 1.7。`ext` 是载体所在宇宙的外延公理。传递性把 `a` 的元素全部拉回 `M`，
于是「在 M 里元素相同」和「在宇宙里元素相同」是同一句话。 -/
theorem relativized_extensionality
    (mem : S → S → Prop) (M : S → Prop)
    (ext : ∀ {a b : S}, (∀ x, mem x a ↔ mem x b) → a = b)
    (tr : ∀ {x y}, M x → mem y x → M y)
    {a b : S} (ha : M a) (hb : M b) :
    (∀ x, M x → (mem x a ↔ mem x b)) ↔ a = b := by
  constructor
  · intro h
    apply ext
    intro x
    constructor
    · intro hxa
      have hx : M x := tr ha hxa
      exact (h x hx).1 hxa
    · intro hxb
      have hx : M x := tr hb hxb
      exact (h x hx).2 hxb
  · intro hab x _hx
    subst hab
    exact Iff.rfl

inductive Fm : Type where
  | eq : Nat → Nat → Fm
  | neg : Fm → Fm
  | conj : Fm → Fm → Fm
  | ex : Nat → Fm → Fm

def val (e : Nat → S) (p : Fm) (R : S → Prop) : Prop :=
  match p with
  | .eq i j => e i = e j
  | .neg q => ¬ val e q R
  | .conj q r => val e q R ∧ val e r R
  | .ex i q => ∃ x, R x ∧ val (update e i x) q R

/-- 赋值的值都落在载体里。 -/
def envIn (B : S → Prop) (e : Nat → S) : Prop := ∀ k, B (e k)

theorem envIn_update {B : S → Prop} {e : Nat → S} {i : Nat} {x : S}
    (he : envIn B e) (hx : B x) : envIn B (update e i x) := by
  intro k
  by_cases hk : k = i
  · subst hk
    simpa [update] using hx
  · simpa [update, hk] using he k

/-- 定理 1.22 的全称形式：`B ⊆ A`，并且每一个存在公式的见证都能选在 `B` 里。
则 `B` 与 `A` 对全部公式初等。 -/
theorem tarski_agreement
    (A B : S → Prop) (sub : ∀ {x}, B x → A x)
    (closed : ∀ (p : Fm) (e : Nat → S) (i : Nat),
      envIn B e → val e (.ex i p) A → ∃ x, B x ∧ val (update e i x) p A)
    (p : Fm) (e : Nat → S) (he : envIn B e) :
    val e p B ↔ val e p A := by
  induction p generalizing e with
  | eq i j =>
      simp [val]
  | neg p ih =>
      constructor
      · intro h hA
        exact h ((ih e he).2 hA)
      · intro h hB
        exact h ((ih e he).1 hB)
  | conj p q ihp ihq =>
      constructor
      · intro h
        exact ⟨(ihp e he).1 h.1, (ihq e he).1 h.2⟩
      · intro h
        exact ⟨(ihp e he).2 h.1, (ihq e he).2 h.2⟩
  | ex i p ih =>
      constructor
      · intro h
        rcases h with ⟨x, hxB, hx⟩
        have hxA : A x := sub hxB
        have he' : envIn B (update e i x) := envIn_update he hxB
        exact ⟨x, hxA, (ih (update e i x) he').1 hx⟩
      · intro h
        rcases closed p e i he h with ⟨x, hxB, hxA⟩
        have he' : envIn B (update e i x) := envIn_update he hxB
        exact ⟨x, hxB, (ih (update e i x) he').2 hxA⟩

end Settheory.Ch85
