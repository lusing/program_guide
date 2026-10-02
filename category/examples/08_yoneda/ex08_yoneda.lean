-- ex08 —— Yoneda 引理与可表函子
-- 三书对位：贺伟《范畴论》1.6 /《高级范畴论》4.3 / Simmons 3.5
--
-- Nat(Hom(a,-), F) ≅ F a：
--   φ(X)  := X_a(id_a)         （在 id 处取样）
--   ψ(x)_b(g) := F g(x)        （沿 g 搬运取样）
-- 往返 1 用 Fid 白送；往返 2 恰是自然性在 id 处的特例。
-- Lean 版给出**完整 record 相等**的往返 2（cases + congr 1 +
-- 内核证明无关性——06 章的裂缝在这里被结构 η 缝合）。

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

structure NT {C : Category.{u, v}} {D : Category.{u', v'}}
    (F G : FunctorC C D) where
  ncomp : ∀ a, D.Hom (F.FObj a) (G.FObj a)
  nlaw : ∀ {a b} (f : C.Hom a b),
    D.comp (F.FHom f) (ncomp b) = D.comp (ncomp a) (G.FHom f)

/-- 舞台：Set 的化身 -/
def TyCat : Category.{1, 0} where
  Obj := Type 0
  Hom := fun A B => A → B
  idn := fun _ => fun x => x
  comp := fun f g => fun x => g (f x)
  idL := fun _ => rfl
  idR := fun _ => rfl
  assoc := fun _ _ _ => rfl

/-- hom-函子 Hom(a, -) : C → TyCat -/
def homFun (C : Category.{0, 0}) (a : C.Obj) : FunctorC C TyCat where
  FObj := fun b => C.Hom a b
  FHom := fun f => fun g => C.comp g f
  Fid := fun _ => funext C.idR
  Fcomp := fun f g => funext fun h => (C.assoc h f g).symm

/-! 【Yoneda 的两个映射】 -/
/-- ψ：取样 x ↦ 自然变换「沿 g 搬运」 -/
def yonedaTo {C : Category.{0, 0}} {F : FunctorC C TyCat} {a : C.Obj}
    (x : F.FObj a) : NT (homFun C a) F where
  ncomp := fun b g => F.FHom g x
  nlaw := by
    intro a₀ b₀ f
    funext g
    -- F(g;f) x = Ff(Fg x)：Fcomp 反方向搬运「采样点」
    show F.FHom (C.comp g f) x = F.FHom f (F.FHom g x)
    rw [F.Fcomp g f]
    rfl

/-- φ：自然变换 ↦ 在 id 处取样 -/
def yonedaFrom {C : Category.{0, 0}} {F : FunctorC C TyCat} {a : C.Obj}
    (X : NT (homFun C a) F) : F.FObj a :=
  X.ncomp a (C.idn a)

/-! 【往返 1】φ(ψ(x)) = x —— Fid 白送 -/
theorem yoneda_round1 {C : Category.{0, 0}} {F : FunctorC C TyCat} {a : C.Obj}
    (x : F.FObj a) : yonedaFrom (yonedaTo x) = x := by
  show F.FHom (C.idn a) x = x
  rw [F.Fid a]
  rfl

/-! 【往返 2】ψ(φ(X)) = X —— 自然性在 id 处的特例。
完整 record 相等：cases/congr 之后 nlaw 字段被内核证明无关性拍平，
只剩分量目标（06 章的裂缝在 Lean 这边缝合）。 -/
theorem yoneda_round2 {C : Category.{0, 0}} {F : FunctorC C TyCat} {a : C.Obj}
    (X : NT (homFun C a) F) : yonedaTo (yonedaFrom X) = X := by
  obtain ⟨Xc, Xl⟩ := X
  simp only [yonedaTo, yonedaFrom]
  congr 1
  funext b
  funext g
  -- X 的自然性方程（两函数相等）作用到 id_a 上取样，再 idL 换向
  have h : Xc b (C.comp (C.idn a) g) = F.FHom g (Xc a (C.idn a)) :=
    congrFun (Xl g) (C.idn a)
  rw [C.idL g] at h
  exact h.symm

#print axioms yoneda_round1   -- funext 的地基（Quot.sound/propext，内建）
#print axioms yoneda_round2   -- 同上；无外加公理

/-! 【可表函子（贺伟 1.6）】
F 可表 ⟺ F ≅ Hom(a, -)。取 F := homFun C a 本身，Yoneda 给出
Nat(Hom a, Hom a) ≅ Hom C a a：hom-函子的自变换 = 中对象的自态射
——「对象由它的泛态射决定」。Yoneda 嵌入（a ↦ Hom(a,-)）全忠实
是本引理的直接推论，完整机器化留作边界（需要伴随/极限语言）。 -/

/-! 坑位速记：
1. yonedaTo 的 naturality：show 把投影链折叠到点级，再 Fcomp。
2. yoneda_round2 的关键一招：congrFun (X.nlaw g) (C.idn a)——
   把自然性方程作用到 id 上取样（教科书「拆 g = id;g」的机器版），
   换向用 C.idL g。
3. Lean 版的往返 2 是 record 级相等（congr 1 + 内核 PI）；
   Coq 版止步于分量级、Agda 版走 ≈NT——三家对同一裂缝的三种
   缝法，这是全书的分水岭之一。
4. `show F.FHom (C.comp g f) x = ...` 用定义相等把两层投影
   （TyCat.comp、homFun.FHom）的 β 折叠显式化，rw 才有落点。 -/
