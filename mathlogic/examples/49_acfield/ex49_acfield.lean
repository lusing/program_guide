/- ex49_acfield.lean —— 代数闭域：量词消去与范畴性（Marker GTM 217 §3.2）
    与 Coq 侧同构：F₄/F₁₆ 显式算术、加根塔、构造集塌缩、acl 现场账。 -/

/-- 位向量（低位在前）→ nat -/
def bits (k x : Nat) : List Nat :=
  (List.range k).map fun i => x / 2 ^ i % 2

def unbits : List Nat → Nat
  | [] => 0
  | b :: t => b % 2 + 2 * unbits t

/-- 特征 2 多项式加法=异或 -/
def padd : List Nat → List Nat → List Nat
  | [], l => l.map (· % 2)
  | l, [] => l.map (· % 2)
  | x :: t1, y :: t2 => (x + y) % 2 :: padd t1 t2

/-- 多项式卷积（移位累加） -/
def conv : List Nat → List Nat → List Nat
  | [], _ => []
  | x :: t, b => padd (b.map fun y => x * y) (0 :: conv t b)

/-- 折减（燃料版）：长度 > k 时最高位 c·t^n ↦ c·tbl·t^{n-k} -/
def reducePolyF : Nat → Nat → List Nat → List Nat → List Nat
  | 0, _, _, l => l.map (· % 2)
  | f + 1, k, tbl, l =>
      if l.length ≤ k then l.map (· % 2)
      else
        let n := l.length - 1
        let c := l.getD n 0
        let front := l.take n
        let shifted := (List.replicate (n - k) 0) ++ (tbl.map fun x => x * c)
        reducePolyF f k tbl (padd front shifted)

def reducePoly (k : Nat) (tbl : List Nat) (l : List Nat) : List Nat :=
  reducePolyF l.length k tbl l

def f4Add (x y : Nat) : Nat := unbits (padd (bits 2 x) (bits 2 y))
def f4Mul (x y : Nat) : Nat :=
  unbits (reducePoly 2 [1, 1] (conv (bits 2 x) (bits 2 y)))
def f16Add (x y : Nat) : Nat := unbits (padd (bits 4 x) (bits 4 y))
def f16Mul (x y : Nat) : Nat :=
  unbits (reducePoly 4 [1, 1, 0, 0] (conv (bits 4 x) (bits 4 y)))

def f16Dom : List Nat := List.range 16

def cart (as bs : List Nat) : List (Nat × Nat) :=
  as.flatMap fun a => bs.map fun b => (a, b)

def sameSet (a b : List Nat) : Bool := a.all (· ∈ b) && b.all (· ∈ a)

/-- 域公理抽样账 -/
example : f16Dom.all fun x => f16Dom.all fun y =>
    (!(f16Mul x y == 0) || x == 0 || y == 0) = true := by native_decide

example : f16Dom.all fun x => f16Dom.all fun y =>
    (f16Mul x y == f16Mul y x) = true := by native_decide

example : f16Dom.all fun x => (f16Mul x 1 == x) = true := by native_decide

/-- 每个非零元有逆 -/
def inv16 (x : Nat) : Nat :=
  match f16Dom.find? fun y => f16Mul x y == 1 with
  | some y => y | none => 0

example : f16Dom.all fun x => (x == 0 || f16Mul x (inv16 x) == 1) = true := by
  native_decide

/-- GF(2^k) 上的 Horner 求值（系数=域元素） -/
def evalGF (mul add : Nat → Nat → Nat) : List Nat → Nat → Nat
  | [], _ => 0
  | c :: t, x => add (mul x (evalGF mul add t x)) c

/-- x²+x+1 在 F₂ 无根、在 F₄ 有根 t=2 -/
example : [0, 1].all fun x => (!(evalGF f4Mul f4Add [1,1,1] x == 0)) = true := by
  native_decide
example : (evalGF f4Mul f4Add [1,1,1] 2 == 0) = true := by native_decide

/-- F₁₆ 的模多项式 s⁴+s+1 在 F₂ 无根 -/
example : [0, 1].all fun x => (!(evalGF f16Mul f16Add [1,1,0,0,1] x == 0)) = true := by
  native_decide

/-- F₁₆ 内寻得 F₄ 拷贝：α=s²+s 满足 α²+α+1=0 -/
def alpha : Nat := f16Add (f16Mul 2 2) 2

example : (evalGF f16Mul f16Add [1,1,1] alpha == 0) = true := by native_decide

def f4copy : List Nat := [0, 1, alpha, f16Add alpha 1]

example : (cart f4copy f4copy).all fun p =>
    f4copy.contains (f16Mul p.1 p.2) = true := by native_decide

/-- 根数账：x³+1=(x+1)(x²+x+1) 在 F₁₆ 完全分裂 -/
def roots16 (p : List Nat) : List Nat :=
  f16Dom.filter fun x => evalGF f16Mul f16Add p x == 0

example : sameSet (roots16 [1,0,0,1]) [1, alpha, f16Add alpha 1] = true := by
  native_decide

/-- F₃ 线上构造集塌缩：全部 27 个 ≤2 次多项式零点集去重=8 个子集 -/
def evalF3 : List Nat → Nat → Nat
  | [], _ => 0
  | c :: t, x => (x % 3 * evalF3 t x + c) % 3

def vf3 (p : List Nat) : List Nat :=
  [0,1,2].filter fun x => evalF3 p x == 0

def allPolys3 : List (List Nat) :=
  [0,1,2].flatMap fun c0 => [0,1,2].flatMap fun c1 => [0,1,2].map fun c2 => [c0,c1,c2]

def dedupBy (l : List (List Nat)) : List (List Nat) :=
  l.foldl (fun acc s => if acc.any fun t => t == s then acc else acc ++ [s]) []

example : (dedupBy (allPolys3.map vf3)).length = 8 := by native_decide

/-- 子域闭包 acl16 -/
def closeStep (s : List Nat) : List Nat :=
  (cart s s).foldl (fun acc p =>
    [f16Add p.1 p.2, f16Mul p.1 p.2, inv16 p.1].foldl
      (fun acc2 e => if acc2.contains e then acc2 else acc2 ++ [e]) acc) s

def closeTo : Nat → List Nat → List Nat
  | 0, s => s
  | f + 1, s =>
      let s' := closeStep s
      if s'.length == s.length then s' else closeTo f s'

def acl16 (A : List Nat) : List Nat := closeTo 8 ((0 :: 1 :: A).eraseDups)

/-- 三层塔的 acl 账 -/
example : (sameSet (acl16 []) [0,1] && sameSet (acl16 [alpha]) f4copy
    && sameSet (acl16 [2]) f16Dom) = true := by
  native_decide

/-- 6'. 交换律的有限域现场：失败、修复与成立区 -/
example : ((acl16 [2]).contains alpha && !((acl16 [alpha]).contains 2)) = true := by
  native_decide

/-- 修复侧：s 是 F₄ 上多项式 X²+X+α 的根 -/
example : (evalGF f16Mul f16Add [alpha,1,1] 2 == 0) = true := by native_decide

def exchangeCheck (A : List Nat) (a b : Nat) : Bool :=
  !((acl16 (a :: A)).contains b && !((acl16 A).contains b))
    || (acl16 (b :: A)).contains a

def inFailZone (A : List Nat) (a b : Nat) : Bool :=
  A.isEmpty && ([alpha, f16Add alpha 1].contains b)
    && !(f4copy.contains a)

def exchCases : List (List Nat × (Nat × Nat)) :=
  [[], [alpha]].flatMap fun A => (cart f16Dom f16Dom).map fun p => (A, p)

example : exchCases.all fun c =>
    (inFailZone c.1 c.2.1 c.2.2 || exchangeCheck c.1 c.2.1 c.2.2) = true := by
  native_decide
