# postgres-backup-all-database
Backup all postgress databases to separate files with gzip and have a sha256 hash for all the files

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
To restore the database you have to gunzip the file and then run the following command:
```
gunzip <file>.sql.gz
```
Then you can run the following command to restore the database:
```
pg_restore -h <host> -p <port> -U <user> -d <database> <file>.sql
```