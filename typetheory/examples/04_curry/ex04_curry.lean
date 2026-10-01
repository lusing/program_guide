/- ============================================================
   04 Curry 式类型指派与主类型算法 —— Lean 实现
   Hindley《BSTT》ch.2–3 的机器版：
     类型 = 变量 | 箭头；项 = 无注解 λ 项
     指派 Γ ⊢ M : T 由三条规则给出；
     主类型算法 PT：约束生成 + Robinson 合一（带 occurs check）
   这是 Hindley–Milner 类型推断的根：ML/Haskell 的 infer 由此长出
   ============================================================ -/

/-- 类型：变元用自然数编号 -/
inductive Ty where
  | tvar : Nat → Ty
  | arrow : Ty → Ty → Ty
deriving Repr, BEq

/-- Curry 式项：绑定器【无】类型注解 -/
inductive Tm where
  | var : Nat → Tm
  | lam : Tm → Tm
  | app : Tm → Tm → Tm
deriving Repr

/- ---------- 代换 = 「变元 ↦ 类型」的函数 ----------
   函数式表示免掉链式查表，applyS 只剩结构递归。 ---------- -/

abbrev Subst := Nat → Ty

def applyS (s : Subst) : Ty → Ty
  | .tvar n => s n
  | .arrow a b => .arrow (applyS s a) (applyS s b)

/-- σ ∘ τ：先用 τ 再用 σ -/
def comp (σ τ : Subst) : Subst := fun n => applyS σ (τ n)

def single (n : Nat) (t : Ty) : Subst := fun k =>
  if k = n then t else .tvar k

/- ---------- Robinson 合一（occurs check 防无限项） ---------- -/

def occurs (n : Nat) : Ty → Bool
  | .tvar m => n == m
  | .arrow a b => occurs n a || occurs n b

/-- 合一：返回使两类型相等的代换。arrow/arrow 情形先合一定义域，
    再合一喝过 s₁ 的值域。燃料兜底（合一本必终止，见 Hindley 3D；
    教学实现不证测度） -/
def unify (fuel : Nat) (a b : Ty) : Option Subst :=
  match fuel, a, b with
  | 0, _, _ => none
  | _ + 1, .tvar n, .tvar m =>
      if n = m then some id else some (single n (.tvar m))
  | _ + 1, .tvar n, t =>
      if occurs n t then none                    -- x ≟ …x…：无有限解
      else if t == .tvar n then some id else some (single n t)
  | _ + 1, t, .tvar n =>
      if occurs n t then none
      else if t == .tvar n then some id else some (single n t)
  | fuel + 1, .arrow a1 b1, .arrow a2 b2 =>
      match unify fuel a1 a2 with
      | none => none
      | some s1 =>
          match unify fuel (applyS s1 b1) (applyS s1 b2) with
          | none => none
          | some s2 => some (comp s2 s1)
where
  id : Subst := fun n => .tvar n

/-- 解约束表：逐条合一，代换累积并作用于剩余约束。
    燃料版结构递归（不用 WF 测度：WellFounded.fix 内核难解，
    by rfl 断言会卡） -/
def solve : Nat → List (Ty × Ty) → Option Subst
  | 0, _ => none
  | _ + 1, [] => some (fun n => .tvar n)
  | fuel + 1, (a, b) :: cs =>
      match unify fuel a b with
      | none => none
      | some s =>
          match solve fuel (cs.map (fun (x, y) => (applyS s x, applyS s y))) with
          | none => none
          | some s' => some (comp s' s)

/- ---------- 约束生成：为每个绑定器发一个新类型变元 ----------
   gen next Γ M = (更新后的计数器, M 的类型, 新增约束)          -/

def gen (next : Nat) (ctx : List Ty) : Tm → Option (Nat × Ty × List (Ty × Ty))
  | .var k =>
      match ctx[k]? with
      | some t => some (next, t, [])
      | none => none                       -- 未绑定变量：不指派
  | .lam b =>
      let a := .tvar next                  -- 绑定器拿到新鲜变元
      match gen (next + 1) (a :: ctx) b with
      | some (n, t, cs) => some (n, .arrow a t, cs)
      | none => none
  | .app f x =>
      match gen next ctx f with
      | none => none
      | some (n1, tf, cs1) =>
          match gen n1 ctx x with
          | none => none
          | some (n2, tx, cs2) =>
              let r := .tvar n2            -- 应用结果的新鲜变元
              some (n2 + 1, r, (tf, .arrow tx r) :: (cs1 ++ cs2))

/-- 主类型算法 PT：生成 + 求解 + 应用 -/
def principal (t : Tm) : Option Ty :=
  match gen 0 [] t with
  | none => none
  | some (_, ty, cs) =>
      match solve 400 cs with
      | none => none
      | some s => some (applyS s ty)

/- ---------- 实测一：经典组合子的主类型 ---------- -/

-- λx. x 的主类型：t0 → t0
example : principal (.lam (.var 0)) = some (.arrow (.tvar 0) (.tvar 0)) := by rfl

-- λx y. x（K）：t0 → t1 → t0
example : principal (.lam (.lam (.var 1)))
        = some (.arrow (.tvar 0) (.arrow (.tvar 1) (.tvar 0))) := by rfl

-- λf x. f x（应用子）：变元编号跟随算法的新鲜计数器（(t1→t2)→(t1→t2)，
-- 与书上的 (a→b)→(a→b) 只差换名）
example : principal (.lam (.lam (.app (.var 1) (.var 0))))
        = some (.arrow (.arrow (.tvar 1) (.tvar 2)) (.arrow (.tvar 1) (.tvar 2)))
        := by rfl

-- λf g x. f (g x)（组合子 B）：编号随算法走，(t3→t4)→(t2→t3)→t2→t4
example : principal (.lam (.lam (.lam (.app (.var 2) (.app (.var 1) (.var 0))))))
        = some (.arrow (.arrow (.tvar 3) (.tvar 4))
                  (.arrow (.arrow (.tvar 2) (.tvar 3))
                    (.arrow (.tvar 2) (.tvar 4)))) := by rfl

-- λx y z. x z (y z)（S）：(t2→t4→t5)→(t2→t4)→t2→t5
example : principal (.lam (.lam (.lam (.app (.app (.var 2) (.var 0))
                                             (.app (.var 1) (.var 0))))))
        = some (.arrow (.arrow (.tvar 2) (.arrow (.tvar 4) (.tvar 5)))
                  (.arrow (.arrow (.tvar 2) (.tvar 4))
                    (.arrow (.tvar 2) (.tvar 5)))) := by rfl

/- ---------- 实测二：不可类型化 ---------- -/

-- ω = λx. x x：x 得同时是 t0 和 t0→?；occurs check 拒绝
example : principal (.lam (.app (.var 0) (.var 0))) = none := by rfl

-- Ω = ω ω：同因
example : principal (.app (.lam (.app (.var 0) (.var 0)))
                          (.lam (.app (.var 0) (.var 0))))
        = none := by rfl

/- ---------- 实测三：指派的多型与主型 ---------- -/

-- Curry 式：一个项可以有很多指派类型（t→t, (s→s)→(s→s), …），
-- 但它们都是主类型的【实例】（Hindley 主类型定理 3A1：
-- 类型可指派 ⟺ 是主类型的替换实例）
example : applyS (single 0 (.tvar 3)) (.arrow (.tvar 0) (.tvar 0))
        = .arrow (.tvar 3) (.tvar 3) := by rfl

-- 自由变量的下场：λf. (λx. x) (f …) 若体内引用未绑定变量 → 不指派
example : principal (.lam (.app (.lam (.var 0)) (.app (.var 0) (.var 2))))
        = none := by rfl     -- var 2 未绑定（封闭算法对自由变量说不）

#eval principal (.lam (.lam (.app (.var 1) (.var 0))))   -- some (t0 → t1 → t1 … 见输出)
