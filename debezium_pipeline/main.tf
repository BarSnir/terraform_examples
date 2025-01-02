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
resource "confluent_environment" "bsnir_env_debezium_flink_demo" {
  display_name = "bsnir_env_debezium_flink_demo"
  stream_governance {
    package = "ESSENTIALS"
  }
}


#----------------------------------------------------------------
# Cluster
#----------------------------------------------------------------
resource "confluent_kafka_cluster" "bsnir_cluster_debezium_flink_demo" {
  display_name = "bsnir_cluster_debezium_flink_demo"
  availability = "SINGLE_ZONE"
  cloud        = "AWS"
  region       = "eu-west-1"
  dedicated {
    cku = 1
  }
  environment {
    id = confluent_environment.bsnir_env_debezium_flink_demo.id
  }
}

#----------------------------------------------------------------
# Service accounts
#----------------------------------------------------------------

resource "confluent_service_account" "bsnir_sa_debezium_flink_demo" {
  display_name = "bsnir_sa_debezium_flink_demo"
  description  = "Debezium & Flink distribution demo"
}

#----------------------------------------------------------------
# API KEYS - For Terraform usage only
#----------------------------------------------------------------

resource "confluent_api_key" "bsnir_api_key_debezium_flink_demo" {
  owner {
    id          = confluent_service_account.bsnir_sa_debezium_flink_demo.id
    api_version = confluent_service_account.bsnir_sa_debezium_flink_demo.api_version
    kind        = confluent_service_account.bsnir_sa_debezium_flink_demo.kind
  }
  managed_resource {
    id          = confluent_kafka_cluster.bsnir_cluster_debezium_flink_demo.id
    api_version = confluent_kafka_cluster.bsnir_cluster_debezium_flink_demo.api_version
    kind        = confluent_kafka_cluster.bsnir_cluster_debezium_flink_demo.kind
    environment {
      id = confluent_environment.bsnir_env_debezium_flink_demo.id
    }
  }
  # In production - set to true
  lifecycle {
    prevent_destroy = false
  }
}

#----------------------------------------------------------------
# Roles binding
#----------------------------------------------------------------

resource "confluent_role_binding" "bsnir_environment_admin_role_debezium_flink_demo" {
  principal = "User:${confluent_service_account.bsnir_sa_debezium_flink_demo.id}"
  role_name = "EnvironmentAdmin"
  crn_pattern = confluent_environment.bsnir_env_debezium_flink_demo.resource_name
}

resource "confluent_role_binding" "bsnir_cluster_admin_role_debezium_flink_demo" {
  principal = "User:${confluent_service_account.bsnir_sa_debezium_flink_demo.id}"
  role_name = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.bsnir_cluster_debezium_flink_demo.rbac_crn
}

resource "confluent_role_binding" "quotas_developer_manage_role" {
  principal   = "User:${confluent_service_account.bsnir_sa_debezium_flink_demo.id}"
  role_name   = "DeveloperManage"
  crn_pattern = "${confluent_kafka_cluster.bsnir_cluster_debezium_flink_demo.rbac_crn}/kafka=${confluent_kafka_cluster.bsnir_cluster_debezium_flink_demo.id}/topic=*"
}

resource "confluent_role_binding" "quotas_developer_read_role" {
  principal = "User:${confluent_service_account.bsnir_sa_debezium_flink_demo.id}"
  role_name = "DeveloperRead"
  crn_pattern = "${confluent_kafka_cluster.bsnir_cluster_debezium_flink_demo.rbac_crn}/kafka=${confluent_kafka_cluster.bsnir_cluster_debezium_flink_demo.id}/topic=*"

}

resource "confluent_role_binding" "quotas_developer_write_role" {
  principal = "User:${confluent_service_account.bsnir_sa_debezium_flink_demo.id}"
  role_name = "DeveloperWrite"
  crn_pattern = "${confluent_kafka_cluster.bsnir_cluster_debezium_flink_demo.rbac_crn}/kafka=${confluent_kafka_cluster.bsnir_cluster_debezium_flink_demo.id}/topic=*"
}

#----------------------------------------------------------------
# Acls
#----------------------------------------------------------------
resource "confluent_kafka_acl" "read_acl" {
  kafka_cluster {
    id = confluent_kafka_cluster.bsnir_cluster_debezium_flink_demo.id
  }
  resource_type = "TOPIC"
  resource_name = "*"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.bsnir_sa_debezium_flink_demo.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.bsnir_cluster_debezium_flink_demo.rest_endpoint
  credentials {
    key    = confluent_api_key.bsnir_api_key_debezium_flink_demo.id
    secret = confluent_api_key.bsnir_api_key_debezium_flink_demo.secret
  }
  # In production - set to true
  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_kafka_acl" "write_acl" {
  kafka_cluster {
    id = confluent_kafka_cluster.bsnir_cluster_debezium_flink_demo.id
  }
  resource_type = "TOPIC"
  resource_name = "*"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.bsnir_sa_debezium_flink_demo.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.bsnir_cluster_debezium_flink_demo.rest_endpoint
  credentials {
    key    = confluent_api_key.bsnir_api_key_debezium_flink_demo.id
    secret = confluent_api_key.bsnir_api_key_debezium_flink_demo.secret
  }
  # In production - set to true
  lifecycle {
    prevent_destroy = false
  }
}

#----------------------------------------------------------------
# Connector
#----------------------------------------------------------------
resource "confluent_connector" "bsnir_connector_debezium_flink_demo" {
  environment {
    id = confluent_environment.bsnir_env_debezium_flink_demo.id
  }
  kafka_cluster {
    id = confluent_kafka_cluster.bsnir_cluster_debezium_flink_demo.id
  }

  config_sensitive = {
    "database.password" = "****"
  }

  // Block for custom *nonsensitive* configuration properties that are *not* labelled with "Type: password" under "Configuration Properties" section in the docs:
  // https://docs.confluent.io/cloud/current/connectors/cc-postgresql-cdc-source-debezium.html#configuration-properties
  config_nonsensitive = {
    "connector.class"          = "MySqlCdcSourceV2"
    "name"                     = "cdc_connector_demo_v1"
    "kafka.auth.mode"          = "SERVICE_ACCOUNT"
    "kafka.service.account.id" = confluent_service_account.bsnir_sa_debezium_flink_demo.id
    "database.hostname"        = "debezium-demo.ccctmswayzpp.eu-west-1.rds.amazonaws.com"
    "database.port"            = "3306"
    "database.user"            = "admin"
    "table.include.list"       = "production.Vehicles"
    "output.data.format"       = "AVRO",
    "tasks.max"                = "1"
  }

  lifecycle {
    prevent_destroy = true
  }
}