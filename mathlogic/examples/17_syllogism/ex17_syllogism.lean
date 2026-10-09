/- ex17_syllogism.lean —— 三段论与传统逻辑（张寅生第 5 章+9.2/9.3）Lean 镜像
   A/E/I/O 载集语义 + 对当方阵 64 对枚举（空载集暴露存在导入）+
   256 格式枚举判定→15/24 双账 + 四格代表式 FOL 证明 + 量化扩展
   PT 部分量词与量词否定 + 格岗空间五关系可达表。 -/

set_option linter.unusedVariables false

/- ---------- 1. 载集语义 ---------- -/

def D3 : List Nat := [0, 1, 2]

def subsets : List Nat → List (List Nat)
  | [] => [[]]
  | x :: rest =>
      let ss := subsets rest
      ss.map id ++ ss.map (x :: ·)

def inclB (s p : List Nat) : Bool :=
  s.all (fun x => p.contains x)

def disjB (s p : List Nat) : Bool :=
  s.all (fun x => !p.contains x)

def aForm (s p : List Nat) : Bool := inclB s p
def eForm (s p : List Nat) : Bool := disjB s p
def iForm (s p : List Nat) : Bool := s.any (fun x => p.contains x)
def oForm (s p : List Nat) : Bool := s.any (fun x => !p.contains x)

def form2bool : Nat → List Nat → List Nat → Bool
  | 0, s, p => aForm s p
  | 1, s, p => eForm s p
  | 2, s, p => iForm s p
  | _, s, p => oForm s p

/- ---------- 2. 对当方阵 ---------- -/

def allSP : List (List Nat × List Nat) :=
  (subsets D3).flatMap (fun s => (subsets D3).map (fun p => (s, p)))

example : allSP.length = 64 := by native_decide

/- core 里没有 implb 记号，先定义 -/
def implB (a b : Bool) : Bool := !a || b

/-- 矛盾律（全对成立——不依赖非空）：A↔¬O 且 E↔¬I -/
example : allSP.all (fun sp =>
    implB (aForm sp.1 sp.2) (!oForm sp.1 sp.2) &&
    implB (eForm sp.1 sp.2) (!iForm sp.1 sp.2)) := by native_decide

/-- 反对律（非空主项）：A 与 E 不同真——空载集失守 -/
example : allSP.all (fun sp =>
    implB (sp.1 != []) (!(aForm sp.1 sp.2 && eForm sp.1 sp.2))) := by native_decide

example : [aForm [] [0,1], eForm [] [0,1]] = [true, true] := by native_decide

/-- 差等律 A→I（非空主项）+ 失守现场 -/
example : allSP.all (fun sp =>
    implB (sp.1 != [] && aForm sp.1 sp.2) (iForm sp.1 sp.2)) := by native_decide

example : [aForm [] [0,1], iForm [] [0,1]] = [true, false] := by native_decide

/-- 下反对（非空主项） -/
example : allSP.all (fun sp =>
    implB (sp.1 != []) (iForm sp.1 sp.2 || oForm sp.1 sp.2)) := by native_decide

/- ---------- 3. 256 格式判定 ---------- -/

def prem12 (fig m1 m2 : Nat) (s m p : List Nat) : Bool × Bool :=
  match fig with
  | 1 => (form2bool m1 m p, form2bool m2 s m)
  | 2 => (form2bool m1 p m, form2bool m2 s m)
  | 3 => (form2bool m1 m p, form2bool m2 m s)
  | _ => (form2bool m1 p m, form2bool m2 m s)

def sylCheck (fig m1 m2 m3 : Nat) (s m p : List Nat) : Bool :=
  let (h1, h2) := prem12 fig m1 m2 s m p
  implB (h1 && h2) (form2bool m3 s p)

def triples : List (List Nat × (List Nat × List Nat)) :=
  (subsets D3).flatMap (fun s =>
    (subsets D3).flatMap (fun m =>
      (subsets D3).map (fun p => (s, (m, p)))))

def nonEmpty3 : List (List Nat × (List Nat × List Nat)) :=
  triples.filter (fun t => t.1 != [] && t.2.1 != [] && t.2.2 != [])

def sylValidModern (fig m1 m2 m3 : Nat) : Bool :=
  triples.all (fun t => sylCheck fig m1 m2 m3 t.1 t.2.1 t.2.2)

def sylValidTrad (fig m1 m2 m3 : Nat) : Bool :=
  nonEmpty3.all (fun t => sylCheck fig m1 m2 m3 t.1 t.2.1 t.2.2)

def allFormats : List (Nat × (Nat × (Nat × Nat))) :=
  [1,2,3,4].flatMap (fun fig =>
    [0,1,2,3].flatMap (fun m1 =>
      [0,1,2,3].flatMap (fun m2 =>
        [0,1,2,3].map (fun m3 => (fig, (m1, (m2, m3)))))))

example : allFormats.length = 256 := by native_decide

/- 现代 15 强式（枚举序） -/
def modern15 : List (Nat × (Nat × (Nat × Nat))) :=
  [ (1,(0,(0,0))), (1,(0,(2,2))), (1,(1,(0,1))), (1,(1,(2,3)))
  , (2,(0,(1,1))), (2,(0,(3,3))), (2,(1,(0,1))), (2,(1,(2,3)))
  , (3,(0,(2,2))), (3,(1,(2,3))), (3,(2,(0,2))), (3,(3,(0,3)))
  , (4,(0,(1,1))), (4,(1,(2,3))), (4,(2,(0,2))) ]

/- 传统 24 式（= 15 + 9 个依赖存在导入的弱式） -/
def trad24 : List (Nat × (Nat × (Nat × Nat))) :=
  [ (1,(0,(0,0))), (1,(0,(0,2))), (1,(0,(2,2))), (1,(1,(0,1)))
  , (1,(1,(0,3))), (1,(1,(2,3)))
  , (2,(0,(1,1))), (2,(0,(1,3))), (2,(0,(3,3))), (2,(1,(0,1)))
  , (2,(1,(0,3))), (2,(1,(2,3)))
  , (3,(0,(0,2))), (3,(0,(2,2))), (3,(1,(0,3))), (3,(1,(2,3)))
  , (3,(2,(0,2))), (3,(3,(0,3)))
  , (4,(0,(0,2))), (4,(0,(1,1))), (4,(0,(1,3))), (4,(1,(0,3)))
  , (4,(1,(2,3))), (4,(2,(0,2))) ]

example : allFormats.filter (fun q =>
    sylValidModern q.1 q.2.1 q.2.2.1 q.2.2.2) = modern15 := by native_decide

example : allFormats.filter (fun q =>
    sylValidTrad q.1 q.2.1 q.2.2.1 q.2.2.2) = trad24 := by native_decide

/- Darapti 反例：S={0}, P={1}, M=∅——前提空真、结论假 -/
example : sylCheck 3 0 0 2 [0] [] [1] = false := by native_decide

/- ---------- 4. 四格代表式（FOL） ---------- -/

theorem barbara (m p s : Nat → Prop)
    (h1 : ∀ x, m x → p x) (h2 : ∀ x, s x → m x) :
    ∀ x, s x → p x := fun x hs => h1 x (h2 x hs)

theorem celarent (m p s : Nat → Prop)
    (h1 : ∀ x, m x → ¬ p x) (h2 : ∀ x, s x → m x) :
    ∀ x, s x → ¬ p x := fun x hs hp => h1 x (h2 x hs) hp

theorem darii (m p s : Nat → Prop)
    (h1 : ∀ x, m x → p x) (h2 : ∃ x, s x ∧ m x) :
    ∃ x, s x ∧ p x :=
  let ⟨x, hs, hm⟩ := h2; ⟨x, hs, h1 x hm⟩

theorem ferio (m p s : Nat → Prop)
    (h1 : ∀ x, m x → ¬ p x) (h2 : ∃ x, s x ∧ m x) :
    ∃ x, s x ∧ ¬ p x :=
  let ⟨x, hs, hm⟩ := h2; ⟨x, hs, h1 x hm⟩

/-- Baroco（AOO-2）：否定结论=反证（假设 P 导矛盾） -/
theorem baroco (p m s : Nat → Prop)
    (h1 : ∀ x, p x → m x) (h2 : ∃ x, s x ∧ ¬ m x) :
    ∃ x, s x ∧ ¬ p x :=
  let ⟨x, hs, hnm⟩ := h2
  ⟨x, hs, fun hp => hnm (h1 x hp)⟩

/-- Darapti（AAI-3）：需「中项非空」显式前提——存在导入的正面形态 -/
theorem darapti (m p s : Nat → Prop)
    (h1 : ∀ x, m x → p x) (h2 : ∀ x, m x → s x) (hm : ∃ x, m x) :
    ∃ x, s x ∧ p x :=
  let ⟨x, hx⟩ := hm; ⟨x, h2 x hx, h1 x hx⟩

/- ---------- 5. 量化扩展（张氏体系） ---------- -/

def ptForm (s p : List Nat) : Bool := iForm s p && !aForm s p

/-- ¬A=O、¬E=I（64 对） -/
example : allSP.all (fun sp =>
    (!aForm sp.1 sp.2 == oForm sp.1 sp.2) &&
    (!eForm sp.1 sp.2 == iForm sp.1 sp.2)) := by native_decide

/-- PT∨∀=∃（非空主项——空载集失守同前） -/
example : allSP.all (fun sp =>
    implB (sp.1 != [])
      ((ptForm sp.1 sp.2 || aForm sp.1 sp.2) == iForm sp.1 sp.2)) := by
  native_decide

/-- PT→∃（非空主项） -/
example : allSP.all (fun sp =>
    implB (sp.1 != [] && ptForm sp.1 sp.2) (iForm sp.1 sp.2)) := by
  native_decide

/- 定理 4.2 现场：I 与 PT 在 S=P 时分裂 -/
example : [iForm [0,1] [0,1], ptForm [0,1] [0,1]] = [true, false] := by
  native_decide

/- ---------- 6. 格岗空间 ---------- -/

inductive Gerg where
  | gdisj | geq | gcross | gsub | gsup
deriving Repr, DecidableEq

def gergOf (s p : List Nat) : Gerg :=
  if inclB s p && inclB p s then .geq
  else if inclB s p then .gsub
  else if inclB p s then .gsup
  else if disjB s p then .gdisj
  else .gcross

def gergCode : Gerg → Nat
  | .gdisj => 0 | .geq => 1 | .gcross => 2 | .gsub => 3 | .gsup => 4

def reachSet (r1 r2 : Nat) : List Nat :=
  let picked : List (List Nat × (List Nat × List Nat)) :=
    nonEmpty3.filter (fun t =>
      gergCode (gergOf t.1 t.2.1) == r1 &&
      gergCode (gergOf t.2.1 t.2.2) == r2)
  (picked.map (fun t => gergCode (gergOf t.1 t.2.2))).eraseDups

/-- 包含传递（严格版） -/
example : reachSet 4 4 = [4] := by native_decide

/-- M⊊S ∧ M∩P=∅：多余部分定不死——{全异,交叉,被包含} -/
example : reachSet 4 0 = [4, 0, 2] := by native_decide

/-- 交叉+交叉：{交叉,全同} -/
example : reachSet 2 2 = [1, 2] := by native_decide

#eval (trad24.length, modern15.length)
