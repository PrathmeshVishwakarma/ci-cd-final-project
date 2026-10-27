#!/usr/bin/env bash
# Prepare an OpenShift project for the CI/CD final project pipeline.
set -euo pipefail

NAMESPACE="${1:-sn-labs-prathmeshvi1}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v oc >/dev/null 2>&1; then
  echo "The oc CLI is required. Install it and log in first." >&2
  exit 1
fi

echo "Using OpenShift project: ${NAMESPACE}"
oc project "${NAMESPACE}" >/dev/null

echo "Creating the 1Gi skills-network-learner PVC"
oc apply -n "${NAMESPACE}" -f "${ROOT_DIR}/.tekton/pvc.yml"

echo "Creating the Tekton tasks and pipeline"
oc apply -n "${NAMESPACE}" -f "${ROOT_DIR}/.tekton/tasks.yml"
oc apply -n "${NAMESPACE}" -f "${ROOT_DIR}/.tekton/pipeline.yml"

echo
echo "Bootstrap complete."
echo "This lab does not allow the privileged SCC, so the buildah pipeline step"
echo "uses an unprivileged OpenShift S2I BuildConfig instead."
echo
echo "Start a run with:"
echo "  REPO_URL=https://github.com/PrathmeshVishwakarma/ci-cd-final-project.git \\"
echo "  NAMESPACE=${NAMESPACE} RUN_NAME=oc-pipelines-oc-green \\"
echo "  ${ROOT_DIR}/scripts/run-pipeline.sh"
