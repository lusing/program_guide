/-
文件: 05_propositions/equality.lean
描述: Lean 4 等式推理：rfl, symm, trans, congr
编译: lake build Lean4Tutorial.Examples.Propositions.Equality
-/

namespace Lean4Tutorial.Examples.Propositions.Equality

/-! # 等式类型 -/

-- 在 Lean 中，等式是一个归纳类型
-- Eq a b（通常写成 a = b）表示 a 等于 b
-- 唯一的构造子是 rfl（refl）：Eq.refl a : a = a

-- 等式的自反性
theorem eq_refl (n : Nat) : n = n := by rfl

theorem eq_refl' (n : Nat) : n = n := Eq.refl n

/-! # rfl -/

-- rfl 是 reflexivity 的缩写
-- rfl 可以证明任何定义上相等的两个项相等
-- "定义上相等"意味着它们可以通过化简变成同一个项

theorem rfl_example1 : 2 + 2 = 4 := by rfl
theorem rfl_example2 : [1, 2, 3] = 1 :: 2 :: [3] := by rfl
theorem rfl_example3 : "hello" = "h" ++ "ello" := by rfl

-- rfl 也可以作为证明项使用
theorem rfl_term : 1 + 1 = 2 := rfl

/-! # symm -/

-- 等式的对称性：如果 a = b，则 b = a
-- Eq.symm : a = b → b = a

theorem eq_symm (a b : Nat) (h : a = b) : b = a :=
  Eq.symm h

theorem symm_example (n : Nat) (h : n = 5) : 5 = n :=
  Eq.symm h

-- 使用 .symm 方法
theorem symm_example' (n : Nat) (h : n = 5) : 5 = n :=
  h.symm

/-! # trans -/

-- 等式的传递性：如果 a = b 且 b = c，则 a = c
-- Eq.trans : a = b → b = c → a = c

theorem eq_trans (a b c : Nat) (h1 : a = b) (h2 : b = c) : a = c :=
  Eq.trans h1 h2

theorem trans_example (x y z : Nat) (h1 : x = y) (h2 : y + 1 = z) :
  x + 1 = z :=
  have h3 : x + 1 = y + 1 := by rw [h1]
  Eq.trans h3 h2

-- 使用 .trans 方法
theorem trans_example' (a b c : Nat) (h1 : a = b) (h2 : b = c) : a = c :=
  h1.trans h2

/-! # congr -/

-- 同余性（congruence）：
-- 如果 a = b，则 f a = f b
-- 如果 a1 = a2 且 b1 = b2，则 f a1 b1 = f a2 b2

-- 一元函数的同余
theorem congr_arg (f : Nat → Nat) (a b : Nat) (h : a = b) : f a = f b :=
  congr_arg f h

theorem congr_arg_example (a b : Nat) (h : a = b) : a + 1 = b + 1 :=
  congr_arg (fun x => x + 1) h

-- 二元函数的同余
theorem congr_arg2 (f : Nat → Nat → Nat) (a1 a2 b1 b2 : Nat)
  (h1 : a1 = a2) (h2 : b1 = b2) : f a1 b1 = f a2 b2 :=
  congr (congr_arg f h1) h2

theorem congr_add (a b c d : Nat) (h1 : a = b) (h2 : c = d) :
  a + c = b + d :=
  by rw [h1, h2]

-- congr 战术可以自动应用同余
theorem congr_tactic_example (f : Nat → Nat → Nat) (a b : Nat) (h : a = b) :
  f a a = f b b := by
  congr
  · exact h
  · exact h

/-! # 等式的替换（rewrite）-/

-- 如果有 h : a = b，那么可以在目标中用 b 替换 a（或反之）
-- rw 战术就是做这个的

theorem rw_example1 (a b : Nat) (h : a = b) : a + a = b + b := by
  rw [h]
  -- 目标变为 b + b = b + b，然后 rfl 解决

theorem rw_example2 (x y z : Nat) (h1 : x = y) (h2 : y = z) : x = z := by
  rw [h1, h2]
  -- 先将 x 换成 y，再将 y 换成 z，得到 z = z

-- 从右向左替换（使用 ← 或 <-）
theorem rw_left (a b : Nat) (h : a = b) : b = a := by
  rw [←h]
  -- 用 a 替换 b（因为 h 是 a = b，反向就是用 a 替换右边的 b）
  -- 不对，←h 表示从右向左替换：用左边替换右边
  -- h : a = b，←h 表示用 a 替换 b
  -- 目标 b = a 中把 b 替换成 a，得到 a = a

/-! # 等式的注入性 -/

-- 对于归纳类型的构造子，等式是注入的
-- 例如：如果 succ m = succ n，则 m = n
-- 这叫做"构造子的注入性"

theorem succ_inj (m n : Nat) (h : m + 1 = n + 1) : m = n := by
  injection h

-- 列表的 cons 也是注入的
theorem cons_inj (x y : Nat) (xs ys : List Nat)
  (h : x :: xs = y :: ys) : x = y ∧ xs = ys := by
  injection h with h1 h2
  exact ⟨h1, h2⟩

-- 使用 injection 战术

/-! # 不等与矛盾 -/

-- 不同的构造子产生不同的值
-- 例如：zero ≠ succ n

theorem zero_ne_succ (n : Nat) : 0 ≠ n + 1 := by
  intro h
  contradiction

-- 或者使用 discriminate
theorem zero_ne_succ' (n : Nat) (h : 0 = n + 1) : False := by
  discriminate

-- 列表的 nil ≠ cons
theorem nil_ne_cons (x : Nat) (xs : List Nat) : [] ≠ x :: xs := by
  intro h
  contradiction

/-! # 等式归纳（eq.rec）-/

-- 等式的归纳原理：
-- 如果 P a 成立，且 a = b，则 P b 成立
-- 这叫做"代入"（substitution）或"莱布尼茨相等"

theorem eq_subst {α : Type} {P : α → Prop} {a b : α}
  (h1 : P a) (h2 : a = b) : P b :=
  h2 ▸ h1

-- ▸ 运算符（输入 \t）就是等式替换

theorem subst_example (n : Nat) (h : n = 5) : n + 1 = 6 := by
  have h' : n + 1 = 5 + 1 := by rw [h]
  rw [h']
  <;> rfl

-- 使用 ▸
theorem subst_example' (n : Nat) (h : n = 5) : n + 1 = 6 :=
  h ▸ rfl

/-! # 等式与等价关系 -/

-- 等式是一个等价关系（自反、对称、传递）
-- 但不是所有等价关系都是等式

-- 例如：模 2 同余是一个等价关系，但不是等式
def mod2_eq (a b : Nat) : Prop := a % 2 = b % 2

theorem mod2_refl (a : Nat) : mod2_eq a a := by
  simp [mod2_eq]

theorem mod2_symm (a b : Nat) : mod2_eq a b → mod2_eq b a := by
  intro h
  simp [mod2_eq] at * <;> omega

theorem mod2_trans (a b c : Nat) : mod2_eq a b → mod2_eq b c → mod2_eq a c := by
  intro h1 h2
  simp [mod2_eq] at * <;> omega

/-! # 点态相等 -/

-- 两个函数相等（函数外延性）
-- 在 Lean 中，函数外延性需要 funext 公理

-- 函数外延性：如果 ∀ x, f x = g x，则 f = g
theorem funext_example (f g : Nat → Nat) (h : ∀ x, f x = g x) : f = g := by
  funext x
  exact h x

-- funext 战术可以用来证明函数相等

/-! # 命题外延性 -/

-- 命题外延性：如果 P ↔ Q，则 P = Q
-- 这也是一个公理（propext）

theorem propext_example (P Q : Prop) (h : P ↔ Q) : P = Q :=
  propext h

-- 有了命题外延性，等价就等于相等

/-! # 异构等式（heterogeneous equality）-/

-- 通常的等式要求两边的类型相同
-- 异构等式（==）允许两边类型不同

-- 异构等式用 HEq 表示
-- HEq a b 表示 a 和 b 相等（即使它们的类型可能不同）

-- 同构等式蕴含异构等式
theorem eq_imp_heq (a b : Nat) (h : a = b) : HEq a b := by
  rw [h]
  <;> rfl

/-! # 计算等式 -/

-- 对于具体的数值，可以用 decide 或 norm_num 证明等式

theorem compute1 : 1234 + 5678 = 6912 := by decide
theorem compute2 : 123 * 456 = 56088 := by decide
theorem compute3 : 2 ^ 10 = 1024 := by decide

/-! # 等式证明的例子 -/

-- 证明加法交换律（需要归纳法）
theorem add_comm_nat : ∀ m n : Nat, m + n = n + m := by
  intro m n
  induction m with
  | zero =>
    simp
    <;> rfl
  | succ m ih =>
    simp [Nat.add_succ, ih]
    <;> rfl

-- 证明加法结合律
theorem add_assoc_nat : ∀ m n k : Nat, (m + n) + k = m + (n + k) := by
  intro m n k
  induction m with
  | zero => rfl
  | succ m ih =>
    simp [Nat.add_succ, ih] <;> rfl

-- 证明乘法分配律
theorem mul_add (m n k : Nat) : m * (n + k) = m * n + m * k := by
  induction m with
  | zero => simp
  | succ m ih =>
    simp [Nat.mul_succ, ih, add_assoc_nat] <;> ring_nf <;> rfl

end Lean4Tutorial.Examples.Propositions.Equality
