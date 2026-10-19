set_option linter.unusedSimpArgs false
set_option linter.unusedVariables false

/- ex46 —— 集合、幂集与计数（Jongsma ch4）Lean 镜像
   谓词集合运算律（逐点 iff）、powl/prodl 幂集与笛卡尔积、choose 组合数
   Σ C(n,k) = 2^n、容斥二/三集合。账本：全部仅基线公理（文件尾）。 -/

-- ---------- 1. 谓词集合运算律（逐点 iff） ----------

abbrev PSet := Nat → Prop

def sub (S T : PSet) : Prop := ∀ x, S x → T x
def inter (S T : PSet) : PSet := fun x => S x ∧ T x
def union (S T : PSet) : PSet := fun x => S x ∨ T x
def compl (U S : PSet) : PSet := fun x => U x ∧ ¬ S x

theorem inter_comm : ∀ (S T : PSet) x, inter S T x ↔ inter T S x := by
  intro S T x
  exact ⟨fun h => ⟨h.2, h.1⟩, fun h => ⟨h.2, h.1⟩⟩

theorem union_comm : ∀ (S T : PSet) x, union S T x ↔ union T S x := by
  intro S T x
  exact ⟨fun h => h.symm, fun h => h.symm⟩

theorem inter_assoc : ∀ (R S T : PSet) x,
    inter R (inter S T) x ↔ inter (inter R S) T x := by
  intro R S T x
  constructor
  · intro ⟨h1, h2, h3⟩; exact ⟨⟨h1, h2⟩, h3⟩
  · intro ⟨⟨h1, h2⟩, h3⟩; exact ⟨h1, h2, h3⟩

theorem inter_distrib : ∀ (R S T : PSet) x,
    inter R (union S T) x ↔ union (inter R S) (inter R T) x := by
  intro R S T x
  constructor
  · intro h
    match h with
    | ⟨h1, Or.inl h2⟩ => exact Or.inl ⟨h1, h2⟩
    | ⟨h1, Or.inr h3⟩ => exact Or.inr ⟨h1, h3⟩
  · intro h
    match h with
    | Or.inl ⟨h1, h2⟩ => exact ⟨h1, Or.inl h2⟩
    | Or.inr ⟨h1, h3⟩ => exact ⟨h1, Or.inr h3⟩

-- De Morgan（补的交 = 补的并）：→ 方向本质经典，用 Classical（账本见尾）
theorem demorgan_inter : ∀ (U S T : PSet) x,
    compl U (inter S T) x ↔ union (compl U S) (compl U T) x := by
  intro U S T x
  constructor
  · intro ⟨hu, hn⟩
    by_cases hs : S x
    · exact Or.inr ⟨hu, fun ht => hn ⟨hs, ht⟩⟩
    · exact Or.inl ⟨hu, hs⟩
  · intro h
    match h with
    | Or.inl ⟨hu, hs⟩ => exact ⟨hu, fun h => hs h.1⟩
    | Or.inr ⟨hu, ht⟩ => exact ⟨hu, fun h => ht h.2⟩

theorem ext_eq : ∀ S T : PSet, sub S T → sub T S → ∀ x, S x ↔ T x := by
  intro S T h1 h2 x
  exact ⟨h1 x, h2 x⟩

-- ---------- 2. 幂集与笛卡尔积 ----------

def powl : List Nat → List (List Nat)
  | [] => [[]]
  | a :: t => (powl t).map (fun x => a :: x) ++ powl t

theorem powl_len : ∀ l, (powl l).length = 2 ^ l.length := by
  intro l
  induction l with
  | nil => rfl
  | cons a t ih =>
    show ((powl t).map _ ++ powl t).length = 2 ^ (t.length + 1)
    rw [List.length_append, List.length_map, ih, Nat.pow_succ]
    omega

theorem powl_sound : ∀ l x, x ∈ powl l → ∀ e, e ∈ x → e ∈ l := by
  intro l
  induction l with
  | nil =>
    intro x hin e he
    match (List.mem_cons.mp hin) with
    | Or.inl hx => rw [hx] at he; exact absurd he (by simp)
    | Or.inr h => cases h
  | cons a t ih =>
    intro x hin e he
    match (List.mem_append.mp hin) with
    | Or.inl hmap =>
      match (List.mem_map.mp hmap) with
      | ⟨y, hy, hx⟩ =>
        rw [← hx] at he
        match (List.mem_cons.mp he) with
        | Or.inl h => rw [h]; exact List.Mem.head _
        | Or.inr h => exact List.mem_cons.mpr (Or.inr (ih y hy e h))
    | Or.inr ht =>
      exact List.mem_cons.mpr (Or.inr (ih x ht e he))

def prodl : List Nat → List Nat → List (Nat × Nat)
  | [], _ => []
  | a :: s', t => (t.map (fun b => (a, b))) ++ prodl s' t

theorem prodl_len : ∀ s t, (prodl s t).length = s.length * t.length := by
  intro s
  induction s with
  | nil =>
    intro t
    show (0 : Nat) = ([] : List Nat).length * t.length
    rw [show ([] : List Nat).length = 0 from rfl, Nat.zero_mul]
  | cons a s' ih =>
    intro t
    show ((t.map _ ++ prodl s' t)).length = (s'.length + 1) * t.length
    rw [List.length_append, List.length_map, ih, Nat.add_mul]
    omega

theorem prodl_in : ∀ s t x y, (x, y) ∈ prodl s t ↔ x ∈ s ∧ y ∈ t := by
  intro s
  induction s with
  | nil => intro t x y; simp [prodl]
  | cons a s' ih =>
    intro t x y
    show (x, y) ∈ ((t.map (fun b => (a, b))) ++ prodl s' t) ↔ (x ∈ a :: s' ∧ y ∈ t)
    rw [List.mem_append, List.mem_cons]
    constructor
    · intro h
      match h with
      | Or.inl hmap =>
        match (List.mem_map.mp hmap) with
        | ⟨b, hb, hbp⟩ =>
          match hbp with
          | rfl => exact ⟨Or.inl rfl, hb⟩
      | Or.inr hrest =>
        match (ih t x y).mp hrest with
        | ⟨h1, h2⟩ => exact ⟨Or.inr h1, h2⟩
    · intro h
      match h with
      | ⟨Or.inl hx, hy⟩ =>
        rw [hx]
        exact Or.inl (List.mem_map.mpr ⟨y, hy, rfl⟩)
      | ⟨Or.inr hx, hy⟩ =>
        exact Or.inr ((ih t x y).mpr ⟨hx, hy⟩)

-- ---------- 3. 组合数：Σ C(n,k) = 2^n ----------

def choose : Nat → Nat → Nat
  | 0, 0 => 1
  | 0, _ + 1 => 0
  | _ + 1, 0 => 1
  | n + 1, k + 1 => choose n k + choose n (k + 1)

def sumchoose : Nat → Nat → Nat
  | _, 0 => 1
  | n, k + 1 => sumchoose n k + choose n (k + 1)

theorem choose_gt : ∀ n k, n < k → choose n k = 0 := by
  intro n
  induction n with
  | zero =>
    intro k hk
    match k with
    | 0 => omega
    | k'+1 => rfl
  | succ n' ih =>
    intro k hk
    match k with
    | 0 => omega
    | k'+1 =>
      show choose n' k' + choose n' (k'+1) = 0
      rw [ih k' (by omega), ih (k'+1) (by omega)]

theorem choose_n0 : ∀ n, choose n 0 = 1 := by
  intro n
  match n with
  | 0 => rfl
  | n'+1 => rfl

theorem sumchoose_shift : ∀ n m,
    sumchoose (n+1) (m+1) = sumchoose n m + sumchoose n (m+1) := by
  intro n m
  induction m with
  | zero =>
    show sumchoose (n+1) 1 = sumchoose n 0 + sumchoose n 1
    have e1 : sumchoose (n+1) 1 = sumchoose (n+1) 0 + choose (n+1) 1 := rfl
    have e2 : choose (n+1) 1 = choose n 0 + choose n 1 := rfl
    have e3 : sumchoose n 1 = sumchoose n 0 + choose n 1 := rfl
    have e4 : sumchoose (n+1) 0 = 1 := rfl
    have e5 : sumchoose n 0 = 1 := rfl
    have e6 : choose n 0 = 1 := choose_n0 n
    omega
  | succ m' ih =>
    show sumchoose (n+1) (m'+1+1) = sumchoose n (m'+1) + sumchoose n (m'+1+1)
    have e1 : sumchoose (n+1) (m'+1+1)
              = sumchoose (n+1) (m'+1) + choose (n+1) (m'+1+1) := rfl
    have e2 : choose (n+1) (m'+1+1) = choose n (m'+1) + choose n (m'+1+1) := rfl
    have e3 : sumchoose n (m'+1+1) = sumchoose n (m'+1) + choose n (m'+1+1) := rfl
    have e4 : sumchoose n (m'+1) = sumchoose n m' + choose n (m'+1) := rfl
    omega

theorem sumchoose_pow : ∀ n, sumchoose n n = 2 ^ n := by
  intro n
  induction n with
  | zero => rfl
  | succ n' ih =>
    rw [sumchoose_shift, ih]
    have h1 : sumchoose n' (n'+1) = sumchoose n' n' + choose n' (n'+1) := rfl
    have h2 : choose n' (n'+1) = 0 := choose_gt n' (n'+1) (by omega)
    have h3 : 2 ^ (n' + 1) = 2 ^ n' + 2 ^ n' := by
      rw [Nat.pow_succ]
      omega
    omega

-- ---------- 4. 容斥（列表 filter 版） ----------

theorem incexc2 : ∀ (P Q : Nat → Bool) (l : List Nat),
    ((l.filter fun x => P x || Q x).length
   + (l.filter fun x => P x && Q x).length
   = (l.filter P).length + (l.filter Q).length) := by
  intro P Q l
  induction l with
  | nil => rfl
  | cons a l' ih =>
    simp only [List.filter]
    cases hP : P a <;> cases hQ : Q a <;>
      simp only [Bool.or_true, Bool.or_false, Bool.true_or, Bool.false_or,
                 Bool.and_true, Bool.and_false, Bool.true_and, Bool.false_and,
                 if_true, if_false, List.length_cons, List.length_nil] <;>
      omega

theorem incexc3 : ∀ (P Q R : Nat → Bool) (l : List Nat),
    ((l.filter fun x => (P x || Q x) || R x).length
   + (l.filter fun x => P x && Q x).length
   + (l.filter fun x => P x && R x).length
   + (l.filter fun x => Q x && R x).length
   = (l.filter P).length + (l.filter Q).length + (l.filter R).length
     + (l.filter fun x => (P x && Q x) && R x).length) := by
  intro P Q R l
  induction l with
  | nil => rfl
  | cons a l' ih =>
    simp only [List.filter]
    cases hP : P a <;> cases hQ : Q a <;> cases hR : R a <;>
      simp only [Bool.or_true, Bool.or_false, Bool.true_or, Bool.false_or,
                 Bool.and_true, Bool.and_false, Bool.true_and, Bool.false_and,
                 if_true, if_false, List.length_cons, List.length_nil] <;>
      omega

-- ---------- 5. 冒烟与账本 ----------

#eval powl [1,2,3]
#eval ((powl [1,2,3]).length, 2^3)
#eval ((prodl [1,2,3,5] [1,3,4]).length, 4*3)
#eval (sumchoose 10 10, 2^10)
#eval choose 12 5
def nfact : Nat → Nat
  | 0 => 1
  | n'+1 => (n'+1) * nfact n'

#eval nfact 6                    -- 720
#eval (choose 6 2 * 2 * 24, nfact 6) -- C(6,2)·2!·4! = 6!

#print axioms powl_len
#print axioms prodl_len
#print axioms sumchoose_pow
#print axioms incexc2
#print axioms incexc3
