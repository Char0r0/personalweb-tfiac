import os
import boto3
from datetime import datetime

def lambda_handler(event, context):
    # Initialize S3 client
    s3 = boto3.client('s3')
    
    # Get bucket names from environment variables
    source_bucket = os.environ['SOURCE_BUCKET']
    backup_bucket = os.environ['BACKUP_BUCKET']
    
    try:
        print(f"Starting to copy files from {source_bucket} to {backup_bucket}")
        
        # List all objects in source bucket
        paginator = s3.get_paginator('list_objects_v2')
        total_files = 0
        copied_files = 0
        
        # Use paginator to handle large number of files
        for page in paginator.paginate(Bucket=source_bucket):
            if 'Contents' not in page:
                print("Source bucket is empty")
                return {
                    'statusCode': 200,
                    'body': 'Source bucket is empty, no backup needed'
                }
            
            total_files += len(page['Contents'])
            
            # Copy each file
            for obj in page['Contents']:
                source_key = obj['Key']
                
                try:
                    # Check if file already exists in destination bucket
                    try:
                        dest_obj = s3.head_object(
                            Bucket=backup_bucket,
                            Key=source_key
                        )
                        # Skip if file exists and ETag matches
                        if dest_obj['ETag'] == obj['ETag']:
                            print(f"File exists and content matches, skipping: {source_key}")
                            copied_files += 1
                            continue
                    except s3.exceptions.ClientError as e:
                        if e.response['Error']['Code'] != '404':
                            raise e
                    
                    # Copy file
                    print(f"Copying: {source_key}")
                    s3.copy_object(
                        Bucket=backup_bucket,
                        CopySource={
                            'Bucket': source_bucket,
                            'Key': source_key
                        },
                        Key=source_key,
                        MetadataDirective='COPY'  # Preserve all metadata
                    )
                    copied_files += 1
                    print(f"Successfully copied: {source_key}")
                    
                except Exception as e:
                    print(f"Error copying file {source_key}: {str(e)}")
                    raise e
        
        # Check for extra files in backup bucket
        for page in paginator.paginate(Bucket=backup_bucket):
            if 'Contents' in page:
                for obj in page['Contents']:
                    backup_key = obj['Key']
                    try:
                        # Check if file exists in source bucket
                        s3.head_object(
                            Bucket=source_bucket,
                            Key=backup_key
                        )
                    except s3.exceptions.ClientError as e:
                        if e.response['Error']['Code'] == '404':
                            # Delete from backup bucket if not in source
                            print(f"Deleting extra file from backup bucket: {backup_key}")
                            s3.delete_object(
                                Bucket=backup_bucket,
                                Key=backup_key
                            )
        
        print(f"Backup complete! Processed {total_files} files, successfully copied {copied_files} files")
        
        return {
            'statusCode': 200,
            'body': f'Backup complete! Processed {total_files} files, successfully copied {copied_files} files'
        }
        
    except Exception as e:
        print(f"Error during backup process: {str(e)}")
        raise e 