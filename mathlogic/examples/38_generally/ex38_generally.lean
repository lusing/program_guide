/- ex38_generally —— 「一般」逻辑与滤子（Lean 4 版）
   与 ex38_generally.v 同构：3 世界位掩码宇宙、256 复形×64 赋值的
   完全枚举、模块公理表（P/S/L/F）的有效/无效判定、反模型提取、
   真滤子计数 7、模块格严格包含 |F|<|S|<|P|。 -/

namespace Ex38

def univ : Nat := 7
def subI (s t : Nat) : Nat := s ||| t
def subAnd (s t : Nat) : Nat := s &&& t
def comp (s : Nat) : Nat := 7 ^^^ s

def allSubs : List Nat := List.range 8

/-- 位测试（Nat.testbit 不在 core——移位+与替代）。 -/
def testb (m s : Nat) : Bool := (m >>> s) &&& 1 == 1

def inFam (m s : Nat) : Bool := testb m s

def allFamMasks : List Nat := List.range 256

inductive Module_ where
  | MP | MS | ML | MF

def hasUniv (m : Nat) : Bool := inFam m univ
def noEmpty (m : Nat) : Bool := !inFam m 0

def capClosed (m : Nat) : Bool :=
  allSubs.all fun s =>
    allSubs.all fun t =>
      if inFam m s && inFam m t then inFam m (subAnd s t) else true

def cupClosed (m : Nat) : Bool :=
  allSubs.all fun s =>
    allSubs.all fun t =>
      if inFam m s && inFam m t then inFam m (subI s t) else true

def upClosed (m : Nat) : Bool :=
  allSubs.all fun s =>
    allSubs.all fun t =>
      if inFam m s && (subAnd s t == s)   -- s ⊆ t
      then inFam m t else true

def moduleOK (md : Module_) (m : Nat) : Bool :=
  match md with
  | .MP => hasUniv m && noEmpty m
  | .MS => hasUniv m && noEmpty m && upClosed m
  | .ML => hasUniv m && noEmpty m && capClosed m && cupClosed m
  | .MF => hasUniv m && noEmpty m && capClosed m && upClosed m

def allComplexes (md : Module_) : List Nat :=
  (allFamMasks.filter (moduleOK md))

/- ---------- 双层语义 ---------- -/

inductive GForm where
  | gatom (n : Nat)
  | gand (a b : GForm)
  | gimp (a b : GForm)
  | gneg (a : GForm)
  | gfalse
  | grad (a : GForm)   -- ∇u a
  | gall (a : GForm)   -- ∀u a
  | gex (a : GForm)    -- ∃u a

def valAt (v w n : Nat) : Bool := testb v (3 * n + w)

def extOf (v : Nat) : GForm → Nat
  | .gatom n =>
      (if valAt v 0 n then 1 else 0)
      + (if valAt v 1 n then 2 else 0)
      + (if valAt v 2 n then 4 else 0)
  | .gand x y => subAnd (extOf v x) (extOf v y)
  | .gimp x y => subI (comp (extOf v x)) (extOf v y)
  | .gneg x => comp (extOf v x)
  | .gfalse => 0
  | _ => 0

def evG (K v : Nat) : GForm → Bool
  | .gatom _ => false            -- 原子不许出现在 ∇ 层
  | .gfalse => false
  | .gand x y => evG K v x && evG K v y
  | .gimp x y => !(evG K v x) || evG K v y
  | .gneg x => !evG K v x
  | .grad a => inFam K (extOf v a)
  | .gall a => extOf v a == univ
  | .gex a => !(extOf v a == 0)

def allVals : List Nat := List.range 64

def gvalid (md : Module_) (f : GForm) : Bool :=
  (allComplexes md).all fun K => allVals.all fun v => evG K v f

def counterOf (md : Module_) (f : GForm) : Option (Nat × Nat) :=
  let ps := (allComplexes md).flatMap (fun K => allVals.map fun v => (K, v))
  ps.find? (fun p => !evG p.1 p.2 f)

/- ---------- 断言电池 ---------- -/

def A0 : GForm := .gatom 0
def B0 : GForm := .gatom 1

/-- 电一：⊕与∈——P 就够。 -/
example : gvalid .MP (.gimp (.gall A0) (.grad A0)) = true := by
  decide

example : gvalid .MP (.gimp (.grad A0) (.gex A0)) = true := by
  decide

/-- 电二：∩——F 真，S 假。 -/
example : gvalid .MF
      (.gimp (.gand (.grad A0) (.grad B0)) (.grad (.gand A0 B0))) = true := by
  decide

example : gvalid .MS
      (.gimp (.gand (.grad A0) (.grad B0)) (.grad (.gand A0 B0))) = false := by
  decide

/-- 电三：⊇（单调性）——F 真，L 假。 -/
def monoAx : GForm :=
  .gimp (.gand (.gall (.gimp A0 B0)) (.grad A0)) (.grad B0)

example : gvalid .MF monoAx = true := by decide

example : gvalid .ML monoAx = false := by decide

/-- 电四：一致性——F 真，P 假。 -/
example : gvalid .MF
      (.gimp (.gand (.grad A0) (.grad (.gneg A0))) .gfalse) = true := by
  decide

example : gvalid .MP
      (.gimp (.gand (.grad A0) (.grad (.gneg A0))) .gfalse) = false := by
  decide

/-- 电五：反例方向 ∇A→∀A 在 F 假。 -/
example : gvalid .MF (.gimp (.grad A0) (.gall A0)) = false := by decide

/-- 电六：真滤子计数——3 元宇宙恰 7 个。 -/
example : (allComplexes .MF).length = 7 := by decide

/-- 电七：模块格严格包含 |F| < |S| < |P|。 -/
example : ((allComplexes .MF).length < (allComplexes .MS).length
          && (allComplexes .MS).length < (allComplexes .MP).length) = true := by
  decide

end Ex38
