-- ex01 —— 范畴的定义与首批例子
-- 三书对位：贺伟《范畴论》1.1 /《高级范畴论》1.3 / Simmons 1.1
--
-- 范畴 = 对象 + 态射 + 恒等 + 复合 + 三条定律。
-- 写成 structure，就是把数学定义逐字变成类型。

/-- 范畴（宇宙多态：Obj 在 u 层，Hom 在 v 层） -/
structure Category where
  Obj : Type u
  Hom : Obj → Obj → Type v
  idn : ∀ a, Hom a a
  comp : ∀ {a b c}, Hom a b → Hom b c → Hom a c
  idL : ∀ {a b} (f : Hom a b), comp (idn a) f = f
  idR : ∀ {a b} (f : Hom a b), comp f (idn b) = f
  assoc : ∀ {a b c d} (f : Hom a b) (g : Hom b c) (h : Hom c d),
    comp (comp f g) h = comp f (comp g h)

-- 复合按「图序」书写：comp f g = 先 f 后 g（Simmons 风格）。
-- 函数式的 f ∘ g = 先 g 后 f，恰是反范畴视角（见 02 章）。

/-. 【例 1】终范畴 1 —— 一个对象、一条态射 -/

def OneCat : Category where
  Obj := Unit
  Hom := fun _ _ => Unit
  idn := fun _ => ()
  comp := fun _ _ => ()
  idL := fun _ => Unit.ext ..      -- () = f：f 是变量，用 Unit 唯一性
  idR := fun _ => Unit.ext ..
  assoc := fun _ _ _ => rfl

/-. 【例 2】幺半群 = 单对象范畴
`(ℕ, +, 0)`：Hom * * := ℕ，恒等 := 0，复合 := 加法。
定律不再是 rfl（idR 要归纳），而是货真价实的算术定理。 -/
def NatCat : Category where
  Obj := Unit
  Hom := fun _ _ => Nat
  idn := fun _ => 0
  comp := fun f g => f + g
  idL := fun f => Nat.zero_add f          -- 0 + f = f：Lean 的 + 递归在第二参数，这条是 rfl 家族
  idR := fun f => Nat.add_zero f          -- f + 0 = f：要归纳
  assoc := fun f g h => Nat.add_assoc f g h

-- 在 NatCat 里复合两条态射：comp 2 3 = 5，机器可算
def five : Nat := NatCat.comp (a := ()) (b := ()) (c := ()) (2 : Nat) (3 : Nat)
example : five = 5 := rfl

/-. 【例 3】FinCat —— 有限集范畴的骨架
对象 = 自然数（当作基数），Hom m n := Fin m → Fin n。
「函数当态射」的最小化身，且完全避开宇宙问题。 -/
def FinCat : Category where
  Obj := Nat
  Hom := fun m n => Fin m → Fin n
  idn := fun _ => fun x => x
  comp := fun f g => fun x => g (f x)
  idL := fun _ => rfl                    -- (fun x => f x) = f：βη 折叠
  idR := fun _ => rfl
  assoc := fun _ _ _ => rfl

/-. 【例 4】TyCat —— Type 0 的范畴（「Set 的化身」）
对象 = Type 0，态射 = 函数。宇宙多态在此发挥作用：
Obj 落在 1 层，Hom 落在 0 层。 -/
def TyCat : Category.{1, 0} where
  Obj := Type 0
  Hom := fun A B => A → B
  idn := fun _ => fun x => x
  comp := fun f g => fun x => g (f x)
  idL := fun _ => rfl
  idR := fun _ => rfl
  assoc := fun _ _ _ => rfl

-- 在 TyCat 里复合两条态射：not 再 not
def nn : TyCat.Hom Bool Bool :=
  TyCat.comp (fun b => !b) (fun b => !b)

-- 逐点等于 id；函数层面的相等 Lean 用核心库的 funext（见 03 章）
example : (fun b => !(!b)) = (fun b => b) := funext (fun b => by cases b <;> rfl)

/-! 坑位速记：
1. OneCat 的 idL 不能 rfl：`() = f` 里 f 是变量——用 Unit.ext。
2. comp 投影的隐式 {a b c} 在 Obj := Unit 时无法从实参推出，
   用具名隐式 `(a := ())` 显式给。
3. Lean 定义相等含 βη，函数族的定律全是 rfl；NatCat 的 idR 用
   Nat.add_zero（Lean 的 + 递归在第二参数，与 Coq 恰相反——
   typetheory 教程 07 章「方向学」在此再现）。
4. `Type 0` 作对象必须显式给宇宙 `Category.{1, 0}`——Lean 无
   Cumulativity，靠注解对齐 Obj 层与 Hom 层。 -/
