provider "aws" {
    region = "us-west-2"
}

resource "aws_s3_bucket" "glue_scripts" {
    bucket = "aws-project-glue-script"
    tags = {
        Environment = "Dev"
        Project = "Learning"
    }
}

resource "aws_s3_bucket_versioning" "versioning" {
    bucket = aws_s3_bucket.glue_scripts.id
    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_s3_bucket" "s3_src_bucket_scripts" {
    bucket = "aws-project-s3-src-bucket"
    tags = {
        Environment = "Dev"
        Project = "Learning"
    }
}

resource "aws_s3_object" "data_folder" {
    bucket = aws_s3_bucket.s3_src_bucket_scripts.id
    key = "data/"
}

resource "aws_iam_role" "glue_service_role" {
    name = "AWSGlueServiceRole"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "glue.amazonaws.com"
                }
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "glue_service" {
    role = aws_iam_role.glue_service_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role" "glue_crawler_role" {
    name = "AWSGlueCrawlerServiceRole"
    assume_role_policy = jsonencode({
        
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "glue.amazonaws.com"
                }
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "glue_crawler_service" {
    role = aws_iam_role.glue_crawler_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy" "s3_policy" {
    name = "S3Policy"
    role = aws_iam_role.glue_crawler_role.id
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = [
                    "s3:GetObject",
                    "s3:PutObject",
                    "s3:ListBucket"
                ]
            Resource = [
                "arn:aws:s3:::aws-project-s3-src-bucket/*",
                "arn:aws:s3:::aws-project-s3-src-bucket"
            ]
            }
        ]
    })
}

resource "aws_glue_catalog_database" "catalog_database" {
  name = "aws_project_data_catalog_database"
}

resource "aws_glue_crawler" "crawler_resource" {
  database_name = aws_glue_catalog_database.catalog_database.name
  name          = "s3_schema_crawler"
  role          = aws_iam_role.glue_crawler_role.arn

  s3_target {
    path = "s3://aws-project-s3-src-bucket/data/"
  }
}
