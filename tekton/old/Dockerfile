# Copyright (c) 2021-2024 Open Technologies for Integration
# Licensed under the MIT license (see LICENSE for details)

#FROM tdolby/experimental:ace-minimal-11.0.0.11-alpine
ARG BASE_IMAGE=ace-minimal:13.0.1.0-alpine-mqclient
FROM $BASE_IMAGE

LABEL "maintainer"="trevor.dolby@ibm.com"
USER root
WORKDIR /tmp/maven-output

# Must be in $HOME for aceuser
COPY mqclient.ini /home/aceuser/mqclient.ini

COPY ace-server /tmp/maven-output/ace-server/
RUN chown -R aceuser:mqbrkrs /tmp/* && \
    (cd /tmp/maven-output/ace-server && tar -cf - * ) | ( cd /home/aceuser/ace-server && tar -xf - ) && \
    chmod 775 /home/aceuser/ace-server/ace-startup-script.sh && \ 
    chmod 664 /home/aceuser/mqclient.ini


# Kaniko seems to chmod this directory 755 by mistake sometimes, which causes trouble later
RUN chmod 1777 /tmp

USER aceuser

# We're in an internal pipeline
ENV LICENSE=accept

# Set entrypoint to run the server; should move the apply overrides to the startup script at some point
ENTRYPOINT ["bash", "-c", "/home/aceuser/ace-server/ace-startup-script.sh && IntegrationServer -w /home/aceuser/ace-server"]