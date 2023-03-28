# Modify provisioning image and set root password. Login using root\PASSWORD

```shell
metal@metal3:~$ sudo apt-get install libguestfs-tools

metal@metal3: ~$ sudo virt-customize -a <image-name> --root-password password:PASSWORD
```

# Registration Error 

## Error: IPMI call failed: power status.

- Check if the credentials for connecting to bmc is correct

$ ipmitool -H $ilo_ip -I lanplus -U $ilo_user -P $ilo_pwd chassis power status

```shell
metal@metal3:~$ ipmitool -H 192.168.8.53 -I lanplus -U SCALE -P uj2bTkX chassis power status
Error: Unable to establish IPMI v2 / RMCP+ session

metal@metal3:~$ ipmitool -H 192.168.8.53 -I lanplus -U SCALE -P uj2bTkXV chassis power status
Chassis Power is on
```

# Provisioning Error

## Got HTTP code 404 instead of 200 in response to HEAD request.

- Check if the image server to pull the image is accessible from the metal3 VM
- Copy the image to the ironic container and fix the image url in yaml

```shell
metal@metal3:~$ kubectl cp <image_name> capm3-ironic-75db6cbd85-dsqkl:/shared/html/images -n capm3-system -c ironic

Update the image url in yaml
url: http://boot.ironic.suse.baremetal/images/<image_name>
```
