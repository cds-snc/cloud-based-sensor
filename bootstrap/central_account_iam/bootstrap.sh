#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

#
# Bootstraps a given satellite account's IAM roles.
# This is based on the AWS access key and secret that
# is currently exported. 
#

SCRIPT_DIR="$(dirname "$(realpath "$0")")"

rm -rf "$SCRIPT_DIR"/terraform* "$SCRIPT_DIR"/.terraform*
terraform -chdir="$SCRIPT_DIR" init
terraform -chdir="$SCRIPT_DIR" apply
