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

(* ---------- 96.3 蕴含的框架性质（本节先陈述，96.7 给出证明） ---------- *)

Parameter himpl_frame_l : forall H2 H1 H1',
  H1 ==> H1' ->
  (H1 \* H2) ==> (H1' \* H2).

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

(* ---------- 96.5 从堆谓词抽取信息：同一位置的两格是矛盾 ---------- *)

Lemma hstar_hsingle_same_loc : forall (p:loc) (v1 v2:val),
  (p ~~> v1) \* (p ~~> v2) ==> \[False].
Proof using.
  intros. unfold hsingle. intros h (h1&h2&E1&E2&D&E). false.
  subst. eapply Fmap.disjoint_single_single_same_inv. eapply D.
Qed.

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

(* ---------- 96.6 xsimpl 与 xchange：蕴含的自动化 ---------- *)

Module XsimplTactic.
Import LibSepReference.

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

Lemma xsimpl_demo_rhs_exists_solved_1 : forall (p:loc),
  p ~~> 3 ==>
  \exists (n:int), p ~~> n.
Proof using. xsimpl. Qed.

Lemma xsimpl_demo_rhs_exists_solved_2 : forall (p qq:loc),
  p ~~> 3 \* qq ~~> 3 ==>
  \exists (n:int), p ~~> n \* qq ~~> n.
Proof using. xsimpl. Qed.

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
