import ipaddress
import tempfile
import unittest
import unittest.mock
from pathlib import Path

import generate_game_cdn
import generate_rules
import update_encrypted_dns


class GeoSiteConversionTests(unittest.TestCase):
    def test_convert_every_supported_prefix_and_strip_attributes(self) -> None:
        cases = {
            "domain:Example.COM:@!cn": "DOMAIN-SUFFIX,example.com",
            "full:DNS.Example.COM:@cn:@test": "DOMAIN,dns.example.com",
            "keyword:DoH": "DOMAIN-KEYWORD,DoH",
            r"regexp:^dns[0-9]+\.example\.com$": r"DOMAIN-REGEX,^dns[0-9]+\.example\.com$",
        }
        for source, expected in cases.items():
            with self.subTest(source=source):
                self.assertEqual(update_encrypted_dns.convert_geosite_rule(source), expected)

    def test_parse_compiled_category_with_resolved_rules(self) -> None:
        content = """lists:
  - name: "another-list"
    length: 1
    rules:
      - "domain:ignored.example"
  - name: "category-doh"
    length: 4
    rules:
      - "domain:cloudflare-dns.com"
      - "domain:nextdns.io"
      - "full:dns.google"
      - "keyword:resolver"
  - name: "later-list"
    length: 1
    rules:
      - "domain:also-ignored.example"
"""
        with unittest.mock.patch.object(update_encrypted_dns, "MIN_GEOSITE_RULES", 4):
            rules = update_encrypted_dns.parse_geosite_plain(content)
        self.assertEqual(
            rules,
            {
                "DOMAIN-SUFFIX,cloudflare-dns.com",
                "DOMAIN-SUFFIX,nextdns.io",
                "DOMAIN,dns.google",
                "DOMAIN-KEYWORD,resolver",
            },
        )

    def test_parse_rejects_length_mismatch(self) -> None:
        content = """lists:
  - name: "category-doh"
    length: 2
    rules:
      - "domain:cloudflare-dns.com"
"""
        with self.assertRaisesRegex(ValueError, "length mismatch"):
            update_encrypted_dns.parse_geosite_plain(content)


class DomainDeduplicationTests(unittest.TestCase):
    def test_merge_removes_exact_and_suffix_covered_rules(self) -> None:
        hagezi = {"example.com", "dns.test"}
        geosite = {
            "DOMAIN-SUFFIX,example.com",
            "DOMAIN-SUFFIX,sub.example.com",
            "DOMAIN,api.example.com",
            "DOMAIN,exact.test",
            "DOMAIN-KEYWORD,secure-dns",
            r"DOMAIN-REGEX,^dns[0-9]+\.test$",
        }
        self.assertEqual(
            update_encrypted_dns.merge_domain_rules(hagezi, geosite),
            {
                "DOMAIN-SUFFIX,dns.test",
                "DOMAIN-SUFFIX,example.com",
                "DOMAIN,exact.test",
                "DOMAIN-KEYWORD,secure-dns",
                r"DOMAIN-REGEX,^dns[0-9]+\.test$",
            },
        )

    def test_network_deduplication_removes_covered_subnets(self) -> None:
        networks = {
            ipaddress.ip_network("192.0.2.0/24"),
            ipaddress.ip_network("192.0.2.1/32"),
            ipaddress.ip_network("2001:db8::/48"),
            ipaddress.ip_network("2001:db8::1/128"),
        }
        self.assertEqual(
            update_encrypted_dns.deduplicate_networks(networks),
            {
                ipaddress.ip_network("192.0.2.0/24"),
                ipaddress.ip_network("2001:db8::/48"),
            },
        )


class DerivedRuleGenerationTests(unittest.TestCase):
    def test_domain_regex_stays_classical_only(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            source = Path(temporary) / "rules.list"
            source.write_text(
                "DOMAIN-SUFFIX,example.com\n"
                r"DOMAIN-REGEX,^dns[0-9]+\.example\.com$" "\n",
                encoding="utf-8",
            )
            family = generate_rules.parse_list(source)
        self.assertEqual(family.domain, ("+.example.com",))
        self.assertIn(r"DOMAIN-REGEX,^dns[0-9]+\.example\.com$", family.classical)

    def test_domain_regex_is_yaml_quoted(self) -> None:
        rendered = generate_rules.render_yaml(
            Path("rule/example.list"),
            (r"DOMAIN-REGEX,^dns[0-9]{1,3}\.example\.com$",),
            quoted=False,
        )
        self.assertIn(
            r"  - 'DOMAIN-REGEX,^dns[0-9]{1,3}\.example\.com$'",
            rendered,
        )


class GameCdnGenerationTests(unittest.TestCase):
    def test_converts_supported_upstream_rule_types_and_attributes(self) -> None:
        cases = {
            "example.com @cn": "DOMAIN-SUFFIX,example.com",
            "full:www.example.com": "DOMAIN,www.example.com",
            "keyword:download": "DOMAIN-KEYWORD,download",
            r"regexp:^cdn[0-9]+\.example\.com$": (
                r"DOMAIN-REGEX,^cdn[0-9]+\.example\.com$"
            ),
        }
        for source, expected in cases.items():
            with self.subTest(source=source):
                self.assertEqual(generate_game_cdn.convert_line(source), expected)

    def test_deduplicates_rules_without_leaking_duplicate_comments(self) -> None:
        converted = generate_game_cdn.generate_rules(
            "# kept\nexample.com\n# duplicate-only\nexample.com\nfull:www.example.com\n"
        )
        self.assertEqual(
            converted,
            ["# kept", "DOMAIN-SUFFIX,example.com"],
        )

    def test_merges_steam_rules_with_semantic_deduplication(self) -> None:
        converted = generate_game_cdn.generate_rules(
            "example.com\n",
            (
                "DOMAIN,www.example.com\n"
                "DOMAIN-SUFFIX,EXAMPLE.COM.\n"
                "IP-CIDR,192.0.2.128/25\n"
                "IP-CIDR,192.0.2.0/24,no-resolve\n"
            ),
        )
        self.assertEqual(
            converted,
            [
                "DOMAIN-SUFFIX,example.com",
                generate_game_cdn.STEAM_SOURCE_COMMENT,
                "IP-CIDR,192.0.2.0/24,no-resolve",
            ],
        )

    def test_rejects_unexpanded_include(self) -> None:
        with self.assertRaisesRegex(ValueError, "include"):
            generate_game_cdn.convert_line("include:another-list")


if __name__ == "__main__":
    unittest.main()
