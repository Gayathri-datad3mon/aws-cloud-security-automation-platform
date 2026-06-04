terraform {
  backend "s3" {
    bucket         = "gayathri-terraform-state-381491891452"
    key            = "aws-cloud-security-automation-platform/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
