provider "aws" {
  region  = var.aws_region
  profile = "personal"

  default_tags {
    tags = {
      Project     = "sandia-hpc-lab"
      Environment = "demo"
      ManagedBy   = "terraform"
    }
  }
}
