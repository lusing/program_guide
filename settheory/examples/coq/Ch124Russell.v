(* 第 124 章 Coq：罗素悖论的两种机器形态。

   1. 把朴素概括原则当作公理喂给 Coq，Coq 替我们证明：它导出矛盾。
      这正是"悖论"的正确身份——一条关于朴素集合论的不可能性定理。
   2. 把分离公理（概括的限制版）当作公理，罗素推理变成一条建设性
      定理：任何集合 X 都有一个子集不属于 X（书 1.3 的论证）。 *)

(* 尝试把罗素类直接写成项会怎样？
   Definition R (x : Prop) := ~ x x.
   这一行无法通过类型检查：x : Prop 不是函数，x x 非良型。
   罗素类在类型论里根本写不出来——自指被类型系统先天挡在门外。 *)

(* ---------- 1. 朴素概括不一致定理 ---------- *)

Parameter set : Type.
Parameter mem : set -> set -> Prop.

(* 朴素概括原则：任何性质都有全集上的代表集合 *)
Axiom comprehension : forall P : set -> Prop,
  exists X : set, forall y : set, mem y X <-> P y.

Theorem naive_inconsistent : False.
Proof.
  destruct (comprehension (fun x => ~ mem x x)) as [R HR].
  specialize (HR R).                    (* mem R R <-> ~ mem R R *)
  tauto.
Qed.

(* ---------- 2. 分离版：罗素推理成为定理 ---------- *)

(* 分离公理：性质只能从已有的集合中"分离"出子集 *)
Axiom separation : forall (P : set -> Prop) (X : set),
  exists Y : set, forall y : set, mem y Y <-> (mem y X /\ P y).

(* 对任意集合 X，存在 Y ⊆ X 使得 Y ∉ X。
   ——"所有集合的集合"因此不存在（书 1.3.7 习题的前半）。 *)
Theorem russell_relative : forall X : set,
  exists Y : set, (forall y : set, mem y Y -> mem y X) /\ ~ mem Y X.
Proof.
  intros X.
  destruct (separation (fun x => ~ mem x x) X) as [Y HY].
  exists Y. split.
  - intros y Hy. apply HY in Hy. destruct Hy as [Hxy _]. exact Hxy.
  - intro HM.                           (* HM : mem Y X，反设 Y ∈ X *)
    destruct (HY Y) as [Hf Hb].         (* Hf : mem Y Y -> mem Y X /\ ~mem Y Y
                                           Hb : mem Y X /\ ~mem Y Y -> mem Y Y *)
    assert (Hnn : ~ mem Y Y).
    { intro HA. destruct (Hf HA) as [_ Hn]. exact (Hn HA). }
    exact (Hnn (Hb (conj HM Hnn))).
Qed.
