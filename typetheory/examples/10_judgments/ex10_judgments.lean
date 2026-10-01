/- ============================================================
   10 MLTT 的判断形式与一般规则 —— Lean 侧
   Nordström ch.3–5 的机器化身：
   四种判断：A type / A ≡ B / a : A / a ≡ b : A
   一般规则：前提、对称、传递、替换（等式的四个公理动作）
   ============================================================ -/

/- ---------- 判断一：a : A（居留） ---------- -/
#check (1 : Nat)
#check (fun n => n + 1 : Nat → Nat)

/- ---------- 判断二：A type（类型资格） ---------- -/
def Vec : Type → Nat → Type
  | _, 0 => Unit
  | α, n + 1 => α × Vec α n
#check Vec Nat 3          -- 它确实是类型

/- ---------- 判断三：a ≡ b : A（定义相等） ---------- -/
-- 定义相等 = 沿定义展开后的相等；rfl 是它的居留项
example : (fun n => n + 1) 3 = 4 := rfl        -- β
example : (2 + 2 : Nat) = 4 := rfl             -- δ+ι 全家

/- ---------- 判断四：A ≡ B（类型的定义相等） ---------- -/
def N2 := Nat → Nat
example : N2 = (Nat → Nat) := rfl              -- δ

/- ---------- 一般规则（Nordström 5.3）：等式的公理动作 ----------
   MLTT 里这些不是公理而是 J 规则的推论（12 章手工造一遍）   -/

-- 前提规则：假设直接可用（假设即上下文条目）
theorem hypRule (P : Nat → Prop) (n : Nat) (h : P n) : P n := h

-- 对称：a = b ⟹ b = a
theorem symRule (a b : Nat) (h : a = b) : b = a := h.symm

-- 传递：a = b ⟹ b = c ⟹ a = c
theorem transRule (a b c : Nat) (h1 : a = b) (h2 : b = c) : a = c := h1.trans h2

-- 替换：a = b ⟹ P a ⟹ P b（代入/同余的总纲）
theorem substRule (a b : Nat) (h : a = b) (P : Nat → Prop) (pa : P a) : P b :=
  h ▸ pa

-- 替换的常用特例：同余（函数保持相等）
theorem congRule (a b : Nat) (f : Nat → Nat) (h : a = b) : f a = f b := by rw [h]

/- ---------- 上下文：判断总在上下文里做 ---------- -/
section Ctx
variable (α : Type) (a b : α)
-- 「上下文里的判断」：h 是 Γ 的一条假设（variable 用到才收，
-- 所以写在语句里）
theorem inCtx (h : a = b) : b = a := h.symm
end Ctx

/- ---------- 一致性检查：定义相等不是命题相等 ----------
   (fun x => x + 1) 3 与 4 定义相等（rfl 过）；
   但 n + 1 与 1 + n 对【变量】n 只是命题相等 —— rfl 过不了，要证明 -/
theorem notDefEq : ∀ n : Nat, n + 1 = 1 + n := fun n => (Nat.add_comm 1 n).symm

