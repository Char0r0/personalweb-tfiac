const AWS = require('aws-sdk');
const s3 = new AWS.S3();

exports.handler = async (event) => {
    const sourceRegion = process.env.SOURCE_REGION;
    const sourceBucket = process.env.SOURCE_BUCKET;
    const backupBucket = process.env.BACKUP_BUCKET;
    
    try {
        // 列出源存储桶中的所有对象
        const objects = await s3.listObjectsV2({ Bucket: sourceBucket }).promise();
        
        // 复制每个对象到备份存储桶
        for (const object of objects.Contents) {
            const copyParams = {
                CopySource: `${sourceBucket}/${object.Key}`,
                Bucket: backupBucket,
                Key: object.Key
            };
            
            await s3.copyObject(copyParams).promise();
        }
        
        return {
            statusCode: 200,
            body: JSON.stringify('Backup completed successfully')
        };
    } catch (error) {
        console.error('Error during backup:', error);
        throw error;
    }
}; 