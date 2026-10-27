# CI/CD Final Project: Counter Service on OpenShift

[![CI](https://github.com/PrathmeshVishwakarma/ci-cd-final-project/actions/workflows/workflow.yml/badge.svg)](https://github.com/PrathmeshVishwakarma/ci-cd-final-project/actions/workflows/workflow.yml)

Public repository: <https://github.com/PrathmeshVishwakarma/ci-cd-final-project>

## Project name details

| Field | Value |
| --- | --- |
| Project name | **ci-cd-final-project** |
| Application | **counter-service** |
| Runtime | Python 3.9 / Flask 2.2 |
| Continuous integration | GitHub Actions |
| Continuous delivery | Tekton / OpenShift Pipelines |
| Target platform | OpenShift, project `ci-cd-final` |
| Test runner | nose |
| Linter | flake8 |

## Overview

This repository contains a small Flask counter service and a complete CI/CD
pipeline for it. Every push to `main` is linted and tested by GitHub Actions.
The same source is then built and deployed by an OpenShift Tekton pipeline that
runs the following steps:

1. `cleanup` - clears the shared workspace.
2. `git-clone` - clones the repository from GitHub.
3. `flake8` - lints the Python code.
4. `nose` - runs the unit tests.
5. `buildah` - builds the container image and pushes it to the OpenShift
   internal registry.
6. `deploy` - applies the OpenShift manifests and waits for the rollout.

## API

| Method | Path | Description |
| --- | --- | --- |
| `GET` | `/` | Service metadata and status |
| `GET` | `/health` | Readiness/liveness probe |
| `GET` | `/count` | Current counter value |
| `POST` | `/count` | Increment the counter |
| `DELETE` | `/count` | Reset the counter to zero |

The service listens on port `8000`.

## Repository layout

```text
.
|-- .github/workflows/workflow.yml   # GitHub Actions CI
|-- .tekton/
|   |-- tasks.yml                    # cleanup, flake8, nose, buildah, deploy tasks
|   |-- pipeline.yml                 # oc-pipelines pipeline
|   |-- pvc.yml                      # 1Gi skills-network-learner PVC
|   |-- pipeline-run-final.yml       # oc-pipelines-oc-final run
|   `-- pipeline-run-green.yml       # oc-pipelines-oc-green run
|-- manifests/
|   |-- deployment.yaml              # counter-service-green deployment
|   |-- service.yaml                 # counter-service-green service
|   `-- route.yaml                   # edge-terminated route
|-- scripts/
|   |-- bootstrap-openshift.sh       # create project, SA, PVC, tasks, pipeline
|   |-- run-pipeline.sh              # create a PipelineRun
|   |-- capture-github-actions.sh    # writes cicd-github-validate
|   `-- capture-app-logs.sh          # writes oc-pipeline-application-logs
|-- tests/test_app.py                # nose unit tests
|-- app.py
|-- requirements.txt
|-- Dockerfile
`-- README.md
```

## Push updates to GitHub

```bash
git add .
git commit -m "Describe your change"
git push
```

The pipeline run manifests point at
`https://github.com/PrathmeshVishwakarma/ci-cd-final-project.git`. Update that
URL if you fork the repository under a different account, or use
`scripts/run-pipeline.sh` with `REPO_URL`.

## Run locally

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

flake8 app.py tests --count --statistics
nosetests -v tests

PORT=8000 python app.py
```

In another terminal:

```bash
curl http://localhost:8000/health
curl -X POST http://localhost:8000/count
curl http://localhost:8000/count
```

## Continuous integration with GitHub Actions

Workflow: [`.github/workflows/workflow.yml`](.github/workflows/workflow.yml)

The workflow runs on every push and pull request to `main` and performs:

- checkout and Python 3.9 setup;
- dependency installation;
- **Lint with flake8**;
- **Run unit tests with nose**;
- Docker image build.

The exact graded steps are named `Lint with flake8` and
`Run unit tests with nose` inside the workflow.

## Continuous delivery with Tekton

### 1. Log in to OpenShift

```bash
oc login --token=<token> --server=<server>
```

### 2. Create the project, service account, PVC, tasks, and pipeline

```bash
chmod +x scripts/*.sh
./scripts/bootstrap-openshift.sh ci-cd-final
```

This creates:

- the `pipeline` service account with `edit`, `system:image-builder`,
  `privileged`, and `anyuid` permissions;
- the `oc-pipelines-pvc` PVC with storage class `skills-network-learner` and
  a requested capacity of `1Gi`;
- the custom Tekton tasks and the `oc-pipelines` pipeline.

The `git-clone` task is the ClusterTask that ships with OpenShift Pipelines.

### 3. Start a pipeline run

Either edit the repository URL in `.tekton/pipeline-run-green.yml` and apply
it:

```bash
oc apply -n ci-cd-final -f .tekton/pipeline-run-green.yml
```

or use the helper (this accepts the repository URL and run name):

```bash
REPO_URL=https://github.com/<your-user>/ci-cd-final-project.git \
RUN_NAME=oc-pipelines-oc-green \
./scripts/run-pipeline.sh
```

For the `oc-pipelines-oc-final` run:

```bash
REPO_URL=https://github.com/<your-user>/ci-cd-final-project.git \
RUN_NAME=oc-pipelines-oc-final \
COLOR=latest \
./scripts/run-pipeline.sh
```

### 4. Follow and verify the run

```bash
oc logs -n ci-cd-final -f pipelinerun/oc-pipelines-oc-green
oc get pipelinerun -n ci-cd-final
oc get pods -n ci-cd-final
```

The pipeline succeeds when all six tasks are green:
`cleanup`, `git-clone`, `flake8`, `nose`, `buildah`, `deploy`.

Verify the application:

```bash
oc get route -n ci-cd-final
curl -k https://<route-host>/health
curl -k https://<route-host>/
```

## Submission artifacts

| Question | Artifact | How to produce it |
| --- | --- | --- |
| Q1 | This `README.md` | Public GitHub URL of this file |
| Q2 | `.github/workflows/workflow.yml` | Public GitHub URL of the workflow |
| Q3 | `.tekton/tasks.yml` | Public GitHub URL of the tasks |
| Q4 | `cicd-github-validate` | `./scripts/capture-github-actions.sh <owner>/<repo>` |
| Q5 | `oc-pipelines-console-pvc-details.png` | OpenShift console: **Storage > PersistentVolumeClaim > oc-pipelines-pvc** |
| Q6 | `oc-pipelines-oc-final.png` | OpenShift console: **Pipelines > PipelineRuns > oc-pipelines-oc-final** |
| Q7 | `oc-pipelines-oc-green.png` | OpenShift console: **Pipelines > PipelineRuns > oc-pipelines-oc-green** |
| Q8 | `oc-pipeline-application-logs` | `./scripts/capture-app-logs.sh` |

The PVC screenshot must show storage class `skills-network-learner` and
requested capacity `1Gi`. The pipeline screenshots must show all six task nodes
(`cleanup`, `git-clone`, `flake8`, `nose`, `buildah`, `deploy`) in a successful
state.

After the green deployment is running:

```bash
./scripts/capture-app-logs.sh
cat oc-pipeline-application-logs
```

The application log contains the startup line:

```text
SERVICERUNNING counter-service listening on port 8000
```

## Troubleshooting

- **`buildah` cannot push the image:** confirm that the `pipeline` service
  account has `system:image-builder` and `privileged` permissions. The buildah
  task uses the service account token and the OpenShift internal registry.
- **`git-clone` task not found:** install or enable the OpenShift Pipelines
  `git-clone` ClusterTask, or replace the `taskRef` with the Tekton Hub
  `git-clone` task.
- **PVC stays pending:** confirm that the cluster provides the
  `skills-network-learner` storage class in the target project.
- **nose fails on Python 3.10+:** nose 1.3.7 targets Python 3.9. The Dockerfile
  and both pipelined test environments use Python 3.9.
- **Route returns 503:** wait for `oc rollout status deployment/counter-service-green`
  and confirm that the pod is `Running` and its readiness probe passes.

## Cleanup

```bash
oc delete project ci-cd-final
```
