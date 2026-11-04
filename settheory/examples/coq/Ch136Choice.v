(* 第 136 章 Coq：选择公理的浅嵌入账本（书 4.6）。

   ① AC 的函数形式作为公理记账——类型论不能证明它；
   ② 有限选择是纯构造（对族归纳）——AC 的公理性只属于无穷；
   ③ AC1 ⟹ AC2 的影子：选择函数给出两两不交族的选择集，
      且与每块之交为单点。 *)

Require Import List Arith Lia.
Import ListNotations.

(* ---------- ① AC 作为公理（记账，不证明） ---------- *)

Axiom AC1 : forall (I X : Type) (R : I -> X -> Prop),
  (forall i, exists x, R i x) ->
  exists f : I -> X, forall i, R i (f i).

Check AC1.

(* ---------- ② 有限选择：构造而非公理 ---------- *)

Fixpoint choice_list (F : list (list nat)) : list nat :=
  match F with
  | [] => []
  | L :: F' => hd 0 L :: choice_list F'
  end.

Theorem choice_length : forall F, length (choice_list F) = length F.
Proof.
  induction F as [|L F' IH]; simpl; auto.
Qed.

Theorem choice_picks_member : forall F L,
  In L F -> L <> [] -> In (hd 0 L) L.
Proof.
  intros F L HL Hne.
  destruct L as [|x xs]; [contradiction | simpl; left; reflexivity].
Qed.

(* ---------- ③ AC1 ⟹ AC2 的影子（书 4.6.1 (3)→(2)） ---------- *)

(* 给定选择函数 f，S = f[指标族] 是两两不交族的选择集：
   S 与每一块的交至多单点（恰好为 f i）。 *)
Theorem ac2_shadow : forall (idx : list nat) (Fam : nat -> list nat) (f : nat -> nat),
    (forall i, In i idx -> In (f i) (Fam i)) ->
    (forall i j a, In i idx -> In j idx -> i <> j ->
                   In a (Fam i) -> In a (Fam j) -> False) ->
    let S := map f idx in
    forall i a, In i idx -> In a S -> In a (Fam i) -> a = f i.
Proof.
  intros idx Fam f ok disj S i a Hi HaS HaFami.
  apply in_map_iff in HaS.
  destruct HaS as [j [Hj Inj]].
  destruct (Nat.eq_dec i j) as [Heq | Hne].
  - subst j. symmetry. exact Hj.
  - exfalso.
    assert (HfjFamj : In (f j) (Fam j)) by (apply ok; exact Inj).
    rewrite <- Hj in HaFami.
    eapply disj; eauto.
Qed.
