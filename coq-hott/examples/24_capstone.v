(** 示例 24：综合实战 —— 圆上的螺旋覆叠
    自己实现一个覆叠空间，算出它的单值变换，并用它证明环路非平凡。

    这是本教程的收束：把路径归纳、transport、等价、泛等、
    高阶归纳类型、编码-解码这几条线拧在一起。

    对应文档：docs/24-capstone.md *)

Require Import HoTT.
Require Import HoTT.Axioms.Univalence.
Local Open Scope path_scope.

Definition sec_24_BEGIN := tt.   Check sec_24_BEGIN.

(** * 24.1 目标

    给任意类型 [X] 与它的一个自等价 [f : X <~> X]，
    在圆上定义一个类型族 [spiral : Circle -> Type]，使得
    "绕 [loop] 一圈"正好执行 [f]。
    然后算出绕 [n] 圈（[n : Int]）的效果，并由此判断环路是否平凡。 *)

Definition sec_24_1_goal := tt.   Check sec_24_1_goal.

Section SpiralCovering.

  Context (X : Type) (f : X <~> X).

  (** * 24.2 构造覆叠

      [Circle_rec Type X (path_universe f)]：基点上挂 [X]，
      绕一圈时沿 [path_universe f] 搬运，也就是作用 [f]。 *)
  Definition spiral : Circle -> Type
    := Circle_rec Type X (path_universe f).

  Check spiral.

  (** * 24.3 计算绕一圈的搬运

      证明分三步，是"覆叠类证明"的标准套路：
        1. 用 [transport_compose] 把 [transport spiral] 拆成
           [transport idmap]（即 [transport (fun X => X)]）与 [ap spiral]；
        2. 用 [Circle_rec_beta_loop] 把 [ap spiral loop] 化成 [path_universe f]；
        3. 用 [transport_path_universe] 把搬运化成 [f]。 *)
  Definition transport_spiral_loop (x : X)
    : transport spiral Circle.loop x = f x.
  Proof.
    refine (transport_compose idmap spiral Circle.loop x @ _).
    rewrite Circle_rec_beta_loop.
    apply transport_path_universe.
  Defined.
  Check transport_spiral_loop.

  (** 反方向绕一圈就是 [f^-1]：*)
  Definition transport_spiral_loopV (x : X)
    : transport spiral Circle.loop^ x = f^-1 x.
  Proof.
    refine (transport_compose idmap spiral Circle.loop^ x @ _).
    rewrite ap_V.
    rewrite Circle_rec_beta_loop.
    rewrite <- (path_universe_V f).
    apply transport_path_universe.
  Defined.
  Check transport_spiral_loopV.

  (** * 24.4 绕 n 圈：路径的自然数次幂

      库里有处理整数次幂的 [loopexp]（负次幂用逆路径），
      但它在 [Spaces.Int] 与 [Spaces.BinInt] 里各有一份同名定义，
      后者会把前者遮蔽掉——直接写 [loopexp] 很容易拿到 BinInt 版本
      而看到莫名其妙的类型错误。这里自己写一个 nat 次幂，顺便把机制讲清楚。 *)
  Fixpoint loopexp_nat {A : Type} {x : A} (p : x = x) (n : nat) : x = x :=
    match n with
    | O => 1
    | S n' => loopexp_nat p n' @ p
    end.

  Fixpoint iter_nat {Y : Type} (g : Y -> Y) (n : nat) (y : Y) : Y :=
    match n with
    | O => y
    | S n' => g (iter_nat g n' y)
    end.

  Definition transport_spiral_loopexp (n : nat) (x : X)
    : transport spiral (loopexp_nat Circle.loop n) x = iter_nat f n x.
  Proof.
    induction n as [|n IH].
    - reflexivity.                                  (* 绕 0 圈：什么都不做 *)
    - simpl.                                        (* 再多绕一圈 *)
      rewrite transport_pp.
      rewrite IH.
      apply transport_spiral_loop.
  Defined.
  Check transport_spiral_loopexp.

  (** * 24.5 应用：绕一圈若是"动了"，则环路非平凡 *)
  Definition spiral_loop_nontrivial (x : X) (hx : f x <> x)
    : Circle.loop <> 1.
  Proof.
    intro h.
    apply hx.
    (* 若 [loop = 1]，则"绕一圈"与"不绕"效果相同，
       于是 [f x = transport spiral loop x = transport spiral 1 x = x]。 *)
    exact ((transport_spiral_loop x)^
             @ ap (fun p : Circle.base = Circle.base => transport spiral p x) h).
  Defined.
  Check spiral_loop_nontrivial.

End SpiralCovering.

(** * 24.6 实例化：用 [Bool] 上的取反 *)

Definition sec_24_6_instance := tt.   Check sec_24_6_instance.

Definition negb_equiv : Bool <~> Bool
  := equiv_adjointify negb negb
       (fun b => match b with true => idpath | false => idpath end)
       (fun b => match b with true => idpath | false => idpath end).

(** 绕一圈的效果（定理）：*)
Check (transport_spiral_loop Bool negb_equiv true).

(** 由"取反确实改变了值"得到 [loop ≠ 1]。
    取 [x := false]：此时 [f x = true ≠ false = x]，正好对上 [true_ne_false]。 *)
Definition loop_nontrivial_via_negb : Circle.loop <> 1
  := spiral_loop_nontrivial Bool negb_equiv false true_ne_false.
Check loop_nontrivial_via_negb.
Print Assumptions loop_nontrivial_via_negb.

(** * 24.7 与库里成品的对照 *)

Definition sec_24_7_compare := tt.   Check sec_24_7_compare.

(** 库里把 [X := Int]、[f := int_succ] 的特例做成了
    [Circle_code] 与 [equiv_loopCircle_int]（第 13 章）：*)
Check Circle_code.
Check equiv_loopCircle_int.
Check Circle_action_is_iter.

(** 我们的 [transport_spiral_loopexp] 正是
    [Circle_action_is_iter] 的一般化表述。 *)

(** * 24.8 回顾：这一路用到的东西 *)

Definition sec_24_8_review := tt.   Check sec_24_8_review.

Check paths.             (* 01–04：恒等类型与路径归纳 *)
Check transport.         (* 05：搬运 *)
Check concat_p_pp.       (* 06：路径代数 *)
Check (fun (A B : Type) (f : A -> B) => IsEquiv f).   (* 07：等价 *)
Check hfiber.            (* 08：纤维与可缩性 *)
Check (fun A : Type => IsHSet A).   (* 09：截断层级 *)
Check path_forall.       (* 10：函数外延 *)
Check path_universe.     (* 11：泛等 *)
Check interval_rec.      (* 12：HIT 与区间 *)
Check Circle_rec.        (* 13：圆 *)
Check equiv_path_sigma.  (* 14：类型构造器 *)
Check merely.            (* 15：截断 *)
Check Quotient.          (* 16：商类型 *)
Check (fun (A B : Type) (f : A -> B) => IsEmbedding f).  (* 17：截断映射 *)
Check univalent_transport.  (* 18：泛等应用 *)
Check Pushout.           (* 19：余极限 *)
Check loops.             (* 21：点化类型 *)
Check int_iter.          (* 22：整数 *)

Definition sec_24_END := tt.   Check sec_24_END.
