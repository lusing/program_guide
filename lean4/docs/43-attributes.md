# 43 · 属性系统

**对标**: *Reference* 第9章（Attributes）。

属性（attribute）是 Lean 的"声明标注"机制：`@[simp]`、`@[instance]`、`@[reducible]` 这些方括号标注
不改变声明的**含义**，却改变 Lean **如何使用**它——是否参与化简、是否被自动展开、编译成什么代码。
战术 `simp`/`aesop`、类型类合成、编译器优化都由属性驱动。理解属性，才能读懂 Mathlib 的"配置层"。

> 本章为纯 Lean 核心（`import Lean`），在 4.34.1 验证。

## 43.1 属性的两种写法

属性可以**内联**在声明上（`@[attr] def ...`），也可以用 `attribute` 命令**事后**增删：

```lean
-- 内联：声明时打标签
theorem my_id (n : Nat) : n + 0 = n := Nat.add_zero n

-- 命令级：把已有声明加入/移出某属性集
attribute [simp] my_id        -- 注册为 simp 引理
example (k : Nat) : k + 0 = k := by simp   -- simp 现在能用 my_id
attribute [-simp] my_id       -- 前缀 - 表示移除
```

`attribute [simp] foo` 把 `foo` 加进 simp 集，`attribute [-simp] foo` 移除。这让"哪些引理参与自动化"
成为可调的配置，而非写死在定义里。

## 43.2 影响精细化的属性

这些属性改变类型推断、展开、instance 合成的行为：

```lean
import Lean

-- @[reducible]：标记定义"应当被积极展开"（影响统一与 instance 搜索的展开优先级）
@[reducible] def MyNat := Nat
#check (5 : MyNat)   -- 5 : MyNat（MyNat 与 Nat 可互转，因为 reducible）

-- @[class]：把 structure 标记为类型类，使其字段能被 instance 合成填充
@[class] structure HasFoo where
  x : Nat
instance : HasFoo where x := 5
#synth HasFoo        -- instHasFoo
```

| 属性 | 作用 |
|---|---|
| `@[class]` | 把 structure 变成类型类（可被 `[]` 隐式合成） |
| `@[instance]` | 注册一个类型类实例 |
| `@[reducible]` | 提高定义的展开优先级（统一/instance 搜索时优先展开） |
| `@[irreducible]` | 反之，禁止随意展开（`theorem` 默认即不可展开） |
| `@[inline]` | 提示编译器内联该函数 |
| `@[specialize]` | 允许对部分参数特化以优化 |
| `@[match_pattern]` | 允许该常量出现在模式匹配的左侧 |

```lean
-- @[inline]：小函数内联，省去调用开销
@[inline] def addOne (n : Nat) : Nat := n + 1
#eval addOne 5   -- 6
```

## 43.3 影响战术的属性

自动化战术靠属性收集"可用规则"：

| 属性 | 驱动的战术 |
|---|---|
| `@[simp]` | `simp` / `simp_arith` / `simpa` |
| `@[aesop safe/unsafe ...]` | `aesop` 证明搜索 |
| `@[norm_num]` | `norm_num` 数值化简插件 |
| `@[positivity]` | `positivity` 正性推理 |
| `@[grind]` / `@[grind =]` | `grind`（第44章） |
| `@[eliminator]` | `induction`/`rec` 的定制 |
| `@[to_additive]` | 乘法↔加法声明自动对偶生成 |

`simp` 的本质就是"遍历所有 `@[simp]` 引理做条件重写"。给引理打 `@[simp]` 要小心——
方向错或过于宽泛的 simp 引理会导致化简循环或目标爆炸。Mathlib 对 `@[simp]` 的收录有严格规范
（左端必须是"可识别的规范形"，见 `simp` 的 `lhs` 匹配机制）。

## 43.4 影响编译的属性

```lean
-- @[implemented_by]：编译后用另一个实现替换（证明语义仍针对原定义）
def slowDouble : Nat → Nat := fun n => 2 * n
@[implemented_by slowDouble]
def fastDouble : Nat → Nat
  | 0 => 0
  | n + 1 => fastDouble n + 2
#eval fastDouble 5   -- 10（实际运行的是 slowDouble）
```

| 属性 | 作用 |
|---|---|
| `@[implemented_by f]` | 编译时把调用替换成 `f`（原定义仅供证明） |
| `@[extern "name"]` | 绑定外部（C）实现 |
| `@[extern]` + opaque | 声明编译期外部符号 |
| `@[never_extract]` | 禁止把该计算提到编译期 |
| `@[csimp]` | 编译期化简规则 |

第29章详述 `implemented_by`/`extern` 的性能用法——它们是"证明用一套定义、运行用另一套"的桥梁。

## 43.5 元信息属性

```lean
-- @[deprecated]：标记旧名，引用时给警告（建议带 since 标注引入版本）
theorem add_zero' (n : Nat) : n + 0 = n := Nat.add_zero n
@[deprecated add_zero' (since := "2026-09")]
theorem old_add_zero (n : Nat) : n + 0 = n := add_zero' n
```

`@[deprecated newName (since := "...")]` 让旧名字仍可用但触发弃用警告，引导用户迁移到 `newName`。
`since` 标注引入弃用的版本（2026 起 Lean 会对缺失 `since` 的弃用属性给警告）。
文档字符串用 `@[doc "..."]` 或 `add_decl_doc`；`@[inherit_doc]` 继承父声明的文档。

> **版本陷阱**：`@[deprecated foo]` 不带 `since` 会警告
> "should specify the date or library version ... using `(since := "...")`"。新代码请补 `since`。

## 43.6 local 与 scoped 属性

属性的作用范围可控：

```lean
theorem baz (n : Nat) : 0 + n = n := Nat.zero_add n
attribute [local simp] baz       -- 仅当前 section/文件局部生效
example (k : Nat) : 0 + k = k := by simp
```

`[local simp]` 只在当前作用域把 `baz` 当 simp 引理，离开后失效——适合临时给某个证明"加料"
而不污染全局 simp 集。`scoped` 则配合 `open` 控制可见性。

## 43.7 自定义属性

属性系统本身是**可扩展的**——`@[simp]`、`@[aesop]` 都不是内核硬编码，而是用 `register_attribute`
注册的。自定义属性需要在 `initialize` 块里注册（因为要修改全局环境，属于元编程）：

```text
open Lean in
initialize myAttr : SimplePersistentAttribute Name ←
  registerAttribute {
    name := `myattr
    descr := "我的自定义属性"
    add := fun decl _ _ _ => do  -- 给 decl 打上属性时的回调（CoreM）
      logInfo m!"标记了 {decl}"
  }
```

注册后就能写 `@[myattr] def foo := ...` 或 `attribute [myattr] foo`，回调在 `CoreM` 里运行，
能读写环境、记录被标注的声明。`simp`/`aesop`/`norm_num` 的插件机制都建立在此之上。
完整的 `register_attribute` API 见 `Lean/Attributes.lean`，元编程基础见第42章。

属性是 Lean "用数据配置行为"哲学的集中体现：同一套战术，因属性集不同而能力迥异。
读懂一个 Mathlib 文件的 `@[...]` 标注，往往比读懂它的证明更能把握它的设计意图。

---

> 上一章：[42 · 元编程](42-metaprogramming.md) ｜ 下一章：[44 · 证明校验与 grind](44-proof-validation-grind.md) ｜ 返回：[README](../README.md)
