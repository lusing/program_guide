# 06 · 类型类

> 对应示例：`examples/04_typeclasses/typeclasses.lean`

类型类（typeclass）是 Lean 的接口/重载机制，也是 Mathlib 代数层次（`Monoid`、`Ring`、`Module`……）的地基。核心机制源码在 `Init/Classes.lean`、`Init/Prelude.lean`。

## 6.1 类型类基础

```lean
-- class 本质是"带自动查找的结构"：Printable α 是一个结构，
-- 里面装着 print 字段；[Printable α] 约束触发实例搜索
class Printable (α : Type) where
  print : α → String

instance : Printable Nat where
  print n := toString n

instance : Printable Bool where
  print b := if b then "true" else "false"

-- [Printable α] 是实例隐式参数：调用处自动搜索
def printTwice {α : Type} [Printable α] (x : α) : String :=
  Printable.print x ++ Printable.print x

#eval printTwice (5 : Nat)    -- "55"
#eval printTwice true         -- "truetrue"
```

**三种参数括号的速查**：

| 写法 | 名称 | 填充方式 |
|------|------|---------|
| `(x : α)` | 显式参数 | 调用处显式给出 |
| `{x : α}` | 隐式参数 | 类型推断填充 |
| `[C α]` | 实例参数 | 类型类搜索填充 |
| `⦃x : α⦄` | 严格隐式 | 只在有后续显式参数时推断（多见于 binder 记号） |

## 6.2 实例解析如何工作

当代码中出现 `x + y` 且 `x : α` 时，Lean 需要找到 `Add α` 实例。搜索算法大致是：

1. 查本地上下文（`variable` 引入的实例、Let 绑定）
2. 查全局注册的 `instance`，按**优先级**与目标头匹配
3. 递归解析实例自身的参数（比如 `Add (List α)` 需要先找到 `Add α`）

```lean
-- 实例可以有参数：α 可打印 ⇒ Option α 可打印
instance {α : Type} [Printable α] : Printable (Option α) where
  print
    | some x => s!"some({Printable.print x})"
    | none   => "none"

#eval printTwice (some 5 : Option Nat)   -- "some(5)some(5)"

-- inferInstance：手动触发搜索（调试与 #check 时的利器）
#check (inferInstance : Printable (Option Bool))

-- inferInstanceAs：搜索"定义上等于"某个类型的实例
-- 常用于给 newtype/定义别名复用已有实例
def MyNatAlias := Nat
example : Add MyNatAlias := inferInstanceAs (Add Nat)
```

## 6.3 实例优先级与 scoped

```lean
-- @[instance 100]（默认是 1000，数值越小越晚尝试……注意方向：
-- priority 越低越"兜底"）。同一个目标多个实例匹配时按优先级选择。
-- 实际代码中不常用，但 Mathlib 用它控制解析路径。

-- scoped instance：只在 open 对应命名空间后生效，避免污染全局
namespace RationalOps

scoped instance : Mul String where
  mul a b := a ++ "*" ++ b

end RationalOps

-- 全局不可用：
-- #eval "a" * "b"               -- 报错：failed to synthesize Mul String

open RationalOps in
#eval "a" * "b"                 -- "a*b"
```

Mathlib 大量用 `scoped` 挂载记号（如 `∑`、`≡ [MOD n]`），`open scoped BigOperators` 是几乎每个 Mathlib 文件的开头标配。

## 6.4 操作符重载

```lean
structure Point where
  x : Nat
  y : Nat
  deriving Repr

instance : Add Point where
  add p1 p2 := { x := p1.x + p2.x, y := p1.y + p2.y }

instance : Zero Point where
  zero := { x := 0, y := 0 }

#eval ({ x := 1, y := 2 } : Point) + { x := 3, y := 4 }   -- { x := 4, y := 5 }
#eval (0 : Point)                                          -- { x := 0, y := 0 }
```

## 6.5 类型类继承与钻石问题

```lean
-- extends：继承父类的全部字段
class MySemigroup (α : Type) extends Add α where
  add_assoc : ∀ (a b c : α), (a + b) + c = a + (b + c)

class MyMonoid (α : Type) extends MySemigroup α, Zero α where
  add_zero : ∀ (a : α), a + 0 = a
  zero_add : ∀ (a : α), 0 + a = a
```

**钻石问题**：`Ring` 既 `extends Semiring` 又 `extends AddCommGroup`，而两者最终都带来 `Add α` 实例——两条继承路径必须在**定义上相等**，否则同一个 `+` 会出现两个不同实现。Lean 的处理方式：

- 结构继承展开后字段**按位置**共享父类字段（`Point` 继承 `Point2D` 时直接复用 x、y）
- Mathlib 对代数层次用 `toXxx` 字段 + `old_structure_cmd` 传统做扁平化合并

这也是为什么 Mathlib 里几乎看不到手写代数 class 继承链——它有一套非常讲究的层次（第12章）。

## 6.6 常用标准类型类

| 类型类 | 含义 | 操作 | 源码位置 |
|--------|------|------|---------|
| `Add α` | 加法 | `a + b` | Init/Prelude |
| `Mul α` | 乘法 | `a * b` | Init/Prelude |
| `Zero α` / `One α` | 零 / 一 | `0` / `1` | Init/Prelude |
| `LT α` / `LE α` | 小于 / 小于等于 | `<` / `≤` | Init/Prelude |
| `Repr α` | 打印表示 | `repr a` | Init/Data/Repr |
| `ToString α` | 转字符串 | `toString a` | Init/ToString |
| `Inhabited α` | 有默认值 | `default` | Init/Prelude |
| `DecidableEq α` | 可判定相等 | `a = b` 可 `decide` | Init/Core |
| `BEq α` | 布尔相等 | `a == b` | Init/Core |
| `Ord α` | 全序比较 | `compare a b` | Init/Data/Ord |
| `Hashable α` | 哈希 | `hash a` | Init/Data/Hashable |
| `OfNat α n` | 数字字面量 | `42 : α` | Init/OfNat |

## 6.7 实例参数与命名实例

```lean
-- [Add α] 约束下写泛型代码
def sumDouble [Add α] (x y : α) : α := x + y + x + y

#eval sumDouble 3 4   -- 14（α 被推断为 Nat，自动找到 Add Nat）

-- 命名实例便于显式引用/检查（通常交给搜索即可）
instance namedAdd : Add Nat where
  add := Nat.add

-- @ 显式给实例参数（第 5 个参数位是 [inst]）
#check @sumDouble Nat namedAdd 3 4
```

---

> 上一章：[05 · 模式匹配与递归](05-pattern-matching.md) ｜ 下一章：[07 · 命题与证明](07-propositions.md) ｜ 返回：[README](../README.md)
