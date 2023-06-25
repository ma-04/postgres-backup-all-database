# postgres-backup-all-database
Backup all postgress databases to separate files with gzip and have a sha256 hash for all the files

## Features
* Backup all databases to separate files
* Compress the files with gzip
* Create a sha256 hash for all the files
* Periodically delete old backups on spanned time
    * Any backup less than 7 days old will be kept
    * Any backup less than 4 weeks old will be kept
    * Any backup "first day of month and is less than a year old" will be kept
    * Rest of the backups will be deleted
        * If you don't want to delete old backups you can safely remove the scripts part that deletes the old backups

## Usage

Create a file with the name `.pgpass` in your home directory with the following content:

```
hostname:port:database:username:password
```

you can use wildcard for the database name and hostname

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
## Restore
To restore the database we can use the following command:
```
gunzip <file>.sql.gz | pg_restore -v --no-owner --host=mydemoserver.postgres.database.azure.com --port=5432 --username=mylogin --dbname=database_name
```
or 
```
cat <file>.sql.gz | gunzip | pg_restore -v --no-owner --host=mydemoserver.postgres.database.azure.com --port=5432 --username=mylogin --dbname=database_name
```