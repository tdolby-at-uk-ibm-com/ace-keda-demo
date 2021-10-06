# ACE KEDA demo

Based on the MQ KEDA demo at https://github.com/ibm-messaging/mq-dev-patterns/tree/master/Go-K8s but using
an ACE flow instead of the MQ consumer application. The ACE application is a simple MQInput-based flow, and
the build pipeline is the ACE Maven/Tekton pipeline taken from https://github.com/ot4i/ace-demo-pipeline 
and modified.

Note that for versions earlier than 2.4.0, issue https://github.com/kedacore/keda/issues/1938 means
that the admin credentials for the KEDA QM polling need to be attached to the application container.

## Scenario description (in progress)

The original MQ KEDA demo used a pair of MQ applications in separate containers, with one putting and
the other getting MQ messages, and in this demo ACE replaces the consumer container, with the rest being
similar from a Keda point of view:

![Demo overview](keda/ace-keda-demo-picture.png)

Tekton is used to build and deploy the ACE application container, while the IBM MQ producer container
is used to provide a stream of messages. KEDA is configured to monitor the queue depth of the MQ on Cloud
queue (DEMO.QUEUE in this case) and scale the ACE consumer container appropriately.

The application containers use the ace-minimal image built using instructions (and Tekton build
artifacts) from https://github.com/ot4i/ace-demo-pipeline/tree/master/tekton/minimal-image-build

## Application description

The application reads messages from the queue and prints them to the server console:

![Application overview](ConsumeMQ/input-to-trace-flow.png)


## Instructions (in progress)

KEDA can be installed using the operator or via kubectl:
```
kubectl apply -f https://github.com/kedacore/keda/releases/download/v2.3.0/keda-2.3.0.yaml
```

Update the keda/secrets.yaml to contain the correct MQ application and admin credentials
(currently blank) for use by the KEDA scaler. This file then needs to be applied (before 
the app container is created due to the issue referenced above) so that the queue depth 
polling succeeds, and the mq-secret must be create to allow the container to run:

```
kubectl apply -f keda/secrets.yaml
kubectl create secret generic mq-secret --from-literal=USERID='app user' --from-literal=PASSWORD='app key' --from-literal=hostName='mqoc-419f.qm.eu-gb.mq.appdomain.cloud' --from-literal=portNumber='31175'
```

Building the ACE app:

See the [tekton README](tekton/README.md) for build instructions, including building the
ace-minimal containers.

Once the build has succeeded, apply the files in the keda directory to enable scaling for
the ace-keda-demo container:
```
kubectl apply -f keda/keda-configuration.yaml
```

Messages can be sent via the MQ on Cloud console, or by using the mqkeda producer container:
```
kubectl apply -f keda/deploy-producer.yaml
```

Monitor using the Kube console to inspect the number of pods for the deployment, or else use 
kubectl to show the number of replicas increasing and decreasing based on queue depth:
```
root@9ddf9a517959:/# kubectl get hpa -w
keda-hpa-ace-keda-demo   Deployment/ace-keda-demo   0/2 (avg)           1         5         4          65m
keda-hpa-ace-keda-demo   Deployment/ace-keda-demo   <unknown>/2 (avg)   1         5         0          65m
keda-hpa-ace-keda-demo   Deployment/ace-keda-demo   5/2 (avg)           1         5         1          66m
keda-hpa-ace-keda-demo   Deployment/ace-keda-demo   0/2 (avg)           1         5         4          66m
keda-hpa-ace-keda-demo   Deployment/ace-keda-demo   <unknown>/2 (avg)   1         5         0          67m
keda-hpa-ace-keda-demo   Deployment/ace-keda-demo   7/2 (avg)           1         5         1          67m
```

## Startup time notes

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
