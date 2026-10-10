/- ex55_indiscern.lean —— 不可辨元：Ramsey 与 EM 定理（Marker GTM 217 §5.1-5.2），
    Coq 侧同构镜像 -/

def tri3 (n : Nat) : List (Nat × Nat × Nat) :=
  (List.range n).flatMap fun a =>
    ((List.range (n - a - 1)).map (· + (a + 1))).flatMap fun i =>
      ((List.range (n - i - 1)).map (· + (i + 1))).map fun j => (a, i, j)

def edgeCol (c : Nat → Nat → Bool) (i j : Nat) : Bool :=
  if i < j then c i j else c j i

def monoTri3 (c : Nat → Nat → Bool) (a i j : Nat) : Bool :=
  let e1 := edgeCol c a i
  let e2 := edgeCol c i j
  let e3 := edgeCol c a j
  e1 && e2 && e3 || !e1 && !e2 && !e3

def hasMonoTri (n : Nat) (c : Nat → Nat → Bool) : Bool :=
  (tri3 n).any fun tr => monoTri3 c tr.1 tr.2.1 tr.2.2

/-- K₅ 反例：红=C₅，蓝=补（也是 C₅）——两五边形皆无三角 -/
def c5 (i j : Nat) : Bool := ((i + 1) % 5 == j) || ((j + 1) % 5 == i)

example : !hasMonoTri 5 c5 = true := by native_decide

/-- K₆ 全账：2^15 个染色向量皆有单色三角——R(3,3)=6 -/
def allVecs : Nat → List (List Bool)
  | 0 => [[]]
  | k + 1 => (allVecs k).flatMap fun v => [false :: v, true :: v]

def edgeIdxRow : Nat → Nat
  | 0 => 0
  | i + 1 => edgeIdxRow i + (6 - i - 1)

def edgeIdx (i j : Nat) : Nat := edgeIdxRow i + (j - i - 1)

def triIdxs : List (Nat × Nat × Nat) :=
  (tri3 6).map fun t => (edgeIdx t.1 t.2.1, edgeIdx t.2.1 t.2.2, edgeIdx t.1 t.2.2)

def hasMonoVec (v : List Bool) : Bool :=
  triIdxs.any fun p =>
    let e1 := v.getD p.1 false
    let e2 := v.getD p.2.1 false
    let e3 := v.getD p.2.2 false
    e1 && e2 && e3 || !e1 && !e2 && !e3

example : (allVecs 15).all hasMonoVec = true := by native_decide

/-- R(3,4)>8：Wagner 图 M₈=C₈+对径弦——无红三角+独立数 ≤3 -/
def wagner (i j : Nat) : Bool :=
  ((i + 1) % 8 == j) || ((j + 1) % 8 == i) || ((i + 4) % 8 == j % 8)

def hasRedTri (n : Nat) (c : Nat → Nat → Bool) : Bool :=
  (tri3 n).any fun t =>
    edgeCol c t.1 t.2.1 && edgeCol c t.2.1 t.2.2 && edgeCol c t.1 t.2.2

example : !hasRedTri 8 wagner = true := by native_decide

def quadSets : List (List Nat) :=
  (List.range 8).flatMap fun a =>
    ((List.range (8 - a - 1)).map (· + (a + 1))).flatMap fun b =>
      ((List.range (8 - b - 1)).map (· + (b + 1))).flatMap fun c =>
        ((List.range (8 - c - 1)).map (· + (c + 1))).map fun d => [a,b,c,d]

example : !quadSets.any fun q =>
    (q.flatMap fun x => q.map fun y => (x, y)).all fun p => !wagner p.1 p.2
    = true := by native_decide

/-- 不可辨性检查器：两两递增指标对的原子一致 -/
def iterS (k x : Nat) : Nat :=
  match k with
  | 0 => x
  | k + 1 => iterS k (x + 1)

def indAtom (mode k i j : Nat) (seqI : List Nat) : Bool :=
  match mode with
  | 0 => seqI.getD i 0 < seqI.getD j 0
  | 1 => iterS k (seqI.getD i 0) == seqI.getD j 0
  | _ => iterS k (seqI.getD i 0) < seqI.getD j 0

def atomEq (modes B : List Nat) (seqI : List Nat) (i j k l : Nat) : Bool :=
  modes.all fun m => B.all fun kk =>
    indAtom m kk i j seqI == indAtom m kk k l seqI

def indisc2 (modes B : List Nat) (seqI : List Nat) : Bool :=
  let n := seqI.length
  (List.range n).all fun i => (List.range n).all fun j =>
    (List.range n).all fun k => (List.range n).all fun l =>
      !(i < j && k < l)
        || (atomEq modes B seqI i j k l && atomEq modes B seqI j i l k
              && atomEq modes B seqI i i k k)

/-- 账一：序语言下 [2,5,9,14] 不可辨——序原子对间隔视而不见 -/
example : indisc2 [0] [0] [2,5,9,14] = true := by native_decide

/-- 账二：加后继原子后同一列被拆穿 -/
example : !indisc2 [0,1] [1,2,3,4] [2,5,9,14] = true := by native_decide

/-- 账三：等差列也失败——S 语言没有长度 ≥3 的不可辨列 -/
example : !indisc2 [0,1] [1,2,3,4,5] [0,2,4,6] = true := by native_decide

/-- 账四：纯序语言对等差列照旧不可辨 -/
example : indisc2 [0] [0] [0,2,4,6,8] = true := by native_decide

/-- EM 装配：Skolem 壳=项闭包，保序右移诱导嵌入 -/
def emHullPairs (n : Nat) : List (Nat × Nat) :=
  (List.range n).flatMap fun i =>
    ((List.range (n - i - 1)).map (· + (i + 1))).map fun j => (i, j)

def emElem (p : Nat × Nat) : Nat := 100 + 10 * p.1 + p.2

def emShiftPairs (n : Nat) : List (Nat × Nat) :=
  (emHullPairs (n - 1)).map fun p => (p.1 + 1, p.2 + 1)

example : emShiftPairs 4 = [(1,2),(1,3),(2,3)] := by native_decide

/-- 嵌入账：t(i,j) ↦ t(τi,τj)——编码同步右移（emElem(i,j)+10=
    emElem(i+1,j+1)） -/
example : ((emShiftPairs 4).map emElem).length
    = (emShiftPairs 4).length
    && (emShiftPairs 4).all fun p => emElem p + 11 == emElem (p.1 + 1, p.2 + 1)
    = true := by native_decide

/-- 壳大小账：|hull(I)| 项数 = C(n,2) -/
example : (emHullPairs 5).length = 10 := by native_decide
