import sys
import unittest

try:
    from unittest.mock import MagicMock
except ImportError:
    from mock import MagicMock


# Define the default resource to report to Config Rules
DEFAULT_RESOURCE_TYPE = "AWS::WAFv2::WebACL"

CONFIG_CLIENT_MOCK = MagicMock()
WAFV2_CLIENT_MOCK = MagicMock()
STS_CLIENT_MOCK = MagicMock()


class Boto3Mock:
    @staticmethod
    def client(client_name, *args, **kwargs):
        if client_name == "config":
            return CONFIG_CLIENT_MOCK
        if client_name == "sts":
            return STS_CLIENT_MOCK
        if client_name == "wafv2":
            return WAFV2_CLIENT_MOCK
        raise Exception("Attempting to create an unknown client")


sys.modules["boto3"] = Boto3Mock()

RULE = __import__("s3_wafv2_logs_rule")


class ComplianceTest(unittest.TestCase):

    invoking_event_wafv2_config_change = '{"configurationItem":{"configurationItemStatus":"ResourceDiscovered","configurationItemCaptureTime":"2018-07-02T03:37:52.418Z","resourceType":"AWS::WAFv2::WebACL","resourceId":"wafv2-ca-central-1","ARN":"arn:aws:wafv2:ca-central-1:123456789012:regional/webacl","resourceName":"wafv2-ca-central-1"},"notificationCreationTime":"2018-07-02T23:05:34.445Z","messageType":"ConfigurationItemChangeNotification"}'
    invoking_event_wafv2_periodic_change = '{"awsAccountId":"123456789012","notificationCreationTime":"2016-07-13T21:50:00.373Z","messageType":"ScheduledNotification","recordVersion":"1.0"}'
    rule_parameters = {}

    def setUp(self):
        pass

    def test_non_compliant_config_change(self):
        invoking_event = self.invoking_event_wafv2_config_change
        lambda_event = build_lambda_event(invoking_event, self.rule_parameters)
        wafv2_mock(
            [], {"ARN": "arn:aws:wafv2:ca-central-1:123456789012:regional/webacl"}
        )
        response = RULE.lambda_handler(lambda_event, {})
        resp_expected = build_expected_response(
            "NON_COMPLIANT",
            "wafv2-ca-central-1",
            annotation="WAFv2 ACL is not configured to log to either S3 or Kinesis",
        )
        assert_successful_evaluation(self, response, resp_expected)

    def test_compliant_config_change_s3(self):
        invoking_event = self.invoking_event_wafv2_config_change
        lambda_event = build_lambda_event(invoking_event, self.rule_parameters)
        wafv2_mock(
            ["arn:aws:s3:::aws-waf-logs-cbs-123456789012"],
            {"ARN": "arn:aws:wafv2:ca-central-1:123456789012:regional/webacl"},
        )
        response = RULE.lambda_handler(lambda_event, {})
        resp_expected = build_expected_response("COMPLIANT", "wafv2-ca-central-1")
        assert_successful_evaluation(self, response, resp_expected)

    def test_compliant_config_change_kinesis(self):
        invoking_event = self.invoking_event_wafv2_config_change
        lambda_event = build_lambda_event(invoking_event, self.rule_parameters)
        wafv2_mock(
            ["arn:aws:kinesis:::aws-waf-logs-cbs-123456789012"],
            {"ARN": "arn:aws:wafv2:ca-central-1:123456789012:regional/webacl"},
        )
        response = RULE.lambda_handler(lambda_event, {})
        resp_expected = build_expected_response("COMPLIANT", "wafv2-ca-central-1")
        assert_successful_evaluation(self, response, resp_expected)

    def test_non_compliant_periodic_change(self):
        invoking_event = self.invoking_event_wafv2_periodic_change
        lambda_event = build_lambda_event(invoking_event, self.rule_parameters)
        wafv2_mock(
            [], {"ARN": "arn:aws:wafv2:ca-central-1:123456789012:regional/webacl"}
        )
        response = RULE.lambda_handler(lambda_event, {})
        resp_expected = build_expected_response(
            "NON_COMPLIANT",
            "123456789012",
            annotation="WAFv2 ACL is not configured to log to either S3 or Kinesis",
        )
        assert_successful_evaluation(self, response, resp_expected)

    def test_compliant_periodic_change(self):
        invoking_event = self.invoking_event_wafv2_periodic_change
        lambda_event = build_lambda_event(invoking_event, self.rule_parameters)
        wafv2_mock(
            ["arn:aws:s3:::aws-waf-logs-cbs-123456789012"],
            {"ARN": "arn:aws:wafv2:ca-central-1:123456789012:regional/webacl"},
        )
        response = RULE.lambda_handler(lambda_event, {})
        resp_expected = build_expected_response("COMPLIANT", "123456789012")
        assert_successful_evaluation(self, response, resp_expected)


# Helper Functions


def build_lambda_event(invoking_event, rule_parameters=None):
    event_to_return = {
        "configRuleName": "myrule",
        "executionRoleArn": "roleArn",
        "invokingEvent": invoking_event,
        "accountId": "123456789012",
        "configRuleArn": "arn:aws:config:ca-central-1:123456789012:config-rule/config-rule-8fngan",
        "resultToken": "token",
    }
    if rule_parameters:
        event_to_return["ruleParameters"] = rule_parameters
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


def wafv2_mock(log=[], web_acl=[]):
    get_logging_configuration = {"LoggingConfiguration": {"LogDestinationConfigs": log}}
    list_web_acls = {"WebACLs": [{"ARN": web_acl}]}

    WAFV2_CLIENT_MOCK.reset_mock(return_value=True)
    WAFV2_CLIENT_MOCK.get_logging_configuration = MagicMock(
        return_value=get_logging_configuration
    )
    WAFV2_CLIENT_MOCK.list_web_acls = MagicMock(return_value=list_web_acls)
