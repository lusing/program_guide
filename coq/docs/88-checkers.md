# 72 · 可检查性质与收缩

对应示例：`../examples/72_checkers.v`（`Module Ex72Checkers`，rocq 9.1 + QuickChick 2.2.0 实测编译退出码 0）

第 69 章已经见过属性测试最有价值的输出：不是一句抽象的「性质不成立」，而是一个
**能被打印、还能自动缩小的反例**。第 70 章介绍了承载这些能力的类型类，第 71 章
解决了「输入怎样随机产生」。本章把剩下的两半接上：怎样把 `bool`、可判定命题乃至
嵌套的全称性质统一变成可执行的 `Checker`，以及找到失败后怎样用 `Shrink` 做贪心
收缩。

我们先用四间 `CheckerPlayground` 从 `Checker = G Result` 开始重造一个迷你
QuickChick，再对照库里的真正实现；随后先借库自带的 nat / list / pair 收缩器看清
语义，再手写颜色与二叉树的收缩器，并在三叉树案例里让路径 `[Middle]` 精确暴露
「忘记镜像中子树」的 bug。最后用 `collect` 比较生成器分布，用五个组合子组织测试，
用 `Args` 控制运行预算。第 73 章会接着讨论丢弃与按规格生成，第 74 章再把本章手写
的实例交给 `QCDerive` 自动合成，第 75 章则把同一套方法用于带类型程序。

## 72.0 文件头、导入与作用域

```coq
(* 72 可检查性质与收缩 —— Checker 结果类型与 Checkable 类、
   CheckerPlayground 四步渐进、forAll / forAllShrink / forAllProof、
   Shrink 实例与贪心收缩、TernaryTree 综合案例、collect / tag 统计、
   whenFail / expectFailure / conjoin / disjoin、Args 调参与默认参数 *)

Set Warnings "-extraction-opaque-accessed,-extraction".
Set Warnings "-notation-overridden,-parsing".

From QuickChick Require Import QuickChick. Import QcNotation.
From Stdlib Require Import Arith Bool List ZArith. Import ListNotations.
Require Export ExtLib.Structures.Monads.
Export MonadNotation. Open Scope monad_scope.
From Stdlib Require Import String. Local Open Scope string.

Module Ex72Checkers.
```

前两行 `Set Warnings` 关闭抽取与记号覆盖的提示性告警，不改变测试语义。五行导入头
沿用了原书 `QC.v` 的写法，每一行都有明确分工：

- `From QuickChick Require Import QuickChick. Import QcNotation.`：QuickChick 门面
  库加记号库——把 `Dec` 命题变 `bool` 的 `?`、`P?` 等记号都来自 `QcNotation`。
- `From Stdlib Require Import Arith Bool List ZArith. Import ListNotations.`：
  算术、布尔、列表与整数基础库；`ListNotations` 启用 `[x; y]` 写法。
- `Require Export ExtLib.Structures.Monads.` 与
  `Export MonadNotation. Open Scope monad_scope.`：ExtLib 的单子结构提供
  `ret / bind / liftM3`，`MonadNotation` 带来 `x <- g ;; e` 记号。
- `From Stdlib Require Import String. Local Open Scope string.`：字符串库与
  `++` 拼接记号；`Local` 让作用域只在本文件内生效。

`Module Ex72Checkers` 把教学定义与库里同名常量隔开；真正的运行命令集中在文件
末尾模块外的「测试执行区」（72.12 节），做法与第 69 章 69.5 节一致。

**坑：** 作用域的打开顺序会在全章反复制造麻烦。这里打开的 `string` 作用域让 `++`
默认拼字符串、让 `=?` / `<=?` / `<?` 默认解析到字符串比较；72.7 又会
`Open Scope list.` 把 `++` 抢成列表追加。于是 72.8 的 `showTernTree` 要写
`%string`，72.10 的 nat 比较要写 `%nat`。记号冲突时，后打开的作用域优先。

## 72.1 舞台素材：沿用 71 章的树与小性质

本节不引入新的 checker，而是准备四种可打印颜色、两种二叉树生成器、镜像函数、
相等判定实例和两条性质。这样后面的每次改写都只改变「怎样检查」，不必同时重新
理解被测程序。

```coq
(* ---------- 72.1 舞台素材：沿用 71 章的树与小性质 ---------- *)

Inductive color := Red | Green | Blue | Yellow.

#[export] Instance show_color : Show color :=
{| show c :=
     match c with
     | Red => "Red"
     | Green => "Green"
     | Blue => "Blue"
     | Yellow => "Yellow"
     end |}.

Definition genColor : G color := elems [ Red ; Green ; Blue ; Yellow ].

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

Fixpoint genTreeSized {A} (sz : nat) (g : G A) : G (Tree A) :=
  match sz with
  | O => ret Leaf
  | S sz' =>
      oneOf [ ret Leaf ;
              liftM3 Node g (genTreeSized sz' g) (genTreeSized sz' g) ]
  end.

Fixpoint genTreeSized' {A} (sz : nat) (g : G A) : G (Tree A) :=
  match sz with
  | O => ret Leaf
  | S sz' =>
      freq [ (1,  ret Leaf) ;
             (sz, liftM3 Node g (genTreeSized' sz' g) (genTreeSized' sz' g)) ]
  end.

Fixpoint mirror {A : Type} (t : Tree A) : Tree A :=
  match t with
  | Leaf => Leaf
  | Node x l r => Node x (mirror r) (mirror l)
  end.

#[export] Instance eq_dec_tree (t1 t2 : Tree nat) : Dec (t1 = t2).
Proof. constructor; dec_eq. Defined.

Definition mirrorP (t : Tree nat) := (mirror (mirror t)) = t?.

Definition faultyMirrorP (t : Tree nat) := (mirror t) = t ?.
```

逐行抓重点：

- `Show color` 把构造子逐一映射为字符串；`elems` 四选一且等概率。反例能否读得懂，
  首先取决于 `Show`，与性质本身是否成立无关。
- `Tree A` 的 `Leaf` 不带载荷，`Node` 带一个元素和左右子树。两条 `Arguments`
  隐去类型参数。`showTree` 用 `{| show := let fix aux t := ... in aux |}`：局部
  不动点 `aux` 直接作为 `show` 的值，不需要类型标注，类型由外层实例推出；打印
  格式形如 `Node (2) (Leaf) (Leaf)`。外层的 `` `{_ : Show A} `` 表示只需要元素
  可打印，不关心实例的名字。
- 两个生成器都以 `sz` 为结构递归燃料，`O` 必须返回 `Leaf`。`genTreeSized` 在非零
  尺寸用 `oneOf` 让叶与节点等概率；`genTreeSized'` 改用 `freq`，叶与节点权重为
  `1 : sz`。`liftM3` 依次生成载荷、左树、右树，再套用 `Node`。第 71 章已解释尺寸
  与终止性，72.9 节会用数据证明两种分布的差异。
- `mirror` 保留根载荷，交换并递归镜像左右子树。`mirrorP` 断言「镜像两次复原」，
  `faultyMirrorP` 故意断言「镜像一次就等于原树」；后者只在对称树上成立，是稳定的
  反例来源。两条性质都特化到 `Tree nat`：`?` 记号要求相等命题有 `Dec` 实例，而
  下面注册的 `eq_dec_tree` 恰好只对 `Tree nat` 给出（nat 自带相等判定），性质跟着
  实例走，就不必再写泛型约束。
- `eq_dec_tree` 是一个两行的 `Dec` 实例，不再手写 sumbool 递归：`constructor` 把
  `Dec (t1 = t2)` 拆成 `{t1 = t2} + {t1 <> t2}` 的两个分支；`dec_eq` 策略（第
  70 章）按构造子结构自动生成比较代码——先比构造子，同为 `Node` 时再递归比较
  nat 载荷与左右子树；结尾用 `Defined` 而非 `Qed`，保留计算内容供 `?` 与 OCaml
  抽取使用。

**坑：** `faultyMirrorP` 不是「镜像函数有 bug」，而是「把错误性质安在正确函数上」；
72.8 节才会看到实现本身确有 bug。测试失败时先分清是实现错、规格错，还是生成与
判定设施不完整。

## 72.2 CheckerPlayground1：`Checker = G Result`

第一间游乐场只回答一个问题：一次随机测试的计算结果是什么？答案不是单纯的布尔值，
而是一个**随机地产出测试结果的程序**。

```coq
(* ---------- 72.2 CheckerPlayground1：Checker = G Result ---------- *)

(* 原书第一间"游乐场"：自己动手造一个迷你版 QuickChick。
   核心观察：测试结果是"关于随机性的程序"，所以 Checker 就是
   G Result —— 一个产出 Result 的随机程序。 *)

Module CheckerPlayground1.

Inductive Result := Success | Failure.

#[export] Instance showResult : Show Result :=
  {
    show r := match r with Success => "Success" | Failure => "Failure" end
  }.

Definition Checker := G Result.

(* Checkable 类型类：把"可检查的东西"统一抽象成 Checker。
   这里的 unit 实例在最终库里被淘汰了（库中 unit 表示放弃本测试点），
   bool 实例则与库中一致。 *)

Class Checkable (A : Type) : Type :=
  { checker : A -> Checker }.

#[export] Instance checkableBool : Checkable bool :=
  {
    checker b := if b then ret Success else ret Failure
  }.

End CheckerPlayground1.
```

`Result` 目前只有 `Success` 与 `Failure`，`showResult` 让 `Sample` 能打印它们。
`Checker := G Result` 是最关键的类型等式：`G` 是第 71 章的生成器单子，所以一个
checker 可以读取尺寸和随机种子，做一次或多次随机计算，最后给出结果。常生成器
`ret Success` 虽然不看种子，也已经具有正确的类型。

`Checkable A` 只有一个字段 `checker : A -> Checker`，意思是「类型 `A` 的值知道
怎样变成测试程序」。`checkableBool` 是最小实例：`true` 变成恒定成功，`false`
变成恒定失败。两处 record 实例都用了 `{ ... }` 花括号语法——与 72.1 的
`{| ... |}` 完全等价，原书此处即用花括号。

于是 `Sample (checker true)` 会打印 11 个成功——11 来自 `Sample` 的尺寸调度，
不是因为这条性质被检查了 11 个不同输入。不过游乐场的这些 `Sample` 命令在文末
执行区**以注释保留**：`Sample` 只认库里的 `Show` / 生成器体系，对游乐场自定义的
`Checker` / `Checkable` 做抽取会触发 Rocq 编译器异常（evar in typeops），原书也
将它们注释；预期输出（11 个 `Success`、11 个 `Failure`）写在执行区的注释里。

注释还提前指出库版与教学版的一处差异：库中的 `unit` 不表示普通成功，而表示放弃
当前测试点。这个概念会在 72.6 节与第 73 章的 discard 机制相遇。

**坑：** `Checker` 不是 `Result`，正如 `G nat` 不是 `nat`。在 checker 外面不能
直接对结果做模式匹配；要先用单子绑定运行它，或交给 `Sample` / `QuickChick` 命令。

## 72.3 CheckerPlayground2：Prop 也可检查

布尔性质容易执行，但 Rocq 里大量规格住在 `Prop`。第二间游乐场利用第 69 章的可判定
性桥梁：只要命题有 `Dec P`，就能运行与 `P` 对应的判定过程。

```coq
(* ---------- 72.3 CheckerPlayground2：Prop 也可检查 ---------- *)

(* 第二间游乐场：借助可判定性实例 Dec（见第 69 章），
   任何命题 P 只要有 Dec P 就能变成 Checker。 *)

Module CheckerPlayground2.

Export CheckerPlayground1.

#[export] Instance checkableDec `{P : Prop} `{Dec P} : Checkable P :=
  {
    checker p := if P? then ret Success else ret Failure
  }.

(* 两个"猜想"：用 Conjecture 假设命题成立，QuickChick 来验算。
   Prop 在提取时被擦除，所以 checker c1 运行的是判定过程 0 = 42?，
   而不是去评估公理本身 —— 提取是安全的。 *)

Conjecture c1 : 0 = 42.

Conjecture c2 : 41 + 1 = 42.

End CheckerPlayground2.
```

`Export CheckerPlayground1` 不仅导入名字，还在本模块被导入时继续导出第一间的实例，
因此这里仍能使用同一个 `Result`、`Checker` 与 `Checkable`。`checkableDec` 有两个
隐式参数：命题 `P` 本身和 `Dec P` 实例。字段参数 `p : P` 是命题的证据，但函数体
完全不检查 `p`，而是计算 `P?`：证据携带的是逻辑信息，真假判定已经由实例给出。

这也解释了为什么 `Conjecture c1 : 0 = 42` 虽然没有、也不可能有正常证明，却仍能被
采样：抽取会擦除 `Prop` 证据，运行的是 `0 = 42?` 的可计算判定，不是在 OCaml 中
「执行一条公理」。`c1` 全部失败，`c2` 全部成功——这两条 `Sample` 同样因抽取异常
在执行区以注释保留。

**坑：** 可判定不等于为真。`Dec P` 提供「能算出 `P` 或 `not P`」的能力；它既不会
把假命题变真，也不会把一万次测试变成 `forall` 证明。`Conjecture` 仍是公理声明，
若后续把它用于证明，公理会真实进入逻辑上下文。

## 72.4 CheckerPlayground3：`forAll` 的雏形

前两类 checker 都没有随机输入。第三间游乐场把生成器 `g : G A` 与性质
`f : A -> B` 粘起来：每采样一个 `a`，就检查一次 `f a`。

```coq
(* ---------- 72.4 CheckerPlayground3：forAll 的雏形 ---------- *)

Definition isRed (c : color) :=
  match c with
  | Red => true
  | _ => false
  end.

Module CheckerPlayground3.

Import CheckerPlayground2.

(* forAll 把生成器和性质粘在一起：
   从 g 采样一个 a，再把 f a 交给 checker。
   注意类型类参数 `{Checkable B}：被检查侧可以是 bool、Prop 等
   任何可检查的类型。 *)

Definition forAll {A B : Type} `{Checkable B} (g : G A) (f : A -> B)
    : Checker :=
  a <- g ;;
  checker (f a).

End CheckerPlayground3.
```

`isRed` 是一个刻意的弱规格：只有 `Red` 返回 `true`，其余三种颜色都失败。
`forAll` 的两个类型参数分工清楚：`A` 是生成侧，由 `g` 提供；`B` 是性质侧，只要求
`Checkable B`。函数体两行正是单子语义的直译：

1. `a <- g` 从生成器取出一个值；
2. `checker (f a)` 把该值上的布尔式、可判定命题或其他可检查结果转为 `Checker`。

因为返回类型没有限定为 `bool`，同一个组合子可以服务 `isRed`、`mirrorP` 与
`faultyMirrorP`。执行区注释里保留了三组预期输出，分别对应「所有颜色都是红色」
（红黄蓝绿等概率、成败混杂）、「镜像两次复原」（11 个 `Success`）、「镜像一次
不动」（成败混杂，只有对称树通过）。

**坑：** 这一版只能告诉我们某次失败了，不能告诉我们失败输入是什么。还有，`forAll`
每次采样的全称性质不是逻辑上的全称证明；它只是把一次随机选择嵌入 checker。
真正的嵌套量化还依赖库中更丰富的 `Checkable` 实例，见 72.6 节。

## 72.5 CheckerPlayground4：失败时打印反例

调试需要的最小信息是「哪个输入让性质失败」。第四间游乐场把 `Failure` 从无参数
构造子升级为携带任意可打印值的依赖构造子，并重写 `forAll`，让失败结果带上采样
输入与失败原因。

```coq
(* ---------- 72.5 CheckerPlayground4：失败时打印反例 ---------- *)

(* 第三间游乐场的失败只报 Failure，不知道输在哪。
   第四间让 Failure 携带反例本身：Failure 变成依赖构造子，
   打包"任意可打印的值"。bool / Dec 检查器没有有用信息可记，
   就拿 unit 的唯一居民 tt 当"失败原因"占位。 *)

Module CheckerPlayground4.

Export CheckerPlayground2.

Inductive Result :=
  | Success : Result
  | Failure : forall {A} `{Show A}, A -> Result.

#[export] Instance showResult : Show Result :=
  {
    show r := match r with
                Success => "Success"
              | Failure a => "Failure: " ++ show a
              end
  }.

Definition Checker := G Result.

Class Checkable (A : Type) : Type :=
  { checker : A -> Checker }.

#[export] Instance showUnit : Show unit :=
  {
    show u := "tt"
  }.

#[export] Instance checkableBool : Checkable bool :=
  {
    checker b := if b then ret Success else ret (Failure tt)
  }.

#[export] Instance checkableDec `{P : Prop} `{Dec P} : Checkable P :=
  {
    checker p := if P? then ret Success else ret (Failure tt)
  }.

(* 关键改动在 forAll：先采样 a、再检查 f a 得到 r，
   失败时不是丢掉 a，而是把 (a, b) 打包进新的 Failure ——
   a 是让性质失败的输入，b 是失败原因。多个 forAll 连用时，
   反例会累积成嵌套的元组，一层都不丢。 *)

Definition forAll {A B : Type} `{Show A} `{Checkable B}
                  (g : G A) (f : A -> B) : Checker :=
  a <- g ;;
  r <- checker (f a) ;;
  match r with
    Success => ret Success
  | Failure b => ret (Failure (a,b))
  end.

End CheckerPlayground4.
```

先看 `Result`：`Failure` 现在是 `forall {A} `{Show A}, A -> Result` 的依赖构造子，
每个失败自带「值的类型、打印实例、值本身」三件套，于是颜色失败携带颜色、树失败
携带树；`showResult` 把它打印成 `Failure: <反例>`。`Checker` 仍是 `G Result`，
改变的是结果携带的信息，而不是随机执行模型。

bool 与 `Dec` 检查器没有有用信息可记，就拿 `unit` 的唯一居民 `tt` 当「失败原因」
占位：`showUnit` 把它打印成 `tt`，两个检查器失败时都返回 `ret (Failure tt)`。

关键改动在 `forAll` 的三段式结构：

1. `a <- g` 采样输入；
2. `r <- checker (f a)` 检查性质；
3. `match r with ... | Failure b => ret (Failure (a,b))`——失败时不是丢掉 `a`，
   而是把「让性质失败的输入 `a`」与「失败原因 `b`」打包成二元组塞进新的
   `Failure`。pair 自带 `Show` 实例，打印时两个分量都可见。

与第三间的两行版对比：多一次绑定和一次 `match`，换来「失败必带输入」。多个
`forAll` 连用时，外层的 `b` 又可以是内层的 `(a', b')`，反例会累积成嵌套元组，
一层都不丢——库版嵌套量化能打印 `(树, (路径, tt))` 这类反例，原理正在于此。

执行区注释里保留了预期输出：颜色反例形如 `Failure: (Blue, tt)`，树反例形如
`Failure: (Node (2) (Node (3) (Node (2) (Leaf) (Leaf)) (Leaf)) ..., tt)`。同样
因为前述抽取异常，这些 `Sample` 以注释形式保留。

**坑：** 不要只看到 `Show A` 就以为它参与性质判定。它只负责人可读输出；去掉或写坏
`Show` 会影响诊断，不会改变 `f a` 的真假。另一点是「迷你类与库类同名但不同构」，
跨模块混用时必须看清实际解析到哪个 `checker`。

## 72.6 库里真正的 Checker 与 `forAll`

游乐场为了突出主干，把结果压缩成两个构造子。库版还要支持放弃、统计标签、失败
回调、收缩记录等功能，因此接口更丰富。

```coq
(* ---------- 72.6 库里真正的 Checker 与 forAll ---------- *)

(* 库中的真货与游乐场的差别有三：
   - Result 不只是 Success / Failure，而是携带一堆字段的记录：
     ok（成功/失败/放弃三态）、reason（失败原因字符串）、
     stamp（collect 收集的分布标签）、callbacks（whenFail 打印）等；
   - Checkable 的实例多得多：bool、unit（放弃）、Dec、Prop、
     G QProp、Checker 本身、option，乃至函数（testFun 即 forAllShrink）；
   - 这些实例组成一条"实例链"：嵌套的 forAll 之所以能工作，
     是因为每层 bind 后 Checker 自己仍可被 checker 接受。 *)

Check @forAll.
(*
     : forall A prop : Type,
       Producer G A ->
       Checkable prop -> G A -> (A -> prop) -> Checker
*)

Check @forAllShrink.
(*
     : forall A prop : Type,
       Producer G A ->
       Checkable prop ->
       G A -> (A -> list A) -> (A -> prop) -> Checker
*)

Check @forAllProof.
(*
     : forall (A : Type) (prop : A -> Prop),
       Checkable (forall x : A, prop x) ->
       Producer G A ->
       (forall x : A, Producer G (semProd G gen x)) -> ...
       即 forAllProof gen pf 要求对任意 x 提供"gen 能产生 x"的证据，
       返回性质 forall x, semProd gen x -> prop x —— 把随机测试
       提升成关于生成器覆盖范围的定理。实践中多为内部工具，很少手写。
*)

(* 库版 forAll 失败时会打印反例（Show A 的责任在生成侧，
   性质侧只需 Checkable）： *)

Definition treesMirrorP :=
  forAll (genTreeSized' 3 (choose (0, 3))) mirrorP.

Definition faultyForAllP : Checker :=
  forAll (genTreeSized' 3 (choose (0, 3))) faultyMirrorP.

(* unit 的 Checkable 实例表示"放弃本测试点"（discard 的另一入口），
   连续 20000 次（默认 maxDiscard）都放弃后，QuickChick 认输。 *)

Definition giveUpP : Checker :=
  forAll (ret 0) (fun _ : nat => tt).
```

库版 `Result` 的核心不是「成功/失败各存一个字符串」，而是一份测试执行记录：
`ok` 区分成功、失败、放弃，`reason` 保存原因，`stamp` 保存 `collect` 的统计标签，
`callbacks` 保存 `whenFail` 等失败时才执行的动作。72.9–72.10 节会分别用到这些
字段对外提供的功能。

三个 `Check` 展示接口层次：

- `@forAll` 比教学版多 `Producer G A`，这是生成端的抽象约束；性质端仍是
  `Checkable prop`。`treesMirrorP` 把加权树生成器与 `mirrorP` 组合，执行区实测
  `+++ Passed 10000 tests (0 discards)`。
- `@forAllShrink` 在生成器和性质之间增加 `A -> list A`，即收缩函数。它不仅会找
  反例，还会沿候选列表继续寻找更小的反例。
- `@forAllProof` 连接随机生成器的语义 `semProd` 与逻辑命题：若能为生成器覆盖范围
  提供证据，就可把测试对象提升为关于该范围的定理。它是内部设施，不要把它理解成
  「运行 `QuickChick` 后自动得到证明」。

`faultyForAllP` 与 `giveUpP` 都是模块内的命名 `Definition`，执行区直接
`QuickChick` 它们：前者一次实测给出大树反例并报 `Failed after 3 tests and
0 shrinks`（不做收缩时反例可能很大）；后者让性质恒定返回 `tt`——库中这不是恒真，
而是每次都放弃，达到默认 `maxDiscard = 20000` 后输出 `Gave up`。这与第 73 章
`==>` 前提不成立时的丢弃共用预算概念，但入口不同。

所谓**实例链**，就是类型类搜索逐层完成转换。例如性质函数经 `testFun` 使用生成与
收缩，函数体可返回 `Checker`，而 `Checker` 自身又有 `Checkable` 实例；于是外层
`forAll` 的内层仍可再放一个 `forAll`。`Show` 负责生成侧反例打印，`Checkable`
负责性质侧执行，两类约束不要混写。

**坑：** `Passed`、`Failed`、`Gave up` 是三种不同结论。尤其 `Gave up` 既没有找到
反例，也没有完成预定数量的有效测试；第 73 章会专门处理这种测试失效。

## 72.7 Shrinking：收缩实例与收缩语义

未经收缩的反例往往包含大量无关结构。`Shrink` 提供一张「从当前值走向更小值」的
局部候选表；QuickChick 在**保持失败**的前提下反复走这张表。

```coq
(* ---------- 72.7 Shrinking：收缩实例与收缩语义 ---------- *)

(* Shrink 类只有一个方法 shrink : A -> list A，
   要求返回的候选都比原值"更小"。收缩是保持失败前提下的
   贪心局部搜索：每次跳到第一个仍让性质失败的候选，直到
   没有更小的失败候选为止。 *)

#[export] Instance shrinkColor : Shrink color :=
{| shrink c :=
     match c with
     | Red => []
     | Green => [Red]
     | Blue => [Red; Green]
     | Yellow => [Red; Green; Blue]
     end |}.

(* 库自带实例：shrink nat 每次折半（对数级），
   shrink list 先收缩尾再收缩头（shrinkListAux），
   shrink pair 先收缩第一个分量再收缩第二个。 *)

Eval vm_compute in (shrink 42).
(*
     = [21; 10; 5; 2; 1; 0]
     : list nat
*)

Eval vm_compute in (shrink (1, [2; 3])).
(*
     = [(0, [2; 3]); (1, [3]); (1, [2]); (1, [2; 1]); (1, [2; 0]);
        (1, [1; 3]); (1, [0; 3])]
     : list (nat * list nat)
*)

Print shrinkList.
(* 可看到 shrink list 直接复用 shrinkListAux，
   而 shrinkListAux 是"交替收缩元素、收缩结构"的递归。 *)

(* 对树定义收缩：先砍成子树，再收缩节点载荷，再递归收缩子树。
   注意 Open Scope list 让 ++ 走 list_scope。 *)

Open Scope list.

Fixpoint shrinkTreeAux {A}
              (s : A -> list A) (t : Tree A)
            : list (Tree A) :=
  match t with
    | Leaf => []
    | Node x l r => [l] ++ [r] ++
                    map (fun x' => Node x' l r) (s x) ++
                    map (fun l' => Node x l' r) (shrinkTreeAux s l) ++
                    map (fun r' => Node x l r') (shrinkTreeAux s r)
  end.

#[export] Instance shrinkTree {A} `{Shrink A} : Shrink (Tree A) :=
  {| shrink x := shrinkTreeAux shrink x |}.

(* forAllShrink 的完整循环：生成、发现失败、收缩到局部极小反例。 *)

Definition faultyShrinkP : Checker :=
  forAllShrink (genTreeSized' 5 (choose (0, 5))) shrink faultyMirrorP.

(* 有了 Gen + Shrink 两个实例，ArbitraryOfGenShrink 桥接出 Arbitrary，
   于是 faultyMirrorP 这种 nat -> Tree nat -> ... 形式的性质
   可以直接交给 QuickChick（testFun 实例内部就是 forAllShrink）。 *)

#[export] Instance genTree {A} `{Gen A} : GenSized (Tree A) :=
  {| arbitrarySized n := genTreeSized' n arbitrary |}.
```

先把算法说精确。设当前反例为 `x`：按 `shrink x` 的列表顺序试候选，取**第一个仍使
性质失败**的 `x'`，令 `x := x'` 并重复；若所有候选都通过，当前 `x` 就是局部极小
反例。它既不枚举全部更小值，也不保证全局最小；候选顺序会直接影响收缩路径与步数。
返回原值或更大值还可能造成循环、低效或反例膨胀，因此「严格更小」是手写 shrinker
的基本契约。

- `shrinkColor` 把 `Red` 当作最小值；`Green` 只能到 `Red`，`Blue` 依次尝试
  `Red`、`Green`，`Yellow` 再增加 `Blue`。失败若与颜色无关，通常会一路缩到 `Red`。
- `shrink 42` 精确得到 `[21; 10; 5; 2; 1; 0]`：从折半候选开始，逐级逼近零，候选数
  是对数级而非列出 0 到 41。**这是候选列表，不是 QuickChick 对 42 实际走过的收缩
  路径**；实际只按失败保持规则选择其中一项，再从新值重新计算列表。
- pair 示例先列第一分量收缩 `(0, [2; 3])`，再列列表结构与元素收缩。它直观展示
  实例组合：pair 调用 nat/list，list 又调用元素的 nat shrinker。
- `shrinkTreeAux` 采用原书的写法：一个普通 `Fixpoint`，把元素收缩函数
  `s : A -> list A` 作为**显式参数**传入——结构递归发生在 `t` 上（递归调用
  `shrinkTreeAux s l`、`shrinkTreeAux s r`），载荷收缩调用 `s x`。这样既不依赖
  未注册的实例，也不需要 `Program`。对 `Leaf` 无候选；对节点先给 `[l]`、`[r]`
  两个大跳跃，再收缩载荷，再递归收缩左右子树；`map` 把每个子候选重新装回只改了
  一处的节点。随后的普通 `Instance shrinkTree` 把类型类的 `shrink` 喂进去：
  `shrink x := shrinkTreeAux shrink x`。
- `Open Scope list.`：从此 `++` 解析为列表追加，`shrinkTreeAux` 拼候选表用的正是
  它；这一改动的副作用要到 72.8 的 `%string` 才显现。
- `forAllShrink` 把「生成 → 失败 → 收缩」连成完整循环，`faultyShrinkP` 是它的
  命名版本。执行区一次实测：反例收缩为 `Node (0) (Leaf) (Node (0) (Leaf) (Leaf))`
  这样的非对称小树，`Failed after 1 tests and 5 shrinks`——5 步收缩把一棵大树砍成
  最小的非对称树，bug 本质一眼可见。

最后注册 `genTree : GenSized (Tree A)`：它复用 72.1 的加权生成器，元素生成器由
`` `{Gen A} `` 提供。库的 `GenOfGenSized` 再把 `GenSized` 桥成 `Gen`，
`ArbitraryOfGenShrink` 再把 `Gen + Shrink` 桥成 `Arbitrary`。因此裸写
`QuickChick faultyMirrorP` 时，类型类搜索会自动完成原本手写的 `forAllShrink`。

**坑：** 「候选更小」不是 Rocq 类型系统强制检查的结论，而是实例作者必须维护的语义
约定。收缩器也应尽量保持被测对象的不变量；若收缩良类型程序时造出不良类型程序，
就会把真正的反例缩成无关失败。第 75 章会专门处理这种类型保持收缩。

## 72.8 TernaryTree 案例：生成 + 收缩 + 修复

现在把打印、生成、收缩、可判定相等、嵌套全称性质全部组合起来。被测函数看似镜像了
左右子树，却原样保留中子树；普通整树性质或许也能撞上 bug，而路径性质能把失败位置
直接缩成 `[Middle]`。

```coq
(* ---------- 72.8 TernaryTree 案例：生成 + 收缩 + 修复 ---------- *)

Inductive TernaryTree A :=
| TLeaf : TernaryTree A
| TNode : A -> TernaryTree A -> TernaryTree A -> TernaryTree A
          -> TernaryTree A.

Arguments TLeaf {A}.
Arguments TNode {A} _ _ _ _.

(* 故意写错的镜像：中子树忘了镜像。 *)

Fixpoint tern_mirror {A} (t : TernaryTree A) : TernaryTree A :=
  match t with
  | TLeaf => TLeaf
  | TNode x l m r => TNode x (tern_mirror r) m (tern_mirror l)
  end.

#[export] Instance showTernTree {A} `{Show A} : Show (TernaryTree A) :=
  {| show := let fix aux t :=
       match t with
         | TLeaf => "TLeaf"
         | TNode x l m r =>
             ("TNode (" ++ show x ++ ") ("
                      ++ aux l ++ ") ("
                      ++ aux m ++ ") ("
                      ++ aux r ++ ")")%string
       end
     in aux
  |}.

(* 三叉树生成器：没有 liftM4，嵌套 bind 即可。 *)

Fixpoint genTernTreeSized {A} (sz : nat) (g : G A) : G (TernaryTree A) :=
  match sz with
  | O => ret TLeaf
  | S sz' =>
      freq [ (1,  ret TLeaf) ;
             (sz, x <- g ;;
                  l <- genTernTreeSized sz' g ;;
                  m <- genTernTreeSized sz' g ;;
                  r <- genTernTreeSized sz' g ;;
                  ret (TNode x l m r)) ]
  end.

(* 收缩三叉树：先砍成三棵子树之一，再收缩载荷与三棵子树。 *)

Fixpoint shrinkTernTreeAux {A}
              (s : A -> list A) (t : TernaryTree A)
            : list (TernaryTree A) :=
  match t with
    | TLeaf => []
    | TNode x l m r => [l] ++ [m] ++ [r] ++
                    map (fun x' => TNode x' l m r) (s x) ++
                    map (fun l' => TNode x l' m r) (shrinkTernTreeAux s l) ++
                    map (fun m' => TNode x l m' r) (shrinkTernTreeAux s m) ++
                    map (fun r' => TNode x l m r') (shrinkTernTreeAux s r)
  end.

#[export] Instance shrinkTernTree {A} `{Shrink A} : Shrink (TernaryTree A) :=
  {| shrink x := shrinkTernTreeAux shrink x |}.

Inductive direction := Left | Middle | Right.

#[export] Instance showDirection : Show direction :=
{| show d :=
     match d with
     | Left => "Left"
     | Middle => "Middle"
     | Right => "Right"
     end |}.

Definition genDirection : G direction := elems [Left; Middle; Right].

#[export] Instance shrinkDirection : Shrink direction :=
{| shrink d :=
     match d with
     | Left => []
     | Middle => [Left]
     | Right => [Left]
     end |}.

(* 沿路径下潜：只在中子树里才可能暴露 tern_mirror 的 bug。 *)

Definition path := list direction.

#[export] Instance showPath : Show path := showList.

#[export] Instance genPath : Gen path := { arbitrary := listOf genDirection }.

#[export] Instance shrinkPath : Shrink path := shrinkList.

Definition traverse_node {A} (t : direction) (l m r : TernaryTree A) :=
  match t with
  | Left => l
  | Middle => m
  | Right => r
  end.

Fixpoint traverse_path {A} (p : path) (t : TernaryTree A) :=
  match t with
  | TLeaf =>
    TLeaf
  | TNode x l m r =>
    match p with
    | h :: tl => traverse_path tl (traverse_node h l m r)
    | [] => t
    end
  end.

Definition path_mirror := map (fun t => match t with
                                     | Left => Right
                                     | Right => Left
                                     | _ => t
                                     end).

(* 判定三叉树相等：与 eq_dec_tree 一样走 Dec 实例 + dec_eq。 *)

#[export] Instance eq_dec_tern_tree (t1 t2 : TernaryTree nat) : Dec (t1 = t2).
Proof. constructor; dec_eq. Defined.

Definition tern_mirror_path_flip (t : TernaryTree nat) (p : path) :=
  (  traverse_path p t
   = tern_mirror (traverse_path (path_mirror p) (tern_mirror t))) ?.

(* 手写的生成 + 收缩链路，看最小反例长什么样。 *)

Definition bug_finding_tern_tree : Checker :=
  forAllShrink (@genTernTreeSized nat 5 (choose (0, 10))) shrink
    (fun t =>
       forAllShrink (listOf genDirection) shrink
         (fun p => tern_mirror_path_flip t p)).

(* 修复：给中子树也套上 tern_mirror。 *)

Fixpoint tern_mirror_fixed {A} (t : TernaryTree A) : TernaryTree A :=
  match t with
  | TLeaf => TLeaf
  | TNode x l m r =>
      TNode x (tern_mirror_fixed r) (tern_mirror_fixed m)
              (tern_mirror_fixed l)
  end.

Definition tern_mirror_path_flip_fixed (t : TernaryTree nat) (p : path) :=
  (  traverse_path p t
   = tern_mirror_fixed (traverse_path (path_mirror p) (tern_mirror_fixed t))) ?.

Definition tern_tree_fixed_test : Checker :=
  forAllShrink (@genTernTreeSized nat 5 (choose (0, 10))) shrink
    (fun t =>
       forAllShrink (listOf genDirection) shrink
         (fun p => tern_mirror_path_flip_fixed t p)).

(* 注册类型类实例后，性质里的两个参数都能自动走
   "生成 + 收缩"的标准链路，一行 QuickChick 即可。 *)

#[export] Instance genTernTree {A} `{Gen A} : GenSized (TernaryTree A) :=
  {| arbitrarySized n := genTernTreeSized n arbitrary |}.
```

先读数据通路。`TNode` 有四个显式参数：载荷与左、中、右树。错误版 `tern_mirror`
递归镜像 `r` 和 `l`，却直接放回 `m`；修复版唯一关键变化是把中间位置改为
`tern_mirror_fixed m`。`showTernTree` 与 `showTree` 同款 `let fix aux`，但整个
拼接表达式外套 `%string`——72.7 的 `Open Scope list.` 已经把 `++` 抢成列表追加，
不显式回到 string_scope 就会类型错误；72.1 的 `showTree` 定义在打开 list 作用域
之前，所以不需要这个标注。这是「作用域打开时序」的直接后果，也是本章反复出现的
主题。生成器没有现成的 `liftM4`，便在 `freq` 里顺序绑定 `x`、`l`、`m`、`r`，最后
`ret` 构造节点，尺寸仍在每次递归时减一。`shrinkTernTreeAux` 是二叉版本的直接
扩展：同样以 `s : A -> list A` 为显式参数的普通 `Fixpoint`，先尝试三棵完整子树
`[l] ++ [m] ++ [r]`，再分别收缩载荷和三个子位置。

`direction` 与 `path` 把「往哪里走」变成独立随机输入：`genDirection` 均匀生成
三个方向，`showPath` / `shrinkPath` 直接复用列表的 `showList` / `shrinkList`，
`genPath` 用 `listOf` 生成路径。方向收缩把 `Middle`、`Right` 都导向 `Left`，
列表收缩负责删方向或缩元素；最终保留哪个方向仍由「必须保持性质失败」筛选，所以
暴露中子树 bug 时 `[Middle]` 会留下。

遍历这一段与常见的 option 版写法不同，值得细读：

- `traverse_node {A} (t : direction) (l m r : TernaryTree A)` 只做一件事：按方向
  选出三棵子树之一，不需要处理 `TLeaf`。
- `traverse_path {A} (p : path) (t : TernaryTree A)` 直接返回 `TernaryTree` 而
  不是 `option`：先 `match t`——`TLeaf` 上任何路径都停在 `TLeaf`；`TNode` 上空
  路径返回整树 `t`，非空路径递归下潜。路径比树深时自然停在 `TLeaf`，「越界」与
  「到达叶子」合流，性质里就不必再写 option 的三态分支。`tern_mirror` 恰好保持
  `TLeaf` 不变，两边语义兼容。
- `path_mirror := map (...)` 把路径中的 `Left` / `Right` 互换、`Middle` 不动。
  镜像交换了左右子树，所以「镜像树里走翻转路径」恰好对应「原树里走原路径」。

相等判定 `eq_dec_tern_tree` 与 72.1 的 `eq_dec_tree` 完全同款：`#[export]
Instance ... : Dec (t1 = t2)`，证明是 `constructor; dec_eq`，结尾 `Defined`。
`dec_eq` 自动生成逐构造子比较——nat 载荷加三棵子树的递归，不需要手写任何
sumbool 分支，整个开发无公理、可抽取。

`tern_mirror_path_flip` 的性质读法：`traverse_path p t`（原树沿 `p` 下潜的子树）
应当等于 `tern_mirror (traverse_path (path_mirror p) (tern_mirror t))`（先镜像
整树、沿翻转路径下潜、再把结果镜像一次）。末尾 `?` 经 `eq_dec_tern_tree` 实例把
等式命题变成可计算的 bool。`bug_finding_tern_tree` 的两层 `forAllShrink` 分别
负责树和路径：外层生成并收缩树，内层生成并收缩路径，因此失败报告同时含两个值。
执行区一次实测：反例树为 `TNode (0) (TLeaf) (TNode (0) ...) (TNode (1) ...)`，
路径收缩到 `[Middle]`，`Failed after 3 tests and 12 shrinks`——中子树非对称时
`[Middle]` 正好走到未被镜像的子树，使两侧比较失败；其他与 bug 无关的树结构和
路径方向被逐步削去。

修复后 `tern_mirror_fixed` / `tern_mirror_path_flip_fixed` / `tern_tree_fixed_test`
复用同一条测试链，只替换镜像函数与性质，构成回归测试，执行区实测
`+++ Passed 10000 tests`。最后 `genTernTree` 注册 `GenSized`，与已有 `Shrink`、
`Gen path` 一起，让 `QuickChick tern_mirror_path_flip` 也能自动建立两层测试
（执行区一次实测 `[Middle]`、`Failed after 1 tests and 0 shrinks`）。

**坑：** 这个案例有两个常见误判。第一，找到 `[Middle]` 是性质与 shrinker 合作的
结果，不是 shrinker 天生「知道」bug 在哪里。第二，`path_mirror` 若忘记交换
`Left` / `Right`（或下潜方向弄反），性质测的就不再是「镜像」而是某种巧合关系，
可能在部分树上假通过——写路径性质时先把「镜像树里走翻转路径」这层对应关系想
清楚，再交给测试。

## 72.9 `collect`：观察测试数据分布

一万次 `Passed` 可能来自一万个几乎相同的平凡输入。`collect` 不改变性质真假，而是
给每次测试贴上可打印标签，最后按标签汇总，让「测试覆盖到了什么」变得可见。

```coq
(* ---------- 72.9 collect：观察测试数据分布 ---------- *)

Check @collect.
(*
     : forall A prop : Type, Show A -> Checkable prop -> A -> prop -> Checker
   把 show x 作为标签贴到本次测试的结果上，报告按标签聚合计数。
*)

Fixpoint size {A} (t : Tree A) : nat :=
  match t with
  | Leaf => 0
  | Node _ l r => 1 + size l + size r
  end.

Definition treeProp (g : nat -> G nat -> G (Tree nat)) n :=
  forAll (g n (choose (0, n))) (fun t => collect (size t) true).

(* 练习 genTreeSized''（原书 2 星）：让空树更少。思路：只要还有
   燃料（sz >= 1），根部就强制为 Node，空树率降到 0；子树退回
   genTreeSized' 保持形状随机（子树仍可随机终止为 Leaf）。 *)

Fixpoint genTreeSized'' {A} (sz : nat) (g : G A) : G (Tree A) :=
  match sz with
  | O => ret Leaf
  | S sz' =>
      liftM3 Node g (genTreeSized' sz' g) (genTreeSized' sz' g)
  end.
```

`@collect` 的参数依次是标签类型、性质类型、`Show` 与 `Checkable` 实例、标签值、
原性质。`size` 统计节点数：叶为 0，节点为 1 加左右规模。`treeProp` 接收一个二叉树
生成器构造方案 `g` 和尺寸 `n`，生成自然数树；性质恒为 `true`，因此输出差异完全
来自标签 `(size t)`，非常适合单独比较分布。执行区跑了三组（`genTreeSized` /
`genTreeSized'` / `genTreeSized''` 各传 5），QuickChick 2.2 的报告格式是
「次数 : 标签」，例如 `5007 : 0` 表示 5007 个测试点的树规模为 0：

- `oneOf` 在每个非零尺寸等概率选择 `Leaf` 与 `Node`，约一半测试点直接是空树
  （`5007 : 0`），大而深的树很少（`1259 : 1`、`627 : 2`、`472 : 5`……）。
- `freq` 让 `Leaf : Node = 1 : sz`，更偏向继续生长；空树计数降到零头
  （`1657 : 0`），分布向较大尺寸移动（`601 : 12`、`600 : 11`、`580 : 13`……）。
  具体数字随运行变化，重点不是记住某个计数，而是看整体质量集中在哪里。

练习解答 `genTreeSized''`（原书 2 星）换了一个思路：不是在燃料耗尽处强造最小
节点，而是只要还有燃料（`sz >= 1`）就让根部强制为 `Node`——非零分支不再抽签，
直接 `liftM3 Node g ...`；子树退回 `genTreeSized'` 保持形状随机（子树仍可随机
终止为 `Leaf`）。于是 `sz >= 1` 时整树永不为空，空树率降到 0，分布中完全没有
`N : 0` 这一行；`O` 分支仍返回 `Leaf`，但 `treeProp genTreeSized'' 5` 顶层燃料
是 5，根上必为 `Node`。这不是「更好的万能生成器」，而是有意改变测试目标：如果
空树已经由边界测试覆盖，把预算集中到非空树会更有效；如果空树可能触发 bug，则
不能用这个生成器替代全部测试。

**坑：** 分布表证明的是生成器实际产出的样本，不证明性质覆盖所有输入。也不能只看
`Passed` 数量；先问样本是否有区分度。第 73 章还会用 `collect` 观察被丢弃输入，
第 75 章则要求生成器不仅分布合适，还保持类型约束。

## 72.10 五个常用 Checker 组合子

本节组合的是整个 `Checker`，不是生成器：失败时附加说明、把预期失败纳入回归、合取
多条检查、析取多条检查，以及按自定义类别打标签。

```coq
(* ---------- 72.10 五个常用 Checker 组合子 ---------- *)

(* whenFail：失败时打印一条消息（横幅式的自解释）。 *)

Definition whenFailDemo : Checker :=
  whenFail "every color is Red?!" (forAll genColor isRed).

(* expectFailure：预期失败 —— 找到反例反而算通过；
   如果全部通过则以 "*** Failed! Passed N tests (expected Failure)" 报错。 *)

Definition expectFailureDemo : Checker :=
  expectFailure (forAll genColor isRed).

Definition expectFailureAllPass : Checker :=
  expectFailure (forAll genColor (fun _ => true)).

(* conjoin：所有 Checker 都成功才算成功（各自独立生成数据）。 *)

Definition conjoinDemo : Checker :=
  conjoin [ forAll (choose (0, 10)) (fun n => (n <=? 10)%nat) ;
            forAll (choose (0, 10)) (fun n => (n <? 10)%nat) ].

(* disjoin：至少一个成功就算成功（第一个失败后才跑第二个）。 *)

Definition disjoinDemo : Checker :=
  disjoin [ forAll (choose (0, 10)) (fun n => (n <? 0)%nat) ;
            forAll (choose (0, 10)) (fun n => (0 <=? n)%nat) ].

(* tag 与 collect 类似，但标签是手写的字符串而非 show 出来的值；
   适合把数据按"类别"分桶。下面这个例子把 nat 分成三桶：
   等于 3、大于 2、其余。 *)

Definition tag_prop (x : nat) : Checker :=
  collect x (if (x =? 3)%nat then tag "3" false
             else if (2 <? x)%nat then tag "more than 2" false
             else checker true).
```

- `whenFail message c` 给 `c` 注册失败回调。成功时不打印多余横幅；失败时先给出
  「every color is Red?!」，再给出 `Yellow` 等反例。消息应说明规格意图，而不是重复
  一行「测试失败」。
- `expectFailure c` 反转测试的期望：对故意错误的 `isRed` 全称性质，找到反例记作
  `Failed (as expected)`，可用于记录尚未修复的 bug 或演示负例。若换成恒真性质，
  10000 次全通过反而违反「应该失败」的约定，于是整个 checker 报错。
- `conjoin [c1; c2]` 要求所有分支成功。例中 `n <=? 10` 在闭区间生成器上恒真，
  `n <? 10` 会在 `n = 10` 失败，所以合取失败。各分支有自己的生成过程，不是共享
  同一个随机输入。
- `disjoin [c1; c2]` 只需一个分支成功。对自然数而言 `n <? 0` 恒假，`0 <=? n`
  恒真，因此第一个失败后第二个使整体通过。它表达测试层面的析取，不应与逻辑证明中
  的 `or` 自动等同。
- `tag` 使用手写字符串，`collect` 使用值的 `Show` 表示。`tag_prop` 外层仍以 `x`
  收集数值标签，内层在 `x = 3` 时贴 `Tag: 3` 并失败，在 `x > 2` 时贴
  `more than 2` 并失败，其余通过。可见 `collect` 与 `tag` 能叠加：一个描述样本值，
  一个描述人工分类。

注意 `conjoinDemo`、`disjoinDemo`、`tag_prop` 里的 nat 比较逐一加了 `%nat`：文件头
`Local Open Scope string` 打开后，`=?` / `<=?` / `<?` 会优先解析到 string_scope
里的字符串版本（`String.eqb` 等），把 nat 比较当字符串比较直接类型错误；`%nat`
把记号显式锁定回 nat_scope。这是 72.0 埋下的作用域坑在本节兑现。

**坑：** `expectFailure` 不是静默忽略失败，它仍要求输出与「预期失败」一致；已修复
的 bug 若继续包在其中，会从红变绿再变成另一种红。`conjoin` / `disjoin` 也会改变
运行与短路方式，阅读统计时要按组合后的 checker 理解，而不是把各分支输出简单相加。

## 72.11 `Args` 调参与默认参数

到目前为止，10000 次成功、20000 次丢弃、1000 次收缩都不是写死在命令语法里的，
而是 `Args` 记录的默认字段。理解这一层，才能区分「性质失败」「测试预算不足」和
「收缩被截断」。

```coq
(* ---------- 72.11 Args 调参与默认参数 ---------- *)

(* QuickChick 命令背后用的是 Args 记录：
     Record Args := MkArgs
       { replay     : option (RandomSeed * nat)  (* 回放种子与大小 *)
       ; maxSuccess : nat                        (* 目标成功数 *)
       ; maxDiscard : nat                        (* 允许放弃数 *)
       ; maxShrinks : nat                        (* 最大收缩步数 *)
       ; maxSize    : nat                        (* 尺寸上限 *)
       ; chatty     : bool                       (* 是否打印进度 *)
       ; analysis   : bool                       (* 2.2 新增：分布分析 *)
       }.
   默认值由四个可提取常量给出：
     Axiom defNumTests    : nat. Extract Constant defNumTests    => "10000".
     Axiom defNumDiscards : nat. Extract Constant defNumDiscards => "20000".
     Axiom defNumShrinks  : nat. Extract Constant defNumShrinks  => "1000".
     Axiom defSize        : nat. Extract Constant defSize        => "10".
   想全局改默认值，就在导入 QuickChick 之后、任何 QuickChick 命令之前
   写下自己的 Extract Constant（例如把 defNumTests 改成 100）。 *)

Check stdArgs.
(*
     : Args
   stdArgs = MkArgs None defNumTests defNumDiscards defNumShrinks
                     defSize true doAnalysis（doAnalysis 默认 false）。 *)

(* 单次调参用 QuickChickWith（见 73 章）：
   QuickChickWith (updMaxSuccess stdArgs 100) myProp.
   updMaxSize / updMaxSuccess / updAnalysis 三个更新函数可用。 *)

End Ex72Checkers.
```

逐字段读：`replay` 可指定随机种子与尺寸以复现运行；`maxSuccess` 是目标有效通过数；
`maxDiscard` 是允许放弃的测试点数；`maxShrinks` 限制一次反例收缩的步数；`maxSize`
限制生成尺寸；`chatty` 控制进度输出；`analysis` 是 QuickChick 2.2 的分布分析开关。
`stdArgs` 用 `None` 表示不指定回放，其余位置依次接四个默认常量和进度、分析选项。

四个 `def*` 在 Rocq 侧以 `Axiom` 声明，是因为实际数值由抽取后的 OCaml 常量提供：
`Extract Constant ... => "10000"` 等指令把名字映射为对应整数值。要**全局**修改默认
值，应在导入 QuickChick 后、执行任何测试命令前写自己的提取映射；要**单次**修改，
则优先用 `QuickChickWith` 与记录更新函数。示例特别列出 `updMaxSize`、
`updMaxSuccess`、`updAnalysis`，例如把一次运行改为最多 100 个成功测试点。第 73 章
会在 discard 风暴中实际使用 `QuickChickWith`，并说明没有现成 `updMaxDiscard` 时
怎样构造完整记录。

**坑：** 增大 `maxSuccess` 只增加样本量，不改善生成分布，更不产生证明；增大
`maxDiscard` 可能掩盖稀疏前提造成的浪费；`maxShrinks` 太小会让报告停在「较小但
尚未局部极小」的反例。参数调整应与 72.9 的分布观察、72.7 的收缩语义一起解读。

## 72.12 测试执行区：命令为何在模块外

`End Ex72Checkers.` 之后是整章唯一的运行区。所有 `QuickChick` / `Sample` 命令都
放在这里，每条命令配上一次实测输出的注释——这也是第 69 章 69.5 节的做法。

```coq
(* 测试命令统一放在模块外：QuickChick / Sample 经 OCaml 抽取执行，
   而抽取在 Module 内通常不工作（原书在 CheckerPlayground1 结尾
   专门注明了这一点），会报 Unbound value quickchick。命令放到
   模块外、引用模块内容则一切正常。

   但游乐场的 Sample 仍然只能保持注释（与原书一致）：Sample 命令
   只认库里的 Show / 生成器体系，对游乐场自定义的 Checker /
   Checkable 抽取时会触发 Rocq 编译器异常（evar in typeops）——
   教学玩具就停留在"读"的层面，真跑测试用下面的库版命令。 *)

Import Ex72Checkers.

(* 游乐场 1：随机种子不影响常生成器，(checker true) 每次都打印
   11 个 Success，(checker false) 每次都打印 11 个 Failure。 *)
(* Sample (CheckerPlayground1.checker true). *)
(* 形如：
   [Success, Success, Success, Success, Success, Success, Success,
    Success, Success, Success, Success] *)
(* Sample (CheckerPlayground1.checker false). *)
(* 形如：
   [Failure, Failure, Failure, Failure, Failure, Failure, Failure,
    Failure, Failure, Failure, Failure] *)

(* 游乐场 2：两个"猜想"的可判定检查。 *)
(* Sample (CheckerPlayground2.checker CheckerPlayground2.c1). *)
(* 形如：11 个 Failure *)
(* Sample (CheckerPlayground2.checker CheckerPlayground2.c2). *)
(* 形如：11 个 Success *)

(* 游乐场 3：forAll 把生成器与性质粘在一起。 *)
(* Sample (CheckerPlayground3.forAll genColor isRed). *)
(* 形如（红黄蓝绿等概率出现，isRed 只在 Red 上为真）：
   [Failure, Failure, Failure, Failure, Failure, Success, Failure,
    Failure, Success, Failure, Failure] *)

(* Sample (CheckerPlayground3.forAll (genTreeSized 3 (choose (0, 3))) mirrorP). *)
(* 形如：11 个 Success（镜像两次必复原） *)

(* Sample (CheckerPlayground3.forAll (genTreeSized 3 (choose (0, 3))) faultyMirrorP). *)
(* 形如（Success 与 Failure 混杂，只有对称树通过）：
   [Success, Failure, Success, Failure, Success, Failure, Success,
    Success, Success, Success, Failure] *)

(* 游乐场 4：失败携带反例本身。 *)
(* Sample (CheckerPlayground4.forAll genColor isRed). *)
(* 形如：失败项里直接带着反例颜色
   [Failure: (Blue, tt), Failure: (Yellow, tt), Success, …] *)

(* Sample (CheckerPlayground4.forAll (genTreeSized 3 (choose (0, 3))) faultyMirrorP). *)
(* 形如（反例树被打印出来）：
   [Failure: (Node (2) (Node (3) (Node (2) (Leaf) (Leaf)) (Leaf))
                    (Node (0) (Node (2) (Leaf) (Leaf)) (Leaf)), tt),
    Success, …] *)

(* 库版命令。 *)
QuickChick treesMirrorP.
(* 形如：
   +++ Passed 10000 tests (0 discards) *)

QuickChick faultyForAllP.
(* 形如（不做收缩时反例可能很大，一次实测）：
   Node (2) (Node (3) (Leaf) (Node (2) (Leaf) (Leaf))) (Node (3) (Leaf) (Node (0) (Leaf) (Leaf)))
   *** Failed after 3 tests and 0 shrinks. (0 discards) *)

QuickChick giveUpP.
(* 形如：
   *** Gave up! Passed only 0 tests
   Discarded: 20000 *)

QuickChick faultyShrinkP.
(* 形如（一次实测）：
   Node (0) (Leaf) (Node (0) (Leaf) (Leaf))
   *** Failed after 1 tests and 5 shrinks. (0 discards)
   5 步收缩把一棵大树砍成最小的非对称树。 *)

QuickChick faultyMirrorP.
(* 形如（一次实测，Automatic 实例链自动走生成+收缩）：
   Node (0) (Leaf) (Node (0) (Leaf) (Leaf))
   *** Failed after 1 tests and 3 shrinks. (0 discards) *)

Sample (@genTernTreeSized nat 3 (choose (0, 10))).
(* 形如：11 棵随机三叉树，深度受 sz=3 限制 *)

QuickChick bug_finding_tern_tree.
(* 形如（一次实测）：
   TNode (0) (TLeaf) (TNode (0) (TLeaf) (TLeaf) (TNode (3) (TLeaf) (TLeaf) (TLeaf))) (TNode (1) (TLeaf) (TLeaf) (TLeaf))
   [Middle]
   *** Failed after 3 tests and 12 shrinks. (0 discards)
   路径 [Middle] 把测试引到中子树，而 tern_mirror 没有镜像它，
   两边的子树不再对应。 *)

QuickChick tern_tree_fixed_test.
(* 形如：
   +++ Passed 10000 tests (0 discards) *)

QuickChick tern_mirror_path_flip.
(* 形如（一次实测；实例链自动生成树与路径）：
   TNode (0) (TLeaf) (TNode (3) (TLeaf) (TLeaf) (TNode (0) (TLeaf) (TLeaf) (TLeaf))) (TNode (3) (TLeaf) (TNode (0) (TLeaf) (TLeaf) (TLeaf)) (TNode (2) (TLeaf) (TLeaf) (TLeaf)))
   [Middle]
   *** Failed after 1 tests and 0 shrinks. (0 discards) *)

QuickChick (treeProp genTreeSized 5).
(* 形如（QuickChick 2.2 的 collect 报告格式是"次数 : 标签"；
   oneOf 各半，约一半测试点直接是 Leaf，一次实测）：
   5007 : 0
   1259 : 1
    627 : 2
    472 : 5
    ……
   +++ Passed 10000 tests (0 discards) *)

QuickChick (treeProp genTreeSized' 5).
(* 形如（freq 偏向 Node，空树从约一半降到零头，一次实测）：
   1657 : 0
    601 : 12
    600 : 11
    580 : 13
    ……
   +++ Passed 10000 tests (0 discards) *)

QuickChick (treeProp genTreeSized'' 5).
(* 形如：分布中完全没有 "N : 0" 这一行（空树率 0）
   +++ Passed 10000 tests (0 discards) *)

QuickChick whenFailDemo.
(* 形如（一次实测）：
   every color is Red?!
   Yellow
   *** Failed after 1 tests and 0 shrinks. (0 discards) *)

QuickChick expectFailureDemo.
(* 形如：
   +++ Failed (as expected) after 1 tests and 0 shrinks. (0 discards) *)

QuickChick expectFailureAllPass.
(* 形如：
   *** Failed! Passed 10000 tests (expected Failure) *)

QuickChick conjoinDemo.
(* 形如：第一个恒真、第二个在 n=10 处失败
   *** Failed after … tests …
   10 *)

QuickChick disjoinDemo.
(* 形如：
   +++ Passed … *)

QuickChick tag_prop.
(* 形如（一次实测；tag 的分布行带 Tag 前缀）：
   4
   4 : 0
   1 : 2
   Tag: more than 2
   *** Failed after 6 tests and 0 shrinks. (0 discards) *)
```

执行区开头的大段注释交代两条规则。其一，命令为何在模块外：`QuickChick` /
`Sample` 经 OCaml 抽取执行，而抽取在 `Module` 内通常不工作（原书在
CheckerPlayground1 结尾专门注明了这一点），会报 `Unbound value quickchick`；放到
`End Ex72Checkers.` 之后、`Import Ex72Checkers.` 再逐条激活，则一切正常。其二，
游乐场的 8 条 `Sample` 为何保持注释：`Sample` 只认库里的 `Show` / 生成器体系，对
游乐场自定义的 `Checker` / `Checkable` 抽取时会触发 Rocq 编译器异常（evar in
typeops）——教学玩具停留在「读」的层面，注释里保留了预期输出：11 个 `Success` /
11 个 `Failure`、红黄蓝绿等概率下 `isRed` 的成败混杂、镜像两次必复原、第四间的
`Failure: (Blue, tt)` 与带反例树的 `Failure: (Node (2) ..., tt)`。

真跑测试的是后面的库版命令，按主题顺序对应各节：

- 72.6 的三条：`treesMirrorP` 通过 10000；`faultyForAllP` 不收缩，反例很大
  （`Node (2) ...`，3 次测试 0 步收缩）；`giveUpP` 全部放弃，
  `Gave up! Passed only 0 tests / Discarded: 20000`。
- 72.7 的两条：`faultyShrinkP` 手写 `forAllShrink`，5 步收缩砍出最小非对称树
  `Node (0) (Leaf) (Node (0) (Leaf) (Leaf))`；`faultyMirrorP` 裸性质交给
  `QuickChick`，Automatic 实例链自动走生成 + 收缩，同一反例 3 步到位——两条路
  殊途同归。
- 72.8 的四条：`Sample (@genTernTreeSized nat 3 ...)` 打印 11 棵随机三叉树；
  `bug_finding_tern_tree` 给出反例树 + 路径 `[Middle]`（3 次测试 12 步收缩）；
  `tern_tree_fixed_test` 回归通过；`tern_mirror_path_flip` 裸性质走自动实例链，
  同样收敛到 `[Middle]`。
- 72.9 的三条分布：`oneOf` 版 `5007 : 0`（约一半空树）、`freq` 版 `1657 : 0`
  （空树降到零头）、`genTreeSized''` 版没有 `N : 0` 行（空树率 0）。
- 72.10 的五条：`whenFailDemo` 先打横幅再给反例 `Yellow`；`expectFailureDemo`
  `Failed (as expected)`；`expectFailureAllPass` 反向报错；`conjoinDemo` 在
  `n = 10` 处失败并打印 `10`；`disjoinDemo` 通过；`tag_prop` 报告
  `4 / 4 : 0 / 1 : 2 / Tag: more than 2`，6 次测试找到失败。

最后重申第 69 章的版本事项：`QuickChick` 找到反例不会改变编译退出码，因此「rocq
编译退出码 0」只证明示例可编译、抽取与运行流程可执行，**不表示所有故意失败的演示
都通过**。阅读实际输出时仍要逐条区分 `Passed`、预期失败、真实反例与 `Gave up`。

至此，第 69 章的「运行性质」、第 70 章的「实例解析」、第 71 章的「生成数据」和
本章的「检查与收缩」已经闭环。第 73 章处理条件性质与生成预算，第 74 章自动化重复
实例，第 75 章把这些机制放进带类型程序生成；后续若要验证测试套件本身是否足够灵敏，
还可继续做变异测试。
