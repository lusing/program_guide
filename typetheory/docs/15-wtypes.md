# 15 W 类型与良序：归纳定义的一般形式

> 对应读本：Nordström 第 15–16 章（良序 / 一般树集合构造子）。
> 代码：`examples/15_wtypes/`——三家同构实现 W，并用它编码
> 「叶/单/双树」与 ℕ（`2+3=5` 全机器验证）。

## 15.1 一个构造子统治一切

```text
W (A : Type) (B : A → Type)
  sup : (a : A) → (B a → W A B) → W A B
```

直觉：**一棵树 = 一个标签 + 恰好 B a 个孩子**。A 是标签集，
B a 是「标签 a 要几个孩子」（以类型给出——0 个孩子用空类型、
1 个用 Unit、n 个用 n 元枚举）。

Nordström 第 15 章的良序（well-ordering）正是这个结构；第 16 章
的「一般树集合构造子」把它推广为现代的**归纳类型声明**：

> 每个归纳类型 = 一组（构造子名 → 元数）的表。

「Nat = 零元构造子 z + 一元构造子 s」「List A = 零元 nil +
二元 cons」——都是 `(标签集, 元数函数)` 的特例。

## 15.2 两个编码实测

**编码一：叶/单/双树**。标签 `Tag = leaf | unary | binary`，
元数 `arity leaf = ⊥, arity unary = ⊤, arity binary = Bool`：

```lean
def size : Tree → Nat
  | .sup a f =>
      match a with
      | .leaf => 1                          -- 零个孩子
      | .unary => 1 + size (f PUnit.unit)   -- 一个
      | .binary => 1 + size (f true) + size (f false)
```

**编码二：ℕ = W Bool**。`false` 当零（零孩子）、`true` 当后继
（一孩子）：

```lean
def addW : NatW → NatW → NatW
  | .sup false _, n => n                    -- 0 + n = n
  | .sup true f, n => .sup true (fun u => addW (f u) n)
```

`toNat (addW 2 3) = 5` 三家全部机器验证。在 W-ℕ 上写加法时，
「哪一侧递归」不再由语法决定（没有 `Nat.rec` 可用），而是
W 自身的良序归纳——**数据形状驱动递归**，这正是 W 作为
「归纳定义一般形式」的教学价值。

## 15.3 W 的递归：良序归纳

W 的消去子（自动生成）是：

```text
W-rec : C → ((a, f, ih : ∀x, C (f x)) → C (sup a f)) → (w : W) → C w
```

递归调用的合法性来自 `f x` 是 `sup a f` 的「孩子」——树高下降。
三家工程面：

- **Lean**：`Wt.rec` 可用但**代码生成器不支持**（`#eval` 会报
  "code generator does not support recursor"）——可执行版用
  方程语法（走 WF 递归），rfl 断言两版都吃；
- **Coq**：`Fixpoint` 的守卫检查对「经 f 的递归调用」可以直接
  过（`addW` 用了），但更复杂的场合用 `Wt_rect`（`Print`
  出来就是 Noetherian 归纳）；
- **Agda**：终止检查器对 `f x` 结构下降天然放行——观感最接近
  数学定义。

## 15.4 超越 W：归纳-递归与归纳族

W 有两个「表达不到」的地方，各自长出一门理论：

1. **标签带数据负载**：W 的标签集 A 里可以有任意类型（如
   `List A` 的 cons 标签带着 A 元素）——本可以表达；但
   **索引族**（`Vec A n` 的 n 出现在类型里）不行 → 归纳族
   （Coq/Lean/Agda 的 indexed inductive）；
2. **元数依赖整棵子树**（Dybjer 的归纳-递归）：类型声明里
   的递归调用出现在元数计算中——Agda 能写，Coq/Lean 不能
   （它们用 axiomatic 的方式补）。

Nordström 第 16 章「树集合构造子的异体」预演了这些区别。
本指南 13 章的归纳族是工程主流，W 是理论根基——两边对照，
「声明即原理」（构造子 → 消去子 → 归纳原理）的机制完全同构。

> **坑位速记**
> ① Coq 的 W 构造子是 `(B a → W A B) → W A B`（**高阶**），
> 不是 `B a → W A B → W A B`——写错后一切下游错误都是谜；
> ② Coq 里 `sup leaf (fun e => match e with end)` 的空匹配
> 看不透 `arity leaf ≡ Empty_set`——用 `@sup Tag arity leaf`
> 把 B 钉死即可（隐式 B 未解时 match 无从判定空类型）；
> ③ Lean `Wt.rec`/`Tag.rec` 的**代码生成器不支持**——要
> `#eval` 就用方程语法（WF 版），要 rfl 两版都行；
> ④ Coq 递归子的参数 A B 默认显式——`Arguments Wt_rect {A B}`
> 省掉每次手喂；
> ⑤ Lean 在 `match a with` 里用 `if b then ...` 而 b 的类型是
> `arity .binary`（≠语法 Bool）时 if 失明——match on b 直接写。

---

上一章：[14 全域](14-universes.md) · 下一章：[16 子集与强制](16-subtype.md)
