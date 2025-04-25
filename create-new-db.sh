cwd=$(pwd)
PASSWORD=$(pwgen -s 64 1)
admin_user='admin92nx9'
dbname=$1
db_host=postgres
PORT=5432
export PGSSLMODE=prefer

echo "Creating user ${dbname} if it doesn't exist"
psql -U ${admin_user} -h ${db_host} -p $PORT -d postgres -c "SELECT 1 FROM pg_user WHERE usename='${dbname}'" | grep -q 1 || psql -U ${admin_user} -h ${db_host} -p $PORT -d postgres -c "CREATE USER ${dbname} WITH PASSWORD '$PASSWORD'"
echo "${db_host}:${PORT}:${dbname}:${dbname}:${PASSWORD}" >> $cwd/pgpass.conf
echo "${db_host}:${PORT}:${dbname}:${dbname}:${PASSWORD}"

# create new database
echo "Creating Database ${dbname}"
psql -U ${admin_user} -h ${db_host} -p $PORT -d postgres -c "SELECT 1 FROM pg_database WHERE datname='${dbname}'" | grep -q 1 || psql -U ${admin_user} -h ${db_host} -p $PORT -d postgres -c "CREATE DATABASE ${dbname}"


# grant database permissions to the user for the database and set the user as the owner of the database

echo "Granting permissions to user ${dbname} for database ${dbname}"
psql -U ${admin_user} -h ${db_host} -p $PORT -d ${dbname} -c "GRANT ${dbname} TO ${admin_user};"
psql -U ${admin_user} -h ${db_host} -p $PORT -d ${dbname} -c "GRANT ALL ON DATABASE ${dbname} TO ${dbname};"
psql -U ${admin_user} -h ${db_host} -p $PORT -d ${dbname} -c "GRANT ALL PRIVILEGES ON DATABASE ${dbname} TO ${dbname};"
psql -U ${admin_user} -h ${db_host} -p $PORT -d ${dbname} -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${dbname};"
psql -U ${admin_user} -h ${db_host} -p $PORT -d ${dbname} -c "ALTER SCHEMA public OWNER TO ${dbname};"
psql -U ${admin_user} -h ${db_host} -p $PORT -d ${dbname} -c "ALTER DATABASE ${dbname} OWNER TO ${dbname};"
psql -U ${admin_user} -h ${db_host} -p $PORT -d ${dbname} -c "REASSIGN OWNED BY ${admin_user} TO ${dbname};"
psql -U ${admin_user} -h ${db_host} -p $PORT -d ${dbname} -c "REVOKE ALL ON DATABASE ${dbname} FROM PUBLIC;"
psql -U ${admin_user} -h ${db_host} -p $PORT -d ${dbname} -c "REVOKE ALL ON SCHEMA public FROM PUBLIC;"
psql -U ${admin_user} -h ${db_host} -p $PORT -d ${dbname} -c "REVOKE CONNECT ON DATABASE ${dbname} FROM PUBLIC;"
# for future pg_dump backups
psql -U ${admin_user} -h ${db_host} -p $PORT -d ${dbname} -c "GRANT CONNECT ON DATABASE ${dbname} TO ${admin_user};"
psql -U ${admin_user} -h ${db_host} -p $PORT -d ${dbname} -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO ${admin_user}"
psql -U ${admin_user} -h ${db_host} -p $PORT -d ${dbname} -c "GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO ${admin_user};"
