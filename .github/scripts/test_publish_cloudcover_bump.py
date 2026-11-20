import os
from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).with_name("publish-cloudcover-bump.sh").resolve()
BRANCH = "bump-cloudcover-0.2.3"


class PublishBumpTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.remote = self.root / "remote.git"
        self.checkout = self.root / "checkout"
        self.env = dict(os.environ, GIT_CONFIG_NOSYSTEM="1", GIT_CONFIG_GLOBAL="/dev/null")
        self.run_git("init", "--bare", str(self.remote), cwd=self.root)
        self.run_git("init", "-b", "main", str(self.checkout), cwd=self.root)
        self.run_git("config", "user.name", "Test")
        self.run_git("config", "user.email", "test@example.invalid")
        self.run_git("remote", "add", "origin", str(self.remote))
        self.formula = self.checkout / "Formula/cloudcover.rb"
        self.formula.parent.mkdir()
        self.formula.write_text("old formula\n")
        self.run_git("add", ".")
        self.run_git("commit", "-m", "initial")
        self.run_git("push", "origin", "main")
        self.base = self.run_git("rev-parse", "HEAD").stdout.strip()
        self.formula.write_text("new formula\n")
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.log = self.root / "commands.log"
        self.env.update(PATH=str(self.bin) + os.pathsep + self.env["PATH"], COMMAND_LOG=str(self.log))
        self.write_mock("brew", 'echo "brew $*" >> "$COMMAND_LOG"\n')
        self.write_mock("gh", '''echo "gh $*" >> "$COMMAND_LOG"
if [[ "$1 $2" == "pr list" ]]; then
  if [[ "${LIST_EXIT:-0}" != "0" ]]; then
    exit "$LIST_EXIT"
  fi
  printf '%s' "${EXISTING_PR:-}"
elif [[ "$1 $2" == "pr create" ]]; then
  exit "${CREATE_EXIT:-0}"
else
  exit 99
fi
''')

    def write_mock(self, name, contents):
        path = self.bin / name
        path.write_text("#!/usr/bin/env bash\nset -euo pipefail\n" + contents)
        path.chmod(0o755)

    def run_git(self, *args, cwd=None):
        return subprocess.run(["git", *args], cwd=cwd or self.checkout, env=self.env,
                              text=True, capture_output=True, check=True)

    def publish(self, *arguments, **variables):
        return subprocess.run(["bash", str(SCRIPT), "0.2.3", *arguments], cwd=self.checkout,
                              env=dict(self.env, **variables), text=True, capture_output=True)

    def remote_head(self):
        return self.run_git("ls-remote", "--heads", "origin", BRANCH).stdout.split()[0]

    def seed_branch(self, formula="new formula\n", unrelated=False):
        self.run_git("switch", "-c", BRANCH)
        self.formula.write_text(formula)
        if unrelated:
            (self.checkout / "unrelated.txt").write_text("leave this alone\n")
        self.run_git("add", ".")
        self.run_git("commit", "-m", "existing bump")
        self.run_git("push", "origin", BRANCH)
        head = self.remote_head()
        self.run_git("switch", "main")
        self.formula.write_text("new formula\n")
        return head

    def test_creates_new_branch_and_pull_request(self):
        result = self.publish()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotEqual(self.remote_head(), self.base)
        self.assertIn("gh pr create --draft --base main --head " + BRANCH, self.log.read_text())

    def test_reuses_orphan_branch_without_another_commit_or_push(self):
        head = self.seed_branch()
        result = self.publish()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.remote_head(), head)
        self.assertEqual(self.run_git("rev-parse", "HEAD").stdout.strip(), self.base)
        self.assertIn("Reusing existing", result.stdout)
        self.assertIn("gh pr create", self.log.read_text())

    def test_existing_open_pull_request_is_a_noop(self):
        head = self.seed_branch()
        result = self.publish(EXISTING_PR="42")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.remote_head(), head)
        self.assertNotIn("brew ", self.log.read_text())
        self.assertNotIn("gh pr create", self.log.read_text())

    def test_pr_lookup_failure_stops_before_audit_or_publication(self):
        result = self.publish(LIST_EXIT="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.run_git("ls-remote", "--heads", "origin", BRANCH).stdout, "")
        self.assertEqual(self.run_git("rev-parse", "HEAD").stdout.strip(), self.base)
        self.assertNotIn("brew ", self.log.read_text())
        self.assertNotIn("gh pr create", self.log.read_text())

    def test_refuses_existing_branch_with_different_formula(self):
        head = self.seed_branch(formula="someone else's formula\n")
        result = self.publish()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.remote_head(), head)
        self.assertIn("different formula contents", result.stderr)
        self.assertNotIn("gh pr create", self.log.read_text())

    def test_refuses_existing_branch_with_unrelated_changes(self):
        head = self.seed_branch(unrelated=True)
        result = self.publish()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.remote_head(), head)
        self.assertIn("unrelated changes", result.stderr)
        self.assertNotIn("gh pr create", self.log.read_text())

    def test_missing_common_history_stops_before_pull_request_creation(self):
        self.formula.write_text("old formula\n")
        self.run_git("switch", "--orphan", BRANCH)
        self.formula.parent.mkdir(exist_ok=True)
        self.formula.write_text("new formula\n")
        self.run_git("add", ".")
        self.run_git("commit", "-m", "unrelated history")
        self.run_git("push", "origin", BRANCH)
        head = self.remote_head()
        self.run_git("switch", "main")
        self.formula.write_text("new formula\n")
        result = self.publish()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.remote_head(), head)
        self.assertNotIn("gh pr create", self.log.read_text())

    def test_failed_pr_creation_can_be_retried_without_non_fast_forward_push(self):
        failed = self.publish(CREATE_EXIT="1")
        self.assertNotEqual(failed.returncode, 0)
        self.assertIn("compare/main..." + BRANCH, failed.stderr)
        head = self.remote_head()
        self.run_git("switch", "main")
        self.formula.write_text("new formula\n")
        retried = self.publish()
        self.assertEqual(retried.returncode, 0, retried.stderr)
        self.assertEqual(self.remote_head(), head)
        self.assertIn("Reusing existing", retried.stdout)

    def test_prepare_does_not_push_or_create_pr_and_publish_skips_audit(self):
        output = self.root / "outputs"
        result = self.publish("--prepare", GITHUB_OUTPUT=str(output))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("ready=true", output.read_text())
        sha = output.read_text().split("sha=", 1)[1].strip()
        self.assertEqual(self.run_git("ls-remote", "--heads", "origin", BRANCH).stdout, "")
        self.assertNotIn("gh pr create", self.log.read_text())
        self.log.write_text("")
        result = self.publish("--publish", sha, SOURCE_SHA=self.base)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.remote_head(), sha)
        self.assertNotIn("brew ", self.log.read_text())
        self.assertIn("gh pr create --draft", self.log.read_text())

    def test_prepare_reuses_orphan_branch_before_publication(self):
        head = self.seed_branch()
        output = self.root / "outputs"
        result = self.publish("--prepare", GITHUB_OUTPUT=str(output))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("sha=" + head, output.read_text())
        self.assertEqual(self.remote_head(), head)
        self.assertNotIn("gh pr create", self.log.read_text())

    def test_unrelated_staged_changes_stop_before_commit_or_push(self):
        (self.checkout / "unrelated.txt").write_text("unrelated")
        self.run_git("add", "unrelated.txt")
        result = self.publish()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.run_git("rev-parse", "HEAD").stdout.strip(), self.base)
        self.assertNotIn("gh pr create", self.log.read_text())

    def test_untracked_changes_stop_before_commit_or_push(self):
        (self.checkout / "unrelated.txt").write_text("untracked")
        result = self.publish()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.run_git("rev-parse", "HEAD").stdout.strip(), self.base)
        self.assertNotIn("gh pr create", self.log.read_text())

    def test_publish_refuses_changed_remote_without_overwriting_it(self):
        head = self.seed_branch()
        output = self.root / "outputs"
        result = self.publish("--prepare", GITHUB_OUTPUT=str(output))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.formula.write_text("old formula\n")
        self.run_git("switch", BRANCH)
        self.formula.write_text("newer remote formula\n")
        self.run_git("add", ".")
        self.run_git("commit", "-m", "concurrent update")
        self.run_git("push", "origin", BRANCH)
        newer = self.remote_head()
        self.run_git("switch", "main")
        self.formula.write_text("new formula\n")
        result = self.publish("--publish", head, SOURCE_SHA=self.base)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("changed after preparation", result.stderr)
        self.assertEqual(self.remote_head(), newer)
        self.assertNotIn("gh pr create", self.log.read_text())

    def test_pr_created_between_prepare_and_publish_is_a_noop(self):
        output = self.root / "outputs"
        result = self.publish("--prepare", GITHUB_OUTPUT=str(output))
        self.assertEqual(result.returncode, 0, result.stderr)
        sha = output.read_text().split("sha=", 1)[1].strip()
        result = self.publish("--publish", sha, SOURCE_SHA=self.base, EXISTING_PR="42")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("gh pr create", self.log.read_text())

    def test_reuses_formula_only_branch_after_main_changes(self):
        head = self.seed_branch()
        self.formula.write_text("old formula\n")
        (self.checkout / "workflow.yml").write_text("new workflow")
        self.run_git("add", ".")
        self.run_git("commit", "-m", "advance main")
        self.formula.write_text("new formula\n")
        result = self.publish()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.remote_head(), head)

    def test_audit_failure_stops_before_commit_or_push(self):
        self.write_mock("brew", "exit 1\n")
        result = self.publish()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.run_git("rev-parse", "HEAD").stdout.strip(), self.base)
        self.assertNotIn("gh pr create", self.log.read_text())


if __name__ == "__main__":
    unittest.main()
