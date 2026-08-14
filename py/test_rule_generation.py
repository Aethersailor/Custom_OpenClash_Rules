import ipaddress
import tempfile
import unittest
import unittest.mock
from pathlib import Path

import generate_game_cdn
import generate_rules
import generate_stash_configs
import extract_uu_game_routes
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
    def test_game_sources_are_discovered_recursively(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "rule").mkdir()
            for base_name in generate_rules.BASE_NAMES:
                (root / "rule" / f"{base_name}.list").write_text(
                    "DOMAIN,example.com\n", encoding="utf-8"
                )
            nested = (
                root
                / "rule"
                / "game_rule"
                / "Example-Game"
                / "Example-Game_Europe.list"
            )
            nested.parent.mkdir(parents=True)
            nested.write_text("IP-CIDR,192.0.2.0/24,no-resolve\n", encoding="utf-8")

            sources = generate_rules.source_paths(root)
            outputs, _ = generate_rules.textual_outputs(root)

        self.assertIn(
            Path("rule/game_rule/Example-Game/Example-Game_Europe.list"), sources
        )
        self.assertIn(
            Path("rule/game_rule/Example-Game/Example-Game_Europe_IP.yaml"), outputs
        )

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

    def test_removes_orphan_generated_game_rule_files(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "rule").mkdir()
            for base_name in generate_rules.BASE_NAMES:
                (root / "rule" / f"{base_name}.list").write_text(
                    "DOMAIN,example.com\n", encoding="utf-8"
                )

            orphan_directory = root / "rule/game_rule/Removed-Game"
            orphan_directory.mkdir(parents=True)
            orphan_yaml = orphan_directory / "Removed-Game_Europe_Domain.yaml"
            orphan_mrs = orphan_directory / "Removed-Game_Europe_Domain.mrs"
            orphan_yaml.write_text(
                "# Generated from "
                "rule/game_rule/Removed-Game/Removed-Game_Europe.list\n"
                "payload:\n  - 'example.com'\n",
                encoding="utf-8",
            )
            orphan_mrs.write_bytes(b"orphan")

            outputs, mrs_inputs = generate_rules.textual_outputs(root)
            orphans = generate_rules.orphan_output_paths(
                root, outputs, mrs_inputs
            )
            generate_rules.remove_orphan_outputs(root, orphans)

        self.assertEqual(
            set(orphans),
            {
                Path(
                    "rule/game_rule/Removed-Game/"
                    "Removed-Game_Europe_Domain.yaml"
                ),
                Path(
                    "rule/game_rule/Removed-Game/"
                    "Removed-Game_Europe_Domain.mrs"
                ),
            },
        )
        self.assertFalse(orphan_yaml.exists())
        self.assertFalse(orphan_mrs.exists())


class StashConfigGenerationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.root = Path(__file__).resolve().parents[1]
        cls.outputs = generate_stash_configs.generated_outputs(cls.root)

    def test_generates_nine_deterministic_outputs(self) -> None:
        expected_paths = {
            Path("cfg/Custom_Stash.ini"),
            Path("cfg/Custom_Stash_Fallback.ini"),
            Path("cfg/Custom_Stash_Lite.ini"),
            Path("cfg/Custom_Stash_Lite_Fallback.ini"),
            Path("cfg/Custom_Stash_GFW.ini"),
            Path("cfg/Custom_Stash_GFW_Fallback.ini"),
            Path("cfg/Custom_Stash_Full.ini"),
            Path("cfg/Custom_Stash_Full_Fallback.ini"),
            Path("cfg/Custom_Stash_Mainland.ini"),
        }
        self.assertEqual(set(self.outputs), expected_paths)
        self.assertEqual(
            self.outputs,
            generate_stash_configs.generated_outputs(self.root),
        )
        self.assertEqual(
            self.outputs[Path("cfg/Custom_Stash.ini")],
            self.outputs[Path("cfg/Custom_Stash_Mainland.ini")],
        )

    def test_committed_outputs_are_current(self) -> None:
        self.assertEqual(
            generate_stash_configs.check_outputs(self.root, self.outputs),
            (),
        )

    def test_projects_stash_rules_without_silent_unsupported_rules(self) -> None:
        for relative_path, content in self.outputs.items():
            with self.subTest(path=relative_path):
                rulesets = [
                    line for line in content.splitlines() if line.startswith("ruleset=")
                ]
                providers = [line for line in rulesets if ",[]" not in line]
                self.assertEqual(
                    len(providers),
                    generate_stash_configs.EXPECTED_PROVIDER_COUNTS[
                        relative_path.name
                    ],
                )
                self.assertFalse(any("SRC-PORT" in line for line in rulesets))
                self.assertFalse(
                    any(
                        ",[]GEOIP," in line
                        and ",[]GEOIP,cn,no-resolve" not in line
                        for line in rulesets
                    )
                )

        destination_ports, omitted = (
            generate_stash_configs.extract_direct_port_rules(
                "DOMAIN-SUFFIX,example.com\n"
                "IP-CIDR,192.0.2.0/24,no-resolve\n"
                "SRC-PORT,41641\n"
                "DST-PORT,7844\n"
            )
        )
        self.assertEqual(destination_ports, ("DST-PORT,7844",))
        self.assertEqual(omitted, ("SRC-PORT,41641",))
        with self.assertRaisesRegex(ValueError, "unmapped Stash rule"):
            generate_stash_configs.extract_direct_port_rules(
                "SRC-PORT,41641\nSRC-PORT,12345\n"
            )

    def test_projects_only_portable_stash_groups(self) -> None:
        for relative_path, content in self.outputs.items():
            group_lines = [
                line
                for line in content.splitlines()
                if line.startswith("custom_proxy_group=")
            ]
            with self.subTest(path=relative_path):
                self.assertTrue(group_lines)
                self.assertFalse(
                    any(
                        generate_stash_configs.BENCHMARK_URL in line
                        or generate_stash_configs.SELECT_PSEUDO_URL in line
                        for line in group_lines
                    )
                )
                for line in group_lines:
                    selectors = generate_stash_configs.group_dynamic_selectors(line)
                    self.assertLessEqual(len(selectors), 1)
                    self.assertFalse(
                        any("," in selector or "(?<" in selector for selector in selectors)
                    )

    def test_rejects_dangling_stash_policy_references(self) -> None:
        generate_stash_configs.validate_policy_reference_closure(
            "ruleset=Proxy,[]FINAL\n"
            "custom_proxy_group=Proxy`select`[]DIRECT\n"
        )
        with self.assertRaisesRegex(ValueError, "policy-group member"):
            generate_stash_configs.validate_policy_reference_closure(
                "ruleset=Proxy,[]FINAL\n"
                "custom_proxy_group=Proxy`select`[]Missing\n"
            )
        with self.assertRaisesRegex(ValueError, "ruleset policy"):
            generate_stash_configs.validate_policy_reference_closure(
                "ruleset=Missing,[]FINAL\n"
                "custom_proxy_group=Proxy`select`[]DIRECT\n"
            )
        with self.assertRaisesRegex(ValueError, "cyclic"):
            generate_stash_configs.validate_policy_reference_closure(
                "ruleset=A,[]FINAL\n"
                "custom_proxy_group=A`select`[]B\n"
                "custom_proxy_group=B`select`[]A\n"
            )


class UuRouteExtractionTests(unittest.TestCase):
    def test_keeps_only_public_routes_for_the_dominant_uu_gateway(self) -> None:
        rows = [
            {"DestinationPrefix": "0.0.0.0/0", "NextHop": "172.19.84.1"},
            {"DestinationPrefix": "192.168.0.0/16", "NextHop": "172.19.84.1"},
            {"DestinationPrefix": "1.1.1.0/24", "NextHop": "172.19.84.1"},
            {"DestinationPrefix": "1.1.1.1/32", "NextHop": "172.19.84.1"},
            {"DestinationPrefix": "8.8.8.0/24", "NextHop": "172.19.84.1"},
            {"DestinationPrefix": "9.9.9.0/24", "NextHop": "203.0.113.1"},
        ]

        networks, gateway, routed_count = extract_uu_game_routes.normalize_routes(
            rows, minimum_routes=2
        )

        self.assertEqual(gateway, "172.19.84.1")
        self.assertEqual(routed_count, 5)
        self.assertEqual(
            tuple(str(network) for network in networks),
            ("1.1.1.0/24", "8.8.8.0/24"),
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
