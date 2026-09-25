(** 示例 14：类型构造器的路径与等价
    乘积、Σ、和、函数类型里的"相等"各自长什么样。

    对应文档：docs/14-type-formers.md *)

Require Import HoTT.
Local Open Scope path_scope.

Definition sec_14_BEGIN := tt.   Check sec_14_BEGIN.

(** * 14.1 乘积里的路径 = 分量的路径对 *)

Definition sec_14_1_prod := tt.   Check sec_14_1_prod.

Check path_prod.
Check path_prod_uncurried.
Check equiv_path_prod.

(** [(a,b) = (a',b') ≃ (a = a') * (b = b')] *)
Definition my_path_prod {A B : Type} (x y : A * B)
  : (fst x = fst y) * (snd x = snd y) -> x = y
  := equiv_path_prod x y.
Check my_path_prod.

(** 具体构造：给两条分量路径，打包成乘积上的路径。 *)
Definition prod_path_example : (true, 3%nat) = (true, 3%nat)
  := path_prod _ _ 1 1.
Check prod_path_example.

(** * 14.2 Σ 类型里的路径 = 底分量路径 + 依赖分量路径 *)

Definition sec_14_2_sigma := tt.   Check sec_14_2_sigma.

Check path_sigma.
Check path_sigma_uncurried.
Check equiv_path_sigma.

(** 这里第二分量必须是一条*依赖*路径（先 transport 再相等），
    这正是 Σ 与普通乘积的区别。 *)
Check pr1_path.
Check pr2_path.
Check eta_path_sigma.

(** * 14.3 和类型里的路径 = 同侧且分量相等 *)

Definition sec_14_3_sum := tt.   Check sec_14_3_sum.

Check path_sum.
Check path_sum_inl.
Check path_sum_inr.
Check equiv_path_sum.
Check inl_ne_inr.
Check inr_ne_inl.

(** [inl a ≠ inr b]：两侧之间没有任何路径。这是 transport 的经典用法，
    思路见示例 05。 *)

(** 【坑】[path_sum_inl] 的方向是"从 [inl x = inl x'] 拿回 [x = x']"，
    造路径要用 [ap inl] 或 [path_sum]：*)
Definition sum_path_example {A B : Type} (a a' : A) (p : a = a')
  : (inl a : A + B) = inl a'
  := ap (fun x : A => (inl x : A + B)) p.
Check sum_path_example.

(** * 14.4 函数类型里的路径 = 逐点路径（需要 Funext） *)

Definition sec_14_4_arrow := tt.   Check sec_14_4_arrow.

Check path_arrow.
Check equiv_path_arrow.
Check ap10_path_arrow.

(** 不需要 [Funext] 就能用的方向（逐点化）与需要 [Funext] 的方向
    在这里对称地摆着——详见第 10 章。 *)

(** * 14.5 类型构造器都是"等价函子" *)

Definition sec_14_5_functors := tt.   Check sec_14_5_functors.

(** [equiv_functor_*] 系列：等价可以穿过类型构造器。 *)
Check equiv_functor_sigma.
Check equiv_functor_prod.
Check equiv_functor_prod'.
Check equiv_functor_sum.
Check equiv_functor_arrow.

(** 例子：若 [A ≃ A']、[B ≃ B']，则 [A * B ≃ A' * B']。
    这里取 [Bool] 上的取反作为两端：*)
Definition negb_equiv : Bool <~> Bool
  := equiv_adjointify negb negb
       (fun b => match b with true => idpath | false => idpath end)
       (fun b => match b with true => idpath | false => idpath end).

Definition prod_equiv_example : (Bool * Bool) <~> (Bool * Bool)
  := equiv_functor_prod' negb_equiv negb_equiv.
Check prod_equiv_example.
Compute prod_equiv_example (true, false).

(** * 14.6 一个完整的练习：Σ 与乘积的互换 *)

Definition sec_14_6_exercise := tt.   Check sec_14_6_exercise.

(** 常值纤维的 Σ 就是乘积：[{ _ : A & B } ≃ A * B]。 *)
Check equiv_sigma_prod.

(** 反过来，Σ 的第二分量可缩时，忘掉它就是等价（第 08 章的 [equiv_sigma_contr]）。 *)
Check equiv_sigma_contr.
Check equiv_pr1.

(** 练习：证明 [A * Unit ≃ A]。 *)
Definition prod_unit_r (A : Type) : A * Unit <~> A.
Proof.
  make_equiv.
Defined.
Check prod_unit_r.
Compute prod_unit_r Bool (true, tt).

Definition sec_14_END := tt.   Check sec_14_END.
