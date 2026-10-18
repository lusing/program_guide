-- ex11 —— 极限的一般理论（图 = 函子、锥、泛锥）
-- 三书对位：贺伟 2.1 / Simmons 第 4 章 /《高级范畴论》3.5
--
-- 机器内容：常值函子 + Cone2/IsLimit2（二元离散形状的展开版）
-- + 「二元图的极限 = 积」双向包装引理（零公理）。

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

/-- 常值函子 Δc -/
def constFun (C : Category.{u, v}) (D : Category.{u', v'}) (c : D.Obj) :
    FunctorC C D where
  FObj := fun _ => c
  FHom := fun _ => D.idn c
  Fid := fun _ => rfl
  Fcomp := fun _ _ => (D.idL (D.idn c)).symm

/-- 二元形状的锥：两条腿 -/
structure Cone2 (C : Category.{u, v}) (a b x : C.Obj) where
  leg1 : C.Hom x a
  leg2 : C.Hom x b

/-- 二元形状的极限 = 泛锥 -/
structure IsLimit2 (C : Category.{u, v}) (a b p : C.Obj)
    (π1 : C.Hom p a) (π2 : C.Hom p b) : Type (max u v) where
  limCone : Cone2 C a b p
  limUniv : ∀ (x : C.Obj) (k : Cone2 C a b x),
    Σ' h : C.Hom x p,
      (C.comp h π1 = k.leg1 ∧ C.comp h π2 = k.leg2)
        ∧ ∀ h', C.comp h' π1 = k.leg1 → C.comp h' π2 = k.leg2 → h' = h

/-- 二元图的极限 = 积（泛性质逐字段对应） -/
def limit2_as_product {C : Category.{u, v}} {a b p : C.Obj}
    {π1 : C.Hom p a} {π2 : C.Hom p b} (L : IsLimit2 C a b p π1 π2)
    (c : C.Obj) (f : C.Hom c a) (g : C.Hom c b) :
    Σ' h : C.Hom c p,
      (C.comp h π1 = f ∧ C.comp h π2 = g)
        ∧ ∀ h', C.comp h' π1 = f → C.comp h' π2 = g → h' = h :=
  ⟨(L.limUniv c ⟨f, g⟩).1,
    ⟨((L.limUniv c ⟨f, g⟩).2.1),
     fun h' e1 e2 => (L.limUniv c ⟨f, g⟩).2.2 h' e1 e2⟩⟩

/-- 反向：积给二元图的极限 -/
def product_as_limit2 {C : Category.{u, v}} {a b p : C.Obj} {π1 : C.Hom p a}
    {π2 : C.Hom p b}
    (P : ∀ (c : C.Obj) (f : C.Hom c a) (g : C.Hom c b),
      Σ' h : C.Hom c p,
        (C.comp h π1 = f ∧ C.comp h π2 = g)
          ∧ ∀ h', C.comp h' π1 = f → C.comp h' π2 = g → h' = h) :
    IsLimit2 C a b p π1 π2 where
  limCone := ⟨π1, π2⟩
  limUniv := fun x k => P x k.leg1 k.leg2

#check @limit2_as_product   -- 零外加公理
#check @product_as_limit2

/-! 【文档层要点】
1. 一般极限：D : I → C，锥 = (顶点 + 腿族 + 与图态射交换)，
   即 NT(Δc, D)；极限 = 终锥。Cone2/IsLimit2 是 I = 二元离散形状
   的展开版。
2. Set 的极限公式（Simmons 4.6.1）：lim D ⊆ ∏ D(i) 的等化子。
3. 完备范畴（贺伟 2.5）：有全部小极限 ⟺ 有乘积 + 等化子。
4. 对偶：余极限 = 反范畴的极限。 -/

/-! 坑位速记：
1. constFun 的 Fcomp 目标是 idn = idn;idn——`(D.idL _).symm`
   一条收（Coq 版走 symmetry + apply idL）。
2. 结构体的字段填充用 where + 具名字段（Lean）；
   Coq 用 refine {| limCone := ... |}。
3. Cone2 的访问用 k.leg1/k.leg2——结构投影点号。 -/
