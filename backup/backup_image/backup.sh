#!/bin/bash

# splitting file check configuration and backup script
# note that this script is executed by cron, so you can't use environment variables
# you have to set them in the script
# note that the "croned" script will be not included the .sh extension


# fuction for validate cron expression
# TODO

# check if the backup is full or not: dump or dumpall
if [ -z "$POSTGRES_DB" ]; then
    echo "POSTGRES_DB is not set, exiting"
    exit 1
fi
if [ -z "$MASTER_IP" ]; then
    echo "MASTER_IP is not set, exiting"
    exit 1
fi
if [ -z "$POSTGRES_USER" ]; then
    echo "POSTGRES_USER is not set, exiting"
    exit 1
fi
if [ -z "$POSTGRES_PASSWORD" ]; then
    echo "POSTGRES_PASSWORD is not set, exiting"
    exit 1
fi
if [ -z "$DUMP_OUTPUT_FORMAT" ]; then
    echo "DUMP_OUTPUT_FORMAT is not set, exiting"
    exit 1
fi
if [ -z "$DUMPALL" ]; then
    echo "DUMPALL is not set, exiting"
    exit 1
fi
if [ -z "$PG_PORT" ]; then
    echo "PG_PORT is not set, exiting"
    exit 1
fi
# 'custom' is a format for restore dump with pg_restore
# 'sql' is a format for restore dump with psql. Is a plain text format with sql commands
if [[ ! "$DUMP_OUTPUT_FORMAT" == custom || "$DUMP_OUTPUT_FORMAT" == sql ]]; then
    echo "invalid DUMP_OUTPUT_FORMAT. Only 'custom' or 'sql' are allowed, exiting"
    exit 1
fi
if [[ ! "$DUMPALL" == on || "$DUMPALL" == off ]]; then
    echo "invalid DUMPALL. Only 'on' or 'off' are allowed, exiting"
    exit 1
fi
if [ -z "$DUMP_SCHEDULING" ]; then
    echo "DUMP_SCHEDULING is not set. Default value is 'daily'"
    $DUMP_SCHEDULING=daily
fi



case "$DUMP_SCHEDULING" in 
    "15min" | "hourly" | "daily" | "weekly" | "monthly" | "custom")
        echo "OK. ${DUMP_SCHEDULING} mode"
        ;;
    *)
        echo "invalid DUMP_SCHEDULING. Only, '15min', 'daily', 'hourly', 'monthly', 'weekly' or 'custom' are allowed, exiting"
        exit 1
esac

# necessary for cron
env >> /etc/environment

if [[ "$DUMP_SCHEDULING" == 15min ]]; then
    mv /backup_script/cron_job /etc/periodic/15min/cron_job
    chmod a+x /etc/periodic/15min/cron_job
fi
if [[ "$DUMP_SCHEDULING" == daily ]]; then
    mv /backup_script/cron_job /etc/periodic/daily/cron_job
    chmod a+x /etc/periodic/daily/cron_job
fi
if [[ "$DUMP_SCHEDULING" == hourly ]]; then
    mv /backup_script/cron_job /etc/periodic/hourly/cron_job
    chmod a+x /etc/periodic/hourly/cron_job
fi
if [[ "$DUMP_SCHEDULING" == weekly ]]; then
    mv /backup_script/cron_job /etc/periodic/weekly/cron_job
    chmod a+x /etc/periodic/weekly/cron_job
fi
if [[ "$DUMP_SCHEDULING" == monthly ]]; then
    mv /backup_script/cron_job /etc/periodic/monthly/cron_job
    chmod a+x /etc/periodic/monthly/cron_job
fi

if [[ "$DUMP_SCHEDULING" == custom ]]; then
    if [[ -z "$CUSTOM_CRON_EXPRESSION" ]]; then
        echo "CUSTOM_CRON_SCHEDULE is not set, exiting"
        exit 1
    fi
    
    # if [[ ! validateCronExpression $CUSTOM_CRON_EXPRESSION ]]; then
    #     echo "invalid CUSTOM_CRON_EXPRESSION, exiting"
    #     exit 1
    # fi


    # write into crontab
    mkdir -p /etc/periodic/custom
    mv /backup_script/cron_job /etc/periodic/custom/cron_job
    echo "$CUSTOM_CRON_EXPRESSION run-parts /etc/periodic/custom/" >> /etc/crontabs/root
    chmod a+x /etc/periodic/custom/cron_job

fi


# for passwordless authentication
cat > /.pgpass <<EOF
*:*:*:$POSTGRES_USER:$POSTGRES_PASSWORD
EOF
chmod 600 /.pgpass


# start node-uploader in background if all the required variables are set
if [[ ! -z "$AWS_ACCESS_KEY_ID" && ! -z "$AWS_SECRET_ACCESS_KEY" && ! -z "$BUCKET_REGION" && ! -z "$BUCKET_NAME" ]]; then
    echo "starting node-uploader"
    nohup node /backup_script/node_uploader/dist/index.js > /dev/null 2>&1 &
fi

# to start cron daemon
crond -f -l 8
