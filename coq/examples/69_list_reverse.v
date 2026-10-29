(* 69 链表反转 —— 用 VST 验证就地反转链表的 C 程序 *)

(* 69.1 准备：导入 VST 与 clightgen 生成的 Clight AST *)

Require Import VST.floyd.proofauto.
Require Import VC.reverse.
#[export] Instance CompSpecs : compspecs. make_compspecs prog. Defined.
Definition Vprog : varspecs. mk_varspecs prog. Defined.

(* 69.2 链表的分离逻辑表示：listrep 递归谓词 *)

Definition t_list := Tstruct _list noattr.

Fixpoint listrep (sigma: list val) (p: val) : mpred :=
 match sigma with
 | h::hs =>
    EX y:val, data_at Tsh t_list (h,y) p  *  listrep hs y
 | nil =>
    !! (p = nullval) && emp
 end.

Arguments listrep sigma p : simpl never.

(* 69.3 空间谓词的两个 Hint 数据库：saturate_local 与 valid_pointer *)

Lemma data_at_isptr_example1:
  forall (h y p : val) ,
   data_at Tsh t_list (h,y) p |-- !! isptr p.
Proof.
intros.
Print isptr.
(* isptr =
   fun v : val => match v with
                  | Vptr _ _ => True
                  | _ => False
                  end
      : val -> Prop *)
entailer!.
Qed.

Lemma data_at_isptr_example2:
  forall (h y p : val) ,
   data_at Tsh t_list (h,y) p |-- !! isptr p.
Proof.
intros.
saturate_local.
apply prop_right.
Check field_compatible_isptr.
   (* : forall (t : type) (path : list gfield) (p : val),
       field_compatible t path p -> isptr p *)
eapply field_compatible_isptr; eauto.
Qed.

Lemma listrep_facts_example:
 forall sigma p,
   listrep sigma p |-- !! (isptr p \/ p=nullval).
Proof.
intros.
entailer!.
Abort.

Lemma listrep_facts_example:
 forall sigma p,
   listrep sigma p |-- !! (isptr p \/ p=nullval).
Proof.
intros.
saturate_local.
Abort.

Lemma listrep_local_facts:
  forall sigma p,
   listrep sigma p |--
   !! (is_pointer_or_null p /\ (p=nullval <-> sigma=nil)).
Proof.
intros.
revert p; induction sigma; intros p.
- unfold listrep.
  entailer!.
  split; auto.
- unfold listrep; fold listrep.
  entailer.
  entailer!.
  split; intro.
  +
  clear - H H2.
  subst p.
Check field_compatible_isptr.
   (* : forall (t : type) (path : list gfield) (p : val),
       field_compatible t path p -> isptr p *)
Print isptr.
(* isptr =
   fun v : val => match v with
                  | Vptr _ _ => True
                  | _ => False
                  end
      : val -> Prop *)
Print nullval.
(* nullval = if Archi.ptr64 then Vlong Int64.zero else Vint Int.zero
      : val *)
Check field_compatible_nullval.
  (* = forall (CS : compspecs) (t : type) (f : list gfield) (P : Type),
       field_compatible t f nullval -> P *)
  eapply field_compatible_nullval; eauto.
 + inversion H2.
Qed.

#[export] Hint Resolve listrep_local_facts : saturate_local.

Lemma struct_list_valid_pointer_example:
  forall h y p,
   data_at Tsh t_list (h,y) p |-- valid_pointer p.
Proof.
  intros.
  auto with valid_pointer.
Qed.

Lemma listrep_valid_pointer_example:
 forall sigma p,
   listrep sigma p |-- valid_pointer p.
Proof.
 intros.
 auto with valid_pointer.
Abort.

Lemma listrep_valid_pointer:
  forall sigma p,
    listrep sigma p |-- valid_pointer p.
Proof.
 intros.
 unfold listrep.
 destruct sigma; simpl.
- hint.
  entailer!.
- Intros y.
  auto with valid_pointer.
Qed.

#[export] Hint Resolve listrep_valid_pointer : valid_pointer.

(* 69.4 reverse 的函数规格 reverse_spec 与 Gprog *)

Definition reverse_spec : ident * funspec :=
 DECLARE _reverse
  WITH sigma : list val, p: val
  PRE  [ tptr t_list ]
     PROP ()  PARAMS (p)  SEP (listrep sigma p)
  POST [ (tptr t_list) ]
    EX q:val,
     PROP ()  RETURN (q)  SEP (listrep(rev sigma) q).

Definition Gprog : funspecs := [ reverse_spec ].

(* 69.5 主定理 body_reverse：循环不变式与符号执行 *)

Lemma body_reverse: semax_body Vprog Gprog f_reverse reverse_spec.
Proof.
start_function.
forward.  (* w = NULL; *)
forward.  (* v = p; *)
Fail forward.
forward_while
   (EX s1: list val, EX s2 : list val,
    EX w: val, EX v: val,
     PROP (sigma = rev s1 ++ s2)
     LOCAL (temp _w w; temp _v v)
     SEP (listrep s1 w; listrep s2 v)).
- hint.
Exists (@nil val) sigma nullval p.
entailer!.
unfold listrep.
entailer!.
- hint.
entailer!.
- hint.
Fail forward.
destruct s2 as [ | h r].
 + unfold listrep at 2.
   Intros.
   subst. contradiction.
 + unfold listrep at 2; fold listrep.
   Intros y.
   forward. (* t = v->tail *)
   forward. (* v->tail = w; *)
   forward. (* w = v; *)
   forward. (* v = t; *)
   entailer!.
   Exists (h::s1,r,v,y).
   entailer!.
   * simpl. rewrite app_ass. auto.
   * unfold listrep at 3; fold listrep.
     Exists w. entailer!.
- forward.
Exists w; entailer!.
rewrite (proj1 H1) by auto.
unfold listrep at 2; fold listrep.
entailer!.
rewrite app_nil_r, rev_involutive.
auto.
Qed.

(* 69.6 为什么需要分离逻辑：地址反别名 *)

Lemma listrep_len_ge2_fact: forall (a b x: val) (l: list val),
  listrep (a :: b :: l) x |--
  EX y: val, EX z: val,
      data_at Tsh t_list (a,y) x *
      data_at Tsh t_list (b,z) y *
      listrep l z.
Proof.
  intros.
  unfold listrep; fold listrep.
  Intros y z.
  Exists y z.
  cancel.
Qed.

Lemma listrep_len_ge2_address_different: forall (a b x y z: val) (l: list val),
  data_at Tsh t_list (a,y) x *
  data_at Tsh t_list (b,z) y *
  listrep l z |--
  !! (x <> y).
Proof.
  intros.
  Check data_at_conflict.
    (* : forall (sh : Share.t) (t : type) (v v' : reptype t) (p : val),
         sepalg.nonidentity sh ->
         0 < sizeof t -> data_at sh t v p * data_at sh t v' p |-- FF *)
  destruct (Val.eq x y); [| apply prop_right; auto].
  subst x.
  sep_apply (data_at_conflict Tsh t_list (a, y)).
  + auto.
  + entailer!.
Qed.

Print Assumptions body_reverse.
(* Axioms:
   ClassicalDedekindReals.sig_not_dec : forall P : Prop, {~ ~ P} + {~ P}
   ClassicalDedekindReals.sig_forall_dec :
     forall P : nat -> Prop,
     (forall n : nat, {P n} + {~ P n}) ->
     {n : nat | ~ P n} + {forall n : nat, P n}
   prop_ext : ClassicalFacts.prop_extensionality
   functional_extensionality_dep :
     forall (A : Type) (B : A -> Type) (f g : forall x : A, B x),
     (forall x : A, f x = g x) -> f = g
   Eqdep.Eq_rect_eq.eq_rect_eq :
     forall (U : Type) (p : U) (Q : U -> Type) (x : Q p) (h : p = p),
     x = eq_rect p Q x p h
   Classical_Prop.classic : forall P : Prop, P \/ ~ P
   Ensembles.Extensionality_Ensembles :
     forall (U : Type) (A B : Ensembles.Ensemble U),
     Ensembles.Same_set A B -> A = B *)
