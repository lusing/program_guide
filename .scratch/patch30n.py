import io
p = 'examples/30_totalcorrect/ex30_totalcorrect.v'
f = open(p, 'r', encoding='utf-8')
t = f.read()
f.close()
t = t.replace(r'''        assert (Hy : upd (upd s x (s x - 1)) y
                        (upd s x (s x - 1) y + 1) y = s y + 1).
        { unfold upd. destruct (Nat.eqb y x) eqn:Eyx.
          - apply Nat.eqb_eq in Eyx. congruence.
          - rewrite Nat.eqb_refl. exact Hyr. }''', r'''        assert (Hy : upd (upd s x (s x - 1)) y
                        (upd s x (s x - 1) y + 1) y = s y + 1).
        { unfold upd at 1. destruct (Nat.eqb y x) eqn:Eyx.
          - apply Nat.eqb_eq in Eyx. congruence.
          - rewrite Nat.eqb_refl, Hyr. reflexivity. }''')
f = open(p, 'w', encoding='utf-8')
f.write(t)
f.close()
print('ok')
