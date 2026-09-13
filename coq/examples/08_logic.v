Module Ex08Logic.

Theorem and_comm : forall P Q : Prop, P /\ Q -> Q /\ P.
Proof.
  intros P Q H.
  destruct H as [HP HQ].
  split.
  - exact HQ.
  - exact HP.
Qed.

Theorem imp_trans : forall P Q R : Prop, (P -> Q) -> (Q -> R) -> P -> R.
Proof.
  intros P Q R HPQ HQR HP.
  apply HQR.
  apply HPQ.
  exact HP.
Qed.

End Ex08Logic.
