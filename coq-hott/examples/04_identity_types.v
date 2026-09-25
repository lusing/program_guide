(** 示例 04：恒等类型与路径归纳
    [paths] 的真身、J 消去子、[ap] / [apD]、以及"路径归纳"这一唯一武器。

    对应文档：docs/04-identity-types.md *)

Require Import HoTT.
Local Open Scope path_scope.

Definition sec_04_BEGIN := tt.   Check sec_04_BEGIN.

(** * 4.1 [paths] 的真身 *)

Definition sec_04_1_paths := tt.   Check sec_04_1_paths.

Print paths.
Check idpath.
Check paths_ind.
Check paths_rec.

(** [paths] 是一个*索引*归纳族：参数 [A : Type] 与 [a : A]，索引是终点。
    只有一个构造子 [idpath : a = a]，因此"要证 [forall x, P x]，
    只需证 [P (idpath a)]"——这就是路径归纳（J）。 *)

(** * 4.2 路径归纳（J）能干什么

    所有"对所有路径成立"的命题，都只要证 [1]（[idpath]）的情形。
    反向、拼接、[ap] 全部由它派生。 *)

Definition sec_04_2_path_induction := tt.   Check sec_04_2_path_induction.

(** 自己实现一次逆路径：*)
Definition my_inverse {A : Type} {x y : A} (p : x = y) : y = x.
Proof.
  destruct p; reflexivity.
Defined.
Compute my_inverse (idpath : (3%nat) = 3%nat).
Check my_inverse.

(** 自己实现一次拼接：*)
Definition my_concat {A : Type} {x y z : A} (p : x = y) (q : y = z) : x = z.
Proof.
  destruct p, q; reflexivity.
Defined.
Check my_concat.

(** 库里的版本与自己的版本在 [1] 上行为一致：*)
Definition my_inverse_is_inverse {A : Type} {x y : A} (p : x = y)
  : my_inverse p = p^.
Proof.
  destruct p; reflexivity.
Defined.
Check my_inverse_is_inverse.

(** * 4.3 [ap]：函数作用在路径上 *)

Definition sec_04_3_ap := tt.   Check sec_04_3_ap.

Check ap.
Print ap.

(** [ap] 也是由路径归纳定义的：只需看 [p] 是 [1] 的情形。 *)
Definition ap_idpath {A B : Type} (f : A -> B) (x : A) : ap f (idpath x) = 1
  := 1.
Check ap_idpath.
Check ap_1.

(** [ap] 的函子性：保持拼接与逆。 *)
Check ap_pp.
Check ap_V.
Check ap_compose.
Check ap_idmap.
Check ap_const.

(** 一个具体例子：[ap S] 把 [2 = 2] 送到 [3 = 3]。 *)
Check (ap S (1 : (2%nat) = 2%nat)).
Compute (ap S (1 : (2%nat) = 2%nat)).

(** * 4.4 [apD]：依赖函数的情形 *)

Definition sec_04_4_apD := tt.   Check sec_04_4_apD.

Check apD.
Print apD.

(** 依赖函数 [f : forall x, B x] 作用在 [p : x = y] 上得到的是
    [transport B p (f x) = f y]，而不是简单的 [f x = f y]——
    因为两边的类型不同，必须先把左边搬到右边所在的纤维里。 *)
Check (fun (A : Type) (B : A -> Type) (f : forall x, B x) => apD f).

(** * 4.5 路径归纳的几个标准推论 *)

Definition sec_04_5_consequences := tt.   Check sec_04_5_consequences.

(** 拼接的单位元律：*)
Check concat_p1.
Check concat_1p.

(** 逆与拼接的抵消律：*)
Check concat_pV.
Check concat_Vp.
Check concat_pV_p.
Check concat_V_pp.
Check concat_pp_V.

(** 逆的运算律：*)
Check inv_pp.
Check inv_V.
Check inv_VV.

(** 自己证一次 [p @ 1 = p]，体会"只剩 [1] 的情形"：*)
Definition my_concat_p1 {A : Type} {x y : A} (p : x = y) : p @ 1 = p.
Proof.
  destruct p; reflexivity.
Defined.
Check my_concat_p1.

Definition my_concat_p1_matches {A : Type} {x y : A} (p : x = y)
  : my_concat_p1 p = concat_p1 p.
Proof.
  destruct p; reflexivity.
Defined.
Check my_concat_p1_matches.

(** * 4.6 恒等类型不是布尔值

    标准 Coq 有 [UIP]（同一等式的两个证明必相等），HoTT 里*没有*。
    能证 UIP 的类型叫 h-set（第 9 章），而 [Type] 本身甚至不是集合
    （第 11 章会看到 [not_hset_Type]）。 *)

Definition sec_04_6_no_uip := tt.   Check sec_04_6_no_uip.

(** 我们*不能*证明 [forall (p q : x = y), p = q]，只能把它当作假设：*)
Definition UIP_statement (A : Type) : Type := forall x y : A, IsHProp (x = y).
Check UIP_statement.

(** 对 [Unit] 这种可缩类型，它成立：*)
Definition uip_unit : UIP_statement Unit.
Proof.
  intros x y; destruct x, y; exact _.
Defined.
Check uip_unit.

Definition sec_04_END := tt.   Check sec_04_END.
