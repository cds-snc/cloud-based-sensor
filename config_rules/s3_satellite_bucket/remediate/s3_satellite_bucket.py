import logging
import boto3
from botocore.exceptions import ClientError

# Set to True to get the lambda to assume the Role attached on the Config Service (cross-account).
ASSUME_ROLE_MODE = False


def lambda_handler(event, context):
    "Lambda handler that creates the missing satellite bucket"

    check_defined(event, "event")
    return create_satellite_bucket(event)


def create_satellite_bucket(event):
    "Creates the s3 satellite bucket"

    account_id = event["accountId"]
    kms_key_id = event["ResourceProperties"]["kmsKeyId"]
    log_archive_account = event["ResourceProperties"]["logArchiveAccount"]
    log_archive_bucket = event["ResourceProperties"]["logArchiveBucket"]
    region = event["ResourceProperties"]["awsRegion"]
    replication_role_arn = event["ResourceProperties"]["replicationRoleArn"]
    bucket_name = f"cbs-satellite-account-bucket{account_id}"

    s3 = get_client("s3", event)

    # Create the bucket
    response = s3.create_bucket(
        Bucket=bucket_name,
        CreateBucketConfiguration={"LocationConstraint": region},
    )

    # Versionning
    if is_successful(response):
        response = s3.put_bucket_versioning(
            Bucket=bucket_name,
            VersioningConfiguration={"Status": "Enabled"},
        )

    # Encryption
    if is_successful(response):
        response = s3.put_bucket_encryption(
            Bucket=bucket_name,
            ServerSideEncryptionConfiguration={
                "Rules": [
                    {"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}},
                ]
            },
        )

    # Expire objects older than 14 days
    if is_successful(response):
        response = s3.put_bucket_lifecycle_configuration(
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
    if is_successful(response):
        response = s3.put_public_access_block(
            Bucket=bucket_name,
            PublicAccessBlockConfiguration={
                "BlockPublicAcls": True,
                "IgnorePublicAcls": True,
                "BlockPublicPolicy": True,
                "RestrictPublicBuckets": True,
            },
        )

    # Replication to the log archive bucket
    if is_successful(response):
        response = s3.put_bucket_replication(
            Bucket=bucket_name,
            ReplicationConfiguration={
                "Role": replication_role_arn,
                "Rules": [
                    {
                        "ID": "CbsLogging",
                        "Prefix": "",
                        "Status": "Enabled",
                        "ExistingObjectReplication": {"Status": "Enabled"},
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

    return response


def is_successful(response):
    "Checks if a given boto3 response was successful"
    return response["ResponseMetadata"]["HTTPStatusCode"] == 200


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


def check_defined(reference, reference_name):
    "Check that a given object is defined"
    if not reference:
        raise Exception("Error: ", reference_name, "is not defined")
    return reference


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
