(* 102 wpgen 的可靠性：结构公式、语法分支、替换性质与主归纳 *)
(* 取材 Software Foundations 卷六 Separation Logic Foundations 的 WPsound 章。 *)

Set Implicit Arguments.
From SLF Require Import LibSepReference.

Implicit Types f : var.
Implicit Types b : bool.
Implicit Types v : val.
Implicit Types h : heap.
Implicit Types P : Prop.
Implicit Types H : hprop.
Implicit Types Q : val->hprop.

Module WPsound.

Open Scope liblist_scope.

Implicit Types E : ctx.

(* ---------- 102.1 多重替换的技术引理 ---------- *)

Module IsubstProp.

(* 空上下文不改变项；对项作结构归纳后，fequals 处理所有递归子项。 *)

Lemma isubst_nil : forall t,
  isubst nil t = t.
Proof using.
  intros t. induction t; simpl; fequals.
Qed.

(* 单次 subst 就是只含一个绑定的 isubst。函数、递归函数与 let
   的分支需要 case_var 分析绑定变量是否遮蔽本次替换。 *)

Lemma subst_eq_isubst_one : forall x v t,
  subst x v t = isubst ((x,v)::nil) t.
Proof using.
  intros. induction t; simpl.
  { fequals. }
  { case_var*. }
  { fequals. case_var*. { rewrite* isubst_nil. } }
  { fequals. case_var; try case_var; simpl; try case_var;
              try rewrite isubst_nil; auto. }
  { fequals*. }
  { fequals*. }
  { fequals*. case_var*. { rewrite* isubst_nil. } }
  { fequals*. }
Qed.

(* 从上下文删去 y 后，查找 x 的结果由 x 与 y 是否相等决定。 *)

Lemma lookup_rem : forall x y E,
  lookup x (rem y E) = if var_eq x y then None else lookup x E.
Proof using.
  intros. induction E as [|(z,v) E'].
  { simpl. case_var*. }
  { simpl. case_var*; simpl; case_var*. }
Qed.

(* rem 与上下文拼接交换。 *)

Lemma rem_app : forall x E1 E2,
  rem x (E1 ++ E2) = rem x E1 ++ rem x E2.
Proof using.
  intros. induction E1 as [|(y,w) E1']; rew_list; simpl. { auto. }
  { case_var*. { rew_list. fequals. } }
Qed.

(* 两个上下文等价，指每个变量在二者中的查找结果都相同。 *)

Definition ctx_equiv E1 E2 :=
  forall x, lookup x E1 = lookup x E2.

Lemma ctx_equiv_rem : forall x E1 E2,
  ctx_equiv E1 E2 ->
  ctx_equiv (rem x E1) (rem x E2).
Proof using.
  introv M. unfolds ctx_equiv. intros y.
  do 2 rewrite lookup_rem. case_var*.
Qed.

(* isubst 只通过 lookup 读取上下文，因此等价上下文给出相同结果。 *)

Lemma isubst_ctx_equiv : forall t E1 E2,
  ctx_equiv E1 E2 ->
  isubst E1 t = isubst E2 t.
Proof using.
  hint ctx_equiv_rem.
  intros t. induction t; introv EQ; simpl; fequals*.
  { rewrite EQ. auto. }
Qed.

(* 定义域不相交：不存在一个变量能在两个上下文中同时查找成功。 *)

Definition ctx_disjoint E1 E2 :=
  forall x v1 v2, lookup x E1 = Some v1 -> lookup x E2 = Some v2 -> False.

Lemma ctx_disjoint_rem : forall x E1 E2,
  ctx_disjoint E1 E2 ->
  ctx_disjoint (rem x E1) (rem x E2).
Proof using.
  introv D. intros y v1 v2 K1 K2. rewrite lookup_rem in *.
  case_var. applys* D K1 K2.
Qed.

(* 拼接上下文的查找优先使用左侧绑定。 *)

Lemma lookup_app : forall x E1 E2,
  lookup x (E1 ++ E2) = match lookup x E1 with
                        | None => lookup x E2
                        | Some v => Some v
                        end.
Proof using.
  introv. induction E1 as [|(y,w) E1']; rew_list; simpl; intros.
  { auto. }
  { case_var*. }
Qed.

(* 拼接上下文对应依次替换；注意 isubst 从列表头部开始处理，
   所以等式右侧先执行 E1，再执行 E2。 *)

Lemma isubst_app : forall t E1 E2,
  isubst (E1 ++ E2) t = isubst E2 (isubst E1 t).
Proof using.
  hint ctx_disjoint_rem.
  intros t. induction t; simpl; intros.
  { fequals. }
  { rename v into x. rewrite* lookup_app.
    case_eq (lookup x E1); introv K1; case_eq (lookup x E2); introv K2; auto.
    { simpl. rewrite* K2. }
    { simpl. rewrite* K2. } }
  { fequals. rewrite* rem_app. }
  { fequals. do 2 rewrite* rem_app. }
  { fequals*. }
  { fequals*. }
  { fequals*. { rewrite* rem_app. } }
  { fequals*. }
Qed.

(* 若定义域不相交，拼接顺序不影响替换结果。 *)

Lemma isubst_app_swap : forall t E1 E2,
  ctx_disjoint E1 E2 ->
  isubst (E1 ++ E2) t = isubst (E2 ++ E1) t.
Proof using.
  introv D. applys isubst_ctx_equiv. applys* ctx_disjoint_equiv_app.
Qed.

(* let 分支所需的关键等式：先删除旧绑定再添加新绑定，
   等价于先对删除旧绑定的上下文做多重替换，再做一次普通替换。 *)

Lemma isubst_rem : forall x v E t,
  isubst ((x, v)::E) t = subst x v (isubst (rem x E) t).
Proof using.
  intros. rewrite subst_eq_isubst_one. rewrite <- isubst_app.
  rewrite isubst_app_swap.
  { applys isubst_ctx_equiv. intros y. rew_list. simpl. case_var*.
    { rewrite lookup_rem. case_var*. } }
  { intros y v1 v2 K1 K2. simpls. case_var.
    { subst. rewrite lookup_rem in K1. case_var*. } }
Qed.

(* 递归函数分支需要同时处理函数名 f 与参数名 x。 *)

Lemma isubst_rem_2 : forall f x vf vx E t,
    isubst ((f,vf)::(x,vx)::E) t
  = subst x vx (subst f vf (isubst (rem x (rem f E)) t)).
Proof using.
  intros. do 2 rewrite subst_eq_isubst_one. do 2 rewrite <- isubst_app.
  rewrite isubst_app_swap.
  { applys isubst_ctx_equiv. intros y. rew_list. simpl.
    do 2 rewrite lookup_rem. case_var*. }
  { intros y v1 v2 K1 K2. rew_listx in *. simpls.
    do 2 rewrite lookup_rem in K1. case_var. }
Qed.

End IsubstProp.

Import IsubstProp.

(* ---------- 102.2 公式可靠性的谓词 ---------- *)

(* F 是项 t 的可靠公式，当且仅当对任意后条件 Q，
   F Q 都蕴含语义最弱前条件 wp t Q。 *)

Definition formula_sound (t:trm) (F:formula) : Prop :=
  forall Q, F Q ==> wp t Q.

(* 序列分支把两个归纳假设接在 wp_seq 前面：
   先用 S1 处理第一段，再用 wp_conseq 与 S2 处理第二段。 *)

Lemma wpgen_seq_sound : forall t1' t2' F1 F2,
  formula_sound t1' F1 ->
  formula_sound t2' F2 ->
  formula_sound (trm_seq t1' t2') (wpgen_seq F1 F2).
Proof using.
  introv S1 S2. unfolds formula_sound. intros Q. unfolds wpgen_seq.
  applys himpl_trans.
  2:{ applys wp_seq. }
  { applys himpl_trans.
    { applys S1. }
    { applys wp_conseq. intros v. applys S2. } }
Qed.

(* 值、let、条件、应用与失败公式分别对应一个 wp 规则。 *)

Lemma wpgen_val_sound : forall v,
  formula_sound (trm_val v) (wpgen_val v).
Proof using. intros. intros Q. unfolds wpgen_val. applys wp_val. Qed.

Lemma wpgen_let_sound : forall F1 F2of x t1 t2,
  formula_sound t1 F1 ->
  (forall v, formula_sound (subst x v t2) (F2of v)) ->
  formula_sound (trm_let x t1 t2) (wpgen_let F1 F2of).
Proof using.
  introv S1 S2. intros Q. unfolds wpgen_let. applys himpl_trans_r wp_let.
  applys himpl_trans S1. applys wp_conseq. intros v. applys S2.
Qed.

Lemma wpgen_if_sound : forall F1 F2 t0 t1 t2,
  formula_sound t1 F1 ->
  formula_sound t2 F2 ->
  formula_sound (trm_if t0 t1 t2) (wpgen_if t0 F1 F2).
Proof using.
  introv S1 S2. intros Q. unfold wpgen_if. xpull. intros b ->.
  applys himpl_trans_r wp_if. case_if. { applys S1. } { applys S2. }
Qed.

Lemma wpgen_app_sound : forall t,
  formula_sound t (wpgen_app t).
Proof using.
  intros t Q. unfold wpgen_app. xpull. intros H M. rewrite wp_equiv. apply M.
Qed.

Lemma wpgen_fail_sound : forall t,
  formula_sound t wpgen_fail.
Proof using. intros. intros Q. unfold wpgen_fail. xpull. Qed.

(* 函数公式包含一个对任意调用的规格。把全称量词实例化为当前闭包，
   再消去纯事实魔法杖，就分别得到 wp_app_fun 与 wp_app_fix 所需前提。 *)

Lemma wpgen_fun_sound : forall x t1 Fof,
  (forall vx, formula_sound (subst x vx t1) (Fof vx)) ->
  formula_sound (trm_fun x t1) (wpgen_fun Fof).
Proof using.
  introv M. intros Q. unfolds wpgen_fun. applys himpl_hforall_l (val_fun x t1).
  xchange hwand_hpure_l.
  { intros. applys himpl_trans_r. { applys* wp_app_fun. } { applys* M. } }
  { applys wp_fun. }
Qed.

Lemma wpgen_fix_sound : forall f x t1 Fof,
  (forall vf vx, formula_sound (subst x vx (subst f vf t1)) (Fof vf vx)) ->
  formula_sound (trm_fix f x t1) (wpgen_fix Fof).
Proof using.
  introv M. intros Q. unfolds wpgen_fix.
  applys himpl_hforall_l (val_fix f x t1). xchange hwand_hpure_l.
  { intros. applys himpl_trans_r. { applys* wp_app_fix. } { applys* M. } }
  { applys wp_fix. }
Qed.

(* 第 101 章的教学版生成器不递归进入函数体；此时闭包直接按值处理。 *)

Lemma wpgen_fun_val_sound : forall x t,
  formula_sound (trm_fun x t) (wpgen_val (val_fun x t)).
Proof using. intros. intros Q. unfolds wpgen_val. applys wp_fun. Qed.

Lemma wpgen_fix_val_sound : forall f x t,
  formula_sound (trm_fix f x t) (wpgen_val (val_fix f x t)).
Proof using. intros. intros Q. unfolds wpgen_val. applys wp_fix. Qed.

(* ---------- 102.3 mkstruct 保持可靠性 ---------- *)

(* wp 本身已吸收框架与后果规则，所以外面再包一层 mkstruct 不改变它。 *)

Lemma mkstruct_wp : forall t,
  mkstruct (wp t) = (wp t).
Proof using.
  intros. applys fun_ext_1. intros Q. applys himpl_antisym.
  { unfold mkstruct. xpull. intros H Q' M. applys wp_conseq_frame M. xsimpl. }
  { applys mkstruct_erase. }
Qed.

Lemma mkstruct_sound : forall t F,
  formula_sound t F ->
  formula_sound t (mkstruct F).
Proof using.
  introv M. unfolds formula_sound. intros Q.
  rewrite <- mkstruct_wp. applys mkstruct_monotone. applys M.
Qed.

(* 同一结果的底层证明：展开 mkstruct，再直接使用 wp 的分支框架规则。 *)

Lemma mkstruct_sound' : forall t F,
  formula_sound t F ->
  formula_sound t (mkstruct F).
Proof using.
  introv M. unfolds formula_sound. intros Q. unfolds mkstruct.
  xsimpl. intros Q'. xchange (M Q'). applys wp_ramified.
Qed.

(* 原书练习（3 星）：mkstruct 幂等。左到右把两层存在量词展开，
   xsimpl 合并两段后条件魔法杖；右到左就是 mkstruct_erase。 *)

Lemma mkstruct_idempotent : forall F,
  mkstruct (mkstruct F) = mkstruct F.
Proof using.
  intros. apply fun_ext_1. intros Q. applys himpl_antisym.
  { unfold mkstruct. xpull. intros Q1 Q2. xsimpl. }
  { applys mkstruct_erase. }
Qed.

(* ---------- 102.4 对项作结构归纳的主可靠性定理 ---------- *)

Lemma wpgen_sound_induct : forall E t,
  formula_sound (isubst E t) (wpgen E t).
Proof using.
  intros. gen E. induction t; intros; simpl; applys mkstruct_sound.
  { applys wpgen_val_sound. }
  { rename v into x. unfold wpgen_var. case_eq (lookup x E).
    { intros v EQ. applys wpgen_val_sound. }
    { intros N. applys wpgen_fail_sound. } }
  { applys wpgen_fun_sound.
    { intros vx. rewrite <- isubst_rem. applys IHt. } }
  { introv IH. applys wpgen_fix_sound IH.
    { intros vf vx. rewrite <- isubst_rem_2. applys IHt. } }
  { applys wpgen_app_sound. }
  { applys wpgen_seq_sound. { applys IHt1. } { applys IHt2. } }
  { rename v into x. applys wpgen_let_sound.
    { applys IHt1. }
    { intros v. rewrite <- isubst_rem. applys IHt2. } }
  { applys wpgen_if_sound. { applys IHt2. } { applys IHt3. } }
Qed.

(* ---------- 102.5 闭项与函数调用的推论 ---------- *)

Lemma wpgen_sound : forall t Q,
  wpgen nil t Q ==> wp t Q.
Proof using.
  intros t Q. lets N: (wpgen_sound_induct nil t).
  rewrite isubst_nil in N. applys N.
Qed.

Lemma triple_of_wpgen : forall t H Q,
  H ==> wpgen nil t Q ->
  triple t H Q.
Proof using.
  introv M. rewrite <- wp_equiv. xchange M. applys wpgen_sound.
Qed.

(* xwp 的核心引理：函数调用规则把目标化为函数体的 triple，
   wp_equiv 与可靠性定理再把它化为生成公式的蕴含。 *)

Lemma triple_app_fun_from_wpgen : forall v1 v2 x t1 H Q,
  v1 = val_fun x t1 ->
  H ==> wpgen ((x,v2)::nil) t1 Q ->
  triple (trm_app v1 v2) H Q.
Proof using.
  introv M1 M2. applys triple_app_fun M1.
  asserts_rewrite (subst x v2 t1 = isubst ((x,v2)::nil) t1).
  { rewrite isubst_rem. rewrite* isubst_nil. }
  rewrite <- wp_equiv. xchange M2. applys wpgen_sound_induct.
Qed.

Lemma triple_app_fix_from_wpgen : forall v1 v2 f x t1 H Q,
  v1 = val_fix f x t1 ->
  H ==> wpgen ((f,v1)::(x,v2)::nil) t1 Q ->
  triple (trm_app v1 v2) H Q.
Proof using.
  introv M1 M2. applys triple_app_fix M1.
  asserts_rewrite (subst x v2 (subst f v1 t1)
                 = isubst ((f,v1)::(x,v2)::nil) t1).
  { rewrite isubst_rem_2. rewrite* isubst_nil. }
  rewrite <- wp_equiv. xchange M2. applys wpgen_sound_induct.
Qed.

End WPsound.
