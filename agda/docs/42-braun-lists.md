# 42 · Braun 树与列表运算推理

13 章学会了「归纳 = 递归」，但那是在自家玩具（`ℕ`、自造表）上练拳。
这一章把同一套手艺搬到**真列表运算**上：反转的 `length` 保持定理、
`filter` 幂等、按谓词删除元素——Stump 书第 4 章的全部内容；然后火力
升级，进入书第 5 章的**内部验证**（internal verification）：把数据结构的
平衡不变式直接焊进类型，造一棵形状撒谎不了的 **Braun 树**，再借
Σ 类型给「值 + 性质」打包发货。对应已有章节：反转的另一条路见
[13 章](13-induction.md)（`rev-++` 反同态），「不变式进类型」的孪生兄弟
见 [16 章](16-vectors.md)（Vec），Σ/Π 的直觉铺垫见
[41 章 · 类型的代数](41-type-algebra.md)。

对应示例：`../examples/Ex42_braun_lists.agda`

本章所有报错文本均为 Agda 2.9.0 + stdlib 3.0 实测原样粘贴（复现用的
临时探针 `examples/TmpProbe42*.agda` 已删除，报错路径按仓库根相对
显示）；代码片段与示例文件一致。书针对 Agda 2.2.x + Iowa Agda Library
（IAL 自定义 prelude）的写法全部重写并逐一验证——这正是本章的隐藏
主题：**一份 2009 年前后风格的证明脚本，在今天的 stdlib 上复活要付
多少过路费**。

## 42.1 本章地图

书第 4 章（列表运算）与第 5 章（内部验证）在本章的落点：

| 书 | 本章小节 | 一句话看点 |
|---|---|---|
| 4.2.8 reverse-helper | 42.3–42.5 | 累加器版本，线性时间 |
| 4.3.5 length(reverse) | 42.4 | **把累加器泛化进归纳命题** |
| 4.3.1 length-++ | 42.2 | length 是 (List,++) → (ℕ,+) 同态 |
| 4.3.2/4.3.3 filter | 42.6–42.7 | with 分情形的正统用法 |
| 4.3.4 keep idiom | 42.8–42.9 | with 的替换是**一次性**的 |
| 4.2.5 remove | 42.10 | λ 抽象现场造谓词 |
| 5.2 Braun 树 | 42.11–42.15 | 平衡不变式 = 构造子参数 |
| 5.3 Σ 类型 | 42.16–42.17 | 值与性质打包 |
| 5.3.1 Why Σ and Π | 42.17 | 记号背后的集合论 |

先立一个本章反复使用的**选归纳变元**口诀（书 4.3.1 的 rule of thumb）：
*对哪个参数归纳？——选函数定义里**被模式匹配剖开**的那个*。`_++_`
对第一参数递归，所以 `length-++` 对 `xs` 归纳；`revAcc h xs` 只对 `xs`
剖模式，所以归纳的是 `xs`，`h` 保持为变量——这个「保持为变量」正是
42.4 全部故事的起点。

## 42.2 length 把 ++ 变成 +

`length` 是列表代数结构的第一个同态：把 `++` 折成 `+`（13 章
`+-assoc` 一类的搬运工，这里第一次遇到「同态」句式）：

```agda
++-length′ : ∀ {A : Set} (xs ys : List A) →
             length (xs ++ ys) ≡ length xs + length ys
++-length′ []       ys = refl
++-length′ (x ∷ xs) ys rewrite ++-length′ xs ys = refl
```

基例 `length ([] ++ ys) ≡ 0 + length ys` 两边都算到 `length ys`，`refl`
白捡——书在这一点上专门唠叨：Agda 里「能算出来的」不配叫引理。

stdlib 有正品，但**参数结构和你想要的不同**（`Data/List/Properties.agda:129`）：

```agda
length-++ : ∀ (xs : List A) {ys} → length (xs ++ ys) ≡ length xs + length ys
```

`xs` 显式、`ys` **隐式**。照 2.x 时代 `++-length xs ys` 的双显式口径去
对接（2.x 旧名 `++-length`，3.0 改名并换参序，[35 章](35-macos-checklist.md)
清单在册），把整条引理赋给双显式类型的名字，实测撞车：

```text
examples/TmpProbe42l.agda:10.19-28: error: [UnequalTypes]
The function type
  {ys : List A} → length (xs ++ ys) ≡ length xs + length ys
is not a subtype of
  (ys : List A) → length (xs ++ ys) ≡ length xs + length ys
because:
  one takes a hidden argument, while the other takes a visible
  argument.
when checking that the expression length-++ has type
(xs ys : List A) → length (xs ++ ys) ≡ length xs + length ys
```

示例第 8 节的对账声明因此写成 `(xs : List A) {ys : List A}`，一行
`check-length-++ = length-++` 原样收货。教训：**对接 stdlib 引理先
`:Check` 类型，别背 2.x 的参序**。

## 42.3 反转·路 A：慢速 rev（13 章老路，再看一眼）

13 章造过两条反转路：`rev (x ∷ xs) = rev xs ++ [x]`（O(n²)，性质好证）
和反同态 `rev-++`。这里把「length 保持」用**直接四连 rewrite**再做一遍，
当作两条路的第一个岔口：

```agda
rev : ∀ {A : Set} → List A → List A
rev []       = []
rev (x ∷ xs) = rev xs ++ [ x ]

length-rev : ∀ {A : Set} (xs : List A) → length (rev xs) ≡ length xs
length-rev [] = refl
length-rev (x ∷ xs)
  rewrite ++-length′ (rev xs) [ x ] | length-rev xs
          | +-suc (length xs) zero | +-identityʳ (length xs) = refl
```

四刀各自砍掉一个残留模式：先把 `length (rev xs ++ [x])` 拆成
`length (rev xs) + suc zero`，IH 换掉 `length (rev xs)`，`+-suc` 把
`suc` 从右侧第二参数里**搬出来**，`+-identityʳ` 收尾。整条证明没有任何
新武器——13 章「把引理实例到复合项」的剧本从头演到尾。注意
`++-length′ (rev xs) [ x ]`：引理被实例到**中间结果** `rev xs ++ [x]`
上，这是「归纳假设太弱就外拓引理」的第一次预告。

## 42.4 反转·路 B：累加器，以及一次真实的「IH 不够强」

书 4.2.8 的效率反转——累加器放**第一参数**，对第二参数递归：

```agda
revAcc : ∀ {A : Set} (h : List A) → List A → List A
revAcc h []       = h
revAcc h (x ∷ xs) = revAcc (x ∷ h) xs

reverse′ : ∀ {A : Set} → List A → List A
reverse′ xs = revAcc [] xs
```

现在证 `length (reverse′ xs) ≡ length xs`。按口诀，`revAcc` 剖的是第二
参数，那就对 `xs` 归纳，直球上：

```agda
length-reverse′ : ∀ {A : Set} (xs : List A) →
                  length (reverse′ xs) ≡ length xs
length-reverse′ [] = refl
length-reverse′ (x ∷ xs) rewrite length-reverse′ xs = refl   -- ❌
```

实测（步例硬写 `refl`）先收到一条**羞辱性警告**，再撞墙：

```text
examples/TmpProbe42b.agda:16.34-52: warning: -W[no]RewritesNothing
`rewrite' did not apply
when checking that the clause
length-reverse′ (x ∷ xs) rewrite length-reverse′ xs = refl has type
{A : Set} (xs : List A) → length (reverse′ xs) ≡ length xs

examples/TmpProbe42b.agda:16.55-59: error: [UnequalTerms]
The terms
  Data.List.foldr (λ _ → suc) 0 (revAcc (x ∷ []) xs)
and
  suc (Data.List.foldr (λ _ → suc) 0 xs)
are not equal at type ℕ
when checking that the expression refl has type
Data.List.foldr (λ _ → suc) 0 (revAcc (x ∷ []) xs) ≡
suc (Data.List.foldr (λ _ → suc) 0 xs)
```

（`Data.List.foldr (λ _ → suc) 0` 就是 `length` 的 unfold 后真身。）
警告「rewrite did not apply」的意思是：IH 的左端 `length (reverse′ xs)`
即 `length (revAcc [] xs)` 在目标里**根本找不到**——步例目标是
`length (revAcc (x ∷ []) xs)`，累加器已经从 `[]` 变成 `x ∷ []`，IH
钉死在 `h = []` 这一个特例上，够不着。这正是 13 章坑位 3
「IH 太弱 = 缺 generalize」的现场复现，而 Agda 的解法也一模一样：
**generalize = 加函数参数**。把累加器请回命题里：

```agda
length-revAcc : ∀ {A : Set} (h xs : List A) →
                length (revAcc h xs) ≡ length h + length xs
length-revAcc h []       rewrite +-identityʳ (length h) = refl
length-revAcc h (x ∷ xs)
  rewrite length-revAcc (x ∷ h) xs | +-suc (length h) (length xs) = refl

length-reverse′ : ∀ {A : Set} (xs : List A) →
                  length (reverse′ xs) ≡ length xs
length-reverse′ xs = length-revAcc [] xs   -- 实例化 h := []，不再归纳
```

书 4.3.5 对「归纳谁」的裁决值得背下来：*两个参数里挑 reverse-helper
**用模式匹配剖开**的那一个——l；所以归纳 l，把 h 留在命题里当变量。* 泛化后的归纳假设这次真的
能实例到 `revAcc (x ∷ h) xs` 上（`h` 换成了 `x ∷ h`），两刀 `+-suc`、
`+-identityʳ` 与路 A 同款。**一个定理，两条证明路**：路 A 靠引理外拓
（`++-length′` 实例到复合项），路 B 靠命题泛化（`h` 进参数表）——
本质是同一件事的两面：*让 IH 的实例化能力覆盖递归调用的一切现场*。
顺带，`length-revAcc` 基例里那记 `rewrite +-identityʳ (length h)`
对应书的 `+0 (length h)`（IAL 引理名 → stdlib 名，见 42.18 对照）。

## 42.5 两条路的桥，以及 stdlib 的 `ʳ++` 方向坑

同一文件里两条路可以打通——累加器版就是「慢速版 ++ 累加器」：

```agda
revAcc-rev : ∀ {A : Set} (h xs : List A) → revAcc h xs ≡ rev xs ++ h
revAcc-rev h []       = refl
revAcc-rev h (x ∷ xs)
  rewrite revAcc-rev (x ∷ h) xs | ++-assoc (rev xs) [ x ] h = refl

reverse′≡rev : ∀ {A : Set} (xs : List A) → reverse′ xs ≡ rev xs
reverse′≡rev xs rewrite revAcc-rev [] xs | ++-identityʳ (rev xs) = refl
```

步例先 IH（累加器又长大了：`x ∷ h`），再用 stdlib 正品 `++-assoc`
重新结合——`_++_` 对第一参数递归的定义决定了 `(rev xs ++ [x]) ++ h`
和 `rev xs ++ (x ∷ h)` 只差结合律，这种「结构账」Agda 算不出来，
必须递引理（13 章 `+-assoc` 坑位 2 的列表版）。

stdlib 自己怎么反转？`Data/List/Base.agda:234-238`：

```agda
reverseAcc : List A → List A → List A
reverseAcc = foldl (flip _∷_)
reverse : List A → List A
reverse = reverseAcc []
```

正是书的累加器路线（累加器内藏成 `foldl` 的第一参数）。自造版与
正品逐点上标：

```agda
revAcc≡reverseAcc : ∀ {A : Set} (h xs : List A) →
                    revAcc h xs ≡ reverseAcc h xs
revAcc≡reverseAcc h []       = refl
revAcc≡reverseAcc h (x ∷ xs) rewrite revAcc≡reverseAcc (x ∷ h) xs = refl

reverse′≡reverse : ∀ {A : Set} (xs : List A) → reverse′ xs ≡ reverse xs
reverse′≡reverse xs = revAcc≡reverseAcc [] xs
```

另有一个近亲 `_ʳ++_`（Base:244-245，`_ʳ++_ = flip reverseAcc`）——
名字里的 `ʳ` 标的是「**反转左操作数**」，跟书 4.2.8 把累加器写在
**左**参数的 `reverse-helper h l` 恰好**相反**：

```agda
ʳ++-demo : (1 ∷ 2 ∷ []) ʳ++ (3 ∷ 4 ∷ []) ≡ 2 ∷ 1 ∷ 3 ∷ 4 ∷ []
ʳ++-demo = refl
```

实测 refl 通过：`xs ʳ++ ys = reverse xs ++ ys`。把 `reverseAcc h xs ≡
rev xs ++ h` 记牢就不会迷路——**谁在累加器位，谁不被反转**。尾部插入
`snoc` 是累加器思想的第二次收割（两次反转，仍线性）：

```agda
snoc : ∀ {A : Set} → List A → A → List A
snoc xs x = reverse (x ∷ reverse xs)

snoc-demo : snoc (1 ∷ 2 ∷ 3 ∷ []) 4 ≡ 1 ∷ 2 ∷ 3 ∷ 4 ∷ []
snoc-demo = refl
```

## 42.6 filter：书的 Bool 版，stdlib 的 Dec 版

书 4.2.4 的 `filter` 吃**布尔谓词**：

```agda
filter : ∀ {A : Set} → (A → Bool) → List A → List A
filter p []       = []
filter p (x ∷ xs) = if p x then x ∷ filter p xs else filter p xs
```

stdlib 3.0 的同名函数已经不是这个类型（`Data/List/Base.agda:359`）：

```agda
filter : ∀ {P : Pred A p} → Decidable P → List A → List A
```

吃的是**可判定谓词值**（`yes`/`no` 携带证明的 `Dec`），书的 Bool 版在
stdlib 改名叫 `filterᵇ`（Base:365-366，`filterᵇ p = filter (T? ∘ p)`）。
所以示例照书自造 `filter`，不与 stdlib 版本抢名字；读旧教程/旧代码时
把 `filter` 想成 `filterᵇ` 即可。小谓词与计算演示照例 `refl` 白捡：

```agda
isEven : ℕ → Bool
isEven zero           = true
isEven (suc zero)     = false
isEven (suc (suc n))  = isEven n

_ : filter isEven (1 ∷ 2 ∷ 3 ∷ 4 ∷ 5 ∷ 6 ∷ []) ≡ 2 ∷ 4 ∷ 6 ∷ []
_ = refl
```

## 42.7 length-filter：with 的正统用法

书的陈述是布尔版（`length (filter p l) ≤ length l ≡ tt`，IAL 的 `_≤_`
返回 Bool）；教程口径换成命题版 `_≤_`（13 章后的标准姿势），证明骨架
不变。先试「不 with」的直球：

```agda
length-filter-naive p (x ∷ xs) = s≤s (length-filter-naive p xs)   -- ❌
```

实测：

```text
examples/TmpProbe42d.agda:16.34-63: error: [UnequalTerms]
The terms
  suc _m_23
and
  Data.List.foldr (Function.Base.const suc) 0
  (if p x then x ∷ filter p xs else filter p xs)
are not equal at type ℕ
when checking that the inferred type of an application
  suc _m_23 ≤ suc _n_24
matches the expected type
  length (filter p (x ∷ xs)) ≤ length (x ∷ xs)
```

`s≤s` 要求**恰好一层** `suc`，而 `length (if p x then …)` 卡在
`p x` 上算不动——`p x` 是变量表达式，`if` 是 stuck 的正规式。解药就是
`with`：**把卡住的表达式拿来剖模式**，让它当场化成 `true` 或 `false`：

```agda
length-filter : ∀ {A : Set} (p : A → Bool) (xs : List A) →
                length (filter p xs) ≤ length xs
length-filter p []       = z≤n
length-filter p (x ∷ xs) with p x
... | true  = s≤s (length-filter p xs)
... | false = ≤-trans (length-filter p xs) (m≤n⇒m≤1+n ≤-refl)
```

true 分支：`length (x ∷ filter p xs) = suc (length (filter p xs))`，
配 `s≤s (IH)` 严丝合缝。false 分支只丢一个元素，用 stdlib 算术引理
`≤-trans` 拼 `IH ≤ length xs ≤ suc (length xs)`（`m≤n⇒m≤1+n` 是 35 章
清单里的老熟人：2.x 同名引理在 3.0 仍在 `Data/Nat/Properties.agda:305`）。
对照书 4.3.3 的布尔版证明：结构逐行同款，只是「≤ 的传递」从 IAL 手写
换成 stdlib 进货。

## 42.8 keep idiom：with 的替换是一次性的

书 4.3.4 的重头戏。先试「显然」的裸 with 证 `filter p (filter p xs) ≡
filter p xs`：

```agda
filter-idem-naive p (x ∷ xs) with p x
... | true  = refl     -- ❌
... | false = refl     -- ❌
```

true 分支实测：

```text
examples/TmpProbe42c.agda:15.15-19: error: [UnequalTerms]
The terms
  if p x then x ∷ filter p (filter p xs) else filter p (filter p xs)
and
  x ∷ filter p xs
are not equal at type List A
when checking that the expression refl has type
filter p (if true then x ∷ filter p xs else filter p xs) ≡
(if true then x ∷ filter p xs else filter p xs)
```

看书 4.3.4 逐帧解释这件事怎么发生：初始目标里 `p x` 出现**两次**
（外、内各一枚 `filter p (x ∷ xs)`）；`with p x` 把目标里当时的所有
`p x` 实例化掉——但**只此一次**。实例化后左侧 `filter p (if true …)`
又按 `filter` 的定义展开出**新的** `if p x then …`，新的 `p x` 不在
with 的管辖范围内。报错第一行正是这个长回来的目标：`if p x` 明目张胆
地站在 true 分支里。这不是 bug，是 with 的机制：*with 能做的只是
把表达式实例化一次；其后正规化再长出原表达式，Agda 不管*。

书的解法：**keep idiom**——with 的对象不是 `p x`，而是把 `p x` 连同
「它等于自己」的证据一起打包：

```agda
keep : ∀ {A : Set} (x : A) → Σ A (λ y → x ≡ y)
keep x = x , refl
```

```agda
filter-idem : ∀ {A : Set} (p : A → Bool) (xs : List A) →
              filter p (filter p xs) ≡ filter p xs
filter-idem p []       = refl
filter-idem p (x ∷ xs) with keep (p x)
... | true  , p′ rewrite p′ | p′ | filter-idem p xs = refl
... | false , p′ rewrite p′ = filter-idem p xs
```

`p′ : p x ≡ true`（第二分支 `p x ≡ false`）是 keep 随货附赠的证据，
`rewrite p′` 手动补上 with 不肯做的第二、第三次实例化。true 分支为什么
是**两刀** `p′`？第一刀把**旧的** `p x`（with 没管到的那枚）换掉、让
外层 `filter` 能展开；展开又长出**新的** `p x`，第二刀再换。删掉一刀
试试（`rewrite p′ | filter-idem p xs = refl`）：

```text
examples/TmpProbe42n.agda:19.43-47: error: [UnequalTerms]
The terms
  if p x then x ∷ filter p xs else filter p xs
and
  x ∷ filter p xs
are not equal at type List A
when checking that the expression refl has type
(if p x then x ∷ filter p xs else filter p xs) ≡ x ∷ filter p xs
```

目标停在 `if p x`——缺的那刀补的就是刚长出来的这枚 `p x`。false 分支
只需一刀，因为丢掉头元素后 `filter p (filter p xs) ≡ filter p xs`
恰好是 IH 本身，直接 `= filter-idem p xs` 收队。

## 42.9 stdlib 的 inspect：同一个主意的官方包装

书 4.3.4 尾注：keep 在 stdlib 里叫 **inspect**。官方实现是一条
record（`Relation/Binary/PropositionalEquality.agda:106-114`）：

```agda
record Reveal_·_is_ {A : Set a} {B : A → Set b}
                    (f : (x : A) → B x) (x : A) (y : B x) :
                    Set (a ⊔ b) where
  constructor [_]
  field eq : f x ≡ y

inspect : ∀ {A : Set a} {B : A → Set b}
          (f : (x : A) → B x) (x : A) → Reveal f · x is f x
inspect f x = [ refl ]
```

对照 `keep x = x , refl : Σ A (λ y → x ≡ y)`——**完全同一个主意**：
依赖对/record 把「值」和「值等于原表达式」缝在一起。stdlib 版证明：

```agda
filter-idem-inspect : ∀ {A : Set} (p : A → Bool) (xs : List A) →
                      filter p (filter p xs) ≡ filter p xs
filter-idem-inspect p []       = refl
filter-idem-inspect p (x ∷ xs) with p x | inspect p x
... | true  | Relation.Binary.PropositionalEquality.[ eq ]
  rewrite filter-idem-inspect p xs | eq = refl
... | false | Relation.Binary.PropositionalEquality.[ eq ]
  = filter-idem-inspect p xs
```

三处细节，处处有坑：

1. **`[_]` 的名字打架**。`[_]` 既是单元素表（`Data/List/Base.agda:159`）
   又是 Reveal 的构造子。两边都 `using ([_])` 再写 `[ x ]`，实测：

   ```text
   examples/TmpProbe42h3.agda:8.15-20: error: [AmbiguousName]
   Ambiguous name [_]. It could refer to any one of
     Data.List.[_] bound at
       /Volumes/mac004/lang/agda-stdlib/src/Data/List/Base.agda:159.1-4
     Reveal_·_is_.constructor bound at
       /Volumes/mac004/lang/agda-stdlib/src/Relation/Binary/PropositionalEquality.agda:109.15-18
   [_] is in scope as
     * a defined name Data.List.Base.[_] brought into scope by
       - the opening of Data.List at TmpProbe42h3.agda:3.13-22
       - the opening of Data.List.Base at /Volumes/mac004/lang/agda-stdlib/src/Data/List.agda:17.13-27
       - its definition at /Volumes/mac004/lang/agda-stdlib/src/Data/List/Base.agda:159.1-4
     * a constructor Relation.Binary.PropositionalEquality.[_]
       brought into scope by
       - the opening of Relation.Binary.PropositionalEquality at TmpProbe42h3.agda:4.13-50
       - its definition at /Volumes/mac004/lang/agda-stdlib/src/Relation/Binary/PropositionalEquality.agda:109.15-18
   when scope checking [ x ]
   ```

   解法（示例采用）：with 模式里写**完全限定名**
   `Relation.Binary.PropositionalEquality.[ eq ]`（实测可解析、可通过），
   表侧 `[_]` 照常从 Data.List 进货。

2. **rewrite 链顺序与 keep 版相反**。keep 版先补 eq 再 IH；inspect 版
   在 `with p x | inspect p x` 双 with 之下，true 分支的**初始**目标里
   `p x` 已被抽象干净，IH 先把 `filter p (filter p xs)` 摁成
   `filter p xs`，展开才让 `p x` **第二次长回来**，eq 补刀。反序会挂
   （实测与终稿同构，只少那记 `eq`）：

   ```text
   examples/TmpProbe42m.agda:17.23-27: error: [UnequalTerms]
   The terms
     if p x then x ∷ filter p xs else filter p xs
     and
     x ∷ filter p xs
   are not equal at type List A
   when checking that the expression refl has type
   (if p x then x ∷ filter p xs else filter p xs) ≡ x ∷ filter p xs
   ```

3. false 分支**连 eq 都不必动**：目标被 with 抽象成 `if w …`，两枚
   `w` 同形，IH 一步到位。keep/inspect 两版并存的意义不在省几行字，
   而在让你看清：**证据什么时候派上用场，取决于目标里 `p x` 还剩几枚**。

## 42.10 remove：filter + λ 抽象（书 4.2.5）

删掉所有等于 `a` 的元素——把「与 a 不等」现场写成匿名函数喂给 filter：

```agda
remove : ∀ {A : Set} → (eq : A → A → Bool) → (a : A) → List A → List A
remove eq a xs = filter (λ x → not (eq a x)) xs
```

等值判定 `eqℕ : ℕ → ℕ → Bool` 手写（3.0 的 `_≟_` 已是 `_≡?_` 的废弃
别名，35 章清单在册，这里不引 deprecated）。两行 `refl` 验货：

```agda
_ : remove eqℕ 2 (1 ∷ 2 ∷ 3 ∷ 2 ∷ 2 ∷ 4 ∷ []) ≡ 1 ∷ 3 ∷ 4 ∷ []
_ = refl

_ : remove eqℕ 2 (remove eqℕ 2 (1 ∷ 2 ∷ 3 ∷ [])) ≡
    remove eqℕ 2 (1 ∷ 2 ∷ 3 ∷ [])
_ = refl
```

第二行其实是 `filter-idem` 在 `λ x → not (eqℕ 2 x)` 上的**实例**——
幂等定理的即插即用。λ 抽象的角色：谓词不必提升为顶层定义，
「谁进 who out」的控制流与数据一并书写；书 4.2.5 的 `_L,_` 记号
（IAL 的列表推导雏形）在 stdlib 语境下就是普通的 `λ`。

## 42.11 Braun 树：把形状焊进类型

书第 5 章开场白一句话：**内部验证**——不变式不是「用完再查」
（外部验证，返回 `maybe`/标志位），而是**构造子不收违章件**：违反
不变式的树*根本不可构造*。16 章的 Vec（长度进类型）是同一族手艺，
Braun 树把筹码推到「平衡形状」上。

Braun 树（书 5.2）：每个结点的**左子大小 = 右子大小，或左 = 右 + 1**。
由此树高 `O(log n)`，但比 AVL/红黑树便宜得多——平衡信息只用一个
**索引**就表达完了：

```agda
data braun : ℕ → Set where
  empty : braun zero
  node  : ∀ {n m} → (x : A) → (l : braun n) → (r : braun m) →
          (n ≡ m ⊎ n ≡ suc m) → braun (suc (n + m))
```

逐格读：`braun n` 读作「恰好装 n 个结点的 Braun 树」（索引 = 账本，
Vec 既视感）；`node` 的**第四个显式参数**是一枚**证明**——
`n ≡ m ⊎ n ≡ suc m`，左右大小要么平、要么左大一。`⊎` 是
`Data.Sum` 的标签不相并（书 IAL 名 `_Z_`，`inj1/inj2` → `inj₁/inj₂`）。
返回索引 `suc (n + m)`：根 + 两子，尺寸自动求和——**账目也住在类型里**。

违章件收不进去是字面意义的：想造一棵「左空右一」的树？

```agda
bad : braun 2
bad = node 1 empty (node 2 empty empty (inj₁ refl)) (inj₁ refl)
```

实测：

```text
examples/TmpProbe42e.agda:14.59-63: error: [UnequalTerms]
The terms
  0
and
  1
are not equal at type ℕ
when checking that the expression refl has type zero ≡ 1
```

证明位要求 `0 ≡ 1 ⊎ 0 ≡ suc 1`，两个 disjunct 的 `refl` 都造不出来——
Agda 直接指着鼻子：`refl has type zero ≡ 1`？想都别想。整个 Braun
开发包进**参数模块**（书 5.2 的
`module braun-tree {𝓁} (A : Set 𝓁) (_<A_ : A → A → B) where`，
stdlib 3.0 对应写法）：

```agda
module Braun (A : Set) (_≺_ : A → A → Bool) where
```

比较函数改名 `_≺_`：3.0 里 `Data.Nat` 的 `_≤_`/`_<_` 是命题关系，
照书用 `_<_` 当参数名会跟 `Data.Nat` 的 `<` 抢可读性——布尔序关系
请挑一个不撞名的记号（这是风格选择，不是编译错误）。实例化时一行
`open Braun ℕ _≤ᵇ_` 把整套开发接到自然数上（`_≤ᵇ_ : ℕ → ℕ → Bool`
住 `Data/Nat/Base.agda:47`——注意带 `ᵇ` 的才是布尔版）。

## 42.12 insert：先交换，再递归

书图 5.4 搬运（IAL 名已全部换掉，其余**一行没动**）：

```agda
insert : ∀ {n} → (a : A) → (t : braun n) → braun (suc n)
insert a empty = node a empty empty (inj₁ refl)
insert a (node {n} {m} a′ l r p)
  rewrite +-comm n m
  with p | if a ≺ a′ then ( a , a′) else (a′ , a)
...    | inj₁ eq | (a₁ , a₂)
  rewrite eq = node a₁ (insert a₂ r) l (inj₂ refl)
...    | inj₂ eq | (a₁ , a₂) = node a₁ (insert a₂ r) l (inj₁ (sym eq))
```

算法一句话：**较小者坐镇新根；把较大者递归插进旧右子；然后左右子
交换**。交换后，旧右子胖了一号：若原来左右持平（`inj₁`：`n ≡ m`），
交换后左 = `suc m`、右 = `n`，得「左 = 右 + 1」；若原来左大一（`inj₂`：
`n ≡ suc m`），交换后左 `suc m ≡ n` 恰好持平。不变式自动保持——
书图 5.3 那张「r 上移、l 下坠」的箭头图就是这段话。

代码三处心思：

1. **子句头 rewrite 只做一次**。返回类型 `braun (suc (suc (n + m)))`
   里加法方向与构造项的 `suc (suc m + n)` 拧着——既然两个分支都要
   交换子树，`rewrite +-comm n m`（书 `+comm`，stdlib
   `Data/Nat/Properties.agda:569`）索性提到**子句头、with 之前**做掉，
   两个分支共享改写后的目标；inj₂ 分支因此连 rewrite 都不再需要。
   这个「rewrite 打头、with 随后」的 2009 句式实测在 2.9 原样通过。
   漏掉这记 rewrite 的代价（把子句头的 `rewrite +-comm n m` 删掉）：

   ```text
   examples/TmpProbe42f.agda:19.5-39: error: [UnequalTerms]
   The terms
     m
   and
     n
   are not equal at type ℕ
   when checking that the inferred type of an application
     braun (suc (suc m + _m_33))
   matches the expected type
     braun (suc (suc (n + m)))
   ```

2. **剖 p 不开在 LHS 而开在 with**。书原话：normally one would just
   split on p directly——但放进 with，LHS 的子句头 rewrite 只需写一份
   （两个分支 LHS 不用各带一枚 `_`）。这是「with 让 rewrite 复用」的
   微观经济学。
3. **`( a , a₂)` 元组进 with**。`if … then (a , a′) else (a′ , a)`
   把「取小取大」也抽象出去；模式 `(a₁ , a₂)` 用 `Data.Product` 的
   `_,_` 直接拆对——Σ 的第一次露脸。

inj₁ 分支内部：`eq : n ≡ m`，`rewrite eq` 把目标里所有 `n` 换成 `m`，
新 node 的证明位要求 `suc m ≡ m ⊎ suc m ≡ suc m`，`inj₂ refl` 命中
右侧。书文在这里有一处小口误（说「用 refl 证左 disjunct」，实为右
disjunct；代码 `inj2 refl` 是对的）——照抄书时留意。

## 42.13 remove-min：荒谬模式与两对尺寸账

书图 5.5 全量搬运：

```agda
remove-min : ∀ {p} → (t : braun (suc p)) → A × braun p
remove-min (node a empty empty _) = a , empty
remove-min (node a empty (node _ _ _ _) (inj₁ ()))
remove-min (node a empty (node _ _ _ _) (inj₂ ()))
remove-min (node a (node {n} {m} a′ l r u) empty _)
  rewrite +-identityʳ (suc (n + m)) = a , node a′ l r u
remove-min (node a (node a₁ l₁ r₁ u₁) (node a₂ l₂ r₂ u₂) u)
  with remove-min (node a₁ l₁ r₁ u₁)
...    | a₁′ , l′ with if a₁′ ≺ a₂ then ( a₁′ , a₂) else (a₂ , a₁′)
remove-min (node a (node {n₁} {m₁} a₁ l₁ r₁ u₁)
                 (node {n₂} {m₂} _ l₂ r₂ u₂) u)
  | _ , l′ | smaller , other
  rewrite +-suc (n₁ + m₁) (n₂ + m₂) | +-comm (n₁ + m₁) (n₂ + m₂) =
    a , node smaller (node other l₂ r₂ u₂) l′ (lem u)
    where
    lem : ∀ {x y} → suc x ≡ y ⊎ suc x ≡ suc y → y ≡ x ⊎ y ≡ suc x
    lem (inj₁ p) = inj₂ (sym p)
    lem (inj₂ p) = inj₁ (sym (suc-injective p))
```

类型先读：输入树大小 `suc p`（**至少一格**，空树连进门的资格都没有），
返回 `A × braun p`——「删一个、恰好少一格」写在类型里，这就是
「heap 的 pop 返回什么」的类型层回答。五条子句：

- **句 1**：独根（左右皆空），交还 `a , empty`。
- **句 2/3**：左空右非空——42.11 实测过，这种树**不可构造**。子句靠
  荒谬模式 `()` 收掉，但注意书 5.2.3 的原话：*不能把荒谬模式写成整个
  证明一个子句——Agda 要你把 `⊎` 的两个 disjunct 各拆一条子句*。
  于是 `(inj₁ ())` 与 `(inj₂ ())` 两行。为什么？`()` 的判定按 disjunct
  逐个做：`inj₁` 位上的证明类型是 `zero ≡ suc …`（constructor clash，
  判空通过），`inj₂` 位上是 `zero ≡ suc (suc …)`（同理），而整个
  `⊎` 本身**不空**（`A ⊎ B` 只要有一侧有构造子就不空，`node` 明明收
  得下合法证明）——对整体写 `()` 是 Agda 判不动的。
- **句 4**：右空左非空。输入尺寸含 `+ zero`，交还的树不含——
  `rewrite +-identityʳ (suc (n + m))`（书 `+0`）把目标里的 `+ zero`
  消掉。删掉这记 rewrite 实测：

  ```text
  examples/TmpProbe42g.agda:15.59-72: error: [UnequalTerms]
  The terms
    n
  and
    n + m
  are not equal at type ℕ
  when checking that the inferred type of an application
    braun (suc (n + _m_25))
  matches the expected type
    braun (suc (n + m) + zero)
  ```

  Agda 把 `suc (n + m) + zero` 与 `suc (n + m)` 认作两回事——`+` 对第一
  参数递归，`A + zero` 在 `A` 是复合项时**算不动**（13 章 `n + 0` 的
  幽灵，这次以尺寸账的形式还魂）。
- **句 5**：两子皆 node。第一记 with 递归删左子最小元，拿回
  `a₁′ , l′`；第二记 with 在 `a₁′` 与右子根 `a₂`（右子的最小元）之间
  取小。重排后的新树：根 `smaller`、左子 `node other l₂ r₂ u₂`、右子
  `l′`——又是「交换 + 递归件回填」。尺寸账要证
  `suc (n₁+m₁) + suc (n₂+m₂) ≡ …` 一路挪 `suc`：`+-suc`（Properties:548）
  把 `+ suc` 里的 `suc` 外提，`+-comm`（:569）换加法方向，两刀合起来把
  目标掰成构造项的形状。最后证明位 `lem u`：交换子树把不变式**反向**
  了（`suc x ≡ y ⊎ …` 要变成 `y ≡ x ⊎ y ≡ suc x`），`where` 里的两条
  小引理就是手写的「反方向」：`sym` 调转等式，`suc-injective`
  （Properties:92，书 IAL 名 `suc-inj`）剥掉两侧 `suc`。

还有一条藏在契约里：**没有 empty 子句**。输入类型 `braun (suc p)`
与 `empty : braun zero` 顶头冲突（`zero` 与 `suc` 是两个不同构造子），
Agda 自己判掉这一情形，不劳你写 `lookup empty ()` 式的子句——书
5.2.3 特意点名这个「免费的情形消除」。

## 42.14 lookup：Fin 索引搬运，3.0 实名普查

书 5.1 的 `nthV`（越界不可表达的向量取元素）在树上复刻：`Fin n` 下标
O(log n) 查找。难点只有一个：进了右子之后，下标要做算术搬运
`i ∸ n`——这正是 16 章末尾埋的雷。先普查 **2.x 时代的 Fin 搬运工在
3.0 还剩谁**（`Data/Fin/Base.agda` 实名实测）：

| 2.x / 书时代名字 | 3.0 状态 | 位置与备注 |
|---|---|---|
| `toℕ : Fin n → ℕ` | ✅ 健在 | Fin/Base:40 |
| `fromℕ : (n : ℕ) → Fin (suc n)` | ✅ 健在 | Fin/Base:75；收紧版 `fromℕ< : .(m < n) → Fin n`（:81） |
| `embed : Fin m → Fin (m + n)` | ❌ 已删 | 实测 `Not in scope: embed` |
| `with≤ : …` | ❌ 已删 | `Data.Fin` 不再导出（见下） |
| `fromℕ≤ : …` | ❌ 已删 | 同上 |
| `lift : (Fin m → Fin n) → …` | ⚠ 改arity | `lift : ∀ k → (Fin m → Fin n) → Fin (k + m) → Fin (k + n)`（:215），`k` **显式前置** |
| `strengthen` | ✅ | :142 |
| `punchIn / punchOut` | ✅ | :276 / :268 |

（`strengthen`/`punchIn`/`lift` 的源头都在 `Data.Fin.Base`；门面
`Data.Fin` 对它 `public` 转出口（`Data/Fin.agda:14`），两条进货路径
实测都通——探针用 `open import Data.Fin using (lift; strengthen;
punchIn)` 零警告。）

两个实测细节。其一，旧版单参数 `lift f` 直接对接新 `lift`：

```text
examples/TmpProbe42h2.agda:8.12-16: error: [UnequalTypes]
The type
  Fin m → Fin n
is not a subtype of
  ℕ
when checking that the expression lift has type
(Fin m → Fin n) → Fin (suc m) → Fin (suc n)
```

报错说「`Fin m → Fin n` 不是 `ℕ` 的子类型」——因为新 `lift` 的第一
个参数是**那个 ℕ**（`k`），Agda 把你的函数塞给了 `k`。旧代码
`lift f` 一律补成 `lift 1 f` 或 `lift k f`。其二，`embed` 的
NotInScope 全文：

```text
examples/TmpProbe42h1.agda:8.13-18: error: [NotInScope]
Not in scope:
  embed
  at examples/TmpProbe42h1.agda:8.13-18
when scope checking embed
```

`with≤`/`fromℕ≤` 则死在进口处（`Data.Fin` 门面只转出口一部分名字）：

```text
examples/TmpProbe42k.agda:3.22-48: warning: -W[no]ModuleDoesntExport
The module Data.Fin doesn't export the following:
  with≤
  fromℕ≤
  (did you mean
     'fromℕ' or
     'fromℕ<' or
     'fromℕ<″'?)
when scope checking the declaration
  open import Data.Fin using (Fin; with≤; fromℕ≤)
```

提示里 `fromℕ<'` 正是新世界的入口：**所有旧搬运工都塌缩成
`fromℕ< 证明`**。示例第 8 节按这个方子自制 `embed′`：

```agda
embed′ : ∀ {m n} → Fin m → Fin (m + n)
embed′ {m} {n} i = fromℕ< (≤-trans (toℕ<n i) (m≤m+n m n))
```

（`toℕ<n : ∀ (i : Fin n) → toℕ i < n`，`Data/Fin/Properties.agda:186`；
`m≤m+n`，`Data/Nat/Properties.agda:706`。）

有了普查表，`lookup` 的写法就直白：比较 `toℕ i <? n`（`_<?_`，
Properties:415）决定进左子还是右子；左子直接 `fromℕ<`，右子先把
`i < suc (n + m)` 与 `¬ (i < n)` 合成 `i ∸ n < m`——stdlib 的减引理
名字海太深，本章直接手写一枚三行算术账本（注意：**Agda 没有前向
引用**，helper 必须定义在 `lookup` 之前）：

```agda
∸-helper : (i m n : ℕ) → i < n + m → n ≤ i → i ∸ n < m
∸-helper i m zero       i<n+m _       = i<n+m
∸-helper zero m (suc n) _       ()
∸-helper (suc j) m (suc n) j<n+m n≤j  =
  ∸-helper j m n (s<s⁻¹ j<n+m) (s≤s⁻¹ n≤j)

lookup : ∀ {n} → (t : braun n) → Fin n → A
lookup empty ()
lookup (node x l r u) fzero = x
lookup (node {n} {m} x l r u) (fsuc i) with toℕ i <? n
... | yes i<n  = lookup l (fromℕ< i<n)
... | no notLess =
    lookup r (fromℕ< (∸-helper (toℕ i) m n (toℕ<n i) (≮⇒≥ notLess)))
```

第二子句的 `()` 是 `Fin zero` 无构造子（16 章 `lookup : Vec A n →
Fin n → A` 的同款免检）。
`s≤s⁻¹`/`s<s⁻¹` 这对「剥 suc 逆操作」住 `Data/Nat/Base.agda:71,74`，
**不在** `Data.Nat.Properties`（实测撞警告）：

```text
examples/TmpProbe42h4.agda:4.33-53: warning: -W[no]ModuleDoesntExport
The module Data.Nat.Properties doesn't export the following:
  s≤s⁻¹
  s<s⁻¹
when scope checking the declaration
  open import Data.Nat.Properties using (s≤s⁻¹; s<s⁻¹)

examples/TmpProbe42h4.agda:7.7-12: error: [NotInScope]
Not in scope:
  s≤s⁻¹
  at examples/TmpProbe42h4.agda:7.7-12
    (did you mean
       'Data.Nat.s<s⁻¹' or
       'Data.Nat.s≤s⁻¹' or
       'Data.Nat.s≤″s⁻¹'?)
when scope checking s≤s⁻¹
```

did-you-mean 把正确的家（`Data.Nat`）报给你了——3.0 里**构造子层的
逆引理跟构造子住一起**（Base），**关系层的算术引理**才在 Properties。
另备 `≮⇒≥`（Properties:355，`¬ (m < n) → n ≤ m`）把 `no` 分支的否定
转成可用的不等式。

## 42.15 整机演示：摊平、尺寸不撒谎、七棵树

内部验证 ↔ 外部验证的往返：树摊平成表，再证「摊平后的 length 不
撒谎」（尺寸索引与表长的**定理级**一致——索引是内部账本，`length`
是外部账本，对账如下）：

```agda
toList : ∀ {n} → braun n → List A
toList empty = []
toList (node x l r u) = x ∷ toList l ++ toList r

length-toList : ∀ {n} (t : braun n) → length (toList t) ≡ n
length-toList empty = refl
length-toList (node {n} {m} x l r u)
  rewrite ++-length′ (toList l) (toList r)
        | length-toList l | length-toList r = refl

fromList : (xs : List A) → braun (length xs)
fromList []       = empty
fromList (x ∷ xs) = insert x (fromList xs)
```

`length-toList` 步例连打三记 rewrite（42.2 的分配律 + 两枚 IH），
是本章手艺的最小综合测试。`fromList` 的方向值得咂摸：返回类型
`braun (length xs)` 让「插了 n 次 = 有 n 个结点」这类账**由构造保证**，
一行归纳都不必写。实例化与计算演示（`open Braun ℕ _≤ᵇ_` 之后）：

```agda
t1 : braun 3
t1 = insert 5 (insert 3 (insert 8 empty))

_ : toList t1 ≡ 3 ∷ 5 ∷ 8 ∷ []
_ = refl

_ : remove-min t1 ≡ (3 , node 5 (node 8 empty empty (inj₁ refl)) empty (inj₂ refl))
_ = refl

_ : lookup t1 fzero ≡ 3
_ = refl

_ : lookup t1 (fsuc fzero) ≡ 5
_ = refl

_ : lookup t1 (fsuc (fsuc fzero)) ≡ 8
_ = refl
```

全部 `refl`——五棵/三棵树上的 insert、remove-min、lookup 都在 Agda 的
正规化引擎里**真的算出了**堆序结果（3 坐镇根、5 带 8 的左子、右子
空）。`t7 = fromList (1 ∷ … ∷ 7 ∷ [])` 再补一发
`length (toList t7) ≡ 7` 的 refl：七结点 Braun 树的摊平对账同样白捡。
这套件的下游去处：书到 Huffman 编码一章还把 Braun 树封成优先队列
（pqueue）反复 insert/remove-min，本章按主题裁到 lookup 为止。

## 42.16 Σ 实战：非零自然数与「值 + 证据」查询

书 5.3：**不想为新不变式开一个 data，就用 Σ**。Σ 是「依赖对」：

```agda
data Σ {a b} (A : Set a) (B : A → Set b) : Set (a ⊔ b) where
  _,_ : (x : A) → B x → Σ A B
```

（内置于 `Agda.Builtin.Sigma`，`Data/Product/Base.agda:30` 原样转出口；
书图 5.6 的 IAL 版一字不差，只是 `_∔_` 级别运算在 3.0 写作 `⊔`。）
非零自然数（书 5.3 的 N+）：

```agda
ℕ⁺ : Set
ℕ⁺ = Σ ℕ (λ n → eqℕ n zero ≡ false)

suc⁺ : ℕ⁺ → ℕ⁺
suc⁺ (n , p) = suc n , refl

_⁺+_ : ℕ⁺ → ℕ⁺ → ℕ⁺
(zero , ()) ⁺+ y
(suc zero , p) ⁺+ y        = suc⁺ y
(suc (suc n) , p) ⁺+ y     = suc⁺ ((suc n , refl) ⁺+ y)
```

结构完全照书图 5.7（`_++_`/`suc+` 改名 `_⁺+_`/`suc⁺` 避免与表拼接
混读）。三行都是书的旧识：`zero` 分支荒谬模式（Σ 的**第二分量**
`eqℕ zero zero ≡ false` 即 `true ≡ false`，`()` 判空）；`suc n , refl`
给递归调用**现造**非零证据（`eqℕ (suc n) zero` 折叠成 `false`，refl
白捡）。一个易被忽略的设计决策：**为什么性质写 `eqℕ n zero ≡ false`
（Bool 版）而不是 `¬ (n ≡ zero)`（命题版）？** 因为子句
`(zero , ())` 里 `()` 作用在**证明分量**上：Bool 版的
`true ≡ false` 是 `_≡_` 型，`refl` 唯一构造子、两侧不同形，Agda 的
constructor-clash 判空**能过关**；命题版 `¬ (zero ≡ zero)` 是
**函数型** `(zero ≡ zero) → ⊥`，`()` 模式要求函数型判空时 Agda 只能
看值型侧——`zero ≡ zero`  inhabited（`refl` 就在眼前），函数型本身
没有「构造子穷尽」可言，`()` 拒绝。书用 IAL 的 `iszero` 恰是 Bool
版，不是随手——**证明的分量用哪种语言写，决定了模式匹配的手感**。
（`split-demo` 里 `λ ()` 出现在**函数型**上能过，是因为那是
`⊥`-codomain 的 lambda 空模式，情形与 Σ 分量相反；这条区分本身就
值得抄进笔记。）

Σ 的第二件实事：查询函数**返回「值 + 性质」**。书 5.4.3 的
bst-search 返回 `maybe (Σ …)`——「找到的值」和「值确实在表里」一次
打包。本章用最小样张复刻这个姿势：

```agda
nonEmptySplit : ∀ {A : Set} (xs : List A) → ¬ (xs ≡ []) →
                Σ[ x ∈ A ] Σ[ ys ∈ List A ] xs ≡ x ∷ ys
nonEmptySplit []       nd = ⊥-elim (nd refl)
nonEmptySplit (x ∷ xs) nd = x , (xs , refl)

split-demo : nonEmptySplit (1 ∷ 2 ∷ []) (λ ()) ≡ (1 , (2 ∷ [] , refl))
split-demo = refl
```

返回的不只是拆出来的头与尾，还有一张「原表 = 头 ∷ 尾」的**收据**
（`Σ[ ]∈_ ]` 是 `Data.Product` 的 `Σ-syntax`）。空表分支：假设 `nd`
说「它不是 []」，而这里它就是 `[]`——`nd refl : ⊥`，`⊥-elim` 收队
（12 章连接词课的遗产）。demo 里的证据参数直接 `λ ()`：
`(1 ∷ 2 ∷ [] ≡ []) → ⊥` 的「入不敷出」由 constructor clash 判掉，
不费一行话。这个模式在后文 43 章和一切「带证明 API」里反复出现，
先混个脸熟。

## 42.17 为什么记 Σ，又为什么记 Π（书 5.3.1 中文版）

书 5.3.1 是个精彩的记号考据，值得完整转述：

**Σ = 广义不相并。** 不相并 `A Z B`（即 `A ⊎ B`）的元素是带标签的
`(0, x)` 或 `(1, y)`——标签标明来路。无穷族 `B₁ ⊎ B₂ ⊎ …` 的标签
不再只有 0/1，而是指标集里的元素；指标集换成 `ℕ`，不相并就是
`Σn ∈ ℕ. Bn`，元素 `(n, b)`，`b ∈ Bn`。一般地，指标集为 `A` 的
**依赖不相并**写作 `Σa ∈ A. Ba`——`B` 的类型可以跟着 `a` 变。
这就是依赖对的 Σ：**把「挑一个指标，再挑该指标下的一个元素」
合并成一对**。「sum type」这个名字不是白得的（41 章类型的代数里
`A + B` 的基数正是求和）。

**Π = 广义笛卡尔积。** 有限积 `B₁ × … × Bₙ` 的元素是元组
`(b₁, …, bₙ)`；无穷积的「无穷元组」怎么表示？——元组第 n 位是什么，
就是**从位置到值的函数** `n ↦ bₙ`。于是依赖函数型
`Πx : A. Bx`（Agda 写作 `(x : A) → B x`）的元素是函数：吃一个指标
`a`，吐该指标下的一个值 `b : B a`。**「依赖函数」和「无穷元组」是
同一枚硬币**——40 章 `fold` 的多态型 `(A → B) → List A → List B`
其实一直是 `Π`，只是没人逼你读成元组。

一句话收束：`Σ` 管「**存在**一个配对」（第 12 章 `_,_` 的依赖版），
`Π` 管「**每个**都给得出」（∀ 的依赖版）。Braun 树 `node` 的第四
参数（存在性证据）与 `fromList`（对所有表都造得出树）本章各用了
一路，正好一边一硬币。

## 42.18 书 ↔ stdlib 3.0 命名对照总表

IAL（书 prelude，Agda 2.2.x 时代）→ stdlib 3.0，全部实测：

| 书（IAL） | stdlib 3.0 | 出处 / 备注 |
|---|---|---|
| `B`、`tt`、`ff` | `Bool`、`true`、`false` | `Data.Bool` |
| `L A`、`::`、`List-rec` | `List A`、`_∷_`、递归即归纳 | `Data.List` |
| `reverse-helper` | （无同名；同路线 `reverseAcc`） | Base:234；示例自造 `revAcc` |
| `reverse` | `reverse` | Base:238；⚠ `ʳ++` 反转**左**操作数，Base:244 |
| `filter`（Bool 谓词） | `filterᵇ`；`filter` 已改吃 Dec | Base:365 / :359 |
| `keep` / keep idiom | `inspect` + `Reveal_·_is_` | PropEq:106-114 |
| `iszero` | 无同名；自制 `eqℕ` 或 `_≡?_ zero` | `Data.Nat` |
| `_Z_`、`inj1`、`inj2` | `_⊎_`、`inj₁`、`inj₂` | `Data.Sum`（Sum/Base:28） |
| `Σ`、`_∔_` 级别 | `Data.Product` 的 `Σ`、`_,_` | Product/Base:30 转出口；`⊔` 代 `_+_` |
| `+0` | `+-identityʳ` | Nat/Properties:562 |
| `+comm` | `+-comm` | :569 |
| `+suc` | `+-suc` | :548 |
| `suc-inj` | `suc-injective` | :92 |
| `lem`（尺寸反证） | 自制（示例 remove-min 内 `where`） | 书图 5.5 同名 |
| `braun-tree` 模块参数 `_<_A_` | `module Braun (A) (_≺_)` 参数改名 | 避开 `_≤_`/`_<_` 撞名 |
| `bt-empty` / `bt-node` | `empty` / `node`（进 `Braun` 模块） | 示例 42.11 |
| `_≤_`（Bool 版，书 4.3.3） | `_≤ᵇ_`（Base:47）；命题版 `_≤_` 另册 | 布尔/命题两套要分清 |
| Fin：`embed` | ❌ 删；自制 `embed′ = fromℕ< …` | 实测 NotInScope |
| Fin：`with≤`、`fromℕ≤` | ❌ 删 | 实测 ModuleDoesntExport |
| Fin：`lift f` | `lift k f`（k 显式前置） | Fin/Base:215 |
| `s≤s⁻¹`、`s<s⁻¹` | 住 `Data.Nat`（Base:71/74），**非** Properties | 实测 ModuleDoesntExport |
| `++-length`（2.x） | `length-++`（ys 改隐式） | List/Properties:129 |

## 坑位清单

1. **`length-++` 参数结构变了**：3.0 是 `(xs) {ys}`「一显一隐」，
   照 2.x `++-length xs ys` 双显式对接撞 `UnequalTypes`
   （hidden/visible 那截报错，42.2）。进货前 `:Check`。
2. **`_ʳ++_` 反转的是左操作数**：`xs ʳ++ ys = reverse xs ++ ys`，与书
   `reverse-helper h l`（累加器在左）方向相反。口诀：*谁在累加器位，
   谁不被反转*（42.5）。
3. **stdlib `filter` 已不是书的 filter**：吃 `Decidable P`，Bool 版叫
   `filterᵇ`（42.6）。旧教程的 `filter p xs` 一律先翻译成 `filterᵇ`。
4. **with 的替换是一次性的**：正规化后「长回来」的 `p x` 没人管
   （实测 probe c 的 `if p x` 还魂）。keep/inspect 随身带等式，
   `rewrite` 补刀；keep 版 true 分支**要两刀**（少一刀实测还魂，
   probe n），inspect 版顺序反过来（先 IH 后 eq，probe m）。
5. **`[_]` 重名核弹**：Data.List 单元素表 vs PropEq Reveal 构造子，
   两边都进 scope 再用到就是 `AmbiguousName`（全文 42.9）。解法：
   with 模式写完全限定名 `Relation.Binary.PropositionalEquality.[ eq ]`。
6. **Fin 旧搬运工集体阵亡**：`embed`（NotInScope）、`with≤`/`fromℕ≤`
   （门面不导出）；`lift` 多了一个**显式**前置 `k`（报错把 `Fin m → Fin n`
   对着 `ℕ` 比，42.14）。新世界的统一入口是 `fromℕ< 证明`。
7. **Fin 搬运工的本家在 `Data.Fin.Base`**：门面 `Data.Fin` 有
   `public` 转出口（实测 `using (lift; strengthen; punchIn)` 零警告），
   但 `embed`/`with≤`/`fromℕ≤` 哪条路都没有（probe h1/k）——旧代码里
   它们全都改走 `fromℕ< 证明`。
8. **`s≤s⁻¹`/`s<s⁻¹` 住在 `Data.Nat`**（Base），不在
   `Data.Nat.Properties`——did-you-mean 会把家报给你（42.14）。构造子
   层逆引理跟构造子走，关系层算术引理在 Properties。
9. **Σ 证明分量的「空」要用 Bool 式判空**：`eqℕ n zero ≡ false` 让
   `(zero , ())` 可行；命题式 `¬ (n ≡ zero)` 的分量是函数型，`()`
   拒收（42.16 末段）。书用 `iszero` 正是 Bool 式，细节即设计。
10. **荒谬模式按 disjunct 拆**：`node a empty (node …) (inj₁ ())` 与
    `(inj₂ ())` 必须各一条子句，整体 `()` 判不动（书的 remove-min
    句 2/3，42.13）。
11. **尺寸账的 `+ zero` 不会自己掉**：`suc (n + m) + zero` 卡死在
    `+` 对第一参数递归上，`rewrite +-identityʳ` 手动消（实测 probe g，
    42.13）；加法方向拧着时 `+-comm` 记得提前量（实测 probe f，子句头
    rewrite 一次救两分支，42.12）。
12. **Agda 无前向引用**：`∸-helper` 必须定义在使用它的 `lookup` 之前
    （示例里一条 NotInScope 的教训，挪定义即愈）。

---
上一章：[41 · 类型的代数](41-type-algebra.md) ｜ 下一章：[43 · 类型层计算与证明反射](43-typelevel-reflection.md) ｜ 返回：[README](../README.md)
