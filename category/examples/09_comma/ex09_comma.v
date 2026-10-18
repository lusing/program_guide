(* ex09 —— 逗号范畴（Simmons 3.3.4）
   三书对位：Simmons 3.3.10-3.3.12 /《高级范畴论》2.3 / 贺伟 2.2。

   (U ↓ L)：平行函子 C --U--> A <--L-- B 的逗号范畴。
   本文件在 leCat（03 章的预序范畴）上实例化 (Id ↓ K_1)：
   U := Id，B := 终范畴，L := 常值在 1 的 K_1。
   对象类型定义地化简为主下截面 ↓1 = {x | x ≤ 1}。 *)

(* ---------- 最小基建：范畴 + leCat + catOne（03 章同款） ---------- *)

Record Category : Type := mkCat {
  Obj : Type;
  Hom : Obj -> Obj -> Set;
  idn : forall a, Hom a a;
  comp : forall {a b c}, Hom a b -> Hom b c -> Hom a c;
  idL : forall {a b} (f : Hom a b), comp (idn a) f = f;
  idR : forall {a b} (f : Hom a b), comp f (idn b) = f;
  assoc : forall {a b c d} (f : Hom a b) (g : Hom b c) (h : Hom c d),
            comp (comp f g) h = comp f (comp g h)
}.

Inductive Le : nat -> nat -> Set :=
| le_refl : forall n, Le n n
| le_step : forall m n, Le m n -> Le m (S n)
.

Definition le_trans {a b c} (p : Le a b) (q : Le b c) : Le a c.
Proof.
  revert p. induction q as [n | m n q IH]; intros p0.
  - exact p0.
  - exact (le_step a n (IH p0)).
Defined.

Lemma le_idR : forall a b (f : Le a b), le_trans f (le_refl b) = f.
Proof. intros. destruct f; reflexivity. Qed.

Lemma le_idL : forall a b (f : Le a b), le_trans (le_refl a) f = f.
Proof.
  induction f as [n | m n f IH]; simpl.
  - reflexivity.
  - rewrite IH. reflexivity.
Qed.

Lemma le_assoc : forall a b c d (f : Le a b) (g : Le b c) (h : Le c d),
  le_trans (le_trans f g) h = le_trans f (le_trans g h).
Proof.
  induction h as [n | c d h IH]; simpl.
  - reflexivity.
  - rewrite IH. reflexivity.
Qed.

Definition leCat : Category := {|
  Obj := nat;
  Hom := fun a b => Le a b;
  idn := fun a => le_refl a;
  comp := fun a b c f g => le_trans f g;
  idL := le_idL; idR := le_idR; assoc := le_assoc
|}.

Lemma unit_eq (u : unit) : tt = u. Proof. destruct u; reflexivity. Qed.

Definition catOne : Category := {|
  Obj := unit;
  Hom := fun _ _ => unit;
  idn := fun _ => tt;
  comp := fun _ _ _ _ _ => tt;
  idL := fun _ _ f => unit_eq f;
  idR := fun _ _ f => unit_eq f;
  assoc := fun _ _ _ _ _ _ _ => eq_refl
|}.

(* ---------- 逗号范畴 (Id_leCat ↓ K_1)，K_1 := catOne -> leCat 常值 1 ---------- *)

Record CommaObj : Type := mkCommaObj {
  cobj : nat;                    (* C 侧对象 *)
  cbob : unit;                   (* B 侧对象：终范畴的哑元 *)
  carr : Le cobj 1               (* α : Id c -> K_1 b = 1 *)
}.

Record CommaArr (o1 o2 : CommaObj) : Type := mkCommaArr {
  ucomp : Le (cobj o1) (cobj o2);          (* u : C 侧箭头 *)
  vcomp : tt = tt;                         (* v : B 侧箭头，被终范畴抹平 *)
  (* 交换方块：α′ ∘ u = (K v) ∘ α，K v = id，于是即
     le_trans u (carr o2) = le_trans (carr o1) (le_refl 1) *)
  square : le_trans ucomp (carr o2) =
           le_trans (carr o1) (le_refl 1)
}.

(* 复合按分量：外圈交换 = assoc 的一次重组（Simmons 3.3.10） *)
Definition commaComp {x y z} (f : CommaArr x y) (g : CommaArr y z)
  : CommaArr x z.
Proof.
  destruct f as [u1 v1 sq1]. destruct g as [u2 v2 sq2].
  refine (mkCommaArr x z (le_trans u1 u2) eq_refl _).
  simpl in *.
  rewrite le_assoc, sq2, sq1. reflexivity.
Defined.

(* ---------- 对象 = 主下截面 ↓1：对应是定义性的 ---------- *)

Definition SectionDown1 : Type := {x : nat & Le x 1}.

Definition toSection (o : CommaObj) : SectionDown1 :=
  existT _ (cobj o) (carr o).

Definition fromSection (s : SectionDown1) : CommaObj :=
  mkCommaObj (projT1 s) tt (projT2 s).

(* 哑元被扔掉：往返（截面方向）是 rfl 级恒等 *)
Lemma round_section : forall s, toSection (fromSection s) = s.
Proof. destruct s as [x a]. reflexivity. Qed.

(* 反方向差一个哑元：分量级相等，record 级不等——03 章的老裂缝。 *)
Lemma round_comma_component : forall o,
  cobj (fromSection (toSection o)) = cobj o /\ carr (fromSection (toSection o)) = carr o.
Proof. destruct o. split; reflexivity. Qed.

(* 两个具体的截面元素：0 ≤ 1 与 1 ≤ 1 *)
Definition sec0 : SectionDown1 := existT _ 0 (le_step _ _ (le_refl 0)).
Definition sec1 : SectionDown1 := existT _ 1 (le_refl 1).

Example sec0_arr : cobj (fromSection sec0) = 0 := eq_refl.
