(* 44 二项式堆 —— carry 链插入、pow2 堆不变量与元素同构 *)

From Stdlib Require Import Arith Bool Lia List Permutation.
Import ListNotations.

Module Ex44Binom.

(* ---------- 44.1 程序：tree、priqueue 与 carry 链插入 ---------- *)

Definition key := nat.

Inductive tree : Type :=
| Node : key -> tree -> tree -> tree
| Leaf : tree.

Definition priqueue := list tree.

Definition empty : priqueue := nil.

Definition smash (t u : tree) : tree :=
  match t, u with
  | Node x t1 Leaf, Node y u1 Leaf =>
      if y <? x then Node x (Node y u1 t1) Leaf
               else Node y (Node x t1 u1) Leaf
  | _, _ => Leaf (* bogus tree for ill-formed input *)
  end.

Fixpoint carry (q : list tree) (t : tree) : list tree :=
  match q, t with
  | nil, Leaf => nil
  | nil, _ => t :: nil
  | Leaf :: q', _ => t :: q'
  | u :: q', Leaf => u :: q'
  | u :: q', _ => Leaf :: carry q' (smash t u)
  end.

Definition insert (x : key) (q : priqueue) : priqueue :=
  carry q (Node x Leaf Leaf).

Example insert_pi :
  fold_left (fun q x => insert x q) [3;1;4;1;5;9;2;3;5] empty =
  [Node 5 Leaf Leaf; Leaf; Leaf;
   Node 9 (Node 4 (Node 3 (Node 1 Leaf Leaf) (Node 1 Leaf Leaf))
                  (Node 3 (Node 2 Leaf Leaf) (Node 5 Leaf Leaf))) Leaf].
Proof. reflexivity. Qed.

(* ---------- 44.2 join、unzip 与 delete_max ---------- *)

Fixpoint join (p q : priqueue) (c : tree) : priqueue :=
  match p, q, c with
  | [], _, _ => carry q c
  | _, [], _ => carry p c
  | Leaf :: p', Leaf :: q', _ => c :: join p' q' Leaf
  | Leaf :: p', q1 :: q', Leaf => q1 :: join p' q' Leaf
  | Leaf :: p', q1 :: q', Node _ _ _ => Leaf :: join p' q' (smash c q1)
  | p1 :: p', Leaf :: q', Leaf => p1 :: join p' q' Leaf
  | p1 :: p', Leaf :: q', Node _ _ _ => Leaf :: join p' q' (smash c p1)
  | p1 :: p', q1 :: q', _ => c :: join p' q' (smash p1 q1)
  end.

Fixpoint unzip (t : tree) (cont : priqueue -> priqueue) : priqueue :=
  match t with
  | Node x t1 t2 => unzip t2 (fun q => Node x t1 Leaf :: cont q)
  | Leaf => cont nil
  end.

Definition heap_delete_max (t : tree) : priqueue :=
  match t with
  | Node x t1 Leaf => unzip t1 (fun u => u)
  | _ => nil (* bogus value for ill-formed or empty trees *)
  end.

Fixpoint find_max' (current : key) (q : priqueue) : key :=
  match q with
  | [] => current
  | Leaf :: q' => find_max' current q'
  | Node x _ _ :: q' => find_max' (if current <? x then x else current) q'
  end.

Fixpoint find_max (q : priqueue) : option key :=
  match q with
  | [] => None
  | Leaf :: q' => find_max q'
  | Node x _ _ :: q' => Some (find_max' x q')
  end.

Fixpoint delete_max_aux (m : key) (p : priqueue) : priqueue * priqueue :=
  match p with
  | Leaf :: p' => let (j, k) := delete_max_aux m p' in (Leaf :: j, k)
  | Node x t1 Leaf :: p' =>
      if x <? m
      then (let (j, k) := delete_max_aux m p' in (Node x t1 Leaf :: j, k))
      else (Leaf :: p', heap_delete_max (Node x t1 Leaf))
  | _ => (nil, nil) (* bogus value *)
  end.

Definition delete_max (q : priqueue) : option (key * priqueue) :=
  match find_max q with
  | None => None
  | Some m => let (p', q') := delete_max_aux m q in Some (m, join p' q' Leaf)
  end.

Definition merge (p q : priqueue) := join p q Leaf.

Example delete_max_small :
  delete_max (insert 5 (insert 2 (insert 4 empty))) =
  Some (5, [Leaf; Node 4 (Node 2 Leaf Leaf) Leaf]).
Proof. reflexivity. Qed.

(* ---------- 44.3 表示不变量：pow2heap 与 priq ---------- *)

(* t 是深度 n 的满二叉树，且每个键 <= m *)
Fixpoint pow2heap' (n : nat) (m : key) (t : tree) : Prop :=
  match n, m, t with
  | 0, _, Leaf => True
  | 0, _, Node _ _ _ => False
  | S _, _, Leaf => False
  | S n', _, Node k l r => m >= k /\ pow2heap' n' k l /\ pow2heap' n' m r
  end.

(* t 是深度 n 的 2 的幂堆 *)
Definition pow2heap (n : nat) (t : tree) : Prop :=
  match t with
  | Node m t1 Leaf => pow2heap' n m t1
  | _ => False
  end.

(* q 的第 i 个分量要么是 Leaf、要么是深 i 的 2 的幂堆 *)
Fixpoint priq' (i : nat) (l : list tree) : Prop :=
  match l with
  | t :: l' => (t = Leaf \/ pow2heap i t) /\ priq' (S i) l'
  | nil => True
  end.

Definition priq (q : priqueue) : Prop := priq' 0 q.

Theorem empty_priq : priq empty.
Proof. unfold priq, empty. simpl. exact I. Qed.

Theorem smash_valid :
  forall n t u, pow2heap n t -> pow2heap n u -> pow2heap (S n) (smash t u).
Proof.
  intros n [x t1 [k a b | ] | ] [y u1 [k' a' b' | ] | ] Ht Hu;
    unfold pow2heap in Ht, Hu; simpl in Ht, Hu;
    try contradiction.
  simpl. destruct (y <? x) eqn:E.
  - apply Nat.ltb_lt in E. simpl. split; [lia | split; assumption].
  - apply Nat.ltb_ge in E. simpl. split; [lia | split; assumption].
Qed.

Theorem carry_valid :
  forall q n, priq' n q ->
  forall t, (t = Leaf \/ pow2heap n t) -> priq' n (carry q t).
Proof.
  induction q as [ | u q' IH]; intros n Hq t Ht.
  - destruct t as [x t1 t2 | ]; simpl.
    + split; [exact Ht | exact I].
    + exact I.
  - simpl in Hq. destruct Hq as [Hu Hq'].
    destruct u as [y u1 u2 | ]; destruct t as [x t1 t2 | ].
    + (* u = Node, t = Node : 进位递归 *)
      destruct Hu as [Hul | Hup]; [discriminate Hul |].
      destruct Ht as [Htl | Htp]; [discriminate Htl |].
      cbn [priq' carry]. split; [left; reflexivity |].
      apply IH; [exact Hq' | right; apply smash_valid; assumption].
    + (* u = Node, t = Leaf : 原样保留 *)
      destruct Hu as [Hul | Hup]; [discriminate Hul |].
      cbn [priq' carry]. split; [right; exact Hup | exact Hq'].
    + (* u = Leaf, t = Node : 直接放行 *)
      cbn [priq' carry]. split; [exact Ht | exact Hq'].
    + (* u = Leaf, t = Leaf : 恒等 *)
      cbn [priq' carry]. split; [left; reflexivity | exact Hq'].
Qed.

Theorem insert_priq : forall x q, priq q -> priq (insert x q).
Proof.
  intros x q H. unfold insert, priq in *.
  apply (carry_valid q 0 H). right. simpl. exact I.
Qed.

(* ---------- 44.4 抽象关系：tree_elems 与 priqueue_elems ---------- *)

Inductive tree_elems : tree -> list key -> Prop :=
| tree_elems_leaf : tree_elems Leaf nil
| tree_elems_node : forall bl br v tl tr b,
    tree_elems tl bl ->
    tree_elems tr br ->
    Permutation b (v :: bl ++ br) ->
    tree_elems (Node v tl tr) b.

(* 原书练习 priqueue_elems：参照 tree_elems 的「任意置换」技巧补全 *)
Inductive priqueue_elems : list tree -> list key -> Prop :=
| priqueue_elems_nil : priqueue_elems nil nil
| priqueue_elems_cons : forall t b q l al,
    tree_elems t b ->
    priqueue_elems q l ->
    Permutation al (b ++ l) ->
    priqueue_elems (t :: q) al.

Definition Abs (p : priqueue) (al : list key) := priqueue_elems p al.

Theorem priqueue_elems_ext : forall q e1 e2,
  Permutation e1 e2 -> priqueue_elems q e1 -> priqueue_elems q e2.
Proof.
  intros q e1 e2 P H.
  inversion H as [ | t b q0 l al Ht Hp Hperm]; subst.
  - apply Permutation_nil in P. subst. constructor.
  - apply priqueue_elems_cons with (b := b) (l := l);
      [exact Ht | exact Hp |].
    apply Permutation_trans with e1;
      [apply Permutation_sym; exact P | exact Hperm].
Qed.

Theorem tree_perm : forall t e1 e2,
  tree_elems t e1 -> tree_elems t e2 -> Permutation e1 e2.
Proof.
  intros t e1 e2 H1. revert e2.
  induction H1 as [ | bl br v tl tr b Hbl IHl Hbr IHr Hperm]; intros e2 H2.
  - inversion H2; subst. apply Permutation_refl.
  - inversion H2 as [ | bl' br' v' tl' tr' b' Hbl' Hbr' Hperm']; subst.
    apply Permutation_trans with (v :: bl ++ br); [exact Hperm |].
    apply Permutation_trans with (v :: bl' ++ br').
    + apply perm_skip. apply Permutation_app;
        [exact (IHl bl' Hbl') | exact (IHr br' Hbr')].
    + apply Permutation_sym. exact Hperm'.
Qed.

Theorem abs_perm : forall p al bl,
  priq p -> Abs p al -> Abs p bl -> Permutation al bl.
Proof.
  intros p al bl _ HA1. revert bl.
  induction HA1 as [ | t b q l al Ht HA1 IH Hperm]; intros bl HA2.
  - inversion HA2; subst. apply Permutation_refl.
  - inversion HA2 as [ | t' b' q' l' al' Ht' HA2' Hperm']; subst.
    apply Permutation_trans with (b ++ l); [exact Hperm |].
    apply Permutation_trans with (b' ++ l').
    + apply Permutation_app;
        [exact (tree_perm t b b' Ht Ht') | exact (IH l' HA2')].
    + apply Permutation_sym. exact Hperm'.
Qed.

Theorem empty_relate : Abs empty nil.
Proof. unfold Abs, empty. constructor. Qed.

(* ---------- 44.5 操作保持抽象关系 ---------- *)

Theorem smash_elems : forall n t u bt bu,
  pow2heap n t -> pow2heap n u ->
  tree_elems t bt -> tree_elems u bu ->
  tree_elems (smash t u) (bt ++ bu).
Proof.
  intros n [x t1 [k a b | ] | ] [y u1 [k' a' b' | ] | ] bt bu Ht Hu Hbt Hbu;
    unfold pow2heap in Ht, Hu; simpl in Ht, Hu;
    try contradiction.
  inversion Hbt as [ | b1 b2 x' t1' t2' bt' Hb1 Hb2 Pbt]; subst.
  inversion Hbu as [ | b1' b2' y' u1' u2' bu' Hb1' Hb2' Pbu]; subst.
  inversion Hb2; subst. inversion Hb2'; subst.
  rewrite app_nil_r in Pbt, Pbu. simpl.
  destruct (y <? x) eqn:E.
  - (* 大者做根，小者做次根 *)
    apply tree_elems_node with (bl := y :: b1' ++ b1) (br := nil);
      [ | constructor |].
    + apply tree_elems_node with (bl := b1') (br := b1);
        [exact Hb1' | exact Hb1 | apply Permutation_refl].
    + apply Permutation_trans with ((x :: b1) ++ (y :: b1'));
        [apply Permutation_app; assumption |].
      rewrite app_nil_r. apply perm_skip.
      apply Permutation_trans with (y :: b1 ++ b1');
        [apply Permutation_sym; apply Permutation_middle
         | apply perm_skip; apply Permutation_app_comm].
  - (* 对称分支 *)
    apply tree_elems_node with (bl := x :: b1 ++ b1') (br := nil);
      [ | constructor |].
    + apply tree_elems_node with (bl := b1) (br := b1');
        [exact Hb1 | exact Hb1' | apply Permutation_refl].
    + apply Permutation_trans with ((x :: b1) ++ (y :: b1'));
        [apply Permutation_app; assumption |].
      rewrite app_nil_r. simpl.
      apply Permutation_trans with (x :: y :: b1 ++ b1');
        [apply perm_skip; apply Permutation_sym; apply Permutation_middle
         | apply perm_swap].
Qed.

Theorem carry_elems :
  forall q n, priq' n q ->
  forall t, (t = Leaf \/ pow2heap n t) ->
  forall eq et, priqueue_elems q eq ->
  tree_elems t et ->
  priqueue_elems (carry q t) (eq ++ et).
Proof.
  induction q as [ | u q' IH]; intros n Hq t Ht eq et Heq Het.
  - (* q = nil *)
    inversion Heq; subst.
    destruct t as [x t1 t2 | ].
    + (* t = Node : 落在末位 *)
      simpl.
      apply priqueue_elems_ext with (et ++ []);
        [rewrite app_nil_r; apply Permutation_refl |].
      apply priqueue_elems_cons with (b := et) (l := []);
        [exact Het | constructor | apply Permutation_refl].
    + (* t = Leaf : 空堆进空树 *)
      inversion Het; subst. simpl. constructor.
  - (* q = u :: q' *)
    simpl in Hq. destruct Hq as [Hu Hq'].
    destruct u as [y u1 u2 | ]; destruct t as [x t1 t2 | ].
    + (* u = Node, t = Node : 相撞进位 *)
      inversion Heq as [ | t0 b0 q0 l0 al0 Ht0 Hl0 P_eq]; subst.
      destruct Hu as [Hul | Hup]; [discriminate Hul |].
      destruct Ht as [Htl | Htp]; [discriminate Htl |].
      cbn [carry].
      apply priqueue_elems_ext with (l0 ++ (et ++ b0)).
      * rewrite app_assoc.
        apply Permutation_trans with (b0 ++ (l0 ++ et));
          [apply Permutation_app_comm |].
        rewrite app_assoc. apply Permutation_app_tail.
        apply Permutation_sym. exact P_eq.
      * apply priqueue_elems_cons with (b := nil) (l := l0 ++ (et ++ b0));
          [constructor | | apply Permutation_refl].
        assert (Hsm : pow2heap (S n) (smash (Node x t1 t2) (Node y u1 u2)))
          by (apply smash_valid; assumption).
        assert (Hse : tree_elems (smash (Node x t1 t2) (Node y u1 u2)) (et ++ b0))
          by (apply (smash_elems n (Node x t1 t2) (Node y u1 u2) et b0); assumption).
        exact (IH (S n) Hq' _ (or_intror Hsm) l0 (et ++ b0) Hl0 Hse).
    + (* u = Node, t = Leaf : 原样保留 *)
      inversion Het; subst. rewrite app_nil_r.
      inversion Heq as [ | t0 b0 q0 l0 al0 Ht0 Hl0 P_eq]; subst.
      apply priqueue_elems_ext with (b0 ++ l0);
        [apply Permutation_sym; exact P_eq |].
      apply priqueue_elems_cons with (b := b0) (l := l0);
        [exact Ht0 | exact Hl0 | apply Permutation_refl].
    + (* u = Leaf, t = Node : 直接放行 *)
      inversion Heq as [ | t0 b0 q0 l0 al0 Ht0 Hl0 P_eq]; subst.
      inversion Ht0; subst. simpl in P_eq.
      cbn [carry].
      apply priqueue_elems_ext with (et ++ l0).
      * apply Permutation_trans with (l0 ++ et);
          [apply Permutation_app_comm
           | apply Permutation_app_tail; apply Permutation_sym; exact P_eq].
      * apply priqueue_elems_cons with (b := et) (l := l0);
          [exact Het | exact Hl0 | apply Permutation_refl].
    + (* u = Leaf, t = Leaf *)
      inversion Heq as [ | t0 b0 q0 l0 al0 Ht0 Hl0 P_eq]; subst.
      inversion Ht0; subst. simpl in P_eq.
      inversion Het; subst. rewrite app_nil_r.
      apply priqueue_elems_ext with l0;
        [apply Permutation_sym; exact P_eq |].
      apply priqueue_elems_cons with (b := nil) (l := l0);
        [constructor | exact Hl0 | apply Permutation_refl].
Qed.

Theorem insert_relate :
  forall p al k, priq p -> Abs p al -> Abs (insert k p) (k :: al).
Proof.
  intros p al k Hp HA. unfold insert, priq, Abs in *.
  apply priqueue_elems_ext with (e1 := al ++ [k]).
  - apply Permutation_sym. apply Permutation_cons_append.
  - apply (carry_elems p 0 Hp).
    + right. simpl. exact I.
    + exact HA.
    + apply tree_elems_node with (bl := nil) (br := nil);
        [constructor | constructor | apply Permutation_refl].
Qed.

(* ---------- 44.6 主定理：insert 的双重正确性 ---------- *)

Theorem insert_correct :
  forall x q al, priq q -> Abs q al ->
  priq (insert x q) /\ Abs (insert x q) (x :: al).
Proof.
  intros x q al Hp HA. split.
  - apply insert_priq. exact Hp.
  - apply insert_relate; [exact Hp | exact HA].
Qed.

Print Assumptions insert_correct.

End Ex44Binom.
