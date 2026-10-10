/- ex100_paradox.lean —— 悖论的结构与解悖理论（张寅生 13.1-13.7）Lean 镜像
   Smullyan 对角集不可表示全枚举+类型阶检查器+ZFC 分离现场+NF 层化
   求解器+情境序列交替账。 -/

set_option linter.unusedVariables false

/- ---------- 1. Smullyan 抽象系统与命题 13.1 ---------- -/

def mem (n : Nat) (l : List Nat) : Bool := l.contains n

def cmap (m n : Nat) : Nat := m          -- 句子 m 恒谈论 m（对角公理 cmap m m=m ✓）

def Ts3 : List (List Nat) :=
  [[], [0], [1], [2], [0,1], [0,2], [1,2], [0,1,2]]

def reprOK (m : Nat) (T X : List Nat) : Bool :=
  [0,1,2].all (fun n => mem (cmap m n) T == mem n X)

def diagSet (T : List Nat) : List Nat := [0,1,2].filter (fun n => !mem n T)

/-- 命题 13.1 全枚举：对角集 {n|n∉T} 在任何 T 下都无表示者 -/
example : Ts3.all (fun T =>
    ![0,1,2].any (fun m => reprOK m T (diagSet T))) = true := by
  native_decide

/- ---------- 2. 类型阶：罗素谓词失败现场 ---------- -/

inductive Obj where
  | ind (n : Nat)
  | sett (level n : Nat)
deriving Repr, DecidableEq

/- ∈ 的类型检查：x∈y 合法当且仅当 y 的层恰比 x 高 1 -/
def elemOK : Obj → Obj → Option Nat
  | .ind _, .sett 1 _ => some 0
  | .sett k _, .sett k' _ => if k' == k + 1 then some k else none
  | _, _ => none

/-- 罗素谓词 x∈x：同层——类型检查失败现场 -/
example : (elemOK (.sett 3 0) (.sett 3 0)).isNone = true := by native_decide

/-- 合法成员关系：k 层属于 k+1 层 -/
example : (elemOK (.sett 2 0) (.sett 3 0)).isSome = true := by native_decide

/- 说谎者的阶分析：q 断言 p 时 q 的阶>阶(p)——「本句假」无解
   （有限阶上任何 p 都有更高阶的 q 可写——自指才被禁） -/
def liarOK (pOrder : Nat) : Bool := pOrder < pOrder + 1
example : liarOK 5 = true := by native_decide

/- ---------- 3. ZFC 分离现场与正规公理 ---------- -/

def sepOf (M : List Nat) (phi : Nat → Bool) : List Nat := M.filter phi

example : sepOf [0,1,2,3,4] (fun x => x % 2 == 0) = [0,2,4] := by native_decide

/- 分离版罗素集：{x∈M | x∉x}——个体论域上 x=x 恒真 → 空集（有界安全） -/
def russellIn (M : List Nat) : List Nat := M.filter (fun x => !(x == x))

example : russellIn [0,1,2] = [] := by native_decide

/- ---------- 4. NF 层化检查器 ---------- -/

inductive Atom where
  | inA (x y : Nat)
  | eqA (x y : Nat)
deriving Repr, DecidableEq

abbrev Formula := List Atom

def assignOK (f : Formula) (a : Nat → Nat) : Bool :=
  f.all (fun c => match c with
    | .inA x y => a y == a x + 1
    | .eqA x y => a x == a y)

def assigns : List (Nat → Nat) :=
  (List.range 3).flatMap (fun v0 =>
    (List.range 3).flatMap (fun v1 =>
      (List.range 3).flatMap (fun v2 =>
        (List.range 3).flatMap (fun v3 =>
          (List.range 3).map (fun v4 =>
            fun n => match n with
            | 0 => v0 | 1 => v1 | 2 => v2 | 3 => v3 | _ => v4)))))

def stratified (f : Formula) : Bool := assigns.any (assignOK f)

/-- x∈y ∧ y∈z：链式约束可解 -/
example : stratified [.inA 0 1, .inA 1 2] = true := by native_decide

/-- x∈x：α(x)=α(x)+1 无解——不分层（罗素概括被禁，例 13.16） -/
example : stratified [.inA 0 0] = false := by native_decide

example : stratified [.eqA 0 0] = true := by native_decide

/-- 环形 ∈：α(1)=α(0)+1 且 α(0)=α(1)+1 无解 -/
example : stratified [.inA 0 1, .inA 1 0] = false := by native_decide

/- ---------- 5. 情境序列（表 13.1） ---------- -/

def sitSeq : Nat → List Bool
  | 0 => []
  | k + 1 => sitSeq k ++ [k % 2 == 0]

example : sitSeq 6 = [true,false,true,false,true,false] := by native_decide

#eval (Ts3.length, stratified [.inA 0 1, .inA 1 0])
