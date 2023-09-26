# GetPostgres Scripts

## Table of Contents

- [A Step Back: What is GetPostgres?](#a-step-back-what-is-getpostgres)
- [Introduction](#introduction)
- [Setup](#setup)
  - [1. Postgres Streaming Replication](#1-postgres-streaming-replication)
    - [1.1 Master Setup](#11-master-setup)
    - [1.2 Setup Replica](#12-setup-replica)
  - [2. Postgres Automatic Backup](#2-postgres-automatic-backup)
- [How to Use](#how-to-use)

## A step back: what is GetPostgres?

<div style="display: flex; align-items: center;">
  <img src="assets/img/justmine-logo-colored.png" width="120" />
  <div>
    <p>Welcome to GetPostgres, your solution for deploying and managing a robust and secure database service in complete privacy.</p>
    <p>You have two options: you can take the DIY approach, managing it yourself, or visit <a href="https://getpostgres.com">GetPostgres.com</a>, where we'll handle all the technical details for you, ensuring a seamless experience.</p>
    <p>At GetPostgres, we embrace the open-source philosophy. We believe in transparency, collaboration, and innovation. Join us in a community that values these principles.</p>
  </div>
</div>

## Introduction

Within this repository, you will discover collection of scripts and Docker files meticulously crafted by the GetPostgres team. These resources empower you to effortlessly establish a fully operational streaming-replication PostgreSQL instance, complete with automated backup capabilities.

Should you wish to take the helm and deploy our service on your own machines, follow the comprehensive guide provided.

**Please Note**: This guide elucidates the process of configuring the service on two separate machines, ideal for scenarios requiring a database replica. However, you are welcome to opt for a single machine setup if it better suits your requirements.

## Setup

### 1. Postgres Streaming Replication

In this section it is explained how to setup streaming replication between two postgres instances.

#### 1.1 Master Setup

The only steps needed to launch the 'master' postgres instance (*the read and write one*) are:

1) edit the `.env` file placed into [db/master](/db/master/) folder
2) and the `master.env` file placed into [db/master](/db/master/) folder

The [`.env`](/db/master/.env) file contains only two configuration parameters:

- **TZ**: sets the container timezone
- **PORT**: sets the exteral container port (*host port*)

The [`master.env`](/db/master/master.env) file contains all postgres configuration parameters:

- **POSTGRES_USER**: the default db user name. It is recommended to use a different name than `postgres`.
- **POSTGRES_PASSWORD**: the default db password.
- **POSTGRES_DB**: the default db name. As said above, it is recomended to write a different name than `postgres`.
- **REPLICA_POSTGRES_USER**: the user name used for replication
- **REPLICA_POSTGRES_PASSWORD**: the password used for replication

 > **pay attention**: `REPLICA_POSTGRES_USER` and `REPLICA_POSTGRES_PASSWORD` must be the credentials of the default user in the replica instance!

- **PGDATA**: the path where the postgres instance will save files into inside the container. It is recommended to use the default value `/var/lib/postgresql/data`.

- **REPLICA_NAME**: the name used by postgres to link "master" and "replica" postgres instances. `replica_slot` is recommended.

- **PG_PORT**: the internal port used for postgres connections (container port)

#### 1.2 Setup Replica

As described for the master instance, all configuration parameters are defined into `.env` (same name, but a different file placed into different folders) and `replica.env` stored into the [db/replica](/db/replica/) folder.

The parameters into the [`.env`](/db/replica/.env) file are the same as described before.

[`replica.env`](/db/replica/replica.env) contains the following parameters:

- **POSTGRES_USER**: the replication user name defined into the master instance.

- **POSTGRES_PASSWORD**: the replication password defined into the master instance.

- **POSTGRES_DB**: the postgres db name defined into the master container.

 > **pay attention**: all databases defined into the postgres master instance will be replicated into the postgres replica instance, not only the main `POSTGRES_DB`, but you need to specify only one.

- **PGDATA**: the path where the postgres instance will save files into inside the container. It is recommended to use the default value `/var/lib/postgresql/data/replica`.

  > **pay attention**: the path is different from the master one

- **REPLICA_NAME**: the `REPLICA_NAME` defined into [master.env](/db/master/master.env)

- **REPLICATE_FROM**: the ip address where the master instance is running.

- **PG_PORT**: the external port of the master instance, defined into the `.env` file (into the `/master` folder)

### 2. Postgres Automatic Backup

In this section, we'll describe the backup functionality of the service. This step should be executed after the PostgreSQL replication deployment is completed. All configuration parameters are stored in an [`.env`](/backup/.env) file located in the [backup](/backup/) folder.

## Postgres Automatic Backup

In this section, we'll describe the backup functionality of the service. This step should be executed after the PostgreSQL replication deployment is completed. All configuration parameters are stored in an `.env` file located in the backup folder.

### Backup Configuration Parameters

The backup service provides the following configuration parameters:

- **MASTER_IP:** The IP address of the PostgreSQL "master" instance.
- **BACKUP_FOLDER:** The absolute path (inside the container) where backup files will be stored. It is recommended to use `/backup_data`.
- **DUMP_SCHEDULING:** Choose from options like `15min`, `hourly`, `daily`, `weekly`, `monthly`, or `custom` to set the cron scheduling interval for database backups. If you select `custom`, you must set the `CUSTOM_CRON_EXPRESSION` environment variable with a valid cron rule following the `* * * * *` template.
- **CUSTOM_CRON_EXPRESSION:** This variable is used only when `DUMP_SCHEDULING` is set to `custom`.
- **PG_PORT:** The TCP port used to connect to the master instance host. It must match the value defined in `master.env`.
- **POSTGRES_USER:** The username of the "master" PostgreSQL user defined in the master instance.
- **POSTGRES_PASSWORD:** The password of the "master" PostgreSQL user defined in the master instance.
- **DUMPALL:** Choose between 'on' and 'off'. If set to 'on', the backup will include all databases defined in the PostgreSQL instance. If 'off', only the database defined in `POSTGRES_DB` will be dumped.
- **POSTGRES_DB:** The default database defined in the PostgreSQL master instance. If `DUMPALL` is 'off', only this database will be dumped.
- **DUMP_OUTPUT_FORMAT:** Choose between 'custom' and 'sql'. If 'custom', the output file will be in a format specified for the `pg_restore` software. If 'sql', the output file will be a plain `.sql` file.
- **TZ:** Set the timezone for the container.
- **EXTERNAL_PORT:** The host port used by the service for external connections.

### Uploading Backups to S3-Compliant Object Storage

This backup service also provides the option to upload backups to S3-compliant object storage. To use this feature, configure the following parameters:

- **AWS_ACCESS_KEY_ID:** The access key ID required for accessing the object storage.
- **AWS_SECRET_ACCESS_KEY:** The secret key ID required for accessing the object storage.
- **BUCKET_REGION:** The AWS Region where your S3 bucket is defined.
- **BUCKET_NAME:** The name of the S3 bucket.
- **BUCKET_ENDPOINT:** Use this if your object storage is S3 compliant but not hosted on AWS (same API).

## How to Use

Follow these steps to set up and use the database:

1. Start the master database:
    - Open the [`docker-compose.yaml`](/db/master/docker-compose.yaml) file.
    - Run `docker-compose up` in the same directory to start the master PostgreSQL instance.

2. Start the replica database:
    - Open the [`docker-compose.yaml`](/db/replica/docker-compose.yaml) file.
    - Run `docker-compose up` in the same directory to start the replica PostgreSQL instance.

3. To back up your database, use the following steps:
    - Navigate to the [`db`](/db) folder.
    - Open the [`docker-compose.yaml`](/backup/docker-compose.yaml) file.
    - Run `docker-compose up` to start the backup service.

4. If you need a minimal database management tool, you can use **Adminer**, which is included in the master database Docker Compose configuration:
    - Access Adminer through port 8080 (the IP address is the same as the master PostgreSQL instance).

This sequence of steps will help you set up and manage your PostgreSQL databases effectively.
