(* ex03 —— 特殊态射与特殊对象
   三书对位：贺伟 1.4（单态射与满态射）/《高级范畴论》第 2 章 / Simmons 2.2

   mono/epi 用「消去性质」定义，iso 用「双侧逆」定义；
   分裂态射（section/retraction）比 iso 弱；
   抽象证明只用三条定律——这是范畴论「泛性质推理」的第一课。 *)

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

(* ---------- 外延公理入账（Coq 不自带；Lean 核心库自带） ----------
   涉及函数相等的定理用它；章末 Print Assumptions 公示。 *)

Axiom funext : forall {A B} (f g : A -> B), (forall x, f x = g x) -> f = g.

(* ---------- 定义 ---------- *)

(* 单态射：左可消去 *)
Definition Mono (C : Category) (a b : Obj C) (f : Hom C a b) : Type :=
  forall c (g h : Hom C c a), comp C g f = comp C h f -> g = h.

(* 满态射：右可消去 *)
Definition Epi (C : Category) (a b : Obj C) (f : Hom C a b) : Type :=
  forall c (g h : Hom C b c), comp C f g = comp C f h -> g = h.

(* 分裂单态射：有retraction r（f;r = id）——《高级范畴论》2.1 *)
Definition SplitMono (C : Category) (a b : Obj C) (f : Hom C a b) : Type :=
  { r : Hom C b a | comp C f r = idn C a }.

(* 同构：有双侧逆 *)
Definition IsIso (C : Category) (a b : Obj C) (f : Hom C a b) : Type :=
  { g : Hom C b a | comp C f g = idn C a /\ comp C g f = idn C b }.

(* 终对象：每个对象恰有一条到它的态射 *)
Definition Terminal (C : Category) (t : Obj C) : Type :=
  forall a, { f : Hom C a t | forall g, g = f }.

(* 初始对象：恰有一条从它出发的态射 *)
Definition Initial (C : Category) (i : Obj C) : Type :=
  forall a, { f : Hom C i a | forall g, g = f }.

(* ---------- 抽象定理：只用三条定律 ---------- *)

(* 旗舰：分裂单态射必单。整个证明只是 assoc/idL/idR 的重写串，
   在任意范畴成立——不涉及任何元素。 *)
Lemma split_mono_mono : forall (C : Category) (a b : Obj C) (f : Hom C a b),
  SplitMono C a b f -> Mono C a b f.
Proof.
  intros C a b f [r Hr] c g h H.
  rewrite <- (idR C g).        (* g 展成 g;id *)
  rewrite <- Hr.               (* id 展成 f;r *)
  rewrite <- (assoc C g f r).  (* (g;f);r 并成组 *)
  rewrite H.                   (* 用假设换 g 为 h *)
  rewrite (assoc C h f r).     (* 拆组 *)
  rewrite Hr.                  (* f;r 折回 id *)
  apply idR.
Qed.

(* 同构是单态射（取 inv 的一个侧逆即可）与满态射（对偶侧） *)
Lemma iso_mono : forall (C : Category) (a b : Obj C) (f : Hom C a b),
  IsIso C a b f -> Mono C a b f.
Proof.
  intros C a b f [g [H1 H2]] c u v H.
  rewrite <- (idR C u), <- H1, <- (assoc C u f g), H,
              (assoc C v f g), H1. apply idR.
Qed.

Lemma iso_epi : forall (C : Category) (a b : Obj C) (f : Hom C a b),
  IsIso C a b f -> Epi C a b f.
Proof.
  intros C a b f [g [H1 H2]] c u v H.
  rewrite <- (idL C u), <- H2, (assoc C g f u), H,
              <- (assoc C g f v), H2. apply idL.
Qed.

(* 对偶翻译：C 的终对象 = C^op 的初始对象（定义层面直接翻转） *)
Definition opposite (C : Category) : Category := {|
  Obj := Obj C; Hom := fun a b => Hom C b a;
  idn := fun a => idn C a; comp := fun _ _ _ f g => comp C g f;
  idL := fun _ _ f => idR C f; idR := fun _ _ f => idL C f;
  assoc := fun _ _ _ _ f g h => eq_sym (assoc C h g f)
|}.

Lemma terminal_opp : forall (C : Category) (t : Obj C),
  Terminal C t -> Initial (opposite C) t.
Proof. intros C t H a. destruct (H a) as [f Hu]. exists f. exact Hu. Qed.

(* ---------- 具体范畴里的含义：FinCat ---------- *)

Fixpoint fin (n : nat) : Set :=
  match n with
  | O => Empty_set
  | S m => option (fin m)
  end.

Definition catFin : Category := {|
  Obj := nat;
  Hom := fun m n => fin m -> fin n;
  idn := fun _ => (fun x => x);
  comp := fun _ _ _ f g => (fun x => g (f x));
  idL := fun _ _ f => eq_refl;
  idR := fun _ _ f => eq_refl;
  assoc := fun _ _ _ _ f g h => eq_refl
|}.

(* FinCat 里 mono = 单射（要点：把元素 x 看成 1 → m 的常值态射） *)
Lemma mono_fin_inj : forall m n (f : fin m -> fin n),
  Mono catFin m n f -> forall x y, f x = f y -> x = y.
Proof.
  intros m n f Hmono x y Hxy.
  assert (Hg : (fun _ : fin 1 => x) = (fun _ : fin 1 => y)).
  { apply (Hmono 1 (fun _ => x) (fun _ => y)), funext.
    intros z. destruct z; simpl; rewrite Hxy; reflexivity. }
  exact (f_equal (fun k : fin 1 -> fin m => k None) Hg).
Qed.

Lemma inj_fin_mono : forall m n (f : fin m -> fin n),
  (forall x y, f x = f y -> x = y) -> Mono catFin m n f.
Proof.
  intros m n f Hinj c g h H. apply funext. intros z. apply Hinj.
  assert (Hz := f_equal (fun k : fin c -> fin n => k z) H).
  exact Hz.
Qed.

(* FinCat 里满射 ⇒ epi：逆像处比较（f x = z 把 H 拉回原像）。
   反方向（epi ⇒ 满射）构造上要做有限搜索或用经典逻辑——
   在 Set 里它通常等价于选择公理的受限形式，本书作为边界记录。 *)
Lemma surj_fin_epi : forall m n (f : fin m -> fin n),
  (forall y, { x : fin m | f x = y }) -> Epi catFin m n f.
Proof.
  intros m n f Hsurj c g h H. apply funext. intro z.
  destruct (Hsurj z) as [x Hx].
  assert (Hz := f_equal (fun k : fin m -> fin c => k x) H).
  simpl in Hz. rewrite Hx in Hz. exact Hz.
Qed.

(* 终对象 = 1，初始对象 = 0：唯一性靠 funext + 空域/单元值域 *)
Definition finOne_terminal : Terminal catFin 1.
Proof.
  intro a. exists ((fun _ => None) : fin a -> fin 1).
  intros g. apply funext. intro z. destruct (g z) as [e|]; [destruct e | reflexivity].
Qed.

Definition finZero_initial : Initial catFin 0.
Proof.
  intro a. exists (fun x : fin 0 => match (x : Empty_set) return fin a with end).
  intros g. apply funext. intro z. destruct z.
Qed.

(* FinCat 没有零对象（0 ≠ 1 且 fin 0 与 fin 1 不同构）——
   零对象存在于「带点的世界」：catOne 的唯一对象既终又始 *)
Lemma unit_eq2 (u : unit) : tt = u. Proof. destruct u; reflexivity. Qed.

Definition catOne : Category := {|
  Obj := unit; Hom := fun _ _ => unit; idn := fun _ => tt;
  comp := fun _ _ _ _ _ => tt;
  idL := fun _ _ f => unit_eq2 f; idR := fun _ _ f => unit_eq2 f;
  assoc := fun _ _ _ _ _ _ _ => eq_refl
|}.

Definition one_terminal : Terminal catOne tt.
Proof. intro a. exists tt. intros g. symmetry; apply unit_eq2. Qed.

Definition one_initial : Initial catOne tt.
Proof. intro a. exists tt. intros g. symmetry; apply unit_eq2. Qed.

(* ---------- 公理记账 ---------- *)
Print Assumptions split_mono_mono.   (* 零公理（纯定律推理） *)
Print Assumptions iso_epi.           (* 零公理 *)
Print Assumptions mono_fin_inj.      (* funext *)
Print Assumptions finOne_terminal.   (* funext *)
Print Assumptions unit_eq2.          (* 零公理 *)

(* 坑位速记：
   1. mono 定义的方向：comp g f = comp h f → g = h——f 在复合的
      「右侧」（后手）；图序书写的消去律两侧要分清。
   2. 从 H : (fun z => f (g z)) = (fun z => f (h z)) 取「点」要用
      f_equal (fun k => k z) H——直接 H z 不进语法。
   3. FinCat 的终对象唯一性：先 destruct (g z) 再 destruct e——
      Some 分支的 e : Empty_set 自灭，None 分支 rfl。
   4. 函数范畴里「元素即态射」：x : fin m 变成 1 → m 的常值函数，
      mono/epi 的消去性质立刻翻译成单射/满射。
   5. funext 是本章唯一新公理；Lean 里它是核心定理（Quot.sound
      的推论），Coq/Agda 要入账——三文化的分岔点。 *)
