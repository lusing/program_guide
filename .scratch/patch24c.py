import io
p = 'examples/24_temporal/ex24_label.v'
f = open(p, 'r', encoding='utf-8')
t = f.read()
f.close()
start = t.index('Lemma eufin_mono')
end = t.index('Qed.', start) + len('Qed.')
new = r'''Lemma eufin_mono : forall k l d s a b,
  eufin k l d s a b -> eufin k l (S d) s a b.
Proof.
  intros k l d. induction d as [|d' IH]; intros s a b H; simpl in *.
  - left. exact H.
  - destruct H as [Hb | [Ha [s' [Htr Hd]]]].
    + left. exact Hb.
    + right. split; [exact Ha|]. exists s'. split; [exact Htr|].
      apply IH. exact Hd.
Qed.'''
t = t[:start] + new + t[end:]
f = open(p, 'w', encoding='utf-8')
f.write(t)
f.close()
print('ok')
