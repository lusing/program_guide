(** 示例 16：集合层面的数学与商类型
    当类型是 h-set 时，HoTT 退化为"普通数学"；商类型是造新集合的主力工具。

    对应文档：docs/16-sets-quotient.md *)

Require Import HoTT.
Local Open Scope path_scope.

Definition sec_16_BEGIN := tt.   Check sec_16_BEGIN.

(** * 16.1 集合（0-型）里能做什么 *)

Definition sec_16_1_sets := tt.   Check sec_16_1_sets.

(** 在集合里，路径是命题，所以"存在唯一"这类话可以照常讲。 *)
Check (fun A : Type => IsHSet A).
Check hset_path2.
Check axiomK_hset.
Check hset_axiomK.

(** 常见的集合实例都能被类型类搜索自动找到：*)
Definition hset_nat : IsHSet nat := _.
Definition hset_bool : IsHSet Bool := _.
Definition hset_int : IsHSet Int := _.
Check hset_nat.
Check hset_bool.
Check hset_int.

(** 乘积保持"是集合"：若 [A]、[B] 是集合，则 [A * B] 也是（由类型类搜索自动得到）。 *)
Definition hset_prod (A B : Type) `{IsHSet A} `{IsHSet B} : IsHSet (A * B) := _.
Check hset_prod.

(** * 16.2 商类型的接口 *)

Definition sec_16_2_quotient_api := tt.   Check sec_16_2_quotient_api.

Check Quotient.
Check class_of.
Check qglue.
Check Quotient_ind.
Check Quotient_ind_beta_qglue.
Check Quotient_rec.
Check Quotient_rec_beta_qglue.
Locate "/".

(** 一个商类型由三件事决定：
      底类型 [A]、
      关系 [R : A -> A -> Type]、
      一条"粘合"路径构造子 [qglue : R a b -> class_of a = class_of b]。
    关键性质：商类型*一定*是集合。 *)
Check ishset_quotient.

(** * 16.3 例子：把 [Bool] 全商掉 *)

Definition sec_16_3_example := tt.   Check sec_16_3_example.

(** 取全关系（任意两点都相关），商掉之后应该只剩一个点。 *)
Definition bool_all_related (a b : Bool) : Type := Unit.

Definition BoolQuot : Type := Quotient bool_all_related.
Check BoolQuot.

(** 从 BoolQuot 到 Unit 的映射：目标必须是集合，且要说明关系被遵守。 *)
Definition boolquot_to_unit : BoolQuot -> Unit
  := Quotient_rec bool_all_related Unit (fun _ => tt) (fun a b _ => 1).
Check boolquot_to_unit.

(** 反过来：Unit 的点送到 [class_of true]。 *)
Definition unit_to_boolquot : Unit -> BoolQuot := fun _ => class_of bool_all_related true.
Check unit_to_boolquot.

(** 两者互逆，于是 [BoolQuot ≃ Unit]。
    右逆（Unit 侧）是显然的；左逆要用 [Quotient_ind] 对商做归纳。 *)
Definition boolquot_equiv_unit : BoolQuot <~> Unit.
Proof.
  srapply equiv_adjointify.
  - exact boolquot_to_unit.
  - exact unit_to_boolquot.
  - intro u; destruct u; reflexivity.     (* Unit 侧：显然 *)
  - intro x.                               (* BoolQuot 侧：对商归纳 *)
    (* 目标是 BoolQuot 中的一条路径，而商是集合 ⇒ 目标是 h-prop，
       于是用省事的 [Quotient_ind_hprop]（详见 16.4），不必写相容条件。 *)
    refine (Quotient_ind_hprop bool_all_related
             (fun x => unit_to_boolquot (boolquot_to_unit x) = x)
             (fun a => qglue (a := true) (b := a) tt) x).
Defined.
Check boolquot_equiv_unit.
Compute boolquot_equiv_unit (class_of bool_all_related false).

(** * 16.4 商上的命题消去：更省事的 [Quotient_ind_hprop] *)

Definition sec_16_4_ind_hprop := tt.   Check sec_16_4_ind_hprop.

Check Quotient_ind_hprop.
Check Quotient_ind2_hprop.
Check Quotient_ind3_hprop.

(** 若目标是 h-prop，连"关系被遵守"这一步都不用写——
    因为目标里所有点自动相等。 *)

(** * 16.5 商类型与"有效性"：为什么商一定是集合 *)

Definition sec_16_5_why_hset := tt.   Check sec_16_5_why_hset.

(** 商类型把关系 [R] 的居民变成*路径*，同时把所有更高层的路径压掉，
    所以结果必然是 0-型。这与"高阶归纳类型"的一般规律一致：
    点构造子造元素，路径构造子造路径，更高维的构造子则控制更高维。 *)
Check ishset_quotient.

(** 对比：圆也是一个商（余等值子），但因为我们*没有*把它压成集合，
    它留下了非平凡的自环。 *)
Check Circle.
Check Circle.loop.

(** * 16.6 集合层面的其他工具 *)

Definition sec_16_6_tools := tt.   Check sec_16_6_tools.

(** 判定性与有限类型：*)
Check Decidable.
Check Finite.
Check (fun (A : Type) => (A -> Empty) + A).   (* 最简单的判定形式 *)

(** 集合上的单射、嵌入：*)
Check isinj_embedding.
Check isinj_section.
Check IsEmbedding.

Definition sec_16_END := tt.   Check sec_16_END.
