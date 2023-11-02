## This directory contains the scripts for the automated deployment of Metal3 and virtual bare metal hosts.

## These scripts are specific to fresh Equinix Ubuntu 22.04 LTS servers. They might fail with other network and / or resource configurations.
- m3.small.x86 is the weakest configuration that will support the Metal3 deployment, though it is not recommended if deploying virtual bare metal hosts.
- c2.medium.x86 will support a Metal3 deployment with several virtual bare metal hosts.

### The quickest setup for Metal3 is to deploy an Equinix server with the previously mentioned configurations, then run the following commands below which will automate the entire deployment.

## Prerequisite Setup
```
cd ~; git clone https://github.com/suse-edge/metal3-demo.git
cd ~/metal3-demo/scripts/bash-scripts/
```

## Deploy Metal3 Infrastructure
To deploy Metal3, run:
```
./deploy_m3.sh
```

## Provision Virtual Bare Metal Hosts
```
./provision_virtual_bmh.sh
```