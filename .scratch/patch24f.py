import io
p = 'examples/24_temporal/ex24_label.v'
f = open(p, 'r', encoding='utf-8')
t = f.read()
f.close()
t = t.replace(r'''  - simpl in Hin. unfold interL in Hin. rewrite filter_In in Hin.
    apply satEX_In in Hin. exact (proj1 Hin).
Qed.''', r'''  - simpl in Hin. unfold interL in Hin. rewrite filter_In in Hin.
    destruct Hin as [_ Hmem]. apply memList_In in Hmem.
    apply satEX_In in Hmem. exact (proj1 Hmem).
Qed.''')
f = open(p, 'w', encoding='utf-8')
f.write(t)
f.close()
print('ok')
