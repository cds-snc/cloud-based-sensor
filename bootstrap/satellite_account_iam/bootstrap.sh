#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

#
# Bootstraps a given satellite account's IAM roles.
# This is based on the AWS access key and secret that
# is currently exported. 
#

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
ACCOUNT_ID="$(aws sts get-caller-identity | jq -r .Account)"
echo -e "\n\033[0;33m⚡\033[0m Bootstrap satellite \033[0;35m$ACCOUNT_ID\033[0m\n"

rm -rf "$SCRIPT_DIR"/terraform* "$SCRIPT_DIR"/.terraform*
terraform -chdir="$SCRIPT_DIR" init
terraform -chdir="$SCRIPT_DIR" apply
