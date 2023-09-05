resource "aws_kinesis_stream" "stream" {
  name = "wsi-log"
  encryption_type = "KMS"

  kms_key_id = "alias/aws/kinesis"

  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }
}

resource "aws_kinesis_firehose_delivery_stream" "stream" {
  name        = "wsi-log"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.stream.arn
    role_arn = aws_iam_role.firehose_role.arn
  }

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.bucket.arn
    buffering_size = 128
    buffering_interval = 60

    prefix = "year=!{partitionKeyFromLambda:year}/month=!{partitionKeyFromLambda:month}/date=!{partitionKeyFromLambda:date}/hour=!{partitionKeyFromLambda:hour}/minute=!{partitionKeyFromLambda:minute}/"
    error_output_prefix = "error/"

    processing_configuration {
      enabled = "true"

      processors {
        type = "Lambda"

        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = "${aws_lambda_function.lambda_processor.arn}:$LATEST"
        }
      }
    }

    data_format_conversion_configuration {
      input_format_configuration {
        deserializer {
          hive_json_ser_de {
            
          }
        }
      }

      output_format_configuration {
        serializer {
          parquet_ser_de {
            
          }
        }
      }

      schema_configuration {
        database_name = aws_glue_catalog_database.database.name
        table_name = aws_glue_catalog_table.table.name
        role_arn = aws_iam_role.firehose_role.arn
      }
    }

    dynamic_partitioning_configuration {
      enabled = true
    }
  }
}

data "aws_iam_policy_document" "firehose_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "firehose_role" {
  name               = "firehose_test_role"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AWSLambda_FullAccess",
    "arn:aws:iam::aws:policy/AWSGlueConsoleFullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonKinesisFullAccess"
  ]
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_iam" {
  name               = "lambda_iam"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "../src/firehose_processor.py"
  output_path = "../temp/firehose_processor.zip"
}

resource "aws_lambda_function" "lambda_processor" {
  filename      = "../temp/firehose_processor.zip"
  function_name = "firehose_lambda_processor"
  role          = aws_iam_role.lambda_iam.arn
  handler       = "firehose_processor.lambda_handler"
  runtime       = "python3.11"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  timeout = 60
}
