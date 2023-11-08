#!/bin/bash

# Run the playbook with the verbose flag
ansible-playbook ~/metal3-demo/scripts/playbooks/m3-playbook.yaml -v

cd ~/metal3-demo; ./setup_metal3_network_infra.sh -vvv 

cd ~/metal3-demo; ./setup_metal3_core.sh -vvv
