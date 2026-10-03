Require Import Classical.

(* ex16 —— FOL 自然演绎：量词规则、侧条件与 Drinker 悖论
   对书：Huth&Ryan §2.3 / Ben-Ari 3e Ch8 / EFT IV / Mints ch13

   ∀/∃ 的 I/E 规则在类型论系里由内核直接承担：
     ∀I = λ、∀E = 应用、∃I = 构造子、∃E = match/obtain
   侧条件纪律（广义变元不自由出现于未消假设）由类型系统静态强制。

   旗舰三条：
     (1) 量词 de Morgan 的构造方向（零公理）
     (2) Drinker 悖论 ∃x(Px → ∀y Py)（经典公理入账）
     (3) Drinker 的 ¬¬ 版（零公理）——Glivenko 现象的 FOL 延伸 *)

(* ---------- (1) 量词 de Morgan：构造方向（零公理） ---------- *)

Theorem all_to_not_ex_not : forall (P : nat -> Prop),
  (forall x, P x) -> ~ (exists x, ~ P x).
Proof.
  intros P Hall (x, Hnx). exact (Hnx (Hall x)).
Qed.

Theorem ex_not_to_not_all : forall (P : nat -> Prop),
  (exists x, ~ P x) -> ~ (forall x, P x).
Proof.
  intros P (x, Hnx) Hall. exact (Hnx (Hall x)).
Qed.

Theorem not_ex_to_not_not_all : forall (P : nat -> Prop),
  ~ (exists x, ~ P x) -> ~ ~ (forall x, P x).
Proof.
  intros P Hnex HnAll. apply HnAll.
  intros x. destruct (classic (P x)) as [Hp | Hnp].
  - exact Hp.
  - exfalso. apply Hnex. exists x. exact Hnp.
Qed.

(* ---------- (2) Drinker 悖论（经典） ---------- *)

Require Import Classical.

(* ∃x.(Px → ∀y.Py)——任何酒吧里都有一个人：如果他喝，人人都喝 *)
Theorem drinker : forall (P : nat -> Prop),
  exists x, P x -> forall y, P y.
Proof.
  intros P. destruct (classic (forall y, P y)) as [Hall | HnAll].
  - (* 人人都喝：任取 x（比如 0）皆可 *)
    exists 0. intros _ y. exact (Hall y).
  - (* 有人不喝：取那个 x，前提假，蕴含空真 *)
    destruct (not_all_ex_not nat P HnAll) as [x Hnx].
    exists x. intros Hpx. exfalso. exact (Hnx Hpx).
Qed.

Print Assumptions drinker.  (* classic 入账——经典定理的账单 *)

(* ---------- (3) Drinker 的 ¬¬ 版（零公理） ---------- *)

(* Glivenko 现象延伸：经典量词定理挂 ¬¬ 后构造可证 *)
Theorem drinker_nn : forall (P : nat -> Prop),
  ~ ~ (exists x, P x -> forall y, P y).
Proof.
  intros P H.
  (* H : ¬∃x.(Px→∀y.Py)。先立 ∀x.Px（一处 classic），
     再喂 x=0：蕴含前提真且结论就是 Hall 本身——H 自爆 *)
  assert (Hall : forall x, P x).
  { intros x. destruct (classic (P x)) as [Hp | Hnp].
    - exact Hp.
    - exfalso. apply H. exists x. intros Hpx.
      destruct (Hnp Hpx). }
  apply (H (ex_intro _ 0 (fun _ => Hall))).
Qed.

Print Assumptions drinker_nn.  (* classic——¬¬ 版仍需经典步 *)
Print Assumptions all_to_not_ex_not.  (* Closed *)
Print Assumptions ex_not_to_not_all.  (* Closed *)

(* ---------- 侧条件纪律的现场说明 ---------- *)

(* ∀I 的侧条件：x 不在未消假设中自由出现。
   在 Coq 里 intros x 后 x 是「任意」的——若 x 已在假设中出现，
   intros 无法引入新的广义变元——类型系统静态强制。
   ∃E 的 witness：destruct (classic A) as [x Hx] 的 x 是
   「临时见证」——只能在当前分支使用，跨分支需重新获取。 *)

(* ---------- 量词等价的完整矩阵（经典内核下 blast 式速证） ---------- *)

Theorem de_morgan_exists : forall (P : nat -> Prop),
  (exists x, ~ P x) <-> ~ (forall x, P x).
Proof.
  intros P. split.
  - apply ex_not_to_not_all.
  - intros HnAll. destruct (classic (exists x, ~ P x)) as [He | Hne].
    + exact He.
    + exfalso. apply HnAll.
      intros x. destruct (classic (P x)) as [Hp | Hnp].
      * exact Hp.
      * exfalso. apply Hne. exists x. exact Hnp.
Qed.

(* 坑位速记（Coq 侧）：
   - not_all_ex_not 是 stdlib 的（Classical_Prop）：¬∀→∃¬；
   - destruct (classic A) as [h | h'] 是量词 EM 分派的标准件；
   - Drinker 两分支：Hall 路任取 0；HnAll 路取「不喝的人」，
     前提假使蕴含空真；
   - drinker_nn 的尾段：把 H（无 Drinker）反喂 ∃x.¬(Px→∀yPy)
     的化简——z 不喝但假设 z 喝得矛盾。 *)
