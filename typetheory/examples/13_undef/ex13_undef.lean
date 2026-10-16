/- ============================================================
   13 未定义性：部分函数世界的逻辑 —— Lean 侧（Farmer 3.4/6.4/7）
   机器复制自 12 章（Ty/Tm/Val/Model/evalV），新装四组实验：
     · TATU 三原则的机器面：原子恒定义、应用/描述可无定义、
       【公式恒有两值】——「未定义谓词应用 = f」
     · 双等式：= 须双方有定义；≃（准等式）连「双无定义」也算等
       —— 1/0 = 1/0 为假而 1/0 ≃ 1/0 为真
     · 非法 β-归约双反例（书例 7.5）：捕获版与无定义实参版——
       朴素代换一个改变值、一个改变定义性
     · 全称例示的守卫（推论 7.4）：把 ⊥ 代进去能把假全称
       例示成真——A↓ 守卫是可靠性的防线
   ============================================================ -/

-- ---- 类型：o / 基型 a_n / 箭头 / 积（复制自 12 章） ----
inductive Ty where
  | o : Ty
  | b : Nat → Ty
  | arrow : Ty → Ty → Ty
  | prod : Ty → Ty → Ty
deriving Repr, BEq

def N : Ty := .b 0

inductive Tm where
  | var : Nat → Ty → Tm
  | con : Nat → Ty → Tm
  | eq : Tm → Tm → Tm
  | app : Tm → Tm → Tm
  | lam : Ty → Tm → Tm
  | des : Ty → Tm → Tm
  | pair : Tm → Tm → Tm
deriving Repr, BEq

def typeOf (d : Nat) : Tm → Option Ty
  | .var x α => if x < d then some α else none
  | .con _ α => some α
  | .eq A B => match typeOf d A, typeOf d B with
      | some α, some β => if α == β then some .o else none
      | _, _ => none
  | .app F A => match typeOf d F, typeOf d A with
      | some (.arrow α β), some α' => if α == α' then some β else none
      | _, _ => none
  | .lam x B => (typeOf (d + 1) B).map (fun β => .arrow x β)
  | .des x A => if typeOf (d + 1) A == some .o then some x else none
  | .pair A B => match typeOf d A, typeOf d B with
      | some α, some β => some (.prod α β)
      | _, _ => none

inductive Val where
  | tv : Bool → Val
  | el : Nat → Nat → Val
  | fv : Ty → Ty → List (Val × Val) → Val
  | pv : Val → Val → Val
deriving Repr

/- 手写 BEq（12 章实测坑：deriving 对嵌套递归字段内核不归约） -/
mutual
def valEq : Val → Val → Bool
  | .tv a, .tv b => a == b
  | .el t1 d1, .el t2 d2 => t1 == t2 && d1 == d2
  | .fv a1 b1 t1, .fv a2 b2 t2 => a1 == a2 && b1 == b2 && tabEq t1 t2
  | .pv a1 b1, .pv a2 b2 => valEq a1 a2 && valEq b1 b2
  | _, _ => false
def tabEq : List (Val × Val) → List (Val × Val) → Bool
  | [], [] => true
  | (a1, b1) :: t1, (a2, b2) :: t2 => valEq a1 a2 && valEq b1 b2 && tabEq t1 t2
  | _, _ => false
end
instance : BEq Val := ⟨valEq⟩
instance : Inhabited Val := ⟨.pv (.tv true) (.tv true)⟩

structure Model where
  baseSize : Nat → Nat
  arrowDom : Ty → Ty → List Val
  interp : Nat → Ty → Val

def domOf (M : Model) : Ty → List Val
  | .o => [.tv false, .tv true]
  | .b n => (List.range (M.baseSize n)).map (.el n)
  | .arrow α β => M.arrowDom α β
  | .prod α β => (domOf M α).flatMap (fun a => (domOf M β).map (fun b => .pv a b))

def applyV : Val → Val → Option Val
  | .fv _ _ tab, a => tab.lookup a
  | _, _ => none

def evalV (M : Model) : List Val → Tm → Option Val
  | φ, .var x _ => φ[x]?
  | _, .con c α => some (M.interp c α)
  | φ, .eq A B =>
      match evalV M φ A, evalV M φ B with
      | some a, some b => some (.tv (a == b))
      | _, _ => some (.tv false)
  | φ, .app F A =>
      match typeOf 0 F with
      | some (.arrow _ β) =>
          match evalV M φ F, evalV M φ A with
          | some f, some a => applyV f a <|> (if β == .o then some (.tv false) else none)
          | _, _ => if β == .o then some (.tv false) else none
      | _ => none
  | φ, .lam x B =>
      let β := (typeOf (φ.length + 1) B).getD (.b 0)
      let tab := (domOf M x).filterMap (fun v =>
        (evalV M (v :: φ) B).map (fun r => (v, r)))
      some (.fv x β tab)
  | φ, .des x A =>
      match (domOf M x).filter (fun v => evalV M (v :: φ) A == some (.tv true)) with
      | [v] => some v
      | _ => none
  | φ, .pair A B =>
      match evalV M φ A, evalV M φ B with
      | some a, some b => some (.pv a b)
      | _, _ => none

-- ============================================================
-- M13：12 章 M1 + 布尔算子伪常数（4:¬ 5:∨ 6:∧ 7:⇒ 8:T）
-- ============================================================
def notTab : List (Val × Val) :=
  [(.tv false, .tv true), (.tv true, .tv false)]
/-- Curry 式两参布尔算子表：先吃一参吐「剩一参」的函数表 -/
def curry2 (op : Bool → Bool → Bool) : Val :=
  .fv .o (.arrow .o .o)
    [(.tv false, .fv .o .o
        [(.tv false, .tv (op false false)), (.tv true, .tv (op false true))]),
     (.tv true,  .fv .o .o
        [(.tv false, .tv (op true false)),  (.tv true, .tv (op true true))])]
def orTab2 : Val := curry2 (· || ·)
def andTab2 : Val := curry2 (· && ·)
def impTab2 : Val := curry2 (fun a b => !a || b)
def idT : List (Val × Val) := [(.el 0 0, .el 0 0), (.el 0 1, .el 0 1)]
def const0T : List (Val × Val) := [(.el 0 0, .el 0 0), (.el 0 1, .el 0 0)]
def const1T : List (Val × Val) := [(.el 0 0, .el 0 1), (.el 0 1, .el 0 1)]
def plusT : List (Val × Val) :=
  [(.pv (.el 0 0) (.el 0 0), .el 0 0), (.pv (.el 0 0) (.el 0 1), .el 0 1),
   (.pv (.el 0 1) (.el 0 0), .el 0 1), (.pv (.el 0 1) (.el 0 1), .el 0 0)]

def M13 : Model :=
  { baseSize := fun _ => 2
    arrowDom := fun α β =>
      match α, β with
      | .b 0, .b 0 => [.fv N N idT, .fv N N const0T, .fv N N const1T, .fv N N []]
      | .prod (.b 0) (.b 0), .b 0 => [.fv (.prod N N) N plusT]
      | .b 0, .o => []          -- 谓词层本章不用满（见 12 章）
      | .o, .o => [.fv .o .o notTab]
      | .o, .arrow .o .o => [orTab2, andTab2, impTab2]
      | _, _ => []
    interp := fun c _ =>
      match c with
      | 0 => .el 0 0
      | 1 => .el 0 1
      | 2 => .fv (.prod N N) N plusT
      | 3 => .fv N N []                       -- ∆ 空函数
      | 4 => .fv .o .o notTab                 -- ¬
      | 5 => orTab2                                -- ∨（Curry 式两参）
      | 6 => andTab2                              -- ∧
      | 7 => impTab2                              -- ⇒
      | _ => .tv true                         -- T_o
  }

-- ---- 语法糖 ----
def v0 (α : Ty) : Tm := .var 0 α
def c0 : Tm := .con 0 N
def c1 : Tm := .con 1 N
def notc (A : Tm) : Tm := .app (.con 4 (.arrow .o .o)) A
def orc (A B : Tm) : Tm := .app (.app (.con 5 (.arrow .o (.arrow .o .o))) A) B
def impc (A B : Tm) : Tm := .app (.app (.con 7 (.arrow .o (.arrow .o .o))) A) B
def andc (A B : Tm) : Tm := .app (.app (.con 6 (.arrow .o (.arrow .o .o))) A) B
def Tc : Tm := .con 8 .o
def deltac : Tm := .con 3 (.arrow N N)

-- ---- 定义性记法（书表 6.4 的机器版） ----
def dn (A : Tm) : Tm := .eq A A                    -- A↓
def up (A : Tm) : Tm := notc (dn A)                 -- A↑
def quasiEq (A B : Tm) : Tm :=                      -- A ≃ B := (A↓∨B↓) ⇒ (A=B)
  impc (orc (dn A) (dn B)) (.eq A B)

-- ⊥_N（12 章的纯等式编码）与 ∆ = λx.⊥
def botN : Tm := .des N (.eq (.eq (v0 N) c0) (.eq (v0 N) c1))
def delta : Tm := .lam N botN

#eval evalV M13 [] botN        -- none
#eval evalV M13 [] delta       -- some (fv [])：空函数本身有定义
#eval evalV M13 [] (.app deltac c0)  -- none

-- ============================================================
-- ① TATU 三原则与双等式
-- ============================================================
-- 原则三：公式恒有定义——含 ⊥ 的公式照样出真值
example : evalV M13 [] (.eq botN botN) = some (.tv false) := by rfl   -- 1/0 = 1/0 假
example : evalV M13 [] (.eq botN c0) = some (.tv false) := by rfl    -- 1/0 = 1 假
-- 准等式：双方无定义也算等——1/0 ≃ 1/0 真！
example : evalV M13 [] (quasiEq botN botN) = some (.tv true) := by rfl
example : evalV M13 [] (quasiEq botN c0) = some (.tv false) := by rfl  -- 一边有定义
-- A↓ / A↑
example : evalV M13 [] (dn botN) = some (.tv false) := by rfl
example : evalV M13 [] (up botN) = some (.tv true) := by rfl
example : evalV M13 [] (dn c0) = some (.tv true) := by rfl
-- ∆ 有定义、∆ 应用无定义、但含 ∆ 应用的公式仍有值
example : evalV M13 [] (dn (.app deltac c0)) = some (.tv false) := by rfl
example : evalV M13 [] (quasiEq (.app deltac c0) (.app deltac c0)) = some (.tv true) := by rfl

-- ============================================================
-- ② 非法 β-归约之一：捕获（书例 7.5.1）
-- ============================================================
-- 命名式小语法（专为演示「朴素代换会捕获」）
inductive NTm where
  | var : String → NTm
  | con : Nat → NTm
  | lam : String → NTm → NTm
  | app : NTm → NTm → NTm
  | eq : NTm → NTm → NTm
deriving Repr, BEq

/-- 朴素代换：绑定器撞名时不避让——注定捕获 -/
def nsub (x : String) (s : NTm) : NTm → NTm
  | .var y => if y == x then s else .var y
  | .lam b bdy => .lam b (if b == x then bdy else nsub x s bdy)
  | .app f a => .app (nsub x s f) (nsub x s a)
  | .eq a b => .eq (nsub x s a) (nsub x s b)
  | .con c => .con c

/-- 命名→de Bruijn（全 N 片段，供 evalV 求值） -/
def toDb : List String → NTm → Tm
  | ctx, .var y => match ctx.idxOf? y with
      | some i => .var i N
      | none => .var 0 N
  | _, .con c => .con c N
  | ctx, .lam b bdy => .lam N (toDb (b :: ctx) bdy)
  | ctx, .app f a => .app (toDb ctx f) (toDb ctx a)
  | ctx, .eq a b => .eq (toDb ctx a) (toDb ctx b)

def Fn : NTm := .lam "x" (.lam "y" (.var "x"))      -- λx.λy.x
def argY : NTm := .var "y"                          -- 自由变量 y
-- 朴素 β：(λy.x)[x:=y] = λy.y ——恒等函数，捕获！
def wrongBeta : NTm := nsub "x" argY (.lam "y" (.var "x"))
#eval wrongBeta                                     -- lam "y" (var "y")

-- 语义真相：F y 在 y↦1 下 = 常 1 函数
def Fd : Tm := .lam N (.lam N (.var 1 N))
example : evalV M13 [] (.app Fd (toDb ["y"] argY)) = none := by rfl  -- 自由变量无指派
-- 指派 y ↦ 1：F y = 常函数 1
def appFy : Tm := .app Fd (.var 0 N)
#eval evalV M13 [.el 0 1] appFy                     -- some (fv const1T)
example : evalV M13 [.el 0 1] appFy = some (.fv N N const1T) := by rfl
-- 朴素 β 的产物是恒等函数 ≠ 常 1 —— 值被改了！
example : evalV M13 [.el 0 1] (toDb ["y"] wrongBeta) = some (.fv N N idT) := by rfl
example : (evalV M13 [.el 0 1] (toDb ["y"] wrongBeta)
        == evalV M13 [.el 0 1] appFy) = false := by rfl

-- ============================================================
-- ③ 非法 β-归约之二：无定义实参（书例 7.5.2 与命题 7.3）
-- ============================================================
-- F ⊥ 语义上无定义（V4：A↑ 且目标型 ≠ o）
example : evalV M13 [] (.app Fd botN) = none := by rfl
-- 朴素 β 产物 λy.⊥ = 空函数——有定义！定义性被改了！
example : evalV M13 [] (.lam N botN) = some (.fv N N []) := by rfl
example : (evalV M13 [] (.app Fd botN) == evalV M13 [] (.lam N botN)) = false := by rfl
-- 命题 7.3：A↑ ⇒ (λx.B)A ≃ ⊥β —— ⊥_{N→N} 用「Ix.x=x」（多满足者）造
def botNN : Tm := .des (.arrow N N) (.eq (v0 (.arrow N N)) (v0 (.arrow N N)))
example : evalV M13 [] botNN = none := by rfl
example : evalV M13 [] (quasiEq (.app Fd botN) botNN) = some (.tv true) := by rfl
-- 对照：λy.⊥ 是空函数（有定义），与 F ⊥ 只在 = 下不等、≃ 下也不等
example : evalV M13 [] (quasiEq (.app Fd botN) (.lam N botN)) = some (.tv false) := by rfl

-- ============================================================
-- ④ 全称例示的守卫（推论 7.4）：⊥ 能把假全称例示成真
-- ============================================================
-- ∀x. x ≠ c0 := (λx.T) = (λx. x≠c0)：两表不同 ⇒ 假
def allNe0 : Tm := .eq (.lam N Tc) (.lam N (notc (.eq (v0 N) c0)))
#eval evalV M13 [] allNe0                           -- some (tv false)
-- 但把 x := ⊥ 代进去：⊥ = c0 为假 ⇒ ¬ = 真！
example : evalV M13 [] (notc (.eq botN c0)) = some (.tv true) := by rfl
-- 带守卫的版本（推论 7.4 原形：(∀ ∧ A'↓) ⇒ 实例）在 ⊥ 上空洞地为真
example : evalV M13 [] (impc (andc allNe0 (dn botN))
                             (notc (.eq botN c0))) = some (.tv true) := by rfl
-- 要害在这对事实：全称为【假】，⊥-实例却为【真】——
-- 无守卫的 UI 规则会从可驳前提推出真实例，守卫 A'↓ 正是挡这一手
example : evalV M13 [] allNe0 = some (.tv false) := by rfl
example : evalV M13 [] (notc (.eq botN c0)) = some (.tv true) := by rfl

-- ---- 公式恒有定义的抽样断言（原则三） ----
example : (typeOf 0 (.eq botN c0)) = some .o := by rfl
example : evalV M13 [] (impc (.eq botN botN) (dn c0)) = some (.tv true) := by rfl
