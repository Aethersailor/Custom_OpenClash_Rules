#!/usr/bin/env python3
"""Build the repository Wiki mirror from a checked-out GitHub Wiki."""

from __future__ import annotations

import argparse
import re
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import unquote, urlsplit, urlunsplit


HEADING_LINK = re.compile(r"^\s*###\s+.*?\[[^]]+]\(([^)]+)\)")


@dataclass(frozen=True)
class WikiPage:
    source_url: str
    page_name: str
    destination_name: str


def page_name_from_url(url: str, repository: str) -> tuple[str, str]:
    """Return the fragment-free URL and decoded Wiki page name."""
    parsed = urlsplit(url)
    expected_prefix = f"/{repository}/wiki/"

    if parsed.scheme or parsed.netloc:
        if parsed.netloc.casefold() != "github.com" or not parsed.path.startswith(
            expected_prefix
        ):
            raise ValueError(f"unsupported Wiki URL: {url}")
        encoded_name = parsed.path[len(expected_prefix) :]
        source_url = urlunsplit((parsed.scheme, parsed.netloc, parsed.path, parsed.query, ""))
    else:
        encoded_name = parsed.path.removeprefix("./").removeprefix("/")
        source_url = urlunsplit(("", "", parsed.path, parsed.query, ""))

    page_name = unquote(encoded_name)
    if (
        not page_name
        or page_name in {".", "..", "Home"}
        or "/" in page_name
        or "\\" in page_name
        or "\0" in page_name
    ):
        raise ValueError(f"unsafe or empty Wiki page name in URL: {url}")
    return source_url, page_name


def parse_home(home: str, repository: str) -> list[WikiPage]:
    pages: list[WikiPage] = []
    seen_names: set[str] = set()
    for line_number, line in enumerate(home.splitlines(), 1):
        match = HEADING_LINK.match(line)
        if not match:
            continue
        source_url, page_name = page_name_from_url(match.group(1), repository)
        if page_name in seen_names:
            raise ValueError(f"Home.md:{line_number}: duplicate Wiki page: {page_name}")
        seen_names.add(page_name)
        pages.append(
            WikiPage(
                source_url=source_url,
                page_name=page_name,
                destination_name=f"{len(pages) + 1}.{page_name}.md",
            )
        )
    if not pages:
        raise ValueError("Home.md does not contain any level-three Wiki page links")
    return pages


def rewrite_links(content: str, pages: list[WikiPage]) -> str:
    # Replace only complete Markdown link targets. A plain substring replace
    # would corrupt a page such as "Page-2" when another page is named "Page".
    for page in sorted(pages, key=lambda item: len(item.source_url), reverse=True):
        content = re.sub(
            rf"(?<=\(){re.escape(page.source_url)}(?=(?:#[^)]*)?\))",
            lambda _match, destination=page.destination_name: destination,
            content,
        )
    return content


def build_backup(source: Path, destination: Path, repository: str) -> None:
    home_path = source / "Home.md"
    if not home_path.is_file():
        raise FileNotFoundError(f"missing Wiki home page: {home_path}")

    home = home_path.read_text(encoding="utf-8-sig")
    pages = parse_home(home, repository)
    missing = [
        page.page_name
        for page in pages
        if not (source / f"{page.page_name}.md").is_file()
    ]
    if missing:
        raise FileNotFoundError(f"Home.md references missing Wiki pages: {', '.join(missing)}")

    if destination.exists():
        if any(destination.iterdir()):
            raise ValueError(f"destination must be empty: {destination}")
    else:
        destination.mkdir(parents=True)

    (destination / "README.md").write_text(
        rewrite_links(home, pages), encoding="utf-8", newline="\n"
    )
    for page in pages:
        content = (source / f"{page.page_name}.md").read_text(encoding="utf-8-sig")
        (destination / page.destination_name).write_text(
            rewrite_links(content, pages), encoding="utf-8", newline="\n"
        )

    generated = {path.name for path in destination.glob("*.md")}
    expected = {"README.md", *(page.destination_name for page in pages)}
    if generated != expected:
        raise RuntimeError(
            f"generated Wiki file set mismatch: missing={sorted(expected - generated)}, "
            f"unexpected={sorted(generated - expected)}"
        )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--destination", type=Path, required=True)
    parser.add_argument("--repository", required=True)
    args = parser.parse_args()

    build_backup(args.source.resolve(), args.destination.resolve(), args.repository)
    print(f"Generated validated Wiki backup in {args.destination}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
