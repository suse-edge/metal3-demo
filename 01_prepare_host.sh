#!/usr/bin/env bash
set -eux

PROJECT_DIR=$(dirname -- $(readlink -e -- ${BASH_SOURCE[0]}))

if [[ "$(id -u)" -eq 0 ]]; then
  echo "Please run as a non-root user"
  exit 1
fi

# Check OS type and version
source /etc/os-release
export DISTRO="${ID}${VERSION_ID%.*}"
# Tumbleweed is rolling, exclude the version as it is a date string
if [[ "$ID" = "opensuse-tumbleweed" ]]; then
  DISTRO="$ID"
fi
export OS="${ID}"
export OS_VERSION_ID="${VERSION_ID}"
export SUPPORTED_DISTROS=(ubuntu22 opensuse-leap15 opensuse-leap16 opensuse-tumbleweed*)

if [[ ! "${SUPPORTED_DISTROS[*]}" =~ ${DISTRO} ]]; then
  echo "Supported OS distros for the host are: ${SUPPORTED_DISTROS[*]}"
  exit 1
fi


if [[ "${OS}" = "ubuntu" ]]; then
  # Set apt retry limit to higher than default to
  # make the data retrival more reliable
  sudo sh -c ' echo "Acquire::Retries \"10\";" > /etc/apt/apt.conf.d/80-retries '
  sudo DEBIAN_FRONTEND=noninteractive apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get -y install python3-pip python3-dev jq curl wget pkg-config bash-completion

  # Set update-alternatives to python3
  if [[ "${DISTRO}" = "ubuntu22" ]]; then
    sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1
  fi
  sudo python -m pip install ansible
elif [[ "${OS}" = "opensuse-tumbleweed" ]] || [[ "${DISTRO}" = "opensuse-leap16" ]]; then
  sudo zypper -n update
  sudo zypper -n install python313 python313-pip jq curl wget pkg-config bash-completion ansible
elif [[ "${DISTRO}" = "opensuse-leap15" ]]; then
  sudo zypper -n update
  sudo zypper -n install python311 python311-pip jq curl wget pkg-config bash-completion
  sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1
  sudo python -m pip install ansible
fi


# Install requirements
ansible-galaxy install -r requirements.yml

# Run ansible prepare host playbook
export ANSIBLE_ROLES_PATH=$PROJECT_DIR/roles
ANSIBLE_FORCE_COLOR=true ansible-playbook \
  -i ${PROJECT_DIR}/inventories/localhost_inventory.yml \
  $PROJECT_DIR/playbooks/prepare_host.yml $@

# Ensure we have an SSH key, used for access to VMs
if [ ! -f ~/.ssh/id_ed25519 ]; then
  ssh-keygen -t ed25519 -C "m3-demo" -f ~/.ssh/id_ed25519 -N ""
fi
