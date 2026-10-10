/- ex89_automata.lean —— 自动机与形式语言：Chomsky 层级（张寅生 11.2-11.8）
   Lean 镜像：DFA 运行器（熊猫/1+1=2）+NFA 子集构造等价对账+PDA
   aⁿbⁿ+LBA 等额影子+3 型文法↔DFA 互译。 -/

set_option linter.unusedVariables false

abbrev DFA := List (Nat × Nat × Nat)   -- (状态,符号,次态)

def dfaStep (d : DFA) (q s : Nat) : Nat :=
  match d.find? (fun e => e.1 == q && e.2.1 == s) with
  | some e => e.2.2
  | none => 99                               -- 缺省：sink（拒收）

def dfaRun : DFA → Nat → List Nat → Nat
  | _, q, [] => q
  | d, q, s :: rest => dfaRun d (dfaStep d q s) rest

def dfaAccept (d : DFA) (q0 : Nat) (fin : List Nat) (w : List Nat) : Bool :=
  fin.contains (dfaRun d q0 w)

/- ---------- 1. DFA 两个书例 ---------- -/

/-- 例 11.6 熊猫识别器：0=xióng 1=māo，越轨入 3(Rej) 自环 -/
def pandaDfa : DFA :=
  [ (0,0,1), (0,1,3), (1,0,3), (1,1,2), (2,0,3), (2,1,3), (3,0,3), (3,1,3) ]

example : dfaAccept pandaDfa 0 [2] [0,1] = true := by native_decide
example : dfaAccept pandaDfa 0 [2] [0,1,0] = false := by native_decide
example : dfaAccept pandaDfa 0 [2] [1,0] = false := by native_decide

/-- 例 11.7「1+1=2」命题识别器：0..4='1','+','1','=','2' -/
def propDfa : DFA :=
  [ (0,0,1), (1,1,2), (2,0,3), (3,2,4), (4,4,5), (5,3,6), (6,3,7), (6,4,8) ]

example : dfaAccept propDfa 0 [5] [0,1,0,2,4] = true := by native_decide
example : dfaAccept propDfa 0 [5] [0,1,0,2,3] = false := by native_decide

/- ---------- 2. NFA 与子集构造（定理 11.1） ---------- -/

abbrev NFA := List (Nat × Nat × Nat)

def nfaTargets : NFA → Nat → Nat → List Nat
  | [], _, _ => []
  | (q1, s1, q2) :: t, q, s =>
      if q1 == q && s1 == s then q2 :: nfaTargets t q s
      else nfaTargets t q s

def nfaStep2 (n : NFA) (qs : List Nat) (s : Nat) : List Nat :=
  qs.flatMap (nfaTargets n · s)

def nfaRun : NFA → List Nat → List Nat → List Nat
  | _, qs, [] => qs
  | n, qs, s :: rest => nfaRun n (nfaStep2 n qs s) rest

def nfaAccept (n : NFA) (q0 : Nat) (fin : List Nat) (w : List Nat) : Bool :=
  (nfaRun n [q0] w).any (fin.contains ·)

/-- 例 11.9 go*gle 家族：语言 g o* g l e（DFA 化） -/
def gogDfa : DFA :=
  [ (0,0,1), (1,1,1), (1,0,2), (2,2,3), (3,3,4), (4,0,5), (5,5,5)
  , (0,1,5), (0,2,5), (0,3,5), (2,0,5), (2,1,5), (2,3,5), (3,0,5)
  , (3,1,5), (3,2,5), (5,1,5), (5,2,5), (5,3,5) ]

example : [ dfaAccept gogDfa 0 [4] [0,0,2,3]
           , dfaAccept gogDfa 0 [4] [0,1,0,2,3]
           , dfaAccept gogDfa 0 [4] [0,1,1,1,0,2,3]
           , dfaAccept gogDfa 0 [4] [0,1,2,3]
           , dfaAccept gogDfa 0 [4] [0,1,1,2,3] ]
    = [true, true, true, false, false] := by native_decide

/- 子集构造：状态集→bitmask -/
def maskOf (qs : List Nat) : Nat := qs.foldl (· + 2 ^ ·) 0

def setOf (m : Nat) : List Nat :=
  [0,1,2,3].filter (fun q => m >>> q &&& 1 != 0)

def subsetRow (n : NFA) (m s : Nat) : Nat :=
  maskOf (nfaStep2 n (setOf m) s)

def subsetDfa (n : NFA) : DFA :=
  (List.range 16).flatMap (fun m => [0,1].map (fun s => (m, s, subsetRow n m s)))

def wordsUpto : Nat → Nat → List (List Nat)
  | _, 0 => [[]]
  | alph, len + 1 =>
      (wordsUpto alph len).flatMap (fun w =>
        (List.range alph).map (fun s => s :: w))

/-- 迷你 NFA：状态 {0..3}，终态 3 -/
def miniNfa : NFA := [ (0,0,1), (0,1,2), (1,0,1), (1,1,3), (2,0,3) ]

def miniDfa : DFA := subsetDfa miniNfa

/-- 定理 11.1 构造化对账：nfaAccept ⟺ dfaAccept(subset)——词长≤4 全枚举 -/
example : (wordsUpto 2 4).all (fun w =>
    nfaAccept miniNfa 0 [3] w == dfaAccept miniDfa (maskOf [0]) [8] w)
    = true := by native_decide

/- ---------- 3. PDA：aⁿbⁿ（例 11.5） ---------- -/

def anbn : List Nat → Nat → Bool
  | [], d => d == 0
  | 0 :: rest, d => anbn rest (d + 1)
  | 1 :: rest, 0 => false
  | 1 :: rest, d + 1 => anbn rest d
  | _ :: _, _ => false

example : [ anbn [0,0,0,1,1,1] 0, anbn [] 0, anbn [0,1] 0 ]
    = [true, true, true] := by native_decide

example : [ anbn [0,0,1] 0, anbn [1,0] 0, anbn [0,1,1] 0, anbn [0,0,0] 0 ]
    = [false, false, false, false] := by native_decide

/- 栈轨迹（书表 11.9）：aabb 的栈深序列 0,1,2,1,0 -/
def depthTrace : List Nat → Nat → List Nat
  | [], d => [d]
  | 0 :: rest, d => d :: depthTrace rest (d + 1)
  | 1 :: rest, d => d :: depthTrace rest (max 0 (d - 1))
  | _ :: _, d => [d]

example : depthTrace [0,0,1,1] 0 = [0,1,2,1,0] := by native_decide

/- ---------- 4. LBA 影子：等额检查（例 11.4②） ---------- -/

/-- ⟨aᵐbcᵐ⟩：符号 0=a 1=b 2=c——线性受限=只看输入内部 -/
def lbaShadow2 (w : List Nat) : Bool :=
  match w with
  | 1 :: rest =>
      rest.all (fun s => s == 0 || s == 2) &&
      (rest.filter (· == 0)).length == (rest.filter (· == 2)).length
  | _ => false

example : [ lbaShadow2 [1,0,0,2,2], lbaShadow2 [1,0,2], lbaShadow2 [1] ]
    = [true, true, true] := by native_decide

example : [ lbaShadow2 [1,0,0,2], lbaShadow2 [1,0,0,1,2], lbaShadow2 [0,2] ]
    = [false, false, false] := by native_decide

/- ---------- 5. 3 型文法↔DFA 互译（定理 11.2(4)） ---------- -/

abbrev RG := List (Nat × (Nat × Option Nat))

def rgDerives : RG → Nat → List Nat → Bool
  | _, _, [] => false
  | g, A, [s] =>
      g.any (fun r => r.1 == A && r.2.1 == s && r.2.2.isNone)
  | g, A, s :: rest =>
      g.any (fun r =>
        r.1 == A && r.2.1 == s &&
        match r.2.2 with
        | none => false
        | some B => rgDerives g B rest)

def rgToDfa (g : RG) : DFA :=
  g.map (fun r => match r.2.2 with
                  | some B => (r.1, r.2.1, B)
                  | none => (r.1, r.2.1, 4))

def gogRg : RG :=
  [ (0,(0,some 1)), (1,(1,some 1)), (1,(0,some 2)), (2,(2,some 3))
  , (3,(3,none)) ]

/-- 互译对账：生成语言=接受语言（词长≤5 全枚举） -/
example : (wordsUpto 4 5).all (fun w =>
    rgDerives gogRg 0 w == dfaAccept (rgToDfa gogRg) 0 [4] w) = true := by
  native_decide

/- 层级总表数据面：0⊇1⊇2⊇3——四层占位账 -/
def chomskyTable : List (Nat × Nat) := [ (0,0), (1,1), (2,2), (3,3) ]

example : chomskyTable.length = 4 := by native_decide

#eval (dfaRun pandaDfa 0 [0,1], (wordsUpto 2 4).length)
