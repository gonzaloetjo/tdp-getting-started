#!/usr/bin/env bash

set -euo pipefail

install_collections_from_requirements() {
  local requirements_file="$1"
  ansible-galaxy collection install -r "$requirements_file"
}
