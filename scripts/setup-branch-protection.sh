#!/usr/bin/env bash
# Apply (or re-apply) branch protection on `main` to match the rules in
# AGENTS.md. Idempotent — safe to run multiple times.
#
# Requires:
#   - gh CLI, authenticated against the repo (`gh auth status`)
#   - admin permission on the repo
#
# Usage:
#   scripts/setup-branch-protection.sh [repo]
#   repo defaults to the current repo from `gh repo view`.

set -euo pipefail

REPO="${1:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}"
BRANCH="main"

echo "Applying protection to ${REPO}:${BRANCH}"

gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "/repos/${REPO}/branches/${BRANCH}/protection" \
  --input - <<'JSON'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["CI"]
  },
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false,
    "required_approving_review_count": 1,
    "require_last_push_approval": true
  },
  "required_conversation_resolution": true,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "restrictions": null,
  "enforce_admins": false,
  "lock_branch": false,
  "allow_fork_syncing": false,
  "require_signed_commits": false
}
JSON

echo "Done. Current state:"
gh api "/repos/${REPO}/branches/${BRANCH}/protection" \
  | jq '{
      require_pr: .required_pull_request_reviews.required_approving_review_count,
      dismiss_stale: .required_pull_request_reviews.dismiss_stale_reviews,
      last_push_approval: .required_pull_request_reviews.require_last_push_approval,
      require_status: .required_status_checks.contexts,
      linear_history: .required_linear_history,
      block_force_push: .allow_force_pushes,
      block_deletion: .allow_deletions,
      enforce_admins: .enforce_admins
    }'
