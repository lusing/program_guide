# 10 · 项目管理与模块系统

> 对应示例：`examples/08_modules_projects/modules.lean`

## 10.1 模块系统

每个 `.lean` 文件对应一个模块，模块名 = 相对源码根目录的路径：

```
Mathlib/
  Data/
    Nat/
      GCD/
        Basic.lean  → Mathlib.Data.Nat.GCD.Basic
```

```lean
import Mathlib.Data.Nat.Basic
import Mathlib.Algebra.Group.Basic

-- import 的粒度很重要：mathlib 有几千个模块，
-- 只导入需要的模块能让编辑器和编译都快一个数量级
```

**Lean 4.34 的模块系统**：新语法 `module` / `public import` 已启用（mathlib4 于 2026 年全面采用）。`public import` 把依赖的声明**传递导出**给下游；普通 `import` 则只在本模块内可见。教程项目保持简单，用普通 `import` 即可；写库时注意区分。

## 10.2 命名空间与 open

```lean
namespace MyNamespace

def x : Nat := 1

namespace Inner
def y : Nat := 2
end Inner

end MyNamespace

#check MyNamespace.x              -- Nat
#check MyNamespace.Inner.y        -- Nat

-- open：把命名空间内容引入当前作用域
open MyNamespace
#check x                          -- Nat

-- open ... in：只作用于下一条命令（Mathlib 风格）
open MyNamespace.Inner in
#check y                          -- Nat

-- open scoped：只引入记号与 scoped instance，不引入名字
-- open scoped BigOperators   -- 启用 ∑ ∏ 记号（第17章）
```

**export**：把一个命名空间的名字"转发"到外层，常用于整理公共 API：

```lean
namespace Base
def helper : Nat := 1
end Base

namespace Api
export Base (helper)     -- Api.helper 与 Base.helper 同名可用
end Api

#check Api.helper
```

## 10.3 section / variable / include / omit

```lean
section MySection

variable (α β : Type) [Add α]

-- doubleAdd 实际用到 α 和 Add α 实例，它们被自动引入
def doubleAdd (a : α) : α := a + a

-- β 没被用到，不会出现在 addBoth 的签名里（Lean 按需引入）
def addBoth (a b : α) : α := a + b

end MySection

#check @doubleAdd   -- {α : Type u_1} → [Add α] → α → α
#check @addBoth     -- {α : Type u_1} → [Add α] → α → α → α
```

`variable` 的引入是**惰性**的：只有实际用到的变量才进入声明签名。控制技巧：

```lean
section Control
variable {α : Type} (l : List α)

-- include：强制引入未使用的 variable
include l in
theorem forced : l = l := rfl

-- omit：强制不引入某个 variable（通常用于清理）
-- omit l in ...
end Control
```

## 10.4 Lake 配置详解

`lakefile.lean`（也可用 `lakefile.toml`，新版模板默认 toml）：

```lean
import Lake
open Lake DSL

package my_project where
  version := v!"0.1.0"

-- 依赖：git 指定 rev/tag
require mathlib from git
  "https://github.com/leanprover-community/mathlib4" @ "main"

-- 或本地路径依赖（教程项目采用的方式）
-- require mathlib from "G:/github/lang/mathlib4"

@[default_target]
lean_lib MyProject where

-- 可执行目标
lean_exe my_exe where
  root := `MyProject.Main
```

**lake-manifest.json** 锁定每个依赖的确切 commit——应提交到 git，保证可复现构建。版本不兼容时（如工具链升级后），需要同步更新 manifest 中的 rev 与 `lean-toolchain`。

## 10.5 常用 Lake 命令

```bash
lake init <name>            # 初始化项目
lake build                  # 构建 default_target
lake build <module>         # 构建指定模块/包
lake clean                  # 清理构建产物
lake exe cache get          # 下载 mathlib 预编译缓存（git 依赖时必做）
lake env lean file.lean     # 在项目环境中编译单文件（本教程验证方式）
lake env lean --run x.lean  # 编译并执行 main
lake update                 # 更新依赖（改 rev）
lake deps                   # 查看依赖树
```

## 10.6 属性（attribute）速览

属性是挂在声明上的元数据，驱动各种自动化：

```lean
@[simp]                -- 加入 simp 引理集
@[ext]                 -- 注册 ext 战术的外延引理
@[instance]            -- 注册类型类实例（与 instance 关键字等价）
@[default_instance]    -- 默认实例（如 OfNat）
@[inline]              -- 编译器内联提示
@[deprecated name]     -- 标记废弃（mathlib 大规模清理依赖它）
@[inherit_doc]         -- 继承文档
```

Mathlib 废弃清理机制：定理改名后保留 `@[deprecated]` 别名若干个月，再批量删除（2026-09-15 的最新提交就删除了 2021~2026-02 的废弃别名）——所以**教程代码要跟最新 mathlib 对齐**，这正是本教程的维护方式。

---

> 上一章：[09 · 结构与记录](09-structures.md) ｜ 下一章：[11 · Mathlib4 概述](11-mathlib-overview.md) ｜ 返回：[README](../README.md)
