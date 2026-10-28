(* 70 类型类机制 —— Class/Instance、`{...} 隐式推广、实例搜索与 hint 库、优先级与 defaulting、Monad、QuickChick 的类 *)

Set Warnings "-extraction-opaque-accessed,-extraction".
Set Warnings "-notation-overridden,-parsing".
(* 适配：导入 ssreflect 后 rewrite 被接管为 ssr 版，rocq 9.3 会对它
   报 rewrite-rw 弃用警告（建议改名 rw）；本章证明沿用原书的标准
   rewrite 用法，屏蔽该警告保持输出干净。 *)
Set Warnings "-rewrite-rw".

From Stdlib Require Import Bool.
From Stdlib Require Import Strings.String.
From Stdlib Require Import Arith.
From Stdlib Require Import Lia.
From Stdlib Require Import List. Import ListNotations.
From Stdlib Require Import Relations.Relation_Definitions.
Require Import ssreflect ssrbool.
Require Export ExtLib.Structures.Monads.

Module Ex70Typeclasses.

Local Open Scope string.

(* ---------- 70.1 Class 与 Instance：以 Show 为例 ---------- *)

Class Show A : Type :=
  {
    show : A -> string
  }.

#[export] Instance showBool : Show bool :=
  {
    show := fun b:bool => if b then "true" else "false"
  }.

Compute (show true).

Inductive primary := Red | Green | Blue.

#[export] Instance showPrimary : Show primary :=
  {
    show :=
      fun c:primary =>
        match c with
        | Red => "Red"
        | Green => "Green"
        | Blue => "Blue"
        end
  }.

Compute (show Green).

Fixpoint string_of_nat_aux (time n : nat) (acc : string) : string :=
  let d := match n mod 10 with
           | 0 => "0" | 1 => "1" | 2 => "2" | 3 => "3" | 4 => "4" | 5 => "5"
           | 6 => "6" | 7 => "7" | 8 => "8" | _ => "9"
           end in
  let acc' := d ++ acc in
  match time with
    | 0 => acc'
    | S time' =>
      match n / 10 with
        | 0 => acc'
        | n' => string_of_nat_aux time' n' acc'
      end
  end.

Definition string_of_nat (n : nat) : string :=
  string_of_nat_aux n n "".

#[export] Instance showNat : Show nat :=
  {
    show := string_of_nat
  }.

Compute (show 42).

(* 练习 showNatBool：为「nat 与 bool 的序对」写 Show 实例 *)
#[export] Instance showNatBool : Show (nat * bool) :=
  {
    show p :=
      let (n, b) := p in
        "(" ++ show n ++ ", " ++ show b ++ ")"
  }.

Compute (show (42, true)).

(* ---------- 70.2 类约束 `{Show A}：泛型函数 ---------- *)

Definition showOne {A : Type} `{Show A} (a : A) : string :=
  "The value is " ++ show a.

Compute (showOne true).
Compute (showOne 42).

Definition showTwo {A B : Type}
           `{Show A} `{Show B} (a : A) (b : B) : string :=
  "First is " ++ show a ++ " and second is " ++ show b.

Compute (showTwo true 42).
Compute (showTwo Red Green).

(* 练习 missingConstraint：把 showOne 的 `{Show A} 约束删掉会怎样？
   答：定义当场报错——没有了约束，上下文里就没有 A 的 show 证据，
   实例搜索对抽象类型变量 A 无能为力： *)
Fail Definition showOneBroken {A : Type} (a : A) : string :=
  "The value is " ++ show a.
(* 实测报错（rocq 9.3）：
     Error:
     The following term contains unresolved implicit arguments:
       (fun (A : Type) (a : A) => "The value is " ++ show a)
     More precisely:
     - ?Show: Cannot infer the implicit parameter Show of show whose
       type is "Show A" (no type class instance found) in environment:
       A : Type
       a : A *)

(* ---------- 70.3 Eq：可判定相等的类 ---------- *)

Class Eq A :=
  {
    eqb: A -> A -> bool;
  }.

Notation "x =? y" := (eqb x y) (at level 70).

#[export] Instance eqBool : Eq bool :=
  {
    eqb := fun (b c : bool) =>
       match b, c with
         | true, true => true
         | true, false => false
         | false, true => false
         | false, false => true
       end
  }.

#[export] Instance eqNat : Eq nat :=
  {
    eqb := Nat.eqb
  }.

(* 练习 boolArrowBool：bool->bool 上只有两个输入，穷尽即可判定相等 *)
#[export] Instance eqBoolBool : Eq (bool -> bool) :=
  {
    eqb f g :=
      andb (f true =? g true) (f false =? g false)
  }.

Compute ((fun b : bool => b) =? (fun b : bool => b)).
Compute ((fun b : bool => b) =? negb).

(* ---------- 70.4 参数化实例：以旧实例造新实例 ---------- *)

#[export] Instance showPair {A B : Type} `{Show A} `{Show B} : Show (A * B) :=
  {
    show p :=
      let (a,b) := p in
        "(" ++ show a ++ "," ++  show b ++ ")"
  }.

Compute (show (true,42)).

#[export] Instance eqPair {A B : Type} `{Eq A} `{Eq B} : Eq (A * B) :=
  {
    eqb p1 p2 :=
      let (p1a,p1b) := p1 in
      let (p2a,p2b) := p2 in
      andb (p1a =? p2a) (p1b =? p2b)
  }.

Fixpoint showListAux {A : Type} (s : A -> string) (l : list A) : string :=
  match l with
    | nil => ""
    | cons h nil => s h
    | cons h t => append (append (s h) ", ") (showListAux s t)
  end.

#[export] Instance showList {A : Type} `{Show A} : Show (list A) :=
  {
    show l := append "[" (append (showListAux show l) "]")
  }.

Compute (show [1; 2; 3]).

(* 练习 eqEx：list 的 Eq 实例、option 的 Show 与 Eq 实例 *)
Fixpoint eqListAux {A : Type} (eq : A -> A -> bool) (l1 l2 : list A) : bool :=
  match l1, l2 with
  | [], [] => true
  | h1 :: t1, h2 :: t2 => andb (eq h1 h2) (eqListAux eq t1 t2)
  | _, _ => false
  end.

#[export] Instance eqList {A : Type} `{Eq A} : Eq (list A) :=
  {
    eqb := eqListAux eqb
  }.

#[export] Instance showOpt {A : Type} `{Show A} : Show (option A) :=
  {
    show o :=
      match o with
      | Some x => "Some " ++ show x
      | None => "None"
      end
  }.

#[export] Instance eqOpt {A : Type} `{Eq A} : Eq (option A) :=
  {
    eqb o1 o2 :=
      match o1, o2 with
      | Some x, Some y => x =? y
      | None, None => true
      | _, _ => false
      end
  }.

Compute (show (Some (true, 42))).
Compute ([1; 2] =? [1; 2]).
Compute (Some 1 =? None).

(* 练习 boolArrowA：推广为 bool->A（A 自带 Eq），并对 bool->bool->nat 验证 *)
#[export] Instance eqBoolArrow {A : Type} `{Eq A} : Eq (bool -> A) :=
  {
    eqb f g :=
      andb (f true =? g true) (f false =? g false)
  }.

Definition f00 : bool -> bool -> nat := fun _ _ => 0.
Definition f01 : bool -> bool -> nat := fun _ b => if b then 1 else 0.

Compute (f00 =? f00).
Compute (f00 =? f01).

(* ---------- 70.5 类层次：Ord 以 Eq 为「超类」 ---------- *)

Class OrdBad A :=
  {
    eqbad : A -> A -> bool;
    lebad : A -> A -> bool
  }.

Definition lt {A: Type} `{Eq A} `{OrdBad A} (x y : A) : bool :=
  andb (lebad x y) (negb (eqbad x y)).

Class Ord A `{Eq A} : Type :=
  {
    le : A -> A -> bool
  }.

Notation "x <=? y" := (le x y) (at level 70).

Check Ord.
(* ==> Ord : forall A : Type, Eq A -> Type *)

#[export] Instance natOrd : Ord nat :=
  {
    le := Nat.leb
  }.

Definition max {A: Type} `{Eq A} `{Ord A} (x y : A) : A :=
  if le x y then y else x.

Compute (max 3 7).

(* 练习 missingConstraintAgain：max 删掉 `{Ord A} 会报错（le 没有证据）；
   删掉 `{Eq A} 却仍能编译——隐式推广会把 Ord 的超类参数 H : Eq A
   一并自动补绑出来，见 70.6 节 max1 的 Print 输出。 *)

(* 练习 ordMisc：option 与 pair 的 Ord 实例 *)
#[export] Instance ordOpt {A : Type} `{Ord A} : Ord (option A) :=
  {
    le o1 o2 :=
      match o1, o2 with
      | None, _ => true
      | Some _, None => false
      | Some x, Some y => le x y
      end
  }.

#[export] Instance ordPair {A B : Type} `{Ord A} `{Ord B} : Ord (A * B) :=
  {
    le p1 p2 :=
      let (a1, b1) := p1 in
      let (a2, b2) := p2 in
      if a1 =? a2 then le b1 b2 else le a1 a2
  }.

Compute (le (Some 3) None).
Compute (le (1, 2) (1, 3)).

(* 练习 ordList：list 的字典序 Ord 实例 *)
Fixpoint leList {A : Type} `{Ord A} (l1 l2 : list A) : bool :=
  match l1, l2 with
  | [], _ => true
  | _ :: _, [] => false
  | h1 :: t1, h2 :: t2 => if h1 =? h2 then leList t1 t2 else le h1 h2
  end.

#[export] Instance ordList {A : Type} `{Ord A} : Ord (list A) :=
  {
    le := leList
  }.

Compute (le [1; 2] [1; 3]).
Compute (le [1; 2] [1]).

(* ---------- 70.6 隐式推广：`{...} 到底展开成什么 ---------- *)

Generalizable Variables A.

Definition showOne1 `{Show A} (a : A) : string :=
  "The value is " ++ show a.

Print showOne1.
(* ==>（rocq 9.3 实测；隐式参数直接印在类型的花括号里）
    showOne1 =
    fun (A : Type) (H : Show A) (a : A) => "The value is " ++ show a
         : forall {A : Type}, Show A -> A -> string

    Arguments showOne1 {A}%_type_scope {H} a
*)

Definition showOne2 `{_ : Show A} (a : A) : string :=
  "The value is " ++ show a.

Definition showOne3 `{H : Show A} (a : A) : string :=
  "The value is " ++ show a.

Definition showOne4 `{Show} a : string :=
  "The value is " ++ show a.

Set Printing Implicit.
Print showOne.
Print showOne1.
Print showOne2.
Print showOne3.
Print showOne4.
(* ==> 五个定义的打印完全相同（rocq 9.3 实测）：
    showOne =
    fun (A : Type) (H : Show A) (a : A) => "The value is " ++ @show A H a
         : forall {A : Type}, Show A -> A -> string

    Arguments showOne {A}%_type_scope {H} a
*)
Unset Printing Implicit.

Definition max1 `{Ord A} (x y : A) :=
  if le x y then y else x.

Set Printing Implicit.
Print max1.
(* ==>（rocq 9.3 实测）注意第二个参数 H : Eq A 也是隐式推广
       自动补出来的：
     max1 =
     fun (A : Type) (H : Eq A) (H0 : @Ord A H) (x y : A) =>
     if x <=? y then y else x
          : forall {A : Type} {H : Eq A}, @Ord A H -> A -> A -> A

     Arguments max1 {A}%_type_scope {H H0} x y
*)

Check Ord.
(* ==> Ord : forall A : Type, Eq A -> Type *)

Unset Printing Implicit.

Generalizable Variables x y.

Lemma commutativity_property : `{x + y = y + x}.
Proof. intros. lia. Qed.

Check commutativity_property.
(* ==>（rocq 9.3 实测）未绑定的 x、y 显示为待推广的 evar：
     commutativity_property
          : ?x + ?y = ?y + ?x
     where
     ?x : [ |- nat]
     ?y : [ |- nat]
*)

Definition implicit_fun := `{x + y}.

Print implicit_fun.

(* 推广的参数是隐式且 maximally inserted 的，直接应用会报错： *)
(* Compute (implicit_fun 2 3). *)
(* ==>
    Error: Illegal application (Non-functional construction):
    The expression "implicit_fun" of type "nat"
    cannot be applied to the term
     "2" : "nat"
*)
Compute (@implicit_fun 2 3).

Definition implicit_fun1 := `(x + y).
Print implicit_fun1.
Compute (implicit_fun1 2 3).

(* ---------- 70.7 记录即积：Record 语法糖 ---------- *)

Record Point :=
  Build_Point
    {
      px : nat;
      py : nat
    }.

Check (Build_Point 2 4).

Check {| px := 2; py := 4 |}.
Check {| py := 4; px := 2 |}.

Definition r : Point := {| px := 2; py := 4 |}.

Compute (r.(px) + r.(py)).

Record LabeledPoint (A : Type) :=
  Build_LabeledPoint
    {
      lx    : nat;
      ly    : nat;
      label : A
    }.

Check {| lx:=2; ly:=4; label:="hello" |}.
(* ==>
     {| lx := 2; ly := 4; label := "hello" |}
        : LabeledPoint string
*)

(* 练习 rcdParens：LabeledPoint 的参数 A 用圆括号（显式）而非花括号
   （隐式）绑定，为何更好？答：理论上 A 总能由 label 字段的值推出，
   隐式也能工作；但显式参数让「这个记录的元件类型是什么」成为语法
   上必须交代的事实——构造点、投影点、错误信息里都更可控。类型类
   场合则相反：实例参数正是为了「不写」而存在的，所以类约束一律
   用 `{...} 隐式推广。 *)

(* ---------- 70.8 类型类即记录：脱下语法糖 ---------- *)

Set Printing All.
Print Show.
(* ==>（rocq 9.3 实测）类就是一个单构造子记录：
    Record Show (A : Type) : Type := Build_Show { show : forall _ : A, string }.

    Arguments Show A%_type_scope
    Arguments Build_Show A%_type_scope show%_function_scope
    Arguments show {A}%_type_scope {Show} _
*)
Unset Printing All.

Print showNat.
(* ==>
    showNat = {| show := string_of_nat |}
       : Show nat
*)

Set Printing All.
Print show.
(* ==>（rocq 9.3 实测）投影就是对记录做一次 match：
    show =
    fun (A : Type) (Show : Show A) =>
    match Show return (forall _ : A, string) with
    | Build_Show _ show => show
    end
         : forall {A : Type} {_ : Show A} (_ : A), string

    show is a projection of Show
    Arguments show {A}%_type_scope {Show} _
*)
Unset Printing All.

(* ---------- 70.9 实例推断：show 42 背后发生了什么 ---------- *)

Definition eg42 := show 42.

Set Printing Implicit.
Print eg42.
Unset Printing Implicit.

(* 练习 HintDb：看看 typeclass_instances 这个 hint 库里有什么 *)
Print HintDb typeclass_instances.
(* 输出很长（本章导入了 ExtLib，库里还有 Monad 等类的实例）。
   搜 "For Show" 一节可以看到 showNat、showPair 等条目——
   每个 #[export] Instance 都往这个库里注册了一条 hint。 *)

Set Typeclasses Debug.
Check (show 42).
(* ==>（rocq 9.3 实测，省略 Calling ... flags 一行）
     Debug: 1: looking for (Show nat) without backtracking
     Debug: 1.1: exact showNat on (Show nat), 0 subgoal(s)
*)

Check (show (true,42)).
(* ==>（rocq 9.3 实测）递归组装：先试 showPair，再分别解决两个子目标
     Debug: 1: looking for (Show (bool * nat)) without backtracking
     Debug: 1.1: simple apply showPair on (Show (bool * nat)), 2 subgoal(s)
     Debug: 1.1-1 : (Show bool)
     Debug: 1.1-1: looking for (Show bool) without backtracking
     Debug: 1.1-1.1: exact showBool on (Show bool), 0 subgoal(s)
     Debug: 1.1-2 : (Show nat)
     Debug: 1.1-2: looking for (Show nat) without backtracking
     Debug: 1.1-2.1: exact showNat on (Show nat), 0 subgoal(s)      *)

Unset Typeclasses Debug.

(* 完整链条：
    show 42
       ===>   { 隐式参数 }
    @show _ _ 42
       ===>   { 类型检查 }
    @show (?A : Type) (?Show0 : Show ?A) 42
       ===>   { 统一 }
    @show nat (?Show0 : Show nat) 42
       ===>   { 对 Show nat 做证明搜索，命中 showNat }
    @show nat showNat 42
*)

(* ---------- 70.10 带证明成员的类：EqDec ---------- *)

Class EqDec (A : Type) {H : Eq A} :=
  {
    eqb_eq : forall x y, x =? y = true <-> x = y
  }.

#[export] Instance eqdecNat : EqDec nat :=
  {
    eqb_eq := Nat.eqb_eq
  }.

#[export] Instance eqdecBool' : EqDec bool.
Proof.
  constructor.
  intros x y. destruct x; destruct y; simpl; unfold iff; auto.
Defined.

Lemma eqb_fact `{EqDec A} : forall (x y z : A),
  x =? y = true -> y =? z = true -> x = z.
Proof.
  intros x y z Exy Eyz.
  rewrite eqb_eq in Exy.
  rewrite eqb_eq in Eyz.
  subst. reflexivity. Qed.

(* ---------- 70.11 子结构：类成员是另一个类 ---------- *)

Class Reflexive (A : Type) (R : relation A) :=
  {
    reflexivity : forall x, R x x
  }.

Class Transitive (A : Type) (R : relation A) :=
  {
    transitivity : forall x y z, R x y -> R y z -> R x z
  }.

Generalizable Variables z w R.

Lemma trans3 : forall `{Transitive A R},
    `{R x y -> R y z -> R z w -> R x w}.
Proof.
  intros.
  apply (transitivity x z w). apply (transitivity x y z).
  assumption. assumption. assumption. Defined.

Class PreOrder (A : Type) (R : relation A) :=
  { PreOrder_Reflexive :: Reflexive A R ;
    PreOrder_Transitive :: Transitive A R }.

Lemma trans3_pre : forall `{PreOrder A R},
    `{R x y -> R y z -> R z w -> R x w}.
Proof. intros. eapply trans3; eassumption. Defined.

(* ---------- 70.12 Dec：可判定命题的类（ssreflect 风格） ---------- *)

Print decidable.
(* ==>
     decidable = fun P : Prop => {P} + {~ P}
          : Prop -> Set
*)

Class Dec (P : Prop) : Type :=
  {
    dec : decidable P
  }.

(* 适配说明：ssreflect 会全局开启 Set Implicit Arguments，把投影 dec
   的 Prop 参数也变成隐式，导致 dec (P a) 这类显式应用失败；
   下面这行恢复「P 显式、类实例参数隐式」的格局（QuickChick 同款）。 *)
Arguments dec _ {_}.

#[export] Instance EqDec__Dec {A} `{H : EqDec A} (x y : A) : Dec (x = y).
Proof.
  constructor.
  unfold decidable.
  destruct (x =? y) eqn:E.
  - left. rewrite <- eqb_eq. assumption.
  - right. intros C. rewrite <- eqb_eq in C. rewrite E in C. inversion C.
Defined.

#[export] Instance Dec_conj {P Q} {H : Dec P} {I : Dec Q} : Dec (P /\ Q).
Proof.
  constructor. unfold decidable.
  destruct H as [D]; destruct D;
    destruct I as [D]; destruct D; auto;
      right; intro; destruct H; contradiction.
Defined.

(* 练习 dec_neg_disj：~P 与 P\/Q 的 Dec 实例
   （解答与 QuickChick 2.2.0 源码 src/Decidability.v 中的
   Dec_neg / Dec_disj 逐字相同） *)
#[export] Instance Dec_neg {P} {H : Dec P} : Dec (~ P).
Proof.
  constructor. unfold decidable.
  destruct H as [D]; destruct D; auto.
Defined.

#[export] Instance Dec_disj {P Q} {H : Dec P} {I : Dec Q} : Dec (P \/ Q).
Proof.
  constructor. unfold decidable.
  destruct H as [D]; destruct D;
    destruct I as [D]; destruct D; auto;
      right; intro; destruct H; contradiction.
Defined.

(* 练习 Dec_All：All P l 的 Dec 实例（P 逐点可判定） *)
Fixpoint All {T : Type} (P : T -> Prop) (l : list T) : Prop :=
  match l with
  | [] => True
  | x :: l' => P x /\ All P l'
  end.

#[export] Instance Dec_All {T : Type} (P : T -> Prop)
         {H : forall a : T, Dec (P a)} (l : list T) : Dec (All P l).
Proof.
  constructor. unfold decidable.
  induction l as [| x l' IH]; simpl.
  - left. exact I.
  - destruct (H x) as [D]. destruct D as [Px | nPx].
    + destruct IH as [AllP | nAllP].
      * left. split; assumption.
      * right. intros [_ C]. contradiction.
    + right. intros [C _]. contradiction.
Defined.

Notation "P '?'" :=
  (match (@dec P _) with
   | left _ => true
   | right _ => false
   end)
  (at level 100).

Definition silly_fun1 (x y z : nat) :=
  if andb (x =? y) (andb (y =? z) (x =? z))
  then "all equal"
  else "not all equal".

Definition silly_fun2 (x y z : nat) :=
  if (x = y /\ y = z /\ x = z)?
  then "all equal"
  else "not all equal".

Compute (silly_fun2 1 1 1).

(* ---------- 70.13 Monad：ext-lib 的 Monad 类与 ret/bind 记号 ---------- *)

Export MonadNotation.
Open Scope monad_scope.

(* ext-lib 的主定义（ExtLib.Structures.Monad，打印时带 Polymorphic
   的宇宙多态细节，此处按原书写出简化版）：
    Class Monad (M : Type -> Type) : Type :=
       {
         ret : forall {T : Type}, T -> M T ;
         bind : forall {T U : Type}, M T -> (T -> M U) -> M U
       }.
*)

#[export] Instance optionMonad : Monad option :=
  {
    ret T x :=
      Some x ;
    bind T U m f :=
      match m with
        None => None
      | Some x => f x
      end
  }.

Fixpoint nth_opt {A : Type} (n : nat) (l : list A) : option A :=
  match l with
    [] => None
  | h::t => if n =? 0 then Some h else nth_opt (n-1) t
  end.

Definition sum3 (l : list nat) : option nat :=
  x0 <- nth_opt 0 l ;;
  x1 <- nth_opt 1 l ;;
  x2 <- nth_opt 2 l ;;
  ret (x0 + x1 + x2).

Compute (sum3 [1; 2; 3; 4]).
Compute (sum3 [1; 2]).

Definition liftM
            {m : Type -> Type}
            {M : Monad m}
            {T U : Type} (f : T -> U)
          : m T -> m U :=
  fun x => bind x (fun x => ret (f x)).

Definition liftM2
            {m : Type -> Type}
            {M : Monad m}
            {T U V : Type} (f : T -> U -> V)
          : m T -> m U -> m V :=
    fun x y => bind x (fun x => liftM (f x) y).

Definition liftM3
            {m : Type -> Type}
            {M : Monad m}
            {T U V W : Type} (f : T -> U -> V -> W)
          : m T -> m U -> m V -> m W :=
    fun x y z => bind x (fun x => liftM2 (f x) y z).

Definition sum3opt (n1 n2 : option nat) :=
  x1 <- n1 ;;
  x2 <- n2 ;;
  ret (x1 + x2).

Definition sum3opt' (n1 n2 : option nat) :=
  liftM2 plus n1 n2.

Compute (sum3opt' (Some 1) (Some 2)).

(* ---------- 70.14 defaulting：解析到非预期实例的陷阱 ---------- *)

Check @eqb.
(* ==>
     @eqb : forall A : Type, Eq A -> A -> A -> bool    *)

Definition foo x := if x =? x then "Of course" else "Impossible".

About foo.
(* ==> 定义当场就被钉死了：
     foo : (bool -> bool) -> string *)

Fail Check (foo true).
(* ==>（rocq 9.3 实测；与原书记载一致）
     Error:
     The term "true" has type "bool" while it is expected to have type
      "bool -> bool". *)

(* 练习 debugDefaulting：Set Typeclasses Debug 后重放
   Definition foo，可以看到搜索 Eq ?A 时第一个命中的是
   eqBoolBool : Eq (bool->bool)——定义 foo 时 x 的类型是待定的
   evar ?A，实例搜索不管 ?A 还没定下来，直接拿库里第一个能统一
   的实例把 ?A 钉成 bool->bool，foo 的类型于是成了
   (bool->bool) -> string。教训：喂给实例搜索的问题的「形状」
   至关重要——泛型函数里用重载操作符时，务必先用 `{Eq A} 等约束
   或显式类型标注把类型变量绑住。 *)

(* ---------- 70.15 操控 hint 库：重叠实例与优先级 ---------- *)

Inductive baz := Baz : nat -> baz.

#[export] Instance baz1 : Show baz :=
  {
    show b :=
      match b with
        Baz n => "Baz: " ++ show n
      end
  }.

#[export] Instance baz2 : Show baz :=
  {
    show b :=
      match b with
        Baz n => "[" ++ show n ++ " is a Baz]"
      end
  }.

Compute (show (Baz 42)).
(* ==> 重叠实例命中哪个不可预料，此处恰好是后注册的先被试中
     = "[42 is a Baz]"
     : string   *)

#[export] Remove Hints baz1 baz2 : typeclass_instances.

#[export] Existing Instance baz1.
Compute (show (Baz 42)).
(* ==>
     = "Baz: 42"
     : string    *)

#[export] Remove Hints baz1 : typeclass_instances.

#[export] Instance baz3 : Show baz | 2 :=
  {
    show b :=
      match b with
        Baz n => "Use me first!  " ++ show n
      end
  }.

#[export] Instance baz4 : Show baz | 3 :=
  {
    show b :=
      match b with
        Baz n => "Use me second!  " ++ show n
      end
  }.

Compute (show (Baz 42)).
(* ==> 优先级数字小者先试用（0 最高）；不写优先级时默认为
       实例的绑定子个数（越特化的实例绑定子越少、越优先）
     = "Use me first!  42"
     : string  *)

#[export] Existing Instance baz1 | 0.
Compute (show (Baz 42)).
(* ==>
     = "Baz: 42"
     : string    *)

(* ---------- 70.16 调试：实例解析失败与发散 ---------- *)

Inductive bar :=
  Bar : nat -> bar.

Fail Definition eqBar :=
  (Bar 42) =? (Bar 43).
(* ==> 没有 Eq bar 实例，报错直指缺口（rocq 9.3 实测）：
    Error:
    The following term contains unresolved implicit arguments:
      (Bar 42 =? Bar 43)
    More precisely:
    - ?Eq: Cannot infer the implicit parameter Eq of eqb whose type is
      "Eq bar" (no type class instance found). *)

Fail Definition ordBarList :=
  le [Bar 42] [Bar 43].
(* ==> 参数化实例尚未注册到 bar，搜索停在 list bar 一层（实测）：
    Error:
    The following term contains unresolved implicit arguments:
      ([Bar 42] <=? [Bar 43])
    More precisely:
    - ?H: Cannot infer the implicit parameter H of le whose type is
      "Eq (list bar)" (no type class instance found).
    - ?Ord: Cannot infer the implicit parameter Ord of le whose type is
      "Ord (list bar)" (no type class instance found). *)

Fail Definition max {A: Type} {Ord A} (x y : A) : A :=
  if le x y then y else x.
(* ==> 忘写反引号：`{Ord A} 变成 {Ord A}——Ord 被当成一个普通的
       隐式绑定子名字（与 A 共享一个待推断的类型 ?T），Rocq 在
       绑定子类型推断处就报错了（rocq 9.3 实测）：
    Error:
    The following term contains unresolved implicit arguments:
      (forall A : Type, ?T -> forall A0 : Type, A0 -> A0 -> A0)
    More precisely:
    - ?T: Cannot infer the type of Ord in environment:
      A : Type
    原书旧版此处报的是三个 UNDEFINED EVARS（?T/?H/?Ord 连环），
    病因相同：少了反引号，类约束根本没有生效。 *)

Class MyMap (A B : Type) : Type :=
  {
    mymap : A -> B
  }.

#[export] Instance MyMap1 : MyMap bool nat :=
  {
    mymap b := if b then 0 else 42
  }.

#[export] Instance MyMap2 : MyMap nat string :=
  {
    mymap := fun n : nat =>
      if le n 20 then "Pretty small" else "Pretty big"
  }.

Definition e1 := mymap true.
Compute e1.

Definition e2 := mymap 42.
Compute e2.

Fail Definition e3 : string := mymap false.
(* ==> 两个实例不会自动「接力」：没有从 bool 直达 string 的实例（实测）
    Error:
    The following term contains unresolved implicit arguments:
      (mymap false)
    More precisely:
    - ?MyMap: Cannot infer the implicit parameter MyMap of mymap whose
      type is "MyMap bool string" (no type class instance found). *)

#[export] Instance MyMap_trans {A B C : Type} `{MyMap A B} `{MyMap B C} : MyMap A C :=
  { mymap a := mymap (mymap a) }.

Definition e3 : string := mymap false.
Compute e3.

(* 练习 nonterm：为什么下面这行一旦放开就会发散？
   Definition e4 : list nat := mymap false.
   答：搜索 MyMap bool (list nat) 时先试 MyMap_trans，产生两个
   子目标 MyMap bool ?B 与 MyMap ?B (list nat)；其中 ?B 是自由
   evar，第二个子目标又可以再次匹配 MyMap_trans（?B 与任何头
   都能统一），于是搜索在 transitivtiy 式实例上无限递归——
   「传递」「对称」类实例是发散的头号嫌疑犯，必须限制或移除。
   保留注释，勿放开。 *)
(*
Definition e4 : list nat := mymap false.
*)

(* ---------- 70.17 实战中的类型类：QuickChick 的四件套 ---------- *)

(* 69 章用过的 QuickChick，其整个接口就建在本章机制之上。
   以下类定义逐字摘自 QuickChick 2.2.0 源码（本机未安装该库，
   仅作阅读；71 章起会在生成器里逐个用到）——

   src/Classes.v（生成与收缩的类层次）：
     Class GenSized (A : Type) :=
       { arbitrarySized : nat -> G A }.
     Class Gen (A : Type) := { arbitrary : G A }.
     Class Shrink (A : Type) :=
       { shrink : A -> list A }.
     Class Arbitrary (A : Type) `{Gen A} `{Shrink A}.
   注意 Arbitrary 的写法正是 70.5 节的「超类参数」模式：
   声明 Arbitrary A 实例前必须先有 Gen A 与 Shrink A。

   src/Show.v（与本章 70.1 节的教学版逐字相同）：
     Class Show (A : Type) : Type :=
     {
       show : A -> string
     }.

   src/Decidability.v（与 70.12 节的 Dec 逐字相同）：
     Class Dec (P : Prop) : Type := { dec : decidable P }.
     Class Dec_Eq (A : Type) :=
       {
         dec_eq : forall (x y : A), decidable (x = y)
       }.
   Dec_Eq 就是本章 EqDec 的「记录证据」版：不包装布尔检查器，
   直接给「任意 x y 可判定」的证据。QuickChick 还为常见类型
   备好了 Dec_eq_bool、Dec_eq_nat 等实例。

   src/Generators.v 里 G 单子注册为 ext-lib 的 Monad 实例：
     #[global] Instance MonadGen : Monad G := ...
   71 章写生成器时的 x <- g1 ;; g2 记号就来自这里。

   也正因为 QuickChick 自带同名的 Show / Dec 等类，本章示例
   全程不导入 QuickChick——两套同名类同处一个文件会撞车
   （类的常量名、showBool/showNat 等实例名都相同）。自本章
   起教程的取舍：本章自建类讲清机制，69、71–76 章统一使用
   QuickChick 库里的类。 *)

End Ex70Typeclasses.
