#!/usr/bin/env bash
set -euo pipefail

version="${1:?usage: publish-cloudcover-bump.sh VERSION [--prepare | --publish SHA]}"
mode="${2:---all}"
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Invalid CloudCover version: $version" >&2
  exit 1
fi
if [[ "$mode" != --all && "$mode" != --prepare && "$mode" != --publish ]]; then
  echo "Invalid publication mode: $mode" >&2
  exit 1
fi
branch="bump-cloudcover-$version"
source_sha="${SOURCE_SHA:-$(git rev-parse HEAD)}"
validator="$(dirname "${BASH_SOURCE[0]}")/validate-cloudcover-publication.py"

existing_pr="$(gh pr list --head "$branch" --state open --json number --jq '.[].number')"
if [[ -n "$existing_pr" ]]; then
  exit 0
fi

if [[ "$mode" != --publish ]]; then
  python3 "$validator" "$source_sha"
  brew style Formula/cloudcover.rb
  brew audit --strict cyruscook/tap/cloudcover
  # Style/audit must not introduce unrelated worktree or staged changes.
  python3 "$validator" "$source_sha"

  remote_sha="$(git ls-remote --heads origin "refs/heads/$branch" | awk 'NR == 1 { print $1 }')"
  if [[ -n "$remote_sha" ]]; then
    remote_ref="refs/remotes/origin/$branch"
    git fetch origin "refs/heads/$branch:$remote_ref"
    publication_sha="$(git rev-parse "$remote_ref")"
    if ! git show "$publication_sha:Formula/cloudcover.rb" | cmp - Formula/cloudcover.rb; then
      echo "Existing $branch has different formula contents; inspect it before retrying." >&2
      exit 1
    fi
    python3 "$validator" "$source_sha" "$publication_sha"
    echo "Reusing existing $branch for pull request creation."
  else
    git switch -c "$branch"
    git add Formula/cloudcover.rb
    git commit -m "cloudcover $version"
    publication_sha="$(git rev-parse HEAD)"
    python3 "$validator" "$source_sha" "$publication_sha"
  fi
  if [[ "$mode" == --prepare ]]; then
    printf 'ready=true\nsha=%s\n' "$publication_sha" >> "${GITHUB_OUTPUT:?GITHUB_OUTPUT is required for --prepare}"
    exit 0
  fi
else
  publication_sha="${3:?--publish requires the validated commit SHA}"
fi

# Revalidate immutable contents before publication, including a reused branch.
python3 "$validator" "$source_sha" "$publication_sha"
if ! git show "$publication_sha:Formula/cloudcover.rb" | cmp - Formula/cloudcover.rb; then
  echo "Prepared formula no longer matches the worktree." >&2
  exit 1
fi
remote_sha="$(git ls-remote --heads origin "refs/heads/$branch" | awk 'NR == 1 { print $1 }')"
if [[ -n "$remote_sha" && "$remote_sha" != "$publication_sha" ]]; then
  echo "Remote $branch changed after preparation; inspect it before retrying." >&2
  exit 1
fi
if [[ -z "$remote_sha" ]]; then
  # Never overwrite an existing branch; a concurrent creation fails safely.
  git push origin "$publication_sha:refs/heads/$branch" --force-with-lease="refs/heads/$branch:"
fi

if ! gh pr create --draft --base main --head "$branch" --title "cloudcover $version" \
  --body "Update all four platform archives and SHA-256 checksums from the CloudCover CLI release asset metadata. Verify required CI checks before merging."; then
  echo "The bump branch is published, but pull request creation failed. Retry after resolving the reported GitHub restriction, or open the PR manually:" >&2
  echo "https://github.com/${GITHUB_REPOSITORY:-cyruscook/homebrew-tap}/compare/main...$branch" >&2
  exit 1
fi
