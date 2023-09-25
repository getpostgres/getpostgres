#!/bin/bash

# edited by andrea baldinelli
# by default, Async mode is used

# CONFIGURE PRIMARY
if [[ -z $REPLICATE_FROM ]]; then

if [[ -z $POSTGRES_USER ]]; then
   echo "error. postgres user is not defined"
   exit 1
fi

# Create replication user
psql -U ${POSTGRES_USER} -p ${PG_PORT} -d ${POSTGRES_DB} -c "CREATE USER $REPLICA_POSTGRES_USER WITH REPLICATION ENCRYPTED PASSWORD '$REPLICA_POSTGRES_PASSWORD';"

# Add replication settings to primary postgres configuration
cat >> ${PGDATA}/postgresql.conf <<EOF
listen_addresses= '*'
wal_level = replica
max_wal_senders = 10
max_replication_slots = 10
EOF

# Add replication settings to pg_hba.conf
cat >> ${PGDATA}/pg_hba.conf <<EOF
host     replication     ${REPLICA_POSTGRES_USER}   0.0.0.0/0      scram-sha-256
EOF

# Restart postgres and add replication for apply changes configuration
pg_ctl restart -D ${PGDATA} -m fast
pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}


# ====================================================================================================
# CONFIGURE REPLICA
else

# Stop postgres instance and clear out PGDATA
echo "Stopping postgres ${PGDATA}"
pg_ctl stop -D ${PGDATA} -m fast
rm -rf ${PGDATA}

# Backup replica from the primary
until pg_basebackup -h ${REPLICATE_FROM} -p ${PG_PORT} -D ${PGDATA} -U ${POSTGRES_USER} --slot=${REPLICA_NAME}_slot  -C -R --checkpoint=fast --verbose
do
# If docker is starting the containers simultaneously, the backup may encounter
    # the primary amidst a restart. Retry until we can make contact.
    psql -U $POSTGRES_USER -p ${PG_PORT} -h ${REPLICATE_FROM} -d $POSTGRES_DB -c "select pg_drop_replication_slot(slot_name) from pg_replication_slots where slot_name = '${REPLICA_NAME}_slot';"

    sleep 1
    echo "Retrying backup . . ."
done
echo "done"

# Remove pg pass file -- it is not needed after backup is restored
# rm ~/.pgpass.conf

# Create the file so the backup knows to start in recovery mode
cat > ${PGDATA}/postgresql.auto.conf <<EOF
primary_conninfo = 'host=${REPLICATE_FROM} port=${PG_PORT} user=${POSTGRES_USER} password=${POSTGRES_PASSWORD}'
primary_slot_name = '${REPLICA_NAME}_slot'
EOF
# restore_command = 'cp /var/lib/postgresql/replica/pg_wal/%f "%p"'

# Ensure proper permissions on recovery.conf
#chown postgres:postgres ${PGDATA}/../replica/postgresql.auto.conf
#chmod 0600 ${PGDATA}/../replica/postgresql.auto.conf


pg_ctl start -D ${PGDATA}
pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}

fi