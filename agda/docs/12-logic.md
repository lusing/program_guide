# 12 · 逻辑连接词

Curry–Howard 对应不是格言，是可以在 Agda 里逐行摸到的代码：**命题是类型、
证明是程序、化简证明就是执行程序**。本章把逻辑课本的整张连接词表搬进 Agda：
真 ⊤（`\top`）、假 ⊥（`\bot`）、合取 ×（`\times`）、析取 ⊎（`\uplus`）、
否定 ¬（`\lnot`）、蕴含 →、全称 ∀、存在 ∃（`\exists`）——每个都给出引入
与消去规则的真实证明，并标注 stdlib 2.3 的准确住址；最后用「双重否定消去
为何要请公理」划清构造性逻辑与经典逻辑的界线——本书第一次动用 `postulate`。

对应示例：`../examples/Ex12_logic.agda`

报错文本均为 Agda 2.8.0 + stdlib 2.3 实测原样粘贴，代码片段与示例一致。

先立总表（「证明视角」列就是本章要逐个写出来的程序）：

| 命题 | 类型 | 引入（怎么证） | 消去（怎么用） |
|------|------|----------------|----------------|
| 真 ⊤ | `record ⊤ : Set where tt` | 交出 `tt` | 几乎无用（谁都会） |
| 假 ⊥ | `data Empty : Set where`（零构造子） | 证不出来 | `⊥-elim`：推出一切 |
| A ∧ B | `A × B` | 一对证据 `p , q` | `proj₁` / `proj₂` |
| A ∨ B | `A ⊎ B` | 选边 `inj₁ p` / `inj₂ q` | 情形证明 `[ f , g ]` |
| ¬A | `A → ⊥` | 写个吃 A 产 ⊥ 的函数 | 函数应用 |
| A ⇒ B | `A → B` | λ | 函数应用（modus ponens） |
| ∀x. P x | `(x : A) → P x` | 吃 x 给证据的函数 | 函数应用（实例化） |
| ∃x. P x | `Σ[ x ∈ A ] P x` | 见证 + 证据 `x , p` | 同时 case 两个分量 |

## 12.1 真与假：record 与零构造子 data

「真」是最容易证的命题——它有一条不需要任何输入的证据。stdlib 的 `⊤`
来自内核库 `Agda.Builtin.Unit`，逐字如下：

```agda
record ⊤ : Set where
  instance constructor tt
```

record 意味着自带 η 规则：`⊤` 的**任何**元素都判定等于 `tt`，于是一条
`refl` 证尽天下真命题（示例 12.1）：

```agda
⊤-intro : ⊤
⊤-intro = tt

⊤-η : ∀ (x : ⊤) → x ≡ tt
⊤-η x = refl
```

「假」是它的对偶：**零构造子的 data**。`Data.Empty` 第 21–29 行的原文
（节选）：

```agda
private
  data Empty : Set where

⊥ : Set
⊥ = Irrelevant Empty
```

两个细节。其一，`data Empty` 一枝构造子都没有——10 章的索引无解在这里
升级成「整个类型无居民」，消去规则 `⊥-elim`（爆炸律）**一个分支都不用写**：

```agda
⊥-elim′ : ∀ {A : Set} → ⊥ → A
⊥-elim′ ()
```

其二，stdlib 2.3 的 `⊥` 不是裸 `Empty`，而是套了一层 `Irrelevant`（单无关
字段的 record）：让 Agda 判定「⊥ 的所有证明彼此相等」，一切产出 ⊥ 的函数
因而互相相等。副作用是**报错里 ⊥ 总以全名
`Data.Irrelevant.Irrelevant Data.Empty.Empty` 出场**（11.7 已撞见过）。

## 12.2 合取 ×：引入是逗号，消去是投影

两条证据并排放，就是合取。stdlib 定义在 `Data.Product.Base` 第 70–71 行
（下略宇宙级处同此），而且**就是 Σ 的特例**（12.3 展开）：

```agda
_×_ : ∀ (A : Set) (B : Set) → Set _
A × B = Σ[ x ∈ A ] B
```

引入用逗号构造子 `_,_`（`\,`），消用 `proj₁`/`proj₂`——课本的
∧-intro/∧-elim 一条不少（示例 12.2）：

```agda
3-+3-is-6 : (3 + 3 ≡ 6) × (2 + 2 ≡ 4)
3-+3-is-6 = refl , refl                    -- ∧-引入：两条 11 章式 refl

∧-elimˡ : ∀ {A B : Set} → A × B → A
∧-elimˡ = proj₁                            -- ∧-消去：投影就是消去

∧-elimʳ : ∀ {A B : Set} → A × B → B
∧-elimʳ = proj₂

×-comm : ∀ {A B : Set} → A × B → B × A
×-comm (a , b) = b , a                     -- 交换律=换配对顺序
```

## 12.3 × 与 Σ 之辨：第二个分量能不能「看见」第一个

`A × B` 里 B 是**固定**类型；`Σ[ x ∈ A ] B x` 里第二个分量的类型可以
**依赖**第一个分量的值——这正是「合取」与「存在」共用一套构造子的原因：

```agda
×→Σ : ∀ {A B : Set} → A × B → Σ[ x ∈ A ] B
×→Σ (a , b) = a , b

Σ→× : ∀ {A B : Set} → Σ[ x ∈ A ] B → A × B
Σ→× (a , b) = a , b
```

两个方向都通：`A × B` 本就**等于** `Σ[ x ∈ A ] B`（B 不依赖 x），上面只是
同义反复的演示。真正体现差别的是这种配对，`×` 根本**写不出类型**：

```agda
∃-witness : Σ[ n ∈ ℕ ] n + n ≡ 4
∃-witness = 2 , refl                       -- 第二个分量的类型由 2 决定
```

`n + n ≡ 4` 里的 `n` 来自第一个分量——Σ 是「带依赖的配对」，其定义在内核库
`Agda.Builtin.Sigma`（`record Σ (A : Set a) (B : A → Set b)`），同样自带 η。

## 12.4 存在 ∃：Σ 的谓词特例

`Data.Product.Base` 第 37–38 行（宇宙级参数略，下同），stdlib 把 ∃ 定义成**一行别名**：

```agda
∃ : ∀ {A : Set} → (A → Set) → Set
∃ = Σ _
```

再配一条 syntax 声明（第 62 行）`syntax ∃-syntax (λ x → B) = ∃[ x ] B`，
得到课本味的写法 `∃[ n ] n + n ≡ 4`。引入 = 交出**见证**和**性质的证明**，
消去 = 对两个分量同时 case（示例 12.4）：

```agda
∃-intro : ∃[ n ] n + n ≡ 4
∃-intro = 2 , refl                   -- 引入 = 交出见证 + 性质证明

∃-elim : ∀ {A : Set} {P : A → Set} {C : Set}
        → ∃[ x ] P x → (∀ {x} → P x → C) → C
∃-elim (x , px) f = f px             -- 消去 = 对见证与证明同时 case
```

`∃-elim` 是课本「存在消去」的翻译：见证 x、证据 P x、再加一条「P x 能产 C」的函数，就得 C。

一个经典「不该成立」的等价：`(∃[ x ] P x) × (∃[ y ] Q y)` **推不出**
`∃[ x ] (P x × Q x)`——两个存在可能各取各的见证。实例：P n = n ≡ 0、Q n = n ≡ 1，
左边成立，右边却要求同一个 n 既 ≡ 0 又 ≡ 1，用 11 章 `trans`/`sym`
立刻导出 `0 ≡ 1`，撞上 11.7 的空分支墙——见证必须交出，偷换骗不过类型检查器。

## 12.5 析取 ⊎：选边即证

`Data.Sum.Base` 第 28 行（宇宙级略），标准的两构造子 data：

```agda
data _⊎_ (A : Set) (B : Set) : Set where
  inj₁ : (x : A) → A ⊎ B
  inj₂ : (y : B) → A ⊎ B
```

构造性「或」比课本多一点内涵：**证据自带「我知道哪边成立」**。示例 12.5
里「2 是偶数或 3 是奇数」选左边就完事：

```agda
or-demo : (∃[ n ] n + n ≡ 2) ⊎ (∃[ n ] suc (n + n) ≡ 3)
or-demo = inj₁ (1 , refl)

⊎-comm : ∀ {A B : Set} → A ⊎ B → B ⊎ A
⊎-comm (inj₁ a) = inj₂ a
⊎-comm (inj₂ b) = inj₁ b
```

消去规则是「情形证明」：两枝各给一个去处。手写模式匹配，或直接用 stdlib
的中括弧 `[_,_]`（`Data.Sum.Base` 第 35 行起，它就是 ⊎ 的消去原理）：

```agda
∨-elim : ∀ {A B C : Set} → A ⊎ B → (A → C) → (B → C) → C
∨-elim (inj₁ a) f _ = f a
∨-elim (inj₂ b) _ g = g b

∨-elim′ : ∀ {A B C : Set} → (A → C) → (B → C) → A ⊎ B → C
∨-elim′ f g = [ f , g ]
```

顺带一对分配律，两个方向都只靠拼拆装（示例 12.5）：

```agda
distʳ→ : ∀ {A B C : Set} → (A × C) ⊎ (B × C) → (A ⊎ B) × C
distʳ→ (inj₁ (a , c)) = inj₁ a , c
distʳ→ (inj₂ (b , c)) = inj₂ b , c

distˡ← : ∀ {A B C : Set} → (A ⊎ B) × C → (A × C) ⊎ (B × C)
distˡ← (inj₁ a , c) = inj₁ (a , c)
distˡ← (inj₂ b , c) = inj₂ (b , c)
```

后者不需要 `C` 可判定——⊎ 已经在你手里，直接拆即可；把 ×/⊎ 换成 ∀/∃ 再想想，
那边才是真吃判定的地方（15 章）。

## 12.6 否定：吃假设的函数

11.7 已经打过照面，这里正式立牌位（`Relation.Nullary.Negation.Core`
第 26–27 行，宇宙级略）：

```agda
¬_ : Set → Set
¬ A = A → ⊥
```

**证 ¬A 没有任何新技巧：写个函数，把 A 的证据吃了、产出 ⊥。**而产 ⊥
最快的路就是 12.1 的空分支——假设本身就是索引无解的证据：

```agda
0≢1 : 0 ≢ 1
0≢1 ()                       -- 展开：(0 ≡ 1) → ⊥；0≡1 无居民，零分支即证

contra-demo : ∀ {A : Set} → A → ¬ A → ⊥
contra-demo a ¬a = ¬a a      -- 「A 且 ¬A」必假 = 把 a 喂给 ¬a

¬-streng : ∀ {A B : Set} → ¬ A → A × B → ⊥
¬-streng ¬a (a , b) = ¬a a   -- 合取消去 + 否定消去，两步
```

`contra-demo` 就是 stdlib 的 `contradiction`（同文件第 53 行，类型为多态版
`A → ¬ A → Whatever`）；变量也可带 Unicode 前缀，如 `¬a`（输入 `\lnot a`）。

## 12.7 双重否定：一个方向免费，另一个要公理

`A → ¬ ¬ A` 是纯 λ 演算的练习题（示例 12.7）：

```agda
¬¬-intro : ∀ {A : Set} → A → ¬ ¬ A
¬¬-intro a ¬na = ¬na a             -- A 的消费者见到 ¬A 当场爆炸
```

逆命题 `¬ ¬ A → A`（DNE，双重否定消去）**构造上写不出**：把主体悬置成
洞 `_`，Agda 2.8.0 原话：

```text
/home/xulun/code/programming/agda/examples/Tmp12u.agda:8.16-17: error: [UnsolvedMetaVariables]
Unsolved metas at the following locations:
  /home/xulun/code/programming/agda/examples/Tmp12u.agda:8.16-17
```

手里只有 `¬¬a : ¬ ¬ A`，即「(A → ⊥) → ⊥」——它要求**喂给它一个 A**，
而 A 恰恰是我们要造的。没有更多信息，循环出不来。stdlib 给这个缺口起了
正式名字：`Negation.Core` 第 38 行 `Stable A = ¬ ¬ A → A`——「稳定」的
命题才允许 DNE；判定可证的一切命题都稳定（15 章）。

## 12.8 排中律：postulate 与 --safe 的正面冲突

请公理不需要写证明，用 `postulate` 把「证据」凭空挂进上下文（示例 12.8）：

```agda
postulate
  LEM : ∀ {A : Set} → A ⊎ ¬ A       -- 经典逻辑：每命题「或真或假」的证词
```

有了它，DNE 一拆就通；皮尔士定律同款手感（with 分情形，13 章细讲）：

```agda
¬¬-elim : ∀ {A : Set} → ¬ ¬ A → A
¬¬-elim {A = A} ¬¬a with LEM {A}
¬¬-elim ¬¬a | inj₁ a = a
¬¬-elim ¬¬a | inj₂ ¬a = ⊥-elim (¬¬a ¬a)

peirce : ∀ {A B : Set} → ((A → B) → A) → A
peirce {A} {B} f with LEM {A}
peirce f | inj₁ a = a
peirce f | inj₂ ¬a = f (λ a → ⊥-elim (¬a a))
```

一个 Agda 语法坑顺手记下：with 抽象后**子句左端仍要重复主参数**，且隐式
`{A}` 想引用必须写 `{A = A}` 绑定——直接写 `LEM` 会报「A 不在作用域」。

De Morgan 律的「可证方向」不欠任何公理（示例 12.8），反方向才吃 LEM——
把两条都写出来，界线一目了然：

```agda
dm₁ : ∀ {A B : Set} → (¬ A ⊎ ¬ B) → ¬ (A × B)
dm₁ (inj₁ ¬a) (a , b) = ¬a a
dm₁ (inj₂ ¬b) (a , b) = ¬b b

dm₂ : ∀ {A B : Set} → ¬ (A ⊎ B) → ¬ A × ¬ B
dm₂ ¬[A⊎B] = (λ a → ¬[A⊎B] (inj₁ a)) , (λ b → ¬[A⊎B] (inj₂ b))
```

最后是本教程第一次也是极少第二次动用「非安全」特性：**postulate 与
`--safe` 互斥**。给本文件加 `{-# OPTIONS --safe #-}` 立刻被拒（实测）：

```text
/home/xulun/code/programming/agda/examples/Tmp12s.agda:9.3-30: error: [SafeFlagPostulate]
Cannot postulate LEM with safe flag
when scope checking the declaration
  LEM : {A : Set} → A ⊎ ¬ A
```

`--safe` 禁 postulate、禁不透明求值、禁一堆危险 pragma，是「编译产物
即构造性证明」的守门员（02 章讲过选项体系）。所以 Ex12 文件头**故意没加**
`--safe`。stdlib 自己的对口模块：`Axiom.ExcludedMiddle` 把 LEM 形式化为
`ExcludedMiddle ℓ = {P : Set ℓ} → Dec P`（第 20–21 行，注意它用 Dec 而非
⊎ 表述），并给出 `Axiom.DoubleNegationElimination` 第 35–39 行的互推
`em⇒dne` 与 `dne⇒em`——排中、DNE 在 stdlib 里互为充要，经典逻辑三件套
同一枚硬币。

## 12.9 蕴含与等价：函数应用就是 modus ponens

蕴含最好办：`A ⇒ B` 就是函数，消去规则（假言推理）就是应用：

```agda
modus-ponens : ∀ {A B : Set} → (A → B) → A → B
modus-ponens f a = f a              -- 「蕴含消去」= 函数应用，零技巧
```

等价不是新类型，是一对双向函数（stdlib 的正式版本是 17 章的
`Relation.Binary.EqReasoning`/record 化的 `⇔`，这里先用 × 手搓）：

```agda
infixr 1 _⇔_
_⇔_ : Set → Set → Set
A ⇔ B = (A → B) × (B → A)          -- 等价 = 双向蕴含

⇔-sym : ∀ {A B : Set} → A ⇔ B → B ⇔ A
⇔-sym (f , g) = g , f              -- 换向 = 换配对顺序（12.2 ×-comm）
```

## 12.10 ∀、∃ 的合影与「判定」预告

全称量词是**依赖函数**——这也是 10 章依赖类型的第一课：

```agda
∀-intro : ∀ (n : ℕ) → n ≡ n
∀-intro n = refl                     -- 证「对所有 n」= 给一个吃 n 的函数
```

小坑预告版：把类型写成 `∀ n → n ≡ n` 不钉 `n : ℕ`，数字字面量类型不明，
Agda 报 UnsolvedMetaVariables——量词上的变量**也要注域**。全称对合取的
分配一行复合函数搞定（`_∘_` 在 `Function`，11.7 的老朋友）：

```agda
∀-distrib-× : ∀ {A : Set} {P Q : A → Set} → (∀ x → P x × Q x) → (∀ x → P x) × (∀ x → Q x)
∀-distrib-× h = (proj₁ ∘ h) , (proj₂ ∘ h)
```

存在与全称的否定对偶（只证可证的这半，另一半吃判定性）：

```agda
¬∃→∀¬ : ∀ {A : Set} {P : A → Set} → ¬ (∃[ x ] P x) → ∀ x → ¬ (P x)
¬∃→∀¬ ¬∃ x px = ¬∃ (x , px)
```

最后是「可判定」概念登场——注意 2.3 里 `Dec` **不是 data 而是 record**
（`Relation.Nullary.Decidable.Core` 第 52–61 行节选）：

```agda
record Dec (A : Set) : Set where
  constructor _because_
  field
    does  : Bool
    proof : Reflects A does

pattern yes a =  true because ofʸ  a
pattern no ¬a = false because ofⁿ ¬a
```

设计动机写在源码注释里（第 42–47 行）：把「布尔答案」和「反射证明」拆开，
计算时只看 `does`。日常用 `yes`/`no` **模式**读写足够（Ex12 的
`yes tt`、`no ⊥-elim`），但要知道真构造子是 `_because_`，match 不出
`yes`/`no` 时别怀疑人生：

```agda
⊤-dec : Dec ⊤
⊤-dec = yes tt

⊥-dec : Dec ⊥
⊥-dec = no ⊥-elim
```

`Dec A` 与 `A ⊎ ¬ A` 长得像但**不等价**：前者多一层可计算的布尔壳，
`yes`/`no` 携带的是**同一份信息**的证与据。12.8 的 LEM 若改成
`∀ {A} → Dec A` 就是 stdlib 的 `ExcludedMiddle`。合取、析取的判定组合子
`_×-dec_`、`_⊎-dec_` 分别在同文件第 108、116 行；**整个 15 章就是这台
「判定机器」的制造车间**，这里只立块路牌。

## 12.11 练习路线

1. 证 `∨-distrib-∀` 的可证方向：`(∀ x → A x ⊎ B) → (∀ x → A x) ⊎ B`
   试试——卡在哪儿？（提示：见证选择；这就是它需要判定的原因。）
2. 不用 LEM，证 `¬ ¬ ¬ A → ¬ A`（纯 λ 三行）。再想想为什么它能穿过
   12.7 的「DNE 墙」。
3. 给 `⊎-comm` 补一个双剑合璧：`⊎-assoc : (A ⊎ B) ⊎ C → A ⊎ (B ⊎ C)`，
   并写出它的逆。

## 12.12 坑位清单（本项目实测）

1. **stdlib 2.3 没有 `Logic` 模块**：`import Logic` 或从老教程抄
   `Logic.Base` 直接 NotInScope/ModuleNotFound；连接词真实住址是
   `Data.Sum.Base`、`Data.Product.Base`、`Relation.Nullary.*`（抄代码先 grep）。
2. **`⊥` 是 `Irrelevant Empty`**：报错打印全名
   `Data.Irrelevant.Irrelevant Data.Empty.Empty`，不代表你写错了 ⊥；
   且它自带「所有 ⊥ 证明相等」，裸 `data Empty` 没有这待遇。
3. **`yes`/`no` 是 pattern 不是构造子**：`Dec` 的真构造子是 `_because_`
   （record），拿 `Dec` 做 with 抽象时匹配的是 `true/false because _`。
4. **DNE 写不出不是水平问题**：`¬ ¬ A → A` 悬洞必报
   UnsolvedMetaVariables（12.7 原文）——命题本身在构造性逻辑不成立，
   要它就得 `postulate`，而 postulate **与 `--safe` 互斥**（SafeFlagPostulate，
   12.8 原文）。
5. **量词变量也要注域**：`∀ n → n ≡ n` 报 UnsolvedMetaVariables，
   必须 `∀ (n : ℕ) → n ≡ n`（数字字面量类型要靠注域定）。
6. **with 子句要重复左端主参数**，隐式变量想用须 `{A = A}` 显式绑定
   （12.8 的 `¬¬-elim`）；漏了报 NotInScope。
7. **∃ 不过分配**：`(∃ x, P x) × (∃ y, Q y) → ∃ x, P x × Q x` 不成立
   （见证可以不同）；Agda 会在类型层拦住你，不存在「先证着再说」。
8. **`contradiction` 的类型是 `A → ¬ A → Whatever`** 多态收尾，别在
   需要具体 ⊥ 的地方等它单给 ⊥——直接 `¬a a` 最稳。

---
上一章：[11 · 命题等式](11-equality.md) ｜ 下一章：[13 · 归纳证明](13-induction.md) ｜ 返回：[README](../README.md)
