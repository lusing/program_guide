#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
iosdev 文档一致性 / 输出快照漂移检查器。

它做三件事，任一失败即以退出码 1 结束（可挂进 CI / pre-commit）：

  1) 结构一致：docs/ 与 examples/ 的 01..20 章一一对应，无缺号、无孤儿。
  2) 引用有效：每篇 doc 顶部 `> 示例：` / `> 实测输出见` 指向的路径真实存在。
  3) 快照未漂移：doc 正文里 ```代码块中形如 "  ok ..." / "  FAIL ..." 的**断言行**，
     必须逐字出现在对应示例的 build/NN_*/stdout.debug.txt 里。
     —— 这挡住了「改了示例断言文案，却忘了同步文档里贴的输出」。

用法：
    python3 tools/check_docs.py            # 检查全部
    python3 tools/check_docs.py --verbose  # 打印每条漂移明细

注意：只比对以两个空格 + ok/FAIL 开头的**断言行**；说明行、`--` 小节标题、
`...` 省略行、普通信息行一律跳过（它们在文档里常被手工裁剪，不属于「快照」）。
"""
import os
import re
import sys

TOP = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOCS = os.path.join(TOP, "docs")
EXAMPLES = os.path.join(TOP, "examples")
BUILD = os.path.join(TOP, "build")

# 形如 "  ok   xxx" 或 "  FAIL xxx"（前导两空格，容许更多空格）
ASSERT_LINE = re.compile(r"^\s{2,}(?:ok|FAIL)\b")


def two_digit_dirs(root):
    """返回 root 下形如 NN 或 NN_* 的编号集合 {1..N}。"""
    nums = {}
    if not os.path.isdir(root):
        return nums
    for name in sorted(os.listdir(root)):
        m = re.match(r"^(\d{2})(?:[_-].*)?$", name)
        if m:
            nums[int(m.group(1))] = name
    return nums


def fail(msg, verbose_lines=None, verbose=False):
    print("  FAIL " + msg)
    if verbose and verbose_lines:
        for vl in verbose_lines:
            print("        " + vl)


def main():
    verbose = "--verbose" in sys.argv
    problems = 0

    doc_nums = two_digit_dirs(DOCS)
    ex_nums = two_digit_dirs(EXAMPLES)

    print("== iosdev 文档一致性检查 ==")

    # ---- 1) 结构一致 ----
    print("\n-- 1) docs/ 与 examples/ 编号一一对应 --")
    all_nums = sorted(set(doc_nums) | set(ex_nums))
    expected = list(range(1, 21))
    if all_nums != expected:
        problems += 1
        fail("编号不是完整的 1..20（实际：%s）" % all_nums)
    for n in expected:
        if n not in doc_nums:
            problems += 1
            fail("docs/ 缺少第 %02d 章" % n)
        if n not in ex_nums:
            problems += 1
            fail("examples/ 缺少第 %02d 个示例" % n)
    if problems == 0:
        print("  ok   01..20 章文档与示例齐全、无缺号")

    # ---- 2) 引用有效 ----
    print("\n-- 2) doc 顶部引用的示例/输出路径存在 --")
    ref_problems = 0
    ref_re = re.compile(r"^>\s*(?:示例|实测输出见)[：:]\s*`([^`]+)`")
    for n in expected:
        if n not in doc_nums:
            continue
        doc_file = os.path.join(DOCS, doc_nums[n])
        with open(doc_file, encoding="utf-8") as f:
            head = [next(f, "") for _ in range(8)]
        for ln in head:
            m = ref_re.match(ln)
            if not m:
                continue
            ref = m.group(1)
            # 允许 build/NN_*/stdout.debug.txt 这种带通配的写法：把 * 当占位
            if "*" in ref:
                # 解析成目录前缀，检查目录存在
                prefix = ref.split("*")[0]
                cand = os.path.join(TOP, prefix.rstrip("/"))
                parent = os.path.dirname(cand)
                if not os.path.isdir(parent):
                    ref_problems += 1
                    fail("第 %02d 章引用路径不存在：%s" % (n, ref))
                continue
            if not os.path.exists(os.path.join(TOP, ref)):
                ref_problems += 1
                fail("第 %02d 章引用路径不存在：%s" % (n, ref))
    problems += ref_problems
    if ref_problems == 0:
        print("  ok   所有 `> 示例：` / `> 实测输出见` 引用路径都存在")

    # ---- 3) 输出快照未漂移 ----
    print("\n-- 3) doc 里贴的断言行 == 当前 build 输出 --")
    drift_problems = 0
    for n in expected:
        if n not in doc_nums or n not in ex_nums:
            continue
        doc_file = os.path.join(DOCS, doc_nums[n])
        stdout_file = os.path.join(BUILD, ex_nums[n], "stdout.debug.txt")
        if not os.path.exists(stdout_file):
            # build 产物未生成（还没跑 run-all.sh）——跳过，不算漂移
            continue
        with open(stdout_file, encoding="utf-8") as f:
            stdout = f.read()
        with open(doc_file, encoding="utf-8") as f:
            doc = f.read()

        in_fence = False
        stale = []
        for raw in doc.splitlines():
            if raw.lstrip().startswith("```"):
                in_fence = not in_fence
                continue
            if not in_fence:
                continue
            if ASSERT_LINE.match(raw):
                # 去掉行尾可能的 markdown 尾巴，逐字查找
                needle = raw.rstrip()
                if needle not in stdout:
                    stale.append(needle)
        if stale:
            drift_problems += 1
            fail("第 %02d 章有 %d 行断言与 build 输出不符" % (n, len(stale)),
                 stale[:8], verbose)
    problems += drift_problems
    if drift_problems == 0:
        print("  ok   所有文档里贴出的断言行都能在当前 build 输出中逐字找到（无漂移）")

    print("\n" + "=" * 50)
    if problems == 0:
        print(" 全部检查通过：结构 / 引用 / 快照 均一致")
        print("=" * 50)
        return 0
    print(" 发现 %d 处问题" % problems)
    print("=" * 50)
    return 1


if __name__ == "__main__":
    sys.exit(main())
