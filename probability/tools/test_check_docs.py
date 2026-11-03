import json
import tempfile
import unittest
from pathlib import Path

from check_docs import check, check_math


class CheckDocsTest(unittest.TestCase):
    def make_root(self):
        tmp = tempfile.TemporaryDirectory()
        root = Path(tmp.name)
        (root / "docs").mkdir()
        (root / "chapters.json").write_text(json.dumps({"chapters": [
            {"number": "00", "slug": "intro", "title": "导论"}
        ]}), encoding="utf-8")
        self.addCleanup(tmp.cleanup)
        return root

    def test_missing_chapter_fails_in_final(self):
        errors = check(self.make_root(), final=True)
        self.assertTrue(any("missing chapter" in e for e in errors))

    def test_example_requires_citation_and_code(self):
        root = self.make_root()
        (root / "docs" / "00-intro.md").write_text("x\n" * 220, encoding="utf-8")
        example = root / "examples" / "python" / "00_intro.py"
        example.parent.mkdir(parents=True)
        example.write_text("print('END ====')\n", encoding="utf-8")
        errors = check(root, final=False)
        self.assertTrue(any("uncited example" in e for e in errors))

    def test_dangling_link_fails(self):
        root = self.make_root()
        (root / "docs" / "00-intro.md").write_text(
            "[下一章](01-events.md)\n", encoding="utf-8")
        self.assertTrue(any("dangling link" in e for e in check(root)))

    def test_legacy_math_delimiter_fails(self):
        text = "价格是 `\\(x\\)` 代码不算，\n但正文 \\(x\\) 要报错。\n"
        errors = check_math(text, Path("x.md"))
        self.assertTrue(any("legacy math delimiter" in e for e in errors), errors)

    def test_balanced_dollar_math_passes(self):
        text = (
            "行内 $x+y$ 与货币 \\$60，000。\n\n"
            "$$\na^2+b^2=c^2\n$$\n"
        )
        self.assertEqual(check_math(text, Path("x.md")), [])

    def test_unbalanced_dollar_fails(self):
        self.assertTrue(any("unbalanced" in e
                            for e in check_math("$$\na\n", Path("x.md"))))
        self.assertTrue(any("unbalanced" in e
                            for e in check_math("$x 元\n", Path("x.md"))))

    def test_forgejo_adjacency_rule(self):
        bad_close = check_math("记作 $\\Omega$，再见。\n", Path("x.md"))
        self.assertTrue(any("after closing $" in e for e in bad_close), bad_close)
        bad_open = check_math("Bernoulli$(p)$ 分布。\n", Path("x.md"))
        self.assertTrue(any("before opening $" in e for e in bad_open), bad_open)
        good = check_math("记作 $\\Omega$ ，再见 $x$ 。\n行尾 $x$\n", Path("x.md"))
        self.assertEqual(good, [])


if __name__ == "__main__":
    unittest.main()
