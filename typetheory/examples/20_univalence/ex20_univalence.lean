/- ============================================================
   20 泛等公理 —— Lean 侧：为什么 Lean【不能】加泛等
   Lean 的 Eq 在 Prop，UIP 可证（19 章实测）——
   泛等与 UIP 不相容，所以只能「把账目摆出来看」
   ============================================================ -/

/-- 等价：函数 + 两侧收缩 -/
structure IsEquiv {A B : Type} (f : A → B) where
  inv : B → A
  retr : ∀ b, f (inv b) = b
  sec : ∀ a, inv (f a) = a

structure Equiv (A B : Type) where
  toFun : A → B
  isEq : IsEquiv toFun

/-- id→eq：不用公理 -/
def idToEquiv {A B : Type} : A = B → Equiv A B
  | rfl => ⟨id, ⟨id, fun _ => rfl, fun _ => rfl⟩⟩

/- ---------- 若强行公理化泛等…… ---------- -/

-- axiom ua {A B : Type} : Equiv A B → A = B
-- 上面这行【没有】打开：它和 UIP（19 章 uip 定理）不合——
-- Bool 的取反等价会给出 negPath : Bool = Bool，使得
-- transport 沿它翻转元素；但 UIP 之下 Bool = Bool 的证明
-- 全等于 rfl，transport 恒等——矛盾。

-- 账目对照：
-- Coq：paths 自造在 Type 层 + Univalence 公理 → 可用（20 章 .v）
-- Agda：_≡_ 本在 Set 层 + postulate ua → 可用（20 章 .agda）
-- Lean：Eq 在 Prop + UIP 是定理 → 泛等不可加（只能换内核路线，
--       如 Lean-HoTT 实验性分支）

/- ---------- 19 章 uip 的再确认 ---------- -/

theorem uip {α : Sort u} {x : α} (p q : x = x) : p = q := by
  cases p
  cases q
  rfl

/- ---------- 泛等的精神可以用「结构」预演 ----------
   「等价的类型应视为相等」的工程直觉，在标准 Lean 里以
   【结构沿等价搬运】的形式部分兑现： -/
def transportFun (P : Type → Type) {A B : Type} (e : A = B) (p : P A) : P B :=
  e ▸ p

example : transportFun (fun X => X → X) (rfl : Nat = Nat) Nat.succ = Nat.succ := rfl
