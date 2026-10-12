# 50 · Huffman 编解码：把一整个工具写进类型检查器

> **第十三部分 · 综合案例（50）** ｜ 全书结构与阅读路线见 [README](../README.md)

最近五章（45–49）要么在造语言（35、49 那类组合子与解释器），要么在给语言证明
性质（46–48）。这一章
换一种口味：**用一个稍大的实际程序把全书的零件串起来**——Huffman 编码与解码。
它给一段英文文本，按词频给每个词分配一串比特（越常见的词越短），把文本压成
比特流；再给反过来的一份比特流和码表，把它还原成文本。

选它有三个理由。第一，它的算法骨架全是纯函数：词频表、优先队列、二分树、
前缀树，恰好是本书 08、18、19、45 章反复练过的数据结构。第二，它有一处
**真正需要依赖类型**的地方——把 n 棵树压成 1 棵树的循环，必须让 Agda 相信
队列不会空，否则连函数签名都写不出来。第三，它是原书唯一一个「完整工具」
案例，把「验证到什么程度才算划算」这个工程问题摆上桌：作者明说有几处不变式
他选择不证，我们既要读懂这个取舍，也要能看出哪一处今天值得补上。

对应示例：`../examples/Ex50_huffman.agda`

**实测口径**：本章代码与报错原文均为 **Agda 2.9.0 + stdlib 3.0** 本机实测
（复现：`cd agda && ./build.sh Ex50_huffman`；被拒绝的写法与对照实验来自临时
探针，跑完即删）。内容取材 Aaron Stump《Verified Functional Programming in
Agda》第 8 章的案例研究，已按最新版本重写成自包含的一章：外部解析器生成器
gratr（原书第 6 章）与 IO 两部分都不移植，理由见 50.1，替代做法见 50.8 与
50.9，读完不需要再翻原书。

本章全章 `--safe`，一个 `postulate` 都没有。

---

## 50.1 进口清单：这个案例要哪些零件

```agda
{-# OPTIONS --safe #-}

module Ex50_huffman where

open import Data.Bool using (Bool; true; false; not; if_then_else_)
open import Data.Char using (Char)
open import Data.List using (List; []; _∷_; length; map; foldr; reverse)
  renaming (_++_ to _++ₗ_)
open import Data.Maybe using (Maybe; just; nothing)
open import Data.Nat using (ℕ; zero; suc; _+_; _≡ᵇ_; _<ᵇ_)
import Data.Nat.Show as Nat
open import Data.Product using (Σ; _×_; _,_)
open import Data.String using (String; _==_; words; _++_; concat)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)
```

逐行交代用途，因为它们就是这一章的「施工料单」：

| 进口 | 用来做 |
|---|---|
| `Data.Bool` | `with` 的分派值 `true`/`false`；`if_then_else_` 与 `not` 本章留着给比较函数用 |
| `Data.Char` | 比特字面量的字符模式 `'0'`、`'1'`（50.8） |
| `Data.List` | 词表、码表、比特流；`foldr` 折出频次表，`reverse` 把反路径翻正 |
| `Data.Maybe` | 查码失败、解码失败的正规表达（不返回魔法字符串） |
| `Data.Nat` | 频次；`_≡ᵇ_` 写「不是零」这个 Bool 谓词，`_<ᵇ_` 写队列的比较 |
| `Data.Nat.Show` | 把频次渲染成字符串，让 `refl` 当断言用（50.9） |
| `Data.Product` | `Tree = Σ ℕ HTree`：把频次和它的树捆在一起 |
| `Data.String` | 词本体；`words` 把文本切成词表，`_++_`/`concat` 拼输出 |
| `PropositionalEquality` | 所有验收只用 `_≡_` 与 `refl`——本章不写归纳证明，只写「算出来对不对」 |

两个细节值得当场记下。`renaming (_++_ to _++ₗ_)`：`Data.List` 和 `Data.String`
**都**导出 `_++_`，两边同时打开会立刻撞上 `AmbiguousName`，本章字符串拼接用得
多，列表拼接只在编码里用一次，于是把列表那一个改名。
`import Data.Nat.Show as Nat`：stdlib 3.0 里 `ℕ → String` 的正品在
`Data.Nat.Show`，`Data.Nat` 本身不导出它。

**为什么没有解析器。** 原书这个案例的输入文件由一个叫 gratr 的外部工具生成
解析器（它读一份类似 BNF 的语法文件，吐出几个 Agda 模块）。gratr 是 OCaml
程序、走 Subversion 分发，源已经失效；把它请进本章，读者要先装一个和 Agda
无关的工具链，而它生成的东西无非是几类字面量的数据类型。所以本章把这些
数据类型**手写**：词表用 `List String`，比特串用 50.8 的 `parse-bits`。
被省掉的只有「从文件里读码表」这一步——解码需要的码表本章直接从 Huffman 树
算出来，正好让编码和解码共用同一份数据，往返验证也更干净。

**为什么没有 IO。** 原书的工具会写出 `.huff`、`-mapping.txt`、`.gv` 等中间
文件；那部分依赖 Haskell FFI 的 IO 绑定。本机这条路上 `agda --compile` 需要
`ghc`，而 PATH 上没有（44 章已实测），更关键的是：**往返正确性不需要打印**。
50.9 用「渲染成 `String` + `refl`」代替打印，效果就是给每个中间产物钉一份
机器核对的样例输出。

---

## 50.2 词频表：一次 `foldr`，以及它的顺序陷阱

频次表把「哪些词、各出现几次」存下来。原书用的是按字符分叉的 trie（共享前缀、
O(词长) 查找）。本章用关联表：stdlib 3.0 里没有 `Data.Map`（实测该目录不存在），
`Data.Trie` 要 `--sized-types` 且 `lookup` 返回 `These`，45 章那棵 `Trie` 则是
**按 Shape 索引的记忆表**（键是 `Fin ∣ sh ∣`，不是字符串）。为了不为了一个
查找加速结构把本章主线挤掉，这里用关联表——算法每一步都一样，只是查表是线性的。

```agda
Freq : Set
Freq = List (String × ℕ)

bump-frequency : String → Freq → Freq
bump-frequency w [] = ( w , 1) ∷ []
bump-frequency w (( v , n) ∷ fs) with w == v
bump-frequency w (( v , n) ∷ fs) | true = ( v , suc n) ∷ fs
bump-frequency w (( v , n) ∷ fs) | false = ( v , n) ∷ bump-frequency w fs

compute-frequencies : List String → Freq
compute-frequencies = foldr bump-frequency []
```

* `Freq` 是「词 × 次数」的表。它不保证键唯一，但 `bump-frequency` 的定义保证
  了：命中就原地改数字，没命中才追加一条，所以只要输入表无重复，输出也无重复。
* 比较用 `_==_`（`Data.String` 的 Bool 值等式）。49 章踩过它的近亲 `_≟_`：
  后者返回 `Dec (s ≡ t)`，是**类型层**的东西，塞不进 `with` 之后还要继续算 Bool
  的场景。这里我们要的正是 Bool。
* `compute-frequencies = foldr bump-frequency []`：整个表是一次左折叠式的
  `foldr`。注意 `foldr` 的求值顺序是**从表尾往表头**，新词是追加到表尾的，
  于是表的先后不是「首次出现顺序」。50.10 会让机器把这张表打出来，手算的人
  第一次就猜错了（坑位 8）。这不影响算法——队列会按频次重新排序——但它说明
  **凡是由计算给出的表，顺序要问机器，不要问直觉**。

频次表非空这件事，后面要用来喂荒谬模式。原书在此处写了两个引理（它的
`compute-frequencies-nonempty`），我们也写，但先把「非空」这个谓词摆正：

```agda
NonEmpty : ℕ → Set
NonEmpty n = (n ≡ᵇ 0) ≡ false

bump-nonempty : ∀ (w : String) (fs : Freq) → NonEmpty (length (bump-frequency w fs))
bump-nonempty w [] = refl
bump-nonempty w (( v , n) ∷ fs) with w == v
bump-nonempty w (( v , n) ∷ fs) | true = refl
bump-nonempty w (( v , n) ∷ fs) | false = refl

compute-frequencies-nonempty :
  ∀ (w : String) (ws : List String) → NonEmpty (length (compute-frequencies (w ∷ ws)))
compute-frequencies-nonempty w ws = bump-nonempty w (compute-frequencies ws)
```

`NonEmpty n` 读作「`n` 与 0 的 Bool 比较结果是 `false`」，也就是「算出来的
`n` 确实不是零」。为什么不一开始就写 `¬ (n ≡ 0)`？因为 Bool 版**靠计算就能
闭合**：`NonEmpty 3` 归约成 `false ≡ false`，一条 `refl` 交差；而 `¬ (3 ≡ 0)`
是要构造一个函数、把 `refl` 吃掉变成 `⊥`，写起来是三条 `()`，读起来是另一种
心智负担。原书选 Bool 版（它的 `n =N 0 ≡ ff`）正是这个考虑。

两条 Bool→Set 的桥要留意，两条报错都是本机实测（坑位 1、2）：

* `_≡ᵇ_` 返回 `Bool`，所以内层 `(n ≡ᵇ 0)` 是 Bool，外层必须换成**命题**等式
  `_≡_`，整个类型才落在 `Set`。写成 `(n ≡ᵇ 0) ≡ᵇ false` 会得到
  `The type Bool is not a subtype of Set`。
* 原书那种 `n ≡ 0 ≡ false` 直写在这里过不了语法关：stdlib 的 `_≡_` 是
  non-associative 的同级运算符，连写两次报
  `[NoParseForApplication] Could not parse the application`。加括号即可。

`bump-nonempty` 的两条分支各一个 `refl`。看点在 `false` 分支：目标是
`NonEmpty (suc (length (bump-frequency w fs)))`，其中 `suc _ ≡ᵇ 0` 归约成
`false`，于是又是 `false ≡ false`——**它不需要归纳假设**。这里裸 `with` 就够，
而不需要 49 章那个 `keep`：`keep` 是用来把「`w == v` 就是 `true`/`false`」这条
等式留在上下文里好去 `rewrite` 的；本章的结论只依赖结果的**形状**（是不是
`suc _`），等式本身没用上。同一件事在 49 章要 `keep`、在这里不用，判据就是
「结论是否用到那条等式」。

`compute-frequencies-nonempty` 是一次点传参：`foldr` 展开后
`compute-frequencies (w ∷ ws)` 就是 `bump-frequency w (compute-frequencies ws)`，
所以直接把上条引理递过去即可。

---

## 50.3 Huffman 树：原书没做的那一步，我们把频次写进类型

Huffman 树是这出戏的主角。叶子存一个词和它的频次，内部结点存左右两棵树，
它的频次**应该**是两棵子树之和。原书写得很坦白：可以把频次做成索引来强制这条
不变式，但既然全代码只有一处计算这个和，就靠肉眼检查过去了。

我们把它补上——这一步几乎不要钱，而它换来的东西在 50.10 会当场演示。

```agda
data HTree : ℕ → Set where
  leaf : (w : String) (f : ℕ) → HTree f
  node : ∀ {f₁ f₂} → HTree f₁ → HTree f₂ → HTree (f₁ + f₂)
```

`HTree f` 是「总频次恰为 `f` 的树」。`leaf` 自己声明自己的频次；`node` 的索引
是 `f₁ + f₂`，**写不出**「子树是 2 和 3、父亲标 6」的树——那样的项根本不闭合。
这就是把不变式焊进类型：不是运行时检查，是不可构造。

队列里装的元素要能互相比较，所以频次必须**同时**存在于数据里（索引是类型的
一部分，比较函数拿不到它当值用）。用 Σ 把两者捆起来：

```agda
Tree : Set
Tree = Σ ℕ HTree

pattern _ᵀ_ f t = ( f , t )

mk-leaf : String → ℕ → Tree
mk-leaf w f = f , leaf w f

merge : Tree → Tree → Tree
merge (f₁ ᵀ t₁) (f₂ ᵀ t₂) = f₁ + f₂ , node t₁ t₂

ht-compare : Tree → Tree → Bool
ht-compare (f₁ ᵀ _) (f₂ ᵀ _) = f₁ <ᵇ f₂
```

* `Tree = Σ ℕ HTree` 是「存在某个频次 f，配一棵 `HTree f`」——存在类型。
  队列的类型参数只能是这一个 `Tree`，因为 `PQ n` 要**同种**元素的表，
  而不同元素的频次索引各不相同。
* `pattern _ᵀ_ f t = ( f , t )` 是模式同义词，纯粹为了读起来像「6 的这棵树」。
  它只能在**模式**里出现，右边表达式仍要写 `_,_`（坑位 7）；而且模式变量不能
  带类型标注：`pattern _ᵀ_ (f : ℕ) (t : HTree f) = f , t` 直接被 parser 拒绝。
* `merge` 的右边是 `f₁ + f₂ , node t₁ t₂`。注意我们没有「算总频次」的独立
  代码：`node t₁ t₂` 的类型**就是** `HTree (f₁ + f₂)`。原书靠肉眼确认的那
  一行，在这里由类型检查器签字。
* 比较用 `<ᵇ`。第一版写的是 `_<?_`，报错原文：
  `The type Relation.Nullary.Decidable.Core.Dec (f₁ Data.Nat.< f₂) is not a
  subtype of Bool`——`_<?_` 是判定过程，不是 Bool 函数（与 49 章 `_≟_` 同族
  的坑，坑位 3）。

---

## 50.4 优先队列：直接实例化 19 章的 Braun 模块

Huffman 算法要反复取「频次最小的两棵树」。19 章做过 Braun 树：形状不变式
（左子大小等于右子或右子加一）写进了 `braun n` 的索引，`insert` 与 `remove-min`
都已经在 `--safe` 下类型检查过。这一章不重复它的证明，只**当库用**。

```agda
import Ex19_braun_lists as Ex19
open Ex19.Braun Tree ht-compare
```

这两行是本章最「模块系统」的一刻：一个已经写好、已经证过的参数化模块，靠两个
实参（元素类型、比较函数）现场装配进来。这里有一条**必须实测才知道**的门道：
`open import Ex19_braun_lists using (Braun)` 这种看起来最自然的写法，在 2.9.0 上
根本拿不到参数化的嵌套模块，报错两连：

```text
warning: -W[no]ModuleDoesntExport
The module Ex19_braun_lists doesn't export the following:
  Braun
error: [NoSuchModule]  No module Braun in scope
```

必须走 `import ... as` 拿到模块别名，再 `open` 那个模块并交参数。附带一条
真门槛：`Ex50_huffman` 声明了 `--safe`，而 19 章文件原本没写 pragma，于是
第一次 import 撞上

```text
error: [CoInfectiveImport]
Importing module Ex19_braun_lists not using the --safe flag
from a module which does.
```

Agda 的 safe 是**逐模块**声明的，不是全局属性。19 章本来就无 `postulate`，
补一行 `{-# OPTIONS --safe #-}` 就通（本机实测：加了之后两个文件一起通过）。

队列本体只是三个改名：

```agda
PQ : ℕ → Set
PQ = braun

pq-insert : ∀ {n} → Tree → PQ n → PQ (suc n)
pq-insert = insert

pq-remove-min : ∀ {p} → PQ (suc p) → Tree × PQ p
pq-remove-min = remove-min
```

名字之外什么都没做，但类型里的账是本格的：`pq-insert` 把尺寸从 `n` 抬到
`suc n`，`pq-remove-min` 把 `suc p` 降到 `p`。「在空队列上取最小元」这个调用
**不存在合法类型**，所以它不是「运行时会崩」，而是「写不出来」。这正是
18/19 章 `Vec` 与 `braun` 那条「越界不可表达」路线的又一次兑现。

初始队列由频次表建出来：

```agda
build-huffman-pq : (fs : Freq) → PQ (length fs)
build-huffman-pq [] = empty
build-huffman-pq (( w , f) ∷ fs) = pq-insert (mk-leaf w f) (build-huffman-pq fs)
```

结论 `PQ (length fs)` 值得停一下：**队列的尺寸是输入表算出来的**，不是号称的。
每条子句把尺寸动一格，所以既不可能漏装一个词，也不可能凭空多一棵树——
「频次表有 3 项但队列里只有 2 棵」这个 bug 在这一层是**类型错误**。

---

## 50.5 折叠队列：荒谬模式在这里上岗

现在到了原书 8.3.3 的核心，也是全章唯一一处「不写依赖类型就写不出来」的地方。

```agda
process-huffman-pq : ∀ {n} → NonEmpty n → PQ n → Tree
process-huffman-pq {zero} () _
process-huffman-pq {suc zero} _ t with pq-remove-min t
... | h , _ = h
process-huffman-pq {suc (suc n)} _ t with pq-remove-min t
... | h , t′ with pq-remove-min t′
process-huffman-pq {suc (suc n)} _ _ | h , t′ | h′ , t″ =
  process-huffman-pq {suc n} refl (pq-insert (merge h h′) t″)
```

逐子句读：

1. `NonEmpty n` 是「队列非空」的凭据。第一条子句把 `n` 实例化成 `zero`，此时
   `NonEmpty zero` 归约成 `true ≡ false`——一条**没有构造子**的类型，于是
   参数位置写荒谬模式 `()` 就是完整的证明：这种情况不存在，无需给右侧。
   这就是原书要 `n =N 0 ≡ ff` 的全部理由：树类型 `HTree` 里没有空树，
   `PQ 0` 折不出 `Tree`，而「0 不可能出现」必须由类型说出来。
2. `{suc zero}`：`pq-remove-min t` 合法（尺寸是 `suc p`），拿走唯一那棵就收工。
   返回的剩余队列尺寸是 `zero`，我们用 `_` 把它扔掉。
3. `{suc (suc n)}`：先取最小 `h`，剩 `t′ : PQ (suc n)`；**再**取一次最小 `h′`
   才合法——因为第二次调用要求参数尺寸形如 `suc p`，而这个形状只有把 `n`
   显式拆成 `suc n` 才看得见。两个 `with` 叠起来，正是 19 章
   `remove-min` 里 `... | a₁′ , l′ with if ...` 的写法。
4. 合并 `h`、`h′` 成 `merge h h′`（它的频次由类型算好），塞回 `t″ : PQ n` 得到
   `PQ (suc n)`，递归调用的凭据写 `refl`：`NonEmpty (suc n)` 里 `suc n ≡ᵇ 0`
   归约成 `false`，所以又是 `false ≡ false`。**递归是沿着索引 `n` 下降的**，
   Agda 直接接受——既不需要 35 章 `normalize` 那套 `Acc _≺_`，也不像 49 章
   那样跟着归纳对象走。

顺带一条实测：把 `...` 展开成完整左端时，`with` 后那个 Σ 对模式里的 `_`
解析不过：

```text
error: [NoParseForLHS]
Could not parse the left-hand side process2 {suc zero} _ t | (h , _)
Problematic expression: ((h ,) _)
```

所以本章统一用 `...` 省略式（19 章的老约定）。

顶层包装把「非空凭据」藏进输入形状：

```agda
huffman-tree : (ws : List String) → NonEmpty (length ws) → Tree
huffman-tree [] ()
huffman-tree (w ∷ ws) _ =
  process-huffman-pq (compute-frequencies-nonempty w ws)
    (build-huffman-pq (compute-frequencies (w ∷ ws)))
```

调用者只需交出「词表非空」，函数内部用 50.2 那条引理把它换成
「频次表非空」。原书要调用方自己凑齐后者（还得先证 `trie-mappings` 保非空），
我们这条链短一节。空词表这一支同样落在荒谬模式上：`huffman-tree [] refl`
在本机被拒（坑位 12），报错原文见 50.12。

---

## 50.6 码表：从树上读出「词 → 比特」，以及查不到怎么办

比特不能存成字符串——那是给打印用的。先给它一个两构造子的类型：

```agda
data Bit : Set where
  b0 b1 : Bit

Code : Set
Code = List Bit

Mapping : Set
Mapping = List (String × Code)
```

码表把树里的路径读出来。技巧是**下行时把经过的位记在最前面**，于是手里拿的是
反路径，到叶子再翻正（19 章的 `reverse` 在这里第二次上岗）；另一处省法是把
路径累在尾部，代价是每下一层做一次 `_++_`。

```agda
build-mapping-h : ∀ {f} → Code → HTree f → Mapping → Mapping
build-mapping-h p (leaf w _) m = ( w , reverse p ) ∷ m
build-mapping-h p (node l r) m =
  build-mapping-h (b1 ∷ p) r (build-mapping-h (b0 ∷ p) l m)

build-mapping : Tree → Mapping
build-mapping ( _ , t ) = build-mapping-h [] t []
```

`build-mapping-h` 的第三个参数是累加器，第四个（返回值）是更新后的表。
`node` 那条子句值得用嘴过一遍：**先**把左子树的处理结果当新的累加器，
**再**在里面处理右子树——嵌套调用就是「两次遍历合表」的写法，不需要额外的
`_++_`。左子记 `b0`、右子记 `b1`，与原书约定一致。

`build-mapping` 把 Σ 的频次分量用 `_` 扔掉：码不依赖频次。这里索引没能帮上忙，
但也没碍事——`t : HTree f` 的 `f` 仍然存在类型里，只是这条子句不读它。

查码与编码：

```agda
lookup-code : String → Mapping → Maybe Code
lookup-code w [] = nothing
lookup-code w (( v , c) ∷ m) with w == v
lookup-code w (( v , c) ∷ m) | true = just c
lookup-code w (( v , c) ∷ m) | false = lookup-code w m

encode-h : Mapping → List String → Maybe Code
encode-h m [] = just []
encode-h m (w ∷ ws) with lookup-code w m | encode-h m ws
encode-h m (w ∷ ws) | just c | just cs = just (c ++ₗ cs)
encode-h m (w ∷ ws) | _ | _ = nothing

encode : Mapping → String → Maybe Code
encode m s = encode-h m (words s)
```

这里有一处**原作者明说不验证**的地方，很值得琢磨。原书的编码函数在查不到词时
返回一个魔法字符串 `"error"`；他的考虑是：码表是否覆盖所有输入词并没有证明，
所以失败分支必须在代码里存在，哪怕按构造它走不到，而 Agda 并不知道这一点。
这个坦白是好的工程判断，但 `"error"` 混在正常输出里，下游分不出来。本章用
`Maybe`：失败是**类型上的分支**，调用方被迫处理（50.10 有一条 `encode-miss`
实测它确实返回 `nothing`）。

要不要干脆把「覆盖性」证掉，让失败分支不可达？那才是这套代码的自然终点，
但要看清它的价钱：得先有「进了频次表的词，查表必命中」这类引理，而 `with`
出来的 `w == v` 是 Bool，要抬成命题等式才能 `rewrite` 进 `Freq` 的结构里——
49 章实测过这条线的脾气（`isYes (map′ …)` 那类中间项挡在 `refl` 前面）。
原书把它列为练习，我们把它留着，只在 50.10 用具体词的 `refl` 把「这个例子里
每个词都查得到」钉住。这是「验证要花在刀刃上」的一次实操：**结构性的不变式
（尺寸、频次和）全部进类型；跨模块的覆盖性引理先记账、不硬凑。**

`encode-h` 的第二个 `with` 参数是递归调用自身，所以两个分支的 `just` 都要拆：
`just c | just cs` 才拼，其余一律 `nothing`。`_++ₗ_` 是 50.1 改名的列表拼接。

---

## 50.7 码树与解码：走到叶子就交词、然后回根

编码用表，解码用树——因为解码要**按位下行**，前缀树（按比特分叉）比查表合适。

```agda
data CTree : Set where
  cempty : CTree
  cleaf : String → CTree
  cnode : CTree → CTree → CTree

flip-bit : Bit → Bit
flip-bit b0 = b1
flip-bit b1 = b0

sub-ct : Bit → CTree → CTree
sub-ct b cempty = cempty
sub-ct b (cleaf _) = cempty
sub-ct b0 (cnode l _) = l
sub-ct b1 (cnode _ r) = r

ct-node-bit : Bit → CTree → CTree → CTree
ct-node-bit b0 l r = cnode l r
ct-node-bit b1 l r = cnode r l
```

`sub-ct b t` 读作「从 `t` 出发按位 `b` 走一步」，它的语义要点是：对着 `cempty`
或 `cleaf` 再往下走，一律返回 `cempty`——这是解码器「走过头」的唯一信号（停在
叶子上却还有比特、或停在空位上，都是错）。

看点在**它按位拆成了两条子句**，而不是一条 `sub-ct b (cnode l r) = if … then l
else r`。这个 `if` 版我们真的试过（临时探针），实机报错：

```text
error: [UnequalTypes]
The type Bit
is not a subtype of
String
when checking that the expression b has type String
```

原因是本章手边的 `_==_` 是 `Data.String` 的那一个（50.1 的料单里只有它的 Bool
等式），只认字符串，喂给它一个 `Bit` 就是类型不符。这不是语言的封锁：我们拿
临时探针补了一个 `Bit → Bit → Bool` 的等式（三条子句：同构造子给 `true`、其余给
`false`）之后，同一条 `if` 写法确实通过了类型检查。所以真正的账是**零件账**——
要走 `if` 那条路，就得先自己造等式，而自造的 Bool 等式还得多证一次可靠才敢给
`refl` 用；按位拆两条子句一分钱不花，并且覆盖检查顺手把 `CTree` 的三个构造子
点清了一遍：探针里删掉 `b1` 那条，Agda 立刻不放过。

```text
error: [CoverageIssue]
Incomplete pattern matching for sub-ct. Missing cases:
  sub-ct b1 (cnode x x₁)
when checking the definition of sub-ct
```

`ct-node-bit b l r` 则是「按位决定谁做左子」：给 `b1` 就把两棵子树交换。它是
`ct-insert` 的螺丝钉——把新叶子放到位之后，另一侧要整段从旧树搬过来。

```agda
ct-insert : CTree → String → Code → CTree
ct-insert t w [] = cleaf w
ct-insert t w (b ∷ bs) =
  ct-node-bit b (ct-insert (sub-ct b t) w bs) (sub-ct (flip-bit b) t)

make-code-tree : Mapping → CTree
make-code-tree [] = cempty
make-code-tree (( w , c) ∷ m) = ct-insert (make-code-tree m) w c
```

`ct-insert` 用一条递归子句同时覆盖了原书拆成两段的写法（末位建叶、非末位递归）：
空码的基例就是「在此处放叶子」，被上层的 `ct-node-bit` 安置到正确的一侧。
读它的关键是那两个 `sub-ct`：**下行方向**用 `sub-ct b t` 继续插，
**另一侧**（`flip-bit b`）直接从旧树整段搬走，不动它。前缀码的无重叠性质由此
保持——两条码走的是不同的位序列，永远落在互不相交的子树上。

`make-code-tree` 把表逐条插入。注意它把「码表」翻译成「树」，而码表的顺序会影响
树的形状吗？不会：`ct-insert` 只在 `b` 那一侧生长，`flip-bit b` 那一侧原样搬运，
所以插入顺序只影响中间过程，最终树一样。

解码：

```agda
data Bitvec : Set where
  alone : (b : Bit) → Bitvec
  _⊙_ : (b : Bit) → (v : Bitvec) → Bitvec

to-bitvec : (b : Bit) (bs : List Bit) → Bitvec
to-bitvec b [] = alone b
to-bitvec b (c ∷ cs) = b ⊙ to-bitvec c cs

emit : String → Maybe (List String) → Maybe (List String)
emit w (just ws) = just ( w ∷ ws)
emit w nothing = nothing

decode-h : CTree → CTree → Bitvec → Maybe (List String)
decode-h orig cur (alone b) with sub-ct b cur
decode-h orig cur (alone b) | cleaf w = just ( w ∷ [])
decode-h orig cur (alone b) | _ = nothing
decode-h orig cur (b ⊙ v) with sub-ct b cur
decode-h orig cur (b ⊙ v) | cleaf w = emit w (decode-h orig orig v)
decode-h orig cur (b ⊙ v) | cnode l r = decode-h orig (cnode l r) v
decode-h orig cur (b ⊙ v) | cempty = nothing

decode : CTree → Code → Maybe (List String)
decode _ [] = just []
decode t (b ∷ bs) = decode-h t t (to-bitvec b bs)
```

`Bitvec` 是本章自己造的「至少有一位」的比特串：`alone b` 表示「就剩这一位」，
`b ⊙ v` 表示「这位之后还有」。为什么要多这一个类型，不用 `List Bit`？
因为解码的最后一步要说「末位必须落在叶子上」。用 `List Bit` 写的解码器，
位用尽时只能返回「已经解出来的词表」，于是**截断的输入会静默成功**。
我们真的写了这个朴素版做对照（临时探针，跑完即删），它对本章样例文本少一位
的输入返回：

```text
naive-out ≡ just ("hi" ∷ "hi" ∷ "bye" ∷ "hello" ∷ "hi" ∷ "hi" ∷ "bye" ∷ "hello"
                 ∷ "hi" ∷ "hi" ∷ "bye" ∷ [])
```

十一词，最后一个词的收尾位被吃掉了，而函数一脸正常地返回 `just`。50.10 里的
`truncated` 证明本章的正经版本对同一输入给 `nothing`。这就是坑位 11：
**「走完就收工」不等于「走到该停的地方」**，而把区别写进数据类型只花两行。

`decode-h` 的两个参数 `orig`/`cur` 是这套算法的灵魂：`cur` 是当前所在的子树，
`orig` 是整棵树的根。每解出一个词（碰到 `cleaf w`）就把 `cur` **归位**成 `orig`
再解下一个——这就是「按码表把比特流切成词」的函数式写法，没有可变指针。
`alone` 那一支没有归位机会，因为它已经是最后一位：落在叶子上就交词，
否则一律 `nothing`（`_` 一条把 `cnode`、`cempty` 都收掉，此时剩余比特为零，
停在内部结点也是截断）。

`to-bitvec` 从「首位 + 其余位」造出非空串：`[]` 变成 `alone`，`c ∷ cs` 变成
`b ⊙ …`——外部解析器语法里「比特串字面量」那两条产生式（首位、后续位），在这里
变成了两个构造子。

---

## 50.8 手写解析：顶掉外部解析器的比特串字面量规则

顶替那条词法规则只需要三个函数：

```agda
parse-bit : Char → Maybe Bit
parse-bit '0' = just b0
parse-bit '1' = just b1
parse-bit _ = nothing

parse-bits-h : List Char → Maybe Code
parse-bits-h [] = just []
parse-bits-h (c ∷ cs) with parse-bit c | parse-bits-h cs
parse-bits-h (c ∷ cs) | just b | just bs = just ( b ∷ bs)
parse-bits-h (c ∷ cs) | _ | _ = nothing

parse-bits : String → Maybe Code
parse-bits s = parse-bits-h (Data.String.toList s)

parse-bits-ok : parse-bits "0101" ≡ just (b0 ∷ b1 ∷ b0 ∷ b1 ∷ [])
parse-bits-ok = refl

parse-bits-bad : parse-bits "0x1" ≡ nothing
parse-bits-bad = refl
```

字符字面量 `'0'`、`'1'` 可以直接当模式用（`Data.Char` 走的是内建字符）。
最后一行必须写**限定名** `Data.String.toList`：`open Ex19.Braun Tree ht-compare`
把 19 章那个 Braun 模块里的 `toList`（摊平成列表）也带进了作用域，两者同名，
不写限定就撞车（坑位 6）。同理 `_++_` 也要改名或限定。

后面两条 `refl` 是给这台小解析器自己上的保险：`parse-bits-ok` 逐位核对
`"0101"`，`parse-bits-bad` 确认掺进一个 `'x'` 就整体失败。50.10 里满地的
`bits "…"` 速记都建在这两条之上。它们并不改变「写错了会不会被发现」——真把
`'0'` 认成 `b1`，`mapping-is` 也一样炸；改变的是**在哪儿被指出**：有这两条，
报错落在解析器身上；没有它们，同一个小失误会在 50.10 的七八个等式上同时炸开，
看上去像整条流水线坏了。这就是快照测试的第二个用途（第一个见 50.9）。

---

## 50.9 无 IO 的打印：把每个中间产物钉成一条 `refl`

打印部分代替原书写中间文件的环节：

```agda
show-bit : Bit → String
show-bit b0 = "0"
show-bit b1 = "1"

show-code : Code → String
show-code cs = concat (map show-bit cs)

show-freq : Freq → String
show-freq [] = ""
show-freq (( w , f) ∷ fs) = w ++ " ↦ " ++ Nat.show f ++ "; " ++ show-freq fs

show-words : List String → String
show-words ws = concat (map (λ w → w ++ " ") ws)

show-mapping : Mapping → String
show-mapping [] = ""
show-mapping (( w , c) ∷ m) = w ++ " ↦ " ++ show-code c ++ "; " ++ show-mapping m
```

这些函数本身没有技术含量，但它们和 `refl` 合起来构成了本章的**快照测试**：
把渲染结果与一段字符串字面量写成等式，`refl` 通过即代表机器认了这份输出。
`Nat.show` 用的是 50.1 里 `import Data.Nat.Show as Nat` 那个模块——stdlib 把
`ℕ → String` 的渲染住在 `Data.Nat.Show`，`Data.Nat` 本身并不导出它。

---

## 50.10 整条流水线跑在样例文本上

样例文本取原书那句：十二个词，`hi` 出现六次，`bye` 与 `hello` 各三次。
先给测试写作用的比特表速记：

```agda
bits : String → Code
bits s with parse-bits s
... | just bs = bs
... | nothing = []

text : String
text = "hi hi bye hello hi hi bye hello hi hi bye hello"

freqs : Freq
freqs = compute-frequencies (words text)

freqs-is : freqs ≡ ( "hello" , 3) ∷ ( "bye" , 3) ∷ ( "hi" , 6) ∷ []
freqs-is = refl

freqs-printed : show-freq freqs ≡ "hello ↦ 3; bye ↦ 3; hi ↦ 6; "
freqs-printed = refl
```

`bits` 非法输入返回空表——它只用来喂自己写死的合法串，而「逐位翻译」这件事
由 50.8 的 `parse-bits-ok` 兜着。频次表这一条 `refl` 是本章最诚实的一课：
**先手猜 `hi` 打头，机器报了错，改成 `hello` 打头才通过**（`foldr` 从表尾起算，
新词追加在表尾，见 50.2）。两条 `refl` 一起立：结构等式给下游用，
渲染等式给人看。

队列折成一棵树：

```agda
tree : Tree
tree = huffman-tree (words text) refl

tree-is : tree ≡ ( 12 , node (leaf "hi" 6) (node (leaf "bye" 3) (leaf "hello" 3)))
tree-is = refl
```

`huffman-tree (words text) refl` 里那个 `refl` 就是「词表非空」的凭据：
`words text` 会真的算成十二个词的表，于是 `NonEmpty 12` 归约成 `false ≡ false`。
**凭据靠计算交出去，不靠人写证明**，这是 Bool 版谓词换来的便利。

`tree-is` 把机器算出的树原样写出来，一条 `refl` 验收：`hi` 在左子树（一位码），
`bye`、`hello` 沉到右子树下面。总频次 12 也写在索引里——它是 `6 + (3 + 3)`，
由 `HTree` 的索引自动成立，不需要谁去检查（原书 8.3.2 的理由是这个和只在一处
算、风险小所以不进类型，见 50.3；现在那一处不归人管）。

码表：

```agda
mapping : Mapping
mapping = build-mapping tree

mapping-is :
  mapping ≡ ( "hello" , bits "11") ∷ ( "bye" , bits "10") ∷ ( "hi" , bits "0") ∷ []
mapping-is = refl

mapping-printed : show-mapping mapping ≡ "hello ↦ 11; bye ↦ 10; hi ↦ 0; "
mapping-printed = refl
```

`hi` 拿到一位码 `0`，两个三次的词拿到两位码 `10`、`11`。位长账单：

| 词 | 频次 | 码长 | 贡献位数 |
|---|---|---|---|
| `hi` | 6 | 1 | 6 |
| `bye` | 3 | 2 | 6 |
| `hello` | 3 | 2 | 6 |
| 合计 | 12 | — | **18** |

编码与解码，以及往返：

```agda
encoded : Maybe Code
encoded = encode mapping text

encoded-is : encoded ≡ just (bits "001011001011001011")
encoded-is = refl

decoded : Maybe (List String)
decoded with encoded
... | nothing = nothing
... | just bs = decode (make-code-tree mapping) bs

round-trip : decoded ≡ just (words text)
round-trip = refl

decoded-printed : String
decoded-printed with decoded
... | just ws = show-words ws
... | nothing = "解码失败"

decoded-printed-is :
  decoded-printed ≡ "hi hi bye hello hi hi bye hello hi hi bye hello "
decoded-printed-is = refl
```

`encoded-is` 说：十二个词编成 18 位，正好对上表里那个合计。
`round-trip` 是本章的收场白：**编出来的串用同一张表建出的码树去解，
拿回原词表**。它不是一段测试代码跑一跑看输出，而是一条 Agda 类型检查——
`build.sh` 通过后，这条往返性质对本机就是这个程序的既定事实。
`decoded` 用 `with encoded` 把「编码失败则不试解码」写成结构，
所以它的两条子句分别对应 50.6 那条 `Maybe` 分支。

四条边界，都写成 `refl`：

```agda
truncated : decode (make-code-tree mapping) (bits "00101100101100101") ≡ nothing
truncated = refl

encode-miss : encode mapping "hi zzz" ≡ nothing
encode-miss = refl

single-tree : Tree
single-tree = huffman-tree (words "hi hi hi") refl

single-decode : decode (make-code-tree (build-mapping single-tree)) (bits "0") ≡ nothing
single-decode = refl

empty-input : decode (make-code-tree mapping) [] ≡ just []
empty-input = refl
```

* `truncated`：少一位的比特流必须失败（50.7 已展示朴素写法会静默交十一词）。
* `encode-miss`：码表里没有的词查不到，`encode` 给 `nothing`——这就是 50.6
  那个「没证覆盖性」的分支被真实触发的样子。
* `single-tree`/`single-decode`：**只有一个不同词**时，它的码是空表
  （根就是叶子），于是任何比特都解不动，返回 `nothing`。这是原书没写、我们在本
  节现场踩到的退化情形（坑位 10）。真要给它一个码，得允许「固定
  一位码」之类的外部约定。
* `empty-input`：空比特流解成空词表，与「非空输入才有 Huffman 树」并不矛盾——
  后者是**编码侧**的要求（频次表要能建出树），前者是**解码侧**的平凡情形。

最后一组最有意思：拿原书第 8 章开头用来引出问题的那串比特，用**我们**算出的码树去解。

```agda
book-decoded : Maybe (List String)
book-decoded = decode (make-code-tree mapping) (bits "001110001110001110")

book-decoded-is :
  book-decoded ≡ just (words "hi hi hello bye hi hi hello bye hi hi hello bye")
book-decoded-is = refl
```

原书那条例子里 `bye` 标 `11`、`hello` 标 `10`，我们的队列把两者标反了
（`bye ↦ 10`、`hello ↦ 11`）——`hi ↦ 0` 倒是一模一样。同一串 18 比特，用我们的
码树解出来是 `hi hi hello bye` 三遍，词数、位长都对，只是内容串了位。
原书 8.3 第 4 点其实预告了这件事：队列的处理顺序不同就会算出不同的树、
不同的码。这条 `refl` 把「码不唯一」从一句话变成一件可执行的事实，同时提醒
**前缀码不会自报家门**：跨码树解串不会报错，只会安静地给出另一段文本。
所以码表必须随比特流同行——那正是原书文件格式把 `!` 段（码表）放在数据前面的原因。

---

## 50.11 这一章在全书里的位置

这一章是全书的「应用端」终点：它几乎不带新逻辑，而是把已有零件全部派上用场。

* **数据结构复用**：`List`（08 章）、Σ 与关联表（09 章）、Braun 树及其
  insert/remove-min（19 章）、`reverse` 的两条用法（19 章）、把尺寸写进索引
  的 `Vec`/`braun` 路线（18 章）。队列那两行 `import … as` +
  `open Ex19.Braun Tree ht-compare` 是全书第一次**跨文件实例化另一个章的参数化
  模块**——16 章和 47 章也 import 别的章，但它们 `open import Ex15_induction`、
  `open import Ex46_ppil_kripke` 都是拿无参数的模块；一交参数就顺带考到了
  `--safe` 的逐模块性质（48 章）与嵌套模块的导出规则（25 章的模块机制）。
* **验证的账本**：本章把不变式全部押在「构造不可越」这一档——`PQ (length fs)`
  押住不丢不多，`HTree (f₁ + f₂)` 押住频次之和，`NonEmpty n` 押住循环起点，
  `Bitvec` 押住末位落叶；而「码表覆盖所有输入词」这种要跨结构推理的性质
  **有意留白**，像原书一样把它记在账上。45 章的 `Memoizes` 展示过另一种风格：
  把「这张表确实在记忆 f」做成索引类型。两条路线对照着看，才知道
  「依赖类型该花在哪」。
* **与元理论三章的关系**：46–48 章用元语言给对象语言做模型，49 章把 λ 编译成
  组合子，都是「关于程序的知识」。这一章回到「程序本身」，但它证明的东西
  （往返、非空、尺寸）同样是命题即类型——只不过证法几乎全是 `refl`：
  **对可计算的不变式，归约就是证明**（11 章的计算模型、13 章的 `refl`）。
* **能继续往下的两步**：把覆盖性引理真的证掉（`encode` 就不再返回 `Maybe`），
  以及给码表加前缀无关性的证明（原书列为未来工作）。前者要跨 `Freq` 归纳，
  后者要对 `HTree` 的路径做 49 章那种多步关系推理。两件事都在本章的能力圈内，
  只是本章选择先把流水线上线。

---

## 50.12 坑位清单（实测）

1. **`_≡_` 不结合**：照原书风格写 `length fs ≡ 0 ≡ false` 报
   `[NoParseForApplication] Could not parse the application … Operators used in
   the grammar: ≡ (infix operator, level 4)`。stdlib 的命题等式是 non-associative，
   连写必须加括号。
2. **Bool 等式与命题等式各就各位**：`NonEmpty n = (n ≡ᵇ 0) ≡ᵇ false` 报
   `The type Bool is not a subtype of Set when checking that the inferred type
   of an application Bool matches the expected type Set`。内层用 `_≡ᵇ_`（Bool 值），
   外层要换成 `_≡_` 才能落在 `Set`。
3. **`_<?_` 不是 Bool 函数**：`ht-compare` 第一版写 `f₁ <? f₂`，报
   `The type Relation.Nullary.Decidable.Core.Dec (f₁ Data.Nat.< f₂) is not a
   subtype of Bool`。要 Bool 用 `<ᵇ`。（49 章的 `_≟_`/`_≡?_` 是同一族坑。）
4. **参数化嵌套模块不能用 `using` 拿**：`open import Ex19_braun_lists using (Braun)`
   先警告 `The module Ex19_braun_lists doesn't export the following: Braun`，
   再报 `[NoSuchModule] No module Braun in scope`。改成
   `import Ex19_braun_lists as Ex19` + `open Ex19.Braun Tree ht-compare`。
5. **`--safe` 是逐模块的**：从 `--safe` 模块 import 未标 safe 的模块报
   `[CoInfectiveImport] Importing module Ex19_braun_lists not using the --safe
   flag from a module which does`。19 章本就无 `postulate`，补一行 pragma 即可。
6. **模块实例化会污染作用域**：`open Ex19.Braun …` 之后，`toList` 与
   `Data.String.toList`、`Data.List._++_` 与 `Data.String._++_` 同时可见，
   各报一次 `[AmbiguousName]`。解法：限定名（`Data.String.toList s`）或
   `renaming (_++_ to _++ₗ_)`。
7. **模式同义词两条限制**：`pattern _ᵀ_ (f : ℕ) (t : HTree f) = f , t` 报
   `ParseError`（模式变量不能带类型标注）；而且 `_ᵀ_` 只出现在模式里，
   表达式侧仍要写 `f , leaf w f`。
8. **`foldr` 建的表，顺序要问机器**：手猜 `hi` 打头，实测 `hello` 打头——
   `freqs-is` 第一次就报 `The terms "hello" and "hi" are not equal at type String`。
   频次表的顺序不影响算法，但任何由计算给出的表，写死它的等式都别靠直觉。
9. **`refl` 的报错是最好的读值工具**：本章所有中间产物（频次表、树、码表、
   比特流、解码文本）都是先用一条错的 `refl` 让 Agda 打印实际值，再回填。
   这条手法代替了不能用的 `--compile` + `putStr`。
10. **单一种词会退化成空码**：`huffman-tree (words "hi hi hi") refl` 的树是
    `leaf "hi" 3`，`build-mapping` 给出码 `[]`，码树退化为根上的叶子，于是
    `single-decode` 里连 `bits "0"` 都解不动（`nothing`）。真要让单词文本可解，
    得给码加一位的外部约定。
11. **截断必须显式拦**：`decode-h` 若用 `List Bit` 并把基例写成
    `decode-h orig cur [] = just []`，对少一位的输入会返回 11 个词的 `just`
    （实测见 50.7 的朴素对照版），静默丢掉最后一个词的收尾位。`Bitvec` 的
    `alone`/`⊙` 两构造子把「末位要落在叶子上」变成模式匹配看得见的事。
12. **空输入进不了 Huffman，而且不是装饰**：`huffman-tree [] refl` 报
    ```text
    [UnequalTerms] The terms Agda.Builtin.Bool.Bool.true and
    Agda.Builtin.Bool.Bool.false are not equal at type Agda.Builtin.Bool.Bool
    when checking that the expression refl has type
    Ex50_huffman.NonEmpty (Data.List.length [])
    ```
    注意报错里索引没归约（`Data.List.length []`）、内建类型全限定
    （`Agda.Builtin.Bool.Bool`）——读 Agda 的错要认得这副样子。
13. **频次索引真的在把关**：`node (leaf "a" 2) (leaf "b" 3) : HTree 6` 报
    `The terms 3 and 4 are not equal at type ℕ when checking that the expression
    leaf "b" 3 has type HTree 4`——它不是笼统地说「不匹配」，而是算出
    「右子必须是 4 才能凑成 6」。原书选择不做的这项验证，代价是一行索引。
14. **`with` 展开成完整左端时，Σ 模式里的 `_` 解析不过**：
    `process2 {suc zero} _ t | (h , _)` 报
    `[NoParseForLHS] Problematic expression: ((h ,) _)`。用 19 章的 `...` 省略式，
    或给那个位置起个真名字再扔掉。
15. **`_==_` 只认字符串**：`sub-ct b (cnode l r) = if b == b0 then l else r` 报
    `[UnequalTypes] The type Bit is not a subtype of String`——手边那个 `_==_`
    来自 `Data.String`。自备 `Bit → Bit → Bool` 之后同一条写法能过（实测），
    所以这是**零件账**不是语言限制：多写一个等式函数、还要为它补可靠性引理，
    不如按位拆两条子句，让覆盖检查把 `CTree` 的三个构造子点清（少一条报
    `[CoverageIssue] Incomplete pattern matching for sub-ct`）。

---

上一章：[49 · bracket abstraction：把 λ 抽象编译成 SK 组合子](49-bracket-abstraction.md) ｜ 下一章：暂无（全书完；45 是主线收官章，43–44 为附录，46–50 是元理论、语言防线、λ 消除与一个完整案例） ｜ 返回：[README](../README.md)
