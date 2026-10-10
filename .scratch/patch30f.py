import io
p = 'examples/30_totalcorrect/ex30_totalcorrect.v'
f = open(p, 'r', encoding='utf-8')
t = f.read()
f.close()
t = t.replace(r'''  apply (hoareT_while_layered
    (P := fun s => s x + s y = C)
    (b := fun s => negb (Nat.eqb (s x) 0))
    (c := cseq (cass x (fun s => s x - 1)) (cass y (fun s => s y + 1)))
    (V := fun s => s x)).''', r'''  apply (hoareT_while_layered
           (fun s => s x + s y = C)
           (fun s => negb (Nat.eqb (s x) 0))
           (cseq (cass x (fun s => s x - 1)) (cass y (fun s => s y + 1)))
           (fun s => s x)).''')
f = open(p, 'w', encoding='utf-8')
f.write(t)
f.close()
print('ok')
