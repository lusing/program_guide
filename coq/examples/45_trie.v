(* 45 Trie：字符串键的映射 —— positive 位串上的高效字典与正确性 *)

From Stdlib Require Import Arith Bool List Lia.
From Stdlib Require Import PArith.
From Stdlib Require Import ZArith.
From Stdlib Require Import FunctionalExtensionality.
Import ListNotations.

Module Ex45Trie.

(* ---------- 45.1 函数式编程的 logN 罚金 ---------- *)

Definition total_map (A : Type) : Type := nat -> A.

Definition t_empty {A : Type} (v : A) : total_map A := fun _ => v.

Definition t_update {A : Type} (m : total_map A) (x : nat) (v : A) :=
  fun x' => if Nat.eqb x x' then v else m x'.

Module VerySlow.

Fixpoint loop (input : list nat) (c : nat) (table : total_map bool) : nat :=
  match input with
  | [] => c
  | a :: al => if table a
               then loop al (c + 1) table
               else loop al c (t_update table a true)
  end.

Definition collisions (input : list nat) : nat :=
  loop input 0 (t_empty false).

Example collisions_pi : collisions [3;1;4;1;5;9;2;6] = 1.
Proof. reflexivity. Qed.

End VerySlow.

(* ---------- 45.2 positive：二进制正数的三色表示 ---------- *)

Module Integers.

Inductive positive : Set :=
  | xI : positive -> positive
  | xO : positive -> positive
  | xH : positive.

Definition ten := xO (xI (xO xH)).

Fixpoint positive2nat (p : positive) : nat :=
  match p with
  | xI q => 1 + 2 * positive2nat q
  | xO q => 0 + 2 * positive2nat q
  | xH => 1
  end.

Eval compute in positive2nat ten.  (* = 10 : nat *)

Fixpoint print_in_binary (p : positive) : list nat :=
  match p with
  | xI q => print_in_binary q ++ [1]
  | xO q => print_in_binary q ++ [0]
  | xH => [1]
  end.

Eval compute in print_in_binary ten.  (* = [1; 0; 1; 0] : list nat *)

Notation "p ~ 1" := (xI p).
Notation "p ~ 0" := (xO p).

Print ten.  (* = ((xH~0)~1)~0 : positive *)

(* ---------- 45.3 后继与进位加法 ---------- *)

Fixpoint succ x :=
  match x with
  | p~1 => (succ p)~0
  | p~0 => p~1
  | xH => xH~0
  end.

Fixpoint addc (carry : bool) (x y : positive) {struct x} : positive :=
  match carry, x, y with
  | false, p~1, q~1 => (addc true p q)~0
  | false, p~1, q~0 => (addc false p q)~1
  | false, p~1, xH => (succ p)~0
  | false, p~0, q~1 => (addc false p q)~1
  | false, p~0, q~0 => (addc false p q)~0
  | false, p~0, xH => p~1
  | false, xH, q~1 => (succ q)~0
  | false, xH, q~0 => q~1
  | false, xH, xH => xH~0
  | true, p~1, q~1 => (addc true p q)~1
  | true, p~1, q~0 => (addc true p q)~0
  | true, p~1, xH => (succ p)~1
  | true, p~0, q~1 => (addc true p q)~0
  | true, p~0, q~0 => (addc false p q)~1
  | true, p~0, xH => (succ p)~0
  | true, xH, q~1 => (succ q)~1
  | true, xH, q~0 => (succ q)~0
  | true, xH, xH => xH~1
  end.

Definition add (x y : positive) : positive := addc false x y.

Lemma positive2nat_pos :
 forall p, positive2nat p > 0.
Proof.
intros.
induction p; simpl; lia.
Qed.

Lemma succ_correct : forall p,
  positive2nat (succ p) = S (positive2nat p).
Proof.
intros. induction p as [p IH | p IH |]; simpl; try rewrite IH; lia.
Qed.

Lemma addc_correct : forall (c : bool) (p q : positive),
  positive2nat (addc c p q) =
    (if c then 1 else 0) + positive2nat p + positive2nat q.
Proof.
intros c p q. revert c q.
induction p as [p IH | p IH |]; intros c q; destruct c; destruct q as [r | r |];
  simpl in *; try rewrite IH; try rewrite succ_correct; simpl; lia.
Qed.

Theorem add_correct : forall (p q : positive),
  positive2nat (add p q) = positive2nat p + positive2nat q.
Proof.
intros. unfold add. apply addc_correct.
Qed.

(* ---------- 45.4 三向比较与标准库里的 positive、Z ---------- *)

Inductive comparison : Set :=
  | Eq : comparison | Lt : comparison | Gt : comparison.

Fixpoint compare (x y : positive) {struct x} : comparison :=
  match x, y with
  | p~1, q~1 => compare p q
  | p~1, q~0 => match compare p q with Lt => Lt | _ => Gt end
  | p~1, xH => Gt
  | p~0, q~1 => match compare p q with Gt => Gt | _ => Lt end
  | p~0, q~0 => compare p q
  | p~0, xH => Gt
  | xH, q~1 => Lt
  | xH, q~0 => Lt
  | xH, xH => Eq
  end.

Theorem compare_correct :
 forall x y,
  match compare x y with
  | Lt => positive2nat x < positive2nat y
  | Eq => positive2nat x = positive2nat y
  | Gt => positive2nat x > positive2nat y
  end.
Proof.
induction x as [p IH | p IH |]; intros y; destruct y as [q | q |]; simpl.
- (* xI / xI *) specialize (IH q). destruct (compare p q) eqn:E; simpl in *; lia.
- (* xI / xO *) specialize (IH q). destruct (compare p q) eqn:E; simpl in *; lia.
- (* xI / xH *) pose proof (positive2nat_pos p). lia.
- (* xO / xI *) specialize (IH q). destruct (compare p q) eqn:E; simpl in *; lia.
- (* xO / xO *) specialize (IH q). destruct (compare p q) eqn:E; simpl in *; lia.
- (* xO / xH *) pose proof (positive2nat_pos p). lia.
- (* xH / xI *) pose proof (positive2nat_pos q). lia.
- (* xH / xO *) pose proof (positive2nat_pos q). lia.
- (* xH / xH *) reflexivity.
Qed.

End Integers.

Print positive.  (* 标准库的 positive 与我们刚造的同构 *)

Check Pos.compare : positive -> positive -> comparison.

Check Pos.add : positive -> positive -> positive.

Check Z.add : Z -> Z -> Z.

Goal 10%positive = xO (xI (xO xH)).
Proof. reflexivity. Qed.

(* ---------- 45.5 效率阶梯的中间站：Z 键的函数式映射 ---------- *)

Module RatherSlow.

Definition total_mapz (A : Type) := Z -> A.

Definition empty {A : Type} (default : A) : total_mapz A := fun _ => default.

Definition update {A : Type} (m : total_mapz A) (x : Z) (v : A) :=
  fun x' => if Z.eqb x x' then v else m x'.

Fixpoint loop (input : list Z) (c : Z) (table : total_mapz bool) : Z :=
  match input with
  | [] => c
  | a :: al => if table a
               then loop al (c + 1) table
               else loop al c (update table a true)
  end.

Definition collisions (input : list Z) : Z :=
  loop input 0 (empty false).

Example collisions_pi : collisions [3;1;4;1;5;9;2;6]%Z = 1%Z.
Proof. reflexivity. Qed.

End RatherSlow.

(* ---------- 45.6 二叉 trie：定义与插入、查找 ---------- *)

Inductive trie (A : Type) :=
  | Leaf : trie A
  | Node : trie A -> A -> trie A -> trie A.
Arguments Leaf {A}.
Arguments Node {A} _ _ _.

Definition trie_table (A : Type) : Type := (A * trie A)%type.

Definition empty {A : Type} (default : A) : trie_table A :=
  (default, Leaf).

Fixpoint look {A : Type} (default : A) (i : positive) (m : trie A) : A :=
  match m with
  | Leaf => default
  | Node l x r =>
      match i with
      | xH => x
      | xO i' => look default i' l
      | xI i' => look default i' r
      end
  end.

Print look.  (* Rocq 自动选了 {struct i}：m=Leaf 也卡在 i 上 *)

Definition lookup {A : Type} (i : positive) (t : trie_table A) : A :=
  look (fst t) i (snd t).

Fixpoint ins {A : Type} default (i : positive) (a : A) (m : trie A) : trie A :=
  match m with
  | Leaf =>
      match i with
      | xH => Node Leaf a Leaf
      | xO i' => Node (ins default i' a Leaf) default Leaf
      | xI i' => Node Leaf default (ins default i' a Leaf)
      end
  | Node l o r =>
      match i with
      | xH => Node l a r
      | xO i' => Node (ins default i' a l) o r
      | xI i' => Node l o (ins default i' a r)
      end
  end.

Definition insert {A : Type} (i : positive) (a : A) (t : trie_table A)
  : trie_table A :=
  (fst t, ins (fst t) i a (snd t)).

Definition three_ten : trie_table bool :=
  insert 3 true (insert 10 true (empty false)).

Eval compute in three_ten.

Eval compute in map (fun i => lookup i three_ten) [3;1;4;1;5]%positive.

(* ---------- 45.7 查重程序终版：N 次 logN ---------- *)

Module FastEnough.

Fixpoint loop (input : list positive) (c : nat) (table : trie_table bool) : nat :=
  match input with
  | [] => c
  | a :: al => if lookup a table
               then loop al (1 + c) table
               else loop al c (insert a true table)
  end.

Definition collisions (input : list positive) : nat :=
  loop input 0 (empty false).

Example collisions_pi : collisions [3;1;4;1;5;9;2;6]%positive = 1.
Proof. reflexivity. Qed.

End FastEnough.

(* ---------- 45.8 lookup 与 insert 的关系引理 ---------- *)

Lemma look_leaf : forall A (a : A) j, look a j Leaf = a.
Proof.
intros. Fail reflexivity. destruct j; reflexivity.
Qed.

Lemma look_ins_same : forall {A} a k (v : A) t,
  look a k (ins a k v t) = v.
Proof.
intros A a k. induction k as [p IH | p IH |]; intros v t;
  destruct t as [| l o r]; simpl; try reflexivity; apply IH.
Qed.

Lemma look_ins_other : forall {A} a j k (v : A) t,
  j <> k -> look a j (ins a k v t) = look a j t.
Proof.
intros A a j. induction j as [p IH | p IH |]; intros k v t Hne;
  destruct t as [| l o r]; destruct k as [q | q |]; simpl in *;
  try contradiction; try reflexivity;
  try (rewrite IH by congruence; first [apply look_leaf | reflexivity]);
  try apply look_leaf.
Qed.

(* ---------- 45.9 positive 与 nat 的双射 ---------- *)

Definition nat2pos (n : nat) : positive := Pos.of_succ_nat n.

Definition pos2nat (n : positive) : nat := pred (Pos.to_nat n).

Lemma pos2nat2pos : forall p, nat2pos (pos2nat p) = p.
Proof.
intro. unfold nat2pos, pos2nat.
rewrite <- (Pos2Nat.id p) at 2.
destruct (Pos.to_nat p) eqn:?.
pose proof (Pos2Nat.is_pos p). lia.
rewrite <- Pos.of_nat_succ.
reflexivity.
Qed.

Lemma nat2pos2nat : forall i, pos2nat (nat2pos i) = i.
Proof.
intro. unfold nat2pos, pos2nat.
rewrite SuccNat2Pos.id_succ.
reflexivity.
Qed.

Lemma pos2nat_injective : forall p q, pos2nat p = pos2nat q -> p = q.
Proof.
intros p q H.
rewrite <- (pos2nat2pos p), <- (pos2nat2pos q), H.
reflexivity.
Qed.

Lemma nat2pos_injective : forall i j, nat2pos i = nat2pos j -> i = j.
Proof.
intros i j H.
rewrite <- (nat2pos2nat i), <- (nat2pos2nat j), H.
reflexivity.
Qed.

(* ---------- 45.10 「所见即所得」的抽象关系 ---------- *)

Definition is_trie {A : Type} (t : trie_table A) : Prop := True.

Definition abstract {A : Type} (t : trie_table A) (n : nat) : A :=
  lookup (nat2pos n) t.

Definition Abs {A : Type} (t : trie_table A) (m : total_map A) :=
  abstract t = m.

Theorem empty_is_trie : forall {A} (default : A), is_trie (empty default).
Proof. intros. exact I. Qed.

Theorem insert_is_trie : forall {A} i x (t : trie_table A),
  is_trie t -> is_trie (insert i x t).
Proof. intros. exact I. Qed.

Theorem empty_relate : forall {A} (default : A),
  Abs (empty default) (t_empty default).
Proof.
intros A default.
unfold Abs, abstract, empty, t_empty, lookup.
apply functional_extensionality. intro n.
apply look_leaf.
Qed.

Theorem lookup_relate : forall {A} i (t : trie_table A) m,
  is_trie t -> Abs t m -> lookup i t = m (pos2nat i).
Proof.
intros A i t m _ H. unfold Abs in H. rewrite <- H. unfold abstract.
rewrite pos2nat2pos. reflexivity.
Qed.

Theorem insert_relate : forall {A} k (v : A) t cts,
  is_trie t ->
  Abs t cts ->
  Abs (insert k v t) (t_update cts (pos2nat k) v).
Proof.
intros A k v t cts _ Habs.
unfold Abs in *; unfold abstract, t_update.
apply functional_extensionality. intro n.
destruct (Nat.eqb_spec (pos2nat k) n) as [E | E].
- rewrite <- E, pos2nat2pos. unfold insert, lookup.
  apply look_ins_same.
- rewrite <- Habs. unfold insert, lookup.
  apply look_ins_other.
  intro Heq. apply E. rewrite <- Heq. apply nat2pos2nat.
Qed.

Print Assumptions insert_relate.

Example Abs_three_ten :
  Abs (insert 3 true (insert 10 true (empty false)))
      (t_update (t_update (t_empty false) (pos2nat 10) true) (pos2nat 3) true).
Proof.
apply insert_relate.
- exact I.
- apply insert_relate.
  + exact I.
  + apply empty_relate.
Qed.

End Ex45Trie.
