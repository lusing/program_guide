/-
文件: 06_tactics/basic_tactics.lean
描述: Lean 4 intro, exact, apply, have, rw
编译: lake build Lean4Tutorial.Examples.Tactics.BasicTactics
-/

namespace Lean4Tutorial.Examples.Tactics.BasicTactics

/-! # 战术（Tactics）简介 -/

-- 战术是 Lean 证明中的指令，用于操作目标（goal）
-- 一个证明可以看作是从目标出发，通过战术逐步简化，直到目标被解决
--
-- 常用的基本战术：
-- - intro   引入假设
-- - exact   用给定的证明项精确匹配目标
-- - apply   将蕴含式应用于目标
-- - have    引入中间结论
-- - rw      重写（使用等式替换）

/-! # intro 战术 -/

-- intro 用于引入蕴含式的前提或全称量词的变量
-- 当目标是 P → Q 时，intro h 会将 h : P 加入假设，目标变为 Q

-- 示例：证明 P → P
theorem intro_example1 (P : Prop) : P → P := by
  intro hP   -- 引入假设 hP : P
  exact hP   -- 用 hP 精确匹配目标 P

-- 多个 intro
theorem intro_example2 (P Q R : Prop) : P → Q → R → P := by
  intro hP
  intro hQ
  intro hR
  exact hP

-- 可以一次引入多个
theorem intro_example3 (P Q R : Prop) : P → Q → R → P := by
  intro hP hQ hR
  exact hP

-- 对全称量词使用 intro
theorem intro_forall : ∀ n : Nat, n + 0 = n := by
  intro n
  simp

-- 引入多个变量
theorem intro_forall2 : ∀ m n : Nat, m + n = n + m := by
  intro m n
  omega

/-! # exact 战术 -/

-- exact 用给定的证明项精确匹配目标
-- 如果证明项的类型与目标完全一致，证明完成

theorem exact_example1 (P : Prop) (h : P) : P := by
  exact h

-- exact 可以接受复合证明项
theorem exact_example2 (P Q : Prop) (hP : P) (hPQ : P → Q) : Q := by
  exact hPQ hP

-- exact 可以使用假设的组合
theorem exact_example3 (P Q R : Prop) (hPQ : P → Q) (hQR : Q → R) (hP : P) : R := by
  exact hQR (hPQ hP)

/-! # apply 战术 -/

-- apply 将一个蕴含式应用于目标
-- 如果目标是 Q，且有 h : P → Q，那么 apply h 会将目标变为 P
-- （因为要证明 Q，只需要证明 P）

theorem apply_example1 (P Q : Prop) (hPQ : P → Q) (hP : P) : Q := by
  apply hPQ    -- 目标 Q 变为 P
  exact hP     -- 用 hP 证明 P

-- apply 可以用于多前提的蕴含式
theorem apply_example2 (P Q R : Prop) (h : P → Q → R) (hP : P) (hQ : Q) : R := by
  apply h      -- 目标 R 变为两个子目标：P 和 Q
  · exact hP   -- 证明 P
  · exact hQ   -- 证明 Q

-- apply 也可以反向使用（apply at）
theorem apply_at_example (P Q : Prop) (hPQ : P → Q) (hP : P) : Q := by
  have hQ : Q := by
    exact hPQ hP
  exact hQ

/-! # have 战术 -/

-- have 用于在证明中引入中间结论
-- 格式：have <名称> : <命题> := <证明>
-- 之后可以在证明中使用这个名称作为假设

theorem have_example1 (P Q R : Prop)
  (hPQ : P → Q) (hQR : Q → R) (hP : P) : R := by
  have hQ : Q := hPQ hP    -- 先证明 Q
  exact hQR hQ             -- 再用 Q 证明 R

-- have 也可以用战术证明
theorem have_example2 (n : Nat) : n + 0 = 0 + n := by
  have h1 : n + 0 = n := by simp
  have h2 : 0 + n = n := by simp
  rw [h1, h2]

-- have 的匿名版本（不需要命名）
theorem have_example3 (P Q : Prop) (hP : P) (hPQ : P → Q) : Q := by
  have := hPQ hP
  exact this  -- this 指代最近的匿名 have

/-! # rw 战术 -/

-- rw（rewrite）使用等式进行重写
-- 如果有 h : a = b，rw [h] 会将目标中的 a 替换为 b

theorem rw_example1 (a b : Nat) (h : a = b) : a + 1 = b + 1 := by
  rw [h]    -- 将目标中的 a 替换为 b，得到 b + 1 = b + 1
  rfl       -- 自反性解决

-- 可以多次重写
theorem rw_example2 (a b c : Nat) (h1 : a = b) (h2 : b = c) : a = c := by
  rw [h1, h2]

-- 反向重写：用 ←（或 <-）表示从右向左替换
-- h : a = b，rw [←h] 表示用 a 替换 b
theorem rw_example3 (a b : Nat) (h : a = b) : b = a := by
  rw [←h]   -- 把目标中的 b 换成 a，得到 a = a
  rfl

-- rw 也可以在假设中使用（rw ... at h）
theorem rw_at_example (a b c : Nat) (h1 : a = b) (h2 : b = c) : a = c := by
  have h3 : b = c := h2
  rw [←h1] at h3  -- 在 h3 中用 a 替换 b，得到 a = c
  exact h3

-- rw 可以用于函数
theorem rw_fun (f : Nat → Nat) (a b : Nat) (h : a = b) : f a = f b := by
  rw [h]

-- 使用列表语法重写多次
theorem rw_list (a b c d : Nat) (h1 : a = b) (h2 : c = d) :
  a + c = b + d := by
  rw [h1, h2]

/-! # 战术的组合使用 -/

-- 一个稍微复杂的例子
theorem tactic_combo1 (P Q R S : Prop)
  (h1 : P → Q) (h2 : Q → R) (h3 : R → S) (hP : P) : S := by
  have hQ : Q := h1 hP
  have hR : R := h2 hQ
  exact h3 hR

-- 使用 apply 的版本
theorem tactic_combo2 (P Q R S : Prop)
  (h1 : P → Q) (h2 : Q → R) (h3 : R → S) (hP : P) : S := by
  apply h3
  apply h2
  apply h1
  exact hP

-- 使用 rw 的代数证明
theorem tactic_combo3 (a b c : Nat) (h1 : a = b + 1) (h2 : b = c) :
  a = c + 1 := by
  rw [h1, h2]
  <;> rfl

/-! # 更多基本战术 -/

/- ## assumption 战术 -/

-- assumption 在假设中寻找能直接证明目标的假设
theorem assumption_example (P Q : Prop) (hP : P) (hQ : Q) : P := by
  assumption  -- 自动找到 hP

/- ## trivial 战术 -/

-- trivial 可以证明简单的目标，如 True
theorem trivial_example : True := by trivial

/- ## contradiction 战术 -/

-- contradiction 在假设中寻找矛盾（False）
theorem contradiction_example (P : Prop) (hP : P) (hNP : ¬P) : Q := by
  contradiction  -- 从 hP 和 hNP 推出 False，然后得到任何结论

/- ## simp 战术 -/

-- simp 使用简化规则（simp lemmas）简化目标
theorem simp_example1 (n : Nat) : n + 0 = n := by simp

theorem simp_example2 : [1, 2, 3].length = 3 := by simp

theorem simp_example3 : (fun x => x + 1) 5 = 6 := by simp

-- simp 也可以在假设中使用
theorem simp_at_example (n : Nat) (h : n + 0 = 5) : n = 5 := by
  simp at h
  exact h

/- ## reflexivity / rfl 战术 -/

-- rfl 证明自反的等式
theorem rfl_tactic_example : 5 = 5 := by rfl

theorem rfl_tactic_example2 {α : Type} (x : α) : x = x := by rfl

/-! # 证明结构 -/

-- 使用 · 聚焦子目标
theorem focus_example (P Q R : Prop) (hP : P) (hQ : Q) (h : P → Q → R) : R := by
  apply h
  · exact hP  -- 聚焦第一个子目标
  · exact hQ  -- 聚焦第二个子目标

-- 使用 {} 包围子目标证明
theorem braces_example (P Q R : Prop) (hP : P) (hQ : Q) (h : P → Q → R) : R := by
  apply h
  { exact hP }
  { exact hQ }

-- 使用分号 ; 连接战术（应用于所有子目标）
theorem semicolon_example : 0 + 0 = 0 ∧ 1 + 0 = 1 := by
  constructor <;> simp

/-! # 综合示例 -/

-- 证明一个关于自然数的简单命题
theorem nat_example1 : ∀ n : Nat, n + 0 = 0 + n := by
  intro n
  rw [add_zero, zero_add]
where
  add_zero (n : Nat) : n + 0 = n := by simp
  zero_add (n : Nat) : 0 + n = n := by simp

-- 使用各种战术证明
theorem mixed_tactics (P Q : Prop) (hP : P) (hPQ : P → Q) : Q ∧ P := by
  have hQ : Q := by
    apply hPQ
    exact hP
  constructor
  · exact hQ
  · exact hP

-- 关于列表的证明
theorem list_example {α : Type} (xs : List α) : xs ++ [] = xs := by
  induction xs with
  | nil => rfl
  | cons x xs ih =>
    simp [List.append_cons]
    rw [ih]
    <;> rfl

end Lean4Tutorial.Examples.Tactics.BasicTactics
