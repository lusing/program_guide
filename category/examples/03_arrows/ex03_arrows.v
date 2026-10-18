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

(* ---------- 分裂满态射 + 消去律封闭（Simmons 2.2.1 / 2.2.4） ---------- *)

(* 分裂满态射：有 section s（s;f = id） *)
Definition SplitEpi (C : Category) (a b : Obj C) (f : Hom C a b) : Type :=
  { s : Hom C b a | comp C s f = idn C b }.

(* 2.2.1(a)：section 若还是 epi，自动补出另一侧逆——成 iso。
   全程只用 idL/idR/assoc/Epi 的定义，零公理。 *)
Lemma section_epi_iso : forall (C : Category) (a b : Obj C) (s : Hom C b a),
  Epi C b a s -> forall r : Hom C a b,
  comp C s r = idn C b -> IsIso C b a s.
Proof.
  intros C a b s Hepi r Hsr.
  exists r. split.
  - exact Hsr.
  - apply (Hepi a (comp C r s) (idn C a)).
    rewrite <- (assoc C s r s), Hsr, idL, idR. reflexivity.
Qed.

(* 2.2.4 封闭八律（一半由对偶免费，这里全写） *)
Lemma mono_comp : forall C a b c (f : Hom C a b) (g : Hom C b c),
  Mono C a b f -> Mono C b c g -> Mono C a c (comp C f g).
Proof.
  intros C a b c f g Hf Hg d h1 h2 H.
  rewrite <- !assoc in H.
  exact (Hf d h1 h2 (Hg d (comp C h1 f) (comp C h2 f) H)).
Qed.

Lemma mono_of_comp : forall C a b c (f : Hom C a b) (g : Hom C b c),
  Mono C a c (comp C f g) -> Mono C a b f.
Proof.
  intros C a b c f g H d h1 h2 Hf1.
  apply (H d h1 h2). rewrite <- !assoc, Hf1. reflexivity.
Qed.

Lemma epi_comp : forall C a b c (f : Hom C a b) (g : Hom C b c),
  Epi C a b f -> Epi C b c g -> Epi C a c (comp C f g).
Proof.
  intros C a b c f g Hf Hg d h1 h2 H.
  rewrite !assoc in H.
  exact (Hg d h1 h2 (Hf d (comp C g h1) (comp C g h2) H)).
Qed.

Lemma epi_of_comp : forall C a b c (f : Hom C a b) (g : Hom C b c),
  Epi C a c (comp C f g) -> Epi C b c g.
Proof.
  intros C a b c f g H d h1 h2 Hg1.
  apply (H d h1 h2). rewrite !assoc, Hg1. reflexivity.
Qed.

(* ---------- 双消去（Simmons 2.2.10 的抽象内核） ----------
   e 单、m 满（按 mono/epi 定义）时：m ∘ u ∘ e = m ∘ v ∘ e ⟹ u = v。
   书里的五格图（2.2.10）正是这条的图上特例。 *)
Lemma mono_epi_cancel : forall (C : Category) (A B X Y : Obj C)
  (e : Hom C A B) (u v : Hom C B X) (m : Hom C X Y),
  Epi C A B e -> Mono C X Y m ->
  comp C (comp C e u) m = comp C (comp C e v) m -> u = v.
Proof.
  intros C A B X Y e u v m He Hm H.
  rewrite !assoc in H.
  exact (Hm B u v (He Y (comp C u m) (comp C v m) H)).
Qed.

(* ---------- 平衡范畴的最小反例（Simmons 2.2.2） ----------
   瘦范畴（每对对象至多一条箭头）里平行箭头恒相等 ⟹
   一切箭头既 mono 又 epi；行走箭头 0->1 没有反向箭头，
   不是 iso——catTwo 不平衡。预序版：balanced ⟺ 离散。 *)

Definition twoLegal : bool -> bool -> bool := fun a b => orb (negb a) b.
Definition twoHom : bool -> bool -> Set :=
  fun a b => if twoLegal a b then unit else Empty_set.

Definition twoIdn (a : bool) : twoHom a a :=
  match a as x return twoHom x x with false => tt | true => tt end.

Definition twoComp {a b c} (f : twoHom a b) (g : twoHom b c) : twoHom a c.
Proof.
  destruct a, b, c; simpl; try exact tt;
  destruct f; destruct g; simpl; exact tt.
Defined.

Lemma two_idL : forall a b (f : twoHom a b), twoComp (twoIdn a) f = f.
Proof. intros a b f; destruct a, b, f; reflexivity. Qed.
Lemma two_idR : forall a b (f : twoHom a b), twoComp f (twoIdn b) = f.
Proof. intros a b f; destruct a, b, f; reflexivity. Qed.
Lemma two_assoc : forall a b c d (f : twoHom a b) (g : twoHom b c) (h : twoHom c d),
  twoComp (twoComp f g) h = twoComp f (twoComp g h).
Proof. intros; destruct a, b, c, d, f, g, h; reflexivity. Qed.

Definition catTwo : Category := {|
  Obj := bool;
  Hom := fun a b => twoHom a b;
  idn := twoIdn;
  comp := fun a b c f g => twoComp f g;
  idL := two_idL; idR := two_idR; assoc := two_assoc
|}.

Lemma thin_mono : forall a b (f : twoHom a b), Mono catTwo a b f.
Proof.
  intros a b f c g h _.
  destruct c, a; cbn in g, h; try destruct g; try destruct h; reflexivity.
Qed.

Lemma thin_epi : forall a b (f : twoHom a b), Epi catTwo a b f.
Proof.
  intros a b f c g h _.
  destruct c, b; cbn in g, h; try destruct g; try destruct h; reflexivity.
Qed.

Definition twoArr : twoHom false true := tt.

Lemma arr_not_iso : IsIso catTwo false true twoArr -> False.
Proof.
  intros [g _].
  change (twoHom true false) with Empty_set in g.
  destruct g.
Qed.


Print Assumptions section_epi_iso.
Print Assumptions mono_epi_cancel.
Print Assumptions thin_mono.

(* ---------- 例 2.6 反例范畴：一条箭头上的全属性（高级范畴论 2.4） ----------
   范畴 Ob = {A, B}、Mor = {1A, 1B, f}（f : A -> B，别无其他）。
   瘦范畴编码（02 章 catTwo 同款）：bool 对象 + 合法性函数。
   平行对在源端只有恒等、在靶端也只有恒等——一切消去律
   空真/平凡：f 同时是 mono、epi、常态射、余常态射、零态射，
   却不对应任何集合论行为（A、B 可取任意集合，f 不必单/满）。 *)

Definition legal26 : bool -> bool -> bool :=
  fun x y => orb (negb x) y.        (* A:=false, B:=true；A->B 合法，B->A 非法 *)

Definition H26 : bool -> bool -> Set :=
  fun x y => if legal26 x y then unit else Empty_set.

Definition f26 : H26 false true := tt.

Definition comp26 {x y z} (k : H26 x y) (h : H26 y z) : H26 x z.
Proof.
  destruct x, y, z; simpl; try exact tt;
  destruct k; destruct h; simpl; exact tt.
Defined.

(* f 是单态射：左可消去 *)
Lemma f26_mono : forall c (g h : H26 c false),
  comp26 g f26 = comp26 h f26 -> g = h.
Proof.
  intros c g h _; destruct c; cbn in *; try destruct g, h; reflexivity.
Qed.

(* f 是满态射：右可消去 *)
Lemma f26_epi : forall c (g h : H26 true c),
  comp26 f26 g = comp26 f26 h -> g = h.
Proof.
  intros c g h _; destruct c; cbn in *; try destruct g, h; reflexivity.
Qed.

(* f 是常态射：吸收一切到达 A 的平行对（高级范畴论 2.4.1） *)
Lemma f26_normal : forall c (g h : H26 c false),
  comp26 g f26 = comp26 h f26.
Proof.
  intros c g h; destruct c; cbn in *; try destruct g, h; reflexivity.
Qed.

(* f 是余常态射 *)
Lemma f26_conormal : forall c (g h : H26 true c),
  comp26 f26 g = comp26 f26 h.
Proof.
  intros c g h; destruct c; cbn in *; try destruct g, h; reflexivity.
Qed.

Print Assumptions f26_normal.
