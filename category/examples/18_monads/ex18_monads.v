(* ex18 —— 单子：伴随的影子
   三书对位：贺伟 3.5（范畴上的模结构）/ 3.6（Beck 定理）/
   Simmons 5.5。单子 = (T, η, μ)：「代数理论的范畴化身」。

   机器内容：Set 上的单子（元素级定律）+ List 单子完整验证。 *)

Set Implicit Arguments.

Require Import List.

Axiom funext : forall {A B} (f g : A -> B), (forall x, f x = g x) -> f = g.

(* Set 上的单子：T 连函子作用 + 单位 + 乘法，定律按元素给 *)
Record SetMonad : Type := mkMonad {
  T : Set -> Set;
  Tmap : forall {A B : Set}, (A -> B) -> T A -> T B;
  ret : forall {A : Set}, A -> T A;
  join : forall {A : Set}, T (T A) -> T A;
  unitL : forall {A : Set} (x : T A), join (ret x) = x;
  unitR : forall {A : Set} (x : T A), join (Tmap ret x) = x;
  joinAssoc : forall {A : Set} (x : T (T (T A))),
    join (Tmap join x) = join (join x)
}.

(* 上述元素级定律 = 范畴级 η_left/η_right/μ_assoc 的点式展开
   （贺伟 3.5 的自然性按分量内联）。Kleisli 扩展与范畴级的桥梁：
   (a >=> b) x := join (Tmap b (a x))——文档层给出。 *)

(* 辅助引理：concat ∘ map concat = concat ∘ concat
   （注意 concat 的 A 是显式参数——map 里要钉实例） *)
Lemma concat_map_concat : forall (A : Type) (x : list (list (list A))),
  concat (map (concat (A:=A)) x) = concat (concat (A:=list A) x).
Proof.
  induction x as [| ys xss IH]; simpl.
  - reflexivity.
  - rewrite concat_app. rewrite IH. reflexivity.
Qed.

(* List 单子：T := list、ret := [x]、join := concat *)
Definition listM : SetMonad.
Proof.
  refine {| T := list; Tmap := map; ret := fun (_ : Set) x => (x :: nil); join := concat |}.
  - intros A x. destruct x. reflexivity.
    simpl. rewrite app_nil_r. reflexivity.
  - intros A x. induction x; simpl; [reflexivity | rewrite IHx; reflexivity].
  - intros A x. exact (@concat_map_concat A x).
Defined.

Print Assumptions listM.   (* 零公理！元素级归纳即够 *)

(* Maybe 单子（练习骨架，读者补全归纳）：
   T := option、ret := some、join := 连接嵌套 option *)

(* ---------- 文档层 ----------
   1. 范畴级单子 (T, η, μ) 的自然性/结合律 = 上面元素级定律的
      funext 打包；Set 语境下两者等价。
   2. 伴随生成单子（贺伟 3.5 主定理）：F ⊣ G ⟹ T := G∘F，
      η := 单位，μ := GεF——14 章的自由范畴伴随生成「路径单子」
      （T G := 图 G 上所有路的顶点集）。
   3. Kleisli 范畴与 Eilenberg–Moore 范畴；Beck 单子性定理
      （贺伟 3.6）：比较函子创造极限 ⟹ 等价——精细条件需要
      极限的完整机器化，作为教程边界。 *)

(* 坑位速记：
   1. 「对象层单子」写不下 η·Tη（T 作用在态射上）——Set 级
      单子把 Tmap 显式携带，元素级定律最省基础设施。
   2. join 的三条定律都是 list 归纳；concat/map 的化简方向
      simpl 直接走（map id 在 18 章不再出现——join 直接用 concat）。
   3. SetMonad 的 Tmap 字段是依赖类型（{A B} 隐式）——record
      字段的隐式 binder 与 01 章同样的填充规则。 *)
