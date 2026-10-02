(* ex07 —— 范畴的等价与同构
   三书对位：《高级范畴论》4.7（范畴的同构与等价）/ Simmons 1.2.7
   （Pfn ≃ Set⊥ 的手工等价）/ 贺伟 3.3 前置。

   严格同构太稀有，「等价」才是范畴论的正确同构观：
   全忠实（Hom 集双射）+ 本质满（每个对象同构于某像）。
   等价 ⟺ 存在拟逆（定理陈述在文档；构造需要选择，作边界记录）。 *)

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

Record IsIsoD (C : Category) (a b : Obj C) (f : Hom C a b) : Type := mkIsoD {
  inv : Hom C b a;
  law1 : comp C f inv = idn C a;
  law2 : comp C inv f = idn C b
}.

(* ---------- 忠实与满（Hom 层面） ---------- *)

(* 忠实：Hom 映射单 *)
Definition Faithful (C D : Category) (F : Functor C D) : Type :=
  forall a b (f g : Hom C a b), FHom F f = FHom F g -> f = g.

(* 满：Hom 映射满（证据是数据） *)
Definition Full (C D : Category) (F : Functor C D) : Type :=
  forall a b (h : Hom D (FObj F a) (FObj F b)),
    { f : Hom C a b | FHom F f = h }.

Definition FullyFaithful (C D : Category) (F : Functor C D) : Type :=
  (@Faithful C D F) * (@Full C D F).   (* Set Implicit Arguments 把 C D F 隐化了，用 @ 显式给 *)

(* 本质满：每个 D 对象同构于某个 F 的像 *)
Definition EssentiallySurj (C D : Category) (F : Functor C D) : Type :=
  forall d : Obj D, { c : Obj C & { h : Hom D (FObj F c) d | True } }.

(* ---------- 恒等函子全忠实（定义即证） ---------- *)

Definition idFun (C : Category) : Functor C C.
Proof.
  refine {| FObj := fun a => a; FHom := fun _ _ f => f |}; intros; reflexivity.
Defined.

Lemma id_ff : forall (C : Category), @FullyFaithful C C (idFun C).
Proof.
  intros C. split.
  - intros a b f g H. exact H.
  - intros a b h. exists h. reflexivity.
Qed.

(* ---------- 恒等函子本质满 ---------- *)

Lemma id_es : forall (C : Category), @EssentiallySurj C C (idFun C).
Proof.
  intros C d. exists d. exists (idn C d). exact I.
Qed.

(* ---------- List 函子忠实（TyCat） ---------- *)

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

Lemma map_id_pt : forall (A : Type) (l : list A), map (fun x => x) l = l.
Proof.
  intros A l. induction l as [| x l IH]; simpl.
  - reflexivity.
  - rewrite IH. reflexivity.
Qed.

Lemma map_comp_pt : forall (A B C : Type) (f : A -> B) (g : B -> C) (l : list A),
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
  - intro A. apply funext. intro l. apply map_id_pt.
  - intros a b c f g. apply funext. intro l.
    change (map (fun x : a => g (f x)) l = map g (map f l)).
    apply map_comp_pt.
Defined.

(* 忠实：map f = map g → f = g——逐点用单点列表探测 *)
Lemma list_faithful : @Faithful catTy catTy listFun.
Proof.
  intros a b f g H. apply funext. intro x.
  assert (Hx := f_equal (fun k : list a -> list b => k (x :: nil)) H).
  simpl in Hx. (* [f x] = [g x] 蕴含 f x = g x *)
  inversion Hx. reflexivity.
Qed.

Print Assumptions id_ff.        (* 零公理 *)
Print Assumptions list_faithful. (* funext *)
Print Assumptions id_es.        (* 零公理 *)

(* ---------- 等价 vs 同构（文档要点） ----------
   同构 = 严格的双向函子对（对象层面也一一对应）；
   等价 = 全忠实 + 本质满。Simmons 1.2.7 的 Pfn ≃ Set⊥：
   部分函数范畴与带点集范畴等价（L 补点 / M 去点互为拟逆）——
   「看起来不同、行为相同」的官方版本。
   等价 ⟹ 拟逆存在（需选择公理；构造性版本要更多结构）——
   本教程把这一步作为诚实边界，机器化到全忠实/本质满为止。 *)

(* 坑位速记：
   1. Abort 的草稿要清干净（listFun 第一稿 induction 写歪）。
   2. 从 map f = map g 取点：f_equal (fun k => k [x]) 后
      [f x] = [g x] 用 inversion 提取头部——单点列表当探针。
   3. EssentiallySurj 里 True 占位是为了把「存在同构」保持为
      可扩充的 sig 结构（换成 IsIsoD 即得完整版，证明变重）。 *)
