/- ex47 —— Gödel 第二不完备与一致性扩张（Müller-Stach ch6）Lean 镜像
   BACH↦8647201500 素数幂编码（Lean Nat 即 GMP 二进制，86 亿直接算）+
   句子宇宙一致性扩张梯子（T0→+Con→+Con+Con 的 Gödel 句逐层逃逸）+
   D1 机制账 + soundness 影子。 -/

set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

/- ---------- 1. BACH ↦ 8647201500 ---------- -/

def primes : List Nat := [2, 3, 5, 7, 11, 13, 17, 19]

def nthPrime (i : Nat) : Nat := primes.getD i 23

def encAt : Nat → List Nat → Nat
  | _, [] => 1
  | i, x :: t => nthPrime i ^ x * encAt (i + 1) t

def bachEncode (l : List Nat) : Nat := encAt 0 l

/-- B=2 A=1 C=3 H=8 ↦ 2²·3¹·5³·7⁸ = 8647201500（书 p91 原例） -/
example : bachEncode [2, 1, 3, 8] = 8647201500 := by native_decide

/-- 唯一分解解码：逐素数剥指数 -/
def peel : Nat → Nat → Nat → Nat → Nat
  | 0, _, _, e => e
  | fuel + 1, n, p, e =>
      if n % (p * p ^ e) == 0 then peel fuel n p (e + 1) else e

def decAt : Nat → Nat → Nat → List Nat
  | 0, _, _ => []
  | fuel + 1, i, n =>
      if n == 1 then []
      else let p := nthPrime i
           let e := peel 8 n p 0
           e :: decAt fuel (i + 1) (n / p ^ e)

def bachDecode (n : Nat) : List Nat := decAt 8 0 n

def leqb : List Nat → List Nat → Bool
  | [], [] => true
  | x :: t, y :: t' => (x == y) && leqb t t'
  | _, _ => false

example : ([[1], [8], [1, 2, 3], [2, 1, 3, 8], [8, 8, 7, 6, 5],
              [4, 4, 4, 4], [1, 2, 3, 4, 5, 6, 7, 8]]).map
              (fun w => leqb (bachDecode (bachEncode w)) w)
    = [true, true, true, true, true, true, true] := by native_decide

/- ---------- 2. 句子宇宙与 MP 规则表 ---------- -/

/-- 0=crash「0=1」（假）；1,2=基础公理；3=Con(T0)；4=G(T0)；
    5=Con(T1)；6=G(T1)；7=「Con(T0)→G(T0)」；8=「Con(T1)→G(T1)」 -/
def TRUTH : List Bool :=
  [false, true, true, true, true, true, true, true, true]

def mpTable : List (Nat × (Nat × Nat)) :=
  [(7, (3, 4)), (8, (5, 6))]

def inN (x : Nat) (l : List Nat) : Bool := l.any (fun y => x == y)

def mpStep (seen : List Nat) : List Nat :=
  seen ++ (mpTable.flatMap fun r =>
    if (inN r.1 seen && inN r.2.1 seen) && !inN r.2.2 seen then [r.2.2]
    else [])

def prov : Nat → List Nat → List Nat
  | 0, ax => ax
  | d + 1, ax => mpStep (prov d ax)

def provC (T : List Nat) : List Nat := prov 3 T

def T0 : List Nat := [1, 2, 7, 8]
def T1 : List Nat := [3] ++ T0
def T2 : List Nat := [5, 3] ++ T0

def conOf (T : List Nat) : Bool := !inN 0 (provC T)

/-- 一致性扩张梯子：逐层收编上一级逃逸句、又造出新逃逸句，三级全一致 -/
example :
  [ !(inN 4 (provC T0)),     -- G(T0) 逃出 T0 —— Gödel I
    inN 4 (provC T1),        -- T0+Con(T0) ⊢ G(T0)
    !(inN 6 (provC T1)),     -- G(T1) 仍逃出 T1 —— Gödel II 再来
    inN 6 (provC T2),        -- T1+Con(T1) ⊢ G(T1)
    conOf T0, conOf T1, conOf T2 ]
    = [true, true, true, true, true, true, true] := by native_decide

/-- Con(T0) 本身逃出 T0 —— Gödel II 的直接陈述 -/
example : !inN 3 (provC T0) := by native_decide

/-- D1 机制账：φ 与 φ→ψ 可证则 ψ 可证（闭包算子即 D1 的兑现） -/
example : (inN 3 (provC T1) && inN 7 (provC T1)) && inN 4 (provC T1) := by
  native_decide

/-- soundness 影子：T2 定理全真（0 假句不可证——Con 为真句的语义根据） -/
example : (provC T2).all (fun i => TRUTH.getD i false) := by native_decide

#eval (provC T0, provC T1, provC T2)
#eval bachEncode [2, 1, 3, 8]
