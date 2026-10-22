(* 第 70 章：第二递归定义定理与彻底有限集合（冯琦 §1.5-1.6）
   HF 归纳类型；燃料版阿克曼编码（定理 1.48）；
   ∈-极小原理的有限版（定理 1.44(3)）：非空有限列表有 ∈-极小元，
   以"尺寸最小者"为证——成员的尺寸严格更小。 *)
From Coq Require Import List Arith Lia.
Import ListNotations.

(* ---------- V_ω 的归纳化身（定理 1.49：∅/{x}/∪ 三算子生成） ---------- *)

Inductive HF : Type :=
| node (children : list HF).

Definition hf_empty : HF := node [].
Definition hf_singleton (a : HF) : HF := node [a].
Definition hf_union (a b : HF) : HF :=
  match a, b with
  | node ca, _ => node (ca ++ [b])    (* f(r) ∪ {f(i)}：拼接即可 *)
  end.

(* Prop 级成员：不需要可判相等 *)
Fixpoint hf_in (a : HF) (b : HF) : Prop :=
  match b with
  | node cs => In a cs
  end.

(* ---------- 定理 1.48：阿克曼编码（燃料版良基递归） ---------- *)

Definition lg2 (n : nat) : nat := Nat.log2 (n + 1).
Definition rrem (n : nat) : nat := n + 1 - 2 ^ (lg2 n).

(* 本版 Coq 无 Nat.pow_pos_nonneg——自证 2^k > 0（两步归纳） *)
Lemma pow2_pos : forall k, 0 < 2 ^ k.
Proof. induction k as [|k IH]; simpl; lia. Qed.

Lemma rrem_le : forall n, rrem n <= n.
Proof.
  intro n. unfold rrem, lg2.
  pose proof (pow2_pos (Nat.log2 (n + 1))) as H.
  lia.
Qed.

(* 本版 Coq 亦无 Nat.log2_le_self——自证 k < 2^k 与 log2 n ≤ n *)
Lemma lt_pow2 : forall k, k < 2 ^ k.
Proof.
  induction k as [|k IH]; simpl; [lia|].
  pose proof (pow2_pos k). lia.
Qed.

Lemma log2_le_self' : forall n, Nat.log2 n <= n.
Proof.
  intro n. destruct n as [|n'].
  - apply Nat.le_0_l.
  - pose proof (Nat.log2_spec (S n') ltac:(lia)) as [Hle _].
    pose proof (lt_pow2 (Nat.log2 (S n'))).
    pose proof (pow2_pos (Nat.log2 (S n'))).
    lia.
Qed.

Lemma lg2_le : forall n, lg2 n <= n.
Proof.
  intro n. unfold lg2.
  pose proof (log2_le_self' (n + 1)) as H1.
  destruct (Nat.eq_dec (Nat.log2 (n + 1)) (n + 1)) as [E|E].
  - (* log2(n+1) = n+1 与 log2_spec 下界、k < 2^k 冲突 *)
    pose proof (Nat.log2_spec (n + 1) ltac:(lia)) as [Hlo _].
    rewrite E in Hlo.
    pose proof (lt_pow2 (n + 1)).
    lia.
  - lia.
Qed.

(* 每次递归第二参数严格变小（rrem m ≤ m、lg2 m ≤ m），燃料 n 足够 *)
Fixpoint ackV (fuel n : nat) : HF :=
  match fuel with
  | 0 => hf_empty
  | S f =>
      match n with
      | 0 => hf_empty
      | S m => hf_union (ackV f (rrem m)) (ackV f (lg2 m))
      end
  end.

Definition ack (n : nat) : HF := ackV n n.

(* 书页 84 断言三：f(3) = {f(1), f(0)}（= 自然数 2 的冯诺伊曼形态） *)
Example ack3 : ack 3 = node [node []; node [node []]].
Proof. vm_compute. reflexivity. Qed.

Example ack5 : ack 5 = node [node []; node [node [node []]]].
Proof. vm_compute. reflexivity. Qed.

(* ---------- 尺寸：∈-下降的引擎 ---------- *)

(* 本版 Coq(8.20) guard 拒绝 HF×list HF 的交叉互递归（教科书形态亦被拒）：
   单 fixpoint + fold_right 嵌套递归承载同一数学——元素是孩子的子项。 *)
Fixpoint size (a : HF) : nat :=
  match a with
  | node cs => S (fold_right (fun c acc => size c + acc) 0 cs)
  end.

Lemma size_child_lt : forall cs y, In y cs -> size y < size (node cs).
Proof.
  induction cs as [|c rest IH]; simpl; intros y Hin.
  - contradiction.
  - destruct Hin as [->|Hin].
    + lia.
    + specialize (IH y Hin); simpl in IH; lia.
Qed.

(* ---------- 定理 1.44(3) 有限版：非空列表有 ∈-极小元 ---------- *)

Lemma list_size_min : forall (l : list HF), l <> [] ->
  exists a, In a l /\ forall b, In b l -> size a <= size b.
Proof.
  induction l as [|c rest IH]; intros Hne.
  - contradiction.
  - destruct rest as [|d rest'].
    + exists c. split.
      * left; reflexivity.
      * intros b [->|Hb]; [lia|contradiction].
    + destruct (IH ltac:(discriminate)) as [a [Ha Hmin]].
      destruct (le_gt_dec (size c) (size a)) as [Hc|Hc].
      * exists c. split.
        -- left; reflexivity.
        -- intros b [->|Hb]; [lia|]. specialize (Hmin b Hb). lia.
      * exists a. split.
        -- right; exact Ha.
        -- intros b [->|Hb]; [lia|]. exact (Hmin b Hb).
Qed.

Theorem hf_minimal : forall (l : list HF), l <> [] ->
  exists a, In a l /\ forall b, In b l -> ~ hf_in b a.
Proof.
  intros l Hne.
  destruct (list_size_min l Hne) as [a [Ha Hmin]].
  destruct a as [ca].          (* a 的孩子列表显形，hf_in 方可化简 *)
  exists (node ca). split; [exact Ha|].
  intros b Hb Hba.
  destruct b as [cb].
  simpl in Hba.                 (* hf_in (node cb) (node ca) = In (node cb) ca *)
  pose proof (size_child_lt ca (node cb) Hba) as Hlt.
  specialize (Hmin (node cb) Hb). lia.
Qed.
