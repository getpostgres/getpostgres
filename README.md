# GetPostgres Scripts

## A step back: what is GetPostgres?

GetPostgres is a private beta platform for deploying and managing complete and rock-solid database services.
Our business principles are devoted to *open-source philosophy*.

## Introduction

In this repo you can find all the scripts and Docker files used by GetPostgres team to setup a fully usable streaming-replication postgres instance with automatic backup.

If you want to deploy our service by yourself on your machines, please continue to follow this guide.

**NOTE**: this guide explains how to setup the service by using two distinct machine, that's because it's a classic replicaton use case. You're free to use just a single machine, if that fits better your needs.

## Setup

### 1. Postgres Streaming Replication

In this section are explained how to setup streaming replication between two postgres instances.

#### 1.1 Setup Master


All setup needed to launch the 'master' postgres instance (*the read and write one*) is to edit two .env file: `.env` and `master.env` placed into [db/master](/db/master/) folder.

The [`.env`](/db/master/.env) file contain only two configuration parameters:

* **TZ**: sets the container timezone
* **PORT**: sets the exteral container port (*host port*)

The [`master.env`](/db/master/master.env) file contain all postgres configuration parameters:

* **POSTGRES_USER**: the default db user name. Is recommended to use a name different to `postgres`.
* **POSTGRES_PASSWORD**: the default db user password.
* **POSTGRES_DB**: the default db. As above, is recomended to write a different name than `postgres`.
* **REPLICA_POSTGRES_USER**: the user name used only for replication
* **REPLICA_POSTGRES_PASSWORD**: the user password used only for replication

 > **pay attention**: `REPLICA_POSTGRES_USER` and `REPLICA_POSTGRES_PASSWORD` must be the credentials of default user in replica instance!

* **PGDATA**: path where will be created postgres instance into container file system. Is recommended to use the default value `/var/lib/postgresql/data`.

* **REPLICA_NAME**: the name used by postgres to link "master" and "replica" postgres instance. `replica_slot` is recommended.

* **PG_PORT**: the internal port used for postgres connections (container port)

#### 1.2 Setup Replica

As described for master instance, all configuration parameters are defined into `.env` (same name, but different files placed into different folders) and `replica.env` stored into [db/replica](/db/replica/) folder.

The parameters into [`.env`](/db/replica/.env) file are the same described before.

Into [`replica.env`](/db/replica/replica.env) contains the following parameters:

* **POSTGRES_USER**: the replication user name defined into master instance.

* **POSTGRES_PASSWORD**: the replication user password defined into master instance.

* **POSTGRES_DB**: the postgres db name defined into master.

 > **pay attention**: all databases defined into postgres master instance will be replicated into postgres replica instance, not only `POSTGRES_DB`. It's necessary for login requirements.

* **PGDATA**: path where will be created postgres instance into container file system. Is recommended to use the default value `/var/lib/postgresql/data/replica`.

* **REPLICA_NAME**: the `REPLICA_NAME` defined into [master.env](/db/master/master.env)

* **REPLICATE_FROM**: the ip address where master instance is running.

* **PG_PORT**: the external port of master instance, defined into `.env` file (into `/master` folder)

### 2. Postgres Automatic Backup

In this section is described the backup part of the service and must be execute after postgres replication deployed is completed.
As seen above all configura parameters are included into an [`.env`](/backup/.env) file placed into [backup](/backup/) folder.

The backup service provide the following configuration parameter:

* **MASTER_IP**: ip of the postgres "master" instance
* **BACKUP_FOLDER**: absolute path where store, into container, the file backup. Recomended to use `/backup_data` as write into file.
* **DUMP_SCHEDULING**: choose between `15min` `hourly` `daily` `weekly` `monthly` `custom` for set cron scheduling for backup db. If you wanna use `custom` option, you must set `CUSTOM_CON_EXPRESSION` with a valid cron rule write as string.
* **CUSTOM_CRON_EXPRESSION**: as described in previous bullet is used only when `DUMP_SCHEDULING` parameter value is `custom`.
* **PG_PORT**: tcp port used to connect with master instance host. Must be the same defined into [`master.env`](/db/master/master.env).
* **POSTGRES_USER**: the "master" postgres user name defined into master instance.
* **POSTGRES_PASSWORD**: the "master" postgres user password defined into master instance.
* **DUMPALL**: choose between 'on' and 'off'. If on backup will include all databases defined into postgres instance.
* **POSTGRES_DB**: the default db defined into postgres master instance. If dumpall off, will be dumped only database defined `POSTGRES_DB`.
* **DUMP_OUTPUT_FORMAT**: choose between 'custom' and 'sql'. custom is a format specified for pg_restore software. If 'sql' the output file will be a "simply" plain `.sql` file.
* **TZ**: Set timezone for container
* **EXTERNAL_PORT**: which host port will use by service to external connections.

This backup service provide the possibility to upload backups within S3-compliant object storage. The following parameters are useful for this:

* **AWS_ACCESS_KEY_ID**: access key id needed to access at the object storage.
* **AWS_SECRET_ACCESS_KEY**: secret key id needed to access at the object storage.
* **BUCKET_REGION**: AWS Region where your s3 is defined
* **BUCKET_NAME**: S3 bucket name
* **BUCKET_ENDPOINT**: If your object storage is S3 compliant (so not AWS )

## How to use

1. Start master [`docker-compose`](/db/master/docker-compose.yaml) file.
2. Start replica [`docker-compose`](/db/replica/docker-compose.yaml) file.

After that if you want upload service, start [`docker-compose`](/backup/docker-compose.yaml) placed into [`db`](/db) folder.

After all, if you want use a minimal database management tool, into master docker-compose is provided **adminer**. The service is exposed through 8080 port (ip is the same of master postgres instance).
