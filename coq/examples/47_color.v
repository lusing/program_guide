(* 47 四色定理 —— 图着色：用 FSets/FMaps 做证明工程 *)

From Stdlib Require Import List Setoid FSets FMaps PArith Arith Recdef.
Import ListNotations.

Module Ex47Color.

(* ---------- 47.1 表示图：positive 节点 + 函数式集合/映射 ---------- *)

Module E := PositiveOrderedTypeBits.
Module S <: FSetInterface.S := PositiveSet.
Module M <: FMapInterface.S := PositiveMap.
Module WF := WFacts_fun E M.
Module WP := WProperties_fun E M.

Lemma lt_strict : StrictOrder E.lt.
Proof. exact M.ME.MO.IsTO.lt_strorder. Qed.

Lemma lt_proper : Proper (eq ==> eq ==> iff) E.lt.
Proof. exact M.ME.MO.IsTO.lt_compat. Qed.

Definition Mdomain {A} (m : M.t A) : S.t :=
   M.fold (fun n _ s => S.add n s) m S.empty.

Definition example_map : M.t S.t :=
  (M.add 3%positive S.empty
   (M.add 9%positive S.empty
    (M.add 2%positive S.empty (M.empty S.t   )))).

Example domain_example_map :
    S.elements (Mdomain example_map) = [2;9;3]%positive.
Proof. compute. reflexivity. Qed.

(* ---------- 47.2 排序列表工具：Sorted / InA / equivlistA ---------- *)

Check SortA_equivlistA_eqlistA.
(*  : forall (A : Type) (eqA : A -> A -> Prop),
       Equivalence eqA ->
       forall ltA : A -> A -> Prop,
       StrictOrder ltA ->
       Proper (eqA ==> eqA ==> iff) ltA ->
       forall l l' : list A,
       Sorted ltA l ->
       Sorted ltA l' -> equivlistA eqA l l' -> eqlistA eqA l l' *)

Lemma eqlistA_Eeq_eq : forall al bl, eqlistA E.eq al bl <-> al = bl.
Proof.
split; intro H.
- induction H as [| x y l l' Hxy Hl IH]; simpl.
  + reflexivity.
  + unfold E.eq in Hxy. rewrite Hxy. f_equal. exact IH.
- subst. induction bl as [| b l IH].
  + constructor.
  + constructor; [reflexivity | exact IH].
Qed.

Lemma SortE_equivlistE_eqlistE :
 forall al bl, Sorted E.lt al ->
                   Sorted E.lt bl ->
                   equivlistA E.eq al bl -> eqlistA E.eq al bl.
Proof.
intros al bl H1 H2 H3.
apply SortA_equivlistA_eqlistA with (ltA := E.lt).
- apply eq_equivalence.
- apply lt_strict.
- apply lt_proper.
- assumption.
- assumption.
- assumption.
Qed.

Lemma filter_sortE : forall f l,
     Sorted E.lt l -> Sorted E.lt (List.filter f l).
Proof.
intros f l H.
apply filter_sort with (eqA := E.eq) (ltA := E.lt).
- apply eq_equivalence.
- apply lt_strict.
- apply lt_proper.
- exact H.
Qed.

Lemma InA_eq_In : forall (A : Type) (l : list A) (x : A),
  InA (@eq A) x l -> In x l.
Proof.
intros A l x H. apply InA_alt in H.
destruct H as [y [Hxy Hin]]. rewrite Hxy. exact Hin.
Qed.

(* ---------- 47.3 S.remove 与 S.elements ---------- *)

Lemma Proper_eq_eq :
  forall f, Proper (E.eq ==> @eq bool) f.
Proof.
unfold Proper, respectful. intros f x y H.
unfold E.eq in H. rewrite H. reflexivity.
Qed.

Lemma Sremove_elements :  forall (i : E.t) (s : S.t),
  S.In i s ->
     S.elements (S.remove i s) =
         List.filter (fun x => if E.eq_dec x i then false else true) (S.elements s).
Proof.
intros i s H.
apply eqlistA_Eeq_eq.
apply SortE_equivlistE_eqlistE.
- apply S.elements_3.
- apply filter_sortE. apply S.elements_3.
- intro j. rewrite filter_InA; [ | apply Proper_eq_eq].
  destruct (E.eq_dec j i) as [Heq | Hne].
  + split; intro HH.
    * exfalso. apply S.elements_2 in HH.
      exact (S.remove_1 s (eq_sym Heq) HH).
    * destruct HH as [H1 H2]. simpl in H2. discriminate H2.
  + split; intro HH.
    * apply S.elements_2 in HH. split.
      -- apply S.elements_1. apply (S.remove_3 s i). exact HH.
      -- destruct (E.eq_dec j i); [contradiction | reflexivity].
    * destruct HH as [H1 H2]. destruct (E.eq_dec j i); [contradiction | idtac].
      apply S.elements_1. apply S.remove_2.
      -- apply not_eq_sym. exact Hne.
      -- apply S.elements_2. exact H1.
Qed.

Lemma filter_length_le : forall (A : Type) (f : A -> bool) (l : list A),
  length (List.filter f l) <= length l.
Proof.
induction l as [| a l IH]; simpl.
- apply Nat.le_refl.
- destruct (f a); simpl.
  + apply le_n_S. exact IH.
  + apply Nat.le_le_succ_r. exact IH.
Qed.

Lemma filter_InA_length_lt :
  forall (A : Type) (eqA : A -> A -> Prop) (f : A -> bool) (l : list A) (x : A),
    InA eqA x l -> Proper (eqA ==> @eq bool) f -> f x = false ->
    length (List.filter f l) < length l.
Proof.
intros A eqA f l x.
induction l as [| a l IH]; intros Hin Hprop Hfx; simpl in *.
- inversion Hin.
- inversion Hin as [l0 y Hxa | l0 y Hin0]; subst; simpl.
  + assert (Hfa : f a = false).
    { rewrite <- (Hprop x a Hxa). exact Hfx. }
    rewrite Hfa. simpl.
    apply Nat.le_lt_trans with (length l).
    * apply filter_length_le.
    * apply Nat.lt_succ_diag_r.
  + destruct (f a); simpl.
    * apply (proj1 (Nat.succ_lt_mono _ _)). apply IH; assumption.
    * apply Nat.lt_lt_succ_r. apply IH; assumption.
Qed.

Lemma Sremove_cardinal_less : forall i s,
        S.In i s ->    S.cardinal (S.remove i s) < S.cardinal s.
Proof.
intros i s H.
repeat rewrite S.cardinal_1.
rewrite (Sremove_elements i s H).
apply filter_InA_length_lt with (eqA := E.eq) (x := i).
- apply S.elements_1. exact H.
- apply Proper_eq_eq.
- destruct (E.eq_dec i i) as [_ | Hii]; [reflexivity | exfalso; apply Hii; reflexivity].
Qed.

(* ---------- 47.4 M.remove 与 M.elements ---------- *)

Lemma InA_map_fst_key :
 forall A j l,
 InA E.eq j (map (@fst M.E.t A) l) <-> exists e, InA (@M.eq_key_elt A) (j,e) l.
Proof.
intros A j l. split; intro H.
- apply InA_alt in H. destruct H as [k [Hjk Hin]].
  apply in_map_iff in Hin. destruct Hin as [[k' e] [Hfst Hpair]].
  simpl in Hfst. rewrite <- Hfst in Hjk.
  exists e. apply InA_alt. exists (k', e). split.
  + unfold M.eq_key_elt. simpl. split; [exact Hjk | reflexivity].
  + exact Hpair.
- destruct H as [e Hke]. apply InA_alt in Hke.
  destruct Hke as [[j' e'] [Hpair Hin]]. simpl in Hpair.
  destruct Hpair as [Hjj' Hee]. unfold E.eq in Hjj'.
  simpl in Hjj', Hee. rewrite <- Hjj', <- Hee in Hin.
  apply InA_alt. exists j. split.
  + unfold E.eq. reflexivity.
  + apply in_map_iff. exists (j, e). split; [reflexivity | exact Hin].
Qed.

Lemma Sorted_lt_key :
  forall A (al : list (positive*A)),
   Sorted (@M.lt_key A) al <->  Sorted E.lt (map (@fst positive A) al).
Proof.
intros A. induction al as [| [k e] rest IH]; simpl.
- split; intro; constructor.
- destruct rest as [| [k' e'] rest']; simpl in *.
  + split; intro; repeat constructor.
  + split; intro H.
    * apply Sorted_inv in H. destruct H as [Hs Hh].
      inversion Hh as [| b l Hlt]. simpl in Hlt.
      constructor.
      -- apply IH. exact Hs.
      -- constructor. exact Hlt.
    * apply Sorted_inv in H. destruct H as [Hs Hh].
      inversion Hh as [| b l Hlt].
      constructor.
      -- apply IH. exact Hs.
      -- constructor. simpl in *. exact Hlt.
Qed.

Lemma cardinal_map :  forall A B (f: A -> B) g,
     M.cardinal (M.map f g) = M.cardinal g.
Proof.
intros A B f g.
repeat rewrite M.cardinal_1.
replace (length (M.elements (M.map f g)))
   with (length (map (@fst M.E.t B) (M.elements (M.map f g))))
   by apply length_map.
replace (length (M.elements g))
   with (length (map (@fst M.E.t A) (M.elements g)))
   by apply length_map.
apply eqlistA_length with (eqA := E.eq).
apply SortE_equivlistE_eqlistE.
- rewrite <- Sorted_lt_key. apply M.elements_3.
- rewrite <- Sorted_lt_key. apply M.elements_3.
- intro j. rewrite !InA_map_fst_key. split; intro H.
  + destruct H as [e He]. apply M.elements_2 in He.
    apply WF.map_mapsto_iff in He. destruct He as [a [_ Ha]].
    exists a. apply M.elements_1. exact Ha.
  + destruct H as [a Ha]. apply M.elements_2 in Ha.
    exists (f a). apply M.elements_1.
    apply WF.map_mapsto_iff. exists a. split; [reflexivity | exact Ha].
Qed.

Lemma specialize_SortA_equivlistA_eqlistA:
  forall A al bl,
  Sorted (@M.lt_key A) al ->
  Sorted (@M.lt_key A) bl ->
  equivlistA (@M.eq_key_elt A) al bl ->
  eqlistA (@M.eq_key_elt A) al bl.
Proof.
intros.
apply SortA_equivlistA_eqlistA with (@M.lt_key A); auto.
apply M.eqke_equiv.
apply M.ltk_strorder.
clear.
repeat intro.
unfold M.lt_key, M.eq_key_elt in *.
destruct H, H0. rewrite H,H0. split; auto.
Qed.

Lemma Proper_eq_key_elt :
 forall A,
   Proper (@M.eq_key_elt A ==> @M.eq_key_elt A ==> iff)
                (fun x y : E.t * A => E.lt (fst x) (fst y)).
Proof.
 repeat intro. destruct H, H0. rewrite H,H0. split; auto.
Qed.

Lemma Proper_eq_dec_fst :
  forall A i,
  Proper (@M.eq_key_elt A ==> @eq bool)
         (fun x => if E.eq_dec (fst x) i then false else true).
Proof.
intros A i. unfold Proper, respectful, M.eq_key_elt.
intros [k1 k2] [j1 j2] [Hk Hj]. simpl in *. rewrite Hk. reflexivity.
Qed.

Lemma Mremove_elements:  forall A i s,
  M.In i s ->
     eqlistA (@M.eq_key_elt A) (M.elements (M.remove i s))
              (List.filter (fun x => if E.eq_dec (fst x) i then false else true) (M.elements s)).
Proof.
intros A i s H.
apply specialize_SortA_equivlistA_eqlistA.
- apply M.elements_3.
- apply filter_sort with (eqA := @M.eq_key_elt A) (ltA := @M.lt_key A).
  + apply M.eqke_equiv.
  + apply M.ltk_strorder.
  + apply Proper_eq_key_elt.
  + apply M.elements_3.
- intro x. rewrite filter_InA; [ | apply Proper_eq_dec_fst].
  destruct x as [x1 x2]. destruct (E.eq_dec x1 i) as [Heq | Hne].
  + split; intro HH.
    * exfalso. apply M.elements_2 in HH.
      exact (M.remove_1 s (eq_sym Heq) (ex_intro _ x2 HH)).
    * destruct HH as [H1 H2]. simpl in H2.
      destruct (E.eq_dec x1 i); [discriminate H2 | contradiction].
  + split; intro HH.
    * apply M.elements_2 in HH. split.
      -- apply M.elements_1. apply (M.remove_3 s i). exact HH.
      -- simpl. destruct (E.eq_dec x1 i); [contradiction | reflexivity].
    * destruct HH as [H1 H2]. simpl in H2.
      destruct (E.eq_dec x1 i); [contradiction | idtac].
      apply M.elements_1. apply M.remove_2.
      -- apply not_eq_sym. exact Hne.
      -- apply M.elements_2. exact H1.
Qed.

Lemma Mremove_cardinal_less : forall A i (s: M.t A), M.In i s ->
        M.cardinal (M.remove i s) < M.cardinal s.
Proof.
intros A i s H.
repeat rewrite M.cardinal_1.
assert (Hlen : length (M.elements (M.remove i s)) =
               length (List.filter (fun x => if E.eq_dec (fst x) i then false else true) (M.elements s))).
{ apply eqlistA_length with (eqA := @M.eq_key_elt A). apply Mremove_elements. exact H. }
rewrite Hlen.
destruct H as [e He].
apply filter_InA_length_lt with (eqA := @M.eq_key_elt A) (x := (i, e)).
- apply M.elements_1. exact He.
- apply Proper_eq_dec_fst.
- simpl. destruct (E.eq_dec i i) as [_ | Hii]; [reflexivity | exfalso; apply Hii; reflexivity].
Qed.

(* ---------- 47.5 图：邻接集作为 positive 到集合的映射 ---------- *)

Definition node := E.t.
Definition nodeset := S.t.
Definition nodemap : Type -> Type := M.t.
Definition graph := nodemap nodeset.

Definition adj (g : graph) (i : node) : nodeset :=
  match M.find i g with Some a => a | None => S.empty end.

Definition undirected (g : graph) :=
   forall i j, S.In j (adj g i) -> S.In i (adj g j).

Definition no_selfloop (g : graph) := forall i, ~ S.In i (adj g i).

Definition nodes (g : graph) := Mdomain g.

Definition subset_nodes
                    (P : node -> nodeset -> bool)
                    (g : graph) :=
   M.fold (fun n adj s => if P n adj then S.add n s else s) g S.empty.

Definition low_deg (K : nat) (n : node) (adj : nodeset) : bool := S.cardinal adj <? K.

Definition remove_node (n : node) (g : graph) : graph :=
  M.map (S.remove n) (M.remove n g).

(* ---------- 47.6 终止性：每删一点，映射严格变小 ---------- *)

Lemma Sin_domain : forall A n (g : M.t A), S.In n (Mdomain g) <-> M.In n g.
Proof.
intros A n g. unfold Mdomain.
apply (WP.fold_rec_bis (elt := A) (A := S.t)
        (P := fun m s => S.In n s <-> M.In n m)
        (f := fun k _ s => S.add k s) (i := S.empty)).
- intros m m' a Heq H. split; intro Hn.
  + destruct (proj1 H Hn) as [e He]. exists e.
    apply (proj2 (WF.find_mapsto_iff (elt := A) m' n e)).
    rewrite <- (Heq n).
    apply (proj1 (WF.find_mapsto_iff (elt := A) m n e)). exact He.
  + destruct Hn as [e He]. apply (proj2 H). exists e.
    apply (proj2 (WF.find_mapsto_iff (elt := A) m n e)).
    rewrite (Heq n).
    apply (proj1 (WF.find_mapsto_iff (elt := A) m' n e)). exact He.
- split; intro Hn.
  + destruct (S.empty_1 Hn).
  + destruct Hn as [e He]. destruct (M.empty_1 He).
- intros k e a m' Hke Hnk H. destruct (E.eq_dec n k) as [Hnk' | Hne].
  + split; intros _.
    * exists e. apply M.add_1. symmetry. exact Hnk'.
    * apply S.add_1. symmetry. exact Hnk'.
  + split; intro Hn.
    * assert (Hia : S.In n a).
      { apply S.add_3 with (x := k); [apply not_eq_sym; exact Hne | exact Hn]. }
      destruct (proj1 H Hia) as [e0 He0]. exists e0.
      apply M.add_2; [apply not_eq_sym; exact Hne | exact He0].
    * destruct Hn as [e0 He0]. apply S.add_2. apply (proj2 H).
      exists e0. apply M.add_3 with (x := k) (e' := e);
        [apply not_eq_sym; exact Hne | exact He0].
Qed.

Lemma subset_nodes_sub :  forall P g, S.Subset (subset_nodes P g) (nodes g).
Proof.
intros P g.
assert (Hfold : forall a, S.In a (subset_nodes P g) -> M.In a g).
{ unfold subset_nodes.
  apply (WP.fold_rec_bis (elt := nodeset) (A := S.t)
          (P := fun m s => forall a, S.In a s -> M.In a m)
          (f := fun n ad s => if P n ad then S.add n s else s)
          (i := S.empty)).
  - intros m m' a Heq H i Hin.
    destruct (H i Hin) as [e He]. exists e.
    apply (proj2 (WF.find_mapsto_iff m' i e)).
    rewrite <- (Heq i).
    apply (proj1 (WF.find_mapsto_iff m i e)). exact He.
  - intros i Hin. destruct (S.empty_1 Hin).
  - intros k e a m' Hke Hnk H i Hin.
    destruct (P k e) eqn:HP.
    + destruct (E.eq_dec i k) as [Hik | Hne].
      * rewrite Hik. exists e. apply M.add_1. reflexivity.
      * assert (Hia : S.In i a).
        { apply S.add_3 with (x := k); [apply not_eq_sym; exact Hne | exact Hin]. }
        destruct (H i Hia) as [e0 He0]. exists e0.
        apply M.add_2; [apply not_eq_sym; exact Hne | exact He0].
    + destruct (E.eq_dec i k) as [Hik | Hne].
      * rewrite Hik. exists e. apply M.add_1. reflexivity.
      * destruct (H i Hin) as [e0 He0]. exists e0.
        apply M.add_2; [apply not_eq_sym; exact Hne | exact He0]. }
unfold S.Subset, nodes. intros a Ha. apply Sin_domain. apply Hfold. exact Ha.
Qed.

Lemma select_terminates :
  forall (K : nat) (g : graph) (n : S.elt),
   S.choose (subset_nodes (low_deg K) g) = Some n ->
   M.cardinal (remove_node n g) < M.cardinal g.
Proof.
intros K g n H.
unfold remove_node, nodes.
rewrite cardinal_map.
apply Mremove_cardinal_less.
apply Sin_domain.
apply (subset_nodes_sub (low_deg K) g).
apply S.choose_1. exact H.
Qed.

(* ---------- 47.7 着色程序：select 与 color ---------- *)

Function select (K : nat) (g : graph) {measure M.cardinal g} : list node :=
  match S.choose (subset_nodes (low_deg K) g) with
  | Some n => n :: select K (remove_node n g)
  | None => nil
  end.
Proof. apply select_terminates. Defined.

Definition coloring := M.t node.

Definition colors_of (f : coloring) (s : S.t) : S.t :=
   S.fold (fun n s => match M.find n f with Some c => S.add c s | None => s end) s S.empty.

Definition color1 (palette : S.t) (g : graph) (n : node) (f : coloring) : coloring :=
   match S.choose (S.diff palette (colors_of f (adj g n))) with
   | Some c => M.add n c f
   | None => f
   end.

Definition color (palette : S.t) (g : graph) : coloring :=
  fold_right (color1 palette g)  (M.empty _) (select (S.cardinal palette) g).

(* ---------- 47.8 正确性：算法产出的着色永不冲突 ---------- *)

Definition coloring_ok (palette : S.t) (g : graph) (f : coloring) :=
 forall i j, S.In j (adj g i) ->
     (forall ci, M.find i f = Some ci -> S.In ci palette) /\
     (forall ci cj, M.find i f = Some ci -> M.find j f = Some cj -> ci<>cj).

Lemma find_empty : forall (A : Type) (n : node), M.find n (M.empty A) = None.
Proof.
intros A n.
destruct (M.find n (M.empty A)) as [c |] eqn:E.
- exfalso. exact (M.empty_1 (proj2 (WF.find_mapsto_iff (elt := A) (M.empty A) n c) E)).
- reflexivity.
Qed.

Lemma find_add_same : forall (A : Type) (f : M.t A) n c,
  M.find n (M.add n c f) = Some c.
Proof.
intros A f n c.
apply (proj1 (WF.find_mapsto_iff (elt := A) (M.add n c f) n c)).
apply M.add_1. reflexivity.
Qed.

Lemma find_add_other : forall (A : Type) (f : M.t A) n m c c0,
  m <> n -> M.find m (M.add n c f) = Some c0 -> M.find m f = Some c0.
Proof.
intros A f n m c c0 Hmn Hfind.
apply (proj1 (WF.find_mapsto_iff (elt := A) f m c0)).
apply M.add_3 with (x := n) (e' := c).
- apply not_eq_sym. exact Hmn.
- exact (proj2 (WF.find_mapsto_iff (elt := A) (M.add n c f) m c0) Hfind).
Qed.

Lemma in_fold_acc :
  forall (l : list node) (f : coloring) (s : S.t) (s0 : node),
    S.In s0 s ->
    S.In s0 (fold_left (fun s n => match M.find n f with
                                   | Some c => S.add c s
                                   | None => s end) l s).
Proof.
induction l as [| a l IH]; intros f s s0 H; simpl.
- exact H.
- destruct (M.find a f) as [ca |] eqn:Ea; simpl.
  + apply IH. apply S.add_2. exact H.
  + apply IH. exact H.
Qed.

Lemma in_colors_of_aux :
  forall (l : list node) (f : coloring) (s : S.t) (i : node) (c : node),
  In i l -> M.find i f = Some c ->
  S.In c (fold_left (fun s n => match M.find n f with
                                | Some c => S.add c s
                                | None => s end) l s).
Proof.
induction l as [| a l IH]; intros f s i c Hin Hfind; simpl.
- contradiction.
- destruct (M.find a f) as [ca |] eqn:Ea; simpl.
  + destruct Hin as [Hia | Hin].
    * rewrite <- Hia in Hfind. rewrite Hfind in Ea.
      injection Ea as Hca. rewrite <- Hca.
      apply in_fold_acc. apply S.add_1. reflexivity.
    * apply IH with (i := i); assumption.
  + destruct Hin as [Hia | Hin].
    * rewrite <- Hia in Hfind. rewrite Hfind in Ea. discriminate.
    * apply IH with (i := i); assumption.
Qed.

Lemma in_colors_of_1 :
  forall i s f c, S.In i s -> M.find i f = Some c -> S.In c (colors_of f s).
Proof.
intros i s f c Hin Hfind. unfold colors_of. rewrite S.fold_1.
apply (in_colors_of_aux (S.elements s) f S.empty i c).
- apply InA_eq_In. apply S.elements_1. exact Hin.
- exact Hfind.
Qed.

Definition partial_ok (palette : S.t) (g : graph) (f : coloring) : Prop :=
  (forall n c, M.find n f = Some c -> S.In c palette) /\
  (forall i j, S.In j (adj g i) ->
     forall ci cj, M.find i f = Some ci -> M.find j f = Some cj -> ci <> cj).

Lemma color1_partial_ok : forall palette g n f,
  no_selfloop g -> undirected g ->
  partial_ok palette g f ->
  partial_ok palette g (color1 palette g n f).
Proof.
intros palette g n f Hns Hun [Hpal Hdif].
unfold color1.
destruct (S.choose (S.diff palette (colors_of f (adj g n)))) as [c |] eqn:Hc.
- assert (Hcpal : S.In c palette).
  { apply S.diff_1 with (s' := colors_of f (adj g n)).
    apply S.choose_1. exact Hc. }
  assert (Hcout : ~ S.In c (colors_of f (adj g n))).
  { apply S.diff_2 with (s := palette). apply S.choose_1. exact Hc. }
  split.
  + intros m cm Hm. destruct (E.eq_dec m n) as [Hmn | Hmn].
    * rewrite Hmn in Hm. rewrite find_add_same in Hm.
      injection Hm as Hmc. rewrite <- Hmc. exact Hcpal.
    * apply Hpal with (n := m). exact (find_add_other node f n m c cm Hmn Hm).
  + intros i j Hij ci cj Hi Hj.
    destruct (E.eq_dec i n) as [Hin | Hni].
    * destruct (E.eq_dec j n) as [Hjn | Hnj].
      -- exfalso. rewrite Hin, Hjn in Hij. apply (Hns n). exact Hij.
      -- rewrite Hin in Hi, Hij. rewrite find_add_same in Hi.
         injection Hi as Hci.
         assert (Hcj : S.In cj (colors_of f (adj g n))).
         { apply (in_colors_of_1 j (adj g n) f cj); [exact Hij | ].
           exact (find_add_other node f n j c cj Hnj Hj). }
         assert (Hnc : c <> cj).
         { intro Heq. apply Hcout. rewrite Heq. exact Hcj. }
         intro Heqc. apply Hnc. rewrite Hci. exact Heqc.
    * destruct (E.eq_dec j n) as [Hjn | Hnj].
      -- rewrite Hjn in Hj, Hij.
         rewrite find_add_same in Hj. injection Hj as Hcj.
         assert (Hci : S.In ci (colors_of f (adj g n))).
         { apply (in_colors_of_1 i (adj g n) f ci).
           + apply (Hun i n). exact Hij.
           + exact (find_add_other node f n i c ci Hni Hi). }
         assert (Hnc : c <> ci).
         { intro Heq. apply Hcout. rewrite Heq. exact Hci. }
         intro Heqc. apply Hnc. rewrite Hcj. symmetry. exact Heqc.
      -- apply Hdif with (i := i) (j := j).
         ++ exact Hij.
         ++ exact (find_add_other node f n i c ci Hni Hi).
         ++ exact (find_add_other node f n j c cj Hnj Hj).
- exact (conj Hpal Hdif).
Qed.

Lemma fold_right_partial_ok : forall palette g l,
  no_selfloop g -> undirected g ->
  partial_ok palette g (fold_right (color1 palette g) (M.empty node) l).
Proof.
intros palette g l Hns Hun.
induction l as [| n l IH].
- split.
  + intros m cm Hm. rewrite find_empty in Hm. discriminate.
  + intros i j Hij ci cj Hi Hj. rewrite find_empty in Hi. discriminate.
- simpl. apply color1_partial_ok; assumption.
Qed.

Theorem color_correct :
  forall palette g,
       no_selfloop g ->
       undirected g ->
       coloring_ok palette g (color palette g).
Proof.
intros palette g Hns Hun.
unfold color, coloring_ok.
destruct (fold_right_partial_ok palette g (select (S.cardinal palette) g) Hns Hun)
  as [Hpal Hdif].
intros i j Hij. split.
- intros ci Hi. apply Hpal with (n := i). exact Hi.
- intros ci cj Hi Hj. apply Hdif with (i := i) (j := j);
  [exact Hij | exact Hi | exact Hj].
Qed.

(* ---------- 47.9 试跑：一张 7 边图，三色全部着上 ---------- *)

Local Open Scope positive.
(* 现在 1, 2, 3 等字面量按 positive 解释 *)

Definition palette : S.t := fold_right S.add S.empty [1; 2; 3].

Definition add_edge (e : (E.t*E.t)) (g : graph) : graph :=
 M.add (fst e) (S.add (snd e) (adj g (fst e)))
  (M.add (snd e) (S.add (fst e) (adj g (snd e))) g).

Definition mk_graph (el : list (E.t*E.t)) :=
  fold_right add_edge (M.empty _) el.

Definition G :=
    mk_graph [ (5,6); (6,2); (5,2); (1,5); (1,2); (2,4); (1,4)].

Compute (S.elements (Mdomain G)).
(* = [4; 2; 6; 1; 5] *)

Compute (M.elements (color palette G)).
(* = [(4, 1); (2, 3); (6, 2); (1, 2); (5, 1)] ：5 个节点全部着色，无一「溢出」 *)

Example G_all_colored : M.cardinal (color palette G) = M.cardinal G.
Proof. compute. reflexivity. Qed.

Print Assumptions color_correct.

End Ex47Color.
