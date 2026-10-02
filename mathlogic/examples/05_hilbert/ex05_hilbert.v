(* ex05 —— Hilbert 系统 L 与演绎定理
   八书对位：Mendelson §1.4（A1/A2/A3+MP）/ Ben-Ari 3e §3.3 / Mints §8（对照 LJ）

   演算本身成为研究对象：推导用归纳定义（hyp/ax/mp 三构造子），
   演绎定理对推导结构归纳——「元定理」的机器证法范本。 *)

Require Import List.
Import ListNotations.

(* ---------- 语言：极小命题片段（var/imp/neg） ---------- *)

Inductive hform : Type :=
| HVar : nat -> hform
| HImp : hform -> hform -> hform
| HNeg : hform -> hform.

(* ---------- Mendelson 三公理模式 ---------- *)

Definition isAxiom (A : hform) : Prop :=
  (exists p q, A = HImp p (HImp q p))
  \/ (exists p q r, A = HImp (HImp p (HImp q r)) (HImp (HImp p q) (HImp p r)))
  \/ (exists p q, A = HImp (HImp (HNeg q) (HNeg p)) (HImp p q)).

(* ---------- 推导关系：证明演算的归纳定义 ---------- *)

Inductive derives (G : list hform) : hform -> Prop :=
| dHyp : forall A, In A G -> derives G A
| dAx  : forall A, isAxiom A -> derives G A
| dMP  : forall p A, derives G (HImp p A) -> derives G p -> derives G A.

(* ---------- 基础设施 ---------- *)

Lemma weak_K : forall G A B, derives G A -> derives G (HImp B A).
Proof.
  intros G A B H. eapply dMP.
  - apply dAx. left. exists A, B. reflexivity.
  - exact H.
Qed.

(* p → p：A1/A2 的五步组合（组合子视角：I = S K K 的命题版）
   注意在任意上下文 G 成立——演绎定理的假设分支要用 *)
Lemma identity : forall G p, derives G (HImp p p).
Proof.
  intros G p.
  assert (s1 : derives G (HImp p (HImp (HImp p p) p))).
  { apply dAx. left. exists p, (HImp p p). reflexivity. }
  assert (s2 : derives G (HImp (HImp p (HImp (HImp p p) p))
                     (HImp (HImp p (HImp p p)) (HImp p p)))).
  { apply dAx. right; left. exists p, (HImp p p), p. reflexivity. }
  assert (s3 : derives G (HImp (HImp p (HImp p p)) (HImp p p))).
  { eapply dMP. exact s2. exact s1. }
  assert (s4 : derives G (HImp p (HImp p p))).
  { apply dAx. left. exists p, p. reflexivity. }
  eapply dMP. exact s3. exact s4.
Qed.

(* ---------- 演绎定理：对推导归纳 ---------- *)

Theorem deduction : forall G p q,
  derives (p :: G) q -> derives G (HImp p q).
Proof.
  intros G p q H.
  induction H as [A HIn | A HAx | r A H1 IH1 H2 IH2].
  - (* 假设：A = p 或 A ∈ G *)
    destruct HIn as [Heq | HIn].
    + subst A. apply identity.
    + apply weak_K. apply dHyp. exact HIn.
  - (* 公理：weak_K 白送 *)
    apply weak_K. apply dAx. exact HAx.
  - (* MP：A2 实例两步接力 *)
    assert (s2 : derives G (HImp (HImp p (HImp r A))
                     (HImp (HImp p r) (HImp p A)))).
    { apply dAx. right; left. exists p, r, A. reflexivity. }
    assert (t1 : derives G (HImp (HImp p r) (HImp p A))).
    { eapply dMP. exact s2. exact IH1. }
    eapply dMP. exact t1. exact IH2.
Qed.

(* ---------- 现场：演绎定理省三页纸 ---------- *)

(* 「假设下的一条 hyp」经演绎定理直接升格为无假设推导 *)
Example use_deduction : forall p q r,
  derives [] (HImp (HImp p (HImp q r)) (HImp p (HImp q r))).
Proof.
  intros p q r.
  apply deduction.
  apply dHyp. left. reflexivity.
Qed.

(* 对照：没有演绎定理时，这类「重言式位移」要手工铺 A1/A2 的 MP 链。 *)

(* 坑位速记（Coq 侧）：
   - induction H 对 derives (p :: G) q 直接归纳——G 是参数，
     上下文 (p :: G) 在 IH 中原样保留；
   - dMP 构造子先给 (p → A) 再给 p——eapply 的子目标顺序别反；
   - 演绎定理的 MP 分支是 A2 的「柯里化分配」——两步 MP 接力。 *)
