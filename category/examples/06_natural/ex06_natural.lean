-- ex06 —— 自然变换、函子范畴与 Godement 积
-- 三书对位：贺伟《范畴论》1.3 /《高级范畴论》4.5–4.6 / Simmons 3.4–3.5
--
-- 自然变换 = 函子之间「一族态射」η_a : F a → G a，对每条态射交换。
-- Lean 的结构 η + 内核证明无关性让函子范畴 [C, D] 的定律
-- 以真正的 record 相等落地（Coq 要 PI 公理+原始投影、Agda 走
-- setoid——三家路线之别，详见 docs/06）。

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

/-- 自然变换 -/
structure NT {C : Category.{u, v}} {D : Category.{u', v'}}
    (F G : FunctorC C D) where
  ncomp : ∀ a, D.Hom (F.FObj a) (G.FObj a)
  nlaw : ∀ {a b} (f : C.Hom a b),
    D.comp (F.FHom f) (ncomp b) = D.comp (ncomp a) (G.FHom f)

/-! 【垂直复合与恒等】 -/
def vcomp {C : Category.{u, v}} {D : Category.{u', v'}} {F G H : FunctorC C D}
    (α : NT F G) (β : NT G H) : NT F H where
  ncomp := fun a => D.comp (α.ncomp a) (β.ncomp a)
  nlaw := by
    intro a b f
    rw [← D.assoc (F.FHom f) (α.ncomp b) (β.ncomp b),
        α.nlaw f,
        D.assoc (α.ncomp a) (G.FHom f) (β.ncomp b),
        β.nlaw f,
        ← D.assoc (α.ncomp a) (β.ncomp a) (H.FHom f)]

def vid {C : Category.{u, v}} {D : Category.{u', v'}} {F : FunctorC C D} :
    NT F F where
  ncomp := fun a => D.idn (F.FObj a)
  nlaw := by
    intro a b f
    rw [D.idR (F.FHom f), D.idL (F.FHom f)]

/-! 【函子范畴定律】cases + congr 1：nlaw 字段（依赖 ncomp 的 Prop）
作为两个证明被内核证明无关性自动拍平——只剩分量目标。 -/
theorem vcomp_assoc {C : Category.{u, v}} {D : Category.{u', v'}}
    {F G H K : FunctorC C D} (α : NT F G) (β : NT G H) (γ : NT H K) :
    vcomp (vcomp α β) γ = vcomp α (vcomp β γ) := by
  cases α
  cases β
  cases γ
  simp only [vcomp]
  congr 1
  · exact funext fun a => D.assoc _ _ _

theorem vcomp_idR {C : Category.{u, v}} {D : Category.{u', v'}}
    {F G : FunctorC C D} (α : NT F G) : vcomp α vid = α := by
  cases α
  simp only [vcomp, vid]
  congr 1
  · exact funext fun a => D.idR _

theorem vcomp_idL {C : Category.{u, v}} {D : Category.{u', v'}}
    {F G : FunctorC C D} (α : NT F G) : vcomp vid α = α := by
  cases α
  simp only [vcomp, vid]
  congr 1
  · exact funext fun a => D.idL _

/-! 于是 [C, D] 是范畴：对象 = 函子、态射 = 自然变换（真 record 相等）。 -/

/-- 函子复合 -/
def compFun {C : Category.{u, v}} {D : Category.{u', v'}} {E : Category.{u'', v''}}
    (G : FunctorC D E) (F : FunctorC C D) : FunctorC C E where
  FObj := fun a => G.FObj (F.FObj a)
  FHom := fun f => G.FHom (F.FHom f)
  Fid := by
    intro a
    rw [F.Fid a, G.Fid]
  Fcomp := by
    intro a b c f g
    rw [F.Fcomp f g, G.Fcomp]

/-! 【Godement 积（水平复合）】α : F ⇒ G（C→D 内），β : H ⇒ K（D→E 内）：
β ⋆ α : H∘F ⇒ K∘G，分量 (β ⋆ α)_a = H(α_a);β_{G a} -/
def hcomp {C : Category.{u, v}} {D : Category.{u', v'}} {E : Category.{u'', v''}}
    {F G : FunctorC C D} {H K : FunctorC D E}
    (α : NT F G) (β : NT H K) : NT (compFun H F) (compFun K G) where
  ncomp := fun a => E.comp (H.FHom (α.ncomp a)) (β.ncomp (G.FObj a))
  nlaw := by
    intro a b f
    -- 先把 compFun 的投影按定义展开（rfl 即可）
    rw [show (compFun H F).FHom f = H.FHom (F.FHom f) from rfl,
        show (compFun K G).FHom f = K.FHom (G.FHom f) from rfl]
    -- 五步追图：并组 → 函子性进 H → α 的自然性 → β 的自然性 → 拆组
    rw [show E.comp (H.FHom (F.FHom f)) (E.comp (H.FHom (α.ncomp b)) (β.ncomp (G.FObj b)))
          = E.comp (E.comp (H.FHom (F.FHom f)) (H.FHom (α.ncomp b))) (β.ncomp (G.FObj b))
        from (E.assoc _ _ _).symm,
        ← H.Fcomp (F.FHom f) (α.ncomp b),
        α.nlaw f,
        H.Fcomp (α.ncomp a) (G.FHom f),
        E.assoc (H.FHom (α.ncomp a)) (H.FHom (G.FHom f)) (β.ncomp (G.FObj b)),
        β.nlaw (G.FHom f),
        show E.comp (H.FHom (α.ncomp a)) (E.comp (β.ncomp (G.FObj a)) (K.FHom (G.FHom f)))
          = E.comp (E.comp (H.FHom (α.ncomp a)) (β.ncomp (G.FObj a))) (K.FHom (G.FHom f))
        from (E.assoc _ _ _).symm]

#print axioms vcomp_assoc   -- 零外加公理（funext 是核心定理）
#print axioms hcomp         -- 零公理：纯方块追图

/-! 【具体例子】reverse 是 List 函子的自变换 -/
def TyCat : Category.{1, 0} where
  Obj := Type 0
  Hom := fun A B => A → B
  idn := fun _ => fun x => x
  comp := fun f g => fun x => g (f x)
  idL := fun _ => rfl
  idR := fun _ => rfl
  assoc := fun _ _ _ => rfl

theorem map_id_pointwise {A : Type 0} : ∀ (l : List A), List.map (fun x => x) l = l := by
  intro l
  induction l with
  | nil => rfl
  | cons x l ih => simp only [List.map_cons, ih]

theorem map_comp_pointwise {A B C : Type 0} (f : A → B) (g : B → C) :
    ∀ (l : List A), List.map (fun x => g (f x)) l = List.map g (List.map f l) := by
  intro l
  induction l with
  | nil => rfl
  | cons x l ih => simp only [List.map_cons, ih]

def listFun : FunctorC TyCat TyCat where
  FObj := fun A => List A
  FHom := fun f => List.map f
  Fid := fun _ => funext map_id_pointwise
  Fcomp := fun f g => funext (map_comp_pointwise f g)

theorem rev_map_pointwise {A B : Type 0} (f : A → B) :
    ∀ (l : List A), List.reverse (List.map f l) = List.map f (List.reverse l) := by
  intro l
  induction l with
  | nil => rfl
  | cons x l ih =>
      simp only [List.map_cons, List.reverse_cons, List.map_append, List.map_nil]
      rw [ih]

def revNT : NT listFun listFun where
  ncomp := fun A => List.reverse
  nlaw := by
    intro A B f
    exact funext (rev_map_pointwise f)

/-! 坑位速记：
1. 依赖字段 record 相等的 Lean 解法：`cases` + `congr 1`——
   nlaw 字段是「依赖 ncomp 的 Prop」的两个证明，内核 PI 自动拍平，
   congr 只留下分量目标（Coq 同型问题无原始投影时无解、Agda setoid）。
2. `(compFun H F).FHom f` 的投影展开用 `rw [show ... from rfl]`
   先行——后续 rewrite 才匹配得上。
3. vid 的 nlaw 两条 rw 都用正向（先 idR 后 idL）；一条反向会把
   已改好的左侧又改回去。
4. rev_map 的 cons 分支交给 simp（reverse_cons + map_append + ih），
   比 simp only 列引理名稳。 -/
