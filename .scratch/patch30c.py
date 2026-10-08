import io
p = 'examples/30_totalcorrect/ex30_totalcorrect.v'
f = open(p, 'r', encoding='utf-8')
t = f.read()
f.close()
t = t.replace(r'''      + destruct (Hbody (V s1) s1) as [s2 [Hex Hstep]].
        { split; [exact HP|exact Eb]. split; [reflexivity|].
          lia. }''', r'''      + assert (Hpre : P s1 /\ b s1 = true /\ V s1 = V s1).
        { split; [exact HP|exact Eb]. split; reflexivity. }
        destruct (Hbody (V s1) s1 Hpre) as [s2 [Hex Hstep]].''')
f = open(p, 'w', encoding='utf-8')
f.write(t)
f.close()
print('ok')
