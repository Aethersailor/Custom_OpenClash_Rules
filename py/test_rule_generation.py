import ipaddress
import tempfile
import unittest
from pathlib import Path
from unittest import mock

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
        with mock.patch.object(update_encrypted_dns, "MIN_GEOSITE_RULES", 4):
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


if __name__ == "__main__":
    unittest.main()
