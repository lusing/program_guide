(** 示例 01：类型论原理
    命题即类型、证明即程序、类型即空间。

    对应文档：docs/01-type-theory.md

    运行方式（详见 docs/02-toolchain.md）：
      coqc -q -noinit -indices-matter -R $HOTT/theories HoTT ex_01_type_theory.v

    关于分节标记：本教程用 [Check] 打印哨兵常量来划分区间——
    在 [-noinit] 下 Rocq 没有 string 记号，[idtac "文本"] 会报
    「No interpretation for string」，所以只能借常量名当标记。
    验证脚本按 [sec_NN_BEGIN] / [sec_NN_END] 两行抽区间做逐字节比对。 *)

Require Import HoTT.

Definition sec_01_BEGIN := tt.   Check sec_01_BEGIN.

(** * 1.1 命题即类型

    在 Martin-Löf 类型论里，逻辑运算就是类型构造器的别名：
    真 = [Unit]，假 = [Empty]，合取 = [prod]，析取 = [sum]，
    蕴含 = 函数类型，全称 = 依赖函数（Π），存在 = 依赖对（Σ）。 *)

Definition sec_01_1_logic_as_types := tt.   Check sec_01_1_logic_as_types.

Check Unit.                        (* 真：只有一个居民 *)
Check Empty.                       (* 假：没有居民 *)
Check prod.                        (* 合取 *)
Check sum.                         (* 析取 *)
Check (fun A B : Type => (A -> B)). (* 蕴含 *)
Check sig.                         (* 存在 *)

(** 全称量词 = Π 类型（依赖函数），否定 = 到 [Empty] 的函数：*)
Definition PiType (A : Type) (P : A -> Type) : Type := forall x : A, P x.
Definition Not (A : Type) : Type := A -> Empty.
Check PiType.
Check Not.

(** 这些"逻辑常量"不是公理，它们有居民，居民就是证明。 *)
Check tt.                          (* Unit 的唯一居民 *)
Check (@inl : forall A B : Type, A -> A + B).  (* 左注入 = 析取引入 *)
Check (@inr : forall A B : Type, B -> A + B).  (* 右注入 *)
Check (@fst : forall A B : Type, A * B -> A).  (* 合取消除 *)
Check (@snd : forall A B : Type, A * B -> B).

(** * 1.2 证明即程序

    写"定理"和写"函数"是同一件事：结论是要造出的类型，假设是参数。
    下面每条都只是 [Definition]，但读起来是逻辑定律。 *)

Definition sec_01_2_proofs_as_programs := tt.   Check sec_01_2_proofs_as_programs.

Definition law_identity (A : Type) : A -> A := fun x => x.
Definition law_and_elim_l (A B : Type) : A * B -> A := fst.
Definition law_or_intro_l (A B : Type) : A -> A + B := inl.
Definition law_modus_ponens (A B : Type) : A -> (A -> B) -> B
  := fun a f => f a.
Definition law_not_elim (A : Type) : A -> (A -> Empty) -> Empty
  := fun a na => na a.
Definition law_exists_intro (A : Type) (P : A -> Type) (a : A) (p : P a)
  : { x : A & P x }
  := (a; p).

Check law_identity.
Check law_modus_ponens.
Check law_exists_intro.

(** 证明项是可以求值的程序。注意 [law_modus_ponens] 的前两个参数是类型：*)
Compute law_modus_ponens Bool Bool true (fun b => b).
Compute (@fst Bool nat (true, 3%nat)).

(** 【坑】HoTT 库里数字字面量默认*不是* [nat]：
    [0] 落在 trunc_scope（截断层级），[1] 落在 path_scope（[idpath]），
    只有显式写 [%nat] 才是自然数。 *)
Check (0%nat : nat).
Check (0 : trunc_index).
Check (1 : (0%nat) = 0%nat).

(** * 1.3 依赖类型：谓词就是 [A -> Type]

    依赖函数（Π）和依赖对（Σ）是普通函数/乘积的依赖版本，
    逻辑上对应全称量词与存在量词。 *)

Definition sec_01_3_dependent_types := tt.   Check sec_01_3_dependent_types.

Definition IsZero (n : nat) : Type := n = 0%nat.

Check IsZero.                      (* nat -> Type：一个谓词 *)
Check IsZero 0%nat.                (* 一个具体的命题 *)
Check (idpath : IsZero 0%nat).     (* 它有居民：0 = 0 *)

(** Σ 类型的居民是"见证 + 证据"。 *)
Definition witness_zero : { n : nat & IsZero n } := (0%nat; idpath).
Check witness_zero.
Compute (witness_zero).1.
Compute (witness_zero).2.

(** * 1.4 相等的特殊地位

    在 HoTT 里 [x = y] 不是布尔值，而是一个*类型*：[paths] 是归纳类型族，
    只有一个构造子 [idpath]。所以"相等"同样有居民（路径），
    而且可以有*多个*不同居民 —— 这是 HoTT 全部新现象的源头。 *)

Definition sec_01_4_identity_types := tt.   Check sec_01_4_identity_types.

Check paths.
Check idpath.
Print paths.

(** [1] 是 [idpath] 的记号（path_scope 默认打开），[p @ q] 是路径拼接，
    [p^] 是逆路径。这与标准 Coq 的记号习惯不同，是本库最常见的绊脚石。 *)
Check (1 : (3%nat) = 3%nat).
Check (@concat Bool true true true).
Check (@inverse Bool true false).

(** * 1.5 类型即空间：HoTT 的三层词典

    类型 = 空间，项 = 点，[p : x = y] = 从 x 到 y 的路径，
    [r : p = q] = 路径之间的同伦（2-路径），依此类推。 *)

Definition sec_01_5_types_as_spaces := tt.   Check sec_01_5_types_as_spaces.

(** 同一条相等命题可以有不同"证明"，而这些证明本身还能再相等：*)
Definition two_paths_to_true : true = true := 1.
Definition path_of_paths : (1 : true = true) = (1 @ 1 : true = true)
  := (concat_1p 1)^.

Check two_paths_to_true.
Check path_of_paths.

(** "所有路径都相同"是很强的性质，叫 h-set（0-类型）；
    允许非平凡环路的类型（比如圆）就不是集合。 *)
Check (fun A : Type => IsHSet A).
Check (fun A : Type => IsHProp A).
Check (fun A : Type => Contr A).

(** 它们都是 [IsTrunc n A] 的记号：[Contr] = -2 层，[IsHProp] = -1 层，
    [IsHSet] = 0 层。层级本身是 [trunc_index]：*)
Check (fun (n : trunc_index) (A : Type) => IsTrunc n A).
Check trunc_index.
Check minus_two.

Definition sec_01_END := tt.   Check sec_01_END.
