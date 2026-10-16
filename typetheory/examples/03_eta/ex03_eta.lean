/- ============================================================
   03 η、βη 与 λI —— Lean 主实现
   η-步进（occurs 检查 + 出绑定器平移）+ βη 两阶段规范化
   + λI 谓词 + 自由变量持存（K 不可定义的机器面）
   依 Hindley BSTT 1C–1D（η/βη；受限 λ-项）
   ============================================================ -

术语约定：本章沿用 02 章的 de Bruijn 项与 β 机器（文件自包含，
直接复制），在其上新增 η 层与 λI 谓词层。
-/

/-- 无类型 λ 项（de Bruijn）：与 02 章同一表示 -/
inductive Term where
  | var : Nat → Term
  | lam : Term → Term
  | app : Term → Term → Term
deriving Repr, BEq

namespace Term

/-- 平移：指标 ≥ c 的自由变量加 d -/
def shift (d : Int) (c : Nat) : Term → Term
  | var k => if c ≤ k then var (Int.toNat (Int.ofNat k + d)) else var k
  | lam b => lam (shift d (c + 1) b)
  | app f a => app (shift d c f) (shift d c a)

/-- 代换 [j := s]t -/
def subst (j : Nat) (s : Term) : Term → Term
  | var k => if k = j then s else var k
  | lam b => lam (subst (j + 1) (shift 1 0 s) b)
  | app f a => app (subst j s f) (subst j s a)

/-- β 单步：最左最外（normal order） -/
def step : Term → Option Term
  | app (lam b) a => some (shift (-1) 0 (subst 0 (shift 1 0 a) b))
  | app f a =>
      match step f with
      | some f' => some (app f' a)
      | none => (step a).map (fun a' => app f a')
  | lam b => (step b).map lam
  | var _ => none

/-- β 规范化（带燃料） -/
def nfBeta : Nat → Term → Term
  | 0, t => t
  | n + 1, t => match step t with
    | none => t
    | some t' => nfBeta n t'

/-! ## η 层（Hindley 1C1）

η-redex：`λx. M x`，其中 **x 不在 M 中自由出现**（外延性：
「原样转发参数的函数」就是 M 本身）。de Bruijn 形态
`lam (app t (var 0))` 配 occurs 检查 `¬ occurs 0 t`。 -/

/-- 指标 k 是否在 t 中（自由）出现；进绑定器时查询目标 +1 补偿深度 -/
def occurs (k : Nat) : Term → Bool
  | var j => decide (j = k)
  | lam b => occurs (k + 1) b
  | app f a => occurs k f || occurs k a

/-- η 单步（最左最外）。

    陷阱实录：contractum **不是** `t` 而是 `shift (-1) 0 t`——
    η 的条件只保证 0 不出现，t 的其余自由指标全体 ≥ 1（被 λ 抬高过），
    出绑定器后必须全体降 1。漏掉这个 shift，`(λx. f x)` 会缩成
    自由指标 1 而不是 0（正字面上把 f 认成了别的变量）。 -/
def etaStep : Term → Option Term
  | lam (app t (var 0)) =>
      if occurs 0 t then (etaStep (app t (var 0))).map lam
      else some (shift (-1) 0 t)
  | lam b => (etaStep b).map lam
  | app f a =>
      match etaStep f with
      | some f' => some (app f' a)
      | none => (etaStep a).map (fun a' => app f a')
  | var _ => none

/-- η 规范化（带燃料；由 |P| 每步减 2 知真实链长 < |P|/2，Hindley 1C2） -/
def nfEta : Nat → Term → Term
  | 0, t => t
  | n + 1, t => match etaStep t with
    | none => t
    | some t' => nfEta n t'

/-- βη 两阶段规范化（Hindley 1C9.5 的策略）：先把 β 缩到头，再缩 η。
    由 1C6（η-后置）与 1C9.4（β-nf 存在 ⟺ βη-nf 存在）保证这就是 βη-范式。 -/
def nfBetaEta (fuel : Nat) (t : Term) : Term := nfEta fuel (nfBeta fuel t)

/-- η 链长（燃料内） -/
def etaSteps (fuel : Nat) (t : Term) : Nat :=
  go fuel t 0
where
  go : Nat → Term → Nat → Nat
    | 0, _, k => k
    | n + 1, t, k => match etaStep t with
      | none => k
      | some t' => go n t' (k + 1)

/-- 项的大小（结点数；η 每步恰减 2，度量 1C2 的基数） -/
def size : Term → Nat
  | var _ => 1
  | lam b => 1 + size b
  | app f a => 1 + size f + size a

/-! ## λI 层（Hindley 1D1）

λI-项：**每个 λ 的绑定变量都在体内出现至少一次**——Church 1941
原版限制（无范式的项「无意义」，有意义项的子项不许藏着无意义）。
无此限制的通常项叫 λK-项（1D1.2）。 -/

/-- λI 谓词 -/
def isLI : Term → Bool
  | var _ => true
  | lam b => occurs 0 b && isLI b
  | app f a => isLI f && isLI a

end Term

open Term

/- ---------- 名角（与 02 章同一批组合子） ---------- -/

def I : Term := lam (var 0)
def K : Term := lam (lam (var 1))                       -- λx y. x
def S : Term :=
  lam (lam (lam (app (app (var 2) (var 0)) (app (var 1) (var 0)))))
def omega : Term := lam (app (var 0) (var 0))           -- λx. x x（注意：它是 λI！）

def cnum (n : Nat) : Term := lam (lam (iter n (var 1) (var 0)))
where
  iter : Nat → Term → Term → Term
    | 0, _, z => z
    | m + 1, s, z => app s (iter m s z)

/- ---------- 实测一：η 基本功 ---------- -/

-- λx. f x  →η  f（f 自由指标 0：contractum 做 shift(-1)，见 etaStep 注释）
example : etaStep (lam (app (var 1) (var 0))) = some (var 0) := by rfl

-- ω = λx. x x **不是** η-redex（x 在 M = x 中出现），且内部无其他 η 位
example : etaStep omega = none := by rfl

-- λI 谓词初筛：K 死于「y 空绑定」，S/I/ω 全过，Church 数 n≥1 过而 0 死
example : isLI K = false := by rfl
example : isLI S = true := by rfl
example : isLI omega = true := by rfl
example : isLI (cnum 3) = true := by rfl
example : isLI (cnum 0) = false := by rfl   -- λf x. x：f 空绑定

/- ---------- 实测二：β/η 两条路在 F 汇合（CR 缩影 + 后置实例） ---------- -/

/-- F = λy. f y（f 自由，指标 0） -/
def F : Term := lam (app (var 1) (var 0))

/-- N2 = λx. (λy. f y) x —— 把 F 上移一层再应用绑定变量 x -/
def N2 : Term := lam (app (shift 1 0 F) (var 0))

-- η 先行：整个 λx.(…)x 是 η-redex（x 不在内部出现），一步缩回 F
example : etaStep N2 = some F := by rfl

-- β 先行：缩掉体内的 (λy.f y) x，得到的恰是同一个 F
-- —— 两种第一步殊途同归；再各缩一步 η 都到 f（1C6 后置定理的活样本）
example : step N2 = some F := by rfl
example : etaStep F = some (var 0) := by rfl

-- 两阶段策略：N2 →β* F →η* f
example : nfBetaEta 50 N2 = var 0 := by rfl
example : nfBetaEta 50 (lam (app I (var 0))) = I := by rfl

-- 度量核对：η 链长 2 ≤ |N2|/2（1C2 的实例账）
example : etaSteps 50 N2 = 2 := by rfl
example : size N2 = 7 := by rfl

/- ---------- 实测三：λI 的「不消元」与 λK 的消元 ---------- -/

-- λI 的 β：绑定变量至少出现一次 ⟹ 实参只会被复制、永不消失。
-- t = (λx. x x) a：a 出现 2 次，缩完仍在（且翻倍）
def selfApp : Term := app (lam (app (var 0) (var 0))) (var 1)
example : step selfApp = some (app (var 1) (var 1)) := by rfl
example : occurs 1 selfApp = true := by rfl
example : occurs 1 (app (var 1) (var 1)) = true := by rfl

-- 对照组（λK，非 λI）：λx y. y 把实参整个吞掉——「消元」
def swallow : Term := app (lam (lam (var 0))) (var 3)
example : step swallow = some (lam (var 0)) := by rfl
example : occurs 3 swallow = true := by rfl
example : occurs 3 (lam (var 0)) = false := by rfl
example : isLI (lam (lam (var 0))) = false := by rfl

/- ---------- 实测四：λI 对 βη 封闭（1D4 的实例账） ---------- -/

-- S I I 是 λI；缩到底得 ω = λx. x x，仍是 λI
example : isLI (app (app S I) I) = true := by rfl
example : nfBetaEta 100 (app (app S I) I) = omega := by rfl
example : isLI (nfBetaEta 100 (app (app S I) I)) = true := by rfl

#eval etaSteps 100 (lam (app I (var 0)))  -- 1：λx. I x →η I（I 已是 η-nf）
