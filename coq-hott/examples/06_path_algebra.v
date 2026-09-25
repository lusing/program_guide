(** 示例 06：路径代数
    一维的群胚律、二维的同伦运算、以及移项术（moveR / moveL）。

    对应文档：docs/06-path-algebra.md *)

Require Import HoTT.
Local Open Scope path_scope.

Definition sec_06_BEGIN := tt.   Check sec_06_BEGIN.

(** * 6.1 一维：路径构成一个群胚

    [1] 是单位元，[@] 是乘法，[^] 是取逆。但注意：
    [p @ q @ r] 的结合律不是"定义上相等"，而是一条*路径*。 *)

Definition sec_06_1_groupoid := tt.   Check sec_06_1_groupoid.

Check concat_p1.          (* p @ 1 = p *)
Check concat_1p.          (* 1 @ p = p *)
Check concat_p_pp.        (* p @ (q @ r) = (p @ q) @ r *)
Check concat_pp_p.        (* (p @ q) @ r = p @ (q @ r) *)
Check concat_pV.          (* p @ p^ = 1 *)
Check concat_Vp.          (* p^ @ p = 1 *)
Check inv_pp.             (* (p @ q)^ = q^ @ p^ *)
Check inv_V.              (* (p^)^ = p *)

(** [rewrite] 用这些引理时方向很关键：库里同时提供了正反两种命名，
    记不住就用 [lhs] / [rhs] 显式改写（见 6.4）。 *)

(** * 6.2 二维：路径之间的路径 *)

Definition sec_06_2_two_dimensional := tt.   Check sec_06_2_two_dimensional.

(** [concat2] 把两条 2-路径"横向"并置：*)
Check concat2.

(** [whiskerL] / [whiskerR] 在 2-路径的一侧补上一条 1-路径：*)
Check whiskerL.
Check whiskerR.

(** 它们各自的运算律：*)
Check whiskerL_pp.
Check whiskerR_pp.
Check whiskerL_1p.
Check whiskerR_p1.

(** [ap] 也能作用在 2-路径上（它就是 [ap (ap f)]）：*)
Check ap.
Check (fun (A B : Type) (f : A -> B) (x y : A) (p q : x = y) => ap (ap f)).

(** * 6.3 Eckmann–Hilton：二阶环路必交换 *)

Definition sec_06_3_eckmann_hilton := tt.   Check sec_06_3_eckmann_hilton.

Check eckmann_hilton.

(** 这个结论在 HoTT 里格外重要：它说明"环路空间的环路空间"永远是交换的，
    所以基本群（1-维）之上才有交换的 π₂、π₃…… *)

(** * 6.4 移项术：[moveR] / [moveL]

    证明形状为 [p @ q = r] 的等式时，手工做 [concat]/[inverse] 的组合很痛苦。
    库里提供了成套的"移项"引理：
      [moveR_Vp  : p = r @ q -> r^ @ p = q]
      [moveL_Vp  : r @ q = p -> q = r^ @ p]
      [moveR_Mp  : p = r^ @ q -> r @ p = q]
      ……
    命名规则：[M] 表示移项后带 ^（minus），[V] 表示被移的那条原本是 ^，
    [p] / [1] 表示等式里出现的是路径还是单位元。 *)

Definition sec_06_4_moves := tt.   Check sec_06_4_moves.

Check moveR_Mp.
Check moveR_pM.
Check moveR_Vp.
Check moveR_pV.
Check moveL_Mp.
Check moveL_pM.
Check moveL_Vp.
Check moveL_pV.
Check moveL_1M.
Check moveR_1M.

(** 一个手工例子：证明 [p^ @ (p @ q) = q]。
    用路径归纳一步就好——这也是 HoTT 证明最常用的节奏。 *)
Definition cancel_p_left {A : Type} {x y z : A} (p : x = y) (q : y = z)
  : p^ @ (p @ q) = q.
Proof.
  destruct p; destruct q; reflexivity.
Defined.
Check cancel_p_left.

(** 库里对应的引理叫 [concat_V_pp]：*)
Check concat_V_pp.

(** * 6.5 [lhs] / [rhs]：把改写锁定在等式的一侧 *)

Definition sec_06_5_lhs_rhs := tt.   Check sec_06_5_lhs_rhs.

(** 目标 [a = c] 时，[lhs napply e] 会把左边 [a] 改成 [e] 的左端，
    把目标变成 [e 的右端 = c]。这是 HoTT 库里到处可见的写法。 *)
Definition demo_lhs {A : Type} {x y : A} (p : x = y) : 1 @ p = p.
Proof.
  lhs napply (concat_1p p).   (* 把左边 [1 @ p] 重写成 [p]，目标变成 [p = p] *)
  reflexivity.
Defined.
Check demo_lhs.

(** [rhs] 反过来改写等式的右边：*)
Definition demo_rhs {A : Type} {x y : A} (p : x = y) : p = 1 @ p.
Proof.
  rhs napply (concat_1p p).
  reflexivity.
Defined.
Check demo_rhs.

(** * 6.6 一个完整的小证明：逆的唯一性 *)

Definition sec_06_6_inverse_unique := tt.   Check sec_06_6_inverse_unique.

Definition inverse_unique {A : Type} {x y : A} (p : x = y) (q : y = x)
  (h : p @ q = 1) : q = p^.
Proof.
  destruct p; simpl in *.
  (* 此时目标 [q = 1]，而 [h : 1 @ q = 1]，
     先用 [concat_1p q : 1 @ q = q] 的逆把左边换成 [q]：*)
  exact ((concat_1p q)^ @ h).
Defined.
Check inverse_unique.

(** 库里现成的是 [moveL_pV] 与 [moveR_M1] 的组合思路。 *)
Check moveR_M1.
Check moveL_M1.

Definition sec_06_END := tt.   Check sec_06_END.
