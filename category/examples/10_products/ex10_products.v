(* ex09 —— 积与余积
   三书对位：贺伟 2.3（积和余积）/《高级范畴论》3.2 / Simmons 2.5
   （Products and coproducts）

   积的泛性质：p 到 a、b 各有投影，任何「双出」对象 c 恰好一条
   中介态射。两条主线：
   1. TyCat 里积 = 笛卡尔积（funext + 配对法则）；
   2. 抽象定理：积由泛性质唯一（到同构）——只用唯一性推，不看元素。 *)

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

(* ---------- 泛性质（存在 + 唯一） ---------- *)

Definition opposite (C : Category) : Category := {|
  Obj := Obj C; Hom := fun a b => Hom C b a;
  idn := fun a => idn C a; comp := fun _ _ _ f g => comp C g f;
  idL := fun _ _ f => idR C f; idR := fun _ _ f => idL C f;
  assoc := fun _ _ _ _ f g h => eq_sym (assoc C h g f)
|}.

Definition IsProduct (C : Category) (a b p : Obj C)
  (p1 : Hom C p a) (p2 : Hom C p b) : Type :=
  forall c (f : Hom C c a) (g : Hom C c b),
    { h : Hom C c p |
        comp C h p1 = f /\ comp C h p2 = g /\
        forall h' (e1 : comp C h' p1 = f) (e2 : comp C h' p2 = g), h' = h }.

Definition IsCoproduct (C : Category) (a b q : Obj C)
  (i1 : Hom C a q) (i2 : Hom C b q) : Type :=
  IsProduct (opposite C) b a q i2 i1.
(* 余积 = 反范畴里的积——02 章的对偶一行兑现（注意对象次序掉头） *)

(* ---------- TyCat 里：积 = 笛卡尔积 ---------- *)

Definition catTy : Category := {|
  Obj := Type@{Set};
  Hom := fun A B => A -> B;
  idn := fun A => (fun x => x);
  comp := fun _ _ _ f g => (fun x => g (f x));
  idL := fun _ _ f => eq_refl;
  idR := fun _ _ f => eq_refl;
  assoc := fun _ _ _ _ f g h => eq_refl
|}.

(* 配对的中介函数：h x = (f x, g x)；唯一性靠满配对 + funext *)
Lemma prod_unique : forall (A B C0 : Type)
  (h' : C0 -> A * B) (f : C0 -> A) (g : C0 -> B),
  (fun x => fst (h' x)) = f -> (fun x => snd (h' x)) = g ->
  h' = fun x => (f x, g x).
Proof.
  intros A B C0 h' f g H1 H2. apply funext. intro x.
  assert (Hx1 : fst (h' x) = f x) by exact (f_equal (fun k : C0 -> A => k x) H1).
  assert (Hx2 : snd (h' x) = g x) by exact (f_equal (fun k : C0 -> B => k x) H2).
  rewrite <- Hx1, <- Hx2. destruct (h' x); reflexivity.
Qed.

Definition tyProduct : forall (A B : Type@{Set}),
  IsProduct catTy A B ((prod A B) : Obj catTy) fst snd.
Proof.
  intros A B c f g. exists (fun x => (f x, g x)).
  split; [reflexivity | split; [reflexivity | ]].
  intros h' e1 e2. apply prod_unique; assumption.
Defined.

(* ---------- 抽象定理：积唯一到同构 ----------
   两个积 (P,π1,π2) 与 (Q,q1,q2)：中介 h : P→Q、k : Q→P，
   则 h;k 与 id 都满足「Q 自己的双出」，唯一性逼出 h;k = id。 *)

Record IsoArrow (C : Category) (a b : Obj C) (f : Hom C a b) : Type := mkIA {
  iinv : Hom C b a;
  ilaw1 : comp C f iinv = idn C a;
  ilaw2 : comp C iinv f = idn C b
}.

Lemma product_unique_iso : forall (C : Category) (a b P Q : Obj C)
  (p1 : Hom C P a) (p2 : Hom C P b)
  (q1 : Hom C Q a) (q2 : Hom C Q b),
  IsProduct C a b P p1 p2 ->
  IsProduct C a b Q q1 q2 ->
  { f : Hom C P Q & IsoArrow C P Q f }.
Proof.
  intros C a b P Q p1 p2 q1 q2 HP HQ.
  (* 两个方向的中介：k : P→Q（喂 Q 的泛性质）、h : Q→P *)
  destruct (HQ P p1 p2) as [k [k1 [k2 _]]].
  destruct (HP Q q1 q2) as [h [h1 [h2 _]]].
  exists k.
  (* k;h : P→P 与 id_P 都满足 P 自己的双出，唯一性逼相等 *)
  destruct (HP P p1 p2) as [n [n1 [n2 nuniq]]].
  assert (Hkh : comp C k h = n).
  { apply nuniq.
    - rewrite (assoc C k h p1), h1. exact k1.
    - rewrite (assoc C k h p2), h2. exact k2. }
  assert (HidP : idn C P = n).
  { apply nuniq; [apply idL | apply idL]. }
  (* h;k : Q→Q 同理 *)
  destruct (HQ Q q1 q2) as [m [m1 [m2 muniq]]].
  assert (Hhk : comp C h k = m).
  { apply muniq.
    - rewrite (assoc C h k q1), k1. exact h1.
    - rewrite (assoc C h k q2), k2. exact h2. }
  assert (HidQ : idn C Q = m).
  { apply muniq; [apply idL | apply idL]. }
  refine (mkIA C P Q k h _ _).
  - rewrite HidP. exact Hkh.      (* k;h = id_P *)
  - rewrite HidQ. exact Hhk.      (* h;k = id_Q *)
Qed.

Print Assumptions product_unique_iso.   (* 零公理：纯泛性质推理 *)
Print Assumptions tyProduct.            (* funext *)

(* 坑位速记：
   1. prod_unique 的 Coq 满配对：destruct (h' x) 后 simpl in *，
      两条假设变成 u = f x / v = g x——rewrite <- 两个方向收口。
   2. product_unique_iso 的骨架：对每个泛性质「取样两次」
      （m/n 的存在性），再把 h;k 与 id 都喂给同一个唯一性——
      这是「泛性质自动给同构」的标准机器套路。
   3. IsCoproduct 用 opposite 一行定义，注意对象次序：
      C^op 的 Hom a b = C 的 b→a，所以 (q2, q1) 对掉。 *)
