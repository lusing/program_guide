(** 示例 23：元理论与证明工程
    公理追踪、定义展开、找引理的技巧、以及常见的工程化设置。

    对应文档：docs/23-metatheory.md *)

Require Import HoTT.
Local Open Scope path_scope.

Definition sec_23_BEGIN := tt.   Check sec_23_BEGIN.

(** * 23.1 公理盘点：[Print Assumptions]

    本库把 [Funext] 与 [Univalence] 做成"空类型 + 类型类"，
    于是每条定理用到哪些公理都能被机器列出来。这是 HoTT 库
    最重要的工程约定之一：公理用量可审计。 *)

Definition sec_23_1_assumptions := tt.   Check sec_23_1_assumptions.

(** 纯路径代数：一个公理都不用。 *)
Print Assumptions concat_p1.
Print Assumptions transport_pp.
Print Assumptions isequiv_adjointify.

(** 函数外延：需要 [Funext]。 *)
Print Assumptions path_forall.

(** 泛等：需要 [Univalence]。 *)
Print Assumptions path_universe.
Print Assumptions equiv_path_universe.

(** 圆的基本群计算：需要 [Univalence]（因为覆叠用到了 [path_universe]）。 *)
Print Assumptions equiv_loopCircle_int.

(** * 23.2 看定义：[Print] 与 [About] *)

Definition sec_23_2_print := tt.   Check sec_23_2_print.

Print concat_p1.
Print transport.
Print IsEquiv.
Print Equiv.
Print hfiber.
Print IsTrunc_internal.

(** [About] 会连记号 scope 与 [Arguments] 一起给出，
    排查"为什么这个项被解析成了别的东西"时最有用：*)
About concat.
About equiv_inv.

(** * 23.3 找引理：[Search] 的三条经验 *)

Definition sec_23_3_search := tt.   Check sec_23_3_search.

(** 1) 用具体的单态类型缩小范围，否则会刷出上百条：*)
Search (IsEquiv) (@inverse Bool true false).

(** 2) 找"形状"而不是"名字"：*)
Search (transport _ _ _ = _ -> _ = _).

(** 3) 找到候选后用 [Check] 确认它的参数顺序（这是最常出错的地方）。 *)
Check moveR_transport_p.

(** * 23.4 类型类搜索失败时的排查顺序 *)

Definition sec_23_4_typeclasses := tt.   Check sec_23_4_typeclasses.

(** 症状：[srapply]/[exact _] 报 "Unable to satisfy the following constraints"。
    常见原因是截断层级实例没找到（[IsHSet]、[IsHProp]），
    或者是 [Funext] / [Univalence] 没导入。 *)

(** 检查某个实例能否被自动找到：*)
Definition can_find_hset_bool : IsHSet Bool := _.
Definition can_find_hprop_unit : IsHProp Unit := _.
Check can_find_hset_bool.
Check can_find_hprop_unit.

(** 手动指定时可以用 [istrunc_leq] 抬层级：*)
Check istrunc_leq.

(** * 23.5 记号与 scope 的排查 *)

Definition sec_23_5_notations := tt.   Check sec_23_5_notations.

(** [Locate] 反查记号定义在哪里、属于哪个 scope：*)
Locate "@".
Locate "^".
Locate "1".
Locate "<~>".
Locate "==".

(** 当一个项的类型和你预期不符时，八成是 scope 抢了记号：
    下面三行的 [1] 分别属于 path_scope、nat_scope、trunc_scope、equiv_scope。 *)
Check (1 : true = true).
Check (1%nat : nat).
Check ((-2)%trunc : trunc_index).

(** * 23.6 编译与验证的工程化设置 *)

Definition sec_23_6_engineering := tt.   Check sec_23_6_engineering.

(** 本教程所有示例都用同一条命令行编译：

<<
coqc -q -noinit -indices-matter -R $HOTT/theories HoTT ex_NN_xxx.v
>>

    其中：
      [-noinit]          不加载 Stdlib 的 Prelude（否则 [paths] 等被抢走）
      [-indices-matter]  让归纳类型的索引参与等价判断
      [-R ... HoTT]      把库根映射成 [HoTT] 命名空间
      [-q]               安静模式（必要的输出仍然会打印）
*)

(** * 23.7 本教程用到的公理总览 *)

Definition sec_23_7_summary := tt.   Check sec_23_7_summary.

(** 到目前为止的示例里，只有涉及 [Funext] / [Univalence] 的章节
    （10、11、13、18、21、24）真正需要公理；
    类型论基础、路径代数、等价、截断这些是公理无关的。 *)

Print Assumptions concat_p1.
Print Assumptions isequiv_contr_map.

Definition sec_23_END := tt.   Check sec_23_END.
