(* ex11 —— 直觉主义与 Glivenko 现象
   对书：Mints ch3（Glivenko）/ §2.9 / Huth&Ryan §1.2.5

   核心现象：经典原理挂上 ¬¬ 后【全部】直觉可证——
     nn_lem      : ¬¬(A ∨ ¬A)
     nn_dne      : ¬¬(¬¬A → A)
     nn_demorgan : ¬(A ∧ B) → ¬¬(¬A ∨ ¬B)
   这是 Glivenko 定理（经典可证 ⟺ 直觉可证 ¬¬f）的构件现场。
   全部零公理——Print Assumptions 逐一验明。 *)

(* ---------- 构件一：¬¬¬A → ¬A（三重否定坍缩） ---------- *)

Theorem n3 : forall A : Prop, ~ ~ ~ A -> ~ A.
Proof.
  intros A H HA. apply H. intros HA'. exact (HA' HA).
Qed.

(* ---------- 构件二：¬¬ 单调 ---------- *)

Theorem nn_mono : forall A B : Prop,
  (A -> B) -> ~ ~ A -> ~ ~ B.
Proof.
  intros A B f Hnn HB. apply Hnn. intros HA. apply HB.
  apply f. exact HA.
Qed.

(* ---------- 现象：经典原理的 ¬¬ 化 ---------- *)

Theorem nn_lem : forall A : Prop, ~ ~ (A \/ ~ A).
Proof.
  intros A H. apply H. right. intros HA. apply H. left. exact HA.
Qed.

Theorem nn_dne : forall A : Prop, ~ ~ (~ ~ A -> A).
Proof.
  intros A H. apply H. intros HDNE.
  assert (HnA : ~ A).
  { intros HA. apply H. intros _. exact HA. }
  exact (False_ind A (HDNE HnA)).
Qed.

(* de Morgan 对偶方向的 ¬¬ 化 *)
Theorem nn_demorgan : forall A B : Prop,
  ~ (A /\ B) -> ~ ~ (~ A \/ ~ B).
Proof.
  intros A B H HN.
  (* 由 ¬(¬A∨¬B) 得 ¬¬A 与 ¬¬B，合成 ¬¬(A∧B) 与 H 冲突 *)
  assert (HnA2 : ~ ~ A) by (intros na; apply HN; left; exact na).
  assert (HnB2 : ~ ~ B) by (intros nb; apply HN; right; exact nb).
  apply (HnA2 (fun HA => HnB2 (fun HB => H (conj HA HB)))).
Qed.

Print Assumptions n3.           (* Closed *)
Print Assumptions nn_mono.      (* Closed *)
Print Assumptions nn_lem.       (* Closed *)
Print Assumptions nn_dne.       (* Closed *)
Print Assumptions nn_demorgan.  (* Closed *)

(* ---------- Glivenko 之核：经典蕴涵的 ¬¬ 化（单向，构造性） ---------- *)

Section Glivenko.
(* 经典定理 A（作为假设）⟹ ¬¬A 直觉可证 *)
Theorem cl_to_nn : forall A : Prop, A -> ~ ~ A.
Proof.
  intros A HA H. apply H. exact HA.
Qed.
End Glivenko.

(* 坑位速记（Coq 侧）：
   - n3 是「三重否定在直觉里已经能坍缩一层」——Glivenko 证明的引擎；
   - nn_dne 的内层证明链：把 ¬(DNE) 喂回 DNE 自己——经典自指的
     直觉安全版；
   - nn_demorgan 的 ¬A 分支要用 n3 绕——直接假设法推不出 ¬A，
     只能从「或右被否」的 ¬¬ 信息里坍缩。 *)
