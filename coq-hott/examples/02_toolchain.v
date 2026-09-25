(** 示例 02：工具链
    HoTT 库的构建、[-noinit] 与 [-indices-matter]、问询命令、公理追踪。

    对应文档：docs/02-toolchain.md

    运行方式：
      coqc -q -noinit -indices-matter -R $HOTT/theories HoTT ex_02_toolchain.v

    注意：少了 [-noinit] 或 [-indices-matter] 中的任一个，本库都无法正确编译。 *)

Require Import HoTT.

Definition sec_02_BEGIN := tt.   Check sec_02_BEGIN.

(** * 2.1 [-noinit]：HoTT 自带一套 prelude

    Rocq 默认会加载 Stdlib 的 Prelude（[nat]、[list]、[+] 等）。
    HoTT 要重新定义 [paths]、[prod]、[sum]、[nat] 等，
    所以必须 [-noinit] 把 Stdlib 挡在外面，再用自己的库充当 prelude。 *)

Definition sec_02_1_noinit := tt.   Check sec_02_1_noinit.

(** Stdlib 里的东西在 [-noinit] 下取不到（LoadPath 里没有 Stdlib）：*)
Fail Require Import Stdlib.Lists.List.

(** HoTT 自己定义了同名的"标准"类型，但它们不是 Stdlib 的那批：*)
Check nat.
Check Bool.
Check list.
Check prod.
Check sum.

(** 关键差别：[paths] 是 HoTT 自己的归纳族，[1] 是 [idpath]，
    数字字面量默认也不是 nat（见示例 01 的 1.2 节）。 *)
Print paths.
Check (1 : Bool = Bool).

(** * 2.2 问询四件套：Check / Print / About / Locate *)

Definition sec_02_2_queries := tt.   Check sec_02_2_queries.

Check concat_p1.                  (* 项的类型 *)
About concat_p1.                  (* 完整信息：参数、scope、 Arguments *)
Print concat_p1.                  (* 定义体 *)
Locate "@".                       (* 记号反查 *)
Locate "<~>".
Locate "->".

(** [Search] 在 [-noinit] 下仍可用（它是 Rocq 内核自带的查询命令）。
    查询要写得窄一点，否则会刷出上百条。 *)
Search (IsEquiv) (@inverse Bool true false).

(** * 2.3 [Print Assumptions]：追踪用到了哪些公理

    HoTT 库刻意把 泛等 / 函数外延 做成"空类型 + 类型类"，
    这样每个定理用到哪些公理都能被机器查出来。 *)

Definition sec_02_3_assumptions := tt.   Check sec_02_3_assumptions.

(** 纯路径代数不依赖任何公理：*)
Print Assumptions concat_p1.

(** 函数外延需要 [Funext]，因为它是由 [isequiv_apD10] 这个公理给出的：*)
Print Assumptions path_forall.
Check isequiv_apD10.

(** 泛等需要 [Univalence]：*)
Check path_universe.
Check equiv_path.
Print Assumptions isequiv_equiv_path.

(** 注意：[Require Import HoTT] 并*不*给你这两个公理的实例，
    必须由调用方显式假设（[`{Univalence}]）或单独导入公理文件。
    可以用下面两行确认它们没被泄漏：*)
Fail Check HoTT.Axioms.Univalence.univalence_axiom.
Fail Check HoTT.Axioms.Funext.funext_axiom.

(** * 2.4 [-indices-matter]

    这个开关让归纳类型的*索引*（而不仅是参数）参与"类型是否相同"的判断。
    HoTT 依赖它来保证 [paths] 这类索引归纳族的等价判定符合预期。
    命令行必须传；写进 [_CoqProject] 时是两行：

<<
-arg -noinit
-arg -indices-matter
>>

*)

Definition sec_02_4_flags := tt.   Check sec_02_4_flags.

(** * 2.5 Unicode 与记号 scope

    库里大量使用 Unicode 记号，并定义了多个专用 scope：
    [path_scope]（[1]、[@]、[^]）、[equiv_scope]（[oE]、[^-1]）、
    [trunc_scope]（[-2]、[.+1]）、[fibration_scope]（[.1]、[.2]）。
    混用时最容易踩的坑就是数字与 [@] 被别的 scope 抢走。 *)

Definition sec_02_5_scopes := tt.   Check sec_02_5_scopes.

Check (1 : nat = nat).
Check (0%nat : nat).
Check (-2)%trunc.
Check (equiv_idmap Bool).
Locate "oE".
Locate "^-1".

Definition sec_02_END := tt.   Check sec_02_END.
