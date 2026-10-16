/- ============================================================
   23 λD 形式系统 —— Lean 主场（TTAFP ch.8–10）
     mini-λD0/λD：λC + 定义环境 Δ
       · 定义做成数据：Def = 参数望远镜 + 缺省体 + 类型；
         原始定义（def-prim）= 无体的 ⊥⊥ 占位
       · (def) 规则 = 环境里每条定义的良构性检查
       · (inst) 规则 = 常数完全应用：实参逐个替换进类型——
         多参数按【逆参数序】连续替换（最内层参数在 index 0）
       · δ-归约 = 完全应用的常数原地展开；βδ-范式 = 转换规则
         引擎——plus two three 与 five 的范式 rfl 相等
       · 原始定义不 δ-展开：ET 公理化后范式保持自身（连 21 章）
   ============================================================ -/

inductive Srt where
  | star | box
deriving Repr, BEq, DecidableEq

open Srt

inductive Tm where
  | sort : Srt → Tm
  | var : Nat → Tm
  | lam : Tm → Tm → Tm          -- λ(x:A). b
  | app : Tm → Tm → Tm
  | pi : Tm → Tm → Tm           -- Π(x:A). B
  | cst : String → List Tm → Tm -- 常数 a(U1,...,Un)（带实参表）
deriving Repr, BEq

namespace Tm

def shift (d : Int) (c : Nat) : Tm → Tm
  | var k => if c ≤ k then var (Int.toNat (Int.ofNat k + d)) else var k
  | lam A b => lam (shift d c A) (shift d (c + 1) b)
  | app f a => app (shift d c f) (shift d c a)
  | pi A B => pi (shift d c A) (shift d (c + 1) B)
  | sort s => sort s
  | cst n us => cst n (us.map (shift d c))

def subst (j : Nat) (s : Tm) : Tm → Tm
  | var k =>
      if k = j then s
      else if k > j then var (k - 1)   -- 越过被替换者：降位
      else var k
  | lam A b => lam (subst j s A) (subst (j + 1) (shift 1 0 s) b)
  | app f a => app (subst j s f) (subst j s a)
  | pi A B => pi (subst j s A) (subst (j + 1) (shift 1 0 s) B)
  | sort s => sort s
  | cst n us => cst n (us.map (subst j s))

end Tm

open Tm

/- ---------- 定义环境 Δ ----------
   d nm params body? ty：params / body / ty 都以参数望远镜为
   前导语境做 de Bruijn（书的 FV 引理 10.4.3：体与类型只引用参数；
   最内层参数 = index 0）。body = none ⇔ 原始定义（⊥⊥ 占位）。-/

structure Def where
  nm : String
  params : List Tm
  body : Option Tm
  ty : Tm

abbrev Delta := List Def

def lookupDef (Δ : Delta) (c : String) : Option Def :=
  Δ.find? (fun d => d.nm == c)

/-- 实例化：按逆参数序连续 subst 0（替换后其余参数自动降位）-/

def instantiate (t : Tm) (us : List Tm) : Tm :=
  us.reverse.foldl (fun acc u => subst 0 u acc) t

/- ---------- βδ-归约（δ 只对完全应用的描述式常数开火） ---------- -/

def unfoldCst (Δ : Delta) (n : String) (us : List Tm) : Option Tm := do
  let d ← lookupDef Δ n
  guard (d.params.length == us.length)
  let b ← d.body            -- 原始定义（none）不展开
  return instantiate b us

mutual

def stepFirstArg (Δ : Delta) : List Tm → Option (List Tm)
  | [] => none
  | u :: rest =>
      match step Δ u with
      | some u' => some (u' :: rest)
      | none => (stepFirstArg Δ rest).map (fun r => u :: r)

def step (Δ : Delta) : Tm → Option Tm
  | app (lam _ b) a => some (subst 0 a b)
  | cst n us =>
      match unfoldCst Δ n us with
      | some r => some r
      | none => (stepFirstArg Δ us).map (cst n)
  | app f a =>
      match step Δ f with
      | some f' => some (app f' a)
      | none => (step Δ a).map (app f)
  | lam A b =>
      match step Δ A with
      | some A' => some (lam A' b)
      | none => (step Δ b).map (fun b' => lam A b')
  | pi A B =>
      match step Δ A with
      | some A' => some (pi A' B)
      | none => (step Δ B).map (fun B' => pi A B')
  | _ => none

end

def norm (Δ : Delta) : Nat → Tm → Tm
  | 0, t => t
  | n + 1, t => match step Δ t with
    | none => t
    | some t' => norm Δ n t'

def bdNf (Δ : Delta) (t : Tm) : Tm := norm Δ 200 t

def beq (Δ : Delta) (a b : Tm) : Bool := bdNf Δ a == bdNf Δ b

/- ---------- 定型：λC 四条 form + def/inst ----------
   语境是统一坐标系：压栈时全体条目（含新注解）在 cutoff 0
   上移一位——与 21 章 Prolog 检查器的 push 同款纪律 -/

def pushTy (A : Tm) (Γ : List Tm) : List Tm :=
  shift 1 0 A :: Γ.map (shift 1 0)

def inferTy (Δ : Delta) (Γ : List Tm) : Tm → Option Tm
  | sort star => some (sort box)
  | var k => match Γ[k]? with
    | some T => some T
    | none => none
  | cst n us => do
      let d ← lookupDef Δ n
      guard (d.params.length == us.length)   -- inst：必须完全应用
      return instantiate d.ty us
  | app f a => do
    let fT ← inferTy Δ Γ f
    match bdNf Δ fT with
    | pi A B =>
        let aT ← inferTy Δ Γ a
        guard (beq Δ aT A)
        return subst 0 a B
    | _ => none
  | lam A b => do
    let AT ← inferTy Δ Γ A
    match AT with
    | sort _ =>
        let bT ← inferTy Δ (pushTy A Γ) b
        return pi A bT
    | _ => none
  | pi A B => do
    let AT ← inferTy Δ Γ A
    let BT ← inferTy Δ (pushTy A Γ) B
    match AT, BT with
    | sort s1, sort s2 =>
        -- λC：四对 (s1,s2) 全开（立方体顶点）
        if (s1 == star && s2 == star) || (s1 == box && s2 == star) ||
           (s1 == star && s2 == box) || (s1 == box && s2 == box)
        then some (sort star)
        else none
    | _, _ => none
  | _ => none

/- (def) 的机器面：描述式定义的体要在「Δ 前缀 + 参数语境」里
   过检且类型吻合；原始定义只查类型是 sort（def-prim 的前提）-/

def defOk (Δ : Delta) (d : Def) : Bool :=
  match d.body with
  | some b =>
      match inferTy Δ d.params b, inferTy Δ d.params d.ty with
      | some bT, some _ => beq Δ bT d.ty
      | _, _ => false
  | none =>
      match inferTy Δ d.params d.ty with
      | some (sort _) => true
      | _ => false

/- ---------- 电池用的样本 Δ ----------

   de Bruijn 速查（ Churches ）：
   tyN = ΠX:*. (X→X)→X→X
        = pi(*) ( pi (pi 0 1) (pi 1 2) )
   zero  = λX.λf.λx. x
   succ  = λn:N. λX.λf.λx. f (n f x)
   plus  = λm.λn. λX.λf.λx. m f (n f x)
   id(α) = λx:α. x : α→α
   iet(α) :: α ∨ ¬α     （原始定义；⊥ = pi * 0，¬A = A→⊥）
-/

def tyN : Tm := pi (sort star) (pi (pi (var 0) (var 1)) (pi (var 1) (var 2)))

def dZero : Def :=
  { nm := "zero", params := [],
    body := some (lam (sort star) (lam (pi (var 0) (var 1)) (lam (var 1) (var 0)))),
    ty := tyN }

def dSucc : Def :=
  { nm := "succ", params := [],
    body := some (lam tyN
               (lam (sort star)
                 (lam (pi (var 0) (var 1))
                   (lam (var 1)
                     (app (var 1)
                          (app (app (app (var 3) (var 2)) (var 1))
                               (var 0))))))),
    ty := pi tyN tyN }

def dPlus : Def :=
  { nm := "plus", params := [],
    body := some (lam tyN (lam tyN
               (lam (sort star)
                 (lam (pi (var 0) (var 1))
                   (lam (var 1)
                     (app (app (app (var 4) (var 2)) (var 1))
                          (app (app (app (var 3) (var 2)) (var 1))
                               (var 0)))))))),
    ty := pi tyN (pi tyN tyN) }

def dId : Def :=
  { nm := "id", params := [sort star],
    body := some (lam (var 0) (var 0)),
    ty := pi (var 0) (var 1) }

/-- iet(α) : α∨¬α = ΠC:*. (α→C)→((α→⊥)→C)→C，db 于 [α] 语境 -/
def dIet : Def :=
  { nm := "iet", params := [sort star], body := none,
    ty := pi (sort star)
        (pi (pi (var 1) (var 1))
          (pi (pi (pi (var 2) (pi (sort star) (var 0))) (var 2)) (var 2))) }

def Δs : Delta := [dZero, dSucc, dPlus, dId, dIet]

def tTwo : Tm := app (cst "succ" []) (app (cst "succ" []) (cst "zero" []))
def tThree : Tm :=
  app (cst "succ" []) (app (cst "succ" []) (app (cst "succ" []) (cst "zero" [])))
def tFive : Tm :=
  app (cst "succ" []) (app (cst "succ" []) (app (cst "succ" [])
    (app (cst "succ" []) (app (cst "succ" []) (cst "zero" [])))))

/- ---------- 电池（10 条） ---------- -/

-- 1. (def)/(def-prim) 前提：五条定义全部良构（4 描述 + 1 原始）
example : ((Δs.filter (defOk Δs)).length == 5) = true := by native_decide

-- 2. inst 0 参数：zero : N
example : (inferTy Δs [] (cst "zero" []) == some tyN) = true := by
  native_decide

-- 3. 零参数常数经 β 应用：succ zero : N（succ 本身 : N→N）
example : (inferTy Δs [] (cst "succ" []) == some (pi tyN tyN)) = true := by
  native_decide

example : (inferTy Δs [] (app (cst "succ" []) (cst "zero" []))
             == some tyN) = true := by
  native_decide

-- 4. inst 类型实例化：id(N) : N→N
example : (inferTy Δs [] (cst "id" [tyN]) == some (pi tyN tyN)) = true := by
  native_decide

-- 5. δ 展开：id(N) zero 的 βδ-范式 = zero 的 βδ-范式
example :
    (bdNf Δs (app (cst "id" [tyN]) (cst "zero" []))
      == bdNf Δs (cst "zero" [])) = true := by
  native_decide

-- 6. 旗舰：plus two three 的 βδ-范式 = five 的 βδ-范式
example : (inferTy Δs [] (app (app (cst "plus" []) tTwo) tThree)
             == some tyN) = true := by native_decide

example : (bdNf Δs (app (app (cst "plus" []) tTwo) tThree)
             == bdNf Δs tFive) = true := by native_decide

-- 7. inst-prim：iet(N) : N∨¬N（21 章的二阶编码在此公理化）
example : (inferTy Δs [] (cst "iet" [tyN])).isSome = true := by
  native_decide

-- 8. 原始定义不 δ-展开：iet(N) 的范式保持自身
example : (bdNf Δs (cst "iet" [tyN]) == cst "iet" [tyN]) = true := by
  native_decide

-- 9. NEG：iet 参数不足不可定型（inst 要求完全应用）
example : (inferTy Δs [] (cst "iet" []) == none) = true := by rfl

-- 10. NEG：不在 Δ 里的常数查无此名
example : (inferTy Δs [] (cst "phantom" []) == none) = true := by rfl

def main : IO Unit := do
  let ok1 := (Δs.filter (defOk Δs)).length == 5
  let ok2 := inferTy Δs [] (cst "zero" []) == some tyN
  let ok3 := (inferTy Δs [] (app (cst "succ" []) (cst "zero" []))).isSome
  let ok4 := inferTy Δs [] (cst "id" [tyN]) == some (pi tyN tyN)
  let ok5 := bdNf Δs (app (cst "id" [tyN]) (cst "zero" [])) == bdNf Δs (cst "zero" [])
  let ok6 := bdNf Δs (app (app (cst "plus" []) tTwo) tThree) == bdNf Δs tFive
  let ok7 := (inferTy Δs [] (cst "iet" [tyN])).isSome
  let ok8 := bdNf Δs (cst "iet" [tyN]) == cst "iet" [tyN]
  let ok9 := inferTy Δs [] (cst "iet" []) == none
  let ok10 := inferTy Δs [] (cst "phantom" []) == none
  let results := [ok1, ok2, ok3, ok4, ok5, ok6, ok7, ok8, ok9, ok10]
  if results.contains false then
    throw (IO.userError "some check failed")
  else
    IO.println "10 条全过"
