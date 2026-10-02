(* ex14 —— 自由与遗忘：图上自由范畴的伴随
   三书对位：Simmons 5.5（Free and cofree）/ 贺伟 3.1 例 /
   《高级范畴论》5.2（泛映射）

   自由构造的样板：freeCat : Graph → Cat 左伴随遗忘函子 U。
   单位 = 把图的边嵌成单边路；泛性质 = 任何图同态 G → U(C)
   唯一延拓成函子 freeCat(G) → C。全章复用 04 章的 Path 机器。 *)

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

Record Graph : Type := mkGraph {
  V : Type; E : Type; src : E -> V; tgt : E -> V
}.

Inductive Path (G : Graph) : V G -> V G -> Type :=
| pid : forall v, Path G v v
| pcat : forall (e : E G) (w : V G), Path G (tgt G e) w -> Path G (src G e) w.

(* 拼接：递归第一条路（revert+induction+Defined 的 04 章配方） *)
Definition papp {G u v w} (p : Path G u v) (q : Path G v w) : Path G u w.
Proof.
  revert q. induction p as [v0 | e w0 p IH]; intros q.
  - exact q.
  - exact (@pcat G e _ (IH q)).
Defined.

Lemma papp_idR : forall (G : Graph) (u v : V G) (p : Path G u v),
  papp p (@pid G v) = p.
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

Definition freeCat (G : Graph) : Category := {|
  Obj := V G;
  Hom := fun a b => Path G a b;
  idn := fun v => @pid G v;
  comp := fun _ _ _ p q => papp p q;
  idL := fun _ _ q => eq_refl;
  idR := fun _ _ p => @papp_idR G _ _ p;
  assoc := fun _ _ _ _ p q r => @papp_assoc G _ _ _ _ p q r
|}.

(* ---------- 单位：边 ↦ 单边路；泛性质：延拓 ---------- *)

(* ---------- 单位与泛性质：图到范畴的映射 ---------- *)

(* 图映射：顶点映射 + 每条边一条态射——端点方程按类型免费
   （对比 04 章 GraphHom 的保端点方程：那里目标是图，这里目标
   是范畴，边直接落在 Hom C (vm src) (vm tgt) 里） *)
Record GraphMap (G : Graph) (C : Category) : Type := mkGM {
  vm : V G -> Obj C;
  em : forall e : E G, Hom C (vm (src G e)) (vm (tgt G e))
}.

(* 单位 η_G 的边映射：e ↦ 单边路（顶点不动） *)
Definition unitGM (G : Graph) : GraphMap G (freeCat G) := {|
  vm := fun (v : V G) => (v : Obj (freeCat G));
  em := fun e => @pcat G e (tgt G e) (@pid G (tgt G e))
|}.

(* 泛性质：任何 GraphMap 唯一延拓成函子 freeCat G → C
   ——「自由」的机器含义。对象部分照 vm，路径部分按边复合。 *)
Definition extendPath (G : Graph) (C : Category)
  (m : GraphMap G C) : forall {u v : V G}, Path G u v
  -> Hom C (vm m u) (vm m v).
Proof.
  intros u v p. induction p as [v0 | e w IH IHIh]; simpl.
  - apply idn.
  - exact (comp C (em m e) IHIh).
Defined.

(* 延拓保复合 ⟺ 延拓函子的 Fcomp 律 *)
Lemma extend_comp : forall (G : Graph) (C : Category)
  (m : GraphMap G C) (u v w : V G)
  (p : Path G u v) (q : Path G v w),
  @extendPath G C m _ _ (@papp G u v w p q)
  = comp C (@extendPath G C m _ _ p) (@extendPath G C m _ _ q).
Proof.
  intros G C m u v w p q. induction p as [v0 | e w0 p IH]; simpl.
  - rewrite (idL C (@extendPath G C m _ _ q)). reflexivity.
  - rewrite IH. symmetry. apply assoc.
Qed.

(* 延拓保恒等按定义成立（pid 分支就是 idn）——两条合起来即
   freeCat ⊣ U 在态射层的完整泛性质；唯一性由「路径由边决定」
   的结构归纳给出（同型引理已在 04 章 plen/papp 系列演练）。 *)
Print Assumptions extend_comp.   (* 零公理：纯复合搬运 *)

(* 坑位速记：
   1. GraphMap 的端点方程在类型里（em 直接落在 Hom C (vm s) (vm t)）
      ——对比 04 章 GraphHom（目标是图，方程要命题给出）；
      目标是范畴时依赖类型让运输消失。
   2. 索引族递归定义走 induction 式 + Defined（02 章配方）；
      as-模式第四个名字是「函数应用的递归假设」IHIh。
   3. 延拓函子律：Fid 按 pid 分支定义成立；Fcomp 即 extend_comp。
   4. 完整 Functor record 打包（FObj/FHom/Fid/Fcomp 四字段填充）
      与本引理同型，留作练习/文档。 *)
