# ACE demo pipeline

```
kubectl create secret generic mq-secret --from-literal=USERID='blah' --from-literal=PASSWORD='blah' --from-literal=hostName='mqoc-419f.qm.eu-gb.mq.appdomain.cloud' --from-literal=portNumber='31175'
kubectl apply -f tekton/10-ace-keda-demo-build-task.yaml 
kubectl apply -f tekton/20-ace-keda-demo-deploy-to-cluster-task.yaml
kubectl apply -f tekton/ace-keda-demo-pipeline.yaml
```

## How to get started

To replicate the pipeline locally, do the following:
