# Intro 

## RKE2 Workload Cluster Deployment on Metal<sup>3</sup>

This is a step by step guide on deploying RKE2 workload clusters on the SUSE Metal<sup>3</sup> Demo environment

### Pre-requisites
- A fully functioning Metal<sup>3</sup> deployment
- At least 2 virtual bare metal hosts

## Deploying the Workload Cluster
- For simplicity, we will continue working in the `vbmc` directory created in the [VBMH Readme](./vbmh-setup.md).
```
cd ~/vbmc
```

1. Get the mac address of the VBMH that will act as the control plane and save it as a variable
``` 
CONTROLPLANEMAC=$(sudo virsh dumpxml node-1 | grep 'mac address' | grep -ioE "([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}")
```


2. Create an XML file with the following information:
```
cat << EOF > ~/vbmc/host.xml
<host mac='$CONTROLPLANEMAC' ip='192.168.124.200'/>
EOF
```

3. Perform a live update to the provisioning network to give a static IP to the VBMH
```
virsh net-update provisioning add-last ip-dhcp-host host.xml --live
```

4. Create an XML file containing the following
```
cat << EOF > ~/vbmc/dns.xml
<host ip='192.168.124.100'>
  <hostname>media.suse.baremetal</hostname>
</host>
EOF
```

5. Live update the provisioning network once again
```
virsh net-update provisioning add-last dns-host dns.xml --live
```

6. Inside of the Metal3-core vm, download the following file:
```
curl https://raw.githubusercontent.com/dbw7/m3-one-click-demo/main/example-manifests/combined-rke2-deploy.yaml > rke2.yaml
```


7. Deploy the cluster
```
kubectl apply -f rke2.yaml
```
- If you followed the [Metal3 Setup Readme](./metal3-setup.md) and [VBMH Readme](./vbmh-setup.md) exactly, you will not need to change anything. However, if you have differences in your setup, you may need to make changes to the RKE2 manifest.

8. Verify that it's working
```
clusterctl describe cluster sample-cluster
```