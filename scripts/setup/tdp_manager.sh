#!/usr/bin/env bash

set -euo pipefail

# Setup submodules

setup_submodule_tdp_lib() {
  git_submodule_setup "tdp-lib" "master"
  local collection_path="$TDP_COLLECTION_PATH"
  local env_path=".env"

  for feature in "${FEATURES[@]}"; do
    case "$feature" in
    extras) collection_path="${collection_path}:${TDP_COLLECTION_EXTRAS_PATH}" ;;
    observability) collection_path="${collection_path}:${TDP_COLLECTION_OBSERVABILITY_PATH}" ;;
    esac
  done

  if [[ "$CLEAN" == "true" ]]; then
    echo "Remove ${env_path}"
    rm -rf "$env_path"
  fi
  if [[ -e "${env_path}" ]]; then
    echo "File ${env_path} exists, nothing to do"
    return 0
  fi
  cat <<EOF > "$env_path"
# common
export TDP_COLLECTION_PATH=${collection_path}
export TDP_RUN_DIRECTORY=.
export TDP_VARS=./tdp_vars

# tdp-lib
export TDP_DATABASE_DSN=${TDP_DATABASE_DSN}
EOF

  local backend_cors_origins
  declare -a backend_cors_origins

  for feature in "${FEATURES[@]}"; do
    case "$feature" in
    server) backend_cors_origins+=("\\\"http://localhost:8000\\\"") ;;
    ui)     backend_cors_origins+=("\\\"http://localhost:3000\\\"") ;;
    esac
  done

  # Generate a comma separated string
  backend_cors_origins_comma=$(join_arr , "${backend_cors_origins[@]}")

  for feature in "${FEATURES[@]}"; do
    case "$feature" in
    server) cat <<EOF >> "$env_path"

# tdp-server
export PROJECT_NAME=tdp-server
export BACKEND_CORS_ORIGINS="[${backend_cors_origins_comma}]"
export SERVER_NAME=localhost
export SERVER_HOST=http://localhost:8000
export OPENID_CONNECT_DISCOVERY_URL=http://localhost:8080/auth/realms/tdp_server/.well-known/openid-configuration
export OPENID_CLIENT_ID=tdp_server
export DATABASE_DSN=${TDP_DATABASE_DSN}
export DO_NOT_USE_IN_PRODUCTION_DISABLE_TOKEN_CHECK=True
EOF
    ;;
    esac
  done
  return 0
}

setup_submodule_tdp_server() {
  git_submodule_setup "tdp-server" "master"
}

setup_submodule_tdp_ui() {
  git_submodule_setup "tdp-ui" "master"

  local config_path="./tdp-ui/config.json"
  if [[ "$CLEAN" == "true" ]]; then
    echo "Remove ${config_path}"
    rm -rf "$config_path"
  fi
  if [[ -e "${config_path}" ]]; then
    echo "File ${config_path} exists, nothing to do"
    return 0
  fi
  cat <<EOF > "$config_path"
{
  "apiBasePath": "http://localhost:8000",
  "skipAuth": true
}
EOF
}

# Init tdp-manager

init_tdp_lib() {
  echo "hi"
  local tdp_vars="./tdp_vars"
  local tdp_lib_cli_args=(init)
  echo "hi '${tdp_lib_cli_args}'"
  if [[ "$CLEAN" == "true" ]]; then
    echo "Remove '${tdp_vars}' and '${SQLITE_DB_PATH}'"
    rm -rf "$tdp_vars" "$SQLITE_DB_PATH"
  fi
  if [[ -n "$TDP_VARS_OVERRIDES" ]]; then
    tdp_lib_cli_args+=(--overrides "$TDP_VARS_OVERRIDES")
    echo "hi '${tdp_lib_cli_args}'"
  fi
  echo "tdp-lib init"
  (
    source "${PYTHON_VENV}/bin/activate"
    tdp "${tdp_lib_cli_args[@]}"
  )
  return 0
}

init_tdp_server() {
  echo "tdp-server init"
  (
    source "${PYTHON_VENV}/bin/activate"
    python tdp-server/tdp_server/initialize_database.py
    python tdp-server/tdp_server/initialize_tdp_vars.py
  )
  return 0
}

init_tdp_ui() {
  echo "tdp-ui init"
  "${NPM_BIN}" install ./tdp-ui
  echo "Generate the API client SDK"
  "${NPM_BIN}" --prefix ./tdp-ui run generate
  return 0
}
