import io
p = 'examples/24_temporal/ex24_label.v'
f = open(p, 'r', encoding='utf-8')
t = f.read()
f.close()

# 在 eufin_to_iter 前插入链式单调
anchor = 'Theorem eufin_to_iter'
chain = r'''Lemma iterEU_mono_le : forall m d1 d2 A B,
  d1 <= d2 -> incl (iterEU m d1 A B) (iterEU m d2 A B).
Proof.
  intros m d1 d2 A B Hle s Hin.
  induction Hle as [| d2' Hle' IH].
  - exact Hin.
  - apply iterEU_mono. exact IH.
Qed.

'''
t = t.replace(anchor, chain + anchor, 1)

start = t.index('Theorem eufin_to_iter')
end = t.index('Qed.', start) + len('Qed.')
new = r'''Theorem eufin_to_iter : forall m (ap bp : nat -> bool) A B d s,
  (forall x, In x A <-> ap x = true) ->
  (forall x, In x B <-> bp x = true) ->
  (forall s0 s', In s' (ftrans m s0) -> In s' (fstates m)) ->
  In s (fstates m) ->
  eufin (ftrans m) (flab m) d s ap bp ->
  In s (iterEU m d A B).
Proof.
  intros m ap bp A B d.
  induction d as [|d' IH]; intros s HA HB Htr Hst H; simpl in H.
  - apply HB. exact H.
  - apply iterEU_In_step.
    destruct H as [Hb | [Ha [s' [Htr' Hd]]]].
    + left. apply iterEU_mono_le with (d1 := 0).
      * lia.
      * apply HB. exact Hb.
    + right. split; [exact Hst|]. split.
      * apply HA. exact Ha.
      * exists s'. split; [exact Htr'|].
        apply IH; auto. exact Hd.
Qed.'''
t = t[:start] + new + t[end:]
f = open(p, 'w', encoding='utf-8')
f.write(t)
f.close()
print('ok')
