-- 
-- SCRIPT BY EDWARD STOEVER, RUN ON SLAVE TO RECORD MOMENTS OF LAG
-- 

SET SESSION sql_log_bin = 0;

CREATE SCHEMA if not exists `rep_hist`;
use rep_hist;

drop table if exists `replica_history`;
CREATE TABLE `replica_history` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `tick` timestamp NOT NULL DEFAULT current_timestamp(),
  `hostname` varchar(128) DEFAULT NULL,
  `mariadbd_cpu_pct` decimal(5,2) DEFAULT NULL,
  `seconds_behind_master` int(11) DEFAULT NULL,
  `gtid_binlog_pos` varchar(200) DEFAULT NULL,
  `gtid_current_pos` varchar(200) DEFAULT NULL,
  `gtid_slave_pos` varchar(200) DEFAULT NULL,
  `gtid_io_pos` varchar(200) DEFAULT NULL,
  `slave_sql_running_state` varchar(500) DEFAULT NULL,
  `handler_read_rnd_next` bigint(20) DEFAULT NULL,
  `relay_log_file` varchar(200) DEFAULT NULL,
  `relay_log_pos` varchar(200) DEFAULT NULL,
  `threads_created` int(11) DEFAULT NULL,
  `threads_connected` int(11) DEFAULT NULL,
  `threads_running` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB CHARSET=utf8mb4;

drop table if exists `processlist_history`;
CREATE TABLE `processlist_history` (
  `rh_id` int(11) DEFAULT NULL,
  `tick` timestamp NOT NULL DEFAULT current_timestamp(),
  `hostname` varchar(128) DEFAULT NULL,
  `db` varchar(64) DEFAULT NULL,
  `command` varchar(16) DEFAULT NULL,
  `state` varchar(64) DEFAULT NULL,
  `info` longtext NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
