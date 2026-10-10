/- ex42_ptval —— 证明论语义与完备性猜想（Lean 4 版）
   与 ex42_ptval.v 同构：64 基枚举、原子闭包、→ 量化一切基扩张的
   有效性；IPC 可靠性电池（K/S/恒等/Glivenko/反换位）+ 非 IPC 驳倒
   电池（LEM/Dummett/DNE/Peirce，反例基当场交出）+ 替换款样本。
   重账走 native_decide。 -/

namespace Ex42

inductive Fm where
  | fat (n : Nat)          -- 0=p 1=q
  | fimp (a b : Fm)
  | fand (a b : Fm)
  | for_ (a b : Fm)
  | fbot

def rulePrem : Nat → Option Nat
  | 0 => none | 1 => none
  | 2 => some 0 | 3 => some 0
  | 4 => some 1 | 5 => some 1
  | _ => none

def ruleConcl : Nat → Nat
  | 0 => 0 | 1 => 1
  | 2 => 0 | 3 => 1
  | 4 => 0 | 5 => 1
  | _ => 0

def testb (m s : Nat) : Bool := (m >>> s) &&& 1 == 1

def ruleActive (B m : Nat) : Bool := testb B m

def allBases : List Nat := List.range 64

def subbase (B2 B1 : Nat) : Bool := (B1 ||| B2) == B2   -- B2 ⊇ B1

def removeDupB : List Nat → List Nat
  | [] => []
  | x :: t => if t.any (· == x) then removeDupB t else x :: removeDupB t

def applyRules : Nat → Nat → List Nat → List Nat
  | 0, _, known => known
  | n + 1, B, known =>
      let add := [0, 1, 2, 3, 4, 5].filter fun m =>
        ruleActive B m
          && match rulePrem m with
             | none => true
             | some a => known.contains a
      let news := add.map ruleConcl
      applyRules n B (known ++ news)

def atomicClosure (B : Nat) : List Nat := removeDupB (applyRules 4 B [])

def atomAt (B n : Nat) : Bool := (atomicClosure B).contains n

/-- 基扩张有效性：→ 量化一切扩张（开放世界蕴含）。 -/
def valF (B : Nat) : Fm → Bool
  | .fat n => atomAt B n
  | .fbot => false
  | .fand x y => valF B x && valF B y
  | .for_ x y => valF B x || valF B y
  | .fimp x y =>
      allBases.all fun B2 => !(subbase B2 B && valF B2 x) || valF B2 y

def VAL (a : Fm) : Bool := allBases.all fun B => valF B a

def counterBase (a : Fm) : Option Nat :=
  allBases.find? fun B => !valF B a

/- ---------- 电池 ---------- -/

def p : Fm := .fat 0
def q : Fm := .fat 1
def neg (a : Fm) : Fm := .fimp a .fbot

/-- 电一：K/S/恒等。 -/
example : VAL (.fimp p (.fimp q p)) = true := by native_decide

example : VAL (.fimp (.fimp p (.fimp q p)) (.fimp (.fimp p q) (.fimp p p)))
  = true := by native_decide

example : VAL (.fimp p p) = true := by native_decide

/-- 电二：Glivenco 与直觉主义套件。 -/
example : VAL (neg (neg (.for_ p (neg p)))) = true := by native_decide

example : VAL (.fimp (neg q) (neg (neg q))) = true := by native_decide

/-- 顺换位（p→q)→(¬q→¬p) 是 IPC 定理；反换位 (¬q→¬p)→(p→q)
    **不是**——初稿写反被机器当场驳回（IPC 只有 ¬¬ 版）。 -/
example : VAL (.fimp (.fimp p q) (.fimp (neg q) (neg p))) = true := by
  native_decide

example : (!VAL (.fimp (.fimp (neg q) (neg p)) (.fimp p q))) = true := by
  native_decide

/-- 电三：非 IPC 者皆被空基驳倒。 -/
example : (!VAL (.for_ p (neg p))
          && (counterBase (.for_ p (neg p)) == some 0)) = true := by
  native_decide

example : (!VAL (.for_ (.fimp p q) (.fimp q p))
          && (counterBase (.for_ (.fimp p q) (.fimp q p)) == some 0))
  = true := by native_decide

example : (!VAL (.fimp (neg (neg p)) p)) = true := by native_decide

/-- 意外账：Peirce 在此影子下**幸存**——原子规则 p→q 进扩张让
    (p→q)→p 在基格上坍缩为 p，Peirce ≡ p→p。基格框架介于 IPC 与
    更强逻辑之间；完备性猜想的开放内容正在论证层 (II)。 -/
example : VAL (.fimp (.fimp (.fimp p q) p) p) = true := by native_decide

/-- 电四：替换款样本。 -/
def substA (src dst : Nat) : Fm → Fm
  | .fat n => if n == src then .fat dst else .fat n
  | .fimp x y => .fimp (substA src dst x) (substA src dst y)
  | .fand x y => .fand (substA src dst x) (substA src dst y)
  | .for_ x y => .for_ (substA src dst x) (substA src dst y)
  | .fbot => .fbot

example : VAL (.fimp p p) && VAL (substA 0 1 (.fimp p p)) = true := by
  native_decide

end Ex42
