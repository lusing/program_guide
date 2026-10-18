(* ex12 —— 子对象、商对象与射影对象（贺伟 1.5 / 1.7）
   四个零公理定理：终点出发皆单（1.5.13）、始对象射影（1.7.6）、
   射影的收缩封闭（1.7.7）、满射的核对是等价关系（1.5.15）。 *)

Record Category : Type := mkCat {
  Obj : Type;
  Hom : Obj -> Obj -> Set;
  idn : forall a, Hom a a;
  comp : forall {a b c}, Hom a b -> Hom b c -> Hom a c;
  idL : forall {a b} (f : Hom a b), comp (idn a) f = f;
  idR : forall {a b} (f : Hom a b), comp f (idn b) = f;
  assoc : forall {a b c d} (f : Hom a b) (g : Hom b c) (h : Hom c d),
            comp (comp f g) h = comp f (comp g h)
}.

Definition Epi (C : Category) (a b : Obj C) (f : Hom C a b) : Type :=
  forall c (g h : Hom C b c), comp C f g = comp C f h -> g = h.

Definition Mono (C : Category) (a b : Obj C) (f : Hom C a b) : Type :=
  forall c (g h : Hom C c a), comp C g f = comp C h f -> g = h.

Definition Terminal (C : Category) (t : Obj C) : Type :=
  forall a, { f : Hom C a t | forall g, g = f }.

Definition Initial (C : Category) (i : Obj C) : Type :=
  forall a, { f : Hom C i a | forall g, g = f }.

(* ---------- 命题 1.5.13：终对象出发的箭头都是单 ---------- *)

Lemma terminal_arrow_mono : forall (C : Category) (t : Obj C),
  Terminal C t -> forall a (f : Hom C t a), Mono C t a f.
Proof.
  intros C t Ht a f c g h _.
  destruct (Ht c) as [u Hu].
  rewrite (Hu g), (Hu h). reflexivity.
Qed.

(* ---------- 命题 1.7.6：始对象是射影对象 ----------
   提升的存在与唯一都由「Hom(P,·) 单点」白送——甚至用不到
   满性（对一切箭头 e 都成立，比书更强）。 ---------- *)

Definition Projective (C : Category) (p : Obj C) : Type :=
  forall a b (e : Hom C a b), Epi C a b e ->
  forall f : Hom C p b, { g : Hom C p a | f = comp C g e }.

Lemma initial_projective : forall (C : Category) (i : Obj C),
  Initial C i -> Projective C i.
Proof.
  intros C i Hi a b e He f.
  destruct (Hi a) as [u Hu].       (* i -> a 的唯一箭头 *)
  destruct (Hi b) as [v Hv].
  exists u.
  (* f = u;e：i -> b 的箭头只有一条，f 与 u;e 都是 *)
  rewrite (Hv f), (Hv (comp C u e)). reflexivity.
Qed.

(* ---------- 命题 1.7.7：射影对象的收缩仍是射影对象 ---------- *)

Definition RetractOf (C : Category) (r p : Obj C) : Type :=
  { i : Hom C r p & { rr : Hom C p r | comp C i rr = idn C r } }.

Lemma retract_projective : forall (C : Category) (p r : Obj C),
  Projective C p -> RetractOf C r p -> Projective C r.
Proof.
  intros C p r Hp Hret a b e He f.
  destruct Hret as [i Hret2]. destruct Hret2 as [rr Hrr].
  (* 提升 rr;f : p -> b 经 e 得 g *)
  destruct (Hp a b e He (comp C rr f)) as [g Hg].
  exists (comp C i g).                               (* 拉回：i;g : r -> a *)
  (* f = f;1 = (i;rr);f = i;(rr;f) = i;(g;e) = (i;g);e *)
  rewrite <- (idL C f), <- Hrr, (assoc C i rr f), Hg, <- (assoc C i g e).
  reflexivity.
Qed.

(* ---------- 例 1.5.15 的核对：满射诱导等价关系 ----------
   4 点集 bool*bool、e := fst；核对 x ~ y ⟺ fst x = fst y。
   refl/sym/trans 全部 destruct 穷尽。 *)

Require Import Bool.

Definition kpair (x y : bool * bool) : bool :=
  eqb (fst x) (fst y).

Lemma kpair_refl : forall x, kpair x x = true.
Proof. intros [a b]. destruct a; reflexivity. Qed.

Lemma kpair_sym : forall x y, kpair x y = true -> kpair y x = true.
Proof. intros [a1 b1] [a2 b2] H. simpl in H.
       destruct a1, a2; simpl in *; try reflexivity; discriminate. Qed.

Lemma kpair_trans : forall x y z,
  kpair x y = true -> kpair y z = true -> kpair x z = true.
Proof.
  intros [a1 b1] [a2 b2] [a3 b3] H1 H2. simpl in *.
  destruct a1, a2, a3; simpl in *; try reflexivity; discriminate.
Qed.

Print Assumptions terminal_arrow_mono.
Print Assumptions initial_projective.
Print Assumptions retract_projective.
Print Assumptions kpair_trans.
