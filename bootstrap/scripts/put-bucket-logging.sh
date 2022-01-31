#!/bin/bash

#
# PURPOSE:
# Sets the given target bucket(s) to use the satellite bucket 
# in the account as the access log destination.
#
# USE:
# ./put-bucket-logging.sh 'bucket-name-1 bucket-name-2 bucket-name-3'
#

set -euo pipefail
IFS=$' '

BUCKET_NAMES="$1"
ACCOUNT_ID="$(aws sts get-caller-identity | jq -r .Account)"
SATELLITE_BUCKET_NAME="cbs-satellite-${ACCOUNT_ID}"
LOG_PREFIX="s3_access_logs/AWSLogs/${ACCOUNT_ID}"

echo -e "\n🪣  S3 access logging for \033[0;35m${ACCOUNT_ID}\033[0m\n"

for BUCKET in ${BUCKET_NAMES}; do
    echo -e "Bucket \033[0;33m${BUCKET}\033[0m"
    aws s3api put-bucket-logging \
        --bucket "${BUCKET}" \
        --bucket-logging-status '{"LoggingEnabled":{"TargetBucket":"'"${SATELLITE_BUCKET_NAME}"'","TargetPrefix":"'"${LOG_PREFIX}"'/"}}'    
done
