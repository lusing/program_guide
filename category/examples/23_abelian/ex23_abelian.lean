/- ex23 —— 加法范畴与 Abel 范畴（贺伟第 4 章）
   旗舰：biproduct_is_product（引理 4.1.6）——五条分块/合成等式
   ⟹ (C,p1,p2) 是积：中介 h = q1f + q2g，唯一性是
   「1 = q1p1 + q2p2」的算术消去。抽象 Preadd 记录上零公理。
   附：引理 4.1.5 的一半（1_A = 0 ⟹ 始对象）。 -/

/-- 准加法范畴（Hom 为交换幺半群的机器近似版） -/
structure Preadd where
  Obj : Type u
  Hom : Obj → Obj → Type v
  idn : ∀ a, Hom a a
  comp : ∀ {a b c}, Hom a b → Hom b c → Hom a c
  idL : ∀ {a b} (f : Hom a b), comp (idn a) f = f
  idR : ∀ {a b} (f : Hom a b), comp f (idn b) = f
  assoc : ∀ {a b c d} (f : Hom a b) (g : Hom b c) (h : Hom c d),
    comp (comp f g) h = comp f (comp g h)
  zero : ∀ a b, Hom a b
  add : ∀ {a b}, Hom a b → Hom a b → Hom a b
  addC : ∀ {a b} (f g : Hom a b), add f g = add g f
  addA : ∀ {a b} (f g h : Hom a b), add (add f g) h = add f (add g h)
  add0R : ∀ {a b} (f : Hom a b), add f (zero a b) = f
  zeroL : ∀ {a b c} (g : Hom b c) (_f : Hom a b), comp (zero a b) g = zero a c
  zeroR : ∀ {a b c} (f : Hom a b) (_g : Hom b c), comp f (zero b c) = zero a c
  distR : ∀ {a b c} (f g : Hom a b) (h : Hom b c),
    comp (add f g) h = add (comp f h) (comp g h)
  distL : ∀ {a b c} (f : Hom a b) (g g' : Hom b c),
    comp f (add g g') = add (comp f g) (comp f g')

namespace Preadd
variable {P : Preadd.{u, v}} {a b c x : P.Obj}

/-- 引理 4.1.5 的一半：1_A = 0 ⟹ 始对象 -/
def one_zero_initial (H : P.idn a = P.zero a a)
    (b : P.Obj) : { f : P.Hom a b // ∀ g, g = f } :=
  ⟨P.zero a b, fun g => by
    have h1 : g = P.comp (P.zero a a) g := by
      rw [← H]; exact (P.idL g).symm
    exact h1.trans (P.zeroL g (P.zero a a))⟩

/-- 双积中介：h = q1∘f + q2∘g -/
def bpMed (q1 : P.Hom a c) (q2 : P.Hom b c)
    (f : P.Hom x a) (g : P.Hom x b) : P.Hom x c :=
  P.add (P.comp f q1) (P.comp g q2)

section Biproduct
variable (P : Preadd.{u, v})

theorem bpMed_p1 {a b c x : P.Obj} (q1 : P.Hom a c) (q2 : P.Hom b c)
    (p1 : P.Hom c a)
    (H11 : P.comp q1 p1 = P.idn a) (H12 : P.comp q2 p1 = P.zero b a)
    (f : P.Hom x a) (g : P.Hom x b) :
    P.comp (bpMed q1 q2 f g) p1 = f := by
  show P.comp (P.add (P.comp f q1) (P.comp g q2)) p1 = f
  rw [P.distR]
  rw [P.assoc, H11, P.idR]
  rw [P.assoc, H12, P.zeroR g (P.zero b a), P.add0R]

theorem bpMed_p2 {a b c x : P.Obj} (q1 : P.Hom a c) (q2 : P.Hom b c)
    (p2 : P.Hom c b)
    (H22 : P.comp q2 p2 = P.idn b) (H21 : P.comp q1 p2 = P.zero a b)
    (f : P.Hom x a) (g : P.Hom x b) :
    P.comp (bpMed q1 q2 f g) p2 = g := by
  show P.comp (P.add (P.comp f q1) (P.comp g q2)) p2 = g
  rw [P.distR]
  rw [P.assoc, H21, P.zeroR f (P.zero a b)]
  rw [P.addC, P.add0R]
  rw [P.assoc, H22, P.idR]

theorem bpMed_unique {a b c x : P.Obj} (q1 : P.Hom a c) (q2 : P.Hom b c)
    (p1 : P.Hom c a) (p2 : P.Hom c b)
    (Hsum : P.add (P.comp p1 q1) (P.comp p2 q2) = P.idn c)
    (f : P.Hom x a) (g : P.Hom x b) (h' : P.Hom x c)
    (Hf : P.comp h' p1 = f) (Hg : P.comp h' p2 = g) :
    h' = bpMed q1 q2 f g := by
  show h' = P.add (P.comp f q1) (P.comp g q2)
  symm
  rw [← Hf, ← Hg]
  rw [P.assoc, P.assoc]
  rw [← P.distL]
  rw [Hsum]
  exact P.idR h'

/-- 引理 4.1.6：(C, p1, p2) 是 A 与 B 的积 -/
def biproduct_is_product {a b c x : P.Obj}
    (p1 : P.Hom c a) (p2 : P.Hom c b) (q1 : P.Hom a c) (q2 : P.Hom b c)
    (H11 : P.comp q1 p1 = P.idn a) (H22 : P.comp q2 p2 = P.idn b)
    (H12 : P.comp q2 p1 = P.zero b a) (H21 : P.comp q1 p2 = P.zero a b)
    (Hsum : P.add (P.comp p1 q1) (P.comp p2 q2) = P.idn c)
    (f : P.Hom x a) (g : P.Hom x b) :
    { h : P.Hom x c //
      P.comp h p1 = f ∧ P.comp h p2 = g ∧
      ∀ h', P.comp h' p1 = f → P.comp h' p2 = g → h' = h } :=
  ⟨bpMed q1 q2 f g,
    bpMed_p1 P q1 q2 p1 H11 H12 f g,
    bpMed_p2 P q1 q2 p2 H22 H21 f g,
    fun h' Hf Hg => bpMed_unique P q1 q2 p1 p2 Hsum f g h' Hf Hg⟩

end Biproduct
end Preadd
