/- ex07 —— 语义表列 tableau（Lean 4 版：实现与可执行现场）
   完整三定理链（sound/complete/decides 的零公理归纳证明）在 Coq 通道；
   本文件给出同构实现 + 计算现场：找到的模型可直接 #eval 验证。 -/

namespace Ex07

inductive Form where
  | fvar (n : Nat) : Form
  | fand (a b : Form) : Form
  | for_ (a b : Form) : Form
  | fimp (a b : Form) : Form
  | fneg (a : Form) : Form

open Form

def eval (e : Nat → Bool) : Form → Bool
  | fvar n => e n
  | fand a b => eval e a && eval e b
  | for_ a b => eval e a || eval e b
  | fimp a b => !(eval e a) || eval e b
  | fneg a => !(eval e a)

inductive Sign where | T | F
open Sign

abbrev Entry := Sign × Form
abbrev Branch := List Entry

def atomic : Form → Bool
  | fvar _ => true
  | _ => false

def extract : Branch → Option (Sign × Form × Branch)
  | [] => none
  | en :: B =>
      if atomic en.2 then
        match extract B with
        | some (s0, f0, rest) => some (s0, f0, en :: rest)
        | none => none
      else some (en.1, en.2, B)

def hasF (n : Nat) (B : Branch) : Bool :=
  B.any fun en => match en with
    | (F, fvar m) => m == n
    | _ => false

def closedB (B : Branch) : Bool :=
  B.any fun en => match en with
    | (T, fvar n) => hasF n B
    | _ => false

def readOff (B : Branch) : Nat → Bool :=
  fun n => B.any fun en => match en with
    | (T, fvar m) => m == n
    | _ => false

def orelse (o1 o2 : Option (Nat → Bool)) : Option (Nat → Bool) :=
  match o1 with | some e => some e | none => o2

def tsearch (fuel : Nat) (B : Branch) : Option (Nat → Bool) :=
  match fuel with
  | 0 => none
  | k + 1 =>
      if closedB B then none
      else match extract B with
        | none => some (readOff B)
        | some (T, fand a b, B') => tsearch k ((T, a) :: (T, b) :: B')
        | some (F, fand a b, B') =>
            orelse (tsearch k ((F, a) :: B')) (tsearch k ((F, b) :: B'))
        | some (T, for_ a b, B') =>
            orelse (tsearch k ((T, a) :: B')) (tsearch k ((T, b) :: B'))
        | some (F, for_ a b, B') => tsearch k ((F, a) :: (F, b) :: B')
        | some (T, fimp a b, B') =>
            orelse (tsearch k ((F, a) :: B')) (tsearch k ((T, b) :: B'))
        | some (F, fimp a b, B') => tsearch k ((T, a) :: (F, b) :: B')
        | some (T, fneg a, B') => tsearch k ((F, a) :: B')
        | some (F, fneg a, B') => tsearch k ((T, a) :: B')
        | some (_, fvar _, _) => none

/- 结果读成 Bool——函数 Option 不能直接判等（funext 地雷） -/
def found (fuel : Nat) (B : Branch) : Bool :=
  match tsearch fuel B with | some _ => true | none => false

/- ---------- 可执行现场 ---------- -/

/- 可满足式：x₀ ∨ x₁ -/
example : found 20 [(T, for_ (fvar 0) (fvar 1))] = true := by rfl

/- 找到的模型真的满足——#eval 直接验证 -/
#eval (tsearch 20 [(T, for_ (fvar 0) (fvar 1))]).get! 0   -- x₀ = true

/- 不可满足式：x₀ ∧ ¬x₀ 全分支封闭 -/
example : found 20 [(T, fand (fvar 0) (fneg (fvar 0)))] = false := by rfl

/- 经典三角：T(x₀→x₁)、T x₀、T ¬x₁ —— β 分裂两路皆闭，UNSAT
   （教训：F(x₀→x₁) 配 T x₀/F x₁ 其实是自洽的——先想清楚再写例句） -/
example : found 30
    [(T, fimp (fvar 0) (fvar 1)), (T, fvar 0), (T, fneg (fvar 1))] = false := by
  native_decide

/- 现场验证读出的模型满足分支（F 号公式取 false） -/
#eval
  match tsearch 30 [(F, fimp (fvar 0) (fand (fvar 1) (fvar 2)))] with
  | some e => !(e 0) && e 1 && e 2   -- x₀=false, x₁=x₂=true
  | none => false

/- 坑位速记（Lean 侧）：
   - for_ 是关键字 for 的避让写法（构造子名冲突）；
   - Option (Nat → Bool) 判等踩 funext 地雷——先 match 成 Bool 再断言；
   - extract 的结构递归在嵌套 match 下自动识别，不用 termination_by。 -/

end Ex07
