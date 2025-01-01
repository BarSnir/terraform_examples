provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
  environment_id   = var.confluent_environment_id
}

resource "confluent_service_account" "example" {
  display_name = "example-service-account"
  description  = "Service account for example purposes"
}

resource "confluent_api_key" "example" {
  service_account_id = confluent_service_account.example.id
  environment_id     = var.confluent_environment_id
  cluster_id         = confluent_kafka_cluster.example.id
}

resource "confluent_kafka_cluster" "example" {
  display_name = "example-enterprise-cluster"
  availability = "MULTI_ZONE"
  cloud        = "aws"
  region       = "us-west-2"
  type         = "ENTERPRISE"
  public_connectivity = true
}

resource "confluent_role_binding" "example" {
  principal = "User:${confluent_service_account.example.id}"
  role_name = "DeveloperRead"
  crn_pattern = confluent_kafka_cluster.example.rbac_crn
}

resource "confluent_kafka_quota" "example" {
  cluster_id = confluent_kafka_cluster.example.id
  service_account_id = confluent_service_account.example.id
  ingress_mbps = 2
  egress_mbps = 4
}

resource "confluent_kafka_acl" "read_acl" {
  kafka_cluster {
    id = confluent_kafka_cluster.example.id
  }
  resource_type = "TOPIC"
  resource_name = "*"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.example.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
}

resource "confluent_kafka_acl" "write_acl" {
  kafka_cluster {
    id = confluent_kafka_cluster.example.id
  }
  resource_type = "TOPIC"
  resource_name = "*"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.example.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
}

variable "confluent_cloud_api_key" {}
variable "confluent_cloud_api_secret" {}
variable "confluent_environment_id" {}