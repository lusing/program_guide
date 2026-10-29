(* 101 最弱前条件生成器：延迟替换、特征公式、结构规则与 x-tactics *)
(* 取材 Software Foundations 卷六 Separation Logic Foundations 的 WPgen 章。 *)

Set Implicit Arguments.
From SLF Require Import LibSepReference.
Import ProgramSyntax DemoPrograms.

Implicit Types n m i a b : int.
Implicit Types p : loc.
Implicit Types v : val.
Implicit Types H : hprop.
Implicit Types Q : val->hprop.

(* ---------- 101.1 不带 mkstruct 的可执行生成器 ---------- *)

Module SimpleGenerator.

(* wpgen E t Q 表示 isubst E t 的一个充分前条件。let 不立即做 subst，
   而把绑定加入 E；变量、应用与闭包在叶结点读取或应用整个 E。 *)

Fixpoint wpgen (E:ctx) (t:trm) (Q:val->hprop) : hprop :=
  match t with
  | trm_val v => Q v
  | trm_fun x t1 => Q (val_fun x (isubst (rem x E) t1))
  | trm_fix f x t1 => Q (val_fix f x (isubst (rem x (rem f E)) t1))
  | trm_seq t1 t2 => wpgen E t1 (fun v => wpgen E t2 Q)
  | trm_let x t1 t2 => wpgen E t1 (fun v => wpgen ((x,v)::E) t2 Q)
  | trm_var x =>
       match lookup x E with
       | Some v => Q v
       | None => \[False]
       end
  | trm_app v1 v2 => \exists H, H \* \[triple (isubst E t) H Q]
  | trm_if t0 t1 t2 =>
      \exists (b:bool), \[t0 = trm_val (val_bool b)]
        \* (if b then (wpgen E t1) Q else (wpgen E t2) Q)
  end.

(* 练习（3 星）：生成公式对后条件满足后果规则。应用叶结点把归纳
   转化为 triple_conseq；序列和 let 则把两段归纳假设接起来。 *)

Lemma wpgen_conseq : forall t E Q1 Q2,
  Q1 ===> Q2 ->
  wpgen E t Q1 ==> wpgen E t Q2.
Proof using.
  intros t. induction t; intros E Q1 Q2 WQ; simpl.
  { applys WQ. }
  { destruct (lookup v E).
    { applys WQ. }
    { xsimpl. } }
  { applys WQ. }
  { applys WQ. }
  { xpull. intros H M. xsimpl. applys triple_conseq M WQ. xsimpl. }
  { applys IHt1. intros r. applys IHt2. applys WQ. }
  { applys IHt1. intros r. applys IHt2. applys WQ. }
  { xpull. intros b Eb. xsimpl b. { auto. }
    case_if.
    { applys IHt2. applys WQ. }
    { applys IHt3. applys WQ. } }
Qed.

(* 练习（4 星）：生成公式满足框架规则。序列与 let 的关键是
   先对第一段使用框架归纳假设，再用 wpgen_conseq 调整后条件。 *)

Lemma wpgen_frame : forall t E H Q,
  (wpgen E t Q) \* H ==> wpgen E t (Q \*+ H).
Proof using.
  intros t. induction t; intros E H Q; simpl.
  { xsimpl. }
  { destruct (lookup v E); xsimpl. }
  { xsimpl. }
  { xsimpl. }
  { xpull. intros H1 M. xsimpl (H1 \* H). applys triple_frame M. }
  { applys himpl_trans (IHt1 E H (fun v => wpgen E t2 Q)).
    applys wpgen_conseq. intros r. applys IHt2. }
  { applys himpl_trans (IHt1 E H (fun r => wpgen ((v,r)::E) t2 Q)).
    applys wpgen_conseq. intros r. applys IHt2. }
  { xpull. intros b Eb. xsimpl b. { auto. } case_if.
    { applys IHt2. }
    { applys IHt3. } }
Qed.

End SimpleGenerator.

(* ---------- 101.2 带 mkstruct、但不递归进入函数体的生成器 ---------- *)

Module NonRecursive.

(* mkstruct F Q = exists Q1, F Q1 * (Q1 --* Q)。它把框架与后果规则
   打包进公式；以下四个性质只使用分离蕴含与魔法杖即可证明。 *)

Lemma mkstruct_frame' : forall F H Q,
  (mkstruct F Q) \* H ==> mkstruct F (Q \*+ H).
Proof using. intros. unfold mkstruct. xpull. intros Q'. xsimpl*. Qed.

Lemma mkstruct_conseq' : forall F Q1 Q2,
  Q1 ===> Q2 ->
  mkstruct F Q1 ==> mkstruct F Q2.
Proof using. introv WQ. unfold mkstruct. xpull. intros Q'. xsimpl*. Qed.

Lemma mkstruct_erase' : forall F Q,
  F Q ==> mkstruct F Q.
Proof using. intros. unfold mkstruct. xsimpl. Qed.

Lemma mkstruct_monotone' : forall F1 F2 Q,
  (forall Q, F1 Q ==> F2 Q) ->
  mkstruct F1 Q ==> mkstruct F2 Q.
Proof using. introv WF. unfolds mkstruct. xpull. intros Q'. xchanges WF. Qed.

Fixpoint wpgen (E:ctx) (t:trm) : formula :=
  mkstruct (match t with
  | trm_val v => wpgen_val v
  | trm_var x => wpgen_var E x
  | trm_fun x t1 => wpgen_val (val_fun x (isubst (rem x E) t1))
  | trm_fix f x t1 => wpgen_val (val_fix f x (isubst (rem x (rem f E)) t1))
  | trm_app t1 t2 => wpgen_app (isubst E t)
  | trm_seq t1 t2 => wpgen_seq (wpgen E t1) (wpgen E t2)
  | trm_let x t1 t2 => wpgen_let (wpgen E t1) (fun v => wpgen ((x,v)::E) t2)
  | trm_if t0 t1 t2 => wpgen_if (isubst E t0) (wpgen E t1) (wpgen E t2)
  end).

(* 本章不把可靠性留作公理。复用库中各叶结点的可靠性引理，
   对这个教学版生成器作结构归纳，即得完整证明。
   函数定义分支把闭包当作值处理，需要下面两条专属引理：
   它们只是 wp_fun / wp_fix 换了个包装。 *)

Lemma wpgen_fun_val_sound : forall x t1,
  formula_sound (trm_fun x t1) (wpgen_val (val_fun x t1)).
Proof using. intros. intros Q. unfolds wpgen_val. applys wp_fun. Qed.

Lemma wpgen_fix_val_sound : forall f x t1,
  formula_sound (trm_fix f x t1) (wpgen_val (val_fix f x t1)).
Proof using. intros. intros Q. unfolds wpgen_val. applys wp_fix. Qed.

Lemma wpgen_sound_induct : forall E t,
  formula_sound (isubst E t) (wpgen E t).
Proof using.
  intros. gen E. induction t; intros; simpl; applys mkstruct_sound.
  { applys wpgen_val_sound. }
  { rename v into x. unfold wpgen_var. case_eq (lookup x E).
    { intros v EQ. applys wpgen_val_sound. }
    { intros N. applys wpgen_fail_sound. } }
  { applys wpgen_fun_val_sound. }
  { applys wpgen_fix_val_sound. }
  { applys wpgen_app_sound. }
  { applys wpgen_seq_sound. { applys IHt1. } { applys IHt2. } }
  { rename v into x. applys wpgen_let_sound.
    { applys IHt1. }
    { intros v. rewrite <- isubst_rem. applys IHt2. } }
  { applys wpgen_if_sound. { applys IHt2. } { applys IHt3. } }
Qed.

Lemma triple_app_fun_from_wpgen : forall v1 v2 x t1 H Q,
  v1 = val_fun x t1 ->
  H ==> wpgen ((x,v2)::nil) t1 Q ->
  triple (trm_app v1 v2) H Q.
Proof using.
  introv M1 M2. applys triple_app_fun M1.
  rewrite subst_eq_isubst_one. rewrite <- wp_equiv.
  xchange M2. applys wpgen_sound_induct.
Qed.

(* 每条 x-lemma 消去公式的一层语法外壳。这里的 xapp_lemma 采用
   三分支形式，便于看清规格、前条件划分和后条件拼接。 *)

Lemma xstruct_lemma' : forall F H Q,
  H ==> F Q ->
  H ==> mkstruct F Q.
Proof using. introv M. xchange M. applys mkstruct_erase. Qed.

Lemma xval_lemma' : forall v H Q,
  H ==> Q v ->
  H ==> wpgen_val v Q.
Proof using. introv M. applys M. Qed.

Lemma xlet_lemma' : forall H F1 F2of Q,
  H ==> F1 (fun v => F2of v Q) ->
  H ==> wpgen_let F1 F2of Q.
Proof using. introv M. xchange M. Qed.

Lemma xseq_lemma' : forall H F1 F2 Q,
  H ==> F1 (fun v => F2 Q) ->
  H ==> wpgen_seq F1 F2 Q.
Proof using. introv M. xchange M. Qed.

Lemma xapp_lemma' : forall t Q1 H1 H2 H Q,
  triple t H1 Q1 ->
  H ==> H1 \* H2 ->
  Q1 \*+ H2 ===> Q ->
  H ==> wpgen_app t Q.
Proof using.
  introv M WH WQ. unfold wpgen_app. xsimpl. applys* triple_conseq_frame M.
Qed.

Lemma xwp_lemma : forall v1 v2 x t1 H Q,
  v1 = val_fun x t1 ->
  H ==> wpgen ((x,v2)::nil) t1 Q ->
  triple (trm_app v1 v2) H Q.
Proof using. introv M1 M2. applys* triple_app_fun_from_wpgen. Qed.

Tactic Notation "xwp_nr" :=
  intros; applys xwp_lemma;
  [ first [ reflexivity | eassumption ]
  | simpl; unfold wpgen_var; simpl ].

Tactic Notation "xstruct_nr" :=
  applys xstruct_lemma'.

Tactic Notation "xstruct_nr_if_needed" :=
  try match goal with |- ?H ==> mkstruct ?F ?Q => xstruct_nr end.

Tactic Notation "xval_nr" :=
  xstruct_nr_if_needed; applys xval_lemma'.

Tactic Notation "xlet_nr" :=
  xstruct_nr_if_needed; applys xlet_lemma'.

Tactic Notation "xseq_nr" :=
  xstruct_nr_if_needed; applys xseq_lemma'.

Tactic Notation "xseq_xlet_nr_if_needed" :=
  try match goal with |- ?H ==> mkstruct ?F ?Q =>
  match F with
  | wpgen_seq ?F1 ?F2 => xseq_nr
  | wpgen_let ?F1 ?F2of => xlet_nr
  end end.

Tactic Notation "xapp_nr" constr(E) :=
  xseq_xlet_nr_if_needed; xstruct_nr_if_needed;
  applys xapp_lemma' E; [ xsimpl | xpull ].

Tactic Notation "xapp_nr" :=
  xseq_xlet_nr_if_needed; xstruct_nr_if_needed;
  applys xapp_lemma'; [ solve [ eauto with triple ] | xsimpl | xpull ].

(* incr 的完整 x-lemmas 证明：每一步对应源代码的一个构造。 *)

Lemma triple_incr_with_xlemmas : forall (p:loc) (n:int),
  triple (trm_app incr p)
    (p ~~> n)
    (fun _ => p ~~> (n+1)).
Proof using.
  intros. applys xwp_lemma. { reflexivity. }
  simpl. unfold wpgen_var. simpl.
  applys xstruct_lemma'. applys xlet_lemma'.
  applys xstruct_lemma'. applys xapp_lemma'.
  { apply triple_get. } { xsimpl. }
  xpull; intros ? ->.
  applys xstruct_lemma'. applys xlet_lemma'.
  applys xstruct_lemma'. applys xapp_lemma'.
  { apply triple_add. } { xsimpl. }
  xpull; intros ? ->.
  applys xstruct_lemma'. applys xapp_lemma'.
  { apply triple_set. } { xsimpl. }
  xsimpl.
Qed.

#[global] Hint Resolve triple_incr_with_xlemmas : triple.

Definition succ_using_incr : val :=
  <{ fun 'n =>
       let 'r = val_ref 'n in
       incr 'r;
       let 'x = ! 'r in
       val_free 'r;
       'x }>.

(* 练习（2 星）：只用 x-lemmas 验证 succ_using_incr。 *)

Lemma triple_succ_using_incr_with_xlemmas : forall (n:int),
  triple (trm_app succ_using_incr n)
    \[]
    (fun v => \[v = n+1]).
Proof using.
  intros. applys xwp_lemma. { reflexivity. }
  simpl. unfold wpgen_var. simpl.
  applys xstruct_lemma'. applys xlet_lemma'.
  applys xstruct_lemma'. applys xapp_lemma'.
  { apply triple_ref. } { xsimpl. }
  xpull; intros r p ->.
  applys xstruct_lemma'. applys xseq_lemma'.
  applys xstruct_lemma'. applys xapp_lemma'.
  { apply triple_incr_with_xlemmas. } { xsimpl. }
  xpull; intros u.
  applys xstruct_lemma'. applys xlet_lemma'.
  applys xstruct_lemma'. applys xapp_lemma'.
  { apply triple_get. } { xsimpl. }
  xpull; intros ? ->.
  applys xstruct_lemma'. applys xseq_lemma'.
  applys xstruct_lemma'. applys xapp_lemma'.
  { apply triple_free. } { xsimpl. }
  xpull; intros u'.
  applys xstruct_lemma'. applys xval_lemma'.
  xsimpl. auto.
Qed.

(* 练习（2 星）：同一证明改用 x-tactics，程序结构仍决定每步 tactic。 *)

Lemma triple_succ_using_incr_with_xtactics : forall (n:int),
  triple (trm_app succ_using_incr n)
    \[]
    (fun v => \[v = n+1]).
Proof using.
  xwp_nr.
  xapp_nr triple_ref. intros r p ->.
  xapp_nr triple_incr_with_xlemmas.
  xapp_nr triple_get. intros ? ->.
  xapp_nr triple_free.
  xval_nr. xsimpl. auto.
Qed.

(* ---------- 101.3 局部函数：内联验证与模块化验证 ---------- *)

Definition incrtwice : val :=
  <{ fun 'p =>
       let 'f = (fun_ 'u => incr 'p) in
       'f ();
       'f () }>.

(* xletval 把 let x = v1 变为 forall x, x = v1 -> ...；
   因而调用点仍可借等式展开局部函数，而不必复制其语法值。 *)

Lemma xletval_lemma : forall H v1 F2of Q,
  (forall x, x = v1 -> H ==> F2of x Q) ->
  H ==> wpgen_let (mkstruct (wpgen_val v1)) F2of Q.
Proof using.
  introv M. applys xlet_lemma'. apply xstruct_lemma'.
  apply xval_lemma'. applys* M.
Qed.

Tactic Notation "xletval" :=
  xstruct_nr_if_needed; applys xletval_lemma.

Lemma xappfun_lemma : forall t H Q,
  triple t H Q ->
  H ==> wpgen_app t Q.
Proof using. introv M. unfold wpgen_app. xsimpl*. Qed.

Tactic Notation "xappfun" :=
  xseq_xlet_nr_if_needed; xstruct_nr_if_needed;
  applys xappfun_lemma; xwp_nr.

Lemma triple_incrtwice_using_xletval : forall (p:loc) (n:int),
  triple (incrtwice p)
    (p ~~> n)
    (fun _ => p ~~> (n+2)).
Proof using.
  xwp_nr. xletval. intros f Hf.
  xappfun. xapp_nr triple_incr_with_xlemmas.
  xappfun. xapp_nr triple_incr_with_xlemmas.
  xsimpl. math.
Qed.

(* xfun 的教学版把局部函数规格 Sof 作为参数：先证 Sof v1，
   再在任意满足 Sof x 的抽象 x 下验证后续代码。 *)

Lemma xfun_lemma : forall (Sof:val->Prop) H v1 F2of Q,
  Sof v1 ->
  (forall x, Sof x -> H ==> F2of x Q) ->
  H ==> wpgen_let (mkstruct (wpgen_val v1)) F2of Q.
Proof using. introv Sf M. applys xletval_lemma. intros ? ->. applys* M. Qed.

Tactic Notation "xfun_nr" constr(Sof) :=
  xstruct_nr_if_needed; applys (@xfun_lemma Sof).

Lemma triple_incrtwice_with_xfun : forall (p:loc) (n:int),
  triple (incrtwice p)
    (p ~~> n)
    (fun _ => p ~~> (n+2)).
Proof using.
  xwp_nr.
  xfun_nr (fun (f:val) => forall (m:int),
    triple <{ f () }> (p ~~> m) (fun _ => p ~~> (m+1))).
  { xwp_nr. xapp_nr triple_incr_with_xlemmas. xsimpl. }
  intros f Sf.
  xapp_nr Sf.
  xapp_nr Sf.
  xsimpl. math.
Qed.

Definition succtwice : val :=
  <{ fun 'n =>
       let 'f = (fun_ 'm => 'm + 1) in
       let 'a = 'f 'n in
       'f 'a }>.

(* 练习（2 星）：用 xletval 与 xappfun 内联验证局部函数两次。 *)

Lemma triple_succtwice_using_xletval : forall (n:int),
  triple (succtwice n)
    \[]
    (fun r => \[r = n + 2]).
Proof using.
  xwp_nr. xletval. intros f Hf.
  xappfun. xapp_nr triple_add. intros ? ->.
  xappfun. xapp_nr triple_add. intros ? ->.
  xsimpl. math.
Qed.

(* 练习（2 星）：用 xfun 给局部函数一次规格，两个调用点复用它。 *)

Lemma triple_succtwice_using_xfun : forall (n:int),
  triple (succtwice n)
    \[]
    (fun r => \[r = n + 2]).
Proof using.
  xwp_nr.
  xfun_nr (fun (f:val) => forall (m:int),
    triple <{ f m }> \[] (fun r => \[r = m+1])).
  { xwp_nr. xapp_nr triple_add. intros ? ->. xsimpl. auto. }
  intros f Sf.
  xapp_nr Sf. intros ? ->.
  xapp_nr Sf. intros ? ->.
  xsimpl. math.
Qed.

(* ---------- 101.4 结构规则对应的 x-lemmas ---------- *)

(* 练习（1 星）：在 mkstruct 外层组合后果规则。 *)

Lemma xconseq_lemma : forall Q1 Q2 H F,
  H ==> mkstruct F Q1 ->
  Q1 ===> Q2 ->
  H ==> mkstruct F Q2.
Proof using.
  introv M WQ. xchange M. applys mkstruct_conseq. applys WQ.
Qed.

(* 练习（2 星）：先把 H 分成 H1 与 H2，在 H1 上验证，再拼回 H2。
   证明只用 mkstruct_frame 与 mkstruct_conseq，不展开其定义。 *)

Lemma xframe_lemma : forall H1 H2 H Q Q1 F,
  H ==> H1 \* H2 ->
  H1 ==> mkstruct F Q1 ->
  Q1 \*+ H2 ===> Q ->
  H ==> mkstruct F Q.
Proof using.
  introv WH M WQ. xchange WH. xchange M.
  xchange (@mkstruct_frame F H2 Q1). applys mkstruct_conseq. applys WQ.
Qed.

Tactic Notation "xframe_nr" constr(H) :=
  eapply (@xframe_lemma H); [ xsimpl | | ].

Lemma triple_incr_frame : forall (p q:loc) (n m:int),
  triple (trm_app incr p)
    (p ~~> n \* q ~~> m)
    (fun _ => (p ~~> (n+1)) \* (q ~~> m)).
Proof using.
  xwp_nr. xframe_nr (p ~~> n).
  xapp_nr triple_get. intros ? ->.
  xapp_nr triple_add. intros ? ->.
  xapp_nr triple_set. xsimpl.
Qed.

End NonRecursive.

(* ---------- 101.5 递归处理局部函数体 ---------- *)

Module RecursiveFunctions.

Implicit Types vx vf : val.

(* 递归版不再返回一个语法闭包，而是对任意 vf 提供其函数体的
   最弱前条件规格。wpgen_fun' 是更易读的三元组形式。 *)

Definition wpgen_fun' (Fof:val->formula) : formula := fun Q =>
  \forall vf, \[forall vx H' Q',
                  H' ==> Fof vx Q' ->
                  triple (trm_app vf vx) H' Q']
              \-* Q vf.

(* 练习（2 星）：wp 与 triple 的等价性允许消去 H'，
   因而 wpgen_fun 与 wpgen_fun' 定义相等。 *)

Lemma wpgen_fun_eq :
  wpgen_fun = wpgen_fun'.
Proof using.
  unfold wpgen_fun, wpgen_fun'. applys fun_ext_2.
  intros Fof Q. applys himpl_antisym.
  { applys himpl_hforall_r. intros vf. xchange (hforall_specialize vf).
    xsimpl. intros M. rewrite hwand_hpure_l. xsimpl.
    introv. rewrite wp_equiv. applys M. xsimpl. }
  { applys himpl_hforall_r. intros vf. xchange (hforall_specialize vf).
    xsimpl. intros M. rewrite hwand_hpure_l. xsimpl.
    intros vx H' Q' K. rewrite <- wp_equiv.
    applys himpl_trans K. applys M. }
Qed.

(* 库中的最终生成器在函数与递归函数分支递归处理函数体；
   上下文分别增加参数绑定，以及“自身 + 参数”两个绑定。 *)

Fixpoint wpgen_rec (E:ctx) (t:trm) : formula :=
  mkstruct match t with
  | trm_val v => wpgen_val v
  | trm_var x => wpgen_var E x
  | trm_fun x t1 => wpgen_fun (fun v => wpgen_rec ((x,v)::E) t1)
  | trm_fix f x t1 => wpgen_fix (fun vf v => wpgen_rec ((f,vf)::(x,v)::E) t1)
  | trm_app t1 t2 => wpgen_app (isubst E t)
  | trm_seq t1 t2 => wpgen_seq (wpgen_rec E t1) (wpgen_rec E t2)
  | trm_let x t1 t2 => wpgen_let (wpgen_rec E t1) (fun v => wpgen_rec ((x,v)::E) t2)
  | trm_if t0 t1 t2 => wpgen_if (isubst E t0) (wpgen_rec E t1) (wpgen_rec E t2)
  end.

Definition forloop : val :=
  <{ fun 'a 'b 'f =>
       let 'g = (fix_ 'g 'i =>
          let 'c = 'i < 'b in
          if 'c then
            'f 'i ;
            let 'j = 'i + 1 in
            'g 'j
          end) in
       'g 'a }>.

(* 练习（4 星）：对 g 使用带规格的 xfun。g i 的规格以 upto b i
   为良基度量：循环体把 I i 变为 I(i+1)，递归调用继续到 I b。 *)

Lemma triple_forloop : forall (I:int->hprop) (a b:int) (f:val),
  a <= b ->
  (forall i, a <= i <= b ->
    triple (f i)
      (I i)
      (fun u => I (i+1))) ->
  triple (forloop a b f)
    (I a)
    (fun r => I b).
Proof using.
  introv Hab Hf. xwp.
  xfun (fun (g:val) => forall i, a <= i <= b ->
    triple (g i) (I i) (fun r => I b)); intros g Hg.
  { intros i. induction_wf IH: (upto b) i. intros Hi.
    applys Hg. clear Hg.
    xapp. xif; intros C.
    { xseq. xapp Hf. { math. }
      xapp.
      asserts Sg1: (triple (g (i+1)) (I (i+1)) (fun r => I b)).
      { applys IH. math. math. }
      xapp Sg1. xsimpl. }
    { xval. math_rewrite (i = b). xsimpl. } }
  xapp Hg. math. xsimpl.
Qed.

End RecursiveFunctions.
