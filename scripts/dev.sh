#!/usr/bin/env bash

set -euo pipefail

source scripts/setup/variables.sh
source scripts/setup/functions.sh
source scripts/setup/tdp_demo.sh
source scripts/setup/tdp_submodules.sh
source scripts/setup/tdp_manager.sh
source scripts/setup/python_env.sh


# CLEAN="false"
# declare -a FEATURES
# HELP="false"
# RELEASE=stable

dev_main() {
  readonly TDP_COLLECTION_PATH="ansible_collections/${namespace}/tdp"
  readonly TDP_COLLECTION_EXTRAS_PATH="ansible_collections/${namespace}/tdp_extra"
  readonly TDP_COLLECTION_OBSERVABILITY_PATH="ansible_collections/${namespace}/tdp_observability"
  # Setup prerequisites
  # validate_features
  create_directories

  # Setup submodules
  setup_submodule_tdp
  setup_submodule_tdp_lib

  # Setup optional submodules
  for feature in "${FEATURES[@]}"; do
    case "$feature" in
    extras)        setup_submodule_extras ;;
    prerequisites) setup_submodule_prerequisites ;;
    vagrant)       setup_submodule_vagrant ;;
    server)        setup_submodule_tdp_server ;;
    ui)            setup_submodule_tdp_ui ;;
    observability) setup_submodule_observability ;;
    esac
  done

  # Setup virtual environment
  setup_python_venv

  # Init tdp manager
  init_tdp_lib

  # Init optional tdp manager components
  for feature in "${FEATURES[@]}"; do
    case "$feature" in
    server) init_tdp_server ;;
    ui)     init_tdp_ui ;;
    esac
  done

  # Download Binaries
  download_tdp_binaries
}


