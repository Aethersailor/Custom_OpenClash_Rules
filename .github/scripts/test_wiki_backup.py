import tempfile
import unittest
from pathlib import Path

import wiki_backup


REPOSITORY = "Aethersailor/Custom_OpenClash_Rules"


class WikiBackupTests(unittest.TestCase):
    def test_builds_numbered_backup_and_rewrites_page_links(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "source"
            destination = root / "destination"
            source.mkdir()
            first_url = (
                "https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/"
                "OpenClash-%E8%AE%BE%E7%BD%AE"
            )
            second_url = (
                "https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/"
                "%E6%95%85%E9%9A%9C%E6%8E%92%E9%99%A4"
            )
            (source / "Home.md").write_text(
                f"### 1 [设置]({first_url})\n\n### 2 [排障]({second_url})\n",
                encoding="utf-8",
            )
            (source / "OpenClash-设置.md").write_text(
                f"参见 [排障]({second_url}#dns)。\n", encoding="utf-8"
            )
            (source / "故障排除.md").write_text("完成。\n", encoding="utf-8")

            wiki_backup.build_backup(source, destination, REPOSITORY)

            self.assertEqual(
                {path.name for path in destination.iterdir()},
                {"README.md", "1.OpenClash-设置.md", "2.故障排除.md"},
            )
            self.assertIn(
                "2.故障排除.md#dns",
                (destination / "1.OpenClash-设置.md").read_text(encoding="utf-8"),
            )

    def test_missing_linked_page_fails_before_creating_destination(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "source"
            destination = root / "destination"
            source.mkdir()
            (source / "Home.md").write_text(
                "### [Missing](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/Missing)\n",
                encoding="utf-8",
            )

            with self.assertRaisesRegex(FileNotFoundError, "Missing"):
                wiki_backup.build_backup(source, destination, REPOSITORY)
            self.assertFalse(destination.exists())

    def test_rejects_links_outside_the_expected_repository(self) -> None:
        home = "### [Bad](https://github.com/another/repository/wiki/Page)\n"
        with self.assertRaisesRegex(ValueError, "unsupported Wiki URL"):
            wiki_backup.parse_home(home, REPOSITORY)

    def test_link_rewrite_does_not_replace_page_name_prefixes(self) -> None:
        home = (
            "### [Page](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/Page)\n"
            "### [Page 2](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/Page-2)\n"
        )
        pages = wiki_backup.parse_home(home, REPOSITORY)
        rewritten = wiki_backup.rewrite_links(home, pages)
        self.assertIn("(1.Page.md)", rewritten)
        self.assertIn("(2.Page-2.md)", rewritten)


if __name__ == "__main__":
    unittest.main()
