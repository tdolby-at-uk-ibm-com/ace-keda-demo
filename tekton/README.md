# Tekton pipeline

Used to run the pipeline stages via Tekton. 

![Pipeline overview](/demo-infrastructure/images/tekton-pipeline.png)

The tasks rely on several different containers:

- The Tekton git-init image to run the initial git clones.
- The ace-minimal-mqclient image for a small Alpine-based runtime container (~420MB, which fits into
the IBM Cloud container registry free tier limit of 512MB) with the MQ client installed..  See 
https://github.com/trevor-dolby-at-ibm-com/ace-docker/tree/master/experimental/ace-minimal for more 
details on the minimal image, and [minimal image build instructions](minimal-image-build/README.md)
on how to build the various pre-req images.

For the initial testing, variants of ace-minimal:13.0.1.0-alpine-mqclient have been pushed to tdolby/experimental 
on DockerHub, but this is not a stable location, and the images should be rebuilt by anyone attempting 
to use this repo.

## Getting started

A Kubernetes cluster will be needed, with Minikube (see [minikube/README.md](/tekton/minikube/README.md)) and
OpenShift 4.16 being the two most-tested. Other clusters should also work with appropriate adjustments to
ingress routing and container registry settings. 

Many of the artifacts in this repo (such as ace-keda-demo-pipeline-run.yaml) will need to be customized 
depending on the exact cluster layout. The defaults are set up for Minikube running with Docker on Ubuntu, 
and may needto be modified depending on network addresses, etc. The most-commonly-modified files have 
options in the comments, with [ace-keda-demo-pipeline-run.yaml](ace-keda-demo-pipeline-run.yaml) being 
one example:
```
    - name: buildImage
      # ace-minimal can be built from the ACE package without needing a key
      # OpenShift - note that ace-keda should match the pipeline namespace
      value: "image-registry.openshift-image-registry.svc.cluster.local:5000/ace-keda/ace-minimal:13.0.1.0-alpine-mqclient"
      #value: "quay.io/trevor_dolby/ace-minimal:13.0.1.0-alpine-mqclient"
      # Minikube
      #value: "192.168.49.2:5000/default/ace-minimal:13.0.1.0-alpine-mqclient"
```

The Tekton pipeline and ACE runtime rely on having permission to push to the container registry,
and this may require the provision of credentials for the service accounts to use:
- Minikube container registry does not have authentication enabled by default, and so dummy
credentials can be used for the `regcred` secret:
```
kubectl create secret docker-registry regcred --docker-server=us.icr.io --docker-username=notused --docker-password=notused
kubectl apply -f tekton/service-account.yaml
```
- OpenShift container registry does have authentication enabled, but this is integrated and requires
only that the service accounts have the `system:image-builder` role and dummy credentials can be used:
```
kubectl create secret docker-registry regcred --docker-server=us.icr.io --docker-username=notused --docker-password=notused
kubectl apply -f tekton/service-account.yaml
```
- External registries normally require authentication, and in that case the default runtime 
service account needs to be given the credentials:
```
kubectl create secret docker-registry regcred --docker-server=us.icr.io --docker-username=<user> --docker-password=<password>
kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "regcred"}]}'
kubectl apply -f tekton/service-account.yaml
```
The service account also has the ability to create services, deployments, etc, which are necessary 
for running the service.

Setting up the pipeline requires Tekton to be installed, tasks to be created, and the pipeline itself
to be configured. For Minikube and other Kubernetes clusters, Tekton must be installed first (which
may have been done already during ace-minimal-image build):
```
kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
kubectl apply -f tekton/10-ace-keda-demo-build-task.yaml
kubectl apply -f tekton/20-ace-keda-demo-deploy-to-cluster-task.yaml
kubectl apply -f tekton/ace-keda-demo-pipeline.yaml
```
Note that for Openshift, Tekton should not be installed this way; see below for details.

Once that has been accomplished, the simplest way to run the pipeline is
```
kubectl create -f tekton/ace-keda-demo-pipeline-run.yaml
tkn pipelinerun logs -L -f
```

and this should build the projects, run the unit tests, create a docker image, and then create a 
deployment that runs the application.

## How to know if the pipeline has succeeded

The end result should be a running container with the MQ demo application deployed, waiting for
messages on DEMO.QUEUE. The container logs should show no errors on startup, and putting a message
to the queue using the MQ on Cloud console should cause the Trace node to output some information
to the container log.

## Tekton dashboard

The Tekton dashboard (for non-OpenShift users) can be installed as follows:
```
kubectl apply --filename https://storage.googleapis.com/tekton-releases/dashboard/latest/tekton-dashboard-release.yaml
```

By default, the Tekton dashboard is not accessible outside the cluster; assuming a secure host
somewhere, the dashboard HTTP port can be made available locally as follows:
```
kubectl --namespace tekton-pipelines port-forward --address 0.0.0.0 svc/tekton-dashboard 9097:9097
```

## OpenShift

Tekton is not normally installed directly with OpenShift, and the Red Hat OpenShift Pipelines operator
would be used instead. The majority of the other steps are the same, but the registry authentication is 
a little different: the namespace in which the pipeline and pod are running must match the project
name in the image registry tags. The examples show 
`image-registry.openshift-image-registry.svc.cluster.local:5000/ace-keda/ace-minimal:13.0.1.0-alpine-mqclient`,
which will work for the `ace-keda` namespace.

To run outside the default namespace, a special SecurityContextConstraints must be created and
associated with the service account:
```
kubectl apply -f tekton/ace-scc.yaml
oc adm policy add-scc-to-user ace-scc -z ace-tekton-service-account
```
Without this change, errors of the form
```
task build-images has failed: pods "ace-minimal-image-pipeline-run-db8lw-build-images-pod" is forbidden: unable to validate against any security context constraint: 
```
may prevent the pipeline running correctly.

After that, the pipeline run files need to be adjusted to use the OpenShift registry, such 
as [ace-keda-demo-pipeline-run.yaml](ace-keda-demo-pipeline-run.yaml):
```
    - name: outputRegistry
      # OpenShift - note that ace-keda should match the pipeline namespace
      #value: "image-registry.openshift-image-registry.svc.cluster.local:5000/ace-keda"
      #value: "quay.io/trevor_dolby"
      #value: "us.icr.io/ace-containers"
      #value: "aceDemoRegistry.azurecr.io"
      # Minikube
      value: "192.168.49.2:5000/default"
```
and then the pipelines can be run as usual. The OpenShift Pipeline operator provides a 
web interface for the pipeline runs also, which may be an easier way to view progress.

## Possible enhancements

