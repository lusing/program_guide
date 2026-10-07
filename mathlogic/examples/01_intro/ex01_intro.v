(* ex01 —— 全景与 hello-logic：同一组定理在六家的第一面
   八书对位：Huth&Ryan §1.2 / Ben-Ari 3e §2.1-2.2 / Mints §2.2 / Mendelson §1.4

   逻辑的三件套：语法（公式怎么写）、证明演算（公式怎么推）、
   语义（公式什么时候为真）。证明助手把「推」交给内核当裁判。

   本章四条：mp（肯定前件）、蕴涵传递、¬¬引入（构造性白送）、
   经典哨兵 ¬¬P→P（构造内核不可证——第 4 章展开矩阵）。 *)

(* ---------- 三条构造性定理：全部零公理 ---------- *)

Lemma mp : forall (P Q : Prop), (P -> Q) -> P -> Q.
Proof. intros P Q H HP. exact (H HP). Qed.

Lemma imp_trans : forall P Q R : Prop, (P -> Q) -> (Q -> R) -> P -> R.
Proof. intros P Q R HPQ HQR HP. apply HQR. apply HPQ. exact HP. Qed.

Lemma nn_intro : forall P : Prop, P -> ~ ~ P.
Proof. intros P HP HNP. exact (HNP HP). Qed.

Print Assumptions mp.        (* Closed under the global context *)
Print Assumptions imp_trans. (* Closed *)
Print Assumptions nn_intro.  (* Closed *)

(* 坑位速记（Coq 侧）：
   - Print Assumptions 是公理记账的第一入口；
   - ~ P 展开就是 P -> False，所以 nn_intro 本质是高阶函数。 *)

(* ---------- 经典哨兵：构造内核下证不出来 ---------- *)

(* 不引公理时，下面这条注释掉的引理无法通过 Qed——试一试便知：
Lemma nn_elim : forall P : Prop, ~ ~ P -> P.
Proof. intros P H. (* 卡在这里：没有信息把否定翻成肯定 *) Abort. *)

From Stdlib Require Import Classical_Prop.

Lemma nn_elim : forall P : Prop, ~ ~ P -> P.
Proof. intros P H. apply NNPP. exact H. Qed.

Print Assumptions nn_elim.   (* 依赖 classic 公理——账本记上了 *)

(* 对比预告（04 章矩阵）：
   Agda：同一条要 postulate；
   Lean：是定理（Classical.em），但 #print axioms 记 Classical.choice；
   Isabelle/HOL4：内核经典，blast 直接证，零额外公理。 *)
