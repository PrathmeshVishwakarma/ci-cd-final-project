#!/usr/bin/env bash
# Save the latest GitHub Actions run and its step logs to cicd-github-validate.
set -euo pipefail

REPO="${1:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}"
WORKFLOW="${WORKFLOW:-workflow.yml}"
OUTPUT="${OUTPUT:-cicd-github-validate}"

if ! command -v gh >/dev/null 2>&1; then
  echo "The GitHub CLI (gh) is required. Run 'gh auth login' first." >&2
  exit 1
fi

RUN_ID="$(gh run list --repo "${REPO}" --workflow "${WORKFLOW}" \
  --limit 1 --json databaseId -q '.[0].databaseId')"

if [ -z "${RUN_ID}" ] || [ "${RUN_ID}" = "null" ]; then
  echo "No run found for ${REPO}/${WORKFLOW}." >&2
  exit 1
fi

{
  echo "# GitHub Actions run ${RUN_ID} for ${REPO}"
  echo
  gh run view "${RUN_ID}" --repo "${REPO}"
  echo
  echo "# Step logs"
  echo
  gh run view "${RUN_ID}" --repo "${REPO}" --log
} > "${OUTPUT}"

echo "Saved GitHub Actions output to ${OUTPUT}"
