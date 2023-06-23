#!/usr/bin/env bash

set -euo pipefail

# Variable declarations

readonly AVAILABLE_FEATURES=(extras prerequisites vagrant server ui observability)
readonly PYTHON_BIN=${PYTHON_BIN:-python3}
readonly PYTHON_VENV=${PYTHON_VENV:-venv}
readonly NPM_BIN=${NPM_BIN:-npm}
readonly SQLITE_DB_PATH=${SQLITE_DB_PATH:-sqlite.db}
readonly TDP_DATABASE_DSN=${TDP_DATABASE_DSN:-sqlite:///$SQLITE_DB_PATH}
if [[ -z "${TDP_VARS_OVERRIDES+x}" ]]; then
  readonly TDP_VARS_OVERRIDES="tdp_vars_overrides"
else
  readonly TDP_VARS_OVERRIDES
fi
