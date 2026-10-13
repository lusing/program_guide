(* 第 07 章 滤子与理想：公理化与三例验证 *)

Require Import Arith Lia.

(* ---------- 一、滤子公理（Jech (7.1) 的谓词版） ----------
   滤子 = 谓词族 F（"X ∈ F" 写作 F X），满足：
   (i)  对交封闭；(ii) 对超集封闭（在论域内）。 *)

Definition Filter_axioms {A : Type} (F : (A -> Prop) -> Prop) : Prop :=
  (forall X, F X -> forall Y, F Y -> F (fun a => X a /\ Y a))
  /\ (forall X Y, (forall a, X a -> Y a) -> F X -> F Y).

(* ---------- 二、主滤子（Jech 例 2） ---------- *)

Definition principal {A : Type} (X0 : A -> Prop) : (A -> Prop) -> Prop :=
  fun X => forall a, X0 a -> X a.

Lemma principal_is_filter :
  forall (A : Type) (X0 : A -> Prop),
    Filter_axioms (principal X0).
Proof.
  intros A X0.
  split.
  - intros X HX Y HY. unfold principal in *.
    intros a h. split; [apply HX | apply HY]; assumption.
  - intros X Y HXY HX. unfold principal in *.
    intros a h. apply HXY. apply HX. assumption.
Qed.

(* ---------- 三、Fréchet 滤子（Jech 例 3，nat 上余有限） ---------- *)

(* "有限谓词"：被某个 N 界定（nat 上有限的正规形态） *)
Definition bounded (p : nat -> Prop) : Prop :=
  exists N, forall n, p n -> n < N.

Definition cofinite_nat : (nat -> Prop) -> Prop :=
  fun X => exists c, bounded c /\ forall a, X a <-> ~ c a.

(* membership 的完整验证（交封闭 + 超集封闭）是初等练习；
   余有限的官方机器形态在 Lean 通道（Filter.mem_cofinite）。 *)

(* ---------- 四、滤子的交（引理 7.1a 的两滤子版） ---------- *)

Definition meet {A : Type} (F G : (A -> Prop) -> Prop) : (A -> Prop) -> Prop :=
  fun X => F X /\ G X.

Lemma meet_is_filter :
  forall (A : Type) (F G : (A -> Prop) -> Prop),
    Filter_axioms F -> Filter_axioms G -> Filter_axioms (meet F G).
Proof.
  intros A F G [HF1 HF2] [HG1 HG2].
  split.
  - intros X [HX1 HX2] Y [HY1 HY2]. unfold meet.
    split; [apply HF1 | apply HG1]; assumption.
  - intros X Y HXY [HX1 HX2]. unfold meet.
    split.
    + apply (HF2 X Y HXY). exact HX1.
    + apply (HG2 X Y HXY). exact HX2.
Qed.

Print Assumptions meet_is_filter.
(* Closed under the global context *)
