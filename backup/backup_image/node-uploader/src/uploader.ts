const chokidar = require('chokidar')
import {PutObjectCommand, S3Client, S3ClientConfig} from "@aws-sdk/client-s3";
const fs = require('fs')

export class Uploader{

    private client:S3Client;
    private storageConfig;
    private folderPathToWatch;
    constructor(folderPathToWatch:string,
                storageConfig:{
                    AWS_ACCESS_KEY_ID?:string,
                    AWS_SECRET_ACCESS_KEY?:string,
                    BUCKET_REGION?:string,
                    BUCKET_NAME?:string,
                    BUCKET_KEY?:string,
                    BUCKET_ENDPOINT?:string //the only optional one.
                }={})
    {
        this.folderPathToWatch = folderPathToWatch;
        this.storageConfig = storageConfig;
        let S3Configuration:S3ClientConfig = {
            credentials: {
                accessKeyId: storageConfig.AWS_ACCESS_KEY_ID,
                secretAccessKey: storageConfig.AWS_SECRET_ACCESS_KEY,
            },
            region: storageConfig.BUCKET_REGION,
            forcePathStyle: true,
            endpoint: storageConfig.BUCKET_ENDPOINT ? storageConfig.BUCKET_ENDPOINT: ''
        }

        this.client = new S3Client(S3Configuration);


        // folder watcher
        chokidar.watch(this.folderPathToWatch,{awaitWriteFinish: {
            stabilityThreshold: 10000,
            pollInterval: 100
        }}).
            on('add', (path,event) => {
            this.handleEvent(path, event);
        })
    }


     handleEvent(path: any, event: any) {
        const fileName = (path as string).split('/').pop()
        if (fileName.endsWith('.sql.gz')) {
            const fileStream = fs.createReadStream(path);
            const input = {
                "Body": fileStream,
                "Bucket": this.storageConfig.BUCKET_NAME,
                "Key": 'backups/'+fileName,
                "Tagging": "backup=true"
            };
            const command = new PutObjectCommand(input);
            this.client.send(command)
                .then(() => {
                    console.log('File uploaded:', fileName);
                    fs.unlink(path, (err) => {
                        if (err) {
                            throw err;
                        }
                        console.log('File deleted:', fileName);
                    })

                })
                .catch((err) => {
                    console.error('Error uploading file:', fileName, err);
                });
        }
    }

}