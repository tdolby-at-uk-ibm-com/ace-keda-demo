#!/bin/bash
#
# Copyright (c) 2020 Open Technologies for Integration
# Licensed under the MIT license (see LICENSE for details)
#

echo "Pulling in secrets"

set +x

mkdir /home/aceuser/ace-server/run/DefaultPolicies
echo '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><ns2:policyProjectDescriptor xmlns="http://com.ibm.etools.mft.descriptor.base" xmlns:ns2="http://com.ibm.etools.mft.descriptor.policyProject"><references/></ns2:policyProjectDescriptor>' > /home/aceuser/ace-server/run/DefaultPolicies/policy.descriptor

export TEMPLATE_POLICYXML=/tmp/MQoC.policyxml

if [[ -e "/home/aceuser/ace-server/MQoC.policyxml" ]]
then
    # Maven s2i
    export TEMPLATE_POLICYXML=/home/aceuser/ace-server/MQoC.policyxml
fi

echo "policy ${TEMPLATE_POLICYXML} before"
cat ${TEMPLATE_POLICYXML}
sed -i "s/HOSTNAME/`cat /run/secrets/mq/hostName`/g" ${TEMPLATE_POLICYXML}
sed -i "s/PORTNUMBER/`cat /run/secrets/mq/portNumber`/g" ${TEMPLATE_POLICYXML}

echo "policy ${TEMPLATE_POLICYXML} after"
cat ${TEMPLATE_POLICYXML}
cp ${TEMPLATE_POLICYXML} /home/aceuser/ace-server/run/DefaultPolicies/

mqsisetdbparms -w /home/aceuser/ace-server -n mq::MQoC -u `cat /run/secrets/mq/USERID` -p `cat /run/secrets/mq/PASSWORD`

sed -i "s/#policyProject: 'DefaultPolicies'/policyProject: 'DefaultPolicies'/g" /home/aceuser/ace-server/server.conf.yaml
