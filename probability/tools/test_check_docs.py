import json
import tempfile
import unittest
from pathlib import Path

from check_docs import check


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


if __name__ == "__main__":
    unittest.main()
