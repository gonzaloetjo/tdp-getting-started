#!/usr/bin/env bash

set -euo pipefail

# source scripts/setup/variables.sh
source scripts/setup/functions.sh
source scripts/setup/tdp_demo.sh
source scripts/setup/tdp_submodules.sh
source scripts/setup/tdp_manager.sh
source scripts/setup/python_env.sh


dev_galaxy() {
  namespace="tdp"
  readonly TDP_COLLECTION_PATH="ansible_collections/${namespace}/core"
  readonly TDP_COLLECTION_EXTRAS_PATH="ansible_collections/${namespace}/extras"
  readonly TDP_COLLECTION_OBSERVABILITY_PATH="ansible_collections/${namespace}/observability"
  readonly TDP_COLLECTION_PREREQUISITES_PATH="ansible_collections/${namespace}/prerequisites"  

  # Setup prerequisites
  # validate_features
  create_directories

  # Install collections
  install_ansible_collection "${namespace}.core" "0.0.1" "https://github.com/gonzaloetjo/tdp-collection.git" "master" "."
  for feature in "${FEATURES[@]}"; do
    case "$feature" in
      extras)
        install_ansible_collection "${namespace}.extras" "0.0.1" "https://github.com/gonzaloetjo/tdp-collection-extras" "master" "."
        ;;
      observability)
        install_ansible_collection "${namespace}.observability" "0.0.1" "https://github.com/gonzaloetjo/tdp-collection-observability" "main" "."
        ;;
      prerequisites)
        install_ansible_collection "${namespace}.prerequisites" "0.0.1" "https://github.com/gonzaloetjo/tdp-collection-prerequisites" "master" "."
        ;;
      *)
        ;;
    esac
  done


  create_symlinks_for_feature "core"
  # Create symlinks
  for feature in "${FEATURES[@]}"; do
    create_symlinks_for_feature "$feature"
  done

  # Setup submodules
  setup_submodule_tdp_lib
  for feature in "${FEATURES[@]}"; do
    case "$feature" in
    vagrant)       setup_submodule_vagrant ;;
    server)        setup_submodule_tdp_server ;;
    ui)            setup_submodule_tdp_ui ;;
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

