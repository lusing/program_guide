# 31 · 类型层计算与证明反射

> **第五部分 · 机制、效应与反射（25–32）** ｜ 全书结构与阅读路线见 [README](../README.md)

11 章我们让程序「算值」（规范化），15 章起让程序「算证明」。这一章把计算搬到
**类型层面**：让类型自己算出来（`Sign n`、格式化打印的类型、
`fmt-类型 ≡ ℕ → String → String → String → String`），再往前一步——
**证明反射**（proof by reflection）：把「要证的式子」反射成一枚数据
类型，写一个化简器和一个保语义解释器，于是一整族等式定理塌缩成
**一次计算 + 一行调用**。这是 Stump 书第 7 章的全部内容，也是 42 章
ring solver、30 章 `quote` 背后共同的原型：所谓「自动证明」，不过是
有人先把小语言的保语义定理证完了。

对应示例：`../examples/Ex31_typelevel_reflection.agda`

**实测口径**（02 章）：本章报错文本均为 **Agda 2.9.0 + stdlib 3.0** 实测原样粘贴（复现用的临时
探针 `examples/TmpProbe43*.agda` 已删除，报错路径按仓库根相对显示）；
代码片段与示例文件一致。书中针对 Agda 2.2.x 的写法全部重写并逐一验证。

## 31.1 类型层整数：零没有符号

前面各章的函数都住在 `Set`：吃值，吐值。类型层计算吃**值**，吐
**类型**——它仍是普通函数，只是 codomain 是某个宇宙：

```agda
data J : Set where
  triv : J

Sign : ℕ → Set
Sign zero    = J
Sign (suc _) = Bool
```

`Sign` 是个普通递归函数，只不过 `Sign 0` 算出来是类型 `J`，
`Sign 3` 算出来是类型 `Bool`。整数就靠它造（Stump 7.1 的 `Z`）：

```agda
data ℤt : Set where
  mkZ : (n : ℕ) → Sign n → ℤt
```

看仔细：第二个参数的**类型由第一个参数的值决定**。幅度为 0 时符号位
必须是 `J`（唯一居民 `triv`，等于没有信息）；幅度非零时才是 `Bool`。
这就是书名那句 "zero has no sign" 的 Agda 表达：

```agda
0Z  = mkZ zero triv                  -- 零：符号位只能交 triv
1Z  = mkZ (suc zero) true            -- 正一
-1Z = mkZ (suc zero) false           -- 负一
3Z  = mkZ 3 true                     -- 数字字面量照常可用
```

给错符号位，类型检查当场拒收。给非零挂「无符号」：

```agda
badZ₁ : ℤt
badZ₁ = mkZ 3 triv
```

```text
examples/TmpProbe43j1.agda:9.15-19: error: [UnequalTypes]
The type
  J
is not a subtype of
  Agda.Builtin.Bool.Bool
when checking that the expression triv has type Sign 3
```

反过来给零挂 Bool 符号，同样碰壁：

```text
examples/TmpProbe43j2.agda:9.18-22: error: [UnequalTypes]
The type
  Data.Bool.Bool
is not a subtype of
  J
when checking that the expression true has type Sign zero
```

报错里的类型都**算了**：`Sign 3` 已归约成 `Bool`、`Sign zero` 已归约
成 `J`——这就是「类型层计算」四个字的字面意思。

**2.2.x 老写法已死**。书中原文是
`mkZ : n : N → Z-pos-t n → Z`（参数绑定不带括号，Haskell f :: a -> b -> c
时代 Agda 的野生语法）。今天照抄是语法错误：

```text
examples/TmpProbe43a.agda:17.11: error: [ParseError]
:<ERROR>  ℕ → Sign n → Z
...
```

现在每个参数必须 `(n : ℕ)` 成对括号。这个改动波及全书所有老例子，
44 章迁移清单里也记过一笔。

算术照常造。`_Z+_` 六条子句，同号直加、异号走差函数 `diffN`；
`diffN` 用纯结构递归逐层销掉公共的 `suc`（Stump 当年要靠三岐判定
`<⊍suc` 加 Σ 证明来喂终止检查，2.9 的依赖模式让四条子句直接通过）：

```agda
diffN : (n m : ℕ) → ℤt
diffN zero    zero    = mkZ zero triv
diffN zero    (suc m) = mkZ (suc m) false
diffN (suc n) zero    = mkZ (suc n) true
diffN (suc n) (suc m) = diffN n m
```

于是 `1 + (-1) ≡ 0` 不需要任何证明技巧——**算出来**的：

```agda
+Z-1 : 1Z Z+ -1Z ≡ 0Z
+Z-1 = refl
```

`refl` 背后是编译器的符号执行：`mkZ 1 true Z+ mkZ 1 false` 命中第五条
子句 → `diffN zero zero` → `mkZ zero triv` → 与 `0Z` 同形。15 章为
`n + 0 ≡ n` 归纳半天的东西，这里闭项算平（开区间仍要归纳，见 31.2）。

## 31.2 ≤Z 与反对称性：唯一表示的回报

序判定七条子句，符号位一手包办（Stump 7.1.3）：

```agda
_≤Z_ : ℤt → ℤt → Bool
mkZ zero _        ≤Z mkZ zero _          = true
mkZ zero _        ≤Z mkZ (suc _) pos     = pos
mkZ (suc _) pos   ≤Z mkZ zero _          = not pos
mkZ (suc x) true  ≤Z mkZ (suc y) true    = x ≤ᵇ y
mkZ (suc x) true  ≤Z mkZ (suc y) false   = false
mkZ (suc x) false ≤Z mkZ (suc y) true    = true
mkZ (suc x) false ≤Z mkZ (suc y) false   = y ≤ᵇ x
```

（右侧两条 `x ≤ᵇ y` 若写成 `x ≤ᵇ y ≡ true` 不括号会直接
`NoParseForApplication`，见 31.7 坑 10。）

本章第一个像样的定理：`≤Z` 反对称。若零有正负两副面孔
（符号位一律 `Bool`），`0⁺ ≤Z 0⁻` 与 `0⁻ ≤Z 0⁺` 同真而 `0⁺ ≢ 0⁻`，
这条从定义上就断了。「零无符号」的全部投资在这里分红：

```agda
ᵇ≡true⇒T : (b : Bool) → b ≡ true → T b
ᵇ≡true⇒T true  _ = tt
ᵇ≡true⇒T false ()

≤ᵇ-antisym : ∀ a b → (a ≤ᵇ b) ≡ true → (b ≤ᵇ a) ≡ true → a ≡ b
≤ᵇ-antisym a b h₁ h₂ =
  ≤-antisym (≤ᵇ⇒≤ a b (ᵇ≡true⇒T _ h₁)) (≤ᵇ⇒≤ b a (ᵇ≡true⇒T _ h₂))

≤Z-antisym : ∀ x y → (x ≤Z y) ≡ true → (y ≤Z x) ≡ true → x ≡ y
```

`≤Z-antisym` 九条子句：混合符号/零的六条靠**荒谬模式** `()` 一笔带过
——`mkZ (suc a) true` 与 `mkZ (suc b) false` 之间 `≤Z` 直接返回
`false`，假设 `(_ ≤Z _) ≡ true` 与 refl 的形不成，Agda 接受 `()`。
同号两条 `rewrite ≤ᵇ-antisym …` 收尾。`ᵇ≡true⇒T` 是 17 章
`Reflects`/`T?` 的手搓替身：把 Bool 世界的判定账搬进命题世界。

## 31.3 Setω：把「类型」降维成数据

想把「类型」本身当数据存进 datatype（书中「类型转换」技巧的骨架），
`Set` 不够高。5 章的宇宙账重算一遍：`Set : Set₁`，构造子 `bad : Set → Bad`
的参量住在 `Set₁`，塞不进 `Set` 层的 datatype：

```text
examples/TmpProbe43e.agda:10.3-6: error: [ConstructorDoesNotFitInData]
Constructor bad
of inferred sort Set₁
does not fit into data type of sort Set.
(Reason: Set₁ is not less or equal than Set)
when checking that the type Set of an argument to the constructor
bad fits in the sort Set of the datatype.
```

上界宇宙 `Setω`（5 章见过一面）才装得下「类型的代码」：

```agda
data Ty : Setω where
  ℕ̂C     : Ty
  Bool̂C  : Ty
  Unit̂C  : Ty
  StrinĝC : Ty
  List̂C  : Ty → Ty

⟦_⟧ᵗ : Ty → Set
⟦ ℕ̂C ⟧ᵗ      = ℕ
⟦ Bool̂C ⟧ᵗ   = Bool
⟦ Unit̂C ⟧ᵗ   = ⊤
⟦ StrinĝC ⟧ᵗ = String
⟦ List̂C t ⟧ᵗ = List ⟦ t ⟧ᵗ
```

`Ty` 是「类型这个语言」的**语法**，`⟦_⟧ᵗ` 是它的**语义**——31.5 证明
反射的整套词汇，这里已经预热。有了代码层，`Sign` 可以并排写一个
代码版 `signTy : ℕ → Ty`（`zero → Unit̂C`，`suc _ → Bool̂C`），再用
`toSign`/`fromSign` 在两界之间搬运，`roundTrip` 双向可逆全是 `refl`。
类型等式也能算着证（这命题自己住在 `Set₁`）：

```agda
_ : Sign 5 ≡ Bool
_ = refl

_ : ⟦ signTy (2 + 3) ⟧ᵗ ≡ Sign (2 + 3)
_ = refl
```

变量情形立刻现形：`bad : (n : ℕ) → ⟦ signTy n ⟧ᵗ ≡ Sign n` 交 `refl`
被拒——

```text
examples/TmpProbe43i.agda:9.9-13: error: [UnequalTerms]
The terms
  ⟦ signTy n ⟧ᵗ
and
  Sign n
are not equal at type Set
when checking that the expression refl has type
⟦ signTy n ⟧ᵗ ≡ Sign n
```

两侧都卡在「`n` 还没给值」上：`signTy n` 与 `Sign n` 是两枚不同的
卡住正规式，哪怕函数外延上逐点相等。修法是把 `n` 拆开放进量词
（示例里 `toSign`/`roundTrip` 就是这么写的）——**类型层计算对变量
惰性**，想「看」`Sign n` 只能先对 `n` 模式匹配（示例中的 `peek`）。

宇宙账的最后一笔：`Setω` 是上界，但**不自我包含**——`Setω : Setω₁`
（Agda 里 `Setω` 的下一个字面量宇宙要手动写 `Setω₁`，`open import
Agda.Primitive` 并不送）。照 5 章习惯写 `Bad₂ : Setω; Bad₂ = Setω`：

```text
examples/TmpProbe43e2.agda:25.8-12: error: [UnequalTypes]
The types
  Setω₁
and
  Setω
are not equal
when checking that the expression Setω has type Setω
```

Girard 悖论没有免费午餐，`Setω` 只保证「下面所有 `Setₗ` 都装得下」。

**老 pragma 补一刀**：书中 7.1 用 `{-# OPTIONS --type-level #-}` 和
`{-# TYPE-LEVEL #-}` 标注类型层函数。2.9 里两个都已作古（当年那套
「类型层子语言」的终止性检查方案被统一进今天的终止检查器了）：

```text
examples/TmpProbe43d1.agda:1.1-29: error: [OptionError]
Unrecognized option: --type-level (did you mean --two-level ?)
```

```text
examples/TmpProbe43d.agda:11.5: error: [ParseError]
TYPE-LEVEL<ERROR>  #-}
...
```

好消息：什么 pragma 都不加，`Sign`、`format-th`（下一节）今天照样在
类型位置算——不需要许可证。

## 31.4 格式化打印：失败尝试与可用解

28 章说过：stdlib 的 `Data.String` 没有 printf。手写一条
`format "%n% of the %ss are in the %s %s" 25 "dog" "toasty" "doghouse"`
想要**类型安全**（`%n` 吃 `ℕ`、`%s` 吃 `String`、吃几个由串决定），
Stump 7.2.1 的第一直觉是：把返回类型直接从格式串**算**出来。2.9 重写：

```agda
format-th : List Char → Set
format-th ('%' ∷ 'n' ∷ f) = ℕ → format-th f
format-th ('%' ∷ 's' ∷ f) = String → format-th f
format-th (c ∷ f)         = format-th f
format-th []              = String
```

然后 handler 逐字符消费，跳过普通字符：

```agda
format-h : List Char → (f : List Char) → format-th f
format-h s ('%' ∷ 'n' ∷ f) = λ n → format-h (s ++ toList (show n)) f
format-h s ('%' ∷ 's' ∷ f) = λ s′ → format-h (s ++ toList s′) f
format-h s (c ∷ f)         = format-h s f     -- ← 第三条卡死
format-h s []              = fromList s
```

实测（探针 TmpProbe43c），报错指回第三条子句的返回类型：

```text
examples/TmpProbe43c.agda:22.30-42: error: [UnequalTerms]
The terms
  f
and
  c ∷ f
are not equal at type List Char
when checking that the expression format-h s f has type
format-th (c ∷ f)
```

死因值得抄下来：**`format-th (c ∷ f)` 归约到一半卡住**。`c` 是变量，
Agda 的部分求值只会机械地试模式——第一条要 `c ≡ '%'`、第二条要
`c ≡ 'n'`，都算不出来；它**不记得**「前两条已经匹配失败所以只能落
默认子句」这笔账（何况这里连默认子句都还没轮到）。于是
`format-th (c ∷ f)` 是正规式却对不上 `format-th f`，类型检查拒绝。
这跟 31.3 末尾「变量卡住」是同一课：**类型层的计算只对闭项慷慨**。

Stump 的解法（7.2.2），也正是本章标题的第一次落地——**反射**：
别拿 `List Char` 硬算类型，先把格式串反射成专门的中间表示，
类型只在**构造子**手上算（构造子模式永远算得动，没有「上一条没中」
的糊涂账）：

```agda
data Fmt : Set where
  FmtNat : Fmt → Fmt
  FmtStr : Fmt → Fmt
  FmtChr : Char → Fmt → Fmt
  FmtEnd : Fmt

⟦_⟧ᶠ : Fmt → Set
⟦ FmtNat v ⟧ᶠ   = ℕ → ⟦ v ⟧ᶠ
⟦ FmtStr v ⟧ᶠ   = String → ⟦ v ⟧ᶠ
⟦ FmtChr _ v ⟧ᶠ = ⟦ v ⟧ᶠ
⟦ FmtEnd ⟧ᶠ     = String
```

`cover : List Char → Fmt` 负责解析。注意：**值层**的默认模式毫无反
对意见——`cover (c ∷ s) = FmtChr c (cover s)` 产出的是数据不是类型。
当年卡死的写法，换到值层就是合法公民：

```agda
cover ('%' ∷ 'n' ∷ s) = FmtNat (cover s)
cover ('%' ∷ 's' ∷ s) = FmtStr (cover s)
cover (c ∷ s)         = FmtChr c (cover s)
cover []              = FmtEnd

format : (f : String) → ⟦ cover (toList f) ⟧ᶠ
format f = fmtH "" (cover (toList f))
```

类型算对了，值也算对了，全部 `refl`（孤立的 `%` 当普通字符，正是
书中这个例句的机关）：

```agda
_ : ⟦ cover (toList "%n% of the %ss are in the %s %s") ⟧ᶠ
      ≡ (ℕ → String → String → String → String)
_ = refl

_ : format "%n% of the %ss are in the %s %s" 25 "dog" "toasty" "doghouse"
      ≡ "25% of the dogs are in the toasty doghouse"
_ = refl
```

对照 28 章：stdlib 只有 `show`/`_++_`/`toList`/`fromList` 这些零件，
本节的 `Fmt` 是**自造小语言**——同一手法，28 章拼字符串是死算，
这里格式串的类型是算出来的。`render`（语义函数的反向）+ `rt` 还能
证明 `cover` 在规范串上可逆：`render (cover (toList "%n cats")) ≡ "%n cats"`
也是 `refl`。

## 31.5 证明的反射：把一整族引理压成一次计算

重头戏。15/16 章我们为列表代数手写了多少条归纳：`map` 分配 `++`、
`map ∘ map` 合并、`++` 重结合……每条都要想不变量、挑归纳变量。
Stump 7.3 的野心：**这些全是同一一定理的实例**——

> 对任意列表表达式 `e`，化简器 `simpl` 保语义：`⟦ e ⟧ ≡ ⟦ simpl e ⟧`。

目标形状（示例「分配律」模块，对应 Stump 的 `test2`）：

```agda
分配 : map f ((l₁ ++ l₂) ++ l₃) ≡ map f l₁ ++ (map f l₂ ++ map f l₃)
分配 = simpl-sound lhs 3
```

一行：造表达式、算 3 步、保语义定理点收。下面从语法、语义、化简、
保语义四步搭起来。

**第一步：语法（反射出的数据类型）**。表达式不再是 Agda 项，而是
`Expr` 的构造子树：

```agda
data Expr : Set → Set₁ where
  lit   : ∀ {A : Set} → List A → Expr A
  _++ᵣ_ : ∀ {A : Set} → Expr A → Expr A → Expr A
  mapᵣ  : ∀ {A B : Set} → (A → B) → Expr A → Expr B
  _∷ᵣ_  : ∀ {A : Set} → A → Expr A → Expr A
  nilᵣ  : ∀ {A : Set} → Expr A
```

照抄书中层级 `data Lr : Set → Set` 是装不下的——构造子里 `∀ {A : Set}`
把 `Set` 本身吃了进去，参量 inferred sort 是 `Set₁`：

```text
examples/TmpProbe43b.agda:8.3-6: error: [ConstructorDoesNotFitInData]
Constructor [_]
of inferred sort Set₁
does not fit into data type of sort Set.
(Reason: Set₁ is not less or equal than Set)
when checking that the type Set of an argument to the constructor
[_] fits in the sort Set of the datatype.
Note: this argument is forced by the indices of [_], so this
definition would be allowed under --large-indices.
```

老老实实 `Set → Set₁`（31.3 的宇宙账，这次债主是自己的 datatype）。
`lit` 把真实列表整个嵌进来当**不可拆的原子**——它是「变量/常量」，
化简器对 `l` 内部永远不看，这正是反射证明只对**表达式形状**成立的
体现。

**第二步：语义**。`⟦_⟧ : Expr A → List A` 把语法翻回真值（五条子句
一一展开 `++`/`map`/`∷`/`[]`）。为什么要绕这一圈？因为**只有对
数据才能模式匹配复合形状**。`(t₁ ++ t₂) ++ t₃ → …` 这种规则在 Agda
的函数定义里对着真列表写不出来——`++` 不是构造子；对 `Expr` 写则
是普通模式匹配。反射换来的就是这个视力。

**第三步：化简器**。`simp-step` 是一张十三行的**规则表**（不递归）：
重结合、`∷` 提出、消灭 `nilᵣ`、分配 `mapᵣ`、合并 `mapᵣ ∘ mapᵣ`……
`is-nil? : Expr A → Bool`（Stump 的 `is-emptyr`）把「右侧是不是空表」
做成 Bool 判定。为什么绕 Bool 而不直接写模式 `lit l ++ᵣ nilᵣ`？
下一段有实测对照，先剧透：与 31.4 的 `format-th` 是同一笔糊涂账，
这次栽的是保语义证明。

递归组合子两个：`sdev`（superdevelopment，超展开：先化简子树再对
产物补一步）、`simpl zero t = t; simpl (suc k) t = sdev (simpl k t)`
——**迭代次数 N 由用户供给**。Stump 原话的抱怨到 2.9 依然成立：让
终止检查相信「化到不动点」的代码终止，花的功夫比化简本身还大；
把 N 变成显式参数是体面的逃生舱。

**第四步：保语义**。三件套引理，每条化简规则后面站一条 stdlib 引理：

```agda
simp-step-sound : ∀ {A : Set} (t : Expr A) → ⟦ t ⟧ ≡ ⟦ simp-step t ⟧
simp-step-sound ((t₁a ++ᵣ t₁b) ++ᵣ t₂) =
  ++-assoc ⟦ t₁a ⟧ ⟦ t₁b ⟧ ⟦ t₂ ⟧
simp-step-sound (lit l ++ᵣ nilᵣ)       = ++-identityʳ l
simp-step-sound (mapᵣ f (t₁ ++ᵣ t₂))   = map-++ f ⟦ t₁ ⟧ ⟦ t₂ ⟧
simp-step-sound (mapᵣ f (mapᵣ g t))    = sym (map-∘ {g = f} {f = g} ⟦ t ⟧)
simp-step-sound (mapᵣ f nilᵣ)          = refl
-- ……共二十二条子句

sdev-sound  : ∀ {A : Set} (t : Expr A) → ⟦ t ⟧ ≡ ⟦ sdev t ⟧
simpl-sound : ∀ {A : Set} (t : Expr A) (n : ℕ) → ⟦ t ⟧ ≡ ⟦ simpl n t ⟧
```

`sdev-sound` 对结构归纳：`cong₂ _++_` 把子树的 IH 拼进大语境，再
`trans` 接上顶层 `simp-step-sound`；`simpl-sound` 对 `n` 归纳。
两个小机关值得单记：**方向**——`simp-step` 把 `(a++b)++c` 变成
`a++(b++c)`，所以 `++-assoc`/`map-++` 直接给、不加 `sym`，唯一反过来
的是 `map-∘`（stdlib 陈述的是 `map (g ∘ f) ≗ map g ∘ map f`，我们的
规则方向要用 `sym`）；**隐式参数顺序**——`map-∘` 声明里 `{g}` 在
`{f}` 前头，按直觉写 `{f = g} {g = f}` 会炸（31.7 坑 9）。

`lit l ++ᵣ t₂` 这类规则的条件（「`t₂` 非空才保留 ++」）在
`simp-step` 里是 `if is-nil? t₂ then … else …`，但保语义证明里 Agda
不肯跟着这个 `if` 走。两条死路都实测了。其一，天真 catch-all：

```agda
bad₁ : ∀ {A : Set} (t : Expr A) → ⟦ t ⟧ ≡ ⟦ simp-step t ⟧
bad₁ (t₁ ++ᵣ t₂) = refl
```

```text
examples/TmpProbe43k.agda:8.20-24: error: [UnequalTerms]
The terms
  ⟦ t₁ ⟧ Data.List.Base.++ ⟦ t₂ ⟧
and
  ⟦ simp-step (t₁ ++ᵣ t₂) ⟧
are not equal at type Agda.Builtin.List.List A
when checking that the expression refl has type
⟦ t₁ ++ᵣ t₂ ⟧ ≡ ⟦ simp-step (t₁ ++ᵣ t₂) ⟧
```

`t₁` 未知，`simp-step` 整个卡住不归约——refl 看不见任何规则。其二，
用现成的 `is-nil?⇒nil`（`is-nil? t ≡ true → t ≡ nilᵣ`，四构造子枚举
加荒谬模式，本身是好练习）现场 `rewrite` 补账：

```text
examples/TmpProbe43l.agda:10.34-38: error: [UnequalTerms]
The terms
  is-nil? t₂
and
  Agda.Builtin.Bool.Bool.true
are not equal at type Agda.Builtin.Bool.Bool
when checking that the expression refl has type
is-nil? t₂ ≡ Agda.Builtin.Bool.Bool.true
```

`rewrite` 要的等式 `is-nil? t₂ ≡ true` 恰恰对一般 `t₂` 不成立——
「if 的 then 分支只在真时才走」这笔账，Agda 依旧不替你记。活路朴素
得近乎笨拙：在证明里把右子树按**五个构造子逐一枚举**
（`lit l ++ᵣ nilᵣ` 走 `++-identityʳ`，`lit l ++ᵣ lit l₂`、
`lit l ++ᵣ (t₁ ++ᵣ t₂)`、`lit l ++ᵣ (mapᵣ f t)`、`lit l ++ᵣ (x ∷ᵣ t)`
各自 `refl`——非 `nilᵣ` 时 `is-nil?` 每条都算得回 `false`，if 当场归约）。
二十二条子句换来规则表随便改而主定理不动，值。

**收获**。分配律模块（对应 Stump `ListSimpTest2`）：

```agda
module 分配律 {A : Set} (f : A → A) (l₁ l₂ l₃ : List A) where
  lhs : Expr A
  lhs = mapᵣ f ((lit l₁ ++ᵣ lit l₂) ++ᵣ lit l₃)

  一步 : simp-step lhs ≡ mapᵣ f (lit l₁ ++ᵣ lit l₂) ++ᵣ mapᵣ f (lit l₃)
  一步 = refl

  三次 : simpl 3 lhs ≡
         lit (map f l₁) ++ᵣ (lit (map f l₂) ++ᵣ lit (map f l₃))
  三次 = refl

  分配 : map f ((l₁ ++ l₂) ++ l₃) ≡ map f l₁ ++ (map f l₂ ++ map f l₃)
  分配 = simpl-sound lhs 3
```

`一步` 让你看清规则表的成色（一条 refl 的「单步录像」），`三次` 是
不动点，`分配` 才是正主：**定理本身是 `simpl-sound` 的一次类型实例
化**。N 少给一步都过不了——探针把等式右边留作 `simpl 2` 的不足：

```text
examples/TmpProbe43h.agda:12.20-24: error: [UnequalTerms]
The terms
  mapᵣ f (lit l₂)
and
  lit (map f l₂)
are not equal at type Expr A
when checking that the expression refl has type
simpl 2 (mapᵣ f ((lit l₁ ++ᵣ lit l₂) ++ᵣ lit l₃)) ≡
lit (map f l₁) ++ᵣ lit (map f l₂) ++ᵣ lit (map f l₃)
```

两次超展开还欠最后一层 `mapᵣ f (lit l₂)` 没算成 `lit`——迭代次数是
证明的一部分，报错报得明明白白。同一手法再赚一条
（`合并 : map f (map g l) ≡ map (f ∘ g) l`，`合并 = simp-step-sound lhs₂`，
连迭代都省了）。15 章的手感是「每条引理一次归纳」；这里是「规则表
证一次，实例白拿一吨」——编译器替你归纳。

**凭什么叫「反射」**：对象语言（列表表达式）的**语法**被搬进元语言的
**数据**（`Expr`），配一座语义桥 `⟦_⟧`，于是「关于表达式的事实」变成
「关于数据的计算」——对象层的问题在元层算，算完经语义桥搬回去。
30 章的 `quote` 是同一动作的全语言版：`Term` 是 Agda 自己语法的反射
数据类型。界限在此划清：`Term` 的语义是整个 Agda，**无法在 Agda 内
给出**（给得出就的统一难题 30 章领教过），所以那边只能配合 TCM 在
元程序里转悠；`Expr` 是我们自选的小语言，`⟦_⟧` 与保语义都是普通
程序，才谈得上 `simpl-sound` 这种「把证明当函数返回」。示例末尾留
了两界同框的纪念照：

```agda
真项 : Term
真项 = quoteTerm ((1 ∷ []) ++ (2 ∷ []))

打印 : String
打印 = showTerm 真项        -- 注意：showTerm 在 Reflection.AST.Show，不在 Reflection
```

`quoteTerm` 反射手写 Agda 项（30 章），`showTerm` 打印其语法树——但
没有人试图证明 `⟦ 真项 ⟧ ≡ …`：全语言的语义桥修不出来。我们的小
语言能证，恰恰因为「小」。

## 31.6 与教程既有章节对照

**17 章（Dec）**。本章两套「反射」的分工跟 Dec 的两个字段严丝合缝：
`cover`/`simp-step`/`is-nil?` 是 `does`（纯 Bool 算法，只管跑），
`⟦_⟧ᶠ`/`⟦_⟧` 加保语义引理是 `proof`（命题层，管跑得对不对）。
`Dec` 本身是带 η 的 record，示例里 `3≡3? : Dec (3 ≡ 3); 3≡3? = yes refl`
问候一下老朋友。**η 实验**（探针 TmpProbe43f）：默认 record 满足
`x ≡ record { val = val x }`（refl 即过，η 就是「字段同则对象同」的
计算律）；加一行 `no-eta-equality` 立刻翻脸：

```text
examples/TmpProbe43f.agda:28.13-17: error: [UnequalTerms]
The terms
  x
and
  record { val = valN x }
are not equal at type NoEta
when checking that the expression refl has type
x ≡ record { val = valN x }
```

`Dec`、`Σ`、`≡` 全都吃 η 才顺手；关掉它，等于把 13 章以来大量
「refl 白拿」的等式降级成手写同构。

**42 章（ring solver）**。`solve-∀` 就是把本章做到工业级：反射算术
表达式 → 规范形 → 判定相等 → 保语义定理现场实例化。示例最后一行
`环-交换 = solve-∀`（`Data.Nat.Tactic.RingSolver`，目标必须是
`∀ (x y : ℕ) → …` 的形状）。读完 31.5 再看 solver，它从魔法降格为
「有人替你写好的 `simpl-sound`」。差别只在体量：小语言 vs 整段
算术，规则表 vs 多项式规范形。

**05 章（宇宙）**。`Set → Set₁`（Expr）、`Setω`（Ty）两处升层都是
5 章账本的续借；`--large-indices` 提示（31.3/31.5 报错里都有 Note）
是「知道自己在干什么再开」的旁路。

**28 章（String）**。`toList`/`fromList`/`show`/`_++_` 是本章所有解析
的原材料；`Fmt` 一节顺便演示了「标准字符串没语法，自造 DSL 才有」。

## 31.7 坑位清单（实测）

1. **2.2.x 老 binder 语法**：`mkZ : n : ℕ → Sign n → ℤt` 今天直接
   `ParseError`（探针 43a）。所有参数都要 `(x : A)` 括号成对。
2. **`--type-level` / `{-# TYPE-LEVEL #-}` 均已移除**：前者
   `Unrecognized option: --type-level (did you mean --two-level ?)`
   （43d1），后者连 pragma 都解析不过（43d）。2.9 的类型层函数无
   需任何许可证。
3. **符号位严格匹配**：`mkZ 3 triv`、`mkZ zero true` 都是
   `UnequalTypes`（43j1/43j2）——这不是坑，是本章卖点；但报错会显示
   归约后的 `Sign 3`/`Sign zero`，读错方向会懵一下。
4. **类型当数据要 `Setω`**：`data Bad : Set where bad : Set → Bad`
   炸 `ConstructorDoesNotFitInData`（43e）；`Setω` 又不自我包含，
   `Setω : Setω₁`（43e2）。
5. **类型层计算对变量惰性**：`⟦ signTy n ⟧ᵗ ≡ Sign n` 的 refl 过不了
   （43i）；`format-th (c ∷ f)` 卡死（43c）。先模式匹配拆变量，或
   反射成中间表示（`Fmt`）再算。
6. **Expr 宇宙层级**：书原样 `Set → Set` 装不下带 `∀ {A : Set}` 的
   构造子，`Set → Set₁` 起步（43b）。报错 Note 推荐 `--large-indices`，
   别信它的邪——升层是正解。
7. **catch-all refl 卡死**：保语义证明里 `bad₁ (t₁ ++ᵣ t₂) = refl`
   时 `simp-step` 对未知左子树整体卡住（43k）。化简器规则一旦「依赖
   上一条模式没匹配」，证明侧必须把构造子枚举干净。
8. **`rewrite` 救不了 if**：拿 `is-nil?⇒nil t₂ refl` 现场补等式，
   `is-nil? t₂ ≡ true` 对一般 `t₂` 根本不成（43l）。条件规则要在
   证明里分真值/分构造子，没有免费通道。
9. **隐式参数按声明序给**：`map-∘` 的隐式是 `{g}` 在前 `{f}` 在后
   （stdlib 陈述 `map (g ∘ f) ≗ map g ∘ map f`），顺手写
   `{f = g} {g = f}` 会炸 `WrongHidingInApplication`（43m）——
   报错会把你已交的参数当成对着 `≗` 的显式参数硬套。
10. **≡ 与 ≤ᵇ/≤Z 同为 level 4 非结合**：`a ≤ᵇ b ≡ true` 不括号直接
    `Could not parse the application a ≤ᵇ b ≡ true`（43n）。等式假设
    一律写成 `(a ≤ᵇ b) ≡ true`。
11. **迭代次数是证据的一部分**：`simpl 2` 差一步到不动点，等式两侧
    不同形（43h）。报错会精确点出卡在 `mapᵣ f (lit l₂)`，照着加 N 即可。
12. **with 模式撞构造子名**：`with is-nil? t₂` 的分支若拿 `false` 当
    模式变量名，会吃一条
    `-W[no]PatternShadowsConstructor` 警告，且分支里的 `if false …`
    因构造子被遮蔽不再归约（开发示例时实测；正解是用完即弃的分支
    名或干脆按 31.5 枚举构造子）。
13. **`no-eta-equality` 断 refl 的等式**：record η 实测（43f）。默认
    别关，关了才知道 13 章以来的 `refl` 有多少是 η 白送的。
14. **`showTerm` 不住在 `Reflection`**：得 `open import
    Reflection.AST.Show using (showTerm)`；另外 `quoteTerm` 是内置语
    法，**不能**出现在 `import Reflection using (…; quoteTerm)` 里
    （30 章同款 ParseError）。
---
上一章：[30 · 反射与元编程](30-reflection.md) ｜ 下一章：[32 · 立方类型论初步](32-cubical.md) ｜ 返回：[README](../README.md)
