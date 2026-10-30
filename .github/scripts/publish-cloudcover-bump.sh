#!/usr/bin/env bash
set -euo pipefail

version="${1:?usage: publish-cloudcover-bump.sh VERSION}"
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Invalid CloudCover version: $version" >&2
  exit 1
fi
branch="bump-cloudcover-$version"
existing_pr="$(gh pr list --head "$branch" --state open --json number --jq '.[].number')"
if [[ -n "$existing_pr" ]]; then
  exit 0
fi

brew style Formula/cloudcover.rb
brew audit --strict cyruscook/tap/cloudcover

remote_sha="$(git ls-remote --heads origin "refs/heads/$branch" | awk 'NR == 1 { print $1 }')"
if [[ -n "$remote_sha" ]]; then
  remote_ref="refs/remotes/origin/$branch"
  git fetch origin "refs/heads/$branch:$remote_ref"
  if ! git show "$remote_ref:Formula/cloudcover.rb" | cmp - Formula/cloudcover.rb; then
    echo "Existing $branch has different formula contents; inspect it before retrying." >&2
    exit 1
  fi
  unrelated_changes="$(git diff --name-only "HEAD...$remote_ref" -- . ':!Formula/cloudcover.rb')"
  if [[ -n "$unrelated_changes" ]]; then
    echo "Existing $branch contains unrelated changes; inspect it before retrying." >&2
    exit 1
  fi
  echo "Reusing existing $branch for pull request creation."
else
  git switch -c "$branch"
  git add Formula/cloudcover.rb
  git commit -m "cloudcover $version"
  git push origin "$branch"
fi

if ! gh pr create --base main --head "$branch" --title "cloudcover $version" \
  --body "Update all four platform archives and SHA-256 checksums from the CloudCover CLI release asset metadata."; then
  echo "The bump branch is published, but pull request creation failed. Retry after resolving the reported GitHub restriction, or open the PR manually:" >&2
  echo "https://github.com/${GITHUB_REPOSITORY:-cyruscook/homebrew-tap}/compare/main...$branch" >&2
  exit 1
fi
