(* ============================================================ *)
(* 19 恒等类型的同伦解读 —— 自包含 mini-HoTT（一）                *)
(* 不用 Coq 的 eq，自造 paths；本文件【零公理】，                *)
(* Print Assumptions 见证。                                       *)
(* ============================================================ *)

Unset Automatic Proposition Inductives.

(* paths 必须住在 Type：它的元素要有【高维结构】（19-23 章的主题） *)
Inductive paths {A : Type} (a : A) : A -> Type :=
| idpath : paths a a.

Arguments paths {A} a b.
Arguments idpath {A a}.

Notation "x == y" := (paths x y) (at level 70).

(* ---- 四个基本算子：组合、逆转、同伦映射、搬运 ---- *)

Definition concat {A : Type} {x y z : A} (p : x == y) (q : y == z)
  : x == z :=
  match p in paths _ y' return forall (q0 : y' == z), x == z with
  | idpath => fun q0 => q0
  end q.

Notation "p · q" := (concat p q) (at level 60, right associativity).

Definition inverse {A : Type} {x y : A} (p : x == y) : y == x :=
  match p in paths _ y' return y' == x with
  | idpath => idpath
  end.

Notation "! p" := (inverse p) (at level 65).

Definition ap {A B : Type} (f : A -> B) {x y : A} (p : x == y)
  : f x == f y :=
  match p in paths _ y' return f x == f y' with
  | idpath => idpath
  end.

Definition transport {A : Type} (P : A -> Type) {x y : A} (p : x == y)
  (u : P x) : P y :=
  match p in paths _ y' return P y' with
  | idpath => u
  end.

(* ---- 群律：全部由「对 idpath 匹配」（= J）一步推得 ---- *)

Definition concat_p1 {A : Type} {x y : A} (p : x == y)
  : p · idpath == p :=
  match p as p0 in paths _ y' return (p0 · (@idpath A y')) == p0 with
  | idpath => idpath
  end.

Definition concat_pV {A : Type} {x y : A} (p : x == y)
  : (p · ! p) == idpath :=
  match p as p0 in paths _ y' return (p0 · ! p0) == (@idpath A x) with
  | idpath => idpath
  end.

Definition concat_Vp {A : Type} {x y : A} (p : x == y)
  : ((! p) · p) == idpath :=
  match p as p0 in paths _ y' return ((! p0) · p0) == (@idpath A y') with
  | idpath => idpath
  end.

Definition inverse_pp {A : Type} {x y : A} (p : x == y)
  : ! (! p) == p :=
  match p as p0 in paths _ y' return ! (! p0) == p0 with
  | idpath => idpath
  end.

(* ---- ap 的函子律 ---- *)

(* ap f idpath 定义性地就是 idpath（J 只在 idpath 上计算）——
   无需引理，eq_refl 即见证（此处留注不立定理） *)

Definition ap_pp {A B : Type} (f : A -> B) {x y z : A}
  (p : x == y) (q : y == z)
  : ap f (p · q) == (ap f p · ap f q) :=
  match p as p0 in paths _ y' return forall (q0 : y' == z),
    (ap f (p0 · q0)) == ((ap f p0) · (ap f q0)) with
  | idpath => fun q0 => idpath
  end q.

Definition ap_compose {A B C : Type} (g : B -> C) (f : A -> B)
  {x y : A} (p : x == y)
  : ap (fun a => g (f a)) p == ap g (ap f p) :=
  match p as p0 in paths _ y' return
    ap (fun a => g (f a)) p0 == ap g (ap f p0) with
  | idpath => idpath
  end.

(* ---- transport 的组合律 ---- *)

Definition transport_pp {A : Type} (P : A -> Type) {x y z : A}
  (p : x == y) (q : y == z) (u : P x)
  : transport P (p · q) u == transport P q (transport P p u) :=
  match p as p0 in paths _ y' return forall (q0 : y' == z),
    transport P (p0 · q0) u == transport P q0 (transport P p0 u) with
  | idpath => fun q0 => idpath
  end q.

(* transport 沿 idpath 是【定义性】恒等（J 只在 idpath 上计算） *)
Definition transport_1_is_def {A : Type} (P : A -> Type) (x : A) (u : P x)
  : transport P idpath u = u := eq_refl.    (* 用 = 当 definitional *)

(* ---- 2D 动作：ap10（函数路径取分量） ---- *)

Definition ap10 {A B : Type} {f g : A -> B} (p : f == g)
  : forall a, f a == g a :=
  match p as p0 in paths _ g' return forall a, f a == g' a with
  | idpath => fun a => idpath
  end.

(* ---- 实测：数值上的路径与搬运 ---- *)

Definition p23 : 2 + 1 == 3 := idpath.             (* 定义相等给的路径 *)
Definition P (n : nat) : Type := match n with 0 => bool | _ => nat end.
Definition t : P 3 := 3.
Check (transport P (p23 : 2 + 1 == 3)) t.          (* 搬到 P 2 = nat *)

(* 路径代数一段：p · !p 折回 idpath 的证明项可计算 *)
Eval compute in (concat_pV (idpath : 2 == 2)).

Print Assumptions concat_pV.   (* Closed under the global context *)
Print Assumptions transport_pp.
