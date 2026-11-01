(* 第 116 章：荟萃塔 I——无界闭集与荟萃性的有限刻画、非平凡反例、
   泛型超幂等价类机制（定义 3.10/引理 3.26/3.36 的机制核；
   本体留在正文 docs/116-tower1.md）。 *)
Require Import List Arith Lia Bool FunctionalExtensionality.
Import ListNotations.

Definition subset := nat -> bool.
Definition emp : subset := fun _ => false.
Definition univ : subset := fun b => if Nat.ltb b 3 then true else false.
Definition co (i : nat) : subset :=
  fun b => andb (Nat.ltb b 3) (negb (Nat.eqb b i)).

Definition gcyc (i : nat) : nat :=
  if Nat.eqb i 0 then 1 else if Nat.eqb i 1 then 2 else 0.

Lemma nat3_cases : forall i, i < 3 -> i = 0 \/ i = 1 \/ i = 2.
Proof. intros i hi; lia. Qed.

Lemma gcyc_lt : forall i, i < 3 -> gcyc i < 3.
Proof.
  intros i hi. unfold gcyc.
  destruct (Nat.eqb_spec i 0) as [E|E]; [subst; lia|].
  destruct (Nat.eqb_spec i 1) as [E2|E2]; [subst; lia|].
  destruct (Nat.eqb_spec i 2) as [E3|E3]; [subst; lia| lia].
Qed.

Lemma gcyc_orbit3 : forall i, i < 3 -> gcyc (gcyc (gcyc i)) = i.
Proof.
  intros i hi. unfold gcyc.
  destruct (Nat.eqb_spec i 0) as [E|E]; [subst; reflexivity|].
  destruct (Nat.eqb_spec i 1) as [E2|E2]; [subst; reflexivity|].
  destruct (Nat.eqb_spec i 2) as [E3|E3]; [subst; reflexivity|].
  lia.
Qed.

Lemma gcyc_ne_self : forall i, i < 3 -> gcyc (gcyc i) <> i.
Proof.
  intros i hi. unfold gcyc.
  destruct (Nat.eqb_spec i 0) as [E|E]; [subst; discriminate|].
  destruct (Nat.eqb_spec i 1) as [E2|E2]; [subst; discriminate|].
  destruct (Nat.eqb_spec i 2) as [E3|E3]; [subst; discriminate|].
  lia.
Qed.

(* 像（只在载体 {0,1,2} 上取）。 *)
Definition imageN (f : nat -> nat) (A : subset) : subset :=
  fun b => if Nat.ltb b 3 && existsb (fun a => andb (A a) (Nat.eqb (f a) b))
                               (seq 0 3) then true else false.

(* 无界闭集：f[A] ⊆ A。 *)
Definition clubf (f : nat -> nat) (A : subset) : Prop :=
  forall b, imageN f A b = true -> A b = true.

Lemma imageN_elim : forall f A b, imageN f A b = true ->
  b < 3 /\ exists a, a < 3 /\ A a = true /\ f a = b.
Proof.
  intros f A b H. unfold imageN in H.
  destruct (andb (Nat.ltb b 3)
    (existsb (fun a => andb (A a) (Nat.eqb (f a) b)) (seq 0 3))) eqn:E;
    [ | discriminate].
  apply andb_true_iff in E. destruct E as [H3 He].
  apply existsb_exists in He. destruct He as [a [Hin Hn]].
  apply in_seq in Hin.
  assert (Hin3 : a < 3) by lia.
  apply andb_true_iff in Hn. destruct Hn as [HA Hfb].
  apply Nat.ltb_lt in H3. apply Nat.eqb_eq in Hfb.
  split. assumption. exists a. split. exact Hin3.
  split. assumption. assumption.
Qed.

Lemma clubf_empty : forall f, clubf f emp.
Proof.
  intros f b Hb. destruct (imageN_elim f emp b Hb) as [_ [a [_ [HA _]]]].
  unfold emp in HA. discriminate.
Qed.

Lemma clubf_univ : forall f, clubf f univ.
Proof.
  intros f b Hb. destruct (imageN_elim f univ b Hb) as [H3 _].
  unfold univ.
  assert (E3 : (b <? 3) = true) by (apply Nat.ltb_lt; exact H3).
  rewrite E3. reflexivity.
Qed.

Lemma imageN_wit : forall f A a, a < 3 -> f a < 3 -> A a = true ->
  imageN f A (f a) = true.
Proof.
  intros f A a ha3 hfa haA. unfold imageN.
  assert (E3 : (f a <? 3) = true) by (apply Nat.ltb_lt; exact hfa).
  rewrite E3. rewrite andb_true_l.
  assert (Ex : existsb (fun a0 => andb (A a0) (Nat.eqb (f a0) (f a)))
                       (seq 0 3) = true).
  { apply existsb_exists. exists a. split.
    - apply in_seq. lia.
    - simpl. rewrite haA, Nat.eqb_refl. reflexivity. }
  rewrite Ex. reflexivity.
Qed.

Lemma gcyc_step : forall A a, clubf gcyc A -> a < 3 -> A a = true ->
  A (gcyc a) = true.
Proof.
  intros A a Hc ha3 haA. apply (Hc (gcyc a)).
  apply (imageN_wit gcyc A a ha3 (gcyc_lt a ha3) haA).
Qed.

Lemma gcyc_orbit : forall A a, clubf gcyc A -> a < 3 -> A a = true ->
  A (gcyc a) = true /\ A (gcyc (gcyc a)) = true.
Proof.
  intros A a Hc ha3 haA. split.
  - apply (gcyc_step A a Hc ha3 haA).
  - apply (gcyc_step A (gcyc a) Hc (gcyc_lt a ha3)
      (gcyc_step A a Hc ha3 haA)).
Qed.

Lemma orbit_cover : forall a b, a < 3 -> b < 3 ->
  b = a \/ b = gcyc a \/ b = gcyc (gcyc a).
Proof.
  intros a b ha hb.
  destruct (nat3_cases a ha) as [Ea|[Ea|Ea]]; subst a;
  destruct (nat3_cases b hb) as [Eb|[Eb|Eb]]; subst b;
  first [ left; reflexivity | right; left; reflexivity
        | right; right; reflexivity ].
Qed.

Lemma gcyc_full_cover : forall (A : subset) (a : nat),
  clubf gcyc A -> a < 3 -> A a = true ->
  forall b, b < 3 -> A b = true.
Proof.
  intros A a Hc ha3 haA b hb.
  destruct (gcyc_orbit A a Hc ha3 haA) as [H1 H2].
  destruct (orbit_cover a b ha3 hb) as [E|[E|E]]; subst b; assumption.
Qed.

Lemma clubf_gcyc_char : forall A, (forall b, A b = true -> b < 3) ->
  clubf gcyc A -> (forall b, A b = false) \/ (forall b, b < 3 -> A b = true).
Proof.
  intros A hA Hc.
  destruct (existsb (fun a => andb (Nat.ltb a 3) (A a)) (seq 0 3)) eqn:E.
  - right. intros b hb.
    apply existsb_exists in E. destruct E as [a [Ha Hn]].
    apply in_seq in Ha.
    assert (Ha3 : a < 3) by lia.
    apply andb_true_iff in Hn. destruct Hn as [Ha3' HA].
    exact (gcyc_full_cover A a Hc Ha3 HA b hb).
  - left. intro b.
    destruct (existsb (fun x => andb (Nat.ltb x 3) (A x)) (seq 0 3)) eqn:E2.
    + discriminate.
    + destruct (A b) eqn:EA; [| reflexivity].
      exfalso. assert (Heq : existsb (fun x => andb (Nat.ltb x 3) (A x))
                              (seq 0 3) = true).
      { apply existsb_exists. exists b. split.
        - apply in_seq. assert (b < 3) by (apply hA; assumption). lia.
        - assert (Eb3 : (b <? 3) = true)
            by (apply Nat.ltb_lt; apply hA; exact EA).
          simpl. rewrite Eb3. assumption. }
      rewrite Heq in E2. discriminate.
Qed.

(* 荟萃：与每个 club 相交。 *)
Definition smn (X : list subset) : Prop :=
  forall f, exists A, In A X /\ clubf f A.

Lemma smn_iff : forall X, (forall A, In A X -> forall b, A b = true -> b < 3) ->
  smn X <-> (In emp X \/ In univ X).
Proof.
  intros X hX. split.
  - intro H. destruct (H gcyc) as [A [hA hc]].
    destruct (clubf_gcyc_char A (hX A hA) hc) as [Hemp|Hfull].
    + left.
      assert (Heq : A = emp) by (apply functional_extensionality; exact Hemp).
      rewrite <- Heq. exact hA.
    + right.
      assert (Heq : A = univ).
      { apply functional_extensionality. intro b.
        destruct (A b) eqn:EA.
        - unfold univ.
          assert (Eb3 : (b <? 3) = true)
            by (apply Nat.ltb_lt; apply (hX A hA); exact EA).
          rewrite Eb3. reflexivity.
        - unfold univ.
          assert (Eb3 : (b <? 3) = false).
          { destruct (Nat.ltb b 3) eqn:E4; [| reflexivity].
            exfalso. apply Nat.ltb_lt in E4.
            rewrite (Hfull b E4) in EA. discriminate. }
          rewrite Eb3. reflexivity. }
      rewrite <- Heq. exact hA.
  - (* 反向：emp/univ 之一在 X 中 ⟹ 荟萃 *)
    intros [H|H] f.
    + exists emp. split. assumption. apply clubf_empty.
    + exists univ. split. assumption. apply clubf_univ.
Qed.

Lemma not_clubf_gcyc_co : forall i, i < 3 -> ~ clubf gcyc (co i).
Proof.
  intros i hi Hc.
  assert (H1 : co i (gcyc (gcyc i)) = true).
  { unfold co. apply andb_true_iff. split.
    - apply Nat.ltb_lt. apply gcyc_lt. apply gcyc_lt. assumption.
    - apply negb_true_iff. apply Nat.eqb_neq.
      intro Heq. apply (gcyc_ne_self i hi Heq). }
  assert (H2 : imageN gcyc (co i) i = true).
  { assert (E3 : (i <? 3) = true) by (apply Nat.ltb_lt; exact hi).
    unfold imageN. rewrite E3. rewrite andb_true_l.
    assert (Ex : existsb (fun a0 => andb (co i a0)
                                (Nat.eqb (gcyc a0) i)) (seq 0 3) = true).
    { apply existsb_exists. exists (gcyc (gcyc i)). split.
      - apply in_seq. assert (gcyc (gcyc i) < 3)
          by (apply gcyc_lt; apply gcyc_lt; exact hi). lia.
      - simpl. rewrite H1.
        assert (Eg : Nat.eqb (gcyc (gcyc (gcyc i))) i = true).
        { apply Nat.eqb_eq. apply gcyc_orbit3. exact hi. }
        rewrite Eg. reflexivity. }
    rewrite Ex. reflexivity. }
  assert (Hbad := Hc i H2). unfold co in Hbad.
  apply andb_true_iff in Hbad. destruct Hbad as [_ Hne].
  apply negb_true_iff, Nat.eqb_neq in Hne. apply Hne. reflexivity.
Qed.

Lemma smn_X2_fail : ~ smn [co 0; co 1; co 2].
Proof.
  intro H. destruct (H gcyc) as [A [hA hc]].
  destruct hA as [EA|[EA|[EA|[]]]].
  - subst A. apply (not_clubf_gcyc_co 0); [lia | assumption].
  - subst A. apply (not_clubf_gcyc_co 1); [lia | assumption].
  - subst A. apply (not_clubf_gcyc_co 2); [lia | assumption].
Qed.

(* ── 泛型超幂等价类机制（引理 3.36 前置的 ~_G） ── *)
Section Filter.
Variable G : subset -> Prop.
Hypothesis hfull : G (fun b => if Nat.ltb b 3 then true else false).
Hypothesis hup : forall B C, (forall b, B b = true -> C b = true) ->
  G B -> G C.
Hypothesis hand : forall B C, G B -> G C ->
  G (fun b => andb (B b) (C b)).

Definition eqset (f g : nat -> nat) : subset :=
  fun b => andb (if Nat.ltb b 3 then true else false) (Nat.eqb (f b) (g b)).

Definition feq (f g : nat -> nat) : Prop := G (eqset f g).

Lemma feq_refl : forall f, feq f f.
Proof.
  intros f. apply (hup (fun b => if Nat.ltb b 3 then true else false)).
  - intros b Hb. unfold eqset.
    assert (Hb' : (if Nat.ltb b 3 then true else false) = true) by exact Hb.
    destruct (Nat.ltb b 3) eqn:E3.
    + rewrite Nat.eqb_refl. reflexivity.
    + simpl in Hb'. discriminate.
  - assumption.
Qed.

Lemma feq_sym : forall f g, feq f g -> feq g f.
Proof.
  intros f g H. unfold feq in *.
  assert (He : eqset f g = eqset g f).
  { apply functional_extensionality. intro b. unfold eqset.
    destruct (Nat.ltb b 3) eqn:E3; rewrite Nat.eqb_sym; reflexivity. }
  rewrite He in H. exact H.
Qed.

Lemma feq_trans : forall f g h, feq f g -> feq g h -> feq f h.
Proof.
  intros f g h H1 H2. unfold feq in *.
  apply (hup (fun b => andb (eqset f g b) (eqset g h b)) (eqset f h)).
  - intros b Hb. unfold eqset in Hb |- *.
    apply andb_true_iff in Hb. destruct Hb as [Hb3 Hbe].
    apply andb_true_iff in Hbe. destruct Hbe as [Hfg Hgh].
    apply andb_true_iff in Hb3. destruct Hb3 as [Hb31 Hb32].
    apply andb_true_iff. split.
    + exact Hfg.
    + apply Nat.eqb_eq in Hb32. rewrite Hb32. exact Hgh.
  - apply (hand (eqset f g) (eqset g h)). assumption. assumption.
Qed.

Lemma feq_const : forall f c,
  feq f (fun _ => c) <-> G (fun b => andb (if Nat.ltb b 3 then true else false)
                                          (Nat.eqb (f b) c)).
Proof. intros f c. reflexivity. Qed.

End Filter.
