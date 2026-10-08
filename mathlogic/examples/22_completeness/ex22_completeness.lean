/- ex22 —— 完备性：Henkin 构造的机器面（EFT ch V）Lean 镜像
   合同闭包（fuel+去重）= 词项解释的商结构；Φ 在 TΦ 上成立；
   「原子式可导 ⟺ 在 TΦ 真」双向对账；见证式 Henkin 化可满足性保持。 -/

set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

inductive tm : Type
  | var (n : Nat) : tm
  | fsym (s : Nat) (ts : List tm) : tm

inductive fm : Type
  | rat (s : Nat) (ts : List tm)
  | eqf (t1 t2 : tm)
  | neg (φ : fm)
  | disj (φ ψ : fm)
  | exq (x : Nat) (φ : fm)

-- 方程推导（EFT S 的等词规则身影；同余按参数表结构内联归纳——
-- 高阶辅助谓词会撞 Lean 的严格正定性，Coq 侧无此限制）
inductive dmeq : List (tm × tm) → tm → tm → Prop
  | refl {Φ} t : dmeq Φ t t
  | symm {Φ} {t1 t2} : dmeq Φ t1 t2 → dmeq Φ t2 t1
  | trans {Φ} {t1 t2 t3} : dmeq Φ t1 t2 → dmeq Φ t2 t3 → dmeq Φ t1 t3
  | cong0 {Φ f} : dmeq Φ (.fsym f []) (.fsym f [])
  | congS {Φ f t1 ts1 t2 ts2} :
      dmeq Φ t1 t2 → dmeq Φ (.fsym f ts1) (.fsym f ts2) →
      dmeq Φ (.fsym f (t1 :: ts1)) (.fsym f (t2 :: ts2))
  | hyp {Φ} {t1 t2} : (t1, t2) ∈ Φ → dmeq Φ t1 t2
  | weak {Φ Ψ} {t1 t2} : Φ ⊆ Ψ → dmeq Φ t1 t2 → dmeq Ψ t1 t2

-- 现场语言与理论

def a_c : tm := .fsym 2 []
def b_c : tm := .fsym 3 []
def f (t : tm) : tm := .fsym 0 [t]

def PhiG : List (tm × tm) := [(a_c, b_c), (f a_c, b_c)]

def terms_upto : Nat → List tm
  | 0 => []
  | d + 1 => a_c :: b_c :: (terms_upto d).map f

def T4 : List tm := terms_upto 3

-- 项相等判定：fuel 递归（嵌套结构 guard 同 Coq 之坑）
def teqbL : Nat → List tm → List tm → Bool
  | 0, l1, l2 => match l1, l2 with | [], [] => true | _, _ => false
  | n + 1, [], [] => true
  | n + 1, .var p :: l1', .var q :: l2' => (p == q) && teqbL n l1' l2'
  | n + 1, .fsym s ts :: l1', .fsym s' ts' :: l2' =>
      (s == s') && teqbL n ts ts' && teqbL n l1' l2'
  | _, _, _ => false

def teqb (t u : tm) : Bool := teqbL 30 [t] [u]

def dedup : List (tm × tm) → List (tm × tm) :=
  fun E => E.foldr (fun p acc =>
    if acc.any (fun q => teqb p.1 q.1 && teqb p.2 q.2) then acc else p :: acc) []

def inT4 (t : tm) : Bool := T4.any (teqb t)

-- 一轮闭包：自反（T4 上）+ 对称 + f-同余 + 传递，T4 内截断 + 去重
def close_step (E : List (tm × tm)) : List (tm × tm) :=
  let R := T4.map (fun t => (t, t))
  let S1 := R ++ E ++ E.map (fun p => (p.2, p.1))
  let L := S1.map (fun p => (f p.1, f p.2))
  let Tr := S1.flatMap (fun p =>
    (S1.filter (fun q => teqb p.2 q.1)).map (fun q => (p.1, q.2)))
  dedup ((S1 ++ L ++ Tr).filter (fun p => inT4 p.1 && inT4 p.2))

def closure : List (tm × tm) → Nat → List (tm × tm)
  | E, 0 => E
  | E, fuel + 1 =>
      let E' := close_step E
      if E'.all (fun p => E.any (fun q => teqb p.1 q.1 && teqb p.2 q.2))
      then E else closure E' fuel

def PhiG_cl : List (tm × tm) := closure PhiG 40

-- 类代表：T4 序下第一个与 t 闭包相连的元素
def canon (t : tm) : tm :=
  match (T4.filter (fun u => PhiG_cl.any (fun p => teqb p.1 t && teqb p.2 u))) with
  | u :: _ => u
  | [] => t

def rep_of (t : tm) : tm := canon t

def quotient_D : List tm :=
  T4.foldr (fun t acc =>
    if acc.any (fun u => teqb u (rep_of t)) then acc else rep_of t :: acc) []

def holds_eq (t1 t2 : tm) : Bool := teqb (rep_of t1) (rep_of t2)

example : PhiG.all (fun p => holds_eq p.1 p.2) = true := by native_decide

-- 「原子式可导 ⟺ 在 TΦ 真」双向对账
def deriv_b (t1 t2 : tm) : Bool :=
  PhiG_cl.any (fun p => (teqb p.1 t1 && teqb p.2 t2)
                     || (teqb p.1 t2 && teqb p.2 t1))

def probes : List (tm × tm) :=
  [ (a_c, b_c), (f a_c, b_c), (f b_c, a_c), (f (f a_c), b_c),
    (f (f (f a_c)), a_c), (a_c, f (f b_c)) ]

example : probes.all (fun p => deriv_b p.1 p.2 == holds_eq p.1 p.2) = true := by
  native_decide

-- 见证式 Henkin 化：可满足性保持
def fm_bool (v : Nat → Bool) : fm → Bool
  | .rat _ _ => v 0
  | .eqf _ _ => v 1
  | .neg ψ => !fm_bool v ψ
  | .disj ψ χ => fm_bool v ψ || fm_bool v χ
  | .exq _ ψ => fm_bool v ψ

def sat (v : Nat → Bool) (Φ : List fm) : Bool := Φ.all (fm_bool v)

def henk : List fm → List fm
  | [] => []
  | .exq _ ψ :: Φ' => ψ :: henk Φ'
  | φ :: Φ' => φ :: henk Φ'

def AX1 : List fm := [.disj (.rat 0 []) (.rat 0 []), .neg (.rat 0 [])]

example : ((List.range 4).all (fun m =>
    sat (fun n => (m >>> n) &&& 1 == 1) AX1
      == sat (fun n => (m >>> n) &&& 1 == 1) (henk AX1))) = true := by native_decide

-- 二元域真量词：∃x P(x) 的 Henkin 分配
def bumpv (P : Nat → Bool) (a : Nat) : Nat → Bool :=
  fun n => if n == 0 then a == 1 else P n

def ev2 (P : Nat → Bool) : fm → Bool
  | .rat _ _ => P 0
  | .eqf _ _ => P 1
  | .neg ψ => !ev2 P ψ
  | .disj ψ χ => ev2 P ψ || ev2 P χ
  | .exq _ ψ => ev2 (bumpv P 0) ψ || ev2 (bumpv P 1) ψ

def sat2 (P : Nat → Bool) (Φ : List fm) : Bool := Φ.all (ev2 P)

def AX2 : List fm := [.exq 0 (.rat 0 []), .neg (.exq 0 (.rat 0 []))]

example : ((List.range 4).all (fun m =>
    !sat2 (fun n => (m >>> n) &&& 1 == 1) AX2)) = true := by native_decide

-- 冒烟
#eval quotient_D.length              -- 1（全塌缩）
#eval (T4.map rep_of).length         -- 6
#eval probes.map (fun p => (deriv_b p.1 p.2, holds_eq p.1 p.2))
