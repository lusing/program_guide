/-!
# 第 87 章 · 可构造宇宙 L 与一般连续统假设（冯琦第二卷 §2.1）

三件与 §2.1 同构的事实：

1. 引理 2.1(1)：只要 𝒟 是扩张的（M ⊆ 𝒟(M)），可构造层次就单调上升。
2. 引理 2.1(3) 的引擎：有限载体上「带参数可定义」覆盖全部子集
   ——L_n = V_n 与 L_ω = V_ω 的全部组合内容。
3. 定义 2.4/2.8/引理 2.6(1)：哥德尔项的值落在任何含参数且对
   十个基本运算封闭的族里——「哥德尔闭包」的最小性。
-/

namespace Settheory.Ch87

/- ## 一、可构造层次的单调性（引理 2.1(1) 的抽象形态） -/

/- 集合表示为谓词；𝒟 是「取全部可定义子集」运算的抽象替身。
定义 2.1 里 L_{α+1} = 𝒟(L_α)，而引理 1.15(1) 保证 L_β ⊆ 𝒟(L_β)。 -/
variable {α : Type} (D : (α → Prop) → α → Prop)

def Lh : Nat → α → Prop
  | 0 => fun _ => False
  | n + 1 => D (Lh n)

/-- 引理 2.1(1)：扩张性（M ⊆ 𝒟(M)）单独保证层次单调。
归纳在「大端」n 上进行：m ≤ n 的情形要么 m = n，要么把 Lh n 的成员
用扩张性推进一层。 -/
theorem Lh_mono (hexp : ∀ s x, s x → D s x) :
    ∀ n m, m ≤ n → ∀ x, Lh D m x → Lh D n x := by
  intro n
  induction n with
  | zero =>
    intro m hm x hx
    have hm0 : m = 0 := Nat.le_zero.mp hm
    subst hm0
    exact hx
  | succ n ih =>
    intro m hm x hx
    rcases Nat.eq_or_lt_of_le hm with heq | hlt
    · subst heq; exact hx
    · exact hexp (Lh D n) x (ih m (Nat.le_of_lt_succ hlt) x hx)

/-! ## 二、有限载体上的可定义性引擎（引理 2.1(3)：L_n = V_n） -/

/-- 单自由变元、参数内嵌的公式语言：等式原子 + 属于原子 + 布尔运算。
这是「带参数定义子集」的最小骨架，足以覆盖有限载体的全部子集。 -/
inductive Fm (α : Type) where
  | tt : Fm α
  | ff : Fm α
  | eq (p : α) : Fm α
  | mem (p : α) : Fm α
  | neg (φ : Fm α) : Fm α
  | or (φ ψ : Fm α) : Fm α

/-- 在载体 (α, mem) 上求值：自由变元取 x，参数已经烧进原子。 -/
def sat (mem : α → α → Prop) : Fm α → α → Prop
  | .tt, _ => True
  | .ff, _ => False
  | .eq p, x => x = p
  | .mem p, x => mem x p
  | .neg φ, x => ¬ sat mem φ x
  | .or φ ψ, x => sat mem φ x ∨ sat mem ψ x

theorem sat_complement (mem : α → α → Prop) (φ : Fm α) (x : α) :
    sat mem (.neg φ) x ↔ ¬ sat mem φ x := Iff.rfl

theorem sat_union (mem : α → α → Prop) (φ ψ : Fm α) (x : α) :
    sat mem (.or φ ψ) x ↔ (sat mem φ x ∨ sat mem ψ x) := Iff.rfl

/-- 由参数表生成析取式：x = a₁ ∨ ⋯ ∨ x = a_k。 -/
def disj : List α → Fm α
  | [] => .ff
  | a :: as => .or (.eq a) (disj as)

theorem sat_disj (mem : α → α → Prop) (as : List α) (x : α) :
    sat mem (disj as) x ↔ x ∈ as := by
  induction as with
  | nil => simp [disj, sat]
  | cons a as ih => simp [disj, sat, ih]

/-- 引理 2.1(3) 的引擎：有限载体 L 的每一个子集都由一个带参数的公式定义。
这就是 L_n = V_n（n < ω）的归纳步骤，也是 L_ω = V_ω 的来源：
在有限世界里「可定义」不比「子集」少任何东西；
分歧要等到 ω+1 层——那里公式只有可数多个，而子集有 2^ℵ₀ 个。 -/
theorem finite_definable (mem : α → α → Prop) (L B : List α) :
    ∃ φ : Fm α, ∀ x, x ∈ L → (sat mem φ x ↔ x ∈ B) :=
  ⟨disj B, fun _ _ => sat_disj mem B _⟩

/-! ## 三、哥德尔项闭包（定义 2.4/2.8，引理 2.6(1) 的方向一） -/

/-- 十个哥德尔基本集合运算（定义 2.4）的抽象替身：在纯类型 α 上，
配对/积/受限积/差/交/并/定义域/翻转/轮换₁/轮换₂ 全部并入函数符号。 -/
structure GOps (α : Type) where
  g1 : α → α → α
  g2 : α → α → α
  g3 : α → α → α
  g4 : α → α → α
  g5 : α → α → α
  g6 : α → α
  g7 : α → α
  g8 : α → α
  g9 : α → α
  g10 : α → α

/-- 由参数与十个基本运算复合生成的项——「哥德尔集合运算」（定义 2.4 后半）。 -/
inductive GT (α : Type) where
  | var (a : α) : GT α
  | c1 (t u : GT α) : GT α
  | c2 (t u : GT α) : GT α
  | c3 (t u : GT α) : GT α
  | c4 (t u : GT α) : GT α
  | c5 (t u : GT α) : GT α
  | c6 (t : GT α) : GT α
  | c7 (t : GT α) : GT α
  | c8 (t : GT α) : GT α
  | c9 (t : GT α) : GT α
  | c10 (t : GT α) : GT α

def GT.vars : GT α → List α
  | .var a => [a]
  | .c1 t u => t.vars ++ u.vars
  | .c2 t u => t.vars ++ u.vars
  | .c3 t u => t.vars ++ u.vars
  | .c4 t u => t.vars ++ u.vars
  | .c5 t u => t.vars ++ u.vars
  | .c6 t => t.vars
  | .c7 t => t.vars
  | .c8 t => t.vars
  | .c9 t => t.vars
  | .c10 t => t.vars

def GOps.eval (o : GOps α) : GT α → α
  | .var a => a
  | .c1 t u => o.g1 (eval o t) (eval o u)
  | .c2 t u => o.g2 (eval o t) (eval o u)
  | .c3 t u => o.g3 (eval o t) (eval o u)
  | .c4 t u => o.g4 (eval o t) (eval o u)
  | .c5 t u => o.g5 (eval o t) (eval o u)
  | .c6 t => o.g6 (eval o t)
  | .c7 t => o.g7 (eval o t)
  | .c8 t => o.g8 (eval o t)
  | .c9 t => o.g9 (eval o t)
  | .c10 t => o.g10 (eval o t)

/-- 引理 2.6(1) 的核心：含参数、对十个基本运算封闭的族包含一切哥德尔项的值。
「M 关于哥德尔运算封闭」由这一归纳立即读出。 -/
theorem gt_closure (o : GOps α) (C : α → Prop)
    (hc1 : ∀ x y, C x → C y → C (o.g1 x y)) (hc2 : ∀ x y, C x → C y → C (o.g2 x y))
    (hc3 : ∀ x y, C x → C y → C (o.g3 x y)) (hc4 : ∀ x y, C x → C y → C (o.g4 x y))
    (hc5 : ∀ x y, C x → C y → C (o.g5 x y))
    (hc6 : ∀ x, C x → C (o.g6 x)) (hc7 : ∀ x, C x → C (o.g7 x))
    (hc8 : ∀ x, C x → C (o.g8 x)) (hc9 : ∀ x, C x → C (o.g9 x))
    (hc10 : ∀ x, C x → C (o.g10 x)) (t : GT α) :
    (∀ a ∈ t.vars, C a) → C (o.eval t) := by
  induction t with
  | var a => intro h; exact h a (by simp [GT.vars])
  | c1 t u ih1 ih2 =>
    intro h
    exact hc1 _ _ (ih1 fun a ha => h a (by simp [GT.vars]; exact Or.inl ha))
      (ih2 fun a ha => h a (by simp [GT.vars]; exact Or.inr ha))
  | c2 t u ih1 ih2 =>
    intro h
    exact hc2 _ _ (ih1 fun a ha => h a (by simp [GT.vars]; exact Or.inl ha))
      (ih2 fun a ha => h a (by simp [GT.vars]; exact Or.inr ha))
  | c3 t u ih1 ih2 =>
    intro h
    exact hc3 _ _ (ih1 fun a ha => h a (by simp [GT.vars]; exact Or.inl ha))
      (ih2 fun a ha => h a (by simp [GT.vars]; exact Or.inr ha))
  | c4 t u ih1 ih2 =>
    intro h
    exact hc4 _ _ (ih1 fun a ha => h a (by simp [GT.vars]; exact Or.inl ha))
      (ih2 fun a ha => h a (by simp [GT.vars]; exact Or.inr ha))
  | c5 t u ih1 ih2 =>
    intro h
    exact hc5 _ _ (ih1 fun a ha => h a (by simp [GT.vars]; exact Or.inl ha))
      (ih2 fun a ha => h a (by simp [GT.vars]; exact Or.inr ha))
  | c6 t ih => intro h; exact hc6 _ (ih h)
  | c7 t ih => intro h; exact hc7 _ (ih h)
  | c8 t ih => intro h; exact hc8 _ (ih h)
  | c9 t ih => intro h; exact hc9 _ (ih h)
  | c10 t ih => intro h; exact hc10 _ (ih h)

end Settheory.Ch87
