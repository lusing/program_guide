(* 100 最弱前条件：wp 的语义定义、wp 式结构规则与构件规则 *)
(* 取材 Software Foundations 卷六 Separation Logic Foundations 的 WPsem 章。 *)

Set Implicit Arguments.
From SLF Require Import LibSepReference.

Implicit Types f : var.
Implicit Types b : bool.
Implicit Types v w : val.
Implicit Types p : loc.
Implicit Types h : heap.
Implicit Types P : Prop.
Implicit Types H : hprop.
Implicit Types Q : val->hprop.

(* ---------- 100.1 最弱前条件的定义 ---------- *)

(* wp t Q 是这样的堆谓词：H ==> wp t Q 当且仅当 triple t H Q。
   对照 triple 的定义可知 wp t Q 就是 fun s => eval s t Q。 *)

Definition wp (t : trm) (Q : val->hprop) : hprop :=
  fun s => eval s t Q.

Lemma wp_equiv : forall t H Q,
  (H ==> wp t Q) <-> (triple t H Q).
Proof using.
  iff M. { introv Hs. applys M Hs. } { introv Hs. applys M Hs. }
Qed.

(* wp t Q 是合法前条件…… *)

Lemma wp_pre : forall t Q,
  triple t (wp t Q) Q.
Proof using. intros. rewrite <- wp_equiv. applys himpl_refl. Qed.

(* ……而且是"最弱的"：一切合法前条件都蕴含它。 *)

Lemma wp_weakest : forall t H Q,
  triple t H Q ->
  H ==> wp t Q.
Proof using. introv M. rewrite wp_equiv. applys M. Qed.

(* ---------- 100.2 结构规则的 wp 版 ---------- *)

(* 框架规则：拿着 H，且在另一块状态上执行 t 能产出 Q，
   则执行 t 能同时产出 Q 与 H。直接用 eval_frame 证。 *)

Lemma wp_frame : forall t H Q,
  (wp t Q) \* H ==> wp t (Q \*+ H).
Proof using.
  intros. unfold wp. intros h HF.
  lets (h1&h2&M1&M2&MD&MU): hstar_inv HF.
  subst. applys eval_conseq.
  { applys eval_frame M1 MD. }
  { xsimpl. intros h' ->. applys M2. }
Qed.

(* 反方向不成立：t = let p = ref 1 in 0 产出悬挂单元 \exists p, p ~~> 1，
   空堆满足 wp t (Q \*+ H)，但 (wp t Q) \* H 需要凭空造出一格。 *)

(* 与 triple_frame 的对应：把 triple t H Q 换成 H ==> wp t Q，
   再用传递性消去 H1，就得到 wp_frame。 *)

Lemma wp_frame_trans : forall t H1 Q H,
  H1 ==> wp t Q ->
  (H1 \* H) ==> wp t (Q \*+ H).
Proof using. introv M. xchange M. applys* wp_frame. Qed.

(* 后果规则：wp t Q 对 Q 协变。 *)

Lemma wp_conseq : forall t Q1 Q2,
  Q1 ===> Q2 ->
  wp t Q1 ==> wp t Q2.
Proof using. unfold wp. introv M. intros s Hs. applys* eval_conseq. Qed.

Lemma wp_conseq_trans : forall t H1 H2 Q1 Q2,
  H1 ==> wp t Q1 ->
  H2 ==> H1 ->
  Q1 ===> Q2 ->
  H2 ==> wp t Q2.
Proof using.
  introv M WH WQ. xchange WH. xchange M. applys wp_conseq WQ.
Qed.

(* 抽取规则在 wp 风格下没有对应物：它们恰好就是蕴含的抽取规则。
   triple_hpure 换写成 wp 蕴含后只是 himpl_hstar_hpure_l 的特例。 *)

Lemma triple_hpure_with_wp : forall t H Q (P:Prop),
  (P -> (H ==> wp t Q)) ->
  (\[P] \* H) ==> wp t Q.
Proof using. introv M. applys himpl_hstar_hpure_l M. Qed.

(* 组合规则的无 H 版本（更简洁）。

   练习（2 星，标准，必做）：用 wp_frame 与 wp_conseq 拼装。 *)

Lemma wp_conseq_frame : forall t H Q1 Q2,
  Q1 \*+ H ===> Q2 ->
  (wp t Q1) \* H ==> (wp t Q2).
Proof using.
  introv M. applys himpl_trans (wp t (Q1 \*+ H)).
  { applys wp_frame. }
  { applys wp_conseq M. }
Qed.

(* 组合的后果-框架规则（两条蕴含版本）。

   练习（2 星，标准，必做）。 *)

Lemma wp_conseq_frame_trans : forall t H H1 H2 Q1 Q,
  H1 ==> wp t Q1 ->
  H ==> H1 \* H2 ->
  Q1 \*+ H2 ===> Q ->
  H ==> wp t Q.
Proof using.
  introv M WH WQ. xchange WH. xchange M.
  applys wp_conseq_frame WQ.
Qed.

(* 分支框架规则：99 章 triple_ramified_frame 的 wp 版，
   一条规则涵盖全部结构规则。 *)

Lemma wp_ramified : forall t Q1 Q2,
  (wp t Q1) \* (Q1 \--* Q2) ==> (wp t Q2).
Proof using. intros. applys wp_conseq_frame. applys qwand_cancel. Qed.

Lemma wp_ramified_trans : forall t H Q1 Q2,
  H ==> (wp t Q1) \* (Q1 \--* Q2) ->
  H ==> (wp t Q2).
Proof using. introv M. xchange M. applys wp_ramified. Qed.

(* 练习（3 星，标准，必做）：wp_conseq 可由 wp_ramified 导出。 *)

Lemma wp_conseq_of_wp_ramified : forall t Q1 Q2,
  Q1 ===> Q2 ->
  wp t Q1 ==> wp t Q2.
Proof using.
  introv M. applys (>> wp_ramified_trans t (wp t Q1) Q1 Q2).
  xsimpl. applys M.
Qed.

(* 练习（2 星，标准，必做）：wp_frame 也可由 wp_ramified 导出。 *)

Lemma wp_frame_of_wp_ramified : forall t H Q,
  (wp t Q) \* H ==> wp t (Q \*+ H).
Proof using.
  intros.
  asserts W: (H ==> (Q \--* (Q \*+ H))).
  { applys himpl_qwand_r. applys qimpl_refl. }
  xchange W. applys wp_ramified.
Qed.

(* ---------- 100.3 构件规则的 wp 版 ---------- *)

(* 值：拿着 Q v 就等于拿着"求值 v 产出 Q"。 *)

Lemma wp_val : forall v Q,
  Q v ==> wp (trm_val v) Q.
Proof using. unfold wp. intros. intros h K. applys* eval_val. Qed.

(* 序列：先产出"能接着跑 t2"的状态，就是能跑整个序列。 *)

Lemma wp_seq : forall t1 t2 Q,
  wp t1 (fun v => wp t2 Q) ==> wp (trm_seq t1 t2) Q.
Proof using. unfold wp. intros. intros h K. applys* eval_seq. Qed.

Lemma wp_let : forall x t1 t2 Q,
  wp t1 (fun v1 => wp (subst x v1 t2) Q) ==> wp (trm_let x t1 t2) Q.
Proof using. unfold wp. intros. intros h K. applys* eval_let. Qed.

Lemma wp_fun : forall x t Q,
  Q (val_fun x t) ==> wp (trm_fun x t) Q.
Proof using. unfold wp. intros. intros h K. applys* eval_fun. Qed.

Lemma wp_fix : forall f x t Q,
  Q (val_fix f x t) ==> wp (trm_fix f x t) Q.
Proof using. unfold wp. intros. intros h K. applys* eval_fix. Qed.

Lemma wp_if : forall b t1 t2 Q,
  wp (if b then t1 else t2) Q ==> wp (trm_if (val_bool b) t1 t2) Q.
Proof using. unfold wp. intros. intros h K. applys* eval_if. Qed.

(* 练习（1 星，标准，选做）：if 也可套在两个 wp 外面。 *)

Lemma wp_if' : forall b t1 t2 Q,
  (if b then (wp t1 Q) else (wp t2 Q)) ==> wp (trm_if b t1 t2) Q.
Proof using. intros. destruct b.
  { applys wp_if true. }
  { applys wp_if false. }
Qed.

Lemma wp_app_fun : forall x v1 v2 t1 Q,
  v1 = val_fun x t1 ->
  wp (subst x v2 t1) Q ==> wp (trm_app v1 v2) Q.
Proof using. unfold wp. intros. intros h K. applys* eval_app_fun. Qed.

Lemma wp_app_fix : forall f x v1 v2 t1 Q,
  v1 = val_fix f x t1 ->
  wp (subst x v2 (subst f v1 t1)) Q ==> wp (trm_app v1 v2) Q.
Proof using. unfold wp. intros. intros h K. applys* eval_app_fix. Qed.

(* ---------- 100.4 wp 的其他定义与唯一性 ---------- *)

(* 定义一：wp_1 用 triple 定义——"任何"合法前条件 H 的存在性刻画。 *)

Module WpFromTriple.

Definition wp_1 (t:trm) (Q:val->hprop) : hprop :=
  \exists (H:hprop), H \* \[triple t H Q].

(* 练习（3 星，标准，必做）：wp_1 也满足特征等价。
   → 方向拆出见证 H0，其纯事实说明 H0 是合法前条件，
   而 \[...] 的堆为空表明原堆就是 H0 的堆。 *)

Lemma wp_equiv_1 : forall t H Q,
  (H ==> wp_1 t Q) <-> (triple t H Q).
Proof using.
  intros. iff M.
  { intros s Hs. lets (H0&h0&h1&K0&K1&D&U): M s Hs.
    lets (Ktriple&E1): hpure_inv (rm K1). subst h1.
    rewrite Fmap.union_empty_r in U. subst s.
    applys Ktriple h0 K0. }
  { intros h Hh. exists H. rewrite hstar_comm, hstar_hpure_l. splits*. }
Qed.

End WpFromTriple.

(* 定义二：wp_2 直接以堆为参数——"恰在此堆上执行 t 产出 Q"。 *)

Module WpFromTriple2.

Definition wp_2 (t:trm) (Q:val->hprop) : hprop :=
  fun (h:heap) => triple t (fun h' => (h' = h)) Q.

(* 练习（4 星，标准，选做）：wp_2 也满足特征等价。
   用 97 章练习 triple_named_heap（给堆命名的规则）。 *)

Lemma wp_equiv_2 : forall t H Q,
  (H ==> wp_2 t Q) <-> (triple t H Q).
Proof using.
  intros. iff M.
  { applys triple_named_heap. intros h Hh. applys M h Hh. }
  { intros h Hh. applys triple_conseq M.
    { intros h' E. subst h'. auto. }
    { applys qimpl_refl. } }
Qed.

End WpFromTriple2.

(* 特征等价唯一确定 wp：任何两个满足它的算子相等。 *)

Lemma wp_unique : forall wp1 wp2,
  (forall t H Q, (triple t H Q) <-> (H ==> wp1 t Q)) ->
  (forall t H Q, (triple t H Q) <-> (H ==> wp2 t Q)) ->
  wp1 = wp2.
Proof using.
  introv M1 M2. applys fun_ext_2. intros t Q. applys himpl_antisym.
  { rewrite <- M2. rewrite M1. auto. }
  { rewrite <- M1. rewrite M2. auto. }
Qed.

(* 练习（2 星，标准，必做）："合法前条件 + 最弱性" 与特征等价等价。 *)

Lemma wp_equiv_iff_wp_pre_and_wp_weakest : forall wp',
  (   (forall t Q, triple t (wp' t Q) Q) (* [wp_pre] *)
   /\ (forall t H Q, triple t H Q -> H ==> wp' t Q)) (* [wp_weakest] *)
  <->
  (forall t H Q, H ==> wp' t Q <-> triple t H Q). (* [wp_equiv] *)
Proof using.
  intros. iff M.
  { destruct M as (M1&M2). intros t H Q. iff E.
    { applys triple_conseq (M1 t Q). { applys E. } { applys qimpl_refl. } }
    { applys M2 E. } }
  { split.
    { intros t Q. applys (proj1 (M t (wp' t Q) Q)). applys himpl_refl. }
    { introv K. applys (proj2 (M t H Q)). applys K. } }
Qed.

(* ---------- 100.5 Texan 三元组：用 wp 写函数规格 ---------- *)

Module TexanTriples.

(* 以 ref 为例：三元组规格逐步改写成 wp 风格（前条件留空位）。 *)

Parameter triple_ref : forall v,
  triple (val_ref v)
    \[]
    (funloc p => p ~~> v).

Lemma wp_ref_0 : forall v,
  \[] ==> wp (val_ref v) (funloc p => p ~~> v).
Proof using. intros. rewrite wp_equiv. applys triple_ref. Qed.

(* 给定抽象后条件 Q，用杖把具体后条件换成 Q： *)

Lemma wp_ref_1 : forall Q v,
  ((funloc p => p ~~> v) \--* Q) ==> wp (val_ref v) Q.
Proof using. intros. xchange (wp_ref_0 v). applys wp_ramified. Qed.

(* 展开 qwand，对结果值 r 显式量化： *)

Lemma wp_ref_2 : forall Q v,
  (\forall r,     (\exists p, \[r = val_loc p] \* p ~~> v) \-* Q r)
              ==> wp (val_ref v) Q.
Proof using. intros. applys himpl_trans wp_ref_1. xsimpl. Qed.

(* r 恰为 val_loc p，代入后得到最终的 Texan 风格规格： *)

Lemma wp_ref_3 : forall Q v,
  (\forall p, (p ~~> v) \-* Q (val_loc p)) ==> wp (val_ref v) Q.
Proof using.
  intros. applys himpl_trans_r wp_ref_2. xsimpl. intros ? p ->.
  xchange (hforall_specialize p).
Qed.

(* 一般模式：triple t H (fun r => \exists x, \[r = vof x] \* Hof r x)
   等价于 Texan 三元组 forall Q, H \* (\forall x, Hof (vof x) x \-* Q (vof x)) ==> wp t Q。 *)

Lemma texan_triple_equiv : forall t H A (Hof:val->A->hprop) (vof:A->val),
      (triple t H (fun r => \exists x, \[r = vof x] \* Hof r x))
  <-> (forall Q, H \* (\forall x, Hof (vof x) x \-* Q (vof x)) ==> wp t Q).
Proof using.
  intros. rewrite <- wp_equiv. iff M.
  { intros Q. xchange M. applys wp_ramified_trans.
    xsimpl. intros r x ->.
    xchange (hforall_specialize x). }
  { applys himpl_trans_r M. xsimpl~. }
Qed.

(* get/set/free 的 wp 规格： *)

Section WpSpecRef.

Lemma wp_get : forall v p Q,
  (p ~~> v) \* (p ~~> v \-* Q v) ==> wp (val_get p) Q.
Proof using.
  intros. rewrite wp_equiv. applys triple_conseq_frame.
  { applys triple_get. } { applys himpl_refl. } { xsimpl. intros ? ->. auto. }
Qed.

Lemma wp_set : forall v w p Q,
  (p ~~> v) \* (\forall r, p ~~> w \-* Q r) ==> wp (val_set p w) Q.
Proof using.
  intros. rewrite wp_equiv. applys triple_conseq_frame.
  { applys triple_set. } { applys himpl_refl. }
  { intros r. xchange (hforall_specialize r). xsimpl. }
Qed.

Lemma wp_free : forall v p Q,
  (p ~~> v) \* (\forall r, Q r) ==> wp (val_free p) Q.
Proof using.
  intros. rewrite wp_equiv. applys triple_conseq_frame.
  { applys triple_free. } { applys himpl_refl. }
  { intros r. xchange (hforall_specialize r). }
Qed.

(* 也可声明返回值为 unit： *)

Parameter triple_set' : forall w p v,
  triple (val_set p w)
    (p ~~> v)
    (fun r => \[r = val_unit] \* p ~~> w).

Lemma wp_set' : forall v w p Q,
  (p ~~> v) \* (p ~~> w \-* Q val_unit) ==> wp (val_set p w) Q.
Proof using.
  intros. rewrite wp_equiv. applys triple_conseq_frame.
  { applys triple_set'. }
  { applys himpl_refl. }
  { xsimpl. intros ? ->. auto. }
Qed.

Parameter triple_free' : forall p v,
  triple (val_free p)
    (p ~~> v)
    (fun r => \[r = val_unit]).

Lemma wp_free' : forall v w p Q,
  (p ~~> v) \* (Q val_unit) ==> wp (val_free p) Q.
Proof using.
  intros. rewrite wp_equiv. applys triple_conseq_frame.
  { applys triple_free'. }
  { applys himpl_refl. }
  { xsimpl. intros ? ->. auto. }
Qed.

End WpSpecRef.

(* 练习（3 星，标准，必做）：为 incr 陈述并证明 Texan 三元组。 *)

Parameter incr : val.

Parameter triple_incr : forall (p:loc) (n:int),
  triple (incr p)
    (p ~~> n)
    (fun v => \[v = val_unit] \* (p ~~> (n+1))).

Lemma wp_incr : forall (p:loc) (n:int) Q,
  (p ~~> n) \* (p ~~> (n+1) \-* Q val_unit) ==> wp (incr p) Q.
Proof using.
  intros. rewrite wp_equiv. applys triple_conseq_frame.
  { applys triple_incr. }
  { applys himpl_refl. }
  { xsimpl. intros ? ->. auto. }
Qed.

End TexanTriples.

(* ---------- 100.6 小结 ----------
   1) wp t Q = fun s => eval s t Q；H ==> wp t Q 与 triple t H Q 互相等价，
      wp 既是合法前条件又是最弱前条件，且被特征等价唯一确定；
   2) 结构规则在 wp 下大幅坍缩：后果=对 Q 协变、框架=一条蕴含，
      抽取规则退化为蕴含的抽取规则，分支框架规则一条全覆盖；
   3) 构件规则的 wp 版全是 eval 构件规则的一行镜像；
   4) Texan 三元组把函数规格写成 H \* (\forall x, H' \-* Q v) ==> wp t Q，
      简化 xapp 实现但可读性略降。 *)
