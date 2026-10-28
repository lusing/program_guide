(* 40 抽取：把验证代码变成 OCaml —— 证明擦除、Recursive Extraction、
   轻量 int 抽象、39 章风格 BST 的导出与 Module 抽象层的处理 *)

From Stdlib Require Import Arith Lia Bool List ZArith Extraction.
Import ListNotations.

Module Ex40Extract.

(* ---------- 40.1 证明被抹掉：抽取的第一原理 ---------- *)

(* 证明携带函数一：左边是 sigma（Set），右边是 Prop，整体是 sumor *)
Definition zero_or_succ (n : nat) : {m : nat | n = S m} + {n = 0}.
Proof. destruct n as [|m].
- right; reflexivity.
- left; exists m; reflexivity.
Defined.

Extraction zero_or_succ.

Recursive Extraction zero_or_succ.

(* 对照组：一条普通定理（Qed 收尾）抽出来是什么 *)
Theorem erased_theorem : forall n : nat, n + 0 = n.
Proof. intros n. lia. Qed.

Extraction erased_theorem.

(* 证明携带函数二：sumbool——判决过程保留，携带的证明被抹掉 *)
Definition leb_dec (n m : nat) : {n <= m} + {m < n}.
Proof.
  destruct (Nat.leb_spec0 n m) as [H | H].
  - left. exact H.
  - right. lia.
Defined.

Extraction leb_dec.

Compute (match zero_or_succ 5 with inleft _ => 111 | inright _ => 222 end).

(* 为什么 leb_dec 里的判决没被抹掉：9.3 的 reflect 已经是 Set 大类 *)
Print reflect.

(* ---------- 40.2 Recursive Extraction：第一个完整程序 ---------- *)

(* 自包含的插入排序（VFA《Extract》章的例子） *)
Fixpoint ins (i : nat) (l : list nat) :=
  match l with
  | [] => [i]
  | h :: t => if i <=? h then i :: h :: t else h :: ins i t
  end.

Fixpoint sort (l : list nat) : list nat :=
  match l with
  | [] => []
  | h :: t => ins h (sort t)
  end.

Compute (sort [3; 1; 2]).

Extraction sort.

Recursive Extraction sort.

(* 让抽取产物直接用 OCaml 原生的 bool 和 list *)
Extract Inductive bool => "bool" [ "true" "false" ].
Extract Inductive list => "list" [ "[]" "(::)" ].

Recursive Extraction sort.

(* ---------- 40.3 轻量 int 抽象：Parameter + Extract Inlined Constant ---------- *)

Open Scope Z_scope.

Parameter int : Type.
Extract Inlined Constant int => "int".

Parameter Abs : int -> Z.
Axiom Abs_inj : forall (n m : int), Abs n = Abs m -> n = m.

Parameter ltb : int -> int -> bool.
Extract Inlined Constant ltb => "( < )".
Axiom ltb_lt : forall (n m : int), ltb n m = true <-> Abs n < Abs m.

(* 反映桥：把公理包装成 reflect，主证明里就能 destruct 出 Abs 事实 *)
Lemma int_ltb_reflect : forall x y, reflect (Abs x < Abs y) (ltb x y).
Proof.
  intros x y. apply iff_reflect. symmetry. apply ltb_lt.
Qed.

Lemma ltb_irrefl : forall x, ltb x x = false.
Proof.
  intros x. destruct (ltb x x) eqn:E.
  - exfalso. assert (Hlt := proj1 (ltb_lt x x) E). lia.
  - reflexivity.
Qed.

(* ---------- 40.4 39 章风格 BST：int 键，验证后待抽取 ---------- *)

Definition key := int.

Inductive tree (V : Type) : Type :=
  | E : tree V
  | T : tree V -> key -> V -> tree V -> tree V.

Arguments E {V}.
Arguments T {V}.

Definition empty_tree {V : Type} : tree V := E.

Fixpoint lookup {V : Type} (default : V) (x : key) (t : tree V) : V :=
  match t with
  | E => default
  | T l k v r => if ltb x k then lookup default x l
                else if ltb k x then lookup default x r
                     else v
  end.

Fixpoint insert {V : Type} (x : key) (v : V) (t : tree V) : tree V :=
  match t with
  | E => T E x v E
  | T l y v' r => if ltb x y then T (insert x v l) y v' r
                 else if ltb y x then T l y v' (insert x v r)
                      else T l x v r
  end.

Fixpoint elements_aux {V : Type}
         (t : tree V) (acc : list (key * V)) : list (key * V) :=
  match t with
  | E => acc
  | T l k v r => elements_aux l ((k, v) :: elements_aux r acc)
  end.

Definition elements {V : Type} (t : tree V) : list (key * V) :=
  elements_aux t [].

Theorem lookup_empty : forall (V : Type) (default : V) (k : key),
    lookup default k empty_tree = default.
Proof. auto. Qed.

Theorem lookup_insert_eq :
  forall (V : Type) (default : V) (t : tree V) (k : key) (v : V),
    lookup default k (insert k v t) = v.
Proof.
  intros V default t. induction t as [| l IHl y v' r IHr]; intros k v; simpl.
  - rewrite !ltb_irrefl. reflexivity.
  - (* simpl 后再 destruct reflect：一次拆掉 insert 与 lookup 里的同一个 if *)
    destruct (int_ltb_reflect k y) as [Hk | Hk]; simpl.
    + destruct (int_ltb_reflect k y) as [Hk2 | Hk2].
      * apply IHl.
      * exfalso; lia.
    + destruct (int_ltb_reflect y k) as [Hy | Hy]; simpl.
      * destruct (int_ltb_reflect k y) as [Hk2 | Hk2].
        -- exfalso; lia.
        -- destruct (int_ltb_reflect y k) as [Hy2 | Hy2].
           ++ apply IHr.
           ++ exfalso; lia.
      * rewrite !ltb_irrefl. reflexivity.
Qed.

Theorem lookup_insert_neq :
  forall (V : Type) (default : V) (t : tree V) (k k' : key) (v : V),
    k <> k' -> lookup default k' (insert k v t) = lookup default k' t.
Proof.
  intros V default t. induction t as [| l IHl y v' r IHr];
    intros k k' v Hne; simpl.
  - (* 空树：k' 与 k 比大小，相等的那条路被 Hne 堵死 *)
    destruct (int_ltb_reflect k' k) as [H1 | H1].
    + reflexivity.
    + destruct (int_ltb_reflect k k') as [H2 | H2].
      * reflexivity.
      * exfalso. apply Hne. apply Abs_inj. lia.
  - destruct (int_ltb_reflect k y) as [Hk | Hk].
    + simpl. destruct (int_ltb_reflect k' y) as [H1 | H1].
      * apply IHl. exact Hne.
      * reflexivity.
    + destruct (int_ltb_reflect y k) as [Hy | Hy].
      * simpl. destruct (int_ltb_reflect k' y) as [H1 | H1].
        -- reflexivity.
        -- destruct (int_ltb_reflect y k') as [H2 | H2].
           ++ apply IHr. exact Hne.
           ++ reflexivity.
      * (* 两侧都不小于对方：Abs k = Abs y，即 k = y，只剩值不同 *)
        assert (Hky : k = y) by (apply Abs_inj; lia).
        subst y. simpl. destruct (int_ltb_reflect k' k) as [H1 | H1].
        -- reflexivity.
        -- destruct (int_ltb_reflect k k') as [H2 | H2].
           ++ reflexivity.
           ++ exfalso. apply Hne. apply Abs_inj. lia.
Qed.

(* 证明依赖公理；40.5 的抽取产物里却一条都看不到 *)
Print Assumptions lookup_insert_eq.

(* ---------- 40.5 落地：抽取成 .ml 文件 ---------- *)

(* 落 OCaml 原生积类型：键值对抽成 (k, v) 而非 fst/snd 记录 *)
Extract Inductive prod => "( * )" [ "( , )" ].

Recursive Extraction empty_tree insert lookup elements.

Set Extraction Output Directory ".".

Extraction "searchtree40.ml" empty_tree insert lookup elements.

(* ---------- 40.6 Module 抽象层：签名密封挡不住抽取 ---------- *)

Module Type KEYSIG.
  Parameter t : Type.
  Parameter ltb : t -> t -> bool.
End KEYSIG.

Module NatKeySealed : KEYSIG.
  Definition t := nat.
  Definition ltb := Nat.ltb.
End NatKeySealed.

Recursive Extraction NatKeySealed.ltb.

Module NatKeyOpen.
  Definition t := nat.
  Definition ltb := Nat.ltb.
End NatKeyOpen.

Recursive Extraction NatKeyOpen.ltb.

End Ex40Extract.
