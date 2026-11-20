"""Allow only a regular, non-executable formula in an autobump publication.

An accidental-change guard, not a sandbox for code executing on trusted main.
"""
import argparse
from pathlib import Path
import re
import subprocess

FORMULA = "Formula/cloudcover.rb"


def git(*args):
    return subprocess.check_output(["git", *args])


def validate(source, target=None):
    if not re.fullmatch(r"[0-9a-f]{40}", source):
        raise ValueError("Expected immutable source SHA")
    if target is None:
        # Include committed, staged, unstaged and untracked changes.
        paths = git("diff", "--name-only", "--no-renames", "-z", source).split(b"\0")
        paths += git("ls-files", "--others", "--exclude-standard", "-z").split(b"\0")
        file = Path(FORMULA)
        regular = file.is_file() and not file.is_symlink() and not file.stat().st_mode & 0o111
    else:
        if not re.fullmatch(r"[0-9a-f]{40}", target):
            raise ValueError("Expected immutable publication SHA")
        base = git("merge-base", source, target).decode().strip()
        paths = git("diff", "--name-only", "--no-renames", "-z", base, target).split(b"\0")
        regular = git("ls-tree", target, "--", FORMULA).startswith(b"100644 blob ")
    if {p.decode() for p in paths if p} != {FORMULA}:
        raise ValueError("Publication must change only Formula/cloudcover.rb (no unrelated changes)")
    if not regular:
        raise ValueError("Formula must be a regular non-executable file")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source")
    parser.add_argument("target", nargs="?")
    args = parser.parse_args()
    validate(args.source, args.target)
