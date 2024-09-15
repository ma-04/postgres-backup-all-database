#!/usr/bin/env bash

#set -x
set -e
source env.conf
export PGSSLMODE=prefer

mkdir -p "$db_backup"

for hostname in "${hostname_list[@]}"; do
    echo "Backing up databases from $hostname"
    mkdir -p "$db_backup/$hostname"
    for db in $(psql "host=$hostname dbname=postgres user=$db_user" -t -c "select datname from pg_database where not datistemplate" | grep '\S' | awk '{$1=$1};1' | grep -vE $excluded_databases); do
        echo "$hostname : Backing up $db"
        # grant database access to the user running this script to the database to be backed up
        # This is a just in case measure, if the user running this script does not have access to the database, the backup script will fail
	echo "$hostname : Requesting permission for $db"
        psql "host=$hostname dbname=$db user=$db_user" -c "GRANT CONNECT ON DATABASE $db TO $db_user" 2> errors.log
        psql "host=$hostname dbname=$db user=$db_user" -c "GRANT USAGE ON SCHEMA public TO $db_user" 2> errors.log
        psql "host=$hostname dbname=$db user=$db_user" -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO $db_user" 2> errors.log
        psql "host=$hostname dbname=$db user=$db_user" -c "GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO $db_user" 2> errors.log
        if ! pg_dump -Fc -O --no-privileges --no-owner "host=$hostname dbname=$db user=$db_user" | gzip > "$db_backup/$hostname/$db-$(date -I).sql.gz"; then
            echo "pg_dump failed due to a permission error. Exiting..."
            exit 1
        fi

        sha256sum "$db_backup/$hostname/$db-$(date -I).sql.gz" | sed 's, .*/,  ,' > "$db_backup/$hostname/$db-$(date -I).sql.gz.sha256"
        #pg_dump "sslmode=require host=$hostname port=5432 dbname=$db user=$db_user" | gzip > "$db_backup/$hostname/$db-$(date -I).sql.gz"
    done
done


# The following will remove backups older than 7 days, except for Thursday backups from last month and first day of month backups from last year
# Can be safely removed if you don't want to remove old backups

if [ "$keep_old_backups" = false ]; then
    # Find all backup files and extract dates
    list_of_backups=($(find "${backup_dir}" -type f -name "dumps-*" | grep -oE "[0-9]{4}-[0-9]{2}-[0-9]{2}$"))

    for backup in "${list_of_backups[@]}"; do
        backup_date=$(date -d "${backup}" +%Y-%m-%d)
        
        # Check if the backup is from the last 7 days
        if [[ "${backup_date}" > $(date -I -d "7 days ago") ]]; then
            echo "${backup} is backup from last 7 days, keeping it"
        
        # Check if the backup is a Thursday backup from the last month
        elif [[ $(date -d "${backup_date}" +%u) -eq 4 && "${backup_date}" > $(date -I -d "1 month ago") ]]; then
            echo "${backup} was Thursday and is less than a month old, keeping it"
        
        # Check if the backup is from the first day of the month in the last year
        elif [[ $(date -d "${backup_date}" +%d) -eq 01 && "${backup_date}" > $(date -I -d "1 year ago") ]]; then
            echo "${backup} was first day of month and is less than a year old, keeping it"
        
        # Remove old backups
        else
            rm -rf "${backup_dir}/dumps-${backup}"
            echo "Removed old backup: ${backup}"
        fi
    done
else
    echo "Not removing old backups"
fi