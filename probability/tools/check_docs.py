import argparse
import json
import re
import sys
from pathlib import Path

LANGS = {"julia": ".jl", "python": ".py", "prolog": ".pl"}
FENCE = {"julia": "julia", "python": "python", "prolog": "prolog"}


def check(root: Path, final: bool = False) -> list[str]:
    """Check chapter files, links, navigation, and example citations."""
    manifest = json.loads((root / "chapters.json").read_text(encoding="utf-8"))
    chapters = manifest["chapters"]
    errors = []
    for index, meta in enumerate(chapters):
        number, slug = meta["number"], meta["slug"]
        doc = root / "docs" / f"{number}-{slug}.md"
        if not doc.exists():
            if final:
                errors.append(f"missing chapter: {doc}")
            continue
        text = doc.read_text(encoding="utf-8")
        lines = text.splitlines()
        if final and len(lines) < 200:
            errors.append(f"short chapter: {doc} has {len(lines)} lines")
        for target in re.findall(r"\[[^]]*\]\(([^)]+)\)", text):
            if "://" in target or target.startswith("#"):
                continue
            clean = target.split("#", 1)[0]
            if clean and not (doc.parent / clean).resolve().exists():
                errors.append(f"dangling link: {doc}: {target}")
        if final and index > 0:
            prev = f"{chapters[index-1]['number']}-{chapters[index-1]['slug']}.md"
            if prev not in text:
                errors.append(f"missing previous navigation: {doc}: {prev}")
        if final and index + 1 < len(chapters):
            nxt = f"{chapters[index+1]['number']}-{chapters[index+1]['slug']}.md"
            if nxt not in text:
                errors.append(f"missing next navigation: {doc}: {nxt}")
        for lang, suffix in LANGS.items():
            folder = root / "examples" / lang
            if not folder.exists():
                continue
            expected_name = f"{number}_{slug.replace('-', '_')}{suffix}"
            for example in folder.glob(f"{number}_*{suffix}"):
                if example.name != expected_name:
                    if final:
                        errors.append(f"unexpected example name: {example}")
                    continue
                relative = example.relative_to(root).as_posix()
                if relative not in text:
                    errors.append(f"uncited example: {doc}: {relative}")
                fence = f"```{FENCE[lang]}"
                if fence not in text:
                    errors.append(f"missing explained code block: {doc}: {lang}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument("--final", action="store_true")
    args = parser.parse_args()
    errors = check(args.root, args.final)
    for error in errors:
        print(error)
    print(f"docs: {'PASS' if not errors else 'FAIL'} ({len(errors)} errors)")
    return int(bool(errors))


if __name__ == "__main__":
    sys.exit(main())
