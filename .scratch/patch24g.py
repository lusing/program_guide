import io
p = 'examples/24_temporal/ex24_label.v'
f = open(p, 'r', encoding='utf-8')
t = f.read()
f.close()
start = t.index('Lemma iterEG_anti')
end = t.index('Admitted.', start) + len('Admitted.')
# 删除整段（含尾部空行）
t = t[:start] + t[end:].lstrip('\n')
f = open(p, 'w', encoding='utf-8')
f.write(t)
f.close()
print('ok')
