# 23 · 类型的代数：ADT 作为半环

> **第四部分 · 依赖编程、代数与证明风格（20–24）** ｜ 全书结构与阅读路线见 [README](../README.md)

把类型当数字做算术，是 Haskell 社区的老玩具：`Maybe A = 1 + A`、
`Either A B = A + B`、`(A, B) = A × B`、`List A = 1 + A + A² + …`。
玩具归玩具，这次我们**认真**一次：把「≅（同构）」定义出来，把
0、1、+、× 逐条配上半环定律的**证明**，用 stdlib 3.0 的 `Fin` 正品
定律做基数算术，最后诚实地记录「为什么它不是环」——消去律是真的
不成立，我们有反例证人。

对应示例：`../examples/Ex23_type_algebra.agda`

**实测口径**（02 章）：本章报错文本均为 **Agda 2.9.0 + stdlib 3.0** 下用
`examples/TmpProbe41*.agda` 临时文件实测原样粘贴（复现完毕临时文件
已删除），示例通过 `./build.sh Ex23_type_algebra` 退出码 0。原书
（Maguire 第 8 章）用的是自研 `Iso` 库和 `FiniteTabular`，本版全部
改写为 stdlib 3.0 正品。

## 23.1 类型同构：一个 record 的事

两个类型「一样大」的准确说法是：存在一对互逆函数。书里的 `Iso`
活在 Setoid 上，要多背两个同余字段；在纯命题等式的世界里，**cong
是白送的**（任何函数都保 `≡`），于是同构就是四条字段：

```agda
record _≅_ {a b : Level} (A : Set a) (B : Set b) : Set (a ⊔ b) where
  field
    to      : A → B
    from    : B → A
    from∘to : ∀ x → from (to x) ≡ x
    to∘from : ∀ y → to (from y) ≡ y
infix 0 _≅_

open _≅_ public
```

字段命名跟书走：`from∘to` 谈**左**类型上的往返，`to∘from` 谈**右**
类型上的往返。自反、对称、传递都是三行 record 操作；传递稍有意思：

```agda
≅-trans i j = record
  { to      = to j ∘ to i
  ; from    = from i ∘ from j
  ; from∘to = λ x → trans (cong (from i) (from∘to j (to i x))) (from∘to i x)
  ; to∘from = λ y → trans (cong (to j) (to∘from i (from j y))) (to∘from j y)
  }
```

复合的左往返用的是 `from∘to j`（不是 to∘from！）——先掐内层
`from j ∘ to j`，再掐外层 `from i ∘ to i`。这里曾实测踩坑：把两条
定律的名字对调，报错是

```text
Ex23_type_algebra.agda:91.54-60: error: [UnequalTypes]
The type
  B
is not a subtype of
  C
when checking that the expression to i x has type C
```

`to∘from j` 的自变量要求 `C`，而 `to i x` 只到 `B`——字段名没白叫，
类型系统按名字提醒你谁是谁。

**实测坑一（算子名 record 的字段不裸进作用域）**。写完 `record _≅_`
就直接用 `from i tt`，Agda 6.9 版语法器翻脸：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe41_fld.agda:11.9-13: error: [NotInScope]
Not in scope:
  from
  at /Volumes/mac004/code/programming/agda/examples/TmpProbe41_fld.agda:11.9-13
    (did you mean '_≅_.from'?)
when scope checking from
```

普通名字的 record（如 09 章 `Σ`）字段自动可用，**算子名不行**，补
一行 `open _≅_ public` 才顺手（示例里已带上）。

**与 20 章 `_↔_` 对照**。stdlib 的 `Function.Bundles._↔_` 本质是
「同构 + 两个 cong 字段」的打包，`mk↔ₛ′` 恰好只要 to/from 加两条
逐点律——注意**参数顺序坑**（20 章实测，本章复测）：第一格要的是
`to∘from`（右往返），第二格才是 `from∘to`。故意反交一遍，报错让你
看清它在检查谁：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe41_mk.agda:17.19-24: error: [ConstructorPatternInWrongDatatype]
false is not a constructor of the datatype Fin
when checking that the pattern false has type Fin 2
```

把 `Bool` 的分支匹配塞给了 `Fin 2`——第一格的自变量是**右类型**的
元素。换袋函数一行：

```agda
≅⇒↔ : ∀ {a b : Level} {A : Set a} {B : Set b} → A ≅ B → A ↔ B
≅⇒↔ i = mk↔ₛ′ (to i) (from i) (to∘from i) (from∘to i)
```

## 23.2 有限数与特征函数：Bool ≅ Fin 2

书 §8.1 的 `toFin/fromFin` 是「二元类型」的最小样本：

```agda
toFin : Bool → Fin 2
toFin false = fzero
toFin true  = fsuc fzero

fromFin : Fin 2 → Bool
fromFin fzero        = false
fromFin (fsuc fzero) = true

bool≅fin : Bool ≅ Fin 2
bool≅fin = record
  { to      = toFin
  ; from    = fromFin
  ; from∘to = λ { false → refl ; true → refl }
  ; to∘from = λ { fzero → refl ; (fsuc fzero) → refl }
  }
```

四条分支全是 `refl`——有限类型的「数一数」在 Agda 里就是模式匹配。

**对照 stdlib（实测口径）**。Maguire 书用的是 Haskell 风格的
`toEnum/fromEnum`。在 stdlib 3.0 里这对名字**不存在**——全库 grep
零命中，硬用当场报：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe41_enum.agda:5.12-20: error: [NotInScope]
Not in scope:
  fromEnum
  at /Volumes/mac004/code/programming/agda/examples/TmpProbe41_enum.agda:5.12-20
when scope checking fromEnum
```

正主是 `Data.Fin` 的 `toℕ / fromℕ / fromℕ< / #_`。`fromℕ` 的妙处在
类型：`fromℕ : (n : ℕ) → Fin (suc n)`——**永远**装得进
`Fin (suc n)`，因为 `toℕ` 会模掉上界。一侧往返靠归纳一行：

```agda
toℕ-fromℕ : ∀ n → toℕ (fromℕ n) ≡ n
toℕ-fromℕ zero    = refl
toℕ-fromℕ (suc n) = cong suc (toℕ-fromℕ n)
```

另一侧 `fromℕ∘toℕ` 回不去：`toℕ` 把上界擦了。这正是「有限类型枚举
器」的要点——**把上界 n 留在类型里**。书里的
`Data.Fin.Tabular`（`Finite` 约束 + 枚举表）在 3.0 也没有对应物：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe41_tabular.agda:2.1-29: error: [FileNotFound]
Failed to find source of module Data.Fin.Tabular in any of the
following locations:
  /Volumes/mac004/code/programming/agda/examples/Data/Fin/Tabular.AGDA
  /Volumes/mac004/lang/agda-stdlib/src/Data/Fin/Tabular.AGDA
  ...
```

没关系：本章 23.5 用 `A ≅ Fin n` 直接表达「A 有 n 个元素」，比书的
`Finite` 类更干净——不用类，不用表，同构本身就是枚举。

## 23.3 Vec 就是特征函数：Vec A n ≅ (Fin n → A)

书 §8.3 的招牌定理。类型别名照抄，两个方向的函数各有讲究：

```agda
Vec′ : Set → ℕ → Set
Vec′ A n = Fin n → A

toVec′ : ∀ {A n} → Vec A n → Vec′ A n
toVec′ = lookup

fromVec′ : ∀ {A : Set} {n : ℕ} → Vec′ A n → Vec A n
fromVec′ {n = zero}  f = V.[]
fromVec′ {n = suc n} f = f fzero V.∷ fromVec′ (f ∘ fsuc)
```

**实测坑二（逆变）**。递归那步顺手写成 `fromVec′ f`（书里专门警告
过的 "backwards"），当场：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe41_fsuc.agda:10.37-38: error: [UnequalTerms]
The terms
  n
and
  suc n
are not equal at type ℕ
when checking that the expression f has type Fin n → A
```

`fromVec′` 递归步要的是 `Fin n → A`，手里的 `f` 定义域是
`Fin (suc n)`——**索引域在缩小，函数却对定义域逆变**：往下传只能
`f ∘ fsuc`（把小的 `Fin n` 抬进 `Fin (suc n)` 再查），不能硬塞。

**实测坑三（隐式参数按位置吃模式）**。第一版签名写 `∀ {A n}`，
分支写 `fromVec′ {zero} f = ...`，本意匹配 n，结果 `{zero}` 按
**位置**匹配了第一个隐参 A：

```text
Ex23_type_algebra.agda:154.11-15: error: [SplitError.NotADatatype]
Cannot split on argument of non-datatype Set
when checking that the pattern zero has type Set
```

改成具名 `{n = zero}` 就好。连带的老坑（10/18 章同款）：`Data.Fin`
和 `Data.Nat` 都叫 `zero/suc`，同时打开时 Fin 的后入者赢，写 ℕ 模式
`{n = zero}` 会撞上

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe41_noext.agda:13.15-19: error: [ConstructorPatternInWrongDatatype]
zero is not a constructor of the datatype ℕ
when checking that the pattern zero has type ℕ
```

示例开头 `renaming (zero to fzero; suc to fsuc)` 一次性排掉。

左侧往返是普通归纳（15 章剧本换到 Vec 布景，`rewrite` 直接收工）：

```agda
fromVec′∘toVec′ : ∀ {A n} (v : Vec A n) → fromVec′ (toVec′ v) ≡ v
fromVec′∘toVec′ V.[]       = refl
fromVec′∘toVec′ (x V.∷ xs) rewrite fromVec′∘toVec′ xs = refl
```

右侧往返是**函数等式**，没有定义可算。逐点引理对 `Fin` 索引归纳
（递归调用变小的是 `ix`），最后 funExt 收口：

```agda
toVec′-pointwise : ∀ {A n} (f : Vec′ A n) (i : Fin n) →
                   lookup (fromVec′ f) i ≡ f i
toVec′-pointwise f fzero     = refl
toVec′-pointwise f (fsuc ix) = toVec′-pointwise (f ∘ fsuc) ix

vec≅⇒ : ∀ {A n} → Vec A n ≅ Vec′ A n
vec≅⇒ = record
  { to      = toVec′
  ; from    = fromVec′
  ; from∘to = fromVec′∘toVec′
  ; to∘from = λ f → funExt (toVec′-pointwise f)
  }
```

不请 funExt、硬交 `refl` 的实测现场（20 章「函数相等要外延」的
再一次作证；stdlib 3.0 仍不提供任何 funExt 定义，只能 postulate）：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe41_noext.agda:23.27-31: error: [UnequalTerms]
The terms
  V.lookup (fromVec′ f) x
and
  f x
are not equal at type A
when checking that the expression refl has type
bad .to (bad .from f) ≡ f
```

好消息：报错已经帮你 η-展开到逐点形 `… x ≟ f x`——离 `refl` 只差
「对变量 f 没法再算」这一步，这正是外延公理的存在理由。

两个顺手的小台阶，23.4 之后有大用：

```agda
vec-cons≅ : ∀ {A : Set} {n} → Vec A (suc n) ≅ (A × Vec A n)
unit0≅⊤    : ∀ {A : Set} → Vec A 0 ≅ ⊤
```

`unit0≅⊤` 的四个字段只需要一条分支就穷尽——`Vec A 0` 只有 `[]`，
Agda 自己数得清（10 章索引无解的老手艺）。有了
`∘↮`（≅ 的传递复合）和 23.4 的乘法零件，「A³ 就是三元组」变成
纯装配：

```agda
vec³≅A³ : ∀ {A : Set} → Vec A 3 ≅ (A × A × A)
vec³≅A³ = c3 where
  c1 = vec-cons≅ ∘↮ ×-preserves-≅ ≅-refl unit0≅⊤ ∘↮ ×-identityʳ-≅
  c2 = vec-cons≅ ∘↮ ×-preserves-≅ ≅-refl c1
  c3 = vec-cons≅ ∘↮ ×-preserves-≅ ≅-refl c2
```

## 23.4 类型半环：0 ⊥、1 ⊤、+ ⊎、× 积

零件登记：`0ᵗ = ⊥`，`1ᵗ = ⊤`，加 = `_⊎_`，乘 = `_×_`。半环定律
全部以 `≅` 交货，示例里的证明风格统一为**copattern 逐字段**（比
record 表达式更适合分支多的定律）：

| 定律（书中形式） | 示例名 | 证明手法 |
|---|---|---|
| A + 0 ≅ A | `⊎-identityʳ-≅` | 荒谬模式 `(inj₂ ())`，⊥ 侧零分支 |
| 0 + A ≅ A | `⊎-identityˡ-≅` | 交换律 ∘↮ 右版，**白送** |
| A × 1 ≅ A | `×-identityʳ-≅` | `proj₁ / (_, tt)`，两侧 refl（record η，09 章） |
| 1 × A ≅ A | `×-identityˡ-≅` | 交换律 ∘↮ 右版，白送 |
| A × 0 ≅ 0 | `×-zeroʳ-≅` | 四个 `⊥-elim` |
| 0 × A ≅ 0 | `×-zeroˡ-≅` | 白送 |
| A + B ≅ B + A | `⊎-comm-≅` | 八条分支 |
| (A+B)+C ≅ A+(B+C) | `⊎-assoc-≅` | 十二条分支 |
| A × B ≅ B × A | `×-comm-≅` | `swap`，refl |
| (A×B)×C ≅ A×(B×C) | `×-assoc-≅` | 挪括号，refl |
| A × (B+C) ≅ A×B + A×C | `×-distribˡ-≅` | 八条分支，全 refl |

三个值得细看的手感。**其一**，`⊎-identityʳ-≅` 的 to 只有两行：

```agda
to ⊎-identityʳ-≅ (inj₁ a) = a
to ⊎-identityʳ-≅ (inj₂ ())     -- ⊥ 侧连分支体都不用写
```

**其二**，「左版 = 交换律 ∘ 右版」的代数课把戏在这里是同构复合一行
的事（`≅-sym ⊎-comm-≅ ∘↮ ⊎-identityʳ-≅`）——定律之间也是互相省的。
**其三**，乘法的单位/结合律全 `refl` 是 **record η** 的功劳（`_×_`、
`⊤` 都是 record）；但这条捷径**只属于 record**。同章的 `Ratio`（23.6）
是 `data`  datatype，一个构造子都不能 η 白送：

```agda
from∘to ratio≅× r = refl   -- ✗
```

```text
Ex23_type_algebra.agda:406.21-25: error: [UnequalTerms]
The terms
  mkRatio (ratio≅× .to r .proj₁) (ratio≅× .to r .proj₂)
and
  r
are not equal at type Ratio
```

写成 `from∘to ratio≅× (mkRatio n d) = refl` 模式匹配一下就好。
「ADT ≅ 它的字段积」看着人人都是 η，其实要自己拆。

## 23.5 基数算术：A Has n = A ≅ Fin n

书的 `Has` 记号一行落地，外加两个「算牌器」——全部吃 stdlib 正品：

```agda
\Has_ : ∀ {a : Level} → Set a → ℕ → Set a
A Has n = A ≅ Fin n

fin⊎≅fin+ : ∀ m n → (Fin m ⊎ Fin n) ≅ Fin (m + n)
fin⊎≅fin+ m n = record
  { to      = join m n
  ; from    = splitAt m
  ; from∘to = splitAt-join m n
  ; to∘from = join-splitAt m n
  }

fin×≅fin× : ∀ p q → (Fin p × Fin q) ≅ Fin (p * q)
to (fin×≅fin× p q) = uncurry combine
from (fin×≅fin× p q) = remQuot q
from∘to (fin×≅fin× p q) (i , j) = remQuot-combine i j
to∘from (fin×≅fin× p q) = combine-remQuot {n = p} q

⊎-has : A Has m → B Has n → (A ⊎ B) Has (m + n)
×-has : A Has m → B Has n → (A × B) Has (m * n)
```

`splitAt/join/combine/remQuot` 与四条往返律都在
`Data.Fin(.Properties)`（44 章迁移清单里的老熟人：2.3 → 3.0 它们一直
在）。隐式参数小坑：`combine` 的两个尺寸全隐式、`remQuot` 只显式收
「除数」，`to∘from` 得手工 `combine-remQuot {n = p} q` 钉住左尺寸，
不然乘法 `n * q ≟ p * q` 解不出来。

零和一的两个基准也各一行：

```agda
⊥-has0 : ⊥ Has 0        -- to/from/from∘to/to∘from 全是 () 模式
⊤-has1 : ⊤ Has 1        -- to _ = fzero; from _ = tt; 两条 refl
```

`⊥-has0` 四个字段全用荒谬模式——`⊥` 和 `Fin 0` 都没有居民，
空对空处处成立。**实测坑四**：这套写法别顺手复制到 `Fin 1` 上，
`Fin 1` 有 `fzero`，不空：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe41_f1.agda:15.1-16: error: [ShouldBeEmpty]
Fin 1 should be empty, but the following constructor patterns are
valid:
  fzero {._}
  fsuc {._} _
when checking that the clause left hand side
to∘from has1 ()
```

（`fsuc` 被列为「合法构造子模式」是模式层的观点；它对 `Fin 1` 实际
无解，但 `()` 只认「类型无构造子」，不认「构造子互相矛盾」。）

基数唯一吗？同基数必同构（都 ≅ 同一个 `Fin n`，走 `≅-trans`）；
反过来「同构 ⇒ 基数相等」是 stdlib 正品 `↔⇒≡`——
`Data.Fin.Permutation` 第 53–54 行 `Permutation m n = Fin m ↔ Fin n`，
`↔⇒≡ : Permutation m n → m ≡ n`。我们的 ≅ 经 `≅⇒↔` 换袋即可投喂：

```agda
has⇒≡ : ∀ {a : Level} {A : Set a} {m n} → A Has m → A Has n → m ≡ n
has⇒≡ i j = ↔⇒≡ (≅⇒↔ (≅-sym i ∘↮ j))
```

于是「1 + 1 = 2 = Bool」两头账都齐了：

```agda
⊤⊤-has2 : (⊤ ⊎ ⊤) Has 2
⊤⊤-has2 = ⊎-has ⊤-has1 ⊤-has1

bool≅1+1 : Bool ≅ (1ᵗ ⊎ 1ᵗ)
bool≅1+1 = bool≅fin ∘↮ ≅-sym ⊤⊤-has2
```

外加不借道 Fin 的手搓版 `bool≅1+1-v2`（`false ↦ inj₁ tt, true ↦
inj₂ tt`），八条分支全 refl。

## 23.6 ADT 的通用表示：构造子读成 1 / + / ×

Maguire §8.8 的核心洞见：任何 ADT 的构造子签名摊平后就是一个多项式。
单构造子的 `Ratio`：

```agda
data Ratio : Set where
  mkRatio : (numerator denominator : ℕ) → Ratio

ratio≅× : Ratio ≅ (ℕ × ℕ)
```

递归构造子的 `List`：`[]` 出一个 `1`，`∷` 出一个 `A × List A`——

```agda
list≅1+AX : ∀ {A : Set} → List A ≅ (1ᵗ ⊎ (A × List A))
```

这就是「X ≅ 1 + A·X」的**方程本身**成立，但还没「解出来」。解是
`A* = 1 + A + A² + …`，类型版即 `List A ≅ Σ[ n ∈ ℕ ] Vec A n`
（第 n 支 Aⁿ = Vec A n）。压轴题，stdlib 的零件看着齐全却**不好用**：
`Data.Vec.Properties` 里 `fromList∘toList` 第 1445 行的真身是

```agda
fromList∘toList : ∀ (xs : Vec A n) → fromList (toList xs) ≈[ length-toList xs ] xs
```

`≈[]` 是「带 cast 的≈」，塞不进 ≅ 的 ≡ 字段。自己归纳？第一版
`cong` 里塞模式 lambda 猜函数，收获一屏**高阶元变量无解**——Σ 的
依赖第二分量让 pattern unification 直接罢工：

```text
error: [UnsolvedConstraints]
Failed to solve the following constraints:
  v = v : Vec A (_n_970 (k = n)) (blocked on _952)
  fromList (toList v) = fromList (toList v)
    : Vec A (_n_970 (k = (length (toList v)))) (blocked on _949)
  suc _n_970 = _n_970 (k = suc k) : ℕ (blocked on _n_970)
  ...
```

对策简单粗暴：给归纳步一个**显式签名**的 helper，cong 就不用猜：

```agda
toΣ∘fromΣ : ∀ {A : Set} {n} (v : Vec A n) →
            (length (toList v) , fromList (toList v)) ≡ (n , v)
toΣ∘fromΣ V.[]       = refl
toΣ∘fromΣ {A = A} (x V.∷ xs) = cong cons (toΣ∘fromΣ xs)
  where
  cons : (Σ[ k ∈ ℕ ] Vec A k) → (Σ[ k ∈ ℕ ] Vec A k)
  cons (k , v) = suc k , x V.∷ v

list≅Σ : ∀ {A : Set} → List A ≅ Σ[ n ∈ ℕ ] Vec A n
to list≅Σ xs = length xs , fromList xs
from list≅Σ (_ , v) = toList v
from∘to list≅Σ xs = toList∘fromList xs    -- 这条 3.0 是普通 ≡，直接能用
to∘from list≅Σ (n , v) = toΣ∘fromΣ v
```

`to∘from` 必须先模式匹配拆出 `(n , v)` 再喂 helper：Σ 上的 η 展开
对字段类型不可见（第一版整函数点分写 `= toΣ∘fromΣ`，报「Σ ℕ (Vec A)
不是 Vec 的子类型」——异构的依赖对子拆不开）。

## 23.7 函数即指数：curry、case、和一条假定律

乘方 = 函数空间：`B^A = A → B`。两条真指数律（呼应 05/09 章的
curry/uncurry 与 14 章的 case）：

```agda
curry≅ : ∀ {A B C : Set} → (A × B → C) ≅ (A → B → C)     -- C^(A×B) = (C^B)^A
case≅  : ∀ {A B C : Set} → (A ⊎ B → C) ≅ ((A → C) × (B → C)) -- C^(A+B) = C^A × C^B

2⇒A≅A×A : ∀ {A : Set} → (Bool → A) ≅ (A × A)              -- A² = A·A
```

`curry≅` 的左往返 `λ f → refl` 白送（uncry∘curry 靠 η），右往返
逐点 η 后 funExt。`case≅` 就讲究了：它的 `from∘to` 是
`[ f ∘ inj₁ , f ∘ inj₂ ]′ ≡ f`——**⊎ 定义域没有 η**，硬 refl 实测：

```text
Ex23_type_algebra.agda:460.21-25: error: [UnequalTerms]
The terms
  Sum.[ (λ x → f (inj₁ x)) , (λ x → f (inj₂ x)) ] x
and
  f x
are not equal at type C
```

和 23.3 同款教训：函数相等 = 逐点 + 外延，且对和型要**分支**：
`funExt λ { (inj₁ a) → refl ; (inj₂ b) → refl }`。

然后是本世纪的**假定律**：`(A × B) → C ≅ (A → C) × (B → C)`？
看着像 `log(A·B) = log A + log B`，其实取 A = ⊤、B = ⊥、C = ⊥ 就穿
帮：左边 `(⊥ → ⊥)` 型 inhabitants 都在（对空定义域的函数唯一），
右边的左腿 `⊤ → ⊥` 无人能当。形式化只需一行——若同构存在，把
「常函数（用 ⊥-elim 造）」送过去取左腿喂 `tt`，当场造出 ⊥ 的居民：

```agda
¬⇒-distrib : ¬ ((⊤ × ⊥ → ⊥) ≅ ((⊤ → ⊥) × (⊥ → ⊥)))
¬⇒-distrib i = proj₁ (to i (λ p → ⊥-elim (proj₂ p))) tt
```

指数是**反变**底、协变顶的杂耍，分配方向只对「指数的加法在指数上」
（`case≅`）和「乘法拆底不行拆顶」（`curry≅`）成立——半环里 × 对 ⇒
没有对数的拆分律。

## 23.8 半环不是环：三张反例证人

环要求加法可消去/有逆。类型世界**没有减法**，本章交三个实证：

**证人一（X + 1 ≅ X 的活标本）**：`ℕ ≅ 1 ⊎ ℕ`（`zero` 走 `inj₁ tt`、
`suc` 走 `inj₂ n`，往返全 refl、零归纳量）。有穷类型不可能这样，
无穷类型随便来。

**证人二（加法消去律失效三连）**：

```agda
⊤≇⊥ : ¬ (⊤ ≅ ⊥)
⊤≇⊥ i = to i tt

no-cancel : ((⊤ ⊎ ℕ) ≅ ℕ) × (ℕ ≅ (⊥ ⊎ ℕ)) × ¬ (⊤ ≅ ⊥)
no-cancel = ≅-sym ℕ≅1+ℕ , ≅-sym ⊎-identityˡ-≅ , ⊤≇⊥
```

A⊎C ≅ B⊎C（都 ≅ ℕ）推不出 A ≅ B（⊤ ≇ ⊥）。三行都是前面零件的
镜像/直接复用。

**证人三（2 × X ≢ X）**：取 X = `Fin 1`。左边基数 2、右边基数 1，
`has⇒≡` 把假想的同构折算成自然数等式 `2 ≡ 1`，再被模式匹配拒绝：

```agda
2×1≅2 : (Bool × Fin 1) Has 2
2×1≅2 = ×-has bool≅fin ≅-refl      -- 2*1 定义归约到 2

2≢1 : 2 ≡ 1 → ⊥
2≢1 ()

¬2×1≅1 : ¬ ((Bool × Fin 1) ≅ Fin 1)
¬2×1≅1 i = 2≢1 (has⇒≡ 2×1≅2 i)
```

`2 ≡ 1 → ⊥` 用 `()`：`refl` 只能证 `2 ≡ 2`，分支集为空。

**出口**：不是环，不代表方程无解。「X ≅ 1 + X × X」的非平凡解就是
二叉树——

```agda
data Tree : Set where
  leaf : Tree
  node : (l r : Tree) → Tree

tree-iso : Tree ≅ (1ᵗ ⊎ (Tree × Tree))
```

`data` 的递归构造子天生给模型（35 章不动点组合子的伏笔）；而
「X ≅ A × X」的解 `Stream A` 住余归纳那边，29 章见。半环缺的减法，
无穷类型用「更多解」补了回来——这正是 Maguire 一节标题
*"Monoids on Types"* 想圈的范围：能登记的都登记，别硬凑环。

## 23.9 登记造册：stdlib Monoid 束收编 (Set, ×, ⊤)

本章零件正好凑出两个幺半群束。先用 IsEquivalence 打包 ≅ 的三件套：

```agda
≅-isEq : IsEquivalence (_≅_ {a = 0ℓ} {b = 0ℓ})
≅-isEq = record { refl = ≅-refl; sym = ≅-sym; trans = ≅-trans }

×-⊤-monoid : Monoid (lsuc 0ℓ) 0ℓ
×-⊤-monoid = record
  { Carrier  = Set
  ; _≈_      = _≅_
  ; _∙_      = _×_
  ; ε        = ⊤
  ; isMonoid = record
      { isSemigroup = record
          { isMagma = record
              { isEquivalence = ≅-isEq
              ; ∙-cong        = ×-preserves-≅
              }
          ; assoc = λ A B C → ×-assoc-≅
          }
      ; identity = (λ A → ×-identityˡ-≅) , (λ A → ×-identityʳ-≅)
      }
  }
```

`⊎-⊥-monoid` 完全同构地再来一遍（`∙-cong` 换 `⊎-preserves-≅`、assoc
换 `⊎-assoc-≅`、identity 换两条 ⊎ 单位律）。再加 23.4 的分配律与
零元律，半环公理集齐——「ADT 是半环」至此**全部登记在案**。

三处实测坑位，都是 37/40 章口径的「3.0 束风格」在 Set 宇宙重演：

1. **层级参数**：`Carrier = Set` 本身住在 `Set₁`，所以是
   `Monoid (lsuc 0ℓ) 0ℓ`。而 `lsuc` 这个名牌在 stdlib `Level` 里
   根本不存在——Level 把 `Agda.Primitive` 的 `lsuc` **改名成 `suc`**
   再 public 转发（Level.agda 第 13–15 行）：

   ```text
   /Volumes/mac004/code/programming/agda/examples/TmpProbe41_lsuc.agda:2.19-43: warning: -W[no]ModuleDoesntExport
   The module Level doesn't export the following:
     lsuc (did you mean 'suc'?)
   ```

   正解是 `open import Level using (Level; _⊔_; 0ℓ) renaming (suc to
   lsuc)`。**再套一层坑**：若在 `using` 里也列一次 `suc`（想着
   「先选后改」），Agda 2.9.0 当场拒绝：

   ```text
   Ex23_type_algebra.agda:18.42-60: error: [RepeatedNamesInImportDirective]
   Repeated name in import directive: suc
   ```

   renaming 自己会去挑那个名字，using 里不要替它点菜。
2. **IsEquivalence 不能写裸 `_≅_`**：异构（两个 Level 参数）的它作为
   单一载体上的 `_≈_` 会留下无解层级元变量（`UnsolvedConstraints`
   里一串 `_b_321 = Level.zero (blocked on _b_321)`），必须
   `(_≅_ {a = 0ℓ} {b = 0ℓ})` 钉死到 Set₀ 层。钉了层级后 `refl` 字段
   连 `λ {A → …}` 都不用写，直接 `≅-refl`——第一版画蛇添足写 case
   lambda，反被拒：

   ```text
   Ex23_type_algebra.agda:554.16-17: error: [CannotEliminateWithPattern]
   Cannot eliminate type x ≅ x with variable pattern A (did you supply
   too many arguments?)
   ```

3. **`assoc` 是显式 ∀（37 章同款），`identity` 是一对显式 ∀**：
   `assoc = ×-assoc-≅` 直接递上去会被嫌：

   ```text
   Ex23_type_algebra.agda:575.21-30: error: [UnequalTypes]
   The type
     (_A_1237 × _B_1238) × _C_1239 ≅ _A_1237 × _B_1238 × _C_1239
   is not a subtype of
     (x y z : Set) → (x × y) × z ≅ x × y × z
   when checking that the expression ×-assoc-≅ has type
   Algebra.Associative _≅_ _×_
   ```

   补 `λ A B C →` 三件套即可；`identity` 同理要
   `(λ A → ×-identityˡ-≅) , (λ A → ×-identityʳ-≅)`。

完整的 `Semiring` 束要三层 Structures 嵌套（37 章会把这三层逐层拆开），
本章
到此为止——反正 23.8 已经证明，类型上半环升不到环，真登记成
Semiring 反而是诚实的上限。

## 23.10 坑位清单（实测）

| # | 坑 | 现场 | 解法 |
|---|---|---|---|
| 1 | 算子名 record `_≅_` 字段不裸进作用域 | `NotInScope: from (did you mean '_≅_.from'?)` | `open _≅_ public` |
| 2 | `mk↔ₛ′` 第一格是 to∘from | 反交定律 → `false is not a constructor of Fin` | 记住「右往返在前」 |
| 3 | stdlib 3.0 无 `toEnum/fromEnum` | `NotInScope: fromEnum` | 用 `toℕ/fromℕ/#_` |
| 4 | 书里的 `Data.Fin.Tabular` 不存在 | `FileNotFound: Data.Fin.Tabular` | 用 `A ≅ Fin n` 表基数 |
| 5 | `fromVec′` 递归漏 `∘ fsuc` | `terms n and suc n are not equal` | 函数对定义域逆变 |
| 6 | 隐式模式按位置吃：`{zero}` 吃了 A | `Cannot split on … non-datatype Set` | 具名 `{n = zero}` |
| 7 | Fin 与 ℕ 的 `zero/suc` 撞名 | `zero is not a constructor of ℕ` | Fin 侧 renaming `fzero/fsuc` |
| 8 | 函数等式硬 refl（Vec iso / case≅） | `V.lookup (fromVec′ f) x != f x` 等 | 逐点引理 + funExt；⊎ 域分支 |
| 9 | `()` 用在不空的类型上 | `Fin 1 should be empty, but …` | 先数构造子再排雷 |
| 10 | data 类型没有 record η | `mkRatio … != r` | 显式模式匹配 |
| 11 | `cong` 猜 Σ 上的模式 lambda | 一屏 `_n (k = …)` 高阶元变量 | 显式签名 helper |
| 12 | `fromList∘toList` 是带 cast 的 `≈[]` | 进不了 ≅ 的 ≡ 字段 | 走 `toList∘fromList` + 自证另一侧 |
| 13 | `Level` 不导出 `lsuc` | `ModuleDoesntExport: lsuc (did you mean 'suc'?)` | `renaming (suc to lsuc)` |
| 14 | using/renaming 重复点名 | `RepeatedNamesInImportDirective: suc` | 只在 renaming 里出现 |
| 15 | 异构 ≅ 直接进 IsEquivalence | 层级元变量 blocked 无解 | `(_≅_ {a = 0ℓ} {b = 0ℓ})` |
| 16 | 3.0 `assoc/identity` 显式 ∀ | `is not a subtype of (x y z : Set) → …` | `λ A B C →`  wrappers |

## 小结

- 类型同构 `≅`：四字段 record，比 stdlib `↔` 少背两个 cong；
  自反/对称/传递 + `∘↮` 记法即可开工。
- 有限类型 = `A ≅ Fin n`；加乘算牌全用 `Data.Fin` 正品
  （splitAt/join、combine/remQuot），基数唯一性吃 `↔⇒≡`。
- `Vec A n ≅ (Fin n → A)`：特征函数视角，`fromVec′` 的 `∘ fsuc`
  是逆变性的全部秘密。
- ADT = 多项式：`Bool ≅ 1+1`、`Ratio ≅ ℕ×ℕ`、`List ≅ 1+A·X` 且
  解出 `List A ≅ Σ n. Aⁿ`（cast 坑已填）。
- 函数即指数：curry/case 两条真律 + 一条假分配律的证伪。
- 半环**不是**环：`ℕ ≅ 1+ℕ`、消去律失效、`2×X ≢ X`，而
  `X ≅ 1+X²` 的解（Tree）说明无穷类型是代数方程的真出口。

下一章我们把「类型算数」换成「列表算真」：Braun 树与列表证明
（19 章）。
---
上一章：[22 · 单子折纸（monoidal origami）](22-monoid-origami.md) ｜ 下一章：[24 · intrinsic 与 extrinsic 证明](24-intrinsic-extrinsic.md) ｜ 返回：[README](../README.md)
