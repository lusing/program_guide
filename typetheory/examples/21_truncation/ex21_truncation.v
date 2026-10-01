(* ============================================================ *)
(* 21 截断层级 —— 自包含 mini-HoTT（三）                          *)
(* Contr(-2) / IsHProp(-1) / IsHSet(0)；公理：funext 一条        *)
(* ============================================================ *)

Unset Automatic Proposition Inductives.

Inductive paths {A : Type} (a : A) : A -> Type := idpath : paths a a.
Arguments paths {A} a b. Arguments idpath {A a}.
Notation "x == y" := (paths x y) (at level 70).

Definition concat {A : Type} {x y z : A} (p : x == y) (q : y == z)
  : x == z :=
  match p in paths _ y' return forall (q0 : y' == z), x == z with
  | idpath => fun q0 => q0
  end q.
Notation "p · q" := (concat p q) (at level 60, right associativity).

(* ---- 层级定义 ---- *)

(* -2：可缩——有中心，且一切点等于中心 *)
Record Contr (A : Type) : Type :=
  MkContr { center : A ; contraction : forall a, a == center }.

(* -1：命题——任两点相等 *)
Record IsHProp (A : Type) : Type :=
  MkHProp { hprop_all : forall a b : A, a == b }.

(* 0：集合——任两条路径相等 *)
Record IsHSet (A : Type) : Type :=
  MkHSet { hset_paths : forall (a b : A) (p q : a == b), p == q }.

(* ---- 单点域可缩（J 直推；HoTT 书 3.11.3 的雏形） ---- *)

Definition singleton_contr {A : Type} (a : A)
  : Contr { x : A & x == a }.
Proof.
  refine (@MkContr _ (existT _ a idpath) _).
  intros [x p]. destruct p. simpl. exact idpath.
Defined.

(* ---- 空类型与单点：两个极端的层级 ---- *)

Inductive empty : Set := .

Definition empty_any (X : Type) (e : empty) : X := match e with end.

Definition empty_hprop : IsHProp empty :=
  @MkHProp _ (fun a b => empty_any (a == b) a).

Inductive unit2 : Type := tt2.

Definition unit_contr : Contr unit2 :=
  @MkContr _ tt2 (fun u => match u with tt2 => idpath end).

(* ---- Bool：构造子互斥的 noconf 示范（0 层味的直击） ---- *)

Inductive bool2 : Type := true2 | false2.

(* true2 == false2 蕴含空：motive 在端点上分流——
   idpath 只能落在 true2 侧（分到 unit2），拿到 false2 侧就赢了 *)
Definition tf_empty (p : true2 == false2) : empty :=
  match p in paths _ b return (match b with true2 => unit2 | false2 => empty end) with
  | idpath => tt2
  end.

(* 注：完整证明 IsHSet bool2（一切 p q : a==b 有 2-路径）在
   自造 paths 上要动用 noconf 全家桶；Coq 自家 eq 的对应事实
   （UIP_refl / K）可证——因为 eq 住在 Prop、被「压平」了。
   这正是 HoTT 要把相等搬到 Type 层重造的原因之一。 *)

(* ---- 公理：funext（本文件唯一一条，账目如下） ---- *)
Axiom funext : forall (A : Type) (P : A -> Type) (f g : forall x, P x),
  (forall x, f x == g x) -> f == g.

(* ---- 命题对 Π 封闭（逻辑性的机器面） ---- *)
(* 每点都是命题，则函数类型整体是命题——funext 一发入魂 *)

Definition pi_hprop (A : Type) (P : A -> Type)
  (H : forall x, IsHProp (P x)) : IsHProp (forall x, P x).
Proof.
  refine (@MkHProp _ _). intros f g.
  apply funext. intro x. exact (hprop_all (P x) (H x) (f x) (g x)).
Defined.

(* ---- 与 Coq 自家 Prop 的关系 ---- *)
(* Coq 的 Prop 就是 -1 层：proof_irrelevance 是它的「层级公理」 *)
Require Import Coq.Logic.ProofIrrelevance.
Check proof_irrelevance :
  forall (P : Prop) (p q : P), p = q.

(* 记账 *)
Print Assumptions tf_empty.        (* Closed：零公理 *)
Print Assumptions singleton_contr. (* Closed：零公理 *)
Print Assumptions pi_hprop.        (* depends on funext *)
