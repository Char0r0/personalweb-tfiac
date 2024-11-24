const AWS = require('aws-sdk');
const s3 = new AWS.S3();

exports.handler = async (event) => {
    const sourceRegion = process.env.SOURCE_REGION;
    const sourceBucket = process.env.SOURCE_BUCKET;
    const backupBucket = process.env.BACKUP_BUCKET;
    
    try {
        // 获取上次备份的时间戳
        let lastBackupTime;
        try {
            const lastBackupFile = await s3.getObject({
                Bucket: backupBucket,
                Key: '.lastbackup'
            }).promise();
            lastBackupTime = new Date(lastBackupFile.Body.toString());
        } catch (err) {
            lastBackupTime = new Date(0); // 如果是第一次备份
        }

        // 只列出上次备份后修改的对象
        const objects = await s3.listObjectsV2({
            Bucket: sourceBucket
        }).promise();
        
        for (const object of objects.Contents) {
            // 只备份新的或修改过的文件
            if (object.LastModified > lastBackupTime) {
                const copyParams = {
                    CopySource: `${sourceBucket}/${object.Key}`,
                    Bucket: backupBucket,
                    Key: object.Key,
                    MetadataDirective: 'COPY'
                };
                
                await s3.copyObject(copyParams).promise();
            }
        }

        // 更新最后备份时间
        await s3.putObject({
            Bucket: backupBucket,
            Key: '.lastbackup',
            Body: new Date().toISOString()
        }).promise();

        return {
            statusCode: 200,
            body: JSON.stringify('Incremental backup completed successfully')
        };
    } catch (error) {
        console.error('Error during backup:', error);
        throw error;
    }
}; 