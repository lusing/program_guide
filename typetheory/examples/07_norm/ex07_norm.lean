/- ============================================================
   07 正规化与可指派刻画 —— Lean 旗舰实现（Hindley 2D + 5C）
   甲·Curry 侧（2D）：typable 类的机器刻画
     · Y 不可指派（WN 之逆否：无范式 ⟹ 不可指派）
     · SN ⇏ typable（λx. x x 是范式却不可指派）
     · 2D7：可指派项的 β-相等可判定（范式比对）
   乙·Church 侧（5C1）：**图灵 1942 的 WN 证明机器化**
     · redex 的「度数」= 函数部分类型的大小
     · 策略：永远收缩当前最大度数的（最左）redex
     · 关键引理的机器面：收缩后新 redex 度数严格变小
   ============================================================ -

先 Curry 侧：β 机器 + PT 机器（复制自 05/06 章）。 -/

inductive UT where          -- 无类型项（Curry 侧）
  | var : Nat → UT
  | lam : UT → UT
  | app : UT → UT → UT
deriving Repr, BEq

namespace UT

def shift (d : Int) (c : Nat) : UT → UT
  | var k => if c ≤ k then var (Int.toNat (Int.ofNat k + d)) else var k
  | lam b => lam (shift d (c + 1) b)
  | app f a => app (shift d c f) (shift d c a)

def subst (j : Nat) (s : UT) : UT → UT
  | var k => if k = j then s else var k
  | lam b => lam (subst (j + 1) (shift 1 0 s) b)
  | app f a => app (subst j s f) (subst j s a)

def step : UT → Option UT
  | app (lam b) a => some (shift (-1) 0 (subst 0 (shift 1 0 a) b))
  | app f a =>
      match step f with
      | some f' => some (app f' a)
      | none => (step a).map (fun a' => app f a')
  | lam b => (step b).map lam
  | var _ => none

/-- β-nf 判定：step 返 none 即范式 -/
def isNf (t : UT) : Bool := (step t).isNone

end UT

inductive Ty where
  | tvar : Nat → Ty
  | arrow : Ty → Ty → Ty
deriving Repr, BEq

abbrev Subst := Nat → Ty

def applyS (s : Subst) : Ty → Ty
  | .tvar n => s n
  | .arrow a b => .arrow (applyS s a) (applyS s b)

def comp (σ τ : Subst) : Subst := fun n => applyS σ (τ n)

def single (n : Nat) (t : Ty) : Subst := fun k => if k = n then t else .tvar k

def occursTy (n : Nat) : Ty → Bool
  | .tvar m => n == m
  | .arrow a b => occursTy n a || occursTy n b

def unify : Nat → Ty → Ty → Option Subst
  | 0, _, _ => none
  | _ + 1, .tvar n, .tvar m =>
      if n = m then some (fun n => .tvar n) else some (single n (.tvar m))
  | _ + 1, .tvar n, t =>
      if occursTy n t then none
      else if t == .tvar n then some (fun n => .tvar n) else some (single n t)
  | _ + 1, t, .tvar n =>
      if occursTy n t then none
      else if t == .tvar n then some (fun n => .tvar n) else some (single n t)
  | fuel + 1, .arrow a1 b1, .arrow a2 b2 =>
      match unify fuel a1 a2 with
      | none => none
      | some s1 =>
          match unify fuel (applyS s1 b1) (applyS s1 b2) with
          | none => none
          | some s2 => some (comp s2 s1)

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

def gen (next : Nat) (ctx : List Ty) : UT → Option (Nat × Ty × List (Ty × Ty))
  | .var k =>
      match ctx[k]? with
      | some t => some (next, t, [])
      | none => none
  | .lam b =>
      let a := .tvar next
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
              let r := .tvar n2
              some (n2 + 1, r, (tf, .arrow tx r) :: (cs1 ++ cs2))

/-- 主类型算法（05 章） -/
def principal (t : UT) : Option Ty :=
  match gen 0 [] t with
  | none => none
  | some (_, ty, cs) =>
      match solve 400 cs with
      | none => none
      | some s => some (applyS s ty)

/-- 可指派判定（2D3：PT 算法即判定程序） -/
def typable (t : UT) : Bool := (principal t).isSome

open UT Ty

/- ---------- 甲·实测一：Y 不可指派（2D5.1 的逆否用法） ---------- -/

/-- Y = λf. (λx. f (x x)) (λx. f (x x)) -/
def Y : UT :=
  lam (app (lam (app (var 1) (app (var 0) (var 0))))
            (lam (app (var 1) (app (var 0) (var 0)))))

example : principal Y = none := by rfl

/-- 无类型规范化（02 章同款，命名避撞） -/
def goFuel : Nat → UT → UT
  | 0, t => t
  | n + 1, t => match step t with
    | none => t
    | some t' => goFuel n t'

-- Y 无 β-范式（1B9.1）：燃料烧完仍不是范式——「不停」的机器面
example : isNf (goFuel 60 Y) = false := by rfl

/- ---------- 甲·实测二：SN ⇏ typable ---------- -/

-- λx. x x 是 β-范式（故 SN），但 occurs check 拒绝配型
example : isNf (lam (app (var 0) (var 0))) = true := by rfl
example : principal (lam (app (var 0) (var 0))) = none := by rfl

-- 对照：SN 的充分条件之外没有免费午餐——但 2D8（BCKλ ⟹ typable）
-- 给了「无重复使用 ⟹ 必可指派」的反向桥。B、C、K 机器验票：
def Bc : UT := lam (lam (lam (app (var 2) (app (var 1) (var 0)))))
def Cc : UT := lam (lam (lam (app (app (var 2) (var 0)) (var 1))))
example : typable Bc = true := by rfl
example : typable Cc = true := by rfl
example : typable (lam (lam (var 1))) = true := by rfl   -- K

/- ---------- 甲·实测三：2D7 β-相等可判定（范式比对） ---------- -/

-- SKK 与 I：都可指派、范式相同 ⟹ β-相等——判定算法跑给机器看
def S : UT := lam (lam (lam (app (app (var 2) (var 0)) (app (var 1) (var 0)))))
def Kc : UT := lam (lam (var 1))
def Iu : UT := lam (var 0)

def goNF : Nat → UT → UT
  | 0, t => t
  | n + 1, t => match step t with
    | none => t
    | some t' => goNF n t'

example : goNF 100 (app (app S Kc) Kc) = goNF 100 Iu := by rfl

/- ============================================================
   乙·Church 侧：图灵 1942 度数策略（5C1）
   ============================================================ -/

inductive Ty2 where           -- 基型用 Nat 编号（与 Curry 侧 Ty 区分）
  | base : Nat → Ty2
  | arrow : Ty2 → Ty2 → Ty2
deriving Repr, BEq

inductive Tm where            -- 带注解项（Church 式；声明须在 Ty2 之后）
  | var : Nat → Tm
  | lam : Ty2 → Tm → Tm
  | app : Tm → Tm → Tm
deriving Repr, BEq, Inhabited

namespace Tm

def shift (d : Int) (c : Nat) : Tm → Tm
  | var k => if c ≤ k then var (Int.toNat (Int.ofNat k + d)) else var k
  | lam ty b => lam ty (shift d (c + 1) b)
  | app f a => app (shift d c f) (shift d c a)

def subst (j : Nat) (s : Tm) : Tm → Tm
  | var k => if k = j then s else var k
  | lam ty b => lam ty (subst (j + 1) (shift 1 0 s) b)
  | app f a => app (subst j s f) (subst j s a)

/-- β 单步（最左外，Church 式注解随绑定器走） -/
def step : Tm → Option Tm
  | app (lam _ b) a => some (shift (-1) 0 (subst 0 (shift 1 0 a) b))
  | app f a =>
      match step f with
      | some f' => some (app f' a)
      | none => (step a).map (fun a' => app f a')
  | lam ty b => (step b).map (fun b' => lam ty b')
  | var _ => none

/-- 类型检查（04 章同款） -/
def infer (ctx : List Ty2) : Tm → Option Ty2
  | var k => ctx[k]?
  | lam ty b => (infer (ty :: ctx) b).map (fun bt => .arrow ty bt)
  | app f a =>
      match infer ctx f, infer ctx a with
      | some (.arrow i o), some i' => if i == i' then some o else none
      | _, _ => none

/-! ### 度数机械（Turing 1942）

redex `((λx:σ→τ. M) N)` 的**度数** = 其函数部分注解的大小 |σ→τ|。
关键引理（5C1 的心脏）：收缩一个度数 d 的 redex，
- 其余 redex 的**残余**度数不变；
- **新生**的 redex 度数严格 < d（函数部分是 N（类型 τ）或
  [N/x]M 的子应用（支配类型 σ 或 τ），都比 σ→τ 小）。 -/

def tySize : Ty2 → Nat
  | .base _ => 1
  | .arrow a b => 1 + tySize a + tySize b

/-- 收集全部 redex 的度数（最左外次序） -/
def redexDegrees : Tm → List Nat
  | app (lam ty _) a => tySize ty :: (redexDegrees a)
  | app f a => redexDegrees f ++ redexDegrees a
  | lam _ b => redexDegrees b
  | var _ => []

def maxOf : List Nat → Option Nat
  | [] => none
  | x :: xs => match maxOf xs with
    | none => some x
    | some m => some (max x m)

def maxDegree (t : Tm) : Option Nat := maxOf (redexDegrees t)

/-- 收缩最左一个「度数 = md」的 redex -/
def stepMaxWith (md : Nat) : Tm → Option Tm
  | app (lam ty b) a =>
      if tySize ty = md then some (shift (-1) 0 (subst 0 (shift 1 0 a) b))
      else
        match stepMaxWith md (lam ty b) with
        | some f' => some (app f' a)
        | none => (stepMaxWith md a).map (fun a' => app (lam ty b) a')
  | app f a =>
      match stepMaxWith md f with
      | some f' => some (app f' a)
      | none => (stepMaxWith md a).map (fun a' => app f a')
  | lam ty b => (stepMaxWith md b).map (fun b' => lam ty b')
  | var _ => none

/-- 图灵策略单步：收缩当前最大度数的最左 redex -/
def stepMax (t : Tm) : Option Tm :=
  match maxDegree t with
  | none => none
  | some d => stepMaxWith d t

/-- 度数轨迹：每次收缩前记录当前最大度数（应严格下降着归零） -/
def degreeTrace : Nat → Tm → List Nat
  | 0, _ => []
  | n + 1, t => match stepMax t with
    | none => []
    | some t' => (maxDegree t).getD 0 :: degreeTrace n t'

/-- 图灵规范化：永远收缩最大度 redex；WN 定理保证必达范式 -/
def normalizeTuring : Nat → Tm → Tm
  | 0, t => t
  | n + 1, t => match stepMax t with
    | none => t
    | some t' => normalizeTuring n t'

end Tm

open Tm Ty2

/- ---------- 乙·样本 ---------- -/

def a : Ty2 := .base 0
def idT : Tm := lam (.arrow a a) (var 0)                  -- λ(x:a→a). x
def ida : Tm := lam a (var 0)                             -- λ(x:a). x

/-- E1 = (λ(g:(a→a)→(a→a)). g (λx:a. x)) I —— 度数 7 的redex 缩出度数 3 的新 redex -/
def E1 : Tm :=
  app (lam (.arrow (.arrow a a) (.arrow a a))
           (app (var 0) ida))
      idT

/-- E2 = twice2 argC：度数 7 的头 redex 缩出两个度数 3（一个残余一个新生）。
    twice2 = λ(g:(a→a)→(a→a)). λ(x:a→a). g (g x)；argC = λ(k:a→a). k -/
def twice2 : Tm :=
  lam (.arrow (.arrow a a) (.arrow a a))
      (lam (.arrow a a) (app (var 1) (app (var 1) (var 0))))
def argC : Tm := lam (.arrow a a) (var 0)      -- λ(k:a→a). k
def E2 : Tm := app twice2 argC

/- ---------- 乙·实测一：类型与两样本的良构 ---------- -/

example : infer [] idT = some (.arrow (.arrow a a) (.arrow a a)) := by rfl
example : infer [] E1 = some (.arrow a a) := by rfl
example : infer [] E2 = some (.arrow (.arrow a a) (.arrow a a)) := by rfl

/- ---------- 乙·实测二：关键引理的机器面（新 redex 严格变小） ---------- -/

-- E1 唯一 redex 度数 = |(a→a)→(a→a)| = 7
example : redexDegrees E1 = [7] := by rfl

-- 收缩后：新 redex (I ida) 度数 = |a→a| = 3 < 7
example : redexDegrees (stepMax E1).get! = [3] := by rfl

-- E2：收缩度 7 的头 redex 后剩两个度 3（残余 argC x + 新生 argC (argC x)）
example : redexDegrees E2 = [7] := by rfl
example : redexDegrees (stepMax E2).get! = [3, 3] := by rfl

/- ---------- 乙·实测三：度数轨迹与 WN ---------- -/

-- E1 的最大度数轨迹：7 → 3 → 完——严格下降
example : degreeTrace 100 E1 = [7, 3] := by rfl

-- E2：7 → 3 → 3（同轮两刀）→ 完
example : degreeTrace 100 E2 = [7, 3, 3] := by rfl

-- 图灵规范化到范式：E1 → ida（λ(x:a). x），E2 → idT（λ(x:a→a). x）
example : normalizeTuring 100 E1 = ida := by rfl
example : normalizeTuring 100 E2 = idT := by rfl

def normalizeViaFuel : Nat → Tm → Tm
  | 0, t => t
  | n + 1, t => match step t with
    | none => t
    | some t' => normalizeViaFuel n t'

-- 范式判定的交叉验证：normal order 也到同一范式（CR 的实例面）
example : normalizeViaFuel 100 E2 = idT := by rfl

-- 主体归约实例（2C1 在 Church 侧的机器面）：类型沿图灵策略保持
example : infer [] (normalizeTuring 100 E2) = some (.arrow (.arrow a a) (.arrow a a)) := by rfl

#eval degreeTrace 100 E2            -- [7, 3, 3]
#eval normalizeTuring 100 E2 == idT  -- true
