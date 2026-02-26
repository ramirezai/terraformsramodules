# Terraform Documentation: https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/cluster

# Cluster Version
data "databricks_spark_version" "latest_lts" {
  long_term_support = true
}

# Cluster Creation
resource "databricks_cluster" "example" {
  cluster_name            = "Standard Classic Compute Plane Cluster"
  data_security_mode      = "USER_ISOLATION"
  spark_version           = data.databricks_spark_version.latest_lts.id
  node_type_id            = var.enable_compliance_security_profile ? "m6idn.xlarge" : (var.region == "us-gov-west-1" ? "i3en.xlarge" : "i3.xlarge")
  autotermination_minutes = 10
  is_single_node          = true
  kind                    = "CLASSIC_PREVIEW"
  no_wait                 = true # Skip polling for RUNNING state; avoids "unexpected EOF" when connection drops during long waits

  # Custom Tags
  custom_tags = {
    "SRA" = var.resource_prefix
  }
}

