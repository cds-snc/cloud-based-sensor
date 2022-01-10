import boto3
import logging
import os

ACCOUNT_ID = os.environ.get('ACCOUNT_ID')
LOGGING_ACCOUNT_ID = os.environ.get('LOGGING_ACCOUNT_ID')

s3 = boto3.resource('s3')
client = boto3.client('s3')

def lambda_handler(event, context):
  responseStatus = 'FAILED'
  bucketName = resource['complianceResourceId']

  try:
      config = client.get_bucket_replication(Bucket=bucketName)
  except botocore.exceptions.ClientError:
      # Log replication config
      logging.info(f'Bucket "{bucket}" : Replication config not enabled')