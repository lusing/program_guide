(* ex10 —— 等化子与拉回
   三书对位：贺伟 2.2（等值子）/ 2.4（拉回与推出）/《高级范畴论》
   3.3（回拉）/ 3.4（核与余核）/ Simmons 2.6、2.7

   拉回 = 「纤维积」：给定 f : A→C、g : B→C，对象 P 带着
   两个投影使方块交换，且泛于一切竞争方块。
   本章旗舰（抽象）：单态射的拉回仍是单态射——只用定律与唯一性。 *)

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
Axiom PI : forall (P : Prop) (p q : P), p = q.

Definition opposite (C : Category) : Category := {|
  Obj := Obj C; Hom := fun a b => Hom C b a;
  idn := fun a => idn C a; comp := fun _ _ _ f g => comp C g f;
  idL := fun _ _ f => idR C f; idR := fun _ _ f => idL C f;
  assoc := fun _ _ _ _ f g h => eq_sym (assoc C h g f)
|}.

(* ---------- 定义 ---------- *)

Definition Mono (C : Category) (a b : Obj C) (f : Hom C a b) : Type :=
  forall c (g h : Hom C c a), comp C g f = comp C h f -> g = h.

(* 等化子：eq 压平 f、g，且泛于一切压平者 *)
Definition IsEqualizer (C : Category) (a b : Obj C)
  (f g : Hom C a b) (e : Obj C) (em : Hom C e a) : Type :=
  (comp C em f = comp C em g) *
  forall c (h : Hom C c a), comp C h f = comp C h g ->
    { m : Hom C c e | comp C m em = h /\ forall m', comp C m' em = h -> m' = m }.

(* 拉回：p1;f = p2;g 的泛方块 *)
Definition IsPullback (C : Category) (a b c : Obj C)
  (f : Hom C a c) (g : Hom C b c) (p : Obj C)
  (p1 : Hom C p a) (p2 : Hom C p b) : Type :=
  (comp C p1 f = comp C p2 g) *
  forall x (u : Hom C x a) (v : Hom C x b),
      comp C u f = comp C v g ->
      { m : Hom C x p | comp C m p1 = u /\ comp C m p2 = v /\
        forall m', comp C m' p1 = u -> comp C m' p2 = v -> m' = m }.

(* 对偶：推出 = 反范畴里的拉回（f、g 视作 C^op 里的 b→a、c→a） *)
Definition IsPushout (C : Category) (a b c : Obj C)
  (f : Hom C a b) (g : Hom C a c) (q : Obj C)
  (i1 : Hom C b q) (i2 : Hom C c q) : Type :=
  IsPullback (opposite C) b c a f g q i1 i2.

(* 核（高级 3.4）：在带零态射的范畴里 ker f = eq(f, 0)——文档层 *)

(* ---------- 旗舰：单态射的拉回仍是单态射 ---------- *)

Lemma pb_of_mono : forall (C : Category) (a b c : Obj C)
  (f : Hom C a c) (g : Hom C b c) (p : Obj C)
  (p1 : Hom C p a) (p2 : Hom C p b),
  IsPullback C a b c f g p p1 p2 ->
  Mono C a c f ->
  Mono C p b p2.
Proof.
  intros C a b c f g p p1 p2 [sq univ] Hf x u v Huv.
  (* u;p2 = v;p2 要证 u = v：让 u、v 竞争同一个锥 *)
  assert (Hcone : comp C (comp C u p1) f = comp C (comp C u p2) g).
  { rewrite (assoc C u p1 f), (assoc C u p2 g), sq. reflexivity. }
  destruct (univ x (comp C u p1) (comp C u p2) Hcone) as [m [m1 [m2 muniq]]].
  assert (Hu : u = m).
  { apply muniq; [reflexivity | reflexivity]. }
  assert (Hv : v = m).
  { apply muniq.
    - (* v;p1 = u;p1：两边后复合 f 后都化到 (u;p2);g，再由 f 单性 *)
      assert (E1 : comp C (comp C v p1) f = comp C (comp C v p2) g).
      { rewrite (assoc C v p1 f), sq, <- (assoc C v p2 g). reflexivity. }
      assert (E2 : comp C (comp C v p2) g = comp C (comp C u p1) f).
      { rewrite <- Huv, (assoc C u p2 g), <- sq, <- (assoc C u p1 f).
        reflexivity. }
      apply Hf. rewrite E1, E2. reflexivity.
    - rewrite <- Huv. reflexivity. }
  rewrite Hu, Hv. reflexivity.
Qed.

Print Assumptions pb_of_mono.   (* 零公理：定律 + 唯一性 + 单性的纯推理 *)

(* ---------- TyCat 里的具体拉回：纤维积 ---------- *)

Definition catTy : Category := {|
  Obj := Type@{Set};
  Hom := fun A B => A -> B;
  idn := fun A => (fun x => x);
  comp := fun _ _ _ f g => (fun x => g (f x));
  idL := fun _ _ f => eq_refl;
  idR := fun _ _ f => eq_refl;
  assoc := fun _ _ _ _ f g h => eq_refl
|}.

(* sig 的外延：第一分量相等即相等（证明分量用 PI） *)
Lemma sig_ext : forall (A : Type) (P : A -> Prop) (p q : {x : A | P x}),
  proj1_sig p = proj1_sig q -> p = q.
Proof.
  intros A P [a Pa] [b Pb] H. simpl in H.
  destruct H.                        (* b 代换成 a（连同 Pb 的类型） *)
  rewrite (@PI _ Pa Pb). reflexivity.
Qed.

(* pb = { (a,b) | f a = g b }；中介函数逐点造，唯一性 funext + sig_ext *)
Definition tyPullback : forall (A B C0 : Type@{Set})
  (f : A -> C0) (g : B -> C0),
  IsPullback catTy A B C0 f g
    { p : A * B | f (fst p) = g (snd p) }
    (fun p => fst (proj1_sig p)) (fun p => snd (proj1_sig p)).
Proof.
  intros A B C0 f g. split.
  - apply funext. intro z. exact (proj2_sig z).   (* sig 的证据即方程 *)
  - intros x u v Huv.
    exists (fun z => exist _ (u z, v z) (f_equal (fun k : x -> C0 => k z) Huv)).
    split; [reflexivity | split; [reflexivity | ]].   (* 两条投影律：βδι 折叠 *)
    intros m' e1 e2. apply funext. intro z.
    apply sig_ext.                 (* 只比第一分量：躲开 Pz 的依赖类型 *)
    destruct (m' z) as [pz Pz] eqn:Emz. simpl.
    destruct pz as [a2 b2]. f_equal.
    + (* a2 = u z：经 proj1_sig (m' z) 桥接 *)
      transitivity (fst (proj1_sig (m' z))).
      * rewrite (f_equal (@proj1_sig (A * B) (fun p => f (fst p) = g (snd p))) Emz).
        reflexivity.
      * exact (f_equal (fun k : x -> A => k z) e1).
    + (* b2 = v z *)
      transitivity (snd (proj1_sig (m' z))).
      * rewrite (f_equal (@proj1_sig (A * B) (fun p => f (fst p) = g (snd p))) Emz).
        reflexivity.
      * exact (f_equal (fun k : x -> B => k z) e2).
Qed.

Print Assumptions tyPullback.   (* funext + PI（sig 证明分量的无关性） *)

(* 坑位速记：
   1. pb_of_mono 的骨架：让 u、v 竞争「u 自己造的锥」——
      v;p1 = u;p1 由 f 的单性从「两边后复合 f 相等」逼出，
      然后 v 落进唯一性。transitivity + assoc + sq 的接力要对齐方向。
   2. tyPullback 的唯一性收尾：destruct (m' z) 提分量，
      pz = (u z, v z) 后要 rewrite <- Pz 恢复证明分量——两个证明
      的相等用 PI（funext 点级 + sig 分量级的双重需要）。
   3. 泛性质的 sig 版本（含唯一性）里第三子句是三参数量词
      （m' + 两条方程）——univ 模式解构时按嵌套 and 拆三层。 *)
