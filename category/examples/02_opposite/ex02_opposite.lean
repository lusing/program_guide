-- ex02 —— 反范畴与对偶原理
-- 三书对位：贺伟《范畴论》1.4 前置 /《高级范畴论》1.5 / Simmons 2.8
--
-- C^op：同样的对象，箭头掉头，复合倒序。
-- C 的 idR 定律变成 C^op 的 idL 定律——「对偶原理」的机器版本。

structure Category where
  Obj : Type u
  Hom : Obj → Obj → Type v
  idn : ∀ a, Hom a a
  comp : ∀ {a b c}, Hom a b → Hom b c → Hom a c
  idL : ∀ {a b} (f : Hom a b), comp (idn a) f = f
  idR : ∀ {a b} (f : Hom a b), comp f (idn b) = f
  assoc : ∀ {a b c d} (f : Hom a b) (g : Hom b c) (h : Hom c d),
    comp (comp f g) h = comp f (comp g h)

/-- 反范畴：箭头掉头、复合倒序 -/
def opposite (C : Category.{u, v}) : Category.{u, v} where
  Obj := C.Obj
  Hom := fun a b => C.Hom b a
  idn := fun a => C.idn a
  comp := fun f g => C.comp g f
  idL := fun f => C.idR f            -- C 的右单位 = C^op 的左单位
  idR := fun f => C.idL f            -- 反之亦然
  assoc := fun f g h => (C.assoc h g f).symm

-- 三条定律的搬运方向（逐条对读）：
-- C^op 的 idL 目标 comp (idn) f = f 展开 = C.comp f (C.idn) = f，
-- 恰是 C 的 idR；assoc 展开后是 C.assoc h g f 的对称。

/-! 【例子】预序范畴（瘦范畴）
`(ℕ, ≤)`：对象 = Nat，Hom a b := Le a b，至多一条态射。 -/
inductive Le : Nat → Nat → Type
  | refl (n : Nat) : Le n n
  | step {m n : Nat} : Le m n → Le m (n + 1)

/-- leTrans 递归在第二参数 -/
def Le.trans {a b c : Nat} : Le a b → Le b c → Le a c
  | p, .refl _ => p
  | p, .step q => .step (p.trans q)

/-- 右单位定义成立（match 分支直接折叠）；左单位要归纳 -/
theorem le_idL {a b : Nat} (f : Le a b) : (Le.refl a).trans f = f := by
  cases f with
  | refl => rfl
  | step f' => simp only [Le.trans, le_idL f']

theorem le_assoc {a b c d : Nat} (f : Le a b) (g : Le b c) (h : Le c d) :
    (f.trans g).trans h = f.trans (g.trans h) := by
  cases h with
  | refl => rfl
  | step h' => simp only [Le.trans, le_assoc f g h']

def LeCat : Category where
  Obj := Nat
  Hom := fun a b => Le a b
  idn := fun a => .refl a
  comp := fun f g => f.trans g
  idL := fun f => le_idL f
  idR := fun _ => rfl                -- 免费
  assoc := fun f g h => le_assoc f g h

/-- 对偶预序：LeCat^op 里 Hom a b = Le b a——「≥」范畴 -/
def geCat : Category := opposite LeCat

-- 具体：LeCat 里 3 → 5 有态射，5 → 3 没有；geCat 里恰好反过来
example : LeCat.Hom (3 : Nat) (5 : Nat) := .step (.step (.refl 3))
example : geCat.Hom (5 : Nat) (3 : Nat) := .step (.step (.refl 3))
-- geCat 5→3 与 LeCat 3→5 是同一棵证明树，方向掉了头

/-! 【对偶实感】FinCat：FinCat^op 的态射 m → n 就是 FinCat 的 Fin n → Fin m -/
def FinCat : Category where
  Obj := Nat
  Hom := fun m n => Fin m → Fin n
  idn := fun _ => fun x => x
  comp := fun f g => fun x => g (f x)
  idL := fun _ => rfl
  idR := fun _ => rfl
  assoc := fun _ _ _ => rfl

-- FinCat^op 的 3 → 2 = FinCat 的 2 → 3 = Fin 2 → Fin 3
def embed23 : Fin 2 → Fin 3 := fun x => ⟨x.1 + 1, by have := x.2; omega⟩

example : (opposite FinCat).Hom (3 : Nat) (2 : Nat) := embed23

/-! 坑位速记：
1. opposite 的定律搬运要看清展开：写反了（idL 填 C.idL）类型对不上。
2. 方程式定义返回「第一参数」要给名字（`| p, .refl _ => p`）；
   写 `.refl _` 会留 metavar，iota 卡死连带 idR 的 rfl 一起挂。
3. `cases` 处理 `refl (n : Nat) : Le n n` 时索引不绑定名字——
   `| refl =>` 零个参数；归纳步用 `simp only [Le.trans, IH]` 展开。
4. `LeCat.Hom 3 5` 里数字推不出 OfNat（Obj 投影不穿透）——
   `(3 : Nat)` 显式标注。
5. leTrans 递归在第二参数 ⇒ idR 是 rfl、idL 要归纳——
   与 typetheory 07 章「加法方向学」同源。 -/
