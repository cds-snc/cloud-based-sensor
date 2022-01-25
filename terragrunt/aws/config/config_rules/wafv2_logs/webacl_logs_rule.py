import boto3
import botocore
import datetime
import json
import os

from copy import copy

# Set to True to get the lambda to assume the Role attached on the Config Service (cross-account).
ASSUME_ROLE_MODE = False
DEFAULT_RESOURCE_TYPE = "AWS::WAFv2::WebACL"
FIREHOSE_ARN = os.environ["FIREHOSE_ARN"]


def lambda_handler(event, context):
    "Lambda handler that invokes the compliance evaluation"
    global AWS_CONFIG_CLIENT

    check_defined(event, "event")
    invoking_event = json.loads(event["invokingEvent"])

    AWS_CONFIG_CLIENT = get_client("config", event)
    configuration_item = get_configuration_item(invoking_event)
    evaluation = evaluate_compliance(configuration_item, event)

    AWS_CONFIG_CLIENT.put_evaluations(
        Evaluations=evaluation, ResultToken=event["resultToken"]
    )

    # Used for unit tests
    return evaluation


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


def is_oversized_changed_notification(message_type):
    "Check whether the message is OversizedConfigurationItemChangeNotification or not"
    check_defined(message_type, "messageType")
    return message_type == "OversizedConfigurationItemChangeNotification"


def is_scheduled_notification(message_type):
    "Check whether the message is a ScheduledNotification or not"
    check_defined(message_type, "messageType")
    return message_type == "ScheduledNotification"


def get_configuration(resource_type, resource_id, configuration_capture_time):
    """Get configurationItem using getResourceConfigHistory API
    in case of OversizedConfigurationItemChangeNotification
    """
    result = AWS_CONFIG_CLIENT.get_resource_config_history(
        resourceType=resource_type,
        resourceId=resource_id,
        laterTime=configuration_capture_time,
        limit=1,
    )
    configurationItem = result["configurationItems"][0]
    return convert_api_configuration(configurationItem)


def convert_api_configuration(configurationItem):
    "Convert from the API model to the original invocation model"
    for k, v in configurationItem.items():
        if isinstance(v, datetime.datetime):
            configurationItem[k] = str(v)
    configurationItem["awsAccountId"] = configurationItem["accountId"]
    configurationItem["ARN"] = configurationItem["arn"]
    configurationItem["configurationStateMd5Hash"] = configurationItem[
        "configurationItemMD5Hash"
    ]
    configurationItem["configurationItemVersion"] = configurationItem["version"]
    configurationItem["configuration"] = json.loads(configurationItem["configuration"])
    if "relationships" in configurationItem:
        for i in range(len(configurationItem["relationships"])):
            configurationItem["relationships"][i]["name"] = configurationItem[
                "relationships"
            ][i]["relationshipName"]
    return configurationItem


def get_configuration_item(invokingEvent):
    """Get the configuration item that will be used to determine
    compliance for the evaluation.
    """
    check_defined(invokingEvent, "invokingEvent")

    # Use the getResourceConfigHistory API to get the config item
    if is_oversized_changed_notification(invokingEvent["messageType"]):
        configurationItemSummary = check_defined(
            invokingEvent["configurationItemSummary"], "configurationItemSummary"
        )
        return get_configuration(
            configurationItemSummary["resourceType"],
            configurationItemSummary["resourceId"],
            configurationItemSummary["configurationItemCaptureTime"],
        )

    # Create a generic placeholder for scheduled runs
    elif is_scheduled_notification(invokingEvent["messageType"]):
        return {
            "resourceType": DEFAULT_RESOURCE_TYPE,
            "resourceId": invokingEvent["awsAccountId"],
            "configurationItemStatus": "OK",
            "configurationItemCaptureTime": str(
                invokingEvent["notificationCreationTime"]
            ),
        }

    # Default to using the config item from the event
    return check_defined(invokingEvent["configurationItem"], "configurationItem")


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


def evaluate_compliance(configuration_item, event):
    "Checks that the WAFV2 ACL's are logging to either S3 or Kinesis"
    check_defined(configuration_item, "configuration_item")

    wafv2 = get_client("wafv2", event)
    response = wafv2.list_web_acls(Scope="REGIONAL")

    evaluations = []

    for webacl in response["WebACLs"]:
        current_item = copy(configuration_item)
        current_item["resourceId"] = webacl["ARN"]
        logging_enabled = False

        try:
            wafv2.get_logging_configuration(ResourceArn=webacl["ARN"])
            logging_enabled = True
        except botocore.exceptions.ClientError as e:

            if (
                e.response["Error"]["Code"] == "WAFNonexistentItemException"
            ):  # Logging not enabled
                logging_enabled = False
                pass
            else:
                evaluations.append(
                    build_evaluation(
                        current_item,
                        "NON_COMPLIANT",
                        "WAFv2 ACL is not configured to log to either S3 or Kinesis",
                    )
                )
                continue

        if not logging_enabled:
            # Attempt to setup logging, otherwise flag as non-compliant for manual verification
            try:
                response = wafv2.put_logging_configuration(
                    LoggingConfiguration={
                        "ResourceArn": webacl["ARN"],
                        "LogDestinationConfigs": [FIREHOSE_ARN],
                    }
                )
            except botocore.exceptions.ClientError:
                evaluations.append(
                    build_evaluation(
                        current_item,
                        "NON_COMPLIANT",
                        "WAFv2 ACL is not configured to log to either S3 or Kinesis",
                    )
                )
                continue

        evaluations.append(build_evaluation(current_item, "COMPLIANT"))
    return evaluations


def build_evaluation(configuration_item, compliance_type, annotation=None):
    """Generate an evaluation object based on the config item and compliance:
    configuration_item -- the configuration item being evaluated
    compliance_type -- either COMPLIANT, NON_COMPLIANT or NOT_APPLICABLE
    annotation -- an annotation to be added to the evaluation (default None)
    """
    eval_cc = {}
    if annotation:
        eval_cc["Annotation"] = annotation
    eval_cc["ComplianceResourceType"] = configuration_item["resourceType"]
    eval_cc["ComplianceResourceId"] = configuration_item["resourceId"]
    eval_cc["ComplianceType"] = compliance_type
    eval_cc["OrderingTimestamp"] = configuration_item["configurationItemCaptureTime"]
    return eval_cc
