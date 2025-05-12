#!/bin/bash
# Created by Edward Stoever for MariaDB Support
# Use as a template to get data from CSV file into a table so it can be selected.

echo "Edit this file before running."; exit 0; # Edit the file where necessary, remove this line.

CSV_DIRECTORY=/tmp/rep_hist

SQL="SET SESSION sql_log_bin = 0;
CREATE SCHEMA IF NOT EXISTS rep_hist;
USE rep_hist;

CREATE TABLE processlist_history (
  rh_id int(11) DEFAULT NULL,
  tick timestamp NOT NULL DEFAULT current_timestamp(),
  hostname varchar(128) DEFAULT NULL,
  db varchar(64) DEFAULT NULL,
  command varchar(16) DEFAULT NULL,
  state varchar(64) DEFAULT NULL,
  info longtext NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;"


mariadb -ABNe "$SQL";

# EXAMPLE OF defaults_file with name processlist.tsv.cnf (commented out)

# [mariadb-import]
# fields-optionally-enclosed-by = '"'
# fields-terminated-by = '\t'
# lines-terminated-by = '\n'
# fields-escaped-by = '\\'
# columns = 'rh_id,tick,hostname,db,command,state,info'


cp processlist.tsv.cnf /tmp/
chmod 664 /tmp/processlist.tsv.cnf

# You will have multiple files with names like db1_processlist_1741681682_001.csv

# This will search for files in $CSV_DIRECTORY with names like *processlist*.csv
find $CSV_DIRECTORY -name "*processlist*.csv" -type f | sort | while read f; do
    echo "processing $f"; 
    cp $f /tmp/processlist_history.csv
    chmod 664 /tmp/processlist_history.csv
    mariadb-import --defaults-file=/tmp/processlist.tsv.cnf rep_hist /tmp/processlist_history.csv
done

rm -f /tmp/processlist.tsv.cnf 
rm -f /tmp/processlist_history.csv
