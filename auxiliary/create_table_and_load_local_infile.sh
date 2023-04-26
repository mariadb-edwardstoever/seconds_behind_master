#!/bin/bash
# Created by Edward Stoever for MariaDB Support
# Use as a template to get data from CSV file into a table so it can be selected.

echo "Edit this file before running."; exit 0;

CSV_FILE=/tmp/hostname_seconds_behind_master.csv

SQL="SET SESSION sql_log_bin = 0;

CREATE SCHEMA if not exists rep_hist;
use rep_hist;

drop table if exists replica_history;
CREATE TABLE replica_history (
    id INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
    tick TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    hostname VARCHAR(128) NULL DEFAULT NULL,
    mariadbd_cpu_pct DECIMAL(5,2) NULL DEFAULT NULL,
    seconds_behind_master int,
    gtid_binlog_pos VARCHAR(200) NOT NULL,
    gtid_current_pos VARCHAR(200) NOT NULL,
    gtid_slave_pos VARCHAR(200) NOT NULL,
    gtid_io_pos VARCHAR(200) NOT NULL,
    slave_sql_running_state VARCHAR(500),
    handler_read_rnd_next bigint,
    PRIMARY KEY (id)
)
COLLATE='utf8mb4_general_ci' ENGINE=InnoDB;

LOAD DATA LOCAL INFILE '$CSV_FILE' INTO TABLE replica_history FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\n';
"
mariadb -ABNe "$SQL";
