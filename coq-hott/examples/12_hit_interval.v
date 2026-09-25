(** 示例 12：高阶归纳类型入门 —— 区间
    [Private Inductive] + 路径构造子，以及如何用区间证明函数外延。

    对应文档：docs/12-hit-interval.md *)

Require Import HoTT.
Local Open Scope path_scope.

Definition sec_12_BEGIN := tt.   Check sec_12_BEGIN.

(** * 12.1 区间是怎么造出来的 *)

Definition sec_12_1_definition := tt.   Check sec_12_1_definition.

Print interval.
Check zero.
Check one.
Check seg.

(** 区间的定义只有三行（见 [HIT/Interval.v]）：

<<
Private Inductive interval : Type0 :=
  | zero : interval
  | one : interval.

Axiom seg : zero = one.
>>

    两个点，外加一条连接它们的*路径构造子*。
    [Private Inductive] 让类型对外封闭，消去子由我们手写。 *)

(** * 12.2 消去子：给两个端点的值 + 一条"跨过 seg"的依赖路径 *)

Definition sec_12_2_eliminators := tt.   Check sec_12_2_eliminators.

Check interval_ind.
Print interval_ind_beta_seg.

(** 非依赖版本更简单：给两点的值和它们之间的一条路径。 *)
Check interval_rec.
Check interval_rec_beta_seg.

(** * 12.3 一个直接后果：区间可缩 *)

Definition sec_12_3_contractible := tt.   Check sec_12_3_contractible.

Check contr_interval.

(** 既然 [seg : zero = one]，而任何点都由 [zero] 或 [one] 给出，
    区间必然可缩——这条引理的证明就是一次 [interval_ind]。 *)

(** * 12.4 区间的杀手级应用：证明函数外延

    关键手法：把"逐点同伦" [p : forall a, f a = g a] 看成
    区间上的一族路径，于是得到一个以区间为参数的函数
    [h : interval -> (forall a, P a)]，它在 [zero] 处是 [f]、在 [one] 处是 [g]。
    再把 [ap h] 作用在 [seg] 上，就得到了 [f = g]。 *)

Definition sec_12_4_funext := tt.   Check sec_12_4_funext.

Definition funext_from_interval {A : Type} (P : A -> Type)
  (f g : forall a : A, P a) (p : forall a : A, f a = g a) : f = g
  := let h := fun (i : interval) (a : A) => interval_rec (P a) (f a) (g a) (p a) i
     in ap h seg.
Check funext_from_interval.
Print Assumptions funext_from_interval.

(** 注意 [Print Assumptions] 的输出：这里*没有*出现 [Funext]！
    函数外延被"证明"了，代价是假设了区间这个 HIT 存在。 *)

(** 对比一下：库里的官方版本在 [Metatheory.IntervalImpliesFunext] 里，
    走的是 [NaiveFunext -> WeakFunext -> Funext] 这条标准路线。 *)
Require Import HoTT.Metatheory.IntervalImpliesFunext.
Check funext_type_from_interval.

(** 这条定理的类型是 [Funext_type]——"函数外延"的一种等价表述。
    库里真正的 [Funext] 类型类实例要从它再转一道手
    （[NaiveFunext -> WeakFunext -> Funext]，见 [Metatheory.FunextVarieties]）。 *)
Check (fun (A : Type) (P : A -> Type) (f g : forall a, P a)
       => funext_from_interval P f g).

(** * 12.5 区间的另一用途：给逐点同伦自动加上自然性 *)

Definition sec_12_5_naturality := tt.   Check sec_12_5_naturality.

(** 若 [p : forall x, f x = x]，那么对任意 [q : x = y]，
    [p x @ q = ap f q @ p y]（自然性方块自动交换）。
    用区间证明只需一行，手工证明则要绕不少路。 *)
Check ap_homotopic_id.
Check concat_A1p.
Check concat_pA1.

(** * 12.6 什么时候该用 HIT

    区间是最小的例子，它说明了 HIT 的两件事：
      1. 类型可以带*路径构造子*，而不只是点构造子；
      2. 消去子必须在 [seg] 上给出一条依赖路径（[transport] 后的相等）。
    更复杂例子（圆、pushout、商类型）都遵循同一套模板。 *)

Definition sec_12_6_summary := tt.   Check sec_12_6_summary.

Check Circle.
Check Pushout.
Check Quotient.

Definition sec_12_END := tt.   Check sec_12_END.
