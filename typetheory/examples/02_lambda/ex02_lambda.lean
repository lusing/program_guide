/- ============================================================
   02 无类型 λ 演算 —— Lean 主实现
   de Bruijn 项 + 代换/平移 + 左外 β-归约 normalizer
   + Church 编码实测（加/乘/乘幂）+ SKK = I + Ω 不终止
   依 Hindley ch.1 / TTAFP ch.1；de Bruijn 技法依 TAPL ch.6
   ============================================================ -/

/-- 无类型 λ 项：变量用 de Bruijn 指标（离最近绑定器的层数） -/
inductive Term where
  | var : Nat → Term
  | lam : Term → Term
  | app : Term → Term → Term
deriving Repr, BEq

namespace Term

/-- 平移：把指标 ≥ c 的自由变量加 d（可为负）。
    β-规约时把项搬进/搬出绑定器，靠它避免变量捕获。 -/
def shift (d : Int) (c : Nat) : Term → Term
  | var k =>
      if c ≤ k then var (Int.toNat (Int.ofNat k + d)) else var k
  | lam b => lam (shift d (c + 1) b)
  | app f a => app (shift d c f) (shift d c a)

/-- 代换 [j := s]t：de Bruijn 版无捕获问题——
    进入 lam 时 j+1，同时把 s 整体 shift 1。 -/
def subst (j : Nat) (s : Term) : Term → Term
  | var k => if k = j then s else var k
  | lam b => lam (subst (j + 1) (shift 1 0 s) b)
  | app f a => app (subst j s f) (subst j s a)

/-- β 单步：最左最外 redex 优先（normal order，保证若有范式必能到达） -/
def step : Term → Option Term
  | app (lam b) a =>
      -- (λ.b) a  →  b[j:=a]，先把 a shift 进去，出来再 shift 回来
      some (shift (-1) 0 (subst 0 (shift 1 0 a) b))
  | app f a =>
      match step f with
      | some f' => some (app f' a)
      | none => (step a).map (fun a' => app f a')
  | lam b => (step b).map lam
  | var _ => none

/-- 带燃料的规范化：normalizeFuel ∞ = 走到 β-范式或发散 -/
def normalizeFuel : Nat → Term → Term
  | 0, t => t
  | n + 1, t => match step t with
    | none => t
    | some t' => normalizeFuel n t'

/-- 走到范式的步数（燃料内） -/
def stepsToNf (fuel : Nat) (t : Term) : Nat :=
  go fuel t 0
where
  go : Nat → Term → Nat → Nat
    | 0, _, k => k          -- 燃料耗尽：返回已走步数
    | n + 1, t, k => match step t with
      | none => k
      | some t' => go n t' (k + 1)

end Term

open Term

/- ---------- Church 数：λf x. fⁿ x ---------- -/

/-- iter n s z = s (s (... z))：n 次 s 套在 z 外 -/
def iter (n : Nat) (s z : Term) : Term :=
  match n with
  | 0 => z
  | n + 1 => app s (iter n s z)

/-- Church 数 n：λλ. fⁿ x，f = var 1，x = var 0 -/
def cnum (n : Nat) : Term := lam (lam (iter n (var 1) (var 0)))

/-- λm n f x. m f (n f x) —— 加法（双重应用链：((m f) ((n f) x))） -/
def cplus : Term :=
  lam (lam (lam (lam (
    app (app (var 3) (var 1))
        (app (app (var 2) (var 1)) (var 0))))))

/-- λm n f. m (n f) —— 乘法 -/
def cmul : Term :=
  lam (lam (lam (app (var 2) (app (var 1) (var 0)))))

/-- λm n. n m —— 乘幂 -/
def cexp : Term := lam (lam (app (var 0) (var 1)))

/-- 把 β-长式 λλ. fⁿ x 解码回 Nat -/
def decodeCnum? : Term → Option Nat
  | lam (lam b) => go b
  | _ => none
where
  go : Term → Option Nat
    | app (var 1) (var 0) => some 1
    | app (var 1) rest => (go rest).map (· + 1)
    | _ => none

/- ---------- 实测一：Church 算术 ---------- -/

-- 2 + 3 = 5
example : decodeCnum? (normalizeFuel 200 (app (app cplus (cnum 2)) (cnum 3)))
        = some 5 := by rfl

-- 2 × 3 = 6
example : decodeCnum? (normalizeFuel 200 (app (app cmul (cnum 2)) (cnum 3)))
        = some 6 := by rfl

-- 2 ^ 3 = 8（乘幂是迭代应用，归约步数最多；实际只需几十步）
example : decodeCnum? (normalizeFuel 500 (app (app cexp (cnum 2)) (cnum 3)))
        = some 8 := by rfl

#eval decodeCnum? (normalizeFuel 2000 (app (app cexp (cnum 2)) (cnum 5)))  -- some 32
#eval stepsToNf 2000 (app (app cexp (cnum 2)) (cnum 5))                    -- 归约步数

/- ---------- 实测二：组合子 S、K —— SKK = I ---------- -/

/-- K = λx y. x：常函数 -/
def K : Term := lam (lam (var 1))
/-- S = λx y z. x z (y z) -/
def S : Term :=
  lam (lam (lam (app (app (var 2) (var 0)) (app (var 1) (var 0)))))

-- S K K 归约到恒等函数 λx. x（任何输入）
example : normalizeFuel 100 (app (app S K) K) = lam (var 0) := by rfl

-- 于是 (S K K) t ≡ t：用无类型 normalizer 直接验证组合逻辑恒等式
example : normalizeFuel 100 (app (app (app S K) K) (cnum 7)) = cnum 7 := by rfl

/- ---------- 实测三：Ω —— 无范式的项 ---------- -/

/-- ω = λx. x x：自应用。无类型 λ 演算允许它，这正是类型要管的事 -/
def omega : Term := lam (app (var 0) (var 0))
/-- Ω = ω ω：一步 β 归约后回到自身——永远归约不完 -/
def Omega : Term := app omega omega

-- 单步归约 Ω → Ω（形态不变：发散的标准例子）
example : step Omega = some Omega := by rfl

-- 燃料版停在原地；无限版永不返回——「有范式 ⟺ 最左外归约到达范式」
#eval stepsToNf 50 Omega   -- 50：燃料耗尽，每一步都还在动

/- ---------- 观察：α-等价由 de Bruijn 免费获得 ---------- -/

-- λx. x 与 λy. y 在 de Bruijn 表示下是同一个项 lam (var 0)
example : (Term.lam (Term.var 0) : Term) = Term.lam (Term.var 0) := rfl

/- ---------- 无捕获代换的经典现场：(λx. λy. x) z → λw. z ---------- -/

-- 命名视角：body λy. x 里的 x 被 z 替换。z 是自由变量（指标 0），
-- 移进 λy 时必须 shift 到 1，否则会被 λy 误「捕获」变成 λy. y。
example : step (app (lam (lam (var 1))) (var 0)) = some (lam (var 1)) := by rfl
