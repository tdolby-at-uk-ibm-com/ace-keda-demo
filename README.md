# ACE Keda demo

Based on the MQ Keda demo at https://github.com/ibm-messaging/mq-dev-patterns/tree/master/Go-K8s with 
the ACE Maven/Tekton pipeline taken from https://github.com/ot4i/ace-demo-pipeline and modified.

## Instructions

Building the ACE app:
```
kubectl create secret generic mq-secret --from-literal=USERID='blah' --from-literal=PASSWORD='blah' --from-literal=hostName='mqoc-419f.qm.eu-gb.mq.appdomain.cloud' --from-literal=portNumber='31175'
kubectl apply -f tekton/10-ace-keda-demo-build-task.yaml 
kubectl apply -f tekton/20-ace-keda-demo-deploy-to-cluster-task.yaml
kubectl apply -f tekton/ace-keda-demo-pipeline.yaml
kubectl apply -f tekton/ace-keda-demo-pipeline-run-crc.yaml
```

Update the keda/secrets.yaml to contain the correct MQ credentials (currently blank).

Apply the files in the keda directory to enable scaling for the ace-keda-demo container and
also send messages to the MQ on Cloud QM using the mqkeda producer container.

