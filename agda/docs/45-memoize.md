# 45 · 记忆化即类型优化：Shape 索引的 Trie 与 Memoizes 谓词

> **第九部分 · 收官（45）** ｜ 全书结构与阅读路线见 [README](../README.md)

这是**主线**（01–45）的收官章；它后面还有第十部分 46–47 两章元理论，把镜头
从「用 Agda 写程序」掉转成「用 Agda 讲逻辑」。前面 44 章把 Agda 的每一层都铺完了：类型与证明
（01–17）、依赖数据结构（18–19）、同构与类型代数（20、23）、判定与
intrinsic 验证（24）、实例搜索（25）、标准库全家桶（36–42）。这一章把
它们全部拧成一股绳，回答一个**计算层面**的问题：

> 动态规划（记忆化）能不能不靠程序员手工调表，而是由类型系统**保证正确**地
> 自动完成？

答案是能，而且整条构造链没有一步超出你已经学过的内容：归纳数据类型
（07 章）、索引类型（10、18、24 章）、Σ 类型（10 章）、Dec 判定
（17 章）、同构与有限类型基数（23 章）、逐点相等与外延（20 章）、
实例搜索（25 章）。本章的每一步都会把对应章节叫回来加班。

对应示例：`../examples/Ex45_memoize.agda`

**实测口径**（两台机器的交代见 02 章）：本章示例与下文报错原文均为 **Agda 2.9.0 + stdlib 3.0**
实测原样粘贴（复现：`cd agda && ./build.sh Ex45_memoize`）；引用的 stdlib
源码行号取自本机 git 源 `/Volumes/mac004/lang/agda-stdlib/src`。

## 45.1 问题：动态规划到底是什么

教科书说「动态规划 = 分治 + 重叠子问题 + 记忆化」，这是把**问题**和
**解法**搅在一起的说法。把两者拆开，问题一侧只是：某些函数会被**反复**
在相同参数上采样。解法一侧只有一句话：

> 动态规划是一种让函数**反复采样变便宜**的技术——把采样结果缓存在一个
> 顺手的地方。

而「缓存」不是一种数据结构，是**一族**数据结构，取决于你打算怎么组织
键空间：

- 确定要采样整个定义域？那就一整张表，全填上。
- 采样很贵、且只会用到一小部分？那就逐格缓存，用到才填。
- 键空间是多个维度拼起来的？那就按维度组合缓存。

所以「记忆化策略」本身必须先被**描述**成一个值，再从这个值**生成**缓存
数据结构。这就是全章的两步走：45.2 用一个小归纳类型 `Shape` 描述策略，
45.3 用 `Shape` 索引出缓存类型 `Trie` 并把「这个 Trie 确实在记忆 f」
做成证明类型 `Memoizes`。

在动手之前，先补一块 23 章留下的理论地基——**函数空间是指数运算**。

## 45.2 地基：函数空间即指数（⇒-fin）

23 章 23.7 节证了 `Bool → A ≅ A × A`，那是 `m^n` 在 `n = 1` 处的特例。
一般定律是：

> `(Fin n → Fin m)` 恰好有 `m ^ n` 个元素。

这条定律是记忆化的全部理论依据：定义域同构于 `Fin n` 的函数，**就是**
长度为 n 的查找表（23.3 的 `vec-iso`：`Vec A n ≅ Fin n → A`）。「把函数
变成表」不是编程技巧，是同构的翻译。

先复刻 23 章的同构记录与「有 n 个元素」谓词（23 章全文讲过，这里直接
引用结论）：

```agda
record _≅_ {a b : Level} (A : Set a) (B : Set b) : Set (a ⊔ b) where
  field
    to      : A → B
    from    : B → A
    from∘to : ∀ x → from (to x) ≡ x
    to∘from : ∀ y → to (from y) ≡ y
infix 0 _≅_
open _≅_ public

infix 4 _Has_
_Has_ : ∀ {a : Level} → Set a → ℕ → Set a
A Has n = A ≅ Fin n
```

`⊎-has` / `×-has`（和/积保基数）在 23 章是 `⊎-has`/`×-has` 的逐字复刻，
正逆函数就是 stdlib 的 `join`/`splitAt` 与 `combine`/`remQuot`，往返律
`splitAt-join`/`join-splitAt`/`remQuot-combine`/`combine-remQuot` 全部来自
`Data.Fin.Properties`。23 章已经逐行讲过，本章源码里它们原样复用，不再
重复展开——**但有一处 2.9.0 实测的新坑要记**：`remQuot` 的第一个隐参
（乘积的第一个因子）必须手写钉住，否则 Agda 会去反转 `_*_`，反转深度
耗尽（`InversionDepthReached` 警告 + 元变量悬空报错）。钉法：

```agda
  from′ f = from i (proj₁ (remQuot {m} n f)) , from j (proj₂ (remQuot {m} n f))
```

以及往返链的收口处：

```agda
    uncurry combine (remQuot {m} n f) ≡⟨ combine-remQuot {n = m} n f ⟩
    f                             ∎
```

（`combine-remQuot` 的隐参名叫 `{n}` 而 `remQuot` 的叫 `{m}`，两边不同名，
23 章 23.5 的实录坑在这里又踩了一次。）

**⇒-fin 本体**：对 n 归纳。底步 `m ^ 0 = 1`：`Fin 0 → Fin m` 是空域函数，
只有一个（空域函数都相等，由 `funExt` + 空模式给出），对应 `Fin 1` 的
唯一元素：

```agda
⇒-fin : ∀ m n → (Fin n → Fin m) Has (m ^ n)
⇒-fin m zero = record
  { to      = λ _ → Data.Fin.zero
  ; from    = λ _ ()
  ; from∘to = λ f → funExt λ ()
  ; to∘from = λ { Data.Fin.zero → refl }   -- Fin 1 只有一个元素：pattern 穷尽
  }
```

注意两个细节。其一，`Data.Fin.zero` 必须限定模块名——`ℕ` 的 `zero` 与
`Fin` 的 `zero` 同名同时进作用域，裸写 `zero` 会被解析成 ℕ 的那个，报错
`ℕ is not a subtype of Fin (m ^ zero)`。这个「同名构造子撞车」在本章
**反复**出现（45.7 的清单里有总账）。其二，`to∘from` 对 `Fin 1` 的
模式匹配只有一个分支 `Data.Fin.zero` 就穷尽——`Fin 1` 只有这一个值，
Agda 自己数得清（06 章 absurd pattern 的正面版）。

归纳步 `m ^ (suc n) = m · m ^ n`，翻译成查表语言就是「函数 ⇔ （首项 ,
尾部函数）」——这正是 23 章 `vec-cons≅`（`Vec A (suc n) ≅ A × Vec A n`）
的 Fin 版：

```agda
⇒-fin m (suc n) = record
  { to      = to′
  ; from    = from′
  ; from∘to = ft
  ; to∘from = tf
  }
  where
  open import Data.Nat using (_^_)
  open import Data.Fin using (combine; remQuot)
  open import Data.Fin.Properties using (remQuot-combine; combine-remQuot)
  to′ : (Fin (suc n) → Fin m) → Fin (m ^ suc n)
  to′ f = combine (f Data.Fin.zero) (to (⇒-fin m n) (f ∘ Data.Fin.suc))
  from′ : Fin (m ^ suc n) → (Fin (suc n) → Fin m)
  from′ p Data.Fin.zero    = proj₁ (remQuot {m} (m ^ n) p)
  from′ p (Data.Fin.suc i) = from (⇒-fin m n) (proj₂ (remQuot {m} (m ^ n) p)) i
```

`to′` 把函数拆成「`zero` 处的值」与「尾部函数」的积；`from′` 用
`remQuot`（`Fin (m · k)` 的商余分解）把它装回去。往返证明 `ft`/`tf`
各有一个 2.9.0 实测坑，都记在 45.7 清单里，这里只点名字：
`from′∘combine`（`rewrite` 找不到藏在 `remQuot` 复合里的子项，改走
`cong` 推进）与 `tf` 里 `remQuot {m}` 的手写钉参。

## 45.3 形状即策略：Shape

现在回到记忆化。策略的**描述**是一个普通归纳类型，三种积木：

```agda
data Shape : Set where
  num    : ℕ → Shape
  beside : Shape → Shape → Shape
  inside : Shape → Shape → Shape
```

- `num n`：一张 n 格表。语义是**整表缓存**——只要有一格被用到，整张表
  就会被填满。适合确定要采样整个定义域的场合。
- `beside s t`：两个缓存并排。键先判别左右，再进对应子缓存。
- `inside s t`：**缓存的缓存**。语义是**逐格缓存**——外层的每格先空着
  （空指针），用到哪格才填哪格。适合采样贵、且只会用到一小部分的场合。

三种积木已经能拼出任意「trie」。二叉树是每层并置两份：

```agda
bintrie : ℕ → Shape
bintrie zero    = num 1
bintrie (suc n) = beside (bintrie n) (bintrie n)
```

也可以随手捏个怪形状（后面 45.5 用它做演示）：

```agda
weird : Shape
weird = beside (beside (num 3) (inside (num 2) (num 1)))
               (inside (num 3) (num 1))
```

`Shape` 只是策略的**名字**。下一步是按名字生成数据结构、键类型、键数量，
三样东西全部由 `Shape` 计算出来。

## 45.4 按图施工：Trie / Ix / ∣_∣

**缓存数据结构**——`Trie` 由 `Shape` 索引（10 章索引类型、24 章「形状进
类型」的正面用法）：

```agda
data Trie (B : Set ℓ) : Shape → Set ℓ where
  empty : {sh : Shape} → Trie B sh
  table : {n : ℕ} → Vec B n → Trie B (num n)
  both  : {m n : Shape} → Trie B m → Trie B n → Trie B (beside m n)
  nest  : {m n : Shape} → Trie (Trie B n) m → Trie B (inside m n)
```

四个构造子对应四种情形。`empty` 表示「还没填任何东西」，任何形状都可以
空。`table`/`both`/`nest` 对应 `Shape` 的三个积木。注意 `nest` 的递归
参数类型是 `Trie (Trie B n) m`——**参数自己变了**（非规则递归，19 章
Braun 树之后又一次见到）：`inside` 的语义就是「不再缓存值，而是缓存
值的缓存」。

**键类型**——每个形状配套一个查找键类型，也是按形状计算的函数：

```agda
Ix : Shape → Set
Ix (num n)       = Fin n
Ix (beside m n)  = Ix m ⊎ Ix n
Ix (inside m n)  = Ix m × Ix n
```

表用 `Fin n` 做下标（18 章）；并置用判别和 `⊎`（先判左右）；嵌套用积
`×`（外层键 + 内层键）。键类型就是「多维数组下标」的类型级翻译。

**键数量**——形状的基数，把 23 章的类型代数变成缓存大小的算术：

```agda
∣_∣ : Shape → ℕ
∣ num m ∣      = m
∣ beside m n ∣ = ∣ m ∣ + ∣ n ∣
∣ inside m n ∣ = ∣ m ∣ * ∣ n ∣
```

**每个形状的键类型恰好有 ∣ sh ∣ 个元素**——这条引理把 `Shape` 接回
23 章的基数机器，归纳直接组装：

```agda
fin0-has0 : Fin 0 Has 0
fin0-has0 = record
  { to = λ ()
  ; from = λ ()
  ; from∘to = λ ()
  ; to∘from = λ () }

shape-fin : (sh : Shape) → Ix sh Has ∣ sh ∣
shape-fin (num zero)    = fin0-has0
shape-fin (num (suc n)) = ≅-refl
shape-fin (beside m n)  = ⊎-has (shape-fin m) (shape-fin n)
shape-fin (inside m n)  = ×-has (shape-fin m) (shape-fin n)
```

`fin0-has0` 的四个字段全是荒谬模式：`Fin 0` 没有构造子（它的两个构造子
都带 `suc` 索引），`Fin 0 → ⊥` 级别的空类型，往返律空泛成立（14 章
`⊥-unique` 的亲戚）。`num (suc n)` 是自同构，`≅-refl` 一行收工。

**键相等可判定**——45.6 的 `replace` 需要比较键是否相等。借道
`shape-fin` 把键搬进 `Fin`，用 stdlib 的 `_≡?_`，再把结果搬回来：

```agda
Ix-dec : {sh : Shape} → (ix₁ ix₂ : Ix sh) → Dec (ix₁ ≡ ix₂)
Ix-dec {sh = sh} ix₁ ix₂
  = let s = shape-fin sh
    in map′
       (λ toix₁≡toix₂ → begin
          ix₁                ≡⟨ sym (from∘to s ix₁) ⟩
          from s (to s ix₁)  ≡⟨ cong (from s) toix₁≡toix₂ ⟩
          from s (to s ix₂)  ≡⟨ from∘to s ix₂ ⟩
          ix₂                ∎)
       (cong (to s))
       (to s ix₁ ≡? to s ix₂)
  where open ≡-Reasoning
```

**2.9.0 迁移坑（实测）**：原书（stdlib 1.7.2）用的是 `map-dec`，它在
1.7.2 标记 deprecated、2.0 已删除——stdlib 3.0 里 grep 不到这个名字。
正主是 `Relation.Nullary.Decidable` 的 `map′`（`Decidable/Core.agda`
第 203 行），签名 `(A → B) → (B → A) → Dec A → Dec B`，两个方向都要给
（`Dec` 的 yes/no 两支各用一个）。同理 `Data.Fin` 的 `_≟_` 在 3.0 里
改名 `_≡?_`（旧名带 `WARNING_ON_USAGE`），且 `Data.Fin` 本体不再
re-export 它，要显式 `open Data.Fin.Properties`。

最后一个小工具：Σ 的第一个分量常能从第二个推出来（`B a` 的类型里藏着
`a`），这个构造子让 Agda 自己补：

```agda
-,_ : {A : Set ℓ} {a : A} {P : A → Set ℓ} → P a → Σ A P
-,_ {a = a} b = a , b
```

## 45.5 正确性进类型：Memoizes 谓词

到了全章的题眼。**不要先写缓存操作再补正确性证明**（那是 extrinsic，
24 章对比过两种路线的代价）——先把「这个 Trie 确实在记忆 f」做成一个
类型，让每次缓存操作**构造**这个类型的值，正确性由构造过程免费附带。

```agda
mutual
  MemoTrie : {B : Set ℓ} {sh : Shape} → (Ix sh → B) → Set ℓ
  MemoTrie {B = B} {sh = sh} f = Σ (Trie B sh) (Memoizes f)

  data Memoizes {B : Set ℓ} : {sh : Shape} → (f : Ix sh → B) → Trie B sh → Set ℓ where
    emptyM : {sh : Shape} {f : Ix sh → B} → Memoizes f empty
    tableM : {n : ℕ} {f : Ix (num n) → B} →
             Memoizes f (table (tabulate f))
    bothM  : {m n : Shape} {f : Ix (beside m n) → B} {t₁ : Trie B m} {t₂ : Trie B n} →
             Memoizes (f ∘ inj₁) t₁ →
             Memoizes (f ∘ inj₂) t₂ →
             Memoizes f (both t₁ t₂)
    nestM  : {m n : Shape} {f : Ix (inside m n) → B}
             (subf : (ix : Ix m) → Σ (Trie B n) (Memoizes (f ∘ (ix ,_)))) →
             Memoizes f (nest (proj₁ (to-trie {f = f} subf)))
```

`MemoTrie f` = 「一个 Trie」×「它确实在记忆 f 的证明」。`Memoizes` 的
索引有三个（函数 f、藏在 `Ix sh → B` 里的形状、Trie 值），**不能改成
参数**——每个构造子对形状的要求不同：`tableM` 只接受 `num n` 形状的
`table`，`bothM` 只接受 `beside` 的 `both`，参数化做不到这种「按构造子
换索引」。

四个构造子逐条读：

- `emptyM`：空 Trie 对**任何**函数都「空泛地」成立——它一个值都没存，
  当然没有任何一个值是错的。这是 14 章 vacuous truth 的正面用法。
- `tableM`：一张表正确，当且仅当它就是 `tabulate f`——逐格采样 f 造出
  来的那张表（`tabulate`/`lookup` 是 18 章的老朋友）。
- `bothM`：并置正确，当且仅当左右分别记忆 `f` 的 `inj₁`/`inj₂` 两半
  （`f ∘ inj₁` 是「先包左再喂 f」）。
- `nestM`：嵌套正确，当且仅当**每个外层键** `ix` 都对应一个正确记忆
  「f 固定外层键」`f ∘ (ix ,_)` 的子 Trie。`subf` 就是那个「逐键给
  子 Trie + 证明」的函数；`to-trie` 把它整体折成一棵 `nest`。

`to-trie` 和它们 mutual（07 章 mutual 递归的升级用法——这里连**类型**
都互相引用）：

```agda
  to-trie
    : {B : Set ℓ} {m n : Shape} {f : Ix (inside m n) → B}
    → (subf : (ix : Ix m) → Σ (Trie B n) (Memoizes (f ∘ (ix ,_))))
    → Σ (Trie (Trie B n) m) (Memoizes (proj₁ ∘ subf))
  to-trie {m = num _}    _    = -, tableM
  to-trie {m = beside _ _} subf
    with proj₂ (to-trie (subf ∘ inj₁)) , proj₂ (to-trie (subf ∘ inj₂))
  ... | mt₁ , mt₂ = -, bothM mt₁ mt₂
  to-trie {m = inside _ _} subf = -, nestM (λ i → to-trie λ j → subf (i , j))
```

读法：`to-trie` 按**外层**形状 `m` 分三种情形。外层是 `num`：所有子
Trie 合成一张整表，证明用 `tableM`。外层是 `beside`：递归折左右两支，
用 `bothM` 拼回。外层是 `inside`：继续往深处折一层，`nestM` 收口。
类型已经说清一切——实现只是按类型填空。

**2.9.0 实测坑（mutual 泛化）**：原书里 `to-trie` 的签名写的是
`MemoTrie (proj₁ ∘ subf)` 别名，在 2.6.3 能通过；2.9.0 里这会触发
mutual 块 telescopes 泛化的 `genTel` 推断失败（报错信息是一串
`Σ _C_1256 (_B_1253 (genTel = genTel))`）。**必须内联展开**成
`Σ (Trie (Trie B n) m) (Memoizes (proj₁ ∘ subf))`。注意展开时 Σ 的
第一个分量是 `Trie (Trie B n) m` 不是 `Trie B n`——`MemoTrie g` 的
值类型由 `g : Ix m → Trie B n` 推出是 `Trie B n`、形状是 `m`，所以
缓存类型是 `Trie (Trie B n) m`（缓存的缓存，正是 `nest` 的递归参数
类型）。写错成 `Trie B n` 会报
`n and m are not equal at type Shape`。

## 45.6 类型即规范：Agda 替我们合成唯一的 Trie

`Memoizes` 的索引精确到什么程度？精确到**完全约束缓存内容**。演示：
给一个「部分填充」的证明——左左填满、左右留空、右侧三个子表只填第
二个——能配出这个证明的 Trie 只有一棵：

```agda
dummy : (sh : Shape) → Ix sh → ℕ
dummy sh ix = toℕ (to (shape-fin sh) ix)

_ : Memoizes
    (dummy weird)
    (both (both (table (0 ∷ 1 ∷ 2 ∷ [])) empty)
          (nest (table (empty ∷ table (6 ∷ []) ∷ empty ∷ []))))
_ = bothM (bothM tableM emptyM)
          (nestM λ { Data.Fin.zero → -, emptyM
                   ; (Data.Fin.suc Data.Fin.zero) → -, tableM
                   ; (Data.Fin.suc (Data.Fin.suc Data.Fin.zero)) → -, emptyM
                   })
```

`dummy` 把键翻译成自然数（经 `shape-fin` 的同构走一圈再 `toℕ`），
这样表里的数字一眼能对上键。`weird` 的左半是
`beside (num 3) (inside (num 2) (num 1))`：`bothM tableM emptyM` 说
「左表填满（`tableM` 的类型强制它是 `tabulate (dummy …)`，即
`0 ∷ 1 ∷ 2 ∷ []`）、右半留空」。右半是 `inside (num 3) (num 1)`：
`nestM` 的 λ 对三个外层键逐一给证明：第 0 格空、第 1 格填
（`tableM` 强制值是 `6 ∷ []`——`dummy` 把键 `suc zero` 翻译成 6）、
第 2 格空。

反方向更惊人：在编辑器里把 Trie 挖成洞——

```agda
--   _ : Memoizes (dummy weird) {!!}
--   _ = bothM (bothM tableM emptyM)
--             (nestM λ { zero → -, emptyM ; (suc zero) → -, tableM ; ... })
```

——对 `{!!}` 按 `C-c C-s`（Solve），Agda 合成的**必然**是上面那棵。
类型精确到这个程度：证明项唯一确定了缓存的每一个格。（块里每行带 `--`
前缀：源码里这段就是注释——`build.sh` 要求零洞通过，上面显式写出的那棵
就是 Solve 的唯一产物。）

## 45.7 按需填充：replace 与 get′

现在写**查询**。Agda 没有 mutation，所以「更新缓存」实现为「返回填充后
的新缓存」。先写一个替换引理：把 `nestM` 的 `subf` 里的一支换掉——
键相等就换新证明，否则查旧表。`Ix-dec` 在这里第一次上岗（17/24 章的
`Dec` 剧本换布景）：

```agda
replace
  : {B : Set ℓ} {m n : Shape} {f : Ix (inside m n) → B}
  → {fst : Trie B n}
  → (x : Ix m)
  → Memoizes (f ∘ (x ,_)) fst
  → ((ix : Ix m) → MemoTrie (f ∘ (ix ,_)))
  → MemoTrie f
replace {f = f} x sub-mem subf
  = -, nestM (λ ix →
      case Ix-dec ix x of λ
        { (yes refl) → -, sub-mem
        ; (no _)     → subf ix
        })
  where -- case_of_ 必须层级多态：分支返回的 MemoTrie 活在 Set ℓ，
        -- 而 Agda.Builtin 自带的 case_of_ 只收 Set₀（2.9 实测坑）。
        case_of_ : {a b : Level} {A : Set a} {B : Set b} → A → (A → B) → B
        case x of f = f x
```

`yes refl` 分支：键就是 `x`，直接给新证明；`no _` 分支：键不是 `x`，
查旧表。`case_of_` 在这里必须**层级多态**——Agda.Builtin 自带的
`case_of_` 只收 `Set₀` 的参数，而分支返回的 `MemoTrie` 活在 `Set ℓ`，
2.9.0 实测报 `Set ℓ and Set are not equal`。本地重定义一个多态版即可。

主事件 `get′`：在「带证明的 Trie」里查键。命中就返回值；未命中就
**只**造出需要的那一格（惰性填充），顺手返回填充后的新 Trie：

```agda
get′ : {B : Set ℓ} {sh : Shape} {f : Ix sh → B} {t : Trie B sh} →
       Memoizes f t → (ix : Ix sh) → B × MemoTrie f
-- 空表：整表采样一次（全章唯一调用 f 的地方），取出要的那格。
get′ {sh = num x} {f = f} emptyM a =
  let t = tabulate f
  in lookup t a , table t , tableM
-- 空并置：递归一侧，另一侧留 empty。
get′ {sh = beside m n} emptyM (inj₁ x)
  with get′ emptyM x
... | b , t₁ , memo = b , both t₁ empty , bothM memo emptyM
get′ {sh = beside m n} emptyM (inj₂ y)
  with get′ emptyM y
... | b , t₂ , memo = b , both empty t₂ , bothM emptyM memo
-- 空嵌套：递归内层，再用 replace 装回外层的 x 支。
get′ {sh = inside m n} {f = f} emptyM (x , y)
  with get′ {f = f ∘ (x ,_)} emptyM y
... | b , _ , sub-mem = b , replace x sub-mem (λ ix → -, emptyM)
-- 已有表：直接查（f 早被采样过了）。
get′ {sh = num _} {t = table t} tableM a = lookup t a , table t , tableM
-- 已有并置：递归对应一侧，另一侧原样保留。
get′ {sh = beside m n} (bothM l r) (inj₁ x)
  with get′ l x
... | b , t₁ , memo = b , both t₁ _ , bothM memo r
get′ {sh = beside m n} (bothM l r) (inj₂ y)
  with get′ r y
... | b , t₂ , memo = b , both _ t₂ , bothM l memo
-- 已有嵌套：取出 x 支的子证明，递归，再 replace 装回。
get′ {sh = inside m n} (nestM subf) (x , y)
  with subf x
... | _ , sub-mem
  with get′ sub-mem y
... | b , _ , _ = b , replace x sub-mem subf
```

八个情形，两组对称。关键观察：

1. **全章只有 `num` 空表情形真正调用 `f`**（`tabulate f`）。其它所有
   情形都只是搬运、合并、替换已经记忆好的值。这就是「采样变便宜」的
   类型级实现。
2. 惰性填充：空并置只填查询那一侧、另一侧留 `empty`；空嵌套只填
   路径上的那一格。没有一次浪费的采样。
3. 书上有个脚注值得放大成正文：**最后一个情形忘了调用 `replace` 会
   直接导致类型检查不过**——因为返回类型要求整棵树都带 `Memoizes`
   证明，而 `get′ sub-mem y` 返回的新子 Trie 的证明对应的是更新后的
   子树，不装回 `subf` 就凑不出 `Memoizes f (nest …)`。类型逼着你在
   更新后维持「全树都被记忆」的全局不变式。这就是「正确性由构造
   附带」的实感。

正确性定理一句话：`get′` 取回的值逐点等于 `f` 自己。`_≗_` 是 20 章
的逐点相等（stdlib 的 `Relation.Binary.PropositionalEquality.Core` 第
43–46 行，不是 `Relation.Binary` 里的 setoid 版——后者作用域里还有
同名异物，2.9.0 实测从 PropositionalEquality 导入最干净）：

```agda
get′-is-fn : {B : Set ℓ} {sh : Shape} {f : Ix sh → B} {t : Trie B sh} →
             (mt : Memoizes f t) → (λ ix → proj₁ (get′ mt ix)) ≗ f
get′-is-fn {sh = num _} emptyM x = lookup∘tabulate _ x
get′-is-fn {sh = beside _ _} emptyM (inj₁ x) = get′-is-fn emptyM x
get′-is-fn {sh = beside _ _} emptyM (inj₂ y) = get′-is-fn emptyM y
get′-is-fn {sh = inside _ _} emptyM (x , y) = get′-is-fn emptyM y
get′-is-fn {sh = num _} tableM x = lookup∘tabulate _ x
get′-is-fn {sh = beside _ _} (bothM t₁ _) (inj₁ x) = get′-is-fn t₁ x
get′-is-fn {sh = beside _ _} (bothM _ t₂) (inj₂ y) = get′-is-fn t₂ y
get′-is-fn {sh = inside _ _} (nestM subf) (x , y) = get′-is-fn (proj₂ (subf x)) y
```

对证明项归纳：每个构造子一条，全部一行。表情形的两条用 stdlib 的
`lookup∘tabulate`（`Data.Vec.Properties` 第 1334 行，「查表 = 采样」
的正品定律；原书在手抄版里自己证了一遍，stdlib 3.0 直接白嫖）。

## 45.8 打包出厂：对用户隐藏 Ix

机器造好了，但用户手里是 `A → B`，不是 `Ix sh → B`。最后一层包装：
给用户一个 `A ≅ Ix sh` 的桥（由「A 的基数 = ∣ sh ∣」经 45.2 的机器
搭出），`f` 改写成 `Ix` 上的 `f′`：

```agda
module Memoizer {A : Set} {B : Set ℓ} (sh : Shape)
                (f : A → B)
                (sized : A Has ∣ sh ∣) where

  private
    A≅Ix : A ≅ Ix sh
    A≅Ix = ≅-trans sized (≅-sym (shape-fin sh))

    f′ : Ix sh → B
    f′ = f ∘ from A≅Ix

  Memoized : Set ℓ
  Memoized = MemoTrie f′

  -- 出厂接口：喂旧缓存 + 一个 A，吐（值 , 新缓存）。内部走 get′。
  get : Memoized → A → B × Memoized
  get (_ , memo) a = get′ memo (to A≅Ix a)

  -- 出厂正确性：get 取回的值就是 f a。
  get-is-fn : (mt : Memoized) → (a : A) → proj₁ (get mt a) ≡ f a
  get-is-fn (_ , memo) a = trans (get′-is-fn memo (to A≅Ix a))
                               (cong f (from∘to A≅Ix a))
```

`get-is-fn` 比书上的多一步：书里的 `get` 直接返回 `get′` 的结果，
正确性是 `get′-is-fn` 的直接推论；这里 `get′-is-fn` 先给
`f′ (to A≅Ix a) = f (from A≅Ix (to A≅Ix a))`，还要掐一次 `from∘to`
的往返（`cong f` 保 `≡`）才得到 `f a`。这一步是 23 章同构机器的标准
用法：**同构翻译函数，往返律翻译证明**。

## 45.9 跑一遍：斐波那契的按表记忆

实例化。形状 `num 45`（整表缓存），`A = Fin 45`，`f = fiboIx`：

```agda
fibo-shape : Shape
fibo-shape = num 45

{-# TERMINATING #-}
fiboIx : Fin 45 → ℕ
fiboIx Data.Fin.zero = 0
fiboIx (Data.Fin.suc Data.Fin.zero) = 1
fiboIx (Data.Fin.suc (Data.Fin.suc i)) =
  fiboIx (inject₁ (Data.Fin.suc i)) + fiboIx (inject₁ (inject₁ i))
  where open import Data.Fin using (inject₁)
```

三个实测坑挤在这一段，都值得展开：

1. **`{-# TERMINATING #-}`**：`i : Fin 43`，而 `fiboIx` 要 `Fin 45`，
   所以递归实参用 `inject₁`（stdlib 2.0 起 `inject+` 改名 `_↑ˡ_` 且带
   弃用警告，`inject₁` 是「抬一阶」的正主）把上界抬上去。`inject₁` 保
   `toℕ` 值不变（`toℕ-inject₁`），递归的键严格变小，终止性**事实上**
   成立——但 Agda 的终止检查器看不穿 `inject₁` 是「结构子项的抬界」，
   实测 `TerminationIssue`。只能手动放行。这是全教程第二个
   `TERMINATING`（第一个在 35 章），用它的门槛是：有 stdlib 正品定律
   背书「值在变小」。
2. **同名构造子撞车**：`Data.Fin.zero`/`Data.Fin.suc` 必须限定模块名，
   裸写会被解析成 ℕ 的同名构造子。本章从 45.2 的 `⇒-fin` 一路踩到
   这里。
3. **从 ℕ 造 Fin 45 的键**：`key n = inject≤ {m = suc n} (fromℕ n) pf`，
   其中 `pf : suc n ≤ 45` 由 25 章的实例搜索老手艺自动构造（`z≤n`/
   `s≤s` 注册成实例，Agda 逐层 unwrap，10 层 31 层都照拆）。这里有两个
   小坑：`inject≤` 的界证明是 dotted（irrelevant），**不会反向**把隐参
   `{m}` 钉成 `suc n`，必须手写（2.9.0 实测 `UnsolvedMetaVariables`）；
   而 `#_` 依赖 `True (n <? 45)` 可计算，对变量 `n` 是 stuck 项，根本
   不能在这个抽象层使用。

出厂与终检：

```agda
fibo-sized : Fin 45 Has ∣ fibo-shape ∣
fibo-sized = shape-fin fibo-shape

open module FibMemo = Memoizer fibo-shape fiboIx fibo-sized

run : ℕ × Memoized → ℕ
run (b0 , m0) =
  let m1 = proj₂ (get m0 (key 10))
      m2 = proj₂ (get m1 (key 20))
      b3 , _ = get m2 (key 30)
  in b0 + b3

_ : run (get (empty , emptyM) (key 7)) ≡ fibo 7 + fibo 30
_ = refl
```

`fibo-sized` 由 `shape-fin` 直接给出——`Fin 45` 有 45 个元素，这正是
45.2 全部机器的存在意义。`run` 从空缓存出发连查四键；终检用 `refl`
一步收工：`refl` 能过，说明两边**定义上**就是同一个自然数——记忆化
路径（建 Trie、查 Trie、惰性填充）与直接递归算出的值，连计算过程都
逐位相同。这就是「正确性由构造附带」的最终形态：不是「证明了两者
相等」，是**两者本来就是同一个东西**。

## 45.10 这章在全书里的位置

回看全章用到的零件：`Shape`/`Trie` 是 07/10/18/24 的归纳与索引；
`Ix`/`∣_∣` 是 23 的类型代数；`shape-fin`/`⇒-fin` 是 23 的基数机器；
`Memoizes` 是 14 的谓词 + 24 的 intrinsic 验证思路（把不变式做进
索引）；`Ix-dec` 是 17 的 Dec；`replace`/`get′` 是 06 的模式匹配 +
with 抽象；`get′-is-fn` 是 20 的逐点相等；`Memoizer` 是 09 的模块
参数化 + 23 的同构翻译；`key` 是 25 的实例搜索。45 章没有引入任何
新语言特性——它演示的是**把已知的特性组合成一台有实际计算意义的
机器**，这也是依赖类型编程的终点：类型不只是防错的篱笆，是可以
**生成**数据结构和**附带**正确性的机器。

## 45.11 坑位清单（实测）

1. **`map-dec` 已删除**：stdlib 1.7.2 deprecated、2.0 移除，3.0 全库
   grep 不到。用 `Relation.Nullary.Decidable` 的 `map′`（Core 第 203
   行），两个方向都要给。报错特征：跟着原书写 `map-dec` 报
   `Not in scope`。
2. **`Data.Fin` 的 `_≟_` 改名 `_≡?_`**：旧名在 3.0 带
   `WARNING_ON_USAGE`，且 `Data.Fin` 本体不再 re-export
   `Properties` 的内容——要显式 `open Data.Fin.Properties`。
3. **`remQuot`/`combine` 的隐参必须手写钉住**：不显式给 `{m}` 时，
   Agda 为解 `_m * k ≟ m * k` 去反转 `_*`，50 层反转深度耗尽
   （`InversionDepthReached` 警告 + 元变量悬空）。两处：`×-has` 的
   `from′`/`tf`，`⇒-fin` 的 `from′`/`tf`。
4. **`combine-remQuot` 与 `remQuot` 的隐参不同名**：前者叫 `{n}` 后者
   叫 `{m}`，钉的时候别抄串（23 章 23.5 实录坑的重演）。
5. **mutual 块里用类型别名会触发 genTel 推断失败**：`to-trie` 签名
   写 `MemoTrie (proj₁ ∘ subf)`（2.6.3 可过）在 2.9.0 报
   `Σ _C_1256 (_B_1253 (genTel = genTel))` 类型不匹配。内联展开成
   `Σ (Trie (Trie B n) m) (Memoizes (proj₁ ∘ subf))`；展开时注意值类型
   是 `Trie (Trie B n) m`（写错报 `n and m are not equal`）。
6. **`case_of_` 要层级多态**：Agda.Builtin 自带版只收 `Set₀`，分支
   返回 `Set ℓ` 的类型时报 `Set ℓ and Set are not equal`。本地重定义
   `case_of_ : {a b : Level} {A : Set a} {B : Set b} → A → (A → B) → B`。
7. **`rewrite` 找不到藏在 `remQuot`/`splitAt` 复合里的子项**：
   `from′ (combine a b)` 里 `remQuot-combine` 的 LHS 不是目标式的
   语法子项（藏在 `swap ∘ quotRem` 的复合里），`rewrite` 报
   `RewritesNothing`。改走 `cong` 推进（45.2 的 `from′∘combine`），
   或先 `cong (to′ ∘ from′) (sym (join-splitAt …))` 把自变量改写成
   `join` 形式让 `from′` 可归约（⊎-has 的 `tf`）。
8. **`to′ (from′ f)`  stuck 在模式匹配**：`to′` 若写成
   `to′ (x , y) = …`（对二元组模式匹配），`to′ (from′ f)` 里
   `from′ f` 是中项，`to′` 不归约。写成投影版
   `to′ p = combine (to i (proj₁ p)) (to j (proj₂ p))` 后，
   `proj₁ (from′ f)` 对「定义上就是二元组」的 `from′ f` 照样归约
   （11 章 stuckness 的正面用法）。
9. **ℕ 与 Fin 的同名构造子撞车**：`zero`/`suc` 裸写被解析成 ℕ 的，
   报 `ℕ is not a subtype of Fin …`。全章所有 Fin 模式与值都写
   `Data.Fin.zero`/`Data.Fin.suc`。
10. **`inject₁` 过不了终止检查**：递归实参 `inject₁ (inject₁ i)` 事实
    上严格变小（`toℕ-inject₁` 保值的定律背书），但检查器看不穿，
    报 `TerminationIssue`。用 `{-# TERMINATING #-}` 放行，门槛是
    「有正品定律背书值在变小」。
11. **`inject≤` 的隐参 `{m}` 要手写**：界证明是 dotted（irrelevant），
    不反向钉参，报 `UnsolvedMetaVariables`。`#_` 在抽象层不可用
    （`True (n <? m)` 对变量 stuck）。
12. **`≅` record 的字段不自动进作用域**：`open _≅_ public` 补一行
    （23 章实录坑的重演）。

---

上一章：[44 · macOS 校验与 2.3→3.0 迁移](44-macos-checklist.md) ｜ 下一章：[46 · Kripke 语义与可靠性定理：给直觉主义逻辑一个「真值」](46-ppil-kripke.md) ｜ 返回：[README](../README.md)
