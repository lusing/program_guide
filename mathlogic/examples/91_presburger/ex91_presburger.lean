/- ex91_presburger.lean —— 简化版本的自然数模型（郝 ch8）Lean 侧账本
   与 Coq 通道同账：8.3.1 断言（注入性/无圈/bump）、8.4.1 min-见证、
   D1 奇偶（omega 一次清账——Lean 内建 Presburger 消去）、习题 8.5.7
   加法在 (N,S,×) 中可定义。鸽笼账（无有限后继模型）由 Coq/Isabelle/
   Prolog 三通道承担（bare core 无 Mathlib 的列表计数件，docs 对账）。
   #print axioms 记账。 -/

set_option linter.unusedVariables false

-- ---------- 1. 定理 8.3.1 的断言账：L_s = {0,S} ----------

/-- S-消去第一步：公共 S 层可约去（公理 (S2) 的账） -/
theorem Scancel (k x y : Nat) (h : x + k = y + k) : x = y := by omega

/-- 无圈：S^k x ≠ x（公理模式 (S4.n) 的语义账） -/
theorem no_cycle (k x : Nat) : x + k + 1 ≠ x := by omega

/-- 断言 3 的语义核（bump 引理）：∃x 的解出条件 -/
theorem bump_sem (k m t u : Nat) :
    (∃ x, x + k = t ∧ x + m = u) ↔ (t + m = u + k ∧ k ≤ t) := by
  constructor
  · intro ⟨x, h1, h2⟩; exact ⟨by omega, by omega⟩
  · intro ⟨h1, h2⟩; exact ⟨t - k, by omega, by omega⟩

-- ---------- 2. 定理 8.4.1 断言 4/5 的语义核 ----------

/-- 双侧夹界：δ₃ = S w < u 的形状（断言 5） -/
theorem min_witness (w u : Nat) : (∃ x, w < x ∧ x < u) ↔ (w + 1 < u) := by
  constructor
  · intro ⟨x, h1, h2⟩; omega
  · intro h; exact ⟨w + 1, by omega, by omega⟩

/-- 断言 4（无下界子情形）：x:=0 见证 -/
theorem zero_witness (u : Nat) : (∃ x, x < u) ↔ (1 ≤ u) := by
  constructor
  · intro ⟨x, h⟩; omega
  · intro h; exact ⟨0, by omega⟩

-- ---------- 3. D1 奇偶账：omega 的 Presburger 现场 ----------

/-- 每个数或偶或奇——Prolog 通道 D1 的 Lean 镜像。omega 不解存在
    目标（只吃无量词片段+∀ 假设），故走奇偶递推；分支内 omega 清账 -/
theorem even_or_odd : ∀ x, ∃ m, x = 2 * m ∨ x = 2 * m + 1
  | 0 => ⟨0, Or.inl rfl⟩
  | x + 1 =>
    match even_or_odd x with
    | ⟨m, Or.inl h⟩ => ⟨m, Or.inr (by omega)⟩
    | ⟨m, Or.inr h⟩ => ⟨m + 1, Or.inl (by omega)⟩

/-- 奇偶不重叠（Prolog 通道 D2 的影子） -/
theorem not_both (x : Nat) : ¬ (∃ m, x = 2 * m ∧ ∃ k, x = 2 * k + 1) := by
  intro ⟨m, hm, k, hk⟩; omega

-- ---------- 4. 习题 8.5.7：加法在 (N,S,×) 中可定义 ----------

/-- 两个多项式展开式（AC-正规化一次到位） -/
theorem expand857a (a b c : Nat) :
    (a * c + 1) * (b * c + 1) = a * b * (c * c) + (a * c + b * c) + 1 := by
  have h5 : (a * c + 1) * (b * c + 1)
      = a * c * (b * c) + b * c + (a * c + 1) := by
    simp [Nat.add_mul, Nat.mul_add, Nat.mul_one, Nat.one_mul]
  have h6 : a * c * (b * c) = a * b * (c * c) := by
    simp [Nat.mul_comm, Nat.mul_left_comm]
  omega

theorem expand857b (a b c : Nat) :
    c * c * (a * b + 1) + 1 = a * b * (c * c) + (c * c) + 1 := by
  have h4 : c * c * (a * b + 1) + 1 = c * c * (a * b) + c * c + 1 := by
    simp [Nat.mul_add]
  have h6 : c * c * (a * b) = a * b * (c * c) := by
    simp [Nat.mul_comm, Nat.mul_left_comm]
  omega

/-- 展开账：S(ac)·S(bc) = S(c²·S(ab)) ⟺ c·(a+b) = c·c -/
theorem id857_core (a b c : Nat) :
    (a * c + 1) * (b * c + 1) = c * c * (a * b + 1) + 1 ↔ c * (a + b) = c * c := by
  rw [expand857a, expand857b]
  constructor
  · intro h
    have hx : a * c + b * c = c * c := by omega
    calc c * (a + b) = c * a + c * b := Nat.mul_add c a b
      _ = a * c + b * c := by rw [Nat.mul_comm c a, Nat.mul_comm c b]
      _ = c * c := hx
  · intro h
    have hx : a * c + b * c = c * c := by
      calc a * c + b * c = c * a + c * b := by rw [Nat.mul_comm a c, Nat.mul_comm b c]
        _ = c * (a + b) := (Nat.mul_add c a b).symm
        _ = c * c := h
    omega

/-- 主定理：方程 ⟺ c = 0 ∨ a + b = c（c≠0 侧即加法图；c=0 行是噪声，
    定义公式需配 c≠0 边条件——见 docs/91-presburger.md 的账） -/
theorem id857 (a b c : Nat) :
    (a * c + 1) * (b * c + 1) = c * c * (a * b + 1) + 1 ↔ (c = 0 ∨ a + b = c) := by
  constructor
  · intro h
    cases Nat.eq_zero_or_pos c with
    | inl hc => exact Or.inl hc
    | inr hc =>
      exact Or.inr (Nat.eq_of_mul_eq_mul_right hc
        (by rw [Nat.mul_comm]; exact (id857_core a b c).mp h))
  · intro h
    cases h with
    | inl hc => subst hc; simp
    | inr hab =>
      subst hab
      apply (id857_core a b (a + b)).mpr
      omega

/-- 样本行：a=1,b=1,c=2（书例网格的一格：9 = 9） -/
example : (1 * 2 + 1) * (1 * 2 + 1) = 2 * 2 * (1 * 1 + 1) + 1 := by
  decide

-- ---------- 5. 记账 ----------

#print axioms bump_sem
#print axioms min_witness
#print axioms even_or_odd
#print axioms id857_core
#print axioms id857
