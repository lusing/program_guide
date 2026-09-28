# 22 · monoid 与折叠：单子折纸（monoidal origami）

> **第四部分 · 依赖编程、代数与证明风格（20–24）** ｜ 全书结构与阅读路线见 [README](../README.md)

`foldr` 谁都会写，但很少人停下来问：**为什么偏偏是 `foldr`？**
答案：因为 `(∙, ε)` 是个 monoid。一旦把「摘要 = 用 monoid 折叠」这层
窗户纸捅破，`sum`、`any`、`all`、`reverse`、`length`、奇偶校验……
几十种查询就都是**同一个函数换不同实例**；「切两块分别算再合并」
（map-reduce 的合法性）成为一条叫 `fold-++` 的等式；「先 map 后 fold
可以融合」成为另一条；而 monoid 同态是一张**搬运计算的船票**——
哪一侧算得贵，就把 `f` 沿等式挪到另一侧。Maguire 的书把这一串等式
叫做 monoidal origami（折纸）：同一张纸（foldList），折出不同的图案。

对应示例：`../examples/Ex22_monoids.agda`

**实测口径**（02 章）：本章报错文本均为 **Agda 2.9.0 + stdlib 3.0** 实测原样粘贴（复现用的
`examples/TmpProbe40*.agda` 已删除，报错路径显示为当时的临时文件名）；
代码片段与示例一致，书中（Haskell 风味的伪 Agda）代码全部改写成了
stdlib 3.0 下真实可编译的写法，逐条探针验证。setoid（带自定义等式
`_≈_` 的集合）只在 22.2 点到为止——那是 39/20 章的正业。

## 22.1 mad-libs 模板：手搓 monoid record

书的 mad-libs 填空句：「A monoid is a **set** equipped with an
**associative binary operation** `_∙_` and an **identity element** `ε`」。
四个空，四段代码，一个都不少：

```agda
Op₂ : Set → Set
Op₂ A = A → A → A

record IsMonoid {A : Set} (_∙_ : Op₂ A) (ε : A) : Set where
  field
    assoc     : (x y z : A) → (x ∙ y) ∙ z ≡ x ∙ (y ∙ z)
    identityˡ : (x : A) → ε ∙ x ≡ x
    identityʳ : (x : A) → x ∙ ε ≡ x

record Monoid : Set₁ where
  field
    Carrier   : Set
    _∙_       : Op₂ Carrier
    ε         : Carrier
    is-monoid : IsMonoid _∙_ ε

bundle : ∀ {A : Set} {_∙_ : Op₂ A} {e : A} → IsMonoid _∙_ e → Monoid
```

两种形状各司其职：`IsMonoid` 是**裸公理记录**——`_∙_` 和 `ε` 当参数，
只谈定律；`Monoid` 把载集也装箱，整个结构当一个**值**传递（后面
`foldList` 的第一参数就是它）。装箱住在 `Set₁`：字段 `Carrier : Set`
逼得整箱进不了 `Set`（实测见 22.10 第 7 条的报错）。

实例全从 stdlib 定律直接取货（`+-assoc`、`∨-identityˡ`……）：

```agda
+-0 : IsMonoid _+_ 0
assoc     +-0 = +-assoc
identityˡ +-0 = +-identityˡ
identityʳ +-0 = +-identityʳ
```

布尔有**两副面孔**：`(Bool, ∨, false)` 与 `(Bool, ∧, true)`——
`all` 用后者、`any` 用前者。更妙的是同一载集同一 `ε` 还能再开一副：
异或。书里说「这例子太简单，但请记住：载集相同、单位元相同，
monoid 也可以不同」，示例里 xor 的四条 assoc 全部逐情形 `refl`。

对偶 monoid 是本书第一个「免费定理」：

```agda
dual : ∀ {A : Set} {_∙_ : Op₂ A} {e : A} →
       IsMonoid _∙_ e → IsMonoid (flip _∙_) e
assoc     (dual m) x y z = sym (assoc m z y x)
identityˡ (dual m)       = identityʳ m
identityʳ (dual m)       = identityˡ m
```

三定律一字不改只是**换个朝向**：`ε` 还是那个 `ε`。「左偏 `<>`」翻成
「右偏」，于是 `foot`（取最后一个元素）白送（见 22.3）。

自映射复合 `(A → A, ∘, id)` 是全书最有味道的一个 monoid——三定律全是
definitional 的 `refl`。但把 stdlib 的 `_∘_` 原样塞进 `Op₂` 的位置会撞墙：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe40n.agda:12.43-46: error: [UnequalTypes]
The function type
  A → A
is not a subtype of
  {x : _A_23} (y : _B_24 x) → _C_25 y
because:
  one takes a visible argument, while the other takes a hidden
  argument.
when checking that the expression _∘_ has type Op₂ (A → A)
```

3.0 的 `Function.Base._∘_` 是**依赖版**（隐式参数挡位），`Op₂ (A → A)`
要的是纯非依赖形状。正解是就地手写非依赖组合子，语义分毫不差：

```agda
∘-id : ∀ {A : Set} → IsMonoid {A = A → A} (λ f g x → f (g x)) id
assoc     ∘-id = λ _ _ _ → refl
identityˡ ∘-id = λ _ → refl
identityʳ ∘-id = λ _ → refl
```

装箱时还有一个小机关：`++-[]`、`<|>-nothing` 的载集随元素类型变，
顶层直接 `++-m = bundle ++-[]` 会让 `A` 悬空成无解 metavariable
（实测见 22.10 第 6 条），所以写成 `++-m {A = A} = bundle (++-[] {A = A})`。

## 22.2 与 stdlib 对照：三层结构里的 IsMonoid

37 章会把 stdlib 代数的三层（Definitions → Structures → Bundles）逐层拆
开；这里先回收结论。
`Algebra.Structures.IsMonoid` 的源码（`Algebra/Structures.agda:190` 起）：

```agda
record IsMonoid (∙ : Op₂ A) (ε : A) : Set (a ⊔ ℓ) where
  field
    isSemigroup : IsSemigroup ∙
    identity    : Identity ε ∙

  open IsSemigroup isSemigroup public

  identityˡ : LeftIdentity ε ∙
  identityˡ = proj₁ identity

  identityʳ : RightIdentity ε ∙
  identityʳ = proj₂ identity
```

与手搓版三点不同：

1. **模块参数带载集和等式**。上面代码块外面还包着（源码 14-17 行）
   `module Algebra.Structures {a ℓ} {A : Set a} (_≈_ : Rel A ℓ) where`
   ——`_≈_` 是 setoid 的等价关系，本教程一律取 `_≡_`（setoid 的正式
   讲法在 39 章，20 章同构塔也用过），于是本章所有「等式」都是命题等式。
2. **定律是零件拼装**：assoc 藏在 `isSemigroup` 里、单位律打包成
   `identity` 一对（`Algebra.Definitions`：`Identity e ∙ =
   LeftIdentity e ∙ × RightIdentity e ∙`，两侧各是 `∀ x → …`）。
   `assoc/identityˡ/identityʳ` 全是**派生投影**
   ——37 章路标「别在 IsMonoid 上直接找 assoc 的 field」在此应验，
   取它们要写 `AlgStr.IsMonoid.assoc m`。
3. **多一桩义务 `∙-cong`**：运算必须对 `_≈_` 同余（在 setoid 世界里，
   「相等的输入给出相等的输出」是结构的一部分而非定理）。取 `_≈_ = _≡_`
   时它由 Leibniz 性 `cong₂ ∙` 白送——这正是迁移的全部体力活。

两个方向的转换器（示例第 2 节，全部 record 组装一次通过）：

```agda
naive→std : ∀ {A : Set} {_∙_ : Op₂ A} {e : A} →
            IsMonoid _∙_ e → AlgStr.IsMonoid {A = A} _≡_ _∙_ e
naive→std {_∙_ = ∙} m = record
  { isSemigroup = record
      { isMagma = record
          { isEquivalence = Eq.isEquivalence
          ; ∙-cong        = cong₂ ∙
          }
      ; assoc = assoc m
      }
  ; identity = identityˡ m , identityʳ m
  }

std→naive : ∀ {A : Set} {_∙_ : Op₂ A} {e : A} →
            AlgStr.IsMonoid {A = A} _≡_ _∙_ e → IsMonoid _∙_ e
std→naive m = record
  { assoc     = AlgStr.IsMonoid.assoc m
  ; identityˡ = AlgStr.IsMonoid.identityˡ m
  ; identityʳ = AlgStr.IsMonoid.identityʳ m
  }
```

往返验收：`+-0-back = std→naive (naive→std +-0)` 类型检查过；stdlib
焊好的现货 `Data.Nat.Properties.+-0-isMonoid`（44 章迁移清单点过名的
`+-0-*` 系成员——网文常见的 `+-isMonoid` 在 3.0 不存在）塞进手搓
record 也严丝合缝——**同型同证**。

级别实测对照（探针里用类型标注当穷人版 `:Check`，`x : T` 过了即级别对）：

| 表达式 | 住的级别 | 实测 |
|---|---|---|
| 手搓 `IsMonoid _+_ 0` | `Set₀` | 标注 `Set₀` 通过 |
| `AlgStr.IsMonoid {A = ℕ} _≡_ _+_ 0` | `Set (0ℓ ⊔ 0ℓ)` = `Set₀` | 两种标注都通过 |
| 手搓 `Monoid`（整箱） | `Set₁` | 标注 `Set₀` 被拒（下方报错） |
| stdlib `Monoid 0ℓ 0ℓ`（整包） | `Set (suc (0ℓ ⊔ 0ℓ))` = `Set₁` | 标注 `Set₁` 通过 |
| stdlib `Algebra.Bundles.Monoid` 未喂参 | `(c ℓ : Level) → Set (suc c ⊔ suc ℓ)` | 强塞 `Setω` 被拒（聚不拢） |

手搓整箱想进 `Set₀` 时的原文：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe40j.agda:29.15-21: error: [UnequalTypes]
The types
  Set₁
and
  Set
are not equal
when checking that the expression Monoid has type Set
```

（报错里的 `Set` 就是 `Set₀` 的打印习惯，05 章说过。）两种整包之间
**不能直接互喂**——stdlib 的 bundle 多一个 `_≈_` 字段、级别参数也写在
类型里：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe40i.agda:35.8-20: error: [UnequalTypes]
The type
  Monoid 0ℓ 0ℓ
is not a subtype of
  NaiveMonoid
when checking that the expression std-+-monoid has type NaiveMonoid
```

桥就是上面那对转换器（对 `IsMonoid` 层拆装，`Carrier` 等字段手工搬运）。

## 22.3 任何 monoid 都给出一个折叠：monoids as queries

「Monoids generate summaries」。把 monoid 当**查询的代名词**：
载集 = 答案类型，`ε` = 空输入的默认答案，`∙` = 合并两份答案。
一个 `foldList` 吃遍所有查询：

```agda
foldList : (M : Monoid) {A : Set} (f : A → Carrier M) → List A → Carrier M
foldList M f []       = ε M
foldList M f (x ∷ xs) = Monoid._∙_ M (f x) (foldList M f xs)
```

（这里必须写全 `Monoid._∙_ M a b`：infix 简写会撞上 22.10 第 5 条的坑。）
换实例 = 换查询，书的目录在这里逐条复现：

| 查询 | monoid 实例 | f |
|---|---|---|
| `sum` | `(ℕ, +, 0)` | `id` |
| `product` | `(ℕ, *, 1)` | `id` |
| `any? p` / `all? p` | `(Bool, ∨, false)` / `(Bool, ∧, true)` | `p` |
| `parity`（奇偶校验） | `(Bool, xor, false)` | `id` |
| `flatten` | `(List A, ++, [])` | `id` |
| `head` / `foot` | `(Maybe A, <|>, nothing)` / 其 **dual** | `just` |
| `reverse` | dual `(List A, ++, [])` | `λ x → x ∷ []` |
| `size` | `(ℕ, +, 0)` | `const 1` |
| `empty?` | `(Bool, ∧, true)` | `const false` |

`parity` 是噪声信道的古老把戏：整块数据异或出一位奇偶位，翻一位必被发现；
`foot`/`reverse` 演示 dual 的 dividends——「取最后一个」在左偏 `<>` 里
不可折，翻个面就可折了。十来个查询全部 `refl` 直算：

```agda
_ : sum (1 ∷ 20 ∷ 300 ∷ []) ≡ 321
_ = refl

_ : foot (1 ∷ 2 ∷ []) ≡ just 2                 -- dual monoid 白送「最后一个」
_ = refl
```

「可分块/可并行」的底气不在这里，在下一条等式。

## 22.4 第一折：fold-++（map-reduce 的数学凭据）

**折叠是 `++` 的同态**：

```agda
fold-++ : (M : Monoid) {A : Set} (f : A → Carrier M)
          (xs ys : List A) →
          foldList M f (xs ++ ys)
          ≡ Monoid._∙_ M (foldList M f xs) (foldList M f ys)
fold-++ M f []       ys = sym (identityˡ (is-monoid M) (foldList M f ys))
fold-++ M f (x ∷ xs) ys rewrite fold-++ M f xs ys
  = sym (assoc (is-monoid M) (f x) (foldList M f xs) (foldList M f ys))
```

这是全章的教学高潮：**monoid 定律不是仪式，是折叠可分块的许可证**。
把数据切成两半、各台机器各折各的、再把两份答案 `∙` 起来——结果与单机
一趟折**逐字相等**，等式由归纳证明，而证明的每一步恰好消费一条定律：

* **基例吃 `identityˡ`**：`xs = []` 时右边多出一个 `ε ∙ …`——空块
  合并进来不改变答案，这正是「单位元存在」的存在理由。
* **步例吃 `assoc`**：归纳假设把 `xs ++ ys` 折开之后，目标是
  `f x ∙ (fold xs ∙ fold ys) ≡ (f x ∙ fold xs) ∙ fold ys`，
  括号搬运工 `sym assoc` 一击致命——「结合律」的存在理由。

也就是说：**给定 `fold-++` 成立的任何摘要，天然支持无限分块**。
反过来，不能用 monoid 表达的查询（比如「倒数第二个元素」）在 map-reduce
里就会死给你看。方向感老话题（15 章 15.4.4）：`assoc` 的标准方向是
「左挪括号到右」，我们的目标要反向挪，所以两处都包了 `sym`。

## 22.5 第二、三折：foldr 等价与 fold∘map 融合

本书的 `foldList` 与 stdlib 的 `foldr` 是同一个函数——把证明逐字摆出来
（每个构造子一步，全靠 `cong` 抬归纳假设）：

```agda
fold-is-foldr : (M : Monoid) {A : Set} (f : A → Carrier M) (xs : List A) →
                foldList M f xs ≡ foldr (Monoid._∙_ M) (Monoid.ε M) (map f xs)
fold-is-foldr M f []       = refl
fold-is-foldr M f (x ∷ xs) =
  cong (Monoid._∙_ M (f x)) (fold-is-foldr M f xs)
```

这就是 Haskell 世界 `foldMap = foldr mappend mempty . map` 的 Agda 证法：
纯定义展开，定律一条都没动用（所以它对手掌上的「伪 monoid」也成立——
坏消息留给 22.7 的 `not-hom` 去心疼）。

第三折是融合律（fusion 的原型）：「先 `map f` 再空折」等于「直接带 `f` 折」，
中间那张列表根本不生成：

```agda
fold-map : (M : Monoid) {A : Set} (f : A → Carrier M) (xs : List A) →
           foldList M f xs ≡ foldL M (map f xs)
fold-map M f []       = refl
fold-map M f (x ∷ xs) rewrite fold-map M f xs = refl
```

三折合起来就是折纸的折痕图：`fold ∘ map` 是一族折叠，`fold-++` 管横向
切分，`fold-map` 管纵向流水合并。

## 22.6 乘积 monoid：一次折叠，两路统计

两个 monoid 可以**并排装箱**：载集取积、运算逐分量、单位元配对
（书里管这叫 Composition of Monoids）：

```agda
_⊗_ : (M N : Monoid) → Op₂ (Carrier M × Carrier N)
_⊗_ M N (a₁ , b₁) (a₂ , b₂) = (Monoid._∙_ M a₁ a₂ , Monoid._∙_ N b₁ b₂)

×-monoid : (M N : Monoid) → Monoid
```

三条定律的搬运全是同一个形状：`assoc` 逐分量成对，用
`cong₂ _,_` 一次装箱——两个 monoid 各自结合，配对就结合：

```agda
assoc (go M N) (a₁ , b₁) (a₂ , b₂) (a₃ , b₃) =
  cong₂ _,_ (assoc (is-monoid M) a₁ a₂ a₃) (assoc (is-monoid N) b₁ b₂ b₃)
```

收益立刻兑现：**分开折再配对 = 配对折一趟**：

```agda
fold-pair : (M N : Monoid) {A : Set}
            (f : A → Carrier M) (g : A → Carrier N) (xs : List A) →
            foldList (×-monoid M N) (λ x → (f x , g x)) xs
            ≡ (foldList M f xs , foldList N g xs)
```

（步例一条 `rewrite` 加 `refl`：靠的是 `_⊗_` 逐分量 + 积类型上 `refl` 自动
投影——两条腿各自 `refl` 即整体 `refl`。）应用：`sum` 和 `size` 一趟算完，
一趟 = 两趟的正确性由 `stats-correct xs = fold-pair +-0-m +-0-m id (const 1) xs`
直接引用。乘积单子里每个分量还能继续并行（fold-++ 管切分、×-monoid 管混编），
这就是 map-reduce 作业的真实形状：**多个查询拼成一个 monoid，一次折叠全收**。

## 22.7 monoid 同态：证一次，搬运计算终身免费

同态 = 保结构函数。书里的 `MonHom` 带一枚 `f-cong` 字段，在 `_≡_` 下
Leibniz 白送，删剩两条：

```agda
record MonHom {M N : Monoid} (f : Carrier M → Carrier N) : Set where
  field
    preserves-ε : f (Monoid.ε M) ≡ Monoid.ε N
    preserves-∙ : (x y : Carrier M) →
                  f (Monoid._∙_ M x y) ≡ Monoid._∙_ N (f x) (f y)
```

核心定理：同态把 `f` 从折叠结果上「挤」进每个元素——**先折后 f = 先 f 后折**：

```agda
hom-fold : ∀ {M N : Monoid} {f : Carrier M → Carrier N} →
           MonHom {M = M} {N = N} f →
           ∀ {A : Set} (g : A → Carrier M) (xs : List A) →
           f (foldList M g xs) ≡ foldList N (λ x → f (g x)) xs
hom-fold {M} {N} h g []       = preserves-ε h
hom-fold {M} {N} {f} h g (x ∷ xs)
  rewrite preserves-∙ h (g x) (foldList M g xs) | hom-fold h g xs = refl
```

基例吃 `preserves-ε`，步例吃 `preserves-∙` + IH——和 fold-++ 一样，
「证明消费定义」的戏码第二回。注意签名里那对 `{M = M} {N = N}`：
**删掉就翻车**，实测：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe40f.agda:46.11-48: warning: -W[no]RewritesNothing
`rewrite' did not apply
when checking that the clause
hom-fold {M} {N} h g (x ∷ xs)
  rewrite preserves-∙ h (g x) (foldList M g xs) | hom-fold h g xs
  = refl
has type
{M N : Monoid} {f : Carrier M → Carrier N} →
MonHom f →
{A : Set} (g : A → Carrier M) (xs : List A) →
f (foldList M g xs) ≡ foldList N (λ x → f (g x)) xs

/Volumes/mac004/code/programming/agda/examples/TmpProbe40f.agda:46.51-66: warning: -W[no]RewritesNothing
`rewrite' did not apply
when checking that the clause
TmpProbe40f.-rewrite162 {M} {N} {_} h {_} g x xs _ refl
  rewrite hom-fold h g xs
  = refl
has type
{M N : Monoid} {f : Carrier M → Carrier N} (h : MonHom f) {A : Set}
(g : A → Carrier M) (x : A) (xs : List A) (lhs : Carrier N) →
lhs ≡ _N._∙__49 (f (g x)) (f (foldList M g xs)) →
f ((M ∙ g x) (foldList M g xs)) ≡
(N ∙ f (g x)) (foldList N (λ x₁ → f (g x₁)) xs)

/Volumes/mac004/code/programming/agda/examples/TmpProbe40f.agda:46.69-73: error: [UnequalTerms]
The terms
  f ((M ∙ g x) (foldList M g xs))
and
  (N ∙ f (g x)) (foldList N (λ x₁ → f (g x₁)) xs)
are not equal at type Carrier N
when checking that the expression refl has type
f ((M ∙ g x) (foldList M g xs)) ≡
(N ∙ f (g x)) (foldList N (λ x₁ → f (g x₁)) xs)
```

病根：`MonHom` 的隐式参数 `M`、`N` 藏在 `Carrier` 投影后面，而
`Carrier` 是 record 投影、**不可反推**（`Carrier M ≡ Carrier N` 推不出
`M ≡ N`，就像 `f x ≡ f y` 推不出 `x ≡ y`）。写 `MonHom f →` 时 Agda 只能
留下两个「blocked on 投影」的卡死 metavariable（第二个警告里
`_N._∙__49` 的裸打印就是它），两条 `rewrite` 全部
匹配失败（`RewritesNothing`，方向感教训同 15 章 15.4.4），最后 `refl`
撞上 UnequalTerms。解药：
在使用点把参数钉死，`MonHom {M = M} {N = N} f`。09 章讲过 record 有 η
（值由字段定）但没说字段可反推投影——「投影不单射」在这一课露了真獠牙。

**同态例一（免费的和不自知的）**：`not` 保 `∧-true → ∨-false`：

```agda
not-hom : MonHom {M = ∧-m} {N = ∨-m} not
preserves-ε not-hom          = refl
preserves-∙ not-hom false y  = refl
preserves-∙ not-hom true  y  = refl
```

`preserves-∙` 展开就是 De Morgan 定律 `¬(a∧b) ≡ ¬a∨¬b`——书里的梗：
「著名定理原来是找同态时撞出来的」。另一半（∨→∧）同样一行一案
（`not-hom′`）。它保的是「折叠 = 折后 f」，哪怕你根本不在乎定律。

**「Finding equivalent computations」**：同一计算的两条路线，由同态判成
一条。例：先拍平再求和 ≡ 先逐表求和再合并——左边是「一次大遍历」，
右边是「分表小求和 + 快加法」，哪边便宜走哪边：

```agda
sum-hom : MonHom {M = ++-m} {N = +-0-m} sum   -- preserves-∙ 就是 sum-++

sum-flatten : ∀ xss → sum (flatten xss) ≡ sum (map sum xss)
sum-flatten xss = begin
  sum (flatten xss)                          ≡⟨⟩
  sum (foldList ++-m id xss)                 ≡⟨ hom-fold sum-hom id xss ⟩
  foldList +-0-m (λ xs → sum (id xs)) xss    ≡⟨⟩
  foldList +-0-m sum xss                     ≡⟨ fold-map +-0-m sum xss ⟩
  foldL +-0-m (map sum xss)                  ≡⟨⟩
  sum (map sum xss)                          ∎
  where open Eq.≡-Reasoning
```

一条链把本章三条定理各用一次：`hom-fold`（同态挤进元素）、
`fold-map`（融合）。`≡⟨⟩` 那些步全是 definitional 展开——
16 章推理记号，`where open Eq.≡-Reasoning` 的取法见 22.10 第 3 条。

例二是书里最漂亮的把戏：`x ↦ 2^x` 是 `(+, 0) → (*, 1)` 的同态。
保单位元 `2^0 ≡ 1` 是 refl；保乘法就是 stdlib 现成引理
`^-distribˡ-+-* 2 m n : 2 ^ (m + n) ≡ 2 ^ m * 2 ^ n`。书的语境是数子集：
有限集的 subsets 有 `2^size` 个，不相并拆两半各数各的，两边必须对上——
`2 ^ sum xs ≡ product (map (2 ^_) xs)`，「先加总再一次乘方」与
「逐个变小幂再一趟乘」是**同一个计算的两条路线**：

```agda
pow-sum≡prod : ∀ xs → 2 ^ sum xs ≡ product (map (2 ^_) xs)
pow-sum≡prod xs = begin
  2 ^ sum xs                             ≡⟨⟩
  2 ^ foldList +-0-m id xs               ≡⟨ hom-fold ^-hom-2 id xs ⟩
  foldList *-1-m (λ x → 2 ^ (id x)) xs   ≡⟨⟩
  foldList *-1-m (2 ^_) xs               ≡⟨ fold-map *-1-m (2 ^_) xs ⟩
  foldL *-1-m (map (2 ^_) xs)            ≡⟨⟩
  product (map (2 ^_) xs)                ∎
  where open Eq.≡-Reasoning
```

哪边便宜走哪侧，这就是 22.7 开头「搬运计算」的字面演示。示例里 `sum-++` 的步例也值得
一看：`cong (x +_)` 把归纳假设塞进上下文再 `sym +-assoc` 挪括号——
「generalize 就是函数应用」（15 章口诀）在等式证明里的变奏。

## 22.8 pointwise monoid：本章唯一不免费的地方

把 monoid 沿任意定义域 `A` **逐点上提**到函数空间 `A → Carrier M`：
运算逐点、单位元常值。数学上这当然是 monoid，Agda 里第一堵墙：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe40h.agda:17.13-17: error: [UnequalTerms]
The terms
  f x + g x
and
  f x
are not equal at type ℕ
when checking that the expression refl has type
((f ⊙ g) ⊙ h) ≡ (f ⊙ (g ⊙ h))
```

两个 **lambda 的命题等式**——`(λ x → (f x ∙ g x) ∙ h x) ≡
(λ x → f x ∙ (g x ∙ h x))`——refl 只会「算」不会「比函数」，它把两边
η-展开成 `λ x → …` 之后干脆拿**不同体**的开头硬比（报错里 `f x + g x`
撞 `f x` 就是这么来的）。同一堵墙更早的版本（20 章老朋友）：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe40g.agda:15.9-13: error: [UnequalTerms]
The terms
  x + 2
and
  suc (suc x)
are not equal at type ℕ
when checking that the expression refl has type f₁ ≡ f₂
```

`f₁ x = x + 2` 与 `f₂ x = 2 + x` 逐点成立（≗ 可证：`f₁≗f₂ (suc x) =
cong suc (+-comm x 2)`），整体 `≡` 却过不了 refl——**逐点等 ≠ 相等，
中间差一条函数外延公理**。20 章手工 postulate 过 `funExt`，40 章对过账：
网上教程常见的 `Function.Extensionality` 在 3.0 **根本不存在**，正主是
`Axiom.Extensionality.Propositional`：

```agda
open import Axiom.Extensionality.Propositional using (Extensionality)

-- 源码（Axiom/Extensionality/Propositional.agda:20 起）——还是依赖版：
Extensionality : (a b : Level) → Set _
Extensionality a b =
  {A : Set a} {B : A → Set b} {f g : (x : A) → B x} →
  (∀ x → f x ≡ g x) → f ≡ g
```

教程立场与 20 章一致：**只 import 这个记录类型，不假设它成立**——
把外延做成**参数化的构造**，谁手持 `ext` 谁实例化：

```agda
⊙-assoc-≗ : ∀ {A : Set} (M : Monoid) (f g h : A → Carrier M) →
            _⊙_ A M (_⊙_ A M f g) h ≗ _⊙_ A M f (_⊙_ A M g h)
⊙-assoc-≗ M f g h x = assoc (is-monoid M) (f x) (g x) (h x)

module _ {A : Set} (M : Monoid) (ext : Extensionality 0ℓ 0ℓ) where
  pointwise : IsMonoid (_⊙_ A M) (εᵖ A M)
  assoc     pointwise f g h = ext (⊙-assoc-≗ M f g h)
  identityˡ pointwise f     = ext (⊙-identityˡ-≗ M f)
  identityʳ pointwise f     = ext (⊙-identityʳ-≗ M f)
```

注意分工：`⊙-assoc-≗` 每条都是**纯计算**——取一点 `x`，两边各自归约，
剩 M 自己的 assoc（「逐点证全是计算」）；`ext` 只负责最后一步
`≗ → ≡` 的惊险一跃。f₁/f₂ 的完整版同款住在示例里：
`module _ (ext : …) where f₁≡f₂ = ext f₁≗f₂`。cubical（32 章）里
外延是定理不是公理，这是「intensional 型论要当佐料、cubical 免费」的
又一处对照。为什么本章非做 pointwise monoid 不可？它是「函数式度量」
的地基：`A → ℕ` 上的逐点加法 monoid，让「每个特征单独求和」也是一次
折叠——折纸的纸还能再摊大。

## 22.9 Foldable：折叠离开列表

书的原话：列表没什么特别。把「可折叠」抽象成一枚记录（书末
Monoidal Origami 的收尾）：

```agda
record Foldable (Container : Set → Set) : Set₁ where
  field
    fold : (M : Monoid) {A : Set} → (A → Carrier M) → Container A → Carrier M
```

三个实例：`fold-list = record { fold = foldList }`；Maybe（`just x → f x`，
`nothing → ε`）；二叉树**中序折叠**：

```agda
Foldable.fold fold-bintree M f empty          = Monoid.ε M
Foldable.fold fold-bintree M f (branch l x r) =
  Monoid._∙_ M (Foldable.fold fold-bintree M f l)
    (Monoid._∙_ M (f x) (Foldable.fold fold-bintree M f r))
```

容器无关的两条通用摘要立得——`+-0-m` 配 `const 1` 数元素、
`++-m` 配 `λ x → x ∷ []` 收元素（中序）：

```agda
_ : size∀ fold-bintree (branch (leaf true) false (leaf true)) ≡ 3
_ = refl

_ : elems∀ fold-bintree (branch (leaf 1) 2 (leaf 3)) ≡ 1 ∷ 2 ∷ 3 ∷ []
_ = refl
```

书中算例（那棵三个节点的真假树）逐字复现。折纸到此收束成一句设计口诀：
**能把问题写成某个 monoid 上的 foldMap，就自动获得分块并行
（fold-++）、融合免中间结构（fold-map）、多路合并（×-monoid）与
算法搬运（hom-fold）四件套**——而且列表、树、Maybe 一概通用（Foldable）。
`fold-++` 对 BinTree 没有逐字陈述（树没有现成的「切两半」），
但它正是「分治 = 折叠」的技术支撑，留作读者练习。

## 22.10 坑位清单（实测）

1. **`MonHom f` 的隐式参数反推不出来**：`Carrier` 是投影不可逆，
   签名裸写 `MonHom f →` 会让 rewrite 整段失灵（两条 `RewritesNothing`
   警告 + UnequalTerms，全文见 22.7）。解法：`MonHom {M = M} {N = N} f`。
   推论：record 的**参数藏在投影后面**时，使用前一律显式钉死。
2. **函数等式不吃 refl**：`f₁ ≡ f₂`（x+2 对 2+x）报
   `The terms x + 2 and suc (suc x) are not equal`——refl 只比**定义展开**，
   函数相等要么逐点 `≗` 要么请外延（22.8；20/40 章）。pointwise assoc 的
   `The terms f x + g x and f x are not equal` 是同一堵墙的另一个面。
3. **`≡-Reasoning` 搬不动**：它是 Properties 里的**模块**不是名字，
   `using (≡-Reasoning)` 实测吃一条警告
   `-W[no]ModuleDoesntExport: The module Relation.Binary.PropositionalEquality
   doesn't export the following: ≡-Reasoning`——using 列表只搬走同文件
   导出的名字，模块要 `open`。正解 `where open Eq.≡-Reasoning`
   （配 `import ... as Eq`，16 章老路）。
4. **裸类型变量不自动泛化**：书里 Haskell 风味签名 `any? : (A → Bool) → …`
   直接 `Not in scope: A`（探针 40l）——05 章说过，Agda 的自动泛化以
   `variable` 声明为前提，声明处没有 Haskell 式隐式 ∀，全部改
   `∀ {A : Set} → …`。
5. **记录字段的 infix 简写会串线**：`foldList` 的 cons 步想偷懒写
   `f x ∙ fold M f xs`，顶层 `open Monoid public` 之后 `_∙_` 解析成
   **字段访问器本身**，第一个参数被按 `Monoid` 检查：
   `The type Carrier M is not a subtype of Monoid … checking that the
   expression f x has type Monoid`（探针 40o）。改走 `where open Monoid M`
   也不省事——探针 40q/40v 实测 where 内层函数反而丢了外层子句变量
   （`Not in scope: f`，连显式应用都救不回来）。全书统一显式
   `Monoid._∙_ M a b`，别省。
6. **参数化 monoid 顶层装箱防悬空**：`++-m = bundle ++-[]` 报
   `UnsolvedMetaVariables`（元素类型 `A` 无处求解；探针 40p：35.15-20
   一处无解 meta）。写 `++-m {A = A} = bundle (++-[] {A = A})`，
   签名同步改成 `∀ {A : Set} → Monoid`。
7. **手搓与 stdlib 整包不互喂 + 级别账**：`std-+-monoid : NaiveMonoid`
   报 `The type Monoid 0ℓ 0ℓ is not a subtype of NaiveMonoid`（多 `_≈_`
   字段、级别参数入型，22.2）；装箱版都住 `Set₁`，裸公理版住 `Set₀`，
   硬塞小一级报 `The types Set₁ and Set are not equal`。跨层走
   `naive→std`/`std→naive`，记得补 `∙-cong = cong₂ ∙`。
8. **stdlib `_∘_` 塞不进 `Op₂`**：依赖版吃隐式参数挡位，
   `is not a subtype of {x : _A_23} (y : _B_24 x) → _C_25 y`（22.1）。
   手写 `λ f g x → f (g x)`。
9. **record 字段名与顶层函数同名 = 自杀**：`Foldable.fold` 字段配顶层
   `fold` 报 `ClashingDefinition`（探针 40m：Multiple definitions of fold）。
   `open R public` 会把字段访问器倒进顶层，示例里折叠函数叫 `foldL`、
   `foldList`，`fold` 一名让给 Foldable 字段。
---
上一章：[21 · 关系代数与抽象代数](21-algebra.md) ｜ 下一章：[23 · 类型的代数：ADT 作为半环](23-type-algebra.md) ｜ 返回：[README](../README.md)
