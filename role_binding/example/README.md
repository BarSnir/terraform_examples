# Description
Small demo to demonstrate resources creating in Confluent cloud via Terraform.

# What resources will be created in this demo?
1. Confluent cloud environment.
2. Confluent cloud kafka cluster in AWS.
3. 2 Services accounts - one for manning topics and the other for reading from specified topic.
4. 2 Api keys - One for managing cluster's topics and the other for reading from specific topic.
5. 3 Role bindings:
    - ClusterAdmin
    - DeveloperManage
    - DeveloperRead
6. Single topic.
7. 1 Acl for specifying topic.

more resources on: https://registry.terraform.io/providers/confluentinc/confluent/latest/docs


# Prerequire actions
1. Install terraform: https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli#install-terraform
2. Export Confluent cloud API & Secret to working terminal tab.
- # export CONFLUENT_CLOUD_API_KEY
- # export CONFLUENT_CLOUD_API_SECRET 

# Init
```terraform init``` - install providers, in that case, confluent official provider.

# Plan
```terraform plan -out=<plan_name>``` plan & validate resources configuration in provider, in that case, config code main.tf.
- In this phase, note for created file such tfstate.json & plan file.

# Execute plan
```terraform apply <plan_name>``` execute the plan

# Tear Down 
```terraform destroy``` destroy all the resources