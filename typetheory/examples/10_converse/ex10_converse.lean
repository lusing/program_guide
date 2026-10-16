/- ============================================================
   10 逆主类型与凝结分离 —— Lean 对照（Hindley ch.7 甲乙两侧）
   甲·7C1 Meyer 构造：I_σ 递归（σ 骨架类型 → PT = σ→σ 的封闭 λI 项）
   乙·7A2.1：βη-相等却【类型集不相交】的双胞胎（I_{a→a} vs I_{a→a→a}）
   丙·双机互证样本：principal (B B) 与 Prolog cd(B,B) 对表；
      PT 不是 β-不变量的活样本（SK vs λyz.z）
   Prolog 主场（cd 原语/D-定理）在 ex10_cd.pl。
   ============================================================ -

β 机器（Term/shift/subst/step/η 两阶段）复制自 03 章；
PT 机器（Ty/unify/solve/principal）复制自 05 章；matchInst 复制自 06 章。 -/

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

def step : Term → Option Term
  | app (lam b) a => some (shift (-1) 0 (subst 0 (shift 1 0 a) b))
  | app f a =>
      match step f with
      | some f' => some (app f' a)
      | none => (step a).map (fun a' => app f a')
  | lam b => (step b).map lam
  | var _ => none

def nfBeta : Nat → Term → Term
  | 0, t => t
  | n + 1, t => match step t with
    | none => t
    | some t' => nfBeta n t'

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

def nfEta : Nat → Term → Term
  | 0, t => t
  | n + 1, t => match etaStep t with
    | none => t
    | some t' => nfEta n t'

def nfBetaEta (fuel : Nat) (t : Term) : Term := nfEta fuel (nfBeta fuel t)

def isLI : Term → Bool
  | var _ => true
  | lam b => occurs 0 b && isLI b
  | app f a => isLI f && isLI a

end Term

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

def principal (t : Term) : Option Ty :=
  match gen 0 [] t with
  | none => none
  | some (_, ty, cs) =>
      match solve 400 cs with
      | none => none
      | some s => some (applyS s ty)

/-- t 是 pt 的替换实例吗（06 章同款单侧匹配） -/
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
  | _ + 1, _, _ => none

open Term Ty

def I : Term := lam (var 0)
def Bc : Term := lam (lam (lam (app (var 2) (app (var 1) (var 0)))))
def S : Term :=
  lam (lam (lam (app (app (var 2) (var 0)) (app (var 1) (var 0)))))
def Kc : Term := lam (lam (var 1))

/-! ## 甲·7C1：Meyer 的 I_σ 构造

    对骨架类型 σ 递归造封闭 λI 项 I_σ，使 PT(I_σ) = σ→σ 且
    I_σ →βη* I：
    · I_a = I
    · I_{ρ→σ} = λx y. I_σ (x (I_ρ y))        -/

def iS : Ty → Term
  | .tvar _ => I
  | .arrow ρ σ => lam (lam (app (iS σ) (app (var 1) (app (iS ρ) (var 0)))))

def a1 : Ty := .tvar 0
def a2 : Ty := .arrow (.tvar 0) (.tvar 1)
def a3 : Ty := .arrow (.tvar 0) (.arrow (.tvar 0) (.tvar 1))

/- ---------- 实测一：PT(I_σ) = σ→σ ---------- -/

example : principal (iS a1) = some (.arrow (.tvar 0) (.tvar 0)) := by rfl

example : principal (iS a2)
        = some (.arrow (.arrow (.tvar 4) (.tvar 6))
                      (.arrow (.tvar 4) (.tvar 6))) := by rfl

example : principal (iS a3)
        = some (.arrow (.arrow (.tvar 10) (.arrow (.tvar 6) (.tvar 8)))
                      (.arrow (.tvar 10) (.arrow (.tvar 6) (.tvar 8)))) := by rfl

/- ---------- 实测二：I_σ 全部 βη-坍缩到 I（7A2/7A3 的 (iii)） ---------- -/

example : nfBetaEta 50 (iS a1) = I := by rfl
example : nfBetaEta 50 (iS a2) = I := by rfl
example : nfBetaEta 50 (iS a3) = I := by rfl

-- 它们都是 λI-项（7C 的世界在 λI 里）
example : isLI (iS a2) = true ∧ isLI (iS a3) = true := ⟨by rfl, by rfl⟩

/- ---------- 实测三：7A2.1 双胞胎——βη 相等，类型集不相交 ---------- -/

def P1 : Term := iS (.arrow (.tvar 0) (.tvar 0))          -- PT = (a→a)→(a→a)
def P2 : Term := iS (.arrow (.tvar 0) (.arrow (.tvar 0) (.tvar 1)))
                                                          -- PT = (a→a→a)→(a→a→a)

-- βη-相等：都坍缩到 I（所以 P1 =βη I =βη P2）
example : nfBetaEta 50 P1 = I ∧ nfBetaEta 50 P2 = I := ⟨by rfl, by rfl⟩

-- 但主类型互不为实例（occurs check 第三次显灵：a→a→a 对 a→a 的
-- 匹配死在「v 出现在自己的实例里」——两个类型集【不相交】）
example : matchInst 20 (.arrow (.arrow (.tvar 0) (.arrow (.tvar 0) (.tvar 1)))
                               (.arrow (.tvar 0) (.arrow (.tvar 0) (.tvar 1))))
                     (.arrow (.arrow (.tvar 0) (.tvar 0))
                               (.arrow (.tvar 0) (.tvar 0)))
        = none := by rfl
example : matchInst 20 (.arrow (.arrow (.tvar 0) (.tvar 0))
                               (.arrow (.tvar 0) (.tvar 0)))
                     (.arrow (.arrow (.tvar 0) (.arrow (.tvar 0) (.tvar 1)))
                               (.arrow (.tvar 0) (.arrow (.tvar 0) (.tvar 1))))
        = none := by rfl

/- ---------- 实测四：双机互证 + PT 不是 β-不变量 ---------- -/

-- principal (B B)：与 Prolog cd(B,B) 的输出对表（同一 α-类：
-- (x→y→z)→(x→(w→y)→(w→z))，机器字面按发号器口径）
example : principal (app Bc Bc)
        = some (.arrow (.arrow (.tvar 2) (.arrow (.tvar 8) (.tvar 9)))
                      (.arrow (.tvar 2)
                        (.arrow (.arrow (.tvar 7) (.tvar 8))
                          (.arrow (.tvar 7) (.tvar 9))))) := by rfl

example : principal (app S Kc)
        = some (.arrow (.arrow (.tvar 5) (.tvar 4))
                      (.arrow (.tvar 5) (.tvar 5))) := by rfl
example : nfBetaEta 50 (app S Kc) = lam (lam (var 0)) := by rfl

-- PT 非 β-不变量：SK =β λy z. z，但两者的主类型不同——
-- (a→b)→(a→a) 是 a→b→b 的真实例（06 章 Eq-规则动机的又一化身）
#eval principal (lam (lam (var 0)))        -- a→b→b：更一般
