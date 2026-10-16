/- ============================================================
   06 等式规则与语义 —— Lean：TA_λ+β[η] 的语构面（Hindley ch.4A）
   Eq 规则把「类型集合」变成转换不变量的代价与红利：
     · eqTypable? M = PT(M 的 β[η]-范式)   ——4A7 主类型定理的机器版
     · 有范式是 TA+β 可指派的必要条件        ——4A3
     · 主体扩张翻案：(λz.I)Ω 在 TA 不可指派、在 TA+β 可指派
   语义面（λ-模型/项模型/完备性）在 ex06_eqsem.pl 的有限结构实验室。
   ============================================================ -

β 机器（Term/shift/subst/step/nfBeta/nfBetaEta）复制自 03 章；
PT 机器（Ty/unify/solve/principal）复制自 05 章——两台机器在此合流。
-/

inductive Term where
  | var : Nat → Term
  | lam : Term → Term
  | app : Term → Term → Term
deriving Repr, BEq

namespace Term

def shift (d : Int) (c : Nat) : Term → Term
  | var k => if c ≤ k then var (Int.toNat (Int.ofNat k + d)) else var k
  | lam b => lam (shift d (c + 1) b)
  | app f a => app (shift d c f) (shift d c a)

def subst (j : Nat) (s : Term) : Term → Term
  | var k => if k = j then s else var k
  | lam b => lam (subst (j + 1) (shift 1 0 s) b)
  | app f a => app (subst j s f) (subst j s a)

/-- β 单步（最左最外） -/
def step : Term → Option Term
  | app (lam b) a => some (shift (-1) 0 (subst 0 (shift 1 0 a) b))
  | app f a =>
      match step f with
      | some f' => some (app f' a)
      | none => (step a).map (fun a' => app f a')
  | lam b => (step b).map lam
  | var _ => none

/-- β 规范化（带燃料；normal order：若有范式必达） -/
def nfBeta : Nat → Term → Term
  | 0, t => t
  | n + 1, t => match step t with
    | none => t
    | some t' => nfBeta n t'

/-- η 单步（occurs 检查 + 出绑定器降 1，见 03 章） -/
def occurs (k : Nat) : Term → Bool
  | var j => decide (j = k)
  | lam b => occurs (k + 1) b
  | app f a => occurs k f || occurs k a

def etaStep : Term → Option Term
  | lam (app t (var 0)) =>
      if occurs 0 t then (etaStep (app t (var 0))).map lam
      else some (shift (-1) 0 t)
  | lam b => (etaStep b).map lam
  | app f a =>
      match etaStep f with
      | some f' => some (app f' a)
      | none => (etaStep a).map (fun a' => app f a')
  | var _ => none

/-- βη 两阶段规范化（03 章 1C9.5 的策略） -/
def nfEta : Nat → Term → Term
  | 0, t => t
  | n + 1, t => match etaStep t with
    | none => t
    | some t' => nfEta n t'

def nfBetaEta (fuel : Nat) (t : Term) : Term := nfEta fuel (nfBeta fuel t)

end Term

/- ---------- PT 机器（复制自 05 章，gen 改吃 Term） ---------- -/

inductive Ty where
  | tvar : Nat → Ty
  | arrow : Ty → Ty → Ty
deriving Repr, BEq

abbrev Subst := Nat → Ty

def applyS (s : Subst) : Ty → Ty
  | .tvar n => s n
  | .arrow a b => .arrow (applyS s a) (applyS s b)

def comp (σ τ : Subst) : Subst := fun n => applyS σ (τ n)

def single (n : Nat) (t : Ty) : Subst := fun k =>
  if k = n then t else .tvar k

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

/-- 约束生成：绑定器发新鲜类型变元（05 章同款，项换成 Term） -/
def gen (next : Nat) (ctx : List Ty) : Term → Option (Nat × Ty × List (Ty × Ty))
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

/-- 主类型算法 PT（TA_λ 版，无 Eq） -/
def principal (t : Term) : Option Ty :=
  match gen 0 [] t with
  | none => none
  | some (_, ty, cs) =>
      match solve 400 cs with
      | none => none
      | some s => some (applyS s ty)

open Term

/- ---------- Eq 层：TA_λ+β[η] = 给范式配型（4A7） ---------- /

   4A7（TA+β[η] 的 PT 定理）：M 在 TA_λ+β[η] 里的主类型
   = M 的 β[η]-范式在 TA_λ 里的主类型。
   于是「带 Eq 的可指派」机器化为：先把范式求出来，再跑 PT。
   注意 4A3 的必要条件：M 必须有 β[η]-范式——Ω 连 Eq 也救不了。 -/

/-- TA_λ+β 的（主类型版）可指派判定：PT(M*β) -/
def eqTypable? (fuel : Nat) (t : Term) : Option Ty := principal (nfBeta fuel t)

/-- TA_λ+βη 的（主类型版）可指派判定：PT(M*βη) -/
def eqTypableEta? (fuel : Nat) (t : Term) : Option Ty := principal (nfBetaEta fuel t)

/-- t 是 pt 的替换实例吗（单侧匹配：只有 pt 的变元可绑） -/
def matchInst : Nat → Ty → Ty → Option Subst
  | 0, _, _ => none
  | _ + 1, .tvar n, .tvar m => if n = m then some (fun k => .tvar k) else none
  | _ + 1, t, .tvar n =>
      if occursTy n t then none else some (single n t)
  | fuel + 1, .arrow a1 b1, .arrow a2 b2 =>
      match matchInst fuel a1 a2 with
      | none => none
      | some s1 =>
          match matchInst fuel (applyS s1 b1) (applyS s1 b2) with
          | none => none
          | some s2 => some (comp s2 s1)
  | _ + 1, _, _ => none              -- tvar 对箭头：t 实例不出 pt 的骨架

open Term Ty

/- ---------- 名角 ---------- -/

def I : Term := lam (var 0)
def omega : Term := lam (app (var 0) (var 0))
def Omega : Term := app omega omega

/-- 主体扩张的反例主角：P = (λz. I) Ω ——无类型地「包着」一个发散项 -/
def P : Term := app (lam I) Omega
  -- λz 体是 I（闭项，shift 不动），实参 Ω（03 章 4A1.2 的现代版样本）

/- ---------- 实测一：Eq 的翻案现场（4A1.2 / 4A5） ---------- -/

-- TA_λ：P 不可指派（Ω 的约束让 occurs check 拒绝——05 章死法同款）
example : principal P = none := by rfl

-- TA_λ+β：P 可指派，主类型 = PT(I) = t0 → t0（4A7：先缩范式再配型）
example : eqTypable? 50 P = some (arrow (tvar 0) (tvar 0)) := by rfl

-- 4A5 的读法：Types_β(P) = Types(I) = {σ→σ}——全是主类型的实例
example : (matchInst 20 (arrow (arrow (tvar 1) (tvar 1)) (arrow (tvar 1) (tvar 1)))
                      (arrow (tvar 0) (tvar 0))).isSome = true := by rfl
example : matchInst 20 (arrow (tvar 1) (tvar 2)) (arrow (tvar 0) (tvar 0))
        = none := by rfl

/- ---------- 实测二：4A3 的必要条件——有范式 ---------- -/

-- Ω 无 β-范式：TA+β 也救不了（Eq 传送类型的前提是范式存在）
example : eqTypable? 50 Omega = none := by rfl

-- K Ω 同因：范式 λy.Ω 里的 Ω 永远缩不完，配型仍被 occurs check 拒
def K : Term := lam (lam (var 1))
example : eqTypable? 50 (app K Omega) = none := by rfl

/- ---------- 实测三：βη 版——Eq 的语义完整版（4A9/4B4(ii)） ---------- -/

/-- M = λg. (λx. g x)：β-范式是自身，η 再缩一步得 λg. g -/
def M : Term := lam (lam (app (var 1) (var 0)))

-- TA_λ 主类型：(t1→t2) → (t1→t2)——「g 必须是函数」的过度约束
example : principal M
        = some (arrow (arrow (tvar 1) (tvar 2)) (arrow (tvar 1) (tvar 2)))
        := by rfl

-- TA_λ+βη 主类型：PT(λg. g) = t0 → t0——更一般（Eq 把 η-相等折进类型集）
example : eqTypableEta? 50 M = some (arrow (tvar 0) (tvar 0)) := by rfl

-- 对照：(t1→t2)→(t1→t2) 是 t0→t0 的实例，反向不成立——
-- TA+βη 的类型集严格更大（4A5：Types_βη(M) = Types(M*βη)）
example : (matchInst 20 (arrow (arrow (tvar 1) (tvar 2)) (arrow (tvar 1) (tvar 2)))
                      (arrow (tvar 0) (tvar 0))).isSome = true := by rfl

#eval eqTypable? 50 P        -- some (t0 → t0)
#eval principal P            -- none
