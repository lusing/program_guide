# 15 · 可判定性质

前两章我们一直在「造证明」：`s≤s (s≤s z≤n)` 这样的证据塔造到
13 章已经让人手酸。但 ℕ 上的不等式有个特殊待遇——**它的真假可以
算出来**：`3 ≤ 5` 不用人肉堆塔，程序自己就能裁决，而且裁决结果
随身带着证据。这就是 Agda 处理「计算」与「证明」关系的正招：
`Dec`（decidable，可判定）。本章把 `Dec` 的 record 真身、
`≟/≤?/<?` 判定族、Bool 版与命题版的换算桥 `T?`、两套同名
`True/False` 包装（含 Agda 2.8 内置版已删除的实测现场）逐一看穿，
最后用停机问题划出「可判定」的边界——那里 `postulate` 是唯一出路，
而 07 章的 `SafeFlagPostulate` 正在边界上站岗。

对应示例：`../examples/Ex15_decidable.agda`（全部引文与报错均为 Agda 2.8.0 + stdlib 2.3 实测）

## 15.1 Dec 的真身：二选一，两边都带证据

直觉上「判定 P 真假」应该是个和类型——要么给 P 的证明，要么给
¬ P 的证明。老式写法至今合法（示例里的 `DecOld`），拿来教学正好：

```agda
data DecOld (P : Set) : Set where
  yesO : (p :   P) → DecOld P
  noO  : (p : ¬ P) → DecOld P
```

但 2.3 实际的 `Relation.Nullary.Dec` **不是** data，是 record
（`Relation/Nullary/Decidable/Core.agda` 源码原文，设计注释压缩
转抄）：

```agda
-- Decidability proofs have two parts: the `does` term which contains
-- the boolean result and the `proof` term which contains a proof that
-- reflects the boolean result. This definition allows the boolean part
-- to compute independently from the proof.

record Dec (A : Set a) : Set a where
  constructor _because_
  field
    does  : Bool
    proof : Reflects A does

pattern yes a =  true because ofʸ  a
pattern no ¬a = false because ofⁿ ¬a
```

读三件事：①判定结果 = Bool（`does`）+「这个 Bool 反射了 A 的真值」
的证明（`proof`）；②`yes p`/`no ¬p` 只是 **pattern**，真构造子是
`_because_`——照旧能写 `yes refl`，也能用 `(true because q)` 直拆
字段；③record 的动机写在注释里：**先把布尔算出来，证明要用再造**。

第一个判定过程，零长判断（坑提前看坑位 5）：

```agda
isZero? : (n : ℕ) → Dec (n ≡ zero)
isZero? zero    = yes refl
isZero? (suc n) = no 1+n≢0     -- 1+n≢0 {n} : ¬ (suc n ≡ 0)，n 是隐式参数

_ : ⌊ isZero? 0 ⌋ ≡ true
_ = refl
```

`⌊_⌋`（老名字，现名 `isYes`，即字段 `does`）「剥掉证据只剩布尔」，
独立可算。而 `with` 匹配 Dec 时做**类型精化**（06 章依赖匹配的回
声）——分支不仅决定算哪条路，还决定手里多出什么证据：

```agda
zeroOrNot : (n : ℕ) → (n ≡ zero) ⊎ ¬ (n ≡ zero)
zeroOrNot n with isZero? n
... | yes p = inj₁ p
... | no ¬p = inj₂ ¬p
```

这与 Coq 的 `destruct (Nat.eq_dec …)` 手感一致；但排中律
`∀ A → Dec A` 在 Agda 内**不可证**（15.8 见边界），`zeroOrNot`
成立纯粹因为 ℕ 等式**具体可判定**。

## 15.2 判定族 ≟ / ≤? / <?：同一配方，三种命题

`Data.Nat.Properties` 里三个判定全是**同一个配方**（源码原文）：

```agda
m ≟ n = map′ (≡ᵇ⇒≡ m n) (≡⇒≡ᵇ m n) (T? (m ≡ᵇ n))
m ≤? n = map′ (≤ᵇ⇒≤ m n) ≤⇒≤ᵇ (T? (m ≤ᵇ n))
m <? n = suc m ≤? n
```

配方三层：**内建 Bool 判定** `_≡ᵇ_`/`_<ᵇ_`/`_≤ᵇ_`（来自
`Agda.Builtin.Nat`，快速机械算法，只吐 Bool 不带证明）；**桥
`T? : ∀ x → Dec (T x)`**（把布尔值 x 反射成命题 `T x` 的现成判定，
`T true = ⊤`、`T false = ⊥`）；**`map′ : (A → B) → (B → A) →
Dec A → Dec B`**（命题等价换皮，把「判定 `T (m ≡ᵇ n)`」升级成
「判定 `m ≡ n`」，互译函数由 Properties 提供）。

于是分工一目了然：**Bool 版负责算，Dec 版负责算完还能讲理**。
计算行为两者一致（`⌊ 2 ≟ 3 ⌋ ≡ false`、`⌊ 4 <? 3 ⌋ ≡ false` 都
refl），值钱的是证据随手可取——10 章坑位 8（`s≤s` 塔手堆到哭）
的解药：

```agda
lt35 : 3 < 5
lt35 = toWitness {a? = 3 <? 5} _
```

**实测大坑**：`toWitness` 的**第一个隐式参数是 Level**，直接
`toWitness {3 <? 5} _` 会把 `Dec (3 < 5)` 塞进要 `Level` 的位置：

```text
error: [UnequalTerms]
Relation.Nullary.Decidable.Dec (3 Data.Nat.< 5) !=<
Agda.Primitive.Level
when checking that the expression 3 <? 5 has type
Agda.Primitive.Level
```

正解是点名 `{a? = …}`（`:toWitness` 看签名便知，别背）。三岐比较
一条不用手写（stdlib 原版叫 `<-cmp`，示例自己走一遍）：

```agda
cmp : (m n : ℕ) → (m < n) ⊎ (m ≡ n) ⊎ (n < m)
cmp m n with m ≟ n | m <? n
... | yes p | _      = inj₂ (inj₁ p)
... | no ¬p | yes q  = inj₁ q
... | no ¬p | no ¬q  = inj₂ (inj₂ (≤∧≢⇒< (≮⇒≥ ¬q) (¬p ∘ sym)))
```

第三分支是全章最「讲理」的一行：手里只有两条**反证**
（`¬q : ¬ (suc m ≤ n)`、`¬p : ¬ (m ≡ n)`），目标却是正的 `n < m`
——`≮⇒≥ ¬q : n ≤ m` 把否定翻成弱式，再喂 `≤∧≢⇒<`（≤ 且不≡ 则 <，
它要 `¬ (n ≡ m)`，所以 `¬p` 得 `∘ sym` 转向）。Bool 版给不了这套：
`m ≤ᵇ n` 算出 false 时你手里什么都没有。

## 15.3 Reflects：yes/no 背后的反射关系

`proof` 字段的类型 `Reflects A b` 住在哪里？**先纠一个路名**：
不少资料（含本章原始提纲）写作 `Relation.Nullary.Reflect`——2.3
全库实测**没有**这个模块，真名是 `Relation.Nullary.Reflects`
（`Relation.Nullary` 公共重导出，只 hiding 了 `recompute` 一族）：

```agda
-- The truth value of A is reflected by a boolean value.
-- `Reflects A b` is equivalent to `if b then A else ¬ A`.

data Reflects (A : Set a) : Bool → Set a where
  ofʸ : ( a :   A) → Reflects A true
  ofⁿ : (¬a : ¬ A) → Reflects A false
```

布尔**值**当索引——10 章「索引携带信息」的又一次出手。注释那句
等价可以亲手证单方向（示例 `reflects-if`；签名必须显式带 Level，
`∀ {P b}` 简写会卡隐式元变量，见坑位 7）：

```agda
reflects-if : ∀ {a : Level} {P : Set a} {b : Bool} → Reflects P b → if b then P else ¬ P
reflects-if (ofʸ p)  = p
reflects-if (ofⁿ ¬p) = ¬p
```

`Dec` 的 `yes`/`no` 就是 `_because_` + `Reflects` 的包装，从判定里
捞反射证明用 `does`/`proof` 字段直取；互逆工具 `of`/`invert` 在
Bool 已定时两边都化简（示例 `invert-of` 用 refl 验证）。

**Coq 对照地图**（两对概念各管各的）：

| 概念 | Agda | Coq |
|---|---|---|
| 「带 Bool 结果的二选一」返回类型 | `Dec A`（record） | `BoolSpec (fun b ⇒ if b then A else ~A)` |
| Bool 值与命题的反射关系 | `Reflects A b` | `reflect P b`（Coq.Bool.Bool） |

Coq 的 `BoolSpec` 依赖 `Prop` 里写 `if`，社区常年嫌难用而转投
`reflect`；Agda 没有 Prop/Set 二分，`Dec` 天生就是「带证据的
BoolSpec」，没有这段历史包袱。

## 15.4 两套 True/False：一个活在 Set，一个已被删除

本章重名灾区，实测讲透。货一：`Relation.Nullary.Decidable.Core`
的**判定包装**（源码原文，`isYes (true because _) = true`）：

```agda
True : Dec A → Set
True = T ∘ isYes

False : Dec A → Set
False = T ∘ isNo
```

即 `True a? = T (isYes a?)`：判定为「是」时退化成 `⊤`。它们是
**`Dec A → Set`** 的一元包装，居民永远是 `tt`——存在的唯一意义
是「告诉你这个判定会说是」，witness 家族负责包装 ↔ 证明的换算：

```agda
_ : True (3 <? 5)
_ = tt

lt35′ : 3 < 5
lt35′ = toWitness {a? = 3 <? 5} tt
```

（反面 `¬lt53 : ¬ (5 < 3)` 走 `toWitnessFalse {a? = 5 <? 3} tt`，
见示例。）货二：**Agda 内置**的 `Agda.Builtin.Reflection.True/False`（旧
教程里的反射版包装）。2.8 实测**已删除**，import 立刻吃警告、
使用立刻 NotInScope（实机复现：新开文件
`open import Agda.Builtin.Reflection using (True; False)`）：

```text
warning: -W[no]ModuleDoesntExport
The module Agda.Builtin.Reflection doesn't export the following:
  True
  False
when scope checking the declaration
  open import Agda.Builtin.Reflection using (True; False)

error: [NotInScope]
Not in scope:
  True
```

老代码写 `True (x < y)` 报 NotInScope，多半是 import 走错门——
货二根本不存在，货一才是正品。（另注意 `Data.Bool` 里还有第三个
`T : Bool → Set`——货一的 `True` 就是 `T ∘ isYes`，三层别搅。）

Bool → 命题只有 `T?` 一座桥，别指望第二座：

```agda
nonZero? : (n : ℕ) → Dec (T (not (n ≡ᵇ zero)))
nonZero? n = T? (not (n ≡ᵇ zero))
```

`Data.Nat.Base` 的 `NonZero` 正是这套 `T` 包装的起别名版。反向
（Dec → Bool）永远顺畅：`⌊_⌋` 即可——**两方向不对称**，Dec 带
证明、Bool 不带，丢弃容易捡起难。

## 15.5 filter 的 Decidable：08 章伏笔回收

08 章照抄过 `filterᵇ (λ n → …)`，留了个疑问：为什么
`Data.List.Base` 的 filter 类型长这样（源码原文）：

```agda
filter  : ∀ {P : Pred A p} → Decidable P → List A → List A
filterᵇ : (A → Bool) → List A → List A
filterᵇ p = filter (T? ∘ p)
```

`Decidable P`（`Relation.Unary`）＝ `∀ x → Dec (P x)`——要的不是
谓词本身（`A → Set`，证明造不出判定），而是**每个点上可计算的
裁决**。Bool 版 `filterᵇ` 只是命题版的**特例**：套上 `T?` 桥即成。
内部实现逐元素只看 `does`（`with does (P? x)`）——record Dec 的
设计意图在这里兑现。两种写法过同一张表示例表：

```agda
ns : List ℕ
ns = 5 ∷ 20 ∷ 8 ∷ 42 ∷ []

evens′ : List ℕ
evens′ = filterᵇ (λ n → n ≤ᵇ 10) ns          -- Bool 谓词版

big : List ℕ
big = filter (λ n → suc 10 ≤? n) ns          -- 命题谓词（_≤_）版

_ : evens′ ≡ 5 ∷ 8 ∷ []
_ = refl
```

`big ≡ 20 ∷ 42 ∷ []` 同样 refl。

## 15.6 自己造判定：Any 与 All（证不出来但判得出来）

「存在/全称」在有穷表上照样可判定。示例手写的 `any?` 逐行读：

```agda
any? : ∀ {A : Set} (P : A → Set) → (∀ x → Dec (P x)) →
       (xs : List A) → Dec (Any P xs)
any? P P? []       = no λ ()
any? P P? (x ∷ xs) with P? x | any? P P? xs
... | yes p  | _        = yes (here p)
... | no  ¬p | yes q    = yes (there q)
... | no  ¬p | no  ¬q   = no λ { (here p) → ¬p p ; (there q) → ¬q q }
```

基例 `no λ ()`：空表上 `Any P []` 无构造子，反证就是「模式匹配
穷尽不了」——06 章荒谬模式在证明位上岗；`no` 分支的匿名函数把
`Any` 的两种构造子逐个拆给两个局部反证——**反证本身也是数据**，
得给出销毁方法。「x 是否在表里」即刻可判（`in? x = any? (_≡ x)
(λ y → y ≟ x)`），26 章去重/排序的成员检查就是它。`all?` 同法
（用 10 章的 All，限定名 `All.[]`/`All._∷_`）。

现在看标题话「**证不出来但判得出来**」是什么意思。命题
`All (λ d → ¬ (suc d ≡ 7)) (1 ∷ 2 ∷ 3 ∷ 4 ∷ 5 ∷ [])` 直证要
五行「`1+n≢0` 加 sym 再应用」的塔；组合 `all? × ¬? × ≟` 把它
变成一次计算，`toWitness tt` 一口吃掉：

```agda
noIs7 : All (λ d → ¬ (suc d ≡ 7)) (1 ∷ 2 ∷ 3 ∷ 4 ∷ 5 ∷ [])
noIs7 = toWitness {a? = all? (λ d → ¬ (suc d ≡ 7))
                           (λ d → ¬? (suc d ≟ 7))
                           (1 ∷ 2 ∷ 3 ∷ 4 ∷ 5 ∷ [])}
            tt
```

素性检测（`∀ 有界 d. ¬ d ∣ n`）、去重后计数对不对，都是同一感性：
**∀ 限定在可判定的有穷域上才可判定**——出了有穷世界，15.8 的
边界立刻出现。

## 15.7 ¬¬¬A → ¬A 与稳定律：Dec 是构造性的排中

先给一条不需要判定的直觉主义定理（stdlib 名 `negated-stable`，
`Relation.Nullary.Negation.Core`）：

```agda
tripleNeg-elim : ∀ {A : Set} → ¬ ¬ ¬ A → ¬ A
tripleNeg-elim h a = h (λ na → na a)
```

读法：给你 `h : ¬¬¬A` 和 `a : A`，构造 `λ na → na a : ¬A` 喂回 h
即得 `⊥`。三重否定能砍到一重，两重却砍不动——排中律的残缺替代品。
但命题一旦可判定，两重直接归零（`Stable A = ¬ ¬ A → A`）：

```agda
stable35 : ¬ ¬ (3 < 5) → 3 < 5
stable35 = decidable-stable (3 <? 5)
```

`decidable-stable` 的实现把 Dec 拆成两枝：真枝 `invert` 出证据，
假枝拿反证与 ¬¬A 对撞（源码用 contradiction）。配套 `¬?`
（Dec A → Dec (¬ A)）与 `¬-drop-Dec`（Dec (¬¬A) → Dec (¬A)）让
否定套娃也可判定，一行把「3 ≢ 4」的反证从计算里钓出来：

```agda
¬3≡4 : 3 ≢ 4
¬3≡4 = toWitness {a? = ¬-drop-Dec (¬? (¬? (3 ≟ 4)))} _
```

规律三层别记混：**可判定 ⇒ 稳定；稳定远多于可判定；一切命题
稳定 = 排中律 = 系统内不可证**。

## 15.8 停机问题：判定的边界上站着 postulate

「可判定」不是免费午餐。把「机器 n 在输入 n 上停机」记作命题
`Halts n`，图灵说 `¬ (∀ n → Dec (Halts n))`。这条定理谈的是
**所有程序**，Agda 内部证不出来，只能请出 07 章警告过的那位：

```agda
postulate
  Halts : ℕ → Set                       -- 外部的停机命题（仅作逻辑占位）
  noDecider : ¬ (∀ n → Dec (Halts n))   -- 图灵定理（此处为公设）

LEM-false : (lem : ∀ (A : Set) → Dec A) → ⊥
LEM-false lem = noDecider (λ n → lem (Halts n))
```

`LEM-false` 是本节真正的手感：假设「全量排中」成立，立刻造出停机
判定器，撞上图灵公设，`⊥` 到手——**全量 Dec 不自洽**。本章与
12 章的分野到此合拢：Agda 能判定的只是具体的类型族（ℕ、Bool、
List、Vec……）。07 章实测提醒仍在岗：`postulate` 在 `--safe` 文件
里直接编译失败（`SafeFlagPostulate`），所以示例文件不声明 safe
——这里的 postulate 是**诚实的假设**，不是 07 章 `magic` 那种
破坏终止性的后门；但工具层面两者同样被 --safe 拦，安全模式宁可
错杀。

## 15.9 坑位清单（本项目实测）

1. **Dec 是 record 不是和类型**：真构造子 `_because_`，`yes`/`no`
   只是 pattern；想同时拆 Bool 与证明要按 `(true because q)` /
   `(false because q)` 分两枝写——合并成一枝 `(b because q)` 时
   `⌊ b because q ⌋` **不**化简（b 是变量），refl 立刻对不上。
   老式 data 版 stdlib 留着当对照，名叫 `DecOld`。
2. **`Relation.Nullary.Reflect` 不存在**：正名 `Relation.Nullary.Reflects`，
   按旧路名 import 吃 ModuleDoesntExport（警告不改退出码，14 章
   同款教训）。
3. **Agda 内置 Reflection 的 True/False 包装在 2.8 已删除**（实测
   警告 + NotInScope 双连击，见 15.4）：本章 `True/False` 是
   `Dec A → Set` 的包装（`= T ∘ isYes`/`T ∘ isNo`），别与
   `Data.Bool` 的 `T : Bool → Set` 混成一层。
4. **`toWitness`/`fromWitness`/`toWitnessFalse` 的第一个隐式参数
   是 Level**：`toWitness {3 <? 5} _` 实测报
   `Dec (3 < 5) !=< Agda.Primitive.Level`；必须点名 `{a? = …}`。
5. **`1+n≢0` 带隐式参数 n**：手写 `no (1+n≢0 n)` 实测报
   `ℕ !=< (suc _n ≡ 0)`——把 ℕ 当 `¬ (suc n ≡ 0)` 用了；正确姿势
   `no 1+n≢0`（隐式参数由期望类型自动解）。
6. **`if_then_else_` 只在 Data.Bool(.Base)**：`Data.Nat` 不重导出，
   想当然写进 using 清单实测吃 ModuleDoesntExport 警告（**退出码
   照旧 0**），到使用处才 NotInScope。
7. **宇宙多态签名别偷懒**：`reflects-if` 写成 `∀ {P b} → …` 实测
   签名检查就停摆（`if b then` 处的 `b` 卡住）：

   ```text
   error: [UnsolvedMetaVariables]
   Unsolved metas at the following locations:
     /home/xulun/code/programming/agda/examples/TmpProbe.agda:4.25-33
   ```

   要显式 `∀ {a : Level} {P : Set a} {b : Bool}`。
8. **Bool 版判定没有反证可用**：`m ≤ᵇ n ≡ false` 在证明位上什么
   也给不了，`≮⇒≥` 之类的桥只吃 `¬ (m ≤ n)`——「算出 false」与
   「证伪」之间隔着整个 Reflects，过桥用 `¬?`/`toWitnessFalse`。
9. **postulate 两种身份（逻辑占位 / 终止后门）在 `--safe` 下待遇
   相同**：全封杀（07 章实测）。别因「我这个无害」就悄悄去掉
   safe 标记。

---
上一章：[14 · 推理框架](14-reasoning.md) ｜ 下一章：[16 · Vec：长度索引的列表](16-vectors.md) ｜ 返回：[README](../README.md)
