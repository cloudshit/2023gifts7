resource "aws_glue_catalog_database" "database" {
  name = "wsi-glue-db"
}

resource "aws_glue_catalog_table" "table" {
  name = "wsi-glue-table"
  database_name = aws_glue_catalog_database.database.name

  table_type = "EXTERNAL_TABLE"

  storage_descriptor {
    location = "s3://${aws_s3_bucket.bucket.bucket}/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      name                  = "wsi-glue-stream"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

      parameters = {
        "serialization.format" = 1
      }
    }

    columns {
      name = "time"
      type = "string"
    }

    columns {
      name = "remote_addr"
      type = "string"
    }

    columns {
      name    = "method"
      type    = "string"
    }

    columns {
      name    = "path"
      type    = "string"
    }

    columns {
      name    = "status_code"
      type    = "string"
    }
  }

  partition_keys {
    name = "year"
    type = "string"
  }

  partition_keys {
    name = "month"
    type = "string"
  }

  partition_keys {
    name = "date"
    type = "string"
  }

  partition_keys {
    name = "hour"
    type = "string"
  }

  partition_keys {
    name = "minute"
    type = "string"
  }

  lifecycle {
    ignore_changes = [
      owner,
      parameters,
      storage_descriptor
    ]
  }
}

resource "aws_glue_partition_index" "index" {
  database_name = aws_glue_catalog_database.database.name
  table_name    = aws_glue_catalog_table.table.name

  partition_index {
    index_name = "wsi-glue-index"
    keys       = ["year", "month", "date", "hour", "minute"]
  }
}

resource "aws_iam_role" "crawler" {
  name = "skills-role-crawler"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid = ""
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  ]
}

resource "aws_glue_crawler" "crawler" {
  database_name = aws_glue_catalog_database.database.name
  name = "wsi-glue-crawler"
  role = aws_iam_role.crawler.arn
  schedule = "cron(* * * * ? *)"

  schema_change_policy {
    delete_behavior = "LOG"
  }

  catalog_target {
    database_name = aws_glue_catalog_database.database.name
    tables = [aws_glue_catalog_table.table.name]
  }

  lifecycle {
    ignore_changes = [
      configuration
    ]
  }
}
