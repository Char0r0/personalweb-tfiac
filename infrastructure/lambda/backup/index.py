import os
import boto3
from datetime import datetime

# Initialize the S3 client
s3 = boto3.client('s3')

def lambda_handler(event, context):
    # Get bucket names from environment variables
    source_bucket = os.environ['SOURCE_BUCKET']
    backup_bucket = os.environ['BACKUP_BUCKET']
    
    try:
        # List objects in source bucket
        print(f"开始从 {source_bucket} 获取对象列表")
        response = s3.list_objects_v2(Bucket=source_bucket)
        
        if 'Contents' not in response:
            print("源桶为空，没有需要备份的文件")
            return {
                'statusCode': 200,
                'body': '源桶为空，没有需要备份的文件'
            }
            
        # Generate timestamp for this backup
        timestamp = datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
        
        # Copy each object
        for obj in response['Contents']:
            source_key = obj['Key']
            destination_key = f"{timestamp}/{source_key}"
            
            print(f"正在备份: {source_key} -> {destination_key}")
            
            # Copy the object
            s3.copy_object(
                Bucket=backup_bucket,
                CopySource={
                    'Bucket': source_bucket,
                    'Key': source_key
                },
                Key=destination_key
            )
            print(f"成功备份: {source_key}")
            
        return {
            'statusCode': 200,
            'body': '备份完成'
        }
        
    except Exception as e:
        print(f"备份过程中发生错误: {str(e)}")
        raise e 