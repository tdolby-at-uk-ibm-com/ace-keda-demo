#!/bin/bash

# Assumes the current shell has kubectl in PATH, is logged in, and has
# the correct namespace set as default. The cluster is also assumed to
# have Tekton installed and a service account created for the pipeline.

# We might be run from the root of the repo or from the subdirectory
export YAMLDIR=`dirname $0`

set -e # Exit on error
set -x # Show what we're doing
kubectl apply -f ${YAMLDIR}/03-ace-mqclient-image-build-and-push-task.yaml
kubectl apply -f ${YAMLDIR}/ace-minimal-image-pipeline.yaml

set +x
echo "Success; the pipeline can now be run after ace-minimal-image-pipeline-run.yaml is customized."
echo "Use ${YAMLDIR}/ace-minimal-image-pipeline-run.yaml to build ace-minimal mqclient"
echo
echo "Example command sequence to run the pipeline and show the Tekton logs:"
echo
echo "kubectl create -f ${YAMLDIR}/ace-minimal-build-image-pipeline-run.yaml ; tkn pr logs -L -f"
