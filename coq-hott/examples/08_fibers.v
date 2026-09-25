(** 示例 08：同伦纤维与可缩性
    "每个纤维可缩"是判定等价的主力手段；可缩性本身也是 (-2)-截断。

    对应文档：docs/08-fibers.md *)

Require Import HoTT.
Local Open Scope path_scope.

Definition sec_08_BEGIN := tt.   Check sec_08_BEGIN.

(** * 8.1 同伦纤维 [hfiber] *)

Definition sec_08_1_hfiber := tt.   Check sec_08_1_hfiber.

Print hfiber.

(** [hfiber f y := { x : A & f x = y }]：
    所有映到 [y] 的点，连同"映到 [y] 的证据"。
    它衡量的是"解的结构"，而不只是"有没有解"。 *)
Check (fun (A B : Type) (f : A -> B) (y : B) => hfiber f y).

(** * 8.2 可缩类型 [Contr] *)

Definition sec_08_2_contr := tt.   Check sec_08_2_contr.

Check (fun A : Type => Contr A).
Check center.
Check contr.
Print IsTrunc_internal.

(** 可缩 = 有一个中心点，且所有点都与之相连。
    [Contr A] 就是 [IsTrunc (-2) A]。 *)
Definition contr_unit : Contr Unit := Build_Contr _ tt (fun u => match u with tt => 1 end).
Check contr_unit.

(** 可缩类型的任何两点之间都有路径，且这些路径还唯一：*)
Check path_contr.
Check path2_contr.
Check contr_paths_contr.

(** 可缩性沿等价保持：*)
Check contr_equiv'.
Check contr_retract.
Check contr_change_center.

(** * 8.3 纤维可缩 ⟺ 是等价 *)

Definition sec_08_3_iff := tt.   Check sec_08_3_iff.

(** 方向一：等价的每个纤维可缩。 *)
Check contr_map_isequiv.

(** 方向二：所有纤维可缩 ⇒ 是等价（[IsTruncMap (-2) f] 即"所有纤维可缩"）。 *)
Check isequiv_contr_map.
Check IsTruncMap.
Locate "IsEmbedding".

(** 把它写成一条显式的定理，用 [isequiv_adjointify] 给反函数：*)
Definition isequiv_from_contr_fibers {A B : Type} (f : A -> B)
  (H : forall b : B, Contr (hfiber f b)) : IsEquiv f.
Proof.
  srapply isequiv_adjointify.
  - intro b; exact (center (hfiber f b)).1.
  - intro b; exact (center (hfiber f b)).2.
  - intro a.
    (* [contr] 给出 [center (hfiber f (f a)) = (a; 1)]，取第一分量即为所求。
       注意 [contr] 的 [Contr] 实例是隐式参数，这里要显式给：*)
    exact (ap pr1 (@contr (hfiber f (f a)) (H (f a)) (a; 1))).
Defined.
Check isequiv_from_contr_fibers.

(** * 8.4 经典例子：带基点的路径类型是可缩的 *)

Definition sec_08_4_basedpaths := tt.   Check sec_08_4_basedpaths.

Check contr_basedpaths.
Check contr_basedpaths'.

(** [{ y : X & x = y }] 可缩——中心是 [(x; 1)]。
    这条引理是"Σ 类型上的路径归纳"的引擎。 *)

(** 由它立刻得到：把第二分量忘掉是等价。 *)
Check isequiv_pr1.
Check equiv_pr1.

(** 同理，"所有纤维可缩的 Σ 上的 pr1"也是等价：*)
Check equiv_sigma_contr.

(** * 8.5 纤维内部的路径长什么样 *)

Definition sec_08_5_paths_in_fibers := tt.   Check sec_08_5_paths_in_fibers.

Check equiv_path_hfiber.
Check path_hfiber.

(** 纤维里两点 [x1 x2 : hfiber f y] 之间的路径，等价于
    一条底空间路径 [q : x1.1 = x2.1] 加上一个相容条件。
    这是"纤维化"这一概念在类型论里的精确形式。 *)

(** * 8.6 可缩 ⇒ 是命题 ⇒ 是集合（预告）

    截断层级是往上走的：可缩（-2）⇒ h-prop（-1）⇒ h-set（0）。
    第 09 章展开这条链。 *)
Definition sec_08_6_preview := tt.   Check sec_08_6_preview.

Check istrunc_contr.
Check hprop_inhabited_contr.

(** 一个 h-prop 只要有一个居民就可缩：*)
Check (fun (A : Type) => hprop_inhabited_contr A).

Definition sec_08_END := tt.   Check sec_08_END.
