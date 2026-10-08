(* ex44_incompleteness.v —— 哥德尔不完备性：机器件升级（Mendelson §3.5-3.6）
   原 44 章三步文档线（算术化→表示性→自指）保留在 docs；本章机器面给：
   1) mini-S 语言（+,×,=,¬,⇒,∃）的标准模型求值；
   2) 表示性样板三件：加法图/≤/偶性的标准正确性——真定理；
   3) 有限域可判定现场（有界量词求值器）：与 Tarski 不可定义的对照。
   Church 不可判定归约链、Rosser、Gödel II 为文档线。 *)

From Stdlib Require Import Bool Arith Lia List PeanoNat.
Import ListNotations.

(* ============ 一、mini-S 语言与标准模型 ============ *)

Inductive tm : Type :=
| var (n : nat)
| num (n : nat)
| pls (t1 t2 : tm)
| mul (t1 t2 : tm).

Inductive fm : Type :=
| eqt (t1 t2 : tm)
| neg (a : fm)
| imp (a b : fm)
| exq (x : nat) (a : fm).

Definition asn := nat -> nat.

Definition upd (s : asn) (x v : nat) : asn :=
  fun n => if Nat.eqb n x then v else s n.

Fixpoint teval (t : tm) (s : asn) : nat :=
  match t with
  | var n => s n
  | num n => n
  | pls a b => teval a s + teval b s
  | mul a b => teval a s * teval b s
  end.

Fixpoint feval (φ : fm) (s : asn) : Prop :=
  match φ with
  | eqt a b => teval a s = teval b s
  | neg a => ~ feval a s
  | imp a b => feval a s -> feval b s
  | exq x a => exists v, feval a (upd s x v)
  end.

(* ============ 二、表示性样板：标准正确性真定理 ============ *)

Definition s2 (x y : nat) : asn := upd (upd (fun _ => 0) 0 x) 1 y.
Definition s3 (x y z : nat) : asn := upd (s2 x y) 2 z.

Definition rep_add : fm := eqt (pls (var 0) (var 1)) (var 2).

Theorem rep_add_ok : forall x y z,
  feval rep_add (s3 x y z) <-> x + y = z.
Proof.
  intros x y z. unfold rep_add, feval, teval, s3, s2, upd. simpl.
  split; intro H; exact H.
Qed.

Definition rep_le : fm := exq 2 (eqt (pls (var 0) (var 2)) (var 1)).

Theorem rep_le_ok : forall x y, feval rep_le (s2 x y) <-> x <= y.
Proof.
  intros x y. split.
  - intros [d Hd]. unfold rep_le, feval, s2, upd in Hd. simpl in Hd. lia.
  - intro Hle. exists (y - x).
    unfold rep_le, feval, s2, upd. simpl. lia.
Qed.

Definition rep_even : fm := exq 1 (eqt (pls (var 1) (var 1)) (var 0)).

Theorem rep_even_ok : forall x,
  feval rep_even (upd (fun _ => 0) 0 x) <-> exists y, y + y = x.
Proof.
  intro x. split.
  - intros [y Hy]. exists y.
    unfold rep_even, feval in Hy. simpl in Hy.
    unfold upd in Hy. simpl in Hy. exact Hy.
  - intros [y Hy]. exists y.
    unfold rep_even, feval. simpl.
    unfold upd. simpl. exact Hy.
Qed.

Definition rep_mul : fm := eqt (mul (var 0) (var 1)) (var 2).

Theorem rep_mul_ok : forall x y z,
  feval rep_mul (s3 x y z) <-> x * y = z.
Proof.
  intros x y z. unfold rep_mul, feval, teval, s3, s2, upd. simpl.
  split; intro H; exact H.
Qed.

(* ============ 三、有限域可判定现场 ============ *)

Definition bexists (K : nat) (P : nat -> bool) : bool :=
  existsb P (seq 0 K).

(* 闭式在有限论域 {0..K-1} 上的可判定求值 *)
Fixpoint fevalb (φ : fm) (K : nat) (s : asn) : bool :=
  match φ with
  | eqt a b => Nat.eqb (teval a s) (teval b s)
  | neg a => negb (fevalb a K s)
  | imp a b => implb (fevalb a K s) (fevalb b K s)
  | exq x a => bexists K (fun v => fevalb a K (upd s x v))
  end.

(* 无量词式：布尔求值与命题语义逐点一致 *)
Fixpoint qf (φ : fm) : bool :=
  match φ with
  | eqt _ _ => true
  | neg a => qf a
  | imp a b => qf a && qf b
  | exq _ _ => false
  end.

Theorem qf_agree : forall φ s K,
  qf φ = true -> (fevalb φ K s = true <-> feval φ s).
Proof.
  intro φ. induction φ as [a b | a IHa | a IHa b IHb | x a IHa];
    intros s K Hq; simpl in *.
  - split; intro H; apply Nat.eqb_eq in H; exact H.
  - specialize (IHa s K Hq).
    split.
    + intro H. rewrite negb_true_iff in H. intro Hfa. apply IHa in Hfa.
      congruence.
    + intro H. destruct (fevalb a K s) eqn:E.
      * exfalso. apply H. apply IHa. reflexivity.
      * reflexivity.
  - rewrite andb_true_iff in Hq. destruct Hq as [Ha Hb].
    specialize (IHa s K Ha). specialize (IHb s K Hb).
    split.
    + intro Hbimp. rewrite Bool.implb_true_iff in Hbimp.
      intro Hfa. destruct (fevalb a K s) eqn:Ea.
      * apply IHb. apply Hbimp. reflexivity.
      * exfalso. apply IHa in Hfa. discriminate.
    + intro Hf. rewrite Bool.implb_true_iff.
      destruct (fevalb a K s) eqn:Ea.
      * intro Hc. apply (proj2 IHb). apply Hf. exact (proj1 IHa eq_refl).
      * intro Hc. discriminate.
  - discriminate.
Qed.

(* 现场一：同一句子的真值随论域变化——有限域真是相对的，N 真是绝对的。
   sen_even2 = ∃x (x+x ≡ 2)：论域 {0..4} 上真（x=1），论域 {0} 上假 *)
Definition sen_even2 : fm := exq 0 (eqt (pls (var 0) (var 0)) (num 2)).

Example finite_even_K5 : fevalb sen_even2 5 (fun _ => 0) = true.
Proof. reflexivity. Qed.

Example finite_even_K1 : fevalb sen_even2 1 (fun _ => 0) = false.
Proof. reflexivity. Qed.

(* 现场二：N 标准模型上它是真句子（定理而非计算——量词跑遍全体自然数） *)
Theorem even2_true : exists v, v + v = 2.
Proof. exists 1. reflexivity. Qed.

(* ============ 账本 ============ *)

Print Assumptions rep_le_ok.
Print Assumptions rep_even_ok.
Print Assumptions qf_agree.

(* ---------- Marker ch13 深化：表示性 ⟹ Σ₁ 片=CE ---------- *)

(* rep_* 样板把递归事实翻成 Σ₁ 句；此处给「翻译一致性」的
   有限影子：rep_add_ok 在 K=1..5 的有限域上与标准加法逐点对账 *)
Example rep_sigma1_shadow :
  forallb (fun K =>
    forallb (fun xy =>
      fevalb rep_add K (s3 (fst xy) (snd xy) (fst xy + snd xy)))
    (list_prod (seq 0 (S K)) (seq 0 (S K))))
    (seq 1 5) = true.
Proof. reflexivity. Qed.
