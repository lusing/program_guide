(* 15 谓词逻辑与 reflect —— 归纳谓词、存在量词、bool 与 Prop 的桥 *)

From Stdlib Require Import Arith List Bool.
Import ListNotations.

Module Ex15Predicates.

(* ---------- even：把「是偶数」定义成归纳命题 ---------- *)

Inductive even : nat -> Prop :=
  | even_O : even 0
  | even_SS : forall n : nat, even n -> even (S (S n)).

(* even 不是「算出来的 bool」，而是一个「可推导的命题」，
   它的结论随参数 n 变化——这叫归纳谓词（inductive predicate），
   是依赖类型最日常的用法。 *)

Example even_4 : even 4.
Proof.
  apply even_SS. apply even_SS. apply even_O.
Qed.

(* ---------- 证明 even 的函数性质 ---------- *)

Fixpoint double (n : nat) : nat :=
  match n with
  | O => O
  | S k => S (S (double k))
  end.

Fixpoint evenb (n : nat) : bool :=
  match n with
  | O => true
  | S O => false
  | S (S k) => evenb k
  end.

Theorem even_double : forall n : nat, even (double n).
Proof.
  induction n as [| n IH].
  - apply even_O.
  - simpl. apply even_SS. exact IH.
Qed.

(* ---------- 对证据本身做归纳 ---------- *)

(* even_evenb：induction H 作用在「even n 的证明」上：
   基例对应 even_O；步例的 as 模式 [| n' Hev IH] 收下
   构造子参数 n'、子证据 Hev、归纳假设 IH。 *)

Theorem even_evenb : forall n : nat, even n -> evenb n = true.
Proof.
  intros n H.
  induction H as [| n' Hev IH].
  - reflexivity.              (* evenb 0 = true *)
  - simpl. exact IH.          (* evenb (S (S n')) 化简就是 evenb n' *)
Qed.

(* ---------- 存在量词 exists ---------- *)

Theorem even_exists_double : forall n : nat,
  even n -> exists k : nat, n = double k.
Proof.
  intros n H.
  induction H as [| n' Hev IH].
  - exists 0. reflexivity.                    (* 0 = double 0 *)
  - destruct IH as [k Hk].
    exists (S k). simpl. rewrite <- Hk. reflexivity.
Qed.

(* exists 的用法：exists 证人. 把目标变成「证人满足性质」；
   destruct 把 exists 假设拆成「证人 + 性质」。
   forall 是「给任何 x 我都交付」的函数，exists 是「我这里有货」
   的打包——两者都是依赖类型的日常形态。 *)

(* ---------- 强化命题：两步归纳 ---------- *)

(* 反向 evenb_even : evenb n = true -> even n 需要「隔一步」的归纳，
   普通 induction 的 IH 只谈直接前驱，不够强。
   标准解法：把命题强化成 P n /\ P (S n) 一起归纳。 *)

Lemma two_step : forall P : nat -> Prop,
  P 0 -> P 1 ->
  (forall n : nat, P n -> P (S (S n))) ->
  forall n : nat, P n.
Proof.
  intros P H0 H1 HSS.
  assert (Hboth : forall n : nat, P n /\ P (S n)).
  { induction n as [| n [IH1 IH2]].
    - split.
      + exact H0.
      + exact H1.
    - split.
      + exact IH2.
      + apply HSS. exact IH1. }
  intros n. destruct (Hboth n) as [Hn _]. exact Hn.
Qed.

Theorem evenb_even : forall n : nat, evenb n = true -> even n.
Proof.
  apply (two_step (fun n => evenb n = true -> even n)).
  - intros _. apply even_O.
  - intros H. simpl in H. discriminate H.   (* evenb 1 = false *)
  - intros n IH H. simpl in H. apply even_SS. apply IH. exact H.
Qed.

(* 这是全书第一次「命题不够强就证明不了」——把结论加强成
   带合取的形式再归纳，是数学归纳法的经典技术，值得反复品味。 *)

(* ---------- reflect：bool 与 Prop 的官方桥 ---------- *)

(* reflect P b 读作「b 为 true 当且仅当 P 成立」，
   且它把两个方向打包在一个归纳类型里。 *)

Theorem evenb_reflect : forall n : nat, reflect (even n) (evenb n).
Proof.
  intros n.
  destruct (evenb n) eqn:E.
  - apply ReflectT. apply evenb_even. exact E.
  - apply ReflectF.
    intros Hev.
    rewrite (even_evenb n Hev) in E.
    discriminate E.
Qed.

(* 有了 reflect，「计算版」与「推理版」可以互相当燃料——
   标准库大量定理的形态就是 reflect。
   一句话总结本章：bool 是给程序算的，Prop 是给逻辑证的，
   reflect / 双向引理是两岸的桥。 *)

End Ex15Predicates.
