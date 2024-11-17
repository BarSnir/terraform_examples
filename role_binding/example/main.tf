#----------------------------------------------------------------
# Init
#----------------------------------------------------------------
terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "2.5.0"          
    }
  }
}
# export CONFLUENT_CLOUD_API_KEY
# export CONFLUENT_CLOUD_API_SECRET
provider "confluent" {}

#----------------------------------------------------------------
# Environment
#----------------------------------------------------------------

resource "confluent_environment" "tf-orchestration-env" {
  display_name = "tf_orchestration_env"
}
#----------------------------------------------------------------
# Cluster
#----------------------------------------------------------------

resource "confluent_kafka_cluster" "bsnir-tf-standard-cluster" {
  display_name = "bsnir_tf_standard_cluster"
  availability = "SINGLE_ZONE"
  cloud = "AWS"
  region = "eu-west-1"
  standard {}
  environment {
    id = confluent_environment.tf-orchestration-env.id
  }
}
#----------------------------------------------------------------
# Service accounts
#----------------------------------------------------------------

resource "confluent_service_account" "tf-demo-manage-topics" {
  display_name = "tf_demo_manage_topics"
  description = "Demo for role binding with Terraform, This SA is to manage topic."
}

resource "confluent_service_account" "tf-demo-read-topic" {
  display_name = "tf_demo_read_topic"
  description = "Demo for role binding with Terraform, This SA is to read from single topic."
}

#----------------------------------------------------------------
# Roles binding
#----------------------------------------------------------------

resource "confluent_role_binding" "cluster-rbac" {
  principal   = "User:${confluent_service_account.tf-demo-manage-topics.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.bsnir-tf-standard-cluster.rbac_crn
}

resource "confluent_role_binding" "tf-role-binding-developer-manage" {
  principal   = "User:${confluent_service_account.tf-demo-manage-topics.id}"
  role_name   = "DeveloperManage"
  crn_pattern = "${confluent_kafka_cluster.bsnir-tf-standard-cluster.rbac_crn}/kafka=${confluent_kafka_cluster.bsnir-tf-standard-cluster.id}/topic=*"
}

resource "confluent_role_binding" "tf-role-binding-developer-read" {
  principal   = "User:${confluent_service_account.tf-demo-read-topic.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${confluent_kafka_cluster.bsnir-tf-standard-cluster.rbac_crn}/kafka=${confluent_kafka_cluster.bsnir-tf-standard-cluster.id}/topic=${confluent_kafka_topic.tf-demo-topic.topic_name}"
}

#----------------------------------------------------------------
# API KEYS - For Terraform usage only
#----------------------------------------------------------------

resource "confluent_api_key" "cluster-manage-topics-api-key" {
  display_name = "cluster_manage_topics_api_key"
  description  = "Kafka API Key that is responsible for creating & deleting topics."
  owner {
    id          = confluent_service_account.tf-demo-manage-topics.id
    api_version = confluent_service_account.tf-demo-manage-topics.api_version
    kind        = confluent_service_account.tf-demo-manage-topics.kind
  }
  managed_resource {
    id          = confluent_kafka_cluster.bsnir-tf-standard-cluster.id
    api_version = confluent_kafka_cluster.bsnir-tf-standard-cluster.api_version
    kind        = confluent_kafka_cluster.bsnir-tf-standard-cluster.kind
    environment {
      id = confluent_environment.tf-orchestration-env.id
    }
  }
  # In production - set to true
  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_api_key" "cluster-read-topic-api-key" {
  display_name = "cluster_read_topic_api_key"
  description  = "Kafka API Key that is responsible for reading from single topic (see tf-demo-topic resouces)."
  owner {
    id          = confluent_service_account.tf-demo-read-topic.id
    api_version = confluent_service_account.tf-demo-read-topic.api_version
    kind        = confluent_service_account.tf-demo-read-topic.kind
  }
  managed_resource {
    id          = confluent_kafka_cluster.bsnir-tf-standard-cluster.id
    api_version = confluent_kafka_cluster.bsnir-tf-standard-cluster.api_version
    kind        = confluent_kafka_cluster.bsnir-tf-standard-cluster.kind
    environment {
      id = confluent_environment.tf-orchestration-env.id
    }
  }
  # In production - set to true
  lifecycle {
    prevent_destroy = false
  }
}

#----------------------------------------------------------------
# Topic
#----------------------------------------------------------------

resource "confluent_kafka_topic" "tf-demo-topic" {
  kafka_cluster {
    id = confluent_kafka_cluster.bsnir-tf-standard-cluster.id
  }
  topic_name         = "automated_topic_v3"
  partitions_count   = 2
  rest_endpoint      = confluent_kafka_cluster.bsnir-tf-standard-cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.cluster-manage-topics-api-key.id
    secret = confluent_api_key.cluster-manage-topics-api-key.secret
  }
  config = {
    "cleanup.policy"                      = "delete"
    "delete.retention.ms"                 = "86400000"
    "max.compaction.lag.ms"               = "9223372036854775807"
    "max.message.bytes"                   = "2097164"
    "message.timestamp.after.max.ms"      = "9223372036854775807"
    "message.timestamp.before.max.ms"     = "9223372036854775807"      
    "message.timestamp.difference.max.ms" = "9223372036854775807"
    "message.timestamp.type"              = "CreateTime"
    "min.compaction.lag.ms"               = "0"
    "min.insync.replicas"                 = "2"
    "retention.bytes"                     = "-1"
    "retention.ms"                        = "604800000"
    "segment.bytes"                       = "104857600"
    "segment.ms"                          = "604800000"
  }
  # In production - set to true
  lifecycle {
    prevent_destroy = false
  }
}

#----------------------------------------------------------------
# Acls
#----------------------------------------------------------------

resource "confluent_kafka_acl" "bsnir-tf-standard-cluster-read-tf-topic" {
  kafka_cluster {
    id = confluent_kafka_cluster.bsnir-tf-standard-cluster.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.tf-demo-topic.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.tf-demo-read-topic.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.bsnir-tf-standard-cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.cluster-manage-topics-api-key.id
    secret = confluent_api_key.cluster-manage-topics-api-key.secret
  }
  # In production - set to true
  lifecycle {
    prevent_destroy = false
  }
}