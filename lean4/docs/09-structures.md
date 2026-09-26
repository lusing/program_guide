# 09 · 结构与记录

> 对应示例：`examples/07_structures/structures.lean`

`structure` 是"只有一个构造子的归纳类型"，编译器额外生成**投影函数**（字段访问器）与 eta 规则。核心实现：`Init/Prelude.lean` 与 `Lean/Elab/Structure.lean`。

## 9.1 结构定义与三种构造语法

```lean
structure Person where
  name : String
  age  : Nat
  deriving Repr

-- 语法一：命名记法（推荐，可读性好）
def alice : Person := { name := "Alice", age := 30 }

-- 语法二：匿名构造器 ⟨⟩（按字段顺序）
def bob : Person := ⟨"Bob", 25⟩

-- 语法三：显式调用构造子 mk
def carol : Person := Person.mk "Carol" 28

#eval alice.name   -- "Alice"
#eval bob.age      -- 25
```

## 9.2 点号记法（dot notation）的工作机制

`p.x` 的解析规则：Lean 先看 `p` 的类型 `Person`，再在 `Person` 命名空间下找 `x`/`x` 开头的函数。所以：

```lean
-- 这个定义让 p.greet 可用（函数在 Person 命名空间且首参是 Person）
def Person.greet (p : Person) : String := s!"Hi, I'm {p.name}"
#eval alice.greet    -- "Hi, I'm Alice"

-- 点号记法不限于字段：任何 Person → β 的函数都能这样调用
def Person.birthday (p : Person) : Person := { p with age := p.age + 1 }
#eval alice.birthday.age    -- 31
```

这就是为什么 Mathlib 定理可以写成 `hp.dvd_mul`、`hf.measurable`——定理命名空间与点号记法是一体的（第 11.4 节详解）。

## 9.3 结构更新

```lean
-- { old with field := v }：拷贝并覆盖
def alice' : Person := { alice with age := 31 }
#eval alice'.name    -- "Alice"（其余字段保留）

-- 多字段同时更新
def alice'' := { alice with name := "Alice Smith", age := 32 }

-- 嵌套结构的更新也支持点路径（Lean 4.x 起）
structure Config where
  server : String
  port : Nat
deriving Repr
structure App where
  name : String
  cfg : Config
deriving Repr

def myApp : App := { name := "demo", cfg := { server := "localhost", port := 8080 } }
def myApp2 := { myApp with cfg.port := 9090 }
#eval myApp2.cfg.port    -- 9090
```

## 9.4 参数化结构与字段依赖

```lean
structure Point2D (α : Type) where
  x : α
  y : α
  deriving Repr

def p1 : Point2D Nat := { x := 1, y := 2 }

-- 字段类型可以依赖前面的字段（依赖记录）
structure BoundedVec where
  len : Nat
  data : Fin len → Nat

-- 字段可以带类型类约束
structure SortedList (α : Type) [LE α] where
  data : List α
```

## 9.5 结构继承

```lean
structure ColoredPoint (α : Type) extends Point2D α where
  color : String
  deriving Repr

def cp : ColoredPoint Nat := { x := 10, y := 20, color := "red" }

#eval cp.x            -- 10（父字段直接可访问：扁平化继承）
#eval cp.color        -- "red"
#eval cp.toPoint2D    -- 父结构投影：Point2D.mk 10 20

-- 多重继承
structure Named where
  name : String

structure NamedColoredPoint (α : Type) extends Point2D α, Named where
  color : String

-- extends 多个父结构时，公共祖先字段只保留一份（解决钻石）
```

## 9.6 匿名构造器模式匹配

```lean
-- ⟨x, y⟩ 既是构造记法也是匹配模式
def getX (p : Point2D α) : α :=
  match p with
  | ⟨x, _⟩ => x

-- have/let 里直接解构
def printPoint (p : Point2D Nat) : String :=
  let ⟨x, y⟩ := p
  s!"({x}, {y})"

-- 定理证明中同样可用（intro ⟨x, y⟩）
example (p : Point2D Nat) : p.x + p.y = p.y + p.x := by
  obtain ⟨x, y⟩ := p
  simp [Nat.add_comm]
```

## 9.7 结构与类型类的关系

**class 就是 structure**：`class C α where ...` 定义一个结构，附带把 `instance` 注册进类型类搜索表。反过来，结构可以 `extends` class：

```lean
-- 打包（bundled）与散装（unbundled）两种设计
structure Point3D (α : Type) [Add α] where    -- 类型类约束在参数层（unbundled 风格）
  x : α
  y : α
  z : α

-- class 作为结构的字段（bundled 风格，Mathlib 的范畴论等使用）
structure PointedType where
  carrier : Type
  pt : carrier
```

Mathlib 的代数层次（`Monoid` 等）是 class，但底层就是带 `toXxx` 父投影字段的 structure（见第 12 章）。

---

> 上一章：[08 · 战术基础](08-tactics.md) ｜ 下一章：[10 · 项目管理与模块系统](10-modules-projects.md) ｜ 返回：[README](../README.md)
