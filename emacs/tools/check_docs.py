#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_docs.py — 核查 Emacs 教程的结构完整性

检查项：
1. 每章 H1 格式正确（`# NN · 标题` 或 `# 附录 X · 标题`）
2. 每章 footer 导航链接文字与目标 H1 逐字一致
3. README 中列出的章节链接都存在
4. extending-emacs: 示例文件与文档按章号配对

用法：
  python3 tools/check_docs.py              # 正常核查
  python3 tools/check_docs.py --mutate     # 自检：故意改坏一个文件，确认能检出
"""
import os
import re
import sys
from pathlib import Path

EMACS_DIR = Path(__file__).parent.parent
USING_DIR = EMACS_DIR / "docs" / "using-emacs"
EXTENDING_DIR = EMACS_DIR / "docs" / "extending-emacs"
EXAMPLES_DIR = EMACS_DIR / "examples"

H1_RE = re.compile(r"^# (\d{2}|附录 [AB]) · (.+)$")
FOOTER_RE = re.compile(
    r"^上一章：(?:\[([^\]]+)\]\(([^)]+)\)|（无上一章）)\s+｜\s+"
    r"下一章：(?:\[([^\]]+)\]\(([^)]+)\)|（无下一章）)\s+｜\s+"
    r"返回：\[([^\]]+)\]\(([^)]+)\)$"
)


def read_file(path):
    return path.read_text(encoding="utf-8")


def extract_h1(text):
    """Extract H1 from first line."""
    first_line = text.split("\n", 1)[0]
    m = H1_RE.match(first_line)
    if not m:
        return None, None
    return m.group(1), m.group(2)


def extract_footer(text):
    """Extract footer nav line (last non-empty line before EOF)."""
    lines = text.rstrip("\n").split("\n")
    for line in reversed(lines):
        if line.strip():
            m = FOOTER_RE.match(line)
            if m:
                return m
    return None


def check_tutorial(tutorial_dir, tutorial_name, has_examples=False):
    """Check a tutorial directory. Returns list of errors."""
    errors = []
    if not tutorial_dir.exists():
        errors.append(f"{tutorial_name}: directory not found: {tutorial_dir}")
        return errors

    # Collect all chapter files
    chapter_files = sorted(
        f for f in tutorial_dir.iterdir()
        if f.suffix == ".md" and f.name != "README.md"
    )

    if not chapter_files:
        errors.append(f"{tutorial_name}: no chapter files found")
        return errors

    # Build H1 map
    h1_map = {}  # filename -> (num, title)
    for f in chapter_files:
        text = read_file(f)
        num, title = extract_h1(text)
        if num is None:
            errors.append(f"{f.name}: H1 format invalid (expected `# NN · title`)")
        else:
            h1_map[f.name] = (num, title)

    # Check footers
    for f in chapter_files:
        text = read_file(f)
        footer = extract_footer(text)
        if not footer:
            errors.append(f"{f.name}: footer nav not found or format invalid")
            continue

        prev_label, prev_file, next_label, next_file, ret_label, ret_file = footer.groups()

        # Check "返回" link
        if ret_file != "README.md":
            errors.append(f"{f.name}: footer '返回' should link to README.md, got {ret_file}")

        # Check prev/next link text matches target H1
        if prev_file and prev_file != "（无上一章）":
            if prev_file not in h1_map:
                errors.append(f"{f.name}: prev link target {prev_file} not found")
            else:
                expected_label = f"{h1_map[prev_file][0]} · {h1_map[prev_file][1]}"
                if prev_label != expected_label:
                    errors.append(
                        f"{f.name}: prev link text mismatch. Expected '{expected_label}', got '{prev_label}'"
                    )

        if next_file and next_file != "（无下一章）":
            if next_file not in h1_map:
                errors.append(f"{f.name}: next link target {next_file} not found")
            else:
                expected_label = f"{h1_map[next_file][0]} · {h1_map[next_file][1]}"
                if next_label != expected_label:
                    errors.append(
                        f"{f.name}: next link text mismatch. Expected '{expected_label}', got '{next_label}'"
                    )

    # Check README links
    readme_path = tutorial_dir / "README.md"
    if readme_path.exists():
        readme_text = read_file(readme_path)
        # Find all markdown links [text](file.md)
        link_re = re.compile(r"\[([^\]]+)\]\(([^)]+\.md)\)")
        for m in link_re.finditer(readme_text):
            link_file = m.group(2)
            if link_file == "README.md":
                continue  # self-link OK
            target = tutorial_dir / link_file
            if not target.exists():
                errors.append(f"README.md: link target {link_file} not found")
    else:
        errors.append(f"{tutorial_name}: README.md not found")

    # Check example↔doc pairing for extending-emacs
    if has_examples and EXAMPLES_DIR.exists():
        # Build chapter number -> doc file map
        num_to_doc = {}
        for fname, (num, title) in h1_map.items():
            if num.isdigit():
                num_to_doc[int(num)] = fname

        # Check each example file has a corresponding doc
        for ex_file in sorted(EXAMPLES_DIR.iterdir()):
            if ex_file.suffix == ".el":
                # Extract chapter number from filename (e.g., 01-hello.el -> 1)
                m = re.match(r"^(\d{2})-", ex_file.name)
                if m:
                    ex_num = int(m.group(1))
                    if ex_num not in num_to_doc:
                        errors.append(
                            f"example {ex_file.name}: no corresponding doc chapter {ex_num:02d}"
                        )

    return errors


def mutate_and_test(tutorial_dir):
    """Intentionally break a file and verify check catches it."""
    chapter_files = sorted(
        f for f in tutorial_dir.iterdir()
        if f.suffix == ".md" and f.name != "README.md"
    )
    if not chapter_files:
        return False

    target = chapter_files[0]
    original_text = read_file(target)

    # Break the H1
    broken_text = original_text.replace("# 00 ·", "# 00 · WRONG", 1)
    target.write_text(broken_text, encoding="utf-8")

    try:
        errors = check_tutorial(tutorial_dir, "test", has_examples=False)
        return any("H1 format invalid" in e or "WRONG" in e for e in errors)
    finally:
        # Restore
        target.write_text(original_text, encoding="utf-8")


def main():
    mutate = "--mutate" in sys.argv

    if mutate:
        print("Running mutation test...")
        if mutate_and_test(USING_DIR):
            print("✓ Mutation test passed (check caught the break)")
        else:
            print("✗ Mutation test FAILED (check did not catch the break)")
            sys.exit(1)
        if mutate_and_test(EXTENDING_DIR):
            print("✓ Mutation test passed for extending-emacs")
        else:
            print("✗ Mutation test FAILED for extending-emacs")
            sys.exit(1)
        return

    all_errors = []

    print("Checking using-emacs tutorial...")
    errors = check_tutorial(USING_DIR, "using-emacs", has_examples=False)
    all_errors.extend(errors)
    if errors:
        for e in errors:
            print(f"  ✗ {e}")
    else:
        print("  ✓ All checks passed")

    print("\nChecking extending-emacs tutorial...")
    errors = check_tutorial(EXTENDING_DIR, "extending-emacs", has_examples=True)
    all_errors.extend(errors)
    if errors:
        for e in errors:
            print(f"  ✗ {e}")
    else:
        print("  ✓ All checks passed")

    if all_errors:
        print(f"\n✗ Total errors: {len(all_errors)}")
        sys.exit(1)
    else:
        print("\n✓ All tutorials passed structural checks")


if __name__ == "__main__":
    main()
