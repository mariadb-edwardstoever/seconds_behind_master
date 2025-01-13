#!/bin/bash
# Script by Edward Stoever for MariaDB Support

# Tested on 10.6.12-7-MariaDB-enterprise

# Comment out the line for CSV_OUTPUT to insert into database table
# CSV_OUTPUT=TRUE
CSV_FILE=/tmp/$(hostname)_seconds_behind_master.csv

# IF NOT OUPUTTING TO EXTERNAL CSV FILE, REQUIRES DATABASE OBJECTS:
#
# CREATE SCHEMA if not exists `rep_hist`;
# use rep_hist;
#
# drop table if exists `replica_history`;
# CREATE TABLE `replica_history` (
#    `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
#    `tick` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
#    `hostname` VARCHAR(128) NULL DEFAULT NULL,
#    `mariadbd_cpu_pct` DECIMAL(5,2) NULL DEFAULT NULL,
#    `seconds_behind_master` int,
#    `gtid_binlog_pos` VARCHAR(200) NOT NULL,
#    `gtid_current_pos` VARCHAR(200) NOT NULL,
#    `gtid_slave_pos` VARCHAR(200) NOT NULL,
#    `gtid_io_pos` VARCHAR(200) NOT NULL,
#    `slave_sql_running_state` VARCHAR(500),
#    `handler_read_rnd_next` bigint,
#    PRIMARY KEY (`id`)
# )
# COLLATE='utf8mb4_general_ci'
# ENGINE=InnoDB;

# NOTE, YOU MAY NEED TO CHANGE the mariadb commands below to include -u and -p for username and password:

STATUS=$(mariadb -Ae "show slave status\G"| grep -i -E '(Slave_SQL_Running_State|Seconds_Behind_Master|Gtid_IO_Pos)')
HANDLER_READ_RND_NEXT=$(mariadb -ABNe "select variable_value from information_schema.GLOBAL_STATUS where variable_name='Handler_read_rnd_next';")

# parsing STATUS:
BEHIND_MASTER=$(printf "$STATUS\n" | grep -i Seconds_Behind_Master | awk '{print $2}')

# THE NEXT THREE MUST BE SEPARATE TO ACCOUNT FOR POSSIBLE NULL VALUES
GTID_IO_POS=$(printf "$STATUS\n" | grep -i Gtid_IO_Pos | awk '{print $2}')
RUNNING_STATE=$(printf "$STATUS\n" | grep -i Slave_SQL_Running_State | sed 's/.*\://' |xargs)
MARIADB_TOP_CPU_PCT=$(top -bn1 -p $(pidof mariadbd) | tail -1 | awk '{print $9}')

if [ ! $CSV_OUTPUT ]; then
  mariadb -ABNe "SET SESSION sql_log_bin = 0; INSERT INTO rep_hist.replica_history (hostname, mariadbd_cpu_pct, seconds_behind_master, gtid_binlog_pos, gtid_current_pos, gtid_slave_pos, gtid_io_pos, slave_sql_running_state,handler_read_rnd_next) VALUES (@@hostname, $MARIADB_TOP_CPU_PCT, $BEHIND_MASTER, @@gtid_binlog_pos, @@gtid_current_pos, @@gtid_slave_pos,'$GTID_IO_POS','$RUNNING_STATE',$HANDLER_READ_RND_NEXT);"
else

  if [ -f $CSV_FILE ]; then
    ID=$(tail -1 $CSV_FILE | cut -d"," -f1 | xargs)
  else
    ID=0;
  fi

  ID=$(( $ID + 1 ))

  GTID_BINLOG_POS=$(mariadb -ABNe "select @@gtid_binlog_pos;")
  GTID_CURRENT_POS=$(mariadb -ABNe "select @@gtid_current_pos;")
  GTID_SLAVE_POS=$(mariadb -ABNe "select @@gtid_slave_pos;")

  printf "$ID,\"$(date "+%Y-%m-%d %H:%M:%S")\",\"$(hostname)\",\"$MARIADB_TOP_CPU_PCT\",\"$BEHIND_MASTER\",\"$GTID_BINLOG_POS\",\"$GTID_CURRENT_POS\",\"$GTID_SLAVE_POS\",\"$GTID_IO_POS\",\"$RUNNING_STATE\",$HANDLER_READ_RND_NEXT\n" >> $CSV_FILE

fi


