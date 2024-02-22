#!/usr/bin/env bash

set -euo pipefail

get_yaml_array() {
  readarray -t "$1" < <(echo "$3" | yq -I=0 "$2")
}

OS_VERSION=$(grep -Po '(?<=VERSION_ID=)\d+' /usr/lib/os-release)

export OS_VERSION
export -f get_yaml_array
