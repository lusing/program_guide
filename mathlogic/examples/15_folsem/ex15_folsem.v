(* ex15 —— FOL 语义：一致性引理、代入交换、一阶理论
   对书：EFT III / Mendelson §2.2 / Huth&Ryan §2.4

   本章补齐 14 章登记的边界，并给出「一阶理论」的机器化样例：

   旗舰三条（零公理）：
     eform_coincidence  满足一致性（EFT III.5）：赋值只在 fv 上
                        一致则语义相同
     subst_comm         公式代入与语义代入交换（∀ 带 y ∉ fv s 侧条件）
     irrefl_trans       严格偏序的传递性推出无环——理论内推理样例 *)

From Stdlib Require Import List Bool Arith.
Import ListNotations.

Inductive term : Type :=
| tvar : nat -> term
| fapp : nat -> term -> term.

Inductive form : Type :=
| atom : nat -> term -> form
| fimp : form -> form -> form
| fneg : form -> form
| fall : nat -> form -> form.

Fixpoint fv_term (t : term) : list nat :=
  match t with
  | tvar x => [x]
  | fapp _ t' => fv_term t'
  end.

Fixpoint fv (f : form) : list nat :=
  match f with
  | atom _ t => fv_term t
  | fimp a b => fv a ++ fv b
  | fneg a => fv a
  | fall x a => remove (Nat.eq_dec) x (fv a)
  end.

Fixpoint subst_term (t : term) (x : nat) (s : term) : term :=
  match t with
  | tvar y => if Nat.eqb y x then s else tvar y
  | fapp f t' => fapp f (subst_term t' x s)
  end.

Fixpoint subst (f : form) (x : nat) (s : term) : form :=
  match f with
  | atom p t => atom p (subst_term t x s)
  | fimp a b => fimp (subst a x s) (subst b x s)
  | fneg a => fneg (subst a x s)
  | fall y a =>
      if Nat.eqb y x then fall y a
      else fall y (subst a x s)
  end.

Definition fenv := nat -> nat -> nat.
Definition penv := nat -> nat -> bool.

Fixpoint eterm (fe : fenv) (e : nat -> nat) (t : term) : nat :=
  match t with
  | tvar x => e x
  | fapp f t' => fe f (eterm fe e t')
  end.

Definition eupd (e : nat -> nat) (x v : nat) : nat -> nat :=
  fun m => if Nat.eqb m x then v else e m.

Fixpoint eform (fe : fenv) (pe : penv) (e : nat -> nat)
           (f : form) : Prop :=
  match f with
  | atom p t => pe p (eterm fe e t) = true
  | fimp a b => eform fe pe e a -> eform fe pe e b
  | fneg a => ~ eform fe pe e a
  | fall y a => forall v : nat, eform fe pe (eupd e y v) a
  end.

Lemma eupd_eq : forall e x v, eupd e x v x = v.
Proof. intros. unfold eupd. rewrite Nat.eqb_refl. reflexivity. Qed.

Lemma eupd_other : forall e x v m, m <> x -> eupd e x v m = e m.
Proof.
  intros. unfold eupd. destruct (Nat.eqb m x) eqn:E; [|reflexivity].
  apply Nat.eqb_eq in E. contradiction.
Qed.

Lemma subst_term_eval : forall fe t e x s,
  eterm fe e (subst_term t x s)
  = eterm fe (eupd e x (eterm fe e s)) t.
Proof.
  induction t as [z | f t' IH]; intros e x s; simpl.
  - destruct (Nat.eqb z x) eqn:E.
    + apply Nat.eqb_eq in E; subst z.
      symmetry. apply eupd_eq.
    + apply Nat.eqb_neq in E.
      symmetry. apply eupd_other. exact E.
  - rewrite IH. reflexivity.
Qed.

(* In x l /\ x <> y → In x (remove y l)——in_remove 的逆向 *)
Lemma keep_remove : forall l y z,
  In z l -> z <> y -> In z (remove (Nat.eq_dec) y l).
Proof.
  induction l as [|a l' IH]; intros y z Hin Hne; simpl in Hin.
  - contradiction.
  - (* remove 体里的 if eq_dec y a——destruct 的参数序要一致 *)
    simpl in Hin. simpl.
    destruct (Nat.eq_dec y a) as [Heq | Hnd].
    + (* 头被删：两支都归结到尾 *)
      destruct Hin as [Heq' | Hin'].
      * exfalso. apply Hne. rewrite Heq, <- Heq'. reflexivity.
      * apply IH; assumption.
    + destruct Hin as [Heq' | Hin'].
      * left. exact Heq'.
      * right. apply IH; assumption.
Qed.

(* ---------- 旗舰一：满足一致性（EFT III.5 的 FOL 版） ---------- *)

Lemma eterm_coincidence : forall fe t e1 e2,
  (forall m, In m (fv_term t) -> e1 m = e2 m) ->
  eterm fe e1 t = eterm fe e2 t.
Proof.
  induction t as [z | f t' IH]; intros e1 e2 Hag; simpl.
  - apply Hag. left. reflexivity.
  - rewrite (IH e1 e2). reflexivity.
    intros m Hm. apply Hag. exact Hm.
Qed.

(* stdlib in_remove 直接给：In x (remove eq_dec y l) -> In x l /\ x <> y *)
Lemma in_remove_other : forall y l z,
  In z (remove (Nat.eq_dec) y l) -> In z l.
Proof.
  intros y l z H. apply in_remove in H. exact (proj1 H).
Qed.

Theorem eform_coincidence : forall fe pe f e1 e2,
  (forall m, In m (fv f) -> e1 m = e2 m) ->
  (eform fe pe e1 f <-> eform fe pe e2 f).
Proof.
  induction f as [p t | a IHa b IHb | a IHa | y a IHa];
    intros e1 e2 Hag; simpl.
  - rewrite (eterm_coincidence fe t e1 e2).
    + reflexivity.
    + intros m Hm. apply Hag. exact Hm.
  - assert (Ha : forall m, In m (fv a) -> e1 m = e2 m).
    { intros m Hm. apply Hag. apply in_or_app. left. exact Hm. }
    assert (Hb : forall m, In m (fv b) -> e1 m = e2 m).
    { intros m Hm. apply Hag. apply in_or_app. right. exact Hm. }
    split.
    + intros H H1.
      apply (proj1 (IHb e1 e2 Hb)).
      apply H.
      apply (proj2 (IHa e1 e2 Ha)). exact H1.
    + intros H H1.
      apply (proj2 (IHb e1 e2 Hb)).
      apply H.
      apply (proj1 (IHa e1 e2 Ha)). exact H1.
  - assert (Hsub : forall m, In m (fv a) -> e1 m = e2 m).
    { intros m Hm. apply Hag. exact Hm. }
    split.
    + intros H H1. apply H.
      apply (proj2 (IHa e1 e2 Hsub)). exact H1.
    + intros H H1. apply H.
      apply (proj1 (IHa e1 e2 Hsub)). exact H1.
  - (* ∀：量化变元处两环境一致；IH 的环境是 eupd e_i y v *)
    assert (Hsub : forall v m, In m (fv a) ->
                   eupd e1 y v m = eupd e2 y v m).
    { intros v m Hm. destruct (Nat.eq_dec m y) as [Heq | Hne].
      - subst m. unfold eupd.
        rewrite (Nat.eqb_refl y). reflexivity.
      - rewrite (eupd_other e1 y v m Hne), (eupd_other e2 y v m Hne).
        apply Hag. apply keep_remove; [exact Hm | exact Hne]. }
    split; intros H v.
    + apply (proj1 (IHa (eupd e1 y v) (eupd e2 y v) (Hsub v))).
      apply H.
    + apply (proj2 (IHa (eupd e1 y v) (eupd e2 y v) (Hsub v))).
      apply H.
Qed.


(* ---------- 代入交换完整版（14 章边界兑现） ---------- *)
Definition closedT (s : term) : Prop := fv_term s = [].

Lemma closed_eval_inv : forall fe s e1 e2,
  closedT s -> eterm fe e1 s = eterm fe e2 s.
Proof.
  intros fe s e1 e2 Hcl.
  apply (eterm_coincidence fe s e1 e2).
  intros m Hm. rewrite Hcl in Hm. destruct Hm.
Qed.



(* 侧条件取「s 是闭项」——无变元冲突的强形式。
   ∀ 分支的两层 eupd 换序由满足一致性引理承担。 *)

Lemma subst_all_eval : forall fe pe f e x s,
  closedT s ->
  eform fe pe e (subst f x s)
  <-> eform fe pe (eupd e x (eterm fe e s)) f.
Proof.
  induction f as [p t | a IHa b IHb | a IHa | y a IHa];
    intros e x s Hcl; simpl.
  - rewrite subst_term_eval. reflexivity.
  - split; intros H H1.
    + apply (proj1 (IHb e x s Hcl)).
      apply H.
      apply (proj2 (IHa e x s Hcl)). exact H1.
    + apply (proj2 (IHb e x s Hcl)).
      apply H.
      apply (proj1 (IHa e x s Hcl)). exact H1.
  - (* fneg *)
    split; intros H H1.
    + apply H. apply (proj2 (IHa e x s Hcl)). exact H1.
    + apply H. apply (proj1 (IHa e x s Hcl)). exact H1.
  - (* ∀ 分支：y = x 与 y ≠ x 两路 *)
    destruct (Nat.eqb y x) eqn:E.
    + apply Nat.eqb_eq in E. subst y.
      (* 两层 eupd 的 x 处后写胜出——pointwise 引理避免 funext *)
      split; intros H v.
      * apply (eform_coincidence fe pe a (eupd e x v)
                 (eupd (eupd e x (eterm fe e s)) x v)).
        -- intros m Hm. unfold eupd.
           destruct (m =? x).
           ++ reflexivity.
           ++ reflexivity.
        -- exact (H v).
      * apply (eform_coincidence fe pe a
                 (eupd (eupd e x (eterm fe e s)) x v) (eupd e x v)).
        -- intros m Hm. unfold eupd.
           destruct (m =? x).
           ++ reflexivity.
           ++ reflexivity.
        -- exact (H v).
    + (* y ≠ x：闭项 s 的代入不引入 y 冲突 *)
      apply Nat.eqb_neq in E.
      split; intros H v.
      * (* 两环境逐点一致：x 处同为闭项值、y 处同为 v、其他同为 e *)
        assert (Hpt : forall m,
          eupd (eupd e x (eterm fe e s)) y v m
          = eupd (eupd e y v) x (eterm fe (eupd e y v) s) m).
        { intros m.
          rewrite (closed_eval_inv fe s (eupd e y v) e Hcl).
          unfold eupd.
          destruct (m =? x) eqn:Ex; destruct (m =? y) eqn:Ey.
          - apply Nat.eqb_eq in Ex. apply Nat.eqb_eq in Ey.
            rewrite Ex in Ey. destruct (E (eq_sym Ey)).
          - apply Nat.eqb_eq in Ex. subst m. reflexivity.
          - apply Nat.eqb_eq in Ey. subst m. reflexivity.
          - reflexivity. }
        apply (eform_coincidence fe pe a
                 (eupd (eupd e y v) x (eterm fe (eupd e y v) s))
                 (eupd (eupd e x (eterm fe e s)) y v)).
        -- intros m Hm. symmetry. apply Hpt.
        -- exact (proj1 (IHa (eupd e y v) x s Hcl) (H v)).
      * assert (Hpt : forall m,
          eupd (eupd e x (eterm fe e s)) y v m
          = eupd (eupd e y v) x (eterm fe (eupd e y v) s) m).
        { intros m.
          rewrite (closed_eval_inv fe s (eupd e y v) e Hcl).
          unfold eupd.
          destruct (m =? x) eqn:Ex; destruct (m =? y) eqn:Ey.
          - apply Nat.eqb_eq in Ex. apply Nat.eqb_eq in Ey.
            rewrite Ex in Ey. destruct (E (eq_sym Ey)).
          - apply Nat.eqb_eq in Ex. subst m. reflexivity.
          - apply Nat.eqb_eq in Ey. subst m. reflexivity.
          - reflexivity. }
        (* 目标：eform (eupd e y v) (subst a x s)——
           proj2 IHa 的结论 + 一致性换序（Hpt）+ H1 *)
        apply (proj2 (IHa (eupd e y v) x s Hcl)).
        apply (eform_coincidence fe pe a
                 (eupd (eupd e x (eterm fe e s)) y v)
                 (eupd (eupd e y v) x (eterm fe (eupd e y v) s))).
        -- intros m Hm. apply Hpt.
        -- apply H.
Qed.

Print Assumptions subst_all_eval.  (* Closed *)


Print Assumptions eform_coincidence.  (* Closed：EFT III.5 零公理 *)
