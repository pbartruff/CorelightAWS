# CorelightAWS
Set of Terraform and Ansible scripts to deploy a simple Corelight lab environment

# Terraform scripts
Only a few scripts have been created to deploy a simple architecture.  Additionally, a varaibles file has much of the configuration, including some items that are not used.  There are no systems being deployed that will need to be monitored.  I left that for the person who is going to be using the architecture.

The variables file can be renamed to variables.tf and is already in the .gitignore file so that keys are not accidentally shared.

S3 Buckets names are there really to track the name.  I ussually used a guid for a bucket name so I don't have to worry about collisions; however, I need to note what bucket is for what purpose.  All this should probably be in ansible, including the creation of the bucket and scripts to configure corelight to send log data to the s3 log bucket, file objects to the objects bucket, and keep persistent data/configuration files in the data bucket.

# Ansible scripts are coming soon

# YMMV
:-)
