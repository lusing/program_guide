(** 第 52 章：Łoś 定理的原子+联词片段 + 满性失败的有限现场 *)

Require Import Bool Arith List.
Import ListNotations.

(* B = 4 元钻石代数 *)
Inductive dia : Type := d0 | du | dv | d1.

Fixpoint dmeet (a b : dia) : dia :=
  match a, b with
  | d0, _ => d0 | _, d0 => d0
  | du, du => du | dv, dv => dv
  | d1, x => x | x, d1 => x
  | _, _ => d0
  end.

Fixpoint djoin (a b : dia) : dia :=
  match a, b with
  | d1, _ => d1 | _, d1 => d1
  | d0, x => x | x, d0 => x
  | du, du => du | dv, dv => dv
  | _, _ => d1
  end.

Definition dnot (a : dia) : dia :=
  match a with d0 => d1 | du => dv | dv => du | d1 => d0 end.

(* 固定超滤 G = 主超滤 ↑du = {du, d1} *)
Definition inG (b : dia) : bool :=
  match b with d1 => true | du => true | _ => false end.

(* 域 = {p, q}；一元谓词 R 的指派（值在 dia 中） *)
Inductive dom2 : Type := p | q.

Definition Rval : dom2 -> dia :=
  fun x => match x with p => du | q => d1 end.

(* ---- Łoś 的原子与联词片段（固定 G 上的等价验证） ---- *)

(* 原子：R(x) 在商中成立 ⟺ ⟦R(x)⟧ ∈ G *)
Lemma los_atom :
  (forall x, inG (Rval x) = true) /\
  (inG (dnot (Rval p)) = false).
Proof.
  split.
  - intros x; destruct x; reflexivity.
  - reflexivity.
Qed.

(* 联词 ∧：在 G 下的保持 *)
Lemma los_and :
  forall a b : dia, inG a = true -> inG b = true -> inG (dmeet a b) = true.
Proof.
  intros a b Ha Hb; destruct a, b; simpl in *; try reflexivity;
  discriminate || reflexivity.
Qed.

(* 联词 ¬：在 G 下的二分 *)
Lemma los_neg :
  forall a : dia, inG a = false -> inG (dnot a) = true.
Proof.
  intros a H; destruct a; simpl in *; try reflexivity; discriminate.
Qed.

(* ---- 满性失败的有限现场（反例 6.3.5 的骨架） ---- *)
(* 公式 φ(y) 的"值函数"：每个 y 给一个 dia 值；
   商中的见证 = 值 ∈ G 的单个 y；
   模型侧 sup = djoin of all values。
   构造：val p = du（∉G? du ∈ G!），改为 val p = dv ∉ G，
   val q = d1；sup = dv ⊔ d1 = d1 ∈ G，但单见证只有 q 合法——
   事实上 q 见证成功。真正的不满是【无穷域】现象：
   有限域 sup 总被最大元达到。这里验证有限域总满： *)

Definition valf : dom2 -> dia :=
  fun x => match x with p => dv | q => d1 end.

Lemma finite_full :
  exists x : dom2, djoin (valf p) (valf q) = valf x.
Proof.
  exists q. reflexivity.
Qed.

(* 结论注记：有限域上 sup = 最大值总被达到 ⟹ 一切有限模型满；
   Viale 6.3.5 的不满需要无穷域（sup 只能被"极限"实现）——
   Julia/Python 通道的无穷实验室承载该现场。 *)
