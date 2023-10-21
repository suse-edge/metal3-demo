# Intro

## Metal<sup>3</sup>

Metal<sup>3</sup> (Metal-Kubed) is an open source tool that provides components for bare metal host management utilizing
the Kubernetes native API. (see https://metal3.io/)

### Pre-requisite Dependencies

Currently requires an Ubuntu (22.04 LTS) host to enable testing on Equinix.

1. Create a non-root user with sudo access

If one does not already exist e.g:

```
sudo useradd auser -m -s /bin/bash
sudo echo "auser ALL=NOPASSWD: ALL" > /etc/sudoers.d/auser
sudo su - auser
```

2. Clone this metal3-demo repo

```shell
git clone https://github.com/suse-edge/metal3-demo.git
```

3. Install pre-requisite packages

```shell
cd metal3-demo
./01_prepare_host.sh
```

## Deploying the SUSE Edge Metal<sup>3</sup> Demo

1. Copy the pre-configured_extra_vars.yml to extra_vars.yml

```shell
cp scripts/required-files/pre-configured_extra_vars.yml extra_vars.yml
```

2. Follow the instructions within extra_vars.yml to configure it according to your needs. If you would like a
   pre-configured file, skip to step 4, otherwise, skip to step 6.

- Important note: There are hardcoded memory and cpu configurations within `playbooks/setup_metal3_core.yaml`
  and `roles/vm/defaults/main.yaml` that are fairly intensive. You can decrease these resources to fit your environment,
  but do note that if the resources are too little, you may run into unexpected issues.
- The lowest resource configuration that is confirmed to work is: 6 VCPUs and 16000 vm_memory
  in `playbooks/setup_metal3_core.yaml` and 8000 vm_memory in `roles/vm/defaults/main.yaml`.

3. Show Pre-configured extra_vars.yml.

<details>
  <summary>Click here for a pre-configured extra_vars.yml file</summary>

```yaml
baremetal_repo_url: https://github.com/suse-edge/charts.git
baremetal_branch: main

# VM user name
vm_user: metal

# VM user plain text password (not hash)
vm_user_plain_text_password: metal

# NOTE: this should be *your* (local user) SSH public key since *you*
# will be using it to login to the VMs. The SSH public keys listed
# here will be appended to the VM user's authorized_keys file.
#
vm_authorized_ssh_keys:
 -YOU CAN REPLACE THIS BUT THE SCRIPT WILL CHANGE THIS AUTOMATICALLY 

# OS image
opensuse_leap_image_url: https://download.opensuse.org/repositories/Cloud:/Images:/Leap_15.5/images/openSUSE-Leap-15.5.x86_64-NoCloud.qcow2
opensuse_leap_image_checksum: sha256:https://download.opensuse.org/repositories/Cloud:/Images:/Leap_15.5/images/openSUSE-Leap-15.5.x86_64-NoCloud.qcow2.sha256
opensuse_leap_image_name: openSUSE-Leap-15.5.x86_64-NoCloud.qcow2

rke2_channel_version: v1.24

metal3_vm_libvirt_network_params: '--network bridge=m3-egress,model=virtio'

metal3_network_infra_public_ip: 192.168.125.100
vm_egress_gw: 192.168.125.1


enable_dhcp: true

dhcp_router: 192.168.124.1
dhcp_range: 192.168.124.150,192.168.124.180

metal3_network_infra_vm_network:
  version: 2
  ethernets:
    eth0:
      dhcp4: false
      addresses: ["{{ metal3_network_infra_public_ip }}/24"]
      nameservers:
        addresses: "{{ vm_egress_gw }}"
      routes:
        - to: default
          via: "{{ vm_egress_gw }}"

#
# Public IPs
#
metal3_core_public_ip: 192.168.125.99
metal3_core_ironic_ip: 192.168.125.10


metal3_core_vm_network:
  version: 2
  ethernets:
    eth0:
      dhcp4: false
      addresses: ["{{ metal3_core_public_ip }}/24"]
      nameservers:
        addresses: "{{ vm_egress_gw }}"
      routes:
        - to: default
          via: "{{ vm_egress_gw }}"
```

</details>
<br>

4. Define virsh egress network (This configuration is specific to step 4)
    - CD into the libvirt directory within the metal3-demo that was cloned earlier
    - Define and start the network
   ```shell
   virsh net-define egress.xml; virsh net-start egress
   ```
    - If you plan not to use the virsh networks, you will need to set up your own network bridges.

5. Install the ansible-galaxy requirements
    - CD into the metal3-demo directory and install ansible requirements
   ```shell
   ansible-galaxy collection install -r requirements.yml
   ```

6. Create the Network Infra VM

- In the main directory of the repository, execute the script to create the network-infra VM

  ```shell
  ./setup_metal3_network_infra.sh
  ```

- You may pass `-vvv` at the end of the script to see the output of the script
- The network-infra script must have completed without any errors before creating the core VM in step 8

7. Create the core VM

  ```shell
  ./setup_metal3_core.sh
  ```

- You may pass `-vvv` at the end of the script to see the output

8. Assuming you are using the networks defined in the `libvirt` directory,
   you can ssh into each of the VMs using the IPs below

- Core VM Running Metal3: `ssh metal@192.168.125.99` or `virsh console metal3-core`
- Network Infra VM Running with public internet access: `ssh metal@192.168.125.100` or `virsh console metal3-network-infra`
