From Coq Require Import List.
Import ListNotations.

Module Ex09Modules.

Module NatStack.

Definition stack := list nat.

Definition empty : stack := [].

Definition push (x : nat) (s : stack) : stack := x :: s.

Definition pop (s : stack) : stack :=
  match s with
  | [] => []
  | _ :: tl => tl
  end.

Definition top (s : stack) : option nat :=
  match s with
  | [] => None
  | h :: _ => Some h
  end.

Example top_after_push :
  top (push 5 empty) = Some 5.
Proof. reflexivity. Qed.

Example pop_after_push :
  pop (push 7 (push 1 empty)) = push 1 empty.
Proof. reflexivity. Qed.

End NatStack.

End Ex09Modules.
