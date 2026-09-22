# 05 · 类型系统与宇宙

01 章立下心智模型：类型即命题、程序即证明；03 章你已经见过「编译器把
`2 + 3` 算到范式才放行 `refl`」的场面。本章把镜头拉远一层，回答一个新手必然
冒出的问题：**类型自己有没有类型？** 如果有，它住在哪一层？顺着这条线索会
牵出 Agda 类型系统的骨架——宇宙阶梯 `Set₀ / Set₁ / … / Setω`、依赖函数类型
Π、宇宙多态（Level），以及「内核判定性」这条底线（排中律不是免费的，公理必须
用 `postulate` 明说）。这些概念平时藏在代码底下，但它们决定了你的多态函数
为什么报 `Unsolved meta`、`Vec` 为什么不能写成 `Set → ℕ → Set`、
`--safe` 到底在防什么。

对应示例：`../examples/Ex05_universes.agda`

本章所有类型/报错均为 Agda 2.8.0 + stdlib 2.3 实测：示例文件整体退出码 0，
引号里的错误文本都是把「反面写法」单独喂给 agda 抓下来的原文。

## 5.1 再强调一遍：类型检查即证明

先把 01/03 章的主线钉死。下面三行定义，同时也是三条逻辑定理的**证明**：

```agda
-- 假言三段论： (B ⇒ C) ⇒ (A ⇒ B) ⇒ (A ⇒ C)
trans′ : ∀ {A B C : Set} → (B → C) → (A → B) → A → C
trans′ g f x = g (f x)

-- A ⇒ A ∨ B（∨ 引入左规则）
or-intro₁ : ∀ {A B : Set} → A → A ⊎ B
or-intro₁ = inj₁

-- 爆炸原理：⊥ 蕴含一切
ex-falso : ∀ {A : Set} → ⊥ → A
ex-falso ()
```

没有 tactic，没有「显然」——函数体就是证明本身，类型检查器逐点核验。
本章不新增证明技巧，而是给这套「证明」搭舞台：**这些命题、类型都住在
哪一层？** 舞台搭错层，戏开不了场（报错你会在下面亲眼看）。

顺带剧透：`ex-falso` 里的 `()`（荒谬模式）和 5.6 的 `with` 是 06 章正戏，
这里先当「不可能分支自动消失」的黑盒用。

## 5.2 Type 还是 Set：类型有没有类型

**有。**Agda 里 `Bool : Set`，而 `Set` 自己也有类型。先实测三件事：

**(1) `Type` 这个名字根本不存在。**从 Coq/Haskell 迁过来的同学最爱问：

```text
error: [NotInScope]
Not in scope:
  Type
when scope checking Type
```

Agda 2.6.1 起彻底移除了历史上的 `Type` 别名，统一叫 **`Set`**（Coq 的
`Type`、Lean 的 `Type u` 在这里都写作 `Set ℓ`）。看老教程看到 `Type` 记得脑内替换。

**(2) `Set` 是类型，也是 term**，可以像给任何值一样给它「标类型」：

```agda
T₁ : Set₁
T₁ = Set        -- Set 的类型是 Set₁，实测通过
```

**(3) 宇宙是阶梯，没有顶端。**下标记法全合法——包括 Unicode 下标 `Set₀`：

```agda
B₀  : Set       -- 裸 Set 就是 Set₀
B₀′ : Set₀
B₀  = Bool      -- 两行都通过

T₂ : Set₂
T₂ = Set₁       -- 再上一层：Set₁ 的类型是 Set₂

T₃ : Set₄
T₃ = Set₃       -- 阶梯无限延伸，规则恒为 Set ℓ : Set (lsuc ℓ)

Predicate : Set₁
Predicate = ℕ → Set   -- 「以类型为值的函数」（谓词族）整体落在 Set₁
```

定位一句话：**`Set₀` 装小类型，它的类型在 `Set₁`；「类型类的类型」永远在
下一层，没有哪个 `Set` 是自家成员。**

**非累积性（实测，和 Coq 的关键差异）**。Coq 的 `Type` 塔是累积的
（`A : Type_i` 可当 `Type_{i+1}` 用），Agda **不累积**：

```text
V : Set₂
V = Bool
--> error: [UnequalSorts]
    Set != Set₂
    when checking that the expression Bool has type Set₂
```

`Bool : Set₀`，而 `Set₀` 这个**排序**不 `≤ Set₂` 地参与 membership 检查——
想搬运到高层，请用显式宇宙多态（5.5）或 `Lift`（5.5 末尾），没有免费的升降。

## 5.3 Setω：所有宇宙的上界，但不是「第 ω 层普通宇宙」

声明 `Set₁`、`Set₂` 还不够写「**所有** Set 的梯子」这类东西。Agda 提供
`Setω`（omega），它是阶梯的**上界排序**，主要用途是给「大」数据/族排序。
四个实测事实摆在一起，才讲清它的脾气：

**(a) 要 import 才能用**（裸写 `Set` 在默认作用域、`Setω` 不在）。
`open import Agda.Primitive using (Setω)` 之后才可用，否则实测 NotInScope，
且提示里还出现 `SSetω`（`--cubical` 的严格变体，24 章见）：

```text
error: [NotInScope]
Not in scope:
  Setω
    (did you mean 'Agda.Primitive.SSetω' or ... or 'Set'?)
```

**(b) 它的本职：给含「大参数」的 datatype 排序。**`Largeω` 的构造子收一个
`Set`——这在 `Set` 或任何有限层 `Set ℓ` 里都写不出来（5.4 会看到现场），
但声明为 `Setω` 就行：

```agda
data Largeω : Setω where
  packω : Set → Largeω
```

**(c) `Setω` 装不下 `Set` 这个「值」**（`T : Setω; T = Set` 实测
`[UnequalSorts] Set₁ != Setω`），别把上界当普通宇宙用。

**(d) `Setω` 自己也不在自己里面**——`Tω : Setω; Tω = Setω` 实测
`Setω₁ != Setω`，它的类型是「更高一格的 ω」。正确写法（是的，
`Setω₁` 这种「ω+1」语法真实存在，实测通过）：

```agda
Sω₁ : Setω₁
Sω₁ = Setω
```

小结（实测版）：`Set ℓ : Set (lsuc ℓ)`；`Setω` 是比一切有限层都高的**排序**，
用来给 datatype 和签名「封顶」，而不是拿来装大值的普通宇宙。日常写程序
基本不碰 `Setω`，读 stdlib 的 `Relation.Binary` 族谱时才会重逢。

## 5.4 Π 类型：参数类型依赖一个「值」

Agda 的函数类型箭头 `A → B` 是 Π 类型的退化情形——B 不提及 A 的参数。
真正的 Π 允许**返回类型依赖参数的值**：`(x : A) → B x`
（Coq 的 `forall x : A, B x`、Idris2 的 `(x : A) -> B x` 是同一件事）。

最小可运行样板——`if _ then _ else _` 直接出现在**类型位置**：

```agda
pick : (b : Bool) → if b then ℕ else Bool
pick true  = 3
pick false = true

_ : pick true ≡ 3
_ = refl
```

调用 `pick true` 时返回类型**算出**是 `ℕ`，调用 `pick false` 时是 `Bool`——
类型检查器在做符号执行级别的活。

招牌预告（16 章主角、10 章的 Fin 同理）：**向量长度进入类型**，
`Vec` 就是一个从值到类型的函数（type family）：

```agda
infixr 5 _∷_
data Vec (A : Set) : ℕ → Set where
  []  : Vec A zero
  _∷_ : ∀ {n : ℕ} → A → Vec A n → Vec A (suc n)

vhead : ∀ {A : Set} {n : ℕ} → Vec A (suc n) → A
vhead (x ∷ xs) = x

v2 : Vec ℕ 2
v2 = 1 ∷ 2 ∷ []

_ : vhead v2 ≡ 1
_ = refl
```

`vhead` 的签名读作定理「任何长度形如 `suc n` 的向量都有头元素」。
想在 `Vec A zero` 上调 `vhead`？**根本写不出这个调用**——
`zero` 与 `suc n` 不可统一，错误发生在类型检查期而非运行期。
这就是 README 那句口号的实现细节：*越界不可表达*，证明由签名代劳。

顺带两个实测坑，都长在这一小节：

**(1) 宇宙记账没算好，Vec 第一步就翻车。**如果偷懒把 Vec 写成最朴素的

```agda
data Vec : Set → ℕ → Set where
  []  : ∀ {A} → Vec A zero
```

报错是本章新学的「排序」类错误（实测原文，信息量很大）：

```text
error: [ConstructorDoesNotFitInData]
Constructor [] of inferred sort Set₁
does not fit into data type of sort Set.
(Reason: Set₁ is not less or equal than Set)
...
Note: this argument is forced by the indices of [], so this
definition would be allowed under --large-indices.
```

解读：构造子字段里出现了 `Set`（它住在 `Set₁`），而 `Vec` 声明的排序只有
`Set`——正是 5.2 非累积性禁止的事。正解二选一：像示例那样把 `A : Set` 提成
**参数**（`data Vec (A : Set) : ℕ → Set`），或做宇宙多态（需 5.5 的块）。

**(2) `_∷_` 忘写 `infixr 5` 时，`1 ∷ 2 ∷ []` 报的是语法级错误**
（默认结合性 infixl 20 把链式应用解析崩了）：

```text
error: [NoParseForApplication]
Could not parse the application 1 ∷ 2 ∷ []
```

而且 `infixr` 声明必须写在 `data` **块外面**——写在构造子之间会撞上
`[Syntax.WrongContentBlock]`：`A data definition can only contain type
signatures`。记号细则见 04 章。

最后用一个熟悉的例子收束本节：`swap` 的类型
`∀ {A B : Set} → A × B → B × A`——`×` 两侧也是Π式多态，
09 章会把「函数即记录」这条线拉直。

## 5.5 多态与 Level：`{A : Set}` 背后的一整套机制

### 隐式参数与显式参数

```agda
idE : ∀ (A : Set) → A → A      -- 显式：调用必给
idE A x = x
n₁ : ℕ
n₁ = idE ℕ 3

id₀ : ∀ {A : Set} → A → A      -- 隐式：花括号，调用处从类型反推
id₀ x = x
n₂ : ℕ
n₂ = id₀ 3

n₃ : ℕ
n₃ = id₀ {A = ℕ} 3             -- 也可以手动实例化（推理失败时的自救）
```

约定：`{}` 里的参数（类型、Level、证明）由 elaborator 反推；推不出才手写
`{A = …}`。这个约定正是本节末尾两个坑的根源。

### 宇宙多态：对 Level 也参数化

`id₀` 只对 `Set₀` 的类型多态。想把「类型本身」搬进 `Set₁`？
给**层级**也开一个隐式参数：

```agda
id : ∀ {ℓ} {A : Set ℓ} → A → A
id x = x

S₁ : Set₁
S₁ = id {A = Set₁} Set         -- ℓ 自动解为 lsuc lzero
```

`Agda.Primitive` 提供底层设施（`Level`、`lsuc`、`lzero`、`_⊔_`）；
stdlib 的 `Level` 模块把 `lzero/lsuc` 改名成 `zero/suc` 并提供 `Lift`：

```agda
open import Level using (Lift; lift; lower)
```

**坑（实测）**：`open import Level` 全家桶和 `Data.Nat` 同开时，
`Level` 导出的 `zero/suc`（宇宙层级的 0 与后继）会截胡数字写法——
`x : ℕ; x = suc zero` 直接撞上 `Level !=< ℕ`。所以 stdlib 风格是
`using (Lift; lift; lower)` 精确取用。

### variable 块：`Set a` 里的 a 从哪来

示例里 `data _×⊔_ (A : Set a) (B : Set b) : Set (a ⊔ b)` 用了裸的 `a/b`，
文件开头必须有：

```agda
variable
  a b ℓ : Level
```

没有这块，Agda 2.8 直接报 `[NotInScope] a`——**层级变量不会从天上掉**，
自动层级泛化以 `variable` 声明为前提（stdlib 每个模块开头都有一块）。

### 隐式参数推理的坑（两个实测案发现场）

**(1) 隐式参数不出现在「可见类型」里 → 调用处永远解不出来。**
对 `f : ∀ {A : Set} → ℕ → ℕ` 写 `y = f 3`，实测：

```text
error: [UnsolvedMetaVariables]
Unsolved metas at the following locations: ...:5.5-6
```

检查器不肯为「反正也用不到」的 `A` 随便挑一个值。修：删掉没用到的隐式参数，
或调用处 `{A = …}`。

**(2) 候选解不唯一 → 直接卡死。**对 `bad = id₀ []`（`Data.List` 的 `[]`）实测：

```text
error: [UnsolvedConstraints]
Failed to solve the following constraints:
  _15 := ambiguous constructor [] : _3 (blocked on _3)
```

修：`bad = id₀ {A = List ℕ} []`，或给 `bad` 写全类型标注（标注一锤定音，
elaborator 立刻有解）。

### Lift：手工跨层的官方通道

不累积的宇宙之间想「硬搬」，用 `Lift` 包一层再拆：

```agda
Bigℕ : Set₁
Bigℕ = Lift (lsuc lzero) ℕ

bv : Bigℕ
bv = lift 3

_ : lower bv ≡ 3
_ = refl
```

记录类型 `Lift {a} ℓ (A : Set a) : Set (a ⊔ ℓ)` 就是「带层级税票的转运箱」；
12 章讲逻辑等价、18 章讲代数层级参数时会再遇到它。

## 5.6 判定性内核：排中律不免费，公理要 postulate

Agda 的内核是 **Martin-Löf 类型论的构造性版本**，类型检查是**可判定**的过程
（这也是「程序即证明」能机器化的前提），代价是：

- 终止性检查把「用 general-recursion 糊弄出证明」的路焊死（07 章展开）；
- **没有内建排中律/选择公理**：`em : ∀ A → A ⊎ (A → ⊥)` 在 Agda 里
  证不出来（元理论事实：构造性类型论具有存在性/不相交性质）；
- 想要经典逻辑，必须 `postulate` 显式引入**公理**——03 章那句话的完全体：
  postulate 是证明界的 `unsafePerformIO`。

示例里做了「诚实拆分」：构造性可证的半边绝不碰公理——

```agda
¬¬-intro : ∀ {A : Set} → A → ((A → ⊥) → ⊥)
¬¬-intro a ¬a = ¬a a

postulate
  em : ∀ (A : Set) → A ⊎ (A → ⊥)

¬¬-elim : ∀ {A : Set} → (A ⊎ (A → ⊥)) → ((A → ⊥) → ⊥) → A
¬¬-elim (inj₁ p)  _  = p
¬¬-elim (inj₂ ¬p) nn = ⊥-elim (nn ¬p)

dn : ∀ {A : Set} → ((A → ⊥) → ⊥) → A
dn {A = A} nn = ¬¬-elim (em A) nn
```

注意 `¬¬-elim` 本身**不依赖** `em`——排中律只是它的普通参数；真正吃公理的
只有 `dn` 那一行。公理用到哪一步暴露得清清楚楚，这是 Agda 处理「借来的逻辑」
的工程美学。

而且「借没借」是机器可查的元性质。给文件开 `--safe` 再检查
（12/15/17 章会解释 `--safe` 的完整语义）：

```text
error: [SafeFlagPostulate]
Cannot postulate em with safe flag
when scope checking the declaration
```

`--safe` 下 postulate 全禁、unsafe 内建函数全禁：一个 `--safe` 通过的文件，
**结构上不可能**藏着经典公理。审计证明时先看它开没开 safe，比通读全文便宜。

## 5.7 本章坑位清单（实测）

1. **`Type` 不存在**：Agda 2.6.1+ 统一 `Set`；从 Coq/Haskell 带来的
   `Type`/`*` 写法全是 `[NotInScope]`；
2. **宇宙不累积**：`Bool : Set₀` 不等于 `Bool : Set₂`（实测
   `Set != Set₂`）；跨层要显式多态或 `Lift`，别指望子类型；
3. **`Setω` 有三张面孔**：要 import（`Agda.Primitive`）；只当排序用
   （`Set : Setω` 实测被拒：`Set₁ != Setω`）；它自己的类型再高一格
   （`Setω : Setω` 实测 `Setω₁ != Setω`，正解 `Sω₁ : Setω₁`）；
4. **构造子装不下高层参数**：`data Vec : Set → ℕ → Set` 报
   `[ConstructorDoesNotFitInData]`——把 `A` 提成参数或做宇宙多态，
   报错里的 `--large-indices` 提示是逃生舱但不是正门；
5. **`variable` 块忘配**：签名里裸写 `Set a` 直接 `[NotInScope] a`，
   层级自动泛化以 `variable a : Level` 为前提；
6. **`open import Level` 全家桶撞名**：它把 `lzero/lsuc` 改名成
   `zero/suc` 导出，和 `Data.Nat` 共开时数字构造子被截胡——精确 `using`；
7. **隐式参数两条铁律**：不出现在可见类型里的隐式参数解不出
   （`[UnsolvedMetaVariables]`）；候选不唯一的构造子（`[]`、`refl`）
   在裸调用时会卡 `[UnsolvedConstraints]`——补标注或手写 `{A = …}`；
8. **fixity 是数据声明的一部分**：`_∷_` 不写 `infixr 5` 链式表直接
   `[NoParseForApplication]`，且 fixity 声明不能夹在 `data` 块里
   （`[Syntax.WrongContentBlock]`）。

---
上一章：[04 · 记号与运算符](04-syntax.md) ｜ 下一章：[06 · 数据类型与模式匹配](06-patterns.md) ｜ 返回：[README](../README.md)
