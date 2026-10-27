#!/usr/bin/env bash
# Prepare an OpenShift project for the CI/CD final project pipeline.
set -euo pipefail

NAMESPACE="${1:-ci-cd-final}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v oc >/dev/null 2>&1; then
  echo "The oc CLI is required. Install it and log in first." >&2
  exit 1
fi

echo "Using OpenShift project: ${NAMESPACE}"
oc new-project "${NAMESPACE}" >/dev/null 2>&1 || oc project "${NAMESPACE}" >/dev/null

echo "Creating the pipeline service account and permissions"
oc create serviceaccount pipeline --dry-run=client -o yaml | oc apply -n "${NAMESPACE}" -f - >/dev/null
oc adm policy add-scc-to-user privileged -z pipeline -n "${NAMESPACE}" >/dev/null
oc adm policy add-scc-to-user anyuid -z pipeline -n "${NAMESPACE}" >/dev/null
oc adm policy add-role-to-user edit -z pipeline -n "${NAMESPACE}" >/dev/null
oc adm policy add-role-to-user system:image-builder -z pipeline -n "${NAMESPACE}" >/dev/null

echo "Creating the 1Gi skills-network-learner PVC"
oc apply -n "${NAMESPACE}" -f "${ROOT_DIR}/.tekton/pvc.yml"

echo "Creating the Tekton tasks and pipeline"
oc apply -n "${NAMESPACE}" -f "${ROOT_DIR}/.tekton/tasks.yml"
oc apply -n "${NAMESPACE}" -f "${ROOT_DIR}/.tekton/pipeline.yml"

echo
echo "Bootstrap complete."
echo "Start a run with:"
echo "  REPO_URL=https://github.com/<user>/ci-cd-final-project.git \\"
echo "  RUN_NAME=oc-pipelines-oc-green ${ROOT_DIR}/scripts/run-pipeline.sh"
