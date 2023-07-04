#!/usr/bin/env bash

#set -x
set -e
source env.conf
temp_dir="restore/tmp"

mkdir -p "${temp_dir}"

# This will restore all databases from the latest backup directory to a single database server, make sure you have enough space for all the databases
# restoring to multiple servers is not supported at this time

# Check for the latest backup directory
latest_backup=$(ls -t "${backup_dir}" | head -n1)

# Check if the latest backup directory is empty
if [[ -z "${latest_backup}" ]]; then
    echo "No backups found in ${backup_dir}"
    exit 1
fi

# copy all latest backup files from backup directory to the temp directory
find "${backup_dir}"/"${latest_backup}" -type f -exec cp {} "${temp_dir}"/ \;

cd "${temp_dir}"

# check if all backups match their checksums
for backup_hash in *.sha256; do
    if ! sha256sum -c "${backup_hash}"; then
        echo "Checksum failed for ${backup_hash}, exiting..."
        exit 1
    fi
done

# remove all checksum files
echo "Removing checksum files from ${temp_dir}"
echo "Press enter to continue"
read
rm -rf *.sha256

# restore all databases from the temp directory
for backup in *.sql.gz; do
    echo "Restoring ${backup}"
    gunzip -c "${backup}" | psql "sslmode=prefer host=${hostname_list[0]} port=${port} dbname=${backup%%-*} user=${db_user}"
done