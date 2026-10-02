(* ex06 —— 自然变换、函子范畴与 Godement 积
   三书对位：贺伟 1.3（自然变换）/《高级范畴论》4.5–4.6（自然变换
   及其 Godement 积）/ Simmons 3.4–3.5

   自然变换 = 函子之间「一族态射」η_a : F a → G a，对每条态射
   交换（自然性方块）。垂直/水平复合让它长成 2-范畴。
   NT 相等需要证明无关性——Coq 用 PI 公理入账（Agda 用分量相等
   的 setoid 风格、Lean 内核免费，见各文件）。 *)

Set Universe Polymorphism.
Set Implicit Arguments.

Record Category@{u v} : Type := mkCat {
  Obj : Type@{u};
  Hom : Obj -> Obj -> Type@{v};
  idn : forall a, Hom a a;
  comp : forall {a b c}, Hom a b -> Hom b c -> Hom a c;
  idL : forall {a b} (f : Hom a b), comp (idn a) f = f;
  idR : forall {a b} (f : Hom a b), comp f (idn b) = f;
  assoc : forall {a b c d} (f : Hom a b) (g : Hom b c) (h : Hom c d),
            comp (comp f g) h = comp f (comp g h)
}.

Record Functor@{u v u' v'} (C : Category@{u v}) (D : Category@{u' v'}) : Type := mkFun {
  FObj : Obj C -> Obj D;
  FHom : forall {a b}, Hom C a b -> Hom D (FObj a) (FObj b);
  Fid : forall a, FHom (idn C a) = idn D (FObj a);
  Fcomp : forall {a b c} (f : Hom C a b) (g : Hom C b c),
            FHom (comp C f g) = comp D (FHom f) (FHom g)
}.

Axiom funext : forall {A B} (f g : A -> B), (forall x, f x = g x) -> f = g.

(* 证明无关性：同一命题的两个证明相等（函子范畴的定律要用） *)
Axiom PI : forall (P : Prop) (p q : P), p = q.

(* 依赖版外延：分量族住在依赖函数空间（Hom D (F a) (K a) 随 a 变） *)
Axiom funextd : forall {A : Type} {B : A -> Type} (f g : forall x, B x),
  (forall x, f x = g x) -> f = g.

(* ---------- 自然变换 ---------- *)

Record NT {C D} (F G : Functor C D) : Type := mkNT {
  ncomp : forall a, Hom D (FObj F a) (FObj G a);
  nlaw : forall {a b} (f : Hom C a b),
           comp D (FHom F f) (ncomp b) = comp D (ncomp a) (FHom G f)
}.

(* 自然性方块的读法：F f;η_b = η_a;G f——
   「η 是一族态射，与一切态射可交换」 *)

(* ---------- 垂直复合与恒等 ---------- *)

Definition vcomp {C D} {F G H : Functor C D} (α : NT F G) (β : NT G H) : NT F H.
Proof.
  refine {| ncomp := fun a => comp D (ncomp α a) (ncomp β a) |}.
  intros a b f. simpl.
  rewrite <- (assoc D (FHom F f) (ncomp α b) (ncomp β b)).
  rewrite (nlaw α f).
  rewrite (assoc D (ncomp α a) (FHom G f) (ncomp β b)).
  rewrite (nlaw β f).
  rewrite <- (assoc D (ncomp α a) (ncomp β a) (FHom H f)).
  reflexivity.
Defined.

Definition vid {C D} {F : Functor C D} : NT F F.
Proof.
  refine {| ncomp := fun a => idn D (FObj F a) |}.
  intros a b f. simpl.
  rewrite (idR D (FHom F f)), (idL D (FHom F f)). reflexivity.
Defined.

(* ---------- 函子范畴的定律 ----------
   注意：NT 的 nlaw 字段类型**依赖** ncomp 字段——record 相等是
   异构问题，f_equal 与 rewrite 都被依赖性挡住（Coq 无原始投影时
   的经典 Setoid 困境；agda-categories 用 setoid 正是为此）。
   本教程的立场：定律在**分量层面**陈述与证明（数学内容全在），
   record 级相等的补全见 Lean 版（结构 η + 内核证明无关性免费）。 *)

Lemma vcomp_assoc_comp : forall (C D : Category) (F G H K : Functor C D)
  (α : NT F G) (β : NT G H) (γ : NT H K),
  ncomp (vcomp (vcomp α β) γ) = ncomp (vcomp α (vcomp β γ)).
Proof.
  intros C D F G H K α β γ.
  unfold vcomp. simpl. apply funextd. intro a. apply assoc.
Qed.

Lemma vcomp_idR_comp : forall (C D : Category) (F G : Functor C D) (α : NT F G),
  ncomp (vcomp α (vid)) = ncomp α.
Proof.
  intros C D F G α. unfold vcomp, vid. simpl.
  apply funextd. intro a. apply idR.
Qed.

Lemma vcomp_idL_comp : forall (C D : Category) (F G : Functor C D) (α : NT F G),
  ncomp (vcomp (vid) α) = ncomp α.
Proof.
  intros C D F G α. unfold vcomp, vid. simpl.
  apply funextd. intro a. apply idL.
Qed.

(* [C, D] 是范畴：对象 = 函子、态射 = 自然变换。上面三条分量定律
   加上 nlaw 字段的证明无关性（PI，或原始投影/结构 η）即得完整
   范畴结构——三家补全路线的差异本身就是 2-范畴形式化的教材。 *)

(* ---------- 函子复合（水平方向的前置件） ---------- *)

Definition compFun {C D E} (G : Functor D E) (F : Functor C D) : Functor C E.
Proof.
  refine {| FObj := fun a => FObj G (FObj F a);
            FHom := fun _ _ f => FHom G (FHom F f) |}.
  - intro a. rewrite (Fid F a), (Fid G). reflexivity.
  - intros a b c f g0. rewrite (Fcomp F f g0), (Fcomp G). reflexivity.
Defined.

(* ---------- Godement 积（水平复合） ----------
   α : F ⇒ G（C→D 内），β : H ⇒ K（D→E 内）：
   β ⋆ α : H∘F ⇒ K∘G，分量  (β ⋆ α)_a = H(α_a) ; β_{G a}   *)

Definition hcomp {C D E} {F G : Functor C D} {H K : Functor D E}
  (α : NT F G) (β : NT H K) : NT (compFun H F) (compFun K G).
Proof.
  refine {| ncomp := fun a =>
    (comp E (FHom H (ncomp α a)) (ncomp β (FObj G a))
       : Hom E (FObj (compFun H F) a) (FObj (compFun K G) a)) |}.
  intros a b f. simpl.
  (* 目标：H(Ff);(H(α_b);β_{Gb}) = (H(α_a);β_{Ga});K(Gf)
     ——五步追图：并组 → 函子性进 H → α 的自然性 → β 的自然性 → 拆组 *)
  rewrite <- (assoc E (FHom H (FHom F f)) (FHom H (ncomp α b))
                (ncomp β (FObj G b))).
  rewrite <- (Fcomp H (FHom F f) (ncomp α b)).
  rewrite (nlaw α f).
  rewrite (Fcomp H (ncomp α a) (FHom G f)).
  rewrite (assoc E (FHom H (ncomp α a)) (FHom H (FHom G f))
                (ncomp β (FObj G b))).
  rewrite (nlaw β (FHom G f)).
  rewrite <- (assoc E (FHom H (ncomp α a)) (ncomp β (FObj G a))
                (FHom K (FHom G f))).
  reflexivity.
Defined.

Print Assumptions vcomp_assoc_comp.   (* funextd *)
Print Assumptions hcomp.         (* 零公理——纯方块追图 *)

(* ---------- 一个具体的自然变换：reverse ----------
   catTy 上 reverse : Id ⇒ Id 是自然变换
   （reverse ∘ map f = map f ∘ reverse） *)

Require Import List.

Definition catTy : Category := {|
  Obj := Type@{Set};
  Hom := fun A B => A -> B;
  idn := fun A => (fun x => x);
  comp := fun _ _ _ f g => (fun x => g (f x));
  idL := fun _ _ f => eq_refl;
  idR := fun _ _ f => eq_refl;
  assoc := fun _ _ _ _ f g h => eq_refl
|}.

(* idFun 按本章基础设施重造（透明、可 ι-折叠） *)
Definition idFun (C : Category) : Functor C C.
Proof.
  refine {| FObj := fun a => a; FHom := fun _ _ f => f |}; intros; reflexivity.
Defined.

Lemma map_id_ext : forall (A : Type) (l : list A), map (fun x => x) l = l.
Proof.
  intros A l. induction l as [| x l IH]; simpl.
  - reflexivity.
  - rewrite IH. reflexivity.
Qed.

Lemma map_comp_ext : forall (A B C : Type) (f : A -> B) (g : B -> C) (l : list A),
  map (fun x : A => g (f x)) l = map g (map f l).
Proof.
  intros A B C f g l. induction l as [| x l IH]; simpl.
  - reflexivity.
  - rewrite IH. reflexivity.
Qed.

Definition listFun : Functor catTy catTy.
Proof.
  refine {| FObj := fun A : Obj catTy => (list A : Obj catTy);
            FHom := fun _ _ f => map f |}.
  - intro A. apply funext. intro l. apply map_id_ext.
  - intros a b c f g. apply funext. intro l.
    change (map (fun x : a => g (f x)) l = map g (map f l)).
    apply map_comp_ext.
Defined.

Lemma rev_map : forall (A B : Type) (f : A -> B) (l : list A),
  rev (map f l) = map f (rev l).
Proof.
  intros A B f l. induction l as [| x l IH]; simpl.
  - reflexivity.
  - rewrite map_app, IH. reflexivity.
Qed.

(* reverse 是 List 函子的自变换：rev ∘ map f = map f ∘ rev *)
Definition revNT : NT (listFun) (listFun).
Proof.
  refine {| ncomp := fun A : Obj catTy =>
            (@rev A : Hom catTy (FObj listFun A) (FObj listFun A)) |}.
  intros A B f. simpl. apply funext. apply rev_map.
Defined.

(* 坑位速记：
   1. NT 的 nlaw 字段类型依赖 ncomp 字段——record 相等是异构\r\n      问题：f_equal 不拆、rewrite 报 ill-typed。定律在分量层面\r\n      陈述（数学内容全在）；record 级补全：Lean 结构 η+内核 PI\r\n      免费、Coq 要原始投影、Agda 干脆 setoid——三家路线。
   2. vcomp/vid/compFun/hcomp 全部 Defined：后续 unfold/ι-折叠
      要透明（Qed 会挡住 ncomp 的化简）。
   3. hcomp 的 naturality 是本章的技术高点：五步追图
      （assoc 并组 → Fcomp 进函子 → nlaw α → Fcomp 出 → nlaw β →
      assoc 拆组），每步 rewrite 的方向都要对着目标摆正。
   4. rev 自然变换的 naturality = rev_map（map_app 展开方向拼）。 *)
