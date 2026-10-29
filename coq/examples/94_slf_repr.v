(* 94 表示谓词 —— MList/MTree/Stack/IsCounter、智能构造器、高阶与 CPS *)
(* 取材 Software Foundations 卷六 Separation Logic Foundations 的 Repr 章。 *)

Set Implicit Arguments.
From SLF Require Import LibSepReference.
Import ProgramSyntax DemoPrograms.
Open Scope liblist_scope.

Implicit Types n m : int.
Implicit Types p q s c : loc.
Implicit Types x : val.

(* ---------- 94.1 链表的表示谓词 MList ---------- *)

Definition head : field := 0%nat.
Definition tail : field := 1%nat.

Fixpoint MList (L:list val) (p:loc) : hprop :=
  match L with
  | nil => \[p = null]
  | x::L' => \exists q, (p ~~~> `{ head := x; tail := q}) \* (MList L' q)
  end.

Lemma MList_nil : forall p,
  (MList nil p) = \[p = null].
Proof using. auto. Qed.

Lemma MList_cons : forall p x L',
  MList (x::L') p =
  \exists q, (p ~~~> `{ head := x; tail := q}) \* (MList L' q).
Proof using. auto. Qed.

(* 按 p 是否为 null 做分情形的「打开」引理（原书练习，这里给出完整证明）。
   证明模式与 MTree_if 相同：先按 L 分情况，再对 If p = null 做 case_if，
   非空分支用 hrecord_not_null 排除 p = null 的可能。 *)

Lemma MList_if : forall (p:loc) (L:list val),
      (MList L p)
  ==> (If p = null
        then \[L = nil]
        else \exists x q L', \[L = x::L']
             \* (p ~~~> `{ head := x; tail := q}) \* (MList L' q)).
Proof using.
  intros. destruct L as [|x L'].
  { xchange MList_nil. intros M. case_if. xsimpl*. }
  { xchange MList_cons. intros q.
    xchange hrecord_not_null. intros N. case_if. xsimpl*. }
Qed.

Global Opaque MList.

(* 本章要用到 93 章的两个小函数：incr 与 get_and_free。 *)

Definition incr : val :=
  <{ fun 'p =>
       let 'n = !'p in
       let 'm = 'n + 1 in
       'p := 'm }>.

Lemma triple_incr : forall (p:loc) (n:int),
  triple (incr p)
    (p ~~> n)
    (fun _ => (p ~~> (n+1))).
Proof using.
  xwp. xapp. xapp. xapp. xsimpl.
Qed.

#[global] Hint Resolve triple_incr : triple.

Definition get_and_free : val :=
  <{ fun 'p =>
      let 'v = ! 'p in
      free 'p;
      'v }>.

Lemma triple_get_and_free : forall p v,
  triple (get_and_free p)
    (p ~~> v)
    (fun r => \[r = v]).
Proof using.
  xwp. xapp. xapp. xval. xsimpl. auto.
Qed.

#[global] Hint Resolve triple_get_and_free : triple.

(* ---------- 94.2 就地拼接 append ---------- *)

Definition append : val :=
  <{ fix 'f 'p1 'p2 =>
       let 'q1 = 'p1`.tail in
       let 'b = ('q1 = null) in
       if 'b
         then 'p1`.tail := 'p2
         else 'f 'q1 'p2 }>.

Lemma triple_append : forall (L1 L2:list val) (p1 p2:loc),
  p1 <> null ->
  triple (append p1 p2)
    (MList L1 p1 \* MList L2 p2)
    (fun _ => MList (L1++L2) p1).
Proof using.
  introv N.
  gen p1. induction_wf IH: list_sub L1. intros. xwp.
  xchange (MList_if p1). case_if.
  xpull.
  intros x q1 L1' ->.
  xapp. xapp. xif; intros Cq1.
  { xchange (MList_if q1). case_if. xpull.
    intros ->.
    xapp. xchange <- MList_cons. }
  { xapp. xchange <- MList_cons. }
Qed.

(* ---------- 94.3 智能构造器 mnil 与 mcons ---------- *)

Definition mnil : val :=
  <{ fun 'u =>
       null }>.

Lemma triple_mnil :
  triple (mnil ())
    \[]
    (funloc p => MList nil p).
Proof using.
  xwp.
  xval.
  generalize (MList_nil null). intros E.
  xchange <- E. { auto. }
   xsimpl. auto.
Qed.

Lemma triple_mnil' :
  triple (mnil ())
    \[]
    (funloc p => MList nil p).
Proof using. xwp. xval. xchanges* <- (MList_nil null). Qed.

#[global] Hint Resolve triple_mnil : triple.

Definition mcons : val :=
  <{ fun 'x 'q =>
       `{ head := 'x; tail := 'q } }>.

Lemma triple_mcons : forall x q,
  triple (mcons x q)
    \[]
    (funloc p => p ~~~> `{ head := x ; tail := q }).
Proof using. xwp. xapp triple_new_hrecord_2; auto. xsimpl*. Qed.

Lemma triple_mcons' : forall L x q,
  triple (mcons x q)
    (MList L q)
    (funloc p => MList (x::L) p).
Proof using.
  intros. xapp triple_mcons.
  intros p. xchange <- MList_cons. xsimpl*.
Qed.

#[global] Hint Resolve triple_mcons' : triple.

(* ---------- 94.4 链表深拷贝 mcopy ---------- *)

Definition mcopy : val :=
  <{ fix 'f 'p =>
       let 'b = ('p = null) in
       if 'b
         then mnil ()
         else
           let 'x = 'p`.head in
           let 'q = 'p`.tail in
           let 'q2 = ('f 'q) in
           mcons 'x 'q2 }>.

Lemma triple_mcopy : forall L p,
  triple (mcopy p)
    (MList L p)
    (funloc p' => (MList L p) \* (MList L p')).
Proof using.
  intros. gen p. induction_wf IH: list_sub L.
  xwp. xapp. xchange MList_if. xif.
  { intros C.
    case_if. (* automatically rules out the case [p <> null] *)
    xpull. intros E. subst L.
    xapp. xsimpl. { auto. }
    subst. xchange <- MList_nil. auto. }
  { intros C. case_if. (* automatically rules out [p = null] *)
    xpull. intros x q L' E. subst L.
    xapp. xapp. xapp. intros q'.
    xapp. intros p'.
    xchange <- MList_cons. xsimpl. auto. }
Qed.

Lemma triple_mcopy' : forall L p,
  triple (mcopy p)
    (MList L p)
    (funloc p' => (MList L p) \* (MList L p')).
Proof using.
  intros. gen p. induction_wf IH: list_sub L.
  xwp. xapp. xchange MList_if. xif; intros C; case_if; xpull.
  { intros ->. xapp. xsimpl*. subst. xchange* <- MList_nil. }
  { intros x q L' ->. xapp. xapp. xapp. intros q'.
    xapp. intros p'. xchange <- MList_cons. xsimpl*. }
Qed.

(* ---------- 94.5 练习：mlength ---------- *)

Definition mlength : val :=
  <{ fix 'f 'p =>
       let 'b = ('p = null) in
       if 'b
         then 0
         else (let 'q = 'p`.tail in
               let 'n = 'f 'q in
               'n + 1) }>.

Lemma triple_mlength : forall L p,
  triple (mlength p)
    (MList L p)
    (fun r => \[r = val_int (length L)] \* (MList L p)).
Proof using.
  intros. gen p. induction_wf IH: list_sub L.
  xwp. xapp. xchange MList_if. xif; intros C; case_if; xpull.
  { intros ->. xval. xsimpl. rew_list. auto.
    xchange <- (MList_nil p). auto. }
  { intros x q L' ->. xapp. xapp. xapp.
    xsimpl. rew_list. math.
    xchange <- MList_cons. }
Qed.

(* ---------- 94.6 练习：带累加引用的 mlength' ---------- *)

Definition acclength : val :=
  <{ fix 'f 'c 'p =>
       let 'b = ('p <> null) in
       if 'b then
         incr 'c;
         let 'q = 'p`.tail in
         'f 'c 'q
       end }>.

Definition mlength' : val :=
  <{ fun 'p =>
       let 'c = ref 0 in
       acclength 'c 'p;
       get_and_free 'c }>.

Lemma triple_acclength : forall L p c n,
  triple (acclength c p)
    (c ~~> n \* MList L p)
    (fun _ => c ~~> (n + length L) \* MList L p).
Proof using.
  intros L. induction_wf IH: list_sub L. intros p c n.
  xwp. xapp. xchange MList_if. xif; intros C; case_if; xpull.
  { intros x q L' ->. xapp. xapp. xapp.
    xsimpl. rew_list. math.
    xchange <- MList_cons. }
  { intros ->. xval. xsimpl. rew_list. math.
    xchange <- (MList_nil p). auto. }
Qed.

Lemma triple_mlength' : forall L p,
  triple (mlength' p)
    (MList L p)
    (fun r => \[r = val_int (length L)] \* (MList L p)).
Proof using.
  intros. xwp. xapp. intros c.
  xapp triple_acclength.
  xapp. xsimpl. math.
Qed.

(* ---------- 94.7 练习：整表释放 mfree ---------- *)

Definition mfree : val :=
  <{ fix 'f 'p =>
       let 'b = ('p <> null) in
       if 'b then
         let 'q = 'p`.tail in
         delete 'p;
         'f 'q
       end }>.

Lemma triple_mfree : forall L p,
  triple (mfree p)
    (MList L p)
    (fun _ => \[]).
Proof using.
  intros. gen p. induction_wf IH: list_sub L.
  xwp. xapp. xchange MList_if. xif; intros C; case_if; xpull.
  { intros x q L' ->. xapp. xapp. xapp. xsimpl. }
  { intros ->. xval. xsimpl. }
Qed.

(* ---------- 94.8 练习：就地反转 mrev ---------- *)

Definition mrev_aux : val :=
  <{ fix 'f 'p1 'p2 =>
       let 'b = ('p2 = null) in
       if 'b
         then 'p1
         else (
           let 'p3 = 'p2`.tail in
           'p2`.tail := 'p1;
           'f 'p2 'p3) }>.

Definition mrev : val :=
  <{ fun 'p =>
       mrev_aux null 'p }>.

Lemma triple_mrev_aux : forall L1 L2 p1 p2,
  triple (mrev_aux p1 p2)
    (MList L1 p1 \* MList L2 p2)
    (funloc p3 => MList (rev L2 ++ L1) p3).
Proof using.
  intros. gen L1 p1 p2. induction_wf IH: list_sub L2. intros L1 p1 p2.
  xwp. xapp. xchange (MList_if p2). xif; intros C; case_if; xpull.
  { intros ->. xval. xsimpl. rew_list. auto. }
  { intros x q L2' ->. xapp.
    xapp.
    xchange <- MList_cons.
    rew_list.
    xapp. intros p3.
    xsimpl. auto. }
Qed.

Lemma triple_mrev : forall L p,
  triple (mrev p)
    (MList L p)
    (funloc q => MList (rev L) q).
Proof using.
  intros. xwp. xapp (triple_mrev_aux nil L null p).
  xchange <- (MList_nil null). { auto. }
  xsimpl.
  { intros x x0 ->. auto. }
  intros. rew_list. xsimpl.
Qed.

(* ---------- 94.9 带尺寸的栈：表示谓词 Stack ---------- *)

Module SizedStack.

Definition data : field := 0%nat.
Definition size : field := 1%nat.

Definition Stack (L:list val) (s:loc) : hprop :=
  \exists p, s ~~~>`{ data := p; size := length L } \* (MList L p).

Definition create : val :=
  <{ fun 'u =>
      `{ data := null; size := 0 } }>.

Lemma triple_create :
  triple (create ())
    \[]
    (funloc s => Stack nil s).
Proof using.
  xwp. xapp triple_new_hrecord_2; auto. intros s.
  unfold Stack. xsimpl*. xchange* <- (MList_nil null).
Qed.

Definition sizeof : val :=
  <{ fun 'p =>
      'p`.size }>.

Lemma triple_sizeof : forall L s,
  triple (sizeof s)
    (Stack L s)
    (fun r => \[r = length L] \* Stack L s).
Proof using.
  xwp. unfold Stack. xpull. intros p. xapp. xsimpl*.
Qed.

Definition push : val :=
  <{ fun 's 'x =>
       let 'p = 's`.data in
       let 'p2 = mcons 'x 'p in
       's`.data := 'p2;
       let 'n = 's`.size in
       let 'n2 = 'n + 1 in
       's`.size := 'n2 }>.

Lemma triple_push : forall L s x,
  triple (push s x)
    (Stack L s)
    (fun u => Stack (x::L) s).
Proof using.
  xwp. unfold Stack. xpull. intros p.
  xapp.
  xapp. intros p2.
  xapp.
  xapp.
  xapp.
  xapp.
  unfold Stack. xsimpl*. rew_list. math.
Qed.

Definition pop : val :=
  <{ fun 's =>
       let 'p = 's`.data in
       let 'x = 'p`.head in
       let 'p2 = 'p`.tail in
       delete 'p;
       's`.data := 'p2;
       let 'n = 's`.size in
       let 'n2 = 'n - 1 in
       's`.size := 'n2;
       'x }>.

Lemma triple_pop : forall L s,
  L <> nil ->
  triple (pop s)
    (Stack L s)
    (fun x => \exists L', \[L = x::L'] \* Stack L' s).
Proof using.
  introv HN. xwp. unfold Stack. xpull. intros p.
  destruct L as [|x L']; [ false | ].
  xapp.
  xchange MList_cons. xpull. intros q.
  xapp.
  xapp.
  xapp.
  xapp.
  xapp.
  xapp.
  xapp.
  xval.
  unfold Stack. xsimpl*. rew_list. math.
Qed.

Definition top : val :=
  <{ fun 's =>
       let 'p = 's`.data in
       'p`.head }>.

Lemma triple_top : forall L s,
  L <> nil ->
  triple (top s)
    (Stack L s)
    (fun x => \exists L', \[L = x::L'] \* Stack L s).
Proof using.
  introv HN. xwp. unfold Stack. xpull. intros p.
  destruct L as [|x L']; [ false | ].
  xapp.
  xchange MList_cons. xpull. intros q.
  xapp.
  xchange <- MList_cons. xsimpl*.
Qed.

End SizedStack.

(* ---------- 94.10 树的表示谓词 MTree ---------- *)

Inductive tree : Type :=
  | Leaf : tree
  | Node : int -> tree -> tree -> tree.

Implicit Types T : tree.

Definition item : field := 0%nat.
Definition left : field := 1%nat.
Definition right : field := 2%nat.

Fixpoint MTree (T:tree) (p:loc) : hprop :=
  match T with
  | Leaf => \[p = null]
  | Node n T1 T2 => \exists p1 p2,
         (p ~~~>`{ item := n; left := p1; right := p2 })
      \* (MTree T1 p1)
      \* (MTree T2 p2)
  end.

Lemma MTree_Leaf : forall p,
  (MTree Leaf p) = \[p = null].
Proof using. auto. Qed.

Lemma MTree_Node : forall p n T1 T2,
  (MTree (Node n T1 T2) p) =
  \exists p1 p2,
       (p ~~~>`{ item := n; left := p1; right := p2 })
    \* (MTree T1 p1) \* (MTree T2 p2).
Proof using. auto. Qed.

Lemma MTree_if : forall (p:loc) (T:tree),
      (MTree T p)
  ==> (If p = null
        then \[T = Leaf]
        else \exists n p1 p2 T1 T2, \[T = Node n T1 T2]
             \* (p ~~~>`{ item := n; left := p1; right := p2 })
             \* (MTree T1 p1) \* (MTree T2 p2)).
Proof using.
  intros. destruct T as [|n T1 T2].
  { xchange MTree_Leaf. intros M. case_if. xsimpl*. }
  { xchange MTree_Node. intros p1 p2.
    xchange hrecord_not_null. intros N. case_if. xsimpl*. }
Qed.

Opaque MTree.

Inductive tree_sub : binary (tree) :=
  | tree_sub_1 : forall n T1 T2,
      tree_sub T1 (Node n T1 T2)
  | tree_sub_2 : forall n T1 T2,
      tree_sub T2 (Node n T1 T2).

Lemma tree_sub_wf : wf tree_sub.
Proof using.
  intros T. induction T; constructor; intros t' H; inversions~ H.
Qed.

#[global] Hint Resolve tree_sub_wf : wf.

Definition mnode : val :=
  val_new_hrecord_3 item left right.

Lemma triple_mnode : forall n p1 p2,
  triple (mnode n p1 p2)
    \[]
    (funloc p => p ~~~> `{ item := n ; left := p1 ; right := p2 }).
Proof using. intros. apply triple_new_hrecord_3; auto. Qed.

Lemma triple_mnode' : forall T1 T2 n p1 p2,
  triple (mnode n p1 p2)
    (MTree T1 p1 \* MTree T2 p2)
    (funloc p => MTree (Node n T1 T2) p).
Proof using.
  intros. xapp triple_mnode. intros p.
  xchange <- MTree_Node. xsimpl*.
Qed.

#[global] Hint Resolve triple_mnode' : triple.

(* ---------- 94.11 练习：树的深拷贝与求和 ---------- *)

Definition tree_copy :=
  <{ fix 'f 'p =>
       let 'b = ('p = null) in
       if 'b then null else (
         let 'n = 'p`.item in
         let 'p1 = 'p`.left in
         let 'p2 = 'p`.right in
         let 'q1 = 'f 'p1 in
         let 'q2 = 'f 'p2 in
         mnode 'n 'q1 'q2
      ) }>.

Lemma triple_tree_copy : forall p T,
  triple (tree_copy p)
    (MTree T p)
    (funloc q => (MTree T p) \* (MTree T q)).
Proof using.
  intros. gen p. induction_wf IH: tree_sub T.
  xwp. xapp. xchange MTree_if. xif; intros C; case_if; xpull.
  { intros E. subst T. xval.
    xchange <- (MTree_Leaf null). { auto. } xsimpl*.
    rewrite C0. xchange <- (MTree_Leaf null). { auto. } }
  { intros n p1 p2 T1 T2 E. subst T.
    xapp. xapp. xapp.
    xapp. { apply tree_sub_1. } intros q1.
    xapp. { apply tree_sub_2. } intros q2.
    xapp. intros p'.
    xchange <- MTree_Node. xsimpl*. }
Qed.

Definition treeacc : val :=
  <{ fix 'f 'c 'p =>
       let 'b = ('p <> null) in
       if 'b then
         let 'm = ! 'c in
         let 'x = 'p`.item in
         let 'm2 = 'm + 'x in
         'c := 'm2;
         let 'p1 = 'p`.left in
         'f 'c 'p1;
         let 'p2 = 'p`.right in
         'f 'c 'p2
       end }>.

Definition mtreesum : val :=
  <{ fun 'p =>
       let 'c = ref 0 in
       treeacc 'c 'p;
       get_and_free 'c }>.

Fixpoint treesum (T:tree) : int :=
  match T with
  | Leaf => 0
  | Node n T1 T2 => n + treesum T1 + treesum T2
  end.

Lemma triple_treeacc : forall T p c n,
  triple (treeacc c p)
    (c ~~> n \* MTree T p)
    (fun _ => c ~~> (n + treesum T) \* MTree T p).
Proof using.
  intros T. induction_wf IH: tree_sub T. intros p c n.
  xwp. xapp. xchange MTree_if. xif; intros C; case_if; xpull.
  { intros n0 p1 p2 T1 T2 E. subst T.
    xapp. xapp. xapp. xapp.
    xapp.
    xapp. { apply tree_sub_1. }
    xapp.
    xapp. { apply tree_sub_2. }
    xsimpl. math.
    xchange <- MTree_Node. }
  { intros E. subst T. xval. xsimpl. simpl. math.
    rewrite C0. xchange <- (MTree_Leaf null). { auto. } }
Qed.

Lemma triple_mtreesum : forall T p,
  triple (mtreesum p)
    (MTree T p)
    (fun r => \[r = treesum T] \* (MTree T p)).
Proof using.
  intros. xwp. xapp. intros c.
  xapp triple_treeacc.
  xapp. xsimpl. math.
Qed.

(* ---------- 94.12 带局部状态的计数器函数 ---------- *)

Definition create_counter : val :=
  <{ fun 'u =>
       let 'p = ref 0 in
       (fun_ 'u => (incr 'p; !'p)) }>.

Definition CounterSpec (f:val) (p:loc) : Prop :=
  forall m, triple (f ())
                    (p ~~> m)
                    (fun r => \[r = m+1] \* p ~~> (m+1)).

Implicit Type f : val.

Lemma triple_create_counter :
  triple (create_counter ())
    \[]
    (fun f => \exists p, (p ~~> 0) \* \[CounterSpec f p]).
Proof using.
  xwp. xapp. intros p.
  xfun. intros f Hf.
  xsimpl.
  { intros m.
    xapp.
    xapp. xapp. xsimpl. auto. }
Qed.

Definition IsCounter (f:val) (n:int) : hprop :=
  \exists p, p ~~> n \* \[CounterSpec f p].

Lemma triple_create_counter_abstract :
  triple (create_counter ())
    \[]
    (fun f => IsCounter f 0).
Proof using. unfold IsCounter. apply triple_create_counter. Qed.

Lemma triple_apply_counter_abstract : forall f n,
  triple (f ())
    (IsCounter f n)
    (fun r => \[r = n+1] \* (IsCounter f (n+1))).
Proof using.
  xtriple. unfold IsCounter. xpull. intros p Hc.
  xapp Hc. xsimpl. auto. auto.
Qed.

Opaque IsCounter.

Definition test_counter : val :=
  <{ fun 'u =>
       let 'c1 = create_counter () in
       let 'c2 = create_counter () in
       let 'n1 = 'c1 () in
       let 'n2 = 'c2 () in
       let 'n3 = 'c1 () in
       'n2 + 'n3 }>.

Lemma triple_test_counter :
  triple (test_counter ())
    \[]
    (fun r => \[r = 3] \* (\exists H, H)).
Proof using.
  xwp.
  xapp triple_create_counter_abstract. intros c1.
  xapp triple_create_counter_abstract. intros c2.
  xapp triple_apply_counter_abstract.
  xapp triple_apply_counter_abstract.
  xapp triple_apply_counter_abstract.
  xapp. xsimpl. math.
Qed.

(* ---------- 94.13 高阶迭代算子 repeat 与 miter ---------- *)

Definition repeat : val :=
  <{ fix 'g 'f 'n =>
       let 'b = ('n > 0) in
       if 'b then
         'f ();
         let 'n2 = 'n - 1 in
         'g 'f 'n2
       end }>.

Lemma triple_repeat : forall (I:int->hprop) (f:val) (n:int),
  n >= 0 ->
  (forall i, 0 <= i < n ->
    triple (f ())
      (I i)
      (fun u => I (i+1))) ->
  triple (repeat f n)
    (I 0)
    (fun u => I n).
Proof using.
  introv Hn Hf.
  cuts G: (forall m, 0 <= m <= n ->
    triple (repeat f m)
      (I (n-m))
      (fun u => I n)).
  { replace 0 with (n - n). { eapply G. math. } { math. } }
  intros m. induction_wf IH: (downto 0) m. intros Hm.
  xwp. xapp. xif; intros C.
  { xapp. { math. } xapp.
    xapp. { math. } { math. }
    math_rewrite ((n - m) + 1 = n - (m - 1)). xsimpl. }
  { xval. math_rewrite (n - m = n). xsimpl. }
Qed.

Definition miter : val :=
  <{ fix 'g 'f 'p =>
       let 'b = ('p <> null) in
       if 'b then
         let 'x = 'p`.head in
         'f 'x;
         let 'q = 'p`.tail in
         'g 'f 'q
       end }>.

Lemma triple_miter : forall (I:list val->hprop) L (f:val) p,
  (forall x L1 L2, L = L1++x::L2 ->
    triple (f x)
      (I L1)
      (fun u => I (L1++(x::nil)))) ->
  triple (miter f p)
    (MList L p \* I nil)
    (fun u => MList L p \* I L).
Proof using.
  introv Hf.
  cuts G: (forall L2 L1 p,
    L = L1 ++ L2 ->
    triple (miter f p)
      (MList L2 p \* I L1)
      (fun u => MList L2 p \* I L)).
  { applys G L (@nil val). rew_list. auto. }
  intros L2. induction_wf IH: list_sub L2. intros L1 p0 HL.
  xwp. xapp. xchange MList_if. xif; intros C; case_if; xpull.
  { intros x q L2' E. subst L2.
    xapp.
    xapp Hf. { apply HL. }
    xapp.
    xapp.
    { apply list_sub_cons. }
    { rewrite HL. rew_list. auto. }
    xchange <- MList_cons. }
  { intros ->. xval. xsimpl.
    rewrite HL. rew_list.
    rewrite (MList_nil p0). xsimpl. auto. }
Qed.

Definition mlength_using_miter : val :=
  <{ fun 'p =>
       let 'c = ref 0 in
       let 'f = (fun_ 'x => incr 'c) in
       miter 'f 'p;
       get_and_free 'c }>.

Lemma triple_mlength_using_miter : forall p L,
  triple (mlength_using_miter p)
    (MList L p)
    (fun r => \[r = length L] \* MList L p).
Proof using.
  intros. xwp. xapp. intros c.
  xfun. intros f Hf.
  xapp (>> triple_miter (fun (K:list val) => c ~~> (length K : int)) L f p).
  { intros x L1 L2 E. applys Hf. xapp. xsimpl. rew_list. math. }
  xapp. xsimpl. math.
Qed.

(* ---------- 94.14 CPS 风格：阶乘与 append ---------- *)

Module Facto.

Parameter facto : int -> int.

Parameter facto_init : forall n,
  0 <= n <= 1 ->
  facto n = 1.

Parameter facto_step : forall n,
  n >= 1 ->
  facto n = n * (facto (n-1)).

Lemma facto_succ : forall i,
  i >= 0 ->
  facto (i + 1) = (i + 1) * facto i.
Proof using.
  introv Hi. rewrite (@facto_step (i+1)). f_equal. f_equal. math. math.
Qed.

End Facto.

Import Facto.

Definition cps_facto_aux : val :=
  <{ fix 'f 'n 'k =>
       let 'b = 'n <= 1 in
       if 'b
         then 'k 1
         else let 'k2 = (fun_ 'r => let 'r2 = 'n * 'r in 'k 'r2) in
              let 'n2 = 'n - 1 in
              'f 'n2 'k2 }>.

Definition cps_facto : val :=
  <{ fun 'n  =>
       let 'k = (fun_ 'r => 'r) in
       cps_facto_aux 'n 'k }>.

Lemma triple_cps_facto_aux : forall (n:int) (k:val) (F:int->int),
  n >= 0 ->
  (forall (a:int), triple (k a) \[] (fun r => \[r = F a])) ->
  triple (cps_facto_aux n k)
    \[]
    (fun r => \[r = F (facto n)]).
Proof using.
  intros n. induction_wf IH: (downto 0) n. introv Hn Hk.
  xwp. xapp. xif; intros C.
  { rewrite facto_init; [|math].
    xapp Hk. xsimpl. math. }
  { xfun. intros k2 Hk2.
    xapp.
    xapp (>> IH (fun a => F (n * a))).
    all: try math.
    { intros a. applys Hk2. xapp. xapp Hk. xsimpl. math. }
    xsimpl. rewrite <- (@facto_step n); [|math]. auto. }
Qed.

Lemma triple_cps_facto : forall n,
  n >= 0 ->
  triple (cps_facto n)
    \[]
    (fun r => \[r = facto n]).
Proof using.
  introv Hn. xwp.
  xfun. intros k Hk.
  xapp (>> triple_cps_facto_aux n k (fun (a:int) => a)).
  { math. }
  { intros a. applys Hk. xval. xsimpl. auto. }
  xsimpl. math.
Qed.

Definition cps_append_aux : val :=
  <{ fix 'f 'p1 'p2 'k =>
       let 'b = ('p1 = null) in
       if 'b
         then 'k 'p2
         else
           let 'q1 = 'p1`.tail in
           let 'k2 = (fun_ 'r => ('p1`.tail := 'r; 'k 'p1)) in
           'f 'q1 'p2 'k2 }>.

Definition cps_append : val :=
  <{ fun 'p1 'p2 =>
      let 'f = (fun_ 'r => 'r) in
      cps_append_aux 'p1 'p2 'f }>.

Lemma triple_cps_append_aux : forall H Q (L1 L2:list val) (p1 p2:loc) (k:val),
  (forall (p3:loc), triple (k p3) (MList (L1 ++ L2) p3 \* H) Q) ->
  triple (cps_append_aux p1 p2 k)
    (MList L1 p1 \* MList L2 p2 \* H)
    Q.
Proof using.
  introv Hk.
  cuts G: (forall (L1':list val) (H':hprop) (p1':loc) (k':val),
    (forall p3, triple (k' p3) (MList (L1' ++ L2) p3 \* H') Q) ->
    triple (cps_append_aux p1' p2 k')
      (MList L1' p1' \* MList L2 p2 \* H')
      Q).
  { applys G L1 H p1 k. auto. }
  intros L1'. induction_wf IH: list_sub L1'. intros H' p1' k' Hk'.
  xwp. xapp. xchange (MList_if p1'). xif; intros C; case_if; xpull.
  { intros ->. xapp Hk'. intros x. auto. }
  { intros x q L1'' E. subst L1'.
    xapp.
    xfun. intros k2 Hk2.
    xapp (>> IH L1'' ((p1' ~~~> `{ head := x; tail := q }) \* H')).
    { apply list_sub_cons. }
    intros p3.
    applys (Hk2 p3 (MList (L1'' ++ L2) p3
                \* (p1' ~~~> `{ head := x; tail := q }) \* H')).
    xapp.
    xchange <- MList_cons.
    xapp Hk'.
    intros x0. auto.
    intros x0. auto. }
Qed.

Lemma triple_cps_append : forall (L1 L2:list val) (p1 p2:loc),
  triple (cps_append p1 p2)
    (MList L1 p1 \* MList L2 p2)
    (funloc p3 => MList (L1++L2) p3).
Proof using.
  intros. xwp.
  xfun. intros k Hk.
  xapp (@triple_cps_append_aux
          (hempty) (funloc p3 => MList (L1++L2) p3) L1 L2 p1 p2 k).
  intros p3. applys Hk. xval. xsimpl.
  all: try auto.
  all: try (intros x0; auto).
  xsimpl. auto.
Qed.
