/-
文件: 08_modules_projects/modules.lean
描述: 第10章 模块系统、命名空间、section/variable、export（与教程同步，Lean 4.34.0 验证）
编译: lake build Lean4Tutorial.Examples.ModulesProjects.Modules
-/

/-! # 命名空间与 open -/

namespace MyNamespace

def x : Nat := 1

namespace Inner
def y : Nat := 2
end Inner

end MyNamespace

#check MyNamespace.x
#check MyNamespace.Inner.y

open MyNamespace
#check x

open MyNamespace.Inner in
#check y

/-! # export -/

namespace Base
def helper : Nat := 1
end Base

namespace Api
export Base (helper)
end Api

#check Api.helper

/-! # section / variable / include -/

section MySection

variable (α β : Type) [Add α]

def doubleAdd (a : α) : α := a + a

def addBoth (a b : α) : α := a + b

end MySection

#check @doubleAdd
#check @addBoth

section Control
variable {α : Type} (l : List α)

-- include：强制引入未使用的 variable
include l in
theorem forced : l = l := rfl

end Control

/-! # 属性速览 -/

/-- 自定义 simp 引理示例 -/
@[simp]
theorem list_append_singleton (x : Nat) : [x] ++ [] = [x] := rfl

example : ([5] ++ []) = [5] := by simp
