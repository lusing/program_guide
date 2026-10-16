/- ============================================================
   14 证明系统 A —— Lean 对照（Farmer ch.8 + 附录 A.3）
   与 ex14_proof.pl 双机互证：同一标本（命题 A.3 ⊢ x ≃ x 的
   三步证明 A5.1 → A4+R1 → R2）在两台机器上各过一遍检查器。
     · 公理模式匹配器 isA5_1/isA5_3/isA4 …（结构即模式）
     · R1/R2 可执行：R2 的单次出现替换带 de Bruijn 移位纪律
     · 每步公式的语义有效性：2 元模型双指派下 decide
   ============================================================ -/

-- ---- 项与公式（de Bruijn；本片段只需 N 型与公式层） ----
inductive Tm where
  | var : Nat → Tm
  | con : Nat → Tm
  | app : Tm → Tm → Tm
  | lam : Tm → Tm
  | des : Tm → Tm
deriving Repr, BEq

inductive Fm where
  | dn : Tm → Fm                 -- A↓
  | eqf : Tm → Tm → Fm           -- A = B
  | quasi : Tm → Tm → Fm         -- A ≃ B
  | imp : Fm → Fm → Fm
deriving Repr, BEq

-- ============================================================
-- 语义侧：2 元模型（el 0 0 / el 0 1），公式层恒 Bool（TATU）
-- ============================================================
inductive Vl where
  | el : Nat → Nat → Vl
  | fvt : List (Vl × Vl) → Vl
deriving Repr, BEq

mutual
def vlEq : Vl → Vl → Bool
  | .el a b, .el c d => a == c && b == d
  | .fvt t1, .fvt t2 => tabsEq t1 t2
  | _, _ => false
def tabsEq : List (Vl × Vl) → List (Vl × Vl) → Bool
  | [], [] => true
  | (a1, b1) :: t1, (a2, b2) :: t2 => vlEq a1 a2 && vlEq b1 b2 && tabsEq t1 t2
  | _, _ => false
end

/-- 手写查表（核心 List.lookup 走的路径内核卡壳——12 章同款教训） -/
def lookupV : List (Vl × Vl) → Vl → Option Vl
  | [], _ => none
  | (a, r) :: t, v => if vlEq a v then some r else lookupV t v

def evalT : List Vl → Tm → Option Vl
  | φ, .var k => φ[k]?
  | _, .con 0 => some (.el 0 0)
  | _, .con 1 => some (.el 0 1)
  | _, .con _ => none
  | φ, .app f a =>
      match evalT φ f, evalT φ a with
      | some (.fvt tab), some v => lookupV tab v
      | _, _ => none
  | φ, .lam b =>
      let tab := [.el 0 0, .el 0 1].filterMap (fun d =>
        (evalT (d :: φ) b).map (fun r => (d, r)))
      some (.fvt tab)
  | φ, .des b =>
      match [.el 0 0, .el 0 1].filter (fun d => evalT (d :: φ) b == some (.el 0 0)) with
      | [d] => some d
      | _ => none

/-- 双 Option 组合器（多关注点 match 编译产物内核卡壳——拆成辅助函数） -/
def ecombine : Option Vl → Option Vl → Bool
  | some x, some y => vlEq x y
  | _, _ => false

def qcombine : Option Vl → Option Vl → Bool
  | none, none => true
  | some x, some y => vlEq x y
  | _, _ => false

/-- 公式层：恒两值 -/
def evalF (φ : List Vl) : Fm → Bool
  | .dn t => (evalT φ t).isSome
  | .eqf a b => ecombine (evalT φ a) (evalT φ b)
  | .quasi a b => qcombine (evalT φ a) (evalT φ b)
  | .imp p q => !evalF φ p || evalF φ q

/-- 双指派下的有效性 -/
def asgs : List (List Vl) := [[.el 0 0], [.el 0 1]]
def valid (f : Fm) : Bool := asgs.all (fun φ => evalF φ f)

-- ============================================================
-- 语构侧：公理模式 + R1/R2 + 证明检查器
-- ============================================================
/-- 移位：自由指标 ≥ c 者加 d -/
def shiftT (d c : Nat) : Tm → Tm
  | .var k => if k >= c then .var (k + d) else .var k
  | .con k => .con k
  | .app f a => .app (shiftT d c f) (shiftT d c a)
  | .lam b => .lam (shiftT d (c + 1) b)
  | .des b => .des (shiftT d (c + 1) b)

/-- 深度 dd 下：模式 A 的对应形 = shiftT dd 0 A -/
private def atDepth (A : Tm) (dd : Nat) : Tm := shiftT dd 0 A

mutual
/-- R2 单次出现替换（公式层）；找不到出现返回 none -/
def repT (A B : Tm) : Tm → Nat → Option Tm
  | t, dd => if t == atDepth A dd then some (atDepth B dd)
      else match t with
        | .app f a => (repT A B f dd).map (.app · a)
              <|> (repT A B a dd).map (.app f ·)
        | .lam b => (repT A B b (dd + 1)).map .lam
        | .des b => (repT A B b (dd + 1)).map .des
        | _ => none

def repF (A B : Tm) : Fm → Nat → Option Fm
  | .dn t, dd => (repT A B t dd).map .dn
  | .eqf s t, dd => (repT A B s dd).map (.eqf · t)
              <|> (repT A B t dd).map (.eqf s ·)
  | .quasi s t, dd => (repT A B s dd).map (.quasi · t)
                <|> (repT A B t dd).map (.quasi s ·)
  | .imp p q, dd => (repF A B p dd).map (.imp · q)
              <|> (repF A B q dd).map (.imp p ·)
end

/-- 公理模式匹配器（标本所需两条；其余模式在 Prolog 侧全覆盖） -/
def axInst : Nat → Fm → Bool
  | 1, .dn (.var _) => true                            -- A5.1：(x:α)↓
  | 4, .imp (.dn A) (.quasi (.app (.lam B) A') B') =>  -- A4：β 公理
      A == A' && B == B'
  | _, _ => false

/-- 步与依据；i,j 为 1 起步号 -/
inductive Jst where
  | ax : Nat → Jst
  | mp : Nat → Nat → Jst
  | r2 : Nat → Nat → Jst
deriving Repr

def okStep (fs : List Fm) (f : Fm) : Jst → Bool
  | .ax s => axInst s f
  | .mp i k =>
      match fs[i-1]?, fs[k-1]? with
      | some p, some (.imp p' q) => p == p' && q == f
      | _, _ => false
  | .r2 i k =>
      match fs[i-1]?, fs[k-1]? with
      | some (.quasi a b), some c => repF a b c 0 == some f
      | _, _ => false

def checkProof (ps : List (Fm × Jst)) : Bool :=
  let fs := ps.map Prod.fst
  ps.all (fun (f, j) => okStep fs f j)

-- ============================================================
-- 标本：命题 A.3 ⊢ x ≃ x（书 217 页三步原证 + 首步）
-- ============================================================
def x : Tm := .var 0
def idxx : Tm := .lam (.var 0)          -- λx.x
def appIx : Tm := .app idxx x           -- (λx.x)(x)

def s1 : Fm := .dn x                                     -- (1) x↓
def s2 : Fm := .imp (.dn x) (.quasi appIx x)             -- (2) A4 实例
def s3 : Fm := .quasi appIx x                            -- (3) R1(1,2)
def s4 : Fm := .quasi x x                                -- (4) R2(3,3)

def proofA3 : List (Fm × Jst) :=
  [ (s1, .ax 1)
  , (s2, .ax 4)
  , (s3, .mp 1 2)
  , (s4, .r2 3 3) ]

#eval checkProof proofA3                -- true

-- ---- 逐条断言 ----
example : axInst 1 s1 = true := by rfl
example : axInst 4 s2 = true := by rfl
example : checkProof proofA3 = true := by rfl
-- 伪证一：换掉公理编号（A5.1 冒充 A5.3）
example : checkProof [(s1, .ax 3)] = false := by rfl
-- 伪证二：MP 的前提不是蕴涵
example : checkProof [ (s1, .ax 1), (.dn (.var 1), .mp 1 1) ] = false := by rfl
-- 伪证三：R2 目标写错（换的不是单次出现的合法结果）
example : checkProof [ (s1, .ax 1), (s2, .ax 4), (s3, .mp 1 2),
                       (.eqf x x, .r2 3 3) ] = false := by rfl

-- ---- 语义抽查：标本每一步的公式都双指派有效（可靠性的实证面） ----
example : valid s1 = true := by decide
example : valid s2 = true := by decide
example : valid s3 = true := by decide
example : valid s4 = true := by decide
-- MP 保有效性（布尔层面的一般引理）
theorem mp_preserves (φ : List Vl) (p q : Fm)
    (h1 : evalF φ p = true) (h2 : evalF φ (.imp p q) = true) :
    evalF φ q = true := by
  simp only [evalF, h1] at h2
  simpa only [Bool.not_true, Bool.false_or] using h2
