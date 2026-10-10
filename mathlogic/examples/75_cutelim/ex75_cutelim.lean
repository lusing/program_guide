/- ex75_cutelim.lean —— 截消定理与序数分析（张寅生 9.7+13.8/13.9+5.3）
   Lean 镜像：矢列语义/反演账/例 9.15 链/cut 演例/级下降/CNF 序数指派
   降序/TI 有限影子/层级表。 -/

set_option linter.unusedVariables false

inductive GForm where
  | gvar (n : Nat)
  | gimp (a b : GForm)
  | gand (a b : GForm)
  | gor (a b : GForm)
  | gneg (a : GForm)
deriving Repr, DecidableEq

abbrev GSeq := List GForm × List GForm

def valAt (n asg : Nat) : Bool := (asg >>> n) &&& 1 != 0

def gev : GForm → Nat → Bool
  | .gvar n, a => valAt n a
  | .gimp x y, a => !gev x a || gev y a
  | .gand x y, a => gev x a && gev y a
  | .gor x y, a => gev x a || gev y a
  | .gneg x, a => !gev x a

def allEv (l : List GForm) (asg : Nat) : Bool := l.all (gev · asg)
def anyEv (l : List GForm) (asg : Nat) : Bool := l.any (gev · asg)

def seqSem (s : GSeq) : Bool :=
  (List.range 256).all (fun asg => !allEv s.1 asg || anyEv s.2 asg)

/- ---------- 2. 反演定理命题侧 ---------- -/

def invPairs : List (GSeq × GSeq) :=
  [ (([.gand (.gvar 0) (.gvar 1)], []), ([.gvar 0], []))
  , (([], [.gand (.gvar 0) (.gvar 1)]), ([], [.gvar 0, .gvar 1]))
  , (([.gor (.gvar 0) (.gvar 1)], []), ([.gvar 0, .gvar 1], []))
  , (([], [.gor (.gvar 0) (.gvar 1)]), ([], [.gvar 0]))
  , (([.gneg (.gvar 0)], []), ([], [.gvar 0]))
  , (([], [.gneg (.gvar 0)]), ([.gvar 0], []))
  , (([.gimp (.gvar 0) (.gvar 1)], []), ([.gvar 1], []))
  , (([], [.gimp (.gvar 0) (.gvar 1)]), ([.gvar 0], [.gvar 1]))
  ]

example : invPairs.all (fun p => seqSem p.1 == seqSem p.2) = true := by
  native_decide

/- ---------- 3. 例 9.15 七步链 ---------- -/

def ex915Chain : List (GSeq × Nat) :=
  [ (([.gvar 0], [.gvar 0]), 1)
  , (([.gvar 0], [.gvar 0, .gneg (.gvar 1)]), 2)
  , (([.gvar 1], [.gvar 1]), 3)
  , (([.gvar 1, .gneg (.gvar 1)], []), 4)
  , (([.gneg (.gvar 1), .gvar 0], [.gvar 0]), 5)
  , (([.gneg (.gvar 1), .gand (.gvar 0) (.gvar 1)], [.gvar 0]), 6)
  , (([.gand (.gvar 0) (.gvar 1)], [.gvar 0, .gneg (.gvar 1)]), 7)
  ]

example : ex915Chain.all (fun st => seqSem st.1) = true := by native_decide

def ex915Thm : GForm :=
  .gimp (.gneg (.gand (.gvar 0) (.gvar 1)))
        (.gor (.gneg (.gvar 0)) (.gneg (.gvar 1)))

example : seqSem ([], [ex915Thm]) = true := by native_decide

/- ---------- 4. cut 演例 ---------- -/

def cutApply (s1 s2 : GSeq) : GSeq := (s1.1 ++ s2.1, s1.2 ++ s2.2)

def cutDemo : GSeq :=
  cutApply ([.gvar 0], [.gor (.gvar 0) (.gvar 0)])
           ([.gor (.gvar 0) (.gvar 0)], [.gvar 0])

example : [ seqSem ([.gvar 0], [.gor (.gvar 0) (.gvar 0)])
           , seqSem ([.gor (.gvar 0) (.gvar 0)], [.gvar 0])
           , seqSem cutDemo ] = [true, true, true] := by native_decide

/- ---------- 5. 级与情形 3 ---------- -/

def grade : GForm → Nat
  | .gvar _ => 1
  | .gimp a b | .gand a b | .gor a b => max (grade a + 1) (grade b + 1)
  | .gneg a => grade a + 1

def m3 : GForm := .gimp (.gimp (.gvar 0) (.gvar 1)) (.gvar 2)

example : grade m3 = 3 := by native_decide

example : max (grade (.gvar 0)) (grade (.gimp (.gvar 1) (.gvar 2)))
    < grade m3 := by native_decide

/- ---------- 6. CNF 序数（低位在前）与指派 ---------- -/

def cnfAdd1 : List Nat → List Nat
  | [] => [1]
  | h :: t => (h + 1) :: t

def natSum : List Nat → List Nat → List Nat
  | [], x | x, [] => x
  | ha :: ta, hb :: tb => Nat.max ha hb :: natSum ta tb

def padL : Nat → List Nat → List Nat
  | 0, l => l
  | k + 1, l => 0 :: padL k l

def cnfLtHi : List Nat → List Nat → Bool
  | _, [] => false
  | [], _ => true
  | ha :: ta, hb :: tb =>
      if ha == hb then cnfLtHi ta tb else !Nat.ble hb ha

def cnfLt (a b : List Nat) : Bool :=
  cnfLtHi (padL (b.length - a.length) a.reverse)
          (padL (a.length - b.length) b.reverse)

def ordInit : List Nat := [1]
def ordLogical (sub : List Nat) : List Nat := cnfAdd1 sub

def cutOrd : List Nat :=
  natSum [0,0,0,1] (natSum (ordLogical [1]) (ordLogical [1]))

def cutfreeOrd : List Nat := ordLogical (natSum [1] [2])

/-- 降序定理单例：o(P') < o(P)——3 < ω³+2 -/
example : cnfLt cutfreeOrd cutOrd = true := by native_decide

/- ---------- 7. TI 有限影子 ---------- -/

def holdsUpto (p : Nat → Bool) : Nat → Bool
  | 0 => p 0
  | k + 1 => holdsUpto p k && p (k + 1)

def tiOn (p : Nat → Bool) : Nat → Bool
  | 0 => p 0
  | k + 1 => tiOn p k && (!p k || p (k + 1))

example : (List.range 8).all (fun n =>
    (!tiOn (fun k => k * k == k * k) n ||
      holdsUpto (fun k => k * k == k * k) n)) = true := by native_decide

def leastCounter (p : Nat → Bool) : Nat → Option Nat
  | 0 => if !p 0 then some 0 else none
  | k + 1 => if !p (k + 1) then some (k + 1) else leastCounter p k

/-- 反例存在 ⟹ 最小反例存在（良序最小元） -/
example : (List.range 8).all (fun n =>
    !((List.range n).any (fun k => !(k + k == 2 * k))) ||
      (leastCounter (fun k => k + k == 2 * k) n).isSome) = true := by
  native_decide

/- ---------- 8. 层级表 ---------- -/

/-- 12 层节选：EFA<PRA<RCA₀<WKL₀<IΣ₁<PA<ACA₀<ATR₀<Π¹₁-CA₀<Z₂<ZFC<不可达 -/
def ladder : List Nat := (List.range 12).map (· + 1)

example : ladder.length = 12 := by native_decide

#eval (grade m3, cutOrd, cutfreeOrd, cnfLt cutfreeOrd cutOrd)

/- ---------- 9. Takeuti §5 深化：mix 规则与 rank（LK* 视角） ---------- -/

/-- 公式可判定相等 -/
def formEqb : GForm → GForm → Bool
  | .gvar m, .gvar n => m == n
  | .gimp a1 a2, .gimp b1 b2 => formEqb a1 b1 && formEqb a2 b2
  | .gand a1 a2, .gand b1 b2 => formEqb a1 b1 && formEqb a2 b2
  | .gor a1 a2, .gor b1 b2 => formEqb a1 b1 && formEqb a2 b2
  | .gneg a1, .gneg b1 => formEqb a1 b1
  | _, _ => false

/-- 9.1 mix：把一侧中混合公式 A 的全部出现一次删光 -/
def eraseAll (A : GForm) : List GForm → List GForm
  | [] => []
  | B :: t => if formEqb A B then eraseAll A t else B :: eraseAll A t

def countForm (A : GForm) (l : List GForm) : Nat :=
  l.foldr (fun B acc => (if formEqb A B then 1 else 0) + acc) 0

/-- mix 结论：Γ, Π* → Δ*, Λ -/
def mixSeq (A : GForm) (S1 S2 : GSeq) : GSeq :=
  (S1.1 ++ eraseAll A S2.1, eraseAll A S1.2 ++ S2.2)

/-- 「一次删光」账本：被删出现数 = 左右两侧 A 出现总数 -/
example :
    let A : GForm := .gvar 0
    let S1 : GSeq := ([.gvar 1], [A, .gvar 2, A])
    let S2 : GSeq := ([A, .gvar 3, A], [.gvar 4])
    (countForm A S1.2, countForm A S2.1,
     countForm A (mixSeq A S1 S2).2, countForm A (mixSeq A S1 S2).1)
      = (2, 2, 0, 0) := by native_decide

/-- 9.2 方向一（mix 可靠性=cut+收缩可导出）：有效前提 mix 后仍有效 -/
example :
    let A : GForm := .gvar 0
    let S1 : GSeq := ([.gvar 1], [.gvar 1, A, .gvar 2, A])
    let S2 : GSeq := ([A, .gvar 2, A], [.gvar 2])
    (seqSem S1 && seqSem S2 && seqSem (mixSeq A S1 S2)) = true := by
  native_decide

/-- 收缩保有效性的样本账 -/
example :
    let A : GForm := .gvar 0
    (seqSem ([.gvar 1], [.gvar 1, A, .gvar 2])
      == seqSem ([.gvar 1], [.gvar 1, A, .gvar 2, A])) = true := by
  native_decide

/-- 方向二（cut ⇒ mix）：cut 只删一次出现、残余再收缩——步数账 -/
example :
    let A : GForm := .gvar 0
    let S1 : GSeq := ([.gvar 1], [.gvar 1, A, .gvar 2, A])
    let S2 : GSeq := ([A, .gvar 2, A], [.gvar 2])
    let cutConcl : GSeq := ([.gvar 1, A, .gvar 2], [.gvar 1, .gvar 2, A, .gvar 2])
    (countForm A (mixSeq A S1 S2).1 + countForm A (mixSeq A S1 S2).2,
     countForm A cutConcl.1 + countForm A cutConcl.2,
     (eraseAll A cutConcl.1 == (mixSeq A S1 S2).1)
       && (eraseAll A cutConcl.2 == (mixSeq A S1 S2).2)) = (0, 2, true) := by
  native_decide

/-- 9.3 rank：自链底（mix 上矢列）向上数连续含 A 者 -/
def rankFromBottom (A : GForm) (side : GSeq → List GForm) : List GSeq → Nat
  | [] => 0
  | s :: t => if (side s).any (formEqb A) then 1 + rankFromBottom A side t else 0

def leftSide (s : GSeq) : List GForm := s.2    -- 左 thread 看 succedent
def rightSide (s : GSeq) : List GForm := s.1   -- 右 thread 看 antecedent

def rankPair (A : GForm) (lchain rchain : List GSeq) : Nat :=
  rankFromBottom A leftSide lchain + rankFromBottom A rightSide rchain

/-- 样本一（rank=2）：两侧混合公式都「新鲜」
   注意链以「底在前」给出 -/
example : rankPair (.gvar 0)
    [([.gvar 1], [.gvar 0, .gvar 2]), ([.gvar 1, .gvar 2], [.gvar 3])]
    [([.gvar 0, .gvar 4], [.gvar 5]), ([.gvar 4], [.gvar 5])] = 2 := by
  native_decide

/-- 样本二（rank=3）：左链底部两个矢列连续含 A——Case 2「推过推理」形态 -/
example : rankPair (.gvar 0)
    [([.gvar 1], [.gvar 0, .gvar 2, .gvar 0]), ([.gvar 1], [.gvar 0, .gvar 2])]
    [([.gvar 0, .gvar 4], [.gvar 5]), ([.gvar 4], [.gvar 5])] = 3 := by
  native_decide

/-- 9.4 Case 1.5(i)：mix 的 grade 下降账 -/
example : grade (.gvar 0) < grade (.gand (.gvar 0) (.gvar 1)) := by
  native_decide

/-- rank≥2 恒成立：链底=mix 上矢列必含 A -/
def lchA : List GSeq := [([.gvar 1], [.gvar 0, .gvar 2])]
def rchA : List GSeq := [([.gvar 0], [.gvar 3])]
def lchB : List GSeq := [([.gvar 1], [.gvar 0])]
def rchB : List GSeq := [([.gvar 0, .gvar 0], [.gvar 3])]

example : [((lchA, rchA)), ((lchB, rchB))].all (fun p =>
    2 <= rankPair (.gvar 0) p.1 p.2) = true := by native_decide
