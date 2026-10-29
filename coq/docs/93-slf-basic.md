# 93 · 分离逻辑入门：三元组与 x-tactics

对应示例：`../examples/93_slf_basic.v`（rocq 9.1.1 + SLF 库实测编译退出码 0）

从本章起进入**分离逻辑篇**（93–105 章），取材 Software Foundations 第六卷
《Separation Logic Foundations》（Charguéraud，v1.0，2026，MIT 许可；原书按
Rocq 9.0 编写，本篇在 rocq 9.1.1 上实测编译，全部内容自包含，无需翻阅原书）。
此前 58–60 章的 Hoare 逻辑用 `{{P}} c {{Q}}` 描述**整个内存状态**；分离逻辑
（Separation Logic，SL）的核心变化只有一个：前后条件只描述**执行所需的那一小
块内存**，并用一个「分离合取」算子 `\*` 声明两块内存**互不相交**。这一个变化带
来了程序验证的模块化革命——著名的**框架规则**：

```text
      { H } t { Q }
 -------------------------
  { H \* H' } t { Q \* H' }
```

只要 `t` 在资源 `H` 下正确，那么在「`H` 再加上任意一块不相关内存 `H'`」的状态
下依然正确，且 `H'` 原封不动。这条规则让「验证过的函数」可以自由组合——这正是
60 章的 Imp 验证里最痛苦的事。

本篇的路线与原书一致，分三个视角：

- **93–94 章（用户视角）**：直接用一个现成的 SL 框架（x-tactics）验证小程序，
  先建立「写规格、跑证明」的手感；
- **95–102 章（实现者视角）**：从零重造这套框架——堆谓词、蕴含、三元组、推理
  规则、魔杖、最弱前置条件及其生成器与可靠性；
- **103–105 章（扩展）**：仿射谓词与垃圾回收、数组、记录。

本章是第一课：如何读一个 SL 规格（`triple t H Q`），如何用 `xwp / xapp /
xsimpl` 三板斧把验证做成「符号执行」，以及别名、分配、释放、非确定性、递归函
数各需要什么新招。

### 93.0 环境、语言与文件头

SLF 库已随教程收在 `lib/slf/`（35 个文件，MIT 许可，LICENSE 同目录）。
`build.sh` 提供 `@slf` 标志集：首次编译本章示例时会自动把库按依赖序编译到
`build/slf`（一次性，约一两分钟），之后所有章节复用。示例文件通过一行
`@slf` 的 `.flags` 文件启用：

```text
examples/93_slf_basic.v.flags 内容：
@slf
```

被验证的语言是一个「带引用的 λ 演算」最小核心（OCaml 风格）：`!p` 读引用、
`p := v` 写引用、`ref v` 分配、`free p` 释放、`val_rand n` 掷骰子。程序不是
OCaml 代码，而是写在 `<{ ... }>` 记号里的**抽象语法树**，变量一律带单引号前
缀（`'p`），与 Rocq 自身变量区分开。为了简化元理论，程序都写成 **A-范
式**（A-normal form）：每个中间结果都必须用 `let` 命名。

文件头三行与原书一致：

```coq
(* 93 分离逻辑入门 —— triple/H/Q 三元组、x-tactics、分离合取与框架性质、递归函数 *)
(* 取材 Software Foundations 卷六 Separation Logic Foundations 的 Basic 章， *)

Set Implicit Arguments.
From SLF Require Import LibSepReference.
Import ProgramSyntax DemoPrograms.

Implicit Types n m : int.
Implicit Types p q : loc.
```

`LibSepReference` 是「参考实现」——整套框架的门面：语言语法、`triple` 定义、
x-tactics、还有一批演示程序（`DemoPrograms`）。95 章起我们会亲手重造其中大部
分。`Implicit Types` 两行**不可省**：它们告诉 Rocq「没写类型的 `n`/`m` 是
`int`、`p`/`q` 是 `loc`」。实测教训：漏掉它们时，`forall n, ...` 里的 `n` 会
被解析成程序项类型 `trm`，然后在完全不相干的地方报「`n` 应当是 `int`」——这
是本篇最容易踩的第一个坑。

下面按示例文件的分节顺序讲解。

### 93.1 第一个函数：incr 与它的规格

第一个程序：把引用单元格 `p` 的内容加一。OCaml 里就是
`let incr p = let n = !p in let m = n + 1 in p := m`。在 SLF 语法里：

```coq
(* ---------- 93.1 第一个函数：incr 与它的规格 ---------- *)

Definition incr : val :=
  <{ fun 'p =>
       let 'n = !'p in
       let 'm = 'n + 1 in
       'p := 'm }>.
```

`incr` 的类型是 `val`——「程序值」。函数是程序值，参数 `'p` 也是程序值；整数
`n+1` 通过强制转换塞进 `val`。规格是一个 **SL 三元组** `triple t H Q`：

```coq
Lemma triple_incr : forall (p:loc) (n:int),
  triple <{ incr p }>
    (p ~~> n)
    (fun _ => (p ~~> (n+1))).
Proof.
  xwp. xapp. xapp. xapp. xsimpl.
Qed.

#[global] Hint Resolve triple_incr : triple.
```

逐项读这条规格：

- `p : loc` 是**位置**（location）——单元格的地址；`n : int` 是「幽灵变量」，
  只存在于规格里，用来描述执行前单元格的内容；
- 前条件 `p ~~> n` 读作「`p` 处有一个单元格，内容是 `n`」——**只描述这一格**，
  内存里还有什么一概不管；
- 后条件 `fun _ => p ~~> (n+1)`：函数返回 unit（所以结果值用 `_` 忽略），执行
  后 `p` 的内容变成 `n+1`。注意 `(n+1)` 的括号不能省——`p ~~> n+1` 会被解析成
  `(p ~~> n) + 1`。

一般规格的模板是：量化函数参数 → 量化描述初态的幽灵变量 → `triple` 应用
→ 前条件 → 后条件 `fun r => H'`（`r` 命名返回值）。

证明只有一行，但每个 tactic 都值得记住——它们是全篇通用的「x-tactics」：

- `xwp`：启动验证，把目标变成 `PRE H CODE F POST Q` 的形式。`CODE` 部分就是
  函数体的内部表示（去掉引号、变量改名后几乎就是源码）。此后**不要**通读整个
  证明义务，只看 `PRE`（当前状态）和 `CODE` 的第一行（下一步操作）；
- `xapp`：对当前第一个操作做符号执行——依次处理 `!p`（读出 `n`）、`n+1`（算
  出 `n+1`）、`p := m`（状态更新为 `p ~~> (n+1)`）。每个 `let` 与每个运算各对
  应一次 `xapp`；
- `xsimpl`：最后剩下一个**蕴含**义务 `H1 ==> H2`（当前状态是否匹配声明的后条
  件），`xsimpl` 自动消解。

`#[global] Hint Resolve triple_incr : triple.` 把这条规格登记进名为 `triple`
的 hint 数据库：以后任何程序调用 `incr p`，`xapp` 会自动引用这条规格——和 61
章的 hint 数据库是同一机制，但这里数据库是 x-tactics 专用的。

程序调用其实可以不写 `<{ incr p }>`：

```coq
(* 借助强制转换（coercion），程序调用可以直接写成 incr p 而不必写 <{ incr p }>。 *)

Lemma triple_incr' : forall (p:loc) (n:int),
  triple (incr p)
    (p ~~> n)
    (fun _ => (p ~~> (n+1))).
Proof.
  xwp. xapp. xapp. xapp. xsimpl.
Qed.
```

Rocq 的强制转换机制看到「程序值 `incr` 应用到参数」会自动插入「函数调用」解
释（52 章讲过 coercion；这里的细节在 98 章实现 `triple` 时再拆）。这让规格读
起来像普通函数调用，代价是偶尔要 `Set Printing Coercions.` 才能看清真身。

### 93.2 纯计算：空堆谓词与纯事实

第二个程序完全不碰内存，只做算术：

```coq
(* ---------- 93.2 纯计算：空堆谓词 \[] 与纯事实 \[P] ---------- *)

Definition example_let : val :=
  <{ fun 'n =>
      let 'a = 'n + 1 in
      let 'b = 'n - 1 in
      'a + 'b }>.

Lemma triple_example_let : forall (n:int),
  triple (example_let n)
    \[]
    (fun r => \[r = 2*n]).
Proof.
  xwp. xapp. xapp. xapp. xsimpl. math.
Qed.
```

两个新记号：

- `\[]` 是**空堆谓词**：描述「空的一块内存」。作为前条件，它说「本函数不需要
  任何资源」——注意不是「整个内存为空」！之前分配的数据可以一直在，只是函数
  不去碰；
- `\[P]` 是**纯事实谓词**：空内存加上命题 `P` 成立。后条件
  `fun r => \[r = 2*n]` 说「返回值 `r` 等于 `2*n`，且不留任何资源」。

证明里 `xapp` 三次对应 `n+1`、`n-1`、`a+b` 三个运算；最后 `xsimpl` 把状态义务
清掉，剩一个纯算术目标 `(n+1)+(n-1) = 2*n`，交给 TLC 的 `math`（它就是 `lia`
的封装，但适配 TLC 自己的整数定义；本篇所有算术义务都用它）。

**练习（1 星）triple_quadruple**：`quadruple n` 返回 `4*n`。这是
`example_let` 的翻版，注意 `let` 只有一个，所以加上返回表达式一共**两次**
`xapp`：

```coq
(* 练习：quadruple n 返回 4*n。 *)

Definition quadruple : val :=
  <{ fun 'n =>
       let 'm = 'n + 'n in
       'm + 'm }>.

Lemma triple_quadruple : forall (n:int),
  triple (quadruple n)
    \[]
    (fun r => \[r = 4*n]).
Proof.
  xwp. xapp. xapp. xsimpl. math.
Qed.
```

**练习（2 星）triple_inplace_double**：就地把单元格翻倍——`incr` 的模板加上
`math` 收尾（因为 `xsimpl` 留下的是 `n+n = 2*n`）：

```coq
(* 练习：inplace_double 就地把引用内容翻倍。 *)

Definition inplace_double : val :=
  <{ fun 'p =>
       let 'n = !'p in
       let 'm = 'n + 'n in
       'p := 'm }>.

Lemma triple_inplace_double : forall (p:loc) (n:int),
  triple (inplace_double p)
    (p ~~> n)
    (fun _ => p ~~> (2*n)).
Proof.
  xwp. xapp. xapp. xapp. xsimpl. math.
Qed.
```

### 93.3 分离合取：incr_two

分离逻辑的招牌算子登场。`incr_two p q` 把两个单元格各加一：

```coq
(* ---------- 93.3 分离合取 \* 与 incr_two ---------- *)

Definition incr_two : val :=
  <{ fun 'p 'q =>
       incr 'p;
       incr 'q }>.

Lemma triple_incr_two : forall (p q:loc) (n m:int),
  triple (incr_two p q)
    (p ~~> n \* q ~~> m)
    (fun _ => p ~~> (n+1) \* q ~~> (m+1)).
Proof using.
  xwp. xapp. xapp. xsimpl.
Qed.

#[global] Hint Resolve triple_incr_two : triple.
```

前条件 `p ~~> n \* q ~~> m` 中的 `\*` 是**分离合取**（separating conjunction，
星号）：它描述的内存可以**切成不相交的两块**，一块满足 `p ~~> n`，另一块满足
`q ~~> m`。「不相交」意味着 `p` 和 `q` 必须是**不同的地址**——星号在描述资源的
同时顺手表达了「无别名」约束，这是 SL 一石二鸟的地方。

证明只有两个 `xapp`（两次 `incr` 调用，规格从 hint 数据库自动取），`xsimpl`
最后核对两块资源都各加一。`Proof using.` 是原书风格（配合 `-vos` 并行编译），
与 `Proof.` 等价。

### 93.4 别名参数：当两个参数是同一个单元格

`triple_incr_two` 只覆盖 `p ≠ q` 的调用。若写 `incr_two p p` 会怎样？

```coq
(* ---------- 93.4 别名参数：incr_two p p ---------- *)

Definition aliased_call : val :=
  <{ fun 'p =>
       incr_two 'p 'p }>.

(* 用 triple_incr_two 去推 aliased_call 会卡住： Preconditions 要求 p ~~> ?n \* p ~~> ?m，
   而手里只有一份 p ~~> n。这个不可证的义务 (\[] ==> p ~~> ?m \* _) 正是分离合取
   「两块不相交」约束的直接体现。 *)

Lemma triple_aliased_call_attempt : forall (p:loc) (n:int),
  triple (aliased_call p)
    (p ~~> n)
    (fun _ => p ~~> (n+2)).
Proof using.
  xwp. xapp.
Abort.
```

`Abort` 的演示值得亲手做一遍：`xapp` 想套用 `triple_incr_two`（`q := p`），
需要前条件 `p ~~> ?n \* p ~~> ?m`；`xsimpl` 的内置化简能消掉一份 `p ~~> n`，
但剩下的义务 `\[] ==> p ~~> ?m \* _` 不可证——你不可能从空内存里凭空变出一个
单元格。这正是星号「不相交」语义的直接后果：一个单元格不能同时属于两块。

对这么简单的函数，最省事的做法是**为别名情形另证一条规格**：

```coq
(* 解决办法之一：为别名情形单独证一条规格。 *)

Lemma triple_incr_two_aliased : forall (p:loc) (n:int),
  triple (incr_two p p)
    (p ~~> n)
    (fun _ => p ~~> (n+2)).
Proof using.
  xwp. xapp. xapp. xsimpl. math.
Qed.

Lemma triple_aliased_call : forall (p:loc) (n:int),
  triple (aliased_call p)
    (p ~~> n)
    (fun _ => p ~~> (n+2)).
Proof using.
  xwp. xapp triple_incr_two_aliased. xsimpl.
Qed.
```

`triple_incr_two_aliased` 的前条件只有**一份** `p ~~> n`，两次 `xapp`（各自
消费又归还这份资源）加上最后的 `math`（`n+1+1 = n+2`）即得。外层证明则演示
了**手动指定规格**的写法：`xapp triple_incr_two_aliased` 明确告诉 `xapp` 不用
数据库里的 `triple_incr_two`，改用这条别名版。（更高级的统一规格技术要用到
99 章的魔杖，此略。）

### 93.5 框架性质初见：未被触碰的资源

```coq
(* ---------- 93.5 框架性质初见：未被触碰的资源 ---------- *)

Definition incr_first : val :=
  <{ fun 'p 'q =>
       incr 'p }>.

Lemma triple_incr_first : forall (p q:loc) (n m:int),
  triple (incr_first p q)
    (p ~~> n \* q ~~> m)
    (fun _ => p ~~> (n+1) \* q ~~> m).
Proof using.
  xwp. xapp. xsimpl.
Qed.

Lemma triple_incr_first' : forall (p q:loc) (n:int),
  triple (incr_first p q)
    (p ~~> n)
    (fun _ => p ~~> (n+1)).
Proof using.
  xwp. xapp. xsimpl.
Qed.

(* 提到两个引用的规格可以从只提一个的规格推出来：这就是框架规则的力量。 *)

Lemma triple_incr_first_derived : forall (p q:loc) (n m:int),
  triple (incr_first p q)
    (p ~~> n \* q ~~> m)
    (fun _ => p ~~> (n+1) \* q ~~> m).
Proof using.
  intros. xapp triple_incr_first'. xsimpl.
Qed.
```

`incr_first` 收两个引用但只动第一个。于是同一个行为有两条规格：提到 `q` 的
`triple_incr_first`，和完全不提 `q` 的 `triple_incr_first'`。妙处在于前者可以
从后者**推导**出来——`xapp triple_incr_first'` 之后 `xsimpl` 自动补上 `q ~~> m`
那块：这正是框架规则的实例（给前后条件同时添上同一块资源，规格依然成立）。
「少即是多」：**规格只声明用到的资源**，没提到的资源由框架规则兜底——这是写
SL 规格的基本功。

### 93.6 练习：transfer

```coq
(* ---------- 93.6 练习：transfer ---------- *)

Definition transfer : val :=
  <{ fun 'p 'q =>
       let 'n = !'p in
       let 'm = !'q in
       let 's = 'n + 'm in
       'p := 's;
       'q := 0 }>.

Lemma triple_transfer : forall (p q:loc) (n m:int),
  triple (transfer p q)
    (p ~~> n \* q ~~> m)
    (fun _ => p ~~> (n+m) \* q ~~> 0).
Proof using.
  xwp. xapp. xapp. xapp. xapp. xapp. xsimpl.
Qed.

Lemma triple_transfer_aliased : forall (p:loc) (n:int),
  triple (transfer p p)
    (p ~~> n)
    (fun _ => p ~~> 0).
Proof using.
  xwp. xapp. xapp. xapp. xapp. xapp. xsimpl.
Qed.
```

**练习（各 1 星）**：`transfer p q` 把 `q` 的余额「转账」给 `p` 并清零 `q`。
五个操作（两读、一加、两写）各对应一次 `xapp`，`xsimpl` 收尾。

别名版 `transfer p p` 是个好谜题：两读都读到 `n`，`s = 2n` 存进 `p`，然后
`q := 0` 把**同一个**单元格清零——中间结果 `2n` 被抹掉，最终状态是
`p ~~> 0`。规格里写 `2*n` 反而是错的。证明脚本与普通版**完全相同**：符号执行
自动处理了「同一单元格被写两次」，因为状态里始终只有一份 `p ~~> _`。

### 93.7 分配：ref 与 funloc 记号

分配的原语规格**不能在本章证明**（它依赖语言的语义，98 章才动手），所以先用
`Parameter` 公理化——`Parameter` 声明一个命题而不给证明，语义上就是公理：

```coq
(* ---------- 93.7 分配：ref 与 funloc 记号 ---------- *)

Parameter triple_ref : forall (v:val),
  triple <{ ref v }>
    \[]
    (fun r => \exists p, \[r = val_loc p] \* p ~~> v).
```

读懂这条规格：

- 前条件 `\[]`：空状态即可分配（不管内存里已有什么）；
- 后条件说：返回值 `r` 是**某个**位置 `p`（`val_loc` 把 `loc` 注入 `val`，这
  个存在量化是必需的——分配之前没人知道新地址是什么），且 `p` 处新建了一个内
  容为 `v` 的单元格。

「返回一个位置」太常用，SLF 给它起了记号：

```coq
Notation "'funloc' p '=>' H" :=
  (fun (r:val) => \exists p, \[r = val_loc p] \* H)
  (at level 200, p name, format "'funloc'  p  '=>'  H").

Parameter triple_ref' : forall (v:val),
  triple <{ ref v }>
    \[]
    (funloc p => p ~~> v).
```

`funloc p => H` 就是 `fun r => \exists p, \[r = val_loc p] \* H` 的缩写。用
它写一个「读取 `p`、分配一个更大的」函数：

```coq
Definition ref_greater : val :=
  <{ fun 'p =>
       let 'n = !'p in
       let 'm = 'n + 1 in
       ref 'm }>.

Lemma triple_ref_greater : forall (p:loc) (n:int),
  triple (ref_greater p)
    (p ~~> n)
    (funloc q => p ~~> n \* q ~~> (n+1)).
Proof using.
  xwp. xapp. xapp. xapp. intros q. xsimpl. auto.
Qed.
```

注意后条件里 `p ~~> n \* q ~~> (n+1)`：调用者原有的 `p` 完好归还，新单元 `q`
另立门户——星号同时告诉你 `q ≠ p`。证明里 `intros q` 引入 `funloc` 的存在变
量，`auto` 处理 `q = q` 的琐碎匹配。

**练习（2 星）triple_ref_greater_abstract**：写一条更抽象的规格——不透露 `q`
的内容，只说它比 `n` 大：

```coq
(* 练习：抽象规格——不透露新单元的内容，只说它比 n 大。 *)

Lemma triple_ref_greater_abstract : forall (p:loc) (n:int),
  triple (ref_greater p)
    (p ~~> n)
    (funloc q => p ~~> n \* \exists (m:int), \[m > n] \* q ~~> m).
Proof using.
  intros. xapp triple_ref_greater. intros q. xsimpl. auto. math.
Qed.
```

套路是 93.5 的「从具体规格推抽象规格」：`xapp triple_ref_greater` 借用具体版
（见证 `m := n+1`），`xsimpl` 自动用 `q ~~> (n+1)` 与 `q ~~> ?m` 统一，最后
`auto` 关掉 `q = q`、`math` 关掉 `n+1 > n`。实测提示：`xsimpl` 之后可能还剩
**两个**小目标（一个 loc 相等、一个算术），`auto` 和 `math` 各管一个。

框架规则还能给分配规格「加旧资源」：

```coq
(* 框架规则给 ref 规格加一块既有状态后仍然成立——这间接说明了
   「新分配的单元与既有单元互不相同」这一关键事实。 *)

Parameter triple_ref_with_frame : forall (p':loc) (v':val) (v:val),
  triple <{ ref v }>
    (p' ~~> v')
    (funloc p => p ~~> v \* p' ~~> v').
```

这条参数化的事实说：在已有 `p' ~~> v'` 的状态下分配，得到的新单元 `p` 与 `p'`
**必然不同**（否则星号不成立）。分配新鲜性（freshness）——SL 出现之前程序验
证最难写的性质之一——在这里是框架规则的免费赠品。

### 93.8 释放：free 与 xval

OCaml 有垃圾回收，没有 `free`；但最小 SL 要求**每一块分配的资源都要归还**，
于是 SLF 的语言里配了一个 `free`。先看没有它会怎样：

```coq
(* ---------- 93.8 释放：free 与 xval ---------- *)

Definition succ_using_incr_attempt :=
  <{ fun 'n =>
       let 'p = ref 'n in
       incr 'p;
       ! 'p }>.

(* 后条件不提内部引用 p 就证不下去：卡在 p ~~> (n+1) ==> \[]。 *)

Lemma triple_succ_using_incr_attempt : forall (n:int),
  triple (succ_using_incr_attempt n)
    \[]
    (fun r => \[r = n+1]).
Proof using.
  xwp. xapp. intros p. xapp. xapp. xsimpl. { auto. }
Abort.
```

函数用内部引用算 `n+1`，想装作什么都没分配——证不下去：最后 `xsimpl` 面临
`p ~~> (n+1) ==> \[]`，一块非空内存蕴含空内存，不可证（`Abort` 之前那个
`{ auto. }` 关掉的是别的琐碎目标，卡住的是这个蕴含）。三条出路：

**出路一**：后条件坦白「会漏一个单元格」：

```coq
Lemma triple_succ_using_incr_attempt' : forall (n:int),
  triple (succ_using_incr_attempt n)
    \[]
    (fun r => \[r = n+1] \* \exists p, (p ~~> (n+1))).
Proof using.
  xwp. xapp. intros p. xapp. xapp. xsimpl. { auto. }
Qed.
```

可证，但很糟：调用者被塞了一块 `\exists p, p ~~> _` 的「垃圾」，而且永远扔不
掉（在最小 SL 里）。

**出路二**：代码里显式 `free`：

```coq
Definition succ_using_incr :=
  <{ fun 'n =>
       let 'p = ref 'n in
       incr 'p;
       let 'x = !'p in
       free 'p;
       'x }>.

Lemma triple_succ_using_incr : forall n,
  triple (succ_using_incr n)
    \[]
    (fun r => \[r = n+1]).
Proof using.
  xwp. xapp. intros p. xapp. xapp.
  xapp. (* 推理 free p：消费掉堆谓词 p ~~> _ *)
  xval. (* 推理返回值 'x *)
  xsimpl. auto.
Qed.
```

`free p` 的 `xapp` **消费**掉 `p ~~> _`（单元格消失了，资源账目平衡）；最后
的 `xval` 处理「返回一个值」：它把目标变成 `H ==> Q v`，即「当前状态匹配返回
值 `v` 的后条件」。

**出路三**：改造逻辑本身，允许丢弃某些谓词——这就是 103 章的仿射 SL，专为带
GC 的语言准备。本章先用出路二。

**练习（2 星）triple_get_and_free**：

```coq
(* 练习：get_and_free 读出内容并释放单元。 *)

Definition get_and_free : val :=
  <{ fun 'p =>
      let 'v = ! 'p in
      free 'p;
      'v }>.

Lemma triple_get_and_free : forall p v,
  triple (get_and_free p)
    (p ~~> v)
    (fun r => \[r = v]).
Proof using.
  xwp. xapp. xapp. xval. xsimpl. auto.
Qed.

#[global] Hint Resolve triple_get_and_free : triple.
```

读（`xapp`）→ 释放（`xapp`）→ 返回值（`xval`）→ 对账（`xsimpl. auto.`）。

### 93.9 非确定性：rand

`val_rand n` 返回 `[0, n)` 中的随机整数。它的规格刻画**所有可能**的输出——后
条件用存在量化「存在一个 `m` 落在范围内，且返回值就是它」：

```coq
(* ---------- 93.9 非确定性：rand ---------- *)

Parameter triple_rand : forall n,
  n > 0 ->
  triple (val_rand n)
    \[]
    (fun r => \exists m, \[r = val_int m] \* \[0 <= m < n]).

Definition two_dice : val :=
  <{ fun 'u =>
      let 'n1 = val_rand 6 in
      let 'n2 = val_rand 6 in
      let 's = 'n1 + 'n2 in
      's + 2 }>.

Lemma triple_two_dice :
  triple <{ two_dice () }>
    \[]
    (fun r => \exists n, \[r = val_int n] \* \[2 <= n <= 12]).
Proof using.
  xwp.
  xapp triple_rand. { math. } intros n1 Hn1.
  xapp triple_rand. { math. } intros n2 Hn2.
  xapp. xapp.
  xsimpl. math. math.
Qed.
```

**练习（2 星）triple_two_dice**：掷两个骰子求和（加 2 是因为骰子面从 0 算
起）。三个实测要点：

1. `xapp` 不会自动消解 `n > 0` 这类前提，所以要手动给规格：`xapp triple_rand`，
   括号 `{ math. }` 关掉 `6 > 0`；
2. **每次 `xapp triple_rand` 之后目标是 `forall m, 0 <= m < 6 -> CODE`**——
   骰子结果是个新变量，必须先 `intros n1 Hn1` 引入，下一次 `xapp` 才有干净的三
   元组可用（实测直接连打两个 `xapp triple_rand` 会报
   `Instantiation fails`，原因就在这个前置量词）；
3. 两次 `xapp` 处理加法，`xsimpl` 把 `\exists n` 的见证统一成 `n1+n2+2`，最后
   两个纯算术目标（值等式与范围）各用一个 `math`。`val_int` 是把整数注入 `val`
   的构造子，显示时被 coercion 藏起来了。

### 93.10 递归函数与良基归纳

先给「数学阶乘」做个极简公理化（负数上的取值故意留白）：

```coq
(* ---------- 93.10 递归函数与良基归纳 ---------- *)

Module Facto.

Parameter facto : int -> int.

Parameter facto_init : forall n,
  0 <= n <= 1 ->
  facto n = 1.

Parameter facto_step : forall n,
  n >= 1 ->
  facto n = n * (facto (n-1)).

Lemma facto_succ : forall i,
  i >= 0 ->
  facto (i + 1) = (i + 1) * facto i.
Proof using.
  introv Hi. rewrite (@facto_step (i+1)). f_equal. f_equal. math. math.
Qed.

End Facto.

Import Facto.
```

`facto_succ` 是 `facto_step` 的「下标从 `i+1` 讲起」版本，包装成 Module 便于
其他章节引用。本章还需要一个**乘数在左边**的版本（后面符号执行算出的表达式是
`facto i * (i+1)` 的形状，方向对不上 `rewrite` 就找不到模式）：

```coq
(* 乘法写在左边时的配套版本：facto i * (i+1) = facto (i+1)。 *)

Lemma facto_succ_mul : forall i,
  i >= 0 ->
  facto i * (i+1) = facto (i+1).
Proof using.
  intros i Hi. rewrite facto_succ; [|math]. math.
Qed.
```

（第二个 `math` 处理的是交换后的等式，TLC 的 `math` 能容忍这点非线性。）

第一个递归程序：**不用状态**的纯递归阶乘。`fix 'f 'n => ...` 是递归函数记号：

```coq
Definition factorec : val :=
  <{ fix 'f 'n =>
       let 'b = 'n <= 1 in
       if 'b
         then 1
         else let 'x = 'n - 1 in
              let 'y = 'f 'x in
              'n * 'y }>.

Lemma triple_factorec : forall n,
  n >= 0 ->
  triple (factorec n)
    \[]
    (fun r => \[r = facto n]).
Proof using.
  intros n. induction_wf IH: (downto 0) n.
  unfold downto in IH.
  intros Hn. xwp.
  xapp.
  xif.
  { intros C.
    xval. xsimpl.
    rewrite facto_init. math. math. }
  { intros C.
    xapp.
    xapp.
    { math. }
    { math. }
    xapp.
    xsimpl. rewrite (@facto_step n). math. math. }
Qed.
```

规格是**部分函数**风格：前置假设 `n >= 0` 放在三元组外（也可以放进 `\[n>=0]`，
两者等价，前者更好读）。证明的骨架是**良基归纳**：

- `induction_wf IH: (downto 0) n` 是 TLC 提供的良基归纳设置器：关系
  `downto 0 m n` 表示 `0 <= m < n`（「`m` 比 `n` 小且非负」）。得到的归纳假设
  `IH` 说：对任何更小的非负入参，规格成立。`unfold downto in IH` 只是让 `IH`
  更可读；
- `xif` 把 `if` 拆成两个分支，各自 `intros C` 拿到分支条件（then 分支
  `n <= 1`，else 分支 `n > 1`）；
- **then 分支**：返回常量 `1`（`xval`），对账时 `rewrite facto_init` 把
  `facto n` 化成 `1`（`math` 关掉它的范围前提 `0 <= n <= 1`，第二个 `math`
  关掉 `1 = 1`）；
- **else 分支**：`xapp` 算 `n-1`；下一个 `xapp` 对应**递归调用**——`xapp` 自
  动套用 `IH`（入参 `n-1` 更小），产生的两个义务各用 `math` 关：一个是
  `0 <= n-1 < n`（良基性），一个是 `n-1 >= 0`（规格前提）；最后一次 `xapp`
  算乘法，`xsimpl` 后 `rewrite facto_step` 把 `n * facto (n-1)` 认回 `facto n`。

`xapp` 对递归调用的处理初看像魔法，其实只是「按引理名查到了 `IH`」。

接下来是**带状态的递归**：`repeat_incr p m` 把 `incr p` 执行 `m` 次（`m >= 0`）。
没有 else 分支的 if 写作 `if 'b then ... end`：

```coq
Definition repeat_incr : val :=
  <{ fix 'f 'p 'm =>
       let 'b = 'm > 0 in
       if 'b then
         incr 'p;
         let 'x = 'm - 1 in
         'f 'p 'x
       end }>.

(* 练习：注意归纳要放在 m 上，且 n、p 留在目标里随归纳假设通用。 *)

Lemma triple_repeat_incr : forall (m n:int) (p:loc),
  m >= 0 ->
  triple (repeat_incr p m)
    (p ~~> n)
    (fun _ => p ~~> (n + m)).
Proof using.
  intros m. induction_wf IH: (downto 0) m. unfold downto in IH.
  intros Hm n p. xwp. xapp. xif; intros C.
  { xapp. xapp. xapp.
    { math. }
    { math. }
    xsimpl. math. }
  { xval. xsimpl. math. }
Qed.
```

**练习（2 星）**：这里的关键是**量词顺序**。递归调用时状态值在变（`n` 变成
`n+1`），所以归纳假设必须对 `n`（和 `p`）全称。写法：先把 `m` 放在量化最前
（`forall m n p`），`intros m` 后**立刻**对 `m` 做归纳——此时目标还是
`forall n p, ...`，得到的 `IH` 自然对 `n`、`p` 通用。then 分支里递归调用的两
个 `math` 义务同前；else 分支（`m <= 0` 加上 `Hm : m >= 0` 推出 `m = 0`）由
`math` 收尾。

如果**删掉** `m >= 0` 这个前提会怎样？

```coq
(* 若删掉前提 m >= 0 会怎样？else 分支要求证 n = n + m，m 可为负时不可证。 *)

Lemma triple_repeat_incr_incorrect : forall (p:loc) (n m:int),
  triple (repeat_incr p m)
    (p ~~> n)
    (fun _ => p ~~> (n + m)).
Proof using.
  intros. gen n. induction_wf IH: (downto 0) m. unfold downto in IH.
  intros. xwp. xapp. xif; intros C.
  { xapp. xapp. xapp. { math. } xsimpl. math. }
  { xval.
    xsimpl.
Abort.
```

then 分支照常通过（那里有 `m > 0` 可用），else 分支要求证 `n = n + m`——没有
`m >= 0` 时 `m` 可以是负数，不可证。这个「卡住的位置 + 卡住的义务」是 SL 开发
里最有价值的反馈：它精确指出代码或规格漏了哪个情形。

补救办法之一是给规格**换一个对所有 `m` 都真的说法**：状态从 `p ~~> n` 变成
`p ~~> (n + max 0 m)`。先备好 `max` 的两条化简引理：

```coq
Lemma max_l : forall n m,
  n >= m ->
  max n m = n.
Proof using. intros. unfold max. case_if; math. Qed.

Lemma max_r : forall n m,
  n <= m ->
  max n m = m.
Proof using. intros. unfold max. case_if; math. Qed.

(* 练习（选做）：不约束 m 的最一般规格，用 max 0 m 兜住负数情形。 *)

Lemma triple_repeat_incr_max : forall (p:loc) (n m:int),
  triple (repeat_incr p m)
    (p ~~> n)
    (fun _ => p ~~> (n + max 0 m)).
Proof using.
  intros p n m. gen n.
  induction_wf IH: (downto 0) m. unfold downto in IH.
  intros n. xwp. xapp. xif; intros C.
  { xapp. xapp. xapp.
    { math. }
    xsimpl.
    rewrite max_r; [|math]. rewrite max_r; [|math]. math. }
  { xval. xsimpl. rewrite max_l; [|math]. math. }
Qed.
```

**练习（2 星，选做）**：结构照旧，两处新细节。其一，`gen n`（TLC 的
`revert`）先把会变的 `n` 撤回目标，再对 `m` 归纳——这次**不要** `gen m`，归纳
变量交给 `induction_wf` 自己泛化。其二，收尾的算术带 `max`，`math` 不会自动展
开，要手动 `rewrite max_r`（then 分支，两侧的 `max 0 _` 都化掉）或
`rewrite max_l`（else 分支，`max 0 m = 0`）。实测细节：这条规格没有前提，递归
调用的义务只剩**一个**（良基性），所以 then 分支只有一个 `{ math. }`。

第三个递归例子在两块内存间「一步步转账」：

```coq
Definition step_transfer :=
  <{ fix 'f 'p 'q =>
       let 'm = !'q in
       let 'b = 'm > 0 in
       if 'b then
         incr 'p;
         decr 'q;
         'f 'p 'q
       end }>.

Lemma triple_step_transfer : forall p q n m,
  m >= 0 ->
  triple (step_transfer p q)
    (p ~~> n \* q ~~> m)
    (fun _ => p ~~> (n + m) \* q ~~> 0).
Proof using.
  intros p q n m Hm. gen n Hm.
  induction_wf IH: (downto 0) m. unfold downto in IH.
  intros. xwp. xapp. xapp. xif; intros C.
  { xapp. xapp. xapp.
    { math. }
    { math. }
    xsimpl. math. }
  { xval. xsimpl. math. math. }
Qed.
```

**练习（2 星）**：行为与 `transfer` 相同，但**递归的驱动力量是 `q` 的内容**
（每轮 `m` 减一），而递归调用传的参数 `p q` 不变。归纳要放在 `q` 的**内容
值** `m` 上：`intros p q n m Hm. gen n Hm.` 后 `induction_wf IH: (downto 0) m`
——`IH` 对 `n`、`m`（以及前提）全称，then 分支套用 `IH`（`m-1` 更小）即可。
else 分支拆成两个小目标（`n = n + m` 与 `m = 0`），各一个 `math`。另注意
`decr`（`DemoPrograms` 里的演示程序）的规格已被库登记，`xapp` 直接可用。

### 93.11 用状态算阶乘

命令式的阶乘：外层函数开一个累加器引用，内层递归函数跑「for 循环」：

```coq
(* ---------- 93.11 用状态算阶乘 ---------- *)

Definition factoimp_aux : val :=
  <{ fix 'f 'r 'i 'n =>
       let 'b = 'i < 'n in
       if 'b then
         let 'j = 'i + 1 in
         let 's = !'r in
         let 'p = 's * 'j in
         'r := 'p;
         'f 'r 'j 'n
       end }>.

Definition factoimp : val :=
  <{ fun 'n =>
       let 'r = ref 1 in
       factoimp_aux 'r 1 'n;
       let 'm = !'r in
       free 'r;
       'm }>.

(* 练习：循环不变量是 r ~~> facto i。 *)

Lemma triple_factoimp_aux : forall (r:loc) (i n:int),
  0 <= i <= n ->
  triple (factoimp_aux r i n)
    (r ~~> facto i)
    (fun _ => r ~~> facto n).
Proof using.
  introv. induction_wf IH: (upto n) i. introv Hn.
  xwp. xapp. xif; intros C.
  { xapp.
    xapp.
    xapp.
    xapp.
    rewrite facto_succ_mul; [|math].
    xapp.
    { math. }
    { math. }
    xsimpl. }
  { xval. xsimpl.
    assert (E: i = n). { math. }
    rewrite E. auto. }
Qed.
```

**练习（3 星）triple_factoimp_aux**：循环不变量就是前条件 `r ~~> facto i`——
「循环跑到下标 `i` 时，累加器里存的是 `facto i`」。四个看点：

1. 归纳关系换成 `upto n`（`upto n i' i` 表示 `i <= i' <= n`，下标在 `[i,n]` 里
   递增的良基关系）；
2. **值要先改写再入状态**：符号执行算出的乘积是 `facto i * (i+1)`，而递归调用
   的前条件要说 `facto (i+1)`——两条形状不同，必须在赋值之前
   `rewrite facto_succ_mul; [|math]` 把 CODE 里的表达式改写成归纳假设认得的样
   子（这就是前面准备那条引理的原因；方向反了 `rewrite` 会报「找不到子项」）；
3. 递归调用的两个 `math` 义务：`i <= i+1 <= n`（良基）与 `0 <= i+1 <= n`（规
   格前提）；
4. else 分支（`i >= n` 连同前提推出 `i = n`）留下的目标是
   `facto i = facto n`——`facto` 是不透明公理，`math` 对它无能为力，要
   `assert (E: i = n)` 后 `rewrite E. auto.`。这个「先证索引相等、再改写」的
   小套路在含抽象函数的目标上会反复出现。

主函数把不变量串起来：

```coq
(* 练习：主函数 factoimp。 *)

Lemma triple_factoimp : forall n,
  n >= 1 ->
  triple (factoimp n)
    \[]
    (fun r => \[r = facto n]).
Proof using.
  introv Hn. xwp. xapp. intros r.
  xapp triple_factoimp_aux.
  { math. }
  { rewrite facto_init; [|math]. auto. }
  xapp. xapp. xval. xsimpl. auto.
Qed.
```

**练习（3 星）triple_factoimp**（先做 `n >= 1` 版本）：`xapp`（分配
`ref 1`）→ `intros r` → `xapp triple_factoimp_aux` 套用辅助规格。它产生两个
义务，顺序固定：先 `{ math. }` 关 `0 <= 1 <= n`，再处理状态匹配
`1 = facto 1`——`rewrite facto_init; [|math]` 把 `facto 1` 化成 `1`，`auto`
收尾（注意 `facto_init` 的 `n` 是隐式参数，不能写成 `facto_init 1`，直接裸用
即可）。之后读出、释放、返回值，与 93.8 相同。

### 93.12 选读：把 n = 0 也一并覆盖

`factoimp 0` 其实也正确（循环体不执行，返回初值 1 = facto 0），但直接给
`n >= 0` 的规格要在辅助函数里区分两种「入口」。最笨的办法是**分两次验证**：

```coq
(* ---------- 93.12 选读：把 n = 0 也一并覆盖 ---------- *)

Lemma triple_factoimp_aux_zero : forall (r:loc) (i n:int),
  i = 1 ->
  n = 0 ->
  triple (factoimp_aux r i n)
    (r ~~> facto i)
    (fun _ => r ~~> facto n).
Proof using.
  introv. introv Hi Hn.
  xwp. xapp. xif; intros C.
  { false. math. }
  { xval. xsimpl. subst.
    rewrite facto_init; [|math].
    rewrite facto_init; [|math]. auto. }
Qed.

Lemma triple_factoimp_zero : forall n,
  n = 0 ->
  triple (factoimp n)
    \[]
    (fun r => \[r = facto n]).
Proof using.
  introv Hn. xwp. xapp. intros r.
  xapp triple_factoimp_aux_zero. { math. } { math. }
  { rewrite* facto_init. { math. } }
  xapp. xapp. xval. xsimpl. auto.
Qed.
```

`triple_factoimp_aux_zero` 是 `n = 0` 专用版：then 分支直接 `false`（`i < n`
即 `1 < 0` 不可能）；else 分支 `subst` 代入后两次 `facto_init` 把两侧都化成
`1`。`triple_factoimp_zero` 用它走一遍主函数（`rewrite*` 是 `rewrite` 加
`auto` 的星号写法；`{ math. }` 关 `facto_init` 的范围前提）。同一份代码验证两
遍——脚本冗长，是坏味道。

**练习（4 星，选做）**：一遍过。把辅助规格的前提改成**析取**——要么是
「`i = 1` 且 `n = 0`」（零情形的入口），要么是「`0 <= i <= n`」（常规入口）：

```coq
(* 练习（选做）：把两种情形合并成一条析取前置条件，一遍过整个循环。 *)

Lemma triple_factoimp_aux' : forall (r:loc) (i n:int),
  (i = 1 /\ n = 0) \/ (0 <= i <= n) ->
  triple (factoimp_aux r i n)
    (r ~~> facto i)
    (fun _ => r ~~> facto n).
Proof using.
  introv. induction_wf IH: (upto n) i. introv Hn.
  xwp. xapp. xif; intros C.
  { destruct Hn as [(?&?)|?]; [ false; math | ].
    xapp.
    xapp.
    xapp.
    xapp.
    rewrite facto_succ_mul; [|math].
    xapp.
    { math. }
    { right. math. }
    xsimpl. }
  { destruct Hn as [(?&?)|?].
    { subst. xval. xsimpl.
      rewrite facto_init; [|math].
      rewrite facto_init; [|math]. auto. }
    { xval. xsimpl.
      assert (E: i = n). { math. }
      rewrite E. auto. } }
Qed.
```

then 分支（`i < n`）里零情形不可能，`destruct` 排除后走原路；递归调用的第二
个义务现在是**析取**——TLC 的 `math` 不做命题结构拆分（实测直接 `math` 报
`Cannot find witness`），要 `right. math.` 明确选右支。else 分支按 `Hn` 分两
种情形收尾，各自是 93.11/零版的原样搬迁。

主函数同样一遍过：

```coq
Lemma triple_factoimp' : forall n,
  n >= 0 ->
  triple (factoimp n)
    \[]
    (fun r => \[r = facto n]).
Proof using.
  introv Hn. xwp. xapp. intros r.
  xapp triple_factoimp_aux'.
  { destruct (classic (n = 0)) as [E|E].
    { left. auto. }
    { right. math. } }
  { rewrite facto_init; [|math]. auto. }
  xapp. xapp. xval. xsimpl. auto.
Qed.
```

析取义务在**调用点**才决定选哪支：`classic`（TLC 的经典逻辑排中律，
`n = 0 \/ n <> 0`）做案例分析，零则选左、正数选右（原书的建议是把这个分析
**尽量推迟**，免得脚本分叉）。第二个括号依旧是 `1 = facto 1`。至此
`triple_factoimp'` 覆盖全部 `n >= 0`，代码只过了一遍。

### 93.13 本章小结

**概念**：

- SL 三元组 `triple t H Q`：`H`/`Q` 只描述**所需的那块内存**，`Q` 还描述返回
  值；
- 堆谓词五件套：`p ~~> n`（单元格）、`\[]`（空）、`\[P]`（纯事实）、
  `H1 \* H2`（分离合取，蕴含不相交）、`\exists x, H`（存在量化，分配与随机
  的标配）；`funloc p => H` 是「返回位置」的缩写；
- 框架规则：没写进规格的资源原样保留——因此「少写」反而「更强」，新分配单元
  与旧内存的不同性是它的免费推论；
- 别名：星号要求不相交，`f p p` 需要另立规格；分配与释放要保持资源账目平
  衡，`free` 消费 `p ~~> _`；
- 部分函数规格把前提放在三元组外；非确定性用存在量化刻画输出集合；递归用
  `induction_wf` 良基归纳，`downto`/`upto` 按需选择。

**x-tactics 速查**：`xwp`（开局，目标变 `PRE/CODE/POST`）、`xapp`（对下一操
作做符号执行，可带规格参数 `xapp L`）、`xif`（拆条件）、`xval`（处理返回
值）、`xsimpl`（证明 `H ==> H'` 型蕴含）。

**TLC tactic 速查**：`math`（算术，`lia` 封装）、`introv`（只按名引入假设）、
`gen`（revert）、`induction_wf IH: R x`（良基归纳）、`rew_list`/`rewrite*`
（改写加自动收尾）。

**实测坑位**（本章调试的真实记录）：

- `Implicit Types n m : int.` 等两行必须写，否则裸 `forall n` 被解析成 `trm`；
- `xapp` 数量 = `let` 数 + 返回表达式数，多一个报 `No applicable tactic`；
- 带 `\exists` 后条件的原语（`rand`）要手动 `xapp 规格名`，且每次调用后先
  `intros` 再继续；
- `math` 不拆 `\/` 目标（要 `right. math.`）、不动不透明函数（要
  `assert + rewrite`）、不展开 `max`（要 `rewrite max_l/max_r`）；
- 隐式参数的引理（如 `facto_init`）不能按位置传参，裸用即可；
- `xapp` 产生的多个义务**有固定顺序**（前提义务在前、状态匹配在后），括号要
  按序写，写反了报「找不到子项」。

分离逻辑的用户体验到此为止。下一章（94）继续用户视角，验证真正的数据结构——
可变链表与树；从 95 章开始，我们把这些记号一个个拆开，亲手重造整个框架。
