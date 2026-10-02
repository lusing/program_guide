-- ex07 —— 范畴的等价与同构
-- 三书对位：《高级范畴论》4.7 / Simmons 1.2.7（Pfn ≃ Set⊥）/ 贺伟 3.3 前置
--
-- 严格同构太稀有，「等价」才是正确的同构观：
-- 全忠实（Hom 集双射）+ 本质满（每个对象收到来自某像的态射）。
-- 等价 ⟺ 拟逆存在（需选择，作边界记录）。

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

/-- 忠实：Hom 映射单 -/
def Faithful {C : Category.{u, v}} {D : Category.{u', v'}} (F : FunctorC C D) : Prop :=
  ∀ a b (f g : C.Hom a b), F.FHom f = F.FHom g → f = g

/-- 满：Hom 映射满（证据是数据；Σ' 混居数据与 Prop） -/
def Full {C : Category.{u, v}} {D : Category.{u', v'}} (F : FunctorC C D) :
    Type (max u v v') :=
  ∀ a b (h : D.Hom (F.FObj a) (F.FObj b)), Σ' f : C.Hom a b, F.FHom f = h

/-- 本质满：每个 D 对象收到来自某个像的态射（完整版要求同构） -/
def EssentiallySurj {C : Category.{u, v}} {D : Category.{u', v'}} (F : FunctorC C D) :
    Type (max u u' v') :=
  ∀ d : D.Obj, Σ' c : C.Obj, D.Hom (F.FObj c) d

/-- 恒等函子 -/
def idFun (C : Category.{u, v}) : FunctorC C C where
  FObj := fun a => a
  FHom := fun f => f
  Fid := fun _ => rfl
  Fcomp := fun _ _ => rfl

theorem id_faithful (C : Category.{u, v}) : Faithful (idFun C) :=
  fun _ _ _ _ H => H

def id_full (C : Category.{u, v}) : Full (idFun C) :=
  fun _ _ h => ⟨h, rfl⟩

def id_es (C : Category.{u, v}) : EssentiallySurj (idFun C) :=
  fun d => ⟨d, C.idn d⟩

/-! 【List 函子忠实】map f = map g → f = g——单点列表当探针 -/
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

theorem list_faithful : Faithful listFun := by
  intro a b f g H
  funext x
  have h2 : [f x] = [g x] := congrFun H [x]   -- map f [x] 化简为 [f x]
  injection h2 with h3                          -- 目标 f x = g x 被 injection 顺带关闭

#check (list_faithful)

#print axioms id_faithful   -- 零公理
#print axioms id_es         -- 零公理
#print axioms list_faithful -- funext 的地基（Quot.sound/propext，内建）

/-! 【等价 vs 同构（文档要点）】
同构 = 严格的双向函子对（对象也一一对应）；等价 = 全忠实 + 本质满。
Simmons 1.2.7：Pfn ≃ Set⊥（部分函数 ≅ 带点集，L 补点/M 去点互为
拟逆）——「看起来不同、行为相同」的官方版本。
等价 ⟹ 拟逆（需选择公理）——本教程机器化到全忠实/本质满为止。 -/

/-! 坑位速记：
1. `congrFun H [x]`：函数相等作用到列表探针上；`List.headD`
   从单点列表取头（headD 对空列表返回任意默认值，免 Option）。
2. `[f x] = [g x]` 的头部提取用 congrArg + cases 收尾——
   headD (f x :: []) = f x 是 rfl 级别。
3. Full/EssentiallySurj 用 Σ（数据），Faithful 用 Prop——
   「证据是计算还是命题」决定落哪一层。 -/
