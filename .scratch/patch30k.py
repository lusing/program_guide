import io
p = 'examples/30_totalcorrect/ex30_totalcorrect.v'
f = open(p, 'r', encoding='utf-8')
t = f.read()
f.close()
t = t.replace(r'''      - rewrite Nat.eqb_refl in Hbs. discriminate.
      - reflexivity. }''', r'''      - rewrite Nat.eqb_refl in Hbs. discriminate.
      - discriminate. }''')
f = open(p, 'w', encoding='utf-8')
f.write(t)
f.close()
print('ok')
