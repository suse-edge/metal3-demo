# Intro 

## RKE2 Workload Cluster Deployment on Metal<sup>3</sup>

This is a step by step guide on deploying RKE2 workload clusters on the SUSE Metal<sup>3</sup> Demo environment

### Pre-requisites
- A fully functioning Metal<sup>3</sup> deployment
- At least 2 virtual bare metal hosts

## Deploying the Workload Cluster

1. Get the mac address of whichever VBMH will act as the control plane
- Sample command: ```virsh dumpxml node-1 | grep mac```


2. Create an XML file containing this:
```
<host mac='YOUR-MAC-ADDRESS' ip='192.168.124.200'/>
```

3. Perform a live update to the provisioning network to give a static IP to the VBMH
```
virsh net-update provisioning add-last ip-dhcp-host YOUR-FILE.xml --live
```

4. Create an XML file containing the following
```
<host ip='192.168.124.100'>
  <hostname>media.suse.baremetal</hostname>
</host>
```

5. Live update the provisioning network once again
```
virsh net-update provisioning add-last dns-host YOUR-FILE.xml --live
```

6. Make sure the following line in its entirety exists with `/etc/hosts`
```
192.168.124.99 boot.ironic.suse.baremetal api.ironic.suse.baremetal inspector.ironic.suse.baremetal media.suse.baremetal
```
- If you followed the VBMC script, the only thing missing from that line will be `media.suse.baremetal`


7. Inside of the Metal3-core vm, download the following file:
```
curl https://raw.githubusercontent.com/dbw7/m3-one-click-demo/main/example-manifests/combined-rke2-deploy.yaml > rke2.yaml
```

8. Update the node1.yaml label to be `control-plane` instead of `worker`. This file exists in the home directory of the Metal3-core vm

9. Delete and recreate the node (In theory updating it should work but ran into issues so this is the best way to avoid them)
```
kubectl delete bmh bmc-1
kubectl apply -f node1.yaml
```

10. Deploy the cluster
```
kubectl apply -f rke2.yaml
```

11. Verify that it's working
```
clusterctl describe cluster sample-cluster
```