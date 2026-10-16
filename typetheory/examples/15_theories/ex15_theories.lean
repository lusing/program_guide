/- ============================================================
   15 理论与模型论 —— Lean 对照（Farmer ch.9 + 12.4）
   与 ex15_theories.pl 双机对表：
     · 幺半群 MON 的小阶计数（1/2 阶全枚举；3 阶 33 个）
     · WPO 弱偏序计数（2 阶 3 个、3 阶 19 个）
     · PA⁺ 紧致性引擎的可证内核：sat_slice c K ⟺ K ≤ c
       ——「每个有限切片有标准见证、无总见证」即定理 9.35
   ============================================================ -/

-- ============================================================
-- 一、MON：域 {0,1} 上的运算全表（16 张）与幺半群筛选
-- ============================================================
-- 运算表 = 长度 4 的 List Nat（行优先：op x y = 表[x*2+y]）
def app2 (t : List Nat) (x y : Nat) : Nat := t[x * 2 + y]!

def assoc2 (t : List Nat) : Bool :=
  List.all (List.range 2) fun x =>
    List.all (List.range 2) fun y =>
      List.all (List.range 2) fun z =>
        app2 t (app2 t x y) z == app2 t x (app2 t y z)

def hasId2 (t : List Nat) : Bool :=
  List.any (List.range 2) fun e =>
    List.all (List.range 2) fun x =>
      app2 t e x == x && app2 t x e == x

def isMonoid2 (t : List Nat) : Bool := assoc2 t && hasId2 t

/-- 全部 16 张表 -/
def allOps2 : List (List Nat) :=
  (List.range 16).map fun k =>
    [k / 1 % 2, k / 2 % 2, k / 4 % 2, k / 8 % 2]

def monoids2 : List (List Nat) := allOps2.filter isMonoid2

#eval monoids2.length              -- 4

-- 与 Prolog 侧对表：恰 4 个
example : monoids2.length = 4 := by rfl
-- 其中两张代表：xor（Z2）与 ∧（半格）
def xorT : List Nat := [0, 1, 1, 0]
def andT : List Nat := [0, 0, 0, 1]
example : isMonoid2 xorT = true := by rfl
example : isMonoid2 andT = true := by rfl

/- 二阶同构：x↦x 与 x↦1-x 两种换标下 xor 与 ∧ 互不同构 -/
def perm2 : List (Nat → Nat) := [fun x => x, fun x => 1 - x]

def iso2 (t1 t2 : List Nat) : Bool :=
  perm2.any fun p =>
    List.all (List.range 2) fun x =>
      List.all (List.range 2) fun y =>
        p (app2 t1 x y) == app2 t2 (p x) (p y)

example : iso2 xorT andT = false := by rfl
example : iso2 andT [0, 1, 1, 1] = true := by rfl   -- ∧ 与 ∨ 同构

-- ============================================================
-- 二、WPO：关系 = 4 位/9 位位串
-- ============================================================
def inRel (r : List (Nat × Nat)) (x y : Nat) : Bool := r.contains (x, y)

def wpoN (n : Nat) (r : List (Nat × Nat)) : Bool :=
  (List.all (List.range n) fun x =>
    List.all (List.range n) fun y =>
      List.all (List.range n) fun z =>
        inRel r x x
        && (!(x != y && inRel r x y && inRel r y x))
        && (!(inRel r x y && inRel r y z && !inRel r x z)))

/-- n=2 的全部 16 个关系 -/
def allPairs2 : List (Nat × Nat) :=
  (List.range 4).map fun k => (k % 2, k / 2)
def allRels2 : List (List (Nat × Nat)) :=
  (List.range 16).map fun k =>
    allPairs2.filterMap fun p => if k / (2 ^ (p.1 * 2 + p.2)) % 2 == 1 then some p else none

#eval (allRels2.filter (wpoN 2)).length   -- 3

example : (allRels2.filter (wpoN 2)).length = 3 := by rfl

/- n=3 的 512 个关系——计数交给编译器（内核 decide 512 项太慢） -/
def allPairs3 : List (Nat × Nat) :=
  (List.range 9).map fun k => (k % 3, k / 3)
def allRels3 : List (List (Nat × Nat)) :=
  (List.range 512).map fun k =>
    allPairs3.filterMap fun p => if k / (2 ^ (p.1 * 3 + p.2)) % 2 == 1 then some p else none

#eval (allRels3.filter (wpoN 3)).length   -- 19

-- ============================================================
-- 三、SD 范畴性 + PA⁺ 引理（定理 9.35 的可证内核）
-- ============================================================
-- SD：单点域上唯一结构（1 阶恰一张表——范畴性的极端情形）
def allOps1 : List (List Nat) := [[0]]
example : allOps1.length = 1 := by rfl

/- PA⁺：公理集切片 {C ≠ m | m < K}。
   标准见证 c 满足切片 ⟺ K ≤ c：
   「每个有限切片可满足、但没有任何标准 c 见证全部公理」
   ——于是 PA⁺ 若有模型必含无穷元素，且模型非标准（9.35.2/3）。 -/
def satSlice (c K : Nat) : Bool :=
  (List.range K).all fun m => c != m

theorem satSlice_iff (c K : Nat) : satSlice c K = true ↔ K ≤ c := by
  simp only [satSlice, List.all_eq_true]
  constructor
  · intro h
    cases Nat.lt_or_ge c K with
    | inl hc => exact absurd (h c (List.mem_range.mpr hc)) (by simp)
    | inr hge => exact hge
  · intro h m hm
    have hmK : m < K := List.mem_range.mp hm
    have mlt : m < c := Nat.lt_of_lt_of_le hmK h
    simp only [bne_iff_ne, ne_eq]
    omega

-- 机器抽查：c = K 见证切片 K；任何固定 c 都死在切片 c+1 上
example : satSlice 5 5 = true := by rfl
example : satSlice 4 5 = false := by rfl
example : satSlice 9 4 = true := by rfl
example : satSlice 4 9 = false := by rfl
-- 引理版断言
example : satSlice 7 7 = true := satSlice_iff 7 7 |>.mpr (by omega)
example : satSlice 3 5 = false := by decide
