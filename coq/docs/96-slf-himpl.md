# 96 · 蕴含关系：`==>` 与 xsimpl 的理论

对应示例：`../examples/96_slf_himpl.v`（rocq 9.1.1 + SLF 库实测编译退出码 0）

95 章造好了堆谓词的「代数」，本章给它们配上「序」：**蕴含关系**
`H1 ==> H2`（「满足 `H1` 的堆都满足 `H2`」）与后条件版 `===>`。它是分离逻辑
全部推理规则的粘合剂——`xapp` 每处理一次函数调用，背后都是一条「后果-框架规
则」：

```text
      triple t H1 Q1
      H  ==> H1 \* H2        （我的前条件 ⊇ 规格要的 + 剩余）
      Q1 \*+ H2 ===> Q       （规格给的 + 剩余 ⊆ 我要的后条件）
 -------------------------------------------------
      triple t H Q
```

本章三块内容：蕴含的定义与基本性质（含练习解答）；蕴含与星号/量词/纯事实相
互作用的六条规则；然后换上「用户视角」——系统演示 `xsimpl`、`xpull`、
`xchange` 三个 tactic 到底在做什么，附 12 道真假判断题。最后是框架性质的证明
（`xsimpl` 的正确性就建立在这些引理上）。

文件头与 95 章同款，随后自包含复刻 95 章的全部定义（`heap`、五大组合子、
`hprop_eq`、`hstar_hpure_l`）——本章练习要直接用它们，正文不再重复讲解：

```coq
(* 96 蕴含关系 —— himpl/==>/===>、框架性质、量词与纯事实规则、xsimpl/xchange *)
(* 取材 Software Foundations 卷六 Separation Logic Foundations 的 Himpl 章。 *)

Set Implicit Arguments.
From SLF Require Import LibSepReference.
Import ProgramSyntax.

Implicit Types n m : int.
Implicit Types p q : loc.

(* ---------- 96.1 自包含：沿用 95 章的堆谓词定义 ---------- *)

Definition heap : Type := fmap loc val.

Notation "h1 \u h2" := (Fmap.union h1 h2) (at level 37, right associativity).

Definition hprop : Type := heap -> Prop.

Implicit Type H : hprop.

Definition hempty : hprop :=
  fun (h:heap) => (h = Fmap.empty).

Notation "\[]" := (hempty) (at level 0).

Definition hpure (P:Prop) : hprop :=
  fun (h:heap) => (h = Fmap.empty) /\ P.

Notation "\[ P ]" := (hpure P) (at level 0, format "\[ P ]").

Definition hsingle (p:loc) (v:val) : hprop :=
  fun (h:heap) => (h = Fmap.single p v).

Notation "p '~~>' v" := (hsingle p v) (at level 32).

Definition hstar (H1 H2 : hprop) : hprop :=
  fun (h:heap) => exists h1 h2, H1 h1
                             /\ H2 h2
                             /\ Fmap.disjoint h1 h2
                             /\ h = h1 \u h2.

Notation "H1 '\*' H2" := (hstar H1 H2) (at level 41, right associativity).

Definition hexists (A:Type) (J:A->hprop) : hprop :=
  fun (h:heap) => exists x, J x h.

Notation "'\exists' x1 .. xn , H" :=
  (hexists (fun x1 => .. (hexists (fun xn => H)) ..))
  (at level 39, x1 binder, H at level 50, right associativity,
   format "'[' '\exists' '/ '  x1  ..  xn , '/ '  H ']'").

Axiom predicate_extensionality : forall (A:Type) (P Q:A->Prop),
  (forall x, P x <-> Q x) ->
  P = Q.

Lemma hprop_eq : forall (H1 H2:hprop),
  (forall (h:heap), H1 h <-> H2 h) ->
  H1 = H2.
Proof using. apply predicate_extensionality. Qed.

Lemma hstar_hpure_l : forall P H h,
  (\[P] \* H) h = (P /\ H h).
Proof using.
  intros. apply propositional_extensionality. split.
  { intros (h1&h2&M1&M2&D&U). hnf in M1. destruct M1 as (E1&P').
    subst h1. rewrite Fmap.union_empty_l in U. subst h. splits*. }
  { intros (P'&M). hnf. exists (Fmap.empty:heap) h. splits*.
    { hnf. splits*. }
    { rewrite Fmap.union_empty_l. auto. } }
Qed.
```

### 96.2 蕴含的定义与三性

```coq
(* ---------- 96.2 蕴含的定义与三性 ---------- *)

Definition himpl (H1 H2:hprop) : Prop :=
  forall (h:heap), H1 h -> H2 h.

Notation "H1 ==> H2" := (himpl H1 H2) (at level 55).

Lemma himpl_refl : forall H,
  H ==> H.
Proof using. intros h. hnf. auto. Qed.

Lemma himpl_trans : forall H2 H1 H3,
  (H1 ==> H2) ->
  (H2 ==> H3) ->
  (H1 ==> H3).
Proof using. introv M1 M2. intros h H1h. eauto. Qed.

(* 练习（1 星，选做）：反对称——两个方向的蕴含合起来就是相等。 *)

Lemma himpl_antisym : forall H1 H2,
  (H1 ==> H2) ->
  (H2 ==> H1) ->
  H1 = H2.
Proof using.
  introv M1 M2. apply hprop_eq. intros h. iff Hh.
  { applys M1 h Hh. }
  { applys M2 h Hh. }
Qed.
```

`himpl` 一行定义：逐堆的包含。自反、传递一行一个；**反对称**（练习）要借 95
章的外延：两个方向合起来就是逐堆 `iff`，`hprop_eq` 升级成相等。注意证法是
`applys M1 h Hh`——把蕴含当函数用（它本来就是 `forall h, ... -> ...`）。至此
`(hprop, ==>)` 构成**偏序**。后条件版完全平行：

```coq
Definition qimpl (Q1 Q2:val->hprop) : Prop :=
  forall (v:val), Q1 v ==> Q2 v.

Notation "Q1 ===> Q2" := (qimpl Q1 Q2) (at level 55).

Lemma qimpl_refl : forall Q,
  Q ===> Q.
Proof using. intros Q v. apply himpl_refl. Qed.

Lemma qimpl_trans : forall Q2 Q1 Q3,
  (Q1 ===> Q2) ->
  (Q2 ===> Q3) ->
  (Q1 ===> Q3).
Proof using. introv M1 M2. intros v. eapply himpl_trans; eauto. Qed.

Axiom functional_extensionality : forall A B (f g:A->B),
  (forall x, f x = g x) ->
  f = g.

Lemma qprop_eq : forall (Q1 Q2:val->hprop),
  (forall (v:val), Q1 v = Q2 v) ->
  Q1 = Q2.
Proof using. apply functional_extensionality. Qed.

(* 练习（1 星，选做）：后条件蕴含的反对称。 *)

Lemma qimpl_antisym : forall Q1 Q2,
  (Q1 ===> Q2) ->
  (Q2 ===> Q1) ->
  (Q1 = Q2).
Proof using.
  introv M1 M2. applys qprop_eq. intros v. apply hprop_eq. intros h. iff Hh.
  { applys (M1 v) h Hh. }
  { applys (M2 v) h Hh. }
Qed.
```

### 96.3 框架性质：先陈述后证明

星号对蕴含**单调**：`H1 ==> H1'` 则 `(H1 \* H2) ==> (H1' \* H2)`——任意谓词
可以「框」到蕴含两边；反过来看就是「两边同现的 `H2` 可以约去」。这是
`xsimpl` 消项能力的理论核心。先按原书节奏公理化陈述，96.7 节补证明：

```coq
(* ---------- 96.3 蕴含的框架性质（本节先陈述，96.7 给出证明） ---------- *)

Parameter himpl_frame_l : forall H2 H1 H1',
  H1 ==> H1' ->
  (H1 \* H2) ==> (H1' \* H2).
```

### 96.4 证明蕴含的四条规则

处理量词与纯事实的四条「进出规则」，每条两行——它们是 `xsimpl` 第一步与第三
步的雏形：

```coq
(* ---------- 96.4 证明蕴含的四条规则（练习解答） ---------- *)

Lemma himpl_hstar_hpure_r : forall (P:Prop) H H',
  P ->
  (H ==> H') ->
  H ==> (\[P] \* H').
Proof using.
  introv HP M. intros h Hh. rewrite hstar_hpure_l.
  splits*.
Qed.

Lemma himpl_hstar_hpure_l : forall (P:Prop) (H H':hprop),
  (P -> H ==> H') ->
  (\[P] \* H) ==> H'.
Proof using.
  introv M. intros h Hh. rewrite hstar_hpure_l in Hh.
  destruct Hh as (HP&Hh). applys (M HP) h Hh.
Qed.

Lemma himpl_hexists_r : forall A (x:A) H J,
  (H ==> J x) ->
  H ==> (\exists x, J x).
Proof using.
  introv M. intros h Hh. hnf. exists x. applys M Hh.
Qed.

Lemma himpl_hexists_l : forall (A:Type) (H:hprop) (J:A->hprop),
  (forall x, J x ==> H) ->
  (\exists x, J x) ==> H.
Proof using.
  introv M. intros h Hh. hnf in Hh. destruct Hh as (x&Hh).
  applys M x h Hh.
Qed.
```

读法（对照 `xsimpl` 的行为记忆）：

- **`_r` 是「进」**：往右边（目标）塞纯事实/存在量词——证 `P`、给见证 `x`；
- **`_l` 是「出」**：从左边（假设）抽纯事实/存在量词——左侧的 `\[P]` 变成上
  下文假设，左侧的 `\exists x` 变成**外层的全称变量**（「存在变任意」正是洛
  绎推理）。

证明里的 `rewrite hstar_hpure_l`（95 章）把 `(\[P] \* H) h` 直接化成
`P /\ H h`——注意**改写假设要 `in Hh`**，目标里的应用形态才能被匹配。

### 96.5 从堆谓词抽取信息：同一位置的两格是矛盾

```coq
(* ---------- 96.5 从堆谓词抽取信息：同一位置的两格是矛盾 ---------- *)

Lemma hstar_hsingle_same_loc : forall (p:loc) (v1 v2:val),
  (p ~~> v1) \* (p ~~> v2) ==> \[False].
Proof using.
  intros. unfold hsingle. intros h (h1&h2&E1&E2&D&E). false.
  subst. eapply Fmap.disjoint_single_single_same_inv. eapply D.
Qed.
```

`(p ~~> v1) \* (p ~~> v2)` 描述「两块不相交的内存各自恰有一格、且都在 `p`」
——不可能存在。证明把星号拆开，两个「单格映射」的不相交性交给有限映射库的
`disjoint_single_single_same_inv` 导出矛盾。这就是 93 章「别名会让 `xapp` 卡
住」的形式化根源。一般地，`H \* H`（`H` 是具体资源时）在最小分离逻辑里都可
疑——只有 `\[]`、`\[P]` 这类「不占内存」的谓词可以安全地和自身并列。

**练习（3 星，选做）hexists_named_eq**——「命名见证堆」：

```coq
(* 练习（3 星，选做）：任何堆谓词都等价于「先给自己的见证堆命名」。
   (= h) 是只接受恰好等于 h 的堆的谓词。 *)

Lemma hexists_named_eq : forall H,
  H = (\exists h, \[H h] \* (= h)).
Proof using.
  intros. apply hprop_eq. split.
  { intros Hh. hnf. exists h. rewrite hstar_hpure_l. splits*. }
  { intros Hh. hnf in Hh. destruct Hh as (h'&Hh).
    rewrite hstar_hpure_l in Hh. destruct Hh as (Hh&E). subst. auto. }
Qed.
```

任何 `H` 都等于「存在一个堆 `h`：`H` 在 `h` 成立（纯事实）且当前堆恰好是
`h`」——把「谓词」翻译成「先押注一个具体堆」。`(= h)` 是 TLC 的部分应用记
号（`fun h' => h' = h`）。它偶尔能把堆层面的推理转为命题层面的推理。

### 96.6 xsimpl、xpull 与 xchange

手工化简蕴含极其繁琐——本节目的就是让你体会 `xsimpl` 替你做了什么。从这节起
切回**库的实现**（`Import LibSepReference`，包在模块里避免和本文件前半的自制
定义打架）：

```coq
(* ---------- 96.6 xsimpl 与 xchange：蕴含的自动化 ---------- *)

Module XsimplTactic.
Import LibSepReference.
```

**第一步：从左边抽出纯事实与量词。** 左侧的 `\[n > 0]` 变成可引入的假设；
左侧的 `\exists n` 变成外层变量；`\[False]` 直接全灭：

```coq
Lemma xsimpl_demo_lhs_hpure : forall H1 H2 H3 H4 (n:int),
  H1 \* H2 \* \[n > 0] \* H3 ==> H4.
Proof using.
  intros. xsimpl. intros Hn.
Abort.

Lemma xsimpl_demo_lhs_false : forall H1 H2 H3 H4,
  H1 \* H2 \* \[False] \* H3 ==> H4.
Proof using.
  intros. xsimpl.
Qed.

Lemma xsimpl_demo_lhs_hexists : forall H1 H2 H3 H4 (p:loc),
  H1 \* \exists (n:int), (p ~~> n \* H2) \* H3 ==> H4.
Proof using.
  intros. xsimpl. intros n.
Abort.

Lemma xsimpl_demo_lhs_several : forall H1 H2 H3 H4 (p qq:loc),
  H1 \* \exists (n:int), (p ~~> n \* \[n > 0] \* H2) \* \[p <> qq] \* H3 ==> H4.
Proof using.
  intros. xsimpl. intros n Hn Hp.
Abort.
```

**第二步：两边消项。** 同现的谓词全部约去（次序无关）；全消光时自动以自反性
收尾：

```coq
Lemma xsimpl_demo_cancel_one : forall H1 H2 H3 H4 H5 H6 H7,
  H1 \* H2 \* H3 \* H4 ==> H5 \* H6 \* H2 \* H7.
Proof using.
  intros. xsimpl.
Abort.

Lemma xsimpl_demo_cancel_many : forall H1 H2 H3 H4 H5,
  H1 \* H2 \* H3 \* H4 ==> H4 \* H3 \* H5 \* H2.
Proof using.
  intros. xsimpl.
Abort.

Lemma xsimpl_demo_cancel_all : forall H1 H2 H3 H4,
  H1 \* H2 \* H3 \* H4 ==> H4 \* H3 \* H1 \* H2.
Proof using.
  intros. xsimpl.
Qed.
```

**第三步：实例化右侧的量词与纯事实。** 右侧 `\[P]` 拆成子目标；右侧
`\exists n` 先变成 evar `?Goal`，随后常在消项中「顺便」定值——例如与左边的
`p ~~> 3` 对消时 `?Goal := 3`，连带把纯事实目标变成 `3 > 0`：

```coq
Lemma xsimpl_demo_rhs_hpure : forall H1 H2 H3 (n:int),
  H1 ==> H2 \* \[n > 0] \* H3.
Proof using.
  intros. xsimpl.
Abort.

Lemma xsimpl_demo_rhs_hexists : forall H1 H2 H3 H4 (p:loc),
  H1 ==> H2 \* \exists (n:int), (p ~~> n \* H3) \* H4.
Proof using.
  intros. xsimpl.
Abort.

Lemma xsimpl_demo_rhs_hexists_unify : forall H1 H2 H3 H4 (p:loc),
  H1 \* (p ~~> 3) ==> H2 \* \exists (n:int), (p ~~> n \* H3) \* H4.
Proof using.
  intros. xsimpl.
Abort.

Lemma xsimpl_demo_rhs_hexists_unify_view : forall H1 H2 H4 (p:loc),
  H1 \* (p ~~> 3) ==> H2 \* \exists (n:int), (p ~~> n \* \[n > 0]) \* H4.
Proof using.
  intros. xsimpl.
Abort.
```

经常一次 `xsimpl` 就把右侧存在量词全部消化掉：

```coq
Lemma xsimpl_demo_rhs_exists_solved_1 : forall (p:loc),
  p ~~> 3 ==>
  \exists (n:int), p ~~> n.
Proof using. xsimpl. Qed.

Lemma xsimpl_demo_rhs_exists_solved_2 : forall (p qq:loc),
  p ~~> 3 \* qq ~~> 3 ==>
  \exists (n:int), p ~~> n \* qq ~~> n.
Proof using. xsimpl. Qed.
```

需要**手动指定见证**时给参数：`xsimpl v1 .. vn` 按序填入右侧的存在量词；
`__` 表示「这一个留作 evar」：

```coq
Lemma xsimpl_demo_rhs_hints : forall H1 (p qq:loc),
  H1 ==> \exists (n m:int), (p ~~> n \* qq ~~> m).
Proof using.
  intros. xsimpl 8 9.
Abort.

Lemma xsimpl_demo_rhs_hints_evar : forall H1 (p qq:loc),
  H1 ==> \exists (n m:int), (p ~~> n \* qq ~~> m).
Proof using.
  intros. xsimpl __ 9.
Abort.
```

`xsimpl` 同样作用于后条件蕴含（自动展开 `===>`）；`xpull` 是「只做第一步」
的弱化版；`xchange M` 是「蕴含版的 rewrite」（`M` 是等式或蕴含，`xchange <-
M` 反向用），产出的新项总是顶在最前：

```coq
Lemma qimpl_example_1 : forall (Q1 Q2:val->hprop) (H2 H3:hprop),
  Q1 \*+ H2 ===> Q2 \*+ H2 \*+ H3.
Proof using. intros. xsimpl. intros r. Abort.

Lemma xpull_example_1 : forall (p:loc),
  \exists (n:int), p ~~> n ==>
  \exists (m:int), p ~~> (m + 1).
Proof using.
  intros. xpull.
Abort.

Lemma xpull_example_2 : forall (H:hprop),
  \[False] ==> H.
Proof using. xpull. Qed.

Lemma xpull_example_3 : forall (p:loc),
  (\exists (n:int), p ~~> n) ==>
  (\exists (m:int), p ~~> (m + 1)).
Proof using.
  intros.
  xpull. intros n. xsimpl (n-1). math.
Qed.

Lemma xchange_demo_base : forall H1 H2 H2' H3 H4,
  H2 ==> H2' ->
  H1 \* H2 \* H3 ==> H4.
Proof using.
  introv M. xchange M.
Abort.

Lemma xchange_demo_eq : forall H1 H2 H3 H4 H5,
  H1 \* H3 = H5 ->
  H1 \* H2 \* H3 ==> H4.
Proof using.
  introv M. xchange M.
  xchange <- M.
Abort.

Lemma xchange_demo_inst : forall H1 (J J':int->hprop) H3 H4,
  (forall n, J n = J' (n+1)) ->
  H1 \* J 3 \* H3 ==> H4.
Proof using.
  introv M. xchange M.
Abort.
```

`xpull_example_3` 值得细品：直接 `xsimpl` 会得到 `forall x, x = ?Goal + 1`——
技术上可解（`?Goal := x - 1`）但**evar 依赖约束变量**的义务极难处理；正确姿
势是先 `xpull` 把左侧的 `\exists n` 提出来，再 `xsimpl (n-1)` 显式给右侧见
证——这正是 94 章 `mrev` 提示「rew_list 要在 xsimpl 之前」的同一类教训：
**先把左侧信息露出来，再喂给右侧**。

**12 道判断题**（先自己判断真假，再看答案模块；`Parameter` 在此只是「题目陈
述」的载体）：

```coq
Module EntailmentQuiz.


Parameter case_study_1 : forall p qq,
      p ~~> 3 \* qq ~~> 4
  ==> qq ~~> 4 \* p ~~> 3.

Parameter case_study_2 : forall p qq,
      p ~~> 3
  ==> qq ~~> 4 \* p ~~> 3.

Parameter case_study_3 : forall p qq,
      qq ~~> 4 \* p ~~> 3
  ==> p ~~> 3.

Parameter case_study_4 : forall p qq,
      \[False] \* p ~~> 3
  ==> p ~~> 4 \* qq ~~> 4.

Parameter case_study_5 : forall p qq,
      p ~~> 3 \* qq ~~> 4
  ==> \[False].

Parameter case_study_6 : forall p,
      p ~~> 3 \* p ~~> 4
  ==> \[False].

Parameter case_study_7 : forall p,
      p ~~> 3 \* p ~~> 3
  ==> \[False].

Parameter case_study_8 : forall p,
      p ~~> 3
  ==> \exists n, p ~~> n.

Parameter case_study_9 : forall p,
      exists n, p ~~> n
  ==> p ~~> 3.

Parameter case_study_10 : forall p,
      \exists n, p ~~> n \* \[n > 0]
  ==> \exists n, \[n > 1] \* p ~~> (n-1).

Parameter case_study_11 : forall p qq,
      p ~~> 3 \* qq ~~> 3
  ==> \exists n, p ~~> n \* qq ~~> n.

Parameter case_study_12 : forall p n,
      p ~~> n \* \[n > 0] \* \[n < 0]
  ==> p ~~> n \* p ~~> n.

End EntailmentQuiz.
```

**答案**：1 真（交换律）；2 假（一格给不出两格）；3 假（两格收不回一格——
资源只能少不能多……反了，是**蕴含目标只能比前提弱**：前提两格、目标一格，
目标是「至少有一格」——嗯，两格蕴含一格？注意星号的积木性：`q ~~> 4 \* p ~~>
3` 说的是**恰好**这两格，`p ~~> 3` 说的是**恰好**这一格——前者不蕴含后者，
因为多余的 `q ~~> 4` 没地方放）；4 真（`\[False]` 蕴含一切）；5 假（可满足
的谓词不蕴含假）；6、7 真（同位置两格即矛盾）；8 真（`n := 3`）；9 假（注意
题面用的是**朴素** `exists`——见证不能依赖堆，但 `n` 可以是任意值，不必是
3）；10 真（右侧见证取 `n+1`）；11 真（`n := 3`）；12 真（前提里 `n > 0` 与
`n < 0` 同现，等价于 `\[False]`，而 `\[False] ==> H \* H` 对「不占内存」的证
明成立……准确说：`p ~~> n \* p ~~> n` 同位置矛盾，两侧都是假）。可证的那几
条：

```coq
Module EntailmentQuizAnswers.


Lemma case_study_1 : forall p qq,
      p ~~> 3 \* qq ~~> 4
  ==> qq ~~> 4 \* p ~~> 3.
Proof using. xsimpl. Qed.

Lemma case_study_4 : forall p qq,
      \[False] \* p ~~> 3
  ==> p ~~> 4 \* qq ~~> 4.
Proof using. xsimpl. Qed.

Lemma case_study_6 : forall p,
      p ~~> 3 \* p ~~> 4
  ==> \[False].
Proof using. intros. xchange (hstar_hsingle_same_loc p). Qed.

Lemma case_study_7 : forall p,
      p ~~> 3 \* p ~~> 3
  ==> \[False].
Proof using. intros. xchange (hstar_hsingle_same_loc p). Qed.

Lemma case_study_8 : forall p,
      p ~~> 3
  ==> \exists n, p ~~> n.
Proof using. xsimpl. Qed.

Lemma case_study_10 : forall p,
      \exists n, p ~~> n \* \[n > 0]
  ==> \exists n, \[n > 1] \* p ~~> (n-1).
Proof using.
  intros. xpull. intros n Hn. xsimpl (n+1).
  math. math.
Qed.

Lemma case_study_11 : forall p qq,
      p ~~> 3 \* qq ~~> 3
  ==> \exists n, p ~~> n \* qq ~~> n.
Proof using. xsimpl. Qed.

Lemma case_study_12 : forall p n,
      p ~~> n \* \[n > 0] \* \[n < 0] ==> p ~~> n \* p ~~> n.
Proof using. intros. xsimpl. intros Hn1 Hn2. false. math. Qed.

End EntailmentQuizAnswers.
```

看点：6、7 用 `xchange (hstar_hsingle_same_loc p)` 把「同位置两格」整体换成
`\[False]`；10 又是「先 `xpull` 后给见证」的套路；12 抽出两个矛盾假设后
`false; math`。

**手动证明练习**——体会了 xsimpl 的好，回头手搓三题：

```coq
Module EntailmentProofs.

(* 练习（3 星，选做）：手动证明换位蕴含。四块反转 = 六次相邻交换，
   相邻交换恰好就是 hstar_comm_assoc（前两块）或 hstar_comm（后两块）。 *)

Lemma himpl_example_1 : forall p1 p2 p3 p4,
      p1 ~~> 6 \* p2 ~~> 7 \* p3 ~~> 8 \* p4 ~~> 9
  ==> p4 ~~> 9 \* p3 ~~> 8 \* p2 ~~> 7 \* p1 ~~> 6.
Proof using.
  intros.
  rewrite hstar_comm_assoc.
  rewrite (hstar_comm_assoc (p1 ~~> 6) (p3 ~~> 8)).
  rewrite (hstar_comm (p1 ~~> 6) (p4 ~~> 9)).
  rewrite hstar_comm_assoc.
  rewrite (hstar_comm_assoc (p2 ~~> 7) (p4 ~~> 9)).
  rewrite hstar_comm_assoc.
  apply himpl_refl.
Qed.

(* 练习（2 星，选做）：把纯事实换到最前面，用提取规则变成假设，
   两个矛盾假设合出 False。 *)

Lemma himpl_example_2 : forall p1 p2 p3 n,
      p1 ~~> 6 \* \[n > 0] \* p2 ~~> 7 \* \[n < 0]
  ==> p3 ~~> 8.
Proof using.
  intros.
  rewrite hstar_comm_assoc.
  applys himpl_hstar_hpure_l. intros Hn.
  rewrite hstar_comm_assoc.
  rewrite (hstar_comm (p1 ~~> 6) (\[n < 0])).
  rewrite hstar_comm_assoc.
  applys himpl_hstar_hpure_l. intros Hn2.
  false. math.
Qed.

(* 练习（2 星，选做）：左右两侧的存在量词分别用提取/提供规则处理。 *)

Lemma himpl_example_3 : forall p,
  \exists n, p ~~> n \* \[n > 0]
  ==> \exists n, \[n > 1] \* p ~~> (n-1).
Proof using.
  intros.
  applys himpl_hexists_l. intros n.
  rewrite hstar_comm.
  applys himpl_hstar_hpure_l. intros Hn.
  applys himpl_hexists_r (n+1).
  applys himpl_hstar_hpure_r. { math. }
  math_rewrite (n+1-1 = n).
  applys himpl_refl.
Qed.

End EntailmentProofs.

End XsimplTactic.
```

- **例 1**：四块全换位。手搓思路是把「反转」分解成六次相邻交换；`\*` 是右结
  合记号，前两块的交换恰是 `hstar_comm_assoc`，最内两块的交换是 `hstar_comm`
  ——带参数的 `rewrite` 指定交换对象，不带参数的在最外层。
- **例 2**：两次「换位 + `himpl_hstar_hpure_l` 提取」把 `n > 0` 与 `n < 0` 都
  变成假设，`false. math.` 收场。
- **例 3**：左提取（`\exists` 变全称、纯事实变假设）、右提供（`himpl_hexists_r
  (n+1)` 给见证、`himpl_hstar_hpure_r` 塞回纯事实）、`math_rewrite` 处理
  `n+1-1`——`xsimpl (n+1)` 一行干完的所有事。

### 96.7 蕴含框架性质的证明（选读）

`xsimpl` 的消项建立在这些引理上，所以它们必须先于 `xsimpl` 存在、不能用
`xsimpl` 证。先用 95 章的证明复刻本文件需要的星号定律：

```coq
(* ---------- 96.7 蕴含框架性质的证明（选读） ---------- *)

(* 先备好本文件要用到的星号定律（95 章已证，此处自包含复刻）。 *)

Module HpropLaws.

Lemma hprop_op_comm : forall (op:hprop->hprop->hprop),
  (forall H1 H2 h, op H1 H2 h -> op H2 H1 h) ->
  (forall H1 H2, op H1 H2 = op H2 H1).
Proof using. introv M. intros. apply hprop_eq. split; apply M. Qed.

Lemma hstar_comm : forall H1 H2,
   H1 \* H2 = H2 \* H1.
Proof using.
  apply hprop_op_comm.
  introv (h1&h2&M1&M2&D&U).
  exists h2 h1. subst. splits~.
  { rewrite Fmap.union_comm_of_disjoint; auto. }
Qed.

Lemma hstar_hempty_l : forall H,
  \[] \* H = H.
Proof using.
  intros. apply hprop_eq. split.
  { intros (h1&h2&M1&M2&D&U). hnf in M1. subst h1.
    rewrite Fmap.union_empty_l in U. subst. auto. }
  { intros M. hnf. exists (Fmap.empty:heap) h. splits~.
    { hnf. auto. }
    { rewrite Fmap.union_empty_l. auto. } }
Qed.

Lemma hstar_hempty_r : forall H,
  H \* \[] = H.
Proof using.
  intros. rewrite hstar_comm. rewrite hstar_hempty_l. auto.
Qed.

Lemma hstar_assoc : forall H1 H2 H3,
  (H1 \* H2) \* H3 = H1 \* (H2 \* H3).
Proof using.
  intros. apply hprop_eq. split.
  { intros (h'&h3&M1&M2&D&U). destruct M1 as (h1&h2&M3&M4&D'&U').
    subst h'. rewrite Fmap.disjoint_union_eq_l in D.
    exists h1 (h2 \u h3). splits.
    { apply M3. }
    { exists* h2 h3. }
    { rewrite* @Fmap.disjoint_union_eq_r. }
    { rewrite* @Fmap.union_assoc in U. } }
  { intros (h1&h23&M1&M2&D&U). destruct M2 as (h2&h3&M3&M4&D'&U').
    subst h23. rewrite Fmap.disjoint_union_eq_r in D.
    exists (h1 \u h2) h3. splits.
    { exists* h1 h2. }
    { apply M4. }
    { rewrite* @Fmap.disjoint_union_eq_l. }
    { rewrite* <- @Fmap.union_assoc in U. } }
Qed.

Lemma hstar_comm_assoc : forall H1 H2 H3,
  H1 \* H2 \* H3 = H2 \* H1 \* H3.
Proof using.
  intros. rewrite <- hstar_assoc. rewrite (hstar_comm H1 H2).
  rewrite hstar_assoc. auto.
Qed.

End HpropLaws.

Import HpropLaws.

Module EntailmentRulesProofs.

Lemma himpl_frame_l : forall H2 H1 H1',
  H1 ==> H1' ->
  (H1 \* H2) ==> (H1' \* H2).
Proof using.
  introv M. intros h (h1&h2&M1&M2&D&U).
  exists h1 h2. splits*.
Qed.

Lemma himpl_frame_r : forall H1 H2 H2',
  H2 ==> H2' ->
  (H1 \* H2) ==> (H1 \* H2').
Proof using.
  introv M. intros h (h1&h2&M1&M2&D&U).
  exists h1 h2. splits*.
Qed.

Lemma himpl_frame_lr : forall H1 H1' H2 H2',
  H1 ==> H1' ->
  H2 ==> H2' ->
  (H1 \* H2) ==> (H1' \* H2').
Proof using.
  introv M1 M2. intros h (h1&h2&M1'&M2'&D&U).
  exists h1 h2. splits*.
Qed.

End EntailmentRulesProofs.
```

三条框架引理的证明是同一个模板：拆开左边的星号，**原样交回**两块——变化只
发生在被蕴含修饰的那一块（`splits*` 的 `eauto` 会自动用 `M`/`M1`/`M2` 改写
对应的小目标）。注意「先证框架再用 xsimpl」的依赖顺序，以及 `himpl_frame_r`
本可用交换律从 `_l` 推出，但直证同样只有三行。最后补上 96.6 承诺的
`xchange` 核心引理（它解释了 `xchange M` 的全部行为——左边拆出 `H1 \* H2`，
前者按 `M` 换新，再接续右边的蕴含）：

```coq
Import EntailmentRulesProofs.

(* 练习（2 星）：xchange 的核心引理——先把左边拆出 H1 \* H2，
   前者换成 H1'，再接上右边的蕴含。 *)

Lemma xchange_lemma : forall H1 H1' H H' H2,
  H1 ==> H1' ->
  H ==> H1 \* H2 ->
  H1' \* H2 ==> H' ->
  H ==> H'.
Proof using.
  introv M1 M2 M3.
  applys himpl_trans M2.
  applys himpl_trans (himpl_frame_lr M1 (himpl_refl H2)).
  applys M3.
Qed.
```

两次传递：`H ==> H1 \* H2`（假设），再 `(H1 \* H2) ==> (H1' \* H2)`（框架，
其中 `H2` 那份按自反不动），最后 `(H1' \* H2) ==> H'`（假设）。

### 96.8 本章小结

**概念**：`==>`/`===>` 是堆谓词/后条件上的偏序（自反、传递、反对称——反对称
靠外延公理）；框架性质 = 星号对蕴含的单调性 = 消项的合法来源；四条进出规则
（纯事实/量词 × 左出右进）；`H \* H` 的可疑性（同位置两格 = 矛盾）。

**tactic**（对照理论记忆）：`xsimpl` = 左抽出（`_l` 规则）+ 消项（框架）+
右实例化（`_r` 规则）；`xsimpl v1..vn` 给右侧见证、`__` 跳过；`xpull` 只做
左抽出；`xchange M`/`xchange <- M` 是蕴含/等式版的 rewrite，实现就是
`xchange_lemma`。

**实测坑位**：

- `apply hprop_eq. split.` 会自动引入 `h`（再 `intros h` 报 already used）；
- 改写**假设**里的星号要 `rewrite hstar_hpure_l in Hh`；
- 模块内 `Import LibSepReference` 后，`q` 等名字与库的程序变量常量冲突——绑
  定名要换（还要避开带数字/下划线的名字，`Implicit Types` 不接受）；同理
  `Implicit Types p q : loc` 在模块内不可用；
- `applys` 按位喂参时注意隐式参数（`himpl_frame_l` 的框架变量是隐式的，单独
  apply 可能推不出——`himpl_frame_lr M (himpl_refl H2)` 这类显式组合更稳）；
- evar 依赖约束变量的目标（`forall x, x = ?Goal + 1`）要避开：先 `xpull` 左
  侧、再带见证 `xsimpl (n-1)`。

下一章（97）给「程序执行」本身建立数学模型：语言的语法、操作语义，以及
`triple` 的定义。
