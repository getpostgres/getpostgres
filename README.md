# GetPostgres Scripts

## A step back: what is GetPostgres?

GetPostgres is a platform to privately deploy and manage a complete and rock-solid database service.

You can do it by yourself, or go to getpostgres.com and subsvribe. We'll take care of everything else. 

Our business principles are devoted to *open-source philosophy*.

## Introduction

In this repo you can find all the scripts and Docker files used by the GetPostgres team to setup a complete usable streaming-replication postgres instance with automatic backups.

If you want to deploy our service by yourself on your machines, follow this guide.

**NOTE**: this guide explains how to setup the service by using two distinct machines, when you need a DB replica. 

You're free to use just a single machine, if that fits your needs.

## Setup

### 1. Postgres Streaming Replication

In this section it is explained how to setup streaming replication between two postgres instances.

#### 1.1 Master Setup


The only steps needed to launch the 'master' postgres instance (*the read and write one*) are:

1) edit the `.env` file placed into [db/master](/db/master/) folder
2) and the `master.env` file placed into [db/master](/db/master/) folder

The [`.env`](/db/master/.env) file contains only two configuration parameters:

* **TZ**: sets the container timezone
* **PORT**: sets the exteral container port (*host port*)

The [`master.env`](/db/master/master.env) file contains all postgres configuration parameters:

* **POSTGRES_USER**: the default db user name. It is recommended to use a different name than `postgres`.
* **POSTGRES_PASSWORD**: the default db password.
* **POSTGRES_DB**: the default db name. As said above, it is recomended to write a different name than `postgres`.
* **REPLICA_POSTGRES_USER**: the user name used for replication
* **REPLICA_POSTGRES_PASSWORD**: the password used for replication

 > **pay attention**: `REPLICA_POSTGRES_USER` and `REPLICA_POSTGRES_PASSWORD` must be the credentials of the default user in the replica instance!

* **PGDATA**: the path where the postgres instance will save files into inside the container. It is recommended to use the default value `/var/lib/postgresql/data`.

* **REPLICA_NAME**: the name used by postgres to link "master" and "replica" postgres instances. `replica_slot` is recommended.

* **PG_PORT**: the internal port used for postgres connections (container port)


#### 1.2 Setup Replica

As described for the master instance, all configuration parameters are defined into `.env` (same name, but a different file placed into different folders) and `replica.env` stored into the [db/replica](/db/replica/) folder.

The parameters into the [`.env`](/db/replica/.env) file are the same as described before.

[`replica.env`](/db/replica/replica.env) contains the following parameters:

* **POSTGRES_USER**: the replication user name defined into the master instance.

* **POSTGRES_PASSWORD**: the replication password defined into the master instance.

* **POSTGRES_DB**: the postgres db name defined into the master container.

 > **pay attention**: all databases defined into the postgres master instance will be replicated into the postgres replica instance, not only the main `POSTGRES_DB`, but you need to specify only one.

* **PGDATA**: the path where the postgres instance will save files into inside the container. It is recommended to use the default value `/var/lib/postgresql/data/replica`.

  > **pay attention**: the path is different from the master one

* **REPLICA_NAME**: the `REPLICA_NAME` defined into [master.env](/db/master/master.env)

* **REPLICATE_FROM**: the ip address where the master instance is running.

* **PG_PORT**: the external port of the master instance, defined into the `.env` file (into the `/master` folder)


### 2. Postgres Automatic Backup

In this section it is described the backup part of the service. It must be execute when postgres replication deployment is completed.
As seen above all configuration parameters are included into an [`.env`](/backup/.env) file placed into the [backup](/backup/) folder.

The backup service provides the following configuration parameters:

* **MASTER_IP**: the ip of the postgres "master" instance
* **BACKUP_FOLDER**: the absolute path where we'll store the file backup (inside the container). It is recomended to use `/backup_data`.
* **DUMP_SCHEDULING**: choose between `15min` `hourly` `daily` `weekly` `monthly` `custom` to set the cron scheduling interval to backup the db. If you wanna use a `custom` option, you must set the `CUSTOM_CON_EXPRESSION` environment variable  with a valid cron rule as a string. following the `* * * * *` template.
* **CUSTOM_CRON_EXPRESSION**: as described in the previous bullet, this variable is used only when the `DUMP_SCHEDULING` parameter value is `custom`.
* **PG_PORT**: the tcp port used to connect with the master instance host. It must be the same defined into [`master.env`](/db/master/master.env).
* **POSTGRES_USER**: the "master" postgres user name defined into the master instance.
* **POSTGRES_PASSWORD**: the "master" postgres user password defined into the master instance.
* **DUMPALL**: choose between 'on' and 'off'. If on, the backup will include all databases defined into the postgres instance.
* **POSTGRES_DB**: the default db defined into the postgres master instance. If dumpall is off, only the database defined in `POSTGRES_DB` will be dumped.
* **DUMP_OUTPUT_FORMAT**: choose between 'custom' and 'sql'. custom is a format specified for the pg_restore software. If 'sql', the output file will be a "simply" plain `.sql` file.
* **TZ**: Set the timezone for the container
* **EXTERNAL_PORT**: which host port will be used by the service for external connections.

This backup service provides the possibility to upload backups within S3-compliant object storage. The following parameters are available:

* **AWS_ACCESS_KEY_ID**: the access key id needed to access at the object storage.
* **AWS_SECRET_ACCESS_KEY**: the secret key id needed to access at the object storage.
* **BUCKET_REGION**: the AWS Region where your s3 is defined
* **BUCKET_NAME**: the S3 bucket name
* **BUCKET_ENDPOINT**: If your object storage is S3 compliant (so not on AWS, but same API)

## How to use

1. Start the master [`docker-compose`](/db/master/docker-compose.yaml) file.
2. Start the replica [`docker-compose`](/db/replica/docker-compose.yaml) file.

After that if you want to upload the service, start [`docker-compose`](/backup/docker-compose.yaml) placed into [`db`](/db) folder.

After all, if you want to use a minimal database management tool, into the master docker-compose, **adminer** is provided. The service is exposed through the 8080 port (ip is the same of master postgres instance).
