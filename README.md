# Seconds Behind Master

This script can be used to determine what is causing a slave to fall behind the master. 

### Setup 
Edit the script record_seconds_behind_master.sh and make changes where desired. 
The default is to save output to database tables. If saving to database tables is your preference, review and run the script rep_hist_schema.sql to create the necessary tables.
```
mariadb < rep_hist_schema.sql
```

The commands in this project are to be run on slave and therefore all SQL scripts that CREATE or INSERT are preceeded with `SET SESSION sql_log_bin = 0;`. This will turn off binary logging to ensure that the changes do not break replication by altering the gtid. 

You can avoid saving to tables by saving to csv files. _If you prefer to save to csv files_, uncomment the line `CSV_OUTPUT=TRUE`.

### Crontab
Run the script from crontab on the host of the slave that you want to monitor. For example, every minute looks like this:
```
* * * * * /root/seconds_behind_master/record_seconds_behind_master.sh 2>/root/seconds_behind_master/crontab.log
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
