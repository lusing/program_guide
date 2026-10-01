/- ============================================================
   06 System F（λ2）：多态类型 —— Lean 实现
   类型语法 += ∀X.T；项语法 += ΛX.t 与 t[T]（类型应用）
   两套 β：项 β（03 章那套）+ 类型 β（(ΛX.b)[T] → b[X:=T]）
   交付：求值器 + 类型检查器 + Church 算术带类型复活
   + 多态恒等「一份代码两种类型」
   ============================================================ -/

inductive Ty where
  | tvar : String → Ty
  | arrow : Ty → Ty → Ty
  | all : String → Ty → Ty          -- ∀ X. T
deriving Repr, BEq

inductive Tm where
  | var : Nat → Tm                  -- 项变量：de Bruijn
  | lam : Ty → Tm → Tm              -- λ(x:T). b
  | app : Tm → Tm → Tm
  | Lam : String → Tm → Tm          -- Λ X. b（类型抽象）
  | tapp : Tm → Ty → Tm             -- t [T]（类型应用）
deriving Repr, BEq

namespace Ty
/-- 类型代换 [X := S]T。测试里 S 都是封闭类型，无捕获风险；
    过 ΛY 遮蔽层时按名停代 -/
def tsubst (x : String) (S : Ty) : Ty → Ty
  | .tvar y => if y == x then S else .tvar y
  | .arrow a b => .arrow (tsubst x S a) (tsubst x S b)
  | .all y b => if y == x then .all y b else .all y (tsubst x S b)
end Ty

namespace Tm
open Ty

/-- 项内所有类型注解都做 [X := S]（类型 β 的重命名部分） -/
def tsubstTm (x : String) (S : Ty) : Tm → Tm
  | var k => var k
  | lam T b => lam (tsubst x S T) (tsubstTm x S b)
  | app f a => app (tsubstTm x S f) (tsubstTm x S a)
  | Lam y b => if y == x then Lam y b else Lam y (tsubstTm x S b)
  | tapp t T => tapp (tsubstTm x S t) (tsubst x S T)

/-- de Bruijn 平移与代换（与 02/03 章同构；注解跟着走） -/
def shift (d : Int) (c : Nat) : Tm → Tm
  | var k => if c ≤ k then var (Int.toNat (Int.ofNat k + d)) else var k
  | lam T b => lam T (shift d (c + 1) b)
  | app f a => app (shift d c f) (shift d c a)
  | Lam x b => Lam x (shift d c b)     -- Λ 绑定【类型】变量，不占项位
  | tapp t T => tapp (shift d c t) T

def subst (j : Nat) (s : Tm) : Tm → Tm
  | var k => if k = j then s else var k
  | lam T b => lam T (subst (j + 1) (shift 1 0 s) b)
  | app f a => app (subst j s f) (subst j s a)
  | Lam x b => Lam x (subst j s b)
  | tapp t T => tapp (subst j s t) T

/-- 双 β 单步：最左最外 -/
def step : Tm → Option Tm
  | app (lam _ b) a => some (shift (-1) 0 (subst 0 (shift 1 0 a) b))
  | tapp (Lam x b) T => some (tsubstTm x T b)     -- 类型 β 无平移！
  | app f a =>
      match step f with
      | some f' => some (app f' a)
      | none => (step a).map (fun a' => app f a')
  | tapp t T => (step t).map (fun t' => tapp t' T)
  | lam T b => (step b).map (fun b' => lam T b')
  | Lam x b => (step b).map (fun b' => Lam x b')
  | _ => none

def normalizeFuel : Nat → Tm → Tm
  | 0, t => t
  | n + 1, t => match step t with
    | none => t
    | some t' => normalizeFuel n t'

end Tm

open Tm Ty

/- ---------- Church 数：这次带着 ∀ ---------- -/

def iter (n : Nat) (f x : Tm) : Tm :=
  match n with
  | 0 => x
  | n + 1 => app f (iter n f x)

/-- n : ∀X. (X→X) → X → X —— 多态的 Church 数 -/
def cnum (n : Nat) : Tm :=
  Lam "X" (lam (arrow (tvar "X") (tvar "X"))
          (lam (tvar "X") (iter n (var 1) (var 0))))

/-- 实例化后的 Church 数类型 (X→X)→X→X（X 已替换为给定类型） -/
def cnAt (S : Ty) : Ty := arrow (arrow S S) (arrow S S)

/-- 加法：ΛX. λm n f x. m f (n f x) —— 依赖 02 章的同款骨架 -/
def cplus : Tm :=
  Lam "X" (lam (cnAt (tvar "X")) (lam (cnAt (tvar "X"))
    (lam (arrow (tvar "X") (tvar "X")) (lam (tvar "X")
      (app (app (var 3) (var 1))
           (app (app (var 2) (var 1)) (var 0)))))))

/-- 乘法：ΛX. λm n f. m (n f) -/
def cmul : Tm :=
  Lam "X" (lam (cnAt (tvar "X")) (lam (cnAt (tvar "X"))
    (lam (arrow (tvar "X") (tvar "X"))
      (app (var 2) (app (var 1) (var 0))))))

/-- 乘幂：ΛX. λ(m : X→X). λ(n : C(C X)). n m —— n 在「Church 数类型」
    上迭代，把 m 复合 n 次。所以调用时 n 要实例化在 C B 上（rank-2 味） -/
def cexp : Tm :=
  Lam "X" (lam (arrow (tvar "X") (tvar "X"))
    (lam (cnAt (cnAt (tvar "X")))
      (app (var 0) (var 1))))

/-- 解码：λ(f:S→S). λ(x:S). fⁿ x 的范式里数出 n -/
def decode : Tm → Option Nat
  | lam _ (lam _ b) => go b
  | _ => none
where
  go : Tm → Option Nat
    | app (var 1) (var 0) => some 1
    | app (var 1) rest => (go rest).map (· + 1)
    | _ => none

def B := tvar "B"     -- 任意选一个「 witnesses 」类型
def INST (t : Tm) (S : Ty) : Tm := tapp t S

/- ---------- 实测一：Church 算术在类型世界里复活 ---------- -/

-- 2 + 3 = 5：注意每个 cnum 都各自实例化（值的内多态），
-- 外层运算符也实例化
def atB (t : Tm) : Tm := INST t B

example : decode (normalizeFuel 400
          (app (app (atB cplus) (atB (cnum 2))) (atB (cnum 3))))
        = some 5 := by rfl

-- 2 × 3 = 6
example : decode (normalizeFuel 400
          (app (app (atB cmul) (atB (cnum 2))) (atB (cnum 3))))
        = some 6 := by rfl

-- 2 ^ 3 = 8（n 实例化在 cnAt B 上——指数位在高阶类型上迭代）
example : decode (normalizeFuel 800
          (app (app (atB cexp) (atB (cnum 2))) (INST (cnum 3) (cnAt B))))
        = some 8 := by rfl

#eval decode (normalizeFuel 2000
      (app (app (atB cexp) (atB (cnum 2))) (INST (cnum 5) (cnAt B))))   -- some 32

/- ---------- 实测二：多态恒等「一份代码，两种类型」 ---------- -/

/-- pid = ΛX. λ(x:X). x -/
def pid : Tm := Lam "X" (lam (tvar "X") (var 0))

-- pid [B→B] : (B→B) → (B→B)，参数是 pid [B] : B→B
-- 03 章的 I I 在这里【合法】——两次实例化，同一段代码
def pidAtBB := INST pid (arrow B B)
def pidAtB := INST pid B

-- 注意：tapp 的 β 是【本语义】的规则，不是 Lean 内核的 defeq，
-- 所以断言两侧都要过 normalizeFuel 才可比
example : normalizeFuel 100 (app pidAtBB pidAtB) = normalizeFuel 100 pidAtB := by rfl

/- ---------- 类型检查器：F 的推导规则即代码 ---------- -/

/-- 类型侧合法性：T 的自由类型变元都在 Δ 里 -/
def tvOk (Δ : List String) : Ty → Bool
  | .tvar x => Δ.contains x
  | .arrow a b => tvOk Δ a && tvOk Δ b
  | .all x b => tvOk (x :: Δ) b

/-- 推导规则逐条对应 TTAFP 3.x：
    var: Γ(k) = T；λ: 检查 T 合法后扩 Γ；
    app: 函数位扣箭头；Λ: 扩类型上下文 Δ，包 ∀；
    tapp: 函数位扣 ∀X.B，返回 B[X:=S] -/
def infer (Γ : List Ty) (Δ : List String) : Tm → Option Ty
  | var k => Γ[k]?
  | lam T b =>
      if tvOk Δ T then
        (infer (T :: Γ) Δ b).map (fun bt => arrow T bt)
      else none
  | app f a =>
      match infer Γ Δ f, infer Γ Δ a with
      | some (arrow i o), some i' => if i == i' then some o else none
      | _, _ => none
  | Lam x b =>
      if Δ.contains x then none               -- 测试集保证新名新鲜
      else (infer Γ (x :: Δ) b).map (all x)
  | tapp t S =>
      if tvOk Δ S then
        match infer Γ Δ t with
        | some (.all x B) => some (tsubst x S B)
        | _ => none
      else none

/-- 封闭检查：把 B 当作全局基类型（测试约定的「见证类型」） -/
def inferClosed (t : Tm) : Option Ty := infer [] ["B"] t

/- ---------- 实测三：规则的行为 ---------- -/

-- pid : ∀X. X → X
example : inferClosed pid = some (all "X" (arrow (tvar "X") (tvar "X"))) := by rfl

-- pid [B] : B → B
example : inferClosed pidAtB = some (arrow B B) := by rfl

-- pid [B→B] (pid [B]) : B → B —— 03 章的 I I 之死在此翻案
example : inferClosed (app pidAtBB pidAtB) = some (arrow B B) := by rfl

-- cnum 3 : ∀X. (X→X)→X→X
example : inferClosed (cnum 3)
        = some (all "X" (cnAt (tvar "X"))) := by rfl

-- ω = λ(x:X). x x 仍然不可类型化（F 的 SN 保证没有 Ω 的立足点）
def omegaF : Tm := lam (tvar "X") (app (var 0) (var 0))
example : inferClosed omegaF = none := by rfl

-- 但 λ(x:∀X.X→X). x [B] (x [B] ... )？——rank-2 的微妙：
-- x : ∀X.X→X 应用于自己需要 x : Y→Z 形状，∀ 不是箭头 → none
example : inferClosed (lam (all "X" (arrow (tvar "X") (tvar "X")))
                        (app (var 0) (var 0))) = none := by rfl
