import sys
import unittest

try:
    from unittest.mock import MagicMock
except ImportError:
    from mock import MagicMock


# Define the default resource to report to Config Rules
DEFAULT_RESOURCE_TYPE = "AWS::S3::Bucket"

CONFIG_CLIENT_MOCK = MagicMock()
S3_CLIENT_MOCK = MagicMock()
STS_CLIENT_MOCK = MagicMock()


class Boto3Mock:
    @staticmethod
    def client(client_name, *args, **kwargs):
        if client_name == "config":
            return CONFIG_CLIENT_MOCK
        if client_name == "sts":
            return STS_CLIENT_MOCK
        if client_name == "s3":
            return S3_CLIENT_MOCK
        raise Exception("Attempting to create an unknown client")


sys.modules["boto3"] = Boto3Mock()

RULE = __import__("s3_access_logs")


class ComplianceTest(unittest.TestCase):

    invoking_event_bucket_config_change = '{"configurationItem":{"configurationItemStatus":"ResourceDiscovered","configurationItemCaptureTime":"2018-07-02T03:37:52.418Z","resourceType":"AWS::S3::Bucket","resourceId":"s3-ca-central-1","resourceName":"s3-ca-central-1"},"notificationCreationTime":"2018-07-02T23:05:34.445Z","messageType":"ConfigurationItemChangeNotification"}'
    invoking_event_bucket_periodic_change = '{"awsAccountId":"123456789012","notificationCreationTime":"2016-07-13T21:50:00.373Z","messageType":"ScheduledNotification","recordVersion":"1.0"}'

    def setUp(self):
        pass

    def test_non_compliant_config_change(self):
        invoking_event = self.invoking_event_bucket_config_change
        lambda_event = build_lambda_event(invoking_event)
        s3_mock([])
        response = RULE.lambda_handler(lambda_event, {})
        resp_expected = build_expected_response(
            "NON_COMPLIANT",
            "s3-ca-central-1",
            annotation='The "s3-ca-central-1" bucket is not logging to cbs-satellite-account-bucket123456789012',
        )
        assert_successful_evaluation(self, response, resp_expected)

    def test_compliant_config_change(self):
        invoking_event = self.invoking_event_bucket_config_change
        lambda_event = build_lambda_event(invoking_event)
        s3_mock("cbs-satellite-account-bucket123456789012")
        response = RULE.lambda_handler(lambda_event, {})
        resp_expected = build_expected_response("COMPLIANT", "s3-ca-central-1")
        assert_successful_evaluation(self, response, resp_expected)

    def test_non_compliant_periodic_change(self):
        invoking_event = self.invoking_event_bucket_periodic_change
        lambda_event = build_lambda_event(invoking_event)
        s3_mock([])
        response = RULE.lambda_handler(lambda_event, {})
        resp_expected = build_expected_response(
            "NON_COMPLIANT",
            "123456789012",
            annotation='The "123456789012" bucket is not logging to cbs-satellite-account-bucket123456789012',
        )
        assert_successful_evaluation(self, response, resp_expected)

    def test_compliant_periodic_change(self):
        invoking_event = self.invoking_event_bucket_periodic_change
        lambda_event = build_lambda_event(invoking_event)
        s3_mock("cbs-satellite-account-bucket123456789012")
        response = RULE.lambda_handler(lambda_event, {})
        resp_expected = build_expected_response("COMPLIANT", "123456789012")
        assert_successful_evaluation(self, response, resp_expected)


# Helper Functions


def build_lambda_event(invoking_event):
    event_to_return = {
        "configRuleName": "myrule",
        "executionRoleArn": "roleArn",
        "invokingEvent": invoking_event,
        "accountId": "123456789012",
        "configRuleArn": "arn:aws:config:ca-central-1:123456789012:config-rule/config-rule-8fngan",
        "resultToken": "token",
    }
    return event_to_return


def build_expected_response(
    compliance_type,
    compliance_resource_id,
    compliance_resource_type=DEFAULT_RESOURCE_TYPE,
    annotation=None,
):
    response = {
        "ComplianceType": compliance_type,
        "ComplianceResourceId": compliance_resource_id,
        "ComplianceResourceType": compliance_resource_type,
    }
    if annotation:
        response["Annotation"] = annotation

    return response


def assert_successful_evaluation(test_class, response, resp_expected):
    test_class.assertEqual(
        resp_expected["ComplianceResourceType"], response["ComplianceResourceType"]
    )
    test_class.assertEqual(
        resp_expected["ComplianceResourceId"], response["ComplianceResourceId"]
    )
    test_class.assertEqual(resp_expected["ComplianceType"], response["ComplianceType"])
    test_class.assertTrue(response["OrderingTimestamp"])

    if "Annotation" in resp_expected or "Annotation" in response:
        test_class.assertEqual(resp_expected["Annotation"], response["Annotation"])


def s3_mock(target_bucket):
    get_bucket_logging = {'LoggingEnabled': {'TargetBucket': target_bucket, 'TargetPrefix': ''}}
    S3_CLIENT_MOCK.reset_mock(return_value=True)
    S3_CLIENT_MOCK.get_bucket_logging = MagicMock(return_value=get_bucket_logging)