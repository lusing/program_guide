# 17 · 函数世界：同构与外延

第 11 章给数据定义了 `_≡_`：两个自然数相等，当且仅当正规形相同。
但函数是「没法归一化完」的值——`λ n → n + zero` 和 `λ n → n` 谁也
不「等于」谁，类型检查器只会 β 归约和模式匹配，不会「比较」两个
λ。本章沿三条线把这个缺口补上：**定义相等层**——Agda 内建函数 η
规则，`f ∘ id ≡ f` 这类等式 refl 直接白送；**命题层**——逐点相等
推出函数相等需要函数外延公理 `funExt`，stdlib 2.3 不提供，必须自己
`postulate`（`--cubical` 下可证，24 章预告）；**结构层**——用
`Function.Bundles` 的 `_↔_`（双射）、`_↩_`（左逆）、
`Function.Related`（相对强弱）给「两个类型长得一样」记账。读完你
能回答：为什么 `(Bool → A) ≅ A × A` 一侧平凡、另一侧却要动用公理。

对应示例：`../examples/Ex17_functions.agda`

报错文本与模块路径均为 Agda 2.8.0 + stdlib 2.3 实测；文中 cubical
片段的完整可编译版本另存于 `../examples/Tmp17c.agda`（自带
`--cubical` 选项，独立检查）。

## 17.1 内核认的底线：η 与定义相等

Agda 对函数有一条**定义性 η 规则**：`λ x → f x` 与 `f` 在类型检查
器眼里是同一个东西。三行 `refl` 全部通过（示例 `η₁/η₂/η₃`）：

```agda
η₁ : ∀ (f : Bool → Bool) → f ∘ id ≡ f
η₁ f = refl

η₂ : ∀ (f : Bool → Bool) → (λ x → f x) ≡ f
η₂ f = refl

η₃ : ∀ (f : Bool → Bool) (x : Bool) → (λ x → f x) x ≡ f x
η₃ f x = refl
```

η₁ 能过，是因为 `f ∘ id` 展开成 `λ x → f (id x)`，`id x` 再 β 归约
成 `f x`，最后 η 把 `λ x → f x` 收拢回 `f`——全程「定义相等」，不
需要任何公理。这是 Agda 比「η 只在命题层」的系统（如某些 cubical
实现）宽松的地方，写证明时放心用。

顺手把 `Function.Base` 的记号各点一次名：

```agda
flip-demo : flip _+_ 3 0 ≡ 3
flip-demo = refl

pipe-demo : (3 |> (λ n → n + 4)) ≡ 7
pipe-demo = refl

∘′-demo : ∀ (f : Bool → Bool) → f ∘′ id ≡ f
∘′-demo f = refl
```

注意 `_∘′_` 与 `_∘_` 只差隐式显式：`_∘_` 的函数参数是隐式可推断，
`_∘′_` 全部显式，书写 `f ∘′ g` 时参数顺序和 `f ∘ g` 一样。
`_|>_`（pipe）与 `_$_`（apply）是「换括号」双雄：`x |> f` 就是
`f x`，只是把主语放前面；实测坑：`_|>_` 的结合优先级比 `≡` 松，
`3 |> f ≡ 7` 会被解析成 `3 |> (λ n → n ≡ 7)` 报类型错，须写括号
`(3 |> (λ n → n + 4)) ≡ 7`。

**但 η 救不了所有函数等式**。看这个再朴素不过的例子：

```agda
f₁ f₂ : ℕ → ℕ
f₁ = λ n → n + zero
f₂ = λ n → n

bad : f₁ ≡ f₂
bad = refl   -- 报错！
```

实测报错（Agda 2.8.0）：

```
x + zero != x of type ℕ
when checking that the expression refl has type f₁ ≡ f₂
```

报错里的 `x` 是 bound 变量——检查器把两个 λ 体在**逐点**比较，发现
`x + zero` 与 `x` 不是定义相等。根源在第 14 章就见过：`_+_` 按第一
参数归约，`n + zero`（变量在左）是**卡住的**正规形；只有
`zero + n ≡ n` 才是 refl。η 规则处理的是「λ 外壳」，管不了「体内
的算术」，所以：

> 定义相等能证 `λ x → f x ≡ f`，证不了 `λ n → n + 0 ≡ λ n → n`。
> 后者只能走命题层。

## 17.2 funExt：逐点相等推出函数相等

把「每个输入上取值都等」提升为「函数相等」，这条原理叫**函数外延
**（function extensionality）：

```
funExt : ((x : A) → f x ≡ g x) → f ≡ g
```

先实测一个失踪案：stdlib 2.3 **不提供** funExt——

```
$ grep -rn "funExt" /usr/share/agda-stdlib/src/ | wc -l
0
```

标准库刻意保持内核干净（外延、命题外延、选择公理都是「额外佐料」
，各章按需用），所以本章自己 postulate：

```agda
postulate
  funExt : ∀ {a b : Level} {A : Set a} {B : A → Set b}
           {f g : (x : A) → B x} → ((x : A) → f x ≡ g x) → f ≡ g
```

有了它，17.1 的残局一扫而光（`n+0≡n` 是第 13 章的归纳引理）：

```agda
f₁≡f₂ : f₁ ≡ f₂
f₁≡f₂ = funExt λ n → n+0≡n n
```

**方向不对称**值得单独说：funExt 是公理，反方向是定理——函数相等
作用到点上（`cong`）就有逐点相等，零成本：

```agda
funExt⁻ : ∀ {a b : Level} {A : Set a} {B : A → Set b}
          {f g : (x : A) → B x} → f ≡ g → (x : A) → f x ≡ g x
funExt⁻ p x = cong (λ h → h x) p
```

MLTT 的正规模型里 funExt 不成立（同一函数的不同 λ 项语法不同），
但它对命题层一致（不产生矛盾），postulate 是社区标准操作——和第
11 章讲过的 `J`/`subst` 一样，外延公理也是「无危害佐料」。

**`--cubical` 下它不是公理而是定理**（24 章正式开讲，这里只剧透
可编译的证据，见 `Tmp17c.agda`）：

```agda
{-# OPTIONS --cubical #-}
open import Agda.Builtin.Cubical.Path using (_≡_)

refl : ∀ {a : Level} {A : Set a} {x : A} → x ≡ x
refl {x = x} i = x

funExt : ∀ {a b : Level} {A : Set a} {B : A → Set b}
         {f g : (x : A) → B x} → ((x : A) → f x ≡ g x) → f ≡ g
funExt {f = f} {g = g} h i x = h x i
```

类型检查器把 `f ≡ g` 看作「带区间参数 i 的路径」，而 `h x i` 恰好
是「区间 × 定义域」拼出的正方形——funExt 的证明就是一次**换元**。
这反过来解释了为什么外延在 intensional 型论里要当公理：在 cubical
里它内建在路径的类型里。

实测坑三连：① 此模式必须配 `Agda.Builtin.Cubical.Path` 的 `_≡_`；
② stdlib/`Agda.Builtin.Equality` 的 `_≡_` 在 cubical 模式下仍是
wrapper datatype（仍是 `data _≡_ where refl`），拿它写 `h i x` 模
式匹配直接吃闭门羹：

```
Cannot eliminate type f ≡ g with variable pattern i (did you supply
too many arguments?)
when checking the clause left hand side
funExt {f = f} {g = g} h i x
```

③ Path 版 `_≡_` 不导出 refl，要自己写一行 `refl {x = x} i = x`。

## 17.3 有限域上的函数相等：可判定

`f ≡ g`（`f g : Bool → Bool`）看着吓人，其实 Bool 只有两个点，函
数总共 2²=4 个，逐个查点就能判——关键是**先判逐点，再用外延拼接**
。stdlib 没有现成的函数相等判定器（`Function.Bundles` 只有 `⇔`
双箭头，没有 `_⇔_?`；实测搜 `decEq` 在 Function/ 目录零命中），自
己造：

```agda
≟-pointwise : (f g : Bool → Bool) → Dec ((x : Bool) → f x ≡ g x)
≟-pointwise f g with f true ≟ g true | f false ≟ g false
... | yes p₁ | yes p₂ = yes (λ { true → p₁ ; false → p₂ })
... | no ¬p₁ | _      = no λ h → ¬p₁ (h true)
... | _      | no ¬p₂ = no λ h → ¬p₂ (h false)

≟-fun : (f g : Bool → Bool) → Dec (f ≡ g)
≟-fun f g with ≟-pointwise f g
... | yes h = yes (funExt h)
... | no ¬h = no λ eq → ¬h (funExt⁻ eq)
```

逐条读：`≟-pointwise` 用 `Data.Bool.Properties` 的 `_≟_`（Bool 判
等）分别查两个点，四个 with 分支覆盖所有组合；`no` 分支里
`λ h → ¬p₁ (h true)` 是说「若逐点相等成立，则它在 true 上的分量
与 p₁ 的否定矛盾」——否证逐点相等只需要在一个点上找岔。
`≟-fun` 正面用 17.2 的 funExt 把逐点证据升格成函数等式，反面用免
费的 funExt⁻ 降回去。**公理只在正向用了这一次。**

自检小例：

```agda
not≢id : not ≢ (λ x → x)
not≢id eq = not≢id-pointwise (funExt⁻ eq)
  where
  not≢id-pointwise : ¬_ ((x : Bool) → not x ≡ id x)
  not≢id-pointwise h = case h true of λ ()
```

`h true : not true ≡ id true`，即 `false ≡ true`，`λ ()` 一锅端。

推广口径：定义域**有限**（可枚举成表）+ 余域判等可判定 ⇒ 函数判等
可判定；`ℕ → ℕ` 就完全没戏——逐点要查无穷个点，且总函数的等价性
本身就不可判定。这不是 Agda 的锅，是数学事实。

## 17.4 Function.Bundles：`_↔_`、`_⇔_`、`_⟶_`、`_↩_`

「两个类型同构」在纸上写 `A ≅ B` 就完了；Agda 里它是一个**记录**
，字段把「谁到谁、逆是谁、两条往返律」全部显式装袋。先实测失踪案
二号——很多老教程写 `import Logic`：

```
Failed to find source of module Agda.Builtin.Logic …
```

`Logic` 与 `Agda.Builtin.Logic` 在 stdlib 2.x 已整体删除；
`Function.Inverse` 也自 2.0 起弃用。**正品是
`Function.Bundles`**（配 `Function.Structures` 里的 `IsXxx` 字段
层）。核心记录（源码注释原话：「同构 = 互逆对」）：

```agda
record Inverse (A : Set α) (B : Set β) : Set (α ⊔ β) where
  field
    to       : ⦃ Setoid A ⦄ → A → B    -- 概念示意：Actual 定义用 ≡-setoid
    from     : B → A
    to-cong  : ∀ x y → x ≡ y → to x ≡ to y
    from-cong : ∀ x y → x ≡ y → from x ≡ from y
    inverse  : to ∘ from ≡ id × from ∘ to ≡ id
```

手搓五条字段太累（源码 `Function/Bundles.agda` 第 275 行起）：

```agda
record Inverse : Set (a ⊔ b ⊔ ℓ₁ ⊔ ℓ₂) where
  field
    to        : A → B
    from      : B → A
    to-cong   : Congruent _≈₁_ _≈₂_ to
    from-cong : Congruent _≈₂_ _≈₁_ from
    inverse   : Inverseᵇ _≈₁_ _≈₂_ to from   -- = Inverseˡ × Inverseʳ
```快捷构造 `mk↔ₛ′` 只要四个参数：

```agda
mk↔ₛ′ : ∀ (to : A → B) (from : B → A) →
        StrictlyInverseˡ _≡_ to from →   -- ∀ y → to (from y) ≡ y
        StrictlyInverseʳ _≡_ to from →   -- ∀ x → from (to x) ≡ x
        A ↔ B
```

**坑爆预警**：名字带 `ˡ` 的第一条律其实是 `to ∘ from ≡ id`（作用在
B 上的恒等）！命名沿用的是「from 出现在左侧」的历史习惯，与直觉
刚好相反。实测教训：写反两条定律，编译器报的错是两条互相缠绕的
类型不匹配，调试半天才发现是顺序问题。背下来：**mk↔ₛ′ 先「去回
」（to∘from），后「回去去」（from∘to）**。

例 1，`Σ` over Bool 就是 `⊎`（依赖和的非依赖分解，纯构造子演算）：

```agda
ΣBool↔⊎ : ∀ {A B : Set} → (Σ[ x ∈ Bool ] (if x then A else B)) ↔ (A ⊎ B)
ΣBool↔⊎ {A = A} {B = B} = mk↔ₛ′ to from
  (λ { (inj₁ a) → refl ; (inj₂ b) → refl })
  (λ { (true , a) → refl ; (false , b) → refl })
  where
  to : (Σ[ x ∈ Bool ] (if x then A else B)) → A ⊎ B
  to (true  , a) = inj₁ a
  to (false , b) = inj₂ b

  from : A ⊎ B → (Σ[ x ∈ Bool ] (if x then A else B))
  from (inj₁ a) = true  , a
  from (inj₂ b) = false , b
```

四条腿全是 refl——两边互为「换皮」，构造子算得动。

例 2，curry 同构 `(Bool → A) ≅ (A × A)`，这里剧情反转：

```agda
curry↔ : ∀ {A : Set} → (Bool → A) ↔ (A × A)
curry↔ {A = A} = mk↔ₛ′ to from to∘from from∘to
  where
  to : (Bool → A) → A × A
  to f = f true , f false

  from : A × A → Bool → A
  from (x , y) = λ b → if b then x else y

  from∘to : ∀ f → from (to f) ≡ f
  from∘to f = funExt λ { true → refl ; false → refl }

  to∘from : ∀ p → to (from p) ≡ p
  to∘from (x , y) = refl
```

`to∘from`（对偶对）refl 秒过；`from∘to`（对函数）必须 funExt——
`λ b → if b then f true else f false` 与 `f` 逐点等但定义不等。
**这就是外延的全部意义**：数据层再细碎，函数层永远差最后一块，
公理补上。也解释了本章标题——同构检验（↔）和外延（funExt）是同
一条裂缝的两面。

其余三个 bundle 一句话定位：

- `_⇔_`（`mk⇔ to from`）：**可互达**，只有 to/from（+cong），没有
  任何往返定律——比 ↔ 弱得多，别拿它当同构用。`A × B ⇔ B × A`
  一行 `mk⇔ swap swap` 就成，但 `A ⇔ B` 完全推不出 `A ↔ B`。
- `_⟶_`（`mk⟶ f`）：**带同余证明的函数**（setoid 视角），应用写作
  `f ⟨$⟩ x` 而不是 `f x`。例：`double⟶ ⟨$⟩ 3 ≡ 6` 是 refl。
- `_↩_`（`mk↩`）：**左逆/收缩-扩张**。`A ↩ B` 记录 `to : A → B`、
  `from : B → A`，只要求一侧定律 `from ∘ to ≡ id`（即 A 是 B 的
   retract，to 是收缩、from 是截面）。例：`proj↩ : (A × Bool) ↩ A`
  ，丢 Bool 再补 true，回来原样；反方向 `from (to (a , b)) ≡ (a , b)`
  显然不成立（b 丢了），`↩` 只记成立的那半边。注意 mk↩ 的定律参
  数是曲解版 `Inverseˡ : ∀ {x y} → y ≡ from x → to y ≡ x`，实证的
  惯用写法是 `λ { refl → refl }`。

## 17.5 Pointwise：容器的逐点相等

`List A` 上「对应元素分别相等」的关系，stdlib 叫 Pointwise。实测
坑：**2.3 没有统一的 `Relation.Binary.Pointwise`**，它按容器拆住
——列表在 `Data.List.Relation.Binary.Pointwise`，向量在
`Data.Vec.Relation.Binary.Pointwise.Inductive`（另有 functional
版，见 16 章的两套 Vec）。且构造子 `∷`/`[]` 与列表构造子**同名**
，裸写 `refl ∷ refl ∷ []` 会被解析成列表，类型对了值却造不出来。
正解是给模块起别名，处处限定：

```agda
import Data.List.Relation.Binary.Pointwise as PW

pw-list : PW.Pointwise _≡_ (1 ∷ 2 ∷ []) (suc zero ∷ suc (suc zero) ∷ [])
pw-list = refl PW.∷ refl PW.∷ PW.[]
```

Pointwise 的价值在于它是**可组合的证明骨架**，比如 map 保逐点等：

```agda
map-preserves-Pointwise : ∀ {A B : Set} (f : A → B) {xs ys : List A} →
                          PW.Pointwise _≡_ xs ys →
                          PW.Pointwise _≡_ (map f xs) (map f ys)
map-preserves-Pointwise f PW.[]       = PW.[]
map-preserves-Pointwise f (r PW.∷ ps) =
  cong f r PW.∷ map-preserves-Pointwise f ps
```

实测坑二号：拿它推 `PW.Pointwise _≡_ (map g xs) (map g ys)` 时，
若目标里 `map g (1 ∷ 2 ∷ [])` 这种**卡住的函数应用**出现在索引位
置，unifier 无法从 `map` 里反解出列表，留下 Unsolved metavariables
——此时显式给出 `{xs = 1 ∷ 2 ∷ []} {ys = …}` 即可：

```agda
pw-map-demo : PW.Pointwise _≡_ (map g (1 ∷ 2 ∷ [])) (map g (1 ∷ 2 ∷ []))
pw-map-demo = map-preserves-Pointwise g {xs = 1 ∷ 2 ∷ []} {ys = 1 ∷ 2 ∷ []}
                (refl PW.∷ refl PW.∷ PW.[])
```

Vec 版同理（`import Data.Vec.Base as V` +
`… Pointwise.Inductive as VecPW`），长度相同是类型强制的前提，
`refl VecPW.∷ refl VecPW.∷ refl VecPW.∷ VecPW.[]` 造出
`VecPW.Pointwise _≡_ v₁ v₂`。

## 17.6 Function.Related：强弱关系统一记账

`A ≲ B`（A 可嵌入 B）、`A ≈ B`（双射）、`A ⇐ B`……这类「一个类
型不比另一个复杂」的关系，stdlib 收在 `Function.Related.Propositional`：

```
X ∼[ k ] Y      k ∈ { implication, injection, surjection,
                      equivalence, bijection, … }
```

语义是「从 X 到 Y 存在一个**至少是 k** 的映射」。三个示例（Ex17
`imp-demo/inj-demo/bij-demo`）：

```agda
imp-demo : ∀ {A B : Set} → (A × B) R.∼[ R.implication ] (A ⊎ B)
imp-demo = mk⟶ λ { (a , b) → inj₁ a }

inj-demo : ∀ {A B : Set} → A R.∼[ R.injection ] (A ⊎ B)
inj-demo = mk↣ {to = inj₁} λ { refl → refl }

bij-demo : ∀ {A B : Set} → (A × B) R.∼[ R.bijection ] (B × A)
bij-demo = ↔⇒ (×-comm _ _)
```

三条注意：① `implication` 档只要求「有函数」，用裸 `mk⟶` 即可，
`inj-demo` 的 `injective` 字段证明 `inj₁ x ≡ inj₁ y → x ≡ y` 时也
只需一个 refl；② `mk↣`/`mk↩` 的 `to`/`from` 是**隐式参数**，必须
`mk↣ {to = inj₁} …` 命名传入，裸位置应用报
WrongHidingInApplication；③ 同构到 `∼[ bijection ]` 的桥是 `↔⇒`
，而 `×-comm A B` 这种「参数全隐」的引理要写 `×-comm _ _` 才能把
A B 带出来。`R.K-trans` 提供同 kind 的传递复合，是链式推理的底座
。`Function.Related.TypeIsomorphisms` 里已经登记好了
`×-comm`/`⊎-comm`/`Σ-assoc` 一大批**具体双射**（都是 `↔`），要
哪条引哪条。扩展/收缩/伴随的直觉对应：`↩`（左逆）= 收缩+截面，
而「伴随」在 stdlib 另有 `Function.HalfAdjointEquivalence`——
`A ⇔ B` 的范畴升级版（带单位/余单位的自然同构），本章点到为止。

## 17.7 同构即相等？

集合论里两个双射集就是「一样」的集合（外延公理：元素相同即集合相
同）；MLTT 里 `A ↔ B` 只是**一条可搬运的等价**，命题是否对 `≡` 无
感——`Bool ≡ ℕ` 照样证不出，也照样不能用。差距的根源：MLTT 的等
式是**归纳生成**的最细关系（refl 起步），而数学传统想要的等式是
**外延生成**的最粗关系。本章的 funExt 已经朝「粗」走了一步；一步
到位就是**单价公理**（univalence：`(A ≃ B) ≡ (A ≡ B)`），那是
`--cubical` 的世界，24 章见分晓。工程上的折中心法：证明里能走
Pointwise/↔ 的明路就走，别硬凑 `≡`。

## 17.8 坑位清单（本项目实测）

1. **`Logic` / `Agda.Builtin.Logic` 已死**：stdlib 2.x 整体删除，
   老教程的 `open import Logic using (_↔_)` 直接 FileNotFound；
   正品 `Function.Bundles`。`Function.Inverse` 是弃用而非删除，
   别再用。
2. **funExt 全库 grep 零命中**：不是藏在哪个角落，是真没有；
   stdlib 立场是「佐料自备」。postulate 或上 `--cubical`。
3. **cubical 的 funExt 只认 Path 的 `_≡_`**：对 stdlib/Equality 的
   `_≡_` 做区间模式匹配报 `CannotEliminateWithPattern`；Path 版还
   不导出 refl，本地手写 `refl {x = x} i = x`。
4. **`mk↔ₛ′` 定律顺序反直觉**：第一参数是 `∀ y → to (from y) ≡ y`
   （名字却叫 `ˡ`）；写反得到两条缠死的类型不匹配，先查顺序。
5. **η 只剥 λ 外壳，不碰体内计算**：`f ∘ id ≡ f` 白送，
   `λ n → n + 0 ≡ λ n → n` 必卡（`n + 0` 是 stuck term，第 14 章
   的教训在函数空间的复刻）。
6. **Pointwise 按容器分家且构造子撞名**：没有全局
   `Relation.Binary.Pointwise`；`refl ∷ refl ∷ []` 会解析成 List，
   一律模块别名 `PW.` / `VecPW.`。
7. **卡住的函数应用别留在索引里**：`PW.Pointwise _≡_ (map g xs) …`
   当 unifier 反解不动 `map` 时报 Unsolved metavariables，显式给
   `{xs = …} {ys = …}`。
8. **`mk↣`/`mk↩` 的位置应用踩隐式参数**：WrongHidingInApplication
   ；老老实实 `{to = inj₁}`。`|> f` 表达式嵌等式时记得加括号。

---
上一章：[16 · Vec：长度索引的列表](16-vectors.md) ｜ 下一章：[18 · 关系代数与抽象代数](18-algebra.md) ｜ 返回：[README](../README.md)
