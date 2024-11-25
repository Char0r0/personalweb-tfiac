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
        # 处理 S3 事件
        for record in event['Records']:
            # 获取事件类型和对象信息
            event_name = record['eventName']
            object_key = record['s3']['object']['key']
            
            print(f"处理事件: {event_name} 对象: {object_key}")
            
            # 处理不同类型的事件
            if event_name.startswith('ObjectCreated'):
                # 复制新文件或更新的文件
                print(f"复制文件: {object_key}")
                s3.copy_object(
                    Bucket=backup_bucket,
                    CopySource={
                        'Bucket': source_bucket,
                        'Key': object_key
                    },
                    Key=object_key
                )
                print(f"文件已复制到备份桶: {object_key}")
                
            elif event_name.startswith('ObjectRemoved'):
                # 从备份桶中删除文件
                print(f"删除文件: {object_key}")
                s3.delete_object(
                    Bucket=backup_bucket,
                    Key=object_key
                )
                print(f"文件已从备份桶删除: {object_key}")
            
        return {
            'statusCode': 200,
            'body': '备份操作完成'
        }
        
    except Exception as e:
        print(f"处理过程中发生错误: {str(e)}")
        raise e 