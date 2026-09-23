# 07 · 递归与终止检查

上一章讲了模式匹配为什么「必须穷尽」；这一章回答它的孪生问题：递归为什么
「必须变小」。Haskell 里 `f x = f x` 是合法定义（运行时才爆炸），Agda 里它
**连类型检查都过不了**——每个递归定义都要通过**终止检查**。这不是 lint，
而是逻辑地基：程序即证明，不终止的证明能造出 `⊥`（7.7 实测）。本章摸清
这台检查器的脾气：它在盯什么语法形状、报错怎么读、够不着时的正规出路
（`with` 递归论据、`Acc`/`_<_` 良基递归、fuel）与逃生门的价签——一切以
Agda 2.8.0 实测为准，包括那些**并不存在**的老记法。

对应示例：`../examples/Ex07_recursion.agda`

本章所有报错原文均为本机实测粘贴。

## 7.1 结构递归：终止性的地基

Agda 接受的最小递归模式一句话能说清：**递归调用必须发生在「左侧模式里
从构造子拆出来的变量」上**。看 stdlib 版加法的骨架：

```agda
_∸′_ : ℕ → ℕ → ℕ
m     ∸′ zero    = m
zero  ∸′ suc n   = zero
suc m ∸′ suc n   = m ∸′ n
```

第三条等式的调用 `m ∸′ n` 里，两个参数 `m`、`n` 都是从模式
`suc m`、`suc n` 拆出来的变量——各自比原来小一层。检查器**不看函数体、
不算任何值**，纯靠语法形状就批了这张「终止支票」。为什么这么保守？
因为「任意程序是否终止」是不可判定的（停机问题），检查器只能给出一个
**可靠但不完备**的近似：它接受的都终止，但它拒绝的不一定真不终止。
理解这一点，后面所有「Agda 为什么这么笨」的怨气就有了出处。

「变小」可以同时沿多个参数（上例沿字典序剥两层）；一步剥两层再递归也合法：

```agda
half : ℕ → ℕ
half zero = zero
half (suc zero) = zero
half (suc (suc n)) = suc (half n)
```

调用参数 `n` 仍是模式变量，合法。验证它是向下取整除二：

```agda
_ : half 7 ≡ 3
_ = refl
```

## 7.2 with 与「递归论据」：老记法、新记法、以及不存在的记法

结构递归只管「调用参数变小」。但很多时候我们要**拿着递归结果继续分派**——
这就是 `with`（06 章）与递归的组合拳，Agda 里叫它 recursor 模式：

```agda
double-with : ℕ → ℕ
double-with zero = zero
double-with (suc n) with double-with n
... | m = suc (suc m)
```

这里 `with double-with n` 把递归调用做成一个**中间观察对象**，子句再对
结果 `m` 分派；检查器把 with 头部的递归调用视为登记在册的正规递归论据
（recursive argument），嵌在 with 里也认。

关于老式记法，先把实测结论钉死：

- **`...` 续行点**：2.8.0 实测**照常接受、零告警**，stdlib 2.3 里也还大量
  在用（仅 `Data/Nat/Properties.agda` 就 25 处）。新代码惯例是重复左侧模式：

  ```agda
  double-modern : ℕ → ℕ
  double-modern zero = zero
  double-modern (suc n) with double-modern n
  double-modern (suc n) | m = suc (suc m)
  ```

- **`measured by` / `| x measured by f` 一类记法**：**从未是 Agda 语法**。
  实测写 `with f n measured by n`，报的是把它当普通函数应用的作用域错误：

  ```text
  examples/Tmp07t.agda:7.20-28: error: [NotInScope]
  Not in scope:
    measured
    (at examples/Tmp07t.agda:7.20-28)
  when scope checking measured
  ```

  老教程里的「度量递归」写法在 2.8 下要翻译成 7.5 节的 `Acc`/`_<_` 套路。

## 7.3 终止检查报错解剖课

先看最高频的一条。`f (suc n) = f (f n)`（McCarthy 风格嵌套调用）实测被拒：

```text
examples/Tmp07d.agda:5.1-7.20: error: [TerminationIssue]
Termination checking failed for the following functions:
  f
Problematic calls:
  f (f n)
    (at examples/Tmp07d.agda:7.13-14)
  f n
    (at examples/Tmp07d.agda:7.16-17)
```

逐块读：**错误码 `[TerminationIssue]`** 的作用范围是整段声明区域
（`5.1-7.20` 覆盖签名加两条等式，不止出错行）；**failed 名单**可以连坐
整个 mutual 块，别被数量吓到；**Problematic calls** 列出肇事调用表达式
+ 位置——注意 `f (f n)` 与 `f n` 都在：判词的核心是 **`f n` 是函数
应用，不是模式变量**，检查器从不做「f 输出总比输入小」的演绎。

再看互递归的经典连坐现场（两条边都不缩小的 p/q 乒乓）：

```text
examples/Tmp07e.agda:5.1-12.24: error: [TerminationIssue]
Termination checking failed for the following functions:
  p, q
Problematic calls:
  q (suc n)
    (at examples/Tmp07e.agda:8.15-16)
  p (suc n)
    (at examples/Tmp07e.agda:12.15-16)
```

`q (suc n)` 把 `suc n` **原样**递给伙伴——参数没变小，环上没有任何一处
缩小，拒绝合理。最阴险的第三种是「被函数当参数传走」：对多叉树
`data Tree : Set where node : List Tree → Tree` 用 `map` 偷懒（示例文件里以注释存在，实测失败）：`size-bad (node ts) = suc (sum (map
size-bad ts))`。

```text
examples/Tmp07m.agda:12.1-14.43: error: [TerminationIssue]
Termination checking failed for the following functions:
  size
Problematic calls:
  size
    (at examples/Tmp07m.agda:14.34-38)
```

报错只列了光秃秃的 `size`（连参数都没有）——因为它此刻不是「调用」，而是
**作为参数交给 map** 的值。检查器无法穿透 map 的函数体确认「map 只在表的
骨架上递归、传进去的 size 只吃到子表元素」，只好一票否决。解法见 7.4。

还有一面镜子值得照：**什么能骗过检查器**。`--termination-depth=N` 在
`--help` 里的自述是 "allow termination checker to count decrease/increase
upto N"——它是放宽**增减计数**的，不是嵌套调用的通行证。实测
`f (suc n) = f (f n)` 加了 `{-# OPTIONS --termination-depth=2 #-}` 后
**依然**原样报错（退出码 42，报错一字未变）。所以别把它当逃生门。

## 7.4 互递归与大小关系：mutual 块怎么过检

两个观察合起来就是互递归的通过规则：**把 mutual 块看成调用图，每条边标注
「缩小/持平/未知」，每个环上至少有一条严格缩小的边即可**（且不能有「未知」
边）。`even/odd` 各剥一层，环上处处缩小，顺利通过——这就是示例里的版本：

```agda
mutual
  even : ℕ → Bool
  even zero = true
  even (suc n) = odd n

  odd : ℕ → Bool
  odd zero = false
  odd (suc n) = even n

_ : even 10 ≡ true
_ = refl
```

注意 `mutual` 块要把**签名和定义捆在一起**写（03 章说过声明自上而下解析）。

回看 7.3 的树大小。`map` 版被拒后，标准手术是把「遍历子表」显式拆出来，
造一对互递归伙伴：

```agda
mutual
  size : Tree → ℕ
  size (node ts) = suc (sizeList ts)

  sizeList : List Tree → ℕ
  sizeList [] = zero
  sizeList (t ∷ ts) = size t + sizeList ts
```

现在调用图是：`size → sizeList`（对表剥一层，缩小）；`sizeList → size`
（`t` 是模式 `t ∷ ts` 拆出的变量，缩小）。环上处处有据可查，过检。验证
（`t2 = node (t1 ∷ t1 ∷ [])`，`t1 = node []`）：

```agda
_ : size t2 ≡ 3
_ = refl
```

这个「把隐式的结构调用提出来当互递归伙伴」的手法，是适应检查器形状思维的
第一课——后面 22 章（余归纳）、26 章（排序）还会反复用到。

## 7.5 度量与 `_<_` 关系：良基递归的正规姿势

结构递归按**语法子项**算「小」，很多自然算法却按**值**变小：log₂ 每步对
`⌊n/2⌋` 递归，而 `⌊n/2⌋` 不是 n 的语法子项，检查器看不见（`half` 恰好
顺着剥皮剥出了子项才蒙混过关）。正规出路：**把「变小」升级成类型**——
stdlib 在 `Induction.WellFounded` 里给了可达性谓词：

```agda
-- 示意（真实定义见 Induction/WellFounded.agda）
data Acc {A : Set} (_<_ : Rel A ℓ) (x : A) : Set ... where
  acc : (rs : ∀ {y} → y < x → Acc _<_ y) → Acc _<_ x
```

读法：`Acc _<_ x` 是「x 之上的下降链都有限」的**证据**；构造子 `acc rs`
携带一台「从 y<x 造 y 的证据」的机器。关键洞察：对 `Acc` 证明本身做
**结构递归**是合法的——证明对象是归纳定义的！于是（import 见示例文件）：

```agda
⌊log2⌋-acc : (n : ℕ) → Acc _<_ n → ℕ
⌊log2⌋-acc zero _ = zero
⌊log2⌋-acc (suc zero) _ = zero
⌊log2⌋-acc (suc n′@(suc n)) (acc rs) =
  suc (⌊log2⌋-acc (suc ⌊ n /2⌋) (rs (⌊n/2⌋<n n′)))
```

缩小发生在值上（`⌊n/2⌋<n` 证明 `suc ⌊ n /2⌋ < suc n′`），递归的**语法**
发生在 Acc 证据肚子里。`Data.Nat.Induction` 备好 `<-wellFounded`：

```agda
⌊log2⌋′ : ℕ → ℕ
⌊log2⌋′ n = ⌊log2⌋-acc n (<-wellFounded n)

_ : ⌊log2⌋′ 8 ≡ 3
_ = refl
```

方式二是直接用打包好的不动点组合子 `<-rec`（它内部就是「对 Acc 结构递归」）：

```agda
⌊log2⌋″ : ℕ → ℕ
⌊log2⌋″ = <-rec (λ _ → ℕ) step
  where
    step : (n : ℕ) → ({ m : ℕ } → m < n → ℕ) → ℕ
    step zero _ = zero
    step (suc zero) _ = zero
    step (suc n′@(suc n)) rec = suc (rec {m = suc ⌊ n /2⌋} (⌊n/2⌋<n n′))
```

两个实测拦路虎先替大家踩过：`<-rec` 的**第一个显式参数是逐点类型谓词**
`P : ℕ → Set`（漏了它会报 `((m : ℕ) → m < n → ℕ) → ℕ !=< Set ...`）；
step 里的递归假设是**隐式** `{m}`（`WfRec` 用的 `∀ {y}`），写成显式
`(m : ℕ) → ...` 会撞 `UnequalHiding`。两版在 16 处汇合，可焊成一条等式：

```agda
_ : ⌊log2⌋′ 16 ≡ ⌊log2⌋″ 16
_ = refl
```

代价也要说清：函数多吃一个 Acc 参数，不同来源的证明**值上**可能不同，
想要无关性得另证（stdlib 的 `Data.Nat.Logarithm.Core` 配了
`⌊log2⌋-acc-irrelevant`）。日常工程用方式二即可。

## 7.6 fuel：深度受限的 eval 返回 Maybe

结构递归太窄、Acc 太贵时，还有一条务实路线——**燃料（fuel）**：给每个
递归函数多塞一个自然数参数，每剥一层烧一格，烧完返回「算不出来」。
第 25 章的表达式解释器就用这招处理「深度不可控的求值 + 除零」双重部分性，
本章先立最小骨架：

```agda
open import Data.Maybe.Base using (Maybe; just; nothing; _>>=_)

data Expr : Set where
  val : ℕ → Expr
  _⟨+⟩_ : Expr → Expr → Expr
  _⟨÷⟩_ : Expr → Expr → Expr

divMaybe : ℕ → ℕ → Maybe ℕ
divMaybe x (suc d) = just (x / suc d)
divMaybe x zero = nothing

eval : ℕ → Expr → Maybe ℕ
eval zero _ = nothing
eval (suc fuel) (val n) = just n
eval (suc fuel) (a ⟨+⟩ b) =
  eval fuel a >>= λ x → eval fuel b >>= λ y → just (x + y)
eval (suc fuel) (a ⟨÷⟩ b) =
  eval fuel a >>= λ x → eval fuel b >>= λ y → divMaybe x y
```

`eval` 沿 fuel 结构递归，终止检查无懈可击；「燃料耗尽」与「除以零」都
诚实落地为 `nothing`。三条实测等式：

```agda
_ : eval 5 (val 3 ⟨+⟩ val 4) ≡ just 7
_ = refl

_ : eval 1 ((val 1 ⟨+⟩ val 2) ⟨+⟩ val 3) ≡ nothing   -- 燃料不够深
_ = refl

_ : eval 9 (val 8 ⟨÷⟩ val 0) ≡ nothing               -- 部分性与燃料无关
_ = refl
```

fuel 的心智模型是「**有界近似**」：`just v` 是「深度 ≤ fuel 内求值得 v」
的可靠证据；但 `nothing` **不携带信息**——可能是真错，也可能只是燃料不够。
Coq 教程同样用 fuel 入门、`Function` 进阶；差异在 Agda 把 Maybe 焊进了
返回类型，错误路径**类型可见**。

## 7.7 逃生门与价签：postulate、pragma、OPTIONS

最后一章保险柜。实测在 2.8 上可用的旁路（以及一个**已死**的名字）：

1. **`{-# NON_TERMINATING #-}`**：贴单个函数，免检放行（实测编译通过）。
2. **`{-# TERMINATING #-}`**：反向保险，声明「它其实终止」，日常少用。
3. **`{-# OPTIONS --no-termination-check #-}`**：整文件关掉终止检查。
4. **`--partial-definitions`**：**旧版旗号，2.8 已无此项**。实测：

   ```text
   examples/Tmp07g.agda:1.1-38: error: [OptionError]
   Unrecognized option: --partial-definitions
   ```

   2.8 `--help` 里活着的相关开关是另外两个语义：`--allow-unsolved-metas`
   （孔洞没填完也算过关）和 `--allow-incomplete-matches`（模式不穷尽也
   放行），各管各的检查。
5. **postulate**（03 章讲过）：向虚空要一个函数，终止检查无从检查。

价签实测：贴了 `NON_TERMINATING` 的 `bad = bad` 能「证明」空类型，本机
实测整个文件**退出码 0** 一路绿灯——

```agda
{-# NON_TERMINATING #-}
bad : ∀ {A : Set} → A
bad = bad

oops : ⊥
oops = bad
```

这正是「终止性=一致性」的活体证明。解药是 `--safe`，实测逐一封杀旁路：

```text
error: [SafeFlagPostulate]
Cannot postulate magic with safe flag
...
error: [SafeFlagNonTerminating]
Cannot use NON_TERMINATING pragma with safe flag.
```

（`TERMINATING` 同款 `SafeFlagTerminating`。）另一实测细节：allow 系开关
放**命令行**会顺依赖图传染，连 stdlib 的 `--safe` 模块都拒绝被这样检查
（`The --safe mode does not allow OPTIONS pragma --allow-incomplete-matches`），
所以它们只能写成文件级 `{-# OPTIONS ... #-}`。

选择顺序建议：改结构（7.4）→ fuel → Acc/`_<_` → pragma（只配 `--safe`
体检的草稿用，提交前拆除）。

## 7.8 与 Coq 的 Fixpoint/Guard 对比：谁更严，为什么

会 Coq 的读者心里多半在比：Coq 的 `Fixpoint` 不也是结构递归吗？差异有三：

1. **语法层**。Coq 的 `Fixpoint f (n : nat) : T := match n with ...` 自带
   递归参数标注位（可用 `struct m` 显式指定在哪个参数上递归）；Agda 没有
   专门标注语法，递归论据**从签名+模式的形状反推**，`with` 头部调用是唯一
   的「显式登记」处。
2. **良基递归的支持方式**。Coq 的 `Function` 命令把良基递归做成**内置
   工作流**（终结性证明义务、`Functional Induction` 一条龙）；Agda 把同样
   材料做成**普通类型**（`Acc`/`<-rec`），没有「证明义务」这一说——所以
   「Coq 接受更多」的直觉来源是 `Function`/`Program Fixpoint` 这套外加工，
   而不是内核更宽。
3. **为什么 Agda 宁可严**。Agda 的类型检查**本身就靠归约**——检查器要
   不断求值项来比对类型，一个不终止的函数会直接把「判断两个类型是否相等」
   这台机器挂死，破坏的是编译本身；严格终止检查 + 显眼逃生门 + `--safe`
   封杀，是「归约驱动一切」架构的自洽选择。顺带一提：Coq 的 mutual
   Fixpoint 要求所有环在同一参数上缩小，Agda 的调用图判据（7.4）反而更
   宽松——两家的「严」方向并不相同。

## 7.9 本章坑位清单（实测）

1. **`measured by` 不是语法**：老教程里的度量递归记法在 2.8 报
   `NotInScope: measured`；正解是 `Data.Nat.Induction` 的
   `<-wellFounded`/`<-rec` 或对 `Acc` 结构递归；
2. **`...` 续行仍可用但属旧风**：2.8.0 实测无告警，stdlib 也还在用；
   新代码请写「重复完整左侧模式」的现代 with 子句；
3. **终止报错连坐整个 mutual 块**："failed for the following functions"
   列一串名字，真正肇事的往往只有一两条 Problematic call——从调用位置往回
   找「哪个参数没缩小」，别按名单逐个怀疑；
4. **`--termination-depth=2` 救不了 `f (f n)`**：实测报错一字不变；
   它放宽的是增减计数，不是嵌套调用；
5. **`--partial-definitions` 在 2.8 已不存在**：`OptionError:
   Unrecognized option`；对应需求拆成
   `--allow-unsolved-metas`/`--allow-incomplete-matches`，且**命令行传入会
   传染 stdlib 的 `--safe` 检查**，要用文件级 OPTIONS；
6. **`<-rec` 双坑**：漏掉第一显式参数 `P` → `!=< Set`；把递归假设写成
   显式 `(m : ℕ) →` → `UnequalHiding`（真实类型是 `∀ {m} → m < n → P m`）；
7. **`NON_TERMINATING` 能「证明」`⊥` 且一路绿灯**：逃生门不带保险，
   正经文件请开 `{-# OPTIONS --safe #-}` 做体检（实测报
   `SafeFlagNonTerminating`）。

---
上一章：[06 · 数据类型与模式匹配](06-patterns.md) ｜ 下一章：[08 · 列表专题](08-lists.md) ｜ 返回：[README](../README.md)
