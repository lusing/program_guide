# 09 · 记录与 Σ 类型

第 06–08 章我们造的都是「多变体」数据：`Bool` 有两个构造子、`List` 有
`[]` 和 `_∷_` 两个构造子。但依赖类型编程里出场频率更高的其实是另一极：
**只有一种构造方式的数据**——坐标、配置、代数结构、以及最要紧的
「数据 + 对该数据的证明」。这类东西在 Agda 里由两样语法承载：`record`
和 `Σ`。本章把两者掰开揉碎：record 的字段怎么声明、怎么访问、eta 契约
强到什么程度（强到 `refl` 就能证明「拆开再装回去等于原物」）；Σ 为什么
**字面上就是**一个两字段的内建 record（我们把源码翻给你看）；以及
「函数即记录、记录即接口」这条通往 18 章代数库的暗线。

对应示例：`../examples/Ex09_records.agda`

本章所有代码片段均与示例文件一致；报错文本均为 Agda 2.8.0 + stdlib 2.3
实测原样粘贴。

## 9.1 record 语法解剖

声明一个 record，就是声明「字段名 → 字段类型」的清单：

```agda
record Point : Set where
  field
    posX : ℕ
    posY : ℕ
```

实例化用匿名记录表达式 `record { … }`，**字段顺序随意**；只有能被约束
反推出来的字段（如 instance 字段）才允许省略，一般字段一个不能少：

```agda
origin : Point
origin = record { posX = 0; posY = 0 }

p : Point
p = record { posX = 3; posY = 4 }
```

字段访问有三种等价写法：

```agda
_ : p .posX ≡ 3          -- 点前缀（Haskell 味）
_ : Point.posY p ≡ 4     -- 限定投影名当普通函数用
_ : posX p ≡ 3           -- open Point 之后，投影直接进作用域
```

三者其实是同一个东西：`Point.posX : Point → ℕ` 是一个真实存在的**函数**，
点记法 `p .posX` 只是 `posX p` 的另一种书写。这里藏着本章第一个实测坑：

```text
/home/xulun/code/programming/agda/examples/TmpD1.agda:13.8-12: error: [NotInScope]
Not in scope:
  posX
  at /home/xulun/code/programming/agda/examples/TmpD1.agda:13.8-12
    (did you mean
       'Point.posX' or
       'Point.posY'?)
when scope checking posX
```

`p .posX` 里的 `posX` **也必须先在作用域里**——和 Haskell「定义即自带
访问器」不同，Agda 的投影默认只以 `Point.posX` 的限定名存在，想打点必须
先 `open Point`。报错还算体贴，直接给你 did-you-mean。

更新语法（其余字段沿用原记录）：

```agda
p′ : Point
p′ = record p { posX = 10 }

_ : p′ .posX ≡ 10
_ = refl

_ : p′ .posY ≡ 4
_ = refl
```

字段声明支持同行多名共享类型（对应示例里 `Segment` 的 `start end : Point`），
嵌套访问一路打点：`seg .end .posX ≡ 3` 照样 `refl`。

## 9.2 eta 契约：记录是「唯一同构」

Agda 的 record 附带一条比 Haskell/Coq 都硬的规则，行话叫 **η（eta）契约**：
一个记录值**完全由它的字段决定**，「拆开再装回去」和原物不是同构、不是双模拟，
而是**逐字相等**——相等证明就是 `refl`：

```agda
ηP : (q : Point) → record { posX = q .posX; posY = q .posY } ≡ q
ηP q = refl
```

`refl` 能通过，意味着类型检查器把「记录」和「它的字段 tuple」看作**同一个范式**。
后果一条比一条实用：

- **记录相等 ⟺ 逐字段相等**：`record { posX = 1; posY = 2 } ≡ record { posX = 1;
  posY = 2 }` 用 `refl`，不用归纳、不用构造子 injectivity。
- **空 record 是「至多一个值」的类型**：stdlib 的 `⊤` 就是无字段 record——
  `Data.Unit.Base` 转发的 `Agda.Builtin.Unit` 原文是
  `record ⊤ : Set where instance constructor tt`，于是
  「所有 ⊤ 的居民都相等」一行白送：

  ```agda
  η⊤ : (x : ⊤) → x ≡ tt
  η⊤ x = refl
  ```

  这条在 12 章当「平凡真」的引理用，在 11 章解释「命题证明相关吗」时也是活标本。
- 对比 `data`：如果你用 `data PairD : Set where pair : (x y : ℕ) → PairD`
  模拟同一个结构，`ηP` 这类等式就证不出来——data 值不是「字段的展开」，
  规约时不会把 `pair a b` 拆回投影。需要 eta 就写 record，这几乎是 Agda
  社区的默认答案；只有当你**需要多构造子区分情形**（像 `List` 分 `[]`/`∷`）
  时才用 data。

和 Coq/Haskell 的差异值得点名：Haskell 的 record 只是给构造子起字段名，
既无 eta 规则也无依赖字段（`data P = P {x, y :: Int}` 里 `y` 的类型不可能
依赖 `x`）；Coq 的 `Record` 声明有 eta 但历史上默认不启用、且字段依赖要靠
`Definition` 手工配 Sigma 包装。Agda 把「字段可有依赖 + eta 免费」同时做进
了语言本体。

## 9.3 依赖记录：后面的字段依赖前面的字段

record 的杀手锏是**字段间的依赖**——第二个字段的类型可以引用先声明的字段：

```agda
record DepBox : Set₁ where
  field
    Carrier : Set
    value : Carrier
```

「一个类型，外加该类型的一个值」。注意宇宙：`Carrier : Set` 说明盒子住在
高一层的 `Set₁`（05 章的宇宙阶梯在这露脸）。实例化：

```agda
b : DepBox
b = record { Carrier = ℕ; value = 42 }

_ : b .value ≡ 42
_ = refl
```

`b .value` 的类型是什么？`DepBox.value b : b .Carrier`——而 `b .Carrier`
规约后就是 `ℕ`，所以 `≡ 42` 合法。字段不仅当数据用，还当**类型层的参数**用，
这就是「依赖记录」。

## 9.4 Σ 类型：内建的两字段依赖 record

`(Σ A λ x → B x)` 读作「A 上的依赖对」：第一位 `x : A`，第二位类型是
`B x`（依赖第一位）。它是 record 最纯的原型机——**因为它就是内建 record**。
本机 Agda 2.8.0 的原始定义（`/usr/share/libghc-agda-dev/lib/prim/Agda/Builtin/Sigma.agda`）
一字不差如下：

```agda
record Σ {a b} (A : Set a) (B : A → Set b) : Set (a ⊔ b) where
  constructor _,_
  field
    fst : A
    snd : B fst
```

`snd : B fst`——第二个字段的类型依赖第一个字段，和 9.3 的 DepBox 同构。
而 stdlib 的 `Data.Product` 本体也贴出来（`Data/Product/Base.agda`）：

```agda
open import Agda.Builtin.Sigma public
  renaming (fst to proj₁; snd to proj₂)
  hiding (module Σ)
```

所以「Data.Product 就是一个 record 的门面」不是比喻，是 import 语句。
本章示例直接绕过门面用原材料，验证两套名字指的是同一批函数：

```agda
open import Agda.Builtin.Sigma using () renaming (Σ to Σ′; fst to fst₀; snd to snd₀)

q1 : Σ′ ℕ λ _ → Bool
q1 = 7 , true

_ : fst₀ q1 ≡ 7
_ = refl

_ : fst₀ q1 ≡ proj₁ q1
_ = refl
```

语法速记：

- **构造**：`constructor _,_` 意味着配对写 `7 , true`（或带括号 `( 7 , true )`，
  模式匹配时那对括号必不可少，见下）；
- **非依赖特例**：`A × B` 就是 `Σ A λ _ → B`，`ℕ × Bool` 与
  `Σ ℕ λ _ → Bool` 定义同一；
- **依赖记法**：`Σ[ x ∈ A ] B x`（由 `Σ-syntax` 提供，注意 `using` 里要带上
  `Σ-syntax` 这个名字，否则记法不生效）；
- **模式匹配**：`Σ` 值可以像记录一样在等式左边拆：

  ```agda
  fromΣ : (Σ[ S ∈ Set ] S) → DepBox
  fromΣ (S , v) = record { Carrier = S; value = v }
  ```

Σ 与依赖记录互为「同一概念的两副面孔」，示例里给了往返证明：

```agda
toΣ : DepBox → Σ[ S ∈ Set ] S
toΣ x = (x .Carrier) , (x .value)

_ : fromΣ (toΣ b) ≡ b
_ = refl
```

`refl` 通过——再次是 eta：record 字段和 Σ 的 `fst`/`snd` 被检查器视为一回事。
Σ 自己也吃 eta（因为它本来就是 record）：

```agda
ηΣ : (pr : Σ ℕ λ _ → Bool) → (proj₁ pr , proj₂ pr) ≡ pr
ηΣ pr = refl
```

一句话选型：**字段要起名字、要更新、要给人读——record；匿名短对、
当逻辑连接词用——Σ**。12 章讲 ∧ 与 ∃ 时会看到，合取就是非依赖 Σ，
存在量词就是依赖 Σ。

## 9.5 实战：带证明的排序列表（预告 12、26 章）

依赖记录最值钱的应用：**把「性质证明」当字段装进数据类型**。先用归纳定义
给出「升序」关系（13 章教这种写法，这里先当黑盒消费）：

```agda
data Sorted : List ℕ → Set where
  snil  : Sorted []
  sone  : ∀ {x} → Sorted (x ∷ [])
  scons : ∀ {x y ys} → x ≤ y → Sorted (y ∷ ys) → Sorted (x ∷ y ∷ ys)
```

然后「排序列表」有两种等价写法，务必亲手对比：

```agda
-- 写法一：依赖记录，字段 list 和它的证明 sorted
record SortedList : Set where
  field
    list   : List ℕ
    sorted : Sorted list

-- 写法二：依赖对（Σ），连字段名都省了
asΣ : Σ[ l ∈ List ℕ ] Sorted l
```

构造一个合法值需要**同时交出数据和证据**：

```agda
ok : SortedList
ok = record
  { list   = 1 ∷ 2 ∷ 3 ∷ []
  ; sorted = scons (s≤s z≤n) (scons (s≤s (s≤s z≤n)) sone)
  }
```

`[1,2,3]` 为什么升序？1≤2 一个 `s≤s z≤n`，2≤3 两个，递归搭出证明塔。
更关键的在反面：**你构造不出「[3,1,2] + 它是升序」的记录**——第二字段
要求的 `Sorted (3 ∷ 1 ∷ 2 ∷ [])` 没有任何构造方式可填，编译器直接拒收
候选值。这就是依赖类型编程的心法：非法对象不是「运行时炸」，而是
**根本没有这个类型的值**。26 章的可验证插入排序，输出的正是
`SortedList` 这种记录（届时 sorted 字段用布尔判定精化，思路不变）。

12 章的逻辑主角 `∃`（存在量词）就是依赖 Σ 的别名——示例里先尝一口：

```agda
witness : ∃ λ n → 2 ≤ n
witness = 5 , s≤s (s≤s z≤n)

_ : proj₁ witness ≡ 5
_ = refl
```

「存在 n 使 2≤n」的证明 = 数 5 + 一个不等式证据。证明即数据，数据即证明，
record/Σ 就是这对孪生体的产房。

## 9.6 record 当接口、函数即记录（预告 18 章）

record 的字段可以是**函数**。一个「迷你幺半群」就是一本运算说明书：

```agda
record MiniMonoid : Set₁ where
  field
    Carrier : Set
    _·_ : Carrier → Carrier → Carrier
    ε : Carrier

ℕ+-mono : MiniMonoid
ℕ+-mono = record { Carrier = ℕ; _·_ = _+_; ε = 0 }

_ : MiniMonoid._·_ ℕ+-mono 2 3 ≡ 5
_ = refl
```

字段 `_·_` 的**类型引用了先声明的字段 Carrier**——接口里处处是依赖记录。
对比另外两家的「接口」：Haskell 用 type class（隐式全局、one instance per
type），Coq 用 Module/Module Type（签名匹配制）；Agda 的答案最朴素：**接口
= record，实例 = 该 record 的值，派发 = 显式传参**。18 章的
`Algebra.Structures` 大家族全是这个模式放大一千倍的产物。

再往深处想一层（README 标题里「函数即记录」的下半场）：record 是「多字段
打包的函数」（每个字段名是一个访问器函数 `R → A`），而 Π 类型是「以值的
每个点为下标的无穷 record」——`∀ {n} → Fin n → Vec A n → A` 这类依赖函数
和带依赖字段的 record 在类型论里本是对偶的两极。现在只需记住实操结论：
**能用 record 表达的结构就别发明新 data；需要区分情形时才回到 data。**

顺带一个实测行为：record **体内**可以写引用字段的定义（派生值），但它会被
提升成「多收一个记录参数」的函数，而且**点记法不认它**：

```agda
record PointSum : Set where
  field
    sumX : ℕ
    sumY : ℕ
  total : ℕ
  total = sumX + sumY

open PointSum

_ : total ps ≡ 3      -- 正常用法：函数形式
_ = refl
```

写成 `ps .total` 会撞上（实测）：

```text
CannotApply: Expression used as function but does not have function type:
  expr: ps
  type: PointSum
when checking that .total is a valid argument to a function of type PointSum
```

## 9.7 嵌套与 inherit 的实测命运

嵌套记录（字段是别的记录）毫无障碍，示例里 `Sphere` 的 `center : Point`
加上一路打点的 `sph .center .posX ≡ 0` 已验证。**但「字段继承」没有**：
2.6 时代文档介绍过的 `record B where inherit A` 复用字段的机制，在本机
Agda 2.8.0 上已经不是合法关键字，两种摆放位置各撞一堵墙：

```text
error: [NotValidBeforeField]
This declaration is illegal in a record before the last field
```

（`inherit Flat` 放在 `field` 段之前；它被解析成一条普通定义，于是后面的
`field` 段「出现在定义之后」又违规。）把 `inherit Flat` 挪到最后一个 field
之后，则当场按函数左端处理：

```text
error: [MissingTypeSignature.Function]
Missing type signature for left hand side inherit Flat
when scope checking the declaration
  inherit Flat
```

结论：**别在 2.8.0 上用 inherit**；复用字段就嵌套包一层，或老老实实重抄字段
（社区替代方案如 `Data.Record` 提供的字段组合工具，27 章再议）。读老教程
撞见 inherit，第一反应应是查版本——这是本项目版敏感坑的标本。

## 9.8 坑位清单（本项目实测）

1. **点记法要求投影在作用域内**：`p .posX` 也要先 `open Point`，否则
   `NotInScope`（带 did-you-mean 提示 `Point.posX`）。
2. **派生字段 ≠ 字段**：record 体内 `total = sumX + sumY` 这类定义，open 后
   变成 `total : PointSum → ℕ`（多收记录参数），且 `ps .total` 报
   `CannotApply`——只有真字段配点号。
3. **`inherit` 在 2.8.0 已死**（两种报错见 9.7），老教程示例照抄必翻车；
   字段复用改用嵌套或手工重声明。
4. **record 表达式少写必填字段，报错不是「缺字段」而是Unsolved metas**：
   `record { posX = 1 } : Point` 实测得到
   `UnsolvedMetaVariables ... 11.7-13`，指认现场要靠脑补字段清单。
5. **Σ 有两套投影名**：内建 `fst`/`snd` 与 stdlib `proj₁`/`proj₂` 是同一函数
   的改名转发（`Agda.Builtin.Sigma` vs `Data.Product`）；混用时 import
   的 `using/renaming/hiding` 要自己理干净，示例用 `Σ′/fst₀/snd₀` 演示了
   共存姿势。
6. **`Σ[ x ∈ A ] B` 记法不是白来的**：语法挂在 `Σ-syntax` 这个名字上，
   `using` 里不带它就写不成方括号形式。
7. **证明字段要人手交**：`record { list = …; sorted = … }` 不会因为列表
   恰好有序就自动通过，编译器**不搜索**证明——26 章将用 `_≤?_` 判定 +
   `toWitness` 把这类手工塔自动化（15 章伏笔）。

---
上一章：[08 · 列表专题](08-lists.md) ｜ 下一章：[10 · 依赖类型入门：Fin](10-dependent.md) ｜ 返回：[README](../README.md)
