#!/bin/bash

yum install python-pip docker -y
pip install ansible docker
/usr/local/bin/ansible-playbook -i 'localhost,' -c local -v -e domain=$DOMAIN playbook.yml
chown -R ec2-user: clients_keys_*
