(** 示例 11：泛等公理
    "(A ≃ B) ≃ (A = B)"——等价就是相等。

    对应文档：docs/11-univalence.md *)

Require Import HoTT.
Local Open Scope path_scope.
(** 【坑】这里刻意*不*打开 [equiv_scope]：该 scope 里 [1] 是 [equiv_idmap]，
    会和 path_scope 的 [idpath] 抢记号，写证明时极易出错。 *)

Definition sec_11_BEGIN := tt.   Check sec_11_BEGIN.

(** * 11.1 [Univalence] 也是一个"空类型" *)

Definition sec_11_1_class := tt.   Check sec_11_1_class.

Print Univalence.
Check equiv_path.
Check isequiv_equiv_path.

(** [Univalence] 与 [Funext] 一样是空的占位类型，
    需要它的定理写成 [Context `{Univalence}]，这样公理用量可被追踪。 *)

(** * 11.2 [equiv_path]：从相等到等价（不需要公理） *)

Definition sec_11_2_equiv_path := tt.   Check sec_11_2_equiv_path.

Check equiv_path.
Print Assumptions equiv_path.

(** 相等必然给出等价——把元素沿路径搬运过去。这一步是纯定义的。 *)

(** * 11.3 [path_universe]：从等价到相等（需要泛等） *)

Definition sec_11_3_path_universe := tt.   Check sec_11_3_path_universe.

Section UnivalenceDemo.
  Context `{Univalence}.

  Check path_universe.
  Check path_universe_uncurried.
  Check equiv_path_universe.
  Check equiv_equiv_path.

  (** 布尔取反这个自等价，给出一条 [Bool = Bool] 的路径。
      【坑】这里必须写 [idpath] 而不是 [1]：本文件打开了 [equiv_scope]，
      [1] 在 [equiv_scope] 里是 [equiv_idmap]，不是 [idpath]。 *)
  Definition negb_path : Bool = Bool
    := path_universe (equiv_adjointify negb negb
        (fun b => match b with true => idpath | false => idpath end)
        (fun b => match b with true => idpath | false => idpath end)).
  Check negb_path.

  (** 沿这条路径搬运，等于把等价作用在元素上（这是泛等唯一的"计算律"）：*)
  Check transport_path_universe.
  Check transport_path_universe_V.

End UnivalenceDemo.

(** 出了 Section，[negb_path] 带着 [Univalence] 假设：*)
Check negb_path.
Print Assumptions negb_path.

(** * 11.4 导入公理，然后把世界撬起来 *)

Definition sec_11_4_axiom := tt.   Check sec_11_4_axiom.

Require Import HoTT.Axioms.Univalence.
Check univalence_axiom.

(** 现在可以无条件使用 [path_universe]。先看一条著名结论：
    [Type] 本身*不是*集合——因为它有非平凡的自等价。 *)
Check not_hset_Type.

(** 我们自己证一遍，思路是：
    若 [Type] 是集合，则 [Bool = Bool] 的任意两条路径相等；
    但恒等等价与取反等价给出的两条路径并不相等。 *)

Definition negb_equiv : Bool <~> Bool
  := equiv_adjointify negb negb
       (fun b => match b with true => idpath | false => idpath end)
       (fun b => match b with true => idpath | false => idpath end).

Definition negb_path' : Bool = Bool := path_universe negb_equiv.

Definition negb_path_neq_1 : negb_path' <> 1.
Proof.
  intro h.
  apply true_ne_false.               (* 目标变成 [true = false] *)
  (* [transport_path_universe] 说：沿 [negb_path'] 搬运 = 作用 [negb]。
     而 [h] 说这条路径等于 [1]，于是搬运 = 不搬。两者冲突。 *)
  (* 【坑】[@] 不是左结合的，连写三个要显式加括号，
     否则 Rocq 9 会给出 [level-tolerance] 警告（它出现在 stderr 上）。 *)
  exact ((1 @ (ap (fun p : Bool = Bool => transport idmap p true) h)^)
           @ transport_path_universe negb_equiv true).
Defined.
Check negb_path_neq_1.
Print Assumptions negb_path_neq_1.

(** * 11.5 泛等的行为律 *)

Definition sec_11_5_laws := tt.   Check sec_11_5_laws.

Check eta_path_universe.       (* path_universe (equiv_path p) = p *)
Check equiv_path_path_universe.  (* equiv_path (path_universe f) = f *)
Check path_universe_1.         (* path_universe (1 : A <~> A) = 1 *)
Check path_universe_V.         (* path_universe (f^-1) = (path_universe f)^ *)
Check path_universe_compose.   (* path_universe (g oE f) = ... *)

(** 等价归纳（等价版的路径归纳）：*)
Check equiv_induction.
Check equiv_induction'.

(** * 11.6 泛等能做什么：结构沿等价自动搬运 *)

Definition sec_11_6_transport_structures := tt.   Check sec_11_6_transport_structures.

(** 任何定义在类型上的结构都能沿等价搬过去。
    比如把 [Bool] 上的取反搬到任何一个与之等价的两元素类型上。 *)
Check univalent_transport.
Check univalent_transport_idequiv.

(** 更常见的是"两个等价的类型，一个满足某性质则另一个也满足"：*)
Check istrunc_equiv_istrunc.

Definition sec_11_END := tt.   Check sec_11_END.
