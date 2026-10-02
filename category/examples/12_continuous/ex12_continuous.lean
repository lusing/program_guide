-- ex12 —— 保持极限的函子：可表函子保积
-- 三书对位：贺伟 2.6 / Simmons 3.5 / 高级 5.6 前置
--
-- Hom(c, -) 把积变成积：泛性质穿过 hom 集（Yoneda 推论的实践版）。

structure Category where
  Obj : Type u
  Hom : Obj → Obj → Type v
  idn : ∀ a, Hom a a
  comp : ∀ {a b c}, Hom a b → Hom b c → Hom a c
  idL : ∀ {a b} (f : Hom a b), comp (idn a) f = f
  idR : ∀ {a b} (f : Hom a b), comp f (idn b) = f
  assoc : ∀ {a b c d} (f : Hom a b) (g : Hom b c) (h : Hom c d),
    comp (comp f g) h = comp f (comp g h)

def IsProduct (C : Category.{u, v}) (a b p : C.Obj)
    (p1 : C.Hom p a) (p2 : C.Hom p b) : Type (max u v) :=
  ∀ (c : C.Obj) (f : C.Hom c a) (g : C.Hom c b),
    Σ' h : C.Hom c p,
      (C.comp h p1 = f ∧ C.comp h p2 = g)
        ∧ ∀ h', C.comp h' p1 = f → C.comp h' p2 = g → h' = h

/-- Hom(c, A×B) 的配对存在（hom 层的「保积」满方向） -/
def hom_preserves_product {C : Category.{u, v}} {a b p : C.Obj}
    {p1 : C.Hom p a} {p2 : C.Hom p b} (HP : IsProduct C a b p p1 p2)
    (c : C.Obj) (f : C.Hom c a) (g : C.Hom c b) :
    Σ' h : C.Hom c p, C.comp h p1 = f ∧ C.comp h p2 = g :=
  ⟨(HP c f g).1, ((HP c f g).2.1)⟩

/-- hom 层的配对唯一（泛性质直通 hom 集） -/
theorem hom_product_unique {C : Category.{u, v}} {a b p : C.Obj}
    {p1 : C.Hom p a} {p2 : C.Hom p b} (HP : IsProduct C a b p p1 p2)
    (c : C.Obj) (h h' : C.Hom c p)
    (E1 : C.comp h p1 = C.comp h' p1) (E2 : C.comp h p2 = C.comp h' p2) :
    h = h' := by
  obtain ⟨m, _, muniq⟩ := HP c (C.comp h p1) (C.comp h p2)
  have Hh : h = m := muniq h rfl rfl
  have Hh' : h' = m := muniq h' E1.symm E2.symm
  rw [Hh, Hh']

#print axioms hom_preserves_product   -- 零外加公理
#print axioms hom_product_unique      -- 零外加公理

/-! 【文档层】一般定理「可表函子保持全部极限」由 Yoneda 推广；
「右伴随保极限」（贺伟 3.6/高级 5.6）见 15 章。 -/

/-! 坑位速记：
1. 「保积」的两种陈述：对象层 vs hom 层——后者不需要目标范畴
   有积，是抽象证明的正确形态。
2. 唯一性的「双取样」套路：h 与 h' 各喂一次 muniq（后者方程
   取 sym），再合一——与 09/10 章同一招式。 -/
