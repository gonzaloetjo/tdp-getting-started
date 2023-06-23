#!/usr/bin/env bash

set -euo pipefail

# Functions
print_help() {
  cat <<EOF
SYNOPSIS
  TDP getting started environment setup script.

DESCRIPTION
  Ensures the existence of directories and dependencies required for TDP deployment.
  If submodule are not present, they will be checkout. Use "-c" option to force submodule update.
  If needed symlink and "tdp_vars" are not present, they will be created. Use "-c" option to remove and re-create them.

USAGE
  setup.sh [-e feature1 -e ...] [-h] [-r latest|stable]

OPTIONS
  -c Run in clean mode (reset git submodule, symlink, tdp_vars, etc.)
  -e Enable feature, can be set multiple times (Available features: ${AVAILABLE_FEATURES[@]})
  -h Display help
  -r Specify the release for TDP deployment. Takes options latest and stable (the default).
EOF
}

parse_cmdline() {
  local OPTIND
  while getopts 'cde:hr:' options; do
    case "$options" in
    c) CLEAN="true" ;;
    d) DEV_MODE="true" ;;
    e) FEATURES+=("$OPTARG") ;;
    h) HELP="true" && return 0 ;;
    r) RELEASE="$OPTARG" ;;
    *) return 1 ;;
    esac
  done
  shift $((OPTIND - 1))
  return 0
}

validate_features() {
  local validate="true"
  for feature in "${FEATURES[@]}"; do
    local is_available="false"
    for available_feature in "${AVAILABLE_FEATURES[@]}"; do
      [[ "$feature" == "$available_feature" ]] && is_available="true"
    done
    if [[ "$is_available" == "false" ]]; then
      echo "Feature ${feature} does not exist"
      validate="false"
    fi
  done
  if [[ "$validate" == "true" ]]; then
    return 0
  else
    echo "Available features: ${AVAILABLE_FEATURES[@]}"
    return 1
  fi
}

# From https://stackoverflow.com/a/53839433
join_arr() {
  local IFS="$1"
  shift
  echo "$*"
}

create_directories() {
  mkdir -p logs files inventory/topologies ansible_collections/tdp/core ansible_collections/tdp/extras ansible_collections/tdp/observability
}

download_tdp_binaries() {
  wget --no-clobber --input-file="scripts/tdp-release-uris.txt" --directory-prefix="files"
}

git_submodule_setup() {
  local path=$1
  local status="$(git submodule status -- "$path")"
  if [[ "$status" != -* ]] && [[ "$CLEAN" == "false" ]]; then
    echo "Submodule '${path}' present, nothing to do"
    return 0
  fi
  git submodule update --init --recursive "$path"
  if [[ "$RELEASE" == "latest" ]]; then
    local commit="origin/$2"
    (
      cd "$path"
      git fetch --prune
      git checkout "$commit"
      echo "Submodule '${path}' checkout to '${commit}'"
    )
  fi
  return 0
}

create_symlink_if_needed() {
  local target=$1
  local link_name=$2
  if [[ "$CLEAN" == "true" ]]; then
    echo "Remove '${link_name}'"
    rm -rf "$link_name"
  fi
  if [[ -e "$link_name" ]] || [[ -L "$link_name" ]]; then
    echo "File '${link_name}' exists, nothing to do"
    return 0
  fi
  echo "Create symlink '${link_name}'"
  ln -s "$target" "$link_name"
}

# create_symlinks_for_feature() {
#   local feature="$1"
#   local collection_path="ansible_collections/tdp/${feature}"
#   local topology_name="${feature,,}"


#   create_symlink_if_needed "../../../../files" "${collection_path}/playbooks/files"
#   create_symlink_if_needed "../../${collection_path}/topology.ini" "inventory/topologies/${topology_name}"
# }

# create_symlinks_for_feature() {
#   local feature="$1"
#   local collection_path="ansible_collections/tdp/${feature}"
#   local topology_name="${feature,,}"

#   case "$feature" in
#     core|extras|observability|vagrant)
#       create_symlink_if_needed "../../../../files" "${collection_path}/playbooks/files"
#       create_symlink_if_needed "../../${collection_path}/topology.ini" "inventory/topologies/${topology_name}"
#       ;;
#     prerequisites)
#       create_symlink_if_needed "../../${collection_path}/topology.ini" "inventory/topologies/${topology_name}"
#       ;;
#     *)
#       ;;
#   esac
# }

create_symlinks_for_feature() {
  local feature="$1"
  local collection_path="ansible_collections/tdp/${feature}"
  local topology_name="${feature,,}"
  
  if [[ "$feature" == "prerequisites" ]]; then
    create_symlink_if_needed "../../${collection_path}/topology.ini" "inventory/topologies/${topology_name}"
  elif [[ "$feature" == "core" || "$feature" == "extras" || "$feature" == "observability" ]]; then
    create_symlink_if_needed "../../../../files" "${collection_path}/playbooks/files"
    create_symlink_if_needed "../../${collection_path}/topology.ini" "inventory/topologies/${topology_name}"
  fi
}

# install_ansible_collection() {
#   local collection_name="$1"
#   local collection_version="$2"
#   ansible-galaxy collection install "${collection_name}:${collection_version}"
# }


# install_ansible_collection() {
#   local collection_name="$1"
#   local collection_version="$2"
#   local git_repo="$3"
#   local git_ref="$4" # Optional: branch, commit, or tag
#   local collection_subdir="$5" # Optional: specify the collection location within the Git repository
#   local collections_path="${6:-./ansible_collections}"
#   export ANSIBLE_COLLECTIONS_PATHS="$collections_path"

#   if [ -z "$git_repo" ]; then
#     ansible-galaxy collection install "${collection_name}:${collection_version}" --force -vvv
#     echo "${collection_version}"
#   else
#     local install_src="git+${git_repo}"
#     if [ -n "$collection_subdir" ]; then
#       install_src="${install_src}#/${collection_subdir}"
#     fi
#     if [ -n "$git_ref" ]; then
#       install_src="${install_src},${git_ref}"
#     fi
#     echo "${install_src}"
#     ansible-galaxy collection install "${install_src}" --force -vvv
#   fi
# }

# install_ansible_collection() {
#   local collection_namespace="$1"
#   local collection_name="$2"
#   local collection_version="$3"
#   local git_repo="$4"
#   local git_ref="$5" # Optional: branch, commit, or tag
#   local collection_subdir="$6" # Optional: specify the collection location within the Git repository
#   local collections_path="${7:-./ansible_collections}"
#   local collection_install_path="${collections_path}/${collection_namespace}/${collection_name}"

#   if [ -z "$git_repo" ]; then
#     ansible-galaxy collection install "${collection_namespace}.${collection_name}:${collection_version}" --force -vvv
#   else
#     local install_src="git+${git_repo}.git,${git_ref}"
#     if [ -n "$collection_subdir" ]; then
#       install_src="${install_src}:${collection_subdir}"
#     fi
#     ansible-galaxy collection install "${install_src}" --force -vvv
#   fi
# }

# install_ansible_collection() {
#   local collection_namespace="$1"
#   local collection_name="$2"
#   local collection_version="${3:-}"
#   local git_repo="${4:-}"
#   local git_ref="${5:-}" # Optional: branch, commit, or tag
#   local collection_subdir="${6:-}" # Optional: specify the collection location within the Git repository
#   local collections_path="${7:-./ansible_collections}"
#   local collection_install_path="${collections_path}/${collection_namespace}/${collection_name}"

#   if [ -z "$git_repo" ]; then
#     ansible-galaxy collection install "${collection_namespace}.${collection_name}:${collection_version}" --force -vvv
#   else
#     local install_src="git+${git_repo}.git,${git_ref}"
#     if [ -n "$collection_subdir" ]; then
#       install_src="${install_src}:${collection_subdir}"
#     fi
#     ansible-galaxy collection install "${install_src}" --force -vvv
#   fi
# }

# install_ansible_collection() {
#   local collection_name="$1"
#   local collection_version="$2"
#   local git_repo="$3"
#   local git_ref="$4" # Optional: branch, commit, or tag
#   local collection_subdir="$5" # Optional: specify the collection location within the Git repository
#   local collections_path="${6:-./ansible_collections}"
#   export ANSIBLE_COLLECTIONS_PATHS="$collections_path"

#   if [ -z "$git_repo" ]; then
#     ansible-galaxy collection install "${collection_name}:${collection_version}" --force -vvv
#   else
#     local install_src="git+${git_repo}"
#     if [ -n "$collection_subdir" ]; then
#       install_src="${install_src}#/${collection_subdir}"
#     fi
#     if [ -n "$git_ref" ]; then
#       install_src="${install_src},${git_ref}"
#     fi
#     ansible-galaxy collection install "${install_src}" --force -vvv
#   fi
# }

# install_ansible_collection() {
#   local collection_name="$1"
#   local collection_version="$2"
#   local git_repo="$3"
#   local git_ref="$4" # Optional: branch, commit, or tag
#   local collection_subdir="$5" # Optional: specify the collection location within the Git repository
#   local collections_path="${6:-./ansible_collections}"
#   export ANSIBLE_COLLECTIONS_PATHS="$collections_path"

#   if [ -z "$git_repo" ]; then
#     ansible-galaxy collection install "${collection_name}:${collection_version}" --force -vvv
#   else
#     local install_src="git+${git_repo}"
#     if [ -n "$git_ref" ]; then
#       install_src="${install_src},${git_ref}"
#     fi
#     if [ -n "$collection_subdir" ]; then
#       install_src="${install_src}#/${collection_subdir}"
#     fi
#     ansible-galaxy collection install "${install_src}" --force -vvv
#   fi
# }


# install_ansible_collection() {
#   local collection_namespace="$1"
#   local collection_name="$2"
#   local collection_version="${3:-}"
#   local git_repo="${4:-}"
#   local git_ref="${5:-}" # Optional: branch, commit, or tag
#   local collection_subdir="${6:-}" # Optional: specify the collection location within the Git repository
#   local collections_path="${7:-./ansible_collections}"
#   local collection_install_path="${collections_path}/${collection_namespace}/${collection_name}"

#   if [ -z "$git_repo" ]; then
#     ansible-galaxy collection install "${collection_namespace}.${collection_name}:${collection_version}" --force -vvv
#   else
#     local install_src="git+${git_repo}.git,${git_ref}"
#     if [ -n "$collection_subdir" ]; then
#       install_src="${install_src},${collection_subdir}"
#     fi
#     ansible-galaxy collection install "${install_src}" --force -vvv
#   fi
# }

# install_ansible_collection() {
#   local collection_namespace="$1"
#   local collection_name="$2"
#   local collection_version="${3:-}"
#   local git_repo="${4:-}"
#   local git_ref="${5:-}" # Optional: branch, commit, or tag
#   local collection_subdir="${6:-}" # Optional: specify the collection location within the Git repository
#   local collections_path="${7:-./ansible_collections}"
#   local collection_install_path="${collections_path}/${collection_namespace}/${collection_name}"

#   if [ -z "$git_repo" ]; then
#     ansible-galaxy collection install "${collection_namespace}.${collection_name}:${collection_version}" --force -vvv
#   else
#     local install_src="git+${git_repo}.git"
#     if [ -n "$git_ref" ]; then
#       install_src="${install_src}@${git_ref}"
#     fi
#     if [ -n "$collection_subdir" ]; then
#       install_src="${install_src},${collection_subdir}"
#     fi
#     ansible-galaxy collection install "${collection_namespace}.${collection_name}:${install_src}" --force -vvv
#   fi
# }

# install_ansible_collection() {
#   local collection_namespace="$1"
#   local collection_name="$2"
#   local collection_version="${3:-}"
#   local git_repo="${4:-}"
#   local git_ref="${5:-}" # Optional: branch, commit, or tag
#   local collection_subdir="${6:-}" # Optional: specify the collection location within the Git repository
#   local collections_path="${7:-./ansible_collections}"
#   local collection_install_path="${collections_path}/${collection_namespace}/${collection_name}"

#   if [ -z "$git_repo" ]; then
#     ansible-galaxy collection install "${collection_namespace}.${collection_name}:${collection_version}" --force -vvv
#   else
#     local install_src="git+${git_repo}.git"
#     if [ -n "$git_ref" ]; then
#       install_src="${install_src}@${git_ref}"
#     fi
#     if [ -n "$collection_subdir" ]; then
#       install_src="${install_src},${collection_subdir}"
#     fi
#     ansible-galaxy collection install "${collection_namespace}.${collection_name}" -r "${install_src}" --force -vvv
#   fi
# }

install_ansible_collection() {
  local collection_name="$1"
  local collection_version="$2"
  local git_repo="$3"
  local git_ref="$4" # Optional: branch, commit, or tag
  local collection_subdir="$5" # Optional: specify the collection location within the Git repository
  local collections_path="${6:-./ansible_collections}"
  export ANSIBLE_COLLECTIONS_PATHS="$collections_path"

  if [ -z "$git_repo" ]; then
    ansible-galaxy collection install "${collection_name}:${collection_version}" --force -vvv
  else
    local install_src="git+${git_repo}"
    if [ -n "$collection_subdir" ]; then
      install_src="${install_src}#/${collection_subdir}"
    fi
    if [ -n "$git_ref" ]; then
      install_src="${install_src},${git_ref}"
    fi
    echo "ansible-galaxy collection install "${install_src}" --force -vvv"
    ansible-galaxy collection install "${install_src}" --force -vvv
  fi
}
