(* 14 命题逻辑 —— Prop 世界的 /\ \/ -> ~ <-> 与它们的策略 *)

From Coq Require Import List.
Import ListNotations.

Module Ex14Logic.

(* ---------- 合取 /\ ---------- *)

Theorem and_comm : forall P Q : Prop, P /\ Q -> Q /\ P.
Proof.
  intros P Q H.
  destruct H as [HP HQ].   (* 把 /\ 假设拆成两个 *)
  split.                   (* 把 /\ 目标拆成两个 *)
  - exact HQ.
  - exact HP.
Qed.

Theorem and_assoc : forall P Q R : Prop,
  (P /\ Q) /\ R <-> P /\ (Q /\ R).
Proof.
  intros P Q R. split.
  - intros [[HP HQ] HR]. split.
    + exact HP.
    + split.
      * exact HQ.
      * exact HR.
  - intros [HP [HQ HR]]. split.
    + split.
      * exact HP.
      * exact HQ.
    + exact HR.
Qed.

(* ---------- 析取 \/ ---------- *)

Theorem or_comm : forall P Q : Prop, P \/ Q -> Q \/ P.
Proof.
  intros P Q H.
  destruct H as [HP | HQ].   (* 析取假设：哪个分支就给哪个 *)
  - right. exact HP.
  - left. exact HQ.
Qed.

(* left / right 选择造哪个分支——注意与子弹无关，
   它们是「构造 inl/inr」的策略。 *)

(* ---------- 蕴含 -> ：函数！ ---------- *)

(* Curry-Howard：P -> Q 的证明就是函数。下面不用策略，直接写项： *)

Definition modus_ponens (P Q : Prop) (hpq : P -> Q) (hp : P) : Q :=
  hpq hp.

(* 也可以用策略风格完成同一件事： *)
Theorem modus_ponens' (P Q : Prop) : (P -> Q) -> P -> Q.
Proof.
  intros hpq hp.      (* 蕴含的前提就是函数参数 *)
  apply hpq.          (* 目标 Q，hpq : P -> Q，apply 对齐 *)
  exact hp.
Qed.

(* ---------- 否定 ~ 与 False ---------- *)

Print not.
(* not A := A -> False —— 否定不是新东西，是「推出假」 *)

(* Empty_set 没有构造子（第 4 章的「假命题」），False 同理。
   从 False 可以推出任何东西（爆炸原理）： *)
Theorem from_false : forall P : Prop, False -> P.
Proof.
  intros P H. destruct H.   (* False 没有构造子，destruct 直接关闭 *)
Qed.

Theorem not_and_true : forall P : Prop, ~ (P /\ ~ P).
Proof.
  intros P [HP HnP].
  (* 注意：~ P 不再往下解构了——~ 是个定义（P -> False），
     不是构造子，intro 模式进不去；直接收下当函数用 *)
  apply HnP.             (* 目标 ~ P 即 P -> False：给 P 就行 *)
  exact HP.
Qed.

(* ---------- True 与 <-> ---------- *)

Theorem and_true_iff : forall P : Prop, P /\ True <-> P.
Proof.
  intros P. split.
  - intros [HP _]. exact HP.
  - intros HP. split.
    + exact HP.
    + exact I.       (* I : True —— True 的唯一证明 *)
Qed.

(* ---------- 三层子弹的完整体验 ---------- *)
(* and_assoc 已经示范 - + * 三层；数子弹的层级：
   第一层 -，第二层 +，第三层 *。 *)

(* ---------- 命题逻辑动作速查 ----------
   逻辑证明里最常见的几个动作：
   - 目标是 /\  → split
   - 假设是 /\  → destruct（或 intros 时直接解构）
   - 目标是 \/  → left / right
   - 假设是 \/  → destruct（两个分支各来一次）
   - 目标是 ->  → intros（它是函数）
   - 假设是 ->  → apply（用函数）
   - 目标是 ~P  → intros（它是 P -> False）
   - 目标是 False → 找矛盾的假设 destruct/discriminate *)

End Ex14Logic.
