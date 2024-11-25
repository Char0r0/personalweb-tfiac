import os
import boto3
from datetime import datetime

def lambda_handler(event, context):
    # 初始化 S3 客户端
    s3 = boto3.client('s3')
    
    # 从环境变量获取桶名
    source_bucket = os.environ['SOURCE_BUCKET']
    backup_bucket = os.environ['BACKUP_BUCKET']
    
    try:
        print(f"开始从 {source_bucket} 复制文件到 {backup_bucket}")
        
        # 列出源桶中的所有对象
        paginator = s3.get_paginator('list_objects_v2')
        total_files = 0
        copied_files = 0
        
        # 使用分页器处理大量文件
        for page in paginator.paginate(Bucket=source_bucket):
            if 'Contents' not in page:
                print("源桶为空")
                return {
                    'statusCode': 200,
                    'body': '源桶为空，无需备份'
                }
            
            total_files += len(page['Contents'])
            
            # 复制每个文件
            for obj in page['Contents']:
                source_key = obj['Key']
                
                try:
                    # 检查目标桶中是否已存在相同的文件
                    try:
                        dest_obj = s3.head_object(
                            Bucket=backup_bucket,
                            Key=source_key
                        )
                        # 如果文件存在且 ETag 相同，跳过复制
                        if dest_obj['ETag'] == obj['ETag']:
                            print(f"文件已存在且内容相同，跳过: {source_key}")
                            copied_files += 1
                            continue
                    except s3.exceptions.ClientError as e:
                        if e.response['Error']['Code'] != '404':
                            raise e
                    
                    # 复制文件
                    print(f"正在复制: {source_key}")
                    s3.copy_object(
                        Bucket=backup_bucket,
                        CopySource={
                            'Bucket': source_bucket,
                            'Key': source_key
                        },
                        Key=source_key,
                        MetadataDirective='COPY'  # 保留所有元数据
                    )
                    copied_files += 1
                    print(f"成功复制: {source_key}")
                    
                except Exception as e:
                    print(f"复制文件 {source_key} 时出错: {str(e)}")
                    raise e
        
        # 检查备份桶中多余的文件
        for page in paginator.paginate(Bucket=backup_bucket):
            if 'Contents' in page:
                for obj in page['Contents']:
                    backup_key = obj['Key']
                    try:
                        # 检查源桶是否存在此文件
                        s3.head_object(
                            Bucket=source_bucket,
                            Key=backup_key
                        )
                    except s3.exceptions.ClientError as e:
                        if e.response['Error']['Code'] == '404':
                            # 如果源桶没有这个文件，从备份桶删除
                            print(f"删除备份桶中多余的文件: {backup_key}")
                            s3.delete_object(
                                Bucket=backup_bucket,
                                Key=backup_key
                            )
        
        print(f"备份完成! 总共处理 {total_files} 个文件，成功复制 {copied_files} 个文件")
        
        return {
            'statusCode': 200,
            'body': f'备份完成! 总共处理 {total_files} 个文件，成功复制 {copied_files} 个文件'
        }
        
    except Exception as e:
        print(f"备份过程中发生错误: {str(e)}")
        raise e 