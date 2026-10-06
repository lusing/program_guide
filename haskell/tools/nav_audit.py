#!/usr/bin/env python3
# nav_audit.py —— 教程导航与链接审计。
# 用法：python tools/nav_audit.py
# 检查：① 每章页脚 prev/next 链接目标存在；② README 章节表链接存在；
#       ③ H1 标题号 = 文件名号；④ 页脚格式统一（--- 分隔 + ｜ 连接）。
# 退出码 0 = 全部通过。
import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8', errors='replace')
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOCS = os.path.join(ROOT, 'docs')
README = os.path.join(ROOT, 'README.md')

# 尚未落地的章节（写作批次中，链接允许暂时悬空）
PENDING = set()  # 收官：31 章全部落地


def main():
    problems = []
    files = sorted(f for f in os.listdir(DOCS) if re.fullmatch(r'\d{2}-[a-z0-9-]+\.md', f))

    for f in files:
        path = os.path.join(DOCS, f)
        text = open(path, encoding='utf-8').read()
        n = int(f[:2])

        # ③ H1 号 = 文件名号
        m = re.match(r'# (\d{2}) ', text)
        if not m:
            problems.append(f'{f}: H1 不含章号')
        elif int(m.group(1)) != n:
            problems.append(f'{f}: H1 号 {m.group(1)} ≠ 文件名号 {n:02d}')

        # ① 页脚导航
        tail = text.rstrip('\n')
        m = re.search(r'\n---\n\n((?:上一章：.*?)(?: ｜ 下一章：.*?)? ｜ 返回：\[README\]\(\.\./README\.md\))$'
                      r'|\n---\n\n下一章：.*? ｜ 返回：\[README\]\(\.\./README\.md\)$'
                      r'|\n---\n\n上一章：.*? ｜ 下一章：（完） ｜ 返回：\[README\]\(\.\./README\.md\)$', tail)
        if not m:
            problems.append(f'{f}: 页脚导航缺失或格式不对')
        for link, target in re.findall(r'\[(.*?)\]\((\d{2}-[a-z0-9-]+\.md)\)', tail[tail.rfind('---'):]):
            if not os.path.exists(os.path.join(DOCS, target)):
                if target in PENDING:
                    continue
                problems.append(f'{f}: 链接目标不存在 → {target}')
            # 链接文字的章号应等于目标文件号
            if not link.startswith(target[:2]):
                problems.append(f'{f}: 链接文字「{link}」与目标 {target} 章号不符')

    # ② README 表链接
    readme = open(README, encoding='utf-8').read()
    for target in re.findall(r'\]\((docs/(\d{2}-[a-z0-9-]+\.md))\)', readme):
        fname = target[1]
        if not os.path.exists(os.path.join(ROOT, target[0])) and fname not in PENDING:
            problems.append(f'README: 链接目标不存在 → {target[0]}')

    if problems:
        print(f'导航审计：{len(problems)} 个问题')
        for p in problems:
            print(' -', p)
        sys.exit(1)
    print(f'导航审计通过：{len(files)} 章，页脚/链接/H1 全部一致')


if __name__ == '__main__':
    main()
