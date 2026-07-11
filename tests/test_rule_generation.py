from pathlib import Path
from collections import Counter
import sys
import unittest


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "py"))

from generate_game_cdn import convert_line, generate_rules  # noqa: E402
from generate_rules import textual_outputs  # noqa: E402


class GameCdnConversionTests(unittest.TestCase):
    def test_supported_domain_list_formats(self):
        self.assertEqual(convert_line("example.com"), "DOMAIN-SUFFIX,example.com")
        self.assertEqual(convert_line("domain:example.com @cn"), "DOMAIN-SUFFIX,example.com")
        self.assertEqual(convert_line("full:www.example.com"), "DOMAIN,www.example.com")
        self.assertEqual(convert_line("keyword:example"), "DOMAIN-KEYWORD,example")
        self.assertEqual(convert_line(r"regexp:^example\\.com$"), r"DOMAIN-REGEX,^example\\.com$")

    def test_comments_attributes_and_duplicates_are_removed(self):
        source = "# group\nexample.com @cn\nexample.com # duplicate\nfull:www.example.com\n"
        self.assertEqual(
            generate_rules(source),
            ["# group", "DOMAIN-SUFFIX,example.com", "DOMAIN,www.example.com"],
        )

    def test_unresolved_include_fails_closed(self):
        with self.assertRaises(ValueError):
            convert_line("include:another-list")


class RepositoryGenerationTests(unittest.TestCase):
    def test_game_cdn_file_has_only_supported_unique_rules(self):
        path = ROOT / "rule" / "Game_Download_CDN.list"
        rules = [
            line.strip()
            for line in path.read_text(encoding="utf-8-sig").splitlines()
            if line.strip() and not line.startswith(("#", ";"))
        ]
        allowed = ("DOMAIN,", "DOMAIN-SUFFIX,", "DOMAIN-KEYWORD,", "DOMAIN-REGEX,")
        invalid = [rule for rule in rules if not rule.startswith(allowed)]
        duplicates = [rule for rule, count in Counter(rules).items() if count > 1]
        self.assertEqual(invalid, [])
        self.assertEqual(duplicates, [])

    def test_generated_text_files_match_repository(self):
        outputs, _ = textual_outputs(ROOT)
        stale = [
            str(relative)
            for relative, expected in outputs.items()
            if not (ROOT / relative).exists()
            or (ROOT / relative).read_text(encoding="utf-8-sig") != expected
        ]
        self.assertEqual(stale, [], f"stale generated files: {', '.join(stale)}")

    def test_mrs_inputs_are_only_pure_domain_or_ip_providers(self):
        _, mrs_inputs = textual_outputs(ROOT)
        self.assertTrue(mrs_inputs)
        for relative, (behavior, source) in mrs_inputs.items():
            self.assertIn(behavior, {"domain", "ipcidr"})
            self.assertNotIn("Classical", relative.name)
            self.assertNotIn("Classical", source)


if __name__ == "__main__":
    unittest.main()
