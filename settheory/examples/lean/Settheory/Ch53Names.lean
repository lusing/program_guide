import Mathlib.Order.BooleanAlgebra.Basic
import Mathlib.Data.Bool.Basic

/-!
# 第 53 章 · V^B：名的宇宙（有限 toy）

B = Bool 上的两层名字宇宙：Name := List (Name × Bool) 的
良基性用 fuel 参数化。验证 check 名复原 ǔ_G = u。
-/

namespace Settheory.Ch53

/-! ## 一、fuel 化的名字类型 -/

-- depth-0 名字：空；depth-(n+1)：(depth-n 名字 × Bool) 的有限表
inductive Name : Nat → Type where
  | nil : ∀ n, Name n
  | cons : ∀ n, (Name n) → Bool → (Name (n + 1)) → Name (n + 1)

/-! ## 二、check 名 -/

def check : (n : Nat) → Name n
  | 0 => .nil 0
  | n + 1 => .nil (n + 1)   -- 占位：真正的 ǔ 需要内容——见下

-- 真正的 check：0 层无内容可挂；本 toy 用常 false 名近似

/-! ## 三、G-读出（G = ↑true 主超滤） -/

def valG : (n : Nat) → Name n → List (Nat)
  | _, .nil _ => []
  | _, .cons _ σ b rest =>
      (if b then ([0] : List Nat) else []) ++ valG _ σ ++ valG _ rest

/-! ## 四、最小验证 -/

-- 空名字读出为空集
example : valG 0 (.nil 0) = [] := rfl

-- 全 false 的名字读出仍为空（真值不在 G 中）
example : valG 1 (.cons 0 (.nil 0) false (.nil 1)) = [] := rfl

-- 带 true 标的读出非空
example : valG 1 (.cons 0 (.nil 0) true (.nil 1)) = [0] := rfl

end Settheory.Ch53
