import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location(
    "validator", Path(__file__).with_name("validate-cloudcover-publication.py"))
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)


class PublicationGuardTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.git("init", "-q")
        self.git("config", "user.name", "Test")
        self.git("config", "user.email", "test@example.invalid")
        self.formula = self.root / "Formula/cloudcover.rb"
        self.formula.parent.mkdir()
        self.formula.write_text("base")
        self.git("add", ".")
        self.git("commit", "-qm", "base")
        self.source = self.git("rev-parse", "HEAD").decode().strip()
        self.formula.write_text("new")

    def git(self, *args):
        return subprocess.check_output(["git", *args], cwd=self.root)

    def validate(self, target=None):
        import os
        old = os.getcwd()
        try:
            os.chdir(self.root)
            with patch.object(validator, "git", self.git):
                validator.validate(self.source, target)
        finally:
            os.chdir(old)

    def commit(self):
        self.git("add", ".")
        self.git("commit", "-qm", "bump")
        return self.git("rev-parse", "HEAD").decode().strip()

    def test_regular_formula_allowed_in_worktree_and_commit(self):
        self.validate()
        self.validate(self.commit())

    def test_symlink_blocked_in_worktree_and_commit(self):
        self.formula.unlink()
        self.formula.symlink_to("../README.md")
        with self.assertRaisesRegex(ValueError, "regular"):
            self.validate()
        with self.assertRaisesRegex(ValueError, "regular"):
            self.validate(self.commit())

    def test_executable_blocked_in_worktree_and_commit(self):
        self.formula.chmod(0o755)
        with self.assertRaisesRegex(ValueError, "regular"):
            self.validate()
        with self.assertRaisesRegex(ValueError, "regular"):
            self.validate(self.commit())

    def test_deletion_blocked(self):
        self.formula.unlink()
        with self.assertRaisesRegex(ValueError, "regular"):
            self.validate()
        with self.assertRaisesRegex(ValueError, "regular"):
            self.validate(self.commit())

    def test_unrelated_committed_path_blocked(self):
        (self.root / "workflow.yml").write_text("unrelated")
        with self.assertRaisesRegex(ValueError, "only Formula"):
            self.validate(self.commit())

    def test_mutable_ref_blocked(self):
        with self.assertRaisesRegex(ValueError, "immutable"):
            self.validate("HEAD")


class WorkflowBoundaryTest(unittest.TestCase):
    def test_app_scope_and_credential_boundary(self):
        text = (Path(__file__).parent.parent / "workflows/autobump.yml").read_text()
        self.assertIn("if: github.repository == 'cyruscook/homebrew-tap' && github.ref == 'refs/heads/main'", text)
        self.assertIn("environment: homebrew-tap-updater", text)
        self.assertIn("contents: read", text)
        self.assertIn("pull-requests: read", text)
        self.assertNotIn("\n      contents: write", text)
        self.assertNotIn("\n      pull-requests: write", text)
        self.assertNotIn("token: ${{ secrets.GITHUB_TOKEN }}", text)
        self.assertEqual(text.count("secrets.HOMEBREW_TAP_UPDATER_APP_PRIVATE_KEY"), 1)
        self.assertIn("repositories: homebrew-tap", text)
        self.assertIn("permission-contents: write", text)
        self.assertIn("permission-pull-requests: write", text)
        self.assertNotIn("skip-token-revoke:", text)
        self.assertLess(text.index("Test autobump helpers"), text.index("id: publisher-token"))
        self.assertLess(text.index('"$version" --prepare'), text.index("id: publisher-token"))
        self.assertEqual(text.count("GH_TOKEN: ${{ steps.publisher-token.outputs.token }}"), 1)
        self.assertIn("GIT_CONFIG_VALUE_1: '!gh auth git-credential'", text)
        self.assertNotIn("shell: bash -x", text)


if __name__ == "__main__":
    unittest.main()
