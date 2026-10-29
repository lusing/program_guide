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

(* ---------- 99.2 析取 hor ---------- *)

Module Hor.

(* 直接定义：堆满足 H1 或满足 H2。 *)

Definition hor' (H1 H2 : hprop) : hprop :=
  fun h => H1 h \/ H2 h.

(* 实用定义：借助存在量词与布尔，避免直接操纵堆。 *)

Definition hor (H1 H2 : hprop) : hprop :=
  \exists (b:bool), if b then H1 else H2.

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

(* 消去规则：要证 hor H1 H2 ==> H3，须两个方向都证。 *)

Lemma himpl_hor_l : forall H1 H2 H3,
  H1 ==> H3 ->
  H2 ==> H3 ->
  hor H1 H2 ==> H3.
Proof using.
  introv M1 M2. unfolds hor. applys himpl_hexists_l. intros b. case_if*.
Qed.

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

(* ---------- 99.3 合取 hand ---------- *)

Module Hand.
Import Hforall Hor.

(* 直接定义。 *)

Definition hand' (H1 H2 : hprop) : hprop :=
  fun h => H1 h /\ H2 h.

(* 实用定义：同一个堆既满足 H1 又满足 H2（借助 \forall 与布尔）。 *)

Definition hand (H1 H2 : hprop) : hprop :=
  \forall (b:bool), if b then H1 else H2.

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

(* 练习（1 星，标准，必做）：hand 交换律。 *)

Lemma hand_comm : forall H1 H2,
  hand H1 H2 = hand H2 H1.
Proof using.
  applys hprop_op_comm. intros H1 H2. unfolds hand.
  applys himpl_hforall_r. intros b.
  rewrite if_neg. applys himpl_hforall_l (neg b). applys himpl_refl.
Qed.

End Hand.

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

(* 特征等价：H0 ==> H1 \-* H2 当且仅当 H1 \* H0 ==> H2。
   类比算术：H0 = -H1+H2 与 H1+H0 = H2 是同一个说法。 *)

Lemma hwand_equiv : forall H0 H1 H2,
  (H0 ==> H1 \-* H2) <-> (H1 \* H0 ==> H2).
Proof using.
  unfold hwand. iff M.
  { xchange M. intros H N. xchange N. }
  { xsimpl H0. xchange M. }
Qed.

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

(* 消去规则的好用形式：H1 星上 (H1 \-* H2) 得 H2。 *)

Lemma hwand_cancel : forall H1 H2,
  H1 \* (H1 \-* H2) ==> H2.
Proof using. intros. applys himpl_hwand_r_inv. applys himpl_refl. Qed.

Arguments hwand_cancel : clear implicits.

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

(* 要证 H1 ==> \[P] \-* H2，只需在 P 成立时证 H1 ==> H2。 *)

Lemma himpl_hwand_hpure_r : forall H1 H2 P,
  (P -> H1 ==> H2) ->
  H1 ==> (\[P] \-* H2).
Proof using. introv M. applys himpl_hwand_r. xsimpl. applys M. Qed.

(* 练习（2 星，标准，选做）：\[P1 -> P2] 蕴含 \[P1] \-* \[P2]。
   提示：展开 hwand 后用 xsimpl 给右边的存在量词提供显式见证。 *)

Lemma himpl_hwand_hpure_lr : forall (P1 P2:Prop),
  \[P1 -> P2] ==> (\[P1] \-* \[P2]).
Proof using.
  intros. unfold hwand. xsimpl (\[P1 -> P2]).
  { auto. }
  { xsimpl. auto. }
Qed.

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

(* 练习（1 星，标准，必做）：H1 ==> H2 \-* (H2 \* H1)。 *)

Lemma himpl_hwand_hstar_same_r : forall H1 H2,
  H1 ==> (H2 \-* (H2 \* H1)).
Proof using. intros. applys himpl_hwand_r. xsimpl. Qed.

(* 练习（2 星，标准，必做）：H1 \* ((H1 \* H2) \-* H3) 化简为 H2 \-* H3。 *)

Lemma hwand_cancel_part : forall H1 H2 H3,
  H1 \* ((H1 \* H2) \-* H3) ==> (H2 \-* H3).
Proof using.
  intros. applys himpl_hwand_r. xchange (hwand_cancel (H1 \* H2) H3).
Qed.

(* 练习（3 星，标准，选做）：杖的框架性。 *)

Lemma hwand_frame : forall H1 H2 H3,
  H1 \-* H2 ==> (H1 \* H3) \-* (H2 \* H3).
Proof using.
  intros. applys himpl_hwand_r. xchange (hwand_cancel H1 H2).
Qed.

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

(* 练习（1 星，标准，必做）：H ==> Q \--* (Q \*+ H)。 *)

Lemma himpl_qwand_hstar_same_r : forall H Q,
  H ==> Q \--* (Q \*+ H).
Proof using. intros. rewrite qwand_equiv. applys qimpl_refl. Qed.

(* 练习（2 星，标准，选做）：H \* ((Q1 \*+ H) \--* Q2) 化简为 Q1 \--* Q2。 *)

Lemma qwand_cancel_part : forall H Q1 Q2,
  H \* ((Q1 \*+ H) \--* Q2) ==> (Q1 \--* Q2).
Proof using.
  intros. rewrite qwand_equiv. xchange (@qwand_cancel (Q1 \*+ H)).
Qed.

End Qwand.

(* ---------- 99.6 xsimpl 对魔法杖的支持 ---------- *)

Module XsimplDemo.

(* 库版 xsimpl 能识别并约去成对的杖与被减项。 *)

Lemma xsimpl_demo_hwand_cancel : forall H1 H2 H3 H4 H5,
  H1 \* (H2 \-* H3) \* H4 \* H2 ==> H5.
Proof using. intros. xsimpl. Abort.

Lemma xsimpl_demo_hwand_cancel_partial : forall H1 H2 H3 H4 H5 H6,
  ((H1 \* H2 \* H3) \-* H4) \* H5 \* H2 ==> H6.
Proof using. intros. xsimpl. Abort.

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

(* ---------- 99.8 分支框架规则 ---------- *)

Module RamifiedFrame.
Import Hwand Qwand.

Parameter triple_conseq_frame : forall H2 H1 Q1 t H Q,
  triple t H1 Q1 ->
  H ==> H1 \* H2 ->
  Q1 \*+ H2 ===> Q ->
  triple t H Q.

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

(* ---------- 99.9 魔法杖的一些诱人但不成立的性质 ---------- *)

Module HwandFalse.
Import Hwand.

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

(* hwand_cancel 的逆 H2 ==> H1 \* (H1 \-* H2) 也不成立：
   反例 H2 := \[]，H1 := \[False]。 *)

Lemma not_himpl_hwand_r_inv_reciprocal : exists H1 H2,
  ~ (H2 ==> H1 \* (H1 \-* H2)).
Proof using.
  exists \[False] \[]. intros N. forwards K: N (Fmap.empty:heap).
  applys hempty_intro. rewrite hstar_hpure_l in K. destruct K. auto.
Qed.

(* 经验法则：对任何"凭空造出杖"的蕴含都要警惕。 *)

End HwandFalse.

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

(* ---------- 99.12 小结 ----------
   1) hforall/hor/hand 把 Prop 层的量词与联结词提升到 hprop 层，
      均可用 \exists/\forall 加布尔编成"高级算子"，性质全在 hprop 层证；
   2) hwand 的特征等价 (H0 ==> H1 \-* H2) <-> (H1 \* H0 ==> H2)
      唯一确定了它：引入/消去/柯里化/传递/框架性全部由此展开；
   3) qwand 是逐点的 hwand，xsimpl 能自动消杖、自动应用引入规则；
   4) 分支框架规则用 Q1 \--* Q 把后果-框架规则的两条蕴含合成一条，
      绕开 evar H2 在存在量词下实例化失败的问题——这是 wand 的核心应用，
      也是 101 章 WP 生成器的理论基础。 *)
