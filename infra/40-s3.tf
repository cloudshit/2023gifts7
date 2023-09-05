resource "aws_s3_bucket" "bucket" {
  bucket_prefix = "wsi-log-"
  force_destroy = true
}
