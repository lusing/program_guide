(* ex43_modal —— 基本模态逻辑 K（H&R §5.1-5.2）

   对书：Huth&Ryan §5.1（modes of truth）/ §5.2（语法与 Kripke 语义）
             / §5.3.1（有效式库）+ 13 章直觉主义 Kripke 的分工表

   设计：
   - 框架 = 世界集（有限表）+ 可达关系（任意 bool 二元关系）+ 赋值；
   - msat 按公式结构递归（□φ：一切可达世界都 φ；◇=¬□¬ 导出）；
   - 有效 = 在一切框架/世界成立；
   - 旗舰：K 模式有效（零公理）、必然化、◇ 对偶、□ 对 ∧ 的
     分配一半；反例件：□p→p / □p→□□p 在非自反/非传递框架失效
     （§5.3.1 图 5.3 的 x1/x2 现场）——K 只担保 K。 *)

From Stdlib Require Import List Bool Arith.
Import ListNotations.

(* ---------- 语法（□ 原生；◇ 导出） ---------- *)

Inductive mform : Type :=
| mAtom : nat -> mform
| mNeg  : mform -> mform
| mImp  : mform -> mform -> mform
| mBox  : mform -> mform
| mDia  : mform -> mform.      (* 原生：存在可达世界 *)

Definition mAnd (a b : mform) : mform := mNeg (mImp a (mNeg b)).

(* ---------- 框架与语义 ---------- *)

Record frame : Type := mkF {
  worlds : list nat;
  rel : nat -> nat -> bool;       (* 可达关系（任意） *)
  val : nat -> nat -> bool        (* 世界 -> 原子 -> 真值 *)
}.

Fixpoint msat (F : frame) (w : nat) (f : mform) : Prop :=
  match f with
  | mAtom p => val F w p = true
  | mNeg a => ~ msat F w a
  | mImp a b => msat F w a -> msat F w b
  | mBox a => forall v, In v (worlds F) ->
              rel F w v = true -> msat F v a
  | mDia a => exists v, In v (worlds F) /\ rel F w v = true /\ msat F v a
  end.

(* ---------- 旗舰一：K 模式（分配律）——K 只担保 K ---------- *)

Theorem K_valid : forall F w a b,
  msat F w (mImp (mBox (mImp a b)) (mImp (mBox a) (mBox b))).
Proof.
  intros F w a b HKa HP v Hv Hrel.
  apply (HKa v Hv Hrel).
  apply HP; assumption.
Qed.

(* ---------- 旗舰二：必然化规则 ---------- *)

(* 注意方向：「前提无世界限定」才能必然化——
   「定理」的模态提升是规则不是蕴含：□(p→p) 有效但 p→□p 无效 *)
Theorem nec : forall (a : mform),
  (forall F w, In w (worlds F) -> msat F w a) ->
  (forall F w, In w (worlds F) -> msat F w (mBox a)).
Proof.
  intros a Ha F w Hw v Hv Hrel.
  apply Ha; assumption.
Qed.

(* 现场：前提的「无世界限定」不可少——p → □p 不是有效式 *)
Definition lone : frame := {|
  worlds := [0; 1];
  rel := fun x y => match x, y with 0, 1 => true | _, _ => false end;
  val := fun w p => match w, p with 0, 0 => true | _, _ => false end |}.

Example p_not_boxp :
  ~ (forall F w, In w (worlds F) ->
       msat F w (mImp (mAtom 0) (mBox (mAtom 0)))).
Proof.
  intros Hall.
  specialize (Hall lone 0 (or_introl eq_refl) eq_refl).
  simpl in Hall.
  (* Hall : 一切 0-可达世界 p 真——但 1 可达自 0 而 p 在 1 假 *)
  specialize (Hall 1 (or_intror (or_introl eq_refl)) eq_refl).
  simpl in Hall. discriminate.
Qed.

(* ---------- 旗舰三：◇ 对偶 ---------- *)

From Stdlib Require Import Classical_Prop.

Theorem dia_dual : forall F w a,
  msat F w (mDia a) <-> ~ msat F w (mBox (mNeg a)).
Proof.
  intros F w a. split.
  - intros [v [Hv [Hrel Hsat]]] HBox.
    apply (HBox v Hv Hrel). exact Hsat.
  - intros HN.
    (* 经典步骤：可达关系有限的见证提取 *)
    destruct (classic (exists v, In v (worlds F) /\
                                rel F w v = true /\ msat F v a)) as
      [[v [Hv [Hrel Hsat]]] | Hno].
    + exists v. split; [exact Hv | split; assumption].
    + exfalso. apply HN. intros v Hv Hrel.
      (* 反证面：一切可达世界都 ¬a *)
      destruct (classic (msat F v a)) as [Hyes | Hno2].
      * exfalso. apply Hno. exists v. split; [exact Hv|split; assumption].
      * exact Hno2.
Qed.


(* ---------- 旗舰四：□ 对 ∧ 分配（一半） ---------- *)

(* □ 对 ∧ 的分配（一半）：□(a∧b) ⟹ □a ∧ □b（语义层陈述） *)
Theorem box_and_fwd : forall F w a b,
  (forall v, In v (worlds F) -> rel F w v = true ->
     msat F v a /\ msat F v b) ->
  (forall v, In v (worlds F) -> rel F w v = true -> msat F v a)
  /\ (forall v, In v (worlds F) -> rel F w v = true -> msat F v b).
Proof.
  intros F w a b H. split.
  - intros v Hv Hrel. apply (H v Hv Hrel).
  - intros v Hv Hrel. apply (H v Hv Hrel).
Qed.

(* ---------- 反例现场（§5.3.1 图 5.3）：K 不担保 T/4 ---------- *)

(* 非自反框架：x1 → x2（x2 无出边），p 只在 x2 真
   —— x1 ⊨ □p 但 x1 ⊭ p：□p → p 失效 *)
Definition fnoRef : frame := {|
  worlds := [1; 2];
  rel := fun x y => match x, y with 1, 2 => true | _, _ => false end;
  val := fun w p => match w, p with 2, 0 => true | _, _ => false end |}.

Example T_fails : ~ msat fnoRef 1 (mImp (mBox (mAtom 0)) (mAtom 0)).
Proof.
  intros H.
  assert (Hbox : msat fnoRef 1 (mBox (mAtom 0))).
  { intros v [Hv | [Hv | []]]; subst v; simpl.
    - discriminate.  (* rel 1 1 = false *)
    - reflexivity. }  (* rel 1 2 = true，p 在 2 真 *)
  assert (Hp : msat fnoRef 1 (mAtom 0)) by (apply H; exact Hbox).
  simpl in Hp. discriminate.
Qed.

(* 非传递框架：x1 → x2 → x1（x1 无别的出边），p 只在 x1 真
   —— x2 ⊨ □p 但 x2 ⊭ □□p：□p → □□p 失效 *)
Definition fnoTrans : frame := {|
  worlds := [1; 2];
  rel := fun x y => match x, y with 1, 2 | 2, 1 => true | _, _ => false end;
  val := fun w p => match w, p with 1, 0 => true | _, _ => false end |}.

Example four_fails :
  ~ msat fnoTrans 2 (mImp (mBox (mAtom 0)) (mBox (mBox (mAtom 0)))).
Proof.
  intros H. simpl in H.
  assert (Hbox : msat fnoTrans 2 (mBox (mAtom 0))).
  { intros v [Hv | [Hv | []]]; subst v; simpl; auto. }
  specialize (H Hbox).
  (* 1 可达自 2；而 2 又可达自 1，p 在 2 假——□□ 在 2 崩 *)
  specialize (H 1 (or_introl eq_refl) eq_refl).
  specialize (H 2 (or_intror (or_introl eq_refl)) eq_refl).
  simpl in H. discriminate.
Qed.

(* 坑位速记（Coq 侧）：
   - rel 用 bool 函数（nat->nat->bool）而非 Prop 谓词——
     match 字面量的反例框架可以 reflexivity 直算；
   - nec 的方向坑：规则是「前提无世界限定」——p→□p 反例
     （lone）的失败面在「前提在世界 0 真」而 0 的可达世界不含
     p——前提的全称性不可少；
   - dia_dual 的 ◇ 方向需要经典（存在见证的反证提取）——
     classic 入账与 36 章 G_dual_bwd 同款口径；
   - 反例框架的世界有限列举使 □ 展开是**有限全称**——
     逐可达世界手工核（In 表 + rel match 双重 simpl）。 *)
