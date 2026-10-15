"""Update every platform from GitHub release asset SHA-256 digests.

Read `gh api --paginate --slurp repos/cyruscook/cloudcover/releases` on stdin.
Homebrew's bump-formula-pr cannot rewrite nested OS/architecture URL stanzas.
"""

import json
from pathlib import Path
import re
import sys


def update(contents, pages):
    releases = []
    for page in pages:
        for release in page:
            match = re.fullmatch(r"cloudcover-cli-v(\d+(?:\.\d+)+)", release["tag_name"])
            if match and not release["draft"] and not release["prerelease"]:
                releases.append((tuple(map(int, match[1].split("."))), release))
    if not releases:
        raise ValueError("No stable CloudCover CLI release found")
    version_parts, release = max(releases, key=lambda item: item[0])
    version = release["tag_name"].removeprefix("cloudcover-cli-v")
    current = set(re.findall(r"/cloudcover-cli-v(\d+(?:\.\d+)+)/", contents))
    if len(current) != 1:
        raise ValueError("Expected one consistent version across all platform URLs")
    if version_parts <= tuple(map(int, current.pop().split("."))):
        return contents, version

    assets = {asset["name"]: asset for asset in release["assets"]}
    for target in (
        "aarch64-apple-darwin", "x86_64-apple-darwin",
        "aarch64-unknown-linux-gnu", "x86_64-unknown-linux-gnu",
    ):
        name = f"cloudcover-cli-{target}.tar.gz"
        asset = assets[name]
        digest = asset.get("digest", "")
        if asset["state"] != "uploaded" or not re.fullmatch(r"sha256:[0-9a-f]{64}", digest or ""):
            raise ValueError(f"Missing uploaded asset or SHA-256 digest: {name}")
        url = f'https://github.com/cyruscook/cloudcover/releases/download/{release["tag_name"]}/{name}'
        if asset["browser_download_url"] != url:
            raise ValueError(f"Unexpected download URL: {name}")
        pattern = (
            r'url "https://github\.com/cyruscook/cloudcover/releases/download/[^/]+/'
            + re.escape(name) + r'"\n(\s+version "[^"]+"\n)?(\s+)sha256 "[0-9a-f]{64}"'
        )
        contents, count = re.subn(
            pattern,
            lambda match: f'url "{url}"\n'
            + (f'{match[2]}version "{version}"\n' if match[1] else "")
            + f'{match[2]}sha256 "{digest[7:]}"',
            contents,
        )
        if count != 1:
            raise ValueError(f"Expected exactly one formula stanza for {name}, found {count}")
    return contents, version


if __name__ == "__main__":
    formula = Path("Formula/cloudcover.rb")
    contents, version = update(formula.read_text(), json.load(sys.stdin))
    formula.write_text(contents)
    print(version)
