(* ex30_totalcorrect —— 完全正确性：变体方法与最小和段（H&R §4.4 / §4.3.3）

   对书：Huth&Ryan §4.2.3（部分/完全区分）/ §4.4（变体与 total-while）
              / §4.3.3（minimal-sum 案例）

   设计：
   - hoareT P c Q := 前件成立 ⟹ 存在终止态且满足后件（终止内建）；
   - hoareT_while_layered（total-while 式 4.15 的机器版）：变体 V
     每轮严格递减——对变体上界强归纳；
   - countdown_total：countdown 的完全正确性（变体 = s x）；
   - minsum 构件：H&R 招牌案例的教学版（Kadane 最小化扫描的
     min 吸收律三引理）。完整数组归纳正确性登记边界（正文）。 *)

From Stdlib Require Import List Bool Arith Lia.
Import ListNotations.

(* ---------- while 语言（沿 25 章骨架） ---------- *)

Definition state := nat -> nat.

Definition upd (s : state) (x v : nat) : state :=
  fun m => if Nat.eqb m x then v else s m.

Inductive cmd : Type :=
| cskip : cmd
| cass : nat -> (state -> nat) -> cmd
| cseq : cmd -> cmd -> cmd
| cwhile : (state -> bool) -> cmd -> cmd.

Inductive exec : cmd -> state -> state -> Prop :=
| eskip : forall s, exec cskip s s
| eass : forall x f s, exec (cass x f) s (upd s x (f s))
| eseq : forall c1 c2 s1 s2 s3,
    exec c1 s1 s2 -> exec c2 s2 s3 -> exec (cseq c1 c2) s1 s3
| ewhile_true : forall b c s1 s2 s3,
    b s1 = true -> exec c s1 s2 -> exec (cwhile b c) s2 s3 ->
    exec (cwhile b c) s1 s3
| ewhile_false : forall b c s,
    b s = false -> exec (cwhile b c) s s.

(* ---------- 完全正确性：终止内建 ---------- *)

Definition hoareT (P : state -> Prop) (c : cmd) (Q : state -> Prop) : Prop :=
  forall s1, P s1 -> exists s2, exec c s1 s2 /\ Q s2.

(* ---------- 旗舰：total-while（变体版 while 规则，式 4.15 分层形态） ---------- *)

(* 分层前提：体自身完全正确，且每轮变体降到当前值 n 之下——
   H&R 式 4.15 的 E0（逻辑变量冻结本轮变体初值）在此参数化为 n *)
Theorem hoareT_while_layered : forall P b c V,
  (forall s, P s -> b s = true -> V s > 0) ->
  (forall n, hoareT (fun s => P s /\ b s = true /\ V s = n)
                    c (fun s => P s /\ V s < n)) ->
  hoareT P (cwhile b c) (fun s => P s /\ b s = false).
Proof.
  intros P b c V Hpos Hbody.
  assert (Hmain : forall n s1, P s1 -> V s1 <= n ->
    exists s2, exec (cwhile b c) s1 s2 /\ P s2 /\ b s2 = false).
  { induction n as [|n IH]; intros s1 HP HV.
    - destruct (b s1) eqn:Eb.
      + specialize (Hpos s1 HP Eb).
        assert (V s1 = 0) by lia. lia.
      + exists s1. split; [apply ewhile_false; exact Eb|].
        split; [exact HP | exact Eb].
    - destruct (b s1) eqn:Eb.
      + assert (Hpre : P s1 /\ b s1 = true /\ V s1 = V s1).
        { split; [exact HP|]. split; [exact Eb|reflexivity]. }
        destruct (Hbody (V s1) s1 Hpre) as [s2 [Hex Hstep]].
        destruct Hstep as [HP2 HV2].
        destruct (IH s2 HP2) as [s3 [Hex2 [HP3 Eb3]]].
        { lia. }
        exists s3. split.
        { apply ewhile_true with (s2 := s2);
            [exact Eb | exact Hex | exact Hex2]. }
        split; [exact HP3 | exact Eb3].
      + exists s1. split; [apply ewhile_false; exact Eb|].
        split; [exact HP | exact Eb].
  }
  intros s1 HP. apply (Hmain (V s1) s1 HP (Nat.le_refl _)).
Qed.

(* ---------- countdown 的完全正确性 ---------- *)

Definition countdownC (x y : nat) : cmd :=
  cwhile (fun s => negb (Nat.eqb (s x) 0))
         (cseq (cass x (fun s => s x - 1)) (cass y (fun s => s y + 1))).

(* 变体 = s x；不变式 = s x + s y = C；别名前提 x ≠ y *)
Theorem countdown_total : forall x y C s1,
  x <> y ->
  s1 x + s1 y = C ->
  exists s2, exec (countdownC x y) s1 s2 /\ s2 x + s2 y = C /\ s2 x = 0.
Proof.
  intros x y C s1 Hxy Hinv.
  assert (Hpos : forall s, s x + s y = C ->
                        negb (Nat.eqb (s x) 0) = true -> s x > 0).
  { intros s HPs Hbs. unfold negb in Hbs.
    apply negb_true_iff, Nat.eqb_neq in Hbs. lia. }
  assert (Hbody : forall n,
    hoareT (fun s => s x + s y = C /\ negb (Nat.eqb (s x) 0) = true
                       /\ s x = n)
           (cseq (cass x (fun s => s x - 1)) (cass y (fun s => s y + 1)))
           (fun s => s x + s y = C /\ s x < n)).
  { intros n s [HPs [Hbs Hns]].
    assert (Hx0 : s x <> 0).
    { unfold negb in Hbs. destruct (s x) as [|v].
      - rewrite Nat.eqb_refl in Hbs. discriminate.
      - discriminate. }
    (* y 赋值的求值态是 x 更新后的状态——函数读的是 upd 态的 y *)
    exists (upd (upd s x (s x - 1)) y (upd s x (s x - 1) y + 1)).
    split.
    - apply eseq with (s2 := upd s x (s x - 1)); [apply eass | apply eass].
    - split.
      + (* 不变式：x-1 与 y+1 的和守恒（x≠y 防别名） *)
        assert (Hx : upd (upd s x (s x - 1)) y
                        (upd s x (s x - 1) y + 1) x = s x - 1).
        { unfold upd. rewrite Nat.eqb_refl.
          destruct (Nat.eqb x y) eqn:Exy.
          - apply Nat.eqb_eq in Exy. contradiction.
          - reflexivity. }
        assert (Hyr : upd s x (s x - 1) y = s y).
        { unfold upd. destruct (Nat.eqb y x) eqn:Eyx.
          - apply Nat.eqb_eq in Eyx. congruence.
          - reflexivity. }
        assert (Hy : upd (upd s x (s x - 1)) y
                        (upd s x (s x - 1) y + 1) y = s y + 1).
        { unfold upd at 1. destruct (Nat.eqb y x) eqn:Eyx.
          - apply Nat.eqb_eq in Eyx. congruence.
          - rewrite Nat.eqb_refl, Hyr. reflexivity. }
        lia.
      + (* 变体严格下降 *)
        assert (Hx : upd (upd s x (s x - 1)) y
                        (upd s x (s x - 1) y + 1) x = s x - 1).
        { unfold upd. rewrite Nat.eqb_refl.
          destruct (Nat.eqb x y) eqn:Exy.
          - apply Nat.eqb_eq in Exy. contradiction.
          - reflexivity. }
        lia. }
  destruct (hoareT_while_layered _ _ _ _ Hpos Hbody s1 Hinv)
    as [s2 [Hex [HP Hb]]].
  exists s2. split; [exact Hex|]. split; [exact HP|].
  unfold negb in Hb. apply negb_false_iff, Nat.eqb_eq in Hb. exact Hb.
Qed.

(* ---------- minsum 构件：H&R §4.3.3 的教学版 ---------- *)

(* 数组 = 只读函数 a : nat -> nat。Kadane 最小化扫描：
   s := min (s + a[k]) (a[k]) ——「延伸前段」与「重开新段」取小；
   m := min m s ——全程最小。 *)

Definition amin (u v : nat) : nat := if Nat.leb u v then u else v.

Lemma amin_le_left : forall u v, amin u v <= u.
Proof.
  intros u v. unfold amin. destruct (Nat.leb u v) eqn:E.
  - apply Nat.leb_le in E. lia.
  - apply Nat.leb_gt in E. lia.
Qed.

Lemma amin_le_right : forall u v, amin u v <= v.
Proof.
  intros u v. unfold amin. destruct (Nat.leb u v) eqn:E.
  - apply Nat.leb_le in E. lia.
  - apply Nat.leb_gt in E. lia.
Qed.

Lemma amin_min : forall u v w, w <= u -> w <= v -> w <= amin u v.
Proof.
  intros u v w H1 H2. unfold amin. destruct (Nat.leb u v); lia.
Qed.

(* 现场演示：常值数组上的单轮语义（Kadane 心跳） *)
Example minsum_sem : amin (amin 1 1 + 1) 1 = 1.
Proof. reflexivity. Qed.

(* 吸收律：min 已是最小时延伸不减——「重开」决策的语义根据 *)
Example minsum_absorb : forall u, u <= 1 -> amin (u + 1) 1 = 1.
Proof.
  intros u H. unfold amin. destruct (Nat.leb (u + 1) 1) eqn:E.
  - apply Nat.leb_le in E. lia.
  - apply Nat.leb_gt in E. lia.
Qed.

Print Assumptions hoareT_while_layered.  (* Closed *)
Print Assumptions countdown_total.        (* Closed *)
