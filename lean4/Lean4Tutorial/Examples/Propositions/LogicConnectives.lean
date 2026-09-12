/-
文件: 05_propositions/logic_connectives.lean
描述: Lean 4 逻辑连接词：∧ ∨ → ¬ True False
编译: lake build Lean4Tutorial.Examples.Propositions.LogicConnectives
-/

namespace Lean4Tutorial.Examples.Propositions.LogicConnectives

/-! # 命题即类型 -/

-- 在 Lean 中，命题也是类型（Prop）
-- 一个命题的证明就是该类型的一个元素（项）
-- 如果一个命题有证明，我们说它是"真的"

-- Prop 是所有命题的类型
-- 例如：
--   2 + 2 = 4 : Prop    （这是一个命题）
--   rfl : 2 + 2 = 4     （rfl 是这个命题的证明）

/-! # 蕴含（Implication）→ -/

-- P → Q 表示"如果 P，那么 Q"
-- 要证明 P → Q，需要构造一个函数，将 P 的证明映射为 Q 的证明

-- 一个简单的蕴含式：如果 P 成立，那么 P 成立（同一律）
theorem imp_self (P : Prop) : P → P :=
  fun h : P => h

-- 上面的证明是一个恒等函数：给定 P 的证明 h，返回 h 本身

-- 蕴含的传递性
theorem imp_trans (P Q R : Prop) : (P → Q) → (Q → R) → (P → R) :=
  fun hPQ : P → Q =>
    fun hQR : Q → R =>
      fun hP : P =>
        hQR (hPQ hP)

-- 也可以用更简洁的写法
theorem imp_trans' (P Q R : Prop) (hPQ : P → Q) (hQR : Q → R) : P → R :=
  fun hP => hQR (hPQ hP)

/-! # 合取（Conjunction）∧ -/

-- P ∧ Q 表示"P 且 Q"
-- 要证明 P ∧ Q，需要分别证明 P 和 Q
-- 使用 And.intro 或 ⟨, ⟩ 构造

-- 合取的引入（introduction）
theorem and_intro (P Q : Prop) (hP : P) (hQ : Q) : P ∧ Q :=
  And.intro hP hQ

-- 使用尖括号构造
theorem and_intro' (P Q : Prop) (hP : P) (hQ : Q) : P ∧ Q :=
  ⟨hP, hQ⟩

-- 合取的消除（elimination）
-- 从 P ∧ Q 可以推出 P
theorem and_left (P Q : Prop) (h : P ∧ Q) : P :=
  And.left h

-- 从 P ∧ Q 可以推出 Q
theorem and_right (P Q : Prop) (h : P ∧ Q) : Q :=
  And.right h

-- 使用 .1 和 .2 也可以
theorem and_left' (P Q : Prop) (h : P ∧ Q) : P := h.1
theorem and_right' (P Q : Prop) (h : P ∧ Q) : Q := h.2

-- 合取的交换律
theorem and_comm (P Q : Prop) : P ∧ Q → Q ∧ P :=
  fun h => ⟨h.2, h.1⟩

-- 合取的结合律
theorem and_assoc (P Q R : Prop) : (P ∧ Q) ∧ R ↔ P ∧ (Q ∧ R) :=
  Iff.intro
    (fun h => ⟨h.1.1, h.1.2, h.2⟩)
    (fun h => ⟨⟨h.1, h.2.1⟩, h.2.2⟩)

/-! # 析取（Disjunction）∨ -/

-- P ∨ Q 表示"P 或 Q"
-- 要证明 P ∨ Q，只需要证明 P 或者证明 Q
-- 使用 Or.inl（左引入）或 Or.inr（右引入）

-- 析取的左引入
theorem or_intro_left (P Q : Prop) (hP : P) : P ∨ Q :=
  Or.inl hP

-- 析取的右引入
theorem or_intro_right (P Q : Prop) (hQ : Q) : P ∨ Q :=
  Or.inr hQ

-- 析取的消除（分情况讨论）
-- 如果 P → R 且 Q → R，那么 P ∨ Q → R
theorem or_elim (P Q R : Prop) (hPQ : P ∨ Q) (hPR : P → R) (hQR : Q → R) : R :=
  Or.elim hPQ hPR hQR

-- 析取的交换律
theorem or_comm (P Q : Prop) : P ∨ Q → Q ∨ P :=
  fun h =>
    Or.elim h
      (fun hP : P => Or.inr hP)
      (fun hQ : Q => Or.inl hQ)

-- 析取的结合律
theorem or_assoc (P Q R : Prop) : (P ∨ Q) ∨ R ↔ P ∨ (Q ∨ R) :=
  Iff.intro
    (fun h =>
      Or.elim h
        (fun hPQ =>
          Or.elim hPQ
            (fun hP => Or.inl hP)
            (fun hQ => Or.inr (Or.inl hQ)))
        (fun hR => Or.inr (Or.inr hR)))
    (fun h =>
      Or.elim h
        (fun hP => Or.inl (Or.inl hP))
        (fun hQR =>
          Or.elim hQR
            (fun hQ => Or.inl (Or.inr hQ))
            (fun hR => Or.inr hR)))

/-! # 否定（Negation）¬ -/

-- ¬ P 表示"非 P"
-- ¬ P 定义为 P → False
-- 即：如果 P 成立，就会推出矛盾（False）

-- 否定的引入：假设 P 推出矛盾，则 ¬ P
theorem not_intro (P : Prop) (h : P → False) : ¬ P := h

-- 否定的消除：如果有 P 和 ¬ P，就得到 False
theorem not_elim (P : Prop) (hP : P) (hNP : ¬ P) : False :=
  hNP hP

-- 双重否定的一个方向（直觉主义逻辑成立）
theorem double_neg_intro (P : Prop) : P → ¬¬P :=
  fun hP : P =>
    fun hNP : ¬P =>
      hNP hP

-- 注意：¬¬P → P 在直觉主义逻辑中不成立
-- 需要经典逻辑（排中律）

-- 矛盾可以推出任何命题（ex falso quodlibet）
theorem ex_falso (P : Prop) (h : False) : P :=
  False.elim h

/-! # True -/

-- True 是一个永远为真的命题
-- 它只有一个证明：True.intro（也写作 trivial）

theorem true_is_true : True :=
  True.intro

theorem true_is_true' : True := by trivial

-- True 可以由任何命题推出（但反过来不行）
theorem anything_implies_true (P : Prop) : P → True :=
  fun _ => True.intro

/-! # False -/

-- False 是一个永远为假的命题
-- 它没有证明（在一致的逻辑系统中）

-- False 可以推出任何命题
theorem false_implies_anything (P : Prop) : False → P :=
  fun h => False.elim h

/-! # 等价（Biconditional）↔ -/

-- P ↔ Q 表示"P 当且仅当 Q"
-- 即 P → Q 且 Q → P
-- 使用 Iff.intro 构造

-- 等价的引入
theorem iff_intro (P Q : Prop) (hPQ : P → Q) (hQP : Q → P) : P ↔ Q :=
  Iff.intro hPQ hQP

-- 等价的消除
theorem iff_mp (P Q : Prop) (h : P ↔ Q) : P → Q :=
  Iff.mp h

theorem iff_mpr (P Q : Prop) (h : P ↔ Q) : Q → P :=
  Iff.mpr h

-- 等价的自反性
theorem iff_refl (P : Prop) : P ↔ P :=
  Iff.intro (fun h => h) (fun h => h)

-- 等价的对称性
theorem iff_symm (P Q : Prop) : (P ↔ Q) ↔ (Q ↔ P) :=
  Iff.intro
    (fun h => Iff.intro h.mpr h.mp)
    (fun h => Iff.intro h.mpr h.mp)

-- 等价的传递性
theorem iff_trans (P Q R : Prop) (h1 : P ↔ Q) (h2 : Q ↔ R) : P ↔ R :=
  Iff.intro
    (fun hP => h2.mp (h1.mp hP))
    (fun hR => h1.mpr (h2.mpr hR))

/-! # 一些经典逻辑定理 -/

-- 德摩根定律之一（直觉主义成立的方向）
theorem demorgan1 (P Q : Prop) : ¬P ∨ ¬Q → ¬(P ∧ Q) :=
  fun h =>
    Or.elim h
      (fun hNP : ¬P =>
        fun hPQ : P ∧ Q =>
          hNP hPQ.1)
      (fun hNQ : ¬Q =>
        fun hPQ : P ∧ Q =>
          hNQ hPQ.2)

-- 另一个德摩根定律（直觉主义成立）
theorem demorgan2 (P Q : Prop) : ¬P ∧ ¬Q → ¬(P ∨ Q) :=
  fun h =>
    fun hPQ : P ∨ Q =>
      Or.elim hPQ
        (fun hP : P => h.1 hP)
        (fun hQ : Q => h.2 hQ)

-- 分配律：P ∧ (Q ∨ R) ↔ (P ∧ Q) ∨ (P ∧ R)
theorem distrib_and_or (P Q R : Prop) :
  P ∧ (Q ∨ R) ↔ (P ∧ Q) ∨ (P ∧ R) :=
  Iff.intro
    (fun h =>
      have hP : P := h.1
      have hQR : Q ∨ R := h.2
      Or.elim hQR
        (fun hQ => Or.inl ⟨hP, hQ⟩)
        (fun hR => Or.inr ⟨hP, hR⟩))
    (fun h =>
      Or.elim h
        (fun hPQ => ⟨hPQ.1, Or.inl hPQ.2⟩)
        (fun hPR => ⟨hPR.1, Or.inr hPR.2⟩))

-- 分配律：P ∨ (Q ∧ R) ↔ (P ∨ Q) ∧ (P ∨ R)
theorem distrib_or_and (P Q R : Prop) :
  P ∨ (Q ∧ R) ↔ (P ∨ Q) ∧ (P ∨ R) :=
  Iff.intro
    (fun h =>
      Or.elim h
        (fun hP => ⟨Or.inl hP, Or.inl hP⟩)
        (fun hQR => ⟨Or.inr hQR.1, Or.inr hQR.2⟩))
    (fun h =>
      have h1 : P ∨ Q := h.1
      have h2 : P ∨ R := h.2
      Or.elim h1
        (fun hP => Or.inl hP)
        (fun hQ =>
          Or.elim h2
            (fun hP => Or.inl hP)
            (fun hR => Or.inr ⟨hQ, hR⟩)))

/-! # 关于自然数的命题 -/

-- 命题可以涉及具体的数学对象
theorem two_plus_two_eq_four : 2 + 2 = 4 := by rfl

theorem add_comm_nat (m n : Nat) : m + n = n + m := by
  induction m with
  | zero => simp
  | succ m ih =>
    simp [Nat.add_succ, ih] <;> omega

theorem three_lt_five : 3 < 5 := by decide

/-! # 命题证明的不同方式 -/

-- 方式 1：直接构造证明项（term proof）
theorem direct_proof (P Q : Prop) (hP : P) (hQ : Q) : P ∧ Q :=
  ⟨hP, hQ⟩

-- 方式 2：使用战术（tactic proof）
theorem tactic_proof (P Q : Prop) (hP : P) (hQ : Q) : P ∧ Q := by
  constructor
  · exact hP
  · exact hQ

-- 方式 3：混合方式
theorem mixed_proof (P Q : Prop) (hP : P) (hQ : Q) : P ∧ Q := by
  exact ⟨hP, hQ⟩

end Lean4Tutorial.Examples.Propositions.LogicConnectives
