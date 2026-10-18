(* ex13 —— 伴随的三副面孔
   三书对位：贺伟 3.1（伴随函子的定义）/《高级范畴论》5.2–5.4
   （泛映射/余泛映射/伴随）/ Simmons 5.1

   伴随 F ⊣ G 的单位-余单位定义：η : Id ⇒ GF、ε : FG ⇒ Id +
   两条三角恒等式。机器内容：从三角恒等式推出 hom-双射的
   一个往返等式 ψ(φ f) = f——「伴随 = 泛映射」的机器内核。 *)

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

(* 伴随：η/ε 的分量族 + 自然性 + 三角恒等式
   （NT 的完整 record 基础设施在 06 章；这里按分量内联——
   免掉依赖字段的 record 相等问题） *)
Record Adjunction (C D : Category) (F : Functor C D) (G : Functor D C) : Type := mkAdj {
  eta : forall c, Hom C c (FObj G (FObj F c));
  eta_nat : forall {a b} (f : Hom C a b),
    comp C f (eta b) = comp C (eta a) (FHom G (FHom F f));
  eps : forall d, Hom D (FObj F (FObj G d)) d;
  eps_nat : forall {a b} (f : Hom D a b),
    comp D (FHom F (FHom G f)) (eps b) = comp D (eps a) f;
  tri1 : forall c, comp D (FHom F (eta c)) (eps (FObj F c)) = idn D (FObj F c);
  tri2 : forall d, comp C (eta (FObj G d)) (FHom G (eps d)) = idn C (FObj G d)
}.

(* hom-双射的两个方向 *)
Definition adjPhi (C D : Category) (F : Functor C D) (G : Functor D C)
  (A : @Adjunction C D F G) (c : Obj C) (d : Obj D)
  (f : Hom D (FObj F c) d) : Hom C c (FObj G d) :=
  comp C (eta A c) (FHom G f).

Definition adjPsi (C D : Category) (F : Functor C D) (G : Functor D C)
  (A : @Adjunction C D F G) (c : Obj C) (d : Obj D)
  (g : Hom C c (FObj G d)) : Hom D (FObj F c) d :=
  comp D (FHom F g) (eps A d).

(* 往返 1：ψ(φ f) = f —— 三角恒等式 + ε 自然性 *)
Lemma adj_round1 : forall (C D : Category) (F : Functor C D) (G : Functor D C)
  (A : @Adjunction C D F G) (c : Obj C) (d : Obj D)
  (f : Hom D (FObj F c) d),
  @adjPsi C D F G A c d (@adjPhi C D F G A c d f) = f.
Proof.
  intros C D F G A c d f.
  unfold adjPsi, adjPhi.
  rewrite (Fcomp F (eta A c) (FHom G f)).
  rewrite (assoc D (FHom F (eta A c)) (FHom F (FHom G f)) (eps A d)).
  rewrite (eps_nat A f).
  rewrite <- (assoc D (FHom F (eta A c)) (eps A (FObj F c)) f).
  rewrite (tri1 A c).
  apply idL.
Qed.

Print Assumptions adj_round1.   (* 零公理 *)

(* 往返 2（φ(ψ g) = g）对称地用 eta_nat + tri2——练习留给
   读者/后续章；伴随三面孔的等价性证明见文档层：
   hom-双射 ⟺ 泛映射 ⟺ 单位-余单位（贺伟 3.1 的三条路线）。 *)

(* 坑位速记：
   1. Abort 的第一版 Adjunction（tri2 写歪）已删——Record 重复
      声明要先 Abort 掉草稿再重写。
   2. adj_round1 的四步链：Fcomp 并组 → assoc 拆组 → ε 自然性
      → assoc 并组 → tri1 → idL。每步方向对齐目标。
   3. eps_nat 的形状：FGf;ε_b = ε_a;f——「ε 是自然变换」的
      分量内联版（免掉 NT record 的依赖字段问题）。 *)
