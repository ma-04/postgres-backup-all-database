# postgres-backup-all-database
Backup all postgress databases to separate files with gzip and have a sha256 hash for all the files. 

Note that this user must have access to all databases to be backed up.
## Features
* Backup all databases to separate files
* Backup Multiple databases on multiple servers
* Compress the files with gzip
* Create a sha256 hash for all the files
* Periodically delete old backups on spanned time by setting ``keep_old_backups`` to `false` in `env.conf`
    * Any backup less than 7 days old will be kept
    * Any backup less than 4 weeks old will be kept
    * Any backup "first day of month and is less than a year old" will be kept
    * Rest of the backups will be deleted

## Usage

Create a file with the name `.pgpass` in your home directory with the following content:

```
hostname:port:database:username:password
```
you can use wildcard for the database name and hostname(eg. `*:*:*:username:password`)

then you have to change the permissions of the file with the following command:

```
chmod 0600 ~/.pgpass
```

Copy the `example.env.conf` file to `env.conf` with the following command:
```bash
cp example.env.conf env.conf
```
After that you have to update variables in `env.conf` to match your needs

### Variables
* `BACKUP_DIR` : The directory where the backups will be stored (Required) (Restore only)
* `db_backup` : For database backup, and formats for hosts (Required) (Backup only)
* `DB_USER` : The username of the database (Required) (Backup only)
* `hostname_list` : The hostname of the database (Required), can be 1 host or multiple hosts separated by space. (eg. `DB_HOST="host1" "host2" host3"`) (Backup only)
* `PORT` : The port of the database (Required). MUST also be specified in `.pgpass` file (Backup and Restore)
* `excluded_databases` : The databases that you don't want to backup (Optional). Can be 1 database or multiple databases separated by space. (eg. `excluded_databases="database1" "database2" "database3"`) (Backup And restore)

* `restore_host` : The hostname of the database that you want to restore to. Currently only supports 1 host. (eg. `restore_host="host1"`) (Restore only)
* `restore_admin_user` : The Admin/root username of the restore target that you want to restore to. Currently only supports 1 user. (eg. `restore_admin_user="username"`)   (Restore only)
* `create_user` : A new user will be created for every database with the same name as the database with full permissions for the database, for best result pair it with `grant_permissions`. (Optional) (Restore only)
* `grant_permissions` : The permissions that the new user will have. Also removes the database permission from other users and public. (Optional) (Restore only)

After that you can run the script with the following command:

```
./backup.sh
```

or you can put it in a cron job for daily backups (default), if u change the backup frequency you have to change the name of the backup file to include the date and time of the backup.
Suggested cron job:

```
0 0 * * * /path/to/backup.sh
```
Suggested Reading: 
* [Migrate Using Pg_dump and pg_restore](https://learn.microsoft.com/en-us/azure/postgresql/migrate/how-to-migrate-using-dump-and-restore)
* [Best practices for pg_dump and pg_restore ](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/how-to-pgdump-restore)
* [Backup and Restore](https://www.postgresql.org/docs/9.5/backup-dump.html)
* [Pg_dump](https://www.postgresql.org/docs/current/app-pgdump.html)
## Restore
To restore the database we can use the following command:
```
gunzip <file>.sql.gz | pg_restore -v --no-owner --host=mydemoserver.postgres.database.azure.com --port=5432 --username=mylogin --dbname=database_name
```
or 
```
cat <file>.sql.gz | gunzip | pg_restore -v --no-owner --host=mydemoserver.postgres.database.azure.com --port=5432 --username=mylogin --dbname=database_name
```
For further reading:
* [Backup and Restoring Large dump](https://www.postgresql.org/docs/9.5/backup-dump.html#BACKUP-DUMP-LARGE)

Inspired by:
* [postgres-backup-s3 ](https://github.com/eeshugerman/postgres-backup-s3)