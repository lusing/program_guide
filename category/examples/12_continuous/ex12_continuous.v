(* ex12 —— 保持极限的函子：可表函子保积
   三书对位：贺伟 2.6（保持极限的函子）/ Simmons 3.5 / 高级 5.6 前置

   机器内容：Hom(c, -) 把积变成积——泛性质穿过 hom 集。
   这是「Yoneda 推论」的实践版：积的泛性质逐条搬进 Hom 集。 *)

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

Definition IsProduct (C : Category) (a b p : Obj C)
  (p1 : Hom C p a) (p2 : Hom C p b) : Type :=
  forall c (f : Hom C c a) (g : Hom C c b),
    { h : Hom C c p | comp C h p1 = f /\ comp C h p2 = g /\
        forall h' (e1 : comp C h' p1 = f) (e2 : comp C h' p2 = g), h' = h }.

(* Hom(c, A×B) → Hom(c,A) × Hom(c,B) 是双射（打包成两个方向 +
   唯一性）——「hom 函子连续」的二值情形 *)
Lemma hom_preserves_product :
  forall (C : Category) (c a b p : Obj C) (p1 : Hom C p a) (p2 : Hom C p b),
  IsProduct C a b p p1 p2 ->
  forall (f : Hom C c a) (g : Hom C c b),
    { h : Hom C c p | comp C h p1 = f /\ comp C h p2 = g }.
Proof.
  intros C c a b p p1 p2 HP f g.
  destruct (HP c f g) as [h [h1 [h2 _]]].
  exists h. split; assumption.
Qed.

(* 满方向唯一：hom 层的配对也唯一——泛性质直通 *)
Lemma hom_product_unique :
  forall (C : Category) (c a b p : Obj C) (p1 : Hom C p a) (p2 : Hom C p b),
  IsProduct C a b p p1 p2 ->
  forall (h h' : Hom C c p),
  comp C h p1 = comp C h' p1 -> comp C h p2 = comp C h' p2 -> h = h'.
Proof.
  intros C c a b p p1 p2 HP h h' E1 E2.
  destruct (HP c (comp C h p1) (comp C h p2)) as [m [_ [_ muniq]]].
  assert (Hh : h = m) by (apply muniq; reflexivity).
  assert (Hh' : h' = m) by (apply muniq; [symmetry; exact E1 | symmetry; exact E2]).
  rewrite Hh, Hh'. reflexivity.
Qed.

Print Assumptions hom_preserves_product.   (* 零公理 *)
Print Assumptions hom_product_unique.      (* 零公理 *)

(* 文档层：一般定理「可表函子保持全部极限」由 Yoneda 从这一情形
   推广；「右伴随保持极限」（贺伟 3.6/高级 5.6）在 15 章陈述。 *)

(* 坑位速记：
   1. 「保积」的两种陈述：对象层（像还是积）与 hom 层（配对双射）
      ——后者不需要目标范畴有积，更适合抽象证明。
   2. HP 的三段拆包：exists/方程对/唯一——destruct 按嵌套 as 模式
      一次到位。
   3. hom_product_unique 的换向：把 h' 的方程 rewrite 回去后两个
      都变 reflexivity——「唯一性当武器」的最小样本。 *)
