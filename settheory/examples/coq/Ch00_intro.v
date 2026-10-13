(* 第 00 章 导引：Coq 的立场——类型论里的集合论要"嵌入"。

   Coq 与 Lean 同属类型论：x ∈ x 无法成型，全集 V 无法命名。
   要谈 ZFC，要么浅嵌入（一个类型 A + 关系 mem : A -> A -> Prop，
   九公理显式记账），要么深嵌入（一阶语言的语法层）。
   本文件给出类型论里"免费获得"的第一引擎：Cantor 对角线。 *)

(* ---------- 一、核心引理：¬ P ≠ P（直觉主义成立） ---------- *)

(* 这个小引理是 Russell 悖论在命题层的"安全版本"：
   利用相等 transport 搭建自指，再用自指炸毁自己。 *)

Lemma nprp : forall P : Prop, (~ P) <> P.
Proof.
  intros P E.
  (* 双向通道：c 把 ¬P 送进 P，c' 把 P 送回 ¬P *)
  pose (c := fun np => match E in _ = T return T with eq_refl => np end).
  pose (c' := fun p => match (eq_sym E) in _ = T return T with eq_refl => p end).
  (* t : ¬P 自指：t(p) = c'(p)(p) *)
  assert (t : ~ P) by (intro p; exact (c' p p)).
  exact (t (c t)).
Qed.

Print Assumptions nprp.   (* Closed under the global context：零公理 *)

(* ---------- 二、Cantor 定理的类型论版本 ---------- *)

(* 对每个"名单" f : X -> (X -> Prop) 都能显式构造一个逃逸者 g，
   使 g 在每个 x 处都不同于 f x 的对角线值。 *)

Theorem cantor_diagonal :
  forall (X : Type) (f : X -> X -> Prop),
    exists g : X -> Prop, forall x : X, g x <> f x x.
Proof.
  intros X f.
  exists (fun x => ~ f x x).
  intros x.
  apply nprp.
Qed.

Print Assumptions cantor_diagonal.

(* ---------- 三、浅嵌入骨架（01 章填充公理） ---------- *)

Section ShallowEmbedding.

Variable A : Type.
Variable mem : A -> A -> Prop.

(* 外延性：集合由元素决定 *)
Definition Extensional :=
  forall x y : A, (forall u, mem u x <-> mem u y) -> x = y.

(* 观察：外延性在类型论里是关于 mem 的非平凡假设，而不是免费的。
   ZF 的每条公理在类型论里都变成"假设"——这是 01 章的正题。 *)

End ShallowEmbedding.
