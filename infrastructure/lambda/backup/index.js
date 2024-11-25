const { S3Client, ListObjectsCommand, CopyObjectCommand } = require('@aws-sdk/client-s3');

exports.handler = async (event) => {
    const s3Client = new S3Client({});
    const sourceBucket = process.env.SOURCE_BUCKET;
    const backupBucket = process.env.BACKUP_BUCKET;
    
    try {
        // 列出源桶中的所有对象
        const listCommand = new ListObjectsCommand({
            Bucket: sourceBucket
        });
        const objects = await s3Client.send(listCommand);
        
        if (!objects.Contents || objects.Contents.length === 0) {
            console.log('源桶为空，没有需要备份的文件');
            return {
                statusCode: 200,
                body: JSON.stringify('源桶为空，没有需要备份的文件')
            };
        }
        
        // 对每个对象进行备份
        for (const object of objects.Contents) {
            const copyCommand = new CopyObjectCommand({
                Bucket: backupBucket,
                CopySource: `${sourceBucket}/${object.Key}`,
                Key: object.Key
            });
            
            await s3Client.send(copyCommand);
            console.log(`已备份: ${object.Key}`);
        }
        
        return {
            statusCode: 200,
            body: JSON.stringify('备份完成')
        };
    } catch (error) {
        console.error('备份错误:', error);
        throw error;
    }
}; 