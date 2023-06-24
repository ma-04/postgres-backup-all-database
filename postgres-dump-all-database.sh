#!/usr/bin/env bash

set -x

backup_dir="backups/postgres"
db_backup="backups/postgres/dumps-$(date -I)"
db_user="ny9"
hostname=localhost
port=5432
#export PGPASSWORD="asfdsd"
# use export PGPASSWORD="asfdsd" if you want to use password in this script, alternatively you can use .pgpass file
# https://www.postgresql.org/docs/9.3/libpq-pgpass.html
# format for .pgpass file is hostname:port:database:username:password (no spaces) and place it in home directory of user running this script
excluded_databases="template0|template1|azure*|postgres"
# database to exclude from backup, format it with | as separator, example: "template0|template1|azure*|postgres"
# can accept regex, can be empty

mkdir -p "$db_backup"

for db in $(psql "sslmode=require host=$hostname port=$port dbname=postgres user=$db_user" -t -c "select datname from pg_database where not datistemplate" | grep '\S' | awk '{$1=$1};1' | grep -vE $excluded_databases); do
    echo "Backing up $db"
    pg_dump "sslmode=require host=$hostname port=5432 dbname=$db user=$db_user" | gzip > "$db_backup/$db-$(date -I).sql.gz"
    sha256sum "$db_backup/$db-$(date -I).sql.gz" | sed 's, .*/,  ,' > "$db_backup/$db-$(date -I).sql.gz.sha256"
    #pg_dump "sslmode=require host=$hostname port=5432 dbname=$db user=$db_user" | gzip > "$db_backup/$db-$(date -I).sql.gz"
done

list_of_backups=$(ls -l "${backup_dir}" | grep -oE "[0-9]{4}-[0-9]{2}-[0-9]{2}$")

for backup in "${list_of_backups[@]}"; do
    if [[ "${backup}" > $(date -I -d "7 days ago") ]]; then
        echo "${backup} is backup from last 7 days, keeping it"
    elif
        [[ $(date -d "${backup}" +%u) == 4 && "${backup}" > $(date -I -d "1 month ago") ]]; then
        echo "${backup} was Thursday and is less than a month old, keeping it"
    elif
        [[ $(date -d "${backup}" +%d) == 01 && "${backup}" > $(date -I -d "1 year ago") ]]; then
        echo "${backup} was first day of month and is less than a year old, keeping it"
    else
        rm -rf "${backup_dir}"/dumps-"${backup}"
    fi
done