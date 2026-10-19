/- ex44 —— 递推、结构归纳与 Peano 算术（Jongsma §3.3-3.4）Lean 镜像
   aseq/bseq 闭式、sumfib 部分和、rev 双律与长度同态、wff 左括号=连接词数、
   自造 Sn 结构的 PA 加法/乘法/≤ 全链。账本：全部零公理（文件尾）。 -/

-- ---------- 1. 递推闭式两例 ----------

def pow2b : Nat → Nat
  | 0 => 1
  | (k+1) => 2 * pow2b k

def aseq : Nat → Nat
  | 0 => 4
  | (k+1) => aseq k + 2 * (k+1)

theorem sq_succ (k : Nat) : (k+1) * (k+1) = k*k + 2*k + 1 := by
  have s1 := Nat.add_mul k 1 (k+1)
  have s2 := Nat.mul_add k (k+1) 1
  have s2b := Nat.mul_add k k 1
  have s3 := Nat.mul_one k
  have s4 := Nat.one_mul (k+1)
  omega

theorem aseq_closed : ∀ n, aseq n = n * n + n + 4 := by
  intro n
  induction n with
  | zero => rfl
  | succ k ih =>
    show aseq k + 2 * (k+1) = (k+1) * (k+1) + (k+1) + 4
    rw [sq_succ, ih]
    omega

def bseq : Nat → Nat
  | 0 => 1
  | (k+1) => 2 * bseq k + 3

theorem bseq_closed : ∀ n, bseq n + 3 = pow2b (n + 2) := by
  intro n
  induction n with
  | zero => rfl
  | succ k ih =>
    show 2 * bseq k + 3 + 3 = pow2b (k + 1 + 2)
    show 2 * bseq k + 3 + 3 = 2 * pow2b (k + 2)
    omega

-- ---------- 2. Fibonacci 部分和 ----------

def fib : Nat → Nat
  | 0 => 0
  | 1 => 1
  | (k+2) => fib (k+1) + fib k

theorem fib_step2 (n : Nat) : fib (n+2) = fib (n+1) + fib n := rfl

def sumfib : Nat → Nat
  | 0 => fib 0
  | (k+1) => sumfib k + fib (k+1)

theorem sumfib_shift : ∀ n, sumfib n + 1 = fib (n + 2) := by
  intro n
  induction n with
  | zero => rfl
  | succ k ih =>
    rw [fib_step2] at ih
    show sumfib k + fib (k+1) + 1 = fib (k+1+2)
    rw [fib_step2, fib_step2]
    omega

-- ---------- 3. 结构归纳：串=list ----------

def rev : List Nat → List Nat
  | [] => []
  | x :: t => rev t ++ [x]

theorem app_len : ∀ (s t : List Nat), (s ++ t).length = s.length + t.length := by
  intro s t
  induction s with
  | nil => simp
  | cons x s ih => simp only [List.length_cons, List.cons_append]; omega

theorem rev_app_distr : ∀ (s t : List Nat), rev (s ++ t) = rev t ++ rev s := by
  intro s t
  induction s with
  | nil => simp [rev]
  | cons x s ih =>
    show rev (s ++ t) ++ [x] = rev t ++ (rev s ++ [x])
    rw [ih]
    exact List.append_assoc (rev t) (rev s) [x]

theorem rev_invol : ∀ s : List Nat, rev (rev s) = s := by
  intro s
  induction s with
  | nil => rfl
  | cons x s ih =>
    show rev (rev s ++ [x]) = x :: s
    rw [rev_app_distr]
    show (rev [x] ++ rev (rev s)) = x :: s
    rw [ih]
    rfl

-- ---------- 4. 结构归纳：wff ----------

inductive Wf : Type where
  | var : Nat → Wf
  | neg : Wf → Wf
  | conj : Wf → Wf → Wf
  | imp : Wf → Wf → Wf

open Wf

def lp : Wf → Nat
  | var _ => 0
  | neg g => lp g + 1
  | conj g h => lp g + lp h + 1
  | imp g h => lp g + lp h + 1

def cn : Wf → Nat
  | var _ => 0
  | neg g => cn g + 1
  | conj g h => cn g + cn h + 1
  | imp g h => cn g + cn h + 1

theorem lp_cn : ∀ f : Wf, lp f = cn f := by
  intro f
  induction f with
  | var i => rfl
  | neg g ih => simp only [lp, cn]; omega
  | conj g h ihg ihh => simp only [lp, cn]; omega
  | imp g h ihg ihh => simp only [lp, cn]; omega

-- 唯一分解定理的机器形态：构造子单射/互斥免费
theorem conj_inj : ∀ a b c d : Wf, conj a b = conj c d → a = c ∧ b = d := by
  intro a b c d h
  injection h with h1 h2
  exact ⟨h1, h2⟩

theorem neg_conj_disj : ∀ a c d : Wf, neg a ≠ conj c d := by
  intro a c d h
  exact Wf.noConfusion h

-- ---------- 5. Peano 算术：自造后继结构 ----------

inductive Sn : Type where
  | ze : Sn
  | su : Sn → Sn

open Sn

-- 书公理 3.4.1/3.4.2 在归纳类型里是免费定理
theorem su_nonzero : ∀ n : Sn, su n ≠ ze := by
  intro n h
  exact Sn.noConfusion h

theorem su_inj : ∀ m n : Sn, su m = su n → m = n := by
  intro m n h
  exact Sn.noConfusion h (fun h' => h')

def sadd : Sn → Sn → Sn
  | a, .ze => a
  | a, .su k => .su (sadd a k)

theorem sadd_0_l : ∀ n : Sn, sadd ze n = n := by
  intro n
  induction n with
  | ze => rfl
  | su k ih => exact congrArg su ih

theorem sadd_eq_right : ∀ k m : Sn, sadd m k = k → m = ze := by
  intro k
  induction k with
  | ze => intro m h; exact h
  | su k ih =>
    intro m h
    have h' : sadd m k = k := su_inj _ _ h
    exact ih m h'

theorem sadd_cancel_r : ∀ n l m : Sn, sadd l n = sadd m n → l = m := by
  intro n
  induction n with
  | ze => intro l m h; exact h
  | su k ih =>
    intro l m h
    exact ih l m (su_inj _ _ h)

theorem sadd_zero : ∀ m d : Sn, sadd m d = ze → m = ze ∧ d = ze := by
  intro m d h
  cases m with
  | ze =>
    refine ⟨rfl, ?_⟩
    cases d with
    | ze => rfl
    | su d' => exact Sn.noConfusion h
  | su m' =>
    cases d with
    | ze => exact Sn.noConfusion h
    | su d' => exact Sn.noConfusion h

theorem one_comm : ∀ n : Sn, sadd (su ze) n = sadd n (su ze) := by
  intro n
  induction n with
  | ze => rfl
  | su k ih => exact congrArg su ih

theorem sadd_assoc : ∀ n l m : Sn, sadd (sadd l m) n = sadd l (sadd m n) := by
  intro n
  induction n with
  | ze => intro l m; rfl
  | su k ih =>
    intro l m
    show su (sadd (sadd l m) k) = su (sadd l (sadd m k))
    exact congrArg su (ih l m)

theorem sadd_succ_l : ∀ m k : Sn, sadd (su k) m = su (sadd k m) := by
  intro m
  induction m with
  | ze => intro k; rfl
  | su k' ih =>
    intro k
    show su (sadd (su k) k') = su (su (sadd k k'))
    exact congrArg su (ih k)

theorem sadd_comm : ∀ m n : Sn, sadd m n = sadd n m := by
  intro m n
  induction n with
  | ze => show sadd m ze = sadd ze m; rw [sadd_0_l]; rfl
  | su k ih =>
    show su (sadd m k) = sadd (su k) m
    rw [sadd_succ_l, ← ih]

-- ---------- 6. 乘法与 ≤ ----------

def smul : Sn → Sn → Sn
  | _, .ze => ze
  | a, .su k => sadd (smul a k) a

theorem smul_0_l : ∀ n : Sn, smul ze n = ze := by
  intro n
  induction n with
  | ze => rfl
  | su k ih => exact ih

theorem sadd_swap : ∀ b c d : Sn, sadd b (sadd c d) = sadd c (sadd b d) := by
  intro b c d
  rw [← sadd_assoc, ← sadd_assoc, sadd_comm b c]

theorem sadd_shuffle : ∀ a b c d : Sn,
    sadd (sadd a b) (sadd c d) = sadd (sadd a c) (sadd b d) := by
  intro a b c d
  rw [sadd_assoc, sadd_assoc, sadd_swap b c d]

theorem smul_add_distr_r : ∀ n l m : Sn,
    smul (sadd l m) n = sadd (smul l n) (smul m n) := by
  intro n
  induction n with
  | ze => intro l m; rfl
  | su k ih =>
    intro l m
    show sadd (smul (sadd l m) k) (sadd l m)
          = sadd (sadd (smul l k) l) (sadd (smul m k) m)
    rw [ih]
    exact sadd_shuffle (smul l k) (smul m k) l m

theorem one_mul : ∀ n : Sn, smul (su ze) n = n := by
  intro n
  induction n with
  | ze => rfl
  | su k ih => show sadd (smul (su ze) k) (su ze) = su k; rw [ih]; rfl

theorem smul_succ_l : ∀ m k : Sn, smul (su k) m = sadd (smul k m) m := by
  intro m k
  have e : su k = sadd k (su ze) := rfl
  rw [e, smul_add_distr_r, one_mul]

theorem smul_comm : ∀ m n : Sn, smul m n = smul n m := by
  intro m n
  induction n with
  | ze => show smul m ze = smul ze m; rw [smul_0_l]; rfl
  | su k ih =>
    show sadd (smul m k) m = smul (su k) m
    rw [smul_succ_l, ← ih]

-- ≤ 定义为 ∃d, m + d = n（书练习 3.4.20 起）

def sle (m n : Sn) : Prop := ∃ d, sadd m d = n

theorem sle_refl : ∀ m : Sn, sle m m := by
  intro m
  exact ⟨ze, rfl⟩

theorem sle_trans : ∀ l m n : Sn, sle l m → sle m n → sle l n := by
  intro l m n h1 h2
  cases h1 with
  | intro d1 hd1 =>
    cases h2 with
    | intro d2 hd2 =>
      refine ⟨sadd d1 d2, ?_⟩
      rw [← sadd_assoc, hd1]
      exact hd2

theorem sadd_cancel_l : ∀ n l m : Sn, sadd n l = sadd n m → l = m := by
  intro n l m h
  have h1 : sadd l n = sadd n l := sadd_comm l n
  have h2 : sadd m n = sadd n m := sadd_comm m n
  exact sadd_cancel_r n l m (by rw [h1, h2]; exact h)

theorem sle_antisym : ∀ m n : Sn, sle m n → sle n m → m = n := by
  intro m n h1 h2
  cases h1 with
  | intro d1 hd1 =>
    cases h2 with
    | intro d2 hd2 =>
      have hk : sadd m (sadd d1 d2) = sadd m ze := by
        rw [← sadd_assoc, hd1, hd2]
        rfl
      have hz := sadd_zero d1 d2 (sadd_cancel_l _ _ _ hk)
      cases hz with
      | intro hd1z _ =>
        rw [hd1z] at hd1
        exact hd1

theorem sle_total : ∀ m n : Sn, sle m n ∨ sle n m := by
  intro m n
  induction n with
  | ze => exact Or.inr ⟨m, sadd_0_l m⟩
  | su k ih =>
    cases ih with
    | inl hmk =>
      cases hmk with
      | intro d hd => exact Or.inl ⟨su d, by show su (sadd m d) = su k; rw [hd]⟩
    | inr hkm =>
      cases hkm with
      | intro d hd =>
        match d with
        | .ze =>
            refine Or.inl ⟨su ze, ?_⟩
            show sadd m (su ze) = su k
            rw [← hd]
            rfl
        | .su d' =>
            refine Or.inr ⟨d', ?_⟩
            show sadd (su k) d' = m
            rw [sadd_succ_l]
            exact hd

-- ---------- 7. 冒烟与账本 ----------

#eval (aseq 4, bseq 4)
#eval (sumfib 5 + 1, fib (5 + 2))
#eval (lp (conj (var 1) (neg (var 2))), cn (conj (var 1) (neg (var 2))))

#print axioms sumfib_shift
#print axioms lp_cn
#print axioms sadd_comm
#print axioms smul_comm
#print axioms sle_antisym
#print axioms sle_total
