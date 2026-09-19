(* 03 第一个证明 —— 解剖 Proof / reflexivity / Qed，以及失败长什么样
   注意：不 Require Import Arith 的话，nat 上的 "/" 记号不存在，
   写 8 / 2 会直接报 Unknown interpretation for notation "_ / _"。
   这本身就是本教程记录的第一个实测坑。 *)

From Coq Require Import Arith.

Module Ex03FirstProof.

(* ---------- 定义一个可计算函数 ---------- *)

Definition square (n : nat) : nat := n * n.

Compute (square 3).   (* = 9 : nat *)
Check (square 3).     (* square 3 : nat *)
Print square.         (* square = fun n : nat => n * n *)

(* ---------- 断言 + 证明 ---------- *)

Example square_3 : square 3 = 9.
Proof. reflexivity. Qed.

(* 四行拆开读：
   Example square_3 : square 3 = 9.
      —— 陈述：声明一个类型为「等式命题」的对象
   Proof.
      —— 进入证明模式：屏幕上会出现 1 个目标
   reflexivity.
      —— 策略：把等式两边化简到同一形状，
         构造证明项 eq_refl
   Qed.
      —— 封印：把整个脚本转成一个证明项，
         交给内核重新做类型检查后存档 *)

(* ---------- 证明也是一个项 ---------- *)

Print square_3.
(* square_3 = eq_refl : square 3 = 9
   —— 证明不是走个过场，而是一个货真价实的项。
   它的类型恰好是那个命题——这就是 Curry-Howard 对应 *)

(* ---------- 失败长什么样 ---------- *)

(* 把 reflexivity 用在两边不等的等式上，Coq 会拒绝。
   Fail 用来预言失败：被它包住的命令必须失败，
   否则 coqc 反而报错——因此下面整段能编译通过。 *)

Example broken : 2 + 2 = 5.
Proof.
  Fail reflexivity.
  (* 在 coqtop 里会看到：
     The command has indeed failed with message:
     Unable to unify "5" with "4".
     （coqc 批处理下 Fail 静默成功，提示语不打印——实测） *)
Abort.
(* Abort 放弃这个证明，文件才能继续往下编译。
   实战中应当直接删掉失败的尝试，这里保留纯为演示。 *)

(* 类型错误同样可以被 Fail 预言： *)

Fail Check (0 : bool).
(* The term "0" has type "nat" while it is expected to have
   type "bool". —— 提示语同样只在交互模式可见 *)

Fail Definition bad : bool := 0.
(* 同样的类型错误，发生在定义处 *)

(* ---------- Theorem 家族：全是同义词 ---------- *)

Theorem plus_2_2 : 2 + 2 = 4.
Proof. reflexivity. Qed.

Lemma times_3_4 : 3 * 4 = 12.
Proof. reflexivity. Qed.

Fact half_of_8 : 8 / 2 = 4.
Proof. reflexivity. Qed.

(* Theorem / Lemma / Fact / Remark / Corollary / Example / Property
   在 Coq 里语法地位完全相同，选哪个纯看语义习惯。 *)

End Ex03FirstProof.
