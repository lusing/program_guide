/- ============================================================
   03 简单类型 λ→（Church 式）—— Lean：类型检查器 + 求值器
   类型语法 Ty ::= β | A → B；绑定器带类型注解
   判定：infer（类型检查算法）+ normalizeFuel（求值）
   ============================================================ -/

inductive Ty where
  | base : Ty
  | arrow : Ty → Ty → Ty
deriving Repr, BEq

inductive Tm where
  | var : Nat → Tm
  | lam : Ty → Tm → Tm          -- λ(x:T). b —— Church 式注解
  | app : Tm → Tm → Tm
deriving Repr

namespace Tm

/-- de Bruijn 平移（与 02 章同构，作用于带注解的项） -/
def shift (d : Int) (c : Nat) : Tm → Tm
  | var k => if c ≤ k then var (Int.toNat (Int.ofNat k + d)) else var k
  | lam ty b => lam ty (shift d (c + 1) b)
  | app f a => app (shift d c f) (shift d c a)

/-- 代换 [j := s]t -/
def subst (j : Nat) (s : Tm) : Tm → Tm
  | var k => if k = j then s else var k
  | lam ty b => lam ty (subst (j + 1) (shift 1 0 s) b)
  | app f a => app (subst j s f) (subst j s a)

/-- β 单步：最左最外 -/
def step : Tm → Option Tm
  | app (lam _ b) a => some (shift (-1) 0 (subst 0 (shift 1 0 a) b))
  | app f a =>
      match step f with
      | some f' => some (app f' a)
      | none => (step a).map (fun a' => app f a')
  | lam ty b => (step b).map (fun b' => lam ty b')
  | var _ => none

/-- 带燃料规范化：λ→ 的元定理（SN）保证真项必停，燃料只是编译期安慰 -/
def normalizeFuel : Nat → Tm → Tm
  | 0, t => t
  | n + 1, t => match step t with
    | none => t
    | some t' => normalizeFuel n t'

end Tm

open Tm Ty

/- ---------- 类型检查：infer 是 Ty 上的可计算函数 ---------- -/

/-- 上下文 Γ = [T₀, T₁, …]，指标 k 查 ctx[k]。
    三条规则对应推 导 树 的三个构词法：
    var: Γ(k) = T ⊢ var k : T
    lam: Γ, x:T ⊢ b : U ⊢ λ(x:T). b : T → U
    app: Γ ⊢ f : T → U,  Γ ⊢ a : T ⊢ app f a : U            -/
def infer (ctx : List Ty) : Tm → Option Ty
  | var k => ctx[k]?
  | lam ty b => (infer (ty :: ctx) b).map (fun bt => arrow ty bt)
  | app f a =>
      match infer ctx f, infer ctx a with
      | some (arrow i o), some i' => if i == i' then some o else none
      | _, _ => none

def inferClosed (t : Tm) : Option Ty := infer [] t

/- ---------- 实测一：能过检的项 ---------- -/

-- 恒等 λ(x:β→β). x ：基类型函数上的恒等
example : inferClosed (lam (arrow base base) (var 0))
        = some (arrow (arrow base base) (arrow base base)) := by rfl

-- I 应用于恒等的基版本：I (λ(x:β). x) 合法（β→β 是 β 的箭头邻居）
example : inferClosed (app (lam (arrow base base) (var 0)) (lam base (var 0)))
        = some (arrow base base) := by rfl

-- 注意：I I 在 λ→ 里【不】可类型化！I : (β→β)→(β→β)，而 I 的参数
-- 只能是 β→β —— 类型对不上。自应用要等到 System F 的 ∀（06 章）
example : inferClosed (app (lam (arrow base base) (var 0)) (lam (arrow base base) (var 0)))
        = none := by rfl

/- ---------- 实测二：过不了检的项 —— ω 被类型系统拒绝 ---------- -/

-- λ(x:β). x x ：x 必须「同时是 β 和 β→?」——不可能
def omegaTm : Tm := lam base (app (var 0) (var 0))

#eval inferClosed omegaTm          -- none：无类型 λ 演算的 ω 在 λ→ 里写不出来

example : inferClosed omegaTm = none := by rfl

-- 对比 02 章：无类型里 step Ω = some Ω（能写、能跑、不停）；
-- 类型化世界：入口就拒绝。这就是「把矛盾挡在语法层」。

/- ---------- 实测三：求值 + 类型在求值中保持 ---------- -/

-- (λ(f:β→β). f) (λ(x:β). x)  →β  λ(x:β). x
example : normalizeFuel 100
      (app (lam (arrow base base) (var 0)) (lam base (var 0)))
      = lam base (var 0) := by rfl

-- K 组合子的类型与求值
def KTm : Tm := lam base (lam (arrow base base) (var 1))

example : inferClosed KTm = some (arrow base (arrow (arrow base base) base)) := by rfl

example : normalizeFuel 100
      (app (app KTm (var 0)) (lam base (var 0)))   -- K y z，y 自由
      = var 0 := by rfl

/- ---------- 观察一：λ→ 的「贫穷」：没有多态 ---------- -/

-- λ(x:β). x 只能服务基类型；想要「对一切 T 的恒等」需要 ∀，
-- 即 System F —— 06 章的主角。这里只能给每个类型手写一份：
#eval inferClosed (lam base (var 0))                -- β → β
#eval inferClosed (lam (arrow base base) (var 0))   -- (β→β) → (β→β)
#eval inferClosed (lam (arrow (arrow base base) (arrow base base)) (var 0))

/- ---------- 观察二：SN——所有良式项必归约到头 ---------- -/

-- 任取一个可类型检查的封闭项，燃料 200 内必到范式（no step）。
-- 这是 λ→ 的强规范化定理（TTAFP 3.2 / Hindley 5C）的实验面：
def stops : Tm → Bool := fun t =>
  match Tm.normalizeFuel 200 t with
  | t' => (Tm.step t').isNone

example : stops (app (app (lam base (lam (arrow base base) (var 1))) (var 0))
                     (lam base (var 0))) = true := by rfl
