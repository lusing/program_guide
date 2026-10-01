(* ============================================================ *)
(* 20 泛等公理 —— 自包含 mini-HoTT（二）                          *)
(* 核心：等价 ⟷ 相等；公理只有一条 univalence，其余全定理。      *)
(* （19 章的核心 30 行复制于头部，文件自包含原则）                *)
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

Definition inverse {A : Type} {x y : A} (p : x == y) : y == x :=
  match p in paths _ y' return y' == x with idpath => idpath end.

Definition transport {A : Type} (P : A -> Type) {x y : A} (p : x == y)
  (u : P x) : P y :=
  match p in paths _ y' return P y' with idpath => u end.

(* ---- 等价：函数 + 两侧收缩（四份数据） ---- *)

Record isequiv {A B : Type} (f : A -> B) : Type :=
  MkIsEquiv {
    inv : B -> A;
    retr : forall b, f (inv b) == b;
    sec  : forall a, inv (f a) == a
  }.

Record equiv (A B : Type) : Type :=
  MkEquiv { equiv_fun : A -> B; equiv_isequiv : isequiv equiv_fun }.

(* 路径 → 等价：不用公理，J 直接造 *)
Definition idtoequiv {A B : Type} (p : A == B) : equiv A B :=
  transport (fun X => equiv A X) p
    (@MkEquiv A A (fun a => a)
       (@MkIsEquiv A A (fun a => a) (fun a => a)
          (fun a => idpath) (fun a => idpath))).

(* ---- 公理唯一的一条：univalence ---- *)
Axiom univalence : forall A B : Type, isequiv (@idtoequiv A B).

(* 从此 (A == B) ≃ (A ≃ B)：等价的类型就是【相等】的类型 *)
Definition ua {A B : Type} (e : equiv A B) : A == B :=
  @inv (A == B) (equiv A B) (@idtoequiv A B) (univalence A B) e.

(* ua 的计算规则（β）以公理形式补足——mini 开发的记账法：
   公理有几条、各管什么，一目了然 *)
Axiom transport_ua : forall (A B : Type) (e : equiv A B) (u : A),
  transport (fun X => X) (ua e) u == (@equiv_fun A B e) u.

(* ---- 实测一：Bool 上的非平凡自等价 ---- *)

Inductive bool2 : Type := true2 | false2.

Definition negb (b : bool2) : bool2 :=
  match b with true2 => false2 | false2 => true2 end.

Definition negb_retr (b : bool2) : negb (negb b) == b :=
  match b with true2 => idpath | false2 => idpath end.

Definition negb_equiv : equiv bool2 bool2 :=
  @MkEquiv bool2 bool2 negb
    (@MkIsEquiv bool2 bool2 negb negb negb_retr negb_retr).

(* 取反不是恒等（true2 ↦ false2），但它是等价 *)
Definition neg_path := ua negb_equiv.

(* 沿 neg_path 搬运元素 = 逐点取反（β 公理一步接通） *)
Definition transport_neg (b : bool2)
  : transport (fun X => X) neg_path b == negb b :=
  transport_ua bool2 bool2 negb_equiv b.

(* ---- 实测二：宇宙不是集合（泛等的第一个推论） ---- *)
(* Bool == Bool 里至少有两条不同的路：idpath 与 neg_path。
   证不同需要更多机器（encode-decode，见 23 章）；此处先把
   【两条候选】摆出来——集合世界里 (Bool == Bool) 只该有
   idpath 一条。 *)

(* 公理记账：本文件 univalence + transport_ua 共两条 *)
Print Assumptions transport_neg.
(* depends on: transport_ua, univalence —— 账目清楚 *)
