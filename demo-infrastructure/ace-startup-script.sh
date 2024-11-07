#!/bin/bash
#
# Copyright (c) 2020-2024 Open Technologies for Integration
# Licensed under the MIT license (see LICENSE for details)
#

echo "Pulling in secrets"

set +x

export TEMPLATE_POLICYXML=/home/aceuser/ace-server/run/DefaultPolicies/MQoC.policyxml

echo "policy ${TEMPLATE_POLICYXML} before"
cat ${TEMPLATE_POLICYXML}
sed -i "s|<queueManagerHostname>.*</queueManagerHostname>|<queueManagerHostname>`cat /run/secrets/mq/hostName`</queueManagerHostname>|g" ${TEMPLATE_POLICYXML}
sed -i "s|<listenerPortNumber>.*</listenerPortNumber>|<listenerPortNumber>`cat /run/secrets/mq/portNumber`</listenerPortNumber>|g" ${TEMPLATE_POLICYXML}

echo "policy ${TEMPLATE_POLICYXML} after"
cat ${TEMPLATE_POLICYXML}

mqsisetdbparms -w /home/aceuser/ace-server -n mq::MQoC -u `cat /run/secrets/mq/USERID` -p `cat /run/secrets/mq/PASSWORD`

sed -i "s/#policyProject: 'DefaultPolicies'/policyProject: 'DefaultPolicies'/g" /home/aceuser/ace-server/server.conf.yaml
sed -i "s/#remoteDefaultQueueManager: ''/remoteDefaultQueueManager: '{DefaultPolicies}:MQoC'/g" /home/aceuser/ace-server/server.conf.yaml
# This only works because we have switched off TLS validation in mqclient.ini
sed -i "s/#mqKeyRepository: ''/mqKeyRepository: '/dev/null'/g" /home/aceuser/ace-server/server.conf.yaml
