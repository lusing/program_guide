/- ex12 —— 子对象、商对象与射影对象（贺伟 1.5 / 1.7）
   四个零公理定理：终点出发皆单（1.5.13）、始对象射影（1.7.6）、
   射影的收缩封闭（1.7.7）、满射的核对是等价关系（1.5.15）。 -/

structure Category where
  Obj : Type u
  Hom : Obj → Obj → Type v
  idn : ∀ a, Hom a a
  comp : ∀ {a b c}, Hom a b → Hom b c → Hom a c
  idL : ∀ {a b} (f : Hom a b), comp (idn a) f = f
  idR : ∀ {a b} (f : Hom a b), comp f (idn b) = f
  assoc : ∀ {a b c d} (f : Hom a b) (g : Hom b c) (h : Hom c d),
    comp (comp f g) h = comp f (comp g h)

namespace Cat
def Epi (C : Category.{u, v}) (a b : C.Obj) (f : C.Hom a b) : Prop :=
  ∀ (c : C.Obj) (g h : C.Hom b c), C.comp f g = C.comp f h → g = h

def Mono (C : Category.{u, v}) (a b : C.Obj) (f : C.Hom a b) : Prop :=
  ∀ (c : C.Obj) (g h : C.Hom c a), C.comp g f = C.comp h f → g = h

def Terminal (C : Category.{u, v}) (t : C.Obj) : Type (max u v) :=
  ∀ a, { f : C.Hom a t // ∀ g, g = f }

def Initial (C : Category.{u, v}) (i : C.Obj) : Type (max u v) :=
  ∀ a, { f : C.Hom i a // ∀ g, g = f }

/-- 命题 1.5.13：终对象出发的箭头都是单 -/
theorem terminal_arrow_mono {C : Category.{u, v}} {t : C.Obj}
    (Ht : Terminal C t) {a : C.Obj} (f : C.Hom t a) : Mono C t a f := by
  intro c g h _
  have := (Ht c).2
  rw [this g, this h]

/-- 射影对象（提升是数据） -/
def Projective (C : Category.{u, v}) (p : C.Obj) : Type (max u v) :=
  ∀ {a b : C.Obj} (e : C.Hom a b), Epi C a b e →
    ∀ f : C.Hom p b, { g : C.Hom p a // f = C.comp g e }

/-- 命题 1.7.6：始对象是射影对象（连满性都不用） -/
def initial_projective {C : Category.{u, v}} {i : C.Obj}
    (Hi : Initial C i) : Projective C i := by
  intro a b e _ f
  refine ⟨(Hi a).1, ?_⟩
  have h := (Hi b).2
  rw [h f, h (C.comp (Hi a).1 e)]

/-- 命题 1.7.7：射影对象的收缩仍是射影对象 -/
def RetractOf (C : Category.{u, v}) (r p : C.Obj) : Type v :=
  Σ' i : C.Hom r p, { rr : C.Hom p r // C.comp i rr = C.idn r }

def retract_projective {C : Category.{u, v}} {p r : C.Obj}
    (Hp : Projective C p) (Hret : RetractOf C r p) : Projective C r := by
  intro a b e He f
  obtain ⟨i, rr, Hrr⟩ := Hret
  obtain ⟨g, Hg⟩ := Hp e He (C.comp rr f)
  refine ⟨C.comp i g, ?_⟩
  -- f = f;1 = (i;rr);f = i;(rr;f) = i;(g;e) = (i;g);e
  calc f = C.comp (C.idn r) f := (C.idL f).symm
    _ = C.comp (C.comp i rr) f := by rw [← Hrr]
    _ = C.comp i (C.comp rr f) := C.assoc i rr f
    _ = C.comp i (C.comp g e) := by rw [Hg]
    _ = C.comp (C.comp i g) e := (C.assoc i g e).symm

/-- 例 1.5.15 的核对：e := fst 在 Bool×Bool 上诱导等价关系 -/
def eqb : Bool → Bool → Bool
  | false, false => true
  | false, true  => false
  | true,  false => false
  | true,  true  => true

def kpair (x y : Bool × Bool) : Bool := eqb x.1 y.1

theorem kpair_refl (x : Bool × Bool) : kpair x x = true := by
  obtain ⟨a, _⟩ := x; cases a <;> rfl

theorem kpair_sym (x y : Bool × Bool) : kpair x y = true → kpair y x = true := by
  obtain ⟨a1, _⟩ := x; obtain ⟨a2, _⟩ := y
  cases a1 <;> cases a2 <;> intro h <;> first | rfl | exact h

theorem kpair_trans (x y z : Bool × Bool) (h1 : kpair x y = true)
    (h2 : kpair y z = true) : kpair x z = true := by
  obtain ⟨a1, _⟩ := x; obtain ⟨a2, _⟩ := y; obtain ⟨a3, _⟩ := z
  cases a1 <;> cases a2 <;> cases a3 <;> simp [kpair, eqb] at h1 h2 ⊢ <;> rfl
end Cat
