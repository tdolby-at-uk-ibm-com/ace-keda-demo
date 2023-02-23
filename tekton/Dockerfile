# Copyright (c) 2021-2023 Open Technologies for Integration
# Licensed under the MIT license (see LICENSE for details)

#FROM tdolby/experimental:ace-minimal-11.0.0.11-alpine
ARG BASE_IMAGE=ace-minimal:12.0.7.0-alpine
FROM $BASE_IMAGE
ARG MQ_DOWNLOAD_URL=https://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/messaging/mqdev/redist/9.3.1.0-IBM-MQC-Redist-LinuxX64.tar.gz

# Used for tekton and Maven containers

LABEL "maintainer"="trevor.dolby@ibm.com"
USER root
WORKDIR /tmp/maven-output

COPY ace-server /tmp/maven-output/ace-server/
RUN chown -R aceuser:mqbrkrs /tmp/* && \
    (cd /tmp/maven-output/ace-server && tar -cf - * ) | ( cd /home/aceuser/ace-server && tar -xf - ) && \
    chmod 775 /home/aceuser/ace-server/ace-startup-script.sh 

# Install MQ client libraries
RUN mkdir /opt/mqm && \
    chmod 775 /opt/mqm && \
    cd /tmp && \
    aria2c -o mq-client.tar.gz  ${MQ_DOWNLOAD_URL} && \
    tar -xf /tmp/mq-client.tar.gz --directory /opt/mqm && \
    rm /tmp/mq-client.tar.gz

# Kaniko seems to chmod this directory 755 by mistake sometimes, which causes trouble later
RUN chmod 1777 /tmp

USER aceuser

# We're in an internal pipeline
ENV LICENSE=accept

# Set entrypoint to run the server; should move the apply overrides to the startup script at some point
ENTRYPOINT ["bash", "-c", "/home/aceuser/ace-server/ace-startup-script.sh && IntegrationServer -w /home/aceuser/ace-server"]
