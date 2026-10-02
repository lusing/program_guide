-- ex10 —— 等化子与拉回
-- 三书对位：贺伟 2.2/2.4 /《高级范畴论》3.3–3.4 / Simmons 2.6–2.7
--
-- 旗舰抽象定理：单态射的拉回仍是单态射（零公理）；
-- TyCat 具体纤维积用 Subtype（Subtype.ext 免费给唯一性）。

structure Category where
  Obj : Type u
  Hom : Obj → Obj → Type v
  idn : ∀ a, Hom a a
  comp : ∀ {a b c}, Hom a b → Hom b c → Hom a c
  idL : ∀ {a b} (f : Hom a b), comp (idn a) f = f
  idR : ∀ {a b} (f : Hom a b), comp f (idn b) = f
  assoc : ∀ {a b c d} (f : Hom a b) (g : Hom b c) (h : Hom c d),
    comp (comp f g) h = comp f (comp g h)

/-- 单态射 -/
def Mono (C : Category.{u, v}) (a b : C.Obj) (f : C.Hom a b) : Prop :=
  ∀ (c : C.Obj) (g h : C.Hom c a), C.comp g f = C.comp h f → g = h

/-- 拉回：p1;f = p2;g 的泛方块（存在 + 唯一） -/
structure IsPullback (C : Category.{u, v}) (a b c p : C.Obj)
    (f : C.Hom a c) (g : C.Hom b c) (p1 : C.Hom p a) (p2 : C.Hom p b) :
    Type (max u v) where
  square : C.comp p1 f = C.comp p2 g
  univ : ∀ (x : C.Obj) (u : C.Hom x a) (v : C.Hom x b),
      C.comp u f = C.comp v g →
      Σ' m : C.Hom x p,
        (C.comp m p1 = u ∧ C.comp m p2 = v)
          ∧ ∀ m', C.comp m' p1 = u → C.comp m' p2 = v → m' = m

/-! 【旗舰】单态射的拉回仍是单态射：让 u、v 竞争同一个锥，
v;p1 = u;p1 由 f 的单性逼出——只用定律、唯一性与单性。 -/
theorem pb_of_mono {C : Category.{u, v}} {a b c p : C.Obj}
    {f : C.Hom a c} {g : C.Hom b c} {p1 : C.Hom p a} {p2 : C.Hom p b}
    (pb : IsPullback C a b c p f g p1 p2) (Hf : Mono C a c f) :
    Mono C p b p2 := by
  obtain ⟨sq, univ⟩ := pb
  intro x u v Huv
  have Hcone : C.comp (C.comp u p1) f = C.comp (C.comp u p2) g := by
    rw [C.assoc u p1 f, C.assoc u p2 g, sq]
  obtain ⟨m, ⟨_, _⟩, muniq⟩ := univ x (C.comp u p1) (C.comp u p2) Hcone
  have Hu : u = m := muniq u rfl rfl
  -- v;p1 = u;p1：两边后复合 f 后都化到 (u;p2);g
  have Evp1 : C.comp v p1 = C.comp u p1 :=
    Hf x (C.comp v p1) (C.comp u p1) (by
      rw [C.assoc v p1 f, C.assoc u p1 f, sq, ← C.assoc v p2 g, ← Huv]
      exact C.assoc u p2 g)
  have Hv : v = m := muniq v Evp1 (by rw [← Huv])
  rw [Hu, Hv]

/-! 【TyCat】具体纤维积：{ p : A × B | f p.1 = g p.2 } -/
def TyCat : Category.{1, 0} where
  Obj := Type 0
  Hom := fun A B => A → B
  idn := fun _ => fun x => x
  comp := fun f g => fun x => g (f x)
  idL := fun _ => rfl
  idR := fun _ => rfl
  assoc := fun _ _ _ => rfl

def tyPullback (A B C0 : Type 0) (f : A → C0) (g : B → C0) :
    IsPullback TyCat A B C0 { p : A × B // f p.1 = g p.2 } f g
      (fun p => p.val.1) (fun p => p.val.2) := by
  refine ⟨funext fun z => z.2, fun x u v Huv => ?_⟩
  refine ⟨fun z => ⟨(u z, v z), congrFun Huv z⟩, ⟨rfl, rfl⟩, ?_⟩
  intro m' e1 e2
  funext z
  -- Subtype.ext 只比载体；载体相等由两条投影方程逐点给出
  apply Subtype.ext
  have hx1 : (m' z).val.1 = u z := congrFun e1 z
  have hx2 : (m' z).val.2 = v z := congrFun e2 z
  exact Prod.ext hx1 hx2

#check @pb_of_mono

/-! 坑位速记：
1. 「竞争同一个锥」的机器骨架：muniq 三连发（u 自己、v 换向、
   合并）；Evp1 的换向链 assoc → sq → ←assoc → ←Huv 每步对齐方向。
2. TyCat 拉回的载体方程用 `funext fun z => z.2`（sig 的证据即方程）；
   中介函数的证据项 `⟨(u z, v z), by rw [← Huv]; rfl⟩`。
3. Subtype.ext 只比载体——唯一性收尾比 Coq 的 PI 显式得多。 -/
