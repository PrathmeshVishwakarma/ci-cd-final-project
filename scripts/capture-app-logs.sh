#!/usr/bin/env bash
# Save the OpenShift application logs to oc-pipeline-application-logs.
set -euo pipefail

NAMESPACE="${1:-${NAMESPACE:-ci-cd-final}}"
OUTPUT="${OUTPUT:-oc-pipeline-application-logs}"
SELECTOR="${SELECTOR:-app=counter-service,version=green}"

if ! command -v oc >/dev/null 2>&1; then
  echo "The oc CLI is required. Install it and log in first." >&2
  exit 1
fi

POD="$(oc get pods -n "${NAMESPACE}" -l "${SELECTOR}" \
  --sort-by=.metadata.creationTimestamp \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | tail -n 1)"

if [ -z "${POD}" ]; then
  echo "No pod found in ${NAMESPACE} with selector ${SELECTOR}." >&2
  exit 1
fi

oc logs -n "${NAMESPACE}" "${POD}" > "${OUTPUT}"

if grep -q "SERVICERUNNING" "${OUTPUT}"; then
  echo "Saved logs from ${POD} to ${OUTPUT} (SERVICERUNNING found)."
else
  echo "Saved logs from ${POD} to ${OUTPUT}, but SERVICERUNNING was not found." >&2
  exit 1
fi
