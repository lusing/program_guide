(* ex01 —— 范畴的定义与首批例子
   三书对位：贺伟《范畴论》1.1 /《高级范畴论》1.3 / Simmons 1.1

   范畴 = 对象 + 态射 + 恒等 + 复合 + 三条定律。
   把它写成 Record，就是把数学定义逐字变成类型；
   造一个范畴，就是把这五个字段填满——定律无一可逃。 *)

(* ---------- 定义（宇宙多态：Obj 在 u 层，Hom 在 v 层） ---------- *)

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

(* 复合按「图序」书写：comp f g = 先 f 后 g（Simmons 风格）。
   函数式的 f ∘ g = 先 g 后 f，恰是反范畴视角（见 02 章）。

   坑：字段值必须连同隐式 binder 一起绑定——
   comp 的提供项要写 fun _ _ _ f g => …（5 个 binder）。 *)

(* ---------- 例 1：终范畴 1 —— 一个对象、一条态射 ---------- *)

Lemma unit_eq (u : unit) : tt = u.
Proof. destruct u; reflexivity. Qed.

Definition catOne : Category := {|
  Obj := unit;
  Hom := fun _ _ => unit;
  idn := fun _ => tt;
  comp := fun _ _ _ _ _ => tt;
  idL := fun _ _ f => unit_eq f;      (* tt = f：f 是变量，先把它拆开 *)
  idR := fun _ _ f => unit_eq f;
  assoc := fun _ _ _ _ _ _ _ => eq_refl
|}.

(* ---------- 例 2：幺半群 = 单对象范畴 ----------
   (ℕ, +, 0) 看成只有一个对象 * 的范畴：
   Hom * * := ℕ，恒等 := 0，复合 := 加法。
   定律不再是 reflexivity，而是货真价实的算术定理。 *)

Require Import PeanoNat.

Definition catNat : Category := {|
  Obj := unit;
  Hom := fun _ _ => nat;
  idn := fun _ => 0;
  comp := fun _ _ _ f g => f + g;
  idL := fun _ _ f => Nat.add_0_l f;    (* 0 + f = f *)
  idR := fun _ _ f => Nat.add_0_r f;    (* f + 0 = f：+ 递归在第一参数，要归纳 *)
  assoc := fun _ _ _ _ f g h => eq_sym (Nat.add_assoc f g h)
|}.

(* 在 catNat 里复合两条态射：comp 2 3 = 5，机器可算 *)
Definition five : nat := @comp catNat tt tt tt 2 3.
Example five_ok : five = 5 := eq_refl.

(* ---------- 例 3：FinCat —— 有限集范畴的骨架 ----------
   对象 = 自然数（当作基数），Hom m n := fin m -> fin n。
   「函数当态射」的最小化身，且完全避开宇宙问题。
   本机 coqc 的 stdlib 不含 Coq.Fin，顺手自造（与 typetheory 教程
   手造风格的惯例一致）：
     fin 0 = ∅；fin (S m) = option (fin m)
     None 当 F0（第一个），Some k 当 FS k（往后挪一位）。 *)

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
  idL := fun _ _ f => eq_refl;      (* (fun x => f x) = f：βη 折叠 *)
  idR := fun _ _ f => eq_refl;
  assoc := fun _ _ _ _ f g h => eq_refl
|}.

(* ---------- 例 4：TyCat —— Type 的范畴（「Set 的化身」） ----------
   对象 = Type，态射 = 函数。宇宙多态在此发挥作用：
   Obj 落在 Set+1 层，Hom 落在 Set 层。 *)

Definition catTy : Category :=  {|
  Obj := Type@{Set};
  Hom := fun A B => A -> B;
  idn := fun A => (fun x => x);
  comp := fun _ _ _ f g => (fun x => g (f x));
  idL := fun _ _ f => eq_refl;
  idR := fun _ _ f => eq_refl;
  assoc := fun _ _ _ _ f g h => eq_refl
|}.

(* 在 catTy 里做一个具体态射 *)
Definition isEven : nat -> bool := fun n => Nat.even n.
Definition negate : bool -> bool := fun b => negb b.
Definition composed : nat -> bool := @comp catTy nat bool bool isEven negate.
Example composed_ok : composed 3 = true := eq_refl.   (* even 3 = false，再取反 *)

(* ---------- 预告：把范畴本身当对象 ----------
   同构的范畴看起来不同、行为相同。从 02 章起，范畴成为新范畴的
   对象：反范畴 C^op、函子范畴 [C,D]——「范畴论研究范畴」。 *)

(* 坑位速记：
   1. Record 的宇宙注解 @{u v} 不可省——catTy 要求 Obj := Type@{Set}
      而 record 本体住在 Set+1；单态 record 会把宇宙冻结在声明处。
   2. 字段值里隐式 binder 也要绑定：comp 要 5 个、assoc 要 7 个
      下划线（Coq 按类型逐 binder 检查提供项）。
   3. comp 投影的隐式 {a b c} 在 Obj := unit 时无法从 f g 推出，
      要用 @comp catNat tt tt tt 显式给全。
   4. Coq 定义相等含 β 与 η（函数），故函数族的 idL/idR/assoc 全是
      eq_refl——「函数范畴的定律免费」的机器版本。
   5. 幺半群范畴的 idR（f + 0 = f）不是 rfl：加法递归在第一参数。 *)
