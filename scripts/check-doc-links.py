#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
from pathlib import Path

LINK_PATTERN = re.compile(r"\[[^]]+]\(([^)]+)\)")
SKIP_PREFIXES = ("http://", "https://", "mailto:", "tel:")


def iter_markdown_files(root: Path) -> list[Path]:
    return [
        root / "README.md",
        root / "README_cn.md",
        *sorted((root / "docs").rglob("*.md")),
    ]


def normalize_link(link: str) -> str:
    link = link.strip()
    if link.startswith("<") and link.endswith(">"):
        link = link[1:-1].strip()
    return link


def resolve_target(doc_path: Path, link: str) -> Path:
    link = link.split("#", 1)[0].split("?", 1)[0]
    if not link:
        return doc_path
    return (doc_path.parent / link).resolve()


def check_links(root: Path, markdown_files: list[Path]) -> list[str]:
    errors: list[str] = []
    for doc_path in markdown_files:
        if not doc_path.exists():
            continue
        content = doc_path.read_text(encoding="utf-8")
        for match in LINK_PATTERN.findall(content):
            link = normalize_link(match)
            if not link or link.startswith(SKIP_PREFIXES) or link.startswith("#"):
                continue
            if link.startswith("//"):
                continue
            target = resolve_target(doc_path, link)
            if not target.exists():
                errors.append(f"{doc_path.relative_to(root)} -> {link}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description="Check local markdown links.")
    parser.add_argument(
        "--root",
        type=Path,
        default=Path(__file__).resolve().parents[1],
        help="Repository root directory.",
    )
    args = parser.parse_args()
    root = args.root.resolve()
    markdown_files = iter_markdown_files(root)
    errors = check_links(root, markdown_files)
    if errors:
        print("Broken local markdown links detected:")
        for error in sorted(errors):
            print(f"- {error}")
        return 1
    print("All local markdown links look valid.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
