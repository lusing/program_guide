/- ex22_historical.lean —— 历史形式系统考古（张寅生 9.4/9.5/9.3）Lean 镜像
   Frege 九公理（命题侧六条永真抽查）+例 9.5 条件证明账；PM R-1 五公理
   +2.07→2.08 四步链；Hilbert 17 公理全真验证+S-K-K 恒等式；血缘账。 -/

set_option linter.unusedVariables false

inductive PForm where
  | pvar (n : Nat)
  | pimp (a b : PForm)
  | pneg (a : PForm)
  | por (a b : PForm)
  | pand (a b : PForm)
  | piff (a b : PForm)
deriving Repr, DecidableEq

def valAt (n asg : Nat) : Bool := (asg >>> n) &&& 1 != 0

def peval : PForm → Nat → Bool
  | .pvar n, a => valAt n a
  | .pimp x y, a => !peval x a || peval y a
  | .pneg x, a => !peval x a
  | .por x y, a => peval x a || peval y a
  | .pand x y, a => peval x a && peval y a
  | .piff x y, a => peval x a == peval y a

def taut (f : PForm) : Bool := (List.range 256).all (peval f)

/- ---------- 1. Frege 1879 九公理（命题侧六条） ---------- -/

def fAxioms : List PForm :=
  [ .pimp (.pvar 0) (.pimp (.pvar 1) (.pvar 0))                        -- F1
  , .pimp (.pimp (.pvar 2) (.pimp (.pvar 1) (.pvar 0)))
          (.pimp (.pimp (.pvar 2) (.pvar 1)) (.pimp (.pvar 2) (.pvar 0))) -- F2
  , .pimp (.pimp (.pvar 2) (.pimp (.pvar 1) (.pvar 0)))
          (.pimp (.pvar 1) (.pimp (.pvar 2) (.pvar 0)))                  -- F8
  , .pimp (.pimp (.pvar 1) (.pvar 0))
          (.pimp (.pneg (.pvar 0)) (.pneg (.pvar 1)))                    -- F28
  , .pimp (.pneg (.pneg (.pvar 0))) (.pvar 0)                            -- F31
  , .pimp (.pvar 0) (.pneg (.pneg (.pvar 0)))                            -- F41
  ]

example : fAxioms.all taut = true := by native_decide

/- 例 9.5：目标式裸身非永真（条件证明！），前提 b→a 并入后永真 -/
def fEx95Target : PForm :=
  .pimp (.pimp (.pneg (.pvar 0)) (.pvar 1))
        (.pimp (.pimp (.pneg (.pvar 0)) (.pvar 1)) (.pneg (.pneg (.pvar 0))))

def fEx95WithPrem : PForm :=
  .pimp (.pimp (.pvar 1) (.pvar 0)) fEx95Target

example : taut fEx95WithPrem = true := by native_decide

example : taut fEx95Target = false := by native_decide

/- ---------- 2. PM R-1 五公理与 2.08 链 ---------- -/

def pm12 : PForm := .pimp (.por (.pvar 0) (.pvar 0)) (.pvar 0)
def pm13 : PForm := .pimp (.pvar 1) (.por (.pvar 0) (.pvar 1))
def pm14 : PForm := .pimp (.por (.pvar 0) (.pvar 1)) (.por (.pvar 1) (.pvar 0))
def pm15 : PForm :=
  .pimp (.por (.pvar 0) (.por (.pvar 1) (.pvar 2)))
        (.por (.pvar 1) (.por (.pvar 0) (.pvar 2)))
def pm16 : PForm :=
  .pimp (.pimp (.pvar 1) (.pvar 2))
        (.pimp (.por (.pvar 0) (.pvar 1)) (.por (.pvar 0) (.pvar 2)))

def pmAxioms : List PForm := [pm12, pm13, pm14, pm15, pm16]

example : pmAxioms.all taut = true := by native_decide

/- 2.07→2.08 四步链 -/
def pm207 : PForm := .pimp (.pvar 0) (.por (.pvar 0) (.pvar 0))

def pm205Inst : PForm :=
  .pimp (.pimp (.por (.pvar 0) (.pvar 0)) (.pvar 0))
        (.pimp (.pimp (.pvar 0) (.por (.pvar 0) (.pvar 0)))
               (.pimp (.pvar 0) (.pvar 0)))

def pmMpMid : PForm :=
  .pimp (.pimp (.pvar 0) (.por (.pvar 0) (.pvar 0))) (.pimp (.pvar 0) (.pvar 0))

example : [pm207, pm12, pm205Inst, pmMpMid, .pimp (.pvar 0) (.pvar 0)].all taut
    = true := by native_decide

/- 骨架对账：2.05 实例=公理 1.2 与 2.07 的组合包装 -/
example : ∃ A B C, pm205Inst = .pimp A (.pimp B C)
    ∧ A = pm12 ∧ B = pm207 ∧ C = .pimp (.pvar 0) (.pvar 0) :=
  ⟨pm12, pm207, .pimp (.pvar 0) (.pvar 0), by rfl, rfl, rfl, rfl⟩

/- ---------- 3. Hilbert 1927 十七公理 ---------- -/

def h17 : List PForm :=
  [ .pimp (.pvar 0) (.pimp (.pvar 1) (.pvar 0))                        -- I.1
  , .pimp (.pimp (.pvar 0) (.pimp (.pvar 0) (.pvar 1))) (.pimp (.pvar 0) (.pvar 1)) -- I.2
  , .pimp (.pimp (.pvar 0) (.pvar 1))
          (.pimp (.pimp (.pvar 1) (.pvar 2)) (.pimp (.pvar 0) (.pvar 2))) -- I.3
  , .pimp (.pneg (.pvar 0)) (.pimp (.pvar 0) (.pvar 1))                 -- I.4
  , .pimp (.pand (.pvar 0) (.pvar 1)) (.pvar 0)                         -- II.5
  , .pimp (.pand (.pvar 0) (.pvar 1)) (.pvar 1)                         -- II.6
  , .pimp (.pvar 0) (.pimp (.pvar 1) (.pand (.pvar 0) (.pvar 1)))       -- II.7
  , .pimp (.pvar 0) (.por (.pvar 0) (.pvar 1))                          -- III.8
  , .pimp (.pvar 1) (.por (.pvar 0) (.pvar 1))                          -- III.9
  , .pimp (.pand (.pimp (.pvar 0) (.pvar 2)) (.pimp (.pvar 1) (.pvar 2)))
          (.pimp (.por (.pvar 0) (.pvar 1)) (.pvar 2))                  -- III.10
  , .pimp (.piff (.pvar 0) (.pvar 1)) (.pimp (.pvar 0) (.pvar 1))       -- IV.11
  , .pimp (.piff (.pvar 0) (.pvar 1)) (.pimp (.pvar 1) (.pvar 0))       -- IV.12
  , .pimp (.pand (.pimp (.pvar 0) (.pvar 1)) (.pimp (.pvar 1) (.pvar 0)))
          (.piff (.pvar 0) (.pvar 1))                                   -- IV.13
  , .pimp (.pimp (.pvar 0) (.pvar 1))
          (.pimp (.pneg (.pvar 1)) (.pneg (.pvar 0)))                   -- V.14
  , .pimp (.pneg (.pneg (.pvar 0))) (.pvar 0)                           -- V.15
  , .pimp (.pimp (.pneg (.pvar 0)) (.pvar 0)) (.pvar 0)                 -- V.16
  , .pimp (.pvar 0) (.pneg (.pneg (.pvar 0)))                           -- V.17
  ]

example : h17.length = 17 := by native_decide

example : h17.all taut = true := by native_decide

/- ---------- 4. 互导见证 ---------- -/

/-- A1（Mendelson 第 1 公理）就是 H.I.1——同一公理的两次出生 -/
example : (h17.head? == some (.pimp (.pvar 0) (.pimp (.pvar 1) (.pvar 0))))
    = true := by native_decide

/-- V.14（逆否）在 17 公理清单内 -/
example : h17.contains (.pimp (.pimp (.pvar 0) (.pvar 1))
    (.pimp (.pneg (.pvar 1)) (.pneg (.pvar 0)))) = true := by native_decide

/- S-K-K 恒等式（命题版）：Mendelson 引擎的火力见证。
   Lean 侧用抽样实例（任意公式 a，taut (a→a) 的语义事实——一般性证明
   由归纳给出，见 06 章）；Coq 侧有 mder 句法五步 -/
example : ( [ PForm.pimp (.pvar 3) (.pvar 3)
             , PForm.pimp (.pimp (.pvar 0) (.pvar 1))
                         (.pimp (.pvar 0) (.pvar 1))
             , PForm.pimp (.pneg (.pvar 2)) (.pneg (.pvar 2)) ] : List PForm
           ).all taut = true := by
  native_decide

/- ---------- 5. 血缘账 ---------- -/

/-- F28 与 V.14：变元换位后同一骨架（任意赋值同值） -/
example : [0, 5, 9, 200].all (fun asg =>
    peval (.pimp (.pimp (.pvar 1) (.pvar 0))
                 (.pimp (.pneg (.pvar 0)) (.pneg (.pvar 1)))) asg
    == peval (.pimp (.pimp (.pvar 0) (.pvar 1))
                   (.pimp (.pneg (.pvar 1)) (.pneg (.pvar 0)))) asg) := by
  native_decide

#eval (fAxioms.length, pmAxioms.length, h17.length)
