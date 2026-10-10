/- ex34_ge —— 广义消去规则与高层次规则（Lean 4 版）
   与 ex34_ge.v 同构：三套消去系统（MP / GEN+ESL / HL）并存于一个推导
   AST；typeOf 类型演算、六个翻译函数、类型驱动的 β 收缩（坐标由
   typeOf 喂入、下穿引入规则时语境扩张）、正规化与和谐账本电池。 -/

namespace Ex34

inductive Form where
  | atom (n : Nat)
  | fand (a b : Form)
  | fimp (a b : Form)
  deriving Repr

/-- 语境条目：公式假设，或**规则假设** a ⇒ b（高层次演算核心）。 -/
inductive Entry where
  | EF (a : Form)
  | ER (a b : Form)

def eqF : Form → Form → Bool
  | .atom n, .atom m => n == m
  | .fand x1 x2, .fand y1 y2 => eqF x1 y1 && eqF x2 y2
  | .fimp x1 x2, .fimp y1 y2 => eqF x1 y1 && eqF x2 y2
  | _, _ => false

def inCtx : Entry → List Entry → Bool
  | _, [] => false
  | e, x :: t =>
      (match e, x with
       | .EF a, .EF b => eqF a b
       | .ER a1 b1, .ER a2 b2 => eqF a1 a2 && eqF b1 b2
       | _, _ => false) || inCtx e t

/-- dRule x y d1：应用语境中的规则假设 (x ⇒ y) 于 d1 : x，得 y。 -/
inductive Der where
  | dHyp (a : Form)
  | dRule (x y : Form) (d1 : Der)
  | dAndI (d1 d2 : Der)
  | dImpI (x : Form) (d : Der)
  | dAndE1 (d : Der)
  | dAndE2 (d : Der)
  | dMP (d1 d2 : Der)
  | dAndGEN (d0 d : Der)
  | dImpSL (d0 d1 d : Der)
  | dImpHL (d0 d : Der)

/-- 类型演算：良型则恰一个类型。 -/
def typeOf (G : List Entry) : Der → Option Form
  | .dHyp a => if inCtx (.EF a) G then some a else none
  | .dRule x y d1 =>
      if inCtx (.ER x y) G
          && (match typeOf G d1 with
              | some z => eqF z x
              | none => false)
      then some y else none
  | .dAndI d1 d2 => do
      let x ← typeOf G d1
      let y ← typeOf G d2
      return .fand x y
  | .dImpI x d => do
      let y ← typeOf (.EF x :: G) d
      return .fimp x y
  | .dAndE1 d => match typeOf G d with
                 | some (.fand x _) => some x
                 | _ => none
  | .dAndE2 d => match typeOf G d with
                 | some (.fand _ y) => some y
                 | _ => none
  | .dMP d1 d2 =>
      match typeOf G d1, typeOf G d2 with
      | some (.fimp x y), some x' => if eqF x x' then some y else none
      | _, _ => none
  | .dAndGEN d0 d =>
      match typeOf G d0 with
      | some (.fand x y) => typeOf (.EF x :: .EF y :: G) d
      | _ => none
  | .dImpSL d0 d1 d =>
      match typeOf G d0, typeOf G d1 with
      | some (.fimp x y), some x' =>
          if eqF x x' then typeOf (.EF y :: G) d else none
      | _, _ => none
  | .dImpHL d0 d =>
      match typeOf G d0 with
      | some (.fimp x y) => typeOf (.ER x y :: G) d
      | _ => none

def wtdOK (G : List Entry) (d : Der) (c : Form) : Bool :=
  match typeOf G d with
  | some x => eqF x c
  | none => false

/-- substF a E d：公式假设 a 的出现全换成 E。 -/
def substF (a : Form) (E : Der) : Der → Der
  | .dHyp b => if eqF a b then E else .dHyp b
  | .dRule x y d1 => .dRule x y (substF a E d1)
  | .dAndI d1 d2 => .dAndI (substF a E d1) (substF a E d2)
  | .dImpI x d1 => .dImpI x (substF a E d1)
  | .dAndE1 d1 => .dAndE1 (substF a E d1)
  | .dAndE2 d1 => .dAndE2 (substF a E d1)
  | .dMP d1 d2 => .dMP (substF a E d1) (substF a E d2)
  | .dAndGEN d0 d1 => .dAndGEN (substF a E d0) (substF a E d1)
  | .dImpSL d0 d1 d2 =>
      .dImpSL (substF a E d0) (substF a E d1) (substF a E d2)
  | .dImpHL d0 d1 => .dImpHL (substF a E d0) (substF a E d1)

/-- substR x y D1 d：规则假设 (x⇒y) 的应用点全换成 C:=y 的平凡 →ESL
    （书 p.25 构造 (3)）。 -/
def substR (x y : Form) (D1 : Der) : Der → Der
  | .dHyp b => .dHyp b
  | .dRule u v d1 =>
      if eqF x u && eqF y v
      then .dImpSL D1 (substR x y D1 d1) (.dHyp y)
      else .dRule u v (substR x y D1 d1)
  | .dAndI d1 d2 => .dAndI (substR x y D1 d1) (substR x y D1 d2)
  | .dImpI u d1 => .dImpI u (substR x y D1 d1)
  | .dAndE1 d1 => .dAndE1 (substR x y D1 d1)
  | .dAndE2 d1 => .dAndE2 (substR x y D1 d1)
  | .dMP d1 d2 => .dMP (substR x y D1 d1) (substR x y D1 d2)
  | .dAndGEN d0 d1 => .dAndGEN (substR x y D1 d0) (substR x y D1 d1)
  | .dImpSL d0 d1 d2 =>
      .dImpSL (substR x y D1 d0) (substR x y D1 d1) (substR x y D1 d2)
  | .dImpHL d0 d1 => .dImpHL (substR x y D1 d0) (substR x y D1 d1)

/- ---------- 六个翻译 ---------- -/

/-- (i) ESL 的恒等副前提就是 MP。 -/
def mpFromEsl (_x y : Form) (D1 D2 : Der) : Der :=
  .dImpSL D1 D2 (.dHyp y)

/-- (ii) MP 的替换论证：副前提里的 y 假设全换成 MP(D1,D2)。 -/
def mpDerivesEsl (y : Form) (D1 D2 d : Der) : Der :=
  substF y (.dMP D1 D2) d

/-- (iii) ESL 化 HL：y 假设换成规则应用点。 -/
def hlFromEsl (x y : Form) (D1 D2 d : Der) : Der :=
  .dImpHL D1 (substF y (.dRule x y D2) d)

/-- (iv) HL 化 ESL：规则应用点全换成 C:=y 的平凡 ESL。 -/
def eslFromHl (x y : Form) (D1 d : Der) : Der :=
  substR x y D1 d

/-- (v)(vi) ∧E ↔ ∧EGEN。 -/
def andFromGenL (x _y : Form) (D0 : Der) : Der := .dAndGEN D0 (.dHyp x)
def andFromGenR (_x y : Form) (D0 : Der) : Der := .dAndGEN D0 (.dHyp y)
def genFromAnd (x y : Form) (D0 d : Der) : Der :=
  .dAndGEN D0 (substF x (.dAndE1 D0) (substF y (.dAndE2 D0) d))

/- ---------- 类型驱动的 β 收缩 ---------- -/

def derEqb : Der → Der → Bool
  | .dHyp a, .dHyp b => eqF a b
  | .dRule x1 y1 d1, .dRule x2 y2 e1 => eqF x1 x2 && eqF y1 y2 && derEqb d1 e1
  | .dAndI a1 b1, .dAndI a2 b2 => derEqb a1 a2 && derEqb b1 b2
  | .dImpI x1 d1, .dImpI x2 e1 => eqF x1 x2 && derEqb d1 e1
  | .dAndE1 d1, .dAndE1 e1 => derEqb d1 e1
  | .dAndE2 d1, .dAndE2 e1 => derEqb d1 e1
  | .dMP a1 b1, .dMP a2 b2 => derEqb a1 a2 && derEqb b1 b2
  | .dAndGEN a1 b1, .dAndGEN a2 b2 => derEqb a1 a2 && derEqb b1 b2
  | .dImpSL a1 b1 c1, .dImpSL a2 b2 c2 =>
      derEqb a1 a2 && derEqb b1 b2 && derEqb c1 c2
  | .dImpHL a1 b1, .dImpHL a2 b2 => derEqb a1 a2 && derEqb b1 b2
  | _, _ => false

def ty1 (G : List Entry) (d : Der) (fb : Form) : Form :=
  match typeOf G d with
  | some z => z
  | none => fb

/-- beta1 G d：顶红ex收缩；下穿引入规则时语境扩张（坐标正确性命脉）。 -/
def beta1 (G : List Entry) : Der → Der
  | .dMP d1 d2 =>
      match d1 with
      | .dImpI x db => substF x d2 db
      | _ => .dMP (beta1 G d1) (beta1 G d2)
  | .dAndE1 d =>
      match d with
      | .dAndI d1 _ => d1
      | _ => .dAndE1 (beta1 G d)
  | .dAndE2 d =>
      match d with
      | .dAndI _ d2 => d2
      | _ => .dAndE2 (beta1 G d)
  | .dAndGEN d0 d =>
      match d0 with
      | .dAndI d1 d2 =>
          substF (ty1 G d1 (.atom 0)) d1 (substF (ty1 G d2 (.atom 1)) d2 d)
      | _ =>
          match typeOf G d0 with
          | some (.fand x y) => .dAndGEN (beta1 G d0) (beta1 (.EF x :: .EF y :: G) d)
          | _ => .dAndGEN (beta1 G d0) (beta1 G d)
  | .dImpSL d0 d1 d =>
      match d0 with
      | .dImpI x db =>
          substF (ty1 (.EF x :: G) db (.atom 1)) (substF x d1 db) d
      | _ =>
          match typeOf G d0 with
          | some (.fimp _x y) =>
              .dImpSL (beta1 G d0) (beta1 G d1) (beta1 (.EF y :: G) d)
          | _ => .dImpSL (beta1 G d0) (beta1 G d1) (beta1 G d)
  | .dImpHL d0 d =>
      match d0 with
      | .dImpI x db =>
          let y := ty1 (.EF x :: G) db (.atom 1)
          substR x y (.dImpI x db) d
      | _ =>
          match typeOf G d0 with
          | some (.fimp x y) => .dImpHL (beta1 G d0) (beta1 (.ER x y :: G) d)
          | _ => .dImpHL (beta1 G d0) (beta1 G d)
  | .dImpI x d1 => .dImpI x (beta1 (.EF x :: G) d1)
  | .dRule x y d1 => .dRule x y (beta1 G d1)
  | .dAndI d1 d2 => .dAndI (beta1 G d1) (beta1 G d2)
  | .dHyp a => .dHyp a

def normalize : Nat → Der → Der
  | 0, d => d
  | n + 1, d =>
      let d' := beta1 [] d
      if derEqb d d' then d' else normalize n d'

/- ---------- 断言电池 ---------- -/

def p : Form := .atom 0
def q : Form := .atom 1
def imp_pq : Form := .fimp p q

def G0 : List Entry := [.EF imp_pq, .ER p q, .EF p, .EF q]

/-- 电一：三系统同一判断 p→q, p ⊢ q。 -/
def mpD : Der := .dMP (.dHyp imp_pq) (.dHyp p)
def eslD : Der := .dImpSL (.dHyp imp_pq) (.dHyp p) (.dHyp q)
def hlD : Der := .dImpHL (.dHyp imp_pq) (.dRule p q (.dHyp p))

example : wtdOK G0 mpD q && (wtdOK G0 eslD q && wtdOK G0 hlD q) = true := by
  decide

/-- 电二：(iv)(iii) 翻译保判断+形状对齐。 -/
example : derEqb (eslFromHl p q (.dHyp imp_pq) (.dRule p q (.dHyp p))) eslD
          = true := by decide

example : wtdOK [.EF imp_pq, .EF p]
      (eslFromHl p q (.dHyp imp_pq) (.dRule p q (.dHyp p))) q = true := by
  decide

example : derEqb (hlFromEsl p q (.dHyp imp_pq) (.dHyp p) (.dHyp q)) hlD
          = true := by decide

/-- (i) ESL 的恒等副前提即 MP；(ii) MP 替换论证。 -/
example : derEqb (mpFromEsl p q (.dHyp imp_pq) (.dHyp p)) eslD = true := by
  decide

def D3qq : Der := .dAndI (.dHyp q) (.dHyp q)
example : derEqb (mpDerivesEsl q (.dHyp imp_pq) (.dHyp p) D3qq)
                   (.dAndI mpD mpD)
          && wtdOK [.EF imp_pq, .EF p]
               (mpDerivesEsl q (.dHyp imp_pq) (.dHyp p) D3qq) (.fand q q)
          = true := by decide

/-- 电三：GE 绕道 β。 -/
def Gpq : List Entry := [.EF p, .EF q]
def genDetour : Der :=
  .dAndGEN (.dAndI (.dHyp p) (.dHyp q)) (.dAndI (.dHyp p) (.dHyp q))

example : derEqb (normalize 30 genDetour) (.dAndI (.dHyp p) (.dHyp q))
          = true := by decide

/-- 电四：→ESL 绕道 β（真用 p 的 →I 体）。 -/
def db_pq : Der := .dMP (.dHyp imp_pq) (.dHyp p)
def slDetour : Der :=
  .dImpSL (.dImpI p db_pq) (.dHyp p) (.dAndI (.dHyp q) (.dHyp q))

example : derEqb (normalize 30 slDetour) (.dAndI db_pq db_pq) = true := by
  decide

/-- 电五：→EHL 绕道 β（两步账：HL 红ex消掉后留一个 SL 红ex）。 -/
def hlDetour : Der :=
  .dImpHL (.dImpI p db_pq) (.dRule p q (.dMP (.dHyp imp_pq) (.dHyp p)))

example : derEqb (normalize 30 hlDetour) (.dMP (.dHyp imp_pq) db_pq)
          = true := by decide

/-- 电六：子公式性。 -/
def subF : Form → Form → Bool
  | .atom a, c => eqF (.atom a) c
  | .fand x y, c => eqF (.fand x y) c || (subF x c || subF y c)
  | .fimp x y, c => eqF (.fimp x y) c || (subF x c || subF y c)

def formsIn : Der → List Form
  | .dHyp a => [a]
  | .dRule x y d1 => x :: y :: formsIn d1
  | .dAndI d1 d2 => formsIn d1 ++ formsIn d2
  | .dImpI x d1 => x :: formsIn d1
  | .dAndE1 d1 => formsIn d1
  | .dAndE2 d1 => formsIn d1
  | .dMP d1 d2 => formsIn d1 ++ formsIn d2
  | .dAndGEN d0 d1 => formsIn d0 ++ formsIn d1
  | .dImpSL d0 d1 d2 => formsIn d0 ++ formsIn d1 ++ formsIn d2
  | .dImpHL d0 d1 => formsIn d0 ++ formsIn d1

example : (formsIn (normalize 30 genDetour)).all (subF (.fand p q)) = true := by
  decide

/- ---------- 和谐账本 ---------- -/

def etaAnd (d : Der) : Der := .dAndI (.dAndE1 d) (.dAndE2 d)

example : derEqb (normalize 30 (etaAnd (.dAndI (.dHyp p) (.dHyp q))))
                   (.dAndI (.dHyp p) (.dHyp q)) = true := by
  decide

/- ---------- 高层次强于标准层：嵌套规则应用 ---------- -/

def r2 : Form := .atom 2
def G3 : List Entry := [.ER p q, .ER (.fimp p q) r2, .EF p]

/-- 内层假设规则 p⇒q 在 →I 体里当 MP 用；外层把 p→q 证据喂给
    层 3 规则 (p→q)⇒r——两层规则假设咬合的推导。 -/
def viaRules : Der :=
  .dImpI p (.dRule (.fimp p q) r2 (.dImpI p (.dRule p q (.dHyp p))))

example : wtdOK G3 viaRules (.fimp p r2) = true := by decide

end Ex34
