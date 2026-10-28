(* 第 79 章：树、苏斯林树、马丁公理与划分定理（冯琦 §2.5–2.6）——Coq 通道 *)
(* 有限划分定理（定理 2.51）在最小非平凡情形 R(3,3) 上的可决定性证明：
   (1) K5 存在一种二染色不含单色三角形（红边画五循环 0-1-2-3-4-0，
       蓝边是其补，也是一个五循环），故 R(3,3) > 5；
   (2) K6 的全部 2^15 = 32768 种边二染色，每一种都含单色三角形，
       故 R(3,3) ≤ 6。
   全部用 bool 判定子 + vm_compute 反射：这是对有限命题的完整证明，
   不是抽样。它不能推出任何关于无穷划分 ω→(ω)^2_2 的结论。 *)
From Coq Require Import Bool List Arith.
Import ListNotations.
Set Warnings "-deprecated-since-8.17,-deprecated".

Module Ch79.

(* K_n 的边，按 (i,j) 字典序：第 i 行从 i+1 到 n-1。 *)
Definition edgesn (n : nat) : list (nat * nat) :=
  flat_map (fun i => map (fun j => (i, j)) (seq (i + 1) (n - i - 1)))
           (seq 0 n).

(* K_n 的三元组（候选三角形），同样字典序，共 C(n,3) 个。 *)
Definition trisn (n : nat) : list (nat * nat * nat) :=
  flat_map (fun i =>
    flat_map (fun j => map (fun k => (i, j, k)) (seq (j + 1) (n - j - 1)))
             (seq (i + 1) (n - i - 1)))
    (seq 0 n).

Definition edges5 := edgesn 5.
Definition edges6 := edgesn 6.
Definition tris5 := trisn 5.
Definition tris6 := trisn 6.

(* m 条边的全部 2^m 种二染色：true/false 为两种颜色。 *)
Fixpoint colorings (m : nat) : list (list bool) :=
  match m with
  | 0 => [[]]
  | S m' =>
      let C := colorings m' in
      map (cons true) C ++ map (cons false) C
  end.

(* 边 (i,j) 在字典序列表中的下标：第 i 行之前有 i*(2n-1-i)/2 条边，
   行内再偏移 j-i-1。 *)
Definition eidx (n i j : nat) : nat :=
  i * (2 * n - 1 - i) / 2 + (j - i - 1).

(* 下标表核对：eidx 在 edges6 / edges5 上恰好排出 0..14 / 0..9，
   于是染色表的第 k 个 bool 与边表的第 k 条边严格对齐。 *)
Example eidx6_table : map (fun '(i, j) => eidx 6 i j) edges6 = seq 0 15.
Proof. vm_compute. reflexivity. Qed.

Example eidx5_table : map (fun '(i, j) => eidx 5 i j) edges5 = seq 0 10.
Proof. vm_compute. reflexivity. Qed.

(* 取边 (i,j) 的颜色。 *)
Definition color_of (c : list bool) (n i j : nat) : bool :=
  nth (eidx n i j) c false.

(* 三角形 (i,j,k) 是否单色：三条边同 true 或同 false。 *)
Definition tri_mono (n : nat) (c : list bool) (t : nat * nat * nat) : bool :=
  let '(i, j, k) := t in
  let a := color_of c n i j in
  let b := color_of c n i k in
  let d := color_of c n j k in
  (a && b && d) || (negb a && negb b && negb d).

(* 一种染色是否含单色三角形。 *)
Definition has_mono (n : nat) (c : list bool) : bool :=
  existsb (tri_mono n c) (trisn n).

(* 结构计数核对：15 条边、20 个三角形、32768 种染色。 *)
Example edges6_count : length edges6 = 15.
Proof. vm_compute. reflexivity. Qed.
Example tris6_count : length tris6 = 20.
Proof. vm_compute. reflexivity. Qed.
Example colorings_count : length (colorings 15) = 32768.
Proof. vm_compute. reflexivity. Qed.

(* R(3,3) ≤ 6：穷举全部 32768 种染色，逐一含单色三角形。 *)
Theorem R33_le_6 :
  forallb (fun c => has_mono 6 c) (colorings 15) = true.
Proof. vm_compute. reflexivity. Qed.

(* K5 的见证染色，按 edges5 顺序：红边(true)恰为五循环
   (0,1),(0,4),(1,2),(2,3),(3,4)。 *)
Definition k5_witness : list bool :=
  [true; false; false; true;
   true; false; false;
   true; false;
   true].

(* R(3,3) > 5：该染色无单色三角形（红蓝各是一个五循环，循环无三角形）。 *)
Theorem R33_gt_5 : has_mono 5 k5_witness = false.
Proof. vm_compute. reflexivity. Qed.

(* 附带穷举 K5：1024 种染色中恰有 1012 种含单色三角形，
   12 种不含（12 个标号五循环，与 Julia/Python 通道的独立枚举对账）。 *)
Example k5_mono_count :
  length (filter (fun c => has_mono 5 c) (colorings 10)) = 1012.
Proof. vm_compute. reflexivity. Qed.

End Ch79.
