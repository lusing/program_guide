(* ex09 —— DPLL 与 SAT（Ben-Ari 3e Ch6 / Huth&Ryan §1.5-1.6）
   子句集 = 文字的析取表；DPLL = 单元传播 + 分裂回溯。

   实现要点（07/08 章教训的反转）：
   - 赋值不在过程里累积，而是在【返回时用 upd 复合】装配——
     从根上消灭 lookup 遮蔽问题；
   - 化简 fmlStep 同时干两件事：真文字 → 删子句；假文字 → 删文字；
   - fuel 的 0 兜底报 None（保守），度量 = 文字总数，每步净减 ≥1。

   旗舰两条（零公理）：
     dpll_sound    报 Some e 则 e 真满足
     dpll_complete 有模型且 fuel 充分则不报 None *)

Require Import List Bool Arith Lia.
Import ListNotations.

Definition lit : Type := (bool * nat)%type.
Definition clause : Type := list lit.
Definition fml : Type := list clause.

(* ---------- 语义 ---------- *)

Definition litVal (e : nat -> bool) (l : lit) : bool :=
  if fst l then e (snd l) else negb (e (snd l)).

Fixpoint clsSat (e : nat -> bool) (c : clause) : bool :=
  match c with
  | [] => false
  | l :: rest => orb (litVal e l) (clsSat e rest)
  end.

Fixpoint fmlSat (e : nat -> bool) (F : fml) : bool :=
  match F with
  | [] => true
  | c :: F' => andb (clsSat e c) (fmlSat e F')
  end.

Definition upd (e : nat -> bool) (n : nat) (b : bool) : nat -> bool :=
  fun m => if Nat.eqb m n then b else e m.

Lemma upd_eq : forall e n b, upd e n b n = b.
Proof.
  intros e n b. unfold upd. rewrite Nat.eqb_refl. reflexivity.
Qed.

Lemma upd_other : forall e n b m, m <> n -> upd e n b m = e m.
Proof.
  intros e n b m H. unfold upd.
  apply Nat.eqb_neq in H. rewrite H. reflexivity.
Qed.

(* ---------- 化简：真文字删子句、假文字删文字 ---------- *)

Fixpoint clauseStep (c : clause) (n : nat) (s : bool) : option clause :=
  match c with
  | [] => Some []
  | l :: rest =>
      if Nat.eqb (snd l) n then
        if xorb (fst l) s then clauseStep rest n s   (* 假文字：删 *)
        else None                                    (* 真文字：子句满足 *)
      else match clauseStep rest n s with
           | Some c' => Some (l :: c')
           | None => None
           end
  end.

Fixpoint fmlStep (F : fml) (n : nat) (s : bool) : fml :=
  match F with
  | [] => []
  | c :: F' => match clauseStep c n s with
               | None => fmlStep F' n s
               | Some c' => c' :: fmlStep F' n s
               end
  end.

(* ---------- 引理群：无该变元 / None 即满足 / 双向重建 ---------- *)

Lemma clauseStep_var_free : forall c n s c',
  clauseStep c n s = Some c' -> forall l, In l c' -> snd l <> n.
Proof.
  induction c as [|l0 rest IH]; intros n s c' H l Hin; simpl in *.
  - injection H as H; subst c'. contradiction.
  - destruct (Nat.eqb (snd l0) n) eqn:E.
    + destruct (xorb (fst l0) s) eqn:X.
      * apply (IH n s c' H l Hin).
      * discriminate.
    + destruct (clauseStep rest n s) as [c''|] eqn:E2; [|discriminate].
      injection H as H; subst c'.
      simpl in Hin. destruct Hin as [Heq | Hin'].
      -- subst l. apply Nat.eqb_neq in E. exact E.
      -- apply (IH n s c'' E2 l Hin').
Qed.

Lemma fmlStep_var_free : forall F n s c,
  In c (fmlStep F n s) -> forall l, In l c -> snd l <> n.
Proof.
  induction F as [|c0 F' IH]; intros n s c Hin l Hl; simpl in *.
  - contradiction.
  - destruct (clauseStep c0 n s) as [c''|] eqn:E.
    + destruct Hin as [Heq | Hin'].
      * subst c. eapply clauseStep_var_free; eauto.
      * apply (IH n s c Hin' l Hl).
    + apply (IH n s c Hin l Hl).
Qed.

Lemma clauseStep_none_sat : forall c n s e,
  e n = s -> clauseStep c n s = None -> clsSat e c = true.
Proof.
  induction c as [|l0 rest IH]; intros n s e Hn H; simpl in H.
  - discriminate.
  - destruct (Nat.eqb (snd l0) n) eqn:E.
    + apply Nat.eqb_eq in E.
      destruct (xorb (fst l0) s) eqn:X.
      * (* l0 是假文字：满足性来自 rest *)
        assert (Hl : litVal e l0 = false).
        { unfold litVal. rewrite E, Hn.
          destruct (fst l0); destruct s; simpl in X; try discriminate;
            reflexivity. }
        simpl. rewrite Hl. simpl. exact (IH n s e Hn H).
      * (* l0 本身是真文字 *)
        simpl. unfold litVal. rewrite E, Hn.
        destruct (fst l0); destruct s; simpl in X; try discriminate;
          reflexivity.
    + destruct (clauseStep rest n s) as [c''|] eqn:E2.
      * discriminate.
      * (* 真文字在 rest 里 *)
        simpl. destruct (litVal e l0) eqn:El; [reflexivity|].
        exact (IH n s e Hn E2).
Qed.

(* 满足方向的重建：e n = s 且满足化简子句（或子句被删）→ 满足原子句 *)
Lemma clauseStep_sat_back : forall c n s e,
  e n = s ->
  (match clauseStep c n s with
   | Some c' => clsSat e c' = true
   | None => True
   end) ->
  clsSat e c = true.
Proof.
  induction c as [|l0 rest IH]; intros n s e Hn Hstep; simpl in Hstep.
  - discriminate.
  - destruct (Nat.eqb (snd l0) n) eqn:E.
    + apply Nat.eqb_eq in E.
      destruct (xorb (fst l0) s) eqn:X.
      * (* l0 是假文字：满足性来自化简后的 rest *)
        assert (Hl : litVal e l0 = false).
        { unfold litVal. rewrite E, Hn.
          destruct (fst l0); destruct s; simpl in X; try discriminate;
            reflexivity. }
        simpl. rewrite Hl. simpl. exact (IH n s e Hn Hstep).
      * (* l0 真文字：litVal = true 直接满足 *)
        simpl. unfold litVal. rewrite E, Hn.
        destruct (fst l0); destruct s; simpl in X; try discriminate;
          reflexivity.
    + destruct (clauseStep rest n s) as [c''|] eqn:E2.
      * simpl. destruct (litVal e l0) eqn:El; [reflexivity|].
        apply (IH n s e Hn). rewrite E2.
        simpl in Hstep. rewrite El in Hstep. exact Hstep.
      * simpl. destruct (litVal e l0) eqn:El; [reflexivity|].
        exact (clauseStep_none_sat rest n s e Hn E2).
Qed.

Lemma fmlStep_sat_back : forall F n s e,
  e n = s ->
  fmlSat e (fmlStep F n s) = true ->
  fmlSat e F = true.
Proof.
  induction F as [|c0 F' IH]; intros n s e Hn Hsat; simpl in *.
  - reflexivity.
  - destruct (clauseStep c0 n s) as [c''|] eqn:E.
    + apply andb_true_iff in Hsat. destruct Hsat as [H1 H2].
      apply andb_true_iff. split.
      * apply (clauseStep_sat_back c0 n s e Hn). rewrite E. exact H1.
      * apply (IH n s e Hn). exact H2.
    + apply andb_true_iff. split.
      * apply (clauseStep_none_sat c0 n s e Hn E).
      * apply (IH n s e Hn). exact Hsat.
Qed.

(* 反方向（完备用）：满足原式 → 满足化简式 *)
Lemma clauseStep_sat_fwd : forall c n s e,
  e n = s -> clsSat e c = true ->
  match clauseStep c n s with
  | Some c' => clsSat e c' = true
  | None => True
  end.
Proof.
  induction c as [|l0 rest IH]; intros n s e Hn Hsat; simpl.
  - simpl in Hsat. exact Hsat.
  - destruct (Nat.eqb (snd l0) n) eqn:E.
    + apply Nat.eqb_eq in E.
      destruct (xorb (fst l0) s) eqn:X.
      * (* l0 是假文字（对 (n,s) 而言）：litVal e l0 必为 false *)
        destruct (litVal e l0) eqn:El.
        -- exfalso. unfold litVal in El. rewrite E, Hn in El.
           destruct (fst l0); destruct s; simpl in X; simpl in El;
             discriminate.
        -- apply (IH n s e Hn). cbn [clsSat] in Hsat.
           rewrite El in Hsat. simpl in Hsat. exact Hsat.
      * (* l0 真文字 → 子句被删 → None *)
        exact I.
    + (* 变元不同：l0 一律保留 *)
      destruct (litVal e l0) eqn:El.
      * destruct (clauseStep rest n s) as [c''|] eqn:E2.
        -- simpl. apply orb_true_iff. left. exact El.
        -- exact I.
      * destruct (clauseStep rest n s) as [c''|] eqn:E2.
        -- simpl. apply orb_true_iff. right.
           assert (Hrest : clsSat e rest = true).
           { cbn [clsSat] in Hsat. rewrite El in Hsat. simpl in Hsat.
             exact Hsat. }
           pose proof (IH n s e Hn Hrest) as HM.
           rewrite E2 in HM. exact HM.
        -- exact I.
Qed.

Lemma fmlStep_sat_fwd : forall F n s e,
  e n = s -> fmlSat e F = true -> fmlSat e (fmlStep F n s) = true.
Proof.
  induction F as [|c0 F' IH]; intros n s e Hn Hsat; simpl in *.
  - reflexivity.
  - apply andb_true_iff in Hsat. destruct Hsat as [H1 H2].
    destruct (clauseStep c0 n s) as [c''|] eqn:E.
    + apply andb_true_iff. split.
      * assert (HM := clauseStep_sat_fwd c0 n s e Hn H1).
        rewrite E in HM. exact HM.
      * apply (IH n s e Hn). exact H2.
    + apply (IH n s e Hn). exact H2.
Qed.

(* ---------- DPLL ---------- *)

Definition isEmpty (c : clause) : bool :=
  match c with [] => true | _ => false end.

Definition hasConflict (F : fml) : bool := existsb isEmpty F.

Fixpoint findUnit (F : fml) : option lit :=
  match F with
  | [] => None
  | [l] :: _ => Some l
  | _ :: F' => findUnit F'
  end.

Fixpoint firstLit (F : fml) : option lit :=
  match F with
  | [] => None
  | (l :: _) :: _ => Some l
  | _ :: F' => firstLit F'
  end.

Fixpoint dpll (fuel : nat) (F : fml) {struct fuel} : option (nat -> bool) :=
  match fuel with
  | 0 => None
  | S k =>
    if hasConflict F then None else
    match findUnit F with
    | Some (s, n) =>
        match dpll k (fmlStep F n s) with
        | Some e => Some (upd e n s)
        | None => None
        end
    | None =>
        match firstLit F with
        | Some (s, n) =>
            match dpll k (fmlStep F n s) with
            | Some e => Some (upd e n s)
            | None =>
                match dpll k (fmlStep F n (negb s)) with
                | Some e => Some (upd e n (negb s))
                | None => None
                end
            end
        | None => Some (fun _ => true)
        end
    end
  end.

(* ---------- upd 不变性 ---------- *)

Lemma clsSat_irrelevant_at : forall c e n b,
  (forall l, In l c -> snd l <> n) ->
  clsSat e c = clsSat (upd e n b) c.
Proof.
  induction c as [|l0 rest IH]; intros e n b Hf; simpl.
  - reflexivity.
  - unfold litVal. rewrite (upd_other e n b (snd l0))
      by (apply Hf; left; reflexivity).
    rewrite (IH e n b) by (intros l Hl; apply Hf; right; exact Hl).
    reflexivity.
Qed.

Lemma fmlSat_irrelevant_at : forall F e n b,
  (forall c, In c F -> forall l, In l c -> snd l <> n) ->
  fmlSat e F = fmlSat (upd e n b) F.
Proof.
  induction F as [|c0 F' IH]; intros e n b Hf; simpl.
  - reflexivity.
  - rewrite (clsSat_irrelevant_at c0 e n b)
      by (apply Hf; left; reflexivity).
    assert (Hrest : forall c, In c F' -> forall l, In l c -> snd l <> n).
    { intros c Hc l Hl. apply (Hf c (or_intror Hc)). exact Hl. }
    rewrite (IH e n b Hrest). reflexivity.
Qed.

Lemma firstLit_none_conflict : forall F,
  firstLit F = None -> hasConflict F = false -> F = [].
Proof.
  induction F as [|c0 F' IH]; intros H1 H2; [reflexivity|].
  simpl in H1, H2.
  destruct c0 as [|l0 rest].
  - discriminate.
  - discriminate.
Qed.

(* ---------- 旗舰一：Some 方向可靠 ---------- *)

Theorem dpll_sound : forall fuel F e,
  dpll fuel F = Some e -> fmlSat e F = true.
Proof.
  induction fuel as [|k IH]; intros F e H; simpl in H.
  - discriminate.
  - destruct (hasConflict F) eqn:Ec; [discriminate|].
    destruct (findUnit F) as [[s n]|] eqn:Eu.
    + destruct (dpll k (fmlStep F n s)) as [e'|] eqn:E1;
        [|discriminate].
      injection H as H. subst e.
      apply (fmlStep_sat_back F n s (upd e' n s) (upd_eq e' n s)).
      rewrite <- (fmlSat_irrelevant_at (fmlStep F n s) e' n s
                    (fmlStep_var_free F n s)).
      apply (IH _ _ E1).
    + destruct (firstLit F) as [[s n]|] eqn:Ef.
      * destruct (dpll k (fmlStep F n s)) as [e1|] eqn:E1.
        -- injection H as H. subst e.
           apply (fmlStep_sat_back F n s (upd e1 n s) (upd_eq e1 n s)).
           rewrite <- (fmlSat_irrelevant_at (fmlStep F n s) e1 n s
                         (fmlStep_var_free F n s)).
           apply (IH _ _ E1).
        -- destruct (dpll k (fmlStep F n (negb s))) as [e2|] eqn:E2;
            [|discriminate].
           injection H as H. subst e.
           apply (fmlStep_sat_back F n (negb s) (upd e2 n (negb s))
                    (upd_eq e2 n (negb s))).
           rewrite <- (fmlSat_irrelevant_at (fmlStep F n (negb s)) e2 n
                         (negb s) (fmlStep_var_free F n (negb s))).
           apply (IH _ _ E2).
      * injection H as H. subst e.
        rewrite (firstLit_none_conflict F Ef Ec). reflexivity.
Qed.

(* ---------- 度量：文字总数 ---------- *)

Fixpoint csize (c : clause) : nat :=
  match c with [] => 0 | _ :: rest => 1 + csize rest end.

Fixpoint msize (F : fml) : nat :=
  match F with [] => 0 | c :: F' => csize c + msize F' end.

Lemma clauseStep_size_le : forall c n s c',
  clauseStep c n s = Some c' -> csize c' <= csize c.
Proof.
  induction c as [|l0 rest IH]; intros n s c' H; simpl in *.
  - injection H as H; subst c'. simpl. lia.
  - destruct (Nat.eqb (snd l0) n) eqn:E.
    + destruct (xorb (fst l0) s) eqn:X.
      * pose proof (IH n s c' H). lia.
      * discriminate.
    + destruct (clauseStep rest n s) as [c''|] eqn:E2; [|discriminate].
      injection H as H; subst c'.
      specialize (IH n s c'' E2). simpl. lia.
Qed.

Lemma clauseStep_size : forall c n s c' l,
  clauseStep c n s = Some c' -> In l c -> snd l = n ->
  csize c' < csize c.
Proof.
  induction c as [|l0 rest IH]; intros n s c' l H Hin Hv; simpl in *.
  - contradiction.
  - destruct (Nat.eqb (snd l0) n) eqn:E.
    + apply Nat.eqb_eq in E. destruct (xorb (fst l0) s) eqn:X.
      * pose proof (clauseStep_size_le rest n s c' H). lia.
      * discriminate.
    + destruct (clauseStep rest n s) as [c''|] eqn:E2; [|discriminate].
      injection H as H; subst c'.
      simpl in Hin. destruct Hin as [Heq | Hin'].
      -- subst l. rewrite Hv in E. rewrite Nat.eqb_refl in E. discriminate.
      -- specialize (IH n s c'' l E2 Hin' Hv). simpl. lia.
Qed.

Lemma fmlStep_size_le : forall F n s,
  msize (fmlStep F n s) <= msize F.
Proof.
  induction F as [|c0 F' IH]; intros n s; simpl.
  - lia.
  - destruct (clauseStep c0 n s) as [c''|] eqn:E.
    + pose proof (clauseStep_size_le c0 n s c'' E).
      specialize (IH n s). simpl. lia.
    + specialize (IH n s). simpl. lia.
Qed.

Lemma in_size_pos : forall c l, In l c -> 0 < csize c.
Proof.
  induction c as [|l0 rest IH]; intros l Hin; simpl in *.
  - contradiction.
  - lia.
Qed.

Lemma fmlStep_size : forall F n s c l,
  In c F -> In l c -> snd l = n ->
  msize (fmlStep F n s) < msize F.
Proof.
  induction F as [|c0 F' IH]; intros n s c l HinC HinL Hv; simpl in *.
  - contradiction.
  - destruct HinC as [Heq | HinC'].
    + subst c0. destruct (clauseStep c n s) as [c''|] eqn:E.
      * pose proof (clauseStep_size c n s c'' l E HinL Hv).
        pose proof (fmlStep_size_le F' n s). simpl. lia.
      * simpl. pose proof (fmlStep_size_le F' n s).
        pose proof (in_size_pos c l HinL). simpl in *. lia.
    + simpl. destruct (clauseStep c0 n s) as [c''|] eqn:E.
      * pose proof (clauseStep_size_le c0 n s c'' E).
        specialize (IH n s c l HinC' HinL Hv). simpl in *. lia.
      * specialize (IH n s c l HinC' HinL Hv). simpl in *. lia.
Qed.

Lemma findUnit_witness : forall F s n,
  findUnit F = Some (s, n) -> In [(s, n)] F.
Proof.
  induction F as [|c0 F' IH]; intros s n H; simpl in H.
  - discriminate.
  - destruct c0 as [|l0 rest].
    + right. apply (IH s n H).
    + destruct rest.
      * destruct l0 as [s0 n0]. injection H as H1 H2. subst s0 n0.
        left. reflexivity.
      * right. apply (IH s n H).
Qed.

Lemma firstLit_witness : forall F s n,
  firstLit F = Some (s, n) -> exists c, In c F /\ In (s, n) c.
Proof.
  induction F as [|c0 F' IH]; intros s n H; simpl in H.
  - discriminate.
  - destruct c0 as [|l0 rest].
    + destruct (IH s n H) as [c [Hc Hl]]. exists c.
      split; [right; exact Hc | exact Hl].
    + destruct l0 as [s0 n0]. injection H as H1 H2. subst s0 n0.
      exists ((s, n) :: rest). split; [left; reflexivity|left; reflexivity].
Qed.

Lemma hasConflict_unsat : forall F e,
  hasConflict F = true -> fmlSat e F = false.
Proof.
  induction F as [|c0 F' IH]; intros e H; simpl in H.
  - discriminate.
  - destruct c0 as [|l0 rest]; simpl in H.
    + (* 空子句在前：clsSat [] = false 拉低整个合取 *)
      simpl. reflexivity.
    + (* 空子句在尾：IH 递归，andb_false_r 收尾 *)
      simpl. rewrite (IH e H). apply andb_false_r.
Qed.

Lemma fmlSat_in : forall F e c,
  In c F -> fmlSat e F = true -> clsSat e c = true.
Proof.
  induction F as [|c0 F' IH]; intros e c Hin Hsat; simpl in *.
  - contradiction.
  - destruct Hin as [Heq | Hin'].
    + subst c0. apply andb_true_iff in Hsat. exact (proj1 Hsat).
    + apply andb_true_iff in Hsat. apply (IH e c Hin'). exact (proj2 Hsat).
Qed.

(* ---------- 旗舰二：完备（有模型必不报 None） ---------- *)

Theorem dpll_complete : forall fuel F e,
  msize F < fuel -> fmlSat e F = true -> dpll fuel F <> None.
Proof.
  induction fuel as [|k IH]; intros F e Hlt Hsat Hsearch.
  - exfalso. lia.
  - simpl in Hsearch.
    destruct (hasConflict F) eqn:Ec.
    + exfalso. rewrite (hasConflict_unsat F e Ec) in Hsat. discriminate.
    + destruct (findUnit F) as [[s n]|] eqn:Eu.
      * (* 单元：e n = s 必然 *)
        assert (Hn : e n = s).
        { assert (Hin : In [(s, n)] F) by (apply (findUnit_witness F s n Eu)).
          pose proof (fmlSat_in F e [(s, n)] Hin Hsat) as Hc.
          simpl in Hc. unfold litVal in Hc. simpl in Hc.
          rewrite orb_false_r in Hc.
          destruct s.
          - exact Hc.
          - apply Bool.negb_true_iff in Hc. exact Hc. }
        destruct (dpll k (fmlStep F n s)) as [e'|] eqn:E1.
        -- discriminate.
        -- exfalso.
           assert (Hsz : msize (fmlStep F n s) < k).
           { pose proof (fmlStep_size F n s [(s, n)] (s, n)
                           (findUnit_witness F s n Eu)
                           (or_introl eq_refl) eq_refl) as HS.
             lia. }
           apply (IH _ e Hsz).
           ++ apply (fmlStep_sat_fwd F n s e Hn Hsat).
           ++ exact E1.
      * destruct (firstLit F) as [[s n]|] eqn:Ef.
        -- (* 先立两个方向的度量账本，再按模型落点反证 *)
           assert (HszT : msize (fmlStep F n s) < k).
           { destruct (firstLit_witness F s n Ef) as [c [Hc Hl]].
             pose proof (fmlStep_size F n s c (s, n) Hc Hl eq_refl).
             lia. }
           assert (HszF : msize (fmlStep F n (negb s)) < k).
           { destruct (firstLit_witness F s n Ef) as [c [Hc Hl]].
             pose proof (fmlStep_size F n (negb s) c (s, n) Hc Hl eq_refl).
             lia. }
           destruct (dpll k (fmlStep F n s)) as [e1|] eqn:E1.
           ++ discriminate.
           ++ destruct (dpll k (fmlStep F n (negb s))) as [e2|] eqn:E2.
              ** discriminate.
              ** exfalso.
                 assert (Hne : e n = negb s \/ e n = s)
                   by (destruct (e n); destruct s; auto).
                 destruct Hne as [Hne | Hne].
                 --- apply (IH _ e HszF).
                     +++ apply (fmlStep_sat_fwd F n (negb s) e Hne Hsat).
                     +++ exact E2.
                 --- apply (IH _ e HszT).
                     +++ apply (fmlStep_sat_fwd F n s e Hne Hsat).
                     +++ exact E1.
        -- discriminate.
Qed.

(* ---------- 收口：None 即不可满足 ---------- *)

Corollary dpll_decides : forall F,
  dpll (S (msize F)) F = None <-> forall e, fmlSat e F = false.
Proof.
  intros F. split.
  - intros Hn e. destruct (fmlSat e F) eqn:E; [|reflexivity].
    exfalso.
    pose proof (dpll_complete (S (msize F)) F e (Nat.lt_succ_diag_r (msize F)) E) as HC.
    apply HC. exact Hn.
  - intros Hf.
    destruct (dpll (S (msize F)) F) as [e|] eqn:E; [|reflexivity].
    exfalso.
    pose proof (dpll_sound _ _ _ E) as HS.
    rewrite (Hf e) in HS. discriminate.
Qed.

Print Assumptions dpll_sound.     (* Closed *)
Print Assumptions dpll_complete.  (* Closed *)

(* ---------- 现场 ---------- *)

Example dpll_sat_demo :
  match dpll 10 [[(true, 0); (false, 1)]; [(true, 1)]] with
  | Some _ => true | None => false end = true.
Proof. reflexivity. Qed.

Example dpll_unsat_demo : dpll 10 [[(true, 0)]; [(false, 0)]] = None.
Proof. reflexivity. Qed.

(* 坑位速记（Coq 侧）：
   - upd 复合装配模型：返回处 Some (upd e n s)——
     化简式无 n 文字（fmlStep_var_free）保证 upd 不碰语义；
   - match clauseStep … with 的假设先 destruct 内层（eqb/xorb/递归值）
     才能暴露可用形态；
   - Nat.eqb (e n) s 的分派用 _eq/_neq 双引理拆出 e n = s / ≠ s。 *)
