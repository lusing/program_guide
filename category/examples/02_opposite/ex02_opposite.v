(* ex02 —— 反范畴与对偶原理
   三书对位：贺伟 1.4 前置 /《高级范畴论》1.5（范畴的运算）/ Simmons 2.8

   C^op：同样的对象，箭头全部掉头。复合把顺序倒过来：
   C^op 里 comp f g := C 里的 comp g f。
   于是 C 的 idL 定律变成 C^op 的 idR 定律——
   「对偶原理」的机器版本：每个证明免费获得一个孪生证明。 *)

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

(* ---------- 反范畴构造 ---------- *)

Definition opposite (C : Category) : Category := {|
  Obj := Obj C;
  Hom := fun a b => Hom C b a;          (* 箭头掉头 *)
  idn := fun a => idn C a;
  comp := fun _ _ _ f g => comp C g f;  (* 复合倒序 *)
  idL := fun _ _ f => idR C f;           (* C 的右单位 = C^op 的左单位 *)
  idR := fun _ _ f => idL C f;           (* 反之亦然 *)
  assoc := fun _ _ _ _ f g h => eq_sym (assoc C h g f)
|}.

(* 三条定律的搬运方向（值得逐条对读）：
   - C^op 的 idL 目标：comp_op (idn a) f = f
     展开 = comp C f (idn C a) = f ——恰是 C 的 idR；
   - assoc：C^op 的 (f·g)·h = f·(g·h)
     展开 = C 的 h·(g·f) = (h·g)·f ——assoc C h g f 的对称。 *)

(* op 的 op：字段层面可折叠（Hom 双重翻转还原），但 record 之间
   只有「同构」没有「相等」——范畴论的第一课就在这里。 *)

(* ---------- 例子：预序范畴（瘦范畴） ----------
   预序 (ℕ, ≤) 看成范畴：对象 = nat，Hom a b := Le a b，
   每两个对象之间至多一条态射（瘦范畴）。
   自造 Le（放 Set 层，函数族定律的证明要真归纳）： *)

Inductive Le : nat -> nat -> Set :=
| le_refl : forall n, Le n n
| le_step : forall m n, Le m n -> Le m (S n).

(* le_trans 递归在第二参数：q = le_refl 时直接返回 p。
   索引匹配的坑：Fixpoint match 里分支拿不到「b = n」的约束，
   要用归纳抽象两个索引来定义（Defined 保持透明，定律证明要 simpl） *)
Definition le_trans {a b c} (p : Le a b) (q : Le b c) : Le a c.
Proof.
  revert p. induction q as [n | m n q IH]; intros p0.
  - exact p0.
  - exact (le_step a n (IH p0)).
Defined.

(* 右单位定义成立（le_trans p le_refl = p 是 match 的分支，直接折叠）；
   左单位要归纳——「方向」决定了哪条免费（与加法的方向学同理）。 *)
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
  comp := fun _ _ _ f g => le_trans f g;
  idL := fun _ _ f => le_idL _ _ f;
  idR := fun _ _ f => eq_refl;          (* 免费 *)
  assoc := fun _ _ _ _ f g h => le_assoc _ _ _ _ f g h
|}.

(* 对偶预序：leCat^op 里 Hom_op a b = Le b a——「≥」范畴 *)
Definition geCat : Category := opposite leCat.

(* 具体：leCat 里 3 → 5 有态射，5 → 3 没有；geCat 里恰好反过来 *)
Example le35 : Hom leCat 3 5 := le_step 3 4 (le_step 3 3 (le_refl 3)).
Example ge53 : Hom geCat 5 3 := le_step 3 4 (le_step 3 3 (le_refl 3)).
(* geCat 5→3 = leCat 3→5 的同一棵证明树，方向掉了头 *)

(* ---------- 对偶翻译的实感：FinCat ----------
   FinCat^op 的态射 m → n 就是 FinCat 的函数 fin n → fin m *)
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

(* catFin^op 的 3 → 2 = catFin 的 2 → 3 = fin 2 -> fin 3；
   嵌入 x ↦ Some x 把 fin 2 塞进 fin 3 = option (fin 2) *)
Check (fun x : fin 2 => Some x) : Hom (opposite catFin) 3 2.

(* ---------- 伴随预告 ----------
   「对偶」贯穿全书：mono/epi（03 章）、积/余积（09 章）、
   极限/余极限（11 章）、反射/余反射子范畴（15 章）——
   每个概念证明一次，对偶概念免费获得。 *)

(* 坑位速记：
   1. opposite 的定律搬运要看清展开：comp_op (idn) f = comp C f (idn)
      ——是 idR 不是 idL；写反了 Coq 会在展开处卡住。
   2. 自造 Le 放 Set（不用 nat 的 <=）：Prop 版的 Hom 会把
      范畴拖进证明无关性的讨论，Set 版干净。
   3. le_trans 递归在第二参数 ⇒ idR 定义成立、idL 要归纳
      ——与 typetheory 07 章「加法方向学」同构的现象。
   4. record 之间没有「相等」：op (op C) 只在字段层面还原 C，
      机器里能对齐的是每条投影，不是 record 本身。 *)
