#!/usr/bin/env bash

set -euo pipefail

setup_submodule_tdp() {
  local submodule_path="$TDP_COLLECTION_PATH"
  git_submodule_setup "$submodule_path" "master"

  # Quick fix for file lookup related to the Hadoop role refactor (https://github.com/TOSIT-IO/tdp-collection/pull/57)
  create_symlink_if_needed "../../../../files" "${submodule_path}/playbooks/files"
  create_symlink_if_needed "../../${submodule_path}/topology.ini" "inventory/topologies/01_tdp"
}

setup_submodule_extras() {
  local submodule_path="$TDP_COLLECTION_EXTRAS_PATH"
  git_submodule_setup "$submodule_path" "master"

  # Quick fix for file lookup related to the Hadoop role refactor (https://github.com/TOSIT-IO/tdp-collection/pull/57)
  create_symlink_if_needed "../../../../files" "${submodule_path}/playbooks/files"
  create_symlink_if_needed "../../${submodule_path}/topology.ini" "inventory/topologies/extras"
}

setup_submodule_observability() {
  local submodule_path="$TDP_COLLECTION_OBSERVABILITY_PATH"
  git_submodule_setup "$submodule_path" "main"

  # Quick fix for file lookup related to the Hadoop role refactor (https://github.com/TOSIT-IO/tdp-collection/pull/57)
  create_symlink_if_needed "../../../../files" "${submodule_path}/playbooks/files"
  create_symlink_if_needed "../../${submodule_path}/topology.ini" "inventory/topologies/observability"
}
