/- ex29 —— 实闭域与 o-minimality（Marker ch8）Lean 镜像
   Motzkin 两条账本（对角 Gram 表示+SOS 分解——系数表反射验证，
   不依赖 ring）；定点版 IVT 二分；符号表与 o-minimal 有限影子。 -/

set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

-- ---------- 1. Motzkin：系数表反射 ----------

/-- 多项式 = ((x 次数, y 次数), 系数) 表，指数严格递增；padd/pmul 后过滤零系数 -/
abbrev Poly := List ((Nat × Nat) × Int)

def pinsert (m : (Nat × Nat) × Int) : Poly → Poly
  | [] => [m]
  | (e, c) :: t =>
      if m.1.1 < e.1 || (m.1.1 == e.1 && m.1.2 < e.2) then m :: (e, c) :: t
      else if m.1 = e then (e, c + m.2) :: t
      else (e, c) :: pinsert m t

def pinsAll : Poly → Poly → Poly
  | [], acc => acc
  | m :: t, acc => pinsAll t (pinsert m acc)

def pnorm (l : Poly) : Poly := (l.filter (fun p => p.2 != 0))

def padd (a b : Poly) : Poly := pnorm (pinsAll a (pinsAll b []))

def pmul (a b : Poly) : Poly :=
  pnorm (pinsAll (a.flatMap (fun p => b.map (fun q =>
    ((p.1.1 + q.1.1, p.1.2 + q.1.2), p.2 * q.2)))) [])

def psq (p : Poly) : Poly := pmul p p

def pm1 : Poly := [((0,0), 1), ((2,2), -3), ((2,4), 1), ((4,2), 1)]
def pden : Poly := [((0,0), 1), ((2,2), 1)]
def p1 : Poly := [((1,2), -1), ((3,2), 1)]   -- x³y² − xy²
def p2 : Poly := [((2,1), -1), ((2,3), 1)]   -- x²y³ − x²y
def p3 : Poly := [((0,0), -1), ((2,2), 1)]   -- x²y² − 1

-- 账本②：M·(x²y²+1) = p1²+p2²+p3²（Hilbert 17 的正现场）
example : ((pmul pm1 pden) == (padd (psq p1) (padd (psq p2) (psq p3))))
    = true := by native_decide

-- 数值抽查：M 在网格上非负
def mxv (x y : Int) : Int := x*x*x*x*y*y + x*x*y*y*y*y - 3*x*x*y*y + 1
example : ((List.range 12).all (fun x =>
    (List.range 12).all (fun y => 0 ≤ mxv x y)) : Bool) = true := by
  native_decide

-- 账本①：半格对角表示 M = (x²y)²+(xy²)²−3(xy)²+1（数值恒等面；
-- 「交叉项被强制为零」的线性论证见 docs/36-realclosed.md §二）
def diagEq (x y : Int) : Bool :=
  mxv x y == (x*x*y)*(x*x*y) + (x*y*y)*(x*y*y) - 3*(x*y)*(x*y) + 1

example : (List.range 12).all (fun x : Nat =>
    (List.range 12).all (fun y : Nat => diagEq (Int.ofNat x) (Int.ofNat y)))
    = true := by native_decide



-- ---------- 2. 定点 IVT：2^20 尺度上二分夹逼 √2 ----------

def bd : Int := 1048576        -- 2^20
def fqs (k : Int) : Int := k * k - 2 * bd * bd

def bisectI : Int → Int → Nat → (Int × Int)
  | _, _, 0 => (0, 0)
  | a, b, n+1 =>
      if n + 1 = 1 then (a, b)
      else
        let m := (a + b) / 2
        if fqs m * fqs a ≤ 0 then bisectI a m n else bisectI m b n

example : (let r := bisectI bd (2*bd) 21
    (7*bd)/5 ≤ r.1 && r.1 ≤ r.2 && r.2 ≤ (17*bd)/12
    && fqs r.1 ≤ 0 && 0 ≤ fqs r.2 : Bool) = true := by
  native_decide

#eval (bisectI 1048576 2097152 21).1 * 1000000 / 1048576  -- ≈ 1414213

-- ---------- 3. 符号表与 o-minimal 有限影子 ----------

def f5 (x : Int) : Int := x*x - 6*x + 5   -- (x-1)(x-5)

def zsign (z : Int) : Int := if z > 0 then 1 else if z < 0 then -1 else 0

example : ((List.range 10).map (fun x => zsign (f5 (Int.ofNat x)))) =
    [1, 0, -1, -1, -1, 0, 1, 1, 1, 1] := by native_decide

-- {x : f5 < 0} 在网格上是连续段 {2,3,4}（负 ⟺ 符号 = −1）
example : (List.range 10).map (fun x => zsign (f5 (Int.ofNat x)) == -1)
    = [false, false, true, true, true, false, false, false, false, false] := by
  native_decide

inductive Oat : Type
  | olt (k : Nat)
  | oeq (k : Nat)

def oeval : Oat → Nat → Bool
  | .olt k, x => x < k
  | .oeq k, x => x == k

def odef (as_ : List Oat) (x : Nat) : Bool := as_.all (fun a => oeval a x)

def stripF : List Bool → List Bool
  | false :: t => stripF t
  | l => l

def tailF : List Bool → Bool
  | [] => true
  | true :: t => tailF t
  | false :: t => t.all (fun b => !b)

def isOneRun (l : List Bool) : Bool := tailF (stripF l)

def subsets : List Oat → List (List Oat)
  | [] => [[]]
  | a :: t => subsets t ++ (subsets t).map (fun l => a :: l)

def atomPool : List Oat := [.olt 3, .olt 5, .oeq 2, .oeq 4]

example : (subsets atomPool).all (fun as_ =>
    isOneRun ((List.range 8).map (odef as_))) = true := by native_decide

def Pwild (x : Nat) : Bool := x % 2 == 1

example : !isOneRun ((List.range 8).map Pwild) = true := by native_decide
