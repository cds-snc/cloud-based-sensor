# Cloud Based Sensor

Infrastructure configuration to support the Canadian Centre for Cyber Security (CCCS) Cloud Based Sensor integration with CDS's AWS accounts.

# Config rules
* [`s3_satellite_bucket`](./config_rules/s3_satellite_bucket): Checks that an account has the expected CBS s3 satellite bucket. 
* [`s3_access_logs`](./config_rules/s3_access_logs): Checks that all s3 buckets are replicating to the expected CBS s3 satellite bucket. 