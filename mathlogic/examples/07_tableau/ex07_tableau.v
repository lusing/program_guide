(* ex07 —— 语义表列 tableau（Ben-Ari 3e §2.6）
   带符号公式 T/F：分支 = entry 表；α 规则延长分支、β 规则分裂分支；
   闭分支 = 同一原子同时带 T/F 号。fuel 化结构递归实现搜索。

   旗舰三条（全部零公理）：
     tsearch_sound    找到的模型真满足分支
     tsearch_complete 有模型必找到（fuel 充分时）
     tsearch_decides  搜索报 None ⟺ 公式有效（判定程序正确性） *)

Require Import List Bool Arith Lia.
Import ListNotations.

Inductive form : Type :=
| FVar : nat -> form
| FAnd : form -> form -> form
| FOr  : form -> form -> form
| FImp : form -> form -> form
| FNeg : form -> form.

Fixpoint eval (e : nat -> bool) (f : form) : bool :=
  match f with
  | FVar n   => e n
  | FAnd a b => andb (eval e a) (eval e b)
  | FOr a b  => orb (eval e a) (eval e b)
  | FImp a b => implb (eval e a) (eval e b)
  | FNeg a   => negb (eval e a)
  end.

Inductive sign : Type := T | F.
Definition entry : Type := (sign * form)%type.
Definition branch : Type := list entry.

Definition satEntry (e : nat -> bool) (en : entry) : Prop :=
  match en with
  | (T, f) => eval e f = true
  | (F, f) => eval e f = false
  end.

Definition satisfies (e : nat -> bool) (B : branch) : Prop :=
  forall en, In en B -> satEntry e en.

Fixpoint fsize (f : form) : nat :=
  match f with
  | FVar _   => 1
  | FAnd a b => 1 + fsize a + fsize b
  | FOr a b  => 1 + fsize a + fsize b
  | FImp a b => 1 + fsize a + fsize b
  | FNeg a   => 1 + fsize a
  end.

Lemma fsize_pos : forall f, 0 < fsize f.
Proof. induction f; simpl; lia. Qed.

Fixpoint bsize (B : branch) : nat :=
  match B with
  | [] => 0
  | (_, f) :: B' => fsize f + bsize B'
  end.

Definition atomic (f : form) : bool :=
  match f with FVar _ => true | _ => false end.

Fixpoint extract (B : branch) : option (sign * form * branch) :=
  match B with
  | [] => None
  | en :: B' =>
      if atomic (snd en) then
        match extract B' with
        | Some (s0, f0, rest) => Some (s0, f0, en :: rest)
        | None => None
        end
      else Some (fst en, snd en, B')
  end.

Definition hasF (n : nat) (B : branch) : bool :=
  existsb (fun en => match en with
                     | (F, FVar m) => Nat.eqb m n
                     | _ => false
                     end) B.

Definition closedB (B : branch) : bool :=
  existsb (fun en => match en with
                     | (T, FVar n) => hasF n B
                     | _ => false
                     end) B.

Definition readOff (B : branch) : nat -> bool :=
  fun n => existsb (fun en => match en with
                              | (T, FVar m) => Nat.eqb m n
                              | _ => false
                              end) B.

Definition orelse (o1 o2 : option (nat -> bool)) : option (nat -> bool) :=
  match o1 with Some e => Some e | None => o2 end.

Fixpoint tsearch (fuel : nat) (B : branch) {struct fuel} : option (nat -> bool) :=
  match fuel with
  | 0 => None
  | S k =>
    if closedB B then None else
    match extract B with
    | None => Some (readOff B)
    | Some (T, FAnd a b, B') => tsearch k ((T, a) :: (T, b) :: B')
    | Some (F, FAnd a b, B') =>
        orelse (tsearch k ((F, a) :: B')) (tsearch k ((F, b) :: B'))
    | Some (T, FOr a b, B') =>
        orelse (tsearch k ((T, a) :: B')) (tsearch k ((T, b) :: B'))
    | Some (F, FOr a b, B') => tsearch k ((F, a) :: (F, b) :: B')
    | Some (T, FImp a b, B') =>
        orelse (tsearch k ((F, a) :: B')) (tsearch k ((T, b) :: B'))
    | Some (F, FImp a b, B') => tsearch k ((T, a) :: (F, b) :: B')
    | Some (T, FNeg a, B') => tsearch k ((F, a) :: B')
    | Some (F, FNeg a, B') => tsearch k ((T, a) :: B')
    | Some (_, FVar _, _) => None
    end
  end.

(* ---------- 提取与闭分支引理 ---------- *)

Lemma extract_in : forall B s f B' en,
  extract B = Some (s, f, B') ->
  (In en B <-> en = (s, f) \/ In en B').
Proof.
  induction B as [| [s1 f1] B0 IH]; intros s f B' en H; simpl in H.
  - discriminate.
  - destruct (atomic f1) eqn:Ea; unfold atomic in Ea; simpl in Ea.
    + destruct (extract B0) as [[[s0 f0] rest]|] eqn:E.
      * injection H as H1 H2 H3. subst s f B'.
        specialize (IH s0 f0 rest en eq_refl). simpl. rewrite IH. tauto.
      * discriminate.
    + injection H as H1 H2 H3. subst s f B'.
      simpl. firstorder.
Qed.

Lemma extract_all_atoms : forall B,
  extract B = None -> forall en, In en B ->
  exists n, en = (T, FVar n) \/ en = (F, FVar n).
Proof.
  induction B as [| [s1 f1] B0 IH]; intros H en Hin; simpl in *.
  - contradiction.
  - destruct (atomic f1) eqn:Ea; unfold atomic in Ea; simpl in Ea.
    + destruct Hin as [Heq | Hin].
      * destruct f1; try discriminate.
        destruct s1; exists n; [left; symmetry; exact Heq | right; symmetry; exact Heq].
      * destruct (extract B0) as [[[s0 f0] rest]|] eqn:E; [discriminate|].
        destruct (IH eq_refl en Hin) as [n Hn]. exists n. exact Hn.
    + discriminate.
Qed.

Lemma extract_bsize : forall B s f B',
  extract B = Some (s, f, B') -> bsize B = fsize f + bsize B'.
Proof.
  induction B as [| [s1 f1] B0 IH]; intros s f B' H; simpl in *.
  - discriminate.
  - destruct (atomic f1) eqn:Ea; unfold atomic in Ea; simpl in Ea.
    + destruct (extract B0) as [[[s0 f0] rest]|] eqn:E.
      * injection H as H1 H2 H3. subst s f B'.
        specialize (IH s0 f0 rest eq_refl). simpl. lia.
      * discriminate.
    + injection H as H1 H2 H3. subst s f B'. simpl. lia.
Qed.

Lemma extract_never_atom : forall B s n B',
  extract B <> Some (s, FVar n, B').
Proof.
  induction B as [| [s1 f1] B0 IH]; intros s n B' H; simpl in H.
  - discriminate.
  - destruct (atomic f1) eqn:Ea; unfold atomic in Ea; simpl in Ea.
    + destruct (extract B0) as [[[s0 f0] rest]|] eqn:E.
      * injection H as H1 H2 H3.
        apply (IH s0 n rest). rewrite H2. reflexivity.
      * discriminate.
    + injection H as H1 H2 H3. rewrite H2 in Ea. simpl in Ea. discriminate.
Qed.

Lemma closed_contradicts : forall B e,
  closedB B = true -> satisfies e B -> False.
Proof.
  intros B e Ec Hsat.
  unfold closedB in Ec. rewrite existsb_exists in Ec.
  destruct Ec as [en1 [Hin1 Hval1]].
  destruct en1 as [s1 f1]. simpl in Hval1.
  destruct s1; simpl in Hval1.
  - destruct f1; try discriminate.
    unfold hasF in Hval1. rewrite existsb_exists in Hval1.
    destruct Hval1 as [en2 [Hin2 Hval2]].
    destruct en2 as [s2 f2]. simpl in Hval2.
    destruct s2; simpl in Hval2; try discriminate.
    destruct f2 as [n2 | | | |]; try discriminate.
    apply Nat.eqb_eq in Hval2. subst n2.
    assert (Ht : eval e (FVar n) = true).
    { pose proof (Hsat (T, FVar n) Hin1) as HT. exact HT. }
    assert (Hf : eval e (FVar n) = false).
    { pose proof (Hsat (F, FVar n) Hin2) as HF. exact HF. }
    rewrite Ht in Hf. discriminate.
  - destruct f1; try discriminate.
Qed.

(* ---------- 旗舰一：Some 方向可靠 ---------- *)

Theorem tsearch_sound : forall fuel B e,
  tsearch fuel B = Some e -> satisfies e B.
Proof.
  induction fuel as [|k IH]; intros B e H.
  - discriminate.
  - simpl in H. destruct (closedB B) eqn:Ec; [discriminate|].
    destruct (extract B) as [[[s f] B']|] eqn:Eex.
    2: { injection H as Hs. subst e.
         intros en Hin.
         destruct (extract_all_atoms B Eex en Hin) as [n [Hen | Hen]]; subst en.
         - unfold satEntry, readOff. simpl.
           apply existsb_exists. exists (T, FVar n).
           split; [exact Hin | simpl; apply Nat.eqb_refl].
         - unfold satEntry, readOff. simpl.
           destruct (existsb (fun en => match en with
                                       | (T, FVar m) => Nat.eqb m n
                                       | _ => false
                                       end) B) eqn:Er; [|reflexivity].
           exfalso. rewrite existsb_exists in Er.
           destruct Er as [en1 [Hin1 Hval1]].
           assert (Hc : closedB B = true).
           { apply existsb_exists. exists en1. split; [exact Hin1|].
             destruct en1 as [s1 f1]; simpl in Hval1.
             destruct s1; simpl in Hval1.
             - destruct f1 as [m | | | |]; try discriminate.
               unfold hasF. apply existsb_exists. exists (F, FVar n).
               split.
               + exact Hin.
               + simpl. rewrite (proj1 (Nat.eqb_eq m n) Hval1).
                 apply Nat.eqb_refl.
             - destruct f1 as [m | | | |]; try discriminate. }
           rewrite Hc in Ec. discriminate. }
    destruct s.
    + destruct f as [n | a b | a b | a b | a].
      * discriminate.
      * (* T ∧ α *)
        pose proof (IH _ _ H) as HS.
        intros en0 Hin0.
        destruct (extract_in B T (FAnd a b) B' en0 Eex) as [Hfwd _].
        destruct (Hfwd Hin0) as [Heq | HinB'].
        -- subst en0. unfold satEntry in *; simpl in *.
           pose proof (HS (T, a) (or_introl eq_refl)) as HA.
           pose proof (HS (T, b) (or_intror (or_introl eq_refl))) as HB.
           unfold satEntry in HA, HB. rewrite HA, HB. reflexivity.
        -- apply HS; simpl; tauto.
      * (* T ∨ β *)
        simpl in H; unfold orelse in H.
        destruct (tsearch k ((T, a) :: B')) as [e1|] eqn:E1.
        -- injection H as HH. subst e1.
           pose proof (IH _ _ E1) as HS.
           intros en0 Hin0.
           destruct (extract_in B T (FOr a b) B' en0 Eex) as [Hfwd _].
           destruct (Hfwd Hin0) as [Heq | HinB'].
           ++ subst en0. unfold satEntry in *; simpl in *.
              pose proof (HS (T, a) (or_introl eq_refl)) as HA.
              unfold satEntry in HA. rewrite HA. reflexivity.
           ++ apply HS; simpl; tauto.
        -- pose proof (IH _ _ H) as HS.
           intros en0 Hin0.
           destruct (extract_in B T (FOr a b) B' en0 Eex) as [Hfwd _].
           destruct (Hfwd Hin0) as [Heq | HinB'].
           ++ subst en0. unfold satEntry in *; simpl in *.
              assert (HInb : In (T, b) ((T, b) :: B')) by (simpl; tauto).
              pose proof (HS (T, b) HInb) as HB.
              unfold satEntry in HB. rewrite HB.
              destruct (eval e a); reflexivity.
           ++ apply HS; simpl; tauto.
      * (* T → β *)
        simpl in H; unfold orelse in H.
        destruct (tsearch k ((F, a) :: B')) as [e1|] eqn:E1.
        -- injection H as HH. subst e1.
           pose proof (IH _ _ E1) as HS.
           intros en0 Hin0.
           destruct (extract_in B T (FImp a b) B' en0 Eex) as [Hfwd _].
           destruct (Hfwd Hin0) as [Heq | HinB'].
           ++ subst en0. unfold satEntry in *; simpl in *.
              pose proof (HS (F, a) (or_introl eq_refl)) as HA.
              unfold satEntry in HA. rewrite HA. reflexivity.
           ++ apply HS; simpl; tauto.
        -- pose proof (IH _ _ H) as HS.
           intros en0 Hin0.
           destruct (extract_in B T (FImp a b) B' en0 Eex) as [Hfwd _].
           destruct (Hfwd Hin0) as [Heq | HinB'].
           ++ subst en0. unfold satEntry in *; simpl in *.
              assert (HInb : In (T, b) ((T, b) :: B')) by (simpl; tauto).
              pose proof (HS (T, b) HInb) as HB.
              unfold satEntry in HB. rewrite HB.
              destruct (eval e a); reflexivity.
           ++ apply HS; simpl; tauto.
      * (* T ¬ *)
        pose proof (IH _ _ H) as HS.
        intros en0 Hin0.
        destruct (extract_in B T (FNeg a) B' en0 Eex) as [Hfwd _].
        destruct (Hfwd Hin0) as [Heq | HinB'].
        -- subst en0. unfold satEntry in *; simpl in *.
           pose proof (HS (F, a) (or_introl eq_refl)) as HA.
           unfold satEntry in HA. rewrite HA. reflexivity.
        -- apply HS; simpl; tauto.
    + destruct f as [n | a b | a b | a b | a].
      * discriminate.
      * (* F ∧ β *)
        simpl in H; unfold orelse in H.
        destruct (tsearch k ((F, a) :: B')) as [e1|] eqn:E1.
        -- injection H as HH. subst e1.
           pose proof (IH _ _ E1) as HS.
           intros en0 Hin0.
           destruct (extract_in B F (FAnd a b) B' en0 Eex) as [Hfwd _].
           destruct (Hfwd Hin0) as [Heq | HinB'].
           ++ subst en0. unfold satEntry in *; simpl in *.
              pose proof (HS (F, a) (or_introl eq_refl)) as HA.
              unfold satEntry in HA. rewrite HA. reflexivity.
           ++ apply HS; simpl; tauto.
        -- pose proof (IH _ _ H) as HS.
           intros en0 Hin0.
           destruct (extract_in B F (FAnd a b) B' en0 Eex) as [Hfwd _].
           destruct (Hfwd Hin0) as [Heq | HinB'].
           ++ subst en0. unfold satEntry in *; simpl in *.
              assert (HInb : In (F, b) ((F, b) :: B')) by (simpl; tauto).
              pose proof (HS (F, b) HInb) as HB.
              unfold satEntry in HB. rewrite HB.
              destruct (eval e a); reflexivity.
           ++ apply HS; simpl; tauto.
      * (* F ∨ α *)
        pose proof (IH _ _ H) as HS.
        intros en0 Hin0.
        destruct (extract_in B F (FOr a b) B' en0 Eex) as [Hfwd _].
        destruct (Hfwd Hin0) as [Heq | HinB'].
        -- subst en0. unfold satEntry in *; simpl in *.
           pose proof (HS (F, a) (or_introl eq_refl)) as HA.
           pose proof (HS (F, b) (or_intror (or_introl eq_refl))) as HB.
           unfold satEntry in HA, HB. rewrite HA, HB. reflexivity.
        -- apply HS; simpl; tauto.
      * (* F → α *)
        pose proof (IH _ _ H) as HS.
        intros en0 Hin0.
        destruct (extract_in B F (FImp a b) B' en0 Eex) as [Hfwd _].
        destruct (Hfwd Hin0) as [Heq | HinB'].
        -- subst en0. unfold satEntry in *; simpl in *.
           pose proof (HS (T, a) (or_introl eq_refl)) as HA.
           assert (HInb : In (F, b) ((T, a) :: (F, b) :: B'))
             by (simpl; tauto).
           pose proof (HS (F, b) HInb) as HB.
           unfold satEntry in HA, HB. rewrite HA, HB. reflexivity.
        -- apply HS; simpl; tauto.
      * (* F ¬ *)
        pose proof (IH _ _ H) as HS.
        intros en0 Hin0.
        destruct (extract_in B F (FNeg a) B' en0 Eex) as [Hfwd _].
        destruct (Hfwd Hin0) as [Heq | HinB'].
        -- subst en0. unfold satEntry in *; simpl in *.
           pose proof (HS (T, a) (or_introl eq_refl)) as HA.
           unfold satEntry in HA. rewrite HA. reflexivity.
        -- apply HS; simpl; tauto.
Qed.

(* ---------- 语义辅助（shelve 坑的安全写法） ---------- *)

Lemma implb_sem2 : forall e a b,
  implb (eval e a) (eval e b) = true -> eval e a = false \/ eval e b = true.
Proof.
  intros e a b H.
  destruct (implb_true_iff (eval e a) (eval e b)) as [Fwd _].
  pose proof (Fwd H) as H2.
  assert (E : eval e a = true \/ eval e a = false)
    by (destruct (eval e a); auto).
  destruct E as [Ea | Ea].
  - right. exact (H2 Ea).
  - left. exact Ea.
Qed.

Lemma implb_false_sem : forall e a b,
  implb (eval e a) (eval e b) = false ->
  eval e a = true /\ eval e b = false.
Proof.
  intros e a b H.
  destruct (eval e a) eqn:Ea; simpl in H.
  - destruct (eval e b) eqn:Eb; simpl in H.
    + discriminate.
    + split; reflexivity.
  - discriminate.
Qed.

(* ---------- 旗舰二：完备（有模型必找到） ---------- *)

Theorem tsearch_complete : forall fuel B e,
  bsize B < fuel -> satisfies e B -> tsearch fuel B <> None.
Proof.
  induction fuel as [|k IH]; intros B e Hlt Hsat Hsearch.
  - exfalso. lia.
  - simpl in Hsearch.
    destruct (closedB B) eqn:Ec.
    + exfalso. exact (closed_contradicts B e Ec Hsat).
    + destruct (extract B) as [[[s f] B']|] eqn:Eex.
      * destruct s.
        -- destruct f as [n | a b | a b | a b | a].
           ++ exfalso. exact (extract_never_atom B T n B' Eex).
           ++ (* T ∧ α *)
              pose proof (Hsat (T, FAnd a b)
                (proj2 (extract_in B T (FAnd a b) B' (T, FAnd a b) Eex)
                       (or_introl eq_refl))) as HH.
              apply andb_true_iff in HH. destruct HH as [Ha Hb].
              assert (Hsz : bsize ((T, a) :: (T, b) :: B') < k).
              { pose proof (extract_bsize B T (FAnd a b) B' Eex) as HB.
                simpl in HB |- *. lia. }
              assert (SAT : satisfies e ((T, a) :: (T, b) :: B')).
              { intros en0 Hin0. destruct Hin0 as [Heq | Hin0'].
                - subst en0. exact Ha.
                - destruct Hin0' as [Heq | Hin0''].
                  + subst en0. exact Hb.
                  + destruct (extract_in B T (FAnd a b) B' en0 Eex) as [_ Hbwd].
                    apply Hsat. apply Hbwd. right. exact Hin0''. }
              specialize (IH _ e Hsz SAT). apply IH. exact Hsearch.
           ++ (* T ∨ β *)
              pose proof (Hsat (T, FOr a b)
                (proj2 (extract_in B T (FOr a b) B' (T, FOr a b) Eex)
                       (or_introl eq_refl))) as HH.
              apply orb_true_iff in HH. destruct HH as [Ha | Hb];
              unfold orelse in Hsearch;
              destruct (tsearch k ((T, a) :: B')) as [e1|] eqn:E1;
              simpl in Hsearch.
              ** discriminate.
              ** destruct (tsearch k ((T, b) :: B')) as [e2|] eqn:E2;
                 simpl in Hsearch.
                 --- discriminate.
                 --- exfalso.
                     assert (Hsz1 : bsize ((T, a) :: B') < k).
                     { pose proof (extract_bsize B T (FOr a b) B' Eex) as HB.
                       pose proof (fsize_pos a) as Hpa.
                       pose proof (fsize_pos b) as Hpb.
                       simpl in HB |- *. lia. }
                     assert (SAT1 : satisfies e ((T, a) :: B')).
                     { intros en0 Hin0. destruct Hin0 as [Heq | Hin0'].
                       - subst en0. exact Ha.
                       - destruct (extract_in B T (FOr a b) B' en0 Eex) as [_ Hbwd].
                         apply Hsat. apply Hbwd. right. exact Hin0'. }
                     specialize (IH _ e Hsz1 SAT1). apply IH. exact E1.
              ** discriminate.
              ** destruct (tsearch k ((T, b) :: B')) as [e2|] eqn:E2;
                 simpl in Hsearch.
                 --- discriminate.
                 --- exfalso.
                     assert (Hsz2 : bsize ((T, b) :: B') < k).
                     { pose proof (extract_bsize B T (FOr a b) B' Eex) as HB.
                       pose proof (fsize_pos a) as Hpa.
                       pose proof (fsize_pos b) as Hpb.
                       simpl in HB |- *. lia. }
                     assert (SAT2 : satisfies e ((T, b) :: B')).
                     { intros en0 Hin0. destruct Hin0 as [Heq | Hin0'].
                       - subst en0. exact Hb.
                       - destruct (extract_in B T (FOr a b) B' en0 Eex) as [_ Hbwd].
                         apply Hsat. apply Hbwd. right. exact Hin0'. }
                     specialize (IH _ e Hsz2 SAT2). apply IH. exact E2.
           ++ (* T → β *)
              pose proof (Hsat (T, FImp a b)
                (proj2 (extract_in B T (FImp a b) B' (T, FImp a b) Eex)
                       (or_introl eq_refl))) as HH.
              apply implb_sem2 in HH. destruct HH as [Ha | Hb];
              unfold orelse in Hsearch;
              destruct (tsearch k ((F, a) :: B')) as [e1|] eqn:E1;
              simpl in Hsearch.
              ** discriminate.
              ** destruct (tsearch k ((T, b) :: B')) as [e2|] eqn:E2;
                 simpl in Hsearch.
                 --- discriminate.
                 --- exfalso.
                     assert (Hsz1 : bsize ((F, a) :: B') < k).
                     { pose proof (extract_bsize B T (FImp a b) B' Eex) as HB.
                       pose proof (fsize_pos a) as Hpa.
                       pose proof (fsize_pos b) as Hpb.
                       simpl in HB |- *. lia. }
                     assert (SAT1 : satisfies e ((F, a) :: B')).
                     { intros en0 Hin0. destruct Hin0 as [Heq | Hin0'].
                       - subst en0. exact Ha.
                       - destruct (extract_in B T (FImp a b) B' en0 Eex) as [_ Hbwd].
                         apply Hsat. apply Hbwd. right. exact Hin0'. }
                     specialize (IH _ e Hsz1 SAT1). apply IH. exact E1.
              ** discriminate.
              ** destruct (tsearch k ((T, b) :: B')) as [e2|] eqn:E2;
                 simpl in Hsearch.
                 --- discriminate.
                 --- exfalso.
                     assert (Hsz2 : bsize ((T, b) :: B') < k).
                     { pose proof (extract_bsize B T (FImp a b) B' Eex) as HB.
                       pose proof (fsize_pos a) as Hpa.
                       pose proof (fsize_pos b) as Hpb.
                       simpl in HB |- *. lia. }
                     assert (SAT2 : satisfies e ((T, b) :: B')).
                     { intros en0 Hin0. destruct Hin0 as [Heq | Hin0'].
                       - subst en0. exact Hb.
                       - destruct (extract_in B T (FImp a b) B' en0 Eex) as [_ Hbwd].
                         apply Hsat. apply Hbwd. right. exact Hin0'. }
                     specialize (IH _ e Hsz2 SAT2). apply IH. exact E2.
           ++ (* T ¬ *)
              pose proof (Hsat (T, FNeg a)
                (proj2 (extract_in B T (FNeg a) B' (T, FNeg a) Eex)
                       (or_introl eq_refl))) as HH.
              simpl in HH. apply negb_true_iff in HH.
              assert (Hsz : bsize ((F, a) :: B') < k).
              { pose proof (extract_bsize B T (FNeg a) B' Eex) as HB.
                pose proof (fsize_pos a) as Hpa. simpl in HB |- *. lia. }
              assert (SAT : satisfies e ((F, a) :: B')).
              { intros en0 Hin0. destruct Hin0 as [Heq | Hin0'].
                - subst en0. exact HH.
                - destruct (extract_in B T (FNeg a) B' en0 Eex) as [_ Hbwd].
                  apply Hsat. apply Hbwd. right. exact Hin0'. }
              specialize (IH _ e Hsz SAT). apply IH. exact Hsearch.
        -- destruct f as [n | a b | a b | a b | a].
           ++ exfalso. exact (extract_never_atom B F n B' Eex).
           ++ (* F ∧ β *)
              pose proof (Hsat (F, FAnd a b)
                (proj2 (extract_in B F (FAnd a b) B' (F, FAnd a b) Eex)
                       (or_introl eq_refl))) as HH.
              simpl in HH. apply andb_false_iff in HH.
              destruct HH as [Ha | Hb];
              unfold orelse in Hsearch;
              destruct (tsearch k ((F, a) :: B')) as [e1|] eqn:E1;
              simpl in Hsearch.
              ** discriminate.
              ** destruct (tsearch k ((F, b) :: B')) as [e2|] eqn:E2;
                 simpl in Hsearch.
                 --- discriminate.
                 --- exfalso.
                     assert (Hsz1 : bsize ((F, a) :: B') < k).
                     { pose proof (extract_bsize B F (FAnd a b) B' Eex) as HB.
                       pose proof (fsize_pos a) as Hpa.
                       pose proof (fsize_pos b) as Hpb.
                       simpl in HB |- *. lia. }
                     assert (SAT1 : satisfies e ((F, a) :: B')).
                     { intros en0 Hin0. destruct Hin0 as [Heq | Hin0'].
                       - subst en0. exact Ha.
                       - destruct (extract_in B F (FAnd a b) B' en0 Eex) as [_ Hbwd].
                         apply Hsat. apply Hbwd. right. exact Hin0'. }
                     specialize (IH _ e Hsz1 SAT1). apply IH. exact E1.
              ** discriminate.
              ** destruct (tsearch k ((F, b) :: B')) as [e2|] eqn:E2;
                 simpl in Hsearch.
                 --- discriminate.
                 --- exfalso.
                     assert (Hsz2 : bsize ((F, b) :: B') < k).
                     { pose proof (extract_bsize B F (FAnd a b) B' Eex) as HB.
                       pose proof (fsize_pos a) as Hpa.
                       pose proof (fsize_pos b) as Hpb.
                       simpl in HB |- *. lia. }
                     assert (SAT2 : satisfies e ((F, b) :: B')).
                     { intros en0 Hin0. destruct Hin0 as [Heq | Hin0'].
                       - subst en0. exact Hb.
                       - destruct (extract_in B F (FAnd a b) B' en0 Eex) as [_ Hbwd].
                         apply Hsat. apply Hbwd. right. exact Hin0'. }
                     specialize (IH _ e Hsz2 SAT2). apply IH. exact E2.
           ++ (* F ∨ α *)
              pose proof (Hsat (F, FOr a b)
                (proj2 (extract_in B F (FOr a b) B' (F, FOr a b) Eex)
                       (or_introl eq_refl))) as HH.
              simpl in HH. apply orb_false_iff in HH. destruct HH as [Ha Hb].
              assert (Hsz : bsize ((F, a) :: (F, b) :: B') < k).
              { pose proof (extract_bsize B F (FOr a b) B' Eex) as HB.
                simpl in HB |- *. lia. }
              assert (SAT : satisfies e ((F, a) :: (F, b) :: B')).
              { intros en0 Hin0. destruct Hin0 as [Heq | Hin0'].
                - subst en0. exact Ha.
                - destruct Hin0' as [Heq | Hin0''].
                  + subst en0. exact Hb.
                  + destruct (extract_in B F (FOr a b) B' en0 Eex) as [_ Hbwd].
                    apply Hsat. apply Hbwd. right. exact Hin0''. }
              specialize (IH _ e Hsz SAT). apply IH. exact Hsearch.
           ++ (* F → α *)
              pose proof (Hsat (F, FImp a b)
                (proj2 (extract_in B F (FImp a b) B' (F, FImp a b) Eex)
                       (or_introl eq_refl))) as HH.
              simpl in HH. apply implb_false_sem in HH. destruct HH as [Ha Hb].
              assert (Hsz : bsize ((T, a) :: (F, b) :: B') < k).
              { pose proof (extract_bsize B F (FImp a b) B' Eex) as HB.
                simpl in HB |- *. lia. }
              assert (SAT : satisfies e ((T, a) :: (F, b) :: B')).
              { intros en0 Hin0. destruct Hin0 as [Heq | Hin0'].
                - subst en0. exact Ha.
                - destruct Hin0' as [Heq | Hin0''].
                  + subst en0. exact Hb.
                  + destruct (extract_in B F (FImp a b) B' en0 Eex) as [_ Hbwd].
                    apply Hsat. apply Hbwd. right. exact Hin0''. }
              specialize (IH _ e Hsz SAT). apply IH. exact Hsearch.
           ++ (* F ¬ *)
              pose proof (Hsat (F, FNeg a)
                (proj2 (extract_in B F (FNeg a) B' (F, FNeg a) Eex)
                       (or_introl eq_refl))) as HH.
              simpl in HH. apply negb_false_iff in HH.
              assert (Hsz : bsize ((T, a) :: B') < k).
              { pose proof (extract_bsize B F (FNeg a) B' Eex) as HB.
                pose proof (fsize_pos a) as Hpa. simpl in HB |- *. lia. }
              assert (SAT : satisfies e ((T, a) :: B')).
              { intros en0 Hin0. destruct Hin0 as [Heq | Hin0'].
                - subst en0. exact HH.
                - destruct (extract_in B F (FNeg a) B' en0 Eex) as [_ Hbwd].
                  apply Hsat. apply Hbwd. right. exact Hin0'. }
              specialize (IH _ e Hsz SAT). apply IH. exact Hsearch.
      * simpl in Hsearch. discriminate.
Qed.

(* ---------- 旗舰三：判定程序正确性 ---------- *)

Definition valid (f : form) : Prop := forall e, eval e f = true.

Corollary tsearch_decides : forall f,
  tsearch (S (bsize [(F, f)])) [(F, f)] = None <-> valid f.
Proof.
  intros f. split.
  - intros Hn e. destruct (eval e f) eqn:Ef.
    + reflexivity.
    + exfalso.
      assert (Hsat : satisfies e [(F, f)]).
      { intros en [Heq | []]. subst en. unfold satEntry. simpl. exact Ef. }
      apply (tsearch_complete (S (bsize [(F, f)])) [(F, f)] e).
      * simpl. pose proof (fsize_pos f). lia.
      * exact Hsat.
      * exact Hn.
  - intros Hv.
    destruct (tsearch (S (bsize [(F, f)])) [(F, f)]) as [e|] eqn:E;
      [| reflexivity].
    exfalso.
    pose proof (tsearch_sound _ _ _ E) as HS.
    pose proof (HS (F, f) (or_introl eq_refl)) as HF.
    unfold satEntry in HF. simpl in HF.
    rewrite (Hv e) in HF. discriminate.
Qed.

(* ---------- 现场 ---------- *)

Example demo_sat :
  match tsearch 20 [(T, FOr (FVar 0) (FVar 1))] with
  | Some _ => true | None => false end = true.
Proof. reflexivity. Qed.

Example demo_unsat :
  tsearch 20 [(T, FAnd (FVar 0) (FNeg (FVar 0)))] = None.
Proof. reflexivity. Qed.

(* 坑位速记（Coq 侧）：
   - destruct s; destruct f 的九分支里 FVar 情形两定理都要挡：
     soundness 里 tsearch 返回 None 与 Some e 矛盾；
     completeness 里必须用 extract_never_atom 排除 Eex；
   - β 分支的「两路都 None」矛盾在 Ha/Hb 的析构下自然分派；
   - implb 语义引理沿用 06 章的 shelve 安全写法。 *)