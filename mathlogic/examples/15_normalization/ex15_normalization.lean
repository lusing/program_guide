/- ex15_normalization.lean —— 正规化定理（马明辉 2.3）Lean 镜像
   推导树+wf+cutFmls（含置换段）+chD=(k,n)+red1（∧/→-变换+∨-置换）
   +dnorm+dtrace 降序账+子公式性质。 -/

set_option linter.unusedVariables false

inductive Fform where
  | pvar (n : Nat)
  | fbot
  | fand (a b : Fform)
  | forr (a b : Fform)
  | fimp (a b : Fform)
  deriving DecidableEq

def fneg (a : Fform) : Fform := .fimp a .fbot

def Fform.eqb : Fform → Fform → Bool
  | .pvar m, .pvar n => m == n
  | .fbot, .fbot => true
  | .fand a1 a2, .fand b1 b2 => a1.eqb b1 && a2.eqb b2
  | .forr a1 a2, .forr b1 b2 => a1.eqb b1 && a2.eqb b2
  | .fimp a1 a2, .fimp b1 b2 => a1.eqb b1 && a2.eqb b2
  | _, _ => false

def dcomp : Fform → Nat
  | .pvar _ | .fbot => 0
  | .fand a b | .forr a b | .fimp a b => (max (dcomp a) (dcomp b)) + 1

inductive Der where
  | dHyp (n : Nat) (a : Fform)
  | dAI (d1 d2 : Der)
  | dAEL (a b : Fform) (d : Der)
  | dAER (a b : Fform) (d : Der)
  | dOI1 (a b : Fform) (d : Der)
  | dOI2 (a b : Fform) (d : Der)
  | dOE (a b c : Fform) (d0 d1 d2 : Der)
  | dII (n : Nat) (a b : Fform) (d : Der)
  | dIE (a b : Fform) (d1 d2 : Der)
  | dBotE (c : Fform) (d : Der)
  deriving DecidableEq

def conc : Der → Fform
  | .dHyp _ a => a
  | .dAI d1 d2 => .fand (conc d1) (conc d2)
  | .dAEL a _ _ => a
  | .dAER _ b _ => b
  | .dOI1 a b _ => .forr a b
  | .dOI2 a b _ => .forr a b
  | .dOE _ _ c _ _ _ => c
  | .dII _ a b _ => .fimp a b
  | .dIE _ b _ _ => b
  | .dBotE c _ => c

def wf : Der → Bool
  | .dHyp _ _ => true
  | .dAI d1 d2 => wf d1 && wf d2
  | .dAEL a b d => (conc d).eqb (.fand a b) && wf d
  | .dAER a b d => (conc d).eqb (.fand a b) && wf d
  | .dOI1 a b d => (conc d).eqb a && wf d
  | .dOI2 a b d => (conc d).eqb b && wf d
  | .dOE a b c d0 d1 d2 =>
      (conc d0).eqb (.forr a b) && (conc d1).eqb c && (conc d2).eqb c
        && wf d0 && wf d1 && wf d2
  | .dII _ a b d => (conc d).eqb b && wf d
  | .dIE a b d1 d2 =>
      (conc d1).eqb (.fimp a b) && (conc d2).eqb a && wf d1 && wf d2
  | .dBotE c d => (conc d).eqb .fbot && wf d

/-- 切割公式（含 ∨-置换段） -/
def cutFmls : Der → List Fform
  | .dHyp _ _ => []
  | .dAI d1 d2 => cutFmls d1 ++ cutFmls d2
  | .dAEL _ _ d' =>
      (match d' with
       | .dAI _ _ => [conc d']
       | .dOE _ _ _ _ _ _ => [conc d']
       | _ => []) ++ cutFmls d'
  | .dAER _ _ d' =>
      (match d' with
       | .dAI _ _ => [conc d']
       | .dOE _ _ _ _ _ _ => [conc d']
       | _ => []) ++ cutFmls d'
  | .dOI1 _ _ d' => cutFmls d'
  | .dOI2 _ _ d' => cutFmls d'
  | .dOE _ _ _ d0 d1 d2 => cutFmls d0 ++ cutFmls d1 ++ cutFmls d2
  | .dII _ _ _ d' => cutFmls d'
  | .dIE _ _ d1 d2 =>
      (match d1 with
       | .dII _ _ _ _ => [conc d1]
       | _ => []) ++ cutFmls d1 ++ cutFmls d2
  | .dBotE _ d' => cutFmls d'

/-- 切割高度 ch(D)=(k,n)：k=极大切割公式复杂度，n=其个数 -/
def chD (d : Der) : Nat × Nat :=
  let ks := (cutFmls d).map dcomp
  match ks with
  | [] => (0, 0)
  | k0 :: rest =>
      let kmax := rest.foldl max k0
      (kmax, (ks.filter (fun k => k == kmax)).length)

def dsubst (n : Nat) (r : Der) : Der → Der
  | .dHyp m a => if m == n then r else .dHyp m a
  | .dAI d1 d2 => .dAI (dsubst n r d1) (dsubst n r d2)
  | .dAEL a b d' => .dAEL a b (dsubst n r d')
  | .dAER a b d' => .dAER a b (dsubst n r d')
  | .dOI1 a b d' => .dOI1 a b (dsubst n r d')
  | .dOI2 a b d' => .dOI2 a b (dsubst n r d')
  | .dOE a b c d0 d1 d2 =>
      .dOE a b c (dsubst n r d0) (dsubst n r d1) (dsubst n r d2)
  | .dII m a b d' => .dII m a b (dsubst n r d')
  | .dIE a b d1 d2 => .dIE a b (dsubst n r d1) (dsubst n r d2)
  | .dBotE c d' => .dBotE c (dsubst n r d')

/-- 根部红元：优先引入-消去，否则 ∨-置换 -/
def rootRed : Der → Option Der
  | .dAEL _ _ (.dAI d1 _) => some d1
  | .dAER _ _ (.dAI _ d2) => some d2
  | .dIE _ _ (.dII n _ _ e) d2 => some (dsubst n d2 e)
  | .dAEL a b (.dOE a' b' _ d0 d1 d2) =>
      some (.dOE a' b' a d0 (.dAEL a b d1) (.dAEL a b d2))
  | .dAER a b (.dOE a' b' _ d0 d1 d2) =>
      some (.dOE a' b' b d0 (.dAER a b d1) (.dAER a b d2))
  | _ => none

/-- 一步归约：根红元优先（深层模式在前），否则最左深入 -/
def red1 : Der → Option Der
  | .dAEL _ _ (.dAI d1 _) => some d1
  | .dAER _ _ (.dAI _ d2) => some d2
  | .dIE _ _ (.dII n _ _ e) d2 => some (dsubst n d2 e)
  | .dAEL a b (.dOE a' b' _ d0 d1 d2) =>
      some (.dOE a' b' a d0 (.dAEL a b d1) (.dAEL a b d2))
  | .dAER a b (.dOE a' b' _ d0 d1 d2) =>
      some (.dOE a' b' b d0 (.dAER a b d1) (.dAER a b d2))
  | .dHyp _ _ => none
  | .dAI d1 d2 =>
      match red1 d1 with
      | some d1' => some (.dAI d1' d2)
      | none => (red1 d2).map (fun d2' => .dAI d1 d2')
  | .dAEL a b d' => (red1 d').map (fun e => .dAEL a b e)
  | .dAER a b d' => (red1 d').map (fun e => .dAER a b e)
  | .dOI1 a b d' => (red1 d').map (fun e => .dOI1 a b e)
  | .dOI2 a b d' => (red1 d').map (fun e => .dOI2 a b e)
  | .dOE a b c d0 d1 d2 =>
      match red1 d0 with
      | some e => some (.dOE a b c e d1 d2)
      | none =>
        match red1 d1 with
        | some e => some (.dOE a b c d0 e d2)
        | none => (red1 d2).map (fun e => .dOE a b c d0 d1 e)
  | .dII n a b d' => (red1 d').map (fun e => .dII n a b e)
  | .dIE a b d1 d2 =>
      match red1 d1 with
      | some e => some (.dIE a b e d2)
      | none => (red1 d2).map (fun e => .dIE a b d1 e)
  | .dBotE c d' => (red1 d').map (fun e => .dBotE c e)

def dnorm (fuel : Nat) (d : Der) : Der :=
  match fuel with
  | 0 => d
  | f + 1 => match red1 d with
             | some d' => dnorm f d'
             | none => d

def dtrace (fuel : Nat) (d : Der) : List (Nat × Nat) :=
  match fuel with
  | 0 => []
  | f + 1 => match red1 d with
             | some d' => chD d :: dtrace f d'
             | none => [chD d]

/-- 子公式表（自含） -/
def subF : Fform → List Fform
  | a@(.pvar _) => [a]
  | a@.fbot => [a]
  | a@(.fand x y) | a@(.forr x y) | a@(.fimp x y) => a :: (subF x ++ subF y)

def allFmls : Der → List Fform
  | .dHyp _ a => [a]
  | .dAI d1 d2 => conc d1 :: conc d2 :: (allFmls d1 ++ allFmls d2)
  | .dAEL a b d' => .fand a b :: a :: b :: allFmls d'
  | .dAER a b d' => .fand a b :: a :: b :: allFmls d'
  | .dOI1 a b d' => .forr a b :: a :: allFmls d'
  | .dOI2 a b d' => .forr a b :: b :: allFmls d'
  | .dOE a b c d0 d1 d2 =>
      .forr a b :: c :: (allFmls d0 ++ allFmls d1 ++ allFmls d2)
  | .dII _ a b d' => .fimp a b :: b :: allFmls d'
  | .dIE a b d1 d2 => .fimp a b :: a :: (allFmls d1 ++ allFmls d2)
  | .dBotE c d' => c :: allFmls d'

/- ---------- 账例 ---------- -/

def p0 : Fform := .pvar 0
def p1 : Fform := .pvar 1

/-- 例 2.4(1)：α,β ⊢ α∧β 后接 ∧E -/
def exDetour : Der :=
  .dAER p0 p1 (.dAI (.dHyp 0 p0) (.dHyp 1 p1))

example : wf exDetour = true := by native_decide
example : chD exDetour = (1, 1) := by native_decide
example : dtrace 5 exDetour = [(1, 1), (0, 0)] := by native_decide
example : dnorm 5 exDetour = .dHyp 1 p1 := by native_decide

/-- β-赘步：⊢p→p 的绕路证明 -/
def exBeta : Der :=
  .dIE p0 p0 (.dII 0 p0 p0 (.dHyp 0 p0)) (.dHyp 1 p0)

example : wf exBeta = true := by native_decide
example : dtrace 5 exBeta = [(1, 1), (0, 0)] := by native_decide
example : dnorm 5 exBeta = .dHyp 1 p0 := by native_decide

/-- 复杂度 2 级联：β 先造出低一级 ∧-赘步再收掉 -/
def exCascade : Der :=
  .dIE (.fand p0 p1) p0
    (.dII 1 (.fand p0 p1) p0 (.dAEL p0 p1 (.dHyp 1 (.fand p0 p1))))
    (.dAI (.dHyp 2 p0) (.dHyp 3 p1))

example : wf exCascade = true := by native_decide
example : dtrace 5 exCascade = [(2, 1), (1, 1), (0, 0)] := by native_decide

/-- ∨-置换：∨E 的结论立即被 ∧E -/
def exPerm : Der :=
  .dAEL p0 p1
    (.dOE p0 (.fand p0 p1) (.fand p0 p1)
      (.dHyp 9 (.forr p0 (.fand p0 p1)))
      (.dAI (.dHyp 1 p0) (.dHyp 2 p1))
      (.dHyp 3 (.fand p0 p1)))

example : wf exPerm = true := by native_decide
example : dtrace 5 exPerm = [(1, 1), (1, 1), (0, 0)] := by native_decide
example : dnorm 5 exPerm =
  .dOE p0 (.fand p0 p1) p0
    (.dHyp 9 (.forr p0 (.fand p0 p1)))
    (.dHyp 1 p0)
    (.dAEL p0 p1 (.dHyp 3 (.fand p0 p1))) := by native_decide
example : chD (dnorm 5 exPerm) = (0, 0) := by native_decide

/-- 子公式性质：正规终态的全部公式 ⊆ SF(前提,结论) -/
def cascadeCtx : List Fform :=
  subF p0 ++ subF p1 ++ subF (.fimp (.fand p0 p1) p0)

example : (allFmls (dnorm 5 exCascade)).all
    (fun a => cascadeCtx.any (fun c => a.eqb c)) = true := by native_decide

example : (allFmls (dnorm 5 exPerm)).all
    (fun a => (subF (.forr p0 (.fand p0 p1)) ++ subF p0 ++ subF p1).any
      (fun c => a.eqb c)) = true := by native_decide
