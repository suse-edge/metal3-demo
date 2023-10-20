#!/bin/bash

set -e

USAGE="${0}: <dnsDomain>
Where:
  <dnsDomain>: DNS domain that all services will be members of
"

if [ $# -ne 1 ] ; then
        echo "$USAGE"
        exit 1
fi

DNSDOMAIN=$1

# Check Docker command executable exit code
docker images > /dev/null 2>&1; rc=$?;
if [[ $rc != 0 ]]; then
        exit 1
fi

# Get Ironic Version
GetIronicVer () {
       CONTNAME="tmp_$1"
       TARNAME=$CONTNAME
       pushd $(mktemp -d) > /dev/null 2>&1
       docker pull $2 > /dev/null 2>&1; rc=$?;
       if [[ $rc == 0 ]]; then
               docker create --name $CONTNAME $2 > /dev/null 2>&1; rc=$?;
               if [[ $rc == 0 ]]; then
                       docker export $CONTNAME -o "$CONTNAME.tar" > /dev/null 2>&1; rc=$?;
                       if [[ $rc == 0 ]]; then
                               tar -xf "$CONTNAME.tar"
                               VERSION=`ls usr/lib/python3.9/site-packages/ | grep ironic- | awk -F '-' '{print $2}'`
			       COMPONENT="ironic"
			       printf "|%-20s|%-45s|\n" $COMPONENT $VERSION
                       fi

               fi
       fi
       docker rm $CONTNAME > /dev/null 2>&1
       popd > /dev/null 2>&1
}	

# Get MariaDB version
GetMariadbVer () {
       CONTNAME="tmp_$1"
       docker pull $2 > /dev/null 2>&1; rc=$?;
       if [[ $rc == 0 ]]; then
	       docker run --name $CONTNAME -e MARIADB_ROOT_PASSWORD=Password123! -d $2 > /dev/null 2>&1; rc=$?;
               if [[ $rc == 0 ]]; then
		       mariadbVer=$(docker exec -it $CONTNAME mysql -V)
                       if [[ $rc == 0 ]]; then
			       VERSION=$(echo $mariadbVer | awk -F"," '{print $1}' | awk -F ' ' '{print $5}' | awk -F '-' '{print $1}')
			       COMPONENT="mariadb"
			       printf "|%-20s|%-45s|\n" $COMPONENT "$VERSION"
                       fi

               fi
       fi
       docker stop $CONTNAME > /dev/null 2>&1; rc=$?;
       if [[ $rc == 0 ]]; then
               docker rm $CONTNAME > /dev/null 2>&1
       fi	       
}	

# There is no automated way of getting the ironic-python-agent version so getting the ironic-lib version of initrams and use that to manually get the IPA version
GetIronicLibVer () {
       pushd $(mktemp -d) > /dev/null 2>&1
       IPAURL="http://boot.ironic.${DNSDOMAIN}/images/ironic-python-agent.initramfs"
       wget $IPAURL > /dev/null 2>&1; rc=$?;
       if [[ $rc == 0 ]]; then
               LIBVER=`lsinitramfs ironic-python-agent.initramfs | grep "ironic_lib" | grep dist-info$`
	       VERSION=$(echo $LIBVER | awk -F'/' '{print $6}' | awk -F '-' '{print $2}' | cut -d "." -f 1-3 )
       fi
       COMPONENT="IPA ironic-lib"
       printf "|%-20s|%-45s|\n" "$COMPONENT" "$VERSION"
       popd > /dev/null 2>&1
}

printf ' %67s\n' | tr ' ' _
printf "|Component           |Version                                      |\n" 
printf ' %67s\n' | tr ' ' -
HELMDIR=$HOME/charts
for component in `ls $HELMDIR`; do
	if [[ $component == "metal3-deploy" ]]; then
		continue
        fi		

	HELMIMGLST=`helm template ~/charts/$component | grep 'image:' | grep "image:" | awk -F" " '{print $2}' | sed 's/^"//g' | sed 's/\"//g' | sort | awk '!seen[$0]++'` 
	case "$component" in
		"ironic") 
			for IMAGE in $HELMIMGLST; do
				IMGTYP=$(echo $IMAGE | awk -F '/' '{print $3}')
				if [[ $IMGTYP == "ironic" ]]; then
					GetIronicVer $IMGTYP $IMAGE
			        fi		
				if [[ $IMGTYP == "mariadb" ]]; then
                                        GetMariadbVer $IMGTYP $IMAGE
			        fi		

			done	
                ;;
	        "media") 
			VERSION=$(echo $HELMIMGLST | grep nginx | awk -F ':' '{print $2}')
			COMPONENT="media"
			printf "|%-20s|%-45s|\n" $COMPONENT "$VERSION"
	        ;;		
	        "baremetal-operator") 
			VERSION=$(echo $HELMIMGLST | awk -F ' ' '{print $3}' | awk -F ':' '{print $2}')
			COMPONENT="baremetal-operator"
			printf "|%-20s|%-45s|\n" $COMPONENT "$VERSION"
	        ;;		
        esac	
done

# Get ironic-lib version of IPA initramfs
GetIronicLibVer

printf ' %67s\n' | tr ' ' -
