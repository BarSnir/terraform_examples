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
resource "confluent_environment" "bsnir_quotas_demo_env" {
  display_name = "bsnir_quotas_demo_env"
}

#----------------------------------------------------------------
# Cluster
#----------------------------------------------------------------
resource "confluent_kafka_cluster" "bsnir_quotas_demo" {
  display_name = "bsnir_quotas_demo"
  availability = "SINGLE_ZONE"
  cloud        = "AWS"
  region       = "eu-west-1"
  dedicated {
    cku = 1
  }
  environment {
    id = confluent_environment.bsnir_quotas_demo_env.id
  }
}
#----------------------------------------------------------------
# Service accounts
#----------------------------------------------------------------

resource "confluent_service_account" "bsnir_quotas_demo_sa" {
  display_name = "bsnir_quotas_demo_sa"
  description  = "quotas demo"
}

#----------------------------------------------------------------
# API KEYS - For Terraform usage only
#----------------------------------------------------------------

resource "confluent_api_key" "bsnir_quotas_demo_api_key" {
  owner {
    id          = confluent_service_account.bsnir_quotas_demo_sa.id
    api_version = confluent_service_account.bsnir_quotas_demo_sa.api_version
    kind        = confluent_service_account.bsnir_quotas_demo_sa.kind
  }
  managed_resource {
    id          = confluent_kafka_cluster.bsnir_quotas_demo.id
    api_version = confluent_kafka_cluster.bsnir_quotas_demo.api_version
    kind        = confluent_kafka_cluster.bsnir_quotas_demo.kind
    environment {
      id = confluent_environment.bsnir_quotas_demo_env.id
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

resource "confluent_role_binding" "quotas_admin_role" {
  principal = "User:${confluent_service_account.bsnir_quotas_demo_sa.id}"
  role_name = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.bsnir_quotas_demo.rbac_crn
}

resource "confluent_role_binding" "quotas_developer_manage_role" {
  principal   = "User:${confluent_service_account.bsnir_quotas_demo_sa.id}"
  role_name   = "DeveloperManage"
  crn_pattern = "${confluent_kafka_cluster.bsnir_quotas_demo.rbac_crn}/kafka=${confluent_kafka_cluster.bsnir_quotas_demo.id}/topic=*"
}

resource "confluent_role_binding" "quotas_developer_read_role" {
  principal = "User:${confluent_service_account.bsnir_quotas_demo_sa.id}"
  role_name = "DeveloperRead"
  crn_pattern = "${confluent_kafka_cluster.bsnir_quotas_demo.rbac_crn}/kafka=${confluent_kafka_cluster.bsnir_quotas_demo.id}/topic=*"

}

resource "confluent_role_binding" "quotas_developer_write_role" {
  principal = "User:${confluent_service_account.bsnir_quotas_demo_sa.id}"
  role_name = "DeveloperWrite"
  crn_pattern = "${confluent_kafka_cluster.bsnir_quotas_demo.rbac_crn}/kafka=${confluent_kafka_cluster.bsnir_quotas_demo.id}/topic=*"
}

#----------------------------------------------------------------
# Acls
#----------------------------------------------------------------
resource "confluent_kafka_acl" "read_acl" {
  kafka_cluster {
    id = confluent_kafka_cluster.bsnir_quotas_demo.id
  }
  resource_type = "TOPIC"
  resource_name = "*"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.bsnir_quotas_demo_sa.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.bsnir_quotas_demo.rest_endpoint
  credentials {
    key    = confluent_api_key.bsnir_quotas_demo_api_key.id
    secret = confluent_api_key.bsnir_quotas_demo_api_key.secret
  }
  # In production - set to true
  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_kafka_acl" "write_acl" {
  kafka_cluster {
    id = confluent_kafka_cluster.bsnir_quotas_demo.id
  }
  resource_type = "TOPIC"
  resource_name = "*"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.bsnir_quotas_demo_sa.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.bsnir_quotas_demo.rest_endpoint
  credentials {
    key    = confluent_api_key.bsnir_quotas_demo_api_key.id
    secret = confluent_api_key.bsnir_quotas_demo_api_key.secret
  }
  # In production - set to true
  lifecycle {
    prevent_destroy = false
  }
}

#----------------------------------------------------------------
# Quotas
#----------------------------------------------------------------
resource "confluent_kafka_client_quota" "quotas_resource" {
  display_name = "quotas_resource"
  description  = "For Skai's demo"
  throughput {
    ingress_byte_rate = "1000000"
    egress_byte_rate  = "1000000"
  }
  principals = [confluent_service_account.bsnir_quotas_demo_sa.id]

  kafka_cluster {
    id = confluent_kafka_cluster.bsnir_quotas_demo.id
  }
  environment {
    id = confluent_environment.bsnir_quotas_demo_env.id
  }

  lifecycle {
    prevent_destroy = false
  }
}