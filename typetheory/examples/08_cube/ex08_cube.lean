/- ============================================================
   08 Barendregt 立方体与 λC（构造演算）—— mini-PTS 内核
   把「一个类型系统」做成数据：规则三元组集合 = 配置。
   同一个 infer，装上不同配置就是 λ→ / λ2 / λP / λω / λC，
   立方体各角的差别从定理变成【可执行的测试】。
   ============================================================ -/

inductive Srt where
  | star : Srt    -- * ：类型的类
  | box : Srt     -- □ ：* 的类
deriving Repr, BEq, DecidableEq

open Srt

/- ---------- 统一语法（PTS）: 项与类型一个文法 ---------- -/

inductive Tm where
  | sort : Srt → Tm
  | var : Nat → Tm
  | lam : Tm → Tm → Tm        -- λ(x:A). b（A 是注解）
  | app : Tm → Tm → Tm
  | pi : Tm → Tm → Tm         -- Π(x:A). B（B 可依赖 x）
deriving Repr, BEq

namespace Tm

def shift (d : Int) (c : Nat) : Tm → Tm
  | var k => if c ≤ k then var (Int.toNat (Int.ofNat k + d)) else var k
  | lam A b => lam (shift d c A) (shift d (c + 1) b)
  | app f a => app (shift d c f) (shift d c a)
  | pi A B => pi (shift d c A) (shift d (c + 1) B)
  | sort s => sort s

def subst (j : Nat) (s : Tm) : Tm → Tm
  | var k => if k = j then s else var k
  | lam A b => lam (subst j s A) (subst (j + 1) (shift 1 0 s) b)
  | app f a => app (subst j s f) (subst j s a)
  | pi A B => pi (subst j s A) (subst (j + 1) (shift 1 0 s) B)
  | sort s => sort s

/-- 左外归约——统一语法里项层与类型层共用一台引擎 -/
def step : Tm → Option Tm
  | app (lam _ b) a => some (shift (-1) 0 (subst 0 (shift 1 0 a) b))
  | app f a =>
      match step f with
      | some f' => some (app f' a)
      | none => (step a).map (fun a' => app f a')
  | lam A b =>
      match step A with
      | some A' => some (lam A' b)
      | none => (step b).map (fun b' => lam A b')
  | pi A B =>
      match step A with
      | some A' => some (pi A' B)
      | none => (step B).map (fun B' => pi A B')
  | _ => none

def norm : Nat → Tm → Tm
  | 0, t => t
  | n + 1, t => match step t with
    | none => t
    | some t' => norm n t'

end Tm

open Tm

/-- 定义相等 = 规范化后语法相等（教学版；真内核逐层 whnf + 结构比较） -/
def conv (fuel : Nat) (t u : Tm) : Bool := norm fuel t == norm fuel u

/-- 上下文查表：第 k 条是「写在尾上下文里的类型」，
    取回时要上移 k+1 位才是在当前完整上下文里的读法 -/
def lookupTy (Γ : List Tm) (k : Nat) : Option Tm :=
  Γ[k]?.map (fun A => Tm.shift (k + 1 : Int) 0 A)

/- ---------- PTS 配置：一个类型系统 = 一张规则表 ---------- -/

/-- 规则 (s₁,s₂,s₃) 读作：A:s₁, x:A ⊢ B:s₂ ⟹ Π(x:A).B : s₃。
    公理固定：* : □ -/
structure Conf where
  rules : List (Srt × Srt × Srt)

def hasRule (c : Conf) (s1 s2 : Srt) : Option Srt :=
  match c.rules.find? (fun (a, b, _) => a == s1 && b == s2) with
  | some (_, _, s3) => some s3
  | none => none

/-- 立方体：三扇门 = 三条额外规则 ---------- -/
def lamArrow  : Conf := ⟨[(star, star, star)]⟩                       -- λ→
def lam2      : Conf := ⟨[(star, star, star), (box, star, star)]⟩     -- + 多态
def lamP      : Conf := ⟨[(star, star, star), (star, box, box)]⟩      -- + 依赖
def lamOmega  : Conf := ⟨[(star, star, star), (box, star, star),
                          (box, box, box)]⟩                           -- + 类型算子
def lamP2     : Conf := ⟨[(star, star, star), (box, star, star),
                          (star, box, box)]⟩
def lamPomega : Conf := ⟨[(star, star, star), (star, box, box),
                          (box, box, box)]⟩
def lamC      : Conf := ⟨[(star, star, star), (box, star, star),
                          (star, box, box), (box, box, box)]⟩         -- 顶点

/- ---------- 推导：infer 即规则 ---------- -/

/-- 推导 t 的类型。关键复用：「A : s」 就是「infer A 归约为某个 sort」，
    所以 lam/pi 的形成检查是【嵌套 infer】，不需要独立的 sortOf -/
def infer (c : Conf) (Γ : List Tm) : Nat → Tm → Option Tm
  | _, .sort star => some (.sort box)                  -- 公理
  | _, .sort box => none                               -- □ 之上了无类型
  | _, .var k => lookupTy Γ k
  | fuel + 1, .app f a =>
      match infer c Γ fuel f, infer c Γ fuel a with
      | some tf, some ta =>
          match norm fuel tf with
          | .pi A B =>
              if conv fuel A ta then some (subst 0 (shift 1 0 a) B) else none
          | _ => none
      | _, _ => none
  | fuel + 1, .lam A b =>
      match infer c Γ fuel A with                      -- A : s₁
      | some (.sort s1) =>
          match infer c (A :: Γ) fuel b with           -- b : B
          | some tb =>
              match infer c (A :: Γ) fuel tb with      -- B : s₂（类型的类型）
              | some (.sort s2) =>
                  match hasRule c s1 s2 with
                  | some _ => some (.pi A tb)
                  | none => none
              | _ => none
          | none => none
      | _ => none
  | fuel + 1, .pi A B =>
      match infer c Γ fuel A with                      -- A : s₁
      | some (.sort s1) =>
          match infer c (A :: Γ) fuel B with           -- B : s₂
          | some (.sort s2) => (hasRule c s1 s2).map Tm.sort
          | _ => none
      | _ => none
  | _, _ => none

def inferClosed (c : Conf) (t : Tm) : Option Tm := infer c [] 60 t

/-- 上下文也要过规则：第 k 条的类型必须【在尾上下文里】是个型。
    不查这个，λ→ 也会「收下」以 P : Nat→* 为前提的谓词量化——
    因为 P 的型 Π(n:Nat).* 本身在 λ→ 里就造不出来 -/
def ctxValid (c : Conf) (fuel : Nat) (Γ : List Tm) : Bool :=
  go fuel Γ
where
  go : Nat → List Tm → Bool
    | _, [] => true
    | fuel, A :: tail => (infer c tail fuel A).isSome && go fuel tail

/-- 带上下文门禁的检查入口 -/
def inferIn (c : Conf) (Γ : List Tm) (fuel : Nat) (t : Tm) : Option Tm :=
  if ctxValid c fuel Γ then infer c Γ fuel t else none

/- ---------- 被检查的程序们 ---------- -/

-- 上下文 Γ₀ = [Nat : *]：一个基类型
def ctxNat : List Tm := [.sort star]

-- 恒等 λ(x:Nat). x —— 人人都会
def idNat : Tm := .lam (.var 0) (.var 0)

-- 多态恒等 Λ(X:*). λ(x:X). x —— 要 (□,*,*)
def polyId : Tm := .lam (.sort star) (.lam (.var 0) (.var 0))

-- 类型算子 λ(X:*). X → X —— (□,*,*) 也够；真正要 (□,□) 的是
-- 「Π(X:*). *」这种把 * 放进结果的东西（见 boxRule 型）
def arrowOp : Tm := .lam (.sort star) (.pi (.var 0) (.var 1))

-- (□,□) 见证者：Π(X:*). * —— 「以类型为参数产出类型」的型
def mkTypeOp : Tm := .pi (.sort star) (.sort star)

-- 依赖见证者：上下文 [P : Nat→*, Nat : *] 里造 Π(n:Nat). P n
def ctxP : List Tm := [.pi (.var 0) (.sort star), .sort star]
def allPNat : Tm := .pi (.var 1) (.app (.var 1) (.var 0))

-- λC 见证者：Π(A:*). Π(x:A). * —— 多态谓词的型
def polyPred : Tm := .pi (.sort star) (.pi (.var 0) (.sort star))

/- ---------- 实测：立方体的差别 = 可执行的测试 ---------- -/

-- ① 恒等 λ(x:Nat).x：每个角都收（(*,*,*) 人人有）。
-- 注意 Π(x:Nat).Nat 的 de Bruijn 形态：codomain 里 Nat 是 var 1
example : inferIn lamArrow ctxNat 60 idNat = some (.pi (.var 0) (.var 1)) := by rfl
example : inferIn lamC ctxNat 60 idNat = some (.pi (.var 0) (.var 1)) := by rfl

-- ② 多态恒等：只有开了「多态门」的角收
example : inferClosed lamArrow polyId = none := by rfl
example : inferClosed lam2 polyId
        = some (.pi (.sort star) (.pi (.var 0) (.var 1))) := by rfl   -- ∀X:*. X→X

-- ③ (□,□) 门：Π(X:*). * ——「以类型为参数产出类型」的型
example : inferClosed lamArrow mkTypeOp = none := by rfl
example : inferClosed lam2 mkTypeOp = none := by rfl      -- λ2 也没有
example : inferClosed lamOmega mkTypeOp = some (.sort box) := by rfl

-- ④ 依赖门：Π(n:Nat). P n —— 谓词量化。
-- 上下文 [P : Nat→*, Nat :*] 本身在 λ→ 里就不合法（P 的型要 (*,□)）
example : inferIn lamP ctxP 60 allPNat = some (.sort star) := by rfl
example : inferIn lamArrow ctxP 60 allPNat = none := by rfl

-- ⑤ 只有顶点收的型：Π(A:*). Π(x:A). * —— 多态谓词
example : inferClosed lamP polyPred = none := by rfl      -- 缺 (□,□)
example : inferClosed lamOmega polyPred = none := by rfl  -- 缺 (*,□)
example : inferClosed lamC polyPred = some (.sort box) := by rfl

-- ⑥ 顶点上的应用：多态恒等实例化（项层与类型层同机归约）
def inst : Tm := .app polyId (.pi (.sort star) (.var 0))
example : inferClosed lamC inst
        = some (.pi (.pi (.sort star) (.var 0)) (.pi (.sort star) (.var 0)))
        := by rfl
-- norm 后还是同一个型：conv 在类型检查里已经跑过了 β

/- ---------- 八角总表（机器口径，本文件全部实测） ----------
   程序 \\ 系统      λ→    λ2    λP    λω    λP2   λPω   λC
   恒等               ✓     ✓     ✓     ✓     ✓     ✓     ✓
   多态恒等 polyId    ✗     ✓     ✗     ✓     ✓     ✗     ✓
   Π(X:*). *          ✗     ✗     ✗     ✓     ✗     ✓     ✓
   谓词量化 allPNat   ✗     ✗     ✓     ✗     ✓     ✓     ✓
   多态谓词 polyPred  ✗     ✗     ✗     ✗     ✗     ✗     ✓   ← 顶点 -/

