# 99 · 魔法杖：hwand、qwand 与分支框架规则

对应示例：`../examples/99_slf_wand.v`（rocq 9.1.1 + SLF 库实测编译退出码 0）

95/96 章搭好了堆谓词代数（`\[]`、`\[P]`、`p ~~> v`、`\*`、`\exists`）与蕴含
关系；本章（对应原书 Wand 章）补上剩下的算子：**析取 `hor`**、**非分离合取
`hand`**、**全称量词 `hforall`**，以及本章主角——**魔法杖 `H1 \-* H2`** 与
它的后条件版 `Q1 \--* Q2`。

魔法杖的三大用途：

1. 表述**分支框架规则**（ramified frame rule）——比后果-框架规则更好用的
   框架推理形式，`xapp` 的现代化实现都靠它；
2. 101 章将用它定义**最弱前条件生成器**（wpgen）；
3. 给某些数据结构的规格提供紧凑表述。

一个贯穿本章的「元技巧」：新算子尽量**用已有算子定义**（而不是直接写成堆
上的函数），这样它们的全部性质都能用 `xsimpl` 在 `hprop` 层证明，不必下到
具体的堆与不相交性。文件头与两个小工具（96 章的 `hprop_eq`，这里用库底层
的 `fun_ext_dep`/`prop_ext` 外延公理三行重建）：

```coq
(* 99 魔法杖：hwand/qwand、hforall/hor/hand 与分支框架规则 *)
(* 取材 Software Foundations 卷六 Separation Logic Foundations 的 Wand 章。 *)

Set Implicit Arguments.
From SLF Require Import LibSepReference.

Implicit Types h : heap.
Implicit Types P : Prop.
Implicit Types H : hprop.
Implicit Types Q : val->hprop.

(* 96 章的 hprop_eq 在本章多处用到（库以 LibAxioms 的外延公理为底）。 *)

Lemma hprop_eq : forall (H1 H2:hprop),
  (forall (h:heap), H1 h <-> H2 h) ->
  H1 = H2.
Proof using. introv M. applys fun_ext_dep. intros h. applys prop_ext. applys M. Qed.
```

## 99.1 全称量词 hforall

`\forall x, H` 描述「对一切 `x` 都满足 `H`」的堆。乍看无用，马上会看到它是
`hand` 与 `qwand` 的编码底座。定义与 `\exists` 完全对称，只需要一对引入/消
去规则就能用起来：

```coq
(* ---------- 99.1 全称量词 hforall ---------- *)

Module Hforall.

Definition hforall (A : Type) (J : A -> hprop) : hprop :=
  fun h => forall x, J x h.

Notation "'\forall' x1 .. xn , H" :=
  (hforall (fun x1 => .. (hforall (fun xn => H)) ..))
  (at level 39, x1 binder, H at level 50, right associativity,
   format "'[' '\forall' '/ '  x1  ..  xn , '/ '  H ']'").

Lemma hforall_intro : forall A (J:A->hprop) h,
  (forall x, J x h) ->
  (hforall J) h.
Proof using. introv M. applys* M. Qed.

Lemma hforall_inv : forall A (J:A->hprop) h,
  (hforall J) h ->
  forall x, J x h.
Proof using. introv M. applys* M. Qed.
```

在蕴含中的进出规则（对照 96 章 `\exists` 的两条）：`_r` 是「证右」——对每
个 `x` 分别证；`_l` 是「用左」——可以特化到任意 `v`。`himpl_hforall_l` 是
`hforall_specialize` 配上传递性的顺手版：

```coq
Lemma himpl_hforall_r : forall A (J:A->hprop) H,
  (forall x, H ==> J x) ->
  H ==> (\forall x, J x).
Proof using. introv M. intros h K x. apply~ M. Qed.

Lemma hforall_specialize : forall A (v:A) (J:A->hprop),
  (\forall x, J x) ==> (J v).
Proof using. intros. intros h K. apply* K. Qed.

Lemma himpl_hforall_l : forall A (v:A) (J:A->hprop) H,
  J v ==> H ->
  (\forall x, J x) ==> H.
Proof using. introv M. applys himpl_trans_r M. applys hforall_specialize. Qed.
```

三元组前条件里的全称量词同样可以特化（用后果规则一步导出）：

```coq
(* 三元组前条件里的全称量词可以特化。 *)

Lemma triple_hforall : forall A (v:A) t (J:A->hprop) Q,
  triple t (J v) Q ->
  triple t (\forall x, J x) Q.
Proof.
  introv M. applys triple_conseq M.
  { applys hforall_specialize. }
  { applys qimpl_refl. }
Qed.

End Hforall.
```

## 99.2 析取 hor

`hor H1 H2` 把 Prop 层的 `\/` 提升到 `hprop` 层。直接定义 `hor'` 一行；实
际采用的定义借助 `\exists` 与布尔——「存在一个（未指明的）布尔 `b`，真则
`H1`、假则 `H2`」：


```coq
(* ---------- 99.2 析取 hor ---------- *)

Module Hor.

(* 直接定义：堆满足 H1 或满足 H2。 *)

Definition hor' (H1 H2 : hprop) : hprop :=
  fun h => H1 h \/ H2 h.

(* 实用定义：借助存在量词与布尔，避免直接操纵堆。 *)

Definition hor (H1 H2 : hprop) : hprop :=
  \exists (b:bool), if b then H1 else H2.
```

**练习（3 星）hor_eq_hor'**——两种定义等价。二元算子的相等要用两层函数外
延（`fun_ext_2`）降到堆谓词相等，再 `hprop_eq` 降到逐堆 `iff`；两个方向都
是对布尔 `b` 做分类：

```coq
(* 练习（3 星，标准，选做）：两种定义等价。 *)

Lemma hor_eq_hor' :
  hor = hor'.
Proof using.
  applys fun_ext_2. intros H1 H2. applys hprop_eq. intros h.
  unfold hor, hor'. iff M.
  { lets (b&Mb): M. destruct b.
    { left. auto. }
    { right. auto. } }
  { destruct M as [M1|M2].
    { exists true. auto. }
    { exists false. auto. } }
Qed.
```

两条引入规则（各选一个见证布尔）与配好传递性的顺手版：

```coq
Lemma himpl_hor_r_l : forall H1 H2,
  H1 ==> hor H1 H2.
Proof using. intros. unfolds hor. exists* true. Qed.

Lemma himpl_hor_r_r : forall H1 H2,
  H2 ==> hor H1 H2.
Proof using. intros. unfolds hor. exists* false. Qed.

(* 配上传递步骤更好用的版本。 *)

Lemma himpl_hor_r_l_trans : forall H1 H2 H3,
  H3 ==> H1 ->
  H3 ==> hor H1 H2.
Proof using. introv W. applys himpl_trans W. applys himpl_hor_r_l. Qed.

Lemma himpl_hor_r_r_trans : forall H1 H2 H3,
  H3 ==> H2 ->
  H3 ==> hor H1 H2.
Proof using. introv W. applys himpl_trans W. applys himpl_hor_r_r. Qed.
```

消去规则：要证 `hor H1 H2 ==> H3`，须证明两个分支都蕴含 `H3`（拉出存在量
词后 `case_if*` 自动分派）：

```coq
(* 消去规则：要证 hor H1 H2 ==> H3，须两个方向都证。 *)

Lemma himpl_hor_l : forall H1 H2 H3,
  H1 ==> H3 ->
  H2 ==> H3 ->
  hor H1 H2 ==> H3.
Proof using.
  introv M1 M2. unfolds hor. applys himpl_hexists_l. intros b. case_if*.
Qed.
```

**练习（2 星）hor_comm**——`hor` 可交换。用 `hprop_op_comm`（「逐方向蕴含
即相等」的提升器），对 `b` 分类后把见证换成相反的布尔即可。辅助引理 `if_neg`
（用 `neg` 翻转 if 的两分支）在本章后面还会用到：

```coq
(* 用 neg 换 if 的两个分支。 *)

Lemma if_neg : forall (b:bool) A (X Y:A),
  (if b then X else Y) = (if neg b then Y else X).
Proof using. intros. case_if*. Qed.

(* 练习（2 星，标准，必做）：hor 交换律。 *)

Lemma hor_comm : forall H1 H2,
  hor H1 H2 = hor H2 H1.
Proof using.
  applys hprop_op_comm. intros H1 H2. unfolds hor.
  applys himpl_hexists_l. intros b. destruct b.
  { applys (himpl_hexists_r false). applys himpl_refl. }
  { applys (himpl_hexists_r true). applys himpl_refl. }
Qed.
```

**练习（4 星）MList_using_hor**——94 章的链表表示谓词 `MList` 可以用 `hor`
等价刻画。**不要**对 `MList` 做归纳或展开，只用 `MList_nil`/`MList_cons` 两
条等式（本节先按 94 章复刻 `MList`）：

```coq
Module HorExample.
Implicit Types q : loc.

(* 复刻 94 章的 MList（记录表示）： *)

Definition head : field := 0%nat.
Definition tail : field := 1%nat.

Fixpoint MList (L:list val) (p:loc) : hprop :=
  match L with
  | nil => \[p = null]
  | x::L' => \exists q, (p ~~~> `{ head := x; tail := q}) \* (MList L' q)
  end.

Lemma MList_nil : forall p,
  (MList nil p) = \[p = null].
Proof using. auto. Qed.

Lemma MList_cons : forall p x L',
  MList (x::L') p =
  \exists q, (p ~~~> `{ head := x; tail := q}) \* (MList L' q).
Proof using. auto. Qed.

Global Opaque MList.

(* 练习（4 星，标准，必做）：MList 可以用 hor 等价刻画。
   提示：不要对 MList 做归纳或展开，只用 MList_nil/MList_cons 两条等式。 *)

Lemma MList_using_hor : forall L p,
  MList L p =
     hor (\[L = nil /\ p = null])
         (\exists x q L', \[L = x::L']
                       \* (p ~~~> `{ head := x; tail := q})
                       \* (MList L' q)).
Proof using.
  intros. applys himpl_antisym.
  { destruct L as [|x L'].
    { applys himpl_hor_r_l_trans. xchange MList_nil. xsimpl*. }
    { applys himpl_hor_r_r_trans. xchange MList_cons. xsimpl*. } }
  { applys himpl_hor_l.
    { xpull. intros E. destruct E as (E1&E2). subst.
      rewrite MList_nil. xsimpl*. }
    { xpull. intros x q L' E. subst L.
      rewrite MList_cons. xsimpl. } }
Qed.

End HorExample.
End Hor.
```

读法：→ 方向按 `L` 分情况，`xchange MList_nil/MList_cons` 打开定义后选对
应分支；← 方向用消去规则 `himpl_hor_l`，空表分支把纯事实代入后
`rewrite MList_nil` 折回，非空分支 `rewrite MList_cons` 折回。

## 99.3 合取 hand

`hand H1 H2` 是**非分离**合取：**同一个堆**既满足 `H1` 又满足 `H2`（星号
则是把堆拆成两块）。定义用 `\forall` 加布尔——「对一切 `b`，真则 `H1` 假
则 `H2`」：

```coq
(* ---------- 99.3 合取 hand ---------- *)

Module Hand.
Import Hforall Hor.

(* 直接定义。 *)

Definition hand' (H1 H2 : hprop) : hprop :=
  fun h => H1 h /\ H2 h.

(* 实用定义：同一个堆既满足 H1 又满足 H2（借助 \forall 与布尔）。 *)

Definition hand (H1 H2 : hprop) : hprop :=
  \forall (b:bool), if b then H1 else H2.
```

**练习（2 星）hand_eq_hand'**——与 `hor` 同款套路：

```coq
(* 练习（2 星，标准，必做）：两种定义等价。 *)

Lemma hand_eq_hand' :
  hand = hand'.
Proof using.
  applys fun_ext_2. intros H1 H2. applys hprop_eq. intros h.
  unfold hand, hand'. iff M.
  { split.
    { applys (M true). }
    { applys (M false). } }
  { intros b. destruct b.
    { applys (proj1 M). }
    { applys (proj2 M). } }
Qed.
```

引入/消去规则照抄 Prop 层合取的形状：

```coq
Lemma himpl_hand_l_r : forall H1 H2,
  hand H1 H2 ==> H1.
Proof using. intros. unfolds hand. applys* himpl_hforall_l true. Qed.

Lemma himpl_hand_l_l : forall H1 H2,
  hand H1 H2 ==> H2.
Proof using. intros. unfolds hand. applys* himpl_hforall_l false. Qed.

Lemma himpl_hand_r : forall H1 H2 H3,
  H3 ==> H1 ->
  H3 ==> H2 ->
  H3 ==> hand H1 H2.
Proof using. introv M1 M2 Hh. intros b. case_if*. Qed.
```

**练习（1 星）hand_comm**——交换律。诀窍在 `if_neg`：要证 `hand H1 H2 ==>
hand H2 H1`，对右边的每个 `b`，把左边的全称量词**特化到 `neg b`**，得到的
`if neg b then H1 else H2` 恰好被 `if_neg` 重写成需要的 `if b then H2 else
H1`：


```coq
(* 练习（1 星，标准，必做）：hand 交换律。 *)

Lemma hand_comm : forall H1 H2,
  hand H1 H2 = hand H2 H1.
Proof using.
  applys hprop_op_comm. intros H1 H2. unfolds hand.
  applys himpl_hforall_r. intros b.
  rewrite if_neg. applys himpl_hforall_l (neg b). applys himpl_refl.
Qed.

End Hand.
```

## 99.4 魔法杖 hwand

终于到主角。**`H1 \-* H2`（"H1 wand H2"）描述「缺了 `H1` 这块资源的
`H2`」**：把它与 `H1` 星接起来就得到 `H2`——

```text
      H1 \* (H1 \-* H2) ==> H2
```

两个直觉：算术上把 `\*` 想成加法，`H1 \-* H2` 就是「`-H1 + H2`」（减法；
上面那条就是 `H1 + (-H1 + H2) = H2`）；逻辑上把 `\*` 想成 `/\`，杖就是蕴涵
`->`（上面那条就是 `(P1 /\ (P1 -> P2)) -> P2`）。注意减法要有意义，`H1`
得「确实能从 `H2` 里减掉」，否则 `H1 \-* H2` 描述的是不存在的堆。

直接定义（`hwand'`，供 99.10 对照用）一目了然；实用定义（`hwand`）则按本
章的元技巧用存在量词写——「存在缺失的那块 `H0`，它星上 `H1` 恰好蕴含
`H2`」：


```coq
(* ---------- 99.4 魔法杖 hwand ---------- *)

Module Hwand.

(* 直接定义：H1 \-* H2 在堆 h 上成立，指与任意满足 H1 的不相交堆 h'
   合并后满足 H2。 *)

Definition hwand' (H1 H2:hprop) : hprop :=
  fun h => forall h', Fmap.disjoint h h' -> H1 h' -> H2 (h \u h').

(* 实用定义：存在"缺失的那块" H0，它星上 H1 恰好得到 H2。
   好处：全部性质都可以在 hprop 层用 xsimpl 证明，不必下到堆层。 *)

Definition hwand (H1 H2:hprop) : hprop :=
  \exists H0, H0 \* \[ H1 \* H0 ==> H2 ].

Notation "H1 \-* H2" := (hwand H1 H2) (at level 43, right associativity).
```

**特征等价**是杖的灵魂——`H0 ==> H1 \-* H2` 与 `H1 \* H0 ==> H2` 互相等
价（「`H0 = -H1+H2`」与「`H1+H0 = H2`」是同一句话）。它的证明把「杖的使
用」全部编码成 `xchange`（拿 `M` 换资源）：

```coq
(* 特征等价：H0 ==> H1 \-* H2 当且仅当 H1 \* H0 ==> H2。
   类比算术：H0 = -H1+H2 与 H1+H0 = H2 是同一个说法。 *)

Lemma hwand_equiv : forall H0 H1 H2,
  (H0 ==> H1 \-* H2) <-> (H1 \* H0 ==> H2).
Proof using.
  unfold hwand. iff M.
  { xchange M. intros H N. xchange N. }
  { xsimpl H0. xchange M. }
Qed.
```

由它立刻拆出引入规则（→ 方向反过来用）、消去规则与**消去规则的好用形
式**（`H1` 星上杖恰得 `H2`，后面到处引用，`Arguments ... : clear
implicits` 让它按显式参数书写）：


```coq
(* 引入规则（从右到左）。 *)

Lemma himpl_hwand_r : forall H0 H1 H2,
  (H1 \* H0) ==> H2 ->
  H0 ==> (H1 \-* H2).
Proof using. introv M. applys hwand_equiv. applys M. Qed.

(* 消去规则（从左到右）。 *)

Lemma himpl_hwand_r_inv : forall H0 H1 H2,
  H0 ==> (H1 \-* H2) ->
  (H1 \* H0) ==> H2.
Proof using. introv M. applys hwand_equiv. applys M. Qed.

/* 消去规则的好用形式：H1 星上 (H1 \-* H2) 得 H2。 *)
```

```coq
(* 消去规则的好用形式：H1 星上 (H1 \-* H2) 得 H2。 *)

Lemma hwand_cancel : forall H1 H2,
  H1 \* (H1 \-* H2) ==> H2.
Proof using. intros. applys himpl_hwand_r_inv. applys himpl_refl. Qed.

Arguments hwand_cancel : clear implicits.
```

接下来的一串性质全部是「引入规则 + `xchange (hwand_cancel ...)`」的变奏。
先看单调性与传递性（`->` 的对应物：对前件反变、对后件协变；
`(-H1+H2)+(-H2+H3) = -H1+H3`）：

```coq
(* 对 H1 反变、对 H2 协变（与蕴涵 -> 相同）。 *)

Lemma hwand_himpl : forall H1 H1' H2 H2',
  H1' ==> H1 ->
  H2 ==> H2' ->
  (H1 \-* H2) ==> (H1' \-* H2').
Proof using.
  introv M1 M2. applys himpl_hwand_r. xchange M1.
  xchange (hwand_cancel H1 H2). applys M2.
Qed.

(* (-H1+H2) + (-H2+H3) = -H1+H3：普通蕴涵传递性的 wand 版。 *)

Lemma hwand_trans_elim : forall H1 H2 H3,
  (H1 \-* H2) \* (H2 \-* H3) ==> (H1 \-* H3).
Proof using.
  intros. applys himpl_hwand_r. xchange (hwand_cancel H1 H2).
Qed.
```

与空堆、纯事实的交互——`0 = -H+H`；`-0+H = H`；`P` 成立时 `-P+H = H`：


```coq
(* 空堆满足 H \-* H（0 可写成 -H+H）。 *)

Lemma himpl_hempty_hwand_same : forall H,
  \[] ==> (H \-* H).
Proof using. intros. apply himpl_hwand_r. xsimpl. Qed.

(* \[] \-* H 恰为 H（-0+H = H）。 *)

Lemma hwand_hempty_l : forall H,
  (\[] \-* H) = H.
Proof using.
  intros. unfold hwand. xsimpl.
  { intros H0 M. xchange M. }
  { xsimpl. }
Qed.
```

**练习（2 星）hwand_hpure_l**——`P` 成立时 `\[P] \-* H` 恰为 `H`。→ 方向
先「免费」造出 `\[P]`（`himpl_hstar_hpure_r` 用前提 `HP` 白送一个纯事实）
再用 `hwand_cancel` 消掉；← 方向是引入规则配 `himpl_hstar_hpure_l`：


```coq
(* 练习（2 星，标准，必做）：P 成立时 \[P] \-* H 恰为 H。 *)

Lemma hwand_hpure_l : forall P H,
  P ->
  (\[P] \-* H) = H.
Proof using.
  introv HP. applys himpl_antisym.
  { applys himpl_trans (\[P] \* (\[P] \-* H)).
    { applys himpl_hstar_hpure_r HP. applys himpl_refl. }
    { applys hwand_cancel. } }
  { applys himpl_hwand_r. applys himpl_hstar_hpure_l. intros _. applys himpl_refl. }
Qed.
```

**练习（2 星，选做）himpl_hwand_hpure_lr**——`\[P1 -> P2] ==> (\[P1] \-*
\[P2])`。展开 `hwand` 后用 `xsimpl (\[P1 -> P2])` 给右边的存在量词**显式指
定见证**——缺失的那块就是 `\[P1 -> P2]` 自己，剩下的纯事实义务两轮
`auto`：


```coq
(* 要证 H1 ==> \[P] \-* H2，只需在 P 成立时证 H1 ==> H2。 *)

Lemma himpl_hwand_hpure_r : forall H1 H2 P,
  (P -> H1 ==> H2) ->
  H1 ==> (\[P] \-* H2).
Proof using. introv M. applys himpl_hwand_r. xsimpl. applys M. Qed.

/* 练习（2 星，标准，选做）：\[P1 -> P2] 蕴含 \[P1] \-* \[P2]。
   提示：展开 hwand 后用 xsimpl 给右边的存在量词提供显式见证。 *)
```

```coq
(* 练习（2 星，标准，选做）：\[P1 -> P2] 蕴含 \[P1] \-* \[P2]。
   提示：展开 hwand 后用 xsimpl 给右边的存在量词提供显式见证。 *)

Lemma himpl_hwand_hpure_lr : forall (P1 P2:Prop),
  \[P1 -> P2] ==> (\[P1] \-* \[P2]).
Proof using.
  intros. unfold hwand. xsimpl (\[P1 -> P2]).
  { auto. }
  { xsimpl. auto. }
Qed.
```

**柯里化**：`(H1 \* H2) \-* H3`、`H1 \-* (H2 \-* H3)`、`H2 \-* (H1 \-*
H3)` 三者等价（同函数柯里化）；**吸收性**：杖的右侧可以吸走与它星接的资
源——`(H1 \-* H2) \* H3 ==> H1 \-* (H2 \* H3)`（「你现在有 `H3`，且给你
`H1` 就有 `H2`；那么给你 `H1` 就同时有 `H2` 和 `H3`」）。反方向**不成立**
（`H1 := \[False]` 即反例）：



（更正：上一行是重复笔误，正式代码如下。）

```coq
(* 柯里化：(H1 \* H2) \-* H3 = H1 \-* (H2 \-* H3)。 *)

Lemma hwand_curry_eq : forall H1 H2 H3,
  (H1 \* H2) \-* H3 = H1 \-* (H2 \-* H3).
Proof using.
  intros. applys himpl_antisym.
  { apply himpl_hwand_r. apply himpl_hwand_r.
    xchange (hwand_cancel (H1 \* H2) H3). }
  { apply himpl_hwand_r. xchange (hwand_cancel H1 (H2 \-* H3)).
    xchange (hwand_cancel H2 H3). }
Qed.

(* 杖的右侧可以吸收与它星接的资源。 *)

Lemma hstar_hwand : forall H1 H2 H3,
  (H1 \-* H2) \* H3 ==> H1 \-* (H2 \* H3).
Proof using.
  intros. applys himpl_hwand_r. xsimpl. xchange (hwand_cancel H1 H2).
Qed.

(* 反方向不成立：取 H1 := \[False] 即得反例。 *)
```

**练习（1 星）himpl_hwand_hstar_same_r**——`H1 ==> H2 \-* (H2 \* H1)`：
引入规则后目标两侧相同，`xsimpl` 自反关闭：


```coq
(* 练习（1 星，标准，必做）：H1 ==> H2 \-* (H2 \* H1)。 *)

Lemma himpl_hwand_hstar_same_r : forall H1 H2,
  H1 ==> (H2 \-* (H2 \* H1)).
Proof using. intros. applys himpl_hwand_r. xsimpl. Qed.
```

**练习（2 星）hwand_cancel_part**——部分消去：`H1` 手里有，把
`(H1 \* H2) \-* H3` 里属于 `H1` 的部分先还掉：


```coq
(* 练习（2 星，标准，必做）：H1 \* ((H1 \* H2) \-* H3) 化简为 H2 \-* H3。 *)

Lemma hwand_cancel_part : forall H1 H2 H3,
  H1 \* ((H1 \* H2) \-* H3) ==> (H2 \-* H3).
Proof using.
  intros. applys himpl_hwand_r. xchange (hwand_cancel (H1 \* H2) H3).
Qed.
```

注意 `xchange` 会自动把星号按交换/结合律重排后再匹配 `hwand_cancel` 的左
边——这正是它比手工 `rewrite` 好用的地方。

**练习（3 星，选做）hwand_frame**——杖的框架性：`xchange` 消掉 `H1 \-* H2`
后剩下的 `H3 ==> H2 \* H3` 由 `xchange` 的收尾自反性一并关闭：


```coq
(* 练习（3 星，标准，选做）：杖的框架性。 *)

Lemma hwand_frame : forall H1 H2 H3,
  H1 \-* H2 ==> (H1 \* H3) \-* (H2 \* H3).
Proof using.
  intros. applys himpl_hwand_r. xchange (hwand_cancel H1 H2).
Qed.
```

**练习（3 星，选做）hwand_inv**——反演引理，把 `hwand` 与直接定义
`hwand'` 连起来：已知杖在 `h2` 成立、`H1` 在不相交的 `h1` 成立，则并堆满足
`H2`。证明就是展开 `hwand`、拆两层存在量词、用 `hpure_inv` 取出那个蕴含
`N`，最后 `hstar_intro` 把两块堆拼起来交给 `N`：


```coq
(* 练习（3 星，标准，选做）：hwand 的反演引理（对应直接定义 hwand'）。 *)

Lemma hwand_inv : forall h1 h2 H1 H2,
  (H1 \-* H2) h2 ->
  H1 h1 ->
  Fmap.disjoint h1 h2 ->
  H2 (h1 \u h2).
Proof using.
  introv M K1 D. unfold hwand in M.
  destruct M as (H0&K0). destruct K0 as (h2a&h2b&K2a&K2b&D2&U2).
  lets (N&E): hpure_inv (rm K2b). subst h2b. subst h2.
  rewrite Fmap.union_empty_r in *.
  applys N. applys hstar_intro K1 K2a D.
Qed.

End Hwand.
```

## 99.5 后条件上的魔法杖 qwand

把杖推广到后条件：`Q1 \--* Q2` 是**堆谓词**（不是后条件！）。两种定义：照
`hwand` 模式（存在缺失块 `H0`），或直接建在 `hwand` 上（对一切结果值 `v`
的逐点杖）。取后者为定义——实践中最常用的操作就是按下标特化：


```coq
(* ---------- 99.5 后条件上的魔法杖 qwand ---------- *)

Module Qwand.
Import Hwand.

(* 定义一：照 hwand 的模式，存在缺失的堆谓词 H0。 *)

Definition qwand' (Q1 Q2:val->hprop) : hprop :=
  \exists H0, H0 \* \[ Q1 \*+ H0 ===> Q2 ].

(* 定义二（采用）：对一切结果值 v 的逐点 hwand。
   实践中最常用的是按下标特化，故取此定义为 qwand。 *)

Definition qwand (Q1 Q2:val->hprop) : hprop :=
  \forall v, (Q1 v) \-* (Q2 v).

Notation "Q1 \--* Q2" := (qwand Q1 Q2) (at level 43).
```

特化规则是 `hforall_specialize` 的直接推论；随后的特征等价、消去、单调
性、吸收性与 `hwand` 逐条平行（`\*+` 版本的星号吸收）：

```coq
Lemma qwand_specialize : forall (v:val) (Q1 Q2:val->hprop),
  (Q1 \--* Q2) ==> (Q1 v \-* Q2 v).
Proof using.
  intros. unfold qwand. applys himpl_hforall_l v. xsimpl.
Qed.

Lemma qwand_equiv : forall H Q1 Q2,
      H ==> (Q1 \--* Q2)
  <-> (Q1 \*+ H) ===> Q2.
Proof using.
  intros. iff M.
  { intros x. xchange M. xchange (qwand_specialize x).
    xchange (hwand_cancel (Q1 x)). }
  { applys himpl_hforall_r. intros x. applys himpl_hwand_r.
    xchange (M x). }
Qed.

Lemma qwand_cancel : forall Q1 Q2,
  Q1 \*+ (Q1 \--* Q2) ===> Q2.
Proof using. intros. rewrite <- qwand_equiv. applys qimpl_refl. Qed.

Lemma qwand_himpl : forall Q1 Q1' Q2 Q2',
  Q1' ===> Q1 ->
  Q2 ===> Q2' ->
  (Q1 \--* Q2) ==> (Q1' \--* Q2').
Proof using.
  introv M1 M2. rewrite qwand_equiv. intros x.
  xchange (qwand_specialize x). xchange M1.
  xchange (hwand_cancel (Q1 x)). xchange M2.
Qed.

Lemma hstar_qwand : forall Q1 Q2 H,
  (Q1 \--* Q2) \* H ==> Q1 \--* (Q2 \*+ H).
Proof using.
  intros. rewrite qwand_equiv. xchange (@qwand_cancel Q1).
Qed.
```

两条小练习（`hwand` 同款的一行星）：


```coq
(* 练习（1 星，标准，必做）：H ==> Q \--* (Q \*+ H)。 *)

Lemma himpl_qwand_hstar_same_r : forall H Q,
  H ==> Q \--* (Q \*+ H).
Proof using. intros. rewrite qwand_equiv. applys qimpl_refl. Qed.

/* 练习（2 星，标准，选做）：H \* ((Q1 \*+ H) \--* Q2) 化简为 Q1 \--* Q2。 *)
```

```coq
(* 练习（2 星，标准，选做）：H \* ((Q1 \*+ H) \--* Q2) 化简为 Q1 \--* Q2。 *)

Lemma qwand_cancel_part : forall H Q1 Q2,
  H \* ((Q1 \*+ H) \--* Q2) ==> (Q1 \--* Q2).
Proof using.
  intros. rewrite qwand_equiv. xchange (@qwand_cancel (Q1 \*+ H)).
Qed.

End Qwand.
```

套路完全一致：先把目标 `rewrite qwand_equiv` 换成后条件层面的星号等式，再
`xchange` 消杖。

## 99.6 xsimpl 对魔法杖的支持

以上我们「手工」证明了杖的性质——因为 `LibSepSimpl` 的 `xsimpl` 实现本身
就依赖这些引理，不能反过来用它作弊。现在让**库版 xsimpl** 登场（注意本模
块没有 `Import Hwand`，`\-*` 是库自己的杖），看它替你做了什么：


```coq
(* ---------- 99.6 xsimpl 对魔法杖的支持 ---------- *)

Module XsimplDemo.

/* 库版 xsimpl 能识别并约去成对的杖与被减项。 *)
```

（笔误：上行注释符号应为 `(* *)`，正式代码见下。）

```coq
(* 库版 xsimpl 能识别并约去成对的杖与被减项。 *)

Lemma xsimpl_demo_hwand_cancel : forall H1 H2 H3 H4 H5,
  H1 \* (H2 \-* H3) \* H4 \* H2 ==> H5.
Proof using. intros. xsimpl. Abort.

Lemma xsimpl_demo_hwand_cancel_partial : forall H1 H2 H3 H4 H5 H6,
  ((H1 \* H2 \* H3) \-* H4) \* H5 \* H2 ==> H6.
Proof using. intros. xsimpl. Abort.
```

第一例：`H2 \-* H3` 与 `H2` 同现，自动约成 `H3`。第二例：**部分**消去——
杖的左侧是三块星接 `(H1 \* H2 \* H3) \-* H4`，手头只有 `H2`，于是约成
`(H1 \* H3) \-* H4`（正是 `hwand_cancel_part` 的自动化）。右侧只剩杖时自
动应用引入规则（先把两边同现的 `H1` 约掉，再把 `H3` 从右侧挪到左侧）：


```coq
(* 右侧只剩一根杖时，xsimpl 自动应用引入规则 himpl_hwand_r。 *)

Lemma xsimpl_demo_himpl_hwand_r : forall H1 H2 H3 H4 H5,
  H1 \* H2 ==> H1 \* (H3 \-* (H4 \* H5)).
Proof using. intros. xsimpl. Abort.

Lemma xsimpl_demo_hwand_iter : forall H1 H2 H3 H4 H5,
  H4 \* H3 ==> H5 ->
  H2 \* (H1 \-* H3) \* H4 \* (H2 \-* H1) ==> H5.
Proof using. intros. xsimpl. auto. Qed.

Lemma xsimpl_demo_hwand_iter_2 : forall H1 H2 H3 H4 H5,
  H1 \* H2 \* ((H1 \* H3) \-* (H4 \-* H5)) \* H4 ==> ((H2 \-* H3) \-* H5).
Proof using. intros. xsimpl. Qed.
```

这些迭代消去还能两侧同时进行、链式进行；`qwand` 也一样（`(Q1 \--* Q2)`
与 `Q1 v` 同现约成 `Q2 v`）：

```coq
Lemma xsimpl_demo_qwand_cancel : forall v (Q1 Q2:val->hprop) H1 H2,
  (Q1 \--* Q2) \* H1 \* (Q1 v) ==> H2.
Proof using. intros. xsimpl. Abort.

Lemma xsimpl_hwand_frame : forall H1 H2 H3,
  (H1 \-* H2) ==> ((H1 \* H3) \-* (H2 \* H3)).
Proof using.
  intros.
  (* xsimpl 的第一步把目标变成 (H1 \-* H2) \* (H1 \* H3) ==> (H2 \* H3)。 *)
  xsimpl.
Qed.

End XsimplDemo.
```

最后一例即 99.4 的练习 `hwand_frame`——库版 `xsimpl` 一步关闭。从 93 章开
始你用的 `xsimpl` 一直就是这个全功能版。

## 99.7 全部堆谓词算子总表


```coq
(* ---------- 99.7 全部堆谓词算子总表 ---------- *)

Module SummaryHprop.

(* 核心算子：直接定义为堆上的函数。 *)

  Definition hempty : hprop :=
    fun h => (h = Fmap.empty).

  Definition hsingle (p:loc) (v:val) : hprop :=
    fun h => (h = Fmap.single p v).

  Definition hstar (H1 H2 : hprop) : hprop :=
    fun h => exists h1 h2, H1 h1
                                /\ H2 h2
                                /\ Fmap.disjoint h1 h2
                                /\ h = Fmap.union h1 h2.

  Definition hexists A (J:A->hprop) : hprop :=
    fun h => exists x, J x h.

  Definition hforall (A : Type) (J : A -> hprop) : hprop :=
    fun h => forall x, J x h.
```

五个核心算子（空、单格、星、存在、全称）直接定义为堆上的函数；其余算子一
律由它们导出（`hpure` 用 `\exists`、`hand`/`hor` 用 `\forall`/`\exists` 加
布尔、`hwand` 用 `\exists`、`qwand` 用 `\forall` + `hwand`）：


```coq
(* 其余算子：由核心算子导出（性质可用 xsimpl 在 hprop 层证明）。 *)

Module RemainingOperatorsDerived.

  Definition hpure (P:Prop) : hprop :=
    \exists (p:P), \[].

  Definition hand (H1 H2 : hprop) : hprop :=
    \forall (b:bool), if b then H1 else H2.

  Definition hor (H1 H2 : hprop) : hprop :=
    \exists (b:bool), if b then H1 else H2.

  Definition hwand (H1 H2 : hprop) : hprop :=
    \exists H0, H0 \* \[ (H1 \* H0) ==> H2 ].

  Definition qwand (Q1 Q2 : val->hprop) : hprop :=
    \forall v, (Q1 v) \-* (Q2 v).

End RemainingOperatorsDerived.
```

它们当然也都能直接写成堆上的函数（如下），但**导出定义的证明可以用
xsimpl 全自动完成**，直接定义则每条性质都要手拆堆——这就是「高级算子」的
全部意义：


```coq
(* 也可全部直接定义为堆上的函数，但证明更费力。 *)

Module RemainingOperatorsDirect.

  Definition hpure (P:Prop) : hprop :=
    fun h => (h = Fmap.empty) /\ P.

  Definition hor (H1 H2 : hprop) : hprop :=
    fun h => H1 h \/ H2 h.

  Definition hand (H1 H2 : hprop) : hprop :=
    fun h => H1 h /\ H2 h.
  Definition hwand (H1 H2:hprop) : hprop :=
    fun h => forall h', Fmap.disjoint h h' -> H1 h' -> H2 (h \u h').

  Definition qwand (Q1 Q2:val->hprop) : hprop :=
    fun h => forall v h', Fmap.disjoint h h' -> Q1 v h' -> Q2 v (h \u h').

End RemainingOperatorsDirect.

End SummaryHprop.
```

## 99.8 分支框架规则

回顾 `xapp` 赖以工作的**后果-框架规则**（97 章证明）：


```coq
(* ---------- 99.8 分支框架规则 ---------- *)

Module RamifiedFrame.
Import Hwand Qwand.

Parameter triple_conseq_frame : forall H2 H1 Q1 t H Q,
  triple t H1 Q1 ->
  H ==> H1 \* H2 ->
  Q1 \*+ H2 ===> Q ->
  triple t H Q.
```

它的实际痛点：`H2`（`H` 减去 `H1` 的差）要从一个子目标传递到另一个子目
标。手写太烦，留 evar 则在 `H` 含**存在量词**时失败——`xsimpl` 处理
`H ==> H1 \* ?H2` 时会先把左侧的存在量词抽出来，抽出来的变量不在 `?H2` 的
辖域里，实例化失败。

**分支框架规则**的解法：把两条蕴含前提合并成一条、让 `H2` 彻底消失。观察
第二条前提 `Q1 \*+ H2 ===> Q` 等价于 `H2 ==> (Q1 \--* Q)`（`qwand_equiv`），
把它代入第一条前提即得 `H ==> H1 \* (Q1 \--* Q)`：


```coq
(* 后果-框架规则要把 H2 从一个子目标传递到另一个子目标，
   用 evar 时遇前条件含存在量词会失败（见后例）。
   分支框架规则用 qwand 把两条蕴含前提合并成一条，H2 不再出现。 *)

Lemma triple_ramified_frame : forall H1 Q1 t H Q,
  triple t H1 Q1 ->
  H ==> H1 \* (Q1 \--* Q) ->
  triple t H Q.
Proof using.
  introv M W. applys triple_conseq_frame (Q1 \--* Q) M.
  { applys W. } { applys qwand_cancel. }
Qed.
```

证明一行：把 `H2` 显式选成 `Q1 \--* Q`，两条蕴含分别变成 `W` 与
`qwand_cancel`。反过来，分支框架规则也能推出后果-框架规则——**二者表达力
相同**，但前者用起来没有 evar 问题：


```coq
(* 反过来，分支框架规则也能推出后果-框架规则：二者表达力相同。 *)

Lemma triple_conseq_frame_of_ramified_frame : forall H2 H1 Q1 t H Q,
  triple t H1 Q1 ->
  H ==> H1 \* H2 ->
  Q1 \*+ H2 ===> Q ->
  triple t H Q.
Proof using.
  introv M WH WQ. applys triple_ramified_frame M.
  xchange WH. xsimpl. rewrite qwand_equiv. applys WQ.
Qed.
```

（`xchange WH` 注入 `H2`、`xsimpl` 归一、`rewrite qwand_equiv` 把右边的杖
换回后条件层面的蕴含、`WQ` 收尾。）

**好处演示**。给 `triple_ref` 的前后条件都加上「还存在另一个完全不确定的
单元」`\exists l' v', l' ~~> v'`。先用后果-框架规则 + evar 试一次——第一
个子目标后 `?H2` 挂着；第二个子目标里 `xsimpl` 抽出 `l'`、`v'` 后，
`?H2` 无法再实例化（这两个变量不在它的辖域内），**卡死**（故 `Abort`）：


```coq
(* —— 分支框架规则的好处：一个具体例子 —— *)

Parameter triple_conseq_frame' : forall H2 H1 Q1 t H Q,
  triple t H1 Q1 ->
  H ==> H1 \* H2 ->
  Q1 \*+ H2 ===> Q ->
  triple t H Q.

Parameter triple_ref : forall (v:val),
  triple (val_ref v)
    \[]
    (funloc p => p ~~> v).

(* 想给 triple_ref 的前后条件都加上"还存在另一个不确定的单元"，
   用后果-框架规则 + evar ?H2 会卡住：xsimpl 先把左边存在量词抽出来，
   此时 ?H2 的辖域里没有这些新变量，实例化失败。 *)

Lemma triple_ref_extended : forall (v:val),
  triple (val_ref v)
    (\exists l' v', l' ~~> v')
    (funloc p => p ~~> v \* \exists l' v', l' ~~> v').
Proof using.
  intros. applys triple_conseq_frame'.
  { applys triple_ref. }
  { xsimpl.
Abort.
```

换分支框架规则：`xsimpl` 同样抽出存在量词，但抽出的变量**留在同一个子目
标内**，辖域完好；义务变成 `(l' ~~> v) ==> (Q1 \--* Q)`，按 `qwand_equiv`
换成 `Q1 \*+ (l' ~~> v) ===> Q`，`intros x. xsimpl. auto.` 收尾：


```coq
(* 换成分支框架规则，同样的 xsimpl 抽出存在量词后仍在同一子目标内，
   辖域完好，证明顺利完成。 *)

Lemma triple_ref_extended' : forall (v:val),
  triple (val_ref v)
    (\exists l' v', l' ~~> v')
    (funloc p => p ~~> v \* \exists l' v', l' ~~> v').
Proof using.
  intros. applys triple_ramified_frame.
  { applys triple_ref. }
  { xsimpl.
    intros l' v'.
    (* 目标形如 (l' ~~> v) ==> (Q1 \--* Q2)，
       按 qwand_equiv 等价于 Q1 \*+ (l' ~~> v) ===> Q2。 *)
    rewrite qwand_equiv.
    intros x. xsimpl. auto. }
Qed.

End RamifiedFrame.
```

## 99.9 一些诱人但不成立的性质

杖的世界里有几个「看起来应该对」的方向，值得亲手排除，避免日后误用。

其一：`\[] ==> (H \-* H)` 对（0 = -H+H），但反向 `(H \-* H) ==> \[]` 不对。
反例 `H := \[False]`：任何堆都满足 `\[False] \-* \[False]`（前提永远无法凑
齐，杖空转），可只有空堆满足 `\[]`。证明用「任取一个非空堆」构造矛盾
（`Fmap.exists_not_empty` 提供非空堆；杖的前提义务由 `himpl_hwand_r` 配上
「非空」谓词即可满足）：


```coq
(* ---------- 99.9 魔法杖的一些诱人但不成立的性质 ---------- *)

Module HwandFalse.
Import Hwand.

/* (H \-* H) ==> \[] 不成立：取 H := \[False]，
   任何堆都满足 \[False] \-* \[False]，但只有空堆满足 \[]。 *)
```

（笔误：上行注释符号见下方正式代码。）

```coq
(* (H \-* H) ==> \[] 不成立：取 H := \[False]，
   任何堆都满足 \[False] \-* \[False]，但只有空堆满足 \[]。 *)

Lemma himpl_hwand_same_hempty_counterexample :
  ~ (forall H, (H \-* H) ==> \[]).
Proof using.
  rew_logic.
  exists \[False]. intros M.
  lets (h,Hh): (@Fmap.exists_not_empty val _).
  forwards K: M h.
  { applys* himpl_hwand_r (fun h => h <> Fmap.empty). xsimpl*. }
  lets E: hempty_inv K. false* Hh.
Qed.
```

其二：`hwand_cancel` 的逆 `H2 ==> H1 \* (H1 \-* H2)` 不成立（「凭空造杖」）。
反例 `H2 := \[]`、`H1 := \[False]`：空堆满足左边，但要满足
`\[False] \* (\[False] \-* \[])` 得先凭空证明 `False`：


```coq
(* hwand_cancel 的逆 H2 ==> H1 \* (H1 \-* H2) 也不成立：
   反例 H2 := \[]，H1 := \[False]。 *)

Lemma not_himpl_hwand_r_inv_reciprocal : exists H1 H2,
  ~ (H2 ==> H1 \* (H1 \-* H2)).
Proof using.
  exists \[False] \[]. intros N. forwards K: N (Fmap.empty:heap).
  applys hempty_intro. rewrite hstar_hpure_l in K. destruct K. auto.
Qed.

/* 经验法则：对任何"凭空造出杖"的蕴含都要警惕。 *)
```

```coq
(* 经验法则：对任何"凭空造出杖"的蕴含都要警惕。 *)

End HwandFalse.
```

一般地，`hwand_trans_elim`（`H1 <= H2` 且 `H2 <= H3` 推出 `H1 <= H3`）成
立，反向（从 `H1 <= H3` 拆出中间层）不成立——直觉上「是子集」无法凭空找
到中间集合。**经验法则：任何在右边凭空造出杖的蕴含都可疑。**

## 99.10 hwand 多种定义的等价性

本章给过 `hwand` 的直接定义（99.4 的 `hwand'`）、导出定义、特征等价、引
入+消去规则对——四种刻画其实**两两等价**，即杖被它的特征等价**唯一确
定**。以下把这些等价形式化（算子层面的相等写成对 `op` 的谓词），证明供参
考、不必逐行跟，但值得读读 `pred_ext` 系列工具的用法：


```coq
(* ---------- 99.10 hwand 多种定义的等价性 ---------- *)

Module HwandEquiv.
Implicit Type op : hprop->hprop->hprop.

Definition hwand_characterization_1 (op:hprop->hprop->hprop) :=
  op = (fun H1 H2 =>
         (fun h => forall h', Fmap.disjoint h h' -> H1 h' -> H2 (h' \u h))).

Definition hwand_characterization_2 (op:hprop->hprop->hprop) :=
  op = (fun H1 H2 => \exists H0, H0 \* \[ H1 \* H0 ==> H2 ]).

Definition hwand_characterization_3 (op:hprop->hprop->hprop) :=
  forall H0 H1 H2, (H0 ==> op H1 H2) <-> (H1 \* H0 ==> H2).

Definition hwand_characterization_4 (op:hprop->hprop->hprop) :=
     (forall H0 H1 H2, (H1 \* H0 ==> H2) -> (H0 ==> op H1 H2))
  /\ (forall H1 H2, (H1 \* (op H1 H2) ==> H2)).

/* 四种刻画两两等价：1=2、2=3、3=4。以下证明供参考，不必逐行跟。 *)
```

```coq
(* 四种刻画两两等价：1=2、2=3、3=4。以下证明供参考，不必逐行跟。 *)

Lemma hwand_characterization_1_eq_2 :
  hwand_characterization_1 = hwand_characterization_2.
Proof using.
  applys pred_ext_1. intros op.
  unfold hwand_characterization_1, hwand_characterization_2.
  asserts K: (forall A B, A = B -> (op = A <-> op = B)).
  { intros. iff; subst*. } apply K; clear K.
  apply pred_ext_3. intros H1 H2 h. iff M.
  { exists (=h). rewrite hstar_hpure_r. split.
    { auto. }
    { intros h3 K3. rewrite hstar_comm in K3.
      destruct K3 as (h1&h2&K1&K2&D&U). subst h1 h3.
      rewrites (>> union_comm_of_disjoint D). applys M D K2. } }
  { (* 这个方向复刻 hwand_inv 的证明。 *)
    intros h1 D K1. destruct M as (H0&M).
    destruct M as (h0&h2&K0&K2&D'&U).
    lets (N&E): hpure_inv (rm K2). subst h h2.
    rewrite Fmap.union_empty_r in *.
    applys N. applys hstar_intro K1 K0. applys disjoint_sym D. }
Qed.

Lemma hwand_characterization_2_eq_3 :
  hwand_characterization_2 = hwand_characterization_3.
Proof using.
  applys pred_ext_1. intros op.
  unfold hwand_characterization_2, hwand_characterization_3. iff K.
  { subst. intros. iff M.
    { xchange M. intros H3 N. xchange N. }
    { xsimpl H0. xchange M. } }
  { apply fun_ext_2. intros H1 H2. apply himpl_antisym.
    { lets (M&_): (K (op H1 H2) H1 H2). xsimpl (op H1 H2).
      applys M. applys himpl_refl. }
    { xsimpl. intros H0 M. rewrite K. applys M. } }
Qed.

Lemma hwand_characterization_3_eq_4 :
  hwand_characterization_3 = hwand_characterization_4.
Proof using.
  applys pred_ext_1. intros op.
  unfold hwand_characterization_3, hwand_characterization_4. iff K.
  { split.
    { introv M. apply <- K. apply M. }
    { intros. apply K. auto. } }
  { destruct K as (K1&K2). intros. split.
    { introv M. xchange M. xchange (K2 H1 H2). }
    { introv M. applys K1. applys M. } }
Qed.

End HwandEquiv.
```

要点：1=2 的 → 方向取「缺失块」为 `(= h)`（恰好是当前堆这个**纯等式**），
← 方向就是 `hwand_inv`；2=3 就是 99.4 的 `hwand_equiv` 参数化到任意 `op`；
3=4 把 iff 拆成两条。结论：**特征等价唯一确定魔法杖**——这也是杖在各个分
离逻辑实现里「长得都一样」的原因。

## 99.11 qwand 多种刻画的等价性

`qwand` 有五种刻画（堆级直接定义、`\exists H0` 版、`\forall v` 逐点杖版、
特征等价版、引入+消去版），证明与 99.10 基本平行，多出的 2=3 一步把「存在
缺失块」与「逐点杖」接起来：


```coq
(* ---------- 99.11 qwand 多种刻画的等价性 ---------- *)

Module QwandEquiv.
Implicit Type op : (val->hprop)->(val->hprop)->hprop.

Definition qwand_characterization_1 op :=
  op = (fun Q1 Q2 => (fun h => forall v h', Fmap.disjoint h h' ->
                                            Q1 v h' -> Q2 v (h \u h'))).

Definition qwand_characterization_2 op :=
  op = (fun Q1 Q2 => \exists H0, H0 \* \[ Q1 \*+ H0 ===> Q2 ]).

Definition qwand_characterization_3 op :=
  op = (fun Q1 Q2 => \forall v, (Q1 v) \-* (Q2 v)).

Definition qwand_characterization_4 op :=
  forall H0 Q1 Q2, (H0 ==> op Q1 Q2) <-> (Q1 \*+ H0 ===> Q2).

Definition qwand_characterization_5 op :=
     (forall H0 Q1 Q2, (Q1 \*+ H0 ===> Q2) -> (H0 ==> op Q1 Q2))
  /\ (forall Q1 Q2, (Q1 \*+ (op Q1 Q2) ===> Q2)).

Lemma qwand_characterization_1_eq_2 :
  qwand_characterization_1 = qwand_characterization_2.
Proof using.
  applys pred_ext_1. intros op.
  unfold qwand_characterization_1, qwand_characterization_2.
  asserts K: (forall A B, A = B -> (op = A <-> op = B)).
  { intros. iff; subst*. } apply K; clear K.
  apply pred_ext_3. intros Q1 Q2 h. iff M.
  { exists (=h). rewrite hstar_hpure_r. split.
    { auto. }
    { intros v h3 K3. rewrite hstar_comm in K3.
      destruct K3 as (h1&h2&K1&K2&D&U). subst h1 h3. applys M D K2. } }
  { intros v h1 D K1. destruct M as (H0&M).
    destruct M as (h0&h2&K0&K2&D'&U).
    lets (N&E): hpure_inv (rm K2). subst h h2.
    rewrite Fmap.union_empty_r in *.
    applys N. rewrite hstar_comm. applys hstar_intro K0 K1 D. }
Qed.

Lemma qwand_characterization_2_eq_3 :
  qwand_characterization_2 = qwand_characterization_3.
Proof using.
  applys pred_ext_1. intros op.
  unfold qwand_characterization_2, qwand_characterization_3.
  asserts K: (forall A B, A = B -> (op = A <-> op = B)).
  { intros. iff; subst*. } apply K; clear K.
  apply fun_ext_2. intros Q1 Q2. apply himpl_antisym.
  { xpull. intros H0 M. applys himpl_hforall_r. intros v.
    rewrite hwand_equiv. xchange M. }
  { xsimpl (qwand Q1 Q2). applys qwand_cancel. }
Qed.

Lemma qwand_characterization_2_eq_4 :
  qwand_characterization_2 = qwand_characterization_4.
Proof using.
  applys pred_ext_1. intros op.
  unfold qwand_characterization_2, qwand_characterization_4. iff K.
  { subst. intros. iff M.
    { xchange M. intros v H3 N. xchange N. }
    { xsimpl H0. xchange M. } }
  { apply fun_ext_2. intros H1 H2. apply himpl_antisym.
    { lets (M&_): (K (op H1 H2) H1 H2). xsimpl (op H1 H2).
      applys M. applys himpl_refl. }
    { xsimpl. intros H0 M. rewrite K. applys M. } }
Qed.

Lemma qwand_characterization_4_eq_5 :
  qwand_characterization_4 = qwand_characterization_5.
Proof using.
  applys pred_ext_1. intros op.
  unfold qwand_characterization_4, qwand_characterization_5. iff K.
  { split.
    { introv M. apply <- K. apply M. }
    { intros. apply K. auto. } }
  { destruct K as (K1&K2). intros. split.
    { introv M. xchange M. xchange (K2 Q1 Q2). }
    { introv M. applys K1. applys M. } }
Qed.

End QwandEquiv.
```

## 99.12 小结


```coq
(* ---------- 99.12 小结 ----------
   1) hforall/hor/hand 把 Prop 层的量词与联结词提升到 hprop 层，
      均可用 \exists/\forall 加布尔编成"高级算子"，性质全在 hprop 层证；
   2) hwand 的特征等价 (H0 ==> H1 \-* H2) <-> (H1 \* H0 ==> H2)
      唯一确定了它：引入/消去/柯里化/传递/框架性全部由此展开；
   3) qwand 是逐点的 hwand，xsimpl 能自动消杖、自动应用引入规则；
   4) 分支框架规则用 Q1 \--* Q 把后果-框架规则的两条蕴含合成一条，
      绕开 evar H2 在存在量词下实例化失败的问题——这是 wand 的核心应用，
      也是 101 章 WP 生成器的理论基础。 *)
```

历史注记：杖是分离逻辑最初几年就有的算子，但它的实用价值长期存疑——CFML
1.0 验证了数千行高级数据结构与算法，全程没用杖。它的价值在两点上兑现：分
支框架规则（Krishnaswami–Birkedal–Aldrich 2010 提出，Hobor–Villard 2013
给出本章形式，后经 Iris 框架推广）与最弱前条件式推理（下一章起的主线）。

### 实测坑位（rocq 9.1.1 实编译经验）

- **`introv` 才能一步拿到「前提」**：`Lemma ... forall P H, P -> ...` 里写
  `intros HP` 只会引入**第一个变量 `P`**（把 `HP` 当成 `P` 的名字），后面
  `applys himpl_antisym` 便因目标还是 `forall H, ...` 而失败。要拿前提用
  `introv HP`（自动引入非依赖变量、名字给前提）。
- **`applys L x` vs `(L x)`**：部分应用写成**术语** `(himpl_hstar_hpure_r
  HP)` 会在类型检查阶段就报「无法推断隐式参数 H」；写成 `applys
  himpl_hstar_hpure_r HP`（喂参）由 applys 的按位匹配兜底。
- **`xsimpl`/`xpull` 的收尾**：归一化后剩纯 Prop（如 `null = null`、`P1 ->
  P2`）时不会自动关，补 `auto` 或用 `xsimpl*`；反之若 `xchange` 已把目标全
  部关闭，再多写一个 `xsimpl` 会报 "No such goal"——两者都要试。
- **`Global Opaque` 的表示谓词不能靠 `xsimpl` 折叠**：`MList nil p` 要用
  `rewrite MList_nil` 这类等式引理，不能指望化简器展开不透明常量。
- **杖的一行证明模式**：先 `applys himpl_hwand_r`（或 `rewrite
  qwand_equiv`）把杖挪到星号层面，再 `xchange (hwand_cancel H1 H2)` 消杖；
  `xchange` 会自动按交换/结合律重排星号来匹配——`hwand_cancel_part` 这类
  「部分消去」全靠这个能力。
