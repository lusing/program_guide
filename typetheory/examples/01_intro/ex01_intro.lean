/- ============================================================
   01 认识类型论与四大证明助手 —— Lean 4 侧示例
   内核：CIC 变体（依赖类型 + Quot 类型 + Prop/Sort 宇宙层级）
   ============================================================ -/

-- ---- 判断形式 t : T：#check 就是「判断可推导」的问询 ----
#check fun x : Nat => x + 1
#check Nat
#check Nat → Nat
#check ∀ n : Nat, n + 0 = n

-- ---- 定义即 λ 抽象 ----
def idNat : Nat → Nat := fun n => n
#eval idNat 41

-- ---- 命题即类型：∀ n, n + 0 = n 是 Prop 宇宙里的类型 ----
-- 关键事实：Lean 的 Nat.add 递归在【第二】个参数上（与 Coq/Agda 相反），
-- 所以 n + 0 按定义折叠为 n——整个定理 rfl 一行就是证明
theorem lean_rhs_zero : ∀ n : Nat, n + 0 = n := fun _ => rfl

-- 反过来 0 + n 才需要归纳（Coq/Agda 里它是 rfl，n + 0 才要归纳）
theorem lean_lhs_zero : ∀ n : Nat, 0 + n = n := by
  intro n
  induction n with
  | zero => rfl                        -- 0 + 0 折叠为 0
  | succ n ih =>                       -- 0 + succ n ≡ succ (0 + n)
      exact congrArg Nat.succ ih

-- 纯项写法：Nat.rec 就是递归消去子（Coq 的 nat_ind / Agda 的模式匹配）
def zeroAddTerm : ∀ n : Nat, 0 + n = n :=
  fun n =>
    Nat.rec (motive := fun n => 0 + n = n)
      rfl                                 -- zero 情形
      (fun _ ih => congrArg Nat.succ ih)  -- succ 情形
      n

#print zeroAddTerm

-- ---- Prop 与 Sort：Lean 的宇宙是 Sort u，Prop = Sort 0 ----
#check True                  -- : Prop 即 Sort 0
#check Nat                   -- : Type 即 Sort 1
#check (fun A : Type => A → A)   -- : Type → Type

-- ---- 蕴涵即函数：组合子 B ----
theorem imp_trans {P Q R : Prop} (hpq : P → Q) (hqr : Q → R) : P → R :=
  fun hp => hqr (hpq hp)

-- ---- Lean 特有：instance 隐式参数、autoParam 等 17 章细讲 ----
-- 验证零公理：Lean 里 #print axioms 对应 Coq 的 Print Assumptions
#print axioms zeroAddTerm   -- 期望 'does not depend on any axioms'
