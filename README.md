# Seconds Behind Master

### Download
To download Mariadb Seconds Behind Master script to your linux server, you may use git or wget:

```
git clone https://github.com/mariadb-edwardstoever/seconds_behind_master.git
```

```
wget https://github.com/mariadb-edwardstoever/seconds_behind_master/archive/refs/heads/main.zip
```


### Purpose

This script can be used to record what is causing a slave to fall behind the master. This project is essentially a simple bash script that is to be run on the slave via crontab.

This project was created and tested using the system account root. The database user root@localhost exists and has the typical grants:
```
GRANT ALL PRIVILEGES ON *.* TO `root`@`localhost` IDENTIFIED ...
```
It may be possible to adjust the script to run by a different system user and different database account although it is not recommended.



### Setup 
Edit the script record_seconds_behind_master.sh and make changes where desired. 
The default is to save output to database tables. If saving to database tables is your preference, review and run the script rep_hist_schema.sql to create the necessary tables.
```
mariadb < rep_hist_schema.sql
```

The commands in this project are to be run on the slave and therefore all SQL scripts that change anything are preceeded with `SET SESSION sql_log_bin = 0;`. This will turn off binary logging to ensure that replication is not broken by altering the gtid. 

You can avoid creating the tables and saving to the tables by saving to csv files. _If you prefer to save to csv files_, uncomment the line `CSV_OUTPUT=TRUE`.

### Crontab
Run the script from crontab on the host of the slave that you want to monitor. For example, every minute looks like this:
```
* * * * * /root/seconds_behind_master/record_seconds_behind_master.sh 2>>/tmp/seconds_behind_master_crontab.log
```
Or if you prefer, every other minute looks like this:
```
*/2 * * * * /root/seconds_behind_master/record_seconds_behind_master.sh 2>>/tmp/seconds_behind_master_crontab.log
```

### Sharing results with Mariadb Support

If you want to share the data collected to tables, use mariadb-dump, then compress:
```
mariadb-dump rep_hist > /tmp/rep_hist.sql
gzip /tmp/rep_hist.sql
```
Attach the resulting file to your support ticket.

---

If you want to share the data collected in CSV files, use tar with compresssion. For example:
```
tar -czvf rep_hist.tar.gz /tmp/rep_hist
```
Attach the resulting file to your support ticket.

### Truncating the tables

If you are saving to tables, and you want to start over, you can truncate the tables in the rep_hist schema:
```
mariadb < truncate_rep_hist_tables.sql
```

### Disabling the script and dropping the schema
When you are finished using this project, you should remove the entry in crontab and drop the tables.
```
mariadb < drop_rep_hist_schema.sql
```
