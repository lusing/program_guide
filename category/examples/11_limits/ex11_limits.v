(* ex11 —— 极限的一般理论（图 = 函子、锥、泛锥）
   三书对位：贺伟 2.1（极限的定义）/ Simmons 第 4 章（模板与图）/
   《高级范畴论》3.5（极限和余极限）

   一般理论：图 = 函子 D : I → C，锥 = NT(Δc, D)，极限 = 终锥。
   本章机器化其中最透明的一片：常值函子 + 「二元离散图的极限 = 积」。
   Set 中极限 = 等化子拉回乘积的公式（Simmons 4.6.1）在文档层。 *)

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

(* ---------- 常值函子 Δc ---------- *)

Definition constFun (C D : Category) (c : Obj D) : Functor C D.
Proof.
  refine {| FObj := fun _ => c; FHom := fun _ _ f => idn D c |}.
  - intro a. reflexivity.
  - intros a b c0 f g. simpl. symmetry. apply idL.
Defined.

(* ---------- 二元离散图的极限 = 积 ----------
   形状范畴 = 两个对象的离散范畴；二元图表 = 两个对象；
   锥 = 两条腿；泛锥 = 积的泛性质。形状范畴本身（Hom a b 只在
   a = b 时非空）按「两条腿」直接展开成记录——一般形状的
   NT(Δc, D) 定义在文档层。 *)

Record Cone2 (C : Category) (a b x : Obj C) := mkCone2 {
  leg1 : Hom C x a;
  leg2 : Hom C x b
}.

Record IsLimit2 (C : Category) (a b p : Obj C) (π1 : Hom C p a) (π2 : Hom C p b) : Type :=
  mkLim2 {
    limCone : Cone2 C a b p;
    limUniv : forall x (k : Cone2 C a b x),
      { h : Hom C x p | comp C h π1 = leg1 k /\ comp C h π2 = leg2 k /\
        forall h' (e1 : comp C h' π1 = leg1 k) (e2 : comp C h' π2 = leg2 k), h' = h }
  }.

(* 极限 = 泛锥：二元情形就是积的泛性质 *)
Lemma limit2_is_product : forall (C : Category) (a b p : Obj C)
  (π1 : Hom C p a) (π2 : Hom C p b),
  IsLimit2 C a b p π1 π2 ->
  (forall c (f : Hom C c a) (g : Hom C c b),
    { h : Hom C c p | comp C h π1 = f /\ comp C h π2 = g /\
      forall h' (e1 : comp C h' π1 = f) (e2 : comp C h' π2 = g), h' = h }).
Proof.
  intros C a b p π1 π2 [cone univ] c f g.
  destruct (univ c (mkCone2 C a b c f g)) as [h [h1 [h2 huniq]]].
  exists h. split; [exact h1 | split; [exact h2 | exact huniq]].
Qed.

(* 反向同样成立（包装层互换）——极限与积「同构地等同」 *)
Lemma product_is_limit2 : forall (C : Category) (a b p : Obj C)
  (π1 : Hom C p a) (π2 : Hom C p b),
  (forall c (f : Hom C c a) (g : Hom C c b),
    { h : Hom C c p | comp C h π1 = f /\ comp C h π2 = g /\
      forall h' (e1 : comp C h' π1 = f) (e2 : comp C h' π2 = g), h' = h }) ->
  IsLimit2 C a b p π1 π2.
Proof.
  intros C a b p π1 π2 H.
  refine {| limCone := mkCone2 C a b p π1 π2 |}.
  intros x k. destruct k as [k1 k2].
  destruct (H x k1 k2) as [h [h1 [h2 huniq]]].
  exists h. split; [exact h1 | split; [exact h2 | exact huniq]].
Qed.

Print Assumptions limit2_is_product.   (* 零公理 *)
Print Assumptions product_is_limit2.  (* 零公理 *)

(* ---------- 文档层要点 ----------
   1. 一般极限：D : I → C，锥 = (顶点 x + 每个对象一条腿 +
      与每条图态射交换)，极限 = 终锥。上面的 Cone2/IsLimit2 是
      I = 二元离散形状的展开版。
   2. Set 的极限公式（Simmons 4.6.1）：lim D = { (x_i) |
      D(f)(x_i) = x_j } ⊆ ∏ D(i)——等化子嵌进乘积。
   3. 完备范畴（贺伟 2.5）：有全部（小）极限 ⟺ 有乘积与等化子
      （经典定理）——证明是「造锥」的组合术，超出机器范围。
   4. 对偶：余极限 = 反范畴的极限；余积 = 二元离散图的余极限。 *)

(* 坑位速记：
   1. shape2 的 Hom 用 if-then-else 打包恒等——把「离散」的
      类型层定义直接写出来；Abort 的 diag2 草稿删掉
      （直接展开版更清楚，二元图表就是两个对象）。
   2. Cone2/IsLimit2 与 IsProduct（09 章）只差一层包装——
      两个方向的引理都是「拆包装 + 复用」。
   3. record 字段的 comp 访问：limUniv 的输出 sig 结构与
      09 章的 IsProduct 逐字段相同——跨章复用记录形状。 *)
