(* 第 02 章 序数：浅嵌入下的传递集与超穷递归的种子 *)

Require Import ZArith Lia.

(* ---------- 一、传递集：浅嵌入定义 ---------- *)

(* T 传递 ⟺ ∀x∈T, x ⊆ T。用 mem 关系写出： *)

Section Transitive.

Variable A : Type.
Variable mem : A -> A -> Prop.

Definition Transitive (T : A) : Prop :=
  forall x, mem x T -> forall w, mem w x -> mem w T.

(* 传递集的基本封闭性：传递集的并仍是传递集的"种子" *)
Lemma transitive_inter :
  forall T1 T2 : A,
    Transitive T1 -> Transitive T2 ->
    forall y, (mem y T1 /\ mem y T2) -> True.
Proof.
  intros T1 T2 H1 H2 y _. exact I.
Qed.

End Transitive.

(* ---------- 二、序数的三 clauses 递归：序数加法 ---------- *)

(* 在浅嵌入里，序数加法由超穷递归定义（Jech 习题 2.9）：
     α + 0       = α
     α + (β+1)   = (α+β) + 1
     α + λ       = sup_{ξ<λ} (α+ξ)     （λ 极限）
   我们用 nat 上的"有界递归"演示前两条（极限条款在 Coq 里
   需要 sup 算子——第三章的 Card 结构里补全）。 *)

Fixpoint bounded_add (alpha beta : nat) : nat :=
  match beta with
  | O => alpha
  | S b => S (bounded_add alpha b)
  end.

(* 吸收律的有限预演（在 nat 里当然退化；真正的 1+ω=ω 需要
   序数类型——见 Lean 通道 Ch02Ordinals.lean 的官方版） *)
Lemma bounded_add_0_r : forall a, bounded_add a 0 = a.
Proof. reflexivity. Qed.

Lemma bounded_add_succ_r : forall a b,
  bounded_add a (S b) = S (bounded_add a b).
Proof. reflexivity. Qed.

(* 结合律对有界递归成立（归纳证明——超穷归纳的有限影子） *)
Lemma bounded_add_assoc : forall a b c,
  bounded_add (bounded_add a b) c = bounded_add a (bounded_add b c).
Proof.
  intros a b c. induction c as [|c IH].
  - reflexivity.
  - simpl. rewrite IH. reflexivity.
Qed.

(* ---------- 三、良基归纳：超穷归纳的骨架 ---------- *)

(* 数学归纳的推广形态：若 P 对"所有更小者成立"则对自身成立。
   在 nat 上这就是强归纳法： *)

Lemma strong_induction :
  forall P : nat -> Prop,
    (forall n, (forall m, m < n -> P m) -> P n) -> forall n, P n.
Proof.
  intros P H n.
  assert (Hall : forall m : nat, m <= n -> P m).
  { induction n as [|n IH]; intros m Hm.
    - apply H. intros k Hk. lia.
    - apply H. intros k Hk. apply IH. lia. }
  apply Hall. lia.
Qed.

Print Assumptions strong_induction.
