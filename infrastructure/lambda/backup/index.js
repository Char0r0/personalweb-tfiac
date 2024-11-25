const { S3Client, ListObjectsCommand, CopyObjectCommand } = require('@aws-sdk/client-s3');

exports.handler = async (event) => {
    const sourceRegion = process.env.SOURCE_REGION;
    const backupRegion = process.env.BACKUP_REGION;
    const sourceBucket = process.env.SOURCE_BUCKET;
    const backupBucket = process.env.BACKUP_BUCKET;
    
    // 创建两个 S3 客户端，分别用于源桶和备份桶
    const sourceClient = new S3Client({ 
        region: sourceRegion,
        endpoint: `https://s3.${sourceRegion}.amazonaws.com`
    });
    
    const backupClient = new S3Client({ 
        region: backupRegion,
        endpoint: `https://s3.${backupRegion}.amazonaws.com`,
        forcePathStyle: true  // 添加这个配置
    });
    
    try {
        console.log(`开始备份操作: 从 ${sourceBucket}(${sourceRegion}) 到 ${backupBucket}(${backupRegion})`);
        
        // 列出源桶中的所有对象
        const listCommand = new ListObjectsCommand({
            Bucket: sourceBucket
        });
        
        console.log('正在获取源桶文件列表...');
        const objects = await sourceClient.send(listCommand);
        
        if (!objects.Contents || objects.Contents.length === 0) {
            console.log('源桶为空，没有需要备份的文件');
            return {
                statusCode: 200,
                body: JSON.stringify('源桶为空，没有需要备份的文件')
            };
        }
        
        console.log(`找到 ${objects.Contents.length} 个文件需要备份`);
        
        // 对每个对象进行备份
        for (const object of objects.Contents) {
            console.log(`正在备份: ${object.Key}`);
            const copyCommand = new CopyObjectCommand({
                Bucket: backupBucket,
                CopySource: encodeURIComponent(`${sourceBucket}/${object.Key}`),
                Key: object.Key
            });
            
            try {
                await backupClient.send(copyCommand);
                console.log(`成功备份: ${object.Key}`);
            } catch (copyError) {
                console.error(`备份文件失败 ${object.Key}:`, copyError);
                throw copyError;
            }
        }
        
        console.log('所有文件备份完成');
        return {
            statusCode: 200,
            body: JSON.stringify('备份完成')
        };
    } catch (error) {
        console.error('备份过程中发生错误:', error);
        throw error;
    }
}; 