# 18 · 关系代数与抽象代数

16/17 章在单个类型上做文章，本章换视角：**把「一套运算 + 一堆定律」打包
成可传递、可实例化的值**。stdlib 沿两条线组织：**关系线**
（`Relation.Binary`：Setoid = 集合 + 等价关系，Preorder、Poset 逐层加序）
与**代数线**（`Algebra`：Magma/Semigroup/Monoid……= 载体 + 运算 + 定律）。
Agda **没有 type class**：Haskell 靠编译器做字典搜索，Lean 靠 type class
inference 自动补齐；Agda 的「实例」是**显式构造、显式传递的 record 值**
——相当于永远手写在参数表里的 dictionary。代价：组装时逐字段交证明；
红利：泛型定理（18.4 的 `sum`）一次编写处处可用，且 record 字段携带可
计算内容，`refl` 常能穿过整个抽象层直算到底。

对应示例：`../examples/Ex18_algebra.agda`

代码片段均与示例一致；行号与报错文本均为 Agda 2.8.0 + stdlib 2.3 实测。

## 18.0 import 地图：三组路径各管什么

示例的 import 块本身就是 stdlib 组织法的标本：

```agda
open import Level using (Level; 0ℓ; _⊔_)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; sym; trans; cong; cong₂)
import Relation.Binary.PropositionalEquality as Eq
open import Relation.Binary
  using (Setoid; Preorder; Poset; IsEquivalence; IsPreorder; IsPartialOrder)
open import Algebra using (Monoid; Semigroup)
open import Algebra.Structures using (IsMagma; IsSemigroup; IsMonoid)
```

- **`Level` 是刚需**：bundle 类型是 `Set (suc (c ⊔ ℓ))`
  （`Algebra/Bundles.agda:293`），`Monoid 0ℓ 0ℓ` 在填两个层级参数。
- **`Eq` 别名**：组装 record 要交「`_≡_` 是等价关系」的现成证明
  `isEquivalence`，它与 `Relation.Binary.Structures` 的同名记录撞车，
  故 `import … as Eq` 写 `Eq.isEquivalence`。
- **`Algebra` vs `Algebra.Structures`**：前者 re-export `Algebra.Bundles`
  ——**打包了载体**的 `Monoid c ℓ`；后者的 `IsMonoid` 是**公理记录**，
  不打包载体，整个模块以 `{A : Set a} (_≈_ : Rel A ℓ)` 为参数
  （`Algebra/Structures.agda:22-25`），`open import … using (IsMonoid)`
  时这些参数是未解 metavariable，靠 record 组装的上下文反解。
- **`Base` vs `Properties`**（09/27 章的拆分约定）：

```agda
open import Data.Nat.Base
  using (ℕ; zero; suc; _+_; _*_; _^_; _≤_; z≤n; s≤s; +-0-rawMonoid; *-1-rawMonoid)
open import Data.Nat.Properties
  using (≤-poset; ≤-preorder; ≤-refl; ≤-reflexive; +-assoc; +-monoˡ-≤; +-monoʳ-≤; m≤n+m; +-0-monoid; *-1-monoid; ^-distribˡ-+-*)
open import Data.List.Base
  using (List; _∷_; []; _++_; map; length; ++-[]-rawMonoid)
open import Data.List.Properties
  using (++-assoc; ++-identityˡ; ++-identityʳ; ++-monoid; length-++)
open import Data.Bool.Base using (Bool; true; false)
open import Data.Product using (_×_; _,_)
open import Function.Base using (id; _∘_)
```

  `Base` 放定义与**可计算内容**（含只带签名不带证明的 raw bundle，如
  `+-0-rawMonoid`，18.5 详谈）；`Properties` 放定律与**装好的完整
  bundle**（`+-0-monoid`、现成 `≤-poset`，且 `++-monoid` 要类型参数）。

## 18.1 关系的三层包装：Setoid ⊂ Preorder ⊂ Poset

`Relation/Binary/Bundles.agda:40` 的 `record Setoid c ℓ` 就三个字段：
`Carrier : Set c`、`_≈_ : Rel Carrier ℓ`、`isEquivalence :
IsEquivalence _≈_`。拿 Bool 手工做一个「以 `_≡_` 为等式」的 Setoid：

```agda
Bool≡-setoid : Setoid 0ℓ 0ℓ
Bool≡-setoid = record
  { Carrier       = Bool
  ; _≈_           = _≡_
  ; isEquivalence = record { refl = refl; sym = sym; trans = trans }
  }
```

`isEquivalence` 又嵌一层 record（自反、对称、传递三个函数；stdlib 为
`_≡_` 备好即 `Eq.isEquivalence`，手写只为看清字段）。现成结构用**具名
模块实例化**整体展开（`Data.Nat.Properties` 交付
`≤-poset : Poset 0ℓ 0ℓ 0ℓ`）：

```agda
module ≤P = Poset ≤-poset

_ : ≤P.Carrier ≡ ℕ
_ = refl
```

`Carrier` 只是记录投影，`Poset ≤-poset` 算完就是 `ℕ`，refl 白送——
「bundle 是值」的最小证据。层次是 record 套 record + `public` 上提拼出来
的（`Bundles.agda:166-174`）：`record Poset` 四字段，`IsPartialOrder` 嵌
`IsPreorder` 加 `antisym`；`IsPreorder`
（`Relation/Binary/Structures.agda:77-87`）字段只有 `isEquivalence`、
`reflexive : _≈_ ⇒ _≲_`、`trans` 三个，体内却有**派生**成员
`refl = reflexive Eq.refl`——等式自反性 + `reflexive` 推出不等式自反。
record 里混装「义务」（field）与「福利」（derived 定义），于是字段即引理：

```agda
mono-refl : (n : ℕ) → n ≤ n
mono-refl n = ≤P.refl   -- refl 的参数是隐式的（Reflexive _≤_）

antisym-demo : ∀ {m n} → m ≤ n → n ≤ m → m ≡ n
antisym-demo = ≤P.antisym
```

对比：Haskell 的 `Ord` 是 class、等价关系靠 `Eq` 隐式携带；Lean 用
`extends` 让内核处理继承。Agda 是**手写继承**：每层 bundle `open` 下层并
`public`、备降级函数（`Poset.preorder`、`Monoid.semigroup`）——「继承」
是**值之间的投影函数**，不是类型系统魔法。

## 18.2 推理框架：等式与不等式混排

14 章的 `≡-Reasoning` 是这套机件的特例。给定 Poset，
`Relation.Binary.Reasoning.PartialOrder` 是**以 bundle 值为参数的模块**
（源码第 44 行），实例化后得 `begin`/`≡⟨⟩`/`≤⟨⟩`/`∎` 全家桶：

```agda
import Relation.Binary.Reasoning.PartialOrder

module _ where
  open Relation.Binary.Reasoning.PartialOrder ≤-poset

  ≤-chain : 2 ≤ 4
  ≤-chain = begin
    1 + 1  ≡⟨ refl ⟩
    2      ≤⟨ s≤s (s≤s z≤n) ⟩
    4      ∎
```

两点解释。**为何裹 `module _ where`**：每套推理框架都导出同名
`begin`/`∎`/`trans`，对两个 Poset 推理就得各开匿名模块隔离——没有类型类，
命名空间自己管。**`≡⟨ refl ⟩` 为何走得通**：`_+_` 是语言级内建
（`Data.Nat.Base` 数次 `open import Agda.Builtin.Nat public` re-export），
归约**对第一个参数递归**，`1 + 1` 算成 `2`；反例实测 `n+0≡n = λ _ → refl`
撞 `[UnequalTerms] n + 0 != n of type ℕ`。示例注释「常数写在加法左侧，
保证可约」即此——**每个 `≡⟨ refl ⟩` 都在赌内建函数的归约方向**。第二例
把单调性引理当仓库现取现用：

```agda
  mono-demo : ∀ {m n} → m ≤ n → 1 + m ≤ 2 + n
  mono-demo {m} {n} m≤n = begin
    1 + m  ≤⟨ +-monoʳ-≤ 1 m≤n ⟩
    1 + n  ≤⟨ m≤n+m (1 + n) 1 ⟩
    2 + n  ∎
```

`+-monoʳ-≤ 1 m≤n : 1 + m ≤ 1 + n`；`m≤n+m x y : x ≤ x + y`；末步
`(1 + n) + 1` 与 `2 + n` 都归约到 `suc (suc n)`，定义相等免费。

## 18.3 抽象代数：Monoid 是一个 record

接口定义在 `Algebra/Bundles.agda:293-300`，`record Monoid c ℓ` 五件套：
`Carrier : Set c`、`_≈_ : Rel Carrier ℓ`、`_∙_ : Op₂ Carrier`、
`ε : Carrier`、`isMonoid : IsMonoid _≈_ _∙_ ε`——「载体 + 等式 + 二元
运算 + 单位元 + 公理证明」。公理层（`Algebra/Structures.agda:183` 起）
继续套娃：`IsMonoid` 字段只有 `isSemigroup` 与 `identity : Identity ε ∙`
两格；`IsSemigroup` 再嵌 `IsMagma { isEquivalence; ∙-cong }` 并加
`assoc`。record 体内另有派生投影 `identityˡ = proj₁ identity`、
`identityʳ = proj₂ identity`。读源码最容易错过的两点：**`identity`
是一个 × 对字段**——`Algebra/Definitions.agda:60`：
`Identity e ∙ = (LeftIdentity e ∙) × (RightIdentity e ∙)`，顺序（左,右）；
**`∙-cong : Congruent₂ ∙` 是强制字段**：定律全陈述在 `_≈_` 上，等式代入
必须有同余性兜底；`_≈_` 取 `_≡_` 时由 `cong₂ _+_` 白送——这也是 `_≈_`
字段不可省的原因。

手工实例化 `(ℕ, +, 0)`（`n+0≡n` 就是 13 章剧本的右单位元归纳）：

```agda
n+0≡n : ∀ n → n + zero ≡ n
n+0≡n zero    = refl
n+0≡n (suc n) = cong suc (n+0≡n n)

ℕ+-monoid : Monoid 0ℓ 0ℓ
ℕ+-monoid = record
  { Carrier  = ℕ
  ; _≈_      = _≡_
  ; _∙_      = _+_
  ; ε        = zero
  ; isMonoid = record
      { isSemigroup = record
          { isMagma = record
              { isEquivalence = Eq.isEquivalence
              ; ∙-cong        = cong₂ _+_
              }
          ; assoc = +-assoc
          }
      ; identity = (λ _ → refl) , n+0≡n   -- 左单位元 refl；右单位元要归纳
      }
  }
```

组装完，**每个字段都是可直接调用的定理**，且投影是纯计算：

```agda
∙ʸ : ℕ → ℕ → ℕ
∙ʸ = Monoid._∙_ ℕ+-monoid

εʸ : ℕ
εʸ = Monoid.ε ℕ+-monoid

_ : ∙ʸ 3 4 ≡ 7
_ = refl

_ : εʸ ≡ 0
_ = refl

assocℕ : ∀ x y z → (x + y) + z ≡ x + (y + z)
assocℕ = Monoid.assoc ℕ+-monoid

idʳℕ : ∀ x → x + εʸ ≡ x
idʳℕ = Monoid.identityʳ ℕ+-monoid
```

`∙ʸ 3 4 ≡ 7` 走 refl 因为 `_∙_` 字段里存的**就是** `_+_`——抽象层零
代价；`assocℕ` 连模式匹配都不写。对比 Haskell：字典里有运算但**定律
不在字典里**，结合律另立证明库；Agda 把两者焊在同一个值上，**拿到结构
= 拿到全部引理**。对比 Lean：class 字段布局几乎一样
（`mul`/`one`/`mul_assoc`/…），差别只在 Lean 自动找字典、Agda 亲手递
`ℕ+-monoid`。与 stdlib 现货（`+-0-monoid : Monoid 0ℓ 0ℓ`）对账：

```agda
_ : Monoid._∙_ +-0-monoid 3 4 ≡ 7
_ = refl
```

`List ℕ` 的 append monoid 逐字平行，引理全换列表家：

```agda
Listℕ++-monoid : Monoid 0ℓ 0ℓ
Listℕ++-monoid = record
  { Carrier  = List ℕ
  ; _≈_      = _≡_
  ; _∙_      = _++_
  ; ε        = []
  ; isMonoid = record
      { isSemigroup = record
          { isMagma = record
              { isEquivalence = Eq.isEquivalence
              ; ∙-cong        = cong₂ _++_
              }
          ; assoc = ++-assoc
          }
      ; identity = ++-identityˡ , ++-identityʳ
      }
  }

_ : Monoid._∙_ (++-monoid ℕ) (1 ∷ []) (2 ∷ []) ≡ 1 ∷ 2 ∷ []
_ = refl
```

「单位元一侧 refl、一侧归纳」再现：`[] ++ xs` 按第一参数归约所以平凡，
`xs ++ [] ≡ xs` 须归纳——**两个实例撞上同构的证明模式**，这就是抽象的
价值。最妙的是这条「关于证明的证明」：

```agda
_ : Monoid.identityʳ Listℕ++-monoid (1 ∷ []) ≡ refl
_ = refl
```

`identityʳ (1 ∷ [])` 类型是 `(1 ∷ []) ++ [] ≡ 1 ∷ []`，其证明值（一条
`cong` 归纳链）在具体输入上**归约成了 refl**——「证明也是数据」的字面
体现：证明项可计算、可投影、可再比较相等。Agda 不设证明无关性，证明的
**计算行为**是语义的一部分：好处是 transport 之后目标能干净归一，代价
是 18.5 组装同态必须诚实交出每条引理。

## 18.4 泛型定理：任何 Monoid 上都有 sum

打包接口的回报在此兑现。`Algebra.Properties.Monoid.Sum` 的模块头是
`module … {a ℓ} (M : Monoid a ℓ) where`——**以 bundle 值为参数**——交付
`sum : ∀ {n} → Vector Carrier n → Carrier`（并配数学记法 `∑[ i < n ] x`）：

```agda
import Algebra.Properties.Monoid.Sum as MonoSum
import Data.Vec.Functional as VF

-- sum 的参数是「定长向量」（Data.Vec.Functional），长度在类型里
v₃ : VF.Vector ℕ 3
v₃ = 1 VF.∷ 2 VF.∷ 3 VF.∷ VF.[]

_ : MonoSum.sum ℕ+-monoid v₃ ≡ 6
_ = refl

v₂ : VF.Vector (List ℕ) 2
v₂ = (1 ∷ []) VF.∷ (2 ∷ 3 ∷ []) VF.∷ VF.[]

_ : MonoSum.sum Listℕ++-monoid v₂ ≡ 1 ∷ 2 ∷ 3 ∷ []
_ = refl
```

第二例停一下：**列表的列表用 append 求和**就是 `concat`，且 `_∙_` 字段
存的是真 `_++_`，整条链 refl 直算——泛型函数没变成昂贵的抽象解释，它
**就是**那套具体运算的折叠。对比 Haskell：`mconcat` 收无限 List，定长版
要另写；Agda 把「恰好 n 项」写进签名。为何必须 `Data.Vec.Functional` 的
`Vector` 而非 16 章索引版 `Vec`？前者是 `Fin n → A` 的具象化，与索引
data **不是同一个类型**（坑位 5 实测报错）。

## 18.5 结构之间：monoid 同态

同态 = 函数 + 保运算 + 保单位元。新版在 `Algebra.Morphism.Structures`
第 133-138 行：`module MonoidMorphisms (M₁ : RawMonoid a ℓ₁)
(M₂ : RawMonoid b ℓ₂)` 里的
`record IsMonoidHomomorphism (⟦_⟧ : A → B)` 只有两字段
`isMagmaHomomorphism`（内嵌 `isRelHomomorphism` 的 `cong` 与保运算的
`homo`）和 `ε-homo : Homomorphic₀ ⟦_⟧ ε₁ ε₂`。**参数是 `RawMonoid`
不是 `Monoid`**：raw 系 bundle（`+-0-rawMonoid`、`++-[]-rawMonoid`，
都在 `Base` 文件里）只装「载体 + 等式 + 运算 + 单位元」签名，不装
定律——同态律的陈述根本用不到结合律。需要多少结构就声明多少，这是
Definitions/Structures/raw/Bundles 分层精确可控的红利。组装两个同态：

```agda
open import Algebra.Morphism.Structures using (IsMonoidHomomorphism)

-- 2^：把 (ℕ, +, 0) 送进 (ℕ, *, 1)
two-pow-hom : IsMonoidHomomorphism +-0-rawMonoid *-1-rawMonoid (2 ^_)
two-pow-hom = record
  { isMagmaHomomorphism = record
      { isRelHomomorphism = record { cong = cong (2 ^_) }
      ; homo              = ^-distribˡ-+-* 2
      }
  ; ε-homo = refl                        -- 2 ^ 0 ≡ 1 定义成立
  }

module P = IsMonoidHomomorphism two-pow-hom

pow-distrib : ∀ m n → 2 ^ (m + n) ≡ (2 ^ m) * (2 ^ n)
pow-distrib = P.homo

pow-ε : 2 ^ 0 ≡ 1
pow-ε = P.ε-homo

-- length：把 (List ℕ, ++, []) 送进 (ℕ, +, 0)
length-hom : IsMonoidHomomorphism (++-[]-rawMonoid ℕ) +-0-rawMonoid length
length-hom = record
  { isMagmaHomomorphism = record
      { isRelHomomorphism = record { cong = cong length }
      ; homo              = λ xs ys → length-++ xs {ys}
      }
  ; ε-homo = refl
  }

module L = IsMonoidHomomorphism length-hom

++-length-law : ∀ xs ys → length (xs ++ ys) ≡ length xs + length ys
++-length-law = L.homo
```

三个读解：`homo` 的类型正是 Haskell `monoids` 库同态律
`f (a ∙₁ b) ≈ f a ∙₂ f b`，这里是现成引理 `^-distribˡ-+-* 2` 入库再出库；
`ε-homo` 走 refl 因为 `_^_` 是 `Data.Nat.Base:294` 的普通定义
（`x ^ zero = 1`），对第二参数归约；`length-++` 签名 `∀ x {y} → …` 第二
参数隐式而 `homo` 期望双显式参数，故写 `λ xs ys → length-++ xs {ys}`。
历史坑：`Data.Nat.Properties:1073` 的 `^-monoid-morphism` 还用着弃用的
`IsMonoidMorphism`（实测亮警告，见坑位 2），故本节手写新 record。

## 18.6 stdlib 源码阅读示范：取证流程与阅读路线（自下而上）

```bash
grep -rn "^record Monoid c" /usr/share/agda-stdlib/src/Algebra/
# → Algebra/Bundles.agda:293（打包版）
grep -rn "record IsMonoid\b" /usr/share/agda-stdlib/src/Algebra/
# → Algebra/Structures.agda:183（公理版，同法可查 Poset/IsPreorder）
```

`Algebra.Core`（`Op₁/Op₂` 别名）→ `Algebra.Definitions`（`Associative`
等**纯谓词**）→ `Algebra.Structures`（谓词装成公理 record）→
`Algebra.Bundles`（+载体，含 `raw*` 变体）→ `Algebra.Properties.*`（泛型
引理，如 Sum）→ `Algebra.Morphism.Structures`（结构间映射）。
`Relation.Binary` 一系严格平行。先猜层级、再 grep 验证，**别凭记忆**。

## 坑位清单（全部实测）

1. **`RawMonoid` ≠ `Monoid`**：同态参数位要 raw bundle，递 `+-0-monoid`
   撞 `[UnequalTerms] (Monoid 0ℓ 0ℓ) !=< (Algebra.RawMonoid _a_1 _ℓ₁_2)`；
   互转靠 Monoid 自带的派生字段 `rawMonoid`。
2. **旧 morphism API 弃用但不阻塞**：碰 `Algebra.Morphism.IsMonoidMorphism`
   实测亮 `Warning: IsMonoidMorphism was deprecated in v1.5. / Please use
   IsMonoidHomomorphism instead.` 且**退出码仍是 0**——别把警告当通过。
3. **syntax 声明不随限定名进作用域**：`import Algebra.Morphism as Old`
   后用 `F Is … -Monoid⟶ …` 记法，实测报 `[NoParseForApplication] …
   Operators used in the grammar: Old.Is_-Monoid⟶`。`syntax` 只绑
   **非限定**名，`open … using/renaming` 还会把记法一并过滤。
4. **组装 record 漏字段，报的不是 missing field**：删掉 `isMonoid` 里的
   `identity` 整格，实测撞 `[UnsolvedMetaVariables] Unsolved metas at
   …:15.16-22`（record 表达式处）——`Algebra.Structures` 靠上下文字段
   反解模块参数 `_≈_`，约束不够时元变量先炸而非提示缺格。
5. **两族 Vec 不通用**：给 `MonoSum.sum` 递索引版 `Vec ℕ 3`，实测
   `[UnequalTerms] (Vec ℕ 3) !=< (Data.Fin.Base.Fin _n_42 →
   Algebra.RawMonoid.Carrier (Monoid.rawMonoid ℕ+-monoid))`——functional
   `Vector` 以 `Fin n → Carrier` 形态现身；报错还把 Carrier 投影原样展开，
   这类噪声 C-c C-n 归一化后再看。
6. **归约方向决定 refl 成败**：`0 + n ≡ n`、`[] ++ xs ≡ xs`、`2 ^ 0 ≡ 1`
   refl 白送；反向的 `n + 0 ≡ n`、`xs ++ [] ≡ xs` 必须归纳（实测
   `n + 0 != n of type ℕ`）。`identity = (左, 右)` 对序同理别记反。
7. **bundle 的 `open` 是大杀器**：直接 `open Poset …` 把 `refl/trans/sym`
   全灌成 `_≤_` 版本，与命题等式同名函数撞车。本章姿势：具名模块
   `module ≤P = Poset ≤-poset`、别名 `Eq.isEquivalence`。

---
上一章：[17 · 函数世界：同构与外延](17-functions.md) ｜ 下一章：[19 · Functor/Applicative/Monad](19-monads.md) ｜ 返回：[README](../README.md)
