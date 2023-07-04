#!/usr/bin/env bash

#set -x
set -e
source env.conf

mkdir -p "$db_backup"

for hostname in "${hostname_list[@]}"; do
    echo "Backing up databases from $hostname"
    mkdir -p "$db_backup/$hostname"
    for db in $(psql "sslmode=require host=$hostname port=$port dbname=postgres user=$db_user" -t -c "select datname from pg_database where not datistemplate" | grep '\S' | awk '{$1=$1};1' | grep -vE $excluded_databases); do
        echo "$hostname : Backing up $db"
        # grant database access to the user running this script to the database to be backed up
        # This is a just in case measure, if the user running this script does not have access to the database, the backup script will fail
        psql "sslmode=prefer host=$hostname port=$port dbname=$db user=$db_user" -c "GRANT CONNECT ON DATABASE $db TO $db_user" 1>/dev/null
        psql "sslmode=prefer host=$hostname port=$port dbname=$db user=$db_user" -c "GRANT USAGE ON SCHEMA public TO $db_user" 1>/dev/null
        psql "sslmode=prefer host=$hostname port=$port dbname=$db user=$db_user" -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO $db_user" 1>/dev/null

        if ! pg_dump -Fc "sslmode=prefer host=$hostname port=5432 dbname=$db user=$db_user" | gzip > "$db_backup/$hostname/$db-$(date -I).sql.gz"; then
            echo "pg_dump failed due to a permission error. Exiting..."
            exit 1
        fi

        sha256sum "$db_backup/$hostname/$db-$(date -I).sql.gz" | sed 's, .*/,  ,' > "$db_backup/$hostname/$db-$(date -I).sql.gz.sha256"
        #pg_dump "sslmode=require host=$hostname port=5432 dbname=$db user=$db_user" | gzip > "$db_backup/$hostname/$db-$(date -I).sql.gz"
    done
done


# The following will remove backups older than 7 days, except for Thursday backups from last month and first day of month backups from last year
# remove backups older than 7 days, except for Thursday backups from last month and first day of month backups from last year
# Can be safely removed if you don't want to remove old backups
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