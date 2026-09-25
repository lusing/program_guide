(** 示例 13：圆 S¹ 与编码-解码
    一个真正有非平凡环路的类型，以及"如何计算它的环路空间"。

    对应文档：docs/13-circle.md *)

Require Import HoTT.
Require Import HoTT.Axioms.Univalence.   (* 编码-解码要用泛等 *)
Local Open Scope path_scope.

Definition sec_13_BEGIN := tt.   Check sec_13_BEGIN.

(** * 13.1 圆的定义 *)

Definition sec_13_1_definition := tt.   Check sec_13_1_definition.

Check Circle.
Check Circle.base.
Check Circle.loop.

(** 【坑】不要直接写 [base]：全局名字 [base] 属于 [TwoSphere]，
    打开 [HoTT] 后 [base] 解析到的是球面而不是圆。一律写 [Circle.base]。 *)
Check base.          (* 看清楚：这是 TwoSphere.base *)

(** 库里把圆定义为两个 [idmap : Unit -> Unit] 的余等值子（coequalizer），
    这与"一个点 + 一条自环"的朴素定义等价，好处是能直接套用展平引理。 *)

(** * 13.2 消去子：给基点的值 + 一条"绕 loop 一圈"的依赖路径 *)

Definition sec_13_2_eliminators := tt.   Check sec_13_2_eliminators.

Check Circle_ind.
Check Circle_ind_beta_loop.
Check Circle_rec.
Check Circle_rec_beta_loop.

(** 非依赖版本：映到任意类型 [P]，只要指定一个点 [b : P] 和一条自环 [l : b = b]。 *)
Definition circle_to_nat : Circle -> nat := Circle_rec nat 0%nat 1.
Check circle_to_nat.

(** 若 [P] 是集合，自环只能是 [1]，于是这样的映射毫无信息量：*)
Definition circle_to_bool : Circle -> Bool := Circle_rec Bool true 1.
Check circle_to_bool.

(** 反过来，若 [P] 有非平凡自环（比如 [Circle] 自己），映射才有趣。 *)

(** * 13.3 圆的泛性质 *)

Definition sec_13_3_universal := tt.   Check sec_13_3_universal.

Check isequiv_Circle_rec_uncurried.
Check equiv_Circle_rec.

(** [(Circle -> P) ≃ { b : P & b = b }]：
    给一个圆上的映射，就是给"一个点 + 它上面的一条自环"。 *)

(** * 13.4 环路空间 Ω(S¹) ≃ ℤ —— 编码-解码法 *)

Definition sec_13_4_encode_decode := tt.   Check sec_13_4_encode_decode.

(** 库里的成品：*)
Check Circle_code.
Check Circle_encode.
Check Circle_decode.
Check equiv_loopCircle_int.

(** 思路分三步：
      1. 在圆上定义一个类型族 [Circle_code : Circle -> Type]（"覆叠空间"），
         使 [transport] 沿 [loop] 等于整数加一；
      2. 编码 [encode : (base = x) -> Circle_code x]，把路径搬过去；
      3. 解码 [decode : Circle_code x -> (base = x)]，把码变回路径。
    关键是证 [decode] 与 [encode] 互为逆——这一步要对 [x : Circle] 做归纳。 *)

(** 沿 [loop] 搬运就是加一，沿 [loop^] 搬运就是减一：*)
Check transport_Circle_code_loop.
Check transport_Circle_code_loopV.
Check Circle_encode_loopexp.

(** 由此立刻得到 [loop ≠ 1]：*)
Check loopexp.
Check int_succ.

(** * 13.5 自己动手做一次覆叠：用 Bool 证明 [loop ≠ 1]

    不必动用整数——取"沿 [loop] 搬运 = 布尔取反"这个覆叠就够了。
    这是理解编码-解码法的最小实例。 *)

Definition sec_13_5_own_covering := tt.   Check sec_13_5_own_covering.

Definition negb_equiv : Bool <~> Bool
  := equiv_adjointify negb negb
       (fun b => match b with true => idpath | false => idpath end)
       (fun b => match b with true => idpath | false => idpath end).

(** 覆叠：基点上挂 [Bool]，绕一圈执行取反。 *)
Definition my_code : Circle -> Type
  := Circle_rec Type Bool (path_universe negb_equiv).

Definition transport_my_code_loop (b : Bool)
  : transport my_code Circle.loop b = negb b.
Proof.
  refine (transport_compose idmap my_code Circle.loop b @ _).
  rewrite Circle_rec_beta_loop.
  apply transport_path_universe.
Defined.
Check transport_my_code_loop.

Definition loop_nontrivial : Circle.loop <> 1.
Proof.
  intro h.
  apply true_ne_false.            (* 目标：true = false *)
  (* [h] 说 [loop = 1]，于是"绕一圈"和"不绕"效果相同：
     [q : transport my_code loop true = transport my_code 1 true] *)
  pose (q := ap (fun p : Circle.base = Circle.base => transport my_code p true) h).
  exact ((1 @ q^) @ transport_my_code_loop true).
Defined.
Check loop_nontrivial.
Print Assumptions loop_nontrivial.

(** * 13.6 圆是 1-型，且 0-连通 *)

Definition sec_13_6_truncation := tt.   Check sec_13_6_truncation.

Check isconnected_Circle.
Check istrunc_Circle.

(** 圆不是集合（有非平凡自环），但它是一个 1-型：
    任意两点之间的路径构成一个集合（整数）。 *)

(** 圆上的自同伦迭代就是整数倍：*)
Check Circle_action_is_iter.
Check int_iter.

Definition sec_13_END := tt.   Check sec_13_END.
