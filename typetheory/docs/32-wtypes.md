# 32 W 类型与良序：归纳定义的一般形式

> 对应读本：Nordström 第 15–16 章（良序 / 一般树集合构造子）。
> 代码：`examples/32_wtypes/`——三家同构实现 W，用它编码
> 「叶/单/双树」与 ℕ（`2+3=5` 全机器验证）+ Odd/Even 相互
> 依赖族与空域函数技巧的 Agda 件。

## 32.1 一个构造子统治一切

```text
W (A : Type) (B : A → Type)
  sup : (a : A) → (B a → W A B) → W A B
```

直觉：**一棵树 = 一个标签 + 恰好 B a 个孩子**。A 是标签集
（书里叫**构造子集合**：形成树的方式），B 是**选取子族**
（每个标签的孩子槽位）。W 的引入规则与计算规则（wrec）：

```text
W-引入    a ∈ A,  b(x) ∈ W(A,B)[x ∈ B(a)] ⟹ sup(a,b) ∈ W(A,B)
W-相等性  sup(a,b) 的值由 a 与 b 逐点相等决定
```

「叶子的技巧」是书 15 章的第一个惊喜：**没有专门的叶引入
规则**——若某标签 a 的 B(a) 为空集，sup(a, ·) 的函数参数用
空消去供给：

```text
B(a) = {} ⟹ (x)case⊥(x) : B(a) → W(A,B)     -- 空域上的函数
leaf ≝ sup(a, case⊥)                          -- 零个孩子 = 叶
```

Agda 里这就是荒谬模式的一行：

```agda
-- 叶技巧：空域上的函数（书 15 章的 case⊥）
noChild : ⊥ → W Tag arity
noChild ()

leaf : W Tag arity
leaf = sup leaf noChild
```

二元树的标准编码（书 15 章例）：标签集 {leaf,node}、
B(leaf)={}、B(node)={left,right}——**注意构造族 B 本身要用
全域 U**（`Set(case(...)(x,⊤̂,{left,right}̂))`），因为 B 是
「标签到集合」的函数、集合得有地方住——31 章的 U 在这里
第一次成为必需品而非方便。

## 32.2 两个编码实测

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

## 32.3 W 的递归：良序归纳

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

## 32.4 一般树 Tree(A,B,C,d)：相互依赖的归纳定义

书 16 章的收官构造子把 W 推广到**相互依赖的归纳定义族**。
动机例子是 ML 的互递归数据类型：

```text
datatype Odd  = so of Even
       Even = zero | se of Odd
```

W 表达它「可能但相当复杂」；Tree 构造子直接给四个参数：

| 参数 | 名号 | 文法直觉 |
|---|---|---|
| A | 名集合 | 非终结符的集合（{Odd,Even}） |
| B(x) | 构造子集合 | 非终结符 x 的**子句**名集合 |
| C(x,y) | 选取子族 | 子句 y 里非终结符**位置**的名集合 |
| d(x,y,z) | 部件集合名 | 位置 z 对应的非终结符 |
| a | 起始符号 | 要哪一个集合 |

Tree(A,B,C,d)(a) 是**集合族**（每个 a∈A 一个集合），它是
不动点方程组的解：

```text
W 的方程:   W(B,C)  = FIX (λX.(Σy∈B) C(y) → X)        -- 非依赖 →
Tree 的方程: T(x)   = FIX (λT.(x)(Σy∈B(x))(Πz∈C(x,y)) T(d(x,y,z)))
                                                       -- 依赖 Π
```

「一般性在于非依赖函数集合 → 变成依赖函数集合 Π」——族中
每个成员可以由族中**其他**成员定义（d 指路），这就是相互
依赖。Agda 件里 Odd/Even 用现代语法直写（相互归纳是内建的）：

```agda
mutual
  data Evenᵐ : Set where
    zeroᵉ : Evenᵐ
    se    : Oddᵐ → Evenᵐ
  data Oddᵐ : Set where
    so    : Evenᵐ → Oddᵐ
```

对照：W 路线要把「名集合 + 构造子集合 + 选取子族 + 部件名」
全部显式化（Tree 的四参数正是把 data 声明的隐式结构**元层
化**）；现代 data 声明把这套结构交给编译器记——但 62 章 LF
的形式化（把类型论本身做成 LF 常量）与归纳模式的一般理论
仍然需要这套显式参数化。

**外延相等性的必要性**（书 16 章开篇的提醒）：「当我们用
良序和一般树表示归纳定义类型时，我们必须有外延相等性去
得到正确的消去和相等性规则」——这就是 29.3 节 Eq 集合
「仅在良序和一般树几章必须用」的兑现处。直观原因：Tree
的元素携带函数分量（Πz:T(d(x,y,z))），wrec/treerec 的相等性
规则要对函数分量做逐点论证，判断层的定义相等够不着——
只有 Eq 的强消去（或函数外延）能把逐点相等升格为元素相等。
现代实现（Agda/Coq/Lean）绕开它的办法是**让树元素本身
结构化**（data 声明的构造子不带函数参数……除了 W 这种），
从而结构归纳就够了——W 在 Coq/Agda 里能做内涵消去，正是
因为 sup 的函数参数在模式匹配下按结构对待。

## 32.5 超越 W：归纳-递归与归纳族

W 有两个「表达不到」的地方，各自长出一门理论：

1. **标签带数据负载**：W 的标签集 A 里可以有任意类型（如
   `List A` 的 cons 标签带着 A 元素）——本可以表达；但
   **索引族**（`Vec A n` 的 n 出现在类型里）不行 → 归纳族
   （Coq/Lean/Agda 的 indexed inductive）；
2. **元数依赖整棵子树**（Dybjer 的归纳-递归）：类型声明里
   的递归调用出现在元数计算中——Agda 能写，Coq/Lean 不能
   （它们用 axiomatic 的方式补）。

树集合构造子最初引入于 Petersson & Synek 1989 [88]——
相互依赖归纳定义的原始文献。本指南 19 章的归纳族是工程
主流，W 是理论根基——两边对照，「声明即原理」（构造子 →
消去子 → 归纳原理）的机制完全同构。

> **坑位速记**
> ① Coq 的 W 构造子是 `(B a → W A B) → W A B`（**高阶**），
>   不是 `B a → W A B → W A B`——写错后一切下游错误都是谜；
> ② Coq 里 `sup leaf (fun e => match e with end)` 的空匹配
>   看不透 `arity leaf ≡ Empty_set`——用 `@sup Tag arity leaf`
>   把 B 钉死即可（隐式 B 未解时 match 无从判定空类型）；
> ③ Lean `Wt.rec`/`Tag.rec` 的**代码生成器不支持**——要
>   `#eval` 就用方程语法（WF 版），要 rfl 两版都行；
> ④ Coq 递归子的参数 A B 默认显式——`Arguments Wt_rect {A B}`
>   省掉每次手喂；
> ⑤ Lean 在 `match a with` 里用 `if b then ...` 而 b 的类型是
>   `arity .binary`（≠语法 Bool）时 if 失明——match on b 直接写；
> ⑥ Agda 的 mutual 块里两个 data 声明的**先后次序无关**，
>   但若用 `mutual` 外的类型别名引用会循环——Odd/Even 直写
>   最稳（Tree 四参数路线是元层功课，教学件不做编码）。

---

上一章：[31 全域](31-universes.md) · 下一章：[33 子集与强制](33-subtype.md)
