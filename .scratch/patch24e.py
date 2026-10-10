import io
p = 'examples/24_temporal/ex24_label.v'
f = open(p, 'r', encoding='utf-8')
t = f.read()
f.close()
t = t.replace(r'''      * exists s'. split; [exact Htr'|].
        apply IH; auto. exact Hd.''', r'''      * exists s'. split; [exact Htr'|].
        exact (IH s' HA HB Htr (Htr s s' Htr') Hd).''')
f = open(p, 'w', encoding='utf-8')
f.write(t)
f.close()
print('ok')
