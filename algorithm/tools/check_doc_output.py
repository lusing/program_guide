"""校验文档 ```text 块 == 实测输出的顺序敏感子序列（逐字比对，含行尾空格）。"""
import re
import sys

doc_path, out_path = sys.argv[1], sys.argv[2]
doc = open(doc_path, encoding='utf-8', newline='').read().replace('\r\n', '\n')
out = open(out_path, encoding='utf-8', newline='').read().replace('\r\n', '\n').split('\n')

blocks = re.findall(r'```text\n(.*?)```', doc, re.S)
bad = 0
for bi, b in enumerate(blocks):
    lines = b.rstrip('\n').split('\n')
    j = 0  # out 上的游标
    for line in lines:
        if line.strip() == '':
            continue
        k = j
        while k < len(out) and out[k] != line:
            k += 1
        if k >= len(out):
            print(f'  block{bi} NOT FOUND (after out line {j}): {line!r}')
            bad += 1
        else:
            j = k + 1
print(f'{doc_path}: {len(blocks)} text blocks, {bad} mismatches')
sys.exit(1 if bad else 0)
