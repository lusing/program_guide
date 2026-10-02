(* ex04 —— 经典加成：等价矩阵与公理记账
   八书对位：Mints §2.9 / §3 / Huth&Ryan §1.2.5 / Mendelson §1.2

   本章戏核：五条经典原理（LEM/DNE/Peirce/Clavius/经典 de Morgan）
   两两等价，但「A 蕴涵 B」的每个证明都是构造性的——
   把 A 塞进 Section 变量，矩阵零公理；
   而原理本体在构造内核下不可证（13 章 Kripke 反模型收尸）。 *)

(* ---------- 矩阵：LEM 侧 ---------- *)

Section FromLEM.
Variable LEM : forall P : Prop, P \/ ~ P.

Theorem lem_to_dne : forall P : Prop, ~ ~ P -> P.
Proof.
  intros P Hnn. destruct (LEM P) as [HP | HNP].
  - exact HP.
  - exfalso. apply Hnn. exact HNP.
Qed.

Theorem lem_to_peirce : forall P Q : Prop, ((P -> Q) -> P) -> P.
Proof.
  intros P Q H. destruct (LEM P) as [HP | HNP].
  - exact HP.
  - exfalso. apply HNP. apply H. intros HP. exfalso. apply HNP. exact HP.
Qed.

Theorem lem_to_clavius : forall P : Prop, (~ P -> P) -> P.
Proof.
  intros P H. destruct (LEM P) as [HP | HNP].
  - exact HP.
  - exfalso. apply HNP. apply H. exact HNP.
Qed.
End FromLEM.

(* ---------- 矩阵：DNE 侧 ---------- *)

Section FromDNE.
Variable DNE : forall P : Prop, ~ ~ P -> P.

Theorem dne_to_lem : forall P : Prop, P \/ ~ P.
Proof.
  intros P. apply DNE. intros HNP. apply HNP. right.
  intros HP. apply HNP. left. exact HP.
Qed.

Theorem dne_to_clavius : forall P : Prop, (~ P -> P) -> P.
Proof.
  intros P H. apply DNE. intros HNP. apply HNP. apply H. exact HNP.
Qed.
End FromDNE.

(* ---------- 矩阵：Peirce 侧 ---------- *)

Section FromPeirce.
Variable Peirce : forall P Q : Prop, ((P -> Q) -> P) -> P.

Theorem peirce_to_dne : forall P : Prop, ~ ~ P -> P.
Proof.
  intros P Hnn. apply (Peirce P False). intros HPQ.
  exfalso. apply Hnn. intros HP. apply HPQ. exact HP.
Qed.
End FromPeirce.

Print Assumptions lem_to_dne.    (* Closed：矩阵零公理 *)
Print Assumptions dne_to_lem.    (* Closed *)
Print Assumptions peirce_to_dne. (* Closed *)

(* ---------- 原理本体：构造内核下证不出，公理化后记账 ---------- *)

Require Import Classical_Prop.

Theorem classical_dne : forall P : Prop, ~ ~ P -> P.
Proof. intros P H. apply NNPP. exact H. Qed.

Theorem classical_lem : forall P : Prop, P \/ ~ P.
Proof.
  intros P. apply NNPP. intros HNP. apply HNP. right.
  intros HP. apply HNP. left. exact HP.
Qed.

Theorem classical_de_morgan_dual : forall P Q : Prop,
  ~ (P /\ Q) -> ~ P \/ ~ Q.
Proof.
  intros P Q H.
  destruct (classic P) as [HP | HNP].
  - right. intros HQ. apply H. split.
    + exact HP.
    + exact HQ.
  - left. exact HNP.
Qed.

Print Assumptions classical_dne.           (* classic *)
Print Assumptions classical_lem.           (* classic *)
Print Assumptions classical_de_morgan_dual. (* classic *)

(* 坑位速记（Coq 侧）：
   - Section Variable 让「原理作假设」成为一等公民——矩阵定理自动带
     (LEM : ...) 前提，Print Assumptions 仍是 Closed；
   - 03 章的 de_morgan_1/2（构造方向）对照本章 dual 方向——
     后者 classic 入账，差距一目了然。 *)
