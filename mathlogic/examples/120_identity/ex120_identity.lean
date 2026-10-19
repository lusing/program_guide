/- ex79 —— 同一性与结构主义（Müller-Stach ch1/ch3/ch9）Lean 镜像
   Leibniz 等词↔内建 eq + Hume 原理基数分块 + ℕ 三化身（Zermolo
   用归纳树）+ Fermat 数另证（恒等式/互素/F₅ 分解 GMP 直算）+
   Z 商构造良定义 + 对偶数 d²=0。 -/

set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

/- ---------- 1. Leibniz 等值 ---------- -/

def leib (a b : Nat) : Prop := ∀ P : Nat → Prop, P a → P b

/-- Leibniz 等词 = 内建等词（零公理双向；Lean kernel 直觉语境） -/
theorem leib_eq : ∀ a b, leib a b ↔ a = b :=
  fun a b =>
    ⟨fun H => H (fun x => a = x) rfl,
     fun H P HP => H ▸ HP⟩

/- ---------- 2. Hume 原理：等数 = 存在双射 = 同基数 ---------- -/

def sub3 : List (List Nat) :=
  [[], [0], [1], [2], [0, 1], [0, 2], [1, 2], [0, 1, 2]]

def blockOf (x : List Nat) : List (List Nat) :=
  sub3.filter (fun y => y.length == x.length)

example :
    [blockOf [], blockOf [0], blockOf [0, 1], blockOf [0, 1, 2]]
    = [ [[]], [[0], [1], [2]], [[0, 1], [0, 2], [1, 2]], [[0, 1, 2]] ]
    := by native_decide

/- ---------- 3. ℕ 三化身 ---------- -/

def vn : Nat → List Nat
  | 0 => []
  | k + 1 => k :: vn k

inductive ZSet where
  | zleaf
  | znode (x : ZSet)
deriving Repr, DecidableEq

def ze : Nat → ZSet
  | 0 => .zleaf
  | k + 1 => .znode (ze k)

def zdepth : ZSet → Nat
  | .zleaf => 0
  | .znode t => zdepth t + 1

example : [vn 0, vn 1, vn 2, vn 3] = [[], [0], [1, 0], [2, 1, 0]] := by
  native_decide

example : (List.range 6).map (fun k => (vn k).length)
    = (List.range 6).map (fun k => zdepth (ze k)) := by native_decide

/- ---------- 4. Fermat 数：素数无穷另证 ---------- -/

def fermat : Nat → Nat
  | 0 => 3
  | k + 1 => let h := fermat k - 1; h * h + 1   -- (F_k−1)²+1

example : (List.range 4).map fermat = [3, 5, 17, 257] := by native_decide

example : fermat 4 == 256 * 256 + 1 := by native_decide

/-- 恒等式 F₄ = F₀·F₁·F₂·F₃ + 2 -/
example : 3 * 5 * 17 * 257 + 2 == fermat 4 := by native_decide

/-- 两两互素（10 对全查） -/
example :
    [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4),
     (2, 3), (2, 4), (3, 4)].all
      (fun p => Nat.gcd (fermat p.1) (fermat p.2) == 1) := by
  native_decide

/-- F₅ = 641·6700417（Euler 1732）——GMP 直算 43 亿 -/
example : 641 * 6700417 == 4294967297 := by native_decide

/- ---------- 5. Z 的商构造 ---------- -/

def paireq (u v : Nat × Nat) : Bool :=
  u.1 + v.2 == u.2 + v.1

example :
    [ paireq (2, 5) (7, 10)        -- 都表示 −3
    , paireq (0, 3) (5, 8)
    , !(paireq (2, 5) (0, 1)) ]    -- −3 ≠ −1
    = [true, true, true] := by native_decide

def pairmul (u v : Nat × Nat) : Nat × Nat :=
  (u.1 * v.1 + u.2 * v.2, u.1 * v.2 + u.2 * v.1)

example :
    [ paireq (pairmul (2, 5) (3, 1)) (pairmul (7, 10) (3, 1))
    , paireq (pairmul (2, 5) (3, 1)) (11, 17) ]
    = [true, true] := by native_decide

/- ---------- 6. 对偶数环 ---------- -/

def dmul (u v : Nat × Nat) : Nat × Nat :=
  (u.1 * v.1, u.1 * v.2 + u.2 * v.1)

example : dmul (0, 1) (0, 1) = (0, 0) := by native_decide

/-- (1+d)² = 1+2d —— Leibniz 乘法法则从 d²=0 机械流出 -/
example : dmul (1, 1) (1, 1) = (1, 2) := by native_decide

#eval (vn 3, ze 3, fermat 4)
