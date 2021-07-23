# ACE Keda demo

Based on the MQ Keda demo at https://github.com/ibm-messaging/mq-dev-patterns/tree/master/Go-K8s with 
the ACE Maven/Tekton pipeline taken from https://github.com/ot4i/ace-demo-pipeline and modified.

Note that until https://github.com/kedacore/keda/issues/1938 is in a release, the admin credentials for
the keda QM polling need to be attached to the application container.

## Scenario description (in progress)

ACE replaces the consumer container in the MQ demo, and the rest is similar from a Keda point of view.

The container runs without node.js and Java by default to keep startup time to a minimum. On a 
CodeReady Contaners cluster in a VM, the difference is significant.

With Java but without node.js:
```
2021-07-23 16:29:37.000664: BIP1990I: Integration server 'ace-server' starting initialization; version '12.0.1.0' (64-bit)
2021-07-23 16:29:37.019744: BIP9905I: Initializing resource managers.
2021-07-23 16:29:40.223180: BIP9906I: Reading deployed resources.
2021-07-23 16:29:40.232576: BIP9907I: Initializing deployed resources.
2021-07-23 16:29:40.235188: BIP2155I: About to 'Initialize' the deployed resource 'ConsumeMQ' of type 'Application'.
2021-07-23 16:29:40.427972: BIP2155I: About to 'Start' the deployed resource 'ConsumeMQ' of type 'Application'.
2021-07-23 16:29:40.428484: BIP2269I: Deployed resource 'InputToTrace' (uuid='InputToTrace',type='MessageFlow') started successfully.
2021-07-23 16:29:40.429220: BIP1991I: Integration server has finished initialization.
```

With neither Java nor node.js
```
2021-07-23 17:16:11.824198: BIP1990I: Integration server 'ace-server' starting initialization; version '12.0.1.0' (64-bit)
2021-07-23 17:16:11.841579: BIP9905I: Initializing resource managers.
2021-07-23 17:16:11.940874: BIP9906I: Reading deployed resources.
2021-07-23 17:16:11.946663: BIP9907I: Initializing deployed resources.
2021-07-23 17:16:11.947653: BIP2155I: About to 'Initialize' the deployed resource 'ConsumeMQ' of type 'Application'.
2021-07-23 17:16:11.952800: BIP2155I: About to 'Start' the deployed resource 'ConsumeMQ' of type 'Application'.
2021-07-23 17:16:11.953131: BIP2269I: Deployed resource 'InputToTrace' (uuid='InputToTrace',type='MessageFlow') started successfully.
2021-07-23 17:16:11.953606: BIP1991I: Integration server has finished initialization.
```


## Instructions (in progress)

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

