# CloudCover autobump publisher

The autobump previously pushed a bump branch with `GITHUB_TOKEN` and then failed
with “GitHub Actions is not permitted to create or approve pull requests.” It
now prepares and validates the formula using read-only credentials, then uses a
dedicated GitHub App for the push and draft PR. App publication also allows the
resulting PR event to trigger normal CI. It does not approve or merge the PR.

## Required setup before merging

Keep the workflow PR draft until an administrator verifies this setup. No App
installation, credentials or environment configuration is assumed to exist.
The CloudCover updater App installed on `cyruscook/cloudcover` is a separate
identity; this change does not expand its access or reuse its private key.

1. Create a private GitHub App dedicated to this tap, owned by `cyruscook`.
   Disable webhooks; no OAuth callback or user authorization is needed.
2. Grant only repository **Contents: read/write**, **Pull requests: read/write**,
   and implicit metadata read. No Actions, Workflows, Administration, Secrets,
   organization permissions or ruleset bypass rights.
3. Install the App on **only `cyruscook/homebrew-tap`**. First check whether a
   dedicated tap App already exists; do not create duplicate identities/keys.
4. Create the Actions environment **`homebrew-tap-updater`**. Set its deployment
   branch policy to **only the exact branch `main`**, with no tags, wildcard or
   PR refs. Do not use the broad “protected branches” option. This policy is
   required: a YAML condition alone cannot protect a secret from branch edits.
   Required reviewers may remain unset for unattended operation.
5. In that environment, set variable **`HOMEBREW_TAP_UPDATER_APP_CLIENT_ID`** and
   secret **`HOMEBREW_TAP_UPDATER_APP_PRIVATE_KEY`** through approved secure setup.
   Do not use repository/organization secrets for the key; never paste it in
   chat, code, PR text, logs or artifacts.
6. Verify selected repository, exact installation permissions and environment
   branch restrictions before activation. Preserve existing branch protection,
   fork workflow policies and the Actions PR creation setting.

Setup requires separate owner authorization. No repository settings, credentials
or App installations are created by this PR.

## Runtime behavior

- Only `cyruscook/homebrew-tap` on `refs/heads/main` runs the environment job.
- Homebrew's public checkout omits its `token` input to avoid persisting an HTTP
  auth header. The built-in token has only Contents/PR read permissions.
- Regression tests, generation, formula style/audit, worktree path/mode checks,
  and committed publication validation all finish before the App token is minted.
- The App token is explicitly scoped to `homebrew-tap`, Contents write and PR
  write. Only the publication step receives it. Git reads it using `gh`'s
  credential helper via process environment; no token is written to Git config
  or a remote URL. The official action revokes it at job cleanup.
- Validation allows only the regular, non-executable `Formula/cloudcover.rb`.
  It rejects unrelated staged, unstaged, untracked and committed changes.
  This guards accidental publication; it is not a sandbox for hostile main code.
- Preparation commits a new formula locally or validates and reuses a matching
  existing bump branch. Publication revalidates the immutable commit and refuses
  a remote branch that changed. An explicit empty-ref lease prevents overwriting
  a branch created concurrently. Existing open PRs are a no-op; failed PR
  creation leaves the branch intact for retry. New PRs are drafts.
- Contents write is repository-wide, not path-scoped. Main protection and review
  remain required; the publisher has no approval, merge or bypass steps.

## Validation and activation

Run `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s .github/scripts -v`,
`bash -n .github/scripts/publish-cloudcover-bump.sh`, `actionlint`, and workflow
security analysis. Normal PR CI must pass before merge.

After setup and merge, dispatch **Bump CloudCover** on `main` when a newer complete
CLI release is available. Verify the expected App authors the draft PR and both
Homebrew platform checks and autobump tests start without manual workflow
approval. A no-change run skips token creation and cannot verify publication.
Exercise recovery of an existing matching branch as well as a new branch.
Until these real App runs pass, unattended publication remains unverified.

If setup is unavailable, leave this PR draft. Roll back by reverting the workflow
change and revoking/uninstalling the dedicated App if unused. Do not relax fork
policies, enable `pull_request_target`, or modify release assets as a workaround.

References: [GitHub App authentication in Actions](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/making-authenticated-api-requests-with-a-github-app-in-a-github-actions-workflow),
[`GITHUB_TOKEN` behavior](https://docs.github.com/en/actions/concepts/security/github_token).
