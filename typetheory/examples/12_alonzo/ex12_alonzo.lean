/- ============================================================
   12 Alonzo：Church 式简单类型论 —— Lean 侧（Farmer ch.4–5）
   与 04 章的 Curry 式 λ→ 对偶的另一半：
     · 类型四条：o（真值）/ 基型 / → / ×，全非空
     · 表达式七种：变量/常数/等式/应用/抽象/确定描述 I/序对
     · 广义模型 V1–V7：部分赋值——等式永远有定义（V3）、
       谓词吃未定义实参出 f 而函数才传 undefined（V4）、
       I 取「恰一满足者」否则无定义（V6）
     · Henkin 条款可执行化：D_{α→β} 是手选子域，λ 的指称
       必须落在域内——「不是每个解释都是广义模型」
     · 定理 5.9 引擎：有限域上 4 个 λ 项穷尽 4 个谓词
   ============================================================ -/

-- ---- 类型：o / 基型 a_n / 箭头 / 积 ----
inductive Ty where
  | o : Ty
  | b : Nat → Ty
  | arrow : Ty → Ty → Ty
  | prod : Ty → Ty → Ty
deriving Repr, BEq

def N : Ty := .b 0        -- 本实验室唯一的基型

-- ---- 表达式：Farmer 的七种（de Bruijn 指标 + 类型注解） ----
inductive Tm where
  | var : Nat → Ty → Tm               -- (x : α)
  | con : Nat → Ty → Tm               -- c_k : α（常数编号 k）
  | eq : Tm → Tm → Tm                 -- A = B（同型，结果 o）
  | app : Tm → Tm → Tm                -- F A
  | lam : Ty → Tm → Tm                -- λ x:α . B
  | des : Ty → Tm → Tm                -- I x:α . A_o
  | pair : Tm → Tm → Tm               -- (A, B)
deriving Repr, BEq

/-- 类型指派：Farmer「每个表达式按语构得到类型」的检查版 -/
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

-- ---- 值：D_o 的真值 / 基域元素 / 函数表（缺键=该点无定义）/ 序对 ----
inductive Val where
  | tv : Bool → Val
  | el : Nat → Nat → Val              -- el tag d：基型 a_tag 域中第 d 个
  | fv : Ty → Ty → List (Val × Val) → Val
  | pv : Val → Val → Val
deriving Repr

/- 手写 BEq：deriving 对嵌套递归字段（List (Val × Val)）生成的
    实例在内核归约下会卡住（#reduce 停在 instBEqVal.beq）——实测坑 -/
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

-- ---- 模型：基域尺寸 + 各箭头型的手选域（Henkin 子域！）+ 常数解释 ----
structure Model where
  baseSize : Nat → Nat
  arrowDom : Ty → Ty → List Val
  interp : Nat → Ty → Val

def domOf (M : Model) : Ty → List Val
  | .o => [.tv false, .tv true]
  | .b n => (List.range (M.baseSize n)).map (.el n)
  | .arrow α β => M.arrowDom α β
  | .prod α β => (domOf M α).flatMap (fun a => (domOf M β).map (fun b => .pv a b))

/-- 满空间的全函数表：m 个参数点 × n 个值 → 全部 n^m 张表（谓词层用） -/
def totalTabs : List Val → List Val → List (List (Val × Val))
  | [], _ => [[]]
  | a :: rest, vals => (totalTabs rest vals).flatMap (fun g => vals.map (fun v => (a, v) :: g))

/-- V4 的函数应用：表查询，缺键 = 无定义 -/
def applyV : Val → Val → Option Val
  | .fv _ _ tab, a => tab.lookup a
  | _, _ => none

/-- V1–V7 的部分赋值。φ 是按 de Bruijn 深度的值栈（头=指标 0）。 -/
def evalV (M : Model) : List Val → Tm → Option Val
  | φ, .var x _ => φ[x]?                    -- V1（已按指标入栈）
  | _, .con c α => some (M.interp c α)         -- V2
  | φ, .eq A B =>                              -- V3：等式永远有定义
      match evalV M φ A, evalV M φ B with
      | some a, some b => some (.tv (a == b))
      | _, _ => some (.tv false)
  | φ, .app F A =>                             -- V4：目标 o 时失败落 f，否则传无定义
      match typeOf 0 F with
      | some (.arrow _ β) =>
          match evalV M φ F, evalV M φ A with
          | some f, some a => applyV f a <|> (if β == .o then some (.tv false) else none)
          | _, _ => if β == .o then some (.tv false) else none
      | _ => none
  | φ, .lam x B =>                             -- V5：逐点取值成表
      let β := (typeOf (φ.length + 1) B).getD (.b 0)
      let tab := (domOf M x).filterMap (fun v =>
        (evalV M (v :: φ) B).map (fun r => (v, r)))
      some (.fv x β tab)
  | φ, .des x A =>                             -- V6：恰一满足者，否则无定义
      match (domOf M x).filter (fun v => evalV M (v :: φ) A == some (.tv true)) with
      | [v] => some v
      | _ => none
  | φ, .pair A B =>                            -- V7：严格对
      match evalV M φ A, evalV M φ B with
      | some a, some b => some (.pv a b)
      | _, _ => none

-- ============================================================
-- 函数表素材
-- ============================================================
def notTab : List (Val × Val) := []                     -- ∆：空函数
def idTab : List (Val × Val) :=
  [(.el 0 0, .el 0 0), (.el 0 1, .el 0 1)]
def const0Tab : List (Val × Val) := [(.el 0 0, .el 0 0), (.el 0 1, .el 0 0)]
def const1Tab : List (Val × Val) := [(.el 0 0, .el 0 1), (.el 0 1, .el 0 1)]
def plusTab : List (Val × Val) :=                       -- (a,b) ↦ (a+b) mod 2
  [(.pv (.el 0 0) (.el 0 0), .el 0 0), (.pv (.el 0 0) (.el 0 1), .el 0 1),
   (.pv (.el 0 1) (.el 0 0), .el 0 1), (.pv (.el 0 1) (.el 0 1), .el 0 0)]

/-- D_N 上的全部 4 个谓词表（满谓词层） -/
def predTabs : List (List (Val × Val)) :=
  totalTabs [.el 0 0, .el 0 1] [.tv false, .tv true]

-- ============================================================
-- M1：语言 {c0, c1, plus, delta}，|D_N| = 2，plus = 模 2 加法
-- D_{N→N} 只装 4 个（恒等/常0/常1/空）——16 张全表中挑 4 张
-- ============================================================
def M1 : Model :=
  { baseSize := fun _ => 2
    arrowDom := fun α β =>
      match α, β with
      | .b 0, .b 0 =>
          [.fv N N idTab, .fv N N const0Tab, .fv N N const1Tab, .fv N N notTab]
      | .prod (.b 0) (.b 0), .b 0 => [.fv (.prod N N) N plusTab]
      | .b 0, .o => predTabs.map (.fv N .o)
      | _, _ => []
    interp := fun c _ =>
      match c with
      | 0 => .el 0 0                                     -- c0
      | 1 => .el 0 1                                     -- c1
      | 2 => .fv (.prod N N) N plusTab                   -- plus
      | _ => .fv N N notTab                              -- 3 号常数：∆ 空函数
  }

-- ---- 语法糖 ----
def v0 (α : Ty) : Tm := .var 0 α
def c0 : Tm := .con 0 N
def c1 : Tm := .con 1 N
def plusc : Tm := .con 2 (.arrow (.prod N N) N)
def deltac : Tm := .con 3 (.arrow N N)
def app2 (f a b : Tm) : Tm := .app f (.pair a b)

-- ---- 例 5.3 复算：(λx:N. plus(x,x) = c1) c0 ----
def ex53 : Tm := .app (.lam N (.eq (app2 plusc (v0 N) (v0 N)) c1)) c0

#eval evalV M1 [] ex53                    -- some (tv false)：2·0 = 0 ≠ 1

-- ---- V6 确定描述三态 ----
def ixEq0 : Tm := .des N (.eq (v0 N) c0)          -- I x. x = c0
def ixEqEq : Tm := .des N (.eq (v0 N) (v0 N))     -- I x. x = x（两个满足者）
-- ⊥_N 的纯等式编码：I x. (x=c0) = (x=c1) —— 处处为假，零满足者
def botN : Tm := .des N (.eq (.eq (v0 N) c0) (.eq (v0 N) c1))

#eval evalV M1 [] ixEq0                  -- some (el 0 0)：恰一
#eval evalV M1 [] ixEqEq                 -- none：二义
#eval evalV M1 [] botN                   -- none：零满足 = ⊥_N

-- ---- V3 的锋利处：⊥ = ⊥ 是【假】不是无定义 ----
#eval evalV M1 [] (.eq botN botN)        -- some (tv false)

-- ---- V4 不对称：∆ c0 无定义，等式把它折成 f ----
#eval evalV M1 [] (.eq (.app deltac c0) c0)   -- some (tv false)

-- ---- Henkin 条款可执行化：λ 指称必须落在手选域内 ----
/-- t 的所有 λ 子式的指称落域检查（测试集上的广义模型条件） -/
def frameOK (M : Model) (φ : List Val) : Tm → Bool
  | .lam x B =>
      match evalV M φ (.lam x B) with
      | some (.fv _ β _) =>
          (domOf M (.arrow x β)).contains (evalV M φ (.lam x B)).get!
            && frameOK M ([] : List Val) B
      | _ => false
  | .des _ A => frameOK M ([] : List Val) A
  | .eq A B => frameOK M φ A && frameOK M φ B
  | .app F A => frameOK M φ F && frameOK M φ A
  | .pair A B => frameOK M φ A && frameOK M φ B
  | _ => true

#eval frameOK M1 [] (.lam N (v0 N))          -- true：恒等在域内
#eval frameOK M1 [] (.lam N c1)              -- true：常 1 已补进 M1
-- 换一个故意缺成员的域：M1 缺常 1（去掉 const1Tab）
def M1bad : Model := { M1 with
  arrowDom := fun α β => match α, β with
    | .b 0, .b 0 => [.fv N N idTab, .fv N N const0Tab, .fv N N notTab]
    | _, _ => M1.arrowDom α β }
#eval frameOK M1bad [] (.lam N c1)           -- false → M1bad 不是（测试集上的）广义模型

-- ---- 定理 5.9 引擎：有限域上谓词层被 4 个 λ 项穷尽 ----
def pAll : Tm := .lam N (.eq (v0 N) (v0 N))                          -- {0,1}
def p0 : Tm := .lam N (.eq (v0 N) c0)                                -- {0}
def p1 : Tm := .lam N (.eq (v0 N) c1)                                -- {1}
def pNone : Tm := .lam N (.eq (.eq (v0 N) c0) (.eq (v0 N) c1))       -- {}

#eval (evalV M1 [] pAll, evalV M1 [] p0, evalV M1 [] p1, evalV M1 [] pNone)

/-- 解包 λ 指称的表 -/
def tabOf (M : Model) (t : Tm) : List (Val × Val) :=
  match evalV M [] t with
  | some (.fv _ _ tab) => tab
  | _ => []

-- 四张表两两不同：
example : (tabOf M1 pAll != tabOf M1 p0 && tabOf M1 p0 != tabOf M1 p1
        && tabOf M1 p1 != tabOf M1 pNone && tabOf M1 pAll != tabOf M1 pNone) = true := by decide
-- 且恰是满谓词层 predTabs 的全部成员：
example : [pAll, p0, p1, pNone].all (fun p => predTabs.contains (tabOf M1 p)) = true := by decide
example : (predTabs.filter (fun t => [tabOf M1 pAll, tabOf M1 p0, tabOf M1 p1, tabOf M1 pNone].contains t)).length = 4 := by decide

-- ---- 同一定理的基数引擎：n 个常函数 + 恒等 ⇒ |D_{α→α}| ≥ n+1 ----
def constTab (v : Val) : List (Val × Val) := [(.el 0 0, v), (.el 0 1, v)]
def constsAndId : List Val :=
  [.fv N N (constTab (.el 0 0)), .fv N N (constTab (.el 0 1)), .fv N N idTab]
#eval constsAndId.length            -- 3 = |D_N| + 1 > |D_N| = 2（Cantor 引擎）

-- ---- 断言电池 ----
example : typeOf 0 (.app c0 c1) = none := by rfl                -- c0 c0 不良型（书 ex 4.9.2a）
example : typeOf 0 ex53 = some .o := by rfl
example : evalV M1 [] ex53 = some (.tv false) := by rfl
example : evalV M1 [] ixEq0 = some (.el 0 0) := by rfl
example : evalV M1 [] ixEqEq = none := by rfl
example : evalV M1 [] botN = none := by rfl
example : evalV M1 [] (.eq botN botN) = some (.tv false) := by rfl
example : evalV M1 [] (.eq (.app deltac c0) c0) = some (.tv false) := by rfl
example : frameOK M1bad [] (.lam N c1) = false := by rfl
example : frameOK M1 [] (.lam N c1) = true := by rfl
-- V7 严格对：∆ 应用无定义 → 序对整体无定义
example : evalV M1 [] (.pair (.app deltac c0) c0) = none := by rfl
example : typeOf 0 (.pair c0 c1) = some (.prod N N) := by rfl
-- 序对 + plus：plus(c0,c1) = c1
example : evalV M1 [] (app2 plusc c0 c1) = some (.el 0 1) := by rfl
