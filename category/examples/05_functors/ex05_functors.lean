-- ex05 —— 函子
-- 三书对位：贺伟《范畴论》1.2 /《高级范畴论》4.1–4.3 / Simmons 3.1–3.3
--
-- 函子 = 范畴之间的「保结构映射」：保恒等、保复合。
-- 它把整个交换图的世界整体搬运。

structure Category where
  Obj : Type u
  Hom : Obj → Obj → Type v
  idn : ∀ a, Hom a a
  comp : ∀ {a b c}, Hom a b → Hom b c → Hom a c
  idL : ∀ {a b} (f : Hom a b), comp (idn a) f = f
  idR : ∀ {a b} (f : Hom a b), comp f (idn b) = f
  assoc : ∀ {a b c d} (f : Hom a b) (g : Hom b c) (h : Hom c d),
    comp (comp f g) h = comp f (comp g h)

/-- 函子 -/
structure FunctorC (C : Category.{u, v}) (D : Category.{u', v'}) where
  FObj : C.Obj → D.Obj
  FHom : ∀ {a b}, C.Hom a b → D.Hom (FObj a) (FObj b)
  Fid : ∀ a, FHom (C.idn a) = D.idn (FObj a)
  Fcomp : ∀ {a b c} (f : C.Hom a b) (g : C.Hom b c),
    FHom (C.comp f g) = D.comp (FHom f) (FHom g)

/-! 【例 1】恒等函子与常值函子 -/
def idFun (C : Category.{u, v}) : FunctorC C C where
  FObj := fun a => a
  FHom := fun f => f
  Fid := fun _ => rfl
  Fcomp := fun _ _ => rfl

def OneCat : Category where
  Obj := Unit
  Hom := fun _ _ => Unit
  idn := fun _ => ()
  comp := fun _ _ => ()
  idL := fun _ => Unit.ext ..
  idR := fun _ => Unit.ext ..
  assoc := fun _ _ _ => rfl

def constFun (C : Category.{u, v}) : FunctorC C OneCat where
  FObj := fun _ => ()
  FHom := fun _ => ()
  Fid := fun _ => rfl
  Fcomp := fun _ _ => rfl

/-! 【例 2】List 函子（TyCat 上的自函子） -/
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

/-! 【例 3】hom-函子 Hom(a, -) : C → TyCat
对象 b ↦ Hom C a b；态射 f ↦ 后复合 g ↦ g;f。
函子定律逐条就是范畴定律的点式版！ -/
def homFun (C : Category.{0, 0}) (a : C.Obj) : FunctorC C TyCat where
  FObj := fun b => C.Hom a b
  FHom := fun f => fun g => C.comp g f
  Fid := fun _ => funext C.idR                    -- g;id = g 点式
  Fcomp := fun f g => funext fun h => (C.assoc h f g).symm

/-- 逆变 = 反范畴上的协变：Hom(-, b) : C^op → TyCat -/
def opposite (C : Category.{u, v}) : Category.{u, v} where
  Obj := C.Obj
  Hom := fun a b => C.Hom b a
  idn := fun a => C.idn a
  comp := fun f g => C.comp g f
  idL := fun f => C.idR f
  idR := fun f => C.idL f
  assoc := fun f g h => (C.assoc h g f).symm

def homFunContra (C : Category.{0, 0}) (b : C.Obj) : FunctorC (opposite C) TyCat :=
  homFun (opposite C) b

/-! 【函子保交换图】C 里 f;h = g;k ⟹ D 里 Ff;Fh = Fg;Fk -/
theorem F_preserves_square {C : Category.{u, v}} {D : Category.{u', v'}}
    (F : FunctorC C D) {a b c e : C.Obj} (f : C.Hom a b) (h : C.Hom b e)
    (g : C.Hom a c) (k : C.Hom c e) (sq : C.comp f h = C.comp g k) :
    D.comp (F.FHom f) (F.FHom h) = D.comp (F.FHom g) (F.FHom k) := by
  rw [← F.Fcomp f h, ← F.Fcomp g k, sq]

#check (funext map_id_pointwise : List.map (fun x => x) = (fun l => l))

/-! 坑位速记：
1. Lean 的函子定律字段是「函数级等式」，点式归纳引理用
   `funext`（核心定理）一步升级——Coq/Agda 要公理入账。
2. `F.FHom f` 用点号访问投影；具名宇宙 `Category.{u, v}` /
   `.{u', v'}` 跨范畴时必须写全（无 Cumulativity）。
3. map 律点式自证（方程式归纳）比翻核心库引理名稳。
4. homFun 的 Fcomp 是 assoc 的点式对称——「函子定律 = 范畴
   定律点式化」是 08 章 Yoneda 一切免费的根源。 -/
