/-
文件: 16_advanced_tactics/aesop_tactic.lean
描述: aesop 战术：自动证明搜索
编译: lake build Lean4Tutorial.Examples.AdvancedTactics.AesopTactic
依赖: Mathlib.Tactic.Aesop
-/

import Mathlib.Tactic.Aesop
import Mathlib.Data.Real.Basic

namespace Lean4Tutorial.Examples.AdvancedTactics.AesopTactic

/-! # aesop 战术 -/

-- aesop 是一个自动化证明搜索战术
-- 它结合了 simp、拆分目标、应用定理等多种策略
-- 名字来源于 "As Easy as Aesop"
--
-- aesop 适合解决结构化的、常规的证明目标

/-! ## 基本用法 -/

-- 简单的逻辑目标
example (P Q : Prop) (h : P ∧ Q) : P := by aesop
example (P Q : Prop) (h : P ∧ Q) : Q := by aesop
example (P Q : Prop) (h : P) : P ∨ Q := by aesop
example (P Q : Prop) (h : Q) : P ∨ Q := by aesop

-- 蕴含式
example (P Q : Prop) (h : P → Q) (hp : P) : Q := by aesop

-- 否定
example (P : Prop) (h : P) (h' : ¬ P) : False := by aesop

-- 量词
example (P : ℕ → Prop) (h : ∀ n, P n) : P 5 := by aesop
example (P : ℕ → Prop) (h : ∃ n, P n) : ∃ n, P n := by aesop

/-! ## 等式与重写 -/

variable (a b c : ℕ)

example (h : a = b) (h2 : b = c) : a = c := by aesop
example (h : a = b) : a + 1 = b + 1 := by aesop

/-! ## 结构与记录 -/

-- aesop 可以自动访问结构的字段

structure Point where
  x : ℕ
  y : ℕ
  z : ℕ

example (p : Point) : p.x = p.x := by aesop
example (p : Point) : p.x = p.x ∧ p.y = p.y := by aesop

/-! ## 简单的算术 -/

example : 2 + 2 = 4 := by aesop
example : 2 + 3 = 5 := by aesop

example (n : ℕ) : n + 0 = n := by aesop
example (n m : ℕ) : n + m = m + n := by
  aesop  -- 可能不行，aesop 不擅长算术恒等式
  <;> omega

/-! ## 列表和数据结构 -/

-- aesop 可以处理一些列表性质
example (l : List ℕ) : [] ++ l = l := by aesop
example (l : List ℕ) : l ++ [] = l := by aesop
example (x : ℕ) (l : List ℕ) : (x :: l).length = l.length + 1 := by aesop

/-! ## aesop 的策略 -/

-- aesop 使用以下策略：
--   1. 拆分目标（例如 P ∧ Q 拆分为两个子目标）
--   2. 应用假设（例如从 P → Q 和 P 推出 Q）
--   3. 构造证明项（例如对于 P ∨ Q 目标，尝试证明 P 或 Q）
--   4. 简化（使用 simp）
--   5. 归一化（使用 norm）

/-! ## aesop 与 simp 的比较 -/

-- simp 主要用于化简表达式
-- aesop 则是更全面的证明搜索

-- 当 simp 不够用时，试试 aesop
-- aesop 会尝试更多的证明步骤

/-! ## aesop 的配置 -/

-- aesop 有多种配置选项：
--   aesop?  - 显示使用的规则
--   aesop (add safe: ...)  - 添加安全规则
--   aesop (add norm: ...)  - 添加规范化规则
--   aesop (add unsafe: ...) - 添加不安全规则

-- 安全规则：总是正确的，不会导致回溯
-- 不安全规则：可能需要回溯

/-! ## aesop 的局限性 -/

-- aesop 不是万能的：
--   1. 不擅长复杂的算术（用 ring, linarith, omega）
--   2. 不擅长需要创造性的证明
--   3. 可能在搜索空间太大时超时
--   4. 对于需要归纳的问题，通常需要用户引导

-- aesop 最适合"常规"的证明任务
-- 例如逻辑推理、结构字段访问、简单的代数等

/-! ## 建议的使用方式 -/

-- 1. 先试试 aesop，看它能不能自动解决
-- 2. 如果不行，手动做一些步骤，再用 aesop
-- 3. 用 aesop? 看看它用了哪些规则
-- 4. 根据需要添加自定义规则

end Lean4Tutorial.Examples.AdvancedTactics.AesopTactic
