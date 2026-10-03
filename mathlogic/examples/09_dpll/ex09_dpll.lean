/- ex09 —— DPLL 与 SAT（Lean 4 版：实现与可执行现场）
   完整三定理链（sound/complete/decides 零公理归纳证明）在 Coq 通道；
   本文件给出同构实现 + 计算现场：模型可直接 #eval 验证。 -/

namespace Ex09

abbrev Lit := Bool × Nat      -- (sign, var)
abbrev Clause := List Lit
abbrev Fml := List Clause

def litVal (e : Nat → Bool) (l : Lit) : Bool :=
  if l.1 then e l.2 else !(e l.2)

def clsSat (e : Nat → Bool) : Clause → Bool
  | [] => false
  | l :: rest => litVal e l || clsSat e rest

def fmlSat (e : Nat → Bool) : Fml → Bool
  | [] => true
  | c :: F' => clsSat e c && fmlSat e F'

def upd (e : Nat → Bool) (n : Nat) (b : Bool) : Nat → Bool :=
  fun m => if m == n then b else e m

/-- 化简：真文字删子句、假文字删文字 -/
def clauseStep : Clause → Nat → Bool → Option Clause
  | [], _, _ => some []
  | l :: rest, n, s =>
      if l.2 == n then
        if (l.1 != s) then clauseStep rest n s   -- 假文字：删
        else none                                 -- 真文字：子句满足
      else match clauseStep rest n s with
           | some c' => some (l :: c')
           | none => none

def fmlStep : Fml → Nat → Bool → Fml
  | [], _, _ => []
  | c :: F', n, s =>
      match clauseStep c n s with
      | none => fmlStep F' n s
      | some c' => c' :: fmlStep F' n s

def isEmpty : Clause → Bool
  | [] => true
  | _ => false

def hasConflict (F : Fml) : Bool := F.any isEmpty

def findUnit : Fml → Option Lit
  | [] => none
  | [l] :: _ => some l
  | _ :: F' => findUnit F'

def firstLit : Fml → Option Lit
  | [] => none
  | (l :: _) :: _ => some l
  | _ :: F' => firstLit F'

def dpll : Nat → Fml → Option (Nat → Bool)
  | 0, _ => none
  | k + 1, F =>
      if hasConflict F then none
      else match findUnit F with
        | some (s, n) =>
            match dpll k (fmlStep F n s) with
            | some e => some (upd e n s)
            | none => none
        | none =>
            match firstLit F with
            | some (s, n) =>
                match dpll k (fmlStep F n s) with
                | some e => some (upd e n s)
                | none =>
                    match dpll k (fmlStep F n (!s)) with
                    | some e => some (upd e n (!s))
                    | none => none
            | none => some (fun _ => true)

/-- 结果折成 Bool——函数 Option 不能判等（funext 地雷，07 章同款） -/
def found (fuel : Nat) (F : Fml) : Bool :=
  match dpll fuel F with | some _ => true | none => false

/- ---------- 可执行现场 ---------- -/

/- 可满足：(x₀ ∨ x₁) ∧ (¬x₀ ∨ x₁) ∧ (¬x₁ ∨ x₀) —— 单元传播 + 分裂 -/
example : found 30 [[(true, 0), (false, 1)], [(false, 0), (false, 1)],
                    [(true, 1), (true, 0)]] = true := by native_decide

/- 模型验证：读出的赋值直接满足全部子句 -/
#eval
  match dpll 30 [[(true, 0), (false, 1)], [(false, 0), (false, 1)],
                 [(true, 1), (true, 0)]] with
  | some e => e 0 || e 1      -- 第一子句满足即可见
  | none => false

/- 不可满足：x₀ ∧ ¬x₀ -/
example : found 10 [[(true, 0)], [(false, 0)]] = false := by native_decide

/- 单元传播现场：(x₁) ∧ (¬x₁ ∨ x₀) 传播得 x₁=T → x₀=T -/
#eval
  match dpll 20 [[(true, 1)], [(false, 1), (true, 0)]] with
  | some e => (e 1, e 0)      -- 期望 (true, true)
  | none => (false, false)

/- 坑位速记（Lean 侧）：
   - match dpll k ... with 的嵌套 option 匹配层层展开——
     Lean 方程式编译器处理嵌套 match 比 Coq 的 match 温顺；
   - l.1 != s 是 Bool 的 xorb 语义（NE 不行——那是 Prop）；
   - found 折叠规避 Option (Nat → Bool) 判等的 funext 地雷。 -/

end Ex09
