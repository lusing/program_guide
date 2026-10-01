-- ex03 —— 特殊态射与特殊对象
-- 三书对位：贺伟《范畴论》1.4 /《高级范畴论》第 2 章 / Simmons 2.2
--
-- mono/epi 用「消去性质」定义（Prop）；iso/分裂态射带数据用 structure；
-- 抽象证明只用三条定律——范畴论「泛性质推理」的第一课。
-- Lean 的 funext 是核心定理（Quot.sound 的推论），本章全程零公理。

structure Category where
  Obj : Type u
  Hom : Obj → Obj → Type v
  idn : ∀ a, Hom a a
  comp : ∀ {a b c}, Hom a b → Hom b c → Hom a c
  idL : ∀ {a b} (f : Hom a b), comp (idn a) f = f
  idR : ∀ {a b} (f : Hom a b), comp f (idn b) = f
  assoc : ∀ {a b c d} (f : Hom a b) (g : Hom b c) (h : Hom c d),
    comp (comp f g) h = comp f (comp g h)

/-- 单态射：左可消去（Prop 值的泛性质） -/
def Mono (C : Category.{u, v}) (a b : C.Obj) (f : C.Hom a b) : Prop :=
  ∀ (c : C.Obj) (g h : C.Hom c a), C.comp g f = C.comp h f → g = h

/-- 满态射：右可消去 -/
def Epi (C : Category.{u, v}) (a b : C.Obj) (f : C.Hom a b) : Prop :=
  ∀ (c : C.Obj) (g h : C.Hom b c), C.comp f g = C.comp f h → g = h

/-- 分裂单态射：有 retraction（f;r = id）——《高级范畴论》2.1 -/
structure SplitMono (C : Category.{u, v}) (a b : C.Obj) (f : C.Hom a b) where
  retr : C.Hom b a
  law : C.comp f retr = C.idn a

/-- 同构：有双侧逆 -/
structure IsIso (C : Category.{u, v}) (a b : C.Obj) (f : C.Hom a b) where
  inv : C.Hom b a
  inv_r : C.comp f inv = C.idn a
  inv_l : C.comp inv f = C.idn b

/-- 终对象：每个对象恰有一条到它的态射（Σ' 混居 Prop 与数据） -/
def Terminal (C : Category.{u, v}) (t : C.Obj) : Type (max u v) :=
  ∀ a, Σ' f : C.Hom a t, ∀ g, g = f

/-- 初始对象：恰有一条从它出发的态射 -/
def Initial (C : Category.{u, v}) (i : C.Obj) : Type (max u v) :=
  ∀ a, Σ' f : C.Hom i a, ∀ g, g = f

/-! 【旗舰】分裂单态射必单：整个证明只是 assoc/idL/idR 的重写串，
在任意范畴成立——不涉及任何元素。 -/
theorem splitMonoMono (C : Category.{u, v}) {a b : C.Obj} (f : C.Hom a b)
    (sm : SplitMono C a b f) : Mono C a b f := by
  obtain ⟨r, hr⟩ := sm
  intro c g h H
  rw [← C.idR g, ← hr, ← C.assoc g f r, H, C.assoc h f r, hr, C.idR h]

/-- 同构必是满态射（对偶侧的同串重写） -/
theorem isoEpi (C : Category.{u, v}) {a b : C.Obj} (f : C.Hom a b)
    (iso : IsIso C a b f) : Epi C a b f := by
  obtain ⟨g, h1, h2⟩ := iso
  intro c u v H
  rw [← C.idL u, ← h2, C.assoc g f u, H, ← C.assoc g f v, h2, C.idL v]

/-- 反范畴 -/
def opposite (C : Category.{u, v}) : Category.{u, v} where
  Obj := C.Obj
  Hom := fun a b => C.Hom b a
  idn := fun a => C.idn a
  comp := fun f g => C.comp g f
  idL := fun f => C.idR f
  idR := fun f => C.idL f
  assoc := fun f g h => (C.assoc h g f).symm

/-- 对偶翻译：C 的终对象 = C^op 的初始对象（Hom_op t a = Hom C a t 定义相等） -/
def terminal_opp (C : Category.{u, v}) (t : C.Obj) (H : Terminal C t) :
    Initial (opposite C) t := H

/-! 【FinCat】有限集范畴的骨架 -/
def FinCat : Category where
  Obj := Nat
  Hom := fun m n => Fin m → Fin n
  idn := fun _ => fun x => x
  comp := fun f g => fun x => g (f x)
  idL := fun _ => rfl
  idR := fun _ => rfl
  assoc := fun _ _ _ => rfl

/-- mono ⇒ 单射（元素 x 看成 1 → m 的常值态射） -/
theorem mono_inj {m n : Nat} (f : Fin m → Fin n) (Hm : Mono FinCat m n f)
    {x y : Fin m} (h : f x = f y) : x = y := by
  have Hg : (fun _ : Fin 1 => x) = (fun _ => y) := by
    apply Hm (1 : Nat) (fun _ => x) (fun _ => y)
    funext z
    exact h                       -- (fun w => f x) z β→ f x
  exact congrFun Hg 0             -- 在 0 处取值：x = y

/-- 单射 ⇒ mono -/
theorem inj_mono {m n : Nat} (f : Fin m → Fin n)
    (Hinj : ∀ x y : Fin m, f x = f y → x = y) : Mono FinCat m n f := by
  intro c g h H
  funext z
  exact Hinj (g z) (h z) (congrFun H z)

/-- 满射 ⇒ epi（逆像处比较）。反方向要有限搜索或经典逻辑，作边界记录 -/
theorem surj_epi {m n : Nat} (f : Fin m → Fin n)
    (Hs : ∀ y : Fin n, ∃ x : Fin m, f x = y) : Epi FinCat m n f := by
  intro c g h H
  funext z
  obtain ⟨x, hx⟩ := Hs z
  calc g z = g (f x) := by rw [hx]
    _ = h (f x) := congrFun H x
    _ = h z := by rw [hx]

/-- Fin 1 只有一个元素 -/
theorem fin1_only (z : Fin 1) : z = 0 := Fin.ext (by omega)

/-- FinCat 的终对象 = 1 -/
def finOne_terminal : Terminal FinCat (1 : Nat) :=
  fun _ => ⟨fun _ => 0, fun g => funext fun z => fin1_only (g z)⟩

/-- FinCat 的初始对象 = 0 -/
def finZero_initial : Initial FinCat (0 : Nat) :=
  fun a => ⟨fun x => x.elim0, fun g => funext fun z => absurd z.2 (by omega)⟩

/-! 【零对象】OneCat 的唯一对象既终又始 -/
def OneCat : Category where
  Obj := Unit
  Hom := fun _ _ => Unit
  idn := fun _ => ()
  comp := fun _ _ => ()
  idL := fun _ => Unit.ext ..
  idR := fun _ => Unit.ext ..
  assoc := fun _ _ _ => rfl

def one_terminal : Terminal OneCat () := fun _ => ⟨(), fun _ => Unit.ext ..⟩

def one_initial : Initial OneCat () := fun _ => ⟨(), fun _ => Unit.ext ..⟩

#print axioms splitMonoMono   -- 零公理（纯定律推理）
#print axioms isoEpi          -- 零公理
#print axioms mono_inj        -- [propext, Quot.sound]：funext 的地基，Lean 内建
#print axioms finOne_terminal -- [propext, Quot.sound]

/-! 坑位速记：
1. 泛性质的层级三分：消去律（Mono/Epi）是 Prop；带逆/收缩数据的
   （IsIso/SplitMono）用 structure 落 Type v；「存在+唯一」的
   Terminal 用 Σ'（Σ 不收 Prop 分量，PSigma 才混居）。
2. `congrFun H z`：从函数相等取「点」的官方通道（Coq 里是
   f_equal (fun k => k z) H + simpl）。
3. funext 在 Lean 是定理：`funext z` 也是 tactic；Coq/Agda 要
   公理入账——三文化的分岔点。
4. `Unit.ext ..` 证 `f = ()`（f 是变量）；Fin 0 的唯一性用
   `absurd z.2 (by omega)`（z.1 < 0 不可能）。
5. `Terminal FinCat 1` 里数字推不出 OfNat——`(1 : Nat)` 标注。
6. isoEpi 的重写串与 splitMonoMono 镜像：idL↔idR、assoc 方向翻
   ——对偶原理在证明层面的样子。 -/