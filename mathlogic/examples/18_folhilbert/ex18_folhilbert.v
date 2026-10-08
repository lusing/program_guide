(* ex17 —— FOL Hilbert 系统 K 与演绎定理的 Gen 侧条件
   对书：Mendelson §2.3-2.6 / Ben-Ari 3e Ch8.2

   命题 Hilbert（05 章）+ 两条量词公理 + Gen 规则。
   旗舰：闭公式版演绎定理——Gen 的变元不在 FV(A) 时
   Γ∪{A} ⊢ B ⟹ Γ ⊢ A→B。侧条件不可省的经典反例入册：
   A ⊢ ∀x.A 但 ⊬ A → ∀x.A（当 x ∈ FV(A)）。 *)

From Stdlib Require Import List Bool Arith.
Import ListNotations.

Inductive fterm : Type :=
| fvar : nat -> fterm
| ffun : nat -> fterm -> fterm.

Fixpoint fsubst (t : fterm) (x : nat) (s : fterm) : fterm :=
  match t with
  | fvar y => if Nat.eqb y x then s else fvar y
  | ffun f t' => ffun f (fsubst t' x s)
  end.

Inductive fform : Type :=
| fpred : nat -> fterm -> fform
| fimp : fform -> fform -> fform
| fall : nat -> fform -> fform.

(* 公理模式：命题三条（K/S/弥合）+ 量词两条 *)
Fixpoint fvf (t : fterm) : list nat :=
  match t with
  | fvar y => [y]
  | ffun _ t' => fvf t'
  end.

Fixpoint fFV (F : fform) : list nat :=
  match F with
  | fpred _ t => fvf t
  | fimp P Q => fFV P ++ fFV Q
  | fall x P => remove (Nat.eq_dec) x (fFV P)
  end.

Definition closedF (A : fform) : Prop := fFV A = [].

Definition isAx (A : fform) : Prop :=
  (exists P Q, A = fimp P (fimp Q P))
  \/ (exists P Q R,
       A = fimp (fimp P (fimp Q R)) (fimp (fimp P Q) (fimp P R)))
  \/ (exists x p t,
       A = fimp (fall x (fpred p t)) (fpred p (fsubst t x t)))
  \/ (exists x P Q,
       A = fimp (fall x (fimp P Q)) (fimp (fall x P) (fall x Q)))
  \/ (exists x P Q, ~ In x (fFV P) /\ A = fimp (fall x (fimp P Q)) (fimp P (fall x Q))).

(* ---------- 旗舰：闭公式版演绎定理 ---------- *)

Inductive fder (G : list fform) : fform -> Prop :=
| fHyp : forall A, In A G -> fder G A
| fAx : forall A, isAx A -> fder G A
| fMP : forall P A, fder G (fimp P A) -> fder G P -> fder G A
| fGen : forall x A, fder G A -> fder G (fall x A).

(* ---------- 基础设施 ---------- *)

Lemma fweak : forall G A, fder G A -> forall D, incl G D -> fder D A.
Proof.
  intros G A H. induction H; intros D HD.
  - apply fHyp. apply HD. assumption.
  - apply fAx; assumption.
  - eapply fMP; eauto.
  - apply fGen. auto.
Qed.

Lemma fk : forall G A B, fder G A -> fder G (fimp A (fimp B A)).
Proof.
  intros G A B _. apply fAx. left. exists A, B. reflexivity.
Qed.

Lemma fs : forall G A B C,
  fder G (fimp A (fimp B C)) -> fder G (fimp A B) ->
  fder G (fimp A C).
Proof.
  intros G A B C H1 H2. eapply fMP.
  - eapply fMP.
    + apply fAx. right; left. exists A, B, C. reflexivity.
    + exact H1.
  - exact H2.
Qed.

Lemma fid : forall G A, fder G (fimp A A).
Proof.
  intros G A. apply (fs G A (fimp A A) A).
  - apply fAx. left. exists A, (fimp A A). reflexivity.
  - apply fAx. left. exists A, A. reflexivity.
Qed.

Theorem fdeduction_closed : forall G A B,
  closedF A -> fder (A :: G) B -> fder G (fimp A B).
Proof.
  intros G A B Hcl H.
  (* 对推导结构归纳，环境参数化 *)
  induction H as [B0 Hin | B0 HAx | P B0 H1 IH1 H2 IH2 | x B0 H0 IH0].
  - (* 假设分支：B0 = A 时 fid；B0 ∈ G 时 K 公理 + weak *)
    destruct Hin as [Heq | Hin].
    + subst B0. apply fid.
    + eapply fMP.
      * apply fAx. left. exists B0, A. reflexivity.
      * apply (fweak G B0).
        -- apply fHyp. exact Hin.
        -- intros Y HY. exact HY.
  - (* 公理分支：MP(Ax:B0, K 实例 B0→(A→B0)) *)
    eapply fMP.
    + apply fAx. left. exists B0, A. reflexivity.
    + apply fAx. exact HAx.
  - (* MP 分支：A→(P→B0) 与 A→P 合成 A→B0 *)
    apply (fs G A P B0); assumption.
  - (* Gen 分支：IH0 : Γ ⊢ A → B0；
       Gen 提升：Γ ⊢ ∀x.(A→B0)——Gen 作用于闭 A 安全 *)
    (* Gen 后移（K6，闭 A 侧条件）：∀x.(A→B0) → A→∀x.B0 *)
    eapply fMP.
    + apply fAx. right; right; right; right.
      exists x, A, B0. split.
      * (* x ∉ FV(A)：closedF A 的展开 *)
        rewrite Hcl. intros Hc. destruct Hc.
      * reflexivity.
    + apply fGen. exact IH0.
Qed.



(* ---------- 自由变元与闭公式 ---------- *)



Print Assumptions fdeduction_closed.  (* Closed *)

(* ---------- Gen 侧条件不可省的反例（文档） ---------- *)

(* 若 A 含自由变元 x：A ⊢ ∀x.A（Gen 合法），
   但一般 ⊬ A → ∀x.A（A := P(x)）——演绎定理失效。
   闭公式版通过 closedF 前提排除此情形。 *)

(* ---------- 现场 ---------- *)

Example gen_demo :
  forall G (P : fform), fder G P -> fder G (fall 0 P).
Proof. intros G P H. apply fGen. exact H. Qed.

(* 坑位速记（Coq 侧）：
   - induction H 环境参数化需要推导关系以 G 为参数（fder G）；
   - 公理分支的 MP 装配：Ax ∧ (Ax → (A → Ax))——K 公理的
     二次嵌套；
   - Gen 分支的 K5 装配：∀x.(A→B) → (∀x.A → ∀x.B) 的
     两次 MP——第二次需要 Γ ⊢ ∀x.A（闭 A 从假设提升）。 *)
