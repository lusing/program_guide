-- ex09 —— 积与余积
-- 三书对位：贺伟《范畴论》2.3 /《高级范畴论》3.2 / Simmons 2.5
--
-- 积的泛性质（存在 + 唯一）；TyCat 里积 = 笛卡尔积；
-- 抽象定理：积由泛性质唯一（到同构）——只用唯一性推。

structure Category where
  Obj : Type u
  Hom : Obj → Obj → Type v
  idn : ∀ a, Hom a a
  comp : ∀ {a b c}, Hom a b → Hom b c → Hom a c
  idL : ∀ {a b} (f : Hom a b), comp (idn a) f = f
  idR : ∀ {a b} (f : Hom a b), comp f (idn b) = f
  assoc : ∀ {a b c d} (f : Hom a b) (g : Hom b c) (h : Hom c d),
    comp (comp f g) h = comp f (comp g h)

/-- 反范畴 -/
def opposite (C : Category.{u, v}) : Category.{u, v} where
  Obj := C.Obj
  Hom := fun a b => C.Hom b a
  idn := fun a => C.idn a
  comp := fun f g => C.comp g f
  idL := fun f => C.idR f
  idR := fun f => C.idL f
  assoc := fun f g h => (C.assoc h g f).symm

/-- 积的泛性质（存在 + 唯一） -/
def IsProduct (C : Category.{u, v}) (a b p : C.Obj)
    (p1 : C.Hom p a) (p2 : C.Hom p b) : Type (max u v) :=
  ∀ (c : C.Obj) (f : C.Hom c a) (g : C.Hom c b),
    Σ' h : C.Hom c p,
      (C.comp h p1 = f ∧ C.comp h p2 = g)
        ∧ ∀ h', C.comp h' p1 = f → C.comp h' p2 = g → h' = h

/-- 余积 = 反范畴里的积（对象次序掉头） -/
def IsCoproduct (C : Category.{u, v}) (a b q : C.Obj)
    (i1 : C.Hom a q) (i2 : C.Hom b q) : Type (max u v) :=
  IsProduct (opposite C) b a q i2 i1

/-- 同构箭头 -/
structure IsoArrow (C : Category.{u, v}) (a b : C.Obj) (f : C.Hom a b) where
  iinv : C.Hom b a
  ilaw1 : C.comp f iinv = C.idn a
  ilaw2 : C.comp iinv f = C.idn b

/-! 【抽象定理】积唯一到同构：两个积之间有典范同构，
证明只用唯一性——不看任何元素。 -/
def product_unique_iso {C : Category.{u, v}} {a b P Q : C.Obj}
    {p1 : C.Hom P a} {p2 : C.Hom P b} {q1 : C.Hom Q a} {q2 : C.Hom Q b}
    (HP : IsProduct C a b P p1 p2) (HQ : IsProduct C a b Q q1 q2) :
    Σ' f : C.Hom P Q, IsoArrow C P Q f := by
  obtain ⟨k, ⟨k1, k2⟩, _⟩ := HQ P p1 p2        -- k : P→Q
  obtain ⟨h, ⟨h1, h2⟩, _⟩ := HP Q q1 q2         -- h : Q→P
  obtain ⟨n, _, nuniq⟩ := HP P p1 p2            -- P 自身的中介
  obtain ⟨m, _, muniq⟩ := HQ Q q1 q2            -- Q 自身的中介
  have Hkh : C.comp k h = n :=
    nuniq (C.comp k h)
      (by rw [C.assoc k h p1, h1]; exact k1)
      (by rw [C.assoc k h p2, h2]; exact k2)
  have HidP : C.idn P = n := nuniq (C.idn P) (C.idL p1) (C.idL p2)
  have Hhk : C.comp h k = m :=
    muniq (C.comp h k)
      (by rw [C.assoc h k q1, k1]; exact h1)
      (by rw [C.assoc h k q2, k2]; exact h2)
  have HidQ : C.idn Q = m := muniq (C.idn Q) (C.idL q1) (C.idL q2)
  exact ⟨k, ⟨h, by rw [HidP]; exact Hkh, by rw [HidQ]; exact Hhk⟩⟩

#check @product_unique_iso   -- 零外加公理的泛性质推理

/-! 【TyCat】积 = 笛卡尔积；Prod 的 η 让配对唯一性几乎免费 -/
def TyCat : Category.{1, 0} where
  Obj := Type 0
  Hom := fun A B => A → B
  idn := fun _ => fun x => x
  comp := fun f g => fun x => g (f x)
  idL := fun _ => rfl
  idR := fun _ => rfl
  assoc := fun _ _ _ => rfl

def tyProduct (A B : Type 0) : IsProduct TyCat A B (A × B) Prod.fst Prod.snd := by
  intro c f g
  refine ⟨fun x => (f x, g x), ⟨rfl, rfl⟩, ?_⟩
  intro h' e1 e2
  funext x
  have hx1 : (h' x).1 = f x := congrFun e1 x
  have hx2 : (h' x).2 = g x := congrFun e2 x
  show h' x = (f x, g x)
  rw [← hx1, ← hx2]   -- 结构 η 自动收尾：(p.1, p.2) = p 是 rfl 级别

/-! 坑位速记：
1. `rw [C.assoc k h p1, h1]; exact k1` 的次序：assoc 并组 →
   h 的投影律 → k 的投影律——三条等式接力。
2. Lean 的结构 eta 对 × 免费给 `(p.1, p.2) = p`，
   cases h' x 后直接 rfl（Coq 要显式 destruct 满配对）。
3. `def tyProduct ... := ... where uniq : ... | h', e1, e2 => by`
   ——where 附属于 definition（合法），模式匹配处带名字。
4. IsProduct 的三层结构（Σ' h、方程对、唯一性）在三家分别用
   sigT/Σ/Σ'——「证据是数据」的选择决定宇宙层级。 -/
