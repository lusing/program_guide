# 26 · 实战：可验证插入排序

25 章用依赖类型「构造即正确」地造了一门语言，重头戏是**索引挡错**；
本章换一块战场——一个真正的算法：插入排序。「跑了几组都对」和「对」
之间有一道鸿沟，填它得先把「正确」拆成两条可以说清的命题——**输出
有序**、**输出是输入的重排**——各证一条，再用 ×（12 章的合取）打包成
主定理。零件全是旧章回收（13 章 with 分案、06/09 章谓词匹配、14 章
≡-Reasoning、16 章 Vec），并与 coq 教程 21 章
（`../coq/docs/21-sorting.md`）逐段对照。

对应示例：`../examples/Ex26_sorting.agda`（全部报错为 Agda 2.8.0 +
stdlib 2.3 实测输出，探针文件测完已删）

## 26.1 算法：结构递归干净得像白开水

```agda
insert : ℕ → List ℕ → List ℕ
insert x [] = x ∷ []
insert x (y ∷ ys) with x ≤? y
insert x (y ∷ ys) | yes _ = x ∷ y ∷ ys
insert x (y ∷ ys) | no _ = y ∷ insert x ys

sort : List ℕ → List ℕ
sort [] = []
sort (x ∷ xs) = insert x (sort xs)
```

`insert` 假定 ys 已有序，把 x 插进第一个不小于它的位置；`sort` 递归排
尾、插头。两个递归严格走在 List 结构上（`ys`、`xs` 是缩小参数），终止
检查一眼过（07 章）。`≤?` 是 stdlib 的判定函数（15 章的 `Dec`），取代
coq 的 `Nat.leb`。小例子先跑通（源文件里展示求值用等式证明，02 章约定）：

```agda
_ : sort (5 ∷ 3 ∷ 1 ∷ 8 ∷ []) ≡ 1 ∷ 3 ∷ 5 ∷ 8 ∷ []
_ = refl

_ : sort (3 ∷ 3 ∷ 1 ∷ []) ≡ 1 ∷ 3 ∷ 3 ∷ []
_ = refl
```

`refl` 通过说明两边**约到同一个规范形**——但只有这几个具体列表的信息，
能跑 ≠ 正确。coq 21.1 那句「只满足一条的垃圾函数比比皆是」原样成立：
常返 `[]` 的函数有序但丢数据，`id` 保数据但未必有序——**正确 = 两条
都要**。

## 26.2 性质一：Sorted——两个互相搭手的归纳谓词

「有序」怎么形式化？示例自造两个归纳数据（Curry–Howard 下命题即类型，12 章）：

```agda
data AllLe : ℕ → List ℕ → Set where
  le[] : ∀ {x} → AllLe x []
  le∷ : ∀ {x y ys} → x ≤ y → AllLe x ys → AllLe x (y ∷ ys)

data Sorted : List ℕ → Set where
  s[] : Sorted []
  s∷ : ∀ {x xs} → AllLe x xs → Sorted xs → Sorted (x ∷ xs)
```

`AllLe x ys` 读作「x 不大于 ys 的**每一个**元素」（coq 21.3 的 `le_all`
同款），`Sorted` 逐层剥头、每个头全场压制剩下的表。为什么不用「相邻
两两 ≤」？coq 21.3 的理由原样继承：相邻版在 insert 保序时要**另证**
一轮「局部推全局」；全场压制版一步到位，代价只是引理随身多带一枚
`AllLe` 证据。实现层的差异才是要害：coq 的 `le_all`/`sorted` 是住在
`Prop` 里的 **Fixpoint**（命题由计算产生），Agda 这边是 **data**（命
题由构造子产生）——真不真不看怎么算，看能不能把构造子搭出来。

三件小工具先备齐。其一，≤ 传递性穿透 `AllLe`（coq `le_all_le` 的镜像）：

```agda
allLe-trans : ∀ {a b : ℕ} {xs : List ℕ} →
              a ≤ b → AllLe b xs → AllLe a xs
allLe-trans {xs = []} a≤b le[] = le[]
allLe-trans a≤b (le∷ b≤y rest) =
  le∷ (≤-trans a≤b b≤y) (allLe-trans a≤b rest)
```

读法：对 `AllLe b xs` 的**证据**做递归（第二参数是递归论据，07 章），
每层用 stdlib 的 `≤-trans` 把 b 压住的每个 y 换成 a 也压住；空表分支靠
模式 `{xs = []}` 收窄目标。其二荒谬模式（10/15 章回收）：

```agda
3≰1 : ¬ (3 ≤ 1)
3≰1 (s≤s ())
```

`¬ A` 就是 `A → ⊥`（12 章）；`3 ≤ 1` 的证据剥两层 `s≤s` 后无处安放，
`()` 处没有构造子，一行结案。其三，本章真正的 Agda 特色学费——
`¬≤→≥`，「全序的反面」：

```agda
¬≤→≥ : ∀ {m n : ℕ} → ¬ (m ≤ n) → n ≤ m
¬≤→≥ {zero} {n} h = ⊥-elim (h z≤n)
¬≤→≥ {suc m} {zero} h = z≤n
¬≤→≥ {suc m} {suc n} h = s≤s (¬≤→≥ (λ mn → h (s≤s mn)))
```

coq 里这一步一句 `lia` 或 `Nat.leb_gt` 过桥就完了；Agda 没有算术决策
器，得手写——但难度也就三步模式匹配：zero 行 `0 ≤ n` 恒真有 `z≤n`，
证据喂给假设 h 得 ⊥，`⊥-elim` 消灭一切；`suc m` 对 `zero` 目标白送；
两边后继剥一层 `s≤s` 递逆否 lambda。它在 `sorted-insert` 的 no 分支上
岗：no 里裹的是 `¬ (x ≤ y)`，要用的却是 `y ≤ x`，中间人就是它。

现在上主菜。**保序引理 `allLe-insert`——本章泛化技术的标本**：

```agda
allLe-insert : ∀ {z} (x : ℕ) (ys : List ℕ) →
               z ≤ x → AllLe z ys → AllLe z (insert x ys)
allLe-insert x [] z≤x le[] = le∷ z≤x le[]
allLe-insert {z} x (y ∷ ys) z≤x (le∷ z≤y rest) with x ≤? y
... | yes _ = le∷ z≤x (le∷ z≤y rest)
... | no _ = le∷ z≤y (allLe-insert x ys z≤x rest)
```

陈述读作：z 压得住 x、又压得住整段 ys，则 z 压得住把 x 插进 ys 的结
果。**z 为什么必须独立量化、不能偷换成 z = x？** no 分支递归调用的目标
是 `AllLe z (insert x ys)`，z 是归纳假设里活着的变量；若收成
`AllLe x ys → AllLe x (insert x ys)`（coq 教程同款坑位），坏消息在
**使用处**爆发——`sorted-insert` 的 no 分支需要实例 `AllLe y (insert x
ys)`（z = y ≠ x）。实测探针：弱版本身**可证**、编译一路绿灯，替换进
`sorted-insert` 才炸：

```
examples/Tmp26a.agda:47.20-44: error: [UnequalTerms]
x != y of type ℕ
when checking that the inferred type of an application
  AllLe x (insert x ys)
matches the expected type
  AllLe y (insert x ys)
```

**弱引理不是假命题，是弹药口径不对**——「先泛化再归纳」这条 coq 同款
纪律（13 章 generalize 的镜像），在 Agda 里就是「陈述里谁被 ∀ 罩住」的
字面功夫。顺带注意 yes 分支：`insert x (y ∷ ys)` 在 `| yes` 之下
**定义性地**等于 `x ∷ y ∷ ys`，目标直接展开成两层 `le∷`——「和定义同
步 case-split」是 Agda 证明的第一姿势：函数体替证明做完展开。

有了它，`sorted-insert` 是一次装配：

```agda
sorted-insert : (x : ℕ) → ∀ {ys} → Sorted ys → Sorted (insert x ys)
sorted-insert x {[]} ss = s∷ le[] s[]
sorted-insert x {y ∷ ys} (s∷ a s) with x ≤? y
... | yes x≤y = s∷ (le∷ x≤y (allLe-trans x≤y a)) (s∷ a s)
... | no ¬xy = s∷ (allLe-insert x ys (¬≤→≥ ¬xy) a) (sorted-insert x s)
```

逐分支读（模式 `(s∷ a s)` 拆开 Sorted 证据：`a : AllLe y ys`、
`s : Sorted ys`；对 ys 结构归纳，递归调用 `sorted-insert x s` 就是
IH——13 章「归纳 = 对证据的依赖消除」的标准剧本）：

- 空表：目标 `Sorted (x ∷ [])`，摆 `s∷ le[] s[]`，头部压空表白送。
- yes：目标 `Sorted (x ∷ y ∷ ys)`。头一条 `AllLe x (y ∷ ys)`：x ≤ y
  现场有，x 压 ys 靠 `allLe-trans x≤y a`；尾一条就是原证据 `(s∷ a s)`
  ——insert 没动它们，直接复用。
- no：目标 `Sorted (y ∷ insert x ys)`。头一条 `AllLe y (insert x ys)`
  交给 `allLe-insert`：`¬≤→≥ ¬xy` 供 z ≤ x，`AllLe y ys` 正是 `a`——
  **这一处就是泛化引理唯一对得上口径的地方**。尾一条由 IH 供货。

最后 `sorted-sort` 是对输入表的三行归纳（coq 21.7 坑位 5 同款：归纳
对象永远是数据的结构，不是函数的结果）：

```agda
sorted-sort : ∀ ys → Sorted (sort ys)
sorted-sort [] = s[]
sorted-sort (x ∷ xs) = sorted-insert x (sorted-sort xs)
```

并且有序性不是断言而是**可检查的证明项**——示例给了具体见证
`sorted-351 = sorted-sort (5 ∷ 3 ∷ 1 ∷ []) :
Sorted (sort (5 ∷ 3 ∷ 1 ∷ []))`。

## 26.3 性质二：↭ 重排——stdlib 的 4 构造子归纳版

「是重排」有三个候选定义，本仓库实测后才定案。**候选一：stdlib
Setoid 版**（`Data.List.Relation.Binary.Permutation.Setoid`），先试它：

```agda
import Data.List.Relation.Binary.Permutation.Setoid as S
demo : ∀ {A : Set} {x y : A} → (x ∷ y ∷ []) S.↭ (y ∷ x ∷ [])
demo {x = x} {y = y} = S.swap x y S.refl
```

实测报错教你做人：

```
examples/Tmp26d.agda:7.33-43: error: [UnequalTerms]
List _A_5 !=< Relation.Binary.Bundles.Setoid _a_2 _ℓ_3
when checking that the inferred type of an application
  List _A_5
matches the expected type
  Relation.Binary.Bundles.Setoid _a_2 _ℓ_3
```

`S.swap` 的**第一参数是一整个 Setoid 记录**（元素等式关系及其等价性证
明，18 章的 Structure 全家桶），Agda 把 `x` 往 Setoid 位上套才发现不
对：用它得先递 `PropEq.setoid A` 实例，处处背着「元素按哪个等式算相
等」的随身行李——对只排 ℕ、就认命题等式的本章纯属噪音。**候选二：自
造三构造子归纳**。可以，但自造就要自带对称、传递全套零件，而 stdlib
的 Propositional 版已是同样的构造子同样的名字，白捡。**候选三（定案）：
`Data.List.Relation.Binary.Permutation.Propositional` 的 `_↭_`**，四个
构造子就是全部语法：

```
P.refl  : xs ↭ xs
P.prep  : ∀ x → xs ↭ ys → x ∷ xs ↭ x ∷ ys
P.swap  : ∀ x y → xs ↭ ys → x ∷ y ∷ xs ↭ y ∷ x ∷ ys
P.trans : xs ↭ ys → ys ↭ zs → xs ↭ zs
```

和 coq 零件一一对位：`P.prep` = `perm_skip`、`P.swap` = `perm_swap`、`P.trans` = `Permutation_trans`。上手感受一下：

```agda
_ : (3 ∷ 1 ∷ 2 ∷ []) ↭ (1 ∷ 3 ∷ 2 ∷ [])
_ = P.swap 3 1 P.refl
```

对称性 stdlib 现成：`↭-sym : xs ↭ ys → ys ↭ xs`（示例的
`↭-sym-demo = P.↭-sym` 是转手）。import 实测坑：构造子叫 `refl/trans`，
但**对称那条不叫 `sym`**——`using (refl; sym; trans)` 收警告
`ModuleDoesntExport ... sym`。注意示例的 import 姿势：

```agda
open import Data.List.Relation.Binary.Permutation.Propositional
  using (_↭_)
import Data.List.Relation.Binary.Permutation.Propositional as P
```

类型 `↭` 不具名导入、构造子一律限定 `P.xxx`。为什么不 open 进来和
PropEq 的 `refl/trans` 混用？实测同时 open 并不报 ClashingDefinition
（Agda 按目标类型对同名候选消歧）——能编译，但消歧失败时报错列两个同
名候选极难读；限定前缀是花小钱买可读性。

插入即重排，与 26.2 同一个 with、同一套同步分案：

```agda
insert-↭ : (x : ℕ) (ys : List ℕ) → (x ∷ ys) ↭ insert x ys
insert-↭ x [] = P.refl
insert-↭ x (y ∷ ys) with x ≤? y
... | yes _ = P.refl
... | no _ = P.trans (P.swap {xs = ys} {ys = ys} x y P.refl)
                (P.prep y (insert-↭ x ys))
```

yes 分支两端同为 `x ∷ y ∷ ys`，定义相等。no 分支目标
`x ∷ y ∷ ys ↭ y ∷ insert x ys`，中转站 `y ∷ x ∷ ys`：左半 `P.swap` 把
x、y 换个身（实测隐式参数 `{xs = ys} {ys = ys}` **不写也能过**，写出
来纯粹让「中转站是谁」肉眼可见，相当于 coq 的
`apply Permutation_trans with (y :: x :: ys)`）；右半 `P.prep y (IH)`
头不动尾用 IH。tactic 版现场指定中转站，Agda 把它**写进证明项**。排序版：

```agda
sort-↭ : ∀ xs → sort xs ↭ xs
sort-↭ [] = P.refl
sort-↭ (x ∷ xs) =
  P.trans (P.↭-sym (insert-↭ x (sort xs))) (P.prep x (sort-↭ xs))
```

链条读法（示例注释原样成立）：`insert x (sort xs) ↭[sym] x ∷ sort xs
↭[prep x ∘ IH] x ∷ xs`。方向要害：`insert-↭` 说的是「`x ∷ ys ↭ insert
x ys`」，而 `sort xs` 在 ↭ 的**左边**，必须先 `↭-sym` 拧一下。忘了拧？
实测探针摘掉 sym 直接串：

```
examples/Tmp26e.agda:32.12-32: error: [UnequalTerms]
x ∷ sort xs != insert x (sort xs) of type List ℕ
when checking that the expression insert-↭ x (sort xs) has type
sort (x ∷ xs) ↭ _ys_32
```

`P.trans` 要左右链接点字面统一，一边 `insert x (sort xs)`、一边
`x ∷ sort xs`，定义上不等（`insert` 里还有没判的 `≤?`）——报错直译就
是「你少了个 sym」。Agda 把方向纪律压进类型链接点的字面统一，构造项
当场结账；coq 里同款错误表现为子目标方向对调。

## 26.4 主定理：正确 = 有序 × 重排

```agda
sort-correct : (xs : List ℕ) → Sorted (sort xs) × (sort xs ↭ xs)
sort-correct xs = sorted-sort xs , sort-↭ xs
```

就这一行——`×` 配对即构造积，12 章「合取 = 配对」的 Curry–Howard 兑现
（`proj₁`/`proj₂` 拆包）。陈述即目录：分量各自独立，先拆性质再合取；拆包还能只取一瓢：

```agda
perm-531 : sort (5 ∷ 3 ∷ 1 ∷ []) ↭ (5 ∷ 3 ∷ 1 ∷ [])
perm-531 = proj₂ (sort-correct (5 ∷ 3 ∷ 1 ∷ []))
```

对比 coq 21.6：那边 `split` 两拍再 `apply` 两个引理，这边就是逗号一对；
戏份相同，只是 Agda 的「证明」从一开始就是那个叫 `sort-correct` 的
**函数**。

## 26.5 赠品一：保长（≡-Reasoning 计算链）

排序不许变长度，是「重排」的弱化推论——但顺手就能证。`insert` 保 +1：

```agda
length-insert : (x : ℕ) (ys : List ℕ) → length (insert x ys) ≡ suc (length ys)
length-insert x [] = refl
length-insert x (y ∷ ys) with x ≤? y
... | yes _ = refl
... | no _ = cong suc (length-insert x ys)
```

老配方：with 与定义同步，yes 分支两端定义相等，no 分支把 IH 用
`cong suc` 抬进一层 `y ∷ _`。合成版用 14 章的 `≡-Reasoning` 把每一跳写明：

```agda
length-sort : (xs : List ℕ) → length (sort xs) ≡ length xs
length-sort [] = refl
length-sort (x ∷ xs) = begin
  length (sort (x ∷ xs))
 ≡⟨⟩
  length (insert x (sort xs))
 ≡⟨ length-insert x (sort xs) ⟩
  suc (length (sort xs))
 ≡⟨ cong suc (length-sort xs) ⟩
  suc (length xs)
 ∎
```

对照 coq 的 `rewrite ... ; reflexivity` 风格（证据全塞进「看不见的当
前目标」）：calc 链是同一个证明**摊开平铺**——每一跳的等式项就是
tactic 版 `rewrite` 身后自动插入的那个 `cong`/替换。选型沿用 14 章结
论：跳数 ≥ 2 或想留路标用 calc，单跳或 `refl` 级直接等式（`length-insert` 的 no 分支即是）。

## 26.6 赠品二：Vec 索引版——签名即定理（16 章回收）

把「保长」从**定理**降级成**类型**：

```agda
sortV : ∀ {n} → Vec ℕ n → Vec ℕ n
sortV {n = n} v =
  cast (trans (length-sort (toList v)) (length-toList v))
       (fromList (sort (toList v)))
```

签名 `Vec ℕ n → Vec ℕ n` **本身**就是「排序不增不删」：返回的元素个数
被索引 n 钉死，想偷一个元素，n 凑不出来。三件套分工：`toList` 卸成裸
List（长度进影子），List 侧跑 26.1 的算法，`fromList` 按 `length` 编回
索引——但它给的是 `Vec ℕ (length (sort (toList v)))`，目标是
`Vec ℕ n`，差的等式由 `cast` 兑现：`length-sort (toList v)` 接
`length-toList v`（16.7 往返定律里的 `len-forget`，三行归纳
`[] ↦ refl`、`x ∷ xs ↦ cong suc (IH)`），`trans` 串成完整等式。少串半
截？实测探针只递 `length-toList v`：

```
examples/Tmp26c.agda:38.47-73: error: [UnequalTerms]
sort (toList v) != toList v of type List ℕ
when checking that the expression fromList (sort (toList v)) has
type Vec ℕ (length (toList v))
```

Agda 只能试图在 List 层面 unify `sort (toList v) ≟ toList v` 来凑索引
——sort 里有没判的 `≤?`，永远凑不上。等式账一笔都不能欠，这就是依赖
类型「免费」的真实价签。coq 21 章的主定理只有 sorted × Permutation 两
条腿，保长若要得再立定理再推——**全是事后合同**；Agda 的「免费午餐」
分两档：`length-sort` 是「半价」——定理还得证，只是顺手几行；`sortV`
才是签名免证——代价是 `cast`/`length-toList` 的索引算术税，且**有序、
重排两条性质 Vec 索引完全不沾**。索引能钉住的只有「可判定的形状性
质」——25 章结语在本章的复现。

## 26.7 本章小结

本章工程量：两条归纳谓词、五枚引理（`allLe-trans`、`¬≤→≥`、
`allLe-insert`、`sorted-insert`、`insert-↭`）、一枚主定理、两件赠品，
212 行一次类型检查通过。方法论没有新零件——每处「新」都是旧章回收：
`with` 同步分案（13）、× 即合取（12）、≡-Reasoning（14）、Vec cast
（16）、荒谬模式（06/10/15）。Agda 特有的学费只有两笔：谓词构造子的
模式匹配纪律（证据拆包即归纳假设，比 coq 的 `destruct H` 更字面），以及 no 分支手喂 `¬≤→≥`。复杂算法（归并、快排）证明结构完全相同，引理更厚而已——**方法论无差异，工作量有差异**。下一章 27 转向手册化收尾：stdlib 的模块组织与命名地图。

## 26.8 坑位清单（本章实测）

1. **引理不泛化，报错在使用处才爆**：弱版 `allLe-insert`（z 固定为 x）
   自身可证、编译全绿，直到 `sorted-insert` no 分支要 `AllLe y (insert
   x ys)` 实例才炸 `UnequalTerms: x != y`——弱引理不是错的，是口径不对。
2. **↭ 的对称不叫 `sym`**：`using (_↭_; refl; sym; trans)` 实测警告
   `ModuleDoesntExport ... sym`——该版导出 `refl/trans/prep/swap` 加连
   字符命名的 `↭-sym`，拿不准先 grep 模块 export 表。
3. **Setoid 版 Permutation 行李重**：`S.swap x y S.refl` 实测
   `List _A !=< Relation.Binary.Bundles.Setoid _a_2 _ℓ_3`——swap 第一参
   数要整个 Setoid 记录；只认命题等式就用 Propositional 版，否则显式
   递 `PropEq.setoid A`。
4. **忘套 `↭-sym`，trans 链接点对不齐**：实测
   `x ∷ sort xs != insert x (sort xs)` 并附目标 `sort (x ∷ xs) ↭ _ys_32`
   ——`_ys_32` 是未解元变量；读这类错盯「!= 两边的字面差」，此处差 sym。
5. **cast 的等式账必须结全**：只递 `length-toList v` 不先接
   `length-sort`，实测 `sort (toList v) != toList v`——Agda 会拿未归约
   的 `sort` 表达式去 unify 索引，永远凑不上。
6. **同名构造子靠类型消歧，可读性自己买单**：PropEq 与 Permutation 的
   `refl/trans` 同时 open 实测**不报** ClashingDefinition（按目标类型
   挑选），但消歧失败时报错列多个同名候选；示例选构造子一律 `P.` 前缀。
7. **`¬≤→≥` 没有自动版**：coq 一句 `Nat.leb_gt`/`lia`，Agda 手写三行
   模式匹配（zero 行 `⊥-elim (h z≤n)` 是固定招式）；`¬ ∘ ≤` 与 `≤` 反
   向之间没有 definition equality。

---
上一章：[25 · 实战：类型良好表达式解释器](25-typedast.md) ｜ 下一章：[27 · 标准库阅读指南](27-stdlib-guide.md) ｜ 返回：[README](../README.md)
