import io
p = 'examples/30_totalcorrect/ex30_totalcorrect.v'
f = open(p, 'r', encoding='utf-8')
t = f.read()
f.close()
t = t.replace(r'''Lemma amin_le_left : forall u v, amin u v <= u.
Proof. intros u v. unfold amin. destruct (Nat.leb u v); lia. Qed.

Lemma amin_le_right : forall u v, amin u v <= v.
Proof. intros u v. unfold amin. destruct (Nat.leb u v); lia. Qed.''',
r'''Lemma amin_le_left : forall u v, amin u v <= u.
Proof.
  intros u v. unfold amin. destruct (Nat.leb u v) eqn:E.
  - apply Nat.leb_le in E. lia.
  - apply Nat.leb_gt in E. lia.
Qed.

Lemma amin_le_right : forall u v, amin u v <= v.
Proof.
  intros u v. unfold amin. destruct (Nat.leb u v) eqn:E.
  - apply Nat.leb_le in E. lia.
  - apply Nat.leb_gt in E. lia.
Qed.''')
f = open(p, 'w', encoding='utf-8')
f.write(t)
f.close()
print('ok')
