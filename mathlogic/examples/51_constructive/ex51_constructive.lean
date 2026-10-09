/- ex49 —— 构造性与 Heyting 语义（Müller-Stach ch6/ch9）Lean 镜像
   Gödel–Gentzen 双否定 FOL 翻译器 + 经典等价全枚举 + Sierpinski 型
   开集格 Heyting 语义（¬¬U≠U / ¬A∨B ≤ A→B / 布尔-直觉对照）+
   四平方构造搜索器。 -/

set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

/- ---------- 1. Gödel–Gentzen 双否定翻译（FOL 七行） ---------- -/

inductive Form
  | atom (b : Nat)
  | ffalse
  | fand (a b : Form)
  | for_ (a b : Form)
  | fimp (a b : Form)
  | fall (a : Form)
  | fex (a : Form)

/-- Pⁿ=¬¬P (a∨b)ⁿ=¬(¬aⁿ∧¬bⁿ) (∃x a)ⁿ=¬∀x¬aⁿ —— 其余直走 -/
def nnF : Form → Form
  | .atom b => .fimp (.fimp (.atom b) .ffalse) .ffalse
  | .ffalse => .ffalse
  | .fand x y => .fand (nnF x) (nnF y)
  | .for_ x y => .fimp (.fand (.fimp (nnF x) .ffalse) (.fimp (nnF y) .ffalse)) .ffalse
  | .fimp x y => .fimp (nnF x) (nnF y)
  | .fall x => .fall (nnF x)
  | .fex x => .fimp (.fall (.fimp (nnF x) .ffalse)) .ffalse

def evF : Form → List Bool → Bool
  | .atom b, v => v.getD b false
  | .ffalse, _ => false
  | .fand x y, v => evF x v && evF y v
  | .for_ x y, v => evF x v || evF y v
  | .fimp x y, v => !evF x v || evF y v
  | .fall x, v => evF x (false :: v) && evF x (true :: v)
  | .fex x, v => evF x (false :: v) || evF x (true :: v)

def samples : List Form :=
  [ .atom 0
  , .fimp (.atom 0) (.atom 0)
  , .for_ (.atom 0) (.fimp (.atom 0) .ffalse)
  , .fand (.atom 0) (.atom 1)
  , .fimp (.fand (.atom 0) (.atom 1)) (.atom 0)
  , .fex (.atom 0)
  , .fall (.for_ (.atom 0) (.atom 1))
  , .for_ (.fand (.atom 0) (.atom 1)) (.fand (.atom 1) (.atom 0)) ]

def asg4 : List (List Bool) :=
  [[false, false], [false, true], [true, false], [true, true]]

/-- 翻译保持经典意义（样本×全赋值逐位相等） -/
example : samples.all (fun f =>
    asg4.all (fun v => evF (nnF f) v == evF f v)) := by native_decide

/- ---------- 2. Lean 的直觉语境 ---------- -/

/-- 三重否定坍缩——翻译器每步产生 ¬¬ 形状（裸 core 无 tauto，
    直觉证明手写项：Lean kernel 本身直觉） -/
example : ∀ (P : Prop), ¬¬¬P → ¬P :=
  fun _ hnnn hp => hnnn (fun hn => hn hp)

/-- Kripke 引理：双重否定的合取封闭（直觉可证的典范样本） -/
example : ∀ (P Q : Prop), ¬¬P → ¬¬Q → ¬¬(P ∧ Q) :=
  fun _ _ h1 h2 h => h1 (fun hp => h2 (fun hq => h ⟨hp, hq⟩))

/- ---------- 3. Sierpinski 型开集格上的 Heyting 语义 ---------- -/

abbrev Open := List Bool   -- 3 位表 [位0;位1;位2]

def OPENS : List Open :=
  [[false, false, false], [true, false, false],
   [true, true, false], [true, true, true]]

def subL (a b : Open) : Bool :=
  (a.length == b.length) && (a.zip b).all (fun p => !p.1 || p.2)

def cupL : Open → Open → Open
  | [], r => r | r, [] => r
  | x :: t, y :: t' => (x || y) :: cupL t t'

def negL1 (a : Open) : Open := a.map (!·)

def intL (x : Open) : Open :=
  OPENS.foldl (fun acc o => if subL o x then cupL acc o else acc) []

def negL (a : Open) : Open := intL (negL1 a)

def impL (a b : Open) : Open := intL (cupL (negL1 a) b)

/-- ¬¬U = 全集 ≠ U —— 弱排中失败现场 -/
example : negL (negL [true, true, false]) == [true, true, true]
    && !(negL (negL [true, true, false]) == [true, true, false]) := by
  native_decide

/-- ¬A∨B ≤ A→B：经典等式降级为格中不等式（全 16 对） -/
example :
    (OPENS.flatMap fun a => OPENS.map fun b => (a, b)).all (fun ab =>
      subL (cupL (negL ab.1) ab.2) (impL ab.1 ab.2)) := by native_decide

/-- 真不等样本：¬{0}∨{0,1}={0,1} 而 {0}→{0,1}=全集 -/
example : cupL (negL [true, false, false]) [true, true, false]
      == [true, true, false]
    && impL [true, false, false] [true, true, false] == [true, true, true]
    := by native_decide

/-- 布尔补 vs Heyting 否定：同一格、两种否定 -/
example : OPENS.map (fun a => (negL1 a, negL a))
    = [([true, true, true], [true, true, true]),
       ([false, true, true], [false, false, false]),
       ([false, false, true], [false, false, false]),
       ([false, false, false], [false, false, false])] := by native_decide

/- ---------- 4. 四平方：构造性存在的机器面 ---------- -/

abbrev Quad := Nat × (Nat × (Nat × Nat))

def sq4 (t : Quad) : Nat :=
  t.1 * t.1 + t.2.1 * t.2.1 + t.2.2.1 * t.2.2.1 + t.2.2.2 * t.2.2.2

def quadOK (n : Nat) (t : Quad) : Bool := sq4 t == n

def quads (n : Nat) : List Quad :=
  (List.range (n + 1)).flatMap fun a =>
    (List.range (n + 1 - a)).flatMap fun i =>
      let b := a + i
      (List.range (n + 1 - b)).flatMap fun j =>
        let c := b + j
        (List.range (n + 1 - c)).map fun k =>
          (a, (b, (c, c + k)))

def lagrange4 (n : Nat) : Option Quad := (quads n).find? (quadOK n)

/-- 1..24 全部交出见证且平方和恒等式成立 -/
example : (List.range 24).all (fun i =>
    match lagrange4 (i + 1) with
    | some t => quadOK (i + 1) t
    | none => false) := by native_decide

#eval (List.range 24).map (fun i => lagrange4 (i + 1))
#eval (negL [true, true, false], impL [true, false, false] [true, false, false])
