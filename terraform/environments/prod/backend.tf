terraform {
  backend "s3" {
    # Configure with -backend-config during terraform init.
    # Example: bucket, key, region, encrypt, use_lockfile=true.
  }
}
