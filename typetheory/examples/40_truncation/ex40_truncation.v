(* ============================================================ *)
(* 38 截断层级 —— 自包含 mini-HoTT（三）                          *)
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

(* ============================================================ *)
(* 深化批（HoTT 书 §7.2）：Hedberg 定理完整机器版               *)
(*   前奏补件：transport / apd / assoc；引理 7.2.2（第一证明    *)
(*   的 K 路线）；7.2.4 dec ⇒ ¬¬→id；7.2.5 Hedberg；            *)
(*   样本：Bool 与 ℕ 都是 set                                    *)
(* ============================================================ *)

Definition inverse {A : Type} {x y : A} (p : x == y) : y == x :=
  match p in paths _ y' return y' == x with idpath => idpath end.
Notation "! p" := (inverse p) (at level 65).

Definition ap {A B : Type} (f : A -> B) {x y : A} (p : x == y)
  : f x == f y :=
  match p in paths _ y' return f x == f y' with idpath => idpath end.

Definition concat_Vp {A : Type} {x y : A} (p : x == y)
  : ((! p) · p) == idpath :=
  match p as p0 in paths _ y' return ((! p0) · p0) == (@idpath A y') with
  | idpath => idpath
  end.

Definition concat_p1 {A : Type} {x y : A} (p : x == y)
  : p · idpath == p :=
  match p as p0 in paths _ y' return (p0 · (@idpath A y')) == p0 with
  | idpath => idpath
  end.

Definition transport {A : Type} (P : A -> Type) {x y : A} (p : x == y)
  : P x -> P y :=
  match p in paths _ y' return P x -> P y' with idpath => fun u => u end.

Definition apd {A : Type} {P : A -> Type} (f : forall a, P a)
  {x y : A} (p : x == y)
  : transport P p (f x) == f y :=
  match p as p0 in paths _ y' return
      transport P p0 (f x) == f y' with
  | idpath => idpath
  end.

Definition concat_assoc {A : Type} {x y z w : A}
  (p : x == y) (q : y == z) (r : z == w)
  : p · (q · r) == (p · q) · r.
Proof. induction p; exact idpath. Qed.

(* ---- 引理 7.2.2（第一证明：直接打 K）----
   ① p*(f x x ρx) = f x x (p*ρx)   [apd 的自然性]
   ② p*ρx = ρx                     [R(x,x) 是 prop]
   ③ 路径族里的搬运 = 拼接形         [对 p 归纳直读]
   ④ 消去 ⇒ p == idpath             [K ⇒ set 是 7.2.1] ---- *)

Theorem reflexive_mere_rel_set
  {X : Type} (R : X -> X -> Type)
  (isPropR : forall x y, IsHProp (R x y))
  (rho : forall x, R x x)
  (f : forall x y, R x y -> x == y)
  : IsHSet X.
Proof.
  apply MkHSet. intros x y p q. induction q.
  assert (step1 : transport (fun z => x == z) p (f x x (rho x))
                  == f x x (transport (fun z => R x z) p (rho x))).
  { (* 书 7.2.2 的 ①：apd（λz r. f x z r）p 的展开式——
       依赖自然性 2.9.6；显式 J（match 版）一步即溃 *)
    exact (match p as p0 in paths _ y'
             return transport (fun z => x == z) p0 (f x x (rho x)) ==
                   f x y' (transport (fun z => R x z) p0 (rho x)) with
           | idpath => idpath
           end). }
  assert (step12 : transport (fun z => R x z) p (rho x) == rho x).
  { exact (hprop_all (R x x) (isPropR x x) _ _). }
  rewrite step12 in step1.
  assert (step3 : transport (fun z => x == z) p (f x x (rho x))
                  == f x x (rho x) · p).
  { (* 路径族（正侧端点族）的搬运 = 右拼接；基座即 concat_p1 *)
    exact (match p as p0 in paths _ y'
             return transport (fun z => x == z) p0 (f x x (rho x)) ==
                   f x x (rho x) · p0 with
           | idpath => inverse (concat_p1 (f x x (rho x)))
           end). }
  assert (canc : f x x (rho x) · p == f x x (rho x)).
  { (* ③ 的拼接形与 ①② 的规范形经由同一个 transport 合成 *)
    exact (inverse step3 · step1). }
  (* 消去四连（全显式串接避开记号优先级陷阱）：
     p ≡ 1·p ≡ (!w·w)·p ≡ !w·(w·p) ≡ !w·w ≡ 1 *)
  exact (concat (ap (fun k => k · p) (inverse (concat_Vp (f x x (rho x)))))
          (concat (inverse (concat_assoc (inverse (f x x (rho x)))
                                         (f x x (rho x)) p))
            (concat (ap (fun k => concat (inverse (f x x (rho x))) k) canc)
              (concat_Vp (f x x (rho x)))))).
Qed.

(* ---- 7.2.4：可判定 ⇒ ¬¬ 可消除 ---- *)

Lemma dec_dneg {A : Type} (d : A + (A -> empty)) : ((A -> empty) -> empty) -> A.
Proof.
  destruct d as [a | n].
  - intro. exact a.
  - intro nn. exact (empty_any A (nn n)).
Qed.

(* ---- 定理 7.2.5（Hedberg）：可判定等式 ⇒ set ---- *)

Theorem hedberg {X : Type}
  (deceq : forall x y : X, (x == y) + ((x == y) -> empty))
  : IsHSet X.
Proof.
  apply (reflexive_mere_rel_set (fun x y => ((x == y) -> empty) -> empty)).
  - (* 双重否定族的 prop 性：k 处两侧都落在 empty 里——空上无信息 *)
    intros x y. apply MkHProp. intros nn1 nn2.
    exact (funext _ _ nn1 nn2
             (fun k => empty_any (nn1 k == nn2 k) (nn1 k))).
  - intro x. exact (fun k => k idpath).
  - intros x y nn. exact (dec_dneg (deceq x y) nn).
Qed.

(* ---- 样本：Bool 与 ℕ 都是 set ---- *)

Definition bool2_deceq : forall x y : bool2, (x == y) + ((x == y) -> empty).
Proof.
  intros [ | ] [ | ].
  - left; exact idpath.
  - right; exact tf_empty.
  - right; intro p; exact (tf_empty (inverse p)).
  - left; exact idpath.
Defined.

Definition bool2_isSet : IsHSet bool2 := hedberg bool2_deceq.

(* ℕ 的判别等式：0≠S 与 S 的单射都由 paths 的依赖消去（large
   elimination：motive 按 y' 的形状分流）直接取出 *)
Definition noconf_0S {m : nat} (p : O == S m) : empty :=
  match p in paths _ y'
    return (match y' with O => unit | S _ => empty end) with
  | idpath => tt
  end.

Definition noconf_S0 {n : nat} (p : S n == O) : empty :=
  noconf_0S (inverse p).

Definition noconf_step {m n : nat} (p : S m == S n) : m == n :=
  match p in paths _ y'
    return (match y' with O => empty -> empty | S k => m == k end) with
  | idpath => idpath
  end.

Definition nat_deceq : forall x y : nat, (x == y) + ((x == y) -> empty).
Proof.
  induction x as [| n IH]; intros [ | m].
  - left; exact idpath.
  - right; exact noconf_0S.
  - right; exact noconf_S0.
  - destruct (IH m) as [e | ne].
    + left; exact (ap (fun k => S k) e).
    + right; intro p; exact (ne (noconf_step p)).
Defined.

Definition nat_isSet : IsHSet nat := hedberg nat_deceq.

Print Assumptions nat_isSet.
(* → funext：唯一公理（双重否定的 prop 性用它；cubical 侧免费） *)
