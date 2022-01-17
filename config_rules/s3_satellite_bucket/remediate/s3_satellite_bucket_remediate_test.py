import sys
import unittest

from unittest.mock import MagicMock, patch

S3_CLIENT_MOCK = MagicMock()


class Boto3Mock:
    @staticmethod
    def client(client_name, *args, **kwargs):
        if client_name == "s3":
            return S3_CLIENT_MOCK
        raise Exception("Attempting to create an unknown client")


sys.modules["boto3"] = Boto3Mock()

REMEDIATE = __import__("s3_satellite_bucket_remediate")


class RemediateTest(unittest.TestCase):

    event_invalid_props = {"foo": "bar"}
    event_valid_props = {
        "awsRegion": "ca-central-1",
        "kmsKeyId": "someKeyIdArn",
        "logArchiveAccount": "098765432101",
        "logArchiveBucket": "cbs-log-archive-098765432101",
        "replicationRoleArn": "someRoleArn",
        "slackWebhook": "https://localhost/webhook",
    }
    event_invalid_slack_webhook = {"slackWebhook": "file://localhost/webhook"}

    def setUp(self):
        pass

    @patch("s3_satellite_bucket_remediate.logging")
    @patch("s3_satellite_bucket_remediate.notify_slack")
    def test_invalid_props(self, mock_notify_slack, mock_logging):
        s3_mock_reset()
        lambda_event = build_lambda_event(self.event_invalid_props)
        response = REMEDIATE.lambda_handler(lambda_event, {})
        self.assertEqual({"success": False}, response)

        mock_notify_slack.assert_called_once()
        mock_logging.error.assert_called_once()
        exception = mock_logging.error.call_args[0][0]
        self.assertTrue(isinstance(exception, KeyError))
        self.assertEqual("'kmsKeyId'", str(exception))

    def test_create_bucket(self):
        s3_mock_reset()
        lambda_event = build_lambda_event(self.event_valid_props)
        response = REMEDIATE.lambda_handler(lambda_event, {})
        self.assertEqual({"success": True}, response)

        bucket_name = "cbs-log-archive-satellite-123456789012"
        S3_CLIENT_MOCK.create_bucket.assert_called_with(
            Bucket=bucket_name,
            CreateBucketConfiguration={"LocationConstraint": "ca-central-1"},
        )
        S3_CLIENT_MOCK.put_bucket_ownership_controls.assert_called_with(
            Bucket=bucket_name,
            OwnershipControls={
                "Rules": [
                    {"ObjectOwnership": "ObjectWriter"},
                ]
            },
        )
        S3_CLIENT_MOCK.put_bucket_versioning.assert_called_with(
            Bucket=bucket_name,
            VersioningConfiguration={"Status": "Enabled"},
        )
        S3_CLIENT_MOCK.put_bucket_encryption.assert_called_with(
            Bucket=bucket_name,
            ServerSideEncryptionConfiguration={
                "Rules": [
                    {"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}},
                ]
            },
        )
        S3_CLIENT_MOCK.put_bucket_lifecycle_configuration.assert_called_with(
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
        S3_CLIENT_MOCK.put_public_access_block.assert_called_with(
            Bucket=bucket_name,
            PublicAccessBlockConfiguration={
                "BlockPublicAcls": True,
                "IgnorePublicAcls": True,
                "BlockPublicPolicy": True,
                "RestrictPublicBuckets": True,
            },
        )
        S3_CLIENT_MOCK.put_bucket_replication.assert_called_with(
            Bucket=bucket_name,
            ReplicationConfiguration={
                "Role": "someRoleArn",
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
                            "Bucket": "cbs-log-archive-098765432101",
                            "Account": "098765432101",
                            "AccessControlTranslation": {"Owner": "Destination"},
                            "EncryptionConfiguration": {
                                "ReplicaKmsKeyID": "someKeyIdArn"
                            },
                        },
                        "DeleteMarkerReplication": {"Status": "Enabled"},
                    },
                ],
            },
        )

    def test_get_params(self):
        lambda_event = build_lambda_event(self.event_valid_props)
        params = REMEDIATE.get_params(lambda_event)
        self.assertEqual(
            {
                "accountId": "123456789012",
                "awsRegion": "ca-central-1",
                "kmsKeyId": "someKeyIdArn",
                "logArchiveAccount": "098765432101",
                "logArchiveBucket": "cbs-log-archive-098765432101",
                "replicationRoleArn": "someRoleArn",
                "slackWebhook": "https://localhost/webhook",
            },
            params,
        )

    @patch("s3_satellite_bucket_remediate.json")
    @patch("s3_satellite_bucket_remediate.urlopen")
    @patch("s3_satellite_bucket_remediate.Request")
    def test_notify_slack(self, mock_request, mock_urlopen, mock_json):
        lambda_event = build_lambda_event(self.event_valid_props)
        message = {
            "text": ":red: *Remediate failed:* `123456789012` S3 satellite bucket\n```foo```"
        }
        REMEDIATE.notify_slack(lambda_event, "foo")
        mock_json.dumps.assert_called_with(message)
        mock_request.assert_called_with("https://localhost/webhook")

    def test_notify_slack_invalid_url(self):
        lambda_event = build_lambda_event(self.event_invalid_slack_webhook)  
        with self.assertRaises(Exception) as context:
            REMEDIATE.notify_slack(lambda_event, "foo")
        self.assertEqual("Slack wehbook must start with `https://`", str(context.exception))


# Helper Functions


def build_lambda_event(props):
    event = {
        "ResourceProperties": props,
        "accountId": "123456789012",
    }
    return event


def s3_mock_reset():
    S3_CLIENT_MOCK.reset_mock(return_value=True)
