(** 示例 21：点化类型与环路空间
    [pType]、保点映射、[loops]，以及"圆的基本群是 ℤ"的点化表述。

    对应文档：docs/21-pointed.md *)

Require Import HoTT.
Local Open Scope path_scope.
Local Open Scope pointed_scope.

Definition sec_21_BEGIN := tt.   Check sec_21_BEGIN.

(** * 21.1 点化类型 [pType] *)

Definition sec_21_1_ptype := tt.   Check sec_21_1_ptype.

Check pType.
Check IsPointed.
Check pt.
Print pType.

(** [pType] 就是一个类型加一个选定的基点。
    库里的记号是 [[X, x]]（[pointed_scope]），但它和 [list_scope] 的
    [[a, b, c]] 撞车且没有 scope 定界键（[Delimit Scope]），
    所以在打开了列表记号的文件里一律写 [Build_pType]。 *)
Check Build_pType.
Definition pBool : pType := Build_pType Bool true.
Check pBool.
Compute (pt : pBool).

(** 圆自身也是点化的（基点为 [Circle.base]）：*)
Check pCircle.
Check ispointed_Circle.

(** * 21.2 环路空间 [loops] *)

Definition sec_21_2_loops := tt.   Check sec_21_2_loops.

Check loops.
Print loops.

(** [loops X := (pt = pt)]——所有从基点回到基点的路径。
    它自带一个点（恒等路径），并且可以再取环路，得到高阶结构。 *)
Check (loops pBool).
Check (loops pCircle).

(** * 21.3 保点映射 *)

Definition sec_21_3_pmap := tt.   Check sec_21_3_pmap.

Check Build_pMap.
Check (fun (X Y : pType) => (X ->* Y)).  (* 保点映射的记号 *)
Locate "->*".

(** 一个保点映射不只要给函数，还要给"基点被送到基点"的证据。 *)
Definition pnegb : Bool -> Bool := negb.
Check pnegb.

(** * 21.4 点化等价 *)

Definition sec_21_4_pequiv := tt.   Check sec_21_4_pequiv.

Check pEquiv.
Check Build_pEquiv'.
Locate "<~>*".

(** * 21.5 圆的点化泛性质 *)

Definition sec_21_5_circle := tt.   Check sec_21_5_circle.

(** [(pCircle ->** X) ≃* loops X]：
    从圆出发的保点映射，正好对应目标里的一个环路。
    这是第 13 章泛性质的点化版本。 *)
Check pmap_from_circle_loops.
Check equiv_Circle_rec.

(** * 21.6 编码-解码的点化形式 *)

Definition sec_21_6_encode_decode := tt.   Check sec_21_6_encode_decode.

(** [equiv_loopCircle_int] 本身就是 [loops pCircle ≃ Int] 的等价
    （右边 [Int] 以 [0] 为基点）：*)
Check equiv_loopCircle_int.
Check Circle_encode.
Check Circle_decode.

(** 沿着 [loop] 的整数次幂搬运，等于把自等价迭代相应的次数：*)
Check Circle_action_is_iter.
Check int_iter.

(** * 21.7 为什么要点化 *)

Definition sec_21_7_why := tt.   Check sec_21_7_why.

(** 同伦论里的绝大部分构造（环路、悬置、纤维、上纤维）都依赖基点。
    点化类型把"选基点"这件事变成了类型的一部分，
    于是"保点"不再是每次都要重复写的前提条件，
    而是类型检查器替你维护的约束。 *)
Check Susp.
Check pfiber.

Definition sec_21_END := tt.   Check sec_21_END.
