# 24 · 立方类型论初步

前面 23 章里，等式 `x ≡ y` 一直是个归纳数据类型：只有 `refl` 一个构造子，
证明要么"两边本来就一样"，要么靠 `J`/subst 做替换。这种 intensional 等式
很好用，但它有一个著名的欠账：**函数外延性和 univalence 在纯 MLTT 里证不
出来**，第 17 章我们只能把 `Function.Extensionality` 当 postulate 摆着。
本章引入 Agda 的 **立方模式（cubical mode）**：等式被解释成**路径**——
`x ≡ y` 是从 `x` 走到 `y` 的一条道路，参数 `i` 取值于一个区间 `I`，
`i0` 是起点、`i1` 是终点。在这个解释下，univalence（等价即相等）不再是
公理，而是一个能用 `primGlue` 写出来的**定理**；函数外延性是一行 lambda。
代价也不小：立方模式是"传染性"的选项，且与编译后端不兼容——本章所有
取舍都以本机 Agda 2.8.0 + stdlib 2.3 的实测报错为准。

对应示例：`../examples/Ex24_cubical.agda`

本章代码片段全部出自示例文件（逐行讲解见 24.5–24.7 节）；报错文本均为
本机实测原样粘贴，探针文件测完已删除。

## 24.1 先跑起来：怎么开立方模式

唯一的开关是文件第一行的 pragma：

```agda
{-# OPTIONS --cubical #-}
module Ex24_cubical where
```

注意三点（都是实测）：

**其一，`≡` 不会自动出现。** 立方模式下 `Agda.Builtin.Cubical.Path` 里的
`_≡_` 才是"路径等式"，得自己 import。探针里只写 `--cubical` 不 import
就用 `≡`，直接报错：

```text
error: [NotInScope]
Not in scope:
  ≡
when scope checking ≡
```

**其二，`i0`、`i1` 是内建的，import 都不用。** 示例第 30 行
`nat-path i0 ≡ 5` 里的 `i0` 没有任何对应的 import 语句，这是立方模式
注册 `BUILTIN IZERO/IONE` 的效果；`I` 本身和 `PathP` 则要从
`Agda.Primitive.Cubical` 打开（`Agda.Builtin.Cubical.Path` 也
`public` 转出了 `PathP`，但如果你 `using (_≡_)` 做了过滤就带不进来，
实测 `Not in scope: PathP`）。

**其三，立方代码"只出不进"。** 立方模块可以 import 普通模块（示例里
`Agda.Builtin.Nat`、探针里 stdlib 的 `Data.Nat` 都正常工作），反过来
普通模块 import 立方模块会被拒——实测对一个不带 pragma 的文件写
`open import Agda.Builtin.Cubical.Path using (_≡_)`：

```text
error: [InfectiveImport]
Importing module Agda.Builtin.Cubical.Path using the
--cubical/--erased-cubical flag from a module which does not.
```

和第 22/23 章见过的 `--guardedness`/`--rewriting` 一样，这是传染性选项。
好消息是它与 `--safe`、`--guardedness` **可以共存**：
`{-# OPTIONS --cubical --safe #-}`、`{-# OPTIONS --cubical --guardedness #-}`
两个探针都退出码 0（`--safe` 依旧禁止 `postulate`：
`Cannot postulate X with safe flag`）。真正的代价不在选项组合，而在
生态和编译链，见 24.4 与 24.8 节。

## 24.2 直觉：等式即路径，refl 是常道路

普通模式下 `refl` 是构造子；立方模式下它就是**常值函数**——区间上每一点
都停在同一个值。示例第 23–24 行干脆自己重新定义了一遍：

```agda
refl : ∀ {ℓ} {A : Set ℓ} {x : A} → x ≡ x
refl {x = x} = λ i → x
```

对，`x ≡ y` 就是个函数类型！给定"路径参数" `i : I`，返回路径上那一点。
`λ i → x` 就是"哪也不去"的常道路，所以 refl 不需要任何公理身份。
第 27–31 行验证端点语义：

```agda
nat-path : 2 + 3 ≡ 5
nat-path = refl

endpoint-check : nat-path i0 ≡ 5
endpoint-check = refl
```

`nat-path` 是常道路（因为 `2 + 3` 和 `5` 本来就可判定相等），在任何
区间点取值都是 `5`；把 `i0` **应用**到路径上得到起点——这个"路径可以
像函数一样被求值"的手感，就是立方模式与 11 章归纳等式的根本区别。
归纳等式里你只能对 `p : x ≡ y` 做模式匹配（拆成 refl 一种情形）；
立方等式里你可以直接问 `p i` 是什么。

## 24.3 PathP 与区间 I

一般化一步：`_≡_` 其实是 **`PathP`**（P = dependent Path）的特例，
`Agda.Builtin.Cubical.Path` 源码里就一行：

```agda
_≡_ : ∀ {ℓ} {A : Set ℓ} → A → A → Set ℓ
_≡_ {A = A} = PathP (λ i → A)
```

`PathP (λ i → A i) a b` 表示一条从 `a` 到 `b` 的路径，但**类型本身
也随 `i` 滑动**：起点处 `a : A i0`，终点处 `b : A i1`，中间点
`p i : A i`。非依赖情形把 `A i` 常数化，就退回 `≡`。探针验证过：

```agda
pp : PathP (λ i → Bool) true true
pp = λ i → true
```

区间 `I` 上的运算（示例第 16–17 行 import 并改名）：

| 原始名 | 示例记法 | 含义 |
|---|---|---|
| `primIZero` / `primIOne` | `i0` / `i1` | 端点（自动在作用域） |
| `primINeg` | `~ i` | 翻转：`~ i0 = i1` |
| `primIMax` | `_∨_` | max：`i0 ∨ i = i`，`i1 ∨ i = i1` |
| `primIMin` | `_∧_`（示例未用） | min |
| `primTransp` | `transp` | 沿路径族搬运 |
| `primHComp` | 示例未用 | hcomp（组装高维立方体，本章不碰） |

注意 `I` **不是普通数据类型**：它没有可模式匹配的构造子（你不能用
`case i of` 对路径逐点做分案），`∨`/`∧`/`~` 满足的是格论恒等式而非
布尔代数（比如排中 `i ∨ ~ i` 不是常数）。它是类型论里的"几何材料"，
只用来搭路径和高维方体。

## 24.4 启用 --cubical 的实测代价清单

24.1 讲了开法，这里给全账。所有条目都有探针错误文本或退出码背书：

1. **`--compile` 直接不可用**：`agda --compile` 一个 `--cubical` +
   `--guardedness` + stdlib `IO` 的程序，类型检查退出码 0，但编译报
   `error: [CubicalCompilationNotSupported]`
   `Compilation of code that uses --cubical is not supported.`。
   也就是说 20 章那条"编译出可执行文件"的流水线在立方模式下整条断掉。
2. **传染性断绝复用**：普通章节/普通项目文件 import 不进来
   （InfectiveImport，见 24.1），立方代码是单向叶子——它吃别人，
   别人不能吃它。
3. **stdlib 2.3 没有 Cubical 目录**：`ls /usr/share/agda-stdlib/src |
   grep -i cubical` 返回空；`open import Cubical.Foundations.Prelude`
   实测 `FileNotFound`（搜索路径里根本没有 `Cubical/` 目录）。完整的
   立方数学库（`Cubical.Foundations.*`、HITs、平截断等）在独立的
   agda-cubical 库/新版 stdlib 里，本机没有，故示例被迫全部钉在
   `Agda.Builtin.Cubical.*` 原始层——这就是示例文件头注释的由来。
4. **但 stdlib 并非完全不能用**：探针证实 `--cubical` 文件里
   `open import Data.Nat` 和 `open import Relation.Binary.PropositionalEquality
   using (_≡_; refl; sym; trans; subst)` 都正常（退出码 0）——立方模式
   下归纳等式 `≡` 就是 `PathP` 的别名，两套写法可以互认。

## 24.5 示例逐行（一）：路径运算与"这只是一个实例"

示例第 37–44 行，三个运算全是一行 lambda 或一行原始操作：

```agda
sym : ∀ {ℓ} {A : Set ℓ} {x y : A} → x ≡ y → y ≡ x
sym p = λ i → p (~ i)

ap : ∀ {ℓ} {A B : Set ℓ} (f : A → B) {x y : A} → x ≡ y → f x ≡ f y
ap f p = λ i → f (p i)

transport : ∀ {ℓ} {A B : Set ℓ} → A ≡ B → A → B
transport p x = transp (λ i → p i) i0 x
```

- `sym`：把参数翻转，路径倒着走。`~ i` 使 `i = i0` 时取 `p i1 = y`。
- `ap`：逐点作用 `f`——"函数的像保持道路"，在归纳等式里这需要
  subst + 一堆证明，这里是显然的。
- `transport`：`transp (λ i → p i) i0 x` 读作"沿族 `λ i → p i` 从
  端点 `i0` 起，把 `x : p i0` 拖到 `p i1`"。第二个参数是"从哪头开始
  拖"，`primTransp` 的完整能力还包括带面约束 `φ` 的部分搬运，示例
  只用最普通的形态。

接着第 47–51 行：

```agda
sym-sym-check : sym (sym nat-path) ≡ nat-path
sym-sym-check = refl

ap-check : ap suc nat-path ≡ refl {x = 6}
ap-check = refl
```

这两行成立的原因是：`nat-path` 就是常值 `λ i → 5`，`sym (sym …)`、
`ap suc …` 逐点化简后是**可判定的**表达式相等，于是连"路径间等式"
都能用 refl 关。**读示例时千万别把它们当成一般定理**——对任意路径
`p`，`sym (sym p) ≡ p` 需要真正的路程同伦论证，常值路径只是最退化的
情形。这两个 check 的定位是"端点/计算语义没写错"的自检。

## 24.6 示例逐行（二）：ua——用 primGlue 把等价拼成路径

第 57–61 行是全章技术核心：

```agda
ua : ∀ {ℓ} {A B : Set ℓ} → A ≃ B → A ≡ B
ua {A = A} {B = B} e i =
  primGlue B
    (λ { (i = i0) → A ; (i = i1) → B })
    (λ { (i = i0) → e ; (i = i1) → pathToEquiv (λ i → B) })
```

逐层拆：

- 整体是"一个以 `i` 为参数的路径"，逐点回答：`ua e i` 这个类型在
  区间点 `i` 处是什么。终点 `i1` 处必须字面是 `B`（因为 `A ≡ B` 的
  终点语义要求如此），所以外面套 `primGlue B …`——"以 `B` 为底"。
- `primGlue` 的三个参数（源码签名见
  `/usr/share/libghc-agda-dev/lib/prim/Agda/Builtin/Cubical/Glue.agda`）：
  底类型 `A`（这里 `B`）、面约束下的类型族 `T : Partial φ (Set ℓ')`、
  以及每块面上"该类型 ≃ 底类型"的等价。示例的面约束取遍整个区间
  （两个边界都给了），第一个面参数用模式 `{ (i = i0) → A ; (i = i1) → B }`
  写法：`i` 走到 `i0` 时该点类型是 `A`，配等价 `e : A ≃ B`；走到
  `i1` 时是 `B` 自己，配**恒等等价** `pathToEquiv (λ i → B)`。
- `primGlue B T e` 的直觉：一个"和 `B` 等价、但在面上显形为 `T`"的
  类型。于是 `ua e` 逐点滑出一条从 `A` 到 `B` 的类型路径——
  **univalence 从"公理"降级为"用 Glue 造路径的构造"**。

一个实测细节：`pathToEquiv` 的自变量类型是字面的区间族
`(i : I) → Set ℓ`，示例里写 `(λ i → B)` 而不是已有的路径名。探针把
已构造好的路径直接喂给它：`pathToEquiv boolPath`，报错：

```text
error: [UnequalTerms]
(Bool ≡ B̂) !=< ((i : Agda.Primitive.Cubical.I) → Set (_ℓ_3 i))
when checking that the expression boolPath has type
(i : Agda.Primitive.Cubical.I) → Set (_ℓ_3 i)
```

`≡`（即 `PathP`）不会 η-展开成区间 lambda，务必传 `(λ i → …)` 形式。

**没做的事也要说清**：`ua` 的一般计算律（沿 `ua e` 搬运等于 `equivFun e`
作用、`pathToEquiv (ua e) ≡ e`）在本机只用**下一个实例**验证过特例
（`transport-check`，见下节），一般形式属于 agda-cubical 库
`Cubical.Foundations.Equivalence` 的地盘，本机 stdlib 2.3 没有，未验证。
文献定位：构造本身来自 Cohen–Coquand–Hubert–Mörtberg 的立方模型论文
"Cubical Type Theory: a constructive interpretation of the full
univalence axiom"（2016），HTT 书（Homotopy Type System 编写组，2013）
第 2.27 节讲 univalence 的动机，但其模型与 Agda 的有界立方区间
`[0,1]` 细节并不同。

## 24.7 示例逐行（三）：完整实例 `Bool ≡ (⊤ × Bool)`

第 67–89 行是本章的"整机试车"。目标：造一个真·非平凡（元素层面
不同构型、结构上又完全初等）的等价，走一遍 `≃ → ≡ → transport`。

```agda
B̂ : Set
B̂ = Σ ⊤ λ _ → Bool          -- 即 ⊤ × Bool

swap : Bool → B̂
swap b = tt , b
```

`swap` 显然是等价（`⊤` 里没有信息），但要**证明**它是等价——立方
原始层里 `A ≃ B` 定义为"函数 + 每条纤维可缩"（`isEquiv`，record）：

```agda
swapIsEquiv : isEquiv swap
swapIsEquiv .equiv-proof y .fst = snd y , refl
swapIsEquiv .equiv-proof y .snd (z , p) i =
  snd (p (~ i)) , λ j → p (j ∨ ~ i)
```

两行 copattern。第一行给中心点：纤维 `fiber swap y = Σ x → swap x ≡ y`
里的 `x` 取 `snd y`（`y` 的 Bool 分量），路径取 `refl`——这里
`swap (snd y)` 要**字面**等于 `y` 才能 refl；`y = (u , snd y)`，`u : ⊤`
未必是 `tt`，全靠**无字段 record 的 η 规则**（`⊤` 的任何元素都判定
等于 `tt`）把 `u` 化没了。这个 η 在普通模式同样成立，是"立方没改变
数据类型判定等式"的又一佐证。

第二行给"中心 ≡ 任意点"的路径。任意点 `(z , p)` 中 `p : swap z ≡ y`
是条路径。对每个 `i`，构造纤维点
`(snd (p (~ i)) , λ j → p (j ∨ ~ i))`：

- 位置分量 `snd (p (~ i))`：`i = i0` 时取 `p i1 = y` 的 Bool 分量
  `snd y`（回到中心）；`i = i1` 时取 `p i0 = swap z = tt , z` 的分量
  `z`（到达目标点）。
- 路径分量 `λ j → p (j ∨ ~ i)`：一个**方体**（路径的路径），`j` 从
  `~ i` 扫到 `i1`。`i = i0` 时 `j ∨ i1 ≡ i1`，整条边退化为常数 `p i1`
  ——即中心点要求的 `refl`；`i = i1` 时 `j ∨ i0 ≡ j`，整条边就是
  `p` 本身——即目标点的第二个分量。`∨` 在这里的作用就是"在滑动
  过程中逐点解锁被 `i` 钉住的边"。

有了等价，剩下的三行就是流水账，而且**每一行都带计算内容**：

```agda
boolPath : Bool ≡ B̂
boolPath = ua (swap , swapIsEquiv)

transport-check : transport boolPath true ≡ (tt , true)
transport-check = refl

swap-fun : equivFun (swap , swapIsEquiv) false ≡ (tt , false)
swap-fun = refl
```

`transport-check` 值得多看一眼：在 HoTT 风格（postulate UA）下
"沿 `ua e` 搬运等于 `e` 的正向作用"是不可判定的，只能公理化为命题；
而这里 `transport boolPath true` **计算**出了 `(tt , true)`，refl 直接
过关。这就是立方模式招牌卖点"univalence 有计算内容"的最小实证。
探针补充：反向搬运同样可算——`transport (sym boolPath) (tt , true) ≡
true` 也是 `refl`（文件未保留）。

## 24.8 Univalence 是定理；那普通开发为何仍默认不用立方

定理侧再演示一个（探针验证过、示例未收录的著名一行）——函数外延性：

```agda
funExt : ∀ {ℓ} {A B : Set ℓ} {f g : A → B} → (∀ x → f x ≡ g x) → f ≡ g
funExt p = λ i x → p x i
```

"逐点有路径"就是"函数层面有路径"，只是把 `i`、`x` 两个参数换了个
次序（交换方块的两个方向）。在 17 章里这是 postulate，在这里是零成本的
lambda。同理，`transport`/`ap`/`sym` 的一切好性质都不需要"对 ≡ 做
模式匹配"那套归纳戏法。

但**本教程及绝大多数 Agda 工程仍默认不用它**，理由是工程性的：

1. **编译链断裂**（24.4 第 1 条实测）：写得出跑不了，`--compile` 拒绝
   一切立方代码；
2. **生态割裂**：本机 stdlib 2.3 无 Cubical 库（实测 FileNotFound），
   而 11/13/14 章的整条证明主线（`PropositionalEquality` 的
   `subst/cong/sym`、`≡-Reasoning`、`Relation.Binary` 代数结构）都是
   围绕可模式匹配的等式建的，跨不过 InfectiveImport 的单向门；
3. **收益面窄**：如果你的定理不需要 UA/外延性/HIT，立方模式提供不了
   免费的好处，却改变了等式的推理纪律（不能对路径做无端点的 refl
   分案，见 24.9 坑 4）；
4. **判定等式并未变松**：探针实测，`(b : Bool) → notB (notB b) ≡ b`
   直接 `refl` 依然失败：

   ```text
   error: [UnequalTerms]
   notB (notB b) != b of type Bool
   when checking that the expression refl has type notB (notB b) ≡ b
   ```

   必须对 `b` 分案（`notNot true = refl; notNot false = refl`，探针
   验证通过）。数据类型该卡还是卡——立方只多给了路径工具，没有
   削弱终止性/判定性检查（`--cubical --safe` 照常拒绝 postulate）。

适合用立方的场景：需要外延性/UA 的数学化形式化（同调代数、构造性
点集拓扑）、HIT（圆、平截断、商）的试验——前提是把 agda-cubical
（或新版 stdlib 的 Cubical 目录）装进项目库，本机环境没这个条件，
本章就停在"体验最小闭环"。

## 24.9 坑位清单（本章实测）

1. **`--cubical` 下 `≡` 不在自动作用域**：必须
   `open import Agda.Builtin.Cubical.Path using (_≡_)`，否则
   `Not in scope: ≡`（探针原文见 24.1）。`i0`/`i1` 反而是自动的，
   别去 `Agda.Primitive.Cubical` 找 `primIZero`——不存在，实测只是一条
   `ModuleDoesntExport` 警告。
2. **立方传染性是单向门**：普通文件 import 立方模块（包括
   `Agda.Builtin.Cubical.Path`）报 `InfectiveImport`。示例文件因此
   没法和前面章节互相复用；反过来立方文件 import stdlib 普通模块
   （`Data.Nat`、`PropositionalEquality`）实测可行。
3. **`agda --compile` 对立方代码一律拒绝**：
   `Compilation of code that uses --cubical is not supported.`。
   Ex24 只有类型检查、没有 main，就是这个原因。
4. **路径不能做 `refl` 模式分案**：`x ≡ y` 不再是可匹配的 data，
   13 章"对等式 proof 做 `refl` 分案"的归纳剧本在这里失效；端点信息
   用应用（`p i0`/`p i1`）与 `transp` 获取。
5. **`primGlue`/`pathToEquiv` 只吃 lambda 形式的区间族**：传路径名
   `boolPath` 报 `UnequalTerms (Bool ≡ B̂) !=< ((i : I) → Set …)`，
   必须写 `(λ i → B)`（24.6 末）。
6. **常值路径上的"路径间等式"不等于一般定理**：示例的
   `sym-sym-check`/`ap-check` 靠的是 `nat-path` 可判定退化，别外推到
   任意路径（24.5）。
7. **本机 stdlib 2.3 没有 Cubical 目录**：网上教程开头的
   `open import Cubical.Foundations.Prelude` 一律 FileNotFound；
   想用完整库需另装 agda-cubical 或升级 stdlib。
8. **`Agda.Builtin.Bool` 没有 `not`**：钉在 builtin 层写示例时
   `import ... using (not)` 得到 `ModuleDoesntExport` 警告 +
   `Not in scope: not`，得自定义或走 stdlib `Data.Bool.Base`——
   这是 builtin 层"什么都没有"的一个缩影（`Sigma` 同理只有
   `Σ/_,_/fst/snd`，没有配套的等式引理）。

---
上一章：[23 · 反射与元编程](23-reflection.md) ｜ 下一章：[25 · 实战：类型良好表达式解释器](25-typedast.md) ｜ 返回：[README](../README.md)
