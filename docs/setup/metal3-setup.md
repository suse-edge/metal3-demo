# Intro 

## Metal<sup>3</sup>

Metal<sup>3</sup> (Metal-Kubed) is an open source tool that provides components for bare metal host management utilizing the Kubernetes native API. (see https://metal3.io/)

### Pre-requisite Dependencies
<details>
  <summary>Click Here for list of Ubuntu Dependencies (22.04 LTS)</summary>
  <br>

  Make sure your packages are up to date
  ```
  sudo apt-get update -y
  sudo apt-get dist-upgrade -y
  ```
  To avoid kernal upgrade messages, pass the `DEBIAN_FRONTEND=noninteractive` flag like so:
  ```
  sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
  sudo DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y
  ```
  Otherwise, just press enter when it asks about the kernal updates.
  
  Dependencies: <br>
  Make sure to have python3-pip installed first:
  ```
  sudo apt install python3-pip -y
  ```
  ```
  python3 -m pip install ansible
  sudo apt install libvirt-clients -y
  sudo apt install qemu-kvm -y
  sudo apt install libvirt-daemon-system -y
  sudo apt install pkg-config -y
  sudo apt install libvirt-dev -y
  sudo apt install mkisofs -y
  sudo apt install qemu -y
  sudo apt install virtinst -y
  sudo apt install qemu-efi -y
  sudo apt install sshpass -y
  pip3 install libvirt-python
  ```
  </details>


## Deploying the SUSE Edge Metal<sup>3</sup> Demo
1. Begin by cloning the SUSE Edge M3 Demo repo 
```
git clone https://github.com/suse-edge/metal3-demo.git
```
2. Copy the extra_vars.yml.example to extra_vars.yml
```
cp extra_vars.yml.example extra_vars.yml
```

3. Follow the instructions within extra_vars.yml to configure it according to your needs. If you would like a pre-configured file, skip to step 4, otherwise, skip to step 6. 
- Important note: There are hardcoded memory and cpu configurations within `playbooks/setup_metal3_core.yaml` and `roles/vm/defaults/main.yaml` that are fairly intensive. You can decrease these resources to fit your environment, but do note that if the resources are too little, you may run into unexpected issues.
- The lowest resource configuration that is confirmed to work is: 6 VCPUs and 16000 vm_memory in `playbooks/setup_metal3_core.yaml` and 8000 vm_memory in `roles/vm/defaults/main.yaml`.

4. Show Pre-configured extra_vars.yml.
<details>
  <summary>Click here for a pre-configured extra_vars.yml file</summary>

```yaml
##
# Whether to deploy sylva-core
#
deploy_sylva_core: false
sylva_core_repo_url: https://gitlab.com/codefol/sylva-core.git
sylva_core_branch: metal3_existing_rancher
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
 - YOUR SSH KEY HERE 
 
rke2_channel_version: v1.24

dns_domain: suse.baremetal


metal3_provisioning_nic: &metal3_provisioning_nic eth1


# metal3_vm_libvirt_network_params: '--network bridge=virbr0,model=virtio --network bridge=br-eth3,model=virtio'
metal3_vm_libvirt_network_params: '--network bridge=m3-egress,model=virtio --network bridge=m3-prov,model=virtio'

#vm_memory: 16384


metal3_network_infra_provisioning_ip: 192.168.124.100
vm_prov_gw: 192.168.124.1
vm_prov_net: 192.168.124.0/24


metal3_network_infra_public_ip: 192.168.125.100
vm_egress_gw: 192.168.125.1


enable_dhcp: true


dhcp_router: 192.168.124.1
dhcp_range: 192.168.124.150,192.168.124.180


dns_provider: pdns
pdns_ip: "{{ metal3_network_infra_provisioning_ip }}"
pdns_api_port: 8081
pdns_web_password: IveG0tDaPower8
pdns_api_key: IveG0tDaPower8


metal3_network_infra_vm_network:
  version: 2
  ethernets:
    eth0:
      dhcp4: false
      addresses: ["{{ metal3_network_infra_public_ip }}/24"]
      nameservers:
        addresses: [8.8.8.8]
        search:
          - "{{ dns_domain }}"
      routes:
        - to: default
          via: "{{ vm_egress_gw }}"
    *metal3_provisioning_nic:
      dhcp4: false
      addresses: ["{{ metal3_network_infra_provisioning_ip }}/24"]
      nameservers:
        addresses: [8.8.8.8]
        search:
          - "{{ dns_domain }}"
      routes:
        - to: "{{ vm_prov_net }}"
          via: "{{ vm_prov_gw }}"


metal3_core_provisioning_ip: 192.168.124.99

#
# Public IP
#
metal3_core_public_ip: 192.168.125.99


metal3_core_vm_network:
  version: 2
  ethernets:
    eth0:
      dhcp4: false
      addresses: ["{{ metal3_core_public_ip }}/24"]
      nameservers:
        addresses: "{{ metal3_network_infra_provisioning_ip }}"
        search:
          - "{{ dns_domain }}"
      routes:
        - to: default
          via: "{{ vm_egress_gw }}"
    *metal3_provisioning_nic:
      dhcp4: false
      addresses: ["{{ metal3_core_provisioning_ip }}/24"]
      nameservers:
        addresses: "{{ metal3_network_infra_provisioning_ip }}"
        search:
          - "{{ dns_domain }}"
      routes:
        - to: "{{ vm_prov_net }}"
          via: "{{ vm_prov_gw }}"


# Storage setup on the Metal3 Core VM
storage:
  class_name: dynamic
  access_mode: ReadWriteMany
  nfs:
    create: true
    path: "/nfs/share"

```
</details>
<br>

5. Define virsh egress and provisioning networks (This configuration is specific to step 4)
   - CD into the libvirt directory within the metal3-demo that was cloned earlier 
   - Define and start the networks
   ```
   virsh net-define egress.xml; virsh net-start egress
   virsh net-define provisioning.xml; virsh net-start provisioning
   ```
   - If you plan not to use the virsh networks, you will need to set up your own network bridges.

6. Install the ansible-galaxy requirements
   - CD into the metal3-demo directory and install ansible requirements
   ```
   ansible-galaxy collection install -r requirements.yml
   ```
   
7. Create the Network Infra VM
  - In the main directory of the repository, execute the script to create the network-infra VM
  ```
  ./setup_metal3_network_infra.sh
  ```
  - You may pass `-vvv` at the end of the script to see the output of the script
  - The network-infra script must have completed without any errors before creating the core VM in step 8
  
8. Create the core VM
  ```
  ./setup_metal3_core.sh
  ```
  - You may pass `-vvv` at the end of the script to see the output

9. Assuming you are using the networks defined in the `libvirt` directory, you can ssh into each of the VMs using the IPs below
  - Core VM Running Metal3: `ssh metal@192.168.125.99` or `virsh console metal3-core`
  - Network Infra VM Running with public internet access: `ssh metal@192.168.125.100` or `virsh console metal3-network-infra`
