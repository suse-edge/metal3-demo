# This directory contains the scripts for the automated deployment of Metal3 as well as virtual bare metal hosts.

## This scripts are specific to fresh Equinix Ubuntu 22.04LTS servers. The scripts will fail with other network or resource configurations.
- m3.small.x86 is the weakest configuration that will support the Metal3 deploy, but not recommended if deploying virtual bare metal hosts.
- c2.medium.x86 will support a Metal3 deploy with several virtual bare metal hosts.

### The quickest setup for Metal3 is to deploy an Equinix server with the previously mentioned configurations, then run one of the following commands below which will automate the entire process.


1. This script deploys Metal3 without Sylva enabled
```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/dbw7/m3-one-click-demo/main/main-without-sylva/script-main.sh)"
```

2. This script creates 3 virtual bare metal hosts and then provisions them.
```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/dbw7/m3-one-click-demo/main/vbmc/vm_noimg.sh)"
```