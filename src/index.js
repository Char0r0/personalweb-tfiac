const AWS = require('aws-sdk');
const s3 = new AWS.S3();

exports.handler = async (event) => {
    const bucket = process.env.BUCKET_NAME;
    let key = event.rawPath.substring(1); // 移除开头的/
    
    // 处理默认页面
    if (key === '') {
        key = 'index.html';
    }
    
    try {
        // 从S3获取对象
        const s3Object = await s3.getObject({
            Bucket: bucket,
            Key: key
        }).promise();
        
        // 确定内容类型
        let contentType = s3Object.ContentType;
        if (!contentType) {
            contentType = 'application/octet-stream';
            if (key.endsWith('.html')) contentType = 'text/html';
            if (key.endsWith('.css')) contentType = 'text/css';
            if (key.endsWith('.js')) contentType = 'application/javascript';
            if (key.endsWith('.png')) contentType = 'image/png';
            if (key.endsWith('.jpg')) contentType = 'image/jpeg';
        }
        
        // 返回响应
        return {
            statusCode: 200,
            headers: {
                'Content-Type': contentType,
                'Cache-Control': 'public, max-age=3600'
            },
            body: s3Object.Body.toString('base64'),
            isBase64Encoded: true
        };
    } catch (error) {
        if (error.code === 'NoSuchKey') {
            // 返回404页面
            try {
                const errorPage = await s3.getObject({
                    Bucket: bucket,
                    Key: 'error.html'
                }).promise();
                
                return {
                    statusCode: 404,
                    headers: {
                        'Content-Type': 'text/html'
                    },
                    body: errorPage.Body.toString('base64'),
                    isBase64Encoded: true
                };
            } catch (e) {
                return {
                    statusCode: 404,
                    body: 'Not Found'
                };
            }
        }
        
        return {
            statusCode: 500,
            body: 'Internal Server Error'
        };
    }
}; 