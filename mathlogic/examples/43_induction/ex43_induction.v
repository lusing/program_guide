(* ex43 —— 数学归纳与递归（Jongsma §3.1-3.2）
   逻辑篇之后第一次「实战」：归纳法家族的完整机器账本。
     gauss/oddsum_sq —— Gauss 求和与奇数和=平方的 PMI 机器化；
     hanoi_pow   —— Hanoi 塔递推 m_n + 1 = 2^n（nat 无减法的形态教训）；
     nat3_fact   —— Mod PMI：n^3 < n! for 6 <= n（乘法单调性手工装配）；
     strong_ind  —— 强归纳从弱归纳推出（辅助命题 forall k m<=k -> P m）；
     bounded_dec —— 有界排中：bool 谓词在 [0,n] 上免费拿排中；
     prime_divisor —— 素因子存在（Euclid VII.31）：书用「素数或非素数」
                      的 LEM 分叉；这里走构造路线零公理；
     firstUp     —— 良序原理的构造面：线性搜索首真元（WOP-bool）；
     wop_classic —— 良序原理 Prop 版（书：反设无最小元 + 补集强归纳），
                      显式经典记账（Print Assumptions 见 classic）；
     no_sqrt2    —— 无穷下降（Fermat）：sqrt(2) 无理性的强归纳机器化；
     fib_3n      —— Fibonacci F_{3n} 偶：机器必须三合一加强归纳命题。 *)

From Stdlib Require Import List Bool Arith Lia Psatz.
Import ListNotations.

(* ---------- 0. 约定 ----------
   机器 nat 从 0 起，书从 1 起：求和类命题两者同值（0 白加），
   基点类命题体现为 Mod PMI。 *)

(* ---------- 1. PMI 两件求和法宝 ---------- *)

Fixpoint sumn (n : nat) : nat :=
  match n with
  | 0 => 0
  | S k => sumn k + S k
  end.

Lemma gauss : forall n, 2 * sumn n = n * S n.
Proof.
  induction n as [|k IH]; simpl; lia.
Qed.

Fixpoint oddsum (n : nat) : nat :=
  match n with
  | 0 => 0
  | S k => oddsum k + (2 * k + 1)
  end.

Lemma oddsum_sq : forall n, oddsum n = n * n.
Proof.
  induction n as [|k IH]; simpl; lia.
Qed.

(* ---------- 2. 递归定义与递归定理：Hanoi ----------
   书的递归定理（引 Henkin 1960）：给基点与递推条款，概念唯一确定。
   类型论里它化身为 Fixpoint 的结构性终止检查。 *)

Fixpoint pow2 (n : nat) : nat :=
  match n with
  | 0 => 1
  | S k => 2 * pow2 k
  end.

Fixpoint hanoi (n : nat) : nat :=
  match n with
  | 0 => 0
  | S k => 2 * hanoi k + 1
  end.

(* 书写 2^n - 1；nat 上减法不友好，改写为 +1 = 2^n 形态 *)
Lemma hanoi_pow : forall n, hanoi n + 1 = pow2 n.
Proof.
  induction n as [|k IH]; simpl; lia.
Qed.

(* ---------- 3. Mod PMI：n^3 < n! for 6 <= n ---------- *)

Fixpoint nfact (n : nat) : nat :=
  match n with
  | 0 => 1
  | S k => nfact k * S k
  end.

Lemma mul_ge_self : forall d k, 1 <= k -> d <= d * k.
Proof.
  intros d k Hk. destruct k as [|j]; [lia|].
  rewrite Nat.mul_succ_r. lia.
Qed.

Lemma sq_le_cube : forall k, 3 <= k -> (S k) * (S k) <= k * k * k.
Proof.
  intros k Hk.
  assert (H3 : 3 * k <= k * k) by (apply Nat.mul_le_mono_r; lia).
  assert (H2 : k * k * 2 <= k * k * k) by (apply Nat.mul_le_mono_l; lia).
  assert (Hexp : (S k) * (S k) = k * k + 2 * k + 1) by ring.
  lia.
Qed.

Theorem nat3_fact : forall n, 6 <= n -> n * n * n < nfact n.
Proof.
  induction n as [|k IH]; intros H6; [lia|].
  destruct (le_lt_dec 6 k) as [Hk|Hk];
    [|assert (k = 5) by lia; subst k; simpl; lia].
  assert (IHk : k * k * k < nfact k) by (apply IH; lia).
  assert (Hstep : nfact (S k) = S k * nfact k)
    by (simpl; rewrite Nat.mul_comm; reflexivity).
  assert (Hsq : (S k) * (S k) <= k * k * k) by (apply sq_le_cube; lia).
  assert (Hmul : S k * S k * S k < S k * nfact k).
  { apply Nat.le_lt_trans with (m := (k * k * k) * S k).
    - apply Nat.mul_le_mono_r. exact Hsq.
    - nia. }
  rewrite Hstep. exact Hmul.
Qed.

(* ---------- 4. 强归纳：从弱归纳推出 ---------- *)

Theorem strong_ind : forall P : nat -> Prop,
  (forall n, (forall m, m < n -> P m) -> P n) -> forall n, P n.
Proof.
  intros P H n.
  assert (Hall : forall k m, m <= k -> P m).
  { induction k as [|k IHk]; intros m Hm; apply H; intros j Hj.
    - lia.
    - apply IHk. lia. }
  apply (Hall n). lia.
Qed.

(* 有界排中：bool 谓词在 [0,n] 上，「有真」与「全假」可归纳构造二择一 *)
Lemma bounded_dec : forall (p : nat -> bool) n,
  (exists d, d <= n /\ p d = true) \/
  (forall d, d <= n -> p d = false).
Proof.
  intros p n. induction n as [|k IH].
  - destruct (p 0) eqn:E.
    + left. exists 0. split; [lia|assumption].
    + right. intros d Hd. assert (d = 0) by lia. subst. assumption.
  - destruct IH as [[d [Hd Hp]]|Hno].
    + left. exists d. split; [lia|assumption].
    + destruct (p (S k)) eqn:E.
      * left. exists (S k). split; [lia|assumption].
      * right. intros d Hd.
        destruct (Nat.eq_dec d (S k)) as [Hde|Hde].
        -- subst. assumption.
        -- apply Hno. lia.
Qed.

(* ---------- 5. 素因子存在（Euclid VII.31，构造路线） ---------- *)

Definition divides (a b : nat) : Prop := exists k, b = a * k.
Definition prime (p : nat) : Prop :=
  2 <= p /\ forall d, divides d p -> d = 1 \/ d = p.

(* 可判定整除测试：在 k <= n 里搜乘法表 *)
Definition dvb (d n : nat) : bool :=
  existsb (fun k => Nat.eqb (d * k) n) (seq 0 (S n)).

Lemma dvb_true : forall d n, dvb d n = true -> divides d n.
Proof.
  intros d n H. unfold dvb in H.
  apply existsb_exists in H. destruct H as [k [Hin Heq]].
  apply in_seq in Hin. apply Nat.eqb_eq in Heq.
  exists k. symmetry. assumption.
Qed.

Lemma divides_dvb : forall d n, 1 <= d -> divides d n -> dvb d n = true.
Proof.
  intros d n Hd [k Hk]. unfold dvb.
  assert (Hkn : k <= n).
  { assert (Hkd : k <= k * d) by (apply (mul_ge_self k d); assumption).
    lia. }
  apply existsb_exists. exists k. split.
  - apply in_seq. lia.
  - apply Nat.eqb_eq. symmetry. assumption.
Qed.

Definition properFac (d n : nat) : bool :=
  andb (Nat.leb 2 d) (andb (Nat.leb (2 * d) n) (dvb d n)).

Theorem prime_divisor : forall n, 2 <= n -> exists p, prime p /\ divides p n.
Proof.
  apply (strong_ind (fun n => 2 <= n -> exists p, prime p /\ divides p n)).
  intros n IH Hn.
  destruct (bounded_dec (fun d => properFac d n) n) as [[d [Hdn Hdq]]|Hno].
  - (* 有真因子 d：2 <= d 且 2d <= n 且 d | n —— 对 d 用强归纳 *)
    unfold properFac in Hdq.
    apply andb_true_iff in Hdq. destruct Hdq as [Hd2 Hrest].
    apply andb_true_iff in Hrest. destruct Hrest as [H2d Hdvb].
    apply Nat.leb_le in Hd2. apply Nat.leb_le in H2d.
    destruct (IH d ltac:(lia) Hd2) as [p [Hp Hpd]].
    exists p. split; [assumption|].
    destruct Hpd as [k1 Hk1]. destruct (dvb_true d n Hdvb) as [k2 Hk2].
    exists (k1 * k2). rewrite Hk1 in Hk2. rewrite Hk2.
    rewrite Nat.mul_assoc. reflexivity.
  - (* 没有真因子：n 自己就是素数 *)
    exists n. split.
    + split; [lia|]. intros d Hd. destruct d as [|[|d']].
      * destruct Hd as [k Hk]. lia.
      * left. reflexivity.
      * destruct Hd as [k Hk]. destruct k as [|[|j]].
        -- lia.
        -- rewrite Nat.mul_1_r in Hk. right. symmetry. exact Hk.
        -- assert (Hdn : S (S d') <= n) by lia.
           specialize (Hno (S (S d')) Hdn).
           assert (Htrue : properFac (S (S d')) n = true).
           { unfold properFac. apply andb_true_iff. split.
             - apply Nat.leb_le. lia.
             - apply andb_true_iff. split.
               + apply Nat.leb_le. lia.
               + apply divides_dvb; [lia|]. exists (S (S j)). assumption. }
           rewrite Htrue in Hno. discriminate.
    + exists 1. rewrite Nat.mul_1_r. reflexivity.
Qed.

(* ---------- 6. 良序原理：构造面与经典面 ---------- *)

Fixpoint firstUp (p : nat -> bool) (n : nat) : option nat :=
  match n with
  | 0 => if p 0 then Some 0 else None
  | S k => match firstUp p k with
           | Some m => Some m
           | None => if p (S k) then Some (S k) else None
           end
  end.

Lemma firstUp_spec : forall p n,
  (forall m, firstUp p n = Some m ->
     m <= n /\ p m = true /\ (forall k, k < m -> p k = false))
  /\ (firstUp p n = None -> forall k, k <= n -> p k = false).
Proof.
  intros p n. induction n as [|k IH]; simpl.
  - destruct (p 0) eqn:E.
    + split.
      * intros m H. injection H as Hm. subst m.
        split; [lia|]. split; [assumption|]. intros j Hj. lia.
      * intros H j Hj. discriminate.
    + split.
      * intros m H. discriminate.
      * intros H j Hj. assert (j = 0) by lia. subst. assumption.
  - destruct IH as [IH1 IH2].
    destruct (firstUp p k) as [e|] eqn:Ef.
    + specialize (IH1 e eq_refl). destruct IH1 as [H1 [H2 H3]].
      split.
      * intros m H. injection H as Hm. subst m.
        split; [lia|]. split; assumption.
      * intros H. discriminate.
    + destruct (p (S k)) eqn:E.
      * split.
        -- intros m H. injection H as Hm. subst m.
           split; [lia|]. split; [assumption|].
           intros j Hj. apply (IH2 eq_refl). lia.
        -- intros H. discriminate.
      * split.
        -- intros m H. discriminate.
        -- intros H j Hj.
           destruct (Nat.lt_ge_cases j k) as [Hlt|Hge].
           ++ apply (IH2 eq_refl); lia.
           ++ destruct (Nat.eq_dec j k) as [Hjk|Hjk].
              ** subst. apply (IH2 eq_refl); lia.
              ** assert (j = S k) by lia. subst. assumption.
Qed.

(* 良序原理（可判定版）：零公理，线性搜索 *)
Theorem wop_bool : forall (p : nat -> bool) n,
  p n = true ->
  exists m, m <= n /\ p m = true /\ (forall k, k < m -> p k = false).
Proof.
  intros p n Hn. destruct (firstUp_spec p n) as [H1 _].
  destruct (firstUp p n) as [m0|] eqn:E.
  - destruct (H1 m0 eq_refl) as [H2 [H3 H4]].
    exists m0. tauto.
  - exfalso. destruct (firstUp_spec p n) as [_ H2].
    specialize (H2 E n (Nat.le_refl n)). congruence.
Qed.

(* 良序原理（任意 Prop 版）：书 §3.2.4 的论证——反设无最小元，
   强归纳证明每个 n 都不在 S 里，与非空矛盾。反设一步是经典；
   Print Assumptions 会如实记账 classic。 *)
From Stdlib Require Import Classical.

Theorem wop_classic : forall S : nat -> Prop,
  (exists n, S n) ->
  exists m, S m /\ (forall k, S k -> m <= k).
Proof.
  intros S [n Hn].
  destruct (classic (exists m, S m /\ (forall k, S k -> m <= k))) as [H|H].
  - assumption.
  - exfalso.
    assert (Hall : forall j, ~ S j).
    { apply (strong_ind (fun j => ~ S j)). intros j IHj HjS.
      apply H. exists j. split; [assumption|].
      intros k Hk. destruct (le_lt_dec j k) as [Hle|Hlt].
      - assumption.
      - exfalso. apply (IHj k Hlt). assumption. }
    apply (Hall n). assumption.
Qed.

(* ---------- 7. 无穷下降：sqrt(2) 无理性 ---------- *)

Lemma sq_even : forall p c, p * p = 2 * c -> exists m, p = 2 * m.
Proof.
  intros p c H. destruct (Nat.Even_or_Odd p) as [[m Hm]|[m Hm]].
  - exists m. assumption.
  - exfalso. rewrite Hm in H.
    replace ((2 * m + 1) * (2 * m + 1)) with (2 * (2 * m * m + 2 * m) + 1)
      in H by ring.
    lia.
Qed.

Theorem no_sqrt2 : forall q p, q <> 0 -> p * p <> 2 * q * q.
Proof.
  apply (strong_ind (fun q => forall p, q <> 0 -> p * p <> 2 * q * q)).
  intros q IH p0 Hq0 Hbad.
  destruct (Nat.Even_or_Odd p0) as [[r Hr]|[r Hr]].
  - (* p 偶：p = 2r *)
    rewrite Hr in Hbad.
    replace ((2 * r) * (2 * r)) with (4 * (r * r)) in Hbad by ring.
    destruct (Nat.Even_or_Odd q) as [[s Hs]|[s Hs]].
    + (* q 偶：q = 2s，得 r*r = 2*(s*s)，s < q，无穷下降 *)
      rewrite Hs in Hbad.
      replace (2 * (2 * s) * (2 * s)) with (8 * (s * s)) in Hbad by ring.
      exfalso. apply (IH s ltac:(lia) r ltac:(lia)).
      replace (2 * s * s) with (2 * (s * s)) by ring. lia.
    + (* q 奇：偶 = 2*奇^2 的奇偶矛盾 *)
      exfalso.
      rewrite Hs in Hbad.
      replace (2 * (2 * s + 1) * (2 * s + 1))
        with (2 * (2 * (2 * s * s + 2 * s) + 1)) in Hbad by ring.
      lia.
  - (* p 奇：奇^2 奇，不等于偶数 2*q*q *)
    exfalso. rewrite Hr in Hbad.
    replace ((2 * r + 1) * (2 * r + 1))
      with (2 * (2 * r * r + 2 * r) + 1) in Hbad by ring.
    lia.
Qed.

(* ---------- 8. Fibonacci：加强归纳命题 ---------- *)

Fixpoint fib (n : nat) : nat :=
  match n with
  | 0 => 0
  | S m => match m with
           | 0 => 1
           | S k => fib m + fib k
           end
  end.

Lemma fib_step : forall n, fib (n + 3) = fib (n + 2) + fib (n + 1).
Proof.
  intros n.
  replace (n + 3) with (S (S (n + 1))) by lia.
  replace (n + 2) with (S (n + 1)) by lia.
  reflexivity.
Qed.

Definition EvenN (n : nat) : Prop := exists a, n = 2 * a.
Definition OddN (n : nat) : Prop := exists a, n = 2 * a + 1.

(* 书只证 F_{3n} 偶；机器必须三合一（偶、奇、奇）一起归纳 *)
Theorem fib_triple : forall n,
  EvenN (fib (3 * n)) /\ OddN (fib (3 * n + 1)) /\ OddN (fib (3 * n + 2)).
Proof.
  unfold EvenN, OddN.
  induction n as [|k IH].
  - simpl. repeat split; exists 0; lia.
  - destruct IH as [[a Ha] [[b Hb] [c Hc]]].
    rewrite Nat.mul_succ_r.
    assert (He3 : fib (3 * k + 3) = 2 * (c + b + 1)).
    { rewrite fib_step. lia. }
    assert (Ho4 : exists d, fib (3 * k + 3 + 1) = 2 * d + 1).
    { replace (3 * k + 3 + 1) with ((3 * k + 1) + 3) by lia.
      rewrite fib_step.
      replace (3 * k + 1 + 2) with (3 * k + 3) by lia.
      replace (3 * k + 1 + 1) with (3 * k + 2) by lia.
      exists (c + b + 1 + c). lia. }
    assert (Ho5 : exists d, fib (3 * k + 3 + 2) = 2 * d + 1).
    { replace (3 * k + 3 + 2) with ((3 * k + 2) + 3) by lia.
      rewrite fib_step.
      replace (3 * k + 2 + 2) with (3 * k + 3 + 1) by lia.
      replace (3 * k + 2 + 1) with (3 * k + 3) by lia.
      destruct Ho4 as [d Hd]. exists (d + c + b + 1). lia. }
    split; [exists (c + b + 1); exact He3|].
    split.
    + exact Ho4.
    + exact Ho5.
Qed.

Theorem fib_3n : forall n, exists a, fib (3 * n) = 2 * a.
Proof.
  intros n. destruct (fib_triple n) as [[a Ha] _].
  exists a. exact Ha.
Qed.

(* ---------- 9. 冒烟与账本 ---------- *)

Compute (sumn 100, oddsum 7, hanoi 5, pow2 6).
Compute (map fib (seq 0 10)).
(* 60 的最小素因子：线性搜索首真元即「良序」的计算面 *)
Compute (firstUp (fun d => properFac d 60) 60).
Compute (firstUp (fun d => properFac d 91) 91).

Print Assumptions gauss.
Print Assumptions prime_divisor.
Print Assumptions wop_bool.
Print Assumptions wop_classic.
Print Assumptions no_sqrt2.
