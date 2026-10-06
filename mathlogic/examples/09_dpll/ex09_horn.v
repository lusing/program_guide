(* ex09_horn —— Horn 子句与线性可满足性求解器（H&R §1.5.3 / 定理 1.47）

   Horn 子句 = (前提原子表, 结论)——结论 None 表示 ⊥（目标子句）。
   标记算法：从空标记集出发，每遍扫描把「前提全标记」的结论标记上；
   ⊥ 被标记则不可满足，否则不动点处的标记集读出模型。

   正确性两条腿（定理 1.47 的机器版）：
   - hsat_complete：⊥ 被标记 → 不可满足
     （不变量「所有被标记原子在任何满足赋值下为真」——对扫描遍数归纳）；
   - hsat_sound：不动点 + ⊥ 未标记 → 「标记即真」的赋值满足全部子句。
   终止性：标记集只增不减且 ⊆ 公式原子集，fuel = 原子数+1 必够。 *)

From Stdlib Require Import List Bool Arith Lia.
Import ListNotations.

Definition horn : Type := (list nat * option nat)%type.

Definition marked (m : list nat) (n : nat) : bool := existsb (Nat.eqb n) m.

Lemma marked_In : forall m n, marked m n = true <-> In n m.
Proof.
  intros m n. unfold marked. rewrite existsb_exists. split.
  - intros [x [Hin Heq]]. apply Nat.eqb_eq in Heq. subst x. exact Hin.
  - intros Hin. exists n. split. exact Hin. apply Nat.eqb_refl.
Qed.

Lemma marked_notIn : forall m n, marked m n = false <-> ~ In n m.
Proof.
  intros m n. rewrite <- marked_In.
  destruct (marked m n); split; intros H; try discriminate; auto.
  exfalso; auto.
Qed.

Fixpoint allMarked (ps : list nat) (m : list nat) : bool :=
  match ps with
  | [] => true
  | p :: ps' => marked m p && allMarked ps' m
  end.

Lemma allMarked_In : forall ps m,
  allMarked ps m = true -> forall p, In p ps -> In p m.
Proof.
  induction ps as [|p ps' IH]; intros m Ham q Hin; simpl in *.
  - contradiction.
  - apply andb_prop in Ham. destruct Ham as [Hm Hrest].
    destruct Hin as [Heq | Hin].
    + subst q. apply marked_In. exact Hm.
    + exact (IH m Hrest q Hin).
Qed.

Lemma allMarked_true : forall ps m,
  (forall p, In p ps -> In p m) -> allMarked ps m = true.
Proof.
  induction ps as [|p ps' IH]; intros m H; simpl; auto.
  apply andb_true_intro. split.
  - apply marked_In. apply H. left. reflexivity.
  - apply IH. intros q Hq. apply H. right. exact Hq.
Qed.

Lemma allMarked_mono : forall ps m m',
  incl m m' -> allMarked ps m = true -> allMarked ps m' = true.
Proof.
  intros ps m m' Hin Ham. apply allMarked_true.
  intros p Hp. apply Hin. apply (allMarked_In ps m Ham p Hp).
Qed.

(* ---------- 标记算法 ---------- *)

Definition sweep1 (c : horn) (m : list nat) : list nat * bool :=
  match c with
  | (ps, cq) =>
      if allMarked ps m then
        match cq with
        | None => (m, true)
        | Some q => if marked m q then (m, false) else (q :: m, false)
        end
      else (m, false)
  end.

Fixpoint sweep (cs : list horn) (m : list nat) : list nat * bool :=
  match cs with
  | [] => (m, false)
  | c :: cs' =>
      let '(m1, b1) := sweep cs' m in
      let '(m2, b2) := sweep1 c m1 in
      (m2, b1 || b2)
  end.

Fixpoint close (fuel : nat) (cs : list horn) (m : list nat) : list nat * bool :=
  match fuel with
  | 0 => (m, false)
  | S k =>
      let '(m1, b1) := sweep cs m in
      if b1 then (m1, true)
      else if forallb (fun n => marked m n) m1
        then (m, false)    (* 不动点：返回 sweep 前的 m——sweep cs m 的结果已知 *)
        else close k cs m1
  end.

Lemma forallb_marked_incl : forall m1 m,
  forallb (fun n => marked m n) m1 = true -> incl m1 m.
Proof.
  induction m1 as [|n m1' IH]; intros m Hf x Hin; simpl in *.
  - contradiction.
  - apply andb_prop in Hf. destruct Hf as [Hn Hrest].
    destruct Hin as [Heq | Hin].
    + subst x. apply marked_In. exact Hn.
    + apply IH; auto.
Qed.

Lemma forallb_marked_notincl : forall m1 m,
  forallb (fun n => marked m n) m1 = false ->
  exists n, In n m1 /\ ~ In n m.
Proof.
  induction m1 as [|n m1' IH]; intros m Hf; simpl in *.
  - discriminate.
  - apply andb_false_iff in Hf. destruct Hf as [Hn | Hrest].
    + exists n. split; [left; reflexivity|].
      apply marked_notIn. exact Hn.
    + destruct (IH m Hrest) as [x [Hin Hnot]].
      exists x. split; [right; exact Hin | exact Hnot].
Qed.

Definition atomsOf (cs : list horn) : list nat :=
  flat_map (fun c => fst c ++ (match snd c with Some q => [q] | None => [] end)) cs.

Definition hsat (cs : list horn) : bool :=
  negb (snd (close (S (length (atomsOf cs))) cs [])).

(* ---------- 语义 ---------- *)

Definition csat (v : nat -> bool) (c : horn) : Prop :=
  match c with
  | (ps, None) => (forall p, In p ps -> v p = true) -> False
  | (ps, Some q) => (forall p, In p ps -> v p = true) -> v q = true
  end.

Definition allsat (v : nat -> bool) (cs : list horn) : Prop :=
  forall c, In c cs -> csat v c.

Lemma incl_nil_any : forall (A : list nat), incl [] A.
Proof. intros A n Hn. simpl in Hn. contradiction. Qed.

(* ---------- 不变量（H&R 式 1.8）：满足赋值下被标记者必真 ---------- *)

Lemma sweep1_inv : forall c m v,
  csat v c ->
  (forall n, In n m -> v n = true) ->
  (forall n, In n (fst (sweep1 c m)) -> v n = true) /\
  (snd (sweep1 c m) = true -> False).
Proof.
  intros [ps cq] m v Hc Hm. unfold sweep1. simpl.
  destruct (allMarked ps m) eqn:Ham; [| split; auto; discriminate].
  destruct cq as [q|].
  - destruct (marked m q) eqn:Hq; simpl.
    + split; auto; discriminate.
    + split; [| discriminate]. intros n [Heq | Hin].
      * subst n. apply Hc. intros p Hp.
        apply Hm. apply (allMarked_In ps m Ham p Hp).
      * apply Hm. exact Hin.
  - split; auto. intros _.
    apply Hc. intros p Hp. apply Hm. apply (allMarked_In ps m Ham p Hp).
Qed.

Lemma sweep_inv : forall cs m v,
  allsat v cs ->
  (forall n, In n m -> v n = true) ->
  (forall n, In n (fst (sweep cs m)) -> v n = true) /\
  (snd (sweep cs m) = true -> False).
Proof.
  induction cs as [|c cs' IH]; intros m v Hsat Hm; simpl.
  - split; auto; discriminate.
  - destruct (sweep cs' m) as [m1 b1] eqn:E1.
    assert (Hsat' : allsat v cs').
    { intros c0 Hc0. apply Hsat. right. exact Hc0. }
    destruct (IH m v Hsat' Hm) as [Hm1 Hb1]. rewrite E1 in Hm1, Hb1. simpl in Hm1, Hb1.
    pose proof (sweep1_inv c m1 v (Hsat _ (or_introl eq_refl)) Hm1) as [Hm2 Hb2].
    destruct (sweep1 c m1) as [m2 b2] eqn:E2. simpl in *.
    split. exact Hm2.
    intros Hbot. destruct b2; destruct b1; simpl in Hbot;
      try discriminate; auto.
Qed.

Lemma close_inv : forall fuel cs m v,
  allsat v cs ->
  (forall n, In n m -> v n = true) ->
  snd (close fuel cs m) = true -> False.
Proof.
  induction fuel as [|k IH]; intros cs m v Hsat Hm Hc; simpl in Hc.
  - discriminate.
  - destruct (sweep cs m) as [m1 b1] eqn:E1. simpl in Hc.
    pose proof (sweep_inv cs m v Hsat Hm) as [Hm1 Hb1].
    rewrite E1 in Hm1, Hb1. simpl in Hm1, Hb1.
    destruct b1.
    + exact (Hb1 eq_refl).
    + destruct (forallb (fun n => marked m n) m1); try discriminate.
      exact (IH cs m1 v Hsat Hm1 Hc).
Qed.

Theorem hsat_complete : forall cs,
  hsat cs = false -> ~ (exists v, allsat v cs).
Proof.
  intros cs Hh [v Hsat].
  unfold hsat in Hh. apply negb_false_iff in Hh.
  assert (Hnil : forall n, In n (@nil nat) -> v n = true).
  { intros n Hn. simpl in Hn. contradiction. }
  exact (close_inv _ cs [] v Hsat Hnil Hh).
Qed.

(* ---------- 单调性 / NoDup / 原子界 ---------- *)

Lemma sweep1_incl : forall c m, incl m (fst (sweep1 c m)).
Proof.
  intros [ps cq] m; unfold sweep1; simpl.
  destruct (allMarked ps m); [| apply incl_refl].
  destruct cq as [q|]; [| apply incl_refl].
  destruct (marked m q); simpl.
  - apply incl_refl.
  - intros n Hn. right. exact Hn.
Qed.

Lemma sweep_incl : forall cs m, incl m (fst (sweep cs m)).
Proof.
  induction cs as [|c cs' IH]; intros m; simpl.
  - apply incl_refl.
  - destruct (sweep cs' m) as [m1 b1] eqn:E1.
    destruct (sweep1 c m1) as [m2 b2] eqn:E2. simpl.
    intros n Hin.
    assert (H1 : incl m m1).
    { pose proof (IH m) as H. rewrite E1 in H. simpl in H. exact H. }
    assert (H2 : incl m1 m2).
    { pose proof (sweep1_incl c m1) as H. rewrite E2 in H. simpl in H. exact H. }
    apply H2. apply H1. exact Hin.
Qed.

Lemma sweep1_nodup : forall c m, NoDup m -> NoDup (fst (sweep1 c m)).
Proof.
  intros [ps cq] m Hnd. unfold sweep1. simpl.
  destruct (allMarked ps m); [| exact Hnd].
  destruct cq as [q|]; [| exact Hnd].
  destruct (marked m q) eqn:Hq; simpl; [exact Hnd |].
  constructor; [| exact Hnd].
  apply marked_notIn. exact Hq.
Qed.

Lemma sweep_nodup : forall cs m, NoDup m -> NoDup (fst (sweep cs m)).
Proof.
  induction cs as [|c cs' IH]; intros m Hnd; simpl; auto.
  destruct (sweep cs' m) as [m1 b1] eqn:E1.
  destruct (sweep1 c m1) as [m2 b2] eqn:E2. simpl.
  assert (H1 : NoDup m1).
  { pose proof (IH m Hnd) as H. rewrite E1 in H. exact H. }
  pose proof (sweep1_nodup c m1 H1) as H. rewrite E2 in H. exact H.
Qed.

Lemma atomsOf_spec : forall cs ps q,
  In (ps, q) cs ->
  (forall p, In p ps -> In p (atomsOf cs)) /\
  (forall q0, q = Some q0 -> In q0 (atomsOf cs)).
Proof.
  intros cs ps q Hin. split.
  - intros p Hp. unfold atomsOf. apply in_flat_map.
    exists (ps, q). split; [exact Hin|].
    apply in_or_app. left. exact Hp.
  - intros q0 Heq. unfold atomsOf. apply in_flat_map.
    exists (ps, q). split; [exact Hin|].
    simpl. rewrite Heq. simpl. apply in_or_app. right. left. reflexivity.
Qed.

Lemma sweep1_atoms : forall c m A,
  incl m A ->
  (forall p, In p (fst c) -> In p A) ->
  (forall q0, snd c = Some q0 -> In q0 A) ->
  incl (fst (sweep1 c m)) A.
Proof.
  intros [ps [q|]] m A Hm Hps Hq; unfold sweep1; simpl in *.
  - destruct (allMarked ps m); auto.
    destruct (marked m q); auto.
    intros n [Heq | Hn]; subst; auto.
  - destruct (allMarked ps m); auto.
Qed.

Lemma sweep_atoms : forall cs m A,
  incl m A ->
  (forall ps q, In (ps, q) cs ->
     (forall p, In p ps -> In p A) /\
     (forall q0, q = Some q0 -> In q0 A)) ->
  incl (fst (sweep cs m)) A.
Proof.
  induction cs as [|c cs' IH]; intros m A Hm Hcs; simpl; auto.
  destruct c as [ps q].
  destruct (sweep cs' m) as [m1 b1] eqn:E1.
  destruct (sweep1 (ps, q) m1) as [m2 b2] eqn:E2. simpl.
  assert (Hm1 : incl m1 A).
  { pose proof (IH m A) as H. specialize (H Hm).
    assert (Htail : forall ps0 q0, In (ps0, q0) cs' ->
      (forall p, In p ps0 -> In p A) /\
      (forall q1, q0 = Some q1 -> In q1 A)).
    { intros ps0 q0 Hin. apply Hcs. right. exact Hin. }
    specialize (H Htail). rewrite E1 in H. simpl in H. exact H. }
  pose proof (sweep1_atoms (ps, q) m1 A Hm1) as H.
  assert (Hfst : forall p, In p (fst (ps, q)) -> In p A).
  { simpl. intros p Hp. destruct (Hcs ps q (or_introl eq_refl)) as [Hp1 _].
    exact (Hp1 p Hp). }
  assert (Hsnd : forall q0, snd (ps, q) = Some q0 -> In q0 A).
  { simpl. intros q0 Hq. destruct (Hcs ps q (or_introl eq_refl)) as [_ Hc2].
    exact (Hc2 q0 Hq). }
  specialize (H Hfst Hsnd). rewrite E2 in H. simpl in H. exact H.
Qed.

(* ---------- 不动点引理 ---------- *)

Lemma close_fixpoint : forall fuel cs m mF b,
  NoDup m ->
  incl m (atomsOf cs) ->
  (length (atomsOf cs) - length m < fuel)%nat ->
  close fuel cs m = (mF, b) ->
  b = true \/ (snd (sweep cs mF) = false /\ incl (fst (sweep cs mF)) mF).
Proof.
  induction fuel as [|k IH]; intros cs m mF b Hnd Hincl Hfuel Hc; simpl in Hc.
  - lia.
  - destruct (sweep cs m) as [m1 b1] eqn:E1. simpl in Hc.
    assert (Hmm1 : incl m m1).
    { pose proof (sweep_incl cs m) as H. rewrite E1 in H. simpl in H. exact H. }
    assert (Hnd1 : NoDup m1).
    { pose proof (sweep_nodup cs m Hnd) as H. rewrite E1 in H. simpl in H. exact H. }
    assert (Hincl1 : incl m1 (atomsOf cs)).
    { pose proof (sweep_atoms cs m (atomsOf cs) Hincl (atomsOf_spec cs)) as H.
      rewrite E1 in H. simpl in H. exact H. }
    destruct b1.
    + injection Hc as <- <-. left. reflexivity.
    + destruct (forallb (fun n => marked m n) m1) eqn:Efx.
      * injection Hc as <- <-. right.
        rewrite E1. simpl. split; [reflexivity|].
        apply forallb_marked_incl. exact Efx.
      * destruct (forallb_marked_notincl _ _ Efx) as [x [Hx1 Hxm]].
        assert (Hle : (length m <= length m1)%nat).
        { apply NoDup_incl_length; auto. }
        assert (Hne : length m1 <> length m).
        { intros Heq. assert (Hincl10 : incl m1 m).
          { apply (NoDup_length_incl (l:=m) (l':=m1) Hnd).
            - rewrite Heq. constructor.
            - exact Hmm1. }
          apply Hxm. apply Hincl10. exact Hx1. }
        assert (Hlt : (length m < length m1)%nat) by lia.
        assert (Hle2 : (length m1 <= length (atomsOf cs))%nat).
        { apply NoDup_incl_length; auto. }
        exact (IH cs m1 mF b Hnd1 Hincl1 ltac:(lia) Hc).
Qed.

Lemma fixpoint_clause : forall cs m,
  snd (sweep cs m) = false ->
  incl (fst (sweep cs m)) m ->
  forall ps q, In (ps, q) cs ->
  allMarked ps m = true ->
  match q with Some q0 => In q0 m | None => False end.
Proof.
  induction cs as [|c cs' IH]; intros m Hsnd Hincl ps q Hin Ham.
  - contradiction.
  - simpl in Hsnd, Hincl.
    destruct (sweep cs' m) as [m1 b1] eqn:E1. simpl in *.
    destruct (sweep1 c m1) as [m2 b2] eqn:E2. simpl in *.
    assert (Hb1 : b1 = false).
    { destruct b1; destruct b2; simpl in Hsnd; try discriminate; auto. }
    assert (Hb2 : b2 = false).
    { destruct b2; destruct b1; simpl in Hsnd; try discriminate; auto. }
    assert (Hmm1 : incl m m1).
    { pose proof (sweep_incl cs' m) as H. rewrite E1 in H. simpl in H. exact H. }
    assert (Hm1m2 : incl m1 m2).
    { pose proof (sweep1_incl c m1) as H. rewrite E2 in H. simpl in H. exact H. }
    destruct Hin as [Heq | Hin].
    + subst c.
      assert (Ham1 : allMarked ps m1 = true).
      { apply (allMarked_mono ps m m1 Hmm1 Ham). }
      unfold sweep1 in E2. rewrite Ham1 in E2.
      destruct q as [q0|].
      * destruct (marked m1 q0) eqn:Hq.
        -- injection E2 as <- <-.
           apply Hincl. apply (proj1 (marked_In m1 q0)). exact Hq.
        -- injection E2 as <- <-.
           assert (Hin2 : In q0 (q0 :: m1)) by (left; reflexivity).
           apply Hincl in Hin2. apply Hmm1 in Hin2.
           apply marked_notIn in Hq. contradiction.
      * injection E2 as _ Hb. subst b2. discriminate Hb2.
    + assert (Hb1' : snd (sweep cs' m) = false).
      { rewrite E1. simpl. exact Hb1. }
      assert (Hincl' : incl (fst (sweep cs' m)) m).
      { rewrite E1. simpl. intros n Hn. apply Hincl. apply Hm1m2. exact Hn. }
      exact (IH m Hb1' Hincl' ps q Hin Ham).
Qed.

Theorem hsat_sound : forall cs,
  hsat cs = true -> exists v, allsat v cs.
Proof.
  intros cs Hh. unfold hsat in Hh. apply negb_true_iff in Hh.
  destruct (close (S (length (atomsOf cs))) cs []) as [mF b] eqn:Ec.
  simpl in Hh. subst b.
  assert (Hfp := close_fixpoint (S (length (atomsOf cs))) cs [] mF false
                  (NoDup_nil nat) (incl_nil_any _) ltac:(simpl; lia) Ec).
  destruct Hfp as [Hbad | [Hsnd Hincl]].
  - discriminate.
  - exists (fun n => marked mF n). intros [ps q] Hin. simpl.
    destruct q as [q0|]; intros Hpre.
    + assert (Ham : allMarked ps mF = true).
      { apply allMarked_true. intros p Hp.
        exact (proj1 (marked_In mF p) (Hpre p Hp)). }
      pose proof (fixpoint_clause cs mF Hsnd Hincl ps (Some q0) Hin Ham) as Hq0.
      exact (proj2 (marked_In mF q0) Hq0).
    + assert (Ham : allMarked ps mF = true).
      { apply allMarked_true. intros p Hp.
        exact (proj1 (marked_In mF p) (Hpre p Hp)). }
      exact (fixpoint_clause cs mF Hsnd Hincl ps None Hin Ham).
Qed.

(* ---------- 现场（H&R §1.5.3 例题） ---------- *)

(* (p2 ∧ p3 ∧ p5 → p13) ∧ (⊤ → p5) ∧ (p5 ∧ p11 → ⊥)：可满足 *)
Example horn_demo_sat :
  hsat [([2;3;5], Some 13); ([], Some 5); ([5;11], None)] = true.
Proof. reflexivity. Qed.

(* 追加 (⊤ → p11)：p5、p11 都被标记，⊥ 触发——不可满足 *)
Example horn_demo_unsat :
  hsat [([2;3;5], Some 13); ([], Some 5); ([5;11], None); ([], Some 11)] = false.
Proof. reflexivity. Qed.

Print Assumptions hsat_sound.    (* Closed *)
Print Assumptions hsat_complete. (* Closed *)
