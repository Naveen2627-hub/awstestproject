provider "aws" {
    region = "us-west-2"
}

# S3 Resources
resource "aws_s3_bucket" "glue_scripts" {
    bucket = "aws-project-glue-script"
    tags = {
        Environment = "Dev"
        Project = "Learning"
    }
}

resource "aws_s3_object" "scripts_folder" {
    bucket = aws_s3_bucket.glue_scripts.id
    key = "scripts/"
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

resource "aws_s3_bucket" "s3_target_bucket_scripts" {
    bucket = "aws-project-s3-target-bucket"
    tags = {
        Environment = "Dev"
        Project = "Learning"
    }
}

resource "aws_s3_object" "data_target_folder" {
    bucket = aws_s3_bucket.s3_target_bucket_scripts.id
    key = "data/"
}

# IAM Resources
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
                "arn:aws:s3:::aws-project-s3-src-bucket",
                "arn:aws:s3:::aws-project-s3-target-bucket/*",
                "arn:aws:s3:::aws-project-s3-target-bucket",
                "arn:aws:s3:::aws-project-glue-script",
                "arn:aws:s3:::aws-project-glue-script/*"
            ]
            }
        ]
    })
}


# Glue DataCatalog
resource "aws_glue_catalog_database" "catalog_database" {
  name = "aws_project_data_catalog_database"
}

# Glue Crawler
resource "aws_glue_crawler" "crawler_resource" {
  database_name = aws_glue_catalog_database.catalog_database.name
  name          = "s3_schema_crawler"
  role          = aws_iam_role.glue_crawler_role.arn

  s3_target {
    path = "s3://aws-project-s3-src-bucket/data/"
  }
}

# Glue Scripts
resource "aws_s3_object" "glue_object_script" {
    bucket = aws_s3_bucket.glue_scripts.id
    key = "scripts/glue_job.py"
    source = "${path.module}/scripts/glue_job.py"
    etag = filemd5("${path.module}/scripts/glue_job.py")
}

resource "aws_glue_job" "etl_scripts" {
    name = "transformation_job"
    role_arn = aws_iam_role.glue_crawler_role.arn
    command {
        script_location = "s3://${aws_s3_bucket.glue_scripts.bucket}/${aws_s3_object.glue_object_script.key}"
        python_version = "3"
    } 
}

resource "aws_glue_workflow" "etl_workflow" {
    name = "etl_workflow"
}

resource "aws_glue_trigger" "schedule_trigger" {
    name = "schedule_trigger"
    workflow_name = aws_glue_workflow.etl_workflow.name
    type = "SCHEDULED"
    schedule = "cron(0/5 * * * ? *)"

    actions {
        job_name = "transformation_job"
    }
}
