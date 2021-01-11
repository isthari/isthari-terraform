resource "aws_s3_bucket_object" "user" {
  bucket = var.bucket
  key    = "user/"
  source = "/dev/null"
}

resource "aws_s3_bucket_object" "hive" {
  bucket = var.bucket
  key    = "user/hive/"
  source = "/dev/null"
}

resource "aws_s3_bucket_object" "warehouse" {
  bucket = var.bucket
  key    = "user/hive/warehouse/"
  source = "/dev/null"
}
