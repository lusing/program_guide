import io
p = 'examples/30_totalcorrect/ex30_totalcorrect.v'
f = open(p, 'r', encoding='utf-8')
t = f.read()
f.close()
t = t.replace(r'''  intros s1 HP. apply Hmain; [exact HP | apply Nat.le_0_l].
Qed.

(* ---------- countdown 的完全正确性 ---------- *)''', r'''  intros s1 HP. apply (Hmain (V s1) s1 HP (Nat.le_refl _)).
Qed.

(* ---------- countdown 的完全正确性 ---------- *)''')
f = open(p, 'w', encoding='utf-8')
f.write(t)
f.close()
print('ok')
