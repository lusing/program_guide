(* 68 VST 入门 —— 分离逻辑验证 C 程序：数组求和 *)

(* ---------- 68.1 标准样板：compspecs 与 Vprog ---------- *)

Require Import VST.floyd.proofauto.
Require Import VC.sumarray.
#[export] Instance CompSpecs : compspecs. make_compspecs prog. Defined.
Definition Vprog : varspecs.  mk_varspecs prog. Defined.

(* ---------- 68.2 函数模型 sum_Z ---------- *)

Definition sum_Z : list Z -> Z := fold_right Z.add 0.

Lemma sum_Z_app:
  forall a b, sum_Z (a++b) =  sum_Z a + sum_Z b.
Proof.
  intros. induction a; simpl; lia.
Qed.

(* ---------- 68.3 API 规格：sumarray_spec ---------- *)

Definition sumarray_spec : ident * funspec :=
DECLARE _sumarray
 WITH a: val, sh : share, contents : list Z, size: Z
 PRE [ tptr tuint, tint ]
  PROP  (readable_share sh; 0 <= size <= Int.max_signed;
         Forall (fun x => 0 <= x <= Int.max_unsigned) contents)
  PARAMS (a; Vint (Int.repr size))
  SEP   (data_at sh (tarray tuint size) (map Vint (map Int.repr contents)) a)
 POST [ tuint ]
  PROP () RETURN (Vint (Int.repr (sum_Z contents)))
  SEP (data_at sh (tarray tuint size) (map Vint (map Int.repr contents)) a).

(* ---------- 68.4 main 的规格 ---------- *)

Definition main_spec :=
 DECLARE _main
  WITH gv : globals
  PRE  [] main_pre prog tt gv
  POST [ tint ]
     PROP()
     RETURN (Vint (Int.repr (1+2+3+4)))
     SEP(TT).

(* ---------- 68.5 汇总 Gprog ---------- *)

Definition Gprog := [sumarray_spec; main_spec].

(* ---------- 68.6 证明 sumarray 的函数体 ---------- *)

Lemma body_sumarray: semax_body Vprog Gprog f_sumarray sumarray_spec.
Proof.
start_function.
forward.
forward.
forward_while
 (EX i: Z,
   PROP  (0 <= i <= size)
   LOCAL (temp _a a;
          temp _i (Vint (Int.repr i));
          temp _n (Vint (Int.repr size));
          temp _s (Vint (Int.repr (sum_Z (sublist 0 i contents)))))
   SEP   (data_at sh (tarray tuint size) (map Vint (map Int.repr contents)) a)).
- Exists 0.
  entailer!.
- entailer!.
- assert_PROP (Zlength contents = size). {
    entailer!.
    do 2 rewrite Zlength_map. reflexivity.
  }
  forward.
  forward.
  forward.
  Exists (i+1).
  entailer!.
  f_equal. f_equal.
  rewrite (sublist_split 0 i (i+1)) by lia.
  rewrite sum_Z_app. rewrite (sublist_one i) by lia.
  simpl. lia.
- forward.
  entailer!.
  autorewrite with sublist in *|-.
  autorewrite with sublist.
  reflexivity.
Qed.

(* ---------- 68.7 全局变量与 main 的函数体证明 ---------- *)

Definition four_contents := [1; 2; 3; 4].

Lemma body_main:  semax_body Vprog Gprog f_main main_spec.
Proof.
  start_function.
  forward_call (gv _four, Ews, four_contents, 4).
  repeat constructor; computable.
  forward.
Qed.

(* ---------- 68.8 整个程序的正确性 ---------- *)

#[export] Existing Instance NullExtension.Espec.

Lemma prog_correct: semax_prog prog tt Vprog Gprog.
Proof.
prove_semax_prog.

semax_func_cons body_sumarray.
semax_func_cons body_main.
Qed.

Print Assumptions prog_correct.
(* Axioms:
ClassicalDedekindReals.sig_not_dec : forall P : Prop, {~ ~ P} + {~ P}
ClassicalDedekindReals.sig_forall_dec :
  forall P : nat -> Prop,
  (forall n : nat, {P n} + {~ P n}) ->
  {n : nat | ~ P n} + {forall n : nat, ~ P n}
prop_ext : ClassicalFacts.prop_extensionality
functional_extensionality_dep :
  forall (A : Type) (B : A -> Type) (f g : forall x : A, B x),
  f = g -> forall x : A, f x = g x
Eqdep.Eq_rect_eq.eq_rect_eq :
  forall (U : Type) (p : U) (Q : U -> Type) (x : Q p) (h : p = p),
  x = eq_rect p Q x p h
Classical_Prop.classic : forall P : Prop, P \/ ~ P
Ensembles.Extensionality_Ensembles :
  forall (U : Type) (A B : Ensembles.Ensemble U),
  Ensembles.Same_set U A B -> A = B *)
