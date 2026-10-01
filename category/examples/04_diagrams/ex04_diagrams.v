(* ex04 —— 图与交换图
   三书对位：《高级范畴论》1.2（图、图同态）/ Simmons 2.1（diagram chasing）

   图 = 点 + 边 + 两个端点函数；路 = 图上的自由范畴态射；
   「交换图」= 一组方程：f;h = g;k。
   抽象范畴里的图表推理只用三条定律——这是全书证明风格的缩影。 *)

(* ---------- 图 ---------- *)

Record Graph : Type := mkGraph {
  V : Type;
  E : Type;
  src : E -> V;
  tgt : E -> V
}.

(* 图同态：点映射 + 边映射，保端点——两条「小交换图」方程 *)
Record GraphHom (G H : Graph) : Type := mkGH {
  vmap : V G -> V H;
  emap : E G -> E H;
  sq_src : forall e, vmap (src G e) = src H (emap e);
  sq_tgt : forall e, vmap (tgt G e) = tgt H (emap e)
}.

(* ---------- 路：图上的自由范畴 ---------- *)

Inductive Path (G : Graph) : V G -> V G -> Type :=
| pid : forall v, Path G v v
| pcat : forall (e : E G) (w : V G), Path G (tgt G e) w -> Path G (src G e) w.

(* 复合：递归在第一条路。索引 match 拿不到分支约束，用归纳式定义
   （Defined 保持透明，定律证明要 simpl） *)
Definition papp {G u v w} (p : Path G u v) (q : Path G v w) : Path G u w.
Proof.
  revert q. induction p as [v0 | e w0 p IH]; intros q.
  - exact q.
  - exact (pcat G e _ (IH q)).
Defined.

Lemma papp_idR : forall (G : Graph) (u v : V G) (p : Path G u v),
  papp p (pid G v) = p.
Proof.
  intros G u v p. induction p as [v0 | e w0 p IH]; simpl.
  - reflexivity.
  - rewrite IH. reflexivity.
Qed.

Lemma papp_assoc : forall (G : Graph) (u v w x : V G)
  (p : Path G u v) (q : Path G v w) (r : Path G w x),
  papp (papp p q) r = papp p (papp q r).
Proof.
  intros G u v w x p q r. induction p as [v0 | e w0 p IH]; simpl.
  - reflexivity.
  - rewrite IH. reflexivity.
Qed.

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

(* 任意图生成自由范畴：对象=点、态射=路、复合=拼接 *)
Definition freeCat (G : Graph) : Category := {|
  Obj := V G;
  Hom := fun a b => Path G a b;
  idn := fun v => pid G v;
  comp := fun _ _ _ p q => papp p q;
  idL := fun _ _ q => eq_refl;                     (* papp (pid) q 直接折叠 *)
  idR := fun _ _ p => papp_idR G _ _ p;
  assoc := fun _ _ _ _ p q r => papp_assoc G _ _ _ _ p q r
|}.

(* ---------- 一个具体的小图 ---------- *)

Definition gArrow : Graph := {|
  V := bool;
  E := unit;
  src := fun _ => true;
  tgt := fun _ => false
|}.

(* true → false 的路只有一条：直接走边（plen 可算） *)
Fixpoint plen {G u v} (p : Path G u v) : nat :=
  match p with
  | pid _ _ => 0
  | pcat _ _ _ p' => S (plen p')
  end.

Example pDirect2 : Path gArrow true false :=
  pcat gArrow tt false (pid gArrow false).
Example plen_direct : plen pDirect2 = 1 := eq_refl.

(* 交换图 = 方程组：图同态的两条端点方程就是最小的例证（上文 sq_src/sq_tgt）。

   抽象定律版：只用 assoc/idL/idR 推图 *)
Lemma laws_only : forall (C : Category) (a b c : Obj C)
  (f : Hom C a b) (g : Hom C b c),
  comp C (comp C f (idn C b)) g = comp C f g.
Proof. intros. rewrite (idR C f). reflexivity. Qed.

(* ---------- TyCat 里的交换方块 ---------- *)

Require Import Lia.

Axiom funext : forall {A B} (f g : A -> B), (forall x, f x = g x) -> f = g.

Definition catTy : Category := {|
  Obj := Type@{Set};
  Hom := fun A B => A -> B;
  idn := fun A => (fun x => x);
  comp := fun _ _ _ f g => (fun x => g (f x));
  idL := fun _ _ f => eq_refl;
  idR := fun _ _ f => eq_refl;
  assoc := fun _ _ _ _ f g h => eq_refl
|}.

(* 退化方格：恒等边——两边 βη 折叠成同一函数，reflexivity 白送 *)
Example square_refl :
  comp catTy (fun x => x) (fun n => 2 * n)
  = comp catTy (fun n => 2 * n) (fun x => x) := eq_refl.

(* 真方格：succ;double = double;(+2)，逐点 2*(S n) = 2n+2
   ——定义相等白送不了，funext + lia 上场 *)
Example square_commutes :
  comp catTy (fun n => S n) (fun n => 2 * n)
  = comp catTy (fun n => 2 * n) (fun n => n + 2).
Proof.
  apply funext. intro n. simpl. lia.
Qed.

(* 坑位速记：
   1. 索引归纳族（Path/Le）的复合递归定义要用「revert + induction +
      Defined」——Fixpoint match 拿不到分支的索引约束。
   2. 定律证明里 simpl 前确保定义是 Defined（Qed 会挡 delta）。
   3. 交换图验证的两层：退化情形 reflexivity；一般情形
      funext + 算术（lia/omega）——「交换 = 逐点方程」的机器形态。
   4. GraphHom 的两条保端点方程就是最小的「图同态交换图」。 *)
