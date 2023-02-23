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

# Install MQ client libraries and hack the results to keep the image small enough to
# fit in the IBM Cloud Container Registry free tier with a limit of 512MB; the 32-bit
# programs and libraries don't actually work in this container anyway as compatibility
# libraries would also be needed, and we're running an English-only ACE install.
RUN mkdir /opt/mqm && \
    chmod 775 /opt/mqm && \
    cd /tmp && \
    aria2c -o mq-client.tar.gz  ${MQ_DOWNLOAD_URL} && \
    tar -xf /tmp/mq-client.tar.gz --directory /opt/mqm && \
    rm /tmp/mq-client.tar.gz && \
    rm -rf /opt/mqm/gskit8/bin/gsk8capicmd /opt/mqm/gskit8/lib /opt/mqm/lib/lib*.so /opt/mqm/samp/dotnet /opt/mqm/msg/cs_CZ /opt/mqm/msg/de_DE /opt/mqm/msg/es_ES /opt/mqm/msg/fr_FR /opt/mqm/msg/hu_HU /opt/mqm/msg/it_IT /opt/mqm/msg/ja_JP /opt/mqm/msg/ko_KR /opt/mqm/msg/pl_PL /opt/mqm/msg/pt_BR /opt/mqm/msg/ru_RU /opt/mqm/msg/zh_CN /opt/mqm/msg/zh_TW

# Kaniko seems to chmod this directory 755 by mistake sometimes, which causes trouble later
RUN chmod 1777 /tmp

USER aceuser

# We're in an internal pipeline
ENV LICENSE=accept

# Set entrypoint to run the server; should move the apply overrides to the startup script at some point
ENTRYPOINT ["bash", "-c", "/home/aceuser/ace-server/ace-startup-script.sh && IntegrationServer -w /home/aceuser/ace-server"]
