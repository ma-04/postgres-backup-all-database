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
cwd=$(pwd)

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
    dbname=${backup%%-*}
    # create a new user for the database with the same name as the database and create a random 32 character password and save it to file pgpass.conf
    if [ "${create_user}" = true ]; then
        PASSWORD=$(pwgen -s 64 1)
        echo "Creating user ${dbname} if it doesn't exist"
        psql -U ${restore_admin_user} -h ${restore_host} -p $PORT -d postgres -c "SELECT 1 FROM pg_user WHERE usename='${dbname}'" | grep -q 1 || psql -U ${restore_admin_user} -h ${restore_host} -p $PORT -d postgres -c "CREATE USER ${dbname} WITH PASSWORD '$PASSWORD'"
        echo "${restore_host}:${PORT}:${dbname}:${dbname}:${PASSWORD}" >> $cwd/pgpass.conf
    fi
    gunzip -c "${backup}" | pg_restore -v --no-owner --no-acl --create --port=$PORT --host=${restore_host} --dbname=postgres --username=${restore_admin_user}

    # grant database permissions to the user for the database and set the user as the owner of the database
    if [ "${grant_permissions}" = true ] && [ "${create_user}" = true ]; then
        echo "Granting permissions to user ${dbname} for database ${dbname}"
        psql -U ${restore_admin_user} -h ${restore_host} -p $PORT -d ${dbname} -c "GRANT ${dbname} TO ${restore_admin_user};"
        psql -U ${restore_admin_user} -h ${restore_host} -p $PORT -d ${dbname} -c "GRANT ALL ON DATABASE ${dbname} TO ${dbname};"
        psql -U ${restore_admin_user} -h ${restore_host} -p $PORT -d ${dbname} -c "GRANT ALL PRIVILEGES ON DATABASE ${dbname} TO ${dbname};"
        psql -U ${restore_admin_user} -h ${restore_host} -p $PORT -d ${dbname} -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${dbname};"
        psql -U ${restore_admin_user} -h ${restore_host} -p $PORT -d ${dbname} -c "ALTER SCHEMA public OWNER TO ${dbname};"
        psql -U ${restore_admin_user} -h ${restore_host} -p $PORT -d ${dbname} -c "ALTER DATABASE ${dbname} OWNER TO ${dbname};"
        psql -U ${restore_admin_user} -h ${restore_host} -p $PORT -d ${dbname} -c "REASSIGN OWNED BY ${restore_admin_user} TO ${dbname};"
        # for future pg_dump backups
        psql -U ${restore_admin_user} -h ${dbname} -p $PORT -d ${dbname} -c "GRANT CONNECT ON DATABASE ${dbname} TO ${restore_admin_user};"
        psql -U ${restore_admin_user} -h ${dbname} -p $PORT -d ${dbname} -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO ${restore_admin_user}"
        psql -U ${restore_admin_user} -h ${dbname} -p $PORT -d ${dbname} -c "GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO ${restore_admin_user};"
    fi

done
