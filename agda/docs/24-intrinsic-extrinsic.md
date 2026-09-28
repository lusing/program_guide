# 24 · intrinsic 与 extrinsic 证明：二叉查找树实战

> **第四部分 · 依赖编程、代数与证明风格（20–24）** ｜ 全书结构与阅读路线见 [README](../README.md)

同一道题写两遍：**二叉查找树的插入与查找，怎么才知道它还是棵树？**
Maguire《Certainty by Construction》第六章把这道题当成全书的分水岭，
因为它能同时演示两种风格——**extrinsic**（类型允许坏树存在，操作跑完
再附一份「它仍然有序」的证明）与 **intrinsic**（把不变式做进类型索引，
坏树连一个项都写不出来）。本教程 34 章的可验证插入排序是 extrinsic
路线的既有基线：`sorted` 谓词追加在 `List` 上，排序函数交出一条重排
证明。本章把同一副担子换成 BST，并且**两种风格各写一遍完整实现**，
好让「哪种划算」不再是口号：读者手里会有两份可跑、可 `refl` 验收的
代码，以及一份逐条实测的坑位清单。

本章还要顺手解决一个前面几章一直绕开的问题：**「判断」到底有几种
形状**。布尔函数会算不会讲理，纯命题能讲理不会算，`Dec` 是两者的
桥——本章所有树操作都返回 `Dec` 版，并且当场用 `toWitness` 从计算里
**钓出证明**，这是 17 章判定性体系第一次真正派上用场。

对应示例：`../examples/Ex24_intrinsic_extrinsic.agda`

**实测口径**（02 章）：本章报错文本均为 **Agda 2.9.0 + stdlib 3.0** 实测原样粘贴（复现用的
`examples/TmpProbe39*.agda` 已删除，报错路径显示为当时的探针文件名）；
代码片段与示例一致，书中（Haskell 风味的伪 Agda）写法全部改成了
stdlib 3.0 下真实可编译的版本。第 9 节涉及「隐式参数与依赖消除」，
那是 09/10/13 章的正业，此处只用不证。

## 24.1 三种「判断」的分野

Maguire 6.1 节的问题意识：一个谓词可以有三副面孔，**信息含量与可计算
性成反比**。

**面孔一：纯布尔函数**。只会算，不会讲理——它就是 17 章 `_≟_` 配方里
最内层那个 `_≡ᵇ_` 的亲戚：

```agda
leqᵇ : ℕ → ℕ → Bool
leqᵇ zero    _       = true
leqᵇ (suc _) zero    = false
leqᵇ (suc m) (suc n) = leqᵇ m n

_ : leqᵇ 3 5 ≡ true
_ = refl

_ : leqᵇ 5 3 ≡ false
_ = refl
```

`refl` 验收的是**计算结果**（11 章：算到同形）。想拿这个 `false` 去
反驳 `5 ≤ 3`，手里是空的——`false` 只是个构造子，不带任何理由。

**面孔二：bool 命题化**。`Data.Bool.Base` 里一枚三行函数把 Bool 翻成
类型（源码原样）：

```agda
T : Bool → Set
T true  = ⊤
T false = ⊥
```

于是「算出来是 true」变成「`T (leqᵇ 3 5)` 有项」，而它的项就是 `tt`：

```agda
_ : T (leqᵇ 3 5)
_ = tt
```

带证据的判定走 17 章老朋友 `Reflects` + `T?`（`Data.Bool.Properties`）：

```agda
_ : Dec (T (leqᵇ 5 3))
_ = T? (leqᵇ 5 3)
```

**面孔三：纯命题**。直接堆构造子，不可「计算」，但结构里全是信息：

```agda
3≤5-raw : 3 ≤ 5
3≤5-raw = s≤s (s≤s (s≤s z≤n))
```

把三者的关系钉死的是 `Dec` 这个 record（`Relation.Nullary.Decidable.Core`
源码，注意构造子名与两个 pattern）：

```agda
record Dec (A : Set a) : Set a where
  constructor _because_
  field
    does  : Bool
    proof : Reflects A does

pattern yes a =  true because ofʸ  a
pattern no ¬a = false because ofⁿ ¬a
```

`Dec = Bool + Reflects`：**一头可算（`does`），一头可讲理（`proof`）**。
取 Bool 那头的算子叫 `⌊_⌋`，stdlib 注释里话说得很直白——
"The traditional name for isYes is ⌊_⌋, indicating the stripping of
evidence"（剥掉证据）：

```agda
3≤5? : Dec (3 ≤ 5)
3≤5? = 3 ≤? 5

_ : ⌊ 3≤5? ⌋ ≡ true            -- Bool 那头：可算
_ = refl
```

取证据那头就没有 `⌊_⌋` 这种一键剥离的算子——`proof` 的类型 `Reflects A
does` 里 `does` 是**同一个 record 的字段**，所以想拿到 `Reflects (3 ≤ 5)
true` 这个具体形状，得先把 `3≤5?` 拆开看是哪一支：

```agda
3≤5-proof : Reflects (3 ≤ 5) true
3≤5-proof with 3≤5?
... | yes p = ofʸ p
... | no ¬p = ⊥-elim (¬p (s≤s (s≤s (s≤s z≤n))))
```

`no` 分支不是装饰：`¬p : ¬ (3 ≤ 5)`，喂进 `s≤s (s≤s (s≤s z≤n)) : 3 ≤ 5`
得到 `⊥`，`⊥-elim` 结案。这一行是**「3 ≤ 5 的可判定性与它的证据是同一
件事的两面」**的写法示范；`p` 在 `yes` 分支里就是我们要的 `3 ≤ 5`。

分工表，本章后面全部按它行文：

| 形状 | 能计算 | 携带理由 | 本章用途 |
|---|---|---|---|
| `Bool` 函数（`leqᵇ`） | 是 | 否 | 说明「算得出、证不了」 |
| `T b` / `Reflects` | 是（算 `b`） | 间接 | 17 章配方复用 |
| 纯命题（`3 ≤ 5`） | 否 | 是 | `All`、`IsBST`、`_∈_` |
| `Dec A` | 是 | 是 | `∈?`、`all?`、`is-bst?` |

## 24.2 形状进类型的第一次预演：SizeTree

教材版二叉树（`BinTree`）只有两个构造子，空树不带叶值：

```agda
data BinTree (A : Set) : Set where
  empty  : BinTree A
  branch : BinTree A → A → BinTree A → BinTree A

pattern leaf a = branch empty a empty
```

`pattern` 声明是 12 章的正业，这里先用它当语法糖：`leaf 1` 展开即
`branch empty 1 empty`，示例里 `tree`、`bad-tree`、`insert` 的空树分支
全靠它写得紧凑。stdlib 3.0 的正品 `Data.Tree.Binary` 长得不一样
（`leaf` 携带叶值、没有 `empty` 构造子），对照与搬家说明在第 10 节。

「良形」的第一条路不需要命题——**把结点数做成索引**，形状信息进类型：

```agda
data SizeTree : ℕ → Set where
  st-empty : SizeTree zero
  st-node  : ∀ {n m} → SizeTree n → ℕ → SizeTree m → SizeTree (suc (n + m))

st₃ : SizeTree 3
st₃ = st-node (st-node st-empty 1 st-empty) 2 (st-node st-empty 3 st-empty)
```

`st₃` 的类型 `SizeTree 3` 是**算出来的**：两棵单结点子树的索引各是
`suc (zero + zero)`，外层再套 `suc (n + m)`，规范化后正是 `3`（15 章
`n + zero` 的教训反过来用——这里的加法两侧都是构造子，definition 推得开）。
于是「非空树上取根」只需一条子句：

```agda
st-head : ∀ {n} → SizeTree (suc n) → ℕ
st-head (st-node _ x _) = x
```

`st-empty` 那一支**根本不必写**：它的类型是 `SizeTree zero`，与索引
`suc n` 天生对不上。这不是「Agda 好心放过你」，硬写会被索引当场判死
（实测）：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe39h.agda:11.9-17: error: [ImpossibleConstructor.UnifyConflict]
The case for the constructor st-empty is impossible
because unification ended with a conflicting equation
  zero ≟ suc n
Possible solution: remove the clause, or use an absurd pattern ().
when checking that the pattern st-empty has type SizeTree (suc n)
```

报错难得地直接给了**两条修法**（删掉这一支，或者用荒谬模式 `()`）——
这是 18 章 `Vec` 越界不可表达的同一条机制，本章第 9 节会让它为 BST
服务：**不可能的分支不必实现**，是 intrinsic 风格最省的一笔。

顺带记一笔 `st-node` 的设计：索引写成 `suc (n + m)` 而非 `suc (suc n)`
之类，是为了让「树的规模」与子树规模的真实关系进类型；代价是
`SizeTree 3` 的合法项要凑出加法，读 `st₃` 那行时得心里算一遍。

## 24.3 成员命题 `_∈_`：三个构造子 = 三条路径证据

Maguire 6.10：把「`a` 在这棵树里」做成数据（Curry–Howard，14 章）。
构造子读起来就是三条**路径**：

```agda
infix 4 _∈_
data _∈_ {A : Set} : A → BinTree A → Set where
  here  : a ∈ branch l a r
  left  : a ∈ l → a ∈ branch l b r
  right : a ∈ r → a ∈ branch l b r
```

`here` 说「根就是我要的」，`left`/`right` 说「在左（右）子树里，这是
那条更短的证据」。三个构造子都**没有**关于大小的前提，所以证据本身
就是一条从根出发的路径——这也是它天然可判定的原因（24.5）。

写法上有两个坑，都实测过（两条报错出自同一个探针 `TmpProbe39c` 的两次
改写，文件名相同、行号不同，正好说明它们是各自独立的问题）。其一：
`{A : Set}` 必须是 data 的**隐式参数**。
把它省成自由变量（`data _∈_ : A → BinTree A → Set`），`A` 会被泛化到
`Set` 层面，`here` 的参数量 `a ∈ branch l a r` 里 `A` 提升整条构造子的
sort，于是「声明说 Set、构造子却住 Set₁」被拒：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe39c.agda:20.3-7: error: [ConstructorDoesNotFitInData]
Constructor here
of inferred sort Set₁
does not fit into data type of sort Set.
(Reason: Set₁ is not less or equal than Set)
when checking that the type Set of an argument to the constructor
here fits in the sort Set of the datatype.
Note: this argument is forced by the indices of here, so this
definition would be allowed under --large-indices.
```

报错末尾那句 "this argument is forced by the indices … would be allowed
under `--large-indices`" 是标准豁免说明：索引被强制（forced）时大索引
是安全的，但 Agda 要你自己打开开关——**教程体示例不开 `--large-indices`**，
所以老老实实把 `A` 提成隐式参数即可。其二：`here : a ∈ branch l a r` 里
`a`、`l`、`r` 都是自由变量，靠的是**声明式泛化**，前提是它们先在作用域
里；示例第 3 节开头那段 `private variable` 块必须写在 `data` **之前**
（Agda 的作用域是位置敏感的，25 章同款）：

```agda
private
  variable
    A : Set
    a b : A
    t : BinTree A
    l r : BinTree A
    P : A → Set
```

变量块挪到 `data BinTree` 之后时，`l r : BinTree A` 那行直接
`Not in scope: BinTree`——先声明才可使用，与 03 章「文件从上往下读」
一致。

示范树与证据：

```agda
tree : BinTree ℕ
tree = branch (branch (leaf 1) 2 (leaf 3)) 4 (leaf 6)

3∈tree : 3 ∈ tree
3∈tree = left (right here)
```

`3∈tree` 是「先向左到 4 的左子树，再向右，然后就是根 3」——项与路径
一一对应。空树上没有成员，`¬ (a ∈ empty)` 展开就是 `a ∈ empty → ⊥`，
构造子一个都匹配不上，06 章的荒谬模式一行结案：

```agda
not-in-empty : (a : A) → ¬ (a ∈ empty)
not-in-empty a ()
```

## 24.4 Maybe 版 `search∈`：负方向没证据

Maguire 6.7 的第一步（n=5?）：`just` 里塞「找到」的证据，`nothing`
什么也不说。

```agda
search∈ : (A : Set) → (D : (a b : A) → Dec (a ≡ b)) →
          (t : BinTree A) (a : A) → Maybe (a ∈ t)
search∈ A _≟_ empty a = nothing
search∈ A _≟_ (branch l x r) a with x ≟ a
... | yes refl = just here
... | no _ with search∈ A _≟_ l a
...   | just p = just (left p)
...   | nothing with search∈ A _≟_ r a
...   | just p = just (right p)
...   | nothing = nothing
```

两条 `refl` 单元测试（示例里真跑通）：

```agda
_ : search∈ ℕ _≡?_ tree 4 ≡ just here
_ = refl

_ : search∈ ℕ _≡?_ tree 7 ≡ nothing
_ = refl
```

三个写法要点：

1. 参数名写 `_≟_` 是**记号复用**——把判定函数命名为 `_≟_`，体内
   `with x ≟ a` 就能用 infix 写；实参传 stdlib 的 `_≡?_`（38 章：3.0 里
   `_≟_` 已弃用，`Data.Nat` 的正名是 `_≡?_`）。示例第 4 节那两行测试
   传的就是 `_≡?_`。
2. `yes refl`：`Dec (x ≡ a)` 的 `yes` 分支带一条 `x ≡ a`，直接拿它当
   **模式**（`refl` 作为模式即 13 章的 transport-by-pattern），于是
   `just here` 的类型 `x ∈ branch l x r` 里的 `x` 换回 `a` 不用手写 subst。
3. **嵌套 with 的缩进写法**：`... | no _ with search∈ … l a` 之后再开一层
   `...   | just p = …`，内层的 `...` 多缩两格。这种「内层套完不再回外层」
   的形状是合法的——示例里它类型检查通过。坑在**想回到外层**：第 9 节
   会撞上并给出实测报错。

信息损失正是这一节的主题：`nothing` 里没有 `¬ (7 ∈ tree)`。想用它反驳
点什么，手里是空的。这就是 Maguire 说的「Maybe 太弱：`nothing` 只说
『我没找到』，不说『找不到』」。

## 24.5 Dec 版 `∈?`：一条 with 挂三个子判定

Maguire 6.11 的完全体。整个函数只有四条子句，判定与证据同时交付：

```agda
∈? : (D : (a b : A) → Dec (a ≡ b)) → (t : BinTree A) → (a : A) → Dec (a ∈ t)
∈? _≟_ empty a = no λ ()
∈? _≟_ (branch l x r) a
  with x ≟ a | ∈? _≟_ l a | ∈? _≟_ r a
... | yes refl | _ | _ = yes here
... | no _ | yes a∈l | _ = yes (left a∈l)
... | no _ | no _ | yes a∈r = yes (right a∈r)
... | no x≢a | no a∉l | no a∉r
  = no λ { here → x≢a refl
         ; (left a∈l) → a∉l a∈l
         ; (right a∈r) → a∉r a∈r }
```

**多目标 with**（`with e₁ | e₂ | e₃`）一次把三个子判定摆上桌面，分支
按**优先级**从上往下匹配：第一条只锁住 `yes refl`，后两个位置写 `_`
表示不管。四条子句已经是全组合的覆盖——`(no, yes, _)`、`(no, no, yes)`、
`(no, no, no)` 三种剩余情形各一条，`2³ = 8` 里少掉的三条被前面的通配
吞了。**不必**为凑 8 条而写不可达分支，这一点和单目标 with 完全一致。

`empty` 那行是本章最划算的一行：`¬ (a ∈ empty)` 无需证明体，`λ ()` 结案
（24.3 的 `not-in-empty` 就是它）。

最下面的 `no λ { … }` 是「三个构造子各喂一个局部反证」——17 章 `any?`
里同款手艺。少喂一个，覆盖检查立刻开口（实测：把 `right` 那格删掉）：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe39c.agda:31.12-32.22: error: [CoverageIssue]
Incomplete pattern matching for .extendedlambda0. Missing cases:
  .extendedlambda0 l x r a x≢a a∉l a∉r (right x₁)
when checking the definition of .extendedlambda0
```

`.extendedlambda0` 是 Agda 给「with 分支里那枚匿名 λ」起的内部名字——
报错里的这个前缀值得认识，它说明**缺分支的是那枚反证 λ**，不是外层
函数。

两条验收：

```agda
_ : ∈? _≡?_ tree 3 ≡ yes (left (right here))
_ = refl

_ : ∈? _≡?_ tree 7 ≡ no _
_ = refl
```

第一行连**证据**都验：`yes (left (right here))` 与 `∈? _≡?_ tree 3` 的
正规形逐项相同（11 章：`refl` 只认算到同形）。第二行的 `no _` 里有
一个洞：反证那枚 λ 太长，写成 `_` 让类型检查器去解——它是**隐式元变量**，
`refl` 的严格比较允许模式反解，于是洞被左边那枚真正的 λ 填上，过关。
（11.2 的 `true ∨₂ _` 也是洞，但那是带空格的元变量、把式子从函数掉回
Bool；这里 `_` 在 `no` 的实参位，性质不同。）

既然可以留洞，能不能**写死**一个反证试试？最短的猜测是 `λ ()`：

```agda
_ : ∈? _≡?_ tree 7 ≡ no (λ ())
_ = refl
```

实测被拒，而且报错很说明问题：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe39n.agda:10.26-27: error: [ShouldBeEmpty]
7 ∈ tree should be empty, but the following constructor patterns
are valid:
  left {._} {._} {._} {._} _
  right {._} {._} {._} {._} _
when checking that the expression λ () has type ¬ 7 ∈ tree
```

读法：`λ ()` 要求**定义域类型在构造子层面为空**。`a ∈ empty` 为空（三个
构造子的索引都要求 `branch`），所以 `∈? empty a = no λ ()` 合法；而
`7 ∈ tree` 里 `left`/`right` 两枚构造子的**形状**是匹配的（它们只要求
「7 在子树里」，索引冲突要更深一层才能看出），Agda 判定该类型「非空」，
空 λ 不吃。结论：**「算出来的反证」不能凭猜测重写**，要么用 `toWitnessFalse`
把它从计算里钓出来（24.6 的手法），要么留洞让反解去填。

## 24.6 `All` 谓词与 `IsBST`：extrinsic 不变式的标准姿势

Maguire 6.12：BST 的性质是「每棵子树里所有值都满足某谓词」。先做
`All`（与 18 章 `Vec` 的 `All` 同构，只是换载体）：

```agda
data All {A : Set} (P : A → Set) : BinTree A → Set where
  all-empty  : All P empty
  all-branch : All P l → P a → All P r → All P (branch l a r)
```

`All` 是**谓词的提升**：`P : A → Set` 逐点作用到树上每个结点值。它可判定，
只要 `P` 可判定——`all?` 是本章第二个「多目标 with」示范（四条子句覆盖
`2³` 全组合，靠 `_` 吞掉冗余）：

```agda
all? : (P : A → Set) → (P? : (a : A) → Dec (P a)) →
       (t : BinTree A) → Dec (All P t)
all? P P? empty = yes all-empty
all? P P? (branch l a r) with P? a | all? P P? l | all? P P? r
... | yes pa | yes al | yes ar = yes (all-branch al pa ar)
... | no ¬pa | _ | _ = no λ { (all-branch _ pa _) → ¬pa pa }
... | _ | no ¬al | _ = no λ { (all-branch al _ _) → ¬al al }
... | _ | _ | no ¬ar = no λ { (all-branch _ _ ar) → ¬ar ar }
```

注意三条 `no` 分支的**顺序**：每条先锁住一个位置为 `no`、其余位置写 `_`。
次序颠倒了不会错，但会留下不可达分支（07 章子句顺序的代价）；写「第一个
失败者即出反证」时按 `P? a → 左 → 右` 排即可。

BST 定义（Maguire 6.12 原样）：

```agda
data IsBST {A : Set} (rel : A → A → Set) : BinTree A → Set where
  bst-empty  : IsBST rel empty
  bst-branch : All (λ v → rel v a) l →
               All (λ v → rel a v) r → IsBST rel l → IsBST rel r →
               IsBST rel (branch l a r)
```

四个前提：左子树全部 `≺` 根、根 `≺` 右子树全部、两棵子树各自递归 BST。
**这就是 extrinsic 的标志**：`IsBST` 追加在任意 `BinTree` 上，类型允许
坏树存在，坏树只是交不出证据。示例里 `bad-tree`（把 4 塞进 2 的左子树）
是完完全全合法的 `BinTree ℕ`。

判定过程（Maguire 6.13）把「是不是 BST」降成一个 `Dec`——一条 with
挂四个子判定：

```agda
is-bst? : (t : BinTree ℕ) → Dec (IsBST _<_ t)
is-bst? empty = yes bst-empty
is-bst? (branch l a r)
  with all? (λ x → x < a) (λ x → x <? a) l | all? (λ x → a < x) (λ x → a <? x) r
       | is-bst? l | is-bst? r
... | yes l<a | yes a<r | yes bl | yes br = yes (bst-branch l<a a<r bl br)
... | no ¬l<a | _ | _ | _ = no λ { (bst-branch l<a _ _ _) → ¬l<a l<a }
... | _ | no ¬a<r | _ | _ = no λ { (bst-branch _ a<r _ _) → ¬a<r a<r }
... | _ | _ | no ¬bl | _ = no λ { (bst-branch _ _ bl _) → ¬bl bl }
... | _ | _ | _ | no ¬br = no λ { (bst-branch _ _ _ br) → ¬br br }
```

`λ x → x <? a` 是 stdlib 的 `_<?_ : Decidable _<_`（38 章：自然数序的
判定正品），`_≡?_`/`_<?_` 都是 3.0 的正名。

Maguire 在这里写了一句读者容易滑过去的话：这种手搭证明太累，
「交给 `C-c C-a`（自动证明）」。更干脆的第三条路是——**既然已经有
`is-bst?`，就别再证了，直接从计算里钓**：

```agda
tree-is-bst : IsBST _<_ tree
tree-is-bst = toWitness {a? = is-bst? tree} tt

bad-tree : BinTree ℕ
bad-tree = branch (leaf 4) 2 (leaf 1)

¬bad-bst : ¬ IsBST _<_ bad-tree
¬bad-bst = toWitnessFalse {a? = is-bst? bad-tree} tt
```

拆开看这行 `toWitness` 凭什么成立。stdlib 源码：

```agda
True  : Dec A → Set
True  = T ∘ isYes
toWitness : {a? : Dec A} → True a? → A
toWitness {a? = true  because [a]} _  = invert [a]
toWitness {a? = false because  _ } ()
```

所以 `toWitness {a? = is-bst? tree} tt` 的 `tt` 要住的类型是
`True (is-bst? tree) = T ⌊ is-bst? tree ⌋`——**要求 `is-bst? tree` 的
`does` 字段规范化成 `true`**。这是一次纯计算（`all?`、`<?`、四条 with
分支全跑一遍），算出 `true` 就有 `T true = ⊤`、`tt` 合法，而 `toWitness`
顺手把 `proof` 字段里的 `ofʸ` 反转（`invert`）成交付项。**一次 `C-c C-n`
都不按，证明就来自函数体本身**——这是 17 章「判定性与证明的分野」的
兑现时刻，也是 extrinsic 风格在 Agda 里最省力的姿势。

`{a? = …}` 这个具名隐式**不能省**。省掉之后 `a?` 成了待解隐式，而目标
类型 `IsBST _<_ tree` 里没有任何位置能反推出它该是哪个 `Dec` 项（同一个
命题可以有无数个判定器）：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe39o.agda:12.16-25: error: [UnsolvedMetaVariables]
Unsolved metas at the following locations:
  /Volumes/mac004/code/programming/agda/examples/TmpProbe39o.agda:12.16-25
```

报错位置正是 `toWitness tt` 那一段，类型就是「那个隐式 `Dec` 没头绪」。
**`Dec` 的证据不会自己长腿走过来**，必须点名判定过程——这条规律对
所有 `toWitness`/`toWitnessFalse` 通用（示例第 9 节的 `found4`、`¬5∈t∞`
同款写法）。

## 24.7 三分律 `Tri`：一次分案，反证随身

Maguire 6.14：插入要比较 `a` 与根 `x`，需要的不是「`a < x` 成立吗」，
而是**三分**结果——小于／等于／大于，并且另外两条各带一份反证。stdlib
`Relation.Binary.Definitions` 的 `Tri`（源码原样，构造子名与书同名）：

```agda
data Tri (A : Set a) (B : Set b) (C : Set c) : Set (a ⊔ b ⊔ c) where
  tri< : ( a :   A) (¬b : ¬ B) (¬c : ¬ C) → Tri A B C
  tri≈ : (¬a : ¬ A) ( b :   B) (¬c : ¬ C) → Tri A B C
  tri> : (¬a : ¬ A) (¬b : ¬ B) ( c :   C) → Tri A B C

Trichotomous : Rel A ℓ₁ → Rel A ℓ₂ → Set _
Trichotomous _≈_ _<_ = ∀ x y → Tri (x < y) (x ≈ y) (x > y)
  where _>_ = flip _<_
```

每个构造子携带**一份正面证据 + 两份反证**；`Trichotomous` 只要求关系对
`_≡_` 三分（等式用 `≈` 参数化，本章一律取 `_≡_`）。

为什么不用三次 `Dec`？三条 `Dec` 调用要手写 8 个组合的分支，还要自己
拼「同时成立不可能」的论证；`Tri` 把「三选一且互斥」打包在构造子里，
`with` 一行开三支，反证**随身**——第 8、9 节的插入与查找全靠这三个
`¬` 字段活着。

自然数三分的手打证明（书 6.14 的练习，示例完整跑通）：

```agda
refute : ∀ {x y : ℕ} → ¬ x < y → ¬ suc x < suc y
refute x≮y (s≤s x<y) = x≮y x<y

<-cmp′ : (x y : ℕ) → Tri (x < y) (x ≡ y) (y < x)
<-cmp′ zero    zero    = tri≈ (λ ()) refl (λ ())
<-cmp′ zero    (suc y) = tri< (s≤s z≤n) (λ ()) (λ ())
<-cmp′ (suc x) zero    = tri> (λ ()) (λ ()) (s≤s z≤n)
<-cmp′ (suc x) (suc y) with <-cmp′ x y
... | tri< x<y x≉y x≰y =
  tri< (s≤s x<y) (λ { sx≈sy → x≉y (suc-injective sx≈sy) }) (refute x≰y)
... | tri≈ x≮y x≈y x≱y =
  tri≈ (refute x≮y) (cong suc x≈y) (refute x≱y)
... | tri> x≮y x≉y x>y =
  tri> (refute x≮y) (λ { sx≈sy → x≉y (suc-injective sx≈sy) }) (s≤s x>y)
```

`refute` 是「两边同时加一，反向的不等仍然反向」——`s≤s` 剥一层就归约到
归纳假设。等数分支里 `suc-injective`（`Data.Nat.Properties`）把
`suc x ≡ suc y` 折成 `x ≡ y`，这是 13 章 `cong`/单射性的标准弹药。

验货配方（15 章「读库百遍」的那一条）：拿 stdlib 正品类型来接自己的手打版：

```agda
check-cmp : Trichotomous _≡_ _<_
check-cmp = <-cmp′
```

这行通过 = 手打版与 `<-cmp` **同类型**（`<-cmp` 在 stdlib 里正是
`Trichotomous _≡_ _<_` 的值）。想再进一步验「同项」，写成
`(x y : ℕ) → <-cmp′ x y ≡ <-cmp x y` 配 `refl` 就得出入（实测）：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe39f.agda:26.16-20: error: [UnequalTerms]
The terms
  <-cmp′ x y
and
  <-cmp x y
  | Relation.Nullary.map′ (Data.Nat.Properties.≡ᵇ⇒≡ x y)
    (Data.Nat.Properties.≡⇒≡ᵇ x y)
    (x Data.Nat.≡ᵇ y Relation.Nullary.because
     Relation.Nullary.T-reflects (x Data.Nat.≡ᵇ y))
  | x Data.Nat.<ᵇ y Relation.Nullary.because
    Relation.Nullary.T-reflects (x Data.Nat.<ᵇ y)
are not equal at type Tri (x < y) (x ≡ y) (y < x)
when checking that the expression refl has type
<-cmp′ x y ≡ <-cmp x y
```

报错右边那一坨把 stdlib 的实现摊开了：正品 `<-cmp` 不是递归构造 `Tri`，
而是拿**布尔比较** `≡ᵇ`/`<ᵇ` 算出 Bool、再用 `map′` 连同
`≡ᵇ⇒≡`/`≡⇒≡ᵇ` 两条双向引理把命题换过来（`because` 就是 24.1 那个 `Dec`
构造子）。手打版与之**同类型不同语法**，`refl` 自然不认（11.1：`refl`
只认证算到同形）。示例只做**类型层**的验货，这是诚实的强度——想验
同项只能靠外延公理逐点证（40 章实测：3.0 里公理的**类型**是
`Axiom.Extensionality.Propositional.Extensionality`，库不给证明，
`funext` 只是自己 postulate 时的常用名），而那已不是「读库」而是
「证库」了。

## 24.8 extrinsic 版 insert：算法与保序证明分开写

Maguire 6.15 的路线，与 34 章插入排序完全同构：**一份算法 + 若干份
「形状相同」的镜像证明**。

算法本身类型里没有任何 BST 信息，喂任何 `BinTree` 都跑：

```agda
insert : ℕ → BinTree ℕ → BinTree ℕ
insert a empty = leaf a
insert a (branch l x r) with <-cmp a x
... | tri< _ _ _ = branch (insert a l) x r
... | tri≈ _ _ _ = branch l x r
... | tri> _ _ _ = branch l x (insert a r)
```

三个 `_` 是「这版算法不需要反证」的诚实标注：函数只是**分派**。相等就
不重复插入（`tri≈` 分支原样还树），所以 `insert` 保持集合语义而非多重
表语义。

引理一：`All P` 在插入后保持。

```agda
all-insert : (P : ℕ → Set) (a : ℕ) → P a →
             ∀ {t} → All P t → All P (insert a t)
all-insert P a pa {empty} all-empty = all-branch all-empty pa all-empty
all-insert P a pa {branch l x r} (all-branch al px ar) with <-cmp a x
... | tri< a<x _ _ = all-branch (all-insert P a pa al) px ar
... | tri≈ _ a=x _ = all-branch al px ar
... | tri> _ _ x<a = all-branch al px (all-insert P a pa ar)
```

关键在签名的一般化程度：`P` 与「`P a` 成立」是**参数**，所以这条引理一次
覆盖 24.6 里两种具体谓词（`λ v → v < x`、`λ v → x < v`）。`{empty}`、
`{branch l x r}` 用**花括号隐式模式**从目标类型里把 `t` 拆出来（10 章
依赖消除的手法）——因为 `insert a t` 在结论里，`t` 是隐式参数。

引理二 + 主定理：

```agda
bst-insert : (a : ℕ) {t : BinTree ℕ} → IsBST _<_ t → IsBST _<_ (insert a t)
bst-insert a {empty} bst-empty =
  bst-branch all-empty all-empty bst-empty bst-empty
bst-insert a {branch l x r} (bst-branch l<x x<r bl br) with <-cmp a x
... | tri< a<x _ _ =
  bst-branch (all-insert (λ v → v < x) a a<x l<x) x<r
             (bst-insert a bl) br
... | tri≈ _ a=x _ = bst-branch l<x x<r bl br
... | tri> _ _ x<a =
  bst-branch l<x (all-insert (λ v → x < v) a x<a x<r)
             bl (bst-insert a br)
```

逐行读 `tri<` 分支（要交出的四个前提，目标 `IsBST _<_ (branch (insert a l) x r)`）：

1. `All (λ v → v < x) (insert a l)`——由引理一搬运：`all-insert` 喂
   `P = λ v → v < x`、`pa = a<x`（这正是 `tri<` 的第一个字段）、
   原证据 `l<x`。**这就是 `Tri` 那份反证旁边正面证据的用法**。
2. `All (λ v → x < v) r`——右子树没动，直接还 `x<r`。
3. `IsBST _<_ (insert a l)`——递归调用 `bst-insert a bl`。
4. `IsBST _<_ r`——没动，还 `br`。

`with <-cmp a x` 与算法一字不差，四个分支的形状对齐四条子句——这就是
Maguire 反复强调的「**证明形状 = 计算形状**」，也是 15 章归纳剧本的
升级版：归纳假设（递归调用）与算法递归**同处一位**。

负担清点：一个 `insert` 配三份代码（`all-insert`、`bst-insert`、以及
`insert` 本体），且 `IsBST` 证明必须在每个操作之后重新交一次。extrinsic
的收获面也记清楚：算法朴素、和教科书伪码同步、证明可以搬运复用
（`all-insert` 就是一条独立引理，堆、AVL 都能各取所需）。

## 24.9 intrinsic 版 BST：把界做进索引

Maguire 6.16–6.17 的换法：**不写「树 + 它有序的证据」，只写「有序树」**。
具体做法是把上下界做成索引，并且——这一节的第一句就暴露代价——
需要关系带两条定律：

```agda
module Intr (A : Set) (rel : A → A → Set)
            (trans : ∀ {x y z} → rel x y → rel y z → rel x z)
            (asym  : ∀ {x y} → rel x y → ¬ rel y x) where
```

**为什么非要 `trans` 和 `asym`？** 因为界化之后，第一条要证的就不是
「操作保持 BST」而是「这棵树的区间本身合法」。试一下裸 `rel`（示例
`TmpProbe39t`：同样的 `BST`、不给定律）：

```agda
module NoLaws (A : Set) (rel : A → A → Set) where
  data BST : A → A → Set where
    ◃empty : ∀ {lo hi} → rel lo hi → BST lo hi
    ◃node  : ∀ {lo hi} (a : A) → BST lo a → BST a hi → BST lo hi

  ◃lo<hi : ∀ {lo hi} → (t : BST lo hi) → rel lo hi
  ◃lo<hi (◃empty lo<hi) = lo<hi
  ◃lo<hi (◃node x l r) = ◃lo<hi l
```

最后一行报错：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe39t.agda:15.26-34: error: [UnequalTerms]
The terms
  x
and
  hi
are not equal at type A
when checking that the expression ◃lo<hi l has type rel lo hi
```

这条报错值得专门读一遍，因为 intrinsic 风格的报错**经常长得像索引
冲突而不是「定律缺失」**。手里的 `◃lo<hi l : rel lo x`，目标是
`rel lo hi`；Agda 试着让两个 `rel` 项同语法，只能对索引做 unification，
于是问「`x` 和 `hi` 是同一个变量吗」——不是，报错结束。**病根是缺
`rel lo x → rel x hi → rel lo hi` 这一步传递性**，但类型检查器不会替你
说这句话。看到 `The terms x and hi are not equal` 这类「两个本该无关的
索引被要求相等」，第一反应应该是：**我是不是在裸关系上想做有序性推理**。

正主（示例第 9 节）：

```agda
  data BST : A → A → Set where
    ◃empty : ∀ {lo hi} → rel lo hi → BST lo hi
    ◃node  : ∀ {lo hi} (a : A) → BST lo a → BST a hi → BST lo hi
```

`◃empty` 必须附带 `rel lo hi`——**空区间上连空树都造不出来**。这就是
「非法状态不可表达」：不是给坏树配更严的谓词，而是坏树这个类型**没有
项**。对照 24.6：那里 `bad-tree` 是合法 `BinTree ℕ`，只是交不出 `IsBST`；
这里想造一棵「界是 `2 < 1`」的树，直接在构造函数时卡住。

插入。签名里界证据是实参，递归时**换界**：

```agda
  ◃insert : (cmp : Trichotomous {A = A} _≡_ rel) →
            (a : A) → ∀ {lo hi} → rel lo a → rel a hi →
            BST lo hi → BST lo hi
  ◃insert cmp a lo<a a<hi (◃empty _) =
    ◃node a (◃empty lo<a) (◃empty a<hi)
  ◃insert cmp a lo<a a<hi (◃node x l r) with cmp a x
  ... | tri< a<x _ _ = ◃node x (◃insert cmp a lo<a a<x l) r
  ... | tri≈ _ a=x _ = ◃node x l r
  ... | tri> _ _ x<a = ◃node x l (◃insert cmp a x<a a<hi r)
```

和 extrinsic 版一样长，但结论类型是 `BST lo hi`——**没有「保序定理」要证**，
类型正确性由模式匹配交付。`tri<` 分支里递归调用的界从 `rel lo a`、
`rel a x`（`l` 的界是 `lo .. x`，而 `a` 要插进去，`a` 相对 `x` 的位置
由 `a<x` 给出）现拼，Agda 在**这一行**就检查了「界收缩合法」。

成员证据直接活在索引上：

```agda
  data _◃∈_ : ∀ {lo hi} → A → BST lo hi → Set where
    ◃here  : ∀ {lo a hi} (l : BST lo a) (r : BST a hi) →
             a ◃∈ ◃node a l r
    ◃left  : ∀ {lo a hi} {b} (l : BST lo a) (r : BST a hi) →
             b ◃∈ l → b ◃∈ ◃node a l r
    ◃right : ∀ {lo a hi} {b} (l : BST lo a) (r : BST a hi) →
             b ◃∈ r → b ◃∈ ◃node a l r
```

三枚构造子都**带上子树本身**（`l`、`r` 作为模式参数），负方向的反证才
有地方取界。

两条区间引理——intrinsic 的负方向靠它们反驳「另一侧子树」：

```agda
  ◃lo<hi : ∀ {lo hi} → (t : BST lo hi) → rel lo hi
  ◃lo<hi (◃empty lo<hi) = lo<hi
  ◃lo<hi (◃node x l r) = trans (◃lo<hi l) (◃lo<hi r)

  ◃notBelow : ∀ {lo hi b} → (t : BST lo hi) → b ◃∈ t → ¬ rel b lo
  ◃notBelow (◃empty _)        ()
  ◃notBelow (◃node x l r) (◃here .l .r)   = asym (◃lo<hi l)
  ◃notBelow (◃node x l r) (◃left  .l .r p) = ◃notBelow l p
  ◃notBelow (◃node x l r) (◃right .l .r p) q =
    ◃notBelow r p (trans q (◃lo<hi l))

  ◃notAbove : ∀ {lo hi b} → (t : BST lo hi) → b ◃∈ t → ¬ rel hi b
  ◃notAbove (◃empty _)        ()
  ◃notAbove (◃node x l r) (◃here .l .r)    = asym (◃lo<hi r)
  ◃notAbove (◃node x l r) (◃left  .l .r p) q =
    ◃notAbove l p (trans (◃lo<hi r) q)
  ◃notAbove (◃node x l r) (◃right .l .r p) = ◃notAbove r p
```

`◃lo<hi` 是本节 `trans` 的第一次兑现：`◃node` 分支把 `rel lo x`（左子树
的界）与 `rel x hi`（右子树的界）接成 `rel lo hi`——**这正是 39t 报错
那一行的修复**。

`.l`、`.r` 是**点模式**（06 章）：写 `.l` 表示「这里必须是同一个 `l`」，
同时把等式（成员证据里那枚子树 = 外层模式的 `l`）交给你使用。
`◃notBelow` 的 `◃here` 分支：目标 `¬ rel x lo`（因为 `◃here` 强制 `b ≡ x`），
手里 `◃lo<hi l : rel lo x`，`asym` 一翻即得——**`asym` 的第二处兑现**。
`◃right` 分支要 `¬ rel b lo`，反设 `q : rel b lo`；`◃lo<hi l : rel lo x`
配 `trans q (◃lo<hi l) : rel b x`，而 `◃notBelow r p` 正是「`r`（界 `x .. hi`）
里的成员不可能 `≺ x`」——喂进去结案。`◃notAbove` 是镜像，`trans` 的
两个参数换序。

查询返回 `⊎`（找到给成员证据，找不到给**完整反证**）：

```agda
  ◃search : (cmp : Trichotomous {A = A} _≡_ rel) →
            (b : A) → ∀ {lo hi} → rel lo b → rel b hi →
            (t : BST lo hi) → b ◃∈ t ⊎ ¬ (b ◃∈ t)
  ◃search cmp b lo<b b<hi (◃empty _) = inj₂ λ ()
  ◃search cmp b lo<b b<hi (◃node x l r) with cmp b x
  ... | tri<  b<x ¬b≈x _   = ◃go<  b<x ¬b≈x l r (◃search cmp b lo<b b<x l)
  ... | tri≈  _   b≈x  _   = ◃go≈ b b≈x l r
  ... | tri>  _   ¬b≈x x<b = ◃go> x<b ¬b≈x l r (◃search cmp b x<b b<hi r)
```

第一行 `inj₂ λ ()` 是「对不可能分支返回 ⊥」的字面实现：`b ◃∈ ◃empty p`
没有任何构造子（24.3 的 `not-in-empty` 换了载体），荒谬模式结案——
Maguire 6.10 强调的 intrinsic 红利在这里落地。

三条合并引理，每层只管一层：

```agda
  ◃go< : ∀ {lo x hi b} → rel b x → ¬ b ≡ x →
         (l : BST lo x) (r : BST x hi) →
         (b ◃∈ l ⊎ ¬ (b ◃∈ l)) → b ◃∈ ◃node x l r ⊎ ¬ (b ◃∈ ◃node x l r)
  ◃go< b<x ¬b≈x l r (inj₁ p)  = inj₁ (◃left l r p)
  ◃go< b<x ¬b≈x l r (inj₂ ¬p) =
    inj₂ λ { (◃here  .l .r)   → ¬b≈x refl
           ; (◃left  .l .r q) → ¬p q
           ; (◃right .l .r q) → ◃notBelow r q b<x }

  ◃go≈ : ∀ {lo x hi} (b : A) → b ≡ x →
         (l : BST lo x) (r : BST x hi) → b ◃∈ ◃node x l r ⊎ ¬ (b ◃∈ ◃node x l r)
  ◃go≈ x refl l r = inj₁ (◃here l r)

  ◃go> : ∀ {lo x hi b} → rel x b → ¬ b ≡ x →
         (l : BST lo x) (r : BST x hi) →
         (b ◃∈ r ⊎ ¬ (b ◃∈ r)) → b ◃∈ ◃node x l r ⊎ ¬ (b ◃∈ ◃node x l r)
  ◃go> x<b ¬b≈x l r (inj₁ p)  = inj₁ (◃right l r p)
  ◃go> x<b ¬b≈x l r (inj₂ ¬p) =
    inj₂ λ { (◃here  .l .r)   → ¬b≈x refl
           ; (◃left  .l .r q) → ◃notAbove l q x<b
           ; (◃right .l .r q) → ¬p q }
```

`◃go<` 的 `inj₂` 分支三格，各自用了手上不同的信息：`◃here` 撞等式
（`¬b≈x refl`，`refl` 作为模式把 `b` 认成 `x`）、`◃left` 交递归反证、
`◃right` 用 `◃notBelow` + `b<x`（**这里才需要界与定律**）。
`◃go≈` 只有 `b ≡ x` 那一支可写：模式 `refl` 把 `b` 换成 `x`，直接
`inj₁ (◃here l r)`。

为什么不把这三段直接写进 `◃search` 的 `with` 里？**嵌套 with 回不到
外层**。最自然的写法是把 24.4 那招（内层 `with` 就地再开一层）搬过来：

```agda
◃search cmp b lo<b b<hi (◃node x l r) with cmp b x
... | tri< b<x ¬b≈x _ with ◃search cmp b lo<b b<x l
...   | inj₁ p = inj₁ (◃left l r p)
...   | inj₂ ¬p = inj₂ λ { … }
... | tri≈ _ b≈x _ = inj₁ (◃here l r)     -- ← 想回到外层 with
```

探针实测（`TmpProbe39w`，完整可跑的版本）：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe39w.agda:42.7-19: error: [ConstructorPatternInWrongDatatype]
tri≈ is not a constructor of the datatype _⊎_
when checking that the pattern tri≈ _ b≈x _ has type
(b ◃∈ l) ⊎ (b ◃∈ l → Data.Irrelevant.Irrelevant Data.Empty.Empty)
```

报错把病根摊开了：**单 `...` 永远咬住最内层 `with`**，所以第三个外层
分支被当成「对 `b ◃∈ l ⊎ ¬ (b ◃∈ l)` 做模式匹配」，于是 `tri≈` 被判
「不是 `_⊎_` 的构造子」。`¬ (b ◃∈ l)` 展开成 `b ◃∈ l → ⊥` 之后，报错里
`⊥` 打印成 `Data.Irrelevant.Irrelevant Data.Empty.Empty`——3.0 的
`⊥` 定义为 `Irrelevant Empty`（`Data.Empty`，注释说明这样 Agda 才能判定
地宣布「⊥ 的一切证明相等」），读报错时把这层 `Irrelevant` 忽略即可。

那能不能显式点两层、告诉 Agda「我回到外层了」？探针实测（`TmpProbe39e`）：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe39e.agda:38.1-19: error: [Syntax.MultipleEllipses]
Multiple ellipses in left-hand side ... ... | inj₁ p
```

连 parse 都过不去（`Syntax` 层的错，比 `ConstructorPatternInWrongDatatype`
更早）。也就是说 `with` 的嵌套深度在语法上就是**栈**：只有最内层可寻址。

**标准解法就是把「拿到 ⊎ 之后怎么合并」提成引理**：`◃go<`/`◃go≈`/`◃go>`
各自只嵌一层（`with` 只有 `cmp b x` 一处、`inj₁`/`inj₂` 的匹配在引理体
里），外层分支自然不存在。附带好处：三段合并逻辑各自可读、可单测，
而且它们把「用了哪条界」写在签名上——比塞在同一缩进里更好复查。
24.4 的 `search∈` 那种内联嵌套之所以合法，是因为**它的内层 with 之后
再也不回外层**（`no _` 分支只有内层三案），照抄前先看清这一点。

——±∞ 抬升：`rel lo a` 这类界证据得**永远现成**，intrinsic 版才好用。
书的做法是给 `A` 加两个端点：

```agda
data ℕ↑ : Set where
  -∞ +∞ : ℕ↑
  ↑ : ℕ → ℕ↑

data _<∞_ : ℕ↑ → ℕ↑ → Set where
  -∞<↑  : ∀ {x} → -∞ <∞ ↑ x
  ↑<↑   : ∀ {x y} → x < y → ↑ x <∞ ↑ y
  ↑<+∞  : ∀ {x} → ↑ x <∞ +∞
  -∞<+∞ : -∞ <∞ +∞
```

四个构造子就是「一步界关系」——没有传递闭包，所有需要拼接的情形
交给 `<∞-trans` 现证：

```agda
<∞-trans : ∀ {x y z} → x <∞ y → y <∞ z → x <∞ z
<∞-trans -∞<↑       (↑<↑ y<z) = -∞<↑
<∞-trans -∞<↑       ↑<+∞      = -∞<+∞
<∞-trans (↑<↑ x<y)  (↑<↑ y<z) = ↑<↑ (<-trans x<y y<z)
<∞-trans (↑<↑ x<y)  ↑<+∞      = ↑<+∞
<∞-trans ↑<+∞       ()
<∞-trans -∞<+∞      ()
```

后两行的荒谬模式是**索引层**的：`↑<+∞` 与 `-∞<+∞` 都把中间变量 `y` 钉成
`+∞`，于是第二参数的类型 `+∞ <∞ z` **没有构造子**（`_<∞_` 四个构造子的左
索引只有 `-∞` 和 `↑ …` 两种形状）——这正是 24.2 那条报错建议的
「or use an absurd pattern ()」的正面用法，覆盖检查承认这些分支为空。
`<∞-asym` 四行同理：只有 `↑<↑` 对 `↑<↑` 那一行真干活（剥掉 `↑` 转给
`<-asym`），另外三行都是「另一端是 `+∞`/`-∞`，第二参数无构造子可取」，
`()` 结案。

三分律 `<∞-cmp` 是「8 个平凡分支 + 1 个 lift 分支」（书原话：工作量大
但细节无趣）：

```agda
<∞-cmp : ∀ x y → Tri (x <∞ y) (x ≡ y) (y <∞ x)
<∞-cmp -∞ -∞ = tri≈ (λ ()) refl (λ ())
<∞-cmp -∞ +∞ = tri< -∞<+∞ (λ ()) (λ ())
<∞-cmp -∞ (↑ b) = tri< -∞<↑ (λ ()) (λ { () })
…（其余 5 行见示例）…
<∞-cmp (↑ x) (↑ y) with <-cmp x y
... | tri< x<y ¬x≡y ¬y<x =
  tri< (↑<↑ x<y) (λ { refl → ¬x≡y refl }) (λ { (↑<↑ y<x) → ¬y<x y<x })
... | tri≈ ¬x<x refl ¬y<y =
  tri≈ (λ { (↑<↑ x<x) → ¬x<x x<x }) refl (λ { (↑<↑ y<y) → ¬y<y y<y })
... | tri> ¬x<y ¬x≡y y<x =
  tri> (λ { (↑<↑ x<y) → ¬x<y x<y }) (λ { refl → ¬x≡y refl }) (↑<↑ y<x)
```

`λ { () }` 与 `λ { (↑<↑ y<x) → … }` 的分工值得留意：前者对付「另一侧
是 `+∞`／`-∞`」这种**构造子对不上**的反证，后者对付「同为 `↑` 但序
方向反了」——lift 情形里 `Tri` 的两份 `¬` 必须现拆 `↑<↑` 的索引再交给
`<-cmp` 的反证，`refl` 那格靠 `x ≡ y` 的 `cong`/模式统一。

把界藏回类型外，得到用户友好的 BST：

```agda
open Intr ℕ↑ _<∞_ <∞-trans <∞-asym

BST∞ : Set
BST∞ = BST -∞ +∞

∅∞ : BST∞
∅∞ = ◃empty -∞<+∞

insert∞ : ℕ → BST∞ → BST∞
insert∞ a = ◃insert <∞-cmp (↑ a) -∞<↑ ↑<+∞

t∞ : BST∞
t∞ = insert∞ 6 (insert∞ 4 (insert∞ 2 ∅∞))
```

**种一棵 {2,4,6} 用了三次插入、零证明义务**——对照 24.8 每次调用都要
在外面配一条 `bst-insert`。界证据 `-∞<↑ b`、`↑ b<+∞` 永远现成（这正是
±∞ 抬升的全部动机），所以查询可以直接封装成 `Dec` 版：

```agda
∈∞? : (b : ℕ) (t : BST∞) → Dec ((↑ b) ◃∈ t)
∈∞? b t with ◃search <∞-cmp (↑ b) -∞<↑ ↑<+∞ t
... | inj₁ p = yes p
... | inj₂ ¬p = no ¬p

found4 : (↑ 4) ◃∈ t∞
found4 = toWitness {a? = ∈∞? 4 t∞} tt

¬5∈t∞ : ¬ ((↑ 5) ◃∈ t∞)
¬5∈t∞ = toWitnessFalse {a? = ∈∞? 5 t∞} tt
```

`found4` 的类型 `(↑ 4) ◃∈ t∞`——证据活在**索引**上（`t∞` 本身是
`BST -∞ +∞` 的项，界信息在它的类型里）；第 4 节 Maybe 版只给一个光秃秃的
`just`。正反两个方向都从计算里钓（`toWitness`/`toWitnessFalse`），与
24.6 完全同款。

两版的取舍（书 6.17 论证的完整翻译）：

| | extrinsic（24.6/24.8） | intrinsic（24.9） |
|---|---|---|
| 算法长度 | 朴素，与教科书伪码同步 | 一样长，但签名带界证据 |
| 证明负担 | 每个操作一份镜像证明（`all-insert`/`bst-insert`） | 零镜像证明，构造即正确 |
| 坏输入 | 类型允许存在，运行时才交不出证据 | 不可表达（`BST 2 1` 无项） |
| 不可能分支 | 每条都要写并反驳 | `λ ()` 或整支免写 |
| 不变式变动 | 无影响 | 界一变要传证据／±∞ 收口／cast |
| 中途破坏不变式的算法 | 能写（先改形状，再修复，最后补证） | **写不出来**（堆的 sift-up、红黑旋转都要临时越界） |
| 报错可读性 | 命题层，好读 | 索引 unification，晦涩（见 39t） |
| 复用与搬运 | 引理独立可搬 | 与类型绑定，搬运靠 `subst` |

最后一行前两格是全章最实用的一句忠告：**intrinsic 不是「更高级」**。
34 章的排序、堆、任何「算法中途必须先破坏不变式再修复」的场景，
硬套 intrinsic 会把大量精力花在 cast 上；而「非法状态不可表达」这种
**输入面窄、不变式稳定**的对象（BST、`Vec`、`Fin`、良 scoped AST——
33 章正是这条路）才划算。本书其余章节（如 35 章的 S 自由片段）用的
是第三种路：谓词做数据（`Sfree`），计算另走 `Acc`——两条腿各安其位。

## 24.10 stdlib 3.0 对照

先实测一条：`Data.Tree` 这个名字在 3.0 **压根不是一个模块**（树族住在
`Data/Tree/{Rose,Binary,AVL}` 三个子目录里，正主分别叫
`Data.Tree.Rose`、`Data.Tree.Binary`、`Data.Tree.AVL`）：

```agda
import Data.Tree
```

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe39d.agda:2.1-17: error: [FileNotFound]
Failed to find source of module Data.Tree in any of the following
locations:
  /Volumes/mac004/code/programming/agda/examples/Data/Tree.AGDA
  /Volumes/mac004/lang/agda-stdlib/src/Data/Tree.AGDA
  /Volumes/mac004/.stack-home/agda-build/.stack-work/install/x86_64-osx/faff8921e62ea95999f0f67e79eaab55f9b7dfb901de7a43aed2846e77ed6496/9.14.1/share/x86_64-osx-ghc-9.14.1-inplace/Agda-2.9.0/lib/prim/Data/Tree.AGDA
where .AGDA denotes a legal extension for an Agda file
(i.e., one of .agda .lagda .lagda.rst .lagda.tex .lagda.md
 .lagda.org .lagda.tree .lagda.typ)
when scope checking the declaration
  import Data.Tree
```

三条搜索位置恰好把 44 章的装机结构画出来了：项目 `examples` 目录、
`AgdaTutorial.agda-lib` 引入的 stdlib git 源、Agda 自带的 primitive 库。
找不到的模块名先怀疑版本搬家，别怀疑拼写（44 章迁移清单同款思路）。

二叉树正品与本章手搓版的对应：

```agda
import Data.Tree.Binary as Std

-- std 版 leaf 携带叶值：教材 empty ≡ 值为 ⊤ 的 leaf
toStd : BinTree A → Std.Tree A ⊤
toStd empty = Std.leaf tt
toStd (branch l a r) = Std.node (toStd l) a (toStd r)

-- ② stdlib 的树版 All 是「双谓词」（结点的 P + 叶的 Q）：
import Data.Tree.Binary.Relation.Unary.All as StdAll

toStdAll : ∀ {t} → All P t → StdAll.All P (λ _ → ⊤) (toStd t)
toStdAll all-empty = StdAll.leaf tt
toStdAll (all-branch al pa ar) = StdAll.node (toStdAll al) pa (toStdAll ar)
```

`toStd` 那行的类型 `Std.Tree A ⊤` 就是差异所在：正品的两个类型参数分别
服务**结点值**与**叶值**，教材版没有叶值，于是叶类型取 `⊤`、`empty` 映到
`leaf tt`。`toStdAll` 是同构搬运：手搓 `all-empty`（一行）对应正品
`leaf tt`（叶谓词 `λ _ → ⊤` 当场满足），`all-branch` 对应 `node`，
递归结构一字不改。

`Relation.Nullary` 那批名字在 3.0 的确切住址也顺手钉一下（44 章迁移清单
的同族情报）：`Dec`/`Reflects`/`⌊_⌋`/`toWitness` 在
`Relation.Nullary.Decidable.Core`，`¬_` 在 `Relation.Nullary.Negation.Core`
（`¬ A = A → ⊥`），`Relation.Nullary` 顶层做 re-export——本章的
`open import Relation.Nullary using (Dec; yes; no; ¬_; ⌊_⌋; toWitness;
toWitnessFalse)` 走的是 re-export，写论文引用模块时按上面的住址写更准。

| 本章手搓 | stdlib 3.0 正品 | 说明 |
|---|---|---|
| `data BinTree`（`empty` + `branch`） | `Data.Tree.Binary.Tree A B` | 正品 `leaf` **带叶值**，故 `empty ≡ leaf tt`（`toStd`） |
| `data All P t` | `Data.Tree.Binary.Relation.Unary.All P Q t` | 正品是**双谓词**（结点 `P` + 叶 `Q`），本章叶全空 → `Q = λ _ → ⊤` |
| `Dec`/`Reflects`/`⌊_⌋`/`toWitness` | `Relation.Nullary.Decidable.Core` | 17 章钉过；`_because_` 与 `yes`/`no` pattern 也在此 |
| `T`、`T?` | `Data.Bool.Base`、`Data.Bool.Properties` | 本章第 1 节 15 行 |
| `Tri`、`Trichotomous` | `Relation.Binary.Definitions` | 构造子名与 Maguire 书**完全同名**，直 import |
| `<-cmp` | `Data.Nat.Properties` | 手打 `<-cmp′` 用 `check-cmp` 验过同型 |
| `_≡?_`、`_<?_` | `Data.Nat.Properties` | 3.0 正名；`_≟_` 已弃用（33 章的 AST 示例里仍有 deprecation 警告） |
| `Data.Tree.AVL` 的查找 | `Data.Tree.AVL.*`（Comparator + `Maybe`） | 「计算先跑、Properties 里再证」= extrinsic 混搭口味 |
| `BST lo hi`（界做索引） | `Data.Tree.AVL.Height`、`Data.Vec` 长度索引 | 纯 intrinsic 在 stdlib **只用在形状上** |

最后一行值得停一下：stdlib 里成功的 intrinsic 索引全是**数值形状**
（`Vec` 的长度、`Fin` 的上界、`AVL.Height` 的高度），而「有序」这类
**代数不变式**一律走 extrinsic 谓词 + `Properties` 定理。本章第 9 节
是教程里唯一一次把代数不变式做进索引，代价（±∞ 抬升、`trans`/`asym`
参数、报错可读性）在第 11 节坑位清单里有账。

## 24.11 坑位清单（实测）

1. **嵌套 with 回不到外层**：外层 `with cmp b x` 的分支里再开 `with`，
   之后想写 `... | tri≈ …` 会被当成对最内层结果做匹配，报
   `tri≈ is not a constructor of the datatype _⊎_`（`ConstructorPatternInWrongDatatype`，
   24.9）。解法：合并逻辑提成引理（`◃go<`/`◃go≈`/`◃go>`）。
2. **`... ... |` 想显式点两层更不通**：`Syntax.MultipleEllipses`，
   `Multiple ellipses in left-hand side ... ... | inj₁ p`（24.9）——
   比类型错误更早，连 parse 都不过。`with` 嵌套是栈，只有最内层可寻址。
3. **内联嵌套只在「不回外层」时合法**：24.4 `search∈` 的
   `... | no _ with …` + `...   |` 缩进写法能过，是因为内层之后外层再无
   分支。抄代码前先数一下外层还剩几支。
4. **缺定律的 intrinsic 报错长得像索引冲突**：`◃lo<hi` 的 `◃node` 分支
   在没有 `trans` 时报 `The terms x and hi are not equal at type A`
   （24.9）——「两个本该无关的索引被要求相等」= 你在裸关系上做有序性
   推理，去补 `trans`/`asym`。
5. **`λ ()` 只吃「构造子层面为空」的类型**：`a ∈ empty`、`b ◃∈ ◃empty p`
   可以（无构造子）；`7 ∈ tree` 不行，报 `ShouldBeEmpty` 并列出 `left`/
   `right` 两枚「形状上合法」的构造子（24.5）。反证要么留洞 `_` 让反解
   填，要么 `toWitnessFalse` 从计算里钓。
6. **`toWitness` 的隐式 `Dec` 必须点名**：`toWitness tt` 省掉
   `{a? = is-bst? tree}` 直接 `UnsolvedMetaVariables`（24.6）——同一命题
   有无数判定器，Agda 不会猜。
7. **`data _∈_ : A → BinTree A → Set` 会撞 sort**：`A` 被泛化后构造子落进
   `Set₁`，报 `ConstructorDoesNotFitInData`（附 `--large-indices` 说明）；
   写成 `data _∈_ {A : Set} : …` 即解（24.3）。
8. **声明式泛化的 `variable` 块位置敏感**：放在引用它的 `data` 之后 →
   `Not in scope: BinTree`（24.3，与 25 章同一机制）。
9. **多目标 with 不必凑满 2ⁿ 条分支**：`∈?`、`all?`、`is-bst?` 都是
   4 条／5 条靠 `_` 通配覆盖全组合；反过来，`no` 分支里那枚反证 λ
   **必须逐个构造子喂**，少一格即 `CoverageIssue`（24.5）。
10. **`import Data.Tree` 在 3.0 不存在**：`FileNotFound`，报错会列出三条
    搜索路径（24.10）——先怀疑版本搬家。
11. **`_≟_` 已弃用**：`Data.Nat` 用 `_≡?_`、序用 `_<?_`（38/44 章）；本章
    函数参数**起名** `_≟_` 只是为了体内记号好读，与库里的旧名无关。
12. **手打版与正品「同型不同项」**：`check-cmp = <-cmp′` 过，
    `<-cmp′ x y ≡ <-cmp x y` 不过（24.7 实测）——报错会顺便把正品的
    `map′`/`≡ᵇ` 实现摊给你看，这类报错是读库的好素材。
---
上一章：[23 · 类型的代数：ADT 作为半环](23-type-algebra.md) ｜ 下一章：[25 · instance 参数与模算术](25-instance-modular.md) ｜ 返回：[README](../README.md)
