#!/usr/bin/env bash

setup_python_venv() {
  if [[ ! -d "$PYTHON_VENV" ]]; then
    echo "Create python venv with '${PYTHON_BIN}' to '${PYTHON_VENV}' and update pip to latest version"
    "$PYTHON_BIN" -m venv "$PYTHON_VENV"
    (
      source "${PYTHON_VENV}/bin/activate"
      pip install -U pip
    )
  else
    echo "Python venv '${PYTHON_VENV}' already exists, nothing to do"
  fi
  echo "Install python dependencies"
  (
    source "${PYTHON_VENV}/bin/activate"
    pip install -r requirements.txt
    for feature in "${FEATURES[@]}"; do
      case "$feature" in
      # tdp-server must be installed before tdp-lib
      # with tdp-lib installed after, it will override the tdp-lib installed by tdp-server
      server) pip install --editable tdp-server uvicorn==0.16.0 ;;
      esac
    done
    pip install --editable tdp-lib[visualization]
  )
  return 0
}

