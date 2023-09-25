import {Uploader} from "./uploader";


require('dotenv').config();

// LOAD ENV VARIABLES
const {
    AWS_ACCESS_KEY_ID,
    AWS_SECRET_ACCESS_KEY,
    BUCKET_REGION,
    BUCKET_NAME, 
    BUCKET_KEY,
    BUCKET_ENDPOINT,
    BACKUP_FOLDER
} = process.env;

console.log(process.env)


const storageConfig = {
    AWS_ACCESS_KEY_ID,
    AWS_SECRET_ACCESS_KEY,
    BUCKET_REGION,
    BUCKET_NAME,
    BUCKET_KEY,
    BUCKET_ENDPOINT
}

new Uploader(BACKUP_FOLDER, storageConfig);