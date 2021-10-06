# KEDA artifacts

KEDA configuration for the demo application.

## keda-configuration.yaml

Contains a ScaledObject to specify the deployment to scale, and MQ connection
parameters, a TriggerAuthentication setting to enable the KEDA scaler to connect
to the MQ queue manager, and a HorizontalPodAutoscaler definition.

The HorizontalPodAutoscaler should not be needed, but due to some issues with KEDA
and some version of Kube, the KEDA autoscaler fails to create the HorizontalPodAutoscaler.
If it is created beforehand, then the scaling works as normal.

## secrets.yaml

Contains the MQ connection credentials for the app itself and also the admin credentials
for use by the autoscaler polling.

## deploy-producer.yaml

Creates a job to put MQ messages to the demo queue. Only needed if many messages
are desired, and the demo can be run using the MQ console to put test messages to
the queue.

Note that if this demo is run using a Developer edition container, then the ACE flow
will only process one message per second; use the product container with care in this case.

