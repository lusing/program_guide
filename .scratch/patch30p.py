import io
p = 'examples/30_totalcorrect/ex30_totalcorrect.v'
f = open(p, 'r', encoding='utf-8')
t = f.read()
f.close()
t = t.replace(r'''Proof. intros u H. unfold amin. destruct (Nat.leb (u + 1) 1); lia. Qed.''',
r'''Proof.
  intros u H. unfold amin. destruct (Nat.leb (u + 1) 1) eqn:E.
  - apply Nat.leb_le in E. lia.
  - apply Nat.leb_gt in E. lia.
Qed.''')
f = open(p, 'w', encoding='utf-8')
f.write(t)
f.close()
print('ok')
