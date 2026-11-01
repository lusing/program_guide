"""Regression tests for three-digit chapter discovery in build.ps1."""
from pathlib import Path
import re
import subprocess
import unittest

ROOT = Path(__file__).resolve().parent.parent
ANSI = re.compile(r"\x1b\[[0-9;]*m")


def build(*args: str) -> tuple[int, str]:
    command = "& ./build.ps1 " + " ".join(args)
    result = subprocess.run(
        ["pwsh", "-NoProfile", "-Command", command],
        cwd=ROOT,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=600,
    )
    return result.returncode, ANSI.sub("", result.stdout)


class ThreeDigitChapterTests(unittest.TestCase):
    def test_chapter_12_does_not_execute_123(self) -> None:
        code, output = build("-Chapter", "12", "-Lang", "python")
        print(output.encode("ascii", "backslashreplace").decode("ascii"))
        self.assertIn("12_constructible.py", output)
        self.assertNotIn("123_topic.py", output)
        self.assertEqual(code, 0)

    def test_marker_requires_whole_chapter_number(self) -> None:
        probe = ROOT / "examples" / "python" / "12_badmarker.py"
        self.assertFalse(probe.exists(), f"refusing to overwrite {probe}")
        probe.write_text('print("==== 123")\nprint("END ====")\n', encoding="utf-8")
        try:
            code, output = build("-Chapter", "12", "-Lang", "python")
            print(output.encode("ascii", "backslashreplace").decode("ascii"))
            self.assertNotEqual(code, 0)
            self.assertRegex(output, r"(?m)^12\s+python\s+FAIL\s+12_badmarker\.py")
        finally:
            probe.unlink()

    def test_chapter_123_has_seven_channels(self) -> None:
        code, output = build("-Chapter", "123")
        print(output.encode("ascii", "backslashreplace").decode("ascii"))
        self.assertEqual(code, 0)
        for lang in ("isabelle", "coq", "agda", "julia", "python", "prolog"):
            self.assertRegex(output, rf"(?m)^123\s+{lang}\s+PASS\s")
        self.assertRegex(output, r"(?m)^123\s+lean\s+PASS\s")
        self.assertIn("PASS 8 / FAIL 0", output)


if __name__ == "__main__":
    unittest.main()
