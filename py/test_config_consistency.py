import tempfile
import unittest
from pathlib import Path

import check_config_consistency


class ConfigConsistencyTests(unittest.TestCase):
    def test_repository_contract_is_consistent(self) -> None:
        self.assertEqual([], check_config_consistency.validate_repository())

    def test_bad_ini_ruleset_interval_is_reported(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            config = root / "cfg" / "bad.ini"
            config.parent.mkdir()
            config.write_text(
                "ruleset=TEST,clash-domain:https://example.com/rules.mrs,2880\n",
                encoding="utf-8",
            )

            errors = check_config_consistency.check_ini_intervals(root, ("cfg/bad.ini",))

        self.assertEqual(1, len(errors))
        self.assertIn("expected 28800 seconds", errors[0])

    def test_domain_yaml_provider_must_remain_mrs(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            config = root / "cfg" / "bad.yaml"
            config.parent.mkdir()
            config.write_text(
                "rule-providers:\n"
                "  Domain_Rules:\n"
                "    behavior: domain\n"
                "    interval: 28800\n"
                "    type: http\n"
                "    url: https://example.com/rules.yaml\n"
                "    format: yaml\n",
                encoding="utf-8",
            )

            errors = check_config_consistency.check_yaml_providers(root, ("cfg/bad.yaml",))

        self.assertEqual(2, len(errors))
        self.assertTrue(any("must use MRS format" in error for error in errors))
        self.assertTrue(any("URL must end in .mrs" in error for error in errors))

    def test_normal_and_fallback_rule_drift_is_reported(self) -> None:
        errors = check_config_consistency.compare_rule_order(
            "normal.ini",
            ["🚀 手动选择,[]GEOSITE,example"],
            "fallback.ini",
            ["🚀 故障转移,[]GEOSITE,different"],
        )

        self.assertTrue(errors)
        self.assertIn("rule #1", errors[1])

    def test_sync_refreshes_compatibility_alias(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            source = root / "cfg" / "Custom_Clash.ini"
            derived = root / "cfg" / "Custom_Clash_Mainland.ini"
            source.parent.mkdir()
            source.write_bytes(b"canonical\n")
            derived.write_bytes(b"stale\n")

            updated = check_config_consistency.sync_derived_configs(root)

            self.assertEqual(["cfg/Custom_Clash_Mainland.ini"], updated)
            self.assertEqual(source.read_bytes(), derived.read_bytes())
            self.assertEqual([], check_config_consistency.sync_derived_configs(root))


if __name__ == "__main__":
    unittest.main()
