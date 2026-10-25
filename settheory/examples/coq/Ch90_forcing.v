(* 第 90 章 · 力迫基本理论与 CH/AC 独立性（冯琦第二卷 §3.1-3.3）。
   三件样品：定理 3.1 的相遇链递归引擎；条件决定比特与前缀保持
   （真值引理的原子形态）；泛型对角避让与 Fn(n,2) 反链的填充单射。 *)
Require Import List Arith Bool Lia.
Import ListNotations.

(* ---------- 一、稠密相遇链（定理 3.1 的递归引擎） ---------- *)

(* q 延拓 p（更强条件）：q = p ++ r *)
Definition ext (p q : list bool) : Prop := exists r, q = p ++ r.

(* 带选择函数的稠密集：dext 把任何条件延拓成 Dpred 的成员。
   真正的稠密集 ∀p∃q(q≤p∧q∈D) 非构造地给见证；可数模型里
   枚举后逐个选见证——这正是定理 3.1 的证明。 *)
Record Dense := mkDense {
  Dpred : list bool -> Prop;
  dext : list bool -> list bool;
  is_ext : forall p, ext p (dext p);
  hits : forall p, Dpred (dext p)
}.

Definition trivial_dense : Dense.
Proof.
  refine (mkDense (fun _ => True) (fun p => p) _ _).
  - intros p. exists []. symmetry. apply app_nil_r.
  - intros _. exact I.
Defined.

(* 从条件 p 出发逐集延长：相邻两项由 is_ext 见证 *)
Fixpoint chain_from (p : list bool) (ds : list Dense) : list (list bool) :=
  match ds with
  | [] => [p]
  | d :: rest => p :: chain_from (dext d p) rest
  end.

Definition chain (ds : list Dense) : list (list bool) := chain_from [] ds.

Lemma chain_head : forall p ds, nth 0 (chain_from p ds) [] = p.
Proof. intros p [| d rest]; reflexivity. Qed.

(* 链上相邻条件逐层延拓：p_{j+1} 强于 p_j *)
Theorem chain_nested : forall (ds : list Dense) (p : list bool) j,
  S j < length (chain_from p ds) ->
  ext (nth j (chain_from p ds) []) (nth (S j) (chain_from p ds) []).
Proof.
  induction ds as [| d rest ih]; intros p j Hlen.
  - simpl in Hlen; lia.
  - destruct j as [| j'].
    + simpl. rewrite chain_head. apply is_ext.
    + simpl. apply (ih (dext d p) j'). simpl in Hlen. lia.
Qed.

(* 第 k 个稠密集在链的第 k+1 个节点处被相遇 *)
Theorem chain_meets : forall (ds : list Dense) (p : list bool) k,
  k < length ds ->
  Dpred (nth k ds trivial_dense) (nth (S k) (chain_from p ds) []).
Proof.
  induction ds as [| d rest ih]; intros p k Hk.
  - simpl in Hk; lia.
  - destruct k as [| k'].
    + simpl. rewrite chain_head. apply hits.
    + simpl. apply (ih (dext d p) k'). simpl in Hk. lia.
Qed.

(* ---------- 二、决定稠密集与力迫的原子形态 ---------- *)

Definition decider (n : nat) (p : list bool) : list bool :=
  p ++ repeat false (S n - length p).

Lemma decider_ext : forall n p, ext p (decider n p).
Proof.
  intros n p. unfold decider, ext.
  exists (repeat false (S n - length p)). reflexivity.
Qed.

Lemma len_app : forall (A : Type) (l1 l2 : list A),
  length (l1 ++ l2) = length l1 + length l2.
Proof. induction l1; simpl; auto. Qed.

Lemma len_repeat : forall (A : Type) (x : A) n, length (repeat x n) = n.
Proof. induction n; simpl; auto. Qed.

Lemma decider_decides : forall n p, n < length (decider n p).
Proof.
  intros n p. unfold decider.
  rewrite len_app, len_repeat.
  destruct (le_lt_dec (length p) n); lia.
Qed.

(* 尚未决定时补的都是 0：第 n 位被力迫为 0 *)
Lemma nth_repeat_false : forall k m, m < k -> nth m (repeat false k) false = false.
Proof.
  induction k as [| k ih]; intros m Hm.
  - inversion Hm.
  - destruct m as [| m']; simpl.
    + reflexivity.
    + apply ih. lia.
Qed.

Lemma nth_app_right : forall (p t : list bool) n, length p <= n ->
  nth n (p ++ t) false = nth (n - length p) t false.
Proof.
  induction p as [| a p' ih]; intros t n Hle.
  - simpl. rewrite Nat.sub_0_r. reflexivity.
  - destruct n as [| n']; simpl in *.
    + inversion Hle.
    + apply ih. lia.
Qed.

Lemma decider_fresh : forall n p, length p <= n ->
  nth n (decider n p) false = false.
Proof.
  intros n p Hle. unfold decider.
  rewrite nth_app_right by exact Hle.
  apply nth_repeat_false. lia.
Qed.

(* 前缀保持已决定的比特：p ⊩ g(n)=b ⇒ 任何含 p 的泛型都如此 *)
Lemma nth_app_left : forall (p t : list bool) n, n < length p ->
  nth n (p ++ t) false = nth n p false.
Proof.
  induction p as [| a p' ih]; intros t n Hn.
  - inversion Hn.
  - destruct n as [| n'].
    + reflexivity.
    + simpl in Hn |- *. apply ih. lia.
Qed.

Theorem forced_bit : forall p g i, ext p g -> i < length p ->
  nth i g false = nth i p false.
Proof.
  intros p g i [r Hr] Hi. subst g. apply nth_app_left. exact Hi.
Qed.

(* ---------- 泛型对角避让（例 3.3 的对角稠密集，有限版） ---------- *)

Definition flip (b : list bool) (k : nat) : bool := negb (nth k b false).

Fixpoint gen_build_from (k : nat) (bs : list (list bool)) : list bool :=
  match bs with
  | [] => []
  | b :: rest => flip b k :: gen_build_from (S k) rest
  end.

Lemma gen_bit : forall bs k0 j, j < length bs ->
  nth j (gen_build_from k0 bs) false = flip (nth j bs []) (k0 + j).
Proof.
  induction bs as [| b rest ih]; intros k0 j Hj.
  - inversion Hj.
  - destruct j as [| j']; simpl in Hj |- *.
    + rewrite Nat.add_0_r. reflexivity.
    + rewrite (ih (S k0) j') by lia.
      replace (k0 + S j') with (S k0 + j') by lia. reflexivity.
Qed.

Theorem generic_avoids : forall bs k, k < length bs ->
  nth k (gen_build_from 0 bs) false <> nth k (nth k bs []) false.
Proof.
  intros bs k Hk. rewrite gen_bit by exact Hk.
  simpl (0 + k). unfold flip.
  destruct (nth k (nth k bs []) false); simpl; discriminate.
Qed.

(* ---------- 三、Fn(n,2) 反链的填充单射（ccc 有限引擎） ---------- *)

Fixpoint agree (f g : list (option bool)) : bool :=
  match f, g with
  | [], _ => true
  | _, [] => true
  | None :: f', _ :: g' => agree f' g'
  | Some b :: f', None :: g' => agree f' g'
  | Some b :: f', Some c :: g' => andb (Bool.eqb b c) (agree f' g')
  end.

Definition compat (f g : list (option bool)) : Prop := agree f g = true.

Lemma agree_false_witness : forall f g, agree f g = false ->
  exists i b c, nth_error f i = Some (Some b)
                /\ nth_error g i = Some (Some c) /\ b <> c.
Proof.
  induction f as [| o f' ih]; intros g H.
  - simpl in H; discriminate.
  - destruct o as [b|].
    + destruct g as [| q g']; simpl in H.
      * discriminate.
      * destruct q as [c|].
        -- cbn [agree] in H.
           apply andb_false_iff in H. destruct H as [He | Hr].
           ++ apply eqb_false_iff in He.
              exists 0, b, c. simpl.
              split; [reflexivity |]. split; [reflexivity |]. exact He.
           ++ destruct (ih g' Hr) as [i [b0 [c0 [Hf [Hg Hne]]]]].
              exists (S i), b0, c0. simpl. auto.
        -- cbn [agree] in H.
           destruct (ih g' H) as [i [b0 [c0 [Hf [Hg Hne]]]]].
           exists (S i), b0, c0. simpl. auto.
    + destruct g as [| q g']; simpl in H.
      * discriminate.
      * destruct (ih g' H) as [i [b0 [c0 [Hf [Hg Hne]]]]].
        exists (S i), b0, c0. simpl. auto.
Qed.

Definition conv (o : option bool) : bool :=
  match o with Some b => b | None => false end.

Definition fill0 (f : list (option bool)) : list bool := map conv f.

Lemma nth_map_conv : forall (f : list (option bool)) i,
  nth i (map conv f) false = conv (nth i f None).
Proof.
  induction f as [| o f' ih]; intros [| i]; simpl; try reflexivity; apply ih.
Qed.

Lemma nth_of_nth_error : forall (f : list (option bool)) i o,
  nth_error f i = Some o -> nth i f None = o.
Proof.
  induction f as [| o' f' ih]; intros [| i] o H; simpl in *; try discriminate.
  - inversion H; reflexivity.
  - f_equal. apply ih. exact H.
Qed.

(* 相冲 ⇒ 零填充全函数不同：反链经零填充单射进全函数空间 *)
Theorem incompatible_fill_diff : forall f g, ~ compat f g -> fill0 f <> fill0 g.
Proof.
  intros f g Hnc Heq.
  assert (Hf' : agree f g = false).
  { destruct (agree f g) eqn:E.
    - exfalso. apply Hnc. exact E.
    - reflexivity. }
  destruct (agree_false_witness f g Hf') as [i [b [c [Hf [Hg Hne]]]]].
  assert (H1 : nth i (fill0 f) false = b).
  { unfold fill0. rewrite nth_map_conv.
    rewrite (nth_of_nth_error _ _ _ Hf). reflexivity. }
  assert (H2 : nth i (fill0 g) false = c).
  { unfold fill0. rewrite nth_map_conv.
    rewrite (nth_of_nth_error _ _ _ Hg). reflexivity. }
  rewrite Heq in H1. rewrite H1 in H2. contradiction.
Qed.

(* ---------- 演示 ---------- *)

Definition dense_decide (n : nat) : Dense :=
  mkDense (fun p => n < length p) (decider n) (decider_ext n) (decider_decides n).

(* 相遇链：空条件逐层决定第 0/1/2 位 *)
Compute map (@length bool) (chain_from [] [dense_decide 0; dense_decide 1; dense_decide 2]).
(* = [0; 1; 2; 3] *)

(* 泛型对角避让：与第 k 个地基分支恰在第 k 位不同 *)
Compute gen_build_from 0 [[true]; [false; true]; [true; false; false]].
(* = [false; false; true] *)

(* 相冲条件的零填充不同 *)
Compute (agree [Some true; None] [Some false; Some true],
         fill0 [Some true; None], fill0 [Some false; Some true]).
(* = (false, [true; false], [false; true]) *)
