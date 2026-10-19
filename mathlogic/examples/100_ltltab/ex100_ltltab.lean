/- ex36 —— LTL 语义表列（Ben-Ari 3e §13.5）Lean 版
   □A（α：当前 A+next □A）、◇A（β：A ∨ X◇A）、X 收集；状态节点 =
   文字+X；X-步迭代成 lasso（前缀+环 = 无穷路径的有限证书）。
   本通道承载**算法层**完整镜像：饱和（α 优先的系统纪律）+ lasso
   （集合语义的重现检测）+ 兑现检查 + 两现场例。兑现检查的健全性
   定理（fulfill_ok_sound）在 Coq 通道完整机器化——通道分工见 docs/36。 -/

inductive Lform : Type
  | atom (p : Nat)
  | not (a : Lform)
  | and (a b : Lform)
  | or (a b : Lform)
  | imp (a b : Lform)
  | next (a : Lform)   -- X A
  | box (a : Lform)    -- □ A
  | dia (a : Lform)    -- ◇ A
  deriving Repr

open Lform

-- NNF：否定推到原子（时态对偶 ¬X=X¬、¬□=◇¬、¬◇=□¬）
mutual
def nnf (f : Lform) : Lform :=
  match f with
  | .atom _ => f
  | .not g => nnfNeg g
  | .and a b => .and (nnf a) (nnf b)
  | .or a b => .or (nnf a) (nnf b)
  | .imp a b => .or (nnfNeg a) (nnf b)
  | .next a => .next (nnf a)
  | .box a => .box (nnf a)
  | .dia a => .dia (nnf a)

def nnfNeg (f : Lform) : Lform :=
  match f with
  | .atom _ => .not f
  | .not g => nnf g
  | .and a b => .or (nnfNeg a) (nnfNeg b)
  | .or a b => .and (nnfNeg a) (nnfNeg b)
  | .imp a b => .and (nnf a) (nnfNeg b)
  | .next a => .next (nnfNeg a)
  | .box a => .dia (nnfNeg a)
  | .dia a => .box (nnfNeg a)
end

def eqf : Lform → Lform → Bool
  | .atom a, .atom b => a == b
  | .not a, .not b => eqf a b
  | .and a1 b1, .and a2 b2 => eqf a1 a2 && eqf b1 b2
  | .or a1 b1, .or a2 b2 => eqf a1 a2 && eqf b1 b2
  | .imp a1 b1, .imp a2 b2 => eqf a1 a2 && eqf b1 b2
  | .next a, .next b => eqf a b
  | .box a, .box b => eqf a b
  | .dia a, .dia b => eqf a b
  | _, _ => false

def memL (Γ : List Lform) (f : Lform) : Bool :=
  Γ.any (fun g => eqf g f)

def isLit : Lform → Bool
  | .atom _ => true
  | .not (.atom _) => true
  | _ => false

-- 系统性纪律：α（∧/□）优先于 β（∨/→/◇）
def extractA : List Lform → Option (Lform × List Lform)
  | [] => none
  | f :: Γ' =>
      match f with
      | .and _ _ | .box _ => some (f, Γ')
      | _ => (extractA Γ').map (fun (g, rest) => (g, f :: rest))

def extractB : List Lform → Option (Lform × List Lform)
  | [] => none
  | f :: Γ' =>
      match f with
      | .or _ _ | .imp _ _ | .dia _ => some (f, Γ')
      | _ => (extractB Γ').map (fun (g, rest) => (g, f :: rest))

def extractN (Γ : List Lform) : Option (Lform × List Lform) :=
  match extractA Γ with
  | some r => some r
  | none => extractB Γ

def compPair (Γ : List Lform) : Bool :=
  Γ.any (fun f => match f with
                  | .atom p => memL Γ (.not (.atom p))
                  | _ => false)

-- X 去壳：只取 X 的体；文字不带走
def unX : List Lform → List Lform
  | [] => []
  | .next a :: Γ' => a :: unX Γ'
  | _ :: Γ' => unX Γ'

def orelseL {A : Type} (o1 o2 : Option A) : Option A :=
  match o1 with | some x => some x | none => o2

def saturate : Nat → List Lform → List Lform → Option (List Lform × List Lform)
  | 0, _, _ => none
  | k + 1, Γ, nxt =>
      if compPair Γ then none
      else match extractN Γ with
        | some (.and a b, Γ') => saturate k (a :: b :: Γ') nxt
        | some (.box a, Γ') => saturate k (a :: Γ') (.box a :: nxt)
        | some (.or a b, Γ') =>
            orelseL (saturate k (a :: Γ') nxt) (saturate k (b :: Γ') nxt)
        | some (.imp a b, Γ') =>
            orelseL (saturate k (.not a :: Γ') nxt) (saturate k (b :: Γ') nxt)
        | some (.dia a, Γ') =>
            orelseL (saturate k (a :: Γ') nxt) (saturate k Γ' (.dia a :: nxt))
        | some (_, _) => none
        | none => some (Γ, unX Γ ++ nxt)

-- 重现检查用集合语义：多重集会因 □◇ 的反复展开累积重复副本
def setEqL (Γ Δ : List Lform) : Bool :=
  Δ.all (fun f => memL Γ f) && Γ.all (fun f => memL Δ f)

def posOfL (cur : List Lform) : List (List Lform) → Nat
  | [] => 0
  | s :: seen' => if setEqL s cur then 0 else posOfL cur seen' + 1

def lasso : Nat → List (List Lform) → List Lform → Option (List (List Lform) × Nat)
  | 0, _, _ => none
  | k + 1, seen, cur =>
      if seen.any (fun s => setEqL s cur) then
        some ((cur :: seen).reverse, posOfL cur seen.reverse)
      else
        match saturate 64 cur [] with
        | some (_, []) => some ((cur :: seen).reverse, seen.length)
        | some (_, nxt) => lasso k (cur :: seen) nxt
        | none => none

/- ============ 兑现检查（Def 13.49 的 lasso 版） ============ -/

def scanAny : List (List Lform) → Lform → Bool
  | [], _ => false
  | s :: l', a => memL s a || scanAny l' a

def witnessIn (full : List (List Lform)) (c i : Nat) (a : Lform) : Bool :=
  scanAny (full.drop (min i c)) a

def checkAll (full : List (List Lform)) : List (List Lform) → Nat → Nat → Bool
  | [], _, _ => true
  | s :: tail', c, base =>
      s.all (fun f => match f with
                      | .dia a => witnessIn full c base a
                      | _ => true)
      && checkAll full tail' c (base + 1)

def fulfill_ok (st : List (List Lform)) (c : Nat) : Bool :=
  checkAll st st c 0

/- ============ 现场例 ============ -/

def exUnsat : Lform := .and (.box (.not (.atom 0))) (.box (.dia (.atom 0)))
def exFG : Lform := .dia (.box (.atom 0))

-- 现场一：◇□p 的 lasso——三态一环（环起点 1），兑现通过
example :
    (match lasso 30 [] [nnf exFG] with
     | some (st, c) => (st, c, fulfill_ok st c)
     | none => ([], 0, false)) =
      ([[.dia (.box (.atom 0))], [.box (.atom 0)], [.box (.atom 0)]], 1, true) := by
  rfl

-- 现场二：□¬p ∧ □◇p —— ◇p 永远推迟，兑现失败 ⟹ 不可满足
example :
    (match lasso 30 [] [nnf exUnsat] with
     | some (st, c) => (c, fulfill_ok st c)
     | none => (0, true)) = (1, false) := by
  rfl
