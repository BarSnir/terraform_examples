# Example for using Confluent Cloud https://docs.confluent.io/cloud/current/api.html
# that creates multiple resources: a service account, an environment, a basic cluster, a topic, and 2 ACLs.
# Configure Confluent Cloud provider
terraform {
  required_providers {
    confluentcloud = {
      source  = "confluentinc/confluentcloud"
      version = "0.5.0"
    }
  }
}

provider "confluentcloud" {}

resource "confluentcloud_service_account" "test-sa" {
  display_name = "test_sa"
  description = "description for test_sa"
}

resource "confluentcloud_environment" "test-env" {
  display_name = "test_env"
}

resource "confluentcloud_kafka_cluster" "test-basic-cluster" {
  display_name = "test_cluster"
  availability = "SINGLE_ZONE"
  cloud = "GCP"
  region = "us-central1"
  basic {}
  environment {
    id = confluentcloud_environment.test-env.id
  }

}