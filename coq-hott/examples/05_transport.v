(** 示例 05：Transport 与依赖路径
    把纤维里的元素沿底空间的路径搬运；这是 HoTT 里最核心的操作之一。

    对应文档：docs/05-transport.md *)

Require Import HoTT.
Local Open Scope path_scope.

Definition sec_05_BEGIN := tt.   Check sec_05_BEGIN.

(** * 5.1 [transport] 是什么 *)

Definition sec_05_1_what := tt.   Check sec_05_1_what.

Check transport.
Print transport.

(** 给定 [P : A -> Type]、[p : x = y]、[u : P x]，得到 [transport P p u : P y]。
    直觉：把 [u] 沿着 [p] 平行移动到 [y] 上方的纤维里。
    它的定义就是路径归纳——[p] 是 [1] 时什么都不做。 *)

(** * 5.2 沿常值族搬运：什么都没发生 *)

Definition sec_05_2_const := tt.   Check sec_05_2_const.

Check transport_const.

(** 当 [P] 不依赖底空间时，搬运只是一条路径 [y = y']：*)
Definition transport_const_example (p : true = false) (u : nat)
  : transport (fun _ : Bool => nat) p u = u
  := transport_const p u.
Check transport_const_example.

(** * 5.3 搬运的函子性：拼接、逆 *)

Definition sec_05_3_functorial := tt.   Check sec_05_3_functorial.

Check transport_pp.      (* 先后搬运 = 一次性搬运 *)
Check transport_pV.      (* 沿 p 再沿 p^ 回到原处 *)
Check transport_Vp.
Check transport_pVp.
Check transport_VpV.
Check transport_compose.
Check transport2.

(** * 5.4 [apD] 就是"依赖函数的搬运" *)

Definition sec_05_4_apD := tt.   Check sec_05_4_apD.

Check apD.
Print apD.

(** [apD f p : transport B p (f x) = f y]，而普通 [ap f p : f x = f y]；
    常值族下两者通过 [transport_const] 联系在一起：*)
Check apD_const.

(** * 5.5 用 transport 证明不等：经典的 [true ≠ false] *)

Definition sec_05_5_neq := tt.   Check sec_05_5_neq.

(** 构造一个族：[true] 上是 [Unit]，[false] 上是 [Empty]。 *)
Definition bool_code (b : Bool) : Type := if b then Unit else Empty.
Compute bool_code true.
Compute bool_code false.

(** 若 [true = false]，则 [Unit] 的居民 [tt] 会被搬到 [Empty] 里：*)
Definition true_ne_false_by_transport (p : true = false) : Empty
  := transport bool_code p tt.
Check true_ne_false_by_transport.

Definition my_true_ne_false : true <> false := true_ne_false_by_transport.
Check my_true_ne_false.
Check true_ne_false.

(** * 5.6 依赖路径与 [transport_paths_*] 家族 *)

Definition sec_05_6_dependent_paths := tt.   Check sec_05_6_dependent_paths.

(** 当纤维本身是一个路径类型时，"搬运后的路径"可以显式算出来。
    这是 HoTT 里最常用也最容易算错的一组引理，
    命名规则：[l] 左端点变、[r] 右端点变、[F] 端点上还套着函数。 *)
Check transport_paths_l.
Check transport_paths_r.
Check transport_paths_lr.
Check transport_paths_Fl.
Check transport_paths_Fr.
Check transport_paths_FlFr.

(** 与之配套的是"移项"引理 [moveR] / [moveL]，
    它们把 [transport P p u = v] 与 [u = transport P p^ v] 等价起来。 *)
Check moveR_transport_p.
Check moveL_transport_V.
Check moveR_transport_V.
Check moveL_transport_p.

(** 一个具体使用：[pr1] 在 Σ 类型路径上的行为。 *)
Check pr1_path.
Check transport_pr1_path_sigma.

Definition sec_05_END := tt.   Check sec_05_END.
