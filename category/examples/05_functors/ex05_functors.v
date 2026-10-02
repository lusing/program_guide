(* ex05 —— 函子
   三书对位：贺伟 1.2（函子）/《高级范畴论》4.1–4.3（函子、hom-函子）/
   Simmons 3.1–3.3（幂集函子、从积来的函子）

   函子 = 范畴之间的「保结构映射」：对象派对象、态射派态射，
   保恒等、保复合。它把整个交换图的世界整体搬运。 *)

(* Functor 要跨两个范畴，必须真宇宙多态——默认 flags 下 @{u v}
   只是「命名全局宇宙」（单态），多态要显式开关 *)
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

Axiom funext : forall {A B} (f g : A -> B), (forall x, f x = g x) -> f = g.

(* ---------- 定义 ---------- *)

Record Functor@{u v u' v'} (C : Category@{u v}) (D : Category@{u' v'}) : Type := mkFun {
  FObj : Obj C -> Obj D;
  FHom : forall {a b}, Hom C a b -> Hom D (FObj a) (FObj b);
  Fid : forall a, FHom (idn C a) = idn D (FObj a);
  Fcomp : forall {a b c} (f : Hom C a b) (g : Hom C b c),
            FHom (comp C f g) = comp D (FHom f) (FHom g)
}.

(* ---------- 例 1：恒等函子与常值函子 ---------- *)

Definition idFun (C : Category) : Functor C C := {|
  FObj := fun a => a;
  FHom := fun _ _ f => f;
  Fid := fun a => eq_refl;
  Fcomp := fun _ _ _ f g => eq_refl
|}.

(* 常值函子：全部送到单点——需要 D 有终对象；用 catOne 当靶子最省事 *)
Lemma unit_eq (u : unit) : tt = u. Proof. destruct u; reflexivity. Qed.

Definition catOne : Category := {|
  Obj := unit; Hom := fun _ _ => unit; idn := fun _ => tt;
  comp := fun _ _ _ _ _ => tt;
  idL := fun _ _ f => unit_eq f; idR := fun _ _ f => unit_eq f;
  assoc := fun _ _ _ _ _ _ _ => eq_refl
|}.

Definition constFun (C : Category) : Functor C catOne := {|
  FObj := fun _ : Obj C => (tt : Obj catOne);
  FHom := fun _ _ _ => tt;
  Fid := fun a => eq_refl;
  Fcomp := fun _ _ _ _ _ => eq_refl
|}.

(* ---------- 例 2：List 函子（TyCat 上的自函子） ---------- *)

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

Lemma map_id' : forall (A : Type), map (fun x : A => x) = (fun l => l).
Proof.
  intros A. apply funext. intro l. induction l as [| x l IH]; simpl.
  - reflexivity.
  - rewrite IH. reflexivity.
Qed.

Lemma map_comp' : forall (A B C : Type) (f : A -> B) (g : B -> C),
  map (fun x : A => g (f x)) = fun l => map g (map f l).
Proof.
  intros A B C f g. apply funext. intro l. induction l as [| x l IH]; simpl.
  - reflexivity.
  - rewrite IH. reflexivity.
Qed.

Definition listFun : Functor catTy catTy := {|
  FObj := fun A : Obj catTy => (list A : Obj catTy);
  FHom := fun _ _ f => map f;
  Fid := map_id';
  Fcomp := map_comp'
|}.

(* ---------- 例 3：hom-函子 Hom(a, -) : C → TyCat ----------
   对象 b ↦ Hom C a b；态射 f ↦ 后复合 g ↦ g;f。
   注意：函子定律逐条就是范畴定律的点式版！ *)

Definition homFun (C : Category@{Set Set}) (a : Obj C) : Functor C catTy := {|
  FObj := fun b : Obj C => (Hom C a b : Obj catTy);
  FHom := fun _ _ f => (fun g => comp C g f);
  Fid := fun b => @funext _ _ (fun g => comp C g (idn C b)) (fun x => x)
                   (fun g => idR C g);          (* g;id = g 点式 *)
  Fcomp := fun _ _ _ f g => @funext _ _ (fun h => comp C h (comp C f g))
                   (fun h => comp C (comp C h f) g)
                   (fun h => eq_sym (assoc C h f g))
|}.

(* 逆变 = 反范畴上的协变：Hom(-, b) : C^op → TyCat *)
Definition opposite (C : Category) : Category := {|
  Obj := Obj C; Hom := fun a b => Hom C b a;
  idn := fun a => idn C a; comp := fun _ _ _ f g => comp C g f;
  idL := fun _ _ f => idR C f; idR := fun _ _ f => idL C f;
  assoc := fun _ _ _ _ f g h => eq_sym (assoc C h g f)
|}.

Definition homFunContra (C : Category@{Set Set}) (b : Obj C)
  : Functor (opposite C) catTy :=
  homFun (opposite C) b.   (* C^op 的 hom-函子就是原范畴的 Hom(-,b) *)

(* ---------- 例 4：FinCat 上的 length——「忘结构」的雏形 ---------- *)

Fixpoint fin (n : nat) : Set :=
  match n with O => Empty_set | S m => option (fin m) end.

(* ---------- 函子保交换图 ----------
   图形 chase 的整体搬运：C 里 f;h = g;k ⟹ D 里 Ff;Fh = Fg;Fk *)
Lemma F_preserves_square :
  forall (C D : Category) (F : Functor C D) (a b c e : Obj C)
    (f : Hom C a b) (h : Hom C b e) (g : Hom C a c) (k : Hom C c e),
    comp C f h = comp C g k ->
    comp D (FHom F f) (FHom F h) = comp D (FHom F g) (FHom F k).
Proof.
  intros C D F a b c e f h g k H.
  rewrite <- (Fcomp F f h), <- (Fcomp F g k), H. reflexivity.
Qed.

Print Assumptions F_preserves_square.   (* 零公理 *)
Print Assumptions listFun.              (* funext（map 律的点式化） *)
Print Assumptions homFun.               (* funext *)

(* 坑位速记：
   1. map 律的函数级相等要 funext + 归纳（点式版 map_id'/map_comp'
      自证比翻 stdlib 引理名更稳——名字随版本漂）。
   2. hom-函子的 Fcomp 是 assoc 的点式对称——「函子定律 = 范畴
      定律点式化」是 Yoneda（08 章）一切免费的根源。
   3. Hom(a,-) 的靶范畴是 catTy：Hom C a b 必须落在 Set 层——
      源范畴钉 Category@{Set,Set}，宇宙对齐后再玩。
   4. Abort 留下的引理要清干净（map_id_ext 那种写歪的草稿）。 *)
