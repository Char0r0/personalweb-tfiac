import os
import boto3
import json

def lambda_handler(event, context):
    # Get environment variables
    source_bucket = os.environ['SOURCE_BUCKET']
    backup_bucket = os.environ['BACKUP_BUCKET']
    
    # Initialize S3 client
    s3 = boto3.client('s3')
    
    try:
        # Process each record from the S3 event
        for record in event['Records']:
            # Get event details
            event_name = record['eventName']
            object_key = record['s3']['object']['key']
            
            print(f"Processing event {event_name} for file {object_key}")
            print(f"Source bucket: {source_bucket}")
            print(f"Backup bucket: {backup_bucket}")
            
            if 'ObjectCreated' in event_name:
                # Copy new or updated file to backup bucket
                print(f"Copying {object_key} to backup bucket")
                s3.copy_object(
                    Bucket=backup_bucket,
                    Key=object_key,
                    CopySource={'Bucket': source_bucket, 'Key': object_key}
                )
                
            elif 'ObjectRemoved' in event_name:
                # Delete file from backup bucket
                print(f"Deleting {object_key} from backup bucket")
                s3.delete_object(
                    Bucket=backup_bucket,
                    Key=object_key
                )
        
        return {
            'statusCode': 200,
            'body': json.dumps('Backup operation completed successfully')
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error during backup: {str(e)}')
        } 