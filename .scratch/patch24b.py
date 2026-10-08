import io
p = 'examples/24_temporal/ex24_label.v'
f = open(p, 'r', encoding='utf-8')
t = f.read()
f.close()
start = t.index('Lemma iterEU_In_step')
end = t.index('Qed.', start) + len('Qed.')
new = r'''Lemma iterEU_In_step : forall m fuel A B s,
  In s (iterEU m (S fuel) A B) <->
  In s (iterEU m fuel A B) \/
  (In s (fstates m) /\ In s A /\
   exists s', In s' (ftrans m s) /\ In s' (iterEU m fuel A B)).
Proof.
  intros m fuel A B s. simpl.
  rewrite unionL_In, interL_In, satEX_In. tauto.
Qed.'''
t = t[:start] + new + t[end:]
f = open(p, 'w', encoding='utf-8')
f.write(t)
f.close()
print('ok')
