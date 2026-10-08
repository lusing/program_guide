/- ex29 —— 自由模型与逻辑编程的代数（EFT ch XI）Lean 镜像
   幺半群的自由模型=表；初始性两定理（存在唯一同态）；必需性闭包。 -/

set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

-- 自由幺半群：表=词；乘=拼接；幺=空表
def wmul (u v : List Nat) : List Nat := u ++ v

theorem wmul_assoc (u v w : List Nat) :
    wmul (wmul u v) w = wmul u (wmul v w) := by
  simp [wmul, List.append_assoc]

theorem wmul_ident (u : List Nat) : wmul [] u = u := by rfl

-- 现场模型 1：nat 加法
def nat_mon (a b : Nat) : Nat := a + b
def suml (u : List Nat) : Nat := u.foldr (· + ·) 0

theorem suml_mul (u v : List Nat) :
    suml (wmul u v) = nat_mon (suml u) (suml v) := by
  induction u with
  | nil => simp [suml, wmul, nat_mon]
  | cons a u' ih =>
      have : suml (u' ++ v) = suml u' + suml v := ih
      show a + suml (u' ++ v) = a + suml u' + suml v
      omega

theorem suml_one : suml [] = 0 := by rfl

-- 初始性（唯一性侧）：同态由生成元上的取值唯一决定
theorem mor_unique (h : List Nat → Nat)
    (Hmul : ∀ a b, h (wmul a b) = nat_mon (h a) (h b))
    (Hone : h [] = 0) (Hgen : ∀ a, h [a] = a) :
    ∀ u, h u = suml u := by
  intro u
  induction u with
  | nil => exact Hone
  | cons a u' ih =>
      have hu : h (a :: u') = h [a] + h u' := by
        have h1 := Hmul [a] u'
        simp [wmul, nat_mon] at h1
        exact h1
      rw [hu, Hgen a, ih, suml] ; rfl

-- 现场模型 2：布尔与
def bool_mon (a b : Bool) : Bool := a && b
def andl (u : List Bool) : Bool := u.foldr (· && ·) true
def wmulb (u v : List Bool) : List Bool := u ++ v

theorem andl_mul (u v : List Bool) :
    andl (wmulb u v) = bool_mon (andl u) (andl v) := by
  -- 关键引理：折叠的「累加器交换」——foldr f b l = foldr f true l && b
  have acc : ∀ (l : List Bool) (b : Bool),
      List.foldr (fun x y => x && y) b l
        = (List.foldr (fun x y => x && y) true l && b) := by
    intro l
    induction l with
    | nil => intro b; cases b <;> rfl
    | cons x l' ihl =>
        intro b
        rw [List.foldr_cons, List.foldr_cons, ihl]
        cases x <;> cases b <;> rfl
  induction u generalizing v with
  | nil => simp [andl, wmulb, bool_mon]
  | cons a u' ih =>
      simp only [andl, wmulb, bool_mon, List.foldr_cons,
                 List.cons_append]
      rw [List.foldr_append, acc]
      cases a <;> simp [Bool.and_assoc]

-- 必需性：长度函数良定义（穿过同态）
theorem suml_length (u : List Nat) :
    suml (u.map fun _ => 1) = u.length := by
  induction u with
  | nil => rfl
  | cons a u' ih =>
      simp only [List.map_cons, List.length_cons]
      unfold suml at ih ⊢
      simp only [List.foldr_cons] at ih ⊢
      omega

-- 自由=无额外等同：不同生成元的词不同
example : suml [1] != suml [2] := by decide

-- 冒烟
#eval suml [1, 2, 3]                    -- 6
#eval andl [true, false]                -- false
#eval wmul [1, 2] [3]                   -- [1, 2, 3]
#eval [[1], [2], [1, 2]].map suml       -- [1, 2, 3]
