(* ex32_correspondence —— 对应理论（H&R §5.3.2-5.3.3）

   对书：Huth&Ryan §5.3.2（可达关系的性质）/ §5.3.3（对应理论）
   依赖：31 章的 frame/msat 基础设施（自包含复制——章间不跨文件 import）

   交付：五条「框架性质 ⟹ 公式有效」（正向）+ T 的逆
   （□φ→φ 有效 ⟹ 自反——探针世界法）。
   逆方向的通法（H&R）：拿一个世界当探针，给否定方向造反赋值。 *)

From Stdlib Require Import List Bool Arith.
Import ListNotations.

(* ---------- 语法与语义（沿 31 章） ---------- *)

Inductive mform : Type :=
| mAtom : nat -> mform
| mNeg  : mform -> mform
| mImp  : mform -> mform -> mform
| mBox  : mform -> mform
| mDia  : mform -> mform.

Record frame : Type := mkF {
  worlds : list nat;
  rel : nat -> nat -> bool;
  val : nat -> nat -> bool
}.

Fixpoint msat (F : frame) (w : nat) (f : mform) : Prop :=
  match f with
  | mAtom p => val F w p = true
  | mNeg a => ~ msat F w a
  | mImp a b => msat F w a -> msat F w b
  | mBox a => forall v, In v (worlds F) ->
              rel F w v = true -> msat F v a
  | mDia a => exists v, In v (worlds F) /\
              rel F w v = true /\ msat F v a
  end.

(* ---------- T：自反 ⟹ □φ→φ（知识为真） ---------- *)

Theorem T_valid : forall F,
  (forall w, In w (worlds F) -> rel F w w = true) ->
  forall w f, In w (worlds F) ->
  msat F w (mImp (mBox f) f).
Proof.
  intros F Hrefl w f Hw Hbox.
  apply (Hbox w Hw). apply Hrefl. exact Hw.
Qed.

(* ---------- D：serial ⟹ □φ→◇φ（信念一致） ---------- *)

Theorem D_valid : forall F,
  (forall w, In w (worlds F) -> exists v, In v (worlds F) /\ rel F w v = true) ->
  forall w f, In w (worlds F) ->
  msat F w (mImp (mBox f) (mDia f)).
Proof.
  intros F Hser w f Hw Hbox.
  destruct (Hser w Hw) as [v [Hv Hrel]].
  exists v. split; [exact Hv|split; [exact Hrel|]].
  apply (Hbox v Hv Hrel).
Qed.

(* ---------- B：对称 ⟹ φ→□◇φ ---------- *)

Theorem B_valid : forall F,
  (forall x y, In x (worlds F) -> In y (worlds F) ->
               rel F x y = true -> rel F y x = true) ->
  forall w f, In w (worlds F) ->
  msat F w (mImp f (mBox (mDia f))).
Proof.
  intros F Hsym w f Hw Hf v Hv Hrel.
  exists w. split; [exact Hw|split].
  - apply Hsym; assumption.
  - exact Hf.
Qed.

(* ---------- 4：传递 ⟹ □φ→□□φ（正自省） ---------- *)

Theorem four_valid : forall F,
  (forall x y z, In x (worlds F) -> In y (worlds F) -> In z (worlds F) ->
     rel F x y = true -> rel F y z = true -> rel F x z = true) ->
  forall w f, In w (worlds F) ->
  msat F w (mImp (mBox f) (mBox (mBox f))).
Proof.
  intros F Htr w f Hw Hbox v Hv Hrel u Hu Hrel2.
  apply (Hbox u).
  - exact Hu.
  - apply (Htr w v u); assumption.
Qed.

(* ---------- 5：欧性 ⟹ ◇φ→□◇φ（负自省） ---------- *)

(* 欧性：x 的两个后继互相可见——v 见证 ◇，u 是任意后继，
   则 v 也是 u 的后继（欧性给 rel v u），◇f 在 u 由 v 复用见证 *)
Theorem five_valid : forall F,
  (forall x y z, In x (worlds F) -> In y (worlds F) -> In z (worlds F) ->
     rel F x y = true -> rel F x z = true -> rel F y z = true) ->
  forall w f, In w (worlds F) ->
  msat F w (mImp (mDia f) (mBox (mDia f))).
Proof.
  intros F Heu w f Hw [v [Hv [Hrelv Hfv]]] u Hu Hrelu.
  assert (Huv : rel F u v = true).
  { apply (Heu w u v); assumption. }
  exists v. split; [exact Hv|split; [exact Huv|exact Hfv]].
Qed.

(* ---------- T 的逆：公式对**一切赋值**有效 ⟹ 自反 ---------- *)

(* 陈述的正确形态：有效性必须遍历赋值（H&R 的 valid 在「一切
   模型」上）——探针赋值（p 只在 w 假）才能合法造出 *)
Theorem T_converse : forall (ws : list nat) (r : nat -> nat -> bool),
  (forall (V : nat -> nat -> bool) (w : nat) (f : mform),
     In w ws -> msat (mkF ws r V) w (mImp (mBox f) f)) ->
  forall w, In w ws -> r w w = true.
Proof.
  intros ws r Hall w Hw.
  destruct (r w w) eqn:E; [reflexivity|].
  exfalso.
  (* 探针赋值 V₀：原子 0 在 w 假、其他世界沿用任意值 *)
  pose (V0 := fun x p => match Nat.eqb x w, Nat.eqb p 0 with
                         | true, true => false
                         | _, _ => true end).
  specialize (Hall V0 w (mAtom 0) Hw) as Himp.
  assert (Hbox : msat (mkF ws r V0) w (mBox (mAtom 0))).
  { intros v Hv Hrel.
    assert (Hvw : v <> w).
    { intros Ew. subst v. simpl in Hrel.
      rewrite E in Hrel. discriminate. }
    simpl. unfold V0.
    rewrite (proj2 (Nat.eqb_neq v w) Hvw). reflexivity. }
  assert (Hp : msat (mkF ws r V0) w (mAtom 0)).
  { apply Himp. exact Hbox. }
  simpl in Hp. unfold V0 in Hp.
  rewrite Nat.eqb_refl in Hp.
  discriminate.
Qed.

(* 坑位速记（Coq 侧）：
   - 五条正向的共性：性质直接喂给 □/◇ 的语义条款——B/5 的
     见证复用（原世界回投/原 ◇ 见证再挂一层）是全部机智；
   - T_converse 的陈述必须遍历**赋值**——有效性对「一切模型」
     而非「固定赋值」；探针赋值造在 V0 里（match 双 Nat.eqb），
     □p 的每个后继 v ≠ w 处 V0 v 0 = true 由双 eqb_spec 拆；
   - bool_dec 的引用（Coq.Arith.Bool 计划内）——bool 二值
     拆解在 exfalso 路上先行。 *)
