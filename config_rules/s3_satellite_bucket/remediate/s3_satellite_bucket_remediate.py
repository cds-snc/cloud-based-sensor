import logging
import json
from urllib.request import Request, urlopen

import boto3
import botocore

# Set to True to get the lambda to assume the Role attached on the Config Service (cross-account).
ASSUME_ROLE_MODE = False


def lambda_handler(event, context):
    "Lambda handler that creates the s3 satellite bucket"
    is_success = False

    try:
        params = get_params(event)
        is_success = create_satellite_bucket(params, event)
    except Exception as error:
        logging.error(error)
        notify_slack(event, error)

    return {"success": is_success}


def get_params(event):
    """Extracts the required parameters from the Lambda invocation event.
    These are provided by the runbook definition."""
    return {
        "accountId": event["accountId"],
        "kmsKeyId": event["ResourceProperties"]["kmsKeyId"],
        "logArchiveAccount": event["ResourceProperties"]["logArchiveAccount"],
        "logArchiveBucket": event["ResourceProperties"]["logArchiveBucket"],
        "awsRegion": event["ResourceProperties"]["awsRegion"],
        "replicationRoleArn": event["ResourceProperties"]["replicationRoleArn"],
        "slackWebhook": event["ResourceProperties"]["slackWebhook"],
    }


def create_satellite_bucket(params, event):
    "Creates the s3 satellite bucket"

    s3 = get_client("s3", event)

    # Create the bucket
    account_id = params["accountId"]
    region = params["awsRegion"]
    bucket_name = f"cbs-log-archive-satellite-{account_id}"
    s3.create_bucket(
        Bucket=bucket_name,
        CreateBucketConfiguration={"LocationConstraint": region},
    )

    # Set ObjectWriter ACL
    # Required for access logging auto-remediation
    s3.put_bucket_ownership_controls(
        Bucket=bucket_name,
        OwnershipControls={
            "Rules": [
                {"ObjectOwnership": "ObjectWriter"},
            ]
        },
    )

    # Versionning
    s3.put_bucket_versioning(
        Bucket=bucket_name,
        VersioningConfiguration={"Status": "Enabled"},
    )

    # Encryption
    s3.put_bucket_encryption(
        Bucket=bucket_name,
        ServerSideEncryptionConfiguration={
            "Rules": [
                {"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}},
            ]
        },
    )

    # Expire objects older than 14 days
    s3.put_bucket_lifecycle_configuration(
        Bucket=bucket_name,
        LifecycleConfiguration={
            "Rules": [
                {
                    "ID": "DeleteObjects",
                    "Expiration": {
                        "Days": 14,
                    },
                    "Status": "Enabled",
                    "Filter": {"Prefix": ""},
                },
            ],
        },
    )

    # Block all public access
    s3.put_public_access_block(
        Bucket=bucket_name,
        PublicAccessBlockConfiguration={
            "BlockPublicAcls": True,
            "IgnorePublicAcls": True,
            "BlockPublicPolicy": True,
            "RestrictPublicBuckets": True,
        },
    )

    # Replication to the CbsCentral log archive bucket
    # Encrypts with a CMK and updates object ownership to CbsCentral
    kms_key_id = params["kmsKeyId"]
    log_archive_account = params["logArchiveAccount"]
    log_archive_bucket = params["logArchiveBucket"]
    replication_role_arn = params["replicationRoleArn"]
    s3.put_bucket_replication(
        Bucket=bucket_name,
        ReplicationConfiguration={
            "Role": replication_role_arn,
            "Rules": [
                {
                    "ID": "CbsCentral",
                    "Priority": 100,
                    "Status": "Enabled",
                    "Filter": {"Prefix": ""},
                    "SourceSelectionCriteria": {
                        "SseKmsEncryptedObjects": {"Status": "Enabled"},
                    },
                    "Destination": {
                        "Bucket": log_archive_bucket,
                        "Account": log_archive_account,
                        "AccessControlTranslation": {"Owner": "Destination"},
                        "EncryptionConfiguration": {"ReplicaKmsKeyID": kms_key_id},
                    },
                    "DeleteMarkerReplication": {"Status": "Enabled"},
                },
            ],
        },
    )

    return True


def notify_slack(event, error):
    "Post notification to Slack if the remediation fails"
    account_id = event["accountId"]
    slack_webhook = event["ResourceProperties"]["slackWebhook"]
    message = {
        "text": f":red: *Remediate failed:* `{account_id}` S3 satellite bucket\n```{error}```"
    }

    if not slack_webhook.startswith("https://"):
        raise Exception("Slack wehbook must start with `https://`")

    data = json.dumps(message).encode("utf-8")
    req = Request(slack_webhook)
    req.add_header("Content-type", "application/json; charset=utf-8")
    req.add_header("Content-Length", len(data))

    with urlopen(req, data) as conn:  # nosec URL validated above
        return conn.read().decode("utf-8")


def get_client(service, event):
    """Return the service boto client. It should be used instead of directly calling the client.
    Keyword arguments:
    service - the service name used for calling the boto.client()
    event - the event variable given in the lambda handler
    """
    if not ASSUME_ROLE_MODE:
        return boto3.client(service)
    credentials = get_assume_role_credentials(event["executionRoleArn"])
    return boto3.client(
        service,
        aws_access_key_id=credentials["AccessKeyId"],
        aws_secret_access_key=credentials["SecretAccessKey"],
        aws_session_token=credentials["SessionToken"],
    )


def get_assume_role_credentials(role_arn):
    "Get the assumed role credentials used for cross-account invocations"
    sts_client = boto3.client("sts")
    try:
        assume_role_response = sts_client.assume_role(
            RoleArn=role_arn, RoleSessionName="configLambdaExecution"
        )
        return assume_role_response["Credentials"]
    except botocore.exceptions.ClientError as ex:
        # Scrub error message for any internal account info leaks
        if "AccessDenied" in ex.response["Error"]["Code"]:
            ex.response["Error"][
                "Message"
            ] = "AWS Config does not have permission to assume the IAM role."
        else:
            ex.response["Error"]["Message"] = "InternalError"
            ex.response["Error"]["Code"] = "InternalError"
        raise ex
