(* 第 88 章 · L 中的组合原理与弱紧基数（冯琦第二卷 §2.1.4-2.1.5）。
   两件样品：Jensen 苏斯林树构造的封口引擎（定理 2.12 性质 (4)——
   被封口的反链在一切更高层保持极大）与封口构造的计算验证。 *)
Require Import List Arith Bool Lia.
Import ListNotations.

(* ---------- 一、封口引擎（定理 2.12 性质 (4)） ---------- *)

(* 节点是布尔串；树序是前缀延拓 a ⊑ t ↔ t = a ++ r。 *)
Definition sealed (A T : list (list bool)) : Prop :=
  forall t, In t T -> exists a, In a A /\ exists (r : list bool), t = a ++ r.

Lemma prefix_trans : forall a s t,
  (exists (r : list bool), s = a ++ r) -> (exists (r : list bool), t = s ++ r) -> exists (r : list bool), t = a ++ r.
Proof.
  intros a s t [r1 Hs] [r2 Ht].
  exists (r1 ++ r2).
  rewrite Ht, Hs, app_assoc. reflexivity.
Qed.

(* 定理 2.12 性质 (4)：封口一旦完成便永久保持。
   封口层每个节点延拓 A 的成员；此后每层节点延拓前层节点，
   前缀关系传递，于是 A 在所有更高层保持极大。 *)
Theorem sealed_persists : forall (A : list (list bool)) (T : nat -> list (list bool)) k,
  sealed A (T (S k)) ->
  (forall n, k <= n -> forall t, In t (T (S n)) ->
     exists (s : list bool), In s (T n) /\ exists (r : list bool), t = s ++ r) ->
  forall n, S k <= n -> sealed A (T n).
Proof.
  intros A T k h0 hstep n.
  induction n as [|n IH]; intros hn.
  - lia.
  - destruct (Nat.eq_dec (S n) (S k)) as [heq|hne].
    + apply Nat.succ_inj in heq. subst n. exact h0.
    + assert (hle : S k <= n) by lia.
      assert (hk : k <= n) by lia.
      intros t Ht.
      destruct (hstep n hk t Ht) as [s [Hs [r Hr]]].
      destruct (IH hle s Hs) as [a [Ha [r' Hs2]]].
      exists a. split; [exact Ha|].
      apply (prefix_trans a s t).
      * exists r'; exact Hs2.
      * exists r; exact Hr.
Qed.

(* ---------- 二、封口构造的计算样品 ---------- *)

Fixpoint prefb (a t : list bool) : bool :=
  match a, t with
  | [], _ => true
  | x :: a', y :: t' => andb (eqb x y) (prefb a' t')
  | _ :: _, [] => false
  end.

Lemma prefb_app : forall a l l', prefb a l = true -> prefb a (l ++ l') = true.
Proof.
  induction a as [|x a' IHa]; intros l l' H.
  - reflexivity.
  - destruct l as [|y ls]; simpl in H |- *.
    + discriminate H.
    + apply andb_true_iff in H as [Hxy Ha'].
      rewrite Hxy, (IHa ls l' Ha'). reflexivity.
Qed.

Definition extends_some (A : list (list bool)) (t : list bool) : bool :=
  existsb (fun a => prefb a t) A.

(* 正常分叉的通用递归（守卫安全：只在 m 上递归）。 *)
Fixpoint Tfrom (l : list (list bool)) (m : nat) : list (list bool) :=
  match m with
  | 0 => l
  | S m' => flat_map (fun t => [t ++ [true]; t ++ [false]]) (Tfrom l m')
  end.

(* 第 2 层封口单点反链 {[true;true]}：延拓一层后按 A 过滤。 *)
Definition sealSeed : list (list bool) :=
  filter (extends_some [[true; true]])
         (flat_map (fun t => [t ++ [true]; t ++ [false]]) [[true]; [false]]).

Definition Tdemo (n : nat) : list (list bool) :=
  match n with
  | 0 => [[]]
  | 1 => [[true]; [false]]
  | S m => Tfrom sealSeed m
  end.

(* 封口层非空：[true;true;true] 是 [true;true] 的延拓。 *)
Lemma sealSeed_nonempty : In [true; true] sealSeed.
Proof.
  unfold sealSeed. apply filter_In. split.
  - apply in_flat_map. exists [true].
    split; [left; reflexivity|left; reflexivity].
  - unfold extends_some; simpl; reflexivity.
Qed.

(* 延拓保前缀。 *)
Lemma extends_children : forall A u, extends_some A u = true ->
  extends_some A (u ++ [true]) = true /\ extends_some A (u ++ [false]) = true.
Proof.
  intros A u H. unfold extends_some in *.
  apply existsb_exists in H as [a [Ha Hpre]].
  split.
  - apply existsb_exists. exists a.
    split; [exact Ha | apply prefb_app; exact Hpre].
  - apply existsb_exists. exists a.
    split; [exact Ha | apply prefb_app; exact Hpre].
Qed.

(* 传播引理：封口层之上正常分叉仍封口。 *)
Lemma sealed_from : forall m A l,
  (forall t, In t l -> extends_some A t = true) ->
  forall t, In t (Tfrom l m) -> extends_some A t = true.
Proof.
  induction m as [|m IHm]; intros A l Hl t Ht.
  - simpl in Ht. apply Hl; exact Ht.
  - simpl in Ht. apply in_flat_map in Ht as [u [Hu Hc]].
    simpl in Hc. destruct Hc as [Hc|[Hc|[]]]; rewrite <- Hc.
    + destruct (extends_children A u (IHm A l Hl u Hu)) as [H1 _]; exact H1.
    + destruct (extends_children A u (IHm A l Hl u Hu)) as [_ H1]; exact H1.
Qed.

(* 定理 2.12 性质 (4) 的计算验证：从第 2 层起每一层都被
   {[true;true]} 封口。 *)
Theorem Tdemo_sealed_all : forall n, 2 <= n ->
  forall t, In t (Tdemo n) -> extends_some [[true; true]] t = true.
Proof.
  intros n hn t Ht.
  destruct n as [|[|m]]; [lia|lia|].
  change (In t (Tfrom sealSeed (S m))) in Ht.
  apply (sealed_from (S m) [[true; true]] sealSeed); [|exact Ht].
  intros u Hu. unfold sealSeed in Hu.
  apply filter_In in Hu as [_ Hb]. exact Hb.
Qed.

(* 层层封口之后的规模：封口剪枝只保留一支，此后每层恰一个节点。 *)
Compute map (fun n => length (Tdemo n)) (seq 0 6).
