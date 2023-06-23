#!/usr/bin/env bash

set -euo pipefail

setup_submodule_prerequisites() {
  local submodule_path="ansible_collections/tosit/tdp_prerequisites"
  git_submodule_setup "$submodule_path" "master"
  create_symlink_if_needed "../../${submodule_path}/topology.ini" "inventory/topologies/prerequisites"
}

setup_submodule_vagrant() {
  git_submodule_setup "tdp-vagrant" "master"
  create_symlink_if_needed "tdp-vagrant/Vagrantfile" "Vagrantfile"
  create_symlink_if_needed "../.vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory" "inventory/hosts.ini"
}
