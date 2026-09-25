(** 示例 07：等价
    HoTT 里"两个类型一样"的正确含义：[A <~> B]。

    对应文档：docs/07-equivalences.md *)

Require Import HoTT.
Local Open Scope equiv_scope.
Local Open Scope path_scope.

Definition sec_07_BEGIN := tt.   Check sec_07_BEGIN.

(** * 7.1 [IsEquiv] 与 [Equiv] 的结构 *)

Definition sec_07_1_structure := tt.   Check sec_07_1_structure.

Print IsEquiv.
Print Equiv.
Locate "<~>".

(** [IsEquiv f] 是一个类型类，装了四份数据：
      [equiv_inv]  反函数
      [eisretr]    [f o f^-1 == idmap]（右逆）
      [eissect]    [f^-1 o f == idmap]（左逆）
      [eisadj]     两者相容（伴随律）
    最后一条让"半等价"升级为"伴随等价"，是本库采用的定义。 *)
Check equiv_inv.
Check eisretr.
Check eissect.
Check eisadj.

(** [Equiv A B] 把函数与它的 [IsEquiv] 证据打包，可强制转换为函数：*)
Check equiv_fun.
Check (fun (A B : Type) (e : A <~> B) => e : A -> B).

(** * 7.2 由左右逆构造等价：伴随化 *)

Definition sec_07_2_adjointify := tt.   Check sec_07_2_adjointify.

Check isequiv_adjointify.
Check equiv_adjointify.

(** 经典例子：布尔取反是一个自等价。
    只需要给两个同伦（左右逆），伴随律由 [isequiv_adjointify] 自动补上。 *)
Definition equiv_bool_neg : Bool <~> Bool.
Proof.
  refine (equiv_adjointify negb negb _ _).
  - intro b; destruct b; reflexivity.
  - intro b; destruct b; reflexivity.
Defined.
Check equiv_bool_neg.
Compute equiv_bool_neg true.
Compute equiv_bool_neg false.

(** 反函数用 [^-1] 取（function_scope 里的记号）：*)
Compute equiv_bool_neg^-1 true.

(** * 7.3 等价构成一个群胚 *)

Definition sec_07_3_algebra := tt.   Check sec_07_3_algebra.

Check equiv_idmap.
Check equiv_compose.
Check equiv_inverse.
Locate "oE".

(** 复合与取逆都是等价：*)
Check (equiv_compose' equiv_bool_neg equiv_bool_neg).
Compute (equiv_compose' equiv_bool_neg equiv_bool_neg) true.

(** 等价的逆的逆是自己（在 [1] 的意义下）：*)
Check equiv_inverse_compose.

(** * 7.4 [ap] 保持等价 *)

Definition sec_07_4_ap := tt.   Check sec_07_4_ap.

Check isequiv_ap.
Check equiv_ap.

(** 若 [f] 是等价，则 [ap f : (x = y) -> (f x = f y)] 也是等价。
    这条在编码-解码证明（第 13 章）里反复用到。 *)

(** * 7.5 手写几个常见等价 *)

Definition sec_07_5_examples := tt.   Check sec_07_5_examples.

(** 积的交换。注意 [make_equiv] 这个 tactic 能自动把"给出反函数 + 两个同伦"
    的证明收拾干净：*)
Definition my_prod_symm (A B : Type) : A * B <~> B * A.
Proof.
  make_equiv.
Defined.
Check my_prod_symm.
Compute (my_prod_symm Bool nat (true, 3%nat)).

(** 库里的现成版本：*)
Check equiv_prod_symm.

(** Σ 类型的重排：[{a & {b & P a b}} <~> {b & {a & P a b}}] 之类
    也属于"给反函数 + 两个同伦"的形状。 *)
Check equiv_sigma_symm.
Check equiv_functor_sigma.
Check equiv_functor_prod.
Check equiv_functor_sum.

(** * 7.6 等价 vs 可缩纤维

    [f : A -> B] 是等价，当且仅当它的每个同伦纤维 [hfiber f b] 可缩。
    这是判定等价最常用的手段，详见第 08 章。 *)
Definition sec_07_6_vs_fibers := tt.   Check sec_07_6_vs_fibers.

Check hfiber.
Check contr_map_isequiv.

(** * 7.7 [equiv_intro]：像做归纳一样消掉一个等价 *)

Definition sec_07_7_equiv_ind := tt.   Check sec_07_7_equiv_ind.

Check equiv_ind.
Check equiv_ind_comp.
Locate "equiv_intros".

(** 等价归纳说：要证 [forall b, P b]，只需证 [P (f (f^-1 b))] 的形式，
    等价于把 [b] 拉回 [A] 上。配合泛等（第 11 章）它就变成真正的路径归纳。 *)

Definition sec_07_END := tt.   Check sec_07_END.
