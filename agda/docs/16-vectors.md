# 16 · Vec：长度索引的列表

10 章我们见过 `Fin n`——「小于 n 的证明」，当时留了句伏笔：这些
证明早晚要拿去当**下标**。本章兑现：`Vec A n`，长度焊死在类型里
的列表。它是一头教科书级的依赖类型：`head` 对空表**不可表达**、
`lookup` 越界**无法写出来**、append 的长度算式**住在签名里**。
代价也教科书级——索引算术会卡证明：`rewrite` 方向选错、连上下文
一起改写、往返定律用普通等式**证不出来**。本章把这些 pain point
全部实测留档（含 stdlib 官方解法 `≈[ eq ]`）——Vec 正是「证明即
索引」世界观最硬的入门课。

对应示例：`../examples/Ex16_vectors.agda`（全部报错为 Agda 2.8.0
+ stdlib 2.3 实测）

## 16.1 定义解剖：长度住在索引里

stdlib 原文（`Data.Vec.Base`）：

```agda
data Vec (A : Set) : ℕ → Set where
  []  : Vec A zero
  _∷_ : (x : A) (xs : Vec A n) → Vec A (suc n)
```

A 是参数、ℕ 是**索引**：构造子负责把索引「算」出来——`[]` 造
zero 长，`∷` 给长度 +1。`Vec A 3` 和 `Vec A 4` 是不同类型，3 个
元素配 3、多一个少一个都过不了检查：

```agda
v3 : Vec ℕ 3
v3 = 10 ∷ 20 ∷ 30 ∷ []

v4 : Vec ℕ 4
v4 = 40 ∷ v3                    -- Vec ℕ (suc 3) = Vec ℕ 4 ✓
```

⚠ `[]` 与 `_∷_` 和 List 同名——10 章的「按期望类型分派」规则原样
适用，示例为此单独 `open import Data.Vec using ([]; _∷_)`。想
体会构造子的索引算术，示例复刻了一个最小版 `VecT`（自带
`[]T`/`_∷T_`）并双向换算 `toT`/`fromT`——同参数同索引的往返定律
`fromT∘toT` 用 13 章归纳法一路 `refl`/`cong` 畅通。先给点甜头，
16.7 会告诉你索引一不同构立刻寸步难行。

## 16.2 越界不可表达：head/tail/lookup 都要「索引的形状」

三个标准函数的签名（`Data.Vec.Base`）：

```agda
head   : Vec A (1 + n) → A
tail   : Vec A (1 + n) → Vec A n
lookup : Vec A n → Fin n → A
```

`head` 的定义域写死 `1 + n`：空表 `Vec A zero` **根本进不来**，
所以定义只有一行、没有 `[]` 分支——覆盖率检查认可它不可能被调用，
`Fail`/异常在函数语言里就此失业。对照 08 章 List 版 head 的
`Maybe`/默认值 gymnastics，这就是「静态安全」的含金量。实测计算：

```agda
_ : head v3 ≡ 10
_ = refl

i2 : Fin 3
i2 = # 2                        -- 类型检查期自动裁决 2 < 3

_ : lookup v3 i2 ≡ 30
_ = refl
```

`Fin 3` 居民的三种造法 10 章全学过，这里都会用：构造子
`fzero/fsuc`（Data.Fin 改名导入）、字面量限定的 `# 2`、以及
`fromℕ 2 : Fin 3`（`fromℕ : (k : ℕ) → Fin (suc k)`）。想要
「可能为空」的 head？把选择权交还类型：

```agda
headMaybe : ∀ {A : Set} {n} → Vec A n → Maybe A
headMaybe {n = zero}  _       = nothing
headMaybe {n = suc n} (x ∷ _) = just x
```

**实测坑**：两行的 `{n = …}` 都不是装饰——隐式参数位直接写
`zero` 会把它去**绑定最前面的隐式 `A`**（类型是 `Set`，不是可分
析的 data）：

```text
error: [SplitError.NotADatatype]
Cannot split on argument of non-datatype Set
when checking that the pattern zero has type Set
```

自己写单参数版 `head′ : Vec A (suc n) → A` 也只需一行
`head′ (x ∷ xs) = x`——但索引写法有讲究，见坑位 5：`suc n` 能分
析，`n + 1` 不能。

## 16.3 append：索引算术直接写进类型

stdlib 的 append 零 rewrite，先看它为什么这么横（源码原文）：

```agda
_++_ : Vec A m → Vec A n → Vec A (m + n)
[]       ++ ys = ys
(x ∷ xs) ++ ys = x ∷ (xs ++ ys)
```

结果索引 `suc m + n` 会**定义展开**成 `suc (m + n)`——因为 ℕ 的
`_+_` 按**左参数**递归，而 append 的递归也在左参数上。递归方向
和算术方向一致，类型检查器自己就能对上账：

```agda
_ : (1 ∷ 2 ∷ []) ++ (3 ∷ []) ≡ 1 ∷ 2 ∷ 3 ∷ []
_ = refl
```

现在把结果索引反过来写 `n + m`——本章最痛的一步开始。直写递归
（示例去掉 rewrite 的原始尝试）实测两连败：基例死在 `n + zero`
化简不动，步例死在 `suc (n + m) ≟ n + suc m`——数学上真、定义上
不折叠（`+` 不看右参数！）：

```text
error: [UnequalTerms]
n != n + zero of type ℕ
when checking that the expression ys has type Vec A (n + zero)

error: [UnequalTerms]
suc _n_7 != n + suc m of type ℕ
when checking that the inferred type of an application
  Vec A (suc _n_7)
matches the expected type
  Vec A (n + suc m)
```

解药就是 13 章的 `rewrite` 在**类型层**移索引：

```agda
append′ : ∀ {A : Set} {m n : ℕ} → Vec A m → Vec A n → Vec A (n + m)
append′ {m = zero}  {n} []       ys rewrite +-identityʳ n = ys
append′ {m = suc m} {n} (x ∷ xs) ys rewrite +-suc  n m    = x ∷ append′ xs ys
```

`+-identityʳ : ∀ n → n + zero ≡ n`、`+-suc : ∀ m n → m + suc n ≡
suc (m + n)`，方向都挑「把手里的形状改成要的」。另有 **LHS 隐式
参数坑**（实测）：子句里隐式必须挤在所有显式参数**左边**，写成
`append′ {m = zero} [] {n} ys` 直接报：

```text
error: [WrongHidingInLHS]
Unexpected implicit argument
when checking the clause left hand side
```

snoc `_∷ʳ_`（末尾加一个）同样零 rewrite——它的索引写作 `suc n`
而非 `n + 1`，又是那句话：**索引算式的写法就是能否化简的命运**。
`_ : (1 ∷ 2 ∷ []) ∷ʳ 3 ≡ 1 ∷ 2 ∷ 3 ∷ []` 一条 refl 过。

## 16.4 reverse：尾累加版的 sym rewrite（全章最痛实录）

目标 `reverse′ : Vec A n → Vec A n`，尾递归累加器版。辅助函数的
索引怎么定？`go acc xs` 里 xs 还剩 `n` 个、acc 已有 `m` 个，结果
长度写 `n + m`（剩余在前）才有的谈——cons 枝里递归返回
`go (x ∷ acc) xs : Vec A (n + suc m)`，目标却是
`suc n + m = suc (n + m)`。16.3 的对称冤案再现，解药是**反向
rewrite**：

```agda
go {m} {suc n} acc (x ∷ xs) rewrite sym (+-suc n m) = go (x ∷ acc) xs
```

`rewrite sym` 把**目标**从 `n + suc m` 改写成 `suc (n + m)`——
与 Coq 的 `rewrite <- plus_n_Sm` 完全同构，项模式这边连箭头方向
都用 `sym` 明说。真正的暗礁在外层：`go [] xs` 得 `Vec A (n + 0)`，
配不上签名要的 `Vec A n`。自然的想法是再来一发
`rewrite sym (+-identityʳ n)` 写在子句左边——实测翻车：

```text
error: [UnequalTerms]
n + 0 != n of type ℕ
when checking that the inferred type of an application
  Vec A (n + 0 + zero)
matches the expected type
  Vec A (n + 0)
```

看清楚报错里的 `n + 0 + zero`：**rewrite 是对整条子句（含上下文）
的全局替换**——它把 `xs : Vec A n` 里的 `n` 也换成了 `n + 0`，
账越算越大，无穷递归式地自我复刻。13 章教「rewrite 从左到右砍
目标」，这里砍的是类型变量本身。正解换武器：**cast——显式递等式
换索引，上下文纹丝不动**（stdlib 源码原文）：

```agda
cast : .(eq : m ≡ n) → Vec A m → Vec A n
```

全章定稿：

```agda
reverse′ : ∀ {A : Set} {n} → Vec A n → Vec A n
reverse′ {A} {n = n} xs = cast (+-identityʳ n) (go [] xs)
  where
  go : ∀ {m n : ℕ} → Vec A m → Vec A n → Vec A (n + m)
  go acc [] = acc
  go {m} {suc n} acc (x ∷ xs) rewrite sym (+-suc n m) = go (x ∷ acc) xs
```

顺带一提，stdlib 自己的 `reverse`（`Data.Vec.Base`）根本不写
累加器子句：`reverse = foldl (Vec _) (λ rev x → x ∷ rev) []`
（`Data.Vec.Properties` 另有 `reverse-∷`、`reverse-involutive` 等
一堆索引账本引理）——索引算式的坑，官方也得一个个 `rewrite`
踩过去。

## 16.5 map/replicate/zip/unzip：保长函数全家

```agda
map′ : ∀ {A B : Set} {n} → (A → B) → Vec A n → Vec B n
map′ f []       = []
map′ f (x ∷ xs) = f x ∷ map′ f xs

_ : map′ suc v3 ≡ 11 ∷ 21 ∷ 31 ∷ []
_ = refl
```

List 时代「map 不改变长度」是要单证的定理（`length-map`），Vec
时代它**就是签名**——`n` 原样穿到结果类型。同族还有：
`replicate : (n : ℕ) → A → Vec A n`（个数写在第一个参数：
`replicate 4 zero ≡ 0 ∷ 0 ∷ 0 ∷ 0 ∷ []` 实测 refl）、
`zip : Vec A n → Vec B n → Vec (A × B) n`——两个参数**共享同一个
n**，「不等长的表没法 zip」不是运行时报错，是压根写不出调用。解压回
装是免证明的一条等式链：

```agda
zip∘unzip : ∀ {A B : Set} {n} (xs : Vec A n) (ys : Vec B n) →
            unzip (zip xs ys) ≡ (xs , ys)
zip∘unzip []       []       = refl
zip∘unzip (x ∷ xs) (y ∷ ys) rewrite zip∘unzip xs ys = refl
```

（对比 08 章 List 版：不等长时 `zip∘unzip` 根本不是命题——同一个
n 消灭了整类反例。）

## 16.6 with 判定长度做 headOr——Dec 首次上岗依赖匹配

15 章的 `Dec` 怎么和 Vec 配合？两个 Vec 版本对比着看——List 版
`headOrList`（08 章）靠运行时分支兜底，就不重贴了。Vec 版甲：长度做成
**显式**参数，模式匹配直接裁决（`n` 与 `xs` 的索引由匹配自动同步）：

```agda
headOr : ∀ {A : Set} → A → (n : ℕ) → Vec A n → A
headOr d zero    _       = d
headOr d (suc n) (x ∷ _) = x
```

Vec 版乙：隐式索引也能 `with` 一个**等式判定**逼出形状——
`n ≟ zero` 吐出 `Dec (n ≡ zero)`。四种「判定 × 形状」组合里有两条
逻辑上不可能：`(yes, x ∷ xs)` 里 `xs` 的索引已是 `suc …`，
`n ≡ zero` 的证据荒谬，写成 `yes ()` 即灭；`(no, [])` 里反过来
`refl` 撞上 `¬p`，只能显式 `⊥-elim`：

```agda
headOrDec : ∀ {A : Set} {n} → A → Vec A n → A
headOrDec {A} {n} d xs with n ≟ zero | xs
... | yes () | (x ∷ xs)
... | no  ¬p | []                    = ⊥-elim (¬p refl)
... | yes _  | []                    = d
... | no  _  | (x ∷ xs)              = x
```

两条不可能的分支覆盖率检查照样点名要写。这就是「判定的精化
力量」：`Dec` 的证据进 `with` 后**改写上下文类型**（15.1 预告过
的依赖匹配完全体）。版甲够用就别上版乙——显式 `n` 本就是 Vec
调用方的常识。

## 16.7 回到 List：forget/flow 双向换算与往返定律

Vec 和 List 的换算双向：丢长度（stdlib 名 `toList`，这里叫
forget）与**从长度找回索引**（stdlib 名 `fromList`，这里叫 flow）：

```agda
forget : ∀ {A : Set} {n} → Vec A n → List A
forget []       = []
forget (x ∷ xs) = x ∷ forget xs

flow : ∀ {A : Set} (xs : List A) → Vec A (length xs)
flow []       = []
flow (x ∷ xs) = x ∷ flow xs
```

`flow` 的签名值得停三秒：返回类型 `Vec A (length xs)` 里的
`length xs` 是**由输入算出来的类型**——Curry–Howard「证明即索引」
在本章最日常的形态：给什么长度，进什么索引。
正向定律（List → Vec → List）好证，普通归纳两行：

```agda
forget∘flow : ∀ {A : Set} (xs : List A) → forget (flow xs) ≡ xs
forget∘flow []       = refl
forget∘flow (x ∷ xs) = cong (x ∷_) (forget∘flow xs)
```

反向定律（Vec → List → Vec）卡住了，而且卡得理直气壮。目标
`flow (forget v) ≡ v` 的归纳步里，归纳假设的索引是 `n`，而
`flow (forget v)` 的索引是 `length (forget v)`——`v` 是**变量**，
`length (forget v)` 一折一停，两个索引对不上号（实测）：

```text
error: [UnequalTerms]
n != Data.List.foldr (Function.Base.const suc) 0 (forget v) of type
ℕ
when checking that the expression v has type
Vec A (length (forget v))
```

（`foldr (const suc) 0` 就是 `List.length` 的内部真身。）补救
直觉①：先单证「索引账本」引理——这条**确实**能归纳：

```agda
len-forget : ∀ {A : Set} {n} (v : Vec A n) → length (forget v) ≡ n
len-forget []       = refl
len-forget (x ∷ v)  = cong suc (len-forget v)
```

补救直觉②：拿它 `rewrite sym (len-forget v)` 把目标里的 `n` 换
过去——同样死：rewrite 全局替换，**上下文里 `v : Vec A n` 也被
改写成 `v : Vec A (length (forget v))`**，递归调用立刻对不上号
（16.4 同款自伤）。stdlib 对此有正解（`Data.Vec.Properties` 的
`fromList∘toList`），心法是：**别硬证两个不同索引的 Vec 相等，
把 cast 折进定理陈述**。等值关系来自
`Data.Vec.Relation.Binary.Equality.Cast`：

```agda
xs ≈[ eq ] ys = cast eq xs ≡ ys
```

于是定理变成 `flow (forget v) ≈[ len-forget v ] v`，证明回到
两行（`cast` 的等式参数声明为**不相关**——`.(eq : …)`，类型比较
时不追究「哪个证明」，`cong (x ∷_)` 直接过关）：

```agda
open import Data.Vec.Relation.Binary.Equality.Cast using (_≈[_]_)

flow∘forget : ∀ {A : Set} {n} (v : Vec A n) → flow (forget v) ≈[ len-forget v ] v
flow∘forget []       = refl
flow∘forget (x ∷ v)  = cong (x ∷_) (flow∘forget v)
```

这条坑位（16.9 第 7 条）是 Vec 新手墙里最硬的一块：报错文本不提
cast、不提 ≈[]，全靠知道「索引不同构的 Vec 之间没有普通等式可
证」这一层。另一半 `forget∘flow` 用普通 `≡` 即可——`length xs`
随 xs 递归展开，没有跨索引的账。

## 16.8 证明即索引：tabulate/allFin 与小结

`Fin n → A` 与 `Vec A n` 互为「摊开/竖起来」：

```agda
squares : Vec ℕ 4
squares = tabulate (λ i → toℕ i * toℕ i)

_ : squares ≡ 0 ∷ 1 ∷ 4 ∷ 9 ∷ []
_ = refl
```

`allFin : (n : ℕ) → Vec (Fin n) n`——Fin n 的全部 n 个居民排成
一张表，两条 refl 实测（`allFin 3 ≡ fzero ∷ fsuc fzero ∷
fsuc (fsuc fzero) ∷ []`；`lookup (allFin 3) (# 2) ≡
fsuc (fsuc fzero)`）。本章世界观收束成两行：

* `Fin n` ≃ `{0,…,n−1}`：**索引 = 小于 n 的证明**；
* `Vec A n` ≃ 长度恰为 n 的表：**索引 = 长度计算的结果**。

两者都把证明搬进了类型——类型检查器顺手拒收数不对的程序（越界、
错长、zip 不齐），全章没写一条 `Fail`。下一章走向另一极：函数
空间本身的结构（同构与外延）。

## 16.9 坑位清单（本项目实测）

1. **`[]`/`∷` 与 List 同名不分家**：靠期望类型分派（10 章规则），
   `open Data.Vec` 后写的 `[]` 未必是 Vec 的——混用文件里学示例
   单独 `open import Data.Vec using ([]; _∷_)`，必要时写全名
   `Data.Vec._∷_`。
2. **隐式索引不能裸拆**：`headMaybe {zero} _` 的 `zero` 会去绑定
   最前的隐式 `A`，实测 `Cannot split on argument of non-datatype
   Set`；必须点名 `{n = zero}`。
3. **子句 LHS 的隐式参数不能夹在显式参数中间**：
   `append′ {m = zero} [] {n} ys` 实测 `WrongHidingInLHS:
   Unexpected implicit argument`；隐式全部前置。
4. **`_+_` 只按左参数化简**：`suc m + n` 送分、`n + suc m` 卡死
   ——索引算术必须顺着定义方向写，逆方向靠 `rewrite +-suc/
   +-identityʳ`（16.3 两条实测 UnequalTerms 就是学费）。
5. **索引写 `n + 1` 连匹配都过不了**：`head″ : Vec A (n + 1) → A`
   拆 `(x ∷ xs)` 实测 `UnificationStuck: suc n ≟ n₁ + 1`——变量
   在 `+` 左边就化简不动，改 `suc n` 一秒活；`head` 签名写
   `1 + n` 也是同一原因（`1 + n` 能折成 `suc n`）。
6. **rewrite 连上下文一起改**：`reverse′` 外层想用
   `rewrite sym (+-identityʳ n)` 凑签名，结果 `xs : Vec A n` 被
   连带改成 `Vec A (n + 0)`，实测报错里冒出 `n + 0 + zero`——
   要「只换值不换上下文」用 `cast`。
7. **Vec↔List 往返定律用普通 `≡` 证不出来**：`flow (forget v) ≡ v`
   的归纳步卡 `n != length (forget v)`（变量上化简不动）；陈述
   改成 `≈[ len-forget v ]`（cast 等式，`Data.Vec.Relation.Binary.Equality.Cast`）
   才有两行证明——报错文本零提示，全靠常识（本条即本章学费之王）。
8. **`_∷ʳ_`/`replicate` 的索引账别心算**：`snoc` 索引是 `suc n`
   不是 `n + 1`，`replicate` 个数在第一参数；用前 `:type` 一下，
   与 14 章「mono ˡ/ʳ 别赌」同一纪律。

---
上一章：[15 · 可判定性质](15-decidable.md) ｜ 下一章：[17 · 函数世界：同构与外延](17-functions.md) ｜ 返回：[README](../README.md)
