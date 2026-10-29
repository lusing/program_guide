(* 97 三元组：语言语法、omni-big-step 语义、triple 定义与结构规则 *)
(* 取材 Software Foundations 卷六 Separation Logic Foundations 的 Triples 章。 *)

Set Implicit Arguments.
From SLF Require Import LibSepReference.

(* ---------- 97.1 语法：值与项 ---------- *)

Module Syntax.

(* 值是闭项：单元、布尔、整数、位置、函数、递归函数与若干原语操作。 *)

Inductive val : Type :=
  | val_unit : val
  | val_bool : bool -> val
  | val_int : int -> val
  | val_loc : loc -> val
  | val_fun : var -> trm -> val
  | val_fix : var -> var -> trm -> val
  | val_ref : val
  | val_get : val
  | val_set : val
  | val_free : val
  | val_add : val
  | val_div : val
  | val_rand : val

(* 项可以含自由变量：值、变量、函数、递归函数、应用、序列、let 与条件。 *)

with trm : Type :=
  | trm_val : val -> trm
  | trm_var : var -> trm
  | trm_fun : var -> trm -> trm
  | trm_fix : var -> var -> trm -> trm
  | trm_app : trm -> trm -> trm
  | trm_seq : trm -> trm -> trm
  | trm_let : var -> trm -> trm -> trm
  | trm_if : trm -> trm -> trm -> trm.

(* ---------- 97.2 状态、替换与语法糖 ---------- *)

Definition heap : Type := fmap loc val.

Global Instance Inhab_val : Inhab val.
Proof using. apply (Inhab_of_val val_unit). Qed.

(* subst y w t 把项 t 中变量 y 的出现替换为值 w；值恒为闭项故无需下钻，
   遇到与 y 同名的绑定者则不再下钻以避免变量捕获。 *)

Fixpoint subst (y:var) (w:val) (t:trm) : trm :=
  let aux t := subst y w t in
  let if_y_eq x t1 t2 := if var_eq x y then t1 else t2 in
  match t with
  | trm_val v => trm_val v
  | trm_var x => if_y_eq x (trm_val w) t
  | trm_fun x t1 => trm_fun x (if_y_eq x t1 (aux t1))
  | trm_fix f x t1 => trm_fix f x (if_y_eq f t1 (if_y_eq x t1 (aux t1)))
  | trm_app t1 t2 => trm_app (aux t1) (aux t2)
  | trm_seq t1 t2 => trm_seq  (aux t1) (aux t2)
  | trm_let x t1 t2 => trm_let x (aux t1) (if_y_eq x t2 (aux t2))
  | trm_if t0 t1 t2 => trm_if (aux t0) (aux t1) (aux t2)
  end.

Implicit Types b : bool.
Implicit Types v r : val.
Implicit Types t : trm.

Coercion val_loc : loc >-> val.
Coercion val_bool : bool >-> val.
Coercion val_int : Z >-> val.

Coercion trm_val : val >-> trm.

Coercion trm_app : trm >-> Funclass.

End Syntax.

(* 后文回到 LibSepReference 的同名定义（与上面 Syntax 模块中的完全一致）。 *)

Implicit Types f : var.
Implicit Types b : bool.
Implicit Types p : loc.
Implicit Types n : int.
Implicit Types v w r : val.
Implicit Types t : trm.
Implicit Types h s : heap.
Implicit Types H : hprop.

(* ---------- 97.3 标准 big-step 语义 big ---------- *)

(* big s t s' v：从状态 s 出发，项 t 的一种执行终止于状态 s'、结果值 v。 *)

Inductive big : heap -> trm -> heap -> val -> Prop :=

  (* 1. 值与函数定义：值即为自身；项函数/递归函数求值为对应的闭值。 *)

  | big_val : forall s v,
      big s (trm_val v) s v
  | big_fun : forall s x t1,
      big s (trm_fun x t1) s (val_fun x t1)
  | big_fix : forall s f x t1,
      big s (trm_fix f x t1) s (val_fix f x t1)

  (* 2. 函数应用：beta 规约（递归函数把自身也代入）。 *)

  | big_app_fun : forall s1 s2 v1 v2 x t1 v,
      v1 = val_fun x t1 ->
      big s1 (subst x v2 t1) s2 v ->
      big s1 (trm_app v1 v2) s2 v
  | big_app_fix : forall s1 s2 v1 v2 f x t1 v,
      v1 = val_fix f x t1 ->
      big s1 (subst x v2 (subst f v1 t1)) s2 v ->
      big s1 (trm_app v1 v2) s2 v

  (* 3. 结构构件：序列丢弃 t1 的结果；let 把结果代入 t2。 *)

  | big_seq : forall s1 s2 s3 t1 t2 v1 v,
      big s1 t1 s2 v1 ->
      big s2 t2 s3 v ->
      big s1 (trm_seq t1 t2) s3 v
  | big_let : forall s1 s2 s3 x t1 t2 v1 r,
      big s1 t1 s2 v1 ->
      big s2 (subst x v1 t2) s3 r ->
      big s1 (trm_let x t1 t2) s3 r

  (* 4. 条件：设 A-范式，条件表达式已求值为布尔。 *)

  | big_if : forall s1 s2 b v t1 t2,
      big s1 (if b then t1 else t2) s2 v ->
      big s1 (trm_if (val_bool b) t1 t2) s2 v

  (* 5. 无状态原语：加法；部分函数除法（除零则卡死）；非确定的 rand。 *)

  | big_add : forall s n1 n2,
      big s (val_add (val_int n1) (val_int n2)) s (val_int (n1 + n2))
  | big_div : forall s n1 n2,
      n2 <> 0 ->
      big s (val_div (val_int n1) (val_int n2)) s (val_int (Z.quot n1 n2))
  | big_rand : forall s n n1,
      0 <= n1 < n ->
      big s (val_rand (val_int n)) s (val_int n1)

  (* 6. 状态原语：ref 分配新鲜单元；get/set/free 要求位置已绑定。 *)

  | big_ref : forall s v p,
      ~ Fmap.indom s p ->
      big s (val_ref v) (Fmap.update s p v) (val_loc p)
  | big_get : forall s p,
      Fmap.indom s p ->
      big s (val_get (val_loc p)) s (Fmap.read s p)
  | big_set : forall s p v,
      Fmap.indom s p ->
      big s (val_set (val_loc p) v) (Fmap.update s p v) val_unit
  | big_free : forall s p,
      Fmap.indom s p ->
      big s (val_free (val_loc p)) (Fmap.remove s p) val_unit.

(* ---------- 97.4 omni-big-step 语义 eval ---------- *)

(* eval s t Q：从 (s,t) 出发的所有执行都安全终止，且终格局满足后条件 Q。
   Q 是 (值, 状态) 对的集合（后条件的集合语义）。 *)

Implicit Types Q : val->heap->Prop.

Inductive eval : heap -> trm -> (val->heap->Prop) -> Prop :=

  (* 1. 值与函数定义。 *)

  | eval_val : forall s v Q,
      Q v s ->
      eval s (trm_val v) Q
  | eval_fun : forall s x t1 Q,
      Q (val_fun x t1) s ->
      eval s (trm_fun x t1) Q
  | eval_fix : forall s f x t1 Q,
      Q (val_fix f x t1) s ->
      eval s (trm_fix f x t1) Q

  (* 2. 函数应用：先代换再继续，后条件原样传递。 *)

  | eval_app_fun : forall s1 v1 v2 x t1 Q,
      v1 = val_fun x t1 ->
      eval s1 (subst x v2 t1) Q ->
      eval s1 (trm_app v1 v2) Q
  | eval_app_fix : forall s v1 v2 f x t1 Q,
      v1 = val_fix f x t1 ->
      eval s (subst x v2 (subst f v1 t1)) Q ->
      eval s (trm_app v1 v2) Q

  (* 3. 序列与 let：选一个中间后条件 Q1 概括第一步的全部可能结果。 *)

  | eval_seq : forall Q1 s t1 t2 Q,
      eval s t1 Q1 ->
      (forall v1 s2, Q1 v1 s2 -> eval s2 t2 Q) ->
      eval s (trm_seq t1 t2) Q
  | eval_let : forall Q1 s x t1 t2 Q,
      eval s t1 Q1 ->
      (forall v1 s2, Q1 v1 s2 -> eval s2 (subst x v1 t2) Q) ->
      eval s (trm_let x t1 t2) Q

  (* 4. 条件。 *)

  | eval_if : forall s (b:bool) t1 t2 Q,
      eval s (if b then t1 else t2) Q ->
      eval s (trm_if (val_bool b) t1 t2) Q

  (* 5. 无状态原语：rand 要求 n>0 且对一切可能结果 n1 都满足 Q。 *)

  | eval_add : forall s n1 n2 Q,
      Q (val_int (n1 + n2)) s ->
      eval s (val_add (val_int n1) (val_int n2)) Q
  | eval_div : forall s n1 n2 Q,
      n2 <> 0 ->
      Q (val_int (Z.quot n1 n2)) s ->
      eval s (val_div (val_int n1) (val_int n2)) Q
  | eval_rand : forall s n Q,
      n > 0 ->
      (forall n1, 0 <= n1 < n -> Q n1 s) ->
      eval s (val_rand (val_int n)) Q

  (* 6. 状态原语：ref 对一切新鲜位置 p 都要求 Q 成立（非确定性在此处理）。 *)

  | eval_ref : forall s v Q,
      (forall p, ~ Fmap.indom s p ->
          Q (val_loc p) (Fmap.update s p v)) ->
      eval s (val_ref v) Q
  | eval_get : forall s p Q,
      Fmap.indom s p ->
      Q (Fmap.read s p) s ->
      eval s (val_get (val_loc p)) Q
  | eval_set : forall s p v Q,
      Fmap.indom s p ->
      Q val_unit (Fmap.update s p v) ->
      eval s (val_set (val_loc p) v) Q
  | eval_free : forall s p Q,
      Fmap.indom s p ->
      Q val_unit (Fmap.remove s p) ->
      eval s (val_free (val_loc p)) Q.

(* ---------- 97.5 triple 的定义 ---------- *)

(* triple t H Q：任何满足前条件 H 的初始状态 s，(s,t) 的一切执行
   都终止且终格局满足后条件 Q（全正确性）。 *)

Definition triple (t:trm) (H:hprop) (Q:val->hprop) : Prop :=
  forall s, H s -> eval s t Q.

(* ---------- 97.6 结构规则：先陈述后证明 ---------- *)

Module StructuralRules.

Parameter triple_frame : forall t H Q H',
  triple t H Q ->
  triple t (H \* H') (Q \*+ H').

Parameter triple_conseq : forall t H' Q' H Q,
  triple t H' Q' ->
  H ==> H' ->
  Q' ===> Q ->
  triple t H Q.

Parameter triple_hpure : forall t (P:Prop) H Q,
  (P -> triple t H Q) ->
  triple t (\[P] \* H) Q.

Parameter triple_hexists : forall t (A:Type) (J:A->hprop) Q,
  (forall x, triple t (J x) Q) ->
  triple t (\exists x, J x) Q.

(* 练习（1 星，标准，必做）：后果-框架规则。 *)

Lemma triple_conseq_frame : forall H2 H1 Q1 t H Q,
  triple t H1 Q1 ->
  H ==> H1 \* H2 ->
  Q1 \*+ H2 ===> Q ->
  triple t H Q.
Proof using.
  introv M WH WQ. applys triple_conseq WH WQ. applys triple_frame M.
Qed.

(* 练习（1 星，标准，选做）：纯前条件不带星号的变体。 *)

Lemma triple_hpure' : forall t (P:Prop) Q,
  (P -> triple t \[] Q) ->
  triple t \[P] Q.
Proof using.
  introv M. applys triple_conseq (triple_hpure M).
  { xsimpl. auto. }
  { applys qimpl_refl. }
Qed.

End StructuralRules.

(* ---------- 97.7 后果规则的证明 ---------- *)

(* 关键：eval 对后条件 weakening 单调（Q1 ⊆ Q2）。 *)

Lemma eval_conseq : forall s t Q1 Q2,
  eval s t Q1 ->
  Q1 ===> Q2 ->
  eval s t Q2.
Proof using.
  introv M W.
  asserts W': (forall v h, Q1 v h -> Q2 v h). { auto. } clear W.
  induction M; try solve [ constructors* ].
Qed.

Lemma triple_conseq : forall t H' Q' H Q,
  triple t H' Q' ->
  H ==> H' ->
  Q' ===> Q ->
  triple t H Q.
Proof using. unfolds triple. introv M MH MQ HF. applys* eval_conseq. Qed.

(* ---------- 97.8 框架规则的证明 ---------- *)

(* 核心：eval 在并入一块不相交的堆后保持（后条件带上 (= h2) 记录"框架"部分）。 *)

Lemma eval_frame : forall h1 h2 t Q,
  eval h1 t Q ->
  Fmap.disjoint h1 h2 ->
  eval (h1 \u h2) t (Q \*+ (= h2)).
Proof using.
  introv M HD. gen h2. induction M; intros;
    try solve [ hint hstar_intro; constructors* ].
  { rename M into M1, H into M2, IHM into IH1, H0 into IH2.
    specializes IH1 HD. applys eval_seq IH1. introv HK.
    lets (h1'&h2'&K1'&K2'&KD&KU): hstar_inv HK. subst. applys* IH2. }
  { rename M into M1, H into M2, IHM into IH1, H0 into IH2.
    specializes IH1 HD. applys eval_let IH1. introv HK.
    lets (h1'&h2'&K1'&K2'&KD&KU): hstar_inv HK. subst. applys* IH2. }
  { (* 分配是关键情形：新鲜位置的约束从 h1 收紧到 h1 \u h2。 *)
    rename H into M. applys eval_ref. intros p Hp.
    rewrite Fmap.indom_union_eq in Hp. rew_logic in Hp.
    destruct Hp as [Hp1 Hp2].
    rewrite* Fmap.update_union_not_r. applys hstar_intro.
    { applys* M. } { auto. } { applys* Fmap.disjoint_update_not_r. } }
  { applys eval_get. { rewrite* Fmap.indom_union_eq. }
    { rewrite* Fmap.read_union_l. applys* hstar_intro. } }
  { applys eval_set. { rewrite* Fmap.indom_union_eq. }
    { rewrite* Fmap.update_union_l. applys hstar_intro.
      { auto. } { auto. } { applys* Fmap.disjoint_update_l. } } }
  { applys eval_free. { rewrite* Fmap.indom_union_eq. }
    { rewrite* Fmap.remove_disjoint_union_l. applys hstar_intro.
      { auto. } { auto. } { applys* Fmap.disjoint_remove_l. } } }
Qed.

Lemma triple_frame : forall t H Q H',
  triple t H Q ->
  triple t (H \* H') (Q \*+ H').
Proof.
  introv M. intros h HF. lets (h1&h2&M1&M2&MD&MU): hstar_inv (rm HF).
  subst. specializes M M1. applys eval_conseq.
  { applys eval_frame M MD. } { xsimpl. intros h' ->. applys M2. }
Qed.

(* ---------- 97.9 抽取规则的证明 ---------- *)

Lemma triple_hpure : forall t (P:Prop) H Q,
  (P -> triple t H Q) ->
  triple t (\[P] \* H) Q.
Proof using.
  introv M. intros h (h1&h2&M1&M2&D&U). destruct M1 as (M1&HP).
  lets E: hempty_inv HP. subst. rewrite Fmap.union_empty_l. applys~ M.
Qed.

(* 练习（1 星，标准，必做）：存在量词抽取规则。 *)

Lemma triple_hexists : forall t (A:Type) (J:A->hprop) Q,
  (forall (x:A), triple t (J x) Q) ->
  triple t (hexists J) Q.
Proof using. introv M. intros h (x&Hh). applys M Hh. Qed.

(* 练习（1 星，标准，选做）：给堆命名的规则。 *)

Lemma triple_named_heap : forall t H Q,
  (forall h, H h -> triple t (= h) Q) ->
  triple t H Q.
Proof using. introv M Hs. applys M Hs. auto. Qed.

(* ---------- 97.10 存在量词规则的另一种形式（二者等价） ---------- *)

Module AlternativeExistentialRule.

(* 练习（2 星，标准，必做）：传统文献中前后条件都带存在量词的版本。 *)

Lemma triple_hexists2 : forall A (Hof:A->hprop) (Qof:A->val->hprop) t,
  (forall x, triple t (Hof x) (Qof x)) ->
  triple t (\exists x, Hof x) (fun v => \exists x, Qof x v).
Proof using.
  introv M. applys triple_hexists. intros x.
  applys triple_conseq (M x).
  { xsimpl. }
  { intros v. xsimpl x. }
Qed.

(* 练习（2 星，标准，必做）：反方向（不许用 triple_hexists）。 *)

Lemma triple_hexists_of_triple_hexists2 : forall t (A:Type) (Hof:A->hprop) Q,
  (forall x, triple t (Hof x) Q) ->
  triple t (\exists x, Hof x) Q.
Proof using.
  introv M.
  applys triple_conseq (triple_hexists2 Hof (fun (x:A) => Q) M).
  { xsimpl. }
  { intros v. applys himpl_hexists_l. intros x. applys himpl_refl. }
Qed.

End AlternativeExistentialRule.

(* ---------- 97.11 小步语义 ---------- *)

(* step s t s' t'：格局 (s,t) 可以一步归约到 (s',t')。 *)

Inductive step : heap -> trm -> heap -> trm -> Prop :=

(* 上下文规则 *)
| step_seq_ctx : forall s1 s2 t1 t1' t2,
    step s1 t1 s2 t1' ->
    step s1 (trm_seq t1 t2) s2 (trm_seq t1' t2)
| step_let_ctx : forall s1 s2 x t1 t1' t2,
    step s1 t1 s2 t1' ->
    step s1 (trm_let x t1 t2) s2 (trm_let x t1' t2)

(* 归约规则 *)
| step_fun : forall s x t1,
    step s (trm_fun x t1) s (val_fun x t1)
| step_fix : forall s f x t1,
    step s (trm_fix f x t1) s (val_fix f x t1)
| step_app_fun : forall s v1 v2 x t1,
    v1 = val_fun x t1 ->
    step s (trm_app v1 v2) s (subst x v2 t1)
| step_app_fix : forall s v1 v2 f x t1,
    v1 = val_fix f x t1 ->
    step s (trm_app v1 v2) s (subst x v2 (subst f v1 t1))
| step_if : forall s b t1 t2,
    step s (trm_if (val_bool b) t1 t2) s (if b then t1 else t2)
| step_seq : forall s t2 v1,
    step s (trm_seq v1 t2) s t2
| step_let : forall s x t2 v1,
    step s (trm_let x v1 t2) s (subst x v1 t2)

(* 原语操作 *)
| step_add : forall s n1 n2,
    step s (val_add (val_int n1) (val_int n2)) s (val_int (n1 + n2))
| step_div : forall s n1 n2,
    n2 <> 0 ->
    step s (val_div (val_int n1) (val_int n2)) s (Z.quot n1 n2)
| step_rand : forall s n n1,
    0 <= n1 < n ->
    step s (val_rand (val_int n)) s (val_int n1)
| step_ref : forall s v p,
    ~ Fmap.indom s p ->
    step s (val_ref v) (Fmap.update s p v) (val_loc p)
| step_get : forall s p,
    Fmap.indom s p ->
    step s (val_get (val_loc p)) s (Fmap.read s p)
| step_set : forall s p v,
    Fmap.indom s p ->
    step s (val_set (val_loc p) v) (Fmap.update s p v) val_unit
| step_free : forall s p,
    Fmap.indom s p ->
    step s (val_free (val_loc p)) (Fmap.remove s p) val_unit.

(* steps 是 step 的自反传递闭包。 *)

Inductive steps : heap -> trm -> heap -> trm -> Prop :=
  | steps_refl : forall s t,
      steps s t s t
  | steps_step : forall s1 s2 s3 t1 t2 t3,
      step s1 t1 s2 t2 ->
      steps s2 t2 s3 t3 ->
      steps s1 t1 s3 t3.

Lemma steps_of_step : forall s1 s2 t1 t2,
  step s1 t1 s2 t2 ->
  steps s1 t1 s2 t2.
Proof using. introv M. applys steps_step M. applys steps_refl. Qed.

Lemma steps_trans : forall s1 s2 s3 t1 t2 t3,
  steps s1 t1 s2 t2 ->
  steps s2 t2 s3 t3 ->
  steps s1 t1 s3 t3.
Proof using.
  introv M1. induction M1; introv M2. { auto. } { constructors*. }
Qed.

Definition trm_is_val (t:trm) : Prop :=
  match t with trm_val v => True | _ => False end.

(* 不能步进的非值格局称为卡死（stuck）。 *)

Definition reducible (s:heap) (t:trm) : Prop :=
  exists s' t', step s t s' t'.

Lemma reducible_val_inv : forall s v,
  ~ reducible s v.
Proof using. introv (s'&t'&M). inverts M. Qed.

Definition notstuck (s:heap) (t:trm) : Prop :=
  trm_is_val t \/ reducible s t.

(* ---------- 97.12 seval：小步式全正确性与可靠性 ---------- *)

Inductive terminates : heap->trm->Prop :=
  | terminates_step : forall s t,
      (forall s' t', step s t s' t' -> terminates s' t') ->
      terminates s t.

Definition safe (s:heap) (t:trm) : Prop :=
  forall s' t', steps s t s' t' -> notstuck s' t'.

Definition correct (s:heap) (t:trm) (Q:val->hprop) : Prop :=
  forall s' v, steps s t s' v -> Q v s'.

(* seval s t Q：值情形直接要求 Q；步进情形要求可归约且一切后继都 seval。 *)

Inductive seval : heap->trm->(val->hprop)->Prop :=
  | seval_val : forall s v Q,
      Q v s ->
      seval s v Q
  | seval_step : forall s t Q,
      reducible s t -> (* (exists s' t', step s t s' t') *)
      (forall s' t', step s t s' t' -> seval s' t' Q) ->
      seval s t Q.

(* 练习（2 星，标准，选做）：热身——值情形的反演。 *)

Lemma seval_val_inv : forall s v Q,
  seval s v Q ->
  Q v s.
Proof using.
  introv M. inverts M.
  { auto. }
  { destruct H as (s'&t'&R). inverts R. }
Qed.

(* 练习（2 星，标准，必做）：seval 蕴含终止性。 *)

Lemma seval_terminates : forall s t Q,
  seval s t Q ->
  terminates s t.
Proof using.
  introv M. induction M; constructors; introv R.
  { inverts R. }
  { eauto. }
Qed.

(* 练习（3 星，标准，必做）：seval 蕴含安全性（归纳于 steps）。 *)

Lemma seval_safe : forall s t Q,
  seval s t Q ->
  safe s t.
Proof using.
  introv M R. gen Q. induction R; intros.
  { inverts M. { left. hnfs*. } { right*. } }
  { rename H into S. inverts M. { inverts S. } { applys* IHR. } }
Qed.

(* 练习（3 星，标准，必做）：seval 蕴含正确性。 *)

Lemma seval_correct : forall s t Q,
  seval s t Q ->
  correct s t Q.
Proof using.
  introv M. induction M; introv R.
  { inverts R as. { auto. } { introv S. inverts S. } }
  { rename H1 into IH. inverts R. { lets (?&?&R): H. inverts R. } applys* IH. }
Qed.

Lemma seval_sound : forall s t Q,
  seval s t Q ->
  terminates s t /\ safe s t /\ correct s t Q.
Proof using.
  introv M. splits.
  { applys* seval_terminates. }
  { applys* seval_safe. }
  { applys* seval_correct. }
Qed.

(* 为证 eval ⊆ seval，先为 seval 建立一套"大步式"求值规则。 *)

Lemma seval_fun : forall s x t1 Q,
  Q (val_fun x t1) s ->
  seval s (trm_fun x t1) Q.
Proof using.
  introv M. applys seval_step.
  { do 2 esplit. constructor. }
  { introv R. inverts R. { applys seval_val. applys M. } }
Qed.

Lemma seval_fix : forall s f x t1 Q,
  Q (val_fix f x t1) s ->
  seval s (trm_fix f x t1) Q.
Proof using.
  introv M. applys seval_step.
  { do 2 esplit. constructor. }
  { introv R. inverts R. { applys seval_val. applys M. } }
Qed.

Lemma seval_app_fun : forall s x v1 v2 t1 Q,
  v1 = val_fun x t1 ->
  seval s (subst x v2 t1) Q ->
  seval s (trm_app v1 v2) Q.
Proof using.
  introv E M. applys seval_step.
  { do 2 esplit. applys* step_app_fun. }
  { introv R. invert R; try solve [intros; false | introv R; inverts R].
    introv -> -> -> -> -> R. inverts E. applys M. }
Qed.

Lemma seval_app_fix : forall s f x v1 v2 t1 Q,
  v1 = val_fix f x t1 ->
  seval s (subst x v2 (subst f v1 t1)) Q ->
  seval s (trm_app v1 v2) Q.
Proof using.
  introv E M. applys seval_step.
  { do 2 esplit. applys* step_app_fix. }
  { introv R. invert R; try solve [intros; false | introv R; inverts R].
    introv -> -> -> -> -> R. inverts E. applys M. }
Qed.

(* 练习（5 星，标准，必做）：seval 的序列规则——本章最难的练习之一。 *)

Lemma seval_seq : forall s t1 t2 Q1 Q,
  seval s t1 Q1 ->
  (forall s1 v1, Q1 v1 s1 -> seval s1 t2 Q) ->
  seval s (trm_seq t1 t2) Q.
Proof using.
  introv M1 M2. gen_eq Q1': Q1.
  induction M1; intros; subst.
  { apply seval_step.
    { do 2 esplit. applys step_seq. }
    { introv R. inverts R as R'. { inverts R'. } applys* M2. } }
  { rename t into t1, H1 into IH.
    destruct H as (s'&t'&RE). applys seval_step.
    { do 2 esplit. constructors. applys RE. }
    { introv R. inverts R as R'.
      { applys* IH R' M2. }
      { false. inverts RE. } } }
Qed.

(* 练习（5 星，标准，选做）：let 版本，证明同上。 *)

Lemma seval_let : forall s x t1 t2 Q1 Q,
  seval s t1 Q1 ->
  (forall s1 v1, Q1 v1 s1 -> seval s1 (subst x v1 t2) Q) ->
  seval s (trm_let x t1 t2) Q.
Proof using.
  introv M1 M2. gen_eq Q1': Q1.
  induction M1; intros; subst.
  { apply seval_step.
    { do 2 esplit. applys step_let. }
    { introv R. inverts R as R'. { inverts R'. } applys* M2. } }
  { rename t into t1, H1 into IH.
    destruct H as (s'&t'&RE). applys seval_step.
    { do 2 esplit. constructors. applys RE. }
    { introv R. inverts R as R'.
      { applys* IH R' M2. }
      { false. inverts RE. } } }
Qed.

Lemma seval_if : forall s b t1 t2 Q,
  seval s (if b then t1 else t2) Q ->
  seval s (trm_if b t1 t2) Q.
Proof using.
  introv M. applys seval_step.
  { do 2 esplit. constructors*. }
  { introv R. inverts R; tryfalse. { applys M. } }
Qed.

(* 主定理：omni-big-step 蕴含小步式全正确性。 *)

Lemma seval_of_eval : forall s t Q,
  eval s t Q ->
  seval s t Q.
Proof using.
  introv M. induction M.
  { applys* seval_val. }
  { applys* seval_fun. }
  { applys* seval_fix. }
  { applys* seval_app_fun. }
  { applys* seval_app_fix. }
  { applys* seval_seq. }
  { applys* seval_let. }
  { applys* seval_if. }
  { applys seval_step.
    { do 2 esplit. applys* step_add. }
    { introv K. inverts K. applys* seval_val. } }
  { applys seval_step.
    { do 2 esplit. applys* step_div. }
    { introv K. inverts K. applys* seval_val. } }
  { applys seval_step.
    { do 2 esplit. applys* step_rand 0. math. }
    { introv K. inverts K; tryfalse. applys* seval_val. } }
  { applys seval_step.
    { forwards~ (p&D&N): (exists_fresh null s).
      do 2 esplit. applys* step_ref. }
    { introv K. inverts K; tryfalse. applys* seval_val. } }
  { applys seval_step.
    { do 2 esplit. applys* step_get. }
    { introv K. inverts K; tryfalse. applys* seval_val. } }
  { applys seval_step.
    { do 2 esplit. applys* step_set. }
    { introv K. inverts K; tryfalse. applys* seval_val. } }
  { applys seval_step.
    { do 2 esplit. applys* step_free. }
    { introv K. inverts K; tryfalse. applys* seval_val. } }
Qed.

(* 分离逻辑相对于小步语义的可靠性定理。 *)

Lemma soundness_small_step : forall t H Q,
  triple t H Q ->
  forall s, H s -> terminates s t /\ safe s t /\ correct s t Q.
Proof using.
  unfold triple. introv M Hs. specializes M Hs.
  lets R: seval_of_eval M. applys seval_sound R.
Qed.

(* ---------- 97.13 直接基于 seval 的三元组 ---------- *)

Definition striple (t:trm) (H:hprop) (Q:val->hprop) : Prop :=
  forall (s:heap), H s -> seval s t Q.

Lemma striple_sound : forall t H Q,
  striple t H Q ->
  forall s, H s -> terminates s t /\ safe s t /\ correct s t Q.
Proof using. introv M Hs. specializes M Hs. applys seval_sound M. Qed.

Lemma seval_conseq : forall s t Q Q',
  seval s t Q' ->
  Q' ===> Q ->
  seval s t Q.
Proof using.
  introv M WQ. induction M.
  { applys seval_val. applys* WQ. }
  { rename H1 into IH.
    applys seval_step.
    { auto. }
    { introv HR. applys* IH. } }
Qed.

Lemma striple_conseq : forall t H' Q' H Q,
  striple t H' Q' ->
  H ==> H' ->
  Q' ===> Q ->
  striple t H Q.
Proof using.
  introv M MH MQ HF. applys seval_conseq M MQ. applys* MH.
Qed.

Section stepsFrame.
#[local] Hint Constructors step.

Lemma seval_frame : forall h1 h2 t Q,
  seval h1 t Q ->
  Fmap.disjoint h1 h2 ->
  seval (h1 \u h2) t (Q \*+ (= h2)).
Proof using.
  introv M HD. gen h2. induction M; intros.
  { applys seval_val. applys* hstar_intro. }
  { rename H into M1, H0 into M2, H1 into IH2.
    applys seval_step.
    { unfolds reducible. clear M2 IH2. destruct M1 as (s'&t'&R).
      induction R; tryfalse; try solve [ do 2 esplit; constructors* ].
      { forwards* (s'&t'&R'): IHR. }
      { forwards* (s'&t'&R'): IHR. }
      { lets (p'&F&_): exists_fresh null (Fmap.union s h2). do 2 esplit.
        applys step_ref v p'. eauto. }
      { do 2 esplit. applys step_get. applys* Fmap.indom_union_l. }
      { do 2 esplit. applys step_set. applys* Fmap.indom_union_l. }
      { do 2 esplit. applys step_free. applys* Fmap.indom_union_l. } }
    { introv R. cuts (s1'&E'&D'&R'):
        (exists s1', s' = s1' \u h2 /\ Fmap.disjoint s1' h2 /\ step s t s1' t').
      { subst. applys* IH2. }
      clear M2 IH2.
      gen_eq su: (s \u h2). gen s.
      unfolds reducible. induction R; intros; subst; eauto.
      { destruct M1 as (s0&t0&R0).
        rename R into R1. forwards* (s1'&E&D&R1'): IHR s.
        { inverts R0. { eauto. } { inverts R1. } } }
      { destruct M1 as (s0&t0&R0).
        rename R into R1. forwards* (s1'&E&D&R1'): IHR s.
        { inverts R0. { eauto. } { inverts R1. } } }
      { rename H into D. rewrite Fmap.indom_union_eq in D. rew_logic in D.
        destruct D as (D1&D2). esplit. splits.
        { rewrite* Fmap.update_union_not_r. }
        { applys* Fmap.disjoint_update_not_r. }
        { eauto. } }
      { destruct M1 as (se&te&Re). inverts Re; tryfalse.
        rewrite* Fmap.read_union_l. }
      { destruct M1 as (se&te&Re). inverts Re; tryfalse. esplit. splits.
        { rewrite* Fmap.update_union_l. }
        { applys* Fmap.disjoint_update_l. }
        { eauto. } }
      { destruct M1 as (se&te&Re). inverts Re; tryfalse. esplit. splits.
        { rewrite* remove_disjoint_union_l. }
        { applys* Fmap.disjoint_remove_l. }
        { eauto. } } } }
Qed.

End stepsFrame.

Lemma striple_frame : forall t H Q H',
  striple t H Q ->
  striple t (H \* H') (Q \*+ H').
Proof.
  introv M. intros h HF. lets (h1&h2&M1&M2&MD&MU): hstar_inv (rm HF).
  subst. specializes M M1. applys seval_conseq.
  { applys seval_frame M MD. } { xsimpl. intros h' ->. applys M2. }
Qed.

(* ---------- 97.14 准确定性语言与"内嵌框架规则" ---------- *)

Module BakedInFrame.

(* 设除分配外语言是确定性的：beval s t s' v 是标准 big-step 判断。 *)

Parameter beval : heap -> trm -> heap -> val -> Prop.

(* 标准 Hoare 三元组不满足框架规则（分配位置的选择会"吃掉"框架堆）。 *)

Definition hoare (t:trm) (H:hprop) (Q:val->hprop) : Prop :=
  forall (s:heap), H s ->
  exists (s':heap) (v:val), beval s t s' v /\ Q v s'.

(* 练习（2 星，标准，必做）：Hoare 三元组的后果规则。 *)

Lemma hoare_conseq : forall t H Q H' Q',
  hoare t H' Q' ->
  H ==> H' ->
  Q' ===> Q ->
  hoare t H Q.
Proof using.
  introv M MH MQ. unfolds hoare. introv Hs.
  forwards (s'&v&HR&HQ): M s (MH s Hs).
  exists s' v. split. { exact HR. } { applys (MQ v) HQ. }
Qed.

(* 把框架规则"烤进"三元组的定义。 *)

Definition btriple (t:trm) (H:hprop) (Q:val->hprop) : Prop :=
  forall (H':hprop), hoare t (H \* H') (Q \*+ H').

(* 练习（3 星，标准，必做）：btriple 天然满足框架规则（用到星号结合律）。 *)

Lemma btriple_frame : forall t H Q H',
  btriple t H Q ->
  btriple t (H \* H') (Q \*+ H').
Proof using.
  introv M. intros K. unfolds btriple.
  applys hoare_conseq (M (H' \* K)).
  { xsimpl. }
  { intros v. xsimpl. }
Qed.

(* btriple 的低层刻画：直接用堆并与不相交性表述。 *)

Definition btriple_lowlevel (t:trm) (H:hprop) (Q:val->hprop) : Prop :=
  forall h1 h2,
  Fmap.disjoint h1 h2 ->
  H h1 ->
  exists h1' v,
       Fmap.disjoint h1' h2
    /\ beval (h1 \u h2) t (h1' \u h2) v
    /\ Q v h1'.

Lemma btriple_iff_btriple_lowlevel : forall t H Q,
  btriple t H Q <-> btriple_lowlevel t H Q.
Proof using.
  unfold triple, btriple_lowlevel, hoare. iff M.
  { introv D P1.
    forwards (h'&v&HR&HQ): M (=h2) (h1 \u h2). { applys* hstar_intro. }
    destruct HQ as (h1'&h2'&N0&N1&N2&N3). subst.
    exists h1' v. auto. }
  { intros H' h. introv (h1&h2&N1&N2&D&U).
    forwards (h1'&v&D'&HR&HQ): M h1 h2; auto. subst.
    exists (h1' \u h2) v. split. { eauto. } { applys* hstar_intro. } }
Qed.

Parameter beval_let : forall s1 s2 s3 v1 v2 x t1 t2,
  beval s1 t1 s2 v1 ->
  beval s2 (subst x v1 t2) s3 v2 ->
  beval s1 (trm_let x t1 t2) s3 v2.

(* 练习（3 星，标准，必做）：Hoare 三元组的 let 规则。 *)

Lemma hoare_let : forall x t1 t2 H Q Q1,
  hoare t1 H Q1 ->
  (forall v, hoare (subst x v t2) (Q1 v) Q) ->
  hoare (trm_let x t1 t2) H Q.
Proof using.
  introv M1 M2. unfolds hoare. introv Hs.
  forwards (s2&v1&HR1&HQ1): M1 s Hs.
  forwards (s3&v2&HR2&HQ2): (M2 v1) s2 HQ1.
  exists s3 v2. split. { applys beval_let HR1 HR2. } { exact HQ2. }
Qed.

(* 练习（3 星，标准，必做）：btriple 的 let 规则——把上面两条拼起来。 *)

Lemma btriple_let : forall x t1 t2 Q1 H Q,
  btriple t1 H Q1 ->
  (forall v1, btriple (subst x v1 t2) (Q1 v1) Q) ->
  btriple (trm_let x t1 t2) H Q.
Proof using.
  introv M1 M2. intros K. unfolds btriple.
  applys hoare_let (M1 K).
  { intros v. applys hoare_conseq ((M2 v) K).
    { applys himpl_refl. }
    { applys qimpl_refl. } }
Qed.

End BakedInFrame.

(* ---------- 97.15 小结 ----------
   1) triple 定义在 omni-big-step 语义 eval 上，天然表达非确定性语言的全正确性；
   2) 结构规则（框架/后果/抽取）都可由 eval 的逐条性质导出，框架规则的
      关键在于分配规则对"新鲜位置"的约束随堆增大而收紧；
   3) eval ⊆ seval 给出相对于小步语义的可靠性（终止+安全+正确）；
   4) 对准确定性语言，可用"内嵌框架规则"从标准 Hoare 三元组定义 triple。 *)
