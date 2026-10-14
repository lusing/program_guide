(* 第 56 章：朴素集合的机器化（Makinson Ch1）
   列表集合：定律在成员级证明（eqs = 互相包含），幂集的 2^n 计数，
   规范形 norm 只用于具体计算证书。 *)
From Coq Require Import List Arith Lia.
Import ListNotations.

(* ---------- 布尔成员谓词与规范形 ---------- *)
Fixpoint mem (x : nat) (l : list nat) : bool :=
  match l with
  | [] => false
  | y :: ys => if Nat.eqb x y then true else mem x ys
  end.

Lemma mem_spec : forall x l, mem x l = true <-> In x l.
Proof.
  intros x l; induction l as [|y ys IH]; simpl.
  - split; [intros H; discriminate H | intros []].
  - destruct (Nat.eqb x y) eqn:E.
    + apply Nat.eqb_eq in E; subst y; split.
      * intros _; left; reflexivity.
      * intros _; reflexivity.
    + split.
      * intros H; right; apply IH; exact H.
      * intros [Hxy | Hys].
        exfalso; subst; rewrite Nat.eqb_refl in E; discriminate.
        apply IH; exact Hys.
Qed.

Fixpoint insert (x : nat) (l : list nat) : list nat :=
  match l with
  | [] => [x]
  | y :: ys =>
      if Nat.eq_dec x y then y :: ys
      else if Nat.ltb x y then x :: y :: ys
      else y :: insert x ys
  end.

Fixpoint norm (l : list nat) : list nat :=
  match l with
  | [] => []
  | x :: xs => insert x (norm xs)
  end.

(* ---------- 集合运算（定律版：直接 filter/++，不套 norm） ---------- *)
Definition meet (l m : list nat) : list nat :=
  filter (fun z => mem z m) l.
Definition uni (l m : list nat) : list nat := l ++ m.
Definition diff (l m : list nat) : list nat :=
  filter (fun z => negb (mem z m)) l.

Definition incl (l m : list nat) : Prop := forall x, In x l -> In x m.
Definition eqs (l m : list nat) : Prop := incl l m /\ incl m l.

(* ---------- 成员刻画 ---------- *)
Lemma meet_In : forall x l m, In x (meet l m) <-> In x l /\ In x m.
Proof.
  intros; unfold meet; split.
  - intros H; apply filter_In in H; destruct H as [H1 H2].
    split; [exact H1 | apply mem_spec; exact H2].
  - intros [H1 H2]; apply filter_In; split; [exact H1|].
    apply mem_spec; exact H2.
Qed.

Lemma diff_In : forall x l m, In x (diff l m) <-> In x l /\ ~ In x m.
Proof.
  intros; unfold diff; split.
  - intros H; apply filter_In in H.
    destruct H as [H1 H2]; simpl in H2.
    destruct (mem x m) eqn:Em; [discriminate H2|].
    split; [exact H1|]. intros H3.
    assert (T := proj2 (mem_spec x m) H3).
    rewrite Em in T; discriminate.
  - intros [H1 H2]; apply filter_In; split; [exact H1|].
    destruct (mem x m) eqn:Em.
    + exfalso. exact (H2 (proj1 (mem_spec x m) Em)).
    + reflexivity.
Qed.

(* ---------- 基本包含事实 ---------- *)
Lemma incl_nil : forall l, incl nil l.
Proof. intros l x H; destruct H. Qed.

Lemma incl_trans : forall l m n, incl l m -> incl m n -> incl l n.
Proof. intros l m n H1 H2 x Hx; auto. Qed.

(* ---------- 交换律 ---------- *)
Theorem meet_comm : forall l m, eqs (meet l m) (meet m l).
Proof.
  intros l m; split; intros x Hx;
    apply meet_In in Hx; apply meet_In; tauto.
Qed.

(* ---------- 分配律：交对并 ---------- *)
Theorem dist_meet_uni : forall l m n,
    eqs (meet l (uni m n)) (uni (meet l m) (meet l n)).
Proof.
  intros l m n; unfold eqs, incl, uni; split; intros x Hx.
  - apply meet_In in Hx; destruct Hx as [Hl Hun].
    apply in_app_or in Hun; destruct Hun as [Hm | Hn].
    + apply in_or_app; left; apply meet_In; auto.
    + apply in_or_app; right; apply meet_In; auto.
  - apply in_app_or in Hx; destruct Hx as [H1 | H2].
    + apply meet_In in H1; apply meet_In.
      split; [tauto | apply in_or_app; left; tauto].
    + apply meet_In in H2; apply meet_In.
      split; [tauto | apply in_or_app; right; tauto].
Qed.

(* ---------- 相对 De Morgan：差对并 ---------- *)
Theorem demorgan_diff : forall l m n,
    eqs (diff l (uni m n)) (meet (diff l m) (diff l n)).
Proof.
  intros l m n; unfold eqs, incl, uni; split; intros x Hx.
  - apply diff_In in Hx; destruct Hx as [Hl Hn].
    apply meet_In; split.
    + apply diff_In. split; [exact Hl|].
      intros Hm. apply Hn. apply in_or_app. left. exact Hm.
    + apply diff_In. split; [exact Hl|].
      intros Hn2. apply Hn. apply in_or_app. right. exact Hn2.
  - apply meet_In in Hx; destruct Hx as [H1 H2].
    apply diff_In in H1; apply diff_In in H2.
    apply diff_In. split; [tauto|].
    intros Hin. apply in_app_or in Hin.
    destruct Hin as [Hm | Hn2]; tauto.
Qed.

(* 吸收律：交对并 *)
Theorem absorb : forall l m, eqs (meet l (uni l m)) l.
Proof.
  intros l m; unfold eqs, incl, uni; split; intros x Hx.
  - apply meet_In in Hx; tauto.
  - apply meet_In; split; [exact Hx | apply in_or_app; left; exact Hx].
Qed.

(* ---------- 幂集与 2^n 计数 ---------- *)
Fixpoint powerset (l : list nat) : list (list nat) :=
  match l with
  | [] => [[]]
  | x :: xs => let rest := powerset xs in
               rest ++ map (cons x) rest
  end.

Theorem card_powerset : forall l,
    NoDup l -> length (powerset l) = 2 ^ length l.
Proof.
  induction l as [|x xs IH]; intros Hnd; simpl.
  - reflexivity.
  - inversion Hnd; subst.
    rewrite length_app, length_map.
    rewrite IH by assumption. lia.
Qed.

(* ---------- 具体计算证书（norm 规范形 + vm_compute） ---------- *)
Example cert_diff_noncomm :
    norm (diff [1;2] [2;3]) = [1] /\ norm (diff [2;3] [1;2]) = [3].
Proof. vm_compute. repeat split; reflexivity. Qed.

Example cert_pow3 : length (powerset [1;2;3]) = 8.
Proof. vm_compute. reflexivity. Qed.

Example cert_pow3_nodup : NoDup [1;2;3].
Proof.
  apply NoDup_cons_iff; split; [simpl; intros [H|[H|[]]]; discriminate|].
  apply NoDup_cons_iff; split; [simpl; intros [H|[]]; discriminate|].
  apply NoDup_cons_iff; split; [intros []|].
  constructor.
Qed.
