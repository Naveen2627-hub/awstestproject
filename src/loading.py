import boto3
import os
import logging
import pandas
import datetime
from botocore import exceptions

def upload_csv_to_s3(file_path, bucket_name, s3_folder = None):
    try:
        s3_client = boto3.client('s3')
        file_name = os.path.basename(file_path)
        print(file_name)
        if s3_folder:
            s3_key = f"{s3_folder.rstrip('/')}/{file_name}"
        else:
            s3_key = file_name
        print(f"Uploading {file_name} to s3://{bucket_name}/{s3_key}")

        s3_client.upload_file(file_path,bucket_name, s3_key)

        return True
    except Exception as e:
        print("Error Uploading")
        return False
    
if __name__ == "__main__":
    bucket_name = "aws-project-s3-src-bucket"
    local_file = "/mnt/c/Users/navee/Downloads/ny-listings.csv"
    folder = f"data/"
    upload_csv_to_s3(local_file, bucket_name, folder)

    