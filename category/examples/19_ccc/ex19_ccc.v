(* ex16 —— Cartesian 闭范畴
   三书对位：贺伟 3.4（Cartesian 闭范畴）/《高级范畴论》6.3 /
   Simmons 5.x。CCC = 有终对象 + 二元积 + 指数：λ 演算的语义家。

   机器内容：指数的泛性质 + TyCat 的指数 = 函数类型（curry 双射）。 *)

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

Definition IsProduct (C : Category) (a b p : Obj C)
  (p1 : Hom C p a) (p2 : Hom C p b) : Type :=
  forall c (f : Hom C c a) (g : Hom C c b),
    { h : Hom C c p | comp C h p1 = f /\ comp C h p2 = g /\
        forall h' (e1 : comp C h' p1 = f) (e2 : comp C h' p2 = g), h' = h }.

(* 最干净的路：一切在 TyCat 里直接验证——
   指数 = 函数类型、curry = λ、eval = 应用。
   （抽象 CCC 的 record 定义要把 IsProduct 数据背在指数上，
   相互依赖的字段填充超出 mini 库规模——hom 层的 curry 双射
   正是「CCC 的 hom 层定义」，见文档层与 Lean 版。） *)
Definition catTy : Category := {|
  Obj := Type@{Set};
  Hom := fun A B => A -> B;
  idn := fun A => (fun x => x);
  comp := fun _ _ _ f g => (fun x => g (f x));
  idL := fun _ _ f => eq_refl;
  idR := fun _ _ f => eq_refl;
  assoc := fun _ _ _ _ f g h => eq_refl
|}.

Definition curry (A B C0 : Type@{Set}) (f : C0 * A -> B) : C0 -> (A -> B) :=
  fun c a => f (c, a).

Definition uncurry (A B C0 : Type@{Set}) (g : C0 -> (A -> B)) : C0 * A -> B :=
  fun p => g (fst p) (snd p).

Lemma curry_round : forall (A B C0 : Type@{Set}) (f : C0 * A -> B),
  @uncurry A B C0 (@curry A B C0 f) = f.
Proof.
  intros. apply funext. intros [c a]. reflexivity.
Qed.

Lemma uncurry_round : forall (A B C0 : Type@{Set}) (g : C0 -> (A -> B)),
  @curry A B C0 (@uncurry A B C0 g) = g.
Proof.
  intros. apply funext. intro c. apply funext. intro a. reflexivity.
Qed.

Print Assumptions curry_round.    (* funext *)
Print Assumptions uncurry_round.  (* funext（析构配对的 η 展开） *)

(* 坑位速记：
   1. CCC 的抽象定义要携带积的泛性质数据（IsExp 依赖 IsProduct）
      ——record 相互依赖太重，教学版直接在 TyCat 验证 curry 双射
      （=「CCC 的 hom 层定义」）。完整抽象打包见 Lean 版/文档。
   2. curry_round 的 intros [c a] 一步析构点对——η 展开。 *)
