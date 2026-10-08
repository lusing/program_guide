/- ex45 —— Hilbert 第十问题（Marker ch14）Lean 镜像
   Pell ⊗ 恒等式（Int 展开）+解序列+闭包组合子+X/Y 序列。 -/

set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

-- ---------- 1. Diophantine 解与闭包组合子 ----------

def sols2 (p : Int → Int → Int) (b1 b2 : Nat) : List (Int × Int) :=
  let pts := (List.range b1).flatMap (fun i =>
    (List.range b2).map (fun j => (Int.ofNat i, Int.ofNat j)))
  pts.filter (fun xy => p xy.1 xy.2 == 0)

def conjPoly (p q : Int → Int → Int) (x y : Int) : Int :=
  p x y * p x y + q x y * q x y

def disjPoly (p q : Int → Int → Int) (x y : Int) : Int := p x y * q x y

-- 合取：p₁²+p₂²=0 恰挑出交集 {(2,3)}
example : ((sols2 (conjPoly (fun x _ => x - 2) (fun _ y => y - 3)) 6 6).length == 1)
    = true := by native_decide

-- 析取：p₁·p₂=0 给 6+6−1=11 个解
example : ((sols2 (disjPoly (fun x _ => x - 2) (fun _ y => y - 3)) 6 6).length == 11)
    = true := by native_decide

-- ---------- 2. Pell ⊗ 群法则（Int 展开） ----------

theorem pellOtIdentity : ∀ d x y u v : Int,
    (x * x - d * y * y) * (u * u - d * v * v)
      = (x * u + d * y * v) * (x * u + d * y * v)
        - d * (x * v + y * u) * (x * v + y * u) := by
  intro d x y u v
  simp only [Int.mul_add, Int.add_mul, Int.mul_sub, Int.sub_mul,
             Int.mul_assoc, Int.mul_comm, Int.mul_left_comm]
       <;> omega

def pellOt (d : Nat) (xy uv : Int × Int) : Int × Int :=
  (xy.1 * uv.1 + Int.ofNat d * xy.2 * uv.2,
   xy.1 * uv.2 + xy.2 * uv.1)

def pellPow (d : Nat) (base : Int × Int) : Nat → Int × Int
  | 0 => (1, 0)
  | n+1 => pellOt d base (pellPow d base n)

-- d=2 前 6 个解逐项满足 x²−2y²=1
example : (List.range 5).all (fun k =>
    let s := pellPow 2 (3,2) (k+1)
    s.1 * s.1 - 2 * s.2 * s.2 == 1) = true := by native_decide

#eval (List.range 5).map (fun k => pellPow 2 (3,2) (k+1))
-- [(3,2),(17,12),(99,70),(577,408),(3363,2378)]

-- ---------- 3. Fibonacci 与 X/Y 序列 ----------

def fib : Nat → Nat
  | 0 => 0
  | 1 => 1
  | n+2 => fib (n+1) + fib n

-- Cassini n=1..14 逐项验证（一般归纳记文档线）
example : (List.range 14).all (fun k =>
    let n := k + 1
    let lhs := fib (n+1) * fib (n-1)
    let r := fib n * fib n
    if n % 2 == 0 then lhs == r + 1 else r == lhs + 1) = true := by
  native_decide

def iter2 (cur prev k : Nat) : Nat :=
  match k with
  | 0 => cur
  | k'+1 => iter2 (2 * cur + prev) cur k'

def Xseq (n : Nat) : Nat := iter2 1 1 n
def Yseq (n : Nat) : Nat := iter2 1 0 n

-- X²−2Y² = ±1 交替（n=0..7）
def iabs (z : Int) : Int := if z < 0 then -z else z

example : ((List.range 8).all (fun n =>
    iabs (Int.ofNat (Xseq n) * Int.ofNat (Xseq n)
          - 2 * Int.ofNat (Yseq n) * Int.ofNat (Yseq n)) == 1))
    = true := by native_decide

#eval ((List.range 7).map Xseq, (List.range 7).map Yseq)
-- X: 1,3,7,17,41,99,239；Y: 1,2,5,12,29,70,169
