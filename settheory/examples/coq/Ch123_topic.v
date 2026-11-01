Require Import Arith.

(* 第 123 章：六个教学阶段上的有限三轴关系；不形式化无限数学。 *)

Inductive stage : Type :=
  stage0 | stage1 | stage2 | stage3 | stage4 | stage5.

Definition code (s : stage) : nat :=
  match s with
  | stage0 => 0 | stage1 => 1 | stage2 => 2
  | stage3 => 3 | stage4 => 4 | stage5 => 5
  end.

Definition strength_code (s : stage) : nat := code s.
Definition forcing_code (s : stage) : nat := code s.
Definition regularity_code (s : stage) : nat := code s.

Theorem three_axes_coherent :
  forall s : stage,
    strength_code s = code s /\
    forcing_code s = code s /\
    regularity_code s = code s.
Proof. intros []; repeat split; reflexivity. Qed.

Theorem six_stage_cases :
  forall s : stage,
    s = stage0 \/ s = stage1 \/ s = stage2 \/
    s = stage3 \/ s = stage4 \/ s = stage5.
Proof. intros []; intuition. Qed.

Definition next (s : stage) : option stage :=
  match s with
  | stage0 => Some stage1 | stage1 => Some stage2
  | stage2 => Some stage3 | stage3 => Some stage4
  | stage4 => Some stage5 | stage5 => None
  end.

Theorem chain_endpoints :
  next stage0 = Some stage1 /\ next stage5 = None.
Proof. split; reflexivity. Qed.
