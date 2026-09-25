(** 示例 10：函数外延
    逐点相等 [f == g] 与相等 [f = g] 之间的那座桥。

    对应文档：docs/10-funext.md *)

Require Import HoTT.
Local Open Scope path_scope.

Definition sec_10_BEGIN := tt.   Check sec_10_BEGIN.

(** * 10.1 [Funext] 是一个"空类型" *)

Definition sec_10_1_funext_class := tt.   Check sec_10_1_funext_class.

Print Funext.
Check isequiv_apD10.
Check apD10.
Check ap10.
Locate "==".

(** 本库刻意*不*把函数外延当成无条件成立的公理：
    [Funext] 是一个没有任何构造子的类型，把它作为类型类假设（[`{Funext}]），
    这样每个定理用到哪些公理都能被 [Print Assumptions] 查出来。 *)

(** * 10.2 两个方向的桥 *)

Definition sec_10_2_bridge := tt.   Check sec_10_2_bridge.

(** [f = g -> f == g] 永远成立（不需要任何公理），它就是 [ap10]：*)
Definition eq_to_pointwise {A B : Type} (f g : A -> B) : f = g -> f == g
  := ap10.
Check eq_to_pointwise.
Print Assumptions eq_to_pointwise.

(** 反方向 [f == g -> f = g] 就是函数外延，需要 [Funext]：*)
Check path_forall.
Check path_arrow.

(** * 10.3 在 [Section] 里假设 [Funext] *)

Definition sec_10_3_section := tt.   Check sec_10_3_section.

Section FunextDemo.
  Context `{Funext}.

  (** 有了它，"逐点证明"就等于"证明函数相等"：*)
  Definition twice_eq {A B : Type} (f g : A -> B) (h : forall x, f x = g x)
    : f = g := path_forall f g h.
  Check twice_eq.

  (** 一个具体例子：[nat] 上的两个函数逐点相等，所以相等。 *)
  Definition add_zero_l : (fun n : nat => (0 + n)%nat) = (fun n : nat => n).
  Proof.
    apply path_forall; intro n; destruct n; reflexivity.
  Defined.
  Check add_zero_l.

  (** 依赖版本同样可用：*)
  Check (fun (A : Type) (P : A -> Type) (f g : forall x, P x) => path_forall f g).

End FunextDemo.

(** 出了 Section，[twice_eq] 的类型里带着 [Funext] 假设：*)
Check twice_eq.
Print Assumptions twice_eq.

(** * 10.4 没有实例时 [path_forall] 用不了 *)

Definition sec_10_4_fail := tt.   Check sec_10_4_fail.

(** 此刻文件里还没有 [Funext] 的全局实例，类型类搜索会失败——
    [path_forall] 需要 [Funext]，而没有任何东西能提供它。 *)
Fail Definition bad_pointwise : (fun n : nat => n) = (fun n : nat => n)
  := path_forall _ _ (fun n => 1).

(** * 10.5 显式假设 vs 导入公理 *)

Definition sec_10_5_axiom := tt.   Check sec_10_5_axiom.

(** 想在全文件范围内无条件使用，就导入公理文件：*)
Require Import HoTT.Axioms.Funext.
Check funext_axiom.

(** 现在 [path_forall] 可以直接用，不用再写 [Context `{Funext}]：*)
Definition add_zero_r : (fun n : nat => (n + 0)%nat) = (fun n : nat => n).
Proof.
  apply path_forall; intro n; induction n as [|n IH]; simpl.
  - reflexivity.
  - exact (ap S IH).
Defined.
Check add_zero_r.
Print Assumptions add_zero_r.

(** 注意 [Print Assumptions] 现在会列出 [funext_axiom]——
    这就是"显式假设"这套机制的价值：公理用量一目了然。 *)

(** * 10.6 函数外延的常用推论 *)

Definition sec_10_6_corollaries := tt.   Check sec_10_6_corollaries.

(** 前后复合保持等价（需要 [Funext]）：*)
Check isequiv_precompose.
Check isequiv_postcompose.
Check equiv_precompose.
Check equiv_postcompose.

(** 逐点路径的"based homotopy"类型是可缩的：*)
Check contr_basedhomotopy.

(** 等价之间的相等可以逐点判断：*)
Check path_equiv.
Check equiv_path_equiv.

Definition sec_10_END := tt.   Check sec_10_END.
