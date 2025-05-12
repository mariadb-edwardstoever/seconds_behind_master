#!/bin/bash
# Created by Edward Stoever for MariaDB Support
# Use as a template to get data from CSV file into a table so it can be selected.

# echo "Edit this file before running."; exit 0; # Edit the file changing the value for CSV_FILE, remove this line.

CSV_FILE=/tmp/hostname_seconds_behind_master.csv
CSV_FILE=/tmp/rep_hist/alone11_seconds_behind_master.csv

SQL="SET SESSION sql_log_bin = 0;

CREATE SCHEMA IF NOT EXISTS rep_hist;
USE rep_hist;
CREATE TABLE replica_history (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  tick timestamp NOT NULL DEFAULT current_timestamp(),
  hostname varchar(128) DEFAULT NULL,
  mariadbd_cpu_pct decimal(5,2) DEFAULT NULL,
  seconds_behind_master int(11) DEFAULT NULL,
  gtid_binlog_pos varchar(200) DEFAULT NULL,
  gtid_current_pos varchar(200) DEFAULT NULL,
  gtid_slave_pos varchar(200) DEFAULT NULL,
  gtid_io_pos varchar(200) DEFAULT NULL,
  slave_sql_running_state varchar(500) DEFAULT NULL,
  handler_read_rnd_next bigint(20) DEFAULT NULL,
  relay_log_file varchar(200) DEFAULT NULL,
  relay_log_pos varchar(200) DEFAULT NULL,
  threads_created int(11) DEFAULT NULL,
  threads_connected int(11) DEFAULT NULL,
  threads_running int(11) DEFAULT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB CHARSET=utf8mb4;

LOAD DATA LOCAL INFILE '$CSV_FILE' INTO TABLE replica_history FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\n';
"
mariadb -ABNe "$SQL";
