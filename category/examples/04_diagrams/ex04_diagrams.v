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

(* ---------- 图上操练：五角星绕两圈（Simmons 2.1.3） ----------
   五个顶点 0..4 排在圆周上。周长边 p_i : i -> i+1（mod 5），
   星形弦 s_i : i -> i+2（mod 5）。五个三角方程：每个 (i,i+1,i+2)
   三角形交换，即 p_i;p_{i+1} = s_i。
   定理：沿周长绕两圈 = 沿星形绕一圈。
   书中坍缩序列（角标从 1 数）：12345123451 -> 1345123451 ->
   135123451 -> 13523451 -> 1352451 -> 135241，每步塌一个三角。 *)

Section Pentagon.
Variable C : Category.
Variables (v0 v1 v2 v3 v4 : Obj C).
Variables
  (p0 : Hom C v0 v1) (p1 : Hom C v1 v2) (p2 : Hom C v2 v3)
  (p3 : Hom C v3 v4) (p4 : Hom C v4 v0)
  (s0 : Hom C v0 v2) (s1 : Hom C v1 v3) (s2 : Hom C v2 v4)
  (s3 : Hom C v3 v0) (s4 : Hom C v4 v1).
Hypothesis T0 : comp C p0 p1 = s0.   (* 三角 (0,1,2) *)
Hypothesis T1 : comp C p1 p2 = s1.   (* 三角 (1,2,3) *)
Hypothesis T2 : comp C p2 p3 = s2.   (* 三角 (2,3,4) *)
Hypothesis T3 : comp C p3 p4 = s3.   (* 三角 (3,4,0) *)
Hypothesis T4 : comp C p4 p0 = s4.   (* 三角 (4,0,1) *)

(* 沿周长两圈：右嵌套写法 *)
Definition perim2 : Hom C v0 v0 :=
  comp C p0 (comp C p1 (comp C p2 (comp C p3 (comp C p4
    (comp C p0 (comp C p1 (comp C p2 (comp C p3 p4)))))))).

(* 沿星形一圈：0 -> 2 -> 4 -> 1 -> 3 -> 0 *)
Definition star1 : Hom C v0 v0 :=
  comp C s0 (comp C s2 (comp C s4 (comp C s1 s3))).

Theorem pentagram : perim2 = star1.
Proof.
  unfold perim2, star1.
  repeat rewrite <- ?assoc.            (* 先规范到左嵌套 *)
  rewrite T0.                          (* 123 -> 13  *)
  rewrite (assoc C s0 p2 p3), T2.      (* 345 -> 35  *)
  rewrite (assoc C (comp C s0 s2) p4 p0), T4.   (* 512 -> 52  *)
  rewrite (assoc C (comp C (comp C s0 s2) s4) p1 p2), T1.  (* 234 -> 24  *)
  rewrite (assoc C (comp C (comp C (comp C s0 s2) s4) s1) p3 p4), T3.  (* 451 -> 41  *)
  reflexivity.
Qed.

End Pentagon.
