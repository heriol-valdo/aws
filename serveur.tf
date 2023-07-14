provider "aws" {
    region = "eu-west-3"
    access_key = "AKIAYZIKDKY5QXQR6CLC"
    secret_key= "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"
}

// création de la clé ssh
resource "tls_private_key" "ec2Key" {
  algorithm   = "RSA"
  rsa_bits    = 2048
}


//creation de la table
resource "aws_dynamodb_table" "JOB" {
  name           = "JOB"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "id"

  attribute {
    name = "id"
    type = "N"
  }
  attribute {
    name = "job_type"
    type = "S"
  }
  attribute {
    name = "content"
    type = "S"
  }
    attribute {
    name = "processed"
    type = "B"
  }

  global_secondary_index {
    name               = "job_type_index"
    hash_key           = "job_type"
    projection_type    = "ALL"
    read_capacity      = 5
    write_capacity     = 5
  }

  global_secondary_index {
    name               = "processed_index"
    hash_key           = "processed"
    projection_type    = "ALL"
    read_capacity      = 5
    write_capacity     = 5
  }

  global_secondary_index {
    name               = "content_index"
    hash_key           = "content"
    projection_type    = "ALL"
    read_capacity      = 5
    write_capacity     = 5
  }

   lifecycle {
    prevent_destroy = true
  }
}


//creation de la table
resource "aws_dynamodb_table" "addToDynamoDB" {
  name           = "addToDynamoDB"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "id"

  attribute {
    name = "id"
    type = "N"
  }
  lifecycle {
    prevent_destroy = true
  }

}

resource "aws_s3_bucket" "addToS3" {
  bucket = "addtoS3"

  tags = {
    Name        = "addtoS3"
    Environment = "Dev"
  }


}

resource "aws_lambda_function" "selectdb" {
  filename        = "./selectdb.zip"
  function_name   = "selectdb"
  role            = "arn:aws:iam::604000966203:role/service-role/SelectDB-role-m09zqlkj"
  handler         = "selectdb.handler"
  runtime         = "nodejs14.x"
  source_code_hash = filebase64sha256("./selectdb.zip")

  environment {
    variables = {
      TABLE_NAME = "addToDynamoDB"
    }
  }
}

 // Configuration du déclencheur CloudWatch Events
  resource "aws_cloudwatch_event_rule" "job_event_rule" {
    name        = "job_event_rule"
    description = "Rule for triggering process_job Lambda function"

    event_pattern = <<EOF
{
  "source": ["aws.dynamodb"],
  "detail-type": ["Dynamo DB Table Event"],
  "detail": {
    "eventSourceARN": ["${aws_dynamodb_table.JOB.arn}"],
    "eventName": ["INSERT", "MODIFY"]
  }
}
EOF
  }

  resource "aws_cloudwatch_event_target" "job_event_target" {
    rule      = aws_cloudwatch_event_rule.job_event_rule.name
    arn       = aws_lambda_function.selectdb.arn
    target_id = "process_job_target"
  } 