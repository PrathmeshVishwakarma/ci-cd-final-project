#!/usr/bin/env bash
# Create a PipelineRun for the oc-pipelines pipeline.
set -euo pipefail

NAMESPACE="${NAMESPACE:-sn-labs-prathmeshvi1}"
REPO_URL="${REPO_URL:-}"
REVISION="${REVISION:-main}"
RUN_NAME="${RUN_NAME:-oc-pipelines-oc-green}"
SERVICE_ACCOUNT="${SERVICE_ACCOUNT:-default}"
IMAGE="${IMAGE:-image-registry.openshift-image-registry.svc:5000/${NAMESPACE}/cicd-app:latest}"

if [ -z "${REPO_URL}" ]; then
  cat >&2 <<'EOF'
Set REPO_URL to your public GitHub repository, for example:

  REPO_URL=https://github.com/<user>/ci-cd-final-project.git \
  RUN_NAME=oc-pipelines-oc-green \
  ./scripts/run-pipeline.sh
EOF
  exit 1
fi

if ! command -v oc >/dev/null 2>&1; then
  echo "The oc CLI is required. Install it and log in first." >&2
  exit 1
fi

oc delete pipelinerun "${RUN_NAME}" -n "${NAMESPACE}" --ignore-not-found

cat <<EOF | oc create -n "${NAMESPACE}" -f -
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  name: ${RUN_NAME}
  labels:
    app.kubernetes.io/part-of: oc-pipelines
spec:
  pipelineRef:
    name: oc-pipelines
  serviceAccountName: ${SERVICE_ACCOUNT}
  podTemplate:
    securityContext:
      runAsUser: 1001520000
  timeouts:
    pipeline: 1h0m0s
  workspaces:
    - name: pipeline-workspace
      persistentVolumeClaim:
        claimName: oc-lab-pvc
  params:
    - name: repo-url
      value: ${REPO_URL}
    - name: revision
      value: ${REVISION}
    - name: image
      value: ${IMAGE}
    - name: namespace
      value: ${NAMESPACE}
    - name: deployment-name
      value: cicd-app
EOF

echo
echo "PipelineRun ${RUN_NAME} created in ${NAMESPACE}."
echo "Follow the logs with:"
echo "  oc logs -n ${NAMESPACE} -f pipelinerun/${RUN_NAME}"
echo "or, if tkn is installed:"
echo "  tkn pipelinerun logs -f ${RUN_NAME} -n ${NAMESPACE}"
