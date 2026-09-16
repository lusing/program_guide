/-
文件: 17_workflow/workflow.lean
描述: 第20章 定理检索与 Mathlib 工作流（与教程同步，Mathlib4 master@2026-09 验证）
编译: lake build Lean4Tutorial.Examples.Workflow.Workflow
-/

import Mathlib.Tactic.Common
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.Ring

namespace Lean4Tutorial.Examples.Workflow.Ch20

/-! # 20.1 检索战术（Lean 4.34 核心：exact? / apply? / rw? / simp?） -/

-- exact?：在整个环境中搜索能关闭目标的定理
example (a b : Nat) : a + b = b + a := by exact?
-- 输出：Try this: exact Nat.add_comm a b

-- apply?：搜索"结论匹配目标"的定理，剩余前提变子目标
example (a b : Nat) : a + b = b + a := by apply?

-- rw?：搜索可用的 rewrite
example (n : Nat) : n + 0 = n := by rw?

-- simp?：报告 simp 实际用到的引理清单（优化为 simp only 的依据）
example (l : List Nat) : l ++ [] = l := by simp?

/-! # 20.2 hint 战术：一键撒网 -/

-- hint 把注册过的战术按优先级全部试一遍，报告所有可行方案
-- （注册表见 Mathlib/Tactic/Common.lean:151-160；hint 自己就能关闭这个目标）
example (n : Nat) : n + 0 = n := by hint

/-! # 20.3 等式目标的线性组合 -/

-- linear_combination：声明"目标 = 假设的线性组合"，系数算术交给环自动化
-- 目标 5x+5y=10 恰是 -h1 + 2*h2 的组合
example (x y : ℤ) (h1 : x + 3 * y = 4) (h2 : 3 * x + 4 * y = 7) :
    5 * x + 5 * y = 10 := by
  linear_combination 2 * h2 - h1

/-! # 20.7 元编程速览：最小的自定义战术 -/

-- syntax 声明新语法（(name := ...) 便于引用）；macro_rules 给出展开规则
-- 注意：关键字只能用 ASCII/CJK 之外的常规字符——CJK 字符会被当作标识符字符，
-- 无法作为独立 token 识别
syntax (name := easyTac) "try_easy" : tactic

macro_rules
  | `(tactic| try_easy) => `(tactic| first | rfl | trivial | simp_all)

example : 2 + 2 = 4 := by try_easy
example (n : Nat) : n + 0 = n := by try_easy

end Lean4Tutorial.Examples.Workflow.Ch20
