# this image is used to inject a script into postgres vanilla image
# the script is used to enable replication on the database
FROM postgres:15.3-bullseye

# the script is copied to the docker-entrypoint-initdb.d/ folder.
# every .sql or .sh file in this folder is executed when the container is created
ADD replication.sh /docker-entrypoint-initdb.d/