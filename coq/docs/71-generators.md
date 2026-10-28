# 71 · 随机生成器：G 单子与按尺寸生成
对应示例：`../examples/71_generators.v`（`Module Ex71Generators`，rocq 9.1 + QuickChick 2.2.0 实测编译退出码 0）

第 69 章我们用库自带的生成器跑通了第一条 `QuickChick` 性质，第 70 章把
`Show` / `Arbitrary` 钉进了类型类系统。但那些「自带」的随机生成器到底是怎么
写出来的？本章打开这个黑箱：QuickChick 的生成器类型 `G A` 是一枚**单子**
（Monad），围绕它有四组组合子——单子接口（`returnGen` / `bindGen` 与 do 记号）、
区间选择（`choose`）、列表生成（`listOf` / `vectorOf`）、概率选择
（`elems` / `oneOf` / `freq`）与失败重试（`backtrack`）；递归类型则靠
**尺寸参数**（`sized` / `resize`）作燃料。最后这些手艺收拢进 `GenSized` /
`Gen` 类型类，就是 69 章里 `arbitrary` 自动生成器的真身。

示例文件头部与导入（各章统一格式）：

```coq
(* 71 随机生成器：G 单子与按尺寸生成 —— G 类型直觉、returnGen/bindGen 与单子记号、choose、
   listOf/vectorOf、elems/oneOf/freq、backtrack、sized/resize、GenSized/Gen 类型类 *)

Set Warnings "-extraction-opaque-accessed,-extraction".
Set Warnings "-notation-overridden,-parsing".

From QuickChick Require Import QuickChick. Import QcDefaultNotation.
From Stdlib Require Import List ZArith String. Import ListNotations.
From ExtLib.Structures Require Import Monads. Import MonadNotation.
Open Scope qc_scope. Open Scope monad_scope.

Module Ex71Generators.

Local Open Scope string.
```

导入要点：`QuickChick` 总库经 `Producer.v` 传递导出 ExtLib 的 `Monad` 类与
`ret` / `bind` / `liftM` 系列组合子；但 do 记号「`x <- c ;; ...`」住在
`MonadNotation` 模块里，需要显式 `Import`（这是原书 QC.v 的实际做法）。
`QcDefaultNotation` 提供 71.6 节要用的 `elems [...]` 等无默认值记号；
`qc_scope` 与 `monad_scope` 同时打开并不冲突。

## 71.1 G 类型：尺寸参数与随机种子

QuickChick 库中真实的 `G` 定义在 `src/Generators.v`：
`Record GenType (A:Type) := MkGen { unGen : nat -> RandomSeed -> A }`。
为讲清直觉，我们把它写成等价的归纳类型——这正是原书 QC.v 的教学写法：

```coq
(* ---------- 71.1 G 类型：尺寸参数与随机种子 ---------- *)

Module DefineG.

Inductive G (A:Type) : Type :=
| MkG : (nat -> RandomSeed -> A) -> G A.
Arguments MkG {A}.

End DefineG.

(* 真实的 G A 就是库里的 GenType A：一个 nat -> RandomSeed -> A 的函数。
   nat 是「当前尺寸上限」，RandomSeed 是伪随机序列的起点；
   Sample 用 0 到 10 递增的尺寸配上新种子各跑一遍。 *)
```

逐行读 `MkG` 包装的那个函数类型 `nat -> RandomSeed -> A`：

- **`nat`：尺寸参数（size）**。它是「本次生成允许的最大规模」的约定上限——
  对列表生成器约束长度，对树生成器约束高度，库自带的 `nat` 生成器则把它当作
  取值上界。注意是**约定**而非强制：每个生成器各自决定如何解读它，
  `sized` / `resize` 只是读写这个参数。
- **`RandomSeed`：伪随机种子**。QuickChick 的种子可以**分裂**（split）：
  一次随机选择后，种子能劈成两个互不相干的新种子。这正是 `bindGen` 能把两段
  生成独立拼接的关键。
- 返回 `A`：喂入尺寸与种子后**确定性地**吐出一个值。所以同一库版本下
  `Sample` 的输出是可复现的，`Sample` 实际就是用 0 到 10 共 11 个尺寸各采一次。

`Module DefineG ... End DefineG` 只是教学模型；接下来用的 `returnGen`、
`bindGen` 等都是库里针对真实抽象 `G` 的操作。`Arguments MkG {A}` 把类型参数
设为隐式，是 Coq 构造子的常规配套。

## 71.2 Monad 接口：returnGen 与 bindGen

第 70 章讲过类型类如何打包接口；`G` 正是 ExtLib `Monad` 类的一枚实例
（`Monad` 协议 = `ret` + `bind`）：

```coq
(* ---------- 71.2 Monad 接口：returnGen 与 bindGen ---------- *)

Check returnGen.
(* ===> returnGen : ?A -> G ?A *)

Sample (returnGen 42).
(* 形如 [42, 42, 42, 42, 42, 42, 42, 42, 42, 42, 42] —— 常生成器无视尺寸与种子 *)

Check bindGen.
(* ===> bindGen : G ?A -> (?A -> G ?B) -> G ?B
   实现要点：先用 randomSplit 把种子劈成两个，两段生成各拿一个。 *)

Section GMonadDef.

Instance GMonad : `{Monad G} | 3 :=
  {
    ret := @returnGen;
    bind := @bindGen
  }.

End GMonadDef.
```

- `returnGen : ?A -> G ?A` 造**恒定生成器**：无视尺寸与种子，永远吐同一个值。
  `Sample (returnGen 42)` 因此输出 11 个 `42`。
- `bindGen : G ?A -> (?A -> G ?B) -> G ?B` 顺序组合两段生成：先跑 `g1` 得到
  `a`，再把它喂给函数 `g2` 得到下一段生成器。实现上先用 `randomSplit` 把种子
  劈成两半——若顺序传递同一个种子，两段的随机选择会完全相关（生成 `(x, y)`
  时 `x` 恒等于 `y` 之类）；劈开后统计上独立。
- 实例声明 `` `{Monad G} `` 是 70 章见过的隐式通用性语法；`| 3` 是类型类搜索
  的代价提示。整个实例包在 `Section GMonadDef` 里、随 `End` 失效——因为库内部
  早已有等价实例 `MonadGen`，这里只是原书为教学重新声明一遍，避免全局重名冲突。
- `Check` 后注释里的 `===>` 是本书体例：表示该命令的预期输出。

## 71.3 choose：从区间中随机选择

```coq
(* ---------- 71.3 choose：从区间中随机选择 ---------- *)

Check @choose.
(* ===> @choose : forall A : Type, ChoosableFromInterval A -> A * A -> G A
   （省去了 Producer 与序关系 le 两个隐式参数；nat 用 ChooseNat、Z 用 ChooseZ 实例） *)

Definition genNat10 : G nat := choose (0,10).

Definition genZ5 : G Z := choose (-5, 5)%Z.

(* 练习 cfi（1 星）：打印 ChoosableFromInterval 并读懂它 *)

Print ChoosableFromInterval.
(* 2.2 中该类对类型 A 与序 le 有四个字段：
     randomR        : A * A -> RandomSeed -> A * RandomSeed   区间随机函数
     randomRCorrect : 区间内每个元素都能被 randomR 取到（完备性证明义务）
     enumR          : A * A -> LazyList A                     枚举版（供列举器复用）
     enumRCorrect   : enumR 恰好列出区间内全部元素 *)
```

- `choose (l, r)` 在**闭区间** `[l, r]` 中近似均匀地取值。它是 `Producer` 类型类
  的方法，具体「区间随机」算法由 `ChoosableFromInterval` 实例给出：库自带
  `ChooseNat`（基于 `Nat.le`）与 `ChooseZ`（基于 `Z.le`）。
- `(0,10)` 按默认的 `nat` 解释；`(-5, 5)%Z` 里的 `%Z` 强制按 `Z` 解析，
  否则负数字面量匹配不上 `nat`。
- **坑**：区间合法性不在类型里。若 `r < l`，QuickChick 在**运行时**报错
  （「bad range」），而不是类型错误——写生成器时务必保证端点有序。

### 练习 cfi（1 星）解答

原书练习要求 `Print ChoosableFromInterval` 并说明字段。QuickChick 2.2 的实际
定义是四字段类（旧版书稿里还有个 `super : Ord A` 字段，2.2 已移除）：
`randomR` 是区间随机函数；`randomRCorrect` 是它的完备性证明义务——区间内每个
元素都要能被取到（验证生成器「覆盖合法值域」时用）；`enumR` / `enumRCorrect`
是同一接口的枚举版，供列举器（enumerator）复用。随机与枚举两个世界共享一个
类，是 QuickChick 接口设计的典型手法。

## 71.4 单子记号：把两段随机性串起来

有了 `Monad` 实例，就能用 do 记号拼装。下面两种写法完全等价：

```coq
(* ---------- 71.4 单子记号：把两段随机性串起来 ---------- *)

Definition genPairNat : G (nat * nat) :=
  bindGen (choose (0, 3)) (fun x =>
  bindGen (choose (0, 3)) (fun y =>
  returnGen (x, y))).

Definition genPairNat' : G (nat * nat) :=
  x <- choose (0, 3);;
  y <- choose (0, 3);;
  ret (x, y).

Sample genPairNat'.
(* 形如 [(1, 2), (0, 0), (3, 1), ...] —— 与 genPairNat 同分布 *)
```

- `genPairNat` 展示 `bindGen` 裸写的嵌套形状：每多一步随机就深一层 lambda。
- `genPairNat'` 是同一个程序：`x <- c1 ;; c2` 是 `bind c1 (fun x => c2)` 的
  语法糖（`MonadNotation`，右结合）；`ret` 经 `Monad` 实例解析到 `returnGen`。
  本章之后的组合生成都用 do 记号。
- 样本里 `(x, y)` 两分量各自随机——种子劈裂保证独立性；两个版本同分布。

## 71.5 列表生成器：listOf 与 vectorOf

```coq
(* ---------- 71.5 列表生成器：listOf 与 vectorOf ---------- *)

Check listOf.
(* ===> listOf : G ?A -> G (list ?A) *)

Check vectorOf.
(* ===> vectorOf : nat -> G ?A -> G (list ?A) *)

Sample (listOf (choose (0,4))).
(* 形如 [[0, 3, 2, 0], [1, 3, 4, 1, 0], [], [4, 2, 3], ...] —— 长度随机、受尺寸约束 *)

Sample (vectorOf 3 (choose (0,4))).
(* 形如 [[0, 1, 4], [1, 1, 0], [3, 3, 3], ...] —— 长度恒为 3 *)
```

- `listOf g` 的内部实现是
  `sized (fun n => bind (choose (0,n)) (fun k => vectorOf k g))`：先按当前尺寸
  `n` 选一个长度 `k`，再生成 `k` 个元素。所以长度上界来自**当前尺寸**——
  尺寸渐增，列表才可能变长，「小反例先出现」。
- `vectorOf k g` 钉死长度 `k`，与尺寸无关，适合「恰好 k 个」的结构
  （定长键、坐标等）。
- 两者都是 `Producer` 类的组合子，对任何 `Producer` 实例通用；本章只用 `G`。

## 71.6 自定义类型：elems / oneOf / freq

先定义被生成的类型——四种颜色，并配 `Show` 实例（第 69 章讲过 `Show` 的
写法，这里逐字取自原书 QC.v）：

```coq
(* ---------- 71.6 自定义类型：elems / oneOf / freq ---------- *)

Inductive color := Red | Green | Blue | Yellow.

#[export] Instance show_color : Show color :=
  {| show c :=
       match c with
         | Red    => "Red"
         | Green  => "Green"
         | Blue   => "Blue"
         | Yellow => "Yellow"
       end
  |}.

Check elems_.
(* ===> elems_ : ?A -> list ?A -> G ?A
   第一个参数是默认值：列表为空时用它兜底，保证函数的完全性。 *)

Definition genColor' : G color :=
  elems_ Red [ Red ; Green ; Blue ; Yellow ].

Sample genColor'.
(* 形如 [Red, Green, Blue, Blue, Red, Yellow, Blue, ...] *)

(* QcDefaultNotation 模块把默认值藏进记号（表头元素兼任默认值）：
     " 'elems' [ x ] "              := elems_ x (cons x nil)
     " 'elems' [ x ; y ; .. ; z ] " := elems_ x (cons x (cons y .. (cons z nil) ..))
   oneOf / freq 记号同理。 *)

Definition genColor : G color :=
  elems [ Red ; Green ; Blue ; Yellow ].

Sample genColor.
```

- `elems_ def l` 从非空列表 `l` 中**等概率**选一个元素。第一个参数 `def` 是
  默认值：只在列表为空（通常是代码错误）时兜底，保证函数的完全性——它不是
  「更常被选中的元素」。
- `QcDefaultNotation` 的 `elems [...]` 记号把表头元素 `x` 兼任默认值，省去
  冗余参数；`genColor` 与 `genColor'` 语义一致。`oneOf` / `freq` 有同款记号。

再定义一个递归类型——二叉树，并配递归的 `Show` 实例：

```coq
Inductive Tree A :=
| Leaf : Tree A
| Node : A -> Tree A -> Tree A -> Tree A.

Arguments Leaf {A}.
Arguments Node {A} _ _ _.

#[export] Instance showTree {A} `{_ : Show A} : Show (Tree A) :=
  {| show := let fix aux t :=
       match t with
         | Leaf => "Leaf"
         | Node x l r =>
             "Node (" ++ show x ++ ") ("
                      ++ aux l ++ ") ("
                      ++ aux r ++ ")"
       end
     in aux
  |}.

Check oneOf_.
(* ===> oneOf_ : G ?A -> list (G ?A) -> G ?A
   从生成器列表中均匀挑一个；列表为空时退回默认生成器。 *)
```

- `Arguments Leaf {A}` / `Arguments Node {A} _ _ _` 把类型参数隐式化，后面
  写 `Leaf`、`Node x l r` 时不必标注 `A`。
- `showTree` 里 `let fix aux t := ... in aux` 是 Coq 写**局部递归函数**的标准
  手法；`show x` 的 `show` 来自上下文参数 `` `{_ : Show A} ``——正是第 70 章
  的隐式实例实参在干活。
- `oneOf_ def gs` 与 `elems_` 同构，只是列表里装的是**生成器**：均匀挑一个执行。

### 递归生成器的正确姿势：尺寸作燃料

一个诱人的错误写法（留在 .v 的注释里示众）：

```coq
(* 「显然」的递归生成器会被终止性检查拦下：

     Fixpoint genTree {A} (g : G A) : G (Tree A) :=
        oneOf [ ret Leaf ;;
                liftM3 Node g (genTree g) (genTree g) ].

   即使放行也是错的：每选一次 Node 都分裂出两棵待终止的子树，
   可以证明生成树的期望尺寸是无穷的。 *)

Fixpoint genTreeSized {A} (sz : nat) (g : G A) : G (Tree A) :=
  match sz with
    | O => ret Leaf
    | S sz' =>
        oneOf [
          ret Leaf ;
          liftM3 Node g (genTreeSized sz' g) (genTreeSized sz' g)
        ]
  end.

Definition genTree3 : G (Tree nat) := genTreeSized 3 (choose(0,3)).
```

`Sample genTree3`（执行区）形如
`[Leaf, Leaf, Node (3) (Node (0) (Leaf) (Leaf)) (...), Leaf, ...]`
—— 每层一半概率立即 `Leaf`，树普遍偏小。

- 直接递归的 `genTree` 过不了终止性检查：`genTree g` 对 `g` 没有结构递减。
  更糟的是它在**语义上**也错：每层以 1/2 概率选 `Node` 并分裂出两棵子树，
  这是个期望尺寸无穷的Branching process。
- `genTreeSized` 逐行读：
  - `Fixpoint ... (sz : nat)`：对燃料 `sz` 结构递归；
  - `O => ret Leaf`：燃料耗尽只能产叶；
  - `S sz'` 分支：`oneOf` 两分支等概率，`liftM3 Node g (genTreeSized sz' g) (genTreeSized sz' g)` 把三参数构造子提升进单子——递归调用都作用在严格更小的 `sz'` 上，过检查；
  - `liftM3 Node g gl gr` 等价于 `x <- g ;; l <- gl ;; r <- gr ;; ret (Node x l r)`。
- **坑**：叶与节点 1:1 时树普遍太浅（样本里大量 `Leaf`）。测试效果差，
  解决办法是加权——`freq`：

```coq
Check freq_.
(* ===> freq_ : G ?A -> list (nat * G ?A) -> G ?A
   每个生成器带一个 nat 权重，按权重比例选择。 *)

Fixpoint genTreeSized' {A} (sz : nat) (g : G A) : G (Tree A) :=
  match sz with
    | O => ret Leaf
    | S sz' =>
        freq [ (1,  ret Leaf) ;
               (sz, liftM3 Node g (genTreeSized' sz' g)
                                  (genTreeSized' sz' g))
             ]
  end.

Definition genTree3' : G (Tree nat) := genTreeSized' 3 (choose(0,3)).
```

`Sample genTree3'`（执行区）里 `Leaf` 概率降为 `1/(sz+1)`：形如
`[Node (...) (...) (...), Leaf, Node (...), ...]`。

`freq [(w1,g1); ...; (wn,gn)]` 的语义：设权重和 `W = Σwi`，以 `wi/W` 的概率
执行 `gi`。`genTreeSized'` 在尺寸 `S n'` 时令 `Leaf : Node = 1 : sz`——尺寸越大
越倾向长节点，`Leaf` 概率降为 `1/(sz+1)`，树明显更深。注意权重是**比例**而非
绝对值；权重为 0 的项永不选中（静默跳过，不是报错）。

## 71.7 backtrack：可失败的生成器与重试

```coq
(* ---------- 71.7 backtrack：可失败的生成器与重试 ---------- *)

Definition genSmallMaybe : G (option nat) :=
  n <- choose (0, 10) ;;
  ret (if (n <? 3)%nat then Some n else None).

Definition genSmallOr42 : G (option nat) :=
  backtrack [ (3, genSmallMaybe) ; (1, ret (Some 42)) ].

Sample genSmallOr42.
(* 形如 [Some 42, Some 1, Some 42, Some 0, Some 42, ...]
   —— 约两成落在 Some 0/1/2，失败则按权重换下一个，最后兜底 42 *)
```

- `genSmallMaybe : G (option nat)` 是「可能失败」的生成器：抽到 `0..2`
  （约 3/11）给 `Some n`，否则给 `None` 表示这一轮放弃。`(n <? 3)%nat` 是
  `nat` 的 `<` 布尔版——`%nat` 限定不能省：本章导入了 `String`，其字符串
  比较记号会抢占裸写的 `<?`（72 章会再遇到这个坑）。
- `backtrack [(w1,g1); ...]` 要求每个 `gi : G (option A)`：按权重逐个尝试，
  每项**至多跑一次**，遇到第一个 `Some x` 收工；全部 `None` 才整体返回 `None`。
- 与 `freq` 的区别：`freq` 只选**一个**生成器执行；`backtrack` 会**依次**尝试
  多个（不放回）。例中权重 `3 : 1` 倾向先试 `genSmallMaybe`，失败再兜底
  `Some 42`。第 73 章的 `suchThatMaybe` 会复用这套「可失败生成器」思路。

## 71.8 sized 与 resize：读取与改写尺寸参数

尺寸参数从哪来、怎么改？`sized` 读、`resize` 写：

```coq
(* ---------- 71.8 sized 与 resize：读取与改写尺寸参数 ---------- *)

Module DefineSized.
Import DefineG.

Definition sized {A : Type} (f : nat -> G A) : G A :=
  MkG
      (fun n r =>
         match f n with
           MkG g => g n r
         end).

End DefineSized.

Definition genTreeAuto : G (Tree nat) :=
  sized (fun n => genTreeSized' n (choose (0,3))).

Sample genTreeAuto.
(* 尺寸由 0 渐增：样本从 Leaf 起步，逐渐出现多层 Node *)

Check @resize.
(* ===> resize : nat -> G ?A -> G ?A —— 无视当前尺寸，强行钉成指定值 *)

Definition genListR1 : G (list nat) := resize 1 (listOf (choose (0,9))).
```

- `DefineSized` 里的教学定义把 71.1 的直觉落成代码：`sized f` 收到外界传入的
  尺寸 `n` 与种子 `r` 后，先把 `n` 喂给 `f` 得到生成器 `f n`，再让**它**在同样
  的 `n`（与 `r`）下运行——「读出当前尺寸」仅此而已。库里的真实定义对应
  `sizedGen`。
- `genTreeAuto` 把尺寸交给 `genTreeSized'`：`Sample` 的尺寸从 0 渐增到 10，
  所以样本从 `Leaf` 起步、后面的树越来越大——这就是「尺寸调度」。
- `resize n g` 反向操作：**覆盖**外界尺寸，`g` 内部无论怎么 `sized` 看到的都
  是 `n`。`Sample (resize 1 (listOf ...))` 里尺寸恒 1，`listOf` 的长度上界为 1，
  故样本只有 `[]` 与单元素表。典型用法是限制某个子生成器爆炸，如
  `resize 3 (listOf ...)`。

## 71.9 GenSized 与 Gen 类型类

把手艺收拢成类型类，`QuickChick` / `Sample` / `arbitrary` 就能自动找到生成器
（69 章「自动生成器」的真身）：

```coq
(* ---------- 71.9 GenSized 与 Gen 类型类 ---------- *)

Module DefineGen.

Class Gen (A : Type) :=
  {
    arbitrary : G A
  }.

End DefineGen.

Module DefineGenSized.

Class GenSized (A : Type) :=
  {
    arbitrarySized : nat -> G A
  }.

#[export] Instance GenOfGenSized {A} `{GenSized A} : Gen A :=
  {
    arbitrary := sized arbitrarySized
  }.

End DefineGenSized.
```

- `GenSized A`：成员 `arbitrarySized : nat -> G A`——按尺寸生成。递归类型走
  这条路（上面的 `genTreeSized'` 就是它的原型）。
- `Gen A`：成员 `arbitrary : G A`——尺寸无关（或尺寸已包进 `sized`）。
- 桥接实例 `GenOfGenSized`：只要有 `GenSized A` 就自动合成 `Gen A`，做法是
  `arbitrary := sized arbitrarySized`——把尺寸交还运行时调度。库的 `Arbitrary`
  类 = `Gen` + `Shrink`（收缩留给第 72 章）。

注册实例并演示：

```coq
#[export] Instance gen_color : Gen color :=
  {
    arbitrary := genColor
  }.

#[export] Instance genTree {A} `{Gen A} : GenSized (Tree A) :=
  {| arbitrarySized n := genTreeSized' n arbitrary |}.

(* 直接写 Sample (arbitrary : G color) 会触发 Rocq 抽取异常
   （evar in typeops）——带类型标注的类方法投影不适合交给抽取；
   先具名定义再采样即可规避。 *)

Definition genColorAuto : G color := arbitrary.

Definition genTreeNatAuto : G (Tree nat) := arbitrary.
(* Gen (Tree nat) 由桥接实例 GenOfGenSized 从 genTree 自动合成 *)
```

- `gen_color` 尺寸无关，直接钉 `arbitrary := genColor`。
- `genTree` 里裸写的 `arbitrary` 通过 `` `{Gen A} `` 解析到元素生成器——
  `Tree nat` 能用，是因为库自带 `Gen nat` 实例。`#[export]` 让实例随模块
  导出（70 章讲过它与 `Global` 的取舍）。
- `genColorAuto` / `genTreeNatAuto` 说明 `arbitrary` 可以脱离具体生成器名字
  使用：`G (Tree nat)` 的 `Gen` 实例由 `GenOfGenSized` 从 `genTree` 自动合成。
  `QuickChick` 命令收集的正是这套实例。注意注释里的坑：**内联写
  `Sample (arbitrary : G color)` 会触发抽取异常**——类方法投影带着类型标注
  一起被抽取时 Rocq 9 的内核会炸（evar in typeops），先具名定义再采样即可
  规避；74 章还会遇到它的另一个变体（缺 `Show` 实例）。

## 71.10 练习解答

### 练习 genListSized（2 星）

题目：仿 `genTreeSized'` 写按尺寸的列表生成器——尺寸 0 给空表，`S n'` 时按
`1 : sz` 加权选择空表或 `cons`。（库自带 `genListSized` 实例即此思路，故解答
命名加撇避免重名。）

```coq
(* ---------- 71.10 练习解答 ---------- *)

(* 练习 genListSized（2 星）：仿 genTreeSized' 写按尺寸的列表生成器。
   命名为 genListSized' 以避免与库自带的 genListSized 实例重名。 *)

Fixpoint genListSized' {A} (sz : nat) (g : G A) : G (list A) :=
  match sz with
    | O => ret []
    | S sz' =>
        freq [ (1, ret []) ;
               (sz, liftM2 cons g (genListSized' sz' g))
             ]
  end.

Definition genList3 : G (list nat) := genListSized' 3 (choose (0,3)).
```

讲解：`liftM2 cons g (genListSized' sz' g)` 等价于
`x <- g ;; xs <- genListSized' sz' g ;; ret (x :: xs)`；`1 : sz` 的权重让尺寸
越大越倾向续表，期望长度随尺寸线性增长。终止性靠对 `sz` 的结构递归。

### 练习 genColorOption（3 星）

题目：写 `G (option color)`，使 `None` 约占 1/10；`Some` 中 `Red` 的概率是
其余各色各自的 3 倍。

```coq
(* 练习 genColorOption（3 星）：None 约占 1/10，Some Red 是其余颜色各自的 3 倍。
   权重和取 20：None 占 2（1/10）；Some 共 18，其中 Red 9、其余三色各 3。 *)

Definition genColorOption : G (option color) :=
  freq [ (2,  ret None) ;
         (9,  ret (Some Red)) ;
         (3,  ret (Some Green)) ;
         (3,  ret (Some Blue)) ;
         (3,  ret (Some Yellow)) ].

End Ex71Generators.
```

权重设计：总和 `2+9+3+3+3 = 20`；`None` 得 `2/20 = 1/10`；`Some Red` 得
`9/20`，其余三色各 `3/20`——恰为 3 倍关系。`freq` 按**比例**理解权重，
nat 权重取整即可，不必约到最简。

## 71.11 测试执行区：命令为何在模块外

```coq
(* Sample 命令统一放在模块外：QuickChick 2.2 的抽取管线对模块内
   上下文生成的 OCaml 引用缺少模块限定，会报 Unbound value
   quickchick；命令放到模块外、Import 定义之后则一切正常。 *)

Import Ex71Generators.

Sample (returnGen 42).
(* 形如 [42, 42, 42, 42, 42, 42, 42, 42, 42, 42, 42] —— 常生成器无视尺寸与种子 *)

Sample genNat10.
(* 形如 [1, 2, 1, 9, 8, 10, 3, 6, 0, 1, 8] —— 两端点都含在内 *)

Sample genZ5.
(* ChooseZ 实例：形如 [-3, 5, 0, -1, 4, 2, -5, ...] *)

Sample genPairNat'.
(* 形如 [(1, 2), (0, 0), (3, 1), ...] —— 与 genPairNat 同分布 *)

Sample (listOf (choose (0,4))).
(* 形如 [[0, 3, 2, 0], [1, 3, 4, 1, 0], [], [4, 2, 3], ...] —— 长度随机、受尺寸约束 *)

Sample (vectorOf 3 (choose (0,4))).
(* 形如 [[0, 1, 4], [1, 1, 0], [3, 3, 3], ...] —— 长度恒为 3 *)

Sample genColor'.
(* 形如 [Red, Green, Blue, Blue, Red, Yellow, Blue, ...] *)

Sample genColor.

Sample genTree3.
(* 形如 [Leaf, Leaf, Node (3) (Node (0) (Leaf) (Leaf)) (...), Leaf, ...]
   —— 每层一半概率立即 Leaf，树普遍偏小 *)

Sample genTree3'.
(* Leaf 概率降为 1/(sz+1)：形如 [Node (...) (...) (...), Leaf, Node (...), ...] *)

Sample genSmallOr42.
(* 形如 [Some 42, Some 1, Some 42, Some 0, Some 42, ...]
   —— 约两成落在 Some 0/1/2，失败则按权重换下一个，最后兜底 42 *)

Sample genTreeAuto.
(* 尺寸由 0 渐增：样本从 Leaf 起步，逐渐出现多层 Node *)

Sample genListR1.
(* 尺寸钉死为 1：形如 [[7], [], [2], [], [4], ...]，列表长度至多 1 *)

Sample genColorAuto.

Sample genTreeNatAuto.

Sample genList3.
(* 形如 [[2, 0], [], [3, 1, 2], [], [1], ...] *)

Sample genColorOption.
(* 形如 [Some Red, None, Some Red, Some Blue, Some Red, Some Red, ...] *)
```

与前几章相同的结构约定（69 章 69.5 节详述过）：定义住在模块里防重名，
`Sample` / `QuickChick` 命令统一放模块外执行——QuickChick 2.2 的抽取管线
对模块内上下文生成的 OCaml 引用缺少模块限定，会报 `Unbound value
quickchick`。执行区按本章叙事顺序逐个采样：常生成器、区间、单子记号、
列表组合子、颜色、两代树生成器、backtrack、尺寸调度、类方法投影，最后
是两道练习的成品——一次 `build.sh -File 71_generators.v` 就是十七次
抽样演示。

## 71.12 小结与下一步

- `G A` ≈ `nat -> RandomSeed -> A`：尺寸 + 可分裂种子 ⇒ 确定性可复现的
  「随机」。
- `returnGen` / `bindGen` 给出 Monad 实例；`x <- c ;; ...` do 记号是标配写法。
- 四大组合子：`choose`（区间，端点乱序是运行时错误）、`listOf` / `vectorOf`
  （随机/定长列表）、`elems` / `oneOf` / `freq`（等概率/按权重选择，
  `freq` 权重是比例）、`backtrack`（`option` 失败重试，每项至多一次）。
- 递归类型用**尺寸作燃料**：`O` 产叶、`S n'` 分支递归、`freq` 控比例；
  `sized` 读尺寸、`resize` 钉尺寸；`GenSized` / `Gen` + 桥接实例
  `GenOfGenSized` 收拢为 `arbitrary`。
- 下一步：第 72 章讲 `Checkable` 与 `Shrink`（反例自动缩小）；第 73 章讲带
  条件的生成（`==>`、`suchThatMaybe`），会用到本章的 `backtrack` 思路。
- 交叉参考：第 69 章（`Sample` / `QuickChick` 命令本身）、第 70 章
  （`` `{Monad G} `` 记法与 `#[export] Instance` 的来龙去脉）。
