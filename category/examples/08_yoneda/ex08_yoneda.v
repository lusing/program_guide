(* ex08 —— Yoneda 引理与可表函子
   三书对位：贺伟 1.6（Yoneda 引理与可表达函子）/《高级范畴论》4.3
   （hom-函子）/ Simmons 3.5

   Yoneda 引理：Nat(Hom(a, -), F) ≅ F a。
   两个方向：
     φ(X) := X_a(id_a)                    （在 id 处取样）
     ψ(x)_b(g) := F g(x)                  （沿 g 搬运取样）
   一个方向用 Fid 白送；另一个方向恰是 X 的自然性在 id 处的特例——
   「Yoneda 是平凡的，但平凡得深刻」。 *)

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
Axiom funextd : forall {A : Type} {B : A -> Type} (f g : forall x, B x),
  (forall x, f x = g x) -> f = g.

(* ---------- 舞台：catTy 与 NT ---------- *)

Definition catTy : Category := {|
  Obj := Type@{Set};
  Hom := fun A B => A -> B;
  idn := fun A => (fun x => x);
  comp := fun _ _ _ f g => (fun x => g (f x));
  idL := fun _ _ f => eq_refl;
  idR := fun _ _ f => eq_refl;
  assoc := fun _ _ _ _ f g h => eq_refl
|}.

Record NT {C D} (F G : Functor C D) : Type := mkNT {
  ncomp : forall a, Hom D (FObj F a) (FObj G a);
  nlaw : forall {a b} (f : Hom C a b),
           comp D (FHom F f) (ncomp b) = comp D (ncomp a) (FHom G f)
}.

(* ---------- hom-函子 Hom(a, -) ---------- *)

Definition homFun (C : Category@{Set Set}) (a : Obj C) : Functor C catTy.
Proof.
  refine {| FObj := fun b : Obj C => (Hom C a b : Obj catTy);
            FHom := fun _ _ f => (fun g => comp C g f) |}.
  - intro b. simpl. apply funextd. intro g. apply idR.
  - intros a0 b0 c0 f g. simpl.
    apply funextd. intro h. simpl. apply eq_sym. apply assoc.
Defined.

(* ---------- Yoneda 的两个映射 ---------- *)

(* ψ：取样 x ↦ 自然变换「沿 g 搬运」 *)
Definition yonedaTo (C : Category@{Set Set}) (F : Functor C catTy) (a : Obj C)
  (x : FObj F a) : NT (homFun C a) F.
Proof.
  refine {| ncomp := fun (b : Obj C) =>
    ((fun (g : Hom C a b) => FHom F g x)
       : Hom catTy (FObj (homFun C a) b) (FObj F b)) |}.
  intros b c f. simpl.
  apply funextd. intro g. simpl.
  rewrite (Fcomp F g f). reflexivity.
Defined.

(* φ：自然变换 ↦ 在 id 处取样 *)
Definition yonedaFrom (C : Category@{Set Set}) (F : Functor C catTy) (a : Obj C)
  (X : NT (homFun C a) F) : FObj F a :=
  ncomp X a (idn C a).

(* ---------- 往返 1：φ(ψ(x)) = x —— Fid 白送 ---------- *)

Lemma yoneda_round1 : forall (C : Category@{Set Set}) (F : Functor C catTy)
  (a : Obj C) (x : FObj F a),
  @yonedaFrom C F a (@yonedaTo C F a x) = x.
Proof.
  intros. unfold yonedaFrom. simpl.
  rewrite (Fid F a). reflexivity.
Qed.

(* ---------- 往返 2：ψ(φ(X)) = X —— 自然性在 id 处的特例 ----------
   NT 的 record 相等是异构问题（见 06 章），按分量证：
   对每个 b、每条 g : a → b，ψ(φ X)_b(g) = X_b(g)。 *)
Lemma yoneda_round2_pointwise : forall (C : Category@{Set Set}) (F : Functor C catTy)
  (a : Obj C) (X : NT (homFun C a) F) (b : Obj C) (g : Hom C a b),
  ncomp (@yonedaTo C F a (@yonedaFrom C F a X)) b g = ncomp X b g.
Proof.
  intros C F a X b g. simpl.
  assert (Hnat := nlaw X g).
  assert (Hp := f_equal (fun k : Hom C a a -> FObj F b => k (idn C a)) Hnat).
  simpl in Hp.
  rewrite (idL C g) in Hp.
  symmetry. exact Hp.
Qed.

(* 完整的往返 2（record 级相等）见 Lean 版：结构 η + 内核 PI 把
   分量等式升级为 NT 相等；Coq 无原始投影时止步于分量级。 *)

Print Assumptions yoneda_round1.          (* funextd（homFun/yonedaTo 带来） *)
Print Assumptions yoneda_round2_pointwise. (* 证明本身零新公理：纯自然性（继承 funextd） *)

(* ---------- 可表函子（贺伟 1.6） ----------
   F 可表 ⟺ F ≅ Hom(a, -)（某个 a）。取 F := homFun C a 本身，
   Yoneda 给出 Nat(Hom(a,-), Hom(a,-)) ≅ Hom C a a：
   hom-函子的自变换 = 中对象的自态射——「对象由它的泛态射决定」。 *)
(* ---------- 可表函子（贺伟 1.6） ----------
   F 可表 ⟺ F ≅ Hom(a, -)（某个 a）。取 F := homFun C a 本身，
   Yoneda 给出 Nat(Hom(a,-), Hom(a,-)) ≅ Hom C a a：
   hom-函子的自变换 = 中对象的自态射——「对象由它的泛态射决定」。
   「同构的单位对应 id」在分量层面即 yoneda_round2_pointwise 的
   特例（g := id 时自然性给出 X_a(id) 的不动性）。 *)

(* 坑位速记：
   1. yonedaTo 的 naturality 证明核心是 Fcomp 的反方向使用：
      F(g;f) x = Fg(Ff x)——函子律搬运「采样点」。
   2. yoneda_round2 的关键一招：把 X 的自然性方程（两函数相等）
      用 f_equal 作用到 id_a 上取样，再 idL 换向——教科书里
      「把 g 拆成 g;id」的机器版。
   3. homFun 的宇宙钉死在 Category@{Set Set}：Hom C a b 要当
      catTy 的对象（Set 层）。
   4. NT record 相等异构：往返 2 分量化（Lean 版才完整）——
      与 06 章同一裂缝。 *)
