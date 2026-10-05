"""把实测输出中匹配到的行「原样」（含行尾空格）回填到文档 ```text 块。

用法：python tools/sync_doc_output.py <doc.md> <out.txt>
对每个 text 块，逐行在实测输出里顺序敏感地查找；查到就把该行替换成
实测输出的原文（保留行尾空格），查不到则报告。
"""
import re
import sys

doc_path, out_path = sys.argv[1], sys.argv[2]
doc = open(doc_path, encoding='utf-8', newline='').read().replace('\r\n', '\n')
out = open(out_path, encoding='utf-8', newline='').read().replace('\r\n', '\n').split('\n')


def norm(s):
    return s.rstrip()


blocks = list(re.finditer(r'```text\n(.*?)```', doc, re.S))
missing = 0
for bi, m in enumerate(blocks):
    body = m.group(1)
    lines = body.rstrip('\n').split('\n')
    j = 0
    new_lines = []
    for line in lines:
        if line.strip() == '':
            new_lines.append(line)
            continue
        k = j
        while k < len(out) and norm(out[k]) != norm(line):
            k += 1
        if k >= len(out):
            print(f'  block{bi} NOT FOUND: {line!r}')
            missing += 1
            new_lines.append(line)
        else:
            new_lines.append(out[k].rstrip('\n'))
            j = k + 1
    new_body = '\n'.join(new_lines) + '\n'
    doc = doc[:m.start(1)] + new_body + doc[m.end(1):]

if True:
    open(doc_path, 'w', encoding='utf-8', newline='').write(doc.replace('\n', '\r\n'))
print(f'{doc_path}: {len(blocks)} blocks, {missing} not found (已回填全部命中行)')
sys.exit(1 if missing else 0)
