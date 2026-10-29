(* 103 仿射分离逻辑：可丢弃资源、affine-top、精化三元组与 GC 战术 *)
(* 取材 Software Foundations 卷六 Separation Logic Foundations 的 Affine 章。 *)

Set Implicit Arguments.
From SLF Require Export LibSepReference.

Implicit Types f : var.
Implicit Types b : bool.
Implicit Types v : val.
Implicit Types h : heap.
Implicit Types P : Prop.
Implicit Types H : hprop.
Implicit Types Q : val->hprop.

Module Affine.

(* ---------- 103.1 动机：不能泄漏的内存单元 ---------- *)

Module MotivatingExample.
Export DemoPrograms.

Definition succ_using_incr :=
  <{ fun 'n =>
       let 'p = ref 'n in
       incr 'p;
       ! 'p }>.

(* 在线性逻辑中，后条件必须交代函数留下的引用单元。 *)

Lemma triple_succ_using_incr : forall (n:int),
  triple (succ_using_incr n)
    \[]
    (fun r => \[r = n+1] \* \exists p, (p ~~> (n+1))).
Proof using.
  xwp. xapp. intros p. xapp. xapp. xsimpl. auto.
Qed.

End MotivatingExample.

(* ---------- 103.2 哪些堆和堆谓词可以丢弃 ---------- *)

(* heap_affine 是程序逻辑设计者提供的资源策略；这里只假设空堆可丢弃，
   且两个不相交可丢弃堆的并仍可丢弃。 *)

Parameter heap_affine : heap -> Prop.

Parameter heap_affine_empty :
  heap_affine Fmap.empty.

Parameter heap_affine_union : forall h1 h2,
  heap_affine h1 ->
  heap_affine h2 ->
  Fmap.disjoint h1 h2 ->
  heap_affine (Fmap.union h1 h2).

(* 一个堆谓词仿射，当且仅当它只在仿射堆上成立。 *)

Definition haffine (H:hprop) : Prop :=
  forall h, H h -> heap_affine h.

Lemma haffine_hempty :
  haffine \[].
Proof using.
  introv K. lets E: hempty_inv K. subst. applys heap_affine_empty.
Qed.

Lemma haffine_hpure : forall P,
  haffine \[P].
Proof using.
  intros. intros h K. lets (HP&M): hpure_inv K.
  subst. applys heap_affine_empty.
Qed.

Lemma haffine_hstar : forall H1 H2,
  haffine H1 ->
  haffine H2 ->
  haffine (H1 \* H2).
Proof using.
  introv M1 M2 K. lets (h1&h2&K1&K2&D&U): hstar_inv K.
  subst. applys* heap_affine_union.
Qed.

Lemma haffine_hexists : forall A (J:A->hprop),
  (forall x, haffine (J x)) ->
  haffine (\exists x, (J x)).
Proof using. introv F1 (x&Hx). applys* F1. Qed.

(* 对全称量词，只要有一个分支仿射即可；对存在量词则必须全部分支仿射。 *)

Lemma haffine_hforall' : forall A (J:A->hprop),
  (exists x, haffine (J x)) ->
  haffine (\forall x, (J x)).
Proof using.
  introv (x&Hx) M. lets N: hforall_inv M. applys* Hx.
Qed.

Lemma haffine_hforall : forall A `{Inhab A} (J:A->hprop),
  (forall x, haffine (J x)) ->
  haffine (\forall x, (J x)).
Proof using.
  introv IA M. applys haffine_hforall'. exists (arbitrary (A:=A)). applys M.
Qed.

Lemma haffine_hstar_hpure_l : forall P H,
  (P -> haffine H) ->
  haffine (\[P] \* H).
Proof using. introv M. intros h K. rewrite hstar_hpure_l in K. applys* M. Qed.

(* ---------- 103.3 affine-top 谓词 \GC ---------- *)

(* \GC 表示“某个可丢弃谓词所描述的资源”。 *)

Definition hgc : hprop :=
  \exists H, \[haffine H] \* H.

Declare Scope hgc_scope.
Open Scope hgc_scope.

Notation "\GC" := (hgc) : hgc_scope.

(* 原书练习（2 星）：从底层堆的仿射性构造 \GC。 *)

Lemma hgc_intro : forall h,
  heap_affine h ->
  \GC h.
Proof using.
  intros h M. unfold hgc. exists (= h).
  rewrite hstar_hpure_l. split.
  { intros h' ->. exact M. }
  { reflexivity. }
Qed.

(* 原书练习（2 星）：从 \GC 消去得到底层堆的仿射性。 *)

Lemma hgc_inv : forall h,
  \GC h ->
  heap_affine h.
Proof using.
  intros h M. unfold hgc in M. destruct M as (H&M).
  rewrite hstar_hpure_l in M. destruct M as (A&K). applys A K.
Qed.

Lemma hgc_eq_heap_affine :
  hgc = heap_affine.
Proof using.
  intros. applys himpl_antisym.
  { intros h M. applys* hgc_inv. }
  { intros h M. applys* hgc_intro. }
Qed.

(* 两份垃圾可以合并成一份；\GC 自身也是仿射谓词。 *)

Lemma hstar_hgc_hgc :
  (\GC \* \GC) = \GC.
Proof using.
  unfold hgc. applys himpl_antisym.
  { xpull. intros H1 K1 H2 K2. xsimpl (H1 \* H2). applys* haffine_hstar. }
  { xpull. intros H K. xsimpl H \[]. auto. applys haffine_hempty. }
Qed.

Lemma haffine_hgc :
  haffine \GC.
Proof using.
  applys haffine_hexists. intros H. applys haffine_hstar_hpure_l. auto.
Qed.

Lemma himpl_hgc_r : forall H,
  haffine H ->
  H ==> \GC.
Proof using. introv M. intros h K. applys hgc_intro. applys M K. Qed.

Lemma hempty_himpl_hgc :
  \[] ==> \GC.
Proof using. applys himpl_hgc_r. applys haffine_hempty. Qed.

(* 原书练习（3 星）：\GC 可以吸收任意仿射谓词。 *)

Lemma himpl_hgc_absorb_r : forall H,
  haffine H ->
  \GC \* H ==> \GC.
Proof using.
  introv M. xchange (himpl_hgc_r M). rewrite hstar_hgc_hgc. applys himpl_refl.
Qed.

(* ---------- 103.4 全仿射与全线性两种极端实例 ---------- *)

Module FullyAffineLogic.

Parameter heap_affine_def : forall h,
  heap_affine h = True.

Lemma heap_affine_empty :
  heap_affine Fmap.empty.
Proof using. rewrite* heap_affine_def. Qed.

Lemma heap_affine_union : forall h1 h2,
  heap_affine h1 ->
  heap_affine h2 ->
  Fmap.disjoint h1 h2 ->
  heap_affine (Fmap.union h1 h2).
Proof using. intros. rewrite* heap_affine_def. Qed.

Lemma haffine_equiv : forall H,
  (haffine H) <-> True.
Proof using.
  intros. iff M.
  { auto. }
  { unfold haffine. intros. rewrite* heap_affine_def. }
Qed.

Definition htop : hprop :=
  \exists H, H.

Lemma hgc_eq_htop : hgc = htop.
Proof using.
  unfold hgc, htop. applys himpl_antisym.
  { xsimpl. }
  { xsimpl. intros. rewrite* haffine_equiv. }
Qed.

End FullyAffineLogic.

Module FullyLinearLogic.

Parameter heap_affine_def : forall h,
  heap_affine h = (h = Fmap.empty).

Lemma heap_affine_empty :
  heap_affine Fmap.empty.
Proof using. rewrite* heap_affine_def. Qed.

Lemma heap_affine_union : forall h1 h2,
  heap_affine h1 ->
  heap_affine h2 ->
  Fmap.disjoint h1 h2 ->
  heap_affine (Fmap.union h1 h2).
Proof using.
  introv K1 K2 D. rewrite heap_affine_def in *.
  subst. rewrite* Fmap.union_empty_r.
Qed.

Lemma haffine_equiv : forall H,
  haffine H <-> (H ==> \[]).
Proof using.
  intros. unfold haffine. iff M.
  { intros h K. specializes M K. rewrite heap_affine_def in M.
    subst. applys hempty_intro. }
  { intros h K. specializes M K. rewrite heap_affine_def.
    applys hempty_inv M. }
Qed.

Lemma hgc_eq_hempty : hgc = hempty.
Proof using.
  unfold hgc. applys himpl_antisym.
  { xpull. introv N. rewrite* haffine_equiv in N. }
  { xsimpl \[]. applys haffine_hempty. }
Qed.

End FullyLinearLogic.

(* ---------- 103.5 精化三元组并证明结构规则 ---------- *)

Module NewTriples.

(* 新定义把“求值后允许留下垃圾”直接编码进语义三元组。 *)

Definition triple (t:trm) (H:hprop) (Q:val->hprop) : Prop :=
  forall s, H s -> eval s t (Q \*+ \GC).

Lemma triple_conseq : forall t H' Q' H Q,
  triple t H' Q' ->
  H ==> H' ->
  Q' ===> Q ->
  triple t H Q.
Proof using.
  unfolds triple. introv M MH MQ HF. applys* eval_conseq. xsimpl*.
Qed.

Lemma triple_frame : forall t H Q H',
  triple t H Q ->
  triple t (H \* H') (Q \*+ H').
Proof using.
  introv M HF. lets (h1&h2&M1&M2&MD&MU): hstar_inv (rm HF).
  subst. specializes M M1. applys eval_conseq.
  { applys eval_frame M MD. } { xsimpl. intros h' ->. applys M2. }
Qed.

Lemma triple_hpure : forall t (P:Prop) H Q,
  (P -> triple t H Q) ->
  triple t (\[P] \* H) Q.
Proof using.
  introv M. intros h (h1&h2&M1&M2&D&U). destruct M1 as (M1&HP).
  lets E: hempty_inv HP. subst. rewrite Fmap.union_empty_l. applys~ M.
Qed.

Lemma triple_hexists : forall t (A:Type) (J:A->hprop) Q,
  (forall (x:A), triple t (J x) Q) ->
  triple t (hexists J) Q.
Proof using. introv M (x&K). applys M K. Qed.

(* 序列规则必须把两段求值各自留下的 \GC 合并。 *)

Lemma triple_seq : forall t1 t2 H Q H1,
  triple t1 H (fun v => H1) ->
  triple t2 H1 Q ->
  triple (trm_seq t1 t2) H Q.
Proof using.
  unfold triple. introv M1 M2. intros s Hs. applys eval_seq.
  { applys M1 Hs. }
  { simpl. intros v1 s2 Hs2. lets (h1&h2&N1&N2&D&->): hstar_inv (rm Hs2).
    applys eval_conseq. { applys eval_frame D. applys* M2. }
    asserts R: ((= h2) ==> \GC). { intros ? ->. auto. } xchange (rm R).
    xchange hstar_hgc_hgc. xsimpl. }
Qed.

(* 原书练习（3 星）：从后条件删去一个 \GC。 *)

Lemma triple_hgc_post : forall t H Q,
  triple t H (Q \*+ \GC) ->
  triple t H Q.
Proof using.
  introv M. intros s Hs. applys eval_conseq M. { applys Hs. }
  intros v. simpl. rewrite hstar_assoc. rewrite hstar_hgc_hgc. applys himpl_refl.
Qed.

(* 原书练习（1 星）：任意仿射后条件都可先改写成 \GC 再丢弃。 *)

Lemma triple_haffine_post : forall t H H' Q,
  haffine H' ->
  triple t H (Q \*+ H') ->
  triple t H Q.
Proof using.
  introv A M. applys triple_hgc_post. applys triple_conseq M.
  { applys himpl_refl. }
  { intros v. simpl. applys himpl_frame_r. applys himpl_hgc_r A. }
Qed.

(* 原书练习（1 星）：反向实例化 triple_haffine_post。 *)

Lemma triple_hgc_post_from_triple_haffine_post : forall t H Q,
  triple t H (Q \*+ \GC) ->
  triple t H Q.
Proof using.
  introv M. applys triple_haffine_post M. applys haffine_hgc.
Qed.

(* 原书练习（1 星）：框架规则把 H' 移到后条件，再将其丢弃。 *)

Lemma triple_haffine_pre : forall t H H' Q,
  haffine H' ->
  triple t H Q ->
  triple t (H \* H') Q.
Proof using.
  introv A M. applys triple_haffine_post A. applys triple_frame M.
Qed.

(* 原书练习（2 星）：后果、框架与丢弃的组合规则。 *)

Lemma triple_conseq_frame_hgc : forall H2 H1 Q1 t H Q,
  triple t H1 Q1 ->
  H ==> H1 \* H2 ->
  Q1 \*+ H2 ===> Q \*+ \GC ->
  triple t H Q.
Proof using.
  introv M WH WQ. applys triple_hgc_post.
  applys triple_conseq WH WQ. applys triple_frame M.
Qed.

(* 原书练习（1 星）：带丢弃能力的汇聚框架规则。 *)

Lemma triple_ramified_frame_hgc : forall H1 Q1 t H Q,
  triple t H1 Q1 ->
  H ==> H1 \* (Q1 \--* (Q \*+ \GC)) ->
  triple t H Q.
Proof using.
  introv M W. applys triple_conseq_frame_hgc (Q1 \--* (Q \*+ \GC)) M W.
  rewrite* <- qwand_equiv.
Qed.

(* ---------- 103.6 WP 形式的丢弃规则 ---------- *)

Definition wp (t:trm) (Q:val->hprop) : hprop :=
  fun s => eval s t (Q \*+ \GC).

Lemma wp_equiv : forall t H Q,
  (H ==> wp t Q) <-> (triple t H Q).
Proof using. iff M; introv Hs; applys M Hs. Qed.

Lemma wp_conseq : forall t Q1 Q2,
  Q1 ===> Q2 ->
  wp t Q1 ==> wp t Q2.
Proof using.
  unfold wp. introv M. intros s Hs. applys* eval_conseq. xsimpl*.
Qed.

Lemma wp_frame : forall t H Q,
  (wp t Q) \* H ==> wp t (Q \*+ H).
Proof using.
  intros. unfold wp. intros h HF.
  lets (h1&h2&M1&M2&MD&MU): hstar_inv (rm HF).
  subst. applys eval_conseq.
  { applys eval_frame M1 MD. }
  { xsimpl. intros h' ->. applys M2. }
Qed.

(* 原书练习（1 星）：WP 形式的后条件丢弃。 *)

Lemma wp_hgc_post : forall t Q,
  wp t (Q \*+ \GC) ==> wp t Q.
Proof using.
  intros. unfold wp. intros s Hs. applys eval_conseq Hs.
  intros v. simpl. rewrite hstar_assoc. rewrite hstar_hgc_hgc. applys himpl_refl.
Qed.

(* 原书练习（3 星）：先框架，再把 H 改成 \GC，最后使用后条件丢弃。 *)

Lemma wp_haffine_pre : forall t H Q,
  haffine H ->
  (wp t Q) \* H ==> wp t Q.
Proof using.
  introv A. applys himpl_trans (wp t (Q \*+ H)).
  { applys wp_frame. }
  applys himpl_trans (wp t (Q \*+ \GC)).
  { applys wp_conseq. intros v. simpl.
    applys himpl_frame_r. applys himpl_hgc_r A. }
  { applys wp_hgc_post. }
Qed.

(* 原书练习（3 星）：WP 的汇聚框架规则同时包含丢弃规则。 *)

Lemma wp_ramified : forall Q1 Q2 t,
  (wp t Q1) \* (Q1 \--* (Q2 \*+ \GC)) ==> (wp t Q2).
Proof using.
  intros. applys himpl_trans (wp t (Q2 \*+ \GC)).
  2:{ applys wp_hgc_post. }
  applys himpl_trans (wp t (Q1 \*+ (Q1 \--* (Q2 \*+ \GC)))).
  { applys wp_frame. }
  { applys wp_conseq. applys qwand_cancel. }
Qed.

(* ---------- 103.7 把后条件丢弃集成进 xwp ---------- *)

Parameter xwp_lemma : forall v1 v2 x t1 H Q,
  v1 = val_fun x t1 ->
  H ==> wpgen ((x,v2)::nil) t1 Q ->
  triple (trm_app v1 v2) H Q.

Lemma xwp_lemma' : forall v1 v2 x t1 H Q,
  v1 = val_fun x t1 ->
  H ==> wpgen ((x,v2)::nil) t1 (Q \*+ \GC) ->
  triple (trm_app v1 v2) H Q.
Proof using. introv E M. applys triple_hgc_post. applys* xwp_lemma. Qed.

Tactic Notation "xwp" :=
  intros; applys xwp_lemma';
  [ reflexivity | simpl; unfold wpgen_var; simpl ].

Module MotivatingExampleWithUpdatedXwp.
Export MotivatingExample.

Parameter haffine_hany : forall (H:hprop),
  haffine H.

Lemma triple_succ_using_incr' : forall (n:int),
  triple (succ_using_incr n)
    \[]
    (fun r => \[r = n+1]).
Proof using.
  xwp. xapp. intros r. xapp. xapp. xsimpl. { auto. }
  applys himpl_hgc_r. applys haffine_hany.
Qed.

End MotivatingExampleWithUpdatedXwp.

(* ---------- 103.8 支持丢弃的 mkstruct ---------- *)

Definition mkstruct (F:formula) : formula :=
  fun Q => \exists Q', F Q' \* (Q' \--* (Q \*+ \GC)).

Lemma mkstruct_hgc : forall Q F,
  mkstruct F (Q \*+ \GC) ==> mkstruct F Q.
Proof using.
  intros. unfold mkstruct. set (X := hgc) at 3. replace X with (\GC \* \GC).
  { xsimpl. } { subst X. apply hstar_hgc_hgc. }
Qed.

Lemma mkstruct_erase : forall F Q,
  F Q ==> mkstruct F Q.
Proof using.
  intros. unfold mkstruct. xsimpl Q. apply himpl_hgc_r. apply haffine_hempty.
Qed.

Lemma mkstruct_conseq : forall F Q1 Q2,
  Q1 ===> Q2 ->
  mkstruct F Q1 ==> mkstruct F Q2.
Proof using.
  introv WQ. unfold mkstruct. xpull. intros Q'. xsimpl Q'. xchange WQ.
Qed.

Lemma mkstruct_frame : forall F H Q,
  (mkstruct F Q) \* H ==> mkstruct F (Q \*+ H).
Proof using.
  intros. unfold mkstruct. xpull. intros Q'. xsimpl Q'.
Qed.

Lemma mkstruct_monotone : forall F1 F2 Q,
  (forall Q, F1 Q ==> F2 Q) ->
  mkstruct F1 Q ==> mkstruct F2 Q.
Proof using.
  introv WF. unfolds mkstruct. xpull. intros Q'. xchange WF. xsimpl Q'.
Qed.

(* 原书练习（2 星）：mkstruct 的后条件仿射丢弃。 *)

Lemma mkstruct_haffine_post : forall H Q F,
  haffine H ->
  mkstruct F (Q \*+ H) ==> mkstruct F Q.
Proof using.
  introv A. applys himpl_trans_r mkstruct_hgc.
  applys mkstruct_conseq. intros v. simpl.
  applys himpl_frame_r. applys himpl_hgc_r A.
Qed.

(* 原书练习（2 星）：mkstruct 的前条件仿射丢弃。 *)

Lemma mkstruct_haffine_pre : forall H Q F,
  haffine H ->
  (mkstruct F Q) \* H ==> mkstruct F Q.
Proof using.
  introv A. applys himpl_trans.
  { applys mkstruct_frame. }
  { applys mkstruct_haffine_post A. }
Qed.

End NewTriples.

(* ---------- 103.9 xaffine、xsimpl 与三个 GC 战术 ---------- *)

Module Xaffine.

Create HintDb haffine.

Tactic Notation "xaffine" :=
  repeat match goal with |- haffine ?H =>
    match H with
    | (hempty) => apply haffine_hempty
    | (hpure _) => apply haffine_hpure
    | (hstar _ _) => apply haffine_hstar
    | (hexists _) => apply haffine_hexists
    | (hforall _) => apply haffine_hforall
    | (hgc) => apply haffine_hgc
    | _ => eauto with haffine
    end
  end.

Lemma xaffine_demo : forall H1 H2 H3,
  haffine H1 ->
  haffine H2 ->
  haffine H3 ->
  haffine (H1 \* H2 \* H3).
Proof using. introv K1 K2 K3. xaffine. Qed.

End Xaffine.

Module XsimplExtended.

Lemma xsimpl_xaffine_demo : forall H1 H2,
  haffine H1 ->
  H1 \* H2 ==> H2 \* \GC.
Proof using. introv K1. xsimpl. applys himpl_hgc_r K1. Qed.

End XsimplExtended.

Module XGC.
Import Xaffine NewTriples.

Lemma xgc_lemma: forall H1 H2 H F Q,
  H ==> H1 \* H2 ->
  haffine H1 ->
  H2 ==> mkstruct F Q ->
  H ==> mkstruct F Q.
Proof using.
  introv WH K M. xchange WH. xchange M.
  applys himpl_trans mkstruct_frame.
  applys himpl_trans_r mkstruct_hgc.
  applys mkstruct_conseq. xsimpl. applys Affine.himpl_hgc_r K.
Qed.

Tactic Notation "xgc" constr(H) :=
  eapply (@xgc_lemma H); [ xsimpl | xaffine | ].

Lemma xgc_demo : forall H1 H2 H3 F Q,
  haffine H2 ->
  H1 \* H3 ==> mkstruct F Q ->
  (H1 \* H2 \* H3) ==> mkstruct F Q.
Proof using.
  introv K2 M. xgc H2. rewrite (hstar_comm H3 H1). applys M.
Qed.

Tactic Notation "xgc_keep" constr(H) :=
  eapply (@xgc_lemma _ H); [ xsimpl | xaffine | ].

Lemma xgc_keep_demo : forall H1 H2 H3 F Q,
  haffine H1 ->
  haffine H3 ->
  H2 ==> mkstruct F Q ->
  (H1 \* H2 \* H3) ==> mkstruct F Q.
Proof using. introv K1 K3 M. xgc_keep H2. applys M. Qed.

Lemma xgc_post_lemma : forall H Q F,
  H ==> mkstruct F (Q \*+ \GC) ->
  H ==> mkstruct F Q.
Proof using. introv M. xchange M. applys mkstruct_hgc. Qed.

Tactic Notation "xgc_post" :=
  apply xgc_post_lemma.

Lemma xgc_post_demo : forall H1 H2 H3 F Q,
  haffine H2 ->
  haffine H3 ->
  H1 ==> mkstruct F (Q \*+ H2 \*+ H3) ->
  H1 ==> mkstruct F Q.
Proof using.
  introv K2 K3 M.
  xgc_post.
  xchange M. applys mkstruct_conseq.
  xsimpl. applys himpl_hgc_r. xaffine.
Qed.

End XGC.

(* ---------- 103.10 量词规则的谓词族形式 ---------- *)

Module HaffineQuantifiers.

Definition haffine_post (A:Type) (J:A->hprop) : Prop :=
  forall x, haffine (J x).

Lemma haffine_hexists : forall A (J:A->hprop),
  haffine_post J ->
  haffine (hexists J).
Proof using. introv F1 (x&Hx). applys* F1. Qed.

Lemma haffine_hforall : forall A `{Inhab A} (J:A->hprop),
  haffine_post J ->
  haffine (hforall J).
Proof using.
  introv IA F1 Hx. lets N: hforall_inv Hx. applys* F1 (arbitrary (A:=A)).
Qed.

End HaffineQuantifiers.

(* ---------- 103.11 由前条件丢弃推导后条件丢弃 ---------- *)

Module FromPreToPostGC.

Parameter triple_hgc_pre : forall t H Q,
  triple t H Q ->
  triple t (H \* \GC) Q.

Parameter eta_same_triples : forall (t:trm) (x:var) H Q,
   triple t H Q <-> triple (trm_let x t x) H Q.

(* 把 t 改写成 let x = t in x，就能在两段求值之间使用前条件丢弃。 *)

Lemma triple_hgc_post_from_hgc_pre : forall t H Q,
  triple t H (Q \*+ \GC) ->
  triple t H Q.
Proof using.
  introv M. rewrite (eta_same_triples t "x"). applys triple_let.
  { applys M. }
  { intros v. simpl. applys triple_hgc_pre. applys triple_val. auto. }
Qed.

End FromPreToPostGC.

End Affine.
