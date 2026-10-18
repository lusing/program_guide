-- ex13 —— 伴随的三副面孔
-- 三书对位：贺伟 3.1 /《高级范畴论》5.2–5.4 / Simmons 5.1
--
-- 单位-余单位定义 + hom-双射的往返等式（三角恒等式的机器内核）。

structure Category where
  Obj : Type u
  Hom : Obj → Obj → Type v
  idn : ∀ a, Hom a a
  comp : ∀ {a b c}, Hom a b → Hom b c → Hom a c
  idL : ∀ {a b} (f : Hom a b), comp (idn a) f = f
  idR : ∀ {a b} (f : Hom a b), comp f (idn b) = f
  assoc : ∀ {a b c d} (f : Hom a b) (g : Hom b c) (h : Hom c d),
    comp (comp f g) h = comp f (comp g h)

structure FunctorC (C : Category.{u, v}) (D : Category.{u', v'}) where
  FObj : C.Obj → D.Obj
  FHom : ∀ {a b}, C.Hom a b → D.Hom (FObj a) (FObj b)
  Fid : ∀ a, FHom (C.idn a) = D.idn (FObj a)
  Fcomp : ∀ {a b c} (f : C.Hom a b) (g : C.Hom b c),
    FHom (C.comp f g) = D.comp (FHom f) (FHom g)

/-- 伴随：η/ε 分量族 + 自然性 + 三角恒等式（分量内联，免 NT record） -/
structure Adjunction {C : Category.{u, v}} {D : Category.{u', v'}}
    (F : FunctorC C D) (G : FunctorC D C) : Type (max u u' v v') where
  eta : ∀ c, C.Hom c (G.FObj (F.FObj c))
  eta_nat : ∀ {a b} (f : C.Hom a b),
    C.comp f (eta b) = C.comp (eta a) (G.FHom (F.FHom f))
  eps : ∀ d, D.Hom (F.FObj (G.FObj d)) d
  eps_nat : ∀ {a b} (f : D.Hom a b),
    D.comp (F.FHom (G.FHom f)) (eps b) = D.comp (eps a) f
  tri1 : ∀ c, D.comp (F.FHom (eta c)) (eps (F.FObj c)) = D.idn (F.FObj c)
  tri2 : ∀ d, C.comp (eta (G.FObj d)) (G.FHom (eps d)) = C.idn (G.FObj d)

/-- hom-双射的两个方向 -/
def adjPhi {C : Category.{u, v}} {D : Category.{u', v'}}
    {F : FunctorC C D} {G : FunctorC D C} (A : Adjunction F G)
    (c : C.Obj) (d : D.Obj) (f : D.Hom (F.FObj c) d) : C.Hom c (G.FObj d) :=
  C.comp (A.eta c) (G.FHom f)

def adjPsi {C : Category.{u, v}} {D : Category.{u', v'}}
    {F : FunctorC C D} {G : FunctorC D C} (A : Adjunction F G)
    (c : C.Obj) (d : D.Obj) (g : C.Hom c (G.FObj d)) : D.Hom (F.FObj c) d :=
  D.comp (F.FHom g) (A.eps d)

/-- 往返 1：ψ(φ f) = f —— 三角恒等式 + ε 自然性 -/
theorem adj_round1 {C : Category.{u, v}} {D : Category.{u', v'}}
    {F : FunctorC C D} {G : FunctorC D C} (A : Adjunction F G)
    (c : C.Obj) (d : D.Obj) (f : D.Hom (F.FObj c) d) :
    adjPsi A c d (adjPhi A c d f) = f := by
  show D.comp (F.FHom (C.comp (A.eta c) (G.FHom f))) (A.eps d) = f
  rw [F.Fcomp (A.eta c) (G.FHom f),
      D.assoc (F.FHom (A.eta c)) (F.FHom (G.FHom f)) (A.eps d),
      A.eps_nat f,
      ← D.assoc (F.FHom (A.eta c)) (A.eps (F.FObj c)) f,
      A.tri1 c,
      D.idL f]

#print axioms adj_round1   -- 零公理

/-! 【文档层】三面孔等价：hom-双射 ⟺ 泛映射 ⟺ 单位-余单位
（贺伟 3.1 三条路线；完整等价证明要 NT 基础设施 + 选择）。
往返 2（φ∘ψ = id）对称地用 eta_nat + tri2。 -/

/-! 坑位速记：
1. `show` 先把两层投影折叠到 comp 位置，rw 链才有落点
   （五步：Fcomp 并 → assoc 拆 → eps_nat → assoc 并 → tri1 → idL）。
2. Adjunction 按分量内联 η/ε——绕开 06 章 NT 的依赖字段。 -/
