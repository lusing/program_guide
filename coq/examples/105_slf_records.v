(* 105 记录分离逻辑：字段表示、三层访问规格与记录分配 *)
(* 取材 Software Foundations 卷六 Separation Logic Foundations 的 Records 章。 *)

Set Implicit Arguments.
From SLF Require Import LibSepReference LibSepTLCbuffer.

Implicit Types P : Prop.
Implicit Types H : hprop.
Implicit Types Q : val->hprop.
Implicit Type p q : loc.
Implicit Type k : nat.
Implicit Type i : int.
Implicit Type n z : nat.
Implicit Type v : val.
Implicit Type L : list val.

(* ---------- 105.0 记录实现所需的连续内存块接口 ---------- *)

(* 本章只依赖第 104 章的少量运行时机制，在此独立给出，避免依赖原书章节文件。 *)

Definition hheader (n:int) (p:loc) : hprop :=
  p ~~> (val_int n).

Fixpoint hrange (L:list val) (p:loc) : hprop :=
  match L with
  | nil => \[]
  | x::L' => (p ~~> x) \* (hrange L' (p+1)%nat)
  end.

Ltac is_additional_arith_type T ::=
  match T with
  | loc => constr:(true)
  end.

Lemma triple_ptr_add_nonneg : forall (p:loc) (n:int),
  n >= 0 ->
  triple (val_ptr_add p n)
    \[]
    (fun r => \[r = val_loc (p + abs n)%nat]).
Proof using.
  introv Hn. applys triple_conseq triple_ptr_add.
  { math. } { xsimpl. } { xsimpl. intros ? ->. fequal. math. }
Qed.

Parameter val_alloc : val.

Parameter eval_alloc : forall (n:int) sa Q,
  n >= 0 ->
  (forall p sb,
    sb = Fmap.conseq (LibList.make (abs n) val_uninit) p ->
    p <> null ->
    Fmap.disjoint sa sb ->
    Q (val_loc p) (sb \u sa)) ->
  eval sa (val_alloc (val_int n)) Q.

Lemma hrange_intro : forall L p,
  (hrange L p) (Fmap.conseq L p).
Proof using.
  intros L. induction L as [|L']; intros; rew_listx.
  { applys hempty_intro. }
  { simpl. applys hstar_intro.
    { applys* hsingle_intro. }
    { replace (S p) with (p+1)%nat by math. applys IHL. }
    { applys Fmap.disjoint_single_conseq. left. math. } }
Qed.

Lemma triple_alloc : forall (n:int),
  n >= 0 ->
  triple (val_alloc n)
    \[]
    (funloc p => hrange (LibList.make (abs n) val_uninit) p \* \[p <> null]).
Proof using.
  introv Hn Hsa. applys* eval_alloc. intros p sb Esb Hp D.
  lets ->: hempty_inv Hsa. applys hexists_intro p.
  rewrite hstar_hpure_l. split*. rewrite Fmap.union_empty_r.
  rewrite hstar_hpure_r. split*. subst sb. applys* hrange_intro.
Qed.

#[local] Hint Resolve triple_alloc : triple.

(* ---------- 105.1 单个记录字段的表示 ---------- *)

(* 字段名是从零开始的自然数偏移；字段谓词隐藏头单元之后的指针运算。 *)

Definition field : Type := nat.

Definition hfield (p:loc) (k:field) (v:val) : hprop :=
  (p+1+k)%nat ~~> v.

Global Opaque hfield.

Notation "p `. k '~~>' v" := (hfield p k v)
  (at level 32, k at level 0, no associativity,
   format "p `. k  '~~>'  v").

(* ---------- 105.2 字段集合与记录表示 ---------- *)

Definition hrecord_field : Type := (field * val).
Definition hrecord_fields : Type := list hrecord_field.

Implicit Types kvs : hrecord_fields.

Fixpoint hfields (kvs:hrecord_fields) (p:loc) : hprop :=
  match kvs with
  | nil => \[]
  | (k,v)::kvs' => (p`.k ~~> v) \* (hfields kvs' p)
  end.

Notation "`{ k1 := v1 }" :=
  ((k1,(v1:val))::nil)
  (at level 0, k1 at level 0, only parsing).

Notation "`{ k1 := v1 ; k2 := v2 }" :=
  ((k1,(v1:val))::(k2,(v2:val))::nil)
  (at level 0, k1, k2 at level 0, only parsing).

Notation "`{ k1 := v1 ; k2 := v2 ; k3 := v3 }" :=
  ((k1,(v1:val))::(k2,(v2:val))::(k3,(v3:val))::nil)
  (at level 0, k1, k2, k3 at level 0, only parsing).

Notation "`{ k1 := v1 }" :=
  ((k1,v1)::nil)
  (at level 0, k1 at level 0, only printing).

Notation "`{ k1 := v1 ; k2 := v2 }" :=
  ((k1,v1)::(k2,v2)::nil)
  (at level 0, k1, k2 at level 0, only printing).

Notation "`{ k1 := v1 ; k2 := v2 ; k3 := v3 }" :=
  ((k1,v1)::(k2,v2)::(k3,v3)::nil)
  (at level 0, k1, k2, k3 at level 0, only printing).

Open Scope val_scope.

(* maps_all_fields 要求键恰好依次为 0、1、……、n-1。 *)

Definition maps_all_fields (n:nat) (kvs:hrecord_fields) : Prop :=
  LibList.map fst kvs = nat_seq 0 n.

Definition hrecord (kvs:hrecord_fields) (p:loc) : hprop :=
  \exists n, hheader n p \* hfields kvs p \* \[maps_all_fields n kvs].

Notation "p '~~~>' kvs" := (hrecord kvs p)
  (at level 32).

Lemma hrecord_elim : forall p kvs,
  hrecord kvs p ==> hheader (LibListExec.length kvs) p \* hfields kvs p.
Proof using.
  intros. unfold hrecord. xpull. intros z Hz. xsimpl. xsimpl.
  rewrite LibListExec.length_eq. applys himpl_of_eq. fequal. gen Hz.
  unfold maps_all_fields. generalize 0%nat. gen z.
  induction kvs; intros; destruct z as [|z']; rew_listx in *; tryfalse.
  { math. } { inverts Hz. forwards*: IHkvs H1. math. }
Qed.

Definition head : field := 0%nat.
Definition tail : field := 1%nat.

(* 原书此处仅给出演示框架；这里把完整的消去方向证明到底。 *)

Lemma demo_hrecord_elim : forall p x q,
    p ~~~> `{ head := x ; tail := q }
  ==> hheader 2 p \* (p`.head ~~> x) \* (p`.tail ~~> q).
Proof using. intros. xchange hrecord_elim. simpl. xsimpl*. Qed.

(* ---------- 105.3 读取字段的三层规格 ---------- *)

Declare Scope trm_scope_ext.

Parameter val_get_field : field -> val.

Notation "t1 '`.' k" :=
  (val_get_field k t1)
  (in custom trm at level 56, k at level 0, format "t1 '`.' k" )
  : trm_scope_ext.

Parameter triple_get_field : forall p k v,
  triple (val_get_field k p)
    (p`.k ~~> v)
    (fun r => \[r = v] \* (p`.k ~~> v)).

Fixpoint hfields_lookup (k:field) (kvs:hrecord_fields) : option val :=
  match kvs with
  | nil => None
  | (ki,vi)::kvs' => if Nat.eq_dec k ki
                       then Some vi
                       else hfields_lookup k kvs'
  end.

Parameter triple_get_field_hfields : forall kvs p k v,
  hfields_lookup k kvs = Some v ->
  triple (val_get_field k p)
    (hfields kvs p)
    (fun r => \[r = v] \* hfields kvs p).

Parameter triple_get_field_hrecord : forall kvs p k v,
  hfields_lookup k kvs = Some v ->
  triple (val_get_field k p)
    (hrecord kvs p)
    (fun r => \[r = v] \* hrecord kvs p).

(* ---------- 105.4 写入字段的三层规格 ---------- *)

Parameter val_set_field : field -> val.

Notation "t1 '`.' k ':=' t2" :=
  (val_set_field k t1 t2)
  (in custom trm at level 56, k at level 0, format "t1 '`.' k  ':=' t2")
  : trm_scope_ext.

Parameter triple_set_field : forall v p k v',
  triple (val_set_field k p v)
    (p`.k ~~> v')
    (fun _ => p`.k ~~> v).

Fixpoint hfields_update (k:field) (v:val) (kvs:hrecord_fields)
                        : option hrecord_fields :=
  match kvs with
  | nil => None
  | (ki,vi)::kvs' => if Nat.eq_dec k ki
                       then Some ((k,v)::kvs')
                       else match hfields_update k v kvs' with
                            | None => None
                            | Some LR => Some ((ki,vi)::LR)
                            end
  end.

Parameter triple_set_field_hfields : forall kvs kvs' k p v,
  hfields_update k v kvs = Some kvs' ->
  triple (val_set_field k p v)
    (hfields kvs p)
    (fun _ => hfields kvs' p).

Parameter triple_set_field_hrecord : forall kvs kvs' k p v,
  hfields_update k v kvs = Some kvs' ->
  triple (val_set_field k p v)
    (hrecord kvs p)
    (fun _ => hrecord kvs' p).

(* ---------- 105.5 带初始化器的记录分配 ---------- *)

Parameter val_new_hrecord_2 : field -> field -> val.

Notation "`{ k1 := v1 ; k2 := v2 }" :=
  (val_new_hrecord_2 k1 k2 v1 v2)
  (in custom trm at level 65,
   k1, k2 at level 0,
   v1, v2 at level 65).

Parameter triple_new_hrecord_2 : forall (k1 k2:field) (v1 v2:val),
  k1 = 0%nat ->
  k2 = 1%nat ->
  triple <{ `{ k1 := v1; k2 := v2 } }>
    \[]
    (funloc p => p ~~~> `{ k1 := v1 ; k2 := v2 }).

Definition mcons : val :=
  val_new_hrecord_2 head tail.

Lemma triple_mcons : forall (x q:val),
  triple (mcons x q)
    \[]
    (funloc p => p ~~~> `{ head := x ; tail := q }).
Proof using. intros. applys* triple_new_hrecord_2. Qed.

(* ---------- 105.6 用指针运算实现记录操作 ---------- *)

Module Realization.
Import ProgramSyntax.
Open Scope trm_scope_ext.

Global Transparent hfield.

#[local] Hint Extern 1 (_ >= _) => math : triple.

Ltac is_additional_arith_type T ::=
  match T with
  | loc => constr:(true)
  | field => constr:(true)
  end.

Definition val_get_field (k:field) : val :=
  <{ fun 'p =>
       let 'p1 = val_ptr_add 'p 1 in
       let 'q = val_ptr_add 'p1 {nat_to_Z k} in
       val_get 'q }>.

Notation "t1 '`.' f" :=
  (val_get_field f t1)
  (in custom trm at level 56, f at level 0, format "t1 '`.' f" ).

#[export] Hint Resolve triple_ptr_add_nonneg : triple.

Lemma triple_get_field : forall p k v,
  triple ((val_get_field k) p)
    (p`.k ~~> v)
    (fun r => \[r = v] \* (p`.k ~~> v)).
Proof using.
  unfold hfield. xwp. xapp. xapp. unfolds field.
  math_rewrite (p + abs 1 + k = p+1+k)%nat. xapp. xsimpl*.
Qed.

Definition val_set_field (k:field) : val :=
  <{ fun 'p 'v =>
       let 'p1 = val_ptr_add 'p 1 in
       let 'q = val_ptr_add 'p1 {nat_to_Z k} in
       val_set 'q 'v }>.

Lemma triple_set_field : forall v1 p k v2,
  triple ((val_set_field k) p v2)
    (p`.k ~~> v1)
    (fun _ => p`.k ~~> v2).
Proof using.
  unfold hfield. intros. xwp. xapp. xapp.
  unfolds field. math_rewrite (p + abs 1 + k = p+1+k)%nat. xapp. xsimpl.
Qed.

Notation "t1 '`.' f ':=' t2" :=
  (val_set_field f t1 t2)
  (in custom trm at level 56, f at level 0, format "t1 '`.' f  ':='  t2").

(* ---------- 105.7 从单字段规格推导字段列表规格 ---------- *)

Lemma triple_get_field_hfields : forall kvs p k v,
  hfields_lookup k kvs = Some v ->
  triple (val_get_field k p)
    (hfields kvs p)
    (fun r => \[r = v] \* hfields kvs p).
Proof using.
  intros L. induction L as [| [ki vi] L']; simpl; introv E.
  { inverts E. }
  { case_if.
    { inverts E. subst ki. applys triple_conseq_frame.
      { applys triple_get_field. } { xsimpl. } { xsimpl*. } }
    { applys triple_conseq_frame.
      { applys IHL' E. }
      { xsimpl. }
      { xsimpl*. } } }
Qed.

Lemma triple_set_field_hfields : forall kvs kvs' k p v,
  hfields_update k v kvs = Some kvs' ->
  triple (val_set_field k p v)
    (hfields kvs p)
    (fun _ => hfields kvs' p).
Proof using.
  intros kvs. induction kvs as [| [ki vi] kvs']; simpl; introv E.
  { inverts E. }
  { case_if.
    { inverts E. subst ki. applys triple_conseq_frame.
      { applys triple_set_field. } { xsimpl. } { xsimpl*. } }
    { cases (hfields_update k v kvs') as C2; tryfalse. inverts E.
      applys triple_conseq_frame. { applys IHkvs' C2. }
      { xsimpl. } { simpl. xsimpl*. } } }
Qed.

(* ---------- 105.8 从字段列表规格推导完整记录规格 ---------- *)

Lemma triple_get_field_hrecord : forall kvs p k v,
  hfields_lookup k kvs = Some v ->
  triple (val_get_field k p)
    (hrecord kvs p)
    (fun r => \[r = v] \* hrecord kvs p).
Proof using.
  introv M. unfold hrecord. xtriple. xpull. intros z Hz.
  xapp (>> triple_get_field_hfields M). xsimpl*.
Qed.

Lemma hfields_update_preserves_fields : forall kvs kvs' k v,
  hfields_update k v kvs = Some kvs' ->
  LibList.map fst kvs' = LibList.map fst kvs.
Proof using.
  intros kvs. induction kvs as [|[ki vi] kvs1]; simpl; introv E.
  { introv _ H. inverts H. }
  { case_if.
    { inverts E. rew_listx*. subst. fequals. }
    { cases (hfields_update k v kvs1).
      { inverts E. rew_listx. fequals*. }
      { inverts E. } } }
Qed.

Lemma hfields_update_preserves_maps_all_fields : forall kvs kvs' z k v,
  hfields_update k v kvs = Some kvs' ->
  maps_all_fields z kvs = maps_all_fields z kvs'.
Proof using.
  introv M. unfold maps_all_fields. extens.
  rewrites* (>> hfields_update_preserves_fields M).
Qed.

Lemma triple_set_field_hrecord : forall kvs kvs' k p v,
  hfields_update k v kvs = Some kvs' ->
  triple (val_set_field k p v)
    (hrecord kvs p)
    (fun _ => hrecord kvs' p).
Proof using.
  introv M. unfold hrecord. xtriple. xpull. intros z Hz.
  xapp (>> triple_set_field_hfields M). xsimpl.
  rewrites* <- (>> hfields_update_preserves_maps_all_fields z M).
Qed.

(* ---------- 105.9 分配尚未初始化的记录 ---------- *)

Definition val_alloc_hrecord (ks:list field) : val :=
  <{ fun 'v =>
       let 'm = {LibListExec.length ks} + 1 in
       let 'p = val_alloc 'm in
       val_set 'p {LibListExec.length ks};
       'p }>.

Lemma hfields_eq_hrange : forall z L p kvs,
  maps_all_fields z kvs ->
  z = length L ->
  L = LibList.map snd kvs ->
  hfields kvs p = hrange L (p+1)%nat.
Proof using.
  asserts Ind: (forall L p kvs o,
    LibList.map fst kvs = nat_seq o (length L) ->
    L = LibList.map snd kvs ->
    hfields kvs p = hrange L (p+1+o)%nat).
  { intros L. induction L as [|v L']; introv M E; rew_listx in *;
    destruct kvs as [|[k v'] kvs']; tryfalse; rew_listx in *.
    { auto. }
    { simpls. inverts M as M'. inverts E as E'. rew_listx in *.
      unfold hfield. fequals. math_rewrite (p+1+o+1=p+1+(o+1))%nat.
      applys* IHL'. math_rewrite* (o+1=S o)%nat. } }
  introv M HL E. subst z. rewrites (>> Ind M E). fequals. unfold loc. math.
Qed.

Lemma triple_alloc_hrecord : forall ks,
  ks = nat_seq 0 (LibListExec.length ks) ->
  triple ((val_alloc_hrecord ks) ())
    \[]
    (funloc p => hrecord (LibListExec.map (fun k => (k,val_uninit)) ks) p).
Proof using.
  introv Hks. xwp. xapp. xapp. intros p Hp. unfolds field.
  rewrite LibListExec.length_eq in *. set (n := length ks) in *.
  math_rewrite (abs (n + 1) = S n). rew_listx. simpl.
  xapp. xval. xsimpl*. unfold hrecord. autorewrite with rew_list_exec.
  asserts R: (maps_all_fields n (LibList.map (fun k => (k, val_uninit)) ks)).
  { unfolds. rewrite Hks. clears ks p. generalize 0%nat as o.
    induction n as [|n']; intros; simpl; rew_listx; fequals*. }
  xsimpl* n. xchange* <- (@hfields_eq_hrange n). { rew_listx*. }
  { unfold n. clears n p. induction ks as [|ks']; rew_listx; fequals*. }
Qed.

#[global] Hint Resolve triple_alloc_hrecord : triple.

Lemma triple_alloc_mcons :
  triple (val_alloc_hrecord (head::tail::nil) ())
    \[]
    (funloc p => p ~~~> `{ head := val_uninit ; tail := val_uninit }).
Proof using. applys* triple_alloc_hrecord. Qed.

(* ---------- 105.10 分配并初始化二字段记录 ---------- *)

Definition val_new_hrecord_2 (k1:field) (k2:field) : val :=
  <{ fun 'x1 'x2 =>
       let 'p = {val_alloc_hrecord (k1::k2::nil)} () in
       'p`.k1 := 'x1;
       'p`.k2 := 'x2;
       'p }>.

Notation "`{ k1 := v1 ; k2 := v2 }" :=
  (val_new_hrecord_2 k1 k2 v1 v2)
  (in custom trm at level 65,
   k1, k2 at level 0,
   v1, v2 at level 65) : trm_scope_ext.

Lemma triple_new_hrecord_2 : forall k1 k2 v1 v2,
  k1 = 0%nat ->
  k2 = 1%nat ->
  triple <{ `{ k1 := v1; k2 := v2 } }>
    \[]
    (funloc p => p ~~~> `{ k1 := v1 ; k2 := v2 }).
Proof using.
  introv -> ->. xwp. xapp triple_alloc_hrecord. { reflexivity. }
  intros p. simpl.
  xapp triple_set_field_hrecord. { reflexivity. }
  xapp triple_set_field_hrecord. { reflexivity. }
  xval. xsimpl*.
Qed.

End Realization.

(* ---------- 105.11 扩展 xapp 自动处理记录访问 ---------- *)

Lemma xapp_get_field_lemma : forall H k p Q,
  H ==> \exists kvs, (hrecord kvs p) \*
     match hfields_lookup k kvs with
     | None => \[False]
     | Some v => ((fun r => \[r = v] \* hrecord kvs p) \--* protect Q) end ->
  H ==> wpgen_app (val_get_field k p) Q.
Proof using.
  introv N. xchange N. intros kvs. cases (hfields_lookup k kvs).
  { unfold wpgen_app. xsimpl.
    applys* triple_conseq_frame triple_get_field_hrecord.
    { xsimpl. }
    { xpull. intros r ->. xchange (qwand_specialize v).
      rewrite* hwand_hpure_l. } }
  { xpull. }
Qed.

Lemma xapp_set_field_lemma : forall H k p v Q,
  H ==> \exists kvs, (hrecord kvs p) \*
     match hfields_update k v kvs with
     | None => \[False]
     | Some kvs' => ((fun _ => hrecord kvs' p) \--* protect Q) end ->
  H ==> wpgen_app (val_set_field k p v) Q.
Proof using.
  introv N. xchange N. intros kvs. cases (hfields_update k v kvs).
  { unfold wpgen_app. xsimpl.
    applys* triple_conseq_frame triple_set_field_hrecord.
    { xsimpl. }
    { xpull. intros r. xchange (qwand_specialize r). } }
  { xpull. }
Qed.

Ltac xapp_nosubst_for_records tt ::=
  first [ applys xapp_set_field_lemma; xsimpl; simpl; xapp_simpl
        | applys xapp_get_field_lemma; xsimpl; simpl; xapp_simpl ].
