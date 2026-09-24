#!/usr/bin/env python3
"""源码卫生检查：SML 字符串里的 ASCII 双引号。

写中文教程时最容易犯的错：在 SML 字符串里用 ASCII 双引号当书名号，

    val _ = out ("规则生成的是"最小集合"（归纳的）。")

SML 会把第一个内部引号当成字符串结束，于是后面全部变成语法错误，
报错点是 "expected closing parenthesis"，离真正的原因有十万八千里。
（本章写作时踩了 6 次，所以有了这个脚本。）

判据（只查代码行，注释行跳过）：
  一个 " 是合法的 SML 字符串定界符，当且仅当
    - 它前面是 ( ^ , = [ ; 或空白，或
    - 它后面是 ) , ; ^ ] 空白 或行尾，
    - 或者它是 \" 转义的一部分。
  其余一律可疑。

用法：
  python3 check-quotes.py            # 检查 examples/（有问题返回 1）
  python3 check-quotes.py --fix      # 顺手把可疑引号改成「」

--fix 只改"可疑"的那些引号，按出现顺序交替填「和」。
"""
import sys
import pathlib

# 允许的"前一个字符"：左括号、拼接符、逗号、等号、方括号、分号、空白
PREV_OK = set('(^,=[]; \t')
# 允许的"后一个字符"：右括号、逗号、分号、拼接符、方括号、空白
NEXT_OK = set('),;^] \t')


def suspicious_positions(line):
    """返回一行里所有"可疑"双引号的下标。"""
    pos = []
    i, n = 0, len(line)
    while i < n:
        ch = line[i]
        if ch == '\\':          # \" 这种转义里的引号不算定界符
            i += 2
            continue
        if ch == '"':
            prev = line[i - 1] if i > 0 else ''
            nxt = line[i + 1] if i + 1 < n else ''
            at_eol = (i == n - 1)          # 行尾的闭合引号是合法的
            if not (prev in PREV_OK or nxt in NEXT_OK or at_eol):
                pos.append(i)
        i += 1
    return pos


def check_file(path, fix=False):
    """返回可疑行列表 [(行号, 行内容)]；fix=True 时改写成「」。"""
    bad = []
    lines = path.read_text(encoding='utf-8').split('\n')
    changed = False
    in_block_comment = False
    for idx, line in enumerate(lines):
        lineno = idx + 1
        s = line.strip()
        # 极简的注释状态机：只跳 (* ... *)。够用 —— 教程脚本的字符串里
        # 不含 (*，注释也不嵌套。
        if in_block_comment:
            if '*)' in s:
                in_block_comment = False
            continue
        if s.startswith('(*'):
            if '*)' not in s:
                in_block_comment = True
            continue
        if not s or s.startswith('*'):
            continue
        pos = suspicious_positions(line)
        if not pos:
            continue
        bad.append((lineno, line))
        if fix:
            chars = list(line)
            for k, i in enumerate(pos):
                chars[i] = '\u300c' if k % 2 == 0 else '\u300d'
            lines[idx] = ''.join(chars)
            changed = True
    if changed:
        path.write_text('\n'.join(lines), encoding='utf-8')
    return bad


def collect(paths):
    """把命令行参数收成文件列表。参数可以是目录或 .sml 文件；
    目录按 <dir>/*/*.sml 展开（本教程的 examples/NN_topic/NN_topic.sml 布局）。

    注意：早期版本只取 args[0] 当根目录 glob，于是传一串文件时
    glob 结果为空、脚本照样打印「检查通过」—— 典型的"假绿"。
    现在对"一个文件都没收到"直接报错退出。
    """
    files = []
    for a in paths:
        p = pathlib.Path(a)
        if p.is_dir():
            files.extend(sorted(p.glob('*/*.sml')))
        elif p.suffix == '.sml':
            files.append(p)
        else:
            print(f'忽略无法识别的参数：{a}')
    return files


def main():
    args = [a for a in sys.argv[1:] if a != '--fix']
    fix = '--fix' in sys.argv[1:]
    files = collect(args) if args else sorted(pathlib.Path('examples').glob('*/*.sml'))
    if not files:
        print('没有找到任何 .sml 文件 —— 检查参数是不是传错了（拒绝"假绿"）。')
        return 2
    total = 0
    for f in files:
        for lineno, line in check_file(f, fix=fix):
            total += 1
            print(f'{f}:{lineno}: 可疑的 ASCII 双引号')
            print(f'    {line.strip()}')
    if fix:
        print(f'已把 {total} 处可疑引号改成「」。请重新编译确认。')
        return 0
    if total:
        print(f'\n共 {total} 处。中文引号请用「」；或跑 {sys.argv[0]} --fix。')
        return 1
    print(f'引号检查通过：{len(files)} 个文件，无可疑 ASCII 双引号。')
    return 0


if __name__ == '__main__':
    sys.exit(main())
