import unittest

import sync_installer_common


class InstallerContractTests(unittest.TestCase):
    def test_shared_implementations_do_not_drift(self) -> None:
        light = sync_installer_common.LIGHT_INSTALLER.read_text(encoding="utf-8")
        full = sync_installer_common.FULL_INSTALLER.read_text(encoding="utf-8")
        self.assertEqual(
            sync_installer_common.synchronized_light_content(light, full), light
        )

    def test_both_public_scripts_can_be_loaded_without_running_main(self) -> None:
        for path in (
            sync_installer_common.LIGHT_INSTALLER,
            sync_installer_common.FULL_INSTALLER,
        ):
            with self.subTest(path=path.name):
                content = path.read_text(encoding="utf-8")
                self.assertIn('OPENCLASH_INSTALLER_LIB_ONLY:-0', content)


if __name__ == "__main__":
    unittest.main()
