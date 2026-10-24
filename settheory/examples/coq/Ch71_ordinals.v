(* 第 71 章：序数与累积层次（冯琦 §1.7）
   有限序数段上的内禀三条件：Φ₁ 三择一（可比较性 1.50 的有限截面）、
   Φ₂ 最小元（定理 1.51 的有限版）、RK = 尺寸恒等（命题 1.21）。 *)
From Coq Require Import List Bool Arith Lia.
Import ListNotations.

(* ---------- 有限冯诺伊曼序数：0 与后继（避免互递归——8.20 的
   guard 拒绝跨类型互递归，见 Ch70 的实测） ---------- *)

Inductive vonn : Set :=
| v0
| vs (n : vonn).

Fixpoint vonn_eq (a b : vonn) : bool :=
  match a, b with
  | v0, v0 => true
  | vs x, vs y => vonn_eq x y
  | _, _ => false
  end.

Fixpoint vsize (n : vonn) : nat :=
  match n with
  | v0 => 0
  | vs m => S (vsize m)
  end.

(* 成员即"更小"：a ∈ b+1 ⟺ a = b ∨ a ∈ b（冯诺伊曼数字的书页定义；
   只递归于第二变元——与 68 章加法同一风格） *)
Fixpoint vmem (a b : vonn) : bool :=
  match b with
  | v0 => false
  | vs b' => orb (vonn_eq a b') (vmem a b')
  end.

(* ---------- 结构相等 ↔ 尺寸相等（有限序数 = 自然数的镜像） ---------- *)

Lemma vonn_eq_size : forall a b, vonn_eq a b = true -> vsize a = vsize b.
Proof.
  induction a as [|a IHa]; intros [|b] H; simpl in *; try discriminate.
  - reflexivity.
  - rewrite (IHa b H). reflexivity.
Qed.

Lemma vsize_inj : forall a b, vsize a = vsize b -> vonn_eq a b = true.
Proof.
  induction a as [|a IHa]; intros [|b] H; simpl in *; try discriminate.
  - reflexivity.
  - f_equal. apply IHa. lia.
Qed.

Lemma vonn_eq_refl : forall a, vonn_eq a a = true.
Proof. induction a as [|a IHa]; simpl; auto. Qed.

(* ---------- Φ₁ 的内核：成员 ⟺ 尺寸更小 ---------- *)

Lemma vmem_lt : forall b a, vmem a b = true -> vsize a < vsize b.
Proof.
  induction b as [|b IHb]; intros a H; simpl in H; [discriminate|].
  apply orb_true_iff in H. destruct H as [H | H].
  - apply vonn_eq_size in H. simpl. lia.
  - specialize (IHb _ H). simpl. lia.
Qed.

Lemma vmem_ge : forall b a, vsize a < vsize b -> vmem a b = true.
Proof.
  induction b as [|b IHb]; intros a H; simpl in *; [lia|].
  assert (Hlt : vsize a < vsize b \/ vsize a = vsize b) by lia.
  destruct Hlt as [Hlt | Heq].
  - rewrite (IHb _ Hlt), orb_true_r. reflexivity.
  - rewrite (vsize_inj a b Heq), orb_true_l. reflexivity.
Qed.

(* ---------- 定理 1.50（可比较性）的有限截面 ---------- *)

Theorem trichotomy : forall a b,
  (vmem a b = true /\ vmem b a = false) \/
  (a = b) \/
  (vmem b a = true /\ vmem a b = false).
Proof.
  intros a b.
  destruct (lt_eq_lt_dec (vsize a) (vsize b)) as [[H | H] | H].
  - left. split; [apply vmem_ge; exact H |].
    destruct (vmem b a) eqn:E; [|reflexivity].
    apply vmem_lt in E. lia.
  - right; left.
    (* 尺寸相等 + 结构有限 ⟹ 相等：vsize 的单射性 *)
    assert (Hab : vonn_eq a b = true) by (apply vsize_inj; exact H).
    clear H. revert b Hab. induction a as [|a IHa]; intros [|b] Hab;
      simpl in Hab; try discriminate.
    + reflexivity.
    + f_equal. apply (IHa b). exact Hab.
  - right; right. split; [apply vmem_ge; exact H |].
    destruct (vmem a b) eqn:E; [|reflexivity].
    apply vmem_lt in E. lia.
Qed.

(* 自反禁令：a ∉ a（Φ₂ 的直接推论——尺寸不小于自身） *)
Theorem vmem_irrefl : forall a, vmem a a = false.
Proof.
  intros a. destruct (vmem a a) eqn:E; [|reflexivity].
  apply vmem_lt in E. lia.
Qed.

(* ---------- Φ₂（定理 1.51 的有限版）：非空列表的 ∈-最小元 ---------- *)

Theorem min_element : forall (l : list vonn), l <> [] ->
  exists m, In m l /\ forall b, In b l -> vmem b m = false.
Proof.
  induction l as [|c rest IH]; intros Hne.
  - contradiction.
  - destruct rest as [|d rest'].
    + exists c. split; [left; reflexivity|].
      intros b [->|Hb]; [apply vmem_irrefl | contradiction].
    + destruct (IH ltac:(discriminate)) as [m [Hm Hmin]].
      destruct (le_gt_dec (vsize c) (vsize m)) as [Hc|Hc].
      * exists c. split; [left; reflexivity|].
        intros b [->|Hb].
        -- apply vmem_irrefl.
        -- destruct (vmem b c) eqn:E; [|reflexivity].
           apply vmem_lt in E.
           pose proof (vmem_ge m b ltac:(lia)) as Hbm.
           specialize (Hmin b Hb). rewrite Hbm in Hmin. discriminate.
      * exists m. split; [right; exact Hm|].
        intros b Hb. destruct Hb as [He | Hb].
        -- subst b. destruct (vmem c m) eqn:E; [|reflexivity].
           apply vmem_lt in E. lia.
        -- apply Hmin; exact Hb.
Qed.

(* ---------- RK：秩 = 尺寸恒等（命题 1.21 的有限版） ---------- *)

(* 有限序数的秩恰是尺寸：RK(v0) = 0、RK(n+1) = RK(n)+1——
   冯诺伊曼数字在秩轴上排成斜率为 1 的直线（书页 RK(n) = n） *)
Example rk_succ : forall n, vsize (vs n) = S (vsize n).
Proof. reflexivity. Qed.

Example chain5 : vsize (vs (vs (vs (vs (vs v0))))) = 5.
Proof. reflexivity. Qed.
