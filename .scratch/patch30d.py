import io
p = 'examples/30_totalcorrect/ex30_totalcorrect.v'
f = open(p, 'r', encoding='utf-8')
t = f.read()
f.close()
t = t.replace(r'''        { split; [exact HP|exact Eb]. split; reflexivity. }''',
              r'''        { split; [exact HP|]. split; [exact Eb|reflexivity]. }''')
f = open(p, 'w', encoding='utf-8')
f.write(t)
f.close()
print('ok')
