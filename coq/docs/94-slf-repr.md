# 94 · 表示谓词：链表、树、栈与计数器

对应示例：`../examples/94_slf_repr.v`（rocq 9.1.1 + SLF 库实测编译退出码 0）

93 章验证的程序只碰单个引用单元格。真实程序操作**数据结构**——链表、树、
栈——它们由几十个单元格组成，还带有「头部指针为空表示空表」这类**表示约定**。
分离逻辑用**表示谓词**（representation predicate）把「一块内存布局」打包成一
个堆谓词：`MList L p` 读作「位置 `p` 处有一条可变链表，逻辑内容是 Rocq 纯函
数列表 `L`」。规格里只见 `MList`，不见任何单元格——数据结构的**抽象层**就此建
立。本章取材原书 Repr 章（用户视角的最后一章），全章所有练习（含 5 星的
`miter` 与 CPS `append`）都给出完整解答。

文件头与 93 章同一套，多了两样：`Open Scope liblist_scope`（TLC 的列表记号
`++`/`::`/`length`/`rev`），以及 `val` 类型的隐式类型声明：

```coq
(* 94 表示谓词 —— MList/MTree/Stack/IsCounter、智能构造器、高阶与 CPS *)
(* 取材 Software Foundations 卷六 Separation Logic Foundations 的 Repr 章。 *)

Set Implicit Arguments.
From SLF Require Import LibSepReference.
Import ProgramSyntax DemoPrograms.
Open Scope liblist_scope.

Implicit Types n m : int.
Implicit Types p q s c : loc.
Implicit Types x : val.
```

### 94.1 链表的表示谓词 MList

链表单元是双字段记录：`head` 存元素、`tail` 存下一单元的地址。字段名用自然数
表示（`field := nat`）：

```coq
(* ---------- 94.1 链表的表示谓词 MList ---------- *)

Definition head : field := 0%nat.
Definition tail : field := 1%nat.
```

`p ~~~>`{ head := x; tail := q }` 描述「`p` 处的记录，字段值如所列」（`~~~>` 是
93 章见过的 `~~>` 的记录版）。可变链表的表示谓词按逻辑列表 `L` 的结构递归定
义：

```coq
Fixpoint MList (L:list val) (p:loc) : hprop :=
  match L with
  | nil => \[p = null]
  | x::L' => \exists q, (p ~~~> `{ head := x; tail := q}) \* (MList L' q)
  end.
```

读法：**空表**就是空指针（`null`，不占任何内存，所以是纯事实 `\[p = null]`）；
**非空表**是一个单元加上尾巴——星号保证头单元与尾巴**不共享**内存，存在量化
的 `q` 隐藏了尾巴的地址。`MList L p` 的「逻辑层」是 `L`，「物理层」是一串记
录——表示谓词就是连接两层的桥梁。

直接展开 `MList` 做证明很笨拙（Rocq 的折叠/展开不可靠），工程做法是给两个方
向的「折叠/展开」引理，然后把定义本体封成不透明：

```coq
Lemma MList_nil : forall p,
  (MList nil p) = \[p = null].
Proof using. auto. Qed.

Lemma MList_cons : forall p x L',
  MList (x::L') p =
  \exists q, (p ~~~> `{ head := x; tail := q}) \* (MList L' q).
Proof using. auto. Qed.
```

还有第三个最有用的「打开」引理：按**指针是否为 null** 分情况——正好对应代码
里 `if p == null` 的编程模式：

```coq
(* 按 p 是否为 null 做分情形的「打开」引理（原书练习，这里给出完整证明）。
   证明模式与 MTree_if 相同：先按 L 分情况，再对 If p = null 做 case_if，
   非空分支用 hrecord_not_null 排除 p = null 的可能。 *)

Lemma MList_if : forall (p:loc) (L:list val),
      (MList L p)
  ==> (If p = null
        then \[L = nil]
        else \exists x q L', \[L = x::L']
             \* (p ~~~> `{ head := x; tail := q}) \* (MList L' q)).
Proof using.
  intros. destruct L as [|x L'].
  { xchange MList_nil. intros M. case_if. xsimpl*. }
  { xchange MList_cons. intros q.
    xchange hrecord_not_null. intros N. case_if. xsimpl*. }
Qed.

Global Opaque MList.
```

`MList_if` 是原书留给读者的练习（标了「技术性强可跳过」），完整证明只需三招：
按 `L` 分情况；`xchange MList_nil/cons` 展开成记录形式；`case_if` 拆经典命题
`If p = null`——非空分支里 `hrecord_not_null`（「非空指针处必有记录」）排除掉
`p = null` 的矛盾情形，`xsimpl*` 收尾。注意 `If ... then ... else ...` 是 TLC
对**命题** P 的分情况构造（经典逻辑），不是程序的 `if`。此后的所有证明都只
用这三条引理，不再碰定义——`Global Opaque MList` 从机制上禁止了意外展开。

本章还要复用 93 章的两个函数（各文件独立编译，重新定义并登记规格）：

```coq
(* 本章要用到 93 章的两个小函数：incr 与 get_and_free。 *)

Definition incr : val :=
  <{ fun 'p =>
       let 'n = !'p in
       let 'm = 'n + 1 in
       'p := 'm }>.

Lemma triple_incr : forall (p:loc) (n:int),
  triple (incr p)
    (p ~~> n)
    (fun _ => (p ~~> (n+1))).
Proof using.
  xwp. xapp. xapp. xapp. xsimpl.
Qed.

#[global] Hint Resolve triple_incr : triple.

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

### 94.2 就地拼接：append——表示谓词证明的标准舞步

`append p1 p2` 把 `p2` 接到非空表 `p1` 的尾部（OCaml 里 `p1.tail == null` 时
`p1.tail <- p2`，否则递归）：

```coq
(* ---------- 94.2 就地拼接 append ---------- *)

Definition append : val :=
  <{ fix 'f 'p1 'p2 =>
       let 'q1 = 'p1`.tail in
       let 'b = ('q1 = null) in
       if 'b
         then 'p1`.tail := 'p2
         else 'f 'q1 'p2 }>.

Lemma triple_append : forall (L1 L2:list val) (p1 p2:loc),
  p1 <> null ->
  triple (append p1 p2)
    (MList L1 p1 \* MList L2 p2)
    (fun _ => MList (L1++L2) p1).
Proof using.
  introv N.
  gen p1. induction_wf IH: list_sub L1. intros. xwp.
  xchange (MList_if p1). case_if.
  xpull.
  intros x q1 L1' ->.
  xapp. xapp. xif; intros Cq1.
  { xchange (MList_if q1). case_if. xpull.
    intros ->.
    xapp. xchange <- MList_cons. }
  { xapp. xchange <- MList_cons. }
Qed.
```

这条规格值得细读：后条件说**同一块内存**从「`L1` 后接 `L2`」的角度看是
`MList (L1++L2) p1`——就地拼接不分配、不复制，只是改写一个尾指针。前提
`p1 <> null` 保证第一步能安全读 `p1.tail`。证明是全章的**模板舞步**，逐行拆
解：

- `introv N` 引入前提；`gen p1` 把会变的 `p1` 撤回目标，`induction_wf IH:
  list_sub L1` 对**列表结构**做良基归纳（`list_sub L1' L1` 表示 `L1'` 是 `L1`
  去掉头元素后的尾段——库已注册其良基性）；
- `xchange (MList_if p1). case_if.` **打开头单元**：借前提 `N` 排除 `p = null`
  分支，剩下的目标以 `\[L1 = x::L1']` 开头；`xpull` 把存在量词与纯事实提到前
  提里，`intros x q1 L1' ->` 一次性引入并代换——此刻状态是「头单元记录 \* 尾巴
  `MList L1' q1` \* 第二条表 `MList L2 p2`」；
- 三个 `xapp` 依次处理「读 `p1.tail`」「比较 `q1 = null`」「if 分派」（`xif`
  拆分支，`Cq1` 是分支条件）；
- **then 分支**（`q1` 是 null，即 `L1'` 为空）：再次 `xchange (MList_if q1)`
  打开尾巴、`intros ->` 代换 `L1' := nil`；`xapp` 执行写回
  `p1.tail := p2`——状态变成「头单元（tail 已指向 `p2`）\* `MList L2 p2`」；
  `xchange <- MList_cons` **折回** `MList (x::L2) p1`，与目标
  `MList ((x::nil)++L2) p1` 在列表化简下吻合；
- **else 分支**（`q1` 非空）：`xapp` 用归纳假设处理递归调用（框架规则自动保
  住头单元），得到 `MList (L1'++L2) q1`；`xchange <- MList_cons` 把头单元折回
  去，得 `MList (x::(L1'++L2)) p1`，正是 `MList ((x::L1')++L2) p1`。

**打开-执行-折回**（unfolding-execute-refolding）就是表示谓词证明的全部节
奏。实测提示（与原书 rocq 9.0 环境的差异）：我们的 rocq 9.1.1 上 else 分支的
`xapp` 不会自动折回头单元，需补一句 `xchange <- MList_cons`。

### 94.3 智能构造器：mnil 与 mcons

与其让用户直接操作 `null` 和记录分配，不如提供**智能构造器**——空表构造器和
cons 单元构造器——并把它们的规格按 `MList` 的语言陈述：

```coq
(* ---------- 94.3 智能构造器 mnil 与 mcons ---------- *)

Definition mnil : val :=
  <{ fun 'u =>
       null }>.

Lemma triple_mnil :
  triple (mnil ())
    \[]
    (funloc p => MList nil p).
Proof using.
  xwp.
  xval.
  generalize (MList_nil null). intros E.
  xchange <- E. { auto. }
   xsimpl. auto.
Qed.
```

`mnil()` 只是返回 `null`——但规格完全不提 `null`，只说「返回某个 `p`，满足
`MList nil p`」：**实现细节被规格隐藏**。证明里学到新招：空状态里凭空造出一
个 `MList nil null`——`generalize (MList_nil null). intros E.` 拿到等式
`MList nil null = \[null = null]`，`xchange <- E` 用它把 `\[]` 换成
`MList nil null`（代价是证 `null = null`，`{ auto. }` 交掉），`xsimpl. auto.`
统一存在变量并收尾。紧凑版一行：

```coq
Lemma triple_mnil' :
  triple (mnil ())
    \[]
    (funloc p => MList nil p).
Proof using. xwp. xval. xchanges* <- (MList_nil null). Qed.

#[global] Hint Resolve triple_mnil : triple.
```

`xchanges` = `xchange` + `xsimpl`，星号再追加 `eauto`。

`mcons x q` 分配一个新单元（`` `{ head := 'x; tail := 'q } `` 是记录分配记号，
实为原语 `val_new_hrecord_2` 的语法糖，105 章拆解）。两条规格：记录层与列表
层：

```coq
Definition mcons : val :=
  <{ fun 'x 'q =>
       `{ head := 'x; tail := 'q } }>.

Lemma triple_mcons : forall x q,
  triple (mcons x q)
    \[]
    (funloc p => p ~~~> `{ head := x ; tail := q }).
Proof using. xwp. xapp triple_new_hrecord_2; auto. xsimpl*. Qed.

Lemma triple_mcons' : forall L x q,
  triple (mcons x q)
    (MList L q)
    (funloc p => MList (x::L) p).
Proof using.
  intros. xapp triple_mcons.
  intros p. xchange <- MList_cons. xsimpl*.
Qed.

#[global] Hint Resolve triple_mcons' : triple.
```

`triple_mcons` 直接套库里的分配规格；`triple_mcons'` 从它**推导**出列表层版本
（「消费一条表，产出一个更长的表」——注意它**转移了尾部表的所有权**）。日常
使用的是第二条，所以登记它进 hint 数据库。

### 94.4 深拷贝：mcopy

```coq
(* ---------- 94.4 链表深拷贝 mcopy ---------- *)

Definition mcopy : val :=
  <{ fix 'f 'p =>
       let 'b = ('p = null) in
       if 'b
         then mnil ()
         else
           let 'x = 'p`.head in
           let 'q = 'p`.tail in
           let 'q2 = ('f 'q) in
           mcons 'x 'q2 }>.

Lemma triple_mcopy : forall L p,
  triple (mcopy p)
    (MList L p)
    (funloc p' => (MList L p) \* (MList L p')).
Proof using.
  intros. gen p. induction_wf IH: list_sub L.
  xwp. xapp. xchange MList_if. xif.
  { intros C.
    case_if. (* automatically rules out the case [p <> null] *)
    xpull. intros E. subst L.
    xapp. xsimpl. { auto. }
    subst. xchange <- MList_nil. auto. }
  { intros C. case_if. (* automatically rules out [p = null] *)
    xpull. intros x q L' E. subst L.
    xapp. xapp. xapp. intros q'.
    xapp. intros p'.
    xchange <- MList_cons. xsimpl. auto. }
Qed.
```

后条件 `(MList L p) \* (MList L p')` 的**星号是关键**：拷贝出来的表与原表完全
独立（不共享任何单元格）。证明骨架与 `append` 相同，两点新意：then 分支先调
`mnil`（`xapp` 自动用它的 hint）再对返回的 `p'` 做 94.3 的「凭空造空表」；else
分支两次 `intros q'`/`intros p'` 引入 `funloc` 的存在变量，最后折回头单元。熟
练后的紧凑写法（`->` 引入模式 + 星号收尾）：

```coq
Lemma triple_mcopy' : forall L p,
  triple (mcopy p)
    (MList L p)
    (funloc p' => (MList L p) \* (MList L p')).
Proof using.
  intros. gen p. induction_wf IH: list_sub L.
  xwp. xapp. xchange MList_if. xif; intros C; case_if; xpull.
  { intros ->. xapp. xsimpl*. subst. xchange* <- MList_nil. }
  { intros x q L' ->. xapp. xapp. xapp. intros q'.
    xapp. intros p'. xchange <- MList_cons. xsimpl*. }
Qed.
```

### 94.5 练习：mlength——返回值里带 val_int

```coq
(* ---------- 94.5 练习：mlength ---------- *)

Definition mlength : val :=
  <{ fix 'f 'p =>
       let 'b = ('p = null) in
       if 'b
         then 0
         else (let 'q = 'p`.tail in
               let 'n = 'f 'q in
               'n + 1) }>.

Lemma triple_mlength : forall L p,
  triple (mlength p)
    (MList L p)
    (fun r => \[r = val_int (length L)] \* (MList L p)).
Proof using.
  intros. gen p. induction_wf IH: list_sub L.
  xwp. xapp. xchange MList_if. xif; intros C; case_if; xpull.
  { intros ->. xval. xsimpl. rew_list. auto.
    xchange <- (MList_nil p). auto. }
  { intros x q L' ->. xapp. xapp. xapp.
    xsimpl. rew_list. math.
    xchange <- MList_cons. }
Qed.
```

**练习（3 星）**：求表长。要点：(1) 返回整数要写 `val_int (length L)`——
`length` 是 nat，靠 95 章会讲到的 `nat → int → val` 强制转换链放进值层；(2)
`rew_list` 是 TLC 的「列表表达式规范化器」：把 `length (x::L')` 化成
`length L' + 1`、把 `(x::nil)++L` 化成 `x::L` 之类，让 `auto`/`math` 能对上
号；(3) 别数错 `xapp`——读尾、递归、加一各一次，共三次；(4) 空表分支除算术外
还要「凭空造 `MList nil p`」（用 `C : p = null`）。

### 94.6 练习：mlength'——带累加引用的另一种实现

```coq
(* ---------- 94.6 练习：带累加引用的 mlength' ---------- *)

Definition acclength : val :=
  <{ fix 'f 'c 'p =>
       let 'b = ('p <> null) in
       if 'b then
         incr 'c;
         let 'q = 'p`.tail in
         'f 'c 'q
       end }>.

Definition mlength' : val :=
  <{ fun 'p =>
       let 'c = ref 0 in
       acclength 'c 'p;
       get_and_free 'c }>.

Lemma triple_acclength : forall L p c n,
  triple (acclength c p)
    (c ~~> n \* MList L p)
    (fun _ => c ~~> (n + length L) \* MList L p).
Proof using.
  intros L. induction_wf IH: list_sub L. intros p c n.
  xwp. xapp. xchange MList_if. xif; intros C; case_if; xpull.
  { intros x q L' ->. xapp. xapp. xapp.
    xsimpl. rew_list. math.
    xchange <- MList_cons. }
  { intros ->. xval. xsimpl. rew_list. math.
    xchange <- (MList_nil p). auto. }
Qed.

Lemma triple_mlength' : forall L p,
  triple (mlength' p)
    (MList L p)
    (fun r => \[r = val_int (length L)] \* (MList L p)).
Proof using.
  intros. xwp. xapp. intros c.
  xapp triple_acclength.
  xapp. xsimpl. math.
Qed.
```

**练习（3 星）**：先给递归辅助函数 `acclength` 立规格——不变量是
`c ~~> (n + 还没走的表长)`，注意 `c ~~> n` 与 `MList L p` 用星号并列（**累加
器与数据结构互不相干**）；泛化时 `p c n` 都会变（`n` 每步加一），所以归纳放
在 `L` 上、`intros p c n` 放在归纳**之后**。主函数三步走：`ref 0`、
`xapp triple_acclength`（初值 `n = 0`）、`get_and_free` 读出并释放。实测细节：
`get_and_free` 的 `xapp` 会把返回值一并处理掉，后面**不需要** `xval`。

### 94.7 练习：mfree——整表释放

```coq
(* ---------- 94.7 练习：整表释放 mfree ---------- *)

Definition mfree : val :=
  <{ fix 'f 'p =>
       let 'b = ('p <> null) in
       if 'b then
         let 'q = 'p`.tail in
         delete 'p;
         'f 'q
       end }>.

Lemma triple_mfree : forall L p,
  triple (mfree p)
    (MList L p)
    (fun _ => \[]).
Proof using.
  intros. gen p. induction_wf IH: list_sub L.
  xwp. xapp. xchange MList_if. xif; intros C; case_if; xpull.
  { intros x q L' ->. xapp. xapp. xapp. xsimpl. }
  { intros ->. xval. xsimpl. }
Qed.
```

**练习（3 星）**：逐单元 `delete`（记录版 `free`）。后条件 `\[]`——**整条表
被吃掉**，资源账目归零。注意程序测试的是 `'p <> null`，所以**第一个分支是
cons 情形**（实测把两个分支写反会报 `Cannot find a relation to rewrite`）。

### 94.8 练习：mrev——就地反转（4 星）

```coq
(* ---------- 94.8 练习：就地反转 mrev ---------- *)

Definition mrev_aux : val :=
  <{ fix 'f 'p1 'p2 =>
       let 'b = ('p2 = null) in
       if 'b
         then 'p1
         else (
           let 'p3 = 'p2`.tail in
           'p2`.tail := 'p1;
           'f 'p2 'p3) }>.

Definition mrev : val :=
  <{ fun 'p =>
       mrev_aux null 'p }>.

Lemma triple_mrev_aux : forall L1 L2 p1 p2,
  triple (mrev_aux p1 p2)
    (MList L1 p1 \* MList L2 p2)
    (funloc p3 => MList (rev L2 ++ L1) p3).
Proof using.
  intros. gen L1 p1 p2. induction_wf IH: list_sub L2. intros L1 p1 p2.
  xwp. xapp. xchange (MList_if p2). xif; intros C; case_if; xpull.
  { intros ->. xval. xsimpl. rew_list. auto. }
  { intros x q L2' ->. xapp.
    xapp.
    xchange <- MList_cons.
    rew_list.
    xapp. intros p3.
    xsimpl. auto. }
Qed.

Lemma triple_mrev : forall L p,
  triple (mrev p)
    (MList L p)
    (funloc q => MList (rev L) q).
Proof using.
  intros. xwp. xapp (triple_mrev_aux nil L null p).
  xchange <- (MList_nil null). { auto. }
  xsimpl.
  { intros x x0 ->. auto. }
  intros. rew_list. xsimpl.
Qed.
```

**练习（4 星，选做）**。找对辅助函数的不变量是全部难点：`mrev_aux p1 p2` 沿
`p2` 走，把每个单元摘下来**前缀到** `p1` 上——所以规格是「两条表
`MList L1 p1 \* MList L2 p2` 变成一条 `MList (rev L2 ++ L1) p3`」。三个实测要
点：

1. **三个量都要泛化**：`gen L1 p1 p2`——递归调用时第一条表的逻辑内容变成
   `x::L1`、位置变成 `p2`，归纳假设必须对三者全称（漏泛化哪个，`xapp` 就在哪
   报 `No applicable tactic`）；
2. else 分支先折回头单元（写完 `p2.tail := p1` 后，`p2` 处的表已是
   `x::L1`），**`rew_list` 要放在递归 `xapp` 之前**：把目标后条件里的
   `rev (x::L2') ++ L1` 规范成 `rev L2' ++ x::L1`，才能与归纳假设的后条件严
   丝合缝；
3. 主函数 `mrev p = mrev_aux null p` 需要**凭空造一条空表**（`xchange <-
   (MList_nil null)`），再把辅助规格显式实例化（`xapp (triple_mrev_aux nil L
   null p)`）；`xapp` 留下的「后条件魔杖」义务由 `xsimpl` 自动拆解，两个小括
   号分别处理「存在变量统一」（`intros x x0 ->. auto.`）与
   `rev L ++ nil = rev L`（`rew_list. xsimpl.`）。

### 94.9 带尺寸的栈：两层表示谓词

把「链表指针 + 长度计数」打包成一个记录，就得到 O(1) 读尺寸的栈：

```coq
(* ---------- 94.9 带尺寸的栈：表示谓词 Stack ---------- *)

Module SizedStack.

Definition data : field := 0%nat.
Definition size : field := 1%nat.

Definition Stack (L:list val) (s:loc) : hprop :=
  \exists p, s ~~~>`{ data := p; size := length L } \* (MList L p).
```

`Stack L s` 本身就是一台「包装机」：内部指针 `p` 被存在量化隐藏，尺寸字段直
接存 `length L`——**冗余数据与逻辑内容的一致性被定义本身锁定**（规格不可能
表达「尺寸与表长不一致」的栈）。创建与读尺寸：

```coq
Definition create : val :=
  <{ fun 'u =>
      `{ data := null; size := 0 } }>.

Lemma triple_create :
  triple (create ())
    \[]
    (funloc s => Stack nil s).
Proof using.
  xwp. xapp triple_new_hrecord_2; auto. intros s.
  unfold Stack. xsimpl*. xchange* <- (MList_nil null).
Qed.

Definition sizeof : val :=
  <{ fun 'p =>
      'p`.size }>.

Lemma triple_sizeof : forall L s,
  triple (sizeof s)
    (Stack L s)
    (fun r => \[r = length L] \* Stack L s).
Proof using.
  xwp. unfold Stack. xpull. intros p. xapp. xsimpl*.
Qed.
```

`unfold Stack. xpull. intros p.` 是打开两层包装的标准起手（`xpull` 从前条件里
拉出存在变量与纯事实）。压栈：

```coq
Definition push : val :=
  <{ fun 's 'x =>
       let 'p = 's`.data in
       let 'p2 = mcons 'x 'p in
       's`.data := 'p2;
       let 'n = 's`.size in
       let 'n2 = 'n + 1 in
       's`.size := 'n2 }>.

Lemma triple_push : forall L s x,
  triple (push s x)
    (Stack L s)
    (fun u => Stack (x::L) s).
Proof using.
  xwp. unfold Stack. xpull. intros p.
  xapp.
  xapp. intros p2.
  xapp.
  xapp.
  xapp.
  xapp.
  unfold Stack. xsimpl*. rew_list. math.
Qed.
```

**练习（3 星）**：六个 `xapp` 一路符号执行（读 data、mcons、写 data、读
size、加一、写 size），收尾 `unfold Stack. xsimpl*` 重组栈谓词，`rew_list +
math` 对账 `length L + 1 = length (x::L)`。弹栈与取栈顶：

```coq
Definition pop : val :=
  <{ fun 's =>
       let 'p = 's`.data in
       let 'x = 'p`.head in
       let 'p2 = 'p`.tail in
       delete 'p;
       's`.data := 'p2;
       let 'n = 's`.size in
       let 'n2 = 'n - 1 in
       's`.size := 'n2;
       'x }>.

Lemma triple_pop : forall L s,
  L <> nil ->
  triple (pop s)
    (Stack L s)
    (fun x => \exists L', \[L = x::L'] \* Stack L' s).
Proof using.
  introv HN. xwp. unfold Stack. xpull. intros p.
  destruct L as [|x L']; [ false | ].
  xapp.
  xchange MList_cons. xpull. intros q.
  xapp.
  xapp.
  xapp.
  xapp.
  xapp.
  xapp.
  xapp.
  xval.
  unfold Stack. xsimpl*. rew_list. math.
Qed.

Definition top : val :=
  <{ fun 's =>
       let 'p = 's`.data in
       'p`.head }>.

Lemma triple_top : forall L s,
  L <> nil ->
  triple (top s)
    (Stack L s)
    (fun x => \exists L', \[L = x::L'] \* Stack L s).
Proof using.
  introv HN. xwp. unfold Stack. xpull. intros p.
  destruct L as [|x L']; [ false | ].
  xapp.
  xchange MList_cons. xpull. intros q.
  xapp.
  xchange <- MList_cons. xsimpl*.
Qed.

End SizedStack.
```

**练习（4 星 pop / 2 星 top）**：前提 `L <> nil` 先用 `destruct L; false` 排
掉空表；`pop` 要**先打开 `MList_cons`** 暴露头单元才能读 head/tail 与
`delete`；后条件里的 `\exists L', \[L = x::L']` 说明「返回值就是被弹出的头元
素」（`xsimpl*` 自动取见证）。`top` 不改任何东西，折回头单元即完工。

### 94.10 树的表示谓词 MTree

同一套思想搬到大一号的数据结构。逻辑层是 Rocq 的 `tree`，物理层是三字段记录
（元素、左、右）：

```coq
(* ---------- 94.10 树的表示谓词 MTree ---------- *)

Inductive tree : Type :=
  | Leaf : tree
  | Node : int -> tree -> tree -> tree.

Implicit Types T : tree.

Definition item : field := 0%nat.
Definition left : field := 1%nat.
Definition right : field := 2%nat.

Fixpoint MTree (T:tree) (p:loc) : hprop :=
  match T with
  | Leaf => \[p = null]
  | Node n T1 T2 => \exists p1 p2,
         (p ~~~>`{ item := n; left := p1; right := p2 })
      \* (MTree T1 p1)
      \* (MTree T2 p2)
  end.
```

`MList` 的全套配角原样复制一遍——折叠/展开引理、按指针判空的打开引理、不透明
化：

```coq
Lemma MTree_Leaf : forall p,
  (MTree Leaf p) = \[p = null].
Proof using. auto. Qed.

Lemma MTree_Node : forall p n T1 T2,
  (MTree (Node n T1 T2) p) =
  \exists p1 p2,
       (p ~~~>`{ item := n; left := p1; right := p2 })
    \* (MTree T1 p1) \* (MTree T2 p2).
Proof using. auto. Qed.

Lemma MTree_if : forall (p:loc) (T:tree),
      (MTree T p)
  ==> (If p = null
        then \[T = Leaf]
        else \exists n p1 p2 T1 T2, \[T = Node n T1 T2]
             \* (p ~~~>`{ item := n; left := p1; right := p2 })
             \* (MTree T1 p1) \* (MTree T2 p2)).
Proof using.
  intros. destruct T as [|n T1 T2].
  { xchange MTree_Leaf. intros M. case_if. xsimpl*. }
  { xchange MTree_Node. intros p1 p2.
    xchange hrecord_not_null. intros N. case_if. xsimpl*. }
Qed.

Opaque MTree.
```

树的良基关系是**直接子树**，注意要自己证明良基性并注册（`list_sub` 是库自带
的，`tree_sub` 是本章新增）：

```coq
Inductive tree_sub : binary (tree) :=
  | tree_sub_1 : forall n T1 T2,
      tree_sub T1 (Node n T1 T2)
  | tree_sub_2 : forall n T1 T2,
      tree_sub T2 (Node n T1 T2).

Lemma tree_sub_wf : wf tree_sub.
Proof using.
  intros T. induction T; constructor; intros t' H; inversions~ H.
Qed.

#[global] Hint Resolve tree_sub_wf : wf.
```

树的智能构造器 `mnode` 由三字段记录分配原语包装而成，同样有记录层与「转移子
树所有权」两层规格：

```coq
Definition mnode : val :=
  val_new_hrecord_3 item left right.

Lemma triple_mnode : forall n p1 p2,
  triple (mnode n p1 p2)
    \[]
    (funloc p => p ~~~> `{ item := n ; left := p1 ; right := p2 }).
Proof using. intros. apply triple_new_hrecord_3; auto. Qed.

Lemma triple_mnode' : forall T1 T2 n p1 p2,
  triple (mnode n p1 p2)
    (MTree T1 p1 \* MTree T2 p2)
    (funloc p => MTree (Node n T1 T2) p).
Proof using.
  intros. xapp triple_mnode. intros p.
  xchange <- MTree_Node. xsimpl*.
Qed.

#[global] Hint Resolve triple_mnode' : triple.
```

**练习（2 星）triple_mnode'**：套用记录层规格后折回 `MTree_Node` 即得——所
谓「所有权转移」：调用者交出两棵子树，拿回一棵含它们的大树。

### 94.11 练习：树的深拷贝与求和

```coq
(* ---------- 94.11 练习：树的深拷贝与求和 ---------- *)

Definition tree_copy :=
  <{ fix 'f 'p =>
       let 'b = ('p = null) in
       if 'b then null else (
         let 'n = 'p`.item in
         let 'p1 = 'p`.left in
         let 'p2 = 'p`.right in
         let 'q1 = 'f 'p1 in
         let 'q2 = 'f 'p2 in
         mnode 'n 'q1 'q2
      ) }>.

Lemma triple_tree_copy : forall p T,
  triple (tree_copy p)
    (MTree T p)
    (funloc q => (MTree T p) \* (MTree T q)).
Proof using.
  intros. gen p. induction_wf IH: tree_sub T.
  xwp. xapp. xchange MTree_if. xif; intros C; case_if; xpull.
  { intros E. subst T. xval.
    xchange <- (MTree_Leaf null). { auto. } xsimpl*.
    rewrite C0. xchange <- (MTree_Leaf null). { auto. } }
  { intros n p1 p2 T1 T2 E. subst T.
    xapp. xapp. xapp.
    xapp. { apply tree_sub_1. } intros q1.
    xapp. { apply tree_sub_2. } intros q2.
    xapp. intros p'.
    xchange <- MTree_Node. xsimpl*. }
Qed.
```

**练习（3 星）**：`mcopy` 的树版。四个看点：(1) 空树分支里两次「凭空造
`MTree Leaf _`」——一次给返回值（`funloc` 的存在变量由 `xsimpl*` 统一成
`null`），一次给「原样归还」的原树，后者要先用 `rewrite C0` 把 `p` 化成
`null`（**注意** `xif` 给的 `C` 是值层的 `val_loc p = val_loc null`，改写不了
目标；`case_if` 给的 `C0 : p = null` 才是位置层的，能用）；(2) 两处 `subst T`
而不是 `intros ... ->`——`T` 出现在归纳假设里，`intros ->` 只改目标会失败，
`subst` 全局替换才行；(3) 两次递归调用的良基义务要**显式给构造子**
（`apply tree_sub_1 / tree_sub_2`，实测 `xapp` 不会自动消解）；(4) 最后
`mnode` 自动走 `triple_mnode'` 的 hint，折回 `MTree_Node` 收尾。

求和版（用累加引用）：

```coq
Definition treeacc : val :=
  <{ fix 'f 'c 'p =>
       let 'b = ('p <> null) in
       if 'b then
         let 'm = ! 'c in
         let 'x = 'p`.item in
         let 'm2 = 'm + 'x in
         'c := 'm2;
         let 'p1 = 'p`.left in
         'f 'c 'p1;
         let 'p2 = 'p`.right in
         'f 'c 'p2
       end }>.

Definition mtreesum : val :=
  <{ fun 'p =>
       let 'c = ref 0 in
       treeacc 'c 'p;
       get_and_free 'c }>.

Fixpoint treesum (T:tree) : int :=
  match T with
  | Leaf => 0
  | Node n T1 T2 => n + treesum T1 + treesum T2
  end.

Lemma triple_treeacc : forall T p c n,
  triple (treeacc c p)
    (c ~~> n \* MTree T p)
    (fun _ => c ~~> (n + treesum T) \* MTree T p).
Proof using.
  intros T. induction_wf IH: tree_sub T. intros p c n.
  xwp. xapp. xchange MTree_if. xif; intros C; case_if; xpull.
  { intros n0 p1 p2 T1 T2 E. subst T.
    xapp. xapp. xapp. xapp.
    xapp.
    xapp. { apply tree_sub_1. }
    xapp.
    xapp. { apply tree_sub_2. }
    xsimpl. math.
    xchange <- MTree_Node. }
  { intros E. subst T. xval. xsimpl. simpl. math.
    rewrite C0. xchange <- (MTree_Leaf null). { auto. } }
Qed.

Lemma triple_mtreesum : forall T p,
  triple (mtreesum p)
    (MTree T p)
    (fun r => \[r = treesum T] \* (MTree T p)).
Proof using.
  intros. xwp. xapp. intros c.
  xapp triple_treeacc.
  xapp. xsimpl. math.
Qed.
```

**练习（4 星，选做）**：`acclength` 的树版，结构完全平行——八个 `xapp` 对应
「读累加器、读元素、相加、写回、读左、递归左、读右、递归右」。空树分支里
`treesum Leaf` 不会自动算开，补一句 `simpl` 再 `math`（`treesum` 不透明于
`lia`）。

### 94.12 带局部状态的计数器函数

第一个「返回**函数**」的程序——高阶函数与私有状态：

```coq
(* ---------- 94.12 带局部状态的计数器函数 ---------- *)

Definition create_counter : val :=
  <{ fun 'u =>
       let 'p = ref 0 in
       (fun_ 'u => (incr 'p; !'p)) }>.

Definition CounterSpec (f:val) (p:loc) : Prop :=
  forall m, triple (f ())
                    (p ~~> m)
                    (fun r => \[r = m+1] \* p ~~> (m+1)).

Implicit Type f : val.

Lemma triple_create_counter :
  triple (create_counter ())
    \[]
    (fun f => \exists p, (p ~~> 0) \* \[CounterSpec f p]).
Proof using.
  xwp. xapp. intros p.
  xfun. intros f Hf.
  xsimpl.
  { intros m.
    xapp.
    xapp. xapp. xsimpl. auto. }
Qed.
```

`fun_ 'u => ...` 是程序层 λ 的记号。`CounterSpec f p` 是一个**嵌套三元组**的
命题：「对任何 `m`，以 `p ~~> m` 调用 `f ()` 返回 `m+1`」——三元组套三元组，
靠的是 Rocq 谓词的非直谓性。证明的新主角是 **`xfun`**：处理局部函数定义，给
出假设 `Hf`（「以任意前后条件调用 `f` 的泛规格」）；随后的 `xapp` 自动调
`Hf`，对函数体照常符号执行。

直接版规格暴露了内部引用 `p`。抽象版把它藏进**表示谓词**：

```coq
Definition IsCounter (f:val) (n:int) : hprop :=
  \exists p, p ~~> n \* \[CounterSpec f p].

Lemma triple_create_counter_abstract :
  triple (create_counter ())
    \[]
    (fun f => IsCounter f 0).
Proof using. unfold IsCounter. apply triple_create_counter. Qed.
```

调用端的抽象规格是本章最难的练习之一：

```coq
Lemma triple_apply_counter_abstract : forall f n,
  triple (f ())
    (IsCounter f n)
    (fun r => \[r = n+1] \* (IsCounter f (n+1))).
Proof using.
  xtriple. unfold IsCounter. xpull. intros p Hc.
  xapp Hc. xsimpl. auto. auto.
Qed.

Opaque IsCounter.
```

**练习（4 星）**：`xtriple` 把抽象函数调用变成可操作的目标，`xpull` 拆开
`IsCounter` 拿到 `p` 与 `Hc : CounterSpec f p`，然后 **`xapp Hc`**——把命题假
设当规格用——一步到位；剩下两个小目标（`n+1 = n+1` 与 `CounterSpec f p`，后
者就是 `Hc`）各一个 `auto`。客户端程序：

```coq
Definition test_counter : val :=
  <{ fun 'u =>
       let 'c1 = create_counter () in
       let 'c2 = create_counter () in
       let 'n1 = 'c1 () in
       let 'n2 = 'c2 () in
       let 'n3 = 'c1 () in
       'n2 + 'n3 }>.

Lemma triple_test_counter :
  triple (test_counter ())
    \[]
    (fun r => \[r = 3] \* (\exists H, H)).
Proof using.
  xwp.
  xapp triple_create_counter_abstract. intros c1.
  xapp triple_create_counter_abstract. intros c2.
  xapp triple_apply_counter_abstract.
  xapp triple_apply_counter_abstract.
  xapp triple_apply_counter_abstract.
  xapp. xsimpl. math.
Qed.
```

**练习（2 星，选做）**：两个计数器交替调用，结果 `1 + 2 = 3`。后条件里的
`\exists H, H` 是「内存里还剩一些我们无法描述（也无法释放）的东西」——两个
计数器的内部引用。最小 SL 里这块垃圾扔不掉，103 章的仿射逻辑解决它。

### 94.13 高阶迭代算子：repeat 与 miter

**验证高阶函数**是分离逻辑的招牌能力。先看简单的 `repeat f n`（执行 `f()`
共 `n` 次）：

```coq
(* ---------- 94.13 高阶迭代算子 repeat 与 miter ---------- *)

Definition repeat : val :=
  <{ fix 'g 'f 'n =>
       let 'b = ('n > 0) in
       if 'b then
         'f ();
         let 'n2 = 'n - 1 in
         'g 'f 'n2
       end }>.

Lemma triple_repeat : forall (I:int->hprop) (f:val) (n:int),
  n >= 0 ->
  (forall i, 0 <= i < n ->
    triple (f ())
      (I i)
      (fun u => I (i+1))) ->
  triple (repeat f n)
    (I 0)
    (fun u => I n).
Proof using.
  introv Hn Hf.
  cuts G: (forall m, 0 <= m <= n ->
    triple (repeat f m)
      (I (n-m))
      (fun u => I n)).
  { replace 0 with (n - n). { eapply G. math. } { math. } }
  intros m. induction_wf IH: (downto 0) m. intros Hm.
  xwp. xapp. xif; intros C.
  { xapp. { math. } xapp.
    xapp. { math. } { math. }
    math_rewrite ((n - m) + 1 = n - (m - 1)). xsimpl. }
  { xval. math_rewrite (n - m = n). xsimpl. }
Qed.
```

规格的形状是**循环不变量**风格：`I : int -> hprop` 描述「循环进行到第 `i` 步
时的状态」，前提说 `f` 每步把 `I i` 推进到 `I (i+1)`，结论说 `n` 步后从 `I 0`
到达 `I n`——**调用者自己挑不变量**，规格对任意 `I` 都成立。证明技巧：先
`cuts G:` 陈述一个**更一般的命题**（还剩 `m` 步时从 `I (n-m)` 走到 `I n`），
主命题取 `m := n` 特化（`replace 0 with (n - n)` 拼出 `I 0`）；归纳中
`math_rewrite`（TLC：「先证等式再立即改写」）处理 `I` 下标的算术。

压轴的 `miter`（对链表逐元素调用 `f`）是 5 星练习，规格把不变量升级为
**前缀索引** `I : list val -> hprop`：

```coq
Definition miter : val :=
  <{ fix 'g 'f 'p =>
       let 'b = ('p <> null) in
       if 'b then
         let 'x = 'p`.head in
         'f 'x;
         let 'q = 'p`.tail in
         'g 'f 'q
       end }>.

Lemma triple_miter : forall (I:list val->hprop) L (f:val) p,
  (forall x L1 L2, L = L1++x::L2 ->
    triple (f x)
      (I L1)
      (fun u => I (L1++(x::nil)))) ->
  triple (miter f p)
    (MList L p \* I nil)
    (fun u => MList L p \* I L).
Proof using.
  introv Hf.
  cuts G: (forall L2 L1 p,
    L = L1 ++ L2 ->
    triple (miter f p)
      (MList L2 p \* I L1)
      (fun u => MList L2 p \* I L)).
  { applys G L (@nil val). rew_list. auto. }
  intros L2. induction_wf IH: list_sub L2. intros L1 p0 HL.
  xwp. xapp. xchange MList_if. xif; intros C; case_if; xpull.
  { intros x q L2' E. subst L2.
    xapp.
    xapp Hf. { apply HL. }
    xapp.
    xapp.
    { apply list_sub_cons. }
    { rewrite HL. rew_list. auto. }
    xchange <- MList_cons. }
  { intros ->. xval. xsimpl.
    rewrite HL. rew_list.
    rewrite (MList_nil p0). xsimpl. auto. }
Qed.
```

解题思路分四步：

1. **泛化**：把「从表头开始」一般化为「从**任意剩余段** `L2` 开始、已走前缀
   为 `L1`」，前提 `L = L1 ++ L2` 把两段拼回整表；主命题取 `L2 := L, L1 :=
   nil`。
2. **归纳方向**：对**剩余段 `L2`**（递减方）归纳，前缀自然增长——若对前缀归
   纳，`list_sub (L1 ++ x::nil) L1` 根本不成立。
3. **cons 分支**：调 `f x` 用 `xapp Hf`，其前提 `L = L1 ++ x :: L2'` 恰是
   `HL`（`apply HL` 直接交）；递归调用的两个义务分别是良基性
   （`apply list_sub_cons`）与前缀拼接等式（`rewrite HL. rew_list. auto.`）；
   最后折回头单元。
4. **nil 分支**：`HL : L = L1 ++ nil` 配合 `rew_list` 把 `I L` 化成 `I L1`；
   「归还空表」要先 `rewrite (MList_nil p0)` 把 `MList nil p0` 变成纯事实
   `\[p0 = null]`，交给 `auto`（用 `C : p0 = null`）。

有了 `miter`，「用迭代器数表长」就是对它的一个实例化：

```coq
Definition mlength_using_miter : val :=
  <{ fun 'p =>
       let 'c = ref 0 in
       let 'f = (fun_ 'x => incr 'c) in
       miter 'f 'p;
       get_and_free 'c }>.

Lemma triple_mlength_using_miter : forall p L,
  triple (mlength_using_miter p)
    (MList L p)
    (fun r => \[r = length L] \* MList L p).
Proof using.
  intros. xwp. xapp. intros c.
  xfun. intros f Hf.
  xapp (>> triple_miter (fun (K:list val) => c ~~> (length K : int)) L f p).
  { intros x L1 L2 E. applys Hf. xapp. xsimpl. rew_list. math. }
  xapp. xsimpl. math.
Qed.
```

**练习（4 星）**。三个实测要点：

- 不变量要在 `xapp` 时**显式提供**，语法是 `xapp (>> triple_miter 不变量 其余
  参数)`——`(>>)` 按位置预填引理参数；匿名函数的参数**必须写类型标注**
  （`(fun (K:list val) => ...)`，否则 `length K` 推不出 `K` 的类型报
  `Cannot infer ... boxer`）；
- 单元格里存的是 `int`，而 `length K` 是 nat——写成 `c ~~> (length K : int)`
  显式触发 `nat → int` 强制转换（TLC 注册了 `nat_to_Z`），否则 `incr` 的规格
  （int 版）套不上；
- 局部函数 `f` 的行为义务：`applys Hf` 先把 `Hf`（`xfun` 的泛规格）特化成
  「`f x` 在 `c ~~> length L1` 下把计数器加一」，再 `xapp` 执行 `incr`、
  `rew_list + math` 对账 `length L1 + 1 = length (L1 ++ x::nil)`。

### 94.14 CPS 风格：阶乘与 append（选读）

**续延传递风格**（continuation-passing style，CPS）把「返回后做什么」做成参
数 `k` 传下去——递归调用发生在**自定义续延内部**，是验证的经典难题（Reynolds
当年拿它当公开挑战）。先做无状态的阶乘：

```coq
(* ---------- 94.14 CPS 风格：阶乘与 append ---------- *)

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

Definition cps_facto_aux : val :=
  <{ fix 'f 'n 'k =>
       let 'b = 'n <= 1 in
       if 'b
         then 'k 1
         else let 'k2 = (fun_ 'r => let 'r2 = 'n * 'r in 'k 'r2) in
              let 'n2 = 'n - 1 in
              'f 'n2 'k2 }>.

Definition cps_facto : val :=
  <{ fun 'n  =>
       let 'k = (fun_ 'r => 'r) in
       cps_facto_aux 'n 'k }>.
```

续延的规格**不描述状态**，只描述「行为」：用一个数学函数 `F : int -> int` 刻
画「对任何输入 `a`，调用 `k a` 最终返回 `F a`」：

```coq
Lemma triple_cps_facto_aux : forall (n:int) (k:val) (F:int->int),
  n >= 0 ->
  (forall (a:int), triple (k a) \[] (fun r => \[r = F a])) ->
  triple (cps_facto_aux n k)
    \[]
    (fun r => \[r = F (facto n)]).
Proof using.
  intros n. induction_wf IH: (downto 0) n. introv Hn Hk.
  xwp. xapp. xif; intros C.
  { rewrite facto_init; [|math].
    xapp Hk. xsimpl. math. }
  { xfun. intros k2 Hk2.
    xapp.
    xapp (>> IH (fun a => F (n * a))).
    all: try math.
    { intros a. applys Hk2. xapp. xapp Hk. xsimpl. math. }
    xsimpl. rewrite <- (@facto_step n); [|math]. auto. }
Qed.
```

**练习（4 星，选做）**，要点逐个看：

- 量词顺序 `intros n` 在前、归纳、再 `introv Hn Hk`——因为**续延 `k` 与其
  行为 `F` 在递归中都会变**，必须留在归纳假设的全称量词里；
- then 分支（`n <= 1`）：`facto n = 1` 先用 `rewrite facto_init` 化掉，
  `xapp Hk` 调用续延；
- else 分支：`xfun` 拿到新续延 `k2` 的泛规格 `Hk2`；递归调用用
  `xapp (>> IH (fun a => F (n * a)))` **指定新续延的行为函数**（`k2` 收到 `a`
  后先乘 `n` 再交给 `k`，所以行为是 `a ↦ F (n*a)`）；
- `k2` 的行为义务：`applys Hk2` 特化后符号执行其函数体（乘法 `xapp`、原续延
  `xapp Hk`）；
- 递归后的多个算术义务**顺序不定**，实测用 `all: try math` 一网打尽，再处
  理行为义务；
- 收尾的 `F (n * facto (n-1)) = F (facto n)`：`F` 不透明，`math` 推不动，用
  `rewrite <- (@facto_step n); [|math]` 把乘积折回 `facto n`，`auto` 收官。

主函数代入恒等续延：

```coq
Lemma triple_cps_facto : forall n,
  n >= 0 ->
  triple (cps_facto n)
    \[]
    (fun r => \[r = facto n]).
Proof using.
  introv Hn. xwp.
  xfun. intros k Hk.
  xapp (>> triple_cps_facto_aux n k (fun (a:int) => a)).
  { math. }
  { intros a. applys Hk. xval. xsimpl. auto. }
  xsimpl. math.
Qed.
```

**练习（2 星）**：恒等续延的行为函数是 `fun (a:int) => a`（同样**必须带类型
标注**）。

最后的 Boss 战——**CPS 版就地拼接**。注意递归调用 `'f 'q1 'p2 'k2` 发生在
`k2` 的「外部」但 `k2` 捕获了 `p1`：每个单元的续延负责把自己的 tail 接到结果
上。CPS 里框架规则不好使，规格必须**显式量化「其余状态」`H` 与后条件 `Q`**：

```coq
Definition cps_append_aux : val :=
  <{ fix 'f 'p1 'p2 'k =>
       let 'b = ('p1 = null) in
       if 'b
         then 'k 'p2
         else
           let 'q1 = 'p1`.tail in
           let 'k2 = (fun_ 'r => ('p1`.tail := 'r; 'k 'p1)) in
           'f 'q1 'p2 'k2 }>.

Definition cps_append : val :=
  <{ fun 'p1 'p2 =>
      let 'f = (fun_ 'r => 'r) in
      cps_append_aux 'p1 'p2 'f }>.
```

```coq
Lemma triple_cps_append_aux : forall H Q (L1 L2:list val) (p1 p2:loc) (k:val),
  (forall (p3:loc), triple (k p3) (MList (L1 ++ L2) p3 \* H) Q) ->
  triple (cps_append_aux p1 p2 k)
    (MList L1 p1 \* MList L2 p2 \* H)
    Q.
Proof using.
  introv Hk.
  cuts G: (forall (L1':list val) (H':hprop) (p1':loc) (k':val),
    (forall p3, triple (k' p3) (MList (L1' ++ L2) p3 \* H') Q) ->
    triple (cps_append_aux p1' p2 k')
      (MList L1' p1' \* MList L2 p2 \* H')
      Q).
  { applys G L1 H p1 k. auto. }
  intros L1'. induction_wf IH: list_sub L1'. intros H' p1' k' Hk'.
  xwp. xapp. xchange (MList_if p1'). xif; intros C; case_if; xpull.
  { intros ->. xapp Hk'. intros x. auto. }
  { intros x q L1'' E. subst L1'.
    xapp.
    xfun. intros k2 Hk2.
    xapp (>> IH L1'' ((p1' ~~~> `{ head := x; tail := q }) \* H')).
    { apply list_sub_cons. }
    intros p3.
    applys (Hk2 p3 (MList (L1'' ++ L2) p3
                \* (p1' ~~~> `{ head := x; tail := q }) \* H')).
    xapp.
    xchange <- MList_cons.
    xapp Hk'.
    intros x0. auto.
    intros x0. auto. }
Qed.
```

**练习（5 星，选做）**，解题的五个关键决策：

1. **泛化哪些量**：`cuts G` 把 `L1`、`H`（显式帧）、`p1`、`k` 全部量化——递
   归时第一段的表变短、位置变成 `q`、帧多出一块头单元记录、续延换成 `k2`。
   少量化任何一个，特化时就会对不上（实测：量化的 binder 要写全类型，否则
   `k` 会被推成 `loc -> trm`）；
2. **递归调用**：`xapp (>> IH L1'' ((记录) \* H'))` 依次预填「剩余段、新帧」
   ——`(>>)` 按位填参，第一个参数是归纳关系的操作数；
3. **`k2` 的行为义务**：对任意 `p3`，证明
   `triple (k2 p3) (MList (L1''++L2) p3 \* 记录 \* H') Q`。这里 `applys Hk2`
   的自动实例化会抓错帧，实测要**显式给全参数** `applys (Hk2 p3 (完整前条
   件))`——且 `\*` 的结合顺序要写成默认的左结合，否则统一失败报
   `No applicable tactic`；
4. **执行 `k2` 的函数体**：写回 `p1'.tail := p3`（`xapp`）、把头单元折回成
   `MList (x::(L1''++L2)) p1'`（`xchange <- MList_cons`）、调用原续延
   （`xapp Hk'`，其前提 `(x::L1'')++L2` 恰好吻合）；
5. **收尾的魔杖目标**：`xapp Hk'` 会留下 `forall x0, Q x0 ==> Q x0` 型的义务
   （可能一个或两个，顺序不定）——`intros x0. auto.` 干掉，重复一次兜底。

主函数与 `cps_facto` 同款，只是要给 `@` 显式实例化 `H := \[]`（写作 `hempty`）
与目标后条件：

```coq
Lemma triple_cps_append : forall (L1 L2:list val) (p1 p2:loc),
  triple (cps_append p1 p2)
    (MList L1 p1 \* MList L2 p2)
    (funloc p3 => MList (L1++L2) p3).
Proof using.
  intros. xwp.
  xfun. intros k Hk.
  xapp (@triple_cps_append_aux
          (hempty) (funloc p3 => MList (L1++L2) p3) L1 L2 p1 p2 k).
  intros p3. applys Hk. xval. xsimpl.
  all: try auto.
  all: try (intros x0; auto).
  xsimpl. auto.
Qed.
```

**练习（3 星）**：恒等续延的行为义务走 `applys Hk`，其余小目标（存在变量统
一、`p3 = p3` 等）数量不定，用 `all: try auto. all: try (intros x0; auto).`
扫尾，最后一记 `xsimpl. auto.` 关掉 `funloc` 的存在量化。

### 94.15 本章小结

**概念**：

- 表示谓词把「内存布局」抽象成「逻辑数据」：`MList L p`、`MTree T p`、
  `Stack L s`、`IsCounter f n`——规格只谈逻辑层，实现细节（`null`、字段编
  号、内部指针）全部隐藏；`Opaque` + 折叠/展开/判空三引理是标准配套；
- 证明节奏：**打开**（`xchange MList_if/MList_cons`）→ **符号执行**（`xapp`）
  → **折回**（`xchange <- MList_cons`）；「凭空造空表/空树」用
  `xchange <- (MList_nil null)` 配 `case_if` 的位置级事实；
- 递归规格要**泛化一切会变的量**（位置、幽灵值、帧、续延、行为函数），归纳
  放在真正递减的量上（表结构、树结构、整数）；
- 高阶：`xfun` 处理局部函数，行为规格用数学函数（`F`）或不变量（`I`）刻画，
  `xapp (>> 引理 参数)` 按位预填、匿名函数必须带类型标注；CPS 需要显式量化
  `H` 与 `Q`。

**新 tactic / 新引理速查**：`xchange E`/`xchange <- E`（按等式或蕴含改写状
态）、`xchanges*`（其加强版）、`xpull`（从前条件拉出存在量与纯事实）、
`xif; case_if`（拆条件与经典 `If`）、`xfun`（局部函数）、`xtriple`（抽象调用
目标整形）、`rew_list`（列表表达式规范化）、`math_rewrite`（证等式并立即改
写）、`hrecord_not_null`（非空指针处有记录）、`list_sub`/`tree_sub`（结构良
基关系）。

**实测坑位**（本章调试记录，rocq 9.1.1 与原书 9.0 的差异一并标注）：

- `xapp` 之后目标的**副作用义务顺序不稳定**（shelved goal），习惯用
  `all: try math/try auto` 扫尾再逐个处理；
- `intros ->` 在变量出现于归纳假设时会失败，改用 `intros E. subst 变量`；
- `if 'p <> null` 的**第一分支是 cons/node**，`if 'p = null` 的才是 nil/leaf，
  写反报 `Cannot find a relation to rewrite`；
- `xif` 的 `C` 是值层等式（`val_loc p = val_loc null`），改写要用 `case_if`
  产出的 `C0`；
- `get_and_free` 这类「读并释放」的 `xapp` 已含返回值处理，别再补 `xval`；
- `tree_sub`/`list_sub_cons` 的良基义务要显式 `apply` 构造子；nat 与 int 混用
  时靠 `(e : int)` 触发强制转换。

用户视角到此结业。下一章（95）进入实现者视角：把 `\[]`、`\*`、`p ~~> v` 这些
记号一个个拆开，从 `heap` 的定义开始重建分离逻辑的地基。
