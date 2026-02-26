data "terraform_remote_state" "platform" {
  backend = "s3"

  config = {
    bucket = var.platform_state_bucket
    key    = "platform/${var.environment}/terraform.tfstate"
    region = var.region
  }
}
