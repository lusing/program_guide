/- ex57_recfn.lean —— 递归函数与部分递归（Mendelson §3.3）Lean 镜像
   prf 构造子+itup 闭包求值器+逐函数步进方程（rfl）+书例函数族全正确
   +Ackermann（双层递归可定义非 PR）+限制 μ 有界搜索。 -/

set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

-- ============ 一、PR 语法与求值器 ============

inductive Prf : Type where
  | pz                       -- 零函数 Z
  | ps                       -- 后继 N
  | prj (n i : Nat)          -- 投影 U_i^n
  | comp1 (g h : Prf)        -- 一元复合 g(h(x))——(IV) 的代表
  | comp2 (g h1 h2 : Prf)    -- 二元复合 g(h1(x), h2(x))——(IV) 的代表
  | prec (g h : Prf)         -- 原始递归 (V)

def itup (step : Nat → Nat → Nat) (r : Nat) : Nat → Nat
  | 0 => r
  | m + 1 => step m (itup step r m)

def peval (f : Prf) (args : List Nat) : Nat :=
  match f with
  | .pz => 0
  | .ps => match args with | [] => 0 | a :: _ => a + 1
  | .prj _ i => args.getD i 0
  | .comp1 g h => peval g [peval h args]
  | .comp2 g h1 h2 => peval g [peval h1 args, peval h2 args]
  | .prec g h =>
      match args with
      | [] => 0
      | a :: xs => itup (fun m r => peval h (m :: r :: xs)) (peval g xs) a

-- 原始递归的展开方程（通用版，转换检查即可）
theorem prec_unfold (g h : Prf) (x : Nat) (xs : List Nat) :
    peval (.prec g h) (Nat.succ x :: xs)
    = peval h (x :: peval (.prec g h) (x :: xs) :: xs) := rfl

-- ============ 二、书例函数族（命题 3.16）============

def prAdd : Prf := .prec (.prj 1 0) (.comp1 .ps (.prj 3 1))
def prMul : Prf := .prec .pz (.comp2 prAdd (.prj 3 1) (.prj 3 2))
def prPred : Prf := .prec .pz (.prj 2 0)
-- 约定：求值器对首变元递归，故 prMonus [x,y] = y ∸ x
def prMonus : Prf := .prec (.prj 1 0) (.comp1 prPred (.prj 3 1))
def prSg : Prf := .comp2 prMonus prPred (.prj 1 0)
def prExp : Prf := .prec (.comp1 .ps .pz) (.comp2 prMul (.prj 3 1) (.prj 3 2))
def prFact : Prf :=
  .prec (.comp1 .ps .pz) (.comp2 prMul (.prj 3 1) (.comp1 .ps (.prj 3 0)))

-- 逐函数步进方程——整条链都是定义方程的转换检查
theorem prAdd_S (x y : Nat) :
    peval prAdd [Nat.succ x, y] = (peval prAdd [x, y]) + 1 := rfl

theorem prMul_S (x y : Nat) :
    peval prMul [Nat.succ x, y] = peval prAdd [peval prMul [x, y], y] := rfl

theorem prPred_S (x : Nat) : peval prPred [Nat.succ x] = x := rfl

theorem prMonus_S (x y : Nat) :
    peval prMonus [Nat.succ x, y] = peval prPred [peval prMonus [x, y]] := rfl

theorem prFact_S (x : Nat) :
    peval prFact [Nat.succ x] = peval prMul [peval prFact [x], x + 1] := rfl

theorem prAdd_is_add (x y : Nat) : peval prAdd [x, y] = x + y := by
  induction x with
  | zero => simp [peval, prAdd, itup]
  | succ x ih => rw [prAdd_S, ih]; omega

theorem prMul_is_mul (x y : Nat) : peval prMul [x, y] = x * y := by
  induction x with
  | zero => simp [peval, prMul, itup]
  | succ x ih => rw [prMul_S, prAdd_is_add, ih, Nat.succ_mul]

theorem prPred_is_pred (x : Nat) : peval prPred [x] = Nat.pred x := by
  cases x with
  | zero => rfl
  | succ x => rw [prPred_S, Nat.pred_succ]

theorem prMonus_is_sub (x y : Nat) : peval prMonus [x, y] = y - x := by
  induction x with
  | zero => simp [peval, prMonus, itup]
  | succ x ih =>
      rw [prMonus_S, prPred_is_pred, ih, Nat.pred_eq_sub_one]; omega

def fact : Nat → Nat
  | 0 => 1
  | x + 1 => (x + 1) * fact x

theorem prFact_is_fact (x : Nat) : peval prFact [x] = fact x := by
  induction x with
  | zero => rfl
  | succ x ih => rw [prFact_S, prMul_is_mul, ih, Nat.mul_comm]; rfl

-- ============ 三、对账表 ============

example :
    ((List.range 8).map fun x =>
      (peval prPred [x], peval prMonus [3, x], peval prSg [x]))
    = [(0, 0, 0), (0, 0, 1), (1, 0, 1), (2, 0, 1), (3, 1, 1),
       (4, 2, 1), (5, 3, 1), (6, 4, 1)] := by native_decide

example :
    ((List.range 6).map fun x => (peval prExp [x, 2], peval prFact [x]))
    = [(1, 1), (2, 1), (4, 2), (8, 6), (16, 24), (32, 120)] := by native_decide

example :
    ((List.range 5).map fun m =>
      (List.range 5).map fun n => peval prAdd [m, n])
    = ((List.range 5).map fun m =>
        (List.range 5).map fun n => m + n) := by native_decide

-- ============ 四、Ackermann：可定义但非 PR ============

-- 双层递归：外层对 m，内层对 k——非 PR 的现场（增长失控，见 docs 对角论证）
def ack : Nat → Nat → Nat
  | 0, n => n + 1
  | m + 1, 0 => ack m 1
  | m + 1, n + 1 => ack m (ack (m + 1) n)

theorem ack_1n (n : Nat) : ack 1 n = n + 2 := by
  induction n with
  | zero => simp [ack]
  | succ n ih =>
      have h : ack 1 (n + 1) = ack 0 (ack 1 n) := by simp [ack]
      rw [h, ih]; simp [ack]

theorem ack_2n (n : Nat) : ack 2 n = 2 * n + 3 := by
  induction n with
  | zero => simp [ack]
  | succ n ih =>
      have h : ack 2 (n + 1) = ack 1 (ack 2 n) := by simp [ack]
      rw [h, ih, ack_1n]; omega

-- 增长对账：ack 3 n = 2^(n+3) - 3
example : (List.range 6).map (ack 3) = [5, 13, 29, 61, 125, 253] := by native_decide
example : ((List.range 6).map (ack 2), (List.range 4).map (ack 3))
    = ([3, 5, 7, 9, 11, 13], [5, 13, 29, 61]) := by native_decide

-- ============ 五、限制 μ-算子：有界最小化 ============

def muleast (g : Nat → Nat) : Nat → Option Nat
  | 0 => if g 0 == 0 then some 0 else none
  | b + 1 =>
      match muleast g b with
      | some y => some y
      | none => if g (b + 1) == 0 then some (b + 1) else none

example : muleast (fun y => (2 * y - 4) + (4 - 2 * y)) 10 = some 2 := by native_decide
example : muleast (fun y => y + 1) 10 = none := by native_decide

-- ============ 账本 ============

#print axioms prAdd_is_add
#print axioms prMul_is_mul
#print axioms prMonus_is_sub
#print axioms ack_2n
