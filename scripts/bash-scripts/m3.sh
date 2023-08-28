#!/bin/bash

# Update package lists
sudo DEBIAN_FRONTEND=noninteractive apt-get update -y

# Full upgrade
sudo DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y

# Install install pip3
sudo DEBIAN_FRONTEND=noninteractive apt install python3-pip -y

#We install ansible
python3 -m pip install ansible

#We set the path in bashrc and source it in case it's incorrect
if ! grep -q 'export PATH="/root/.local/bin:$PATH"' ~/.bashrc ; then
    echo 'export PATH="/root/.local/bin:$PATH"' >> ~/.bashrc
fi

# Source bashrc to load new PATH
source ~/.bashrc

#create ansible directory in the home directory if it doesn't exist
if [ ! -d ~/ansible ]; then
  mkdir -p ~/ansible;
fi

#put the equinix playbook in the ansible folder
curl https://raw.githubusercontent.com/dbw7/m3-one-click-demo/main/main-without-sylva/equinix-playbook-main.yaml > ~/ansible/equinix-playbook.yaml

#put the extra vars file in the ansible directory temporarily
curl https://raw.githubusercontent.com/dbw7/m3-one-click-demo/main/main-without-sylva/extra_vars_main.yml > ~/ansible/extra_vars.yml

#generate ssh key to use to log into the metal-cubed servers
ssh-keygen -t ed25519 -C "m3-equinix-server" -f ~/.ssh/id_rsa -N ""

#take that key and put it in extra_vars.yml
PUBLIC_KEY_FILE="$HOME/.ssh/id_rsa.pub"
PUBLIC_KEY=$(cat "$PUBLIC_KEY_FILE")

SEARCH_STRING="-YOU CAN REPLACE THIS BUT THE SCRIPT WILL CHANGE THIS AUTOMATICALLY"
REPLACE_STRING="- $PUBLIC_KEY"

perl -i -pe "s|$SEARCH_STRING|$REPLACE_STRING|" ~/ansible/extra_vars.yml


#Run the playbook with the verbose flag
ansible-playbook ~/ansible/equinix-playbook.yaml -v

cd ~/m3-demo-parent/metal3-demo/; ./setup_metal3_network_infra.sh -vvv

cd ~/m3-demo-parent/metal3-demo/; ./setup_metal3_core.sh -vvv