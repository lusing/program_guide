# 38 · instance 参数与模算术

前面几章我们把 `≡`、连接词、归纳证明、关系与代数结构都铺好了。
这一章做两件事：**上半程**补一个 Agda 的关键机制——`instance` 参数
（Haskell 类型类的 Agda 等价物），把「同名的 `refl`/`show`/`_+_` 到底指
哪一个」这件事交给编译器自动求解；**下半程**用它落地一个「真问题」——
**模 n 整数环 ℕ/nℕ**，照着 Maguire《Getting Started with Agda》第 5 章
把同余、加乘法的保序性、以及最硬的「由自反性推出传递性」全部在
Agda 2.9.0 + stdlib 3.0 上重跑一遍，并把书里那套自定义 prelude 换成
stdlib 现成的 `≡-Reasoning`、`Setoid`、`Data.Fin`。

对应示例：`../examples/Ex38_modular.agda`

本章报错文本均为 Agda 2.9.0 + stdlib 3.0 实测原样粘贴（复现用的临时
探针文件已删除，报错路径显示为当时的临时路径；形如 `_A_8` 的尾巴是
类型检查器现造的元变量编号，换文件会变，不影响读解）。代码片段与示例
一致，示例通过 `./build.sh Ex38_modular`（退出码 0）。

## 38.1 instance 参数：`⦃ ⦄` 与 `{{ }}`

instance 参数是一种「特殊的隐式参数」：它不由合一（unification）求解，
而由一套专门的**实例解析算法**求解。用户手册开宗明义：

> Instance arguments are a special kind of implicit arguments that get
> solved by a special instance resolution algorithm, rather than by the
> unification algorithm used for normal implicit arguments. Instance
> arguments are the Agda equivalent of Haskell type class constraints.

写法有两种，成对的双花括号：

- Unicode：`⦃ x : T ⦄`（U+2983 / U+2984，Emacs 里 `\{{`、`\}}`）
- ASCII：`{{ x : T }}`

**2.9.0 实测：两者都合法，语义完全一致**——`⦃ ⦄` 只是 `{{ }}` 的Unicode
皮。示例里新旧语法各写一遍都编得过：

```agda
-- 新语法
default : {ℓ : Level} {A : Set ℓ} → ⦃ a : A ⦄ → A
default ⦃ val ⦄ = val

-- 旧语法（独立模块，免得它的 ℕ 实例和上面的抢目标，见 38.5）
module OldSyntax where
  it-old : {ℓ : Level} {A : Set ℓ} → {{ a : A }} → A
  it-old {{ val }} = val
```

给 `default` 喂上「哪些类型有现成默认值」，就靠 `instance` 块：

```agda
private instance
  default-ℕ : ℕ
  default-ℕ = 0
  default-Bool : Bool
  default-Bool = false

_ : default ≡ 0        -- 自动填 0
_ = refl

_ : default ≡ false    -- 自动填 false
_ = refl
```

`default` 干的事极其朴素：**把搜索到的那个实例原样返回**。当类型是
`ℕ` 时，Agda 扫遍所有 instance，找到唯一类型为 `ℕ` 的定义就交回来。填错
值立刻报错（探针实测）：

```text
The terms
  0
and
  1
are not equal at type ℕ
when checking that the expression refl has type default ≡ 1
```

> 换代提醒：Agda 2.8 及更早，这里的老文案是 `0 != 1 of type ℕ`。2.9 把
> 「不相等」错误改成了整句自然语言 `The terms … and … are not equal at
> type …`。老教程里抄来的报错别再当标准文案。

## 38.2 实例搜索算法（用户手册逐段全译）

这一段把手册 *Instance resolution* 一节的精确规格翻过来，是本教程的
招牌动作——把「编译器到底怎么找实例」讲清楚。目标 `{Γ} → C vs` 里，
`C` 是返回类型、`{Γ}` 是一串隐式/实例参数、`vs` 是已有的索引实参。

**① 验证目标形状（Verify the goal）**
只有形如 `{Γ} → C vs` 的目标能被实例搜索解决，其中 `C` 必须是**变量类型、
数据类型、record 类型或公设（postulate）**之一。若 `C` 不是「具名类型」
（named type，即 data/record）也不是变量类型，实例解析直接失败报错。
手册原文：

> Instance search can only solve goals of the form `{Γ} → C vs`, where the
> target type `C` is either a variable, a data type, a record type, or a
> postulate; and `{Γ}` represents a sequence of implicit or instance
> arguments.

这解释了为什么 38.1 里 `default {A = ℕ}` 能搜：目标 `ℕ` 是具名数据类型；
而 `default {A = ℕ → ℕ}` 这种函数类型当返回类型，实例搜索**不接手**。

**② 找候选（Find candidates）**
计算一份「初始候选」清单：

- 作用域内、`let`/`where` 绑定的变量与顶层定义——若它们在 `instance` 块里
  声明，则为候选。
- 局部变量（lambda、函数类型、左侧模式、module 参数绑定的）——若它们是以
  `{{ }}` 绑定的实例参数，则为候选；这**包括对归纳/record 类型做模式匹配时
  抽出来的那些实例构造子参**。
- 若上下文里某个局部实例变量带「父类字段（superclass field）」，会做父类展开；
  判断是否需要展开要先对它类型做头部归一化。
- 只有类型形如 `{Δ} → C us`（`C` 是①算出的目标返回类型、`{Δ}` 只含隐式/实例参）
  的候选才被考虑。
- 若某候选的类型形状或「是否为 eta-record」无法判定，搜索就**不运行**。典型触发：
  某个局部*实例*变量的返回类型还是元变量、或其类型被别的元变量卡住——哪怕
  选一个未卡住的候选本来能把这个元变量解出来，也不行。

**③ 检查候选类型（Check the type of the candidates）**
初始候选是「可行解的过近似」。逐个筛：目标 `{Γ} → C vs` 时——

1. 把局部上下文扩展上 `{Γ}`（这一步可能又把新的候选带进作用域）。
2. 把候选类型 `c : {Δ} → A` 用全新元变量 `α` 实例化。
3. 用目标 `C vs` 去和 `A[α/Δ]` 合一；一旦明确不匹配，丢弃该候选。
4. 若开了 `--backtracking-instance-search`，再对 `Δ` 里出现的实例变量**递归**做实例搜索。

全部通过，就把 `λ {Γ} → c {α}` 记为一个潜在解。

**④ 消解重叠（Resolve overlaps）**
即便允许回溯，仍可能剩多个潜在解。删除那些被「**严格更特殊**」候选盖过的解。
给定 `c1 : {Δ} → C xs`、`c2 : {Γ} → C ys`，删除 `c1` 当且仅当：

- 存在把 `Δ` 中变量用 `Γ` 中变量表出的替换，使 `C xs` 与 `C ys` 定义式相等——
  称 `c2` 比 `c1` **更特殊**；
- 反过来（用 `Δ` 表出 `Γ`）的替换**不存在**——于是 `c2` **严格**更特殊；
- 且「`c1` 标了 OVERLAPPABLE 或 `c2` 标了 OVERLAPPING」。注意标 `OVERLAPS`
  （或 `INCOHERENT`）的实例**同时**算 overlappable 和 overlapping。

**⑤ 计算结果（Compute the result）**
消解重叠后落在五种情形之一：

1. 恰有一个非-incoherent 候选（外加若干 incoherent）：选那个非-incoherent 的。
2. 所有潜在解都是 incoherent：Agda 任选一个。
3. 多个候选、且全部来自标了 `overlap` 的**实例字段**：Agda 任选一个。
4. 多个非-incoherent 候选：把该实例约束**推迟（postpone）**，等目标或候选有更多
   信息再说。
5. 一个候选都没有：立即报错。

类型检查结束时若仍有遗留的实例问题，对应元变量连同类型和源码位置会打印在
Emacs 状态栏；用 `C-c C-=`（show constraints）能查看引发潜在解的候选清单。

## 38.3 手写 typeclass：Show 与 AdditiveMonoid

有了搜索规则，就能手搓一枚「类型类」：一个 record 当接口，一个泛型函数
带实例上下文。这是 Agda 里最接近 Haskell `class` 的写法。

```agda
record Show (A : Set) : Set where
  field show : A → String

open Show ⦃ ... ⦄          -- 把字段 show 变成「按实例重载」的顶层函数

instance
  showℕ : Show ℕ
  showℕ .Show.show zero    = "zero"
  showℕ .Show.show (suc _) = "suc _"

  showBool : Show Bool
  showBool .Show.show true  = "true"
  showBool .Show.show false = "false"

-- 泛型函数：签名里带 ⦃ Show A ⦄，调用处实例被自动补齐
display : {A : Set} → ⦃ Show A ⦄ → A → String
display ⦃ s ⦄ a = Show.show s a

_ : String
_ = display 3       -- 自动挑 showℕ
_ = display true    -- 自动挑 showBool
```

`open Show ⦃ ... ⦄` 是关键招：它自动生成了一个「先做实例搜索、再取字段」的
顶层函数 `show`（等价于手写 `show ⦃ s ⦄ a = Show.show s a`），于是同名的
`showℕ`/`showBool` 字段能被 `display 3` 这种调用**从类型里自动分辨**——不必
像 3.0 之前某些写法那样显式点名。这跟 38.1 的 `HasDefault.the-default` 是
同一个机制：

```agda
record HasDefault (A : Set) : Set where
  constructor default-of
  field the-default : A

open HasDefault ⦃ ... ⦄      -- 自动生成 the-default : ⦃ HasDefault A ⦄ → A

private instance
  _ = default-of 0           -- instance 块里连名字和类型都能省
  _ = default-of false

_ : the-default {A = ℕ} ≡ 0
_ = refl
```

用带参 record（`HasDefault A`）当命名空间，比把裸 `0`/`false` 直接灌进全局
instance 环境更**讲原则**：`defaultʳ` 只找 `HasDefault` 记录，于是你可以往
instance 环境里塞别的值（比如给 `Color` 塞个 `green`）而不被误当成默认值。
对没有实例的类型用 `defaultʳ`（探针实测）：

```text
No instance of type HasDefault Color was found in scope.
when checking that the expression defaultʳ has type Color
```

再举个「实例上下文里的通用代数函数」——加法幺半群：

```agda
record AdditiveMonoid (A : Set) : Set where
  field
    _⊕_ : A → A → A
    ε   : A

open AdditiveMonoid ⦃ ... ⦄

instance
  ℕ-add : AdditiveMonoid ℕ
  ℕ-add = record { _⊕_ = _+_; ε = zero }

double : {A : Set} → ⦃ AdditiveMonoid A ⦄ → A → A
double a = a ⊕ a

_ : double 21 ≡ 42      -- ℕ-add 自动补齐，_⊕_ 就是 _+_
_ = refl
```

**自动 vs 手动**：`display 3` 走的是自动搜索；你也可以显式传实例
`display {A = ℕ} ⦃ showℕ ⦄ 7`，把「关掉自动搜索、自己点名」的样子摆出来。
两种写法结果一致，但后者在多实例场景里能消歧（见 38.4）。

## 38.4 多实例冲突：OVERLAPPABLE / OVERLAPPING / INCOHERENT

一旦同一类型注册了两个实例，实例搜索就不知道选谁。探针里把 `Show ℕ`
写了两份（`showℕ₁`、`showℕ₂`），`display 3` 立刻卡住（实测）：

```text
Failed to solve the following constraints:
  Resolve instance argument _r_6 : Show ℕ
  Candidates
    showℕ₁ : Show ℕ
    showℕ₂ : Show ℕ
    (stuck)
```

`Candidates` 后面那串就是手册「找候选」算出的初始候选；`(stuck)` 表示④
「消解重叠」谁也压不住谁、⑤ 落到「多个非-incoherent 候选 → 推迟」，最终
没能定夺。三个重叠标注 pragma 的语义（手册 + 实测）：

- `{-# OVERLAPPING #-}`：本实例比同型的别的更特殊，优先选它。
- `{-# OVERLAPPABLE #-}`：本实例接受被更特殊的盖过。
- `{-# OVERLAPS #-}`：两个都是（既能盖人也能被盖）。
- `{-# INCOHERENT #-}`：落到上面⑤的情形 1/2——有多个就**任选**，不再报错。

实测要点（反直觉、务必记住）：**对「完全同型的两个实例」，OVERLAPPING /
OVERLAPPABLE 消解不了**，因为二者一样特殊、谈不上「严格更特殊」。探针里
给 `showℕ₁` 标 OVERLAPPABLE、`showℕ₂` 标 OVERLAPPING，报错文案带着标签却
照样 `(stuck)`：

```text
  Resolve instance argument _r_11 : Show ℕ
  Candidates
    [overlappable] showℕ₁ : Show ℕ
    [overlapping] showℕ₂ : Show ℕ
    (stuck)
```

真正能压住「同型多实例」的只有 `INCOHERENT`（任选其一），或干脆**别让它们
同型**（用 record 参数化去命名空间，见 38.3 / 38.5）。

## 38.5 实例可见性与作用域

实例是**按模块作用域**的，且可见性**依赖声明顺序**——这是全章最容易踩的坑。

`private instance` 只在当前模块及其子模块可见，不导出到外部。手册的经典例子
（本示例 `TmpProbe38B6` 复刻）：先在模块 `M` 里 `private instance defaultNat`，
`open M` 之后**再**在全局 `instance defaultNat`——两者不冲突，因为 `M.test₁`
引用时只看得见 `M` 的那个，全局那个是**之后**才声明的：

```agda
module M where
  private
    instance
      defaultNat : Default ℕ
      defaultNat .default = 6
  test₁ : ℕ
  test₁ = default          -- 拿到 6

open M

instance
  defaultNat : Default ℕ   -- 顺序关键：在 M 之后声明
  defaultNat .default = 42

test₂ : ℕ
test₂ = default            -- 拿到 42，不与 M 里的 private 实例冲突
```

同一份定义、换个 `let instance` 就翻车：`let` 里的实例和**已存在**的顶层实例
会同型共存，触发 38.4 的 `(stuck)` 冲突。`private` 靠的是「看不见即不冲突」，
`let` 靠的是「作用域嵌套」，两者语义不同，别混用。

> 坑：把裸类型实例（`instance myNat : ℕ; myNat = 0`）写在顶层，会污染**所有**
> 子模块里 `⦃ A ⦄`（A=ℕ）的搜索。本示例把 `default-ℕ`/`default-Bool` 关进
> `InstanceBasics` 模块、把 `it-old-ℕ` 关进 `OldSyntax` 模块，正是为了避免
> 「两个 ℕ 实例同处一个可见域」导致的 stuck（实测过一次，删掉隔离就复现冲突）。

## 38.6 用实例「自动」推 ≤：构造子即实例

instance 也能带隐式参数、甚至**递归地再请求实例搜索**。Maguire 书里把 `≤`
的两个构造子 `z≤n`/`s≤s` 写成实例，`find-s≤n` 内部又用 `⦃ m ≤ n ⦄` 请搜索
帮它找子证明，于是 `10 ≤ 20` 这种具体不等式能被**自动推导**出来：

```agda
private instance
  find-z≤n : {n : ℕ} → zero ≤ n
  find-z≤n = z≤n

  find-s≤n : {m n : ℕ} → ⦃ m ≤ n ⦄ → suc m ≤ suc n
  find-s≤n ⦃ m≤n ⦄ = s≤s m≤n

_ : 10 ≤ 20
_ = default        -- default 只是把搜到的证明原样返回
```

这里 Agda 递归展开 `find-s≤n` 十次、最后落在 `find-z≤n`，得到一棵
`s≤s (s≤s … z≤n)` 的证明树。对照：`Data.Nat` 里 `<`/`≤` 的**决策过程**
`_≤?_` 会用 `just`/`nothing` 给回可判结果；实例搜索这条路是「**证明确**自动
拼」，不是「决策」——它只会拼成功，拼不出就 `(stuck)`/报无候选。

手册用同一招演示了「构造子即实例」的证明塔（本示例 38.15 复刻）。

## 38.7 2.9 内置 `instance refl`：it 一键收平凡等式

Agda 2.9.0 的内置 `Agda.Builtin.Equality` 把 `refl` 同时标成了
`instance refl : x ≡ x`。于是任何**形式上就是 `t ≡ t`** 的平凡等式，都能被
实例搜索直接解出——再配上把手册里那条返回搜索结果的万能函数：

```agda
it : ∀ {a} {A : Set a} → ⦃ A ⦄ → A
it ⦃ x ⦄ = x

_ : 3 ≡ 3
_ = it              -- 内置 instance refl 被 it 捞出、原样返回
```

对照 14/34 章的 `≡-Reasoning`：那套链是给人读的分步推进；`it`/`refl` 是
给机器的「这步显然、你自己算平」。本示例 `ClockArithmetic` 里
`10+3≡1 = refl` 就是靠「`⊕₁₂` 计算化简到 `# 1`」这条路把 `≡` 的目标算成
`# 1 ≡ # 1` 再 `refl` 收尾。

目标不成立时 `it` 的报错（探针实测）：

```text
No instance of type 3 ≡ 4 was found in scope.
when checking that the expression it has type 3 ≡ 4
```

## 38.8 record 即 Σ：ℕ/nℕ 的商模型

回到本章的「真问题」。数学上「`a ≡ b (mod n)`」定义为「`a − b` 是 `n` 的整数倍」，
但 ℕ 上没减法，Maguire 把等式两边一挪得到可表示的形式：

```
a + x·n = b + y·n      （存在自然数 x, y）
```

「存在 x, y 使……」在 Agda 里就是一枚 **Σ 型 record**——字段即见证元：

```agda
module ℕ/nℕ (n : ℕ) where
  record _≈_ (a b : ℕ) : Set where
    constructor ≈-mod
    field
      x y : ℕ
      is-mod : a + x * n ≡ b + y * n
  infix 4 _≈_
```

`_≈_` 参数化在 `a b` 上、却**内含** `x y`——这正是「∃ x y. …」的形状。**模式
匹配一个 `_≈_` 值，就同时抽出了见证元 `x`、`y` 和那条命题等式 `is-mod`**，
这是后面「抠见证元证传递」的关键。

自反性：取 `x = y = 0`，`a + 0·n ≡ a + 0·n` 就是 `refl`：

```agda
  ≈-refl : ∀ {a} → a ≈ a
  ≈-refl = ≈-mod 0 0 refl
```

对称性：把 `is-mod` 那条等式 `sym` 一下、顺便交换 `x`/`y` 的名字：

```agda
  ≈-sym : ∀ {a b} → a ≈ b → b ≈ a
  ≈-sym (≈-mod x y p) = ≈-mod y x (sym p)
```

## 38.9 Deriving Transitivity：从证明里抠出见证元

传递性是本章最硬的一块。给定

```
a + x·n = b + y·n
b + z·n = c + w·n
```

要凑出见证元 `p, q` 使 `a + p·n = c + q·n`。纸上消元（书里推的）：

```
a + x·n − y·n = b = c + w·n − z·n
⟹ a + x·n + z·n = c + w·n + y·n
⟹ a + (x+z)·n = c + (w+y)·n
即 p = x + z,  q = w + y
```

难点不只是算出 `p q`，还得**向 Agda 证明这确实是解**。两条引理负责代数搬运：

```agda
  lemma₁ : (a x z : ℕ) → a + (x + z) * n ≡ (a + x * n) + z * n
  lemma₁ a x z = begin
    a + (x + z) * n    ≡⟨ cong (a +_) (*-distribʳ-+ n x z) ⟩
    a + (x * n + z * n) ≡⟨ sym (+-assoc a _ _) ⟩
    (a + x * n) + z * n ∎
    where open ≡-Reasoning

  lemma₂ : (i j k : ℕ) → (i + j) + k ≡ (i + k) + j
  lemma₂ i j k = begin
    (i + j) + k ≡⟨ +-assoc i j k ⟩
    i + (j + k) ≡⟨ cong (i +_) (+-comm j k) ⟩
    i + (k + j) ≡⟨ sym (+-assoc i k j) ⟩
    (i + k) + j ∎
    where open ≡-Reasoning
```

> 书中用的是自定义 prelude 的 `≡-Reasoning`；本教程直接 `open import`
> `Relation.Binary.PropositionalEquality` 里同名模块，`*-distribʳ-+`、`+-assoc`、
> `+-comm`、`+-identityʳ`、`+-suc`、`*-comm`、`suc-injective` 全是
> `Data.Nat.Properties` 的现成引理——书里那些「章前提」在 stdlib 里都有对应。

主证明：两条 `_≈_` 一模式匹配，见证元 `x y z w` 和等式 `pxy pzw` 就落进上下文，
按纸面解塞进 `≈-mod (x+z) (w+y) …`：

```agda
  ≈-trans : ∀ {a b c} → a ≈ b → b ≈ c → a ≈ c
  ≈-trans {a} {b} {c} (≈-mod x y pxy) (≈-mod z w pzw) =
    ≈-mod (x + z) (w + y)
      (begin
        a + (x + z) * n     ≡⟨ lemma₁ a x z ⟩
        (a + x * n) + z * n ≡⟨ cong (_+ z * n) pxy ⟩
        (b + y * n) + z * n ≡⟨ lemma₂ b (y * n) (z * n) ⟩
        (b + z * n) + y * n ≡⟨ cong (_+ y * n) pzw ⟩
        c + w * n + y * n   ≡⟨ sym (lemma₁ c w y) ⟩
        c + (w + y) * n     ∎)
      where open ≡-Reasoning
```

三件套齐了，`_≈_` 是等价关系，打包成 `IsEquivalence` 与 `Setoid`：

```agda
  ≈-isEq : IsEquivalence _≈_
  ≈-isEq = record { refl = ≈-refl; sym = ≈-sym; trans = ≈-trans }

  mod-setoid : Setoid 0ℓ 0ℓ
  mod-setoid = record
    { Carrier = ℕ; _≈_ = _≈_; isEquivalence = ≈-isEq }

  module ModReasoning where
    open SetoidReasoning mod-setoid public
```

> 对照 stdlib：书里说「`_≈_` 显然是等价关系，因为它是命题等式的一个特例」，
> 但**它并不能靠 `refl` 模式反转得到**——`_≈_` 是带见证元的 record，两侧被 `_+_`、
> `_*_` 卡住不约化，`refl` 无法从 `a ≈ b` 里反解出 `x y`。所以 Maguire 只能像上面
> 那样**显式凑见证元**。这与 stdlib 里 `Data.Fin.Properties` 用**点模式（dot pattern）**
> 从 `fromℕ<` 的类型里反抽证明（如 `toℕ-fromℕ<`）是两种风味：前者从数据 record
> 抠字段，后者从索引/点掉参数抠证明。

## 38.10 加法的同余

有了 `≡`（等价关系 + 推理链），先证两个「平凡」事实，再上主力。`0 ≈ n` 取
`x = 1, y = 0`：`0 + 1·n ≡ n + 0·n` 两侧都化简到 `n`：

```agda
  0≈n : 0 ≈ n
  0≈n = ≈-mod 1 0 refl
```

`suc` 保 `_≈_`——注意 `_≈_` **没有通用 `cong`**，只能手抠见证元：

```agda
  suc-cong-mod : ∀ {a b} → a ≈ b → suc a ≈ suc b
  suc-cong-mod (≈-mod x y p) = ≈-mod x y (cong suc p)

  suc-injective-mod : ∀ {a b} → suc a ≈ suc b → a ≈ b
  suc-injective-mod (≈-mod x y p) = ≈-mod x y (suc-injective p)
```

> 为什么 `_≈_` 没有通用 `cong`？书里给了漂亮的反例：若对任意函数都能抬 `cong`，
> 拿 `_∸ 1`（截断减一）去抬 `0 ≈ 5 (mod 5)`（真），就会得到 `4 ≈ 4`——不，会得到把
> 一侧 `0` 变 `0`、另一侧 `5` 变 `4` 的**假**命题。等价关系不像命题等式那样对任意
> 函数保持，所以同余得**逐个函数**证。这正是「为什么不能把 `cong` 用在 `_≈_` 上」的
> 现代同伦类型论动机（书末也点了这句）。

`a ≈ 0 ⟹ a + b ≈ b`（对 `b` 归纳，链里 `_≡⟨_⟩_`（命题步）与 `_≈⟨_⟩_`（模步）
混用，靠的正是 `SetoidReasoning` 同时导出两套语法）：

```agda
  +-zero-mod : (a b : ℕ) → a ≈ 0 → a + b ≈ b
  +-zero-mod a zero    a≈0 = begin
    a + zero  ≡⟨ +-identityʳ a ⟩
    a         ≈⟨ a≈0 ⟩
    zero      ∎
  +-zero-mod a (suc b) a≈0 = begin
    a + suc b    ≡⟨ +-suc a b ⟩
    suc a + b    ≡⟨⟩
    suc (a + b)  ≈⟨ suc-cong-mod (+-zero-mod a b a≈0) ⟩
    suc b        ∎
```

主结果——`+` 保 `_≈_`（对两边做 `zero`/`suc` 分情形）：

```agda
  +-cong₂-mod : ∀ {a b c d} → a ≈ b → c ≈ d → a + c ≈ b + d
  +-cong₂-mod {zero} {b} {c} {d} pab pcd = begin
    c         ≈⟨ pcd ⟩
    d         ≈⟨ ≈-sym (+-zero-mod b d (≈-sym pab)) ⟩
    b + d     ∎
  +-cong₂-mod {suc a} {zero} {c} {d} pab pcd = begin
    suc a + c ≈⟨ +-zero-mod (suc a) c pab ⟩
    c         ≈⟨ pcd ⟩
    d         ∎
  +-cong₂-mod {suc _} {suc _} {c} {d} pab pcd =
    suc-cong-mod (+-cong₂-mod (suc-injective-mod pab) pcd)
```

书里特别强调这里的**对比**：证传递性时你得纸面手算 `x y`；如今有了传递性，
`+-cong₂-mod` 只需丢几个小引理、让 Agda 自己去算见证元。抽象层次上去了。

> 本教程移植时把书里 chain 中的 `sym` 换成 `≈-sym`：因为顶层已 import 命题等式的
> `sym`（见 38.14 的同名冲突教训），`_≈_` 侧的对称一律用带限定意义的 `≈-sym`，避免
> `AmbiguousName`。

## 38.11 乘法的同余

乘法同余更繁，但结构一致：先 `*-zero-mod` 再 `*-cong₂-mod`。书里算了「raw」
解的账：给定两条同余式，要凑 `ac + p·n = bd + q·n`，解是

```
p = c·x + a·z + x·z·n
q = d·y + b·w + y·w·n
```

——约 50 步代数搬运。但有了 `_≈_` 这套等价关系 + `ModReasoning`，Agda 把见证元
全包了，人只写引理摆链：

```agda
  *-zero-mod : (a b : ℕ) → b ≈ 0 → a * b ≈ 0
  *-zero-mod zero    b b≈0 = ≈-refl
  *-zero-mod (suc a) b b≈0 = begin
    suc a * b ≡⟨⟩
    b + a * b ≈⟨ +-cong₂-mod b≈0 (*-zero-mod a b b≈0) ⟩
    0         ∎

  *-cong₂-mod : ∀ {a b c d} → a ≈ b → c ≈ d → a * c ≈ b * d
  *-cong₂-mod {zero} {b} {c} {d} a≈b c≈d = begin
    zero * c ≡⟨⟩
    zero     ≈⟨ ≈-sym (*-zero-mod d b (≈-sym a≈b)) ⟩
    d * b    ≡⟨ *-comm d b ⟩
    b * d    ∎
  *-cong₂-mod {suc a} {zero} {c} {d} a≈b c≈d = begin
    suc a * c ≡⟨ *-comm (suc a) c ⟩
    c * suc a ≈⟨ *-zero-mod c (suc a) a≈b ⟩
    zero      ≡⟨⟩
    zero * d  ∎
  *-cong₂-mod {suc a} {suc b} {c} {d} a≈b c≈d = begin
    suc a * c ≡⟨⟩
    c + a * c ≈⟨ +-cong₂-mod c≈d
                       (*-cong₂-mod (suc-injective-mod a≈b) c≈d) ⟩
    d + b * d ≡⟨⟩
    suc b * d ∎
```

`≡⟨⟩` 那几步（如 `suc a * c ≡⟨⟩ c + a * c`）是**定义式**步——靠的是内置 ℕ 的
`_*_` 递归**第一个**参数（`zero * m = zero; suc n * m = m + n * m`），书里的
`≡⟨⟩` 搬运能一比一对上 stdlib 的 `_+_`/`_*_`。

## 38.12 Fin 模型与 stdlib Data.Fin 对照

商模型适合**证明**，但算起来见证元越堆越大。做**计算**（时钟、循环）更实用的是
`Fin n` 模型：把整数表示成 `Fin (suc n)`，运算后再取模装回。

```agda
module ClockArithmetic where
  open import Data.Fin using (Fin; toℕ; fromℕ<; #_)
  open import Data.Nat.DivMod using (m%n<n)

  +Mod : ∀ {n} → Fin (suc n) → Fin (suc n) → Fin (suc n)
  +Mod {n} i j =
    fromℕ< {m = (toℕ i + toℕ j) % (suc n)} (m%n<n (toℕ i + toℕ j) (suc n))
```

这里有个**活生生的 stdlib 实例用法**：`_%_` 的类型带一个
`.{… {{_ : NonZero n}}}` 的实例参数（`NonZero` 是 `Data.Nat.Base` 里的
record，`instance nonZero : ∀ {n} → NonZero (suc n); nonZero = _`）。因为除数
写成 `suc n` 形式，`NonZero (suc n)` 被 `nonZero` 这个**内置实例自动补齐**，
调用处根本不用手写它。注意：stdlib 源码里仍用旧式 `{{ }}`（截至 3.0 未全量
改 `⦃ ⦄`），但不影响你在自己代码里用新语法。

「10 点过 3 小时是 1 点」直接 `refl` 算平（12 小时制，载体算子把界钉成 `Fin 12`）：

```agda
  infixl 8 _⊕₁₂_ _⊗₁₂_
  _⊕₁₂_ : Fin 12 → Fin 12 → Fin 12
  _⊕₁₂_ = +Mod

  10+3≡1 : # 10 ⊕₁₂ # 3 ≡ # 1
  10+3≡1 = refl
```

对照 stdlib `Data.Fin` 自带的 `_+_`：**它不做模**，而是把上界一起加——
`_+_ : (i : Fin m) (j : Fin n) → Fin (toℕ i ℕ.+ n)`。所以 `10 +F 3` 落在
`Fin 22` 而不是 `Fin 12`：

```agda
  open import Data.Fin using () renaming (_+_ to _+F_)
  ten : Fin 12
  ten = # 10
  three : Fin 12
  three = # 3
  越界 : Fin 22
  越界 = ten +F three
  越界-值 : toℕ 越界 ≡ 13
  越界-值 = refl
```

> stdlib 3.0 实测清点：`Data.Fin` **有** `_+_`（就是上面那个「加界」版，非模），
> **没有** `_*_`（无内置 Fin 乘法）；**没有** `fromℕ≤`（旧名，已移除），装回用
> `fromℕ< : .(m ℕ.< n) → Fin n`。`#_` 是字面量前缀（`# 10 : Fin 11` 之类）。
> `Data.Fin.Properties` 里的 `toℕ-fromℕ< : ∀ .(m<n : m ℕ.< n) → toℕ (fromℕ< m<n) ≡ m`
> 本身就用了**点模式**——它是 stdlib 亲写的「从证明里抠值」的范例，本示例
> `toℕ-+Mod` 直接拿来即用。

> 坑：`# 10 {n = 12}` 会被解析成 `# (10 {n = 12})`（把 `10` 当函数应用），报
> `CannotApply: Expression used as function but does not have function type: expr: 10,
> type: ℕ`。`#_` 的**界由期望类型决定**，不要显式给它传 `{n = …}`；用具名绑定
> （`ten : Fin 12; ten = # 10`）或把运算写成带类型的载体算子来喂期望类型。

## 38.13 Automating Proofs：ring solver 两条路径

手写 `*-cong₂-mod` 固然 instructive，但「这类恒等式本不该人肉推」。Agda 的
**环求解器**能一键收工（对照 34 章）。3.0 主推 tactic 路线：

```agda
module Automation where
  open import Data.Nat.Tactic.RingSolver using (solve-∀)

  gnarly : (a c n x z : ℕ) →
           a * c + (c * x + a * z + x * z * n) * n
           ≡ c * (a + x * n) + z * n * (a + x * n)
  gnarly = solve-∀
```

> 坑：`solve-∀`（`Data.Nat.Tactic.RingSolver`）只能作**裸右侧**用。若写成
> `gnarly a c n x z = solve-∀`（左边带模式变量），求解器会把模式变量当常量、
> 报「`a` 与 `c` 不相等」之类的假失败。正确姿势：整条定义 `gnarly = solve-∀`。

书里附录用的是**旧式语法树**路线，直接搬两侧的词（`:*` 乘、`:+` 加、`:=` 等号）：

```agda
  open import Data.Nat.Solver
  open +-*-Solver

  gnarly′ : (a c n x z : ℕ) →
            a * c + (c * x + a * z + x * z * n) * n
            ≡ c * (a + x * n) + z * n * (a + x * n)
  gnarly′ = solve 5
    (λ a c n x z →
       a :* c :+ (c :* x :+ a :* z :+ x :* z :* n) :* n
       := c :* (a :+ x :* n) :+ z :* n :* (a :+ x :* n))
    refl
```

> 坑：`module NPS = +-*-Solver` 然后 `NPS.solve …` 会 `NotInScope: :*`——那些
> 语法符号只在 `open +-*-Solver` 后才进作用域。要么老实 `open`，要么把 `:= :+ :*`
> 全限定。两条路线在 3.0 都能编过（本示例 `./build.sh` 实测），tactic 路线更短、
> 旧语法路线更显式。

## 38.14 IsEquivalence 与重载 refl/sym/trans（2.9 的坑）

书 5.1 的收尾绝活：把 `IsEquivalence` 的字段 `refl/sym/trans` 用
`open IsEquivalence ⦃ ... ⦄` 变成**按关系自动重载**的顶层函数，从此
不管证 `≡` 还是 `≈` 还是 `~`，都写 `refl`，让实例搜索去分辨。这正是全章
「太多同名 `refl`」问题的解药。核心是那条把 `IsEquivalence` 喂进实例环境：

```agda
  instance ~-is-eq : IsEquivalence _~_
  ~-is-eq = isEq-~

  open IsEquivalence ⦃ ... ⦄

  _ : 4 ~ 4
  _ = IsEquivalence.refl ~-is-eq     -- 本示例用限定访问，见下方坑
  _ : ∀ {x y} → x ~ y → y ~ x
  _ = IsEquivalence.sym ~-is-eq
```

> 2.9 实测大坑：在一个**已经** `open import Relation.Binary.PropositionalEquality
> using (refl; sym; trans)` 的模块里再 `open IsEquivalence ⦃ ... ⦄`，然后裸写
> `refl`，会撞车。两条实测文案：
>
> ① 作用域检查期就 `AmbiguousName`：
> ```text
> Ambiguous name refl. It could refer to any one of
>   …Overloaded-≈.refl …
>   _≡_.refl … (its definition at …/Agda/Builtin/Equality.agda:7.12-16)
> ```
> 因为 2.9 的内置 `Agda.Builtin.Equality` 自带 `instance refl : x ≡ x`，和
> `open IsEquivalence` 造出来的重载 `refl` 同名共存。
>
> ② 若你把 `_≡_` 的 `IsEquivalence` 也注册成 instance，还会退化成一堆**元变量解不出**：
> ```text
> Failed to solve the following constraints:
>   _A_3 = ℕ : Set _a_1 (blocked on _A_3)
>   _a_1 = Level.zero (blocked on _a_1)
> ```
>
> 结论：**≡ 侧直接用内置 `refl` 就行，别再 `open IsEquivalence` 去重载它**；重载
> `refl` 只在「该关系不是命题等式、且顶层没 import 命题 `refl`」时才干净。字段即
> 重载函数的机制本身没问题（`open Show ⦃ ... ⦄`、`open HasDefault ⦃ ... ⦄` 都靠它），
> 本示例对 `_~_` 用限定访问 `IsEquivalence.refl ~-is-eq` 绕开与内置 `refl` 的重名。

对照 stdlib：`Relation.Binary.PropositionalEquality.isEquivalence`（注意 3.0 里
**没有** `≡-isEquivalence` 这个旧名，就叫 `isEquivalence`）是 `IsEquivalence _≡_`
的现成实例；`IsEquivalence` 是 `Relation.Binary.Structures` 里的三字段 record
（`refl : Reflexive _≈_`；`sym : Symmetric _≈_`；`trans : Transitive _≈_`），比
`IsPreorder` 少一层。书里那句 `equiv-to-preorder : ⦃ IsEquivalence _~_ ⦄ →
IsPreorder _~_` 在 stdlib 里要写成 `⦃ IsEquivalence _≈_ ⦄ → IsPreorder _≈_ _≈_`
（3.0 的 `IsPreorder` 收**两个**关系），且一般用 `Setoid` 打包更省事——本示例
`mod-setoid` 走的就是这条路。

## 38.15 证明塔：--backtracking-instance-search

手册压轴：`data` 的构造子也能标 `instance`，配合实例搜索做「回溯」，就能
机械地判定「`x` 是否在表里」这类**证明塔**问题。

```agda
  open import Data.List using (List; _∷_; [])
  infix 4 _∈_
  data _∈_ {A : Set} (x : A) : List A → Set where
    instance
      hereX  : ∀ {xs} → x ∈ x ∷ xs
      thereX : ∀ {y xs} → ⦃ x ∈ xs ⦄ → x ∈ y ∷ xs

  ex₁ : 1 ∈ 1 ∷ 2 ∷ 3 ∷ 4 ∷ []
  ex₁ = it          -- it = ⦃ A ⦄ → A，把搜到的证明塔捞出
```

默认实例搜索**不回溯**：`thereX` 需要子目标 `1 ∈ 2 ∷ 3 ∷ 4 ∷ []`，而它又需要
`thereX`……在 `1` 命中 `hereX` 之前会先撞上歧义而 `(stuck)`。打开文件级选项
`{-# OPTIONS --backtracking-instance-search #-}`（对应手册③第 4 步「递归对 `Δ`
里的实例变量再搜」）后，`it` 就能逐层回溯、把 `thereX (thereX (thereX hereX))`
自动拼出来。

> 坑（两条，均实测）：
> ① 忘写 `infix 4 _∈_`：`_∈_` 默认结合强度 20，比 `⦃∷⦄`（右结合 5）**更紧**，
> `x ∈ x ∷ xs` 被解析成 `(x ∈ x) ∷ xs`，索引 `List _A_` 落到「本该是个 sort」的
> 位置，报 `ShouldBeASort: List _A_8 should be a sort, but it isn't`。关系类
> data 一律先声明 `infix`。
> ② `--backtracking-instance-search` 得是**文件级** OPTIONS，不能局部开；本示例
> 把这段以注释保留，避免为它给整个 `Ex38_modular` 改编译选项（正文探针
> `TmpProbe38F` 单独带上该 pragma 实测 `ex₁ = it` 通过）。

## 坑位清单（本项目实测）

1. **`0 != 1 of type ℕ` 是 2.8 老文案**：2.9 的不相等错误改写成整句
   `The terms 0 and 1 are not equal at type ℕ`。别照抄旧教程的报错。
2. **裸类型实例污染全局搜索**：`instance myNat : ℕ` 会和任何 `⦃ A ⦄`（A=ℕ）抢。
   用 record（`HasDefault A`/`Show A`）把默认值包一层，或干脆关进独立 module。
3. **实例可见性靠声明顺序**：`private instance`（看不见即不冲突）与 `let instance`
   （作用域嵌套）语义不同。手册「先 M 再全局」的例子成立，全靠全局那个**后**声明。
4. **同型两实例，OVERLAPPABLE/OVERLAPPING 压不住**：得「严格更特殊」才行，同型
   谈不上严格。能压的只有 `INCOHERENT`（任选）或消歧（`display {A = ℕ} ⦃ showℕ ⦄ 7`）。
5. **2.9 内置 `instance refl` 与 `open IsEquivalence ⦃ ... ⦄` 抢名字**：≡ 侧别重载
   `refl`，直接写内置 `refl`；重载只对非命题、且顶层没 import 命题 `refl` 的 `~` 干净。
6. **`_≈_` 带见证元 → 不能用 `refl` 模式反转**：`x`、`y` 被 `_+_`/`_*_` 卡住不约化，
   传递性只能纸面凑 `p = x+z`、`q = w+y` 再显式 `≈-mod` 塞进去。
7. **`_≈_` 没有通用 `cong`**：等价关系不像命题等式对任意函数保持，`suc`/`+`/`*` 的
   保序性得逐个手写（`suc-cong-mod`、`+-cong₂-mod`、`*-cong₂-mod`）。
8. **`solve-∀` 必须裸右侧**：左边带模式变量（`gnarly a c n = solve-∀`）会假失败
   报「变量不相等」；要么 `gnarly = solve-∀`，要么回退旧式 `solve 5 (…) refl`。
9. **`-*-Solver` 的 `:* :+ :=` 要 `open`**：`module NPS = +-*-Solver` 再 `NPS.solve`
   会 `NotInScope`；语法符号只在 `open +-*-Solver` 后进入作用域。
10. **`#_` 的界只能从期望类型来**：`# 10 {n = 12}` 解析成 `# (10 {n=12})` 报
    `CannotApply`；用具名绑定或带类型的载体算子喂期望类型。
11. **stdlib `Data.Fin._+_` 不是模加**：它把上界相加（`Fin (toℕ i + n)`），
    `_*_`、`fromℕ≤` 在 3.0 里**不存在**；模算术得自己写 `+Mod`，取模装回用
    `fromℕ<`，除数写成 `suc n` 让内置 `instance nonZero` 自动补 `NonZero`。
12. **关系类 data 要先声明 `infix`**：漏了 `infix 4 _∈_` 会因结合强度把类型式解析
    畸形，报 `ShouldBeASort: List _A_8 should be a sort`。回溯式实例搜索
    （`--backtracking-instance-search`）是**文件级**选项，不能局部开关。

---
上一章：[37 · pattern 同义词与差分整数](37-pattern-synonyms.md) ｜下一章：[39 · intrinsic 与 extrinsic 证明](39-intrinsic-extrinsic.md)｜返回：[README](../README.md)
