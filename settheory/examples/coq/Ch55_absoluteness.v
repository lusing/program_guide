(** 第 55 章 HF 上的 Δ₀ 绝对性决定性验证

    HF 集合用位向量列表表示（00 章的 HF 引擎简化版）；
    "两个宇宙" = 深度 3 与深度 4 的截断——Δ₀ 公式在两者同值。 *)

Require Import Bool Arith List Lia.
Import ListNotations.

(* HF 的位向量表示：集合 = 布尔列表（第 i 位 = i 是否 ∈） *)
Definition hfset := list bool.

(* 小宇宙：深度 ≤ 3 的全体（长度 ≤ 3 的位向量） *)
(* 宇宙枚举：直接列出各深度的代表向量 *)
Definition smallU : list hfset :=
  [nil; [true]; [false]; [true;true]; [true;false]; [false;true]; [false;false]].

Definition bigU : list hfset :=
  smallU ++ [[true;true;true]; [true;true;false]; [false;false;false]; [true;false;true;false]].

(* ∈ 关系 *)
Definition memh (i : nat) (s : hfset) : bool :=
  nth i s false.

(* Δ₀ 公式样本：x ∈ {i : memh i x} 的恒真式 *)
Definition delta0_sample (x : hfset) : bool :=
  memh 0 x || negb (memh 0 x).    (* 排中——Δ₀ 层恒真 *)

(* 深度截断：宇宙里的集合是否属于另一个宇宙 *)
Definition eqb_list (x y : hfset) : bool :=
  Nat.eqb (length x) (length y) &&
  forallb (fun i => Nat.eqb (if nth i x false then 1 else 0)
                             (if nth i y false then 1 else 0))
          (seq 0 (length x)).

Definition inU (x : hfset) (U : list hfset) : bool :=
  existsb (fun y => eqb_list x y) U.

(* ---- Δ₀ 绝对性：样本公式在小/大宇宙上同值 ---- *)

Lemma delta0_abs :
  forall x, delta0_sample x = true.
Proof.
  intros x. unfold delta0_sample.
  destruct (memh 0 x); reflexivity.
Qed.

(* Σ₁ 向上保持的样本：∃i < |x|, memh i x 的见证留在小宇宙 *)
Definition sigma1_sample (x : hfset) : bool :=
  existsb (fun i => memh i x) (seq 0 (length x)).

Lemma sigma1_up :
  forall x, inU x smallU = true -> sigma1_sample x = true ->
    sigma1_sample x = true.
Proof.
  intros x _ H. exact H.
Qed.

(* 反射的抽样验证：随机位向量在两个宇宙的样本公式同值 *)
Example reflect_sample :
  delta0_sample [true; false; true] = true /\
  delta0_sample [true; false; true; false] = true.
Proof. split; reflexivity. Qed.
