import copy
import importlib.util
from pathlib import Path
import re
import unittest

spec = importlib.util.spec_from_file_location("bump", Path(__file__).with_name("bump-cloudcover.py"))
bump = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bump)


class BumpTest(unittest.TestCase):
    def setUp(self):
        self.contents = Path("Formula/cloudcover.rb").read_text()
        self.version = "99.0.0"
        self.release = {
            "tag_name": f"cloudcover-cli-v{self.version}", "draft": False, "prerelease": False,
            "assets": [
                {"name": name, "state": "uploaded", "digest": "sha256:" + str(i) * 64,
                 "browser_download_url": f"https://github.com/cyruscook/cloudcover/releases/download/cloudcover-cli-v{self.version}/{name}"}
                for i, name in enumerate(re.findall(r'/([^/"\n]+\.tar\.gz)"', self.contents), 1)
            ],
        }

    def test_updates_all_platforms_and_is_idempotent(self):
        result, version = bump.update(self.contents, [[self.release]])
        self.assertEqual(version, self.version)
        self.assertEqual(result.count(f"/cloudcover-cli-v{version}/"), 4)
        self.assertEqual(result.count(f'version "{version}"'), 2)
        for asset in self.release["assets"]:
            self.assertIn(asset["digest"][7:], result)
        self.assertEqual(bump.update(result, [[self.release]])[0], result)

    def test_incomplete_release_does_not_update(self):
        self.release["assets"].pop()
        with self.assertRaises(KeyError):
            bump.update(self.contents, [[self.release]])

    def test_missing_digest_does_not_update(self):
        self.release["assets"][0]["digest"] = None
        with self.assertRaises(ValueError):
            bump.update(self.contents, [[self.release]])

    def test_ignores_prereleases_and_other_release_tags(self):
        preview = copy.deepcopy(self.release)
        preview.update(tag_name="cloudcover-cli-v100.0.0", prerelease=True)
        other = dict(self.release, tag_name="cloudcover-sdk-v200.0.0")
        self.assertEqual(bump.update(self.contents, [[preview, other], [self.release]])[1], self.version)

    def test_does_not_downgrade(self):
        result, _ = bump.update(self.contents, [[self.release]])
        self.assertEqual(bump.update(result, [[dict(self.release, tag_name="cloudcover-cli-v0.0.1")]])[0], result)


if __name__ == "__main__":
    unittest.main()
