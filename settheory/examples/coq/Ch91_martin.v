(* 第 91 章 · 马丁公理之合理性与迭代力迫（冯琦第二卷 §3.4）。
   四件样品：一步迭代的相容分解（定理 3.14 的组合核心）、
   典型嵌入的完备性半边（引理 3.54(6)）、有限支撑与坐标合并
   （定义 3.36）、Solovay-Tennenbaum 记录函数的 Cantor 配对实现
   （定理 3.18 的 (b) 款）。MA 的 greedy 相遇引擎附演示。 *)
Require Import List Arith Bool Lia.
Import ListNotations.

(* ---------- 一、一步迭代的相容分解（定理 3.14 的组合核心） ---------- *)

Definition ext (p q : list bool) : Prop := exists r, q = p ++ r.

Lemma ext_refl : forall p, ext p p.
Proof. intros p. exists []. rewrite app_nil_r. reflexivity. Qed.

(* 相容：存在公共延长（力迫相容的一般形态） *)
Definition agree (p q : list bool) : Prop := exists r, ext p r /\ ext q r.

(* 迭代条件：第一步与第二步各一个串条件 *)
Definition extPair (x y : list bool * list bool) : Prop :=
  ext (fst x) (fst y) /\ ext (snd x) (snd y).

(* (p,q) 与 (p',q') 相容 ⟺ 两个分量分别相容 *)
Theorem iterAgree_iff : forall x y : list bool * list bool,
  (exists r, extPair x r /\ extPair y r) <->
    (agree (fst x) (fst y) /\ agree (snd x) (snd y)).
Proof.
  intros [p q] [p' q']. split.
  - intros [r [Hx Hy]]. destruct Hx as [h1 h2]. destruct Hy as [h3 h4].
    split.
    + exists (fst r). split; [exact h1 | exact h3].
    + exists (snd r). split; [exact h2 | exact h4].
  - intros [[r1 [e1 e2]] [r2 [e3 e4]]].
    exists (r1, r2). split.
    + split; [exact e1 | exact e3].
    + split; [exact e2 | exact e4].
Qed.

(* ---------- 二、典型嵌入的完备性半边（引理 3.54(6)） ---------- *)

Definition canon (p : list bool) : list bool * list bool := (p, []).

Theorem canon_incompat_iff : forall p p',
  (~ exists r, extPair (canon p) r /\ extPair (canon p') r) <-> ~ agree p p'.
Proof.
  intros p p'. rewrite iterAgree_iff. simpl.
  assert (Hnil : agree (@nil bool) (@nil bool)).
  { exists []. split; apply ext_refl. }
  split; intros H Ha.
  - exact (H (conj Ha Hnil)).
  - exact (H (proj1 Ha)).
Qed.

(* ---------- 三、有限支撑迭代（定义 3.36） ---------- *)

(* 支撑：偏离最大元的坐标个数（递归定义） *)
Fixpoint spt (p : list (option bool)) : nat :=
  match p with
  | [] => 0
  | Some _ :: p' => S (spt p')
  | None :: p' => spt p'
  end.

Lemma spt_le : forall p, spt p <= length p.
Proof.
  induction p as [| a p' IH]; simpl; [reflexivity |].
  destruct a; simpl in *; lia.
Qed.

(* 相容两条件的合并：每个坐标取首先给出决定者 *)
Fixpoint mergeC (p q : list (option bool)) : list (option bool) :=
  match p, q with
  | [], _ => q
  | _, [] => p
  | Some x :: p', _ :: q' => Some x :: mergeC p' q'
  | None :: p', b' :: q' => b' :: mergeC p' q'
  end.

(* 合并保持第一个输入已决定的位 *)
Lemma mergeC_keeps_left : forall p q i a,
  nth_error p i = Some (Some a) -> nth_error (mergeC p q) i = Some (Some a).
Proof.
  induction p as [| o p' ih]; intros q i a H.
  - destruct i; simpl in H; discriminate.
  - destruct q as [| c q'].
    + destruct o as [b|]; destruct i as [| i']; simpl in *.
      * exact H.
      * exact H.
      * discriminate H.
      * exact H.
    + destruct i as [| i']; simpl in *.
      * destruct o as [b|]; [exact H | discriminate H].
      * destruct o as [b|]; apply (ih q'); exact H.
Qed.

(* 合并保持第二个输入在第一个输入未决定位上的值 *)
Lemma mergeC_keeps_right : forall p q i a,
  nth_error p i = Some None ->
  nth_error q i = Some (Some a) ->
  nth_error (mergeC p q) i = Some (Some a).
Proof.
  induction p as [| o p' ih]; intros q i a Hp Hq.
  - destruct i; simpl in Hp; discriminate.
  - destruct q as [| c q'].
    + destruct i; simpl in Hq; discriminate.
    + destruct i as [| i']; simpl in *.
      * destruct o as [b|].
        -- discriminate Hp.
        -- exact Hq.
      * destruct o as [b|]; apply (ih q'); assumption.
Qed.

(* ---------- 四、Solovay-Tennenbaum 记录函数（Cantor 配对） ---------- *)

Definition cantor (b g : nat) : nat := (b + g) * (b + g + 1) / 2 + g.

(* 记录函数公理 (b)：π 的第一分量不超过编号 *)
Theorem cantor_selfLE : forall b g, b <= cantor b g.
Proof.
  unfold cantor. intros b g.
  assert (key : 2 * b <= (b + g) * (b + g + 1)).
  { destruct (b + g) as [| s] eqn:E.
    - assert (Hb : b = 0) by lia. subst. simpl. lia.
    - assert (H1 : (s + 1) * 2 <= (s + 1) * (s + 1 + 1)).
      { apply Nat.mul_le_mono_l. lia. }
      assert (H3 : b * 2 <= (s + 1) * 2).
      { apply Nat.mul_le_mono_r. lia. }
      lia. }
  assert (Hd : 2 * b / 2 = b).
  { rewrite Nat.mul_comm. apply Nat.div_mul. lia. }
  apply Nat.le_trans with (2 * b / 2).
  - rewrite Hd. lia.
  - apply Nat.le_trans with ((b + g) * (b + g + 1) / 2).
    + apply Nat.div_le_mono; [lia | exact key].
    + lia.
Qed.

(* ---------- MA 的 greedy 相遇引擎（定理 3.1 的迭代面） ---------- *)

Fixpoint deciderN (n : nat) (p : list bool) : list bool :=
  p ++ repeat false (S n - length p).

Fixpoint greedyChain (ds : list nat) (p : list bool) : list (list bool) :=
  match ds with
  | [] => [p]
  | n :: ns => p :: greedyChain ns (deciderN n p)
  end.

(* 演示：三步迭代每步决定下一位；支撑即非平凡坐标 *)
Compute map (@length bool) (greedyChain [0; 1; 2] []).
(* = [0; 1; 2; 3] *)

Compute (spt [None; Some true; None], spt [Some false; Some true; None]).
(* = (1, 2) *)

Compute (mergeC [None; Some true] [Some false; None],
         mergeC [Some true; None] [None; Some false]).
(* 相容对的合并：两个方向都得到逐坐标决定并 *)

Compute map (fun b => map (fun g => cantor b g) [0; 1; 2; 3]) [0; 1; 2; 3].
(* 三角数编号表 *)
