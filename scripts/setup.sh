#!/usr/bin/env bash

set -euo pipefail

# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

source scripts/setup/functions.sh
source scripts/dev.sh
source scripts/galaxy.sh



CLEAN="false"
declare -a FEATURES
HELP="false"
RELEASE=stable
REQUIREMENTS_FILE="../../requirements.yml"
DEV_MODE="false"


main() {
  parse_cmdline "$@" || { print_help; exit 1; }
  [[ "$HELP" == "true" ]] && { print_help; exit 0; }
  validate_features
  
  if [[ "$DEV_MODE" == "true" ]]; then
    # Call tdp_submodule.sh script, passing all remaining arguments
    namespace="tosit"
    dev_main "$@"
  else
    # Call tdp_galaxy.sh script, passing all remaining arguments
    namespace="tdp"
    dev_galaxy "$*"
  fi
}

main "$@"
# ... (remaining content)
