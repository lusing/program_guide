# 08 · 列表专题

列表是函数式编程的呼吸，也是依赖类型教程里最常见的「第一个真正有用的
数据类型」。本章把 `List` 从头解剖一遍：data 定义里参数 `{A}` 到底去了哪、
构造子 `∷` 的优先级怎么读、map/filter/zipWith/concat/`_++_`/foldr/foldl
这一族操作在 stdlib 2.3 里的**真实签名**（有好几处和 Haskell 不一样，
不实测根本发现不了）、`reverse` 的三种写法与它们的价格标签，最后用一截
把长度写进类型的小型 `Vec` 为 16 章埋伏笔——你会亲眼看到隐式索引参数
{m} {n} 如何既添乱又救命。照例：一切以 Agda 2.8.0 + stdlib 2.3 实测为准，
报错原文直接粘贴。

对应示例：`../examples/Ex08_lists.agda`

## 8.1 data 定义解剖：参数、构造子与优先级

`List` 是内建类型，真身在 Agda 安装目录的 prim 库里
（`/usr/share/libghc-agda-dev/lib/prim/Agda/Builtin/List.agda`），
stdlib 的 `Data.List.Base` 只是给它套了层家常便饭的 re-export：

```agda
infixr 5 _∷_
data List {a} (A : Set a) : Set a where
  []  : List A
  _∷_ : (x : A) (xs : List A) → List A
```

三个观察点：

1. **`A` 是参数不是索引**。它在 `data` 头出现、在所有构造子结果里
   原样不变——所以构造子的类型里你看不到 `(A : Set)`：`_∷_` 的完整
   类型是 `A → List A → List A`，`A` 由外层 data 参数**偷偷供给**。
   对照第 10 章：索引类型（如 `Vec A n`）的构造子签名里才会出现
   索引的具体形状。
2. **`infixr 5 _∷_`**：右结合、优先级 5。配合「函数应用最紧」，
   `f x ∷ xs` 解析成 `(f x) ∷ xs`，而 `1 ∷ 2 ∷ 3 ∷ []` 是右梳的
   `1 ∷ (2 ∷ (3 ∷ []))`。自定义同型数据时这个声明**不能省**——
   不写就按默认 `infixl 9` 处理，链式使用直接报（8.7 有同款实测现场）：

   ```text
   error: [NoParseForApplication]
   Could not parse the application 1 ∷ 2 ∷ 3 ∷ []
   Operators used in the grammar:
     ∷ (infix operator, level 20) [_∷_ (at ...)]
   ```

3. **为什么 Agda 把 List 内建**：`{-# BUILTIN LIST List #-}` 让内核在
   归约、编译后端等环节直接认识它（求值更快）。注意这**不附带**任何
   `[a,b,c]` 字面量语法——别指望，8.2 实测。

示例文件里自带一份逐字同构的 `MyList`（构造子改名 `m[]`/`_m∷_`），
配上双向转换 `toMy`/`fromMy` 和一条 refl 往返证明，专治「参数去哪了」
的困惑——构造子 `_m∷_ : A → MyList A → MyList A` 的签名里同样没有
`(A : Set)`，因为它俩是**同一种**声明。

## 8.2 「列表字面量」的真相：Agda 2.8 没有 `[1,2,3]`

这是本章最反直觉的实测结论。写 Haskell 的手感直接平移：

```agda
bad : List ℕ
bad = [ 1 , 2 , 3 ]
```

报错不给你任何商量的余地：

```text
examples/Tmp08c.agda:7.7-8: error: [NotInScope]
Not in scope:
  [
  at examples/Tmp08c.agda:7.7-8
when scope checking [
```

**方括号根本不是什么字面量语法**——它只是 `Data.List.Base` 里一个普通的
mixfix **函数** `[_]`：

```agda
[_] : A → List A
[ x ] = x ∷ []
```

于是 `[ 42 ]` 能用（单元素），而 `[ 1 , 2 , 3 ]` 之所以有时「看起来能跑」，
是因为逗号另有其人——它是 `Data.Product` 的**配对构造子**！当 `,` 在
作用域里时，`[ 1 , 2 ]` 解析为 `[_] (1 , 2)`：**装着对子 `(1 , 2)` 的
单元素列表**，而不是两元素列表。示例文件里钉了一条实测等式：

```agda
tricky : List (ℕ × ℕ)
tricky = [ 1 , 2 ]

_ : tricky ≡ (1 , 2) ∷ []
_ = refl
```

这坑的阴险在于：元素恰好是乘积类型时它**类型检查全对**，只有当你以为
拿到两个元素时它才露出獠牙。至于「用别的类型重载列表字面量」的
`Agda.Builtin.FromList` 机制（某些资料提过），2.8.0 实测**不存在**：

```text
error: [FileNotFound]
Failed to find source of module Agda.Builtin.FromList in any of the following locations: ...
```

正确姿势朴素得像没有姿势：`1 ∷ 2 ∷ 3 ∷ []`，或者配个本地小助手
`list3 = 1 ∷ 2 ∷ 3 ∷ []`。记住这条，读任何声称 Agda 有 `[a,b,c]` 记法的
旧帖都要先跑为敬。

## 8.3 map / filter / zipWith / concat：签名里的两个 Haskell 分水岭

`Data.List`（由 `Data.List.Base` 提升）提供的全家福，先看骨架签名：

```agda
map     : (A → B) → List A → List B
filter  : ∀ {P : Pred A p} → Decidable P → List A → List A
filterᵇ : (A → Bool) → List A → List A
zipWith : (A → B → C) → List A → List B → List C
concat  : List (List A) → List A
length  : List A → ℕ      -- 实际定义：foldr (const suc) 0
```

**分水岭一：`filter` 收 Bool 谓词是 Haskell 的写法。**stdlib 2.x 起
`filter` 要的是**可判定性的证明** `Decidable P`（15 章主角），Bool 版本
被挪到 `filterᵇ`。拿 Haskell 肌肉记忆直接喂 Bool，撞上的是一条相当
玄学的类型不匹配（实测）：

```text
error: [UnequalTerms]
Bool !=< Relation.Nullary.Decidable.Core.Dec (_P_5 n)
when checking that the expression true has type ...
```

翻译成人话：它要 `Dec (P n)`（`yes 证明 ∣ no 证明` 的判定结果），
你给的是 `true`（一个 Bool）。两条正解都在示例里：

```agda
_ : filter (λ n → n <? 3) lit ≡ 1 ∷ 2 ∷ []      -- n <? 3 返回 Dec (n < 3)
_ = refl

even? : ℕ → Bool
even? zero = true
even? (suc zero) = false
even? (suc (suc n)) = even? n

_ : filterᵇ even? lit ≡ 2 ∷ []                  -- Bool 版走 ᵇ
_ = refl
```

**分水岭二：zipWith 短截断，且长度不进类型**。`zipWith _+_ [1,2,3] [10,20]`
得到两元素的 `11 ∷ 22 ∷ []`——丢掉的尾巴在类型上**毫无痕迹**。这正是
16 章 `Vec` 要解决的失忆症（8.7 先尝一口）。concat、`_++_`、`[_]` 等
一切照旧，全部有 refl 焊死的实测等式，示例文件里挨个排着。

## 8.4 附录：`_++_` 与结合律方向——「哪侧被重抄」决定你白送哪些引理

stdlib 的定义一行一行贴在眼前（`Data/List/Base.agda`，实测原文）：

```agda
infixr 5 _++_
_++_ : List A → List A → List A
[]       ++ ys = ys
(x ∷ xs) ++ ys = x ∷ (xs ++ ys)
```

07 章的视角：`++` 在**左参数**上结构递归；等式 1 直接**返回 ys 本尊**
（零拷贝共享），等式 2 拷走一个 x 再递归。三条后果，条条实测：

**后果一：左单位律是 definitional 的，白送：**

```agda
++-left-id : ∀ {A : Set} (xs : List A) → [] ++ xs ≡ xs
++-left-id xs = refl
```

**后果二：右单位律对开口变量过不了 refl**（左边卡在 `match xs`），
示例里以注释保存的正是这条真实报错：

```text
error: [UnequalTerms]
xs ++ [] != xs of type List A
when checking that the expression refl has type xs ++ [] ≡ xs
```

对**闭**列表却算得动——`lit ++ [] ≡ lit` 一条 refl 过关。这种
「同一个引理，实例能 refl、一般陈述不能」的分裂是 Agda 新手最高频的
困惑源之一，第 13 章用归纳法补一般陈述。剧透：stdlib 的
`Data.List.Properties` 里 `++-identityˡ xs = refl` 一字不差就是本节
后果一，而 `++-identityʳ (x ∷ xs) = cong (x ∷_) (…)` 正是标准归纳剧本——
左单位白送、右单位归纳，方向感完全一致。

**后果三：结合律同理**。(xs ++ ys) ++ zs 与 xs ++ (ys ++ zs) 对开口
变量不 definitional（一边先拆左、一边拆了再拆），但任何**具体**列表上
两边归约到同一范式——示例钉的最小结合实例（infixr 链右梳的读法也藏在
里面）：

```agda
_ : 1 ∷ 2 ∷ [] ++ 3 ∷ [] ≡ 1 ∷ 2 ∷ 3 ∷ []
_ = refl
```
效率口径由此定型：`xs ++ ys` 的代价是 **|xs| 次拷贝**，ys 免费。写
`foldr _++_ []`（concat 的真身）时，长表放左还是放右，性能差一个
数量级——8.6 反转对比见真章。

**推理坑**：`++` 左右两侧的类型各自独立可推，但**元素类型完全指望
上下文**。裸的空表谁也不欠谁：`length []` 实测直接炸（`UnsolvedMetaVariables`：
元素类型这个隐式参数无人认领）。别指望加个顶层签名就能救——
`fixed : ℕ; fixed = length []` 实测仍报 meta（签名约束的是**结果**类型
ℕ，元素类型 `A` 不被它绑定）。正解是显式填隐式参 `length {A = ℕ} []`
（示例采用，实测过），或者干脆 `1 ∷ 2 ∷ []` 起手就别让 `[]` 落单。

## 8.5 foldr / foldl：参数顺序与严格性

先给结论：**stdlib 的 foldr/foldl 参数顺序与 Haskell 完全相同**
（函数、种子、列表），Coq 的 `fold_right` 也相同；真正的差异在**求值
策略**。定义仍是 Base 原文：

```agda
foldr : (A → B → B) → B → List A → B
foldr c n []       = n
foldr c n (x ∷ xs) = c x (foldr c n xs)

foldl : (A → B → A) → A → List B → A
foldl c n []       = n
foldl c n (x ∷ xs) = foldl c (c n x) xs
```

注意 `foldl` 的类型：累加器是**函数第一个参数**、结果类型 A 跟种子走——
和 Haskell 的 `(b -> a -> b) -> b -> [a] -> b` 逐字对应。示例实测：

```agda
_ : foldl (λ acc n → acc * 10 + n) 0 lit ≡ 123
_ = refl

_ : foldr _∷_ [] lit ≡ lit
_ = refl
```

Haskell 经验需要覆写的两处：

1. **foldr 的惰性红利没了**。Agda 按需求值但终止检查器不买「lazy
   foldr 处理无限表」的账（无限表属于 22 章的 Stream + guardedness），
   而 `foldr const 0 lit` 这类「短路」在类型上也不比 foldl 便宜——
   两家都得列表有限。
2. **foldl 攒不出 Haskell 的 thunk 塔**：Agda 的规范化策略不同，性能
   讨论请 entirely 以 26 章实测为准；日常记住 stdlib 自己就用
   `foldl (flip _∷_)` 造 `reverseAcc`（Base 原文），`flip` 来自
   `Function`/`Data.List.Base` 的内部 import。

## 8.6 反转三写法：naive、累加器、以及标准库的第三种

**写法一 naive**——教科书最爱，复杂度最恨：

```agda
revNaive : ∀ {A : Set} → List A → List A
revNaive [] = []
revNaive (x ∷ xs) = revNaive xs ++ [ x ]
```

递归返回后 `++ [ x ]` 要把**已反转的整条 xs 重抄一遍**（8.4 后果的
直接推论：++ 拷左扔右）。n 个元素各拷一次 → **O(n²)**。

**写法二 累加器**——把「重抄」换成「搬家」：

```agda
revAcc′ : ∀ {A : Set} → List A → List A → List A
revAcc′ acc [] = acc
revAcc′ acc (x ∷ xs) = revAcc′ (x ∷ acc) xs

revAccum : ∀ {A : Set} → List A → List A
revAccum xs = revAcc′ [] xs
```

每步只把 x 挂到 acc 头上，指针搬运 n 次，**O(n)**、尾部规约到常数
形状。实测两版在 `lit` 上会师：

```agda
_ : revAccum lit ≡ reverse lit
_ = refl
```

**写法三 标准库**：`reverse = reverseAcc []`，而
`reverseAcc = foldl (flip _∷_)`——三写法其实是两写法加一个 fold。
Base 还顺手卖了一条 `xs ʳ++ ys = reverse xs ++ ys`（`_ʳ++_`），
把「反转再接上」合成一趟，写连接类算法时省一次中间拷贝。

**依赖版**长什么样？「反转保长度」在 List 上只能当定理说
（`length (reverse xs) ≡ length xs`），进了 `Vec` 就变成**类型**
（8.7）：`Vec.reverse : Vec A n → Vec A n`。效率之外它还有免费午餐：
16 章里你会看到 Vec 版反转连「越界/错位」这类 bug 都写不出来。

**一条免费的分配律实例**（一般陈述留给 13 章练手）：

```agda
_ : reverse (lit ++ one) ≡ reverse one ++ reverse lit
_ = refl
```

## 8.7 隐式长度预告：把「几」写进类型，为 16 章埋雷

最后 30 行代码，演示依赖版 append 的**手感**（完整 Vec 16 章再学）。
自己搭一个最小索引类型——注意构造子上的 `{n : ℕ}` 隐式索引参数：

```agda
data Vec (A : Set) : ℕ → Set where
  v[] : Vec A zero
  _v∷_ : {n : ℕ} → A → Vec A n → Vec A (suc n)
infixr 5 _v∷_

_v++_ : ∀ {A : Set} {n m : ℕ} → Vec A n → Vec A m → Vec A (n + m)
v[]       v++ ys = ys
(x v∷ xs) v++ ys = x v∷ (xs v++ ys)
```

`_v++_` 的类型就是一本**自动流水账**：进去 n 加 m，出来 n+m，长度
不可能对不上——List 版 `++` 想做而做不到的事。代价也立刻到账，
三笔都实测过：

1. **裸 `v[]` 落单就炸**。`oops = v[] v++ v[]` 报
   `UnsolvedMetaVariables`：两个隐式长度 `{n} {m}` 没有任何来源。
   比 8.4 的 `length []` 更凶——这次缺的不只是元素类型，还有索引。
2. **写错长度当场拒绝**。`wrong : Vec ℕ 4; wrong = 1 v∷ 2 v∷ 3 v∷ v[]`
   在剥到 `v[]` 时发现账目对不平：

   ```text
   error: [UnequalTerms]
   0 != 1 of type ℕ
   when checking that the expression v[] has type Vec ℕ 1
   ```

3. **优先级声明不能省**：一开始忘了 `infixr 5 _v∷_`，`1 v∷ 2 v∷ 3 v∷ v[]`
   直接吃 8.1 引过的那条 `NoParseForApplication`。

好消息是账本同时送你**免检权利**：`v[] v++ v3 ≡ v3` 一条 refl 通过，
而且结果类型自动是 `Vec ℕ 3`——检查器**顺手**证明了「append 保持
长度」这类在 List 上需要归纳的命题的一部分。这就是 16 章的世界观：
**推断从运行期搬到编译期，先付隐式参数的税，再领类型安全的退税**。

## 8.8 本章坑位清单（实测）

1. **`[ 1 , 2 , 3 ]` 在 2.8 不存在**：`Not in scope: [`；`[ x ]` 只是
   单元素函数 `[_]`；`Agda.Builtin.FromList` 也没有（`FileNotFound`）；
2. **`[ 1 , 2 ]` 是「装了对子的单元素列表」**：逗号来自 `Data.Product`，
   元素恰为乘积类型时类型检查全对、语义全错（`tricky ≡ (1 , 2) ∷ []`
   实测为真）——本章头号暗坑；
3. **`filter` 吃 `Decidable P` 不吃 Bool**：Bool 版本叫 `filterᵇ`，
   硬喂 Bool 报 `Bool !=< Dec (_P_5 n)`；
4. **`length []` / 裸 `v[] v++ v[]` 报 `UnsolvedMetaVariables`**：元素
   类型与隐式索引都要人认领；顶层签名也救不了（实测仍报 meta），正解是
   `length {A = ℕ} []` 式显式填参；且 **Agda 没有项级标注语法
   `([] : List ℕ)`**——实测 `ParseError`（冒号标注只属于签名行）；
5. **`xs ++ [] ≡ xs` 对开口变量 refl 不过**，但闭列表实例过——同一个
   引理「有时能证」的分裂感要先适应（右单位/结合律归 13 章归纳管）；
6. **自定义 cons 型构造子忘 `infixr 5` 直接不能成链**：默认 `infixl 9`
   下报 `Could not parse the application ...`（报错会附 level 20 的语法表）；
7. **`using` 列表里运算符的下划线数就是名字本身**：`_*_` 写成 `_*`
   报 `ModuleDoesntExport _*` + 后续 `Not in scope: *` 连环撞。

---
上一章：[07 · 递归与终止检查](07-recursion.md) ｜ 下一章：[09 · 记录与 Σ 类型](09-records.md) ｜ 返回：[README](../README.md)
