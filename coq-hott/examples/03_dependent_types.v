(** 示例 03：依赖类型
    Π、Σ、Unit、Empty、Bool、和类型、option —— HoTT 版的基础类型构造器。

    对应文档：docs/03-dependent-types.md *)

Require Import HoTT.

Definition sec_03_BEGIN := tt.   Check sec_03_BEGIN.

(** * 3.1 [Unit]：只有一个居民的类型 *)

Definition sec_03_1_unit := tt.   Check sec_03_1_unit.

Check Unit.
Check tt.
Print Unit.

(** Unit 上的 η 性质：任何 [u : Unit] 都等于 [tt]。
    注意这里用的是路径归纳（对 [u] 做 [destruct]），
    而不是标准 Coq 的 [destruct u; reflexivity] 那条老路——
    其实是一回事，只是 [reflexivity] 在 HoTT 里被重定向到 [idpath]。 *)
Definition unit_eta (u : Unit) : u = tt.
Proof.
  destruct u; reflexivity.
Defined.
Check unit_eta.

(** * 3.2 [Empty]：没有居民的类型，以及"爆炸原理" *)

Definition sec_03_2_empty := tt.   Check sec_03_2_empty.

Check Empty.

(** 空类型可以消去到任意类型——这就是"假命题蕴涵一切"。 *)
Definition exfalso (A : Type) (e : Empty) : A := match e with end.
Check exfalso.

(** 由 [Empty] 的居民可以造出任何"命题"的证明，包括矛盾：*)
Definition not_true_ne_false_via_empty (p : true = false) : Empty
  := transport (fun b => match b with true => Unit | false => Empty end) p tt.
Check not_true_ne_false_via_empty.

(** 库里已经有一条现成的：*)
Check true_ne_false.

(** * 3.3 [Bool]：两元素类型与 [if] *)

Definition sec_03_3_bool := tt.   Check sec_03_3_bool.

Check Bool.
Check true.
Check false.

Definition bool_not (b : Bool) : Bool := if b then false else true.
Compute bool_not true.
Compute bool_not false.

(** 用 [Bool] 可以编码"可判定命题"，[true ≠ false] 是本库常用的反例来源。 *)
Check negb.
Compute negb true.

(** * 3.4 和类型 [A + B]（析取） *)

Definition sec_03_4_sum := tt.   Check sec_03_4_sum.

Check sum.
Check (fun A B : Type => A + B).

(** 和类型的消去是"分情况讨论"，在 Coq 里就是 [match]：*)
Definition sum_swap {A B : Type} (z : A + B) : B + A
  := match z with inl a => inr a | inr b => inl b end.
Check sum_swap.
Compute sum_swap (inl 1%nat : nat + Bool).

(** * 3.5 Σ 类型（依赖对 / 存在量词） *)

Definition sec_03_5_sigma := tt.   Check sec_03_5_sigma.

Check sig.
Check (fun (A : Type) (P : A -> Type) => { x : A & P x }).
Check (fun (A : Type) (P : A -> Type) => { x : A | P x }).

(** 取分量用 [pr1] / [pr2]，或记号 [.1] / [.2]（fibration_scope）：*)
Definition pair_nat : { n : nat & n = n } := (3%nat; 1).
Check pair_nat.
Compute (pair_nat).1.
Compute pr1 pair_nat.

(** Σ 的 η 性质同样成立（在 [Types.Sigma] 里叫 [eta_sigma]）：*)
Check eta_sigma.

(** * 3.6 Π 类型（依赖函数 / 全称量词） *)

Definition sec_03_6_pi := tt.   Check sec_03_6_pi.

(** 依赖函数的"相等"是逐点相等，记作 [f == g]：*)
Check (fun (A : Type) (P : A -> Type) => forall x : A, P x).
Check pointwise_paths.
Locate "==".

(** 【坑】[+] 在 type_scope 里是和类型，nat 的加法要显式写 [%nat]，
    或者用 [nat_add]：*)
Definition double_all : forall n : nat, nat := fun n => (n + n)%nat.
Compute double_all 3%nat.
Check nat_add.
Check double_all.

(** 逐点相等 [f == g] 与 [f = g] 是两个不同强度的命题：
    前者蕴含后者需要函数外延（第 10 章），后者蕴含前者永远成立（[ap10]）。 *)
Check ap10.
Check apD10.

(** * 3.7 [option]：可能失败的返回值 *)

Definition sec_03_7_option := tt.   Check sec_03_7_option.

Check option.
Check Some.
Check None.

Definition safe_pred (n : nat) : option nat
  := match n with 0%nat => None | S m => Some m end.
Compute safe_pred 0%nat.
Compute safe_pred 5%nat.

Definition sec_03_END := tt.   Check sec_03_END.
