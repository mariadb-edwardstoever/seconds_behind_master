#!/bin/bash
# Script by Edward Stoever for MariaDB Support
# Updated January 2025
# Ref Support Ticket 210602
# In most cases, this script should be run as root, 
# however it may be possible to adjust it to run by a different system user

unset RECORD_PROCESSLIST CSV_OUTPUT

########################################    THRESHOLD    ########################################
#######################################################################################################
# DEFINE A SECONDS BEHIND MASTER THRESHOLD TO RECORD PROCESSLIST
THRESHOLD_RECORD_PROCESSIST=5

#######################################################################################################
#######################################################################################################

########################################    DB USER ACCOUNT    ########################################
#######################################################################################################

# This script has been tested as root@localhost. 
# The script should be run as root on the host of the slave server it is capturing statistics for.

# Leave the following lines commented out if using root@localhost identified via unix_socket
# MARIADB_USER=root
# MARIADB_PASSWORD=password
# MARIADB_HOST=localhost 
# MARIADB_PORT=3306
#######################################################################################################
#######################################################################################################

######################################    CSV OR TABLE OUTPUT    ######################################
#######################################################################################################
# IF YOU UNCOMMENT THE NEXT LINE, "CSV_OUTPUT=TRUE" THE OUTPUT WILL BE SAVED IN EXTERNAL CSV FILES. 
 CSV_OUTPUT=TRUE

OUTDIR=/tmp/rep_hist

if [ $CSV_OUTPUT ]; then
 mkdir -p $OUTDIR
 chmod 777 $OUTDIR
fi

CSV_FILE=${OUTDIR}/$(hostname)_seconds_behind_master.csv; 
PROCESS_LIST_FILE=${OUTDIR}/$(hostname)_processlist_$(date +%s).csv; 
#######################################################################################################
#######################################################################################################


# IF NOT OUPUTTING TO EXTERNAL CSV FILE, REQUIRES DATABASE OBJECTS. SEE INCLUDED SCRIPT rep_hist_schema.sql:
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

# drop table if exists `processlist_history`;
# CREATE TABLE `processlist_history` (
#   `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
#   `tick` timestamp NOT NULL DEFAULT current_timestamp(),
#   `hostname` VARCHAR(128) NULL DEFAULT NULL,
#   `db` varchar(64) DEFAULT NULL,
#   `command` varchar(16) DEFAULT NULL,
#   `state` varchar(64) DEFAULT NULL,
#   `info` longtext NOT NULL,
#   PRIMARY KEY (`id`)
# ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;




MARIADB_COMMAND=$(echo mariadb)
if [ $MARIADB_USER ]; then MARIADB_COMMAND=$(echo $MARIADB_COMMAND -u$MARIADB_USER); fi
if [ $MARIADB_PASSWORD ]; then MARIADB_COMMAND=$(echo $MARIADB_COMMAND -p$MARIADB_PASSWORD); fi
if [ $MARIADB_HOST ]; then MARIADB_COMMAND=$(echo $MARIADB_COMMAND -h$MARIADB_HOST); fi
if [ $MARIABD_PORT ]; then MARIADB_COMMAND=$(echo $MARIADB_COMMAND -P$MARIADB_PORT); fi
STATUS=$(${MARIADB_COMMAND} -Ae "show slave status\G"| grep -i -E '(Slave_SQL_Running_State|Seconds_Behind_Master|Gtid_IO_Pos)')
HANDLER_READ_RND_NEXT=$(${MARIADB_COMMAND} -ABNe "select variable_value from information_schema.GLOBAL_STATUS where variable_name='Handler_read_rnd_next';")

# parsing STATUS:
BEHIND_MASTER=$(printf "$STATUS\n" | grep -i Seconds_Behind_Master | awk '{print $2}')

if (($BEHIND_MASTER >= $THRESHOLD_RECORD_PROCESSIST)) then RECORD_PROCESSLIST=TRUE; fi

# THE NEXT THREE MUST BE SEPARATE TO ACCOUNT FOR POSSIBLE NULL VALUES
GTID_IO_POS=$(printf "$STATUS\n" | grep -i Gtid_IO_Pos | awk '{print $2}')
RUNNING_STATE=$(printf "$STATUS\n" | grep -i Slave_SQL_Running_State | sed 's/.*\://' |xargs)
MARIADB_TOP_CPU_PCT=$(top -bn1 -p $(pidof mariadbd) | tail -1 | awk '{print $9}')

if [ ! $CSV_OUTPUT ]; then
  SQL="SET SESSION sql_log_bin = 0; INSERT INTO rep_hist.replica_history (hostname, mariadbd_cpu_pct, seconds_behind_master, gtid_binlog_pos, gtid_current_pos, gtid_slave_pos, gtid_io_pos, slave_sql_running_state,handler_read_rnd_next) VALUES (@@hostname, $MARIADB_TOP_CPU_PCT, $BEHIND_MASTER, @@gtid_binlog_pos, @@gtid_current_pos, @@gtid_slave_pos,'$GTID_IO_POS','$RUNNING_STATE',$HANDLER_READ_RND_NEXT);"
  if [  $RECORD_PROCESSLIST ]; then
    SQL=$SQL" insert into rep_hist.processlist_history (tick,hostname,db,command,state,info) select now(), @@HOSTNAME, DB, COMMAND, STATE, INFO from information_schema.processlist where INFO is not null;"
  fi
  ${MARIADB_COMMAND} -ABNe "$SQL"
else
  if [ -f $CSV_FILE ]; then
    ID=$(tail -1 $CSV_FILE | cut -d"," -f1 | xargs)
  else
    ID=0;
  fi

  ID=$(( $ID + 1 ))

  GTID_BINLOG_POS=$(${MARIADB_COMMAND} -ABNe "select @@gtid_binlog_pos;")
  GTID_CURRENT_POS=$(${MARIADB_COMMAND} -ABNe "select @@gtid_current_pos;")
  GTID_SLAVE_POS=$(${MARIADB_COMMAND} -ABNe "select @@gtid_slave_pos;")

  printf "$ID,\"$(date "+%Y-%m-%d %H:%M:%S")\",\"$(hostname)\",\"$MARIADB_TOP_CPU_PCT\",\"$BEHIND_MASTER\",\"$GTID_BINLOG_POS\",\"$GTID_CURRENT_POS\",\"$GTID_SLAVE_POS\",\"$GTID_IO_POS\",\"$RUNNING_STATE\",$HANDLER_READ_RND_NEXT\n" >> $CSV_FILE

  if [  $RECORD_PROCESSLIST ]; then
    SQL="select $ID, now(), @@HOSTNAME, DB, COMMAND, STATE, INFO from information_schema.processlist where INFO is not null INTO OUTFILE '$PROCESS_LIST_FILE' COLUMNS OPTIONALLY ENCLOSED BY '\"';"
    ${MARIADB_COMMAND} -ABNe "$SQL"
  fi 
fi


