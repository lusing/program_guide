(* 第 75 章：传递化：刚性与有秩关系（冯琦 §1.10）——Coq 通道 *)
(* HF 彻底有限集合（玫瑰树 HFset (list HF)）+ 可判等（Scheme Equality *)
(* 自动生成 eqb 与 eq_dec——嵌套 list 归纳类型也能自动落）；有限坍缩 *)
(* 器（燃料法 π(a) = HFset (map π (ext a))）在四个现场对拍定理 1.100 *)
(* 的每一条：偶数链坍缩成冯诺伊曼数字（例 1.35）、刚性同像、例 1.34 *)
(* 不自同一相撞、2-循环秩分层覆盖率为零（定理 1.98 的反向）。 *)
From Coq Require Import Arith Lia List Bool.
Import ListNotations.

Module Ch75.

(* ---------- HF 世界：彻底有限集合 = 玫瑰树 ---------- *)
Inductive HF : Set := HFset (children : list HF).

(* 可判等：参数化列表 beq + 高阶嵌套递归（hfl_beq HF_beq——guard 认
   高阶形态；互归手写、Scheme Equality、stdlib list_beq 三无路，8.20） *)
Fixpoint hfl_beq (f : HF -> HF -> bool) (la lb : list HF) : bool :=
  match la with
  | [] => match lb with
          | [] => true
          | _ => false
          end
  | x :: xs => match lb with
               | [] => false
               | y :: ys => f x y && hfl_beq f xs ys
               end
  end.

Fixpoint HF_beq (a b : HF) {struct a} : bool :=
  match a with
  | HFset la =>
    match b with
    | HFset lb => hfl_beq HF_beq la lb
    end
  end.

(* 玫瑰树的归纳原理（嵌套 list 的 IH 必须手工立；
   外层 fix + 内层 list 归纳：单 fix 认嵌套子项） *)
Lemma HF_mut_ind : forall (P : HF -> Prop) (PL : list HF -> Prop),
  (forall l, PL l -> P (HFset l)) ->
  PL [] ->
  (forall x xs, P x -> PL xs -> PL (x :: xs)) ->
  forall h, P h.
Proof.
  intros P PL Hnode Hnil Hcons.
  fix IH 1.
  intros [l]. apply Hnode.
  induction l as [| x xs IHxs].
  - exact Hnil.
  - apply Hcons.
    + apply IH.
    + exact IHxs.
Qed.

(* eqb 正确性（归纳原理的第一次上岗） *)
Lemma HF_beq_eq : forall a b, HF_beq a b = true -> a = b.
Proof.
  apply (HF_mut_ind
           (fun a => forall b, HF_beq a b = true -> a = b)
           (fun la => forall lb, hfl_beq HF_beq la lb = true -> la = lb)).
  - intros l IH [lb] H. simpl in H. f_equal. apply IH. exact H.
  - intros [ | y ys] H. reflexivity. discriminate.
  - intros x xs Px Pxs [ | y ys] H.
    + discriminate.
    + simpl in H. apply andb_prop in H. destruct H as [H1 H2].
      f_equal.
      * apply Px. exact H1.
      * apply Pxs. exact H2.
Qed.

Lemma HF_beq_refl : forall a, HF_beq a a = true.
Proof.
  apply (HF_mut_ind
           (fun a => HF_beq a a = true)
           (fun la => hfl_beq HF_beq la la = true)).
  - intros l IH. simpl. exact IH.
  - reflexivity.
  - intros x xs Px Pxs. simpl. rewrite Px, Pxs. reflexivity.
Qed.

Lemma HF_eq_dec : forall a b : HF, {a = b} + {a <> b}.
Proof.
  intros a b. destruct (HF_beq a b) eqn:E.
  - left. apply HF_beq_eq. exact E.
  - right. intros Heq. subst b. rewrite HF_beq_refl in E. discriminate.
Qed.

Definition children (h : HF) : list HF :=
  match h with HFset l => l end.

(* 冯诺伊曼数字：0 = ∅、n+1 = n∪{n} *)
Fixpoint vn (n : nat) : HF :=
  match n with
  | 0 => HFset []
  | S k => HFset (children (vn k) ++ [vn k])
  end.

(* ---------- 成员与传递 ---------- *)
Definition hfl_memb (x : HF) (l : list HF) : bool :=
  existsb (fun y => HF_beq x y) l.

Definition memb (x y : HF) : bool :=
  match y with HFset l => hfl_memb x l end.

(* M 传递：x ∈ y ∈ M → x ∈ M *)
Definition is_transitive (m : HF) : bool :=
  forallb (fun y => forallb (fun x => hfl_memb x (children m))
                              (children y))
          (children m).

(* ---------- 坍缩器（燃料法；燃料 ≥ 最大秩+1） ---------- *)
Definition ext_of (g : list (nat * list nat)) (a : nat) : list nat :=
  match find (fun p => fst p =? a) g with
  | Some (_, zs) => zs
  | None => []
  end.

Fixpoint pi_f (fuel : nat) (g : list (nat * list nat)) (a : nat) : HF :=
  match fuel with
  | 0 => HFset []
  | S f => HFset (map (pi_f f g) (ext_of g a))
  end.

Definition collapse_image (fuel : nat) (g : list (nat * list nat))
                          (nodes : list nat) : HF :=
  HFset (map (pi_f fuel g) nodes).

(* π 单射检查（自同一前提的另一半） *)
Definition pi_inj (fuel : nat) (g : list (nat * list nat))
                  (nodes : list nat) : bool :=
  forallb (fun a => forallb (fun b =>
    if HF_beq (pi_f fuel g a) (pi_f fuel g b) then a =? b else true)
    nodes) nodes.

(* ---------- 现场一：偶数链（例 1.35 有限段） ---------- *)
Definition g_even : list (nat * list nat) :=
  [(0, []); (2, [0]); (4, [0; 2]); (6, [0; 2; 4])].
Definition nodes_even := [0; 2; 4; 6].

(* π(2n) = n：四个值逐个对拍 *)
Example pi_even_0 : pi_f 5 g_even 0 = vn 0. Proof. reflexivity. Qed.
Example pi_even_2 : pi_f 5 g_even 2 = vn 1. Proof. reflexivity. Qed.
Example pi_even_4 : pi_f 5 g_even 4 = vn 2. Proof. reflexivity. Qed.
Example pi_even_6 : pi_f 5 g_even 6 = vn 3. Proof. reflexivity. Qed.

(* 坍缩像 = 4（冯诺伊曼）且传递、π 单射（定理 1.100 的三验收） *)
Example image_even :
  collapse_image 5 g_even nodes_even = vn 4 /\
  is_transitive (vn 4) = true /\
  pi_inj 5 g_even nodes_even = true.
Proof. repeat split; reflexivity. Qed.

(* ---------- 现场二：刚性（定理 1.95）的计算面 ---------- *)
Definition g_odd : list (nat * list nat) :=
  [(1, []); (3, [1]); (5, [1; 3]); (7, [1; 3; 5])].
Definition nodes_odd := [1; 3; 5; 7].

(* 同构不同集，坍缩到同一 M *)
Example rigid_same_image :
  collapse_image 5 g_odd nodes_odd = collapse_image 5 g_even nodes_even.
Proof. reflexivity. Qed.

(* ---------- 现场三：例 1.34 不自同一 → 相撞 ---------- *)
Definition g_bad : list (nat * list nat) :=
  [(0, []); (1, [0]); (2, [0])].   (* "2"、"3"、"{2}" 的节点化 *)

Example bad_collision :
  pi_f 3 g_bad 1 = pi_f 3 g_bad 2 /\ pi_inj 3 g_bad [0; 1; 2] = false.
Proof.
  split.
  - reflexivity.
  - vm_compute. reflexivity.
Qed.

(* ---------- 现场四：秩分层器（定理 1.98）与 2-循环 ---------- *)
Definition covered_by (acc : list nat) (g : list (nat * list nat))
                      (nodes : list nat) : list nat :=
  filter (fun a =>
    negb (existsb (Nat.eqb a) acc) &&
    forallb (fun z => existsb (Nat.eqb z) acc) (ext_of g a)) nodes.

(* list nat 的相等判断（stdlib 无 list_beq，手卷） *)
Fixpoint nl_eqb (a b : list nat) : bool :=
  match a with
  | [] => match b with [] => true | _ => false end
  | x :: xs => match b with
               | [] => false
               | y :: ys => Nat.eqb x y && nl_eqb xs ys
               end
  end.

Fixpoint rank_cover2 (fuel : nat) (g : list (nat * list nat))
                     (nodes : list nat) (acc : list nat) : list nat :=
  match fuel with
  | 0 => acc
  | S f =>
    let new := covered_by acc g nodes in
    if nl_eqb new []
    then acc
    else rank_cover2 f g nodes (acc ++ new)
  end.

(* 外延 DAG：全部覆盖 *)
Definition g_dag : list (nat * list nat) :=
  [(0, []); (1, [0]); (2, [0; 1]); (3, [0; 2])].
Definition nodes_dag := [0; 1; 2; 3].

Example dag_full_cover :
  rank_cover2 6 g_dag nodes_dag [] = [0; 1; 2; 3].
Proof. vm_compute. reflexivity. Qed.

(* 2-循环：分层覆盖率为零——非有秩 ⟺ 不可分层的反向见证 *)
Definition g_cycle : list (nat * list nat) := [(0, [1]); (1, [0])].

Example cycle_no_cover :
  rank_cover2 6 g_cycle [0; 1] [] = [].
Proof. vm_compute. reflexivity. Qed.

End Ch75.
