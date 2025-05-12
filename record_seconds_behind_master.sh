#!/bin/bash
# Script by Edward Stoever for MariaDB Support
# Updated May 2025
# Ref Support Ticket 210602, 212358 (added Relay_Log_File, Relay_Log_Pos)
# In most cases, this script should be run as root, 
# however it may be possible to adjust it to run by a different system user

unset RECORD_PROCESSLIST CSV_OUTPUT

########################################    THRESHOLD    ########################################
#######################################################################################################
# DEFINE A SECONDS BEHIND MASTER THRESHOLD TO RECORD PROCESSLIST. 
# To always record processlist, set THRESHOLD_RECORD_PROCESSIST to 0.
THRESHOLD_RECORD_PROCESSIST=5

####################################    COLLECTIONS PER MINUTE    #####################################
#######################################################################################################
# PER_MIN determines how many times to run this in the 1 minute from the start of the script. 
# A values from 0 to 90 is acceptable. 60 is recommended limit.
# 2 = every 30 seconds
# 4 = every 15 seconds
# 6 = every 10 seconds
# 10 = every 6 seconds
# 60 is probably the highest you want to go!
PER_MIN=1

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
# IF YOU UNCOMMENT THE LINE "CSV_OUTPUT=TRUE" THE OUTPUT WILL BE SAVED IN EXTERNAL CSV FILES. 
# IF YOU SAVE TO EXTERNAL FILES, YOU WILL NOT NEED TO CREATE DATABASE TABLES. 
# EXTERNAL FILES WILL SAVE IN $OUTDIR.
# CSV_OUTPUT=TRUE
OUTDIR=/tmp/rep_hist

# IF NOT OUPUTTING TO EXTERNAL CSV FILE, THIS SCRIPT REQUIRES DATABASE OBJECTS. 
# SEE INCLUDED SCRIPT rep_hist_schema.sql


if [ $CSV_OUTPUT ]; then
 mkdir -p $OUTDIR
 chmod 777 $OUTDIR
fi

CSV_FILE=${OUTDIR}/$(hostname)_seconds_behind_master.csv; 
 
#######################################################################################################
#######################################################################################################

MARIADB_COMMAND=$(which mariadb)
if [ ! "$MARIADB_COMMAND" ]; then echo "No mariadb client is installed!" >&2; exit 1; fi
if [ $MARIADB_USER ]; then MARIADB_COMMAND=$(echo $MARIADB_COMMAND -u$MARIADB_USER); fi
if [ $MARIADB_PASSWORD ]; then MARIADB_COMMAND=$(echo $MARIADB_COMMAND -p$MARIADB_PASSWORD); fi
if [ $MARIADB_HOST ]; then MARIADB_COMMAND=$(echo $MARIADB_COMMAND -h$MARIADB_HOST); fi
if [ $MARIABD_PORT ]; then MARIADB_COMMAND=$(echo $MARIADB_COMMAND -P$MARIADB_PORT); fi

if [ ! $PER_MIN ]; then PER_MIN=1; fi 
if (( $PER_MIN < 1 )); then PER_MIN=1; fi
if (( $PER_MIN > 90 )); then echo "The value of $PER_MIN for PER_MIN is too high!" >&2; exit 1; fi
LOOPED=0;
for (( ii=1; ii<=$((1 * PER_MIN)); ii++))
 do
 
LOOPED=$((LOOPED + 1));

SLAVE_STATUS=$(${MARIADB_COMMAND} -Ae "show slave status\G"| grep -i -E '(Slave_SQL_Running_State|Seconds_Behind_Master|Gtid_IO_Pos|Relay_Log_File|Relay_Log_Pos)')
GLOBAL_STATUS=$(${MARIADB_COMMAND} -ABNe "select * from information_schema.GLOBAL_STATUS where variable_name in ('handler_read_rnd_next','threads_created','threads_connected','threads_running') UNION ALL select * from information_schema.GLOBAL_VARIABLES where VARIABLE_NAME in ('gtid_binlog_pos','gtid_current_pos','gtid_slave_pos');")

# parsing:
BEHIND_MASTER=$(printf "$SLAVE_STATUS\n" | grep -i Seconds_Behind_Master | awk '{print $2}')
if [ ! $BEHIND_MASTER ]; then BEHIND_MASTER=0; fi
RELAY_LOG_FILE=$(printf "$SLAVE_STATUS\n" | grep -i Relay_Log_File | awk '{print $2}')
if [ ! "$RELAY_LOG_FILE" ]; then RELAY_LOG_FILE='unknown'; fi
RELAY_LOG_POS=$(printf "$SLAVE_STATUS\n" | grep -i Relay_Log_Pos | awk '{print $2}')
if [ ! $RELAY_LOG_POS ]; then RELAY_LOG_POS='0'; fi
HANDLER_READ_RND_NEXT=$(printf "$GLOBAL_STATUS\n" | grep -i handler_read_rnd_next | awk '{print $2}')
if [ ! $HANDLER_READ_RND_NEXT ]; then HANDLER_READ_RND_NEXT='0'; fi
THREADS_CREATED=$(printf "$GLOBAL_STATUS\n" | grep -i threads_created | awk '{print $2}')
if [ ! $THREADS_CREATED ]; then THREADS_CREATED='0'; fi
THREADS_CONNECTED=$(printf "$GLOBAL_STATUS\n" | grep -i threads_connected | awk '{print $2}')
if [ ! $THREADS_CONNECTED ]; then THREADS_CONNECTED='0'; fi
THREADS_RUNNING=$(printf "$GLOBAL_STATUS\n" | grep -i threads_running | awk '{print $2}')
if [ ! $THREADS_RUNNING ]; then THREADS_RUNNING='0'; fi
GTID_IO_POS=$(printf "$SLAVE_STATUS\n" | grep -i Gtid_IO_Pos | awk '{print $2}')
if [ ! "$GTID_IO_POS" ]; then GTID_IO_POS='unknown'; fi
RUNNING_STATE=$(printf "$SLAVE_STATUS\n" | grep -i Slave_SQL_Running_State | sed 's/.*\://' |xargs)
if [ ! "$RUNNING_STATE" ]; then RUNNING_STATE='unknown'; fi
MARIADB_TOP_CPU_PCT=$(top -bn1 -p $(pidof mariadbd) | tail -1 | awk '{print $9}')
if [ ! $MARIADB_TOP_CPU_PCT ]; then MARIADB_TOP_CPU_PCT='0'; fi
GTID_BINLOG_POS=$(printf "$GLOBAL_STATUS\n" | grep -i gtid_binlog_pos | awk '{print $2}')
if [ ! "$GTID_BINLOG_POS" ]; then GTID_BINLOG_POS='unknown'; fi
GTID_CURRENT_POS=$(printf "$GLOBAL_STATUS\n" | grep -i gtid_current_pos | awk '{print $2}')
if [ ! "$GTID_CURRENT_POS" ]; then GTID_CURRENT_POS='unknown'; fi
GTID_SLAVE_POS=$(printf "$GLOBAL_STATUS\n" | grep -i gtid_slave_pos | awk '{print $2}')
if [ ! "$GTID_SLAVE_POS" ]; then GTID_SLAVE_POS='unknown'; fi

if (($BEHIND_MASTER >= $THRESHOLD_RECORD_PROCESSIST)); then RECORD_PROCESSLIST=TRUE; fi

if [ ! $CSV_OUTPUT ]; then

  SQL="SET SESSION sql_log_bin = 0; INSERT INTO rep_hist.replica_history (hostname, mariadbd_cpu_pct, seconds_behind_master, gtid_binlog_pos, gtid_current_pos, gtid_slave_pos, gtid_io_pos, slave_sql_running_state,handler_read_rnd_next,relay_log_file,relay_log_pos,threads_created,threads_connected,threads_running) VALUES (@@hostname, $MARIADB_TOP_CPU_PCT, $BEHIND_MASTER, @@gtid_binlog_pos, @@gtid_current_pos, @@gtid_slave_pos,'$GTID_IO_POS','$RUNNING_STATE',$HANDLER_READ_RND_NEXT,'$RELAY_LOG_FILE',$RELAY_LOG_POS,$THREADS_CREATED,$THREADS_CONNECTED,$THREADS_RUNNING);"
  if [  $RECORD_PROCESSLIST ]; then
    SQL=$SQL" insert into rep_hist.processlist_history (rh_id,tick,hostname,db,command,state,info) select LAST_INSERT_ID(), now(), @@HOSTNAME, DB, COMMAND, STATE, INFO from information_schema.processlist where (ID !=connection_id() AND INFO is not null) OR Command in ('Slave_IO','Slave_SQL','Slave_worker','Binlog Dump');"
  fi
  ${MARIADB_COMMAND} -ABNe "$SQL"
else
  if [ -f $CSV_FILE ]; then
    ID=$(tail -1 $CSV_FILE | cut -d"," -f1 | xargs)
  else
    ID=0;
  fi

  ID=$(( $ID + 1 ))

 printf "$ID,\"$(date "+%Y-%m-%d %H:%M:%S")\",\"$(hostname)\",\"$MARIADB_TOP_CPU_PCT\",\"$BEHIND_MASTER\",\"$GTID_BINLOG_POS\",\"$GTID_CURRENT_POS\",\"$GTID_SLAVE_POS\",\"$GTID_IO_POS\",\"$RUNNING_STATE\",$HANDLER_READ_RND_NEXT,\"$RELAY_LOG_FILE\",$RELAY_LOG_POS,$RELAY_LOG_POS,$THREADS_CREATED,$THREADS_CONNECTED,$THREADS_RUNNING\n" >> $CSV_FILE


PROCESS_LIST_FILE=${OUTDIR}/$(hostname)_processlist_$(date +%s)_$(printf "%03d\n" "${LOOPED}").csv;
  if [  $RECORD_PROCESSLIST ]; then
    SQL="select $ID, now(), @@HOSTNAME, DB, COMMAND, STATE, INFO from information_schema.processlist where (ID !=connection_id() AND INFO is not null) OR Command in ('Slave_IO','Slave_SQL','Slave_worker','Binlog Dump') INTO OUTFILE '$PROCESS_LIST_FILE' COLUMNS OPTIONALLY ENCLOSED BY '\"';"
    ${MARIADB_COMMAND} -ABNe "$SQL"
  fi 
fi


if ((LOOPED < PER_MIN)); then sleep $(awk "BEGIN { printf \"%.2f\n\", 60/$PER_MIN }"); fi
done
