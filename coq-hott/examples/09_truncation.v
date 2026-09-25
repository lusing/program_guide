(** 示例 09：截断层级
    -2（可缩）、-1（命题）、0（集合）——HoTT 的"复杂度标尺"。

    对应文档：docs/09-truncation.md *)

Require Import HoTT.
Local Open Scope path_scope.

Definition sec_09_BEGIN := tt.   Check sec_09_BEGIN.

(** * 9.1 三个最重要的层级 *)

Definition sec_09_1_levels := tt.   Check sec_09_1_levels.

Check (fun A : Type => Contr A).       (* -2：可缩，只有一个点 *)
Check (fun A : Type => IsHProp A).     (* -1：命题，任意两点相连 *)
Check (fun A : Type => IsHSet A).      (*  0：集合，任意两路径相等 *)

(** 层级的索引是 [trunc_index]，从 [minus_two] 开始取后继：*)
Check trunc_index.
Check minus_two.
Check (fun n : trunc_index => trunc_S n).

(** 定义本身是一个索引归纳族：*)
Print IsTrunc_internal.

(** * 9.2 h-prop（-1 层）：唯一性取代存在性 *)

Definition sec_09_2_hprop := tt.   Check sec_09_2_hprop.

(** 一个类型是 h-prop，当且仅当任意两点之间都有路径：*)
Check path_ishprop.
Check hprop_allpath.

(** h-prop 之间只要互相有函数就是等价（逻辑等价即等价）：*)
Check isequiv_iff_hprop.
Check equiv_iff_hprop.

(** 有居民的 h-prop 立即是可缩的：*)
Check hprop_inhabited_contr.

(** 例子：[Empty] 与 [Unit] 都是 h-prop。 *)
Definition ishprop_empty : IsHProp Empty.
Proof.
  apply hprop_allpath; intros x; destruct x.
Defined.
Check ishprop_empty.

Definition ishprop_unit : IsHProp Unit := _.
Check ishprop_unit.

(** * 9.3 h-set（0 层）：路径是命题 *)

Definition sec_09_3_hset := tt.   Check sec_09_3_hset.

(** 集合 = 任意两条平行路径都相等，这就是通常说的 UIP / axiom K。 *)
Check hset_path2.
Check axiomK_hset.
Check hset_axiomK.
Check axiomK.

(** 常见的集合：[Bool]、[nat]、[Empty]、[Unit]；类型类搜索通常能自动找到：*)
Definition hset_bool : IsHSet Bool := _.
Definition hset_nat : IsHSet nat := _.
Check hset_bool.
Check hset_nat.

(** 有了 [IsHSet X]，证 [p = q] 只要一步：*)
Definition two_paths_in_a_set {X : Type} `{IsHSet X} {x y : X} (p q : x = y)
  : p = q := hset_path2 p q.
Check two_paths_in_a_set.

(** * 9.4 层级的基本推理规则 *)

Definition sec_09_4_rules := tt.   Check sec_09_4_rules.

(** 路径类型把层级降一：若 [A] 是 (n+1)-型，则 [x = y] 是 n-型。 *)
Check istrunc_paths.

(** 层级可以往上抬：可缩 ⇒ 命题 ⇒ 集合。 *)
Check istrunc_contr.
Check istrunc_hprop.
Check istrunc_hset.

(** 层级沿等价保持：*)
Check istrunc_equiv_istrunc.
Check istrunc_isequiv_istrunc.

(** * 9.5 把"类型 + 层级证据"打包：[TruncType] *)

Definition sec_09_5_trunctype := tt.   Check sec_09_5_trunctype.

Check TruncType.
Locate "-Type".
(** 【坑】[Build_HSet] / [Build_HProp] 只要一个类型参数，
    层级证据由类型类搜索自动填上——多给一个参数会报
    「Illegal application (Non-functional construction)」。 *)
Check (Build_HSet Bool : HSet).
Check (Build_HProp Unit : HProp).

(** [IsHProp A] 与 [A] 的区别很重要：前者是一个*命题*，
    后者是我们实际在用的类型。打包成 [HProp] 后，
    "两个 h-prop 相等"这件事本身又变成可判定的（需要泛等，见第 11 章）。 *)
Check equiv_equiv_iff_hprop.

Definition sec_09_END := tt.   Check sec_09_END.
