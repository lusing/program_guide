(* 104 数组分离逻辑：大足迹、小足迹、区间聚焦与快速排序 *)
(* 取材 Software Foundations 卷六 Separation Logic Foundations 的 Arrays 章。 *)

Set Implicit Arguments.
From SLF Require Import LibSepReference LibSepTLCbuffer.
#[global] Hint Rewrite conseq_cons' : rew_listx.
Open Scope wp_scope.

Implicit Types P : Prop.
Implicit Types H : hprop.
Implicit Types Q : val->hprop.
Implicit Types p q : loc.
Implicit Types k : nat.
Implicit Types i n : int.
Implicit Types v : val.

Module Arrays.

(* ---------- 104.1 数组操作的大足迹规格 ---------- *)

(* harray L p 拥有地址 p 处的整个数组，逻辑内容由列表 L 描述。 *)

Parameter harray : forall (L:list val) (p:loc), hprop.

Parameter val_array_make : val.
Parameter val_array_length : val.
Parameter val_array_get : val.
Parameter val_array_set : val.

Parameter triple_array_make : forall n v,
  n >= 0 ->
  triple (val_array_make n v)
    \[]
    (funloc p => harray (LibList.make (abs n) v) p).

Parameter triple_array_make' : forall n v,
  n >= 0 ->
  triple (val_array_make n v)
    \[]
    (funloc p => \exists L, harray L p
                 \* \[n = length L]
                 \* \[forall i, 0 <= i < n -> LibList.nth (abs i) L = v]).

Parameter triple_array_length : forall L p,
  triple (val_array_length p)
    (harray L p)
    (fun r => \[r = length L] \* harray L p).

Parameter triple_array_get : forall L p i,
  0 <= i < length L ->
  triple (val_array_get p i)
    (harray L p)
    (fun r => \[r = LibList.nth (abs i) L] \* harray L p).

Parameter triple_array_set : forall L p i v,
  0 <= i < length L ->
  triple (val_array_set p i v)
    (harray L p)
    (fun _ => harray (LibList.update (abs i) v L) p).

#[local] Hint Resolve triple_array_get triple_array_set
                       triple_array_make triple_array_length : triple.

(* ---------- 104.2 头部与单元格的小足迹规格 ---------- *)

(* hheader n p 只拥有保存长度的头单元；hcell v p i 只拥有第 i 个元素。 *)

Parameter hcell : forall (v:val) (p:loc) (i:int), hprop.
Parameter hheader : forall (n:int) (p:loc), hprop.

Parameter triple_array_length_hheader : forall n p,
  triple (val_array_length p)
    (hheader n p)
    (fun r => \[r = (n:int)] \* hheader n p).

Parameter triple_array_get_hcell : forall p i v,
  triple (val_array_get p i)
    (hcell v p i)
    (fun r => \[r = v] \* hcell v p i).

Parameter triple_array_set_hcell : forall p i v w,
  triple (val_array_set p i v)
    (hcell w p i)
    (fun _ => hcell v p i).

(* ---------- 104.3 数组区间 hseg ---------- *)

Fixpoint hseg (L:list val) (p:loc) (j:int) : hprop :=
  match L with
  | nil => \[]
  | x::L' => (hcell x p j) \* (hseg L' p (j+1))
  end.

Lemma hseg_nil : forall p j,
  hseg nil p j = \[].
Proof using. auto. Qed.

Lemma hseg_one : forall v p j,
  hseg (v::nil) p j = hcell v p j.
Proof using. intros. simpl. xsimpl*. Qed.

Parameter hseg_app : forall p j L1 L2,
    hseg (L1 ++ L2) p j
  = hseg L1 p j \* hseg L2 p (j + length L1).

Lemma hseg_cons : forall v p j L,
  hseg (v::L) p j = hcell v p j \* hseg L p (j+1).
Proof using. auto. Qed.

Lemma hseg_last : forall v p j L,
  hseg (L&v) p j = hseg L p j \* hcell v p (j+length L).
Proof using. intros. rewrite hseg_app. rewrite hseg_cons, hseg_nil. xsimpl. Qed.

Lemma hseg_cons_r : forall L v p j1 j2,
  j2 = j1 + 1 ->
  hcell v p j1 \* hseg L p j2 ==> hseg (v::L) p j1.
Proof using. intros. subst. rewrite* hseg_cons. Qed.

Lemma hseg_app_r : forall p L1 L2 j1 j2,
  j2 = j1 + length L1 ->
  hseg L1 p j1 \* hseg L2 p j2 ==> hseg (L1 ++ L2) p j1.
Proof using. intros. subst. rewrite* hseg_app. Qed.

Lemma hseg_last_r : forall v p j L j',
  j' = (j+length L) ->
  hseg L p j \* hcell v p j' ==> hseg (L&v) p j.
Proof using. intros. subst. rewrite* hseg_last. Qed.

Parameter triple_array_make_hseg : forall n v,
  n >= 0 ->
  triple (val_array_make n v)
    \[]
    (funloc p => hheader (abs n) p \* hseg (LibList.make (abs n) v) p 0).

Parameter triple_array_get_hseg : forall L p i j,
  0 <= i - j < length L ->
  triple (val_array_get p i)
    (hseg L p j)
    (fun r => \[r = LibList.nth (abs (i-j)) L] \* hseg L p j).

Parameter triple_array_set_hseg : forall L p i j v,
  0 <= i - j < length L ->
  triple (val_array_set p i v)
    (hseg L p j)
    (fun _ => hseg (LibList.update (abs (i-j)) v L) p j).

(* ---------- 104.4 快速排序的安全性 ---------- *)

Module QuickSort.
Export NotationForVariables.

Parameter val_pivot : val.

Parameter triple_pivot_safety : forall p i n L,
  n = length L ->
  n >= 1 ->
  triple (val_pivot p i n)
    (hseg L p i)
    (fun r => \exists (j:int), \[r = val_int j] \*
              \exists (x:int) (L' L1 L2:list val), hseg L' p i \* \[
                  length L' = length L
               /\ L' = L1 ++ val_int x :: L2
               /\ j - i = length L1 ]).

Definition val_quicksort : val :=
  <{ fix 'f 'p 'i 'n =>
       let 'b = 'n > 1 in
       if 'b then
         let 'j = val_pivot 'p 'i 'n in
         let 'n1 = 'j - 'i in
         'f 'p 'i 'n1;
         let 'i2 = 'j + 1 in
         let 'n3 = 'n - 'n1 in
         let 'n2 = 'n3 - 1 in
         'f 'p 'i2 'n2
       end }>.

(* 原书练习（4 星）：递归调用只拥有各自区间，枢轴单元与区间外资源均被框架保留。 *)

Lemma triple_quicksort_safety : forall p i n L,
  n = length L ->
  i >= 0 ->
  triple (val_quicksort p i n)
    (hseg L p i)
    (fun _ => \exists L', \[length L' = length L] \* hseg L' p i).
Proof using.
  introv Hn Hi. gen i L. induction_wf IH: (downto 0) n. unfold downto in IH. intros.
  xwp. xapp. xif; intros C.
  { xapp triple_pivot_safety; try math.
    intros j x L' L1 L2 (HL'&->&Hj). rew_list in *. xapp.
    xchange hseg_app. xchange hseg_cons.
    math_rewrite (i + length L1 = j).
    xapp (>> IH L1); rew_list*; try math.
    intros L1' HL1'. xapp. xapp. xapp.
    xapp (>> IH L2); rew_list*; try math.
    intros L2' HL2'. xchange <- hseg_cons.
    rewrite (hstar_comm (hseg (val_int x::L2') p j) (hseg L1' p i)).
    xchange (>> hseg_app_r p L1' (val_int x::L2') i j). { math. } xsimpl*.
    rew_list in *. math. }
  { xval. xsimpl*. }
Qed.

(* ---------- 104.5 排列与有序列表 ---------- *)

Inductive permut (A:Type) : list A -> list A -> Prop :=
  | permut_mid : forall L1 L2 L3 L4,
      permut (L1 ++ L2 ++ L3 ++ L4) (L1 ++ L3 ++ L2 ++ L4)
  | permut_trans : forall L3 L1 L2,
      permut L1 L2 ->
      permut L2 L3 ->
      permut L1 L3.

Lemma permut_refl : forall A (L:list A),
  permut L L.
Proof using. intros. applys permut_mid (@nil A) (@nil A) (@nil A) L. Qed.

Lemma permut_sym : forall A (L1 L2: list A),
  permut L1 L2 ->
  permut L2 L1.
Proof using.
  introv M. induction M.
  { applys* permut_mid. }
  { applys* permut_trans IHM2. }
Qed.

#[local] Hint Resolve permut_refl.

Lemma permut_length : forall A (L L':list A),
  permut L L' ->
  length L = length L'.
Proof using. introv M. induction M; rew_list in *; try math. Qed.

Lemma permut_app : forall A (L1 L2 L1' L2':list A),
  permut L1 L1' ->
  permut L2 L2' ->
  permut (L1 ++ L2) (L1' ++ L2').
Proof using.
  introv M1 M2. applys permut_trans (L1' ++ L2).
  { clear M2. induction M1.
    { rew_list. applys permut_mid. }
    { applys* permut_trans IHM1_2. } }
  { clear M1. induction M2.
    { repeat rewrite <- (app_assoc L1'). applys permut_mid. }
    { applys* permut_trans IHM2_2. } }
Qed.

Lemma permut_cons : forall A (x:A) L1 L1',
  permut L1 L1' ->
  permut (x :: L1) (x :: L1').
Proof using. intros. applys* permut_app (x::nil) L1 (x::nil) L1'. Qed.

Lemma permut_last : forall A (x:A) L1 L1',
  permut L1 L1' ->
  permut (L1 & x) (L1' & x).
Proof using. intros. applys* permut_app L1 (x::nil) L1' (x::nil). Qed.

Lemma permut_swap_first_two : forall A (x y : A) (L:list A),
  permut (x :: y :: L) (y :: x :: L).
Proof using. intros. applys permut_mid (@nil A) (x::nil) (y::nil) L. Qed.

Lemma permut_swap_first_last : forall A (x : A) (L:list A),
  permut (x::L) (L&x).
Proof using.
  intros. applys_eq (>> permut_mid (@nil A) (x::nil) L (@nil A)). rew_list*.
Qed.

Lemma permut_Forall : forall A (P:A->Prop) L L',
  Forall P L ->
  permut L L' ->
  Forall P L'.
Proof using.
  introv N M. gen N. induction M; intros; auto.
  { repeat rewrite Forall_app_eq in *. autos*. }
Qed.

Inductive sorted : list int -> Prop :=
  | sorted_nil : sorted nil
  | sorted_one : forall x, sorted (x :: nil)
  | sorted_cons : forall x y L,
      x <= y ->
      sorted (y :: L) ->
      sorted (x :: y :: L).

Definition list_of_gt (x:int) (L:list int) : Prop :=
  Forall (fun y => y > x) L.

Definition list_of_le (x:int) (L:list int) : Prop :=
  Forall (fun y => y <= x) L.

Lemma sorted_cons_gt : forall x L,
  list_of_gt x L ->
  sorted L ->
  sorted (x :: L).
Proof using.
  introv N M. destruct L as [|].
  { applys sorted_one. }
  { lets (Hv&_): Forall_cons_inv N. applys* sorted_cons. math. }
Qed.

Lemma sorted_app_le : forall x L1 L2,
  list_of_le x L1 ->
  sorted L1 ->
  sorted (x :: L2) ->
  sorted (L1 ++ x :: L2).
Proof using.
  introv N M1 M2. induction M1; rew_list in *. { auto. }
  { lets (Hv&_): Forall_cons_inv N. applys* sorted_cons. }
  { lets (_&N'): Forall_cons_inv N. applys* sorted_cons. }
Qed.

(* vals_int 把整数逻辑列表映射为源语言值列表。 *)

Definition vals_int (L:list int) : list val :=
  LibList.map val_int L.

Lemma vals_int_nil : vals_int nil = nil.
Proof using. intros. unfold vals_int. rew_listx*. Qed.

Lemma vals_int_cons : forall x L,
  vals_int (x :: L) = val_int x :: vals_int L.
Proof using. intros. unfold vals_int. rew_listx*. Qed.

Lemma vals_int_app : forall L1 L2,
  vals_int (L1 ++ L2) = vals_int L1 ++ vals_int L2.
Proof using. intros. unfold vals_int. rew_listx*. Qed.

Lemma vals_int_last : forall x L,
  vals_int (L & x) = vals_int L & val_int x.
Proof using. intros. unfold vals_int. rew_listx*. Qed.

Lemma length_vals_int : forall L,
  length (vals_int L) = length L.
Proof using. intros. unfold vals_int. rew_listx*. Qed.

#[local] Hint Rewrite vals_int_nil vals_int_cons vals_int_app
    vals_int_last length_vals_int : rew_list.
#[local] Hint Rewrite vals_int_nil vals_int_cons vals_int_app
    vals_int_last length_vals_int : rew_listx.

(* ---------- 104.6 快速排序的功能正确性 ---------- *)

Parameter triple_pivot : forall n p i L,
  n = length L ->
  n >= 1 ->
  triple (val_pivot p i n)
    (hseg (vals_int L) p i)
    (fun r => \exists j, \[r = val_int j] \*
              \exists x L' L1 L2, hseg (vals_int L') p i \* \[
                  permut L L'
               /\ L' = L1 ++ x :: L2
               /\ j - i = length L1
               /\ list_of_le x L1
               /\ list_of_gt x L2 ]).

(* 原书练习（5 星，可选）：在安全性证明上增加排列与有序性不变式。 *)

Lemma triple_quicksort : forall p i n L,
  n = length L ->
  i >= 0 ->
  triple (val_quicksort p i n)
    (hseg (vals_int L) p i)
    (fun _ => \exists L', \[permut L L' /\ sorted L']
                          \* hseg (vals_int L') p i).
Proof using.
  introv Hn Hi. gen i L. induction_wf IH: (downto 0) n. unfold downto in IH. intros.
  xwp. xapp. xif; intros C.
  { xapp triple_pivot; try math.
    intros j x L' L1 L2 (HP&->&Hj&Hle&Hgt).
    lets HL': permut_length HP. rew_list in *. xapp.
    rew_listx. xchange hseg_app. xchange hseg_cons. rew_listx.
    math_rewrite (i + length L1 = j).
    xapp (>> IH L1); rew_list*; try math.
    intros L1' (HP1&HS1). xapp. xapp. xapp.
    xapp (>> IH L2); rew_list*; try math.
    intros L2' (HP2&HS2). xchange <- hseg_cons.
    lets E1: permut_length HP1.
    rewrite (hstar_comm (hseg (val_int x::vals_int L2') p j)
                        (hseg (vals_int L1') p i)).
    xchange (>> hseg_app_r p (vals_int L1') (val_int x::vals_int L2') i j).
    { rew_list. math. } xsimpl (L1' ++ x :: L2').
    { splits.
      { applys permut_trans HP. applys permut_app HP1. applys permut_cons HP2. }
      { applys sorted_app_le.
        { unfold list_of_le in *. eapply permut_Forall; [exact Hle | exact HP1]. }
        { auto. }
        { applys sorted_cons_gt.
          { unfold list_of_gt in *. eapply permut_Forall; [exact Hgt | exact HP2]. }
          { auto. } } } }
    { rew_list*. } }
  { xval. destruct L as [|x [|]]; rew_list in *; try (false; math).
    { xsimpl (@nil int). splits. applys permut_refl. applys sorted_nil. }
    { xsimpl (x::nil). splits. applys permut_refl. applys sorted_one. } }
Qed.

Definition val_quicksort_full : val :=
  <{ fun 'p =>
       let 'n = val_array_length 'p in
       val_quicksort 'p 0 'n }>.

Parameter harray_eq : forall p L,
  harray L p = \exists n, \[n = length L] \* hheader n p \* hseg L p 0.

(* 原书练习（2 星，可选）：把整数组规格转换为头单元加完整区间。 *)

Lemma triple_quicksort_full : forall p L,
  triple (val_quicksort_full p)
    (harray (vals_int L) p)
    (fun _ => \exists L', \[permut L L' /\ sorted L']
              \* harray (vals_int L') p).
Proof using.
  intros. xwp. xchange harray_eq. xpull. intros n Hn. rew_list in Hn. subst n.
  xapp triple_array_length_hheader. xapp triple_quicksort; rew_list*; try math.
  intros L' (HP&HS). lets E: permut_length HP.
  xchange <- harray_eq. { rew_list. math. } xsimpl*.
Qed.

End QuickSort.

(* ---------- 104.7 头部、单元格与整数组的具体表示 ---------- *)

Module Realization.

Definition hheader (n:int) (p:loc) : hprop :=
  p ~~> (val_int n).

Lemma hheader_eq : forall p n,
  (hheader n p) = (p ~~> (val_int n)).
Proof using. auto. Qed.

Definition hcell (v:val) (p:loc) (i:int) : hprop :=
  ((p + 1 + abs i)%nat ~~> v) \* \[i >= 0].

Lemma hcell_eq : forall v p i,
  (hcell v p i) = ((p + 1 + abs i)%nat ~~> v) \* \[i >= 0].
Proof using. auto. Qed.

Lemma hcell_nonneg : forall v p i,
  hcell v p i ==> hcell v p i \* \[i >= 0].
Proof using. unfold hcell. xsimpl*. Qed.

Fixpoint hseg (L:list val) (p:loc) (j:int) : hprop :=
  match L with
  | nil => \[]
  | x::L' => (hcell x p j) \* (hseg L' p (j+1))
  end.

Definition harray (L:list val) (p:loc) : hprop :=
  hheader (length L) p \* hseg L p 0.

Lemma harray_eq : forall p L,
  harray L p = \exists n, \[n = length L] \* hheader n p \* hseg L p 0.
Proof using. unfold harray. xsimpl*. { intros; subst*. } Qed.

Lemma hseg_start_eq : forall L p j1 j2,
  j1 = j2 ->
  hseg L p j1 ==> hseg L p j2.
Proof using. intros. subst*. Qed.

#[local] Hint Extern 1 (hseg ?L ?p ?j1 ==> hseg ?L ?p ?j2) =>
  apply hseg_start_eq; math.

Lemma hseg_nil : forall p j,
  hseg nil p j = \[].
Proof using. auto. Qed.

Lemma hseg_one : forall v p j,
  hseg (v::nil) p j = hcell v p j.
Proof using. intros. simpl. xsimpl*. Qed.

Lemma hseg_cons : forall v p j L,
  hseg (v::L) p j = hcell v p j \* hseg L p (j+1).
Proof using. intros. simpl. xsimpl*. Qed.

(* 原书练习（3 星）：对 L1 归纳，利用分离合取的结合律和长度算术。 *)

Lemma hseg_app : forall L1 L2 p j,
    hseg (L1 ++ L2) p j
  = hseg L1 p j \* hseg L2 p (j + length L1).
Proof using.
  intros L1. induction L1 as [|x L1']; intros; rew_list.
  { simpl. rewrite hstar_hempty_l. fequals_rec. math. }
  { simpl. rewrite IHL1'. rewrite <- Nat.add_1_r. rewrite hstar_assoc.
    replace (j + (length L1' + 1)%nat) with (j + 1 + length L1') by math.
    reflexivity. }
Qed.

(* ---------- 104.8 聚焦：借出一个单元并保留归还魔杖 ---------- *)

(* 原书练习（4 星）：把列表分成 L1 ++ v :: L2，再聚焦中间单元。 *)

Lemma hseg_focus_relative : forall (k:nat) L p j,
  0 <= k < length L ->
      hseg L p j
  ==> let v := LibList.nth k L in
         hcell v p (j+k)
      \* (\forall w, hcell w p (j+k) \-* hseg (LibList.update k w L) p j).
Proof using.
  introv Hk. lets (L1&v&L2&->&HL1): LibList.list_middle_inv k L. { math. }
  subst k. rewrite LibList.nth_middle; [|auto]. rewrite hseg_app. simpl.
  xsimpl. intros w. rewrite LibList.update_middle.
  { rew_list. rewrite hseg_app. simpl. xsimpl*. }
  { typeclass. }
  { auto. }
Qed.

Arguments hseg_focus_relative : clear implicits.

Lemma hseg_focus : forall i L p j,
  0 <= i-j < length L ->
      hseg L p j
  ==> let v := LibList.nth (abs (i-j)) L in
         hcell v p i
      \* (\forall w, hcell w p i \-* hseg (LibList.update (abs (i-j)) w L) p j).
Proof using.
  introv Hk. xchange (hseg_focus_relative (abs (i-j))). { math. }
  math_rewrite (j + abs (i - j) = i). xsimpl.
Qed.

Arguments hseg_focus : clear implicits.

Lemma harray_focus : forall i L p,
  0 <= i < length L ->
      harray L p
  ==> let v := LibList.nth (abs i) L in
         hcell v p i
      \* (\forall w, hcell w p i \-* harray (LibList.update (abs i) w L) p).
Proof using.
  introv Hi. unfold harray. xchange (hseg_focus i). { math. }
  math_rewrite (i - 0 = i). xsimpl. intros w.
  xchange (hforall_specialize w). xsimpl.
  rewrite* LibList.length_update.
Qed.

Arguments harray_focus : clear implicits.

(* 原书练习（3 星，可选）：把可写聚焦中的 w 实例化为原值。 *)

Lemma harray_focus_read : forall i L p,
  0 <= i < length L ->
      harray L p
  ==> let v := LibList.nth (abs i) L in
      hcell v p i \* (hcell v p i \-* harray L p).
Proof using.
  introv Hi. xchange (harray_focus i). { math. }
  xsimpl. xchange (hforall_specialize (LibList.nth (abs i) L)).
  rewrite LibList.update_nth_same.
  { xsimpl*. }
  { math. }
Qed.

Arguments harray_focus_read : clear implicits.

End Realization.

End Arrays.
