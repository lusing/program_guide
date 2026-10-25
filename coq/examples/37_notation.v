(* 37 自定义记号与语法 —— Coercion、Notation、Custom Entry、level 阶梯与 assn 再造 *)

From Stdlib Require Import Arith Bool List Strings.String.
Import ListNotations.

Module Ex37Notation.

(* ---------- 37.1 为什么需要 Coercion：string / nat 怎么变成 aexp ---------- *)

Definition total_map (A : Type) := string -> A.

Definition t_empty {A : Type} (v : A) : total_map A :=
  fun _ => v.

Definition t_update {A : Type} (m : total_map A) (x : string) (v : A) :=
  fun x' => if String.eqb x x' then v else m x'.

Notation "'__' '!->' v" := (t_empty v)
  (at level 100, right associativity).

Notation "x '!->' v ';' m" := (t_update m x v)
  (at level 100, v constr at level 100, right associativity).

Definition state := total_map nat.

Inductive aexp : Type :=
  | ANum (n : nat)
  | AId (x : string)
  | APlus (a1 a2 : aexp)
  | AMinus (a1 a2 : aexp)
  | AMult (a1 a2 : aexp).

Definition X : string := "X".
Definition Y : string := "Y".
Definition Z : string := "Z".

Inductive bexp : Type :=
  | BTrue
  | BFalse
  | BEq (a1 a2 : aexp)
  | BNeq (a1 a2 : aexp)
  | BLe (a1 a2 : aexp)
  | BGt (a1 a2 : aexp)
  | BNot (b : bexp)
  | BAnd (b1 b2 : bexp).

Definition raw_aexp : aexp := APlus (AId X) (ANum 2).

Fail Definition no_coercion : aexp := X.

Fail Definition no_coercion_pair : aexp := APlus X 2.

Coercion AId : string >-> aexp.
Coercion ANum : nat >-> aexp.

Definition sugar_aexp : aexp := APlus X 2.

Check X.

Fail Definition wrong_way : nat := AId X.

Set Printing Coercions.
Print sugar_aexp.
Unset Printing Coercions.

(* ---------- 37.2 Notation 的基本形态与 scope：一个最小对照实验 ---------- *)

Definition addmul (a b : nat) : nat := a + a * b.

Declare Scope n_demo_scope.
Delimit Scope n_demo_scope with nd.

Notation "a '+*' b" := (addmul a b)
  (at level 40, left associativity) : n_demo_scope.

Check ((1 +* 2))%nd.

Example nd_left_assoc : ((1 +* 2 +* 3))%nd = 12.
Proof. reflexivity. Qed.

Open Scope n_demo_scope.

Check 1 +* 2 +* 3.

Close Scope n_demo_scope.

Fail Check (1 +* 2).

Fail Check nat * nat.

Check (nat * nat)%type.

(* ---------- 37.3 自定义条目 com 与三层抬进记号 ---------- *)

Declare Custom Entry com.
Declare Scope com_scope.

Notation "<{ e }>" := e
  (e custom com, format "'[hv' <{ '/  ' '[v' e ']' '/' }> ']'") : com_scope.

Notation "( x )" := x (in custom com, x at level 99).
Notation "x" := x (in custom com at level 0, x constr at level 0).

Notation "f x .. y" := (.. (f x) .. y)
                  (in custom com at level 0, only parsing,
                  f constr at level 0, x constr at level 1,
                      y constr at level 1).

Notation "x + y"   := (APlus x y) (in custom com at level 50, left associativity).
Notation "x - y"   := (AMinus x y) (in custom com at level 50, left associativity).
Notation "x * y"   := (AMult x y) (in custom com at level 40, left associativity).

Notation "'true'"  := BTrue (in custom com at level 0).
Notation "'false'" := BFalse (in custom com at level 0).

Notation "x <= y"  := (BLe x y) (in custom com at level 70, no associativity).
Notation "x > y"   := (BGt x y) (in custom com at level 70, no associativity).
Notation "x = y"   := (BEq x y) (in custom com at level 70, no associativity).
Notation "x <> y"  := (BNeq x y) (in custom com at level 70, no associativity).
Notation "x && y"  := (BAnd x y) (in custom com at level 80, left associativity).
Notation "'~' b"   := (BNot b) (in custom com at level 75, right associativity).

Open Scope com_scope.

Definition example_aexp : aexp := <{ 3 + (X * 2) }>.
Definition example_bexp : bexp := <{ true && ~(X <= 4) }>.

Print example_aexp.

(* ---------- 37.4 命令记号与 level 阶梯：85 / 89 / 90 / 99 ---------- *)

Inductive com : Type :=
  | CSkip
  | CAsgn (x : string) (a : aexp)
  | CSeq (c1 c2 : com)
  | CIf (b : bexp) (c1 c2 : com)
  | CWhile (b : bexp) (c : com).

Notation "'skip'"  := CSkip
  (in custom com at level 0) : com_scope.
Notation "x := y"  := (CAsgn x y)
  (in custom com at level 0, x constr at level 0, y at level 85, no associativity,
    format "x  :=  y") : com_scope.
Notation "x ; y" := (CSeq x y)
  (in custom com at level 90,
    right associativity,
    format "'[v' x ; '/' y ']'") : com_scope.
Notation "'if' x 'then' y 'else' z 'end'" := (CIf x y z)
  (in custom com at level 89, x at level 99, y at level 99, z at level 99,
    format "'[v' 'if'  x  'then' '/  ' y '/' 'else' '/  ' z '/' 'end' ']'") : com_scope.
Notation "'while' x 'do' y 'end'" := (CWhile x y)
  (in custom com at level 89, x at level 99, y at level 99,
    format "'[v' 'while'  x  'do' '/  ' y '/' 'end' ']'") : com_scope.

Definition left_chain : aexp := <{ X - Y - Z }>.
Definition right_chain : com := <{ X := 1; Y := 2; Z := 3 }>.

Unset Printing Notations.
Print left_chain.
Print right_chain.
Set Printing Notations.

Definition subtract_slowly_body : com :=
  <{ Z := Z - 1 ;
     X := X - 1 }>.

Definition subtract_slowly : com :=
  <{ while X <> 0 do
       subtract_slowly_body
     end }>.

Definition fact_in_coq : com :=
  <{ Z := X;
     Y := 1;
     while Z <> 0 do
       Y := Y * Z;
       Z := Z - 1
     end }>.

Print fact_in_coq.

(* ---------- 37.5 语义小验：aeval / beval 与 reflexivity ---------- *)

Fixpoint aeval (st : state) (a : aexp) : nat :=
  match a with
  | ANum n => n
  | AId x => st x
  | <{a1 + a2}> => (aeval st a1) + (aeval st a2)
  | <{a1 - a2}> => (aeval st a1) - (aeval st a2)
  | <{a1 * a2}> => (aeval st a1) * (aeval st a2)
  end.

Fixpoint beval (st : state) (b : bexp) : bool :=
  match b with
  | <{true}>      => true
  | <{false}>     => false
  | <{a1 = a2}>   => (aeval st a1) =? (aeval st a2)
  | <{a1 <> a2}>  => negb ((aeval st a1) =? (aeval st a2))
  | <{a1 <= a2}>  => (aeval st a1) <=? (aeval st a2)
  | <{a1 > a2}>   => negb ((aeval st a1) <=? (aeval st a2))
  | <{~ b1}>      => negb (beval st b1)
  | <{b1 && b2}>  => andb (beval st b1) (beval st b2)
  end.

Definition empty_st := (__ !-> 0).

Notation "x '!->' v" := (x !-> v ; empty_st)
  (at level 100, right associativity).

Example aexp_demo : aeval (X !-> 5) <{ 3 + (X * 2) }> = 13.
Proof. reflexivity. Qed.

Example bexp_demo : beval (X !-> 5) <{ true && ~(X <= 4) }> = true.
Proof. reflexivity. Qed.

(* ---------- 37.6 Locate 与脱糖三件套 ---------- *)

Unset Printing Notations.
Print fact_in_coq.
Print example_bexp.
Set Printing Notations.

Print example_bexp.
Set Printing Coercions.
Print example_bexp.
Print fact_in_coq.
Unset Printing Coercions.

Set Printing All.
Print example_bexp.
Unset Printing All.

Locate aexp.
Locate "+*".
Locate "&&".
Locate ";".
Locate "while".
Locate "true".

(* ---------- 37.7 assn 自定义条目：把同一套机制再造一遍 ---------- *)

Definition Assertion := state -> Prop.
Definition Aexp := state -> nat.

Definition assert_of_Prop (P : Prop) : Assertion := fun _ => P.
Definition Aexp_of_nat (n : nat) : Aexp := fun _ => n.
Definition Aexp_of_aexp (a : aexp) : Aexp := fun st => aeval st a.

Coercion assert_of_Prop : Sortclass >-> Assertion.
Coercion Aexp_of_nat : nat >-> Aexp.
Coercion Aexp_of_aexp : aexp >-> Aexp.

Arguments assert_of_Prop /.
Arguments Aexp_of_nat /.
Arguments Aexp_of_aexp /.

Declare Custom Entry assn.
Declare Scope assertion_scope.
Bind Scope assertion_scope with Assertion.
Bind Scope assertion_scope with Aexp.
Delimit Scope assertion_scope with assertion.

Notation "# f x .. y" := (fun st => (.. (f ((x:Aexp) st)) .. ((y:Aexp) st)))
                  (in custom assn at level 2,
                  f constr at level 0, x custom assn at level 1,
                  y custom assn at level 1) : assertion_scope.

Notation "P -> Q" := (fun st => (P:Assertion) st -> (Q:Assertion) st) (in custom assn at level 99, right associativity) : assertion_scope.
Notation "P <-> Q" := (fun st => (P:Assertion) st <-> (Q:Assertion) st) (in custom assn at level 95) : assertion_scope.
Notation "P \/ Q" := (fun st => (P:Assertion) st \/ (Q:Assertion) st) (in custom assn at level 85, right associativity) : assertion_scope.
Notation "P /\ Q" := (fun st => (P:Assertion) st /\ (Q:Assertion) st) (in custom assn at level 80, right associativity) : assertion_scope.
Notation "~ P" := (fun st => ~ ((P:Assertion) st)) (in custom assn at level 75, right associativity) : assertion_scope.
Notation "a = b" := (fun st => (a:Aexp) st = (b:Aexp) st) (in custom assn at level 70) : assertion_scope.
Notation "a <> b" := (fun st => (a:Aexp) st <> (b:Aexp) st) (in custom assn at level 70) : assertion_scope.
Notation "a <= b" := (fun st => (a:Aexp) st <= (b:Aexp) st) (in custom assn at level 70) : assertion_scope.
Notation "a < b" := (fun st => (a:Aexp) st < (b:Aexp) st) (in custom assn at level 70) : assertion_scope.
Notation "a >= b" := (fun st => (a:Aexp) st >= (b:Aexp) st) (in custom assn at level 70) : assertion_scope.
Notation "a > b" := (fun st => (a:Aexp) st > (b:Aexp) st) (in custom assn at level 70) : assertion_scope.
Notation "'True'" := (fun st => True) (in custom assn at level 0) : assertion_scope.
Notation "'False'" := (fun st => False) (in custom assn at level 0) : assertion_scope.

Notation "a + b" := (fun st => (a:Aexp) st + (b:Aexp) st) (in custom assn at level 50, left associativity) : assertion_scope.
Notation "a - b" := (fun st => (a:Aexp) st - (b:Aexp) st) (in custom assn at level 50, left associativity) : assertion_scope.
Notation "a * b" := (fun st => (a:Aexp) st * (b:Aexp) st) (in custom assn at level 40, left associativity) : assertion_scope.

Notation "( x )" := x (in custom assn at level 0, x at level 99) : assertion_scope.

Notation "$ f" := f (in custom assn at level 0, f constr at level 0) : assertion_scope.
Notation "x" := x (in custom assn at level 0, x constr at level 0) : assertion_scope.

Declare Scope hoare_spec_scope.
Open Scope hoare_spec_scope.

Notation "{{ e }}" := e (at level 2, e custom assn at level 99) : assertion_scope.
Open Scope assertion_scope.

Definition assertion1 : Assertion := {{ X = 3 }}.
Definition assertion2 : Assertion := {{ True }}.
Definition assertion3 : Assertion := {{ False }}.
Definition assertion4 : Assertion := {{ True \/ False }}.
Definition assertion5 : Assertion := {{ X <= Y }}.
Definition assertion6 : Assertion := {{ X = 3 \/ X <= Y }}.
Definition assertion7 : Assertion := {{ Z = (#max X Y) }}.
Definition assertion8 : Assertion := {{ Z * Z <= X
                                        /\  ~ (((#S Z) * (#S Z)) <= X) }}.
Definition assertion9 : Assertion := {{ #Nat.add X Y > #max Y X }}.
Definition assertion10 : Assertion := {{ $(fun st => forall w, st w = st w) }}.

Print assertion8.
Print assertion10.

Definition assert_implies (P Q : Assertion) : Prop :=
  forall st, P st -> Q st.

Notation "P ->> Q" := (assert_implies P Q)
                        (at level 80) : hoare_spec_scope.

Notation "P <<->> Q" := ((P ->> Q) /\ (Q ->> P))
                          (at level 80) : hoare_spec_scope.

Definition assertion_sub X (a : aexp) (P : Assertion) : Assertion :=
  fun (st : state) => P (X !-> (aeval st a); st).

Notation "P [ X |-> a ]" := (assertion_sub X a P)
                              (in custom assn at level 10, left associativity,
                               P custom assn, X global, a custom com)
                          : assertion_scope.

Example equivalent_assertion1 :
  {{ (X <= 5) [X |-> 3] }} <<->> {{ 3 <= 5 }}.
Proof.
  split; unfold assert_implies, assertion_sub; intros st H;
  simpl in *; apply H.
Qed.

Example equivalent_assertion2 :
  {{ (X <= 5) [X |-> X + 1] }} <<->> {{ (X + 1) <= 5 }}.
Proof.
  split; unfold assert_implies, assertion_sub; intros st H;
  simpl in *; apply H.
Qed.

(* ---------- 37.8 反例集：Fail 抓得住的四类错 ---------- *)

Fail Definition mix_type : aexp := <{ true }>.
Fail Definition mix_level : com := <{ X + 1 }>.
Fail Definition bad_subst : Assertion := {{ (X <= 5) [X |-> true] }}.

Close Scope com_scope.
Fail Definition scope_needed : aexp := <{ X + 1 }>.
Open Scope com_scope.

End Ex37Notation.
