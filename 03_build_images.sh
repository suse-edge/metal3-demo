#!/usr/bin/env bash
set -eux

PROJECT_DIR=$(dirname -- $(readlink -e -- ${BASH_SOURCE[0]}))
EXTRA_VARS_FILE=${EXTRA_VARS_FILE:-$PROJECT_DIR/extra_vars.yml}

if [[ "$(id -u)" -eq 0 ]]; then
  echo "Please run as a non-root user"
  exit 1
fi

# Run ansible configure host playbook
export ANSIBLE_ROLES_PATH=$PROJECT_DIR/roles
ANSIBLE_FORCE_COLOR=true ansible-playbook \
  -i ${PROJECT_DIR}/inventories/localhost_inventory.yml \
  -e "@${EXTRA_VARS_FILE}" \
  $PROJECT_DIR/playbooks/build_images.yml $@
