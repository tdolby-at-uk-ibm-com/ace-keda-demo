# Minikube setup 

[Minikube](https://minikube.sigs.k8s.io/docs/) is used extensively for local Kubernetes testing
and there are quite a few guides on the Internet to explain how to set it up and configure it.
This README describes one example of using minikube v1.32.0 on Ubuntu 22.04 with the KEDA demo.

Points to note:
- The IP address range in this case was 192.168.x.y but this may vary. The `minikube ip` command
  should provide the correct address, which then can be used to determine the correct subnet 
  value for the `--insecure-registry` parameter. The addresses appear to be the same for a given
  machine, so running `minikube start` followed by `minikube ip` to find the IP address followed
  by `minikube stop` and `minikube delete` should provide the information necessary for the "real"
  startup command line.
- This example uses the `ace-minimal` mqclient image with Minikube; it is also possible to use
  KEDA to scale ACE certified containers using the ACE operator.


## Steps

```
minikube start --insecure-registry "192.168.0.0/16"
minikube addons enable dashboard
minikube addons enable registry
minikube addons enable metrics-server

ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ minikube ip
192.168.49.2

kubectl apply -f tekton/minikube/minikube-registry-nodeport.yaml
kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
kubectl apply --filename https://storage.googleapis.com/tekton-releases/dashboard/latest/release.yaml
kubectl create secret docker-registry regcred --docker-server=us.icr.io --docker-username=notused --docker-password=notused

kubectl apply -f tekton/service-account.yaml
```


For `ace-minimal` , update the `aceDownloadUrl` parameter in
tekton/minimal-image-build/ace-minimal-build-image-pipeline-run.yaml to a valid download URL
(see [setting-the-correct-product-version](/tekton/minimal-image-build/README.md#setting-the-correct-product-version)
for details) and then run:
```
kubectl apply -f tekton/minimal-image-build/03-ace-mqclient-image-build-and-push-task.yaml
kubectl apply -f tekton/minimal-image-build/ace-minimal-image-pipeline.yaml

kubectl create -f tekton/minimal-image-build/ace-minimal-image-pipeline-run.yaml
tkn pipelinerun logs -L -f
```

Building and deploying the application:
```
kubectl apply -f tekton/10-ibmint-ace-build-task.yaml
kubectl apply -f tekton/20-deploy-to-cluster-task.yaml
kubectl apply -f tekton/21-knative-deploy-task.yaml
kubectl apply -f tekton/ace-pipeline.yaml

kubectl create -f tekton/ace-pipeline-run.yaml
tkn pipelinerun logs -L -f
```
The application should now be available and processing MQ messages.