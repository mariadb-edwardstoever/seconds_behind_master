-- 
-- SCRIPT BY EDWARD STOEVER, RUN ON SLAVE TO RECORD MOMENTS OF LAG
-- 

SET SESSION sql_log_bin = 0;

CREATE SCHEMA if not exists `rep_hist`;
use rep_hist;

drop table if exists `replica_history`;
CREATE TABLE `replica_history` (
    `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
    `tick` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `hostname` VARCHAR(128) NULL DEFAULT NULL,
    `mariadbd_cpu_pct` DECIMAL(5,2) NULL DEFAULT NULL,
    `seconds_behind_master` int,
    `gtid_binlog_pos` VARCHAR(200) NOT NULL,
    `gtid_current_pos` VARCHAR(200) NOT NULL,
    `gtid_slave_pos` VARCHAR(200) NOT NULL,
    `gtid_io_pos` VARCHAR(200) NOT NULL,
    `slave_sql_running_state` VARCHAR(500),
    `handler_read_rnd_next` bigint,
    `relay_log_file` VARCHAR(200) DEFAULT NULL,
    `relay_log_pos` VARCHAR(200) DEFAULT NULL,
    PRIMARY KEY (`id`)
)
COLLATE='utf8mb4_general_ci'
ENGINE=InnoDB;

drop table if exists `processlist_history`;
CREATE TABLE `processlist_history` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `tick` timestamp NOT NULL DEFAULT current_timestamp(),
  `hostname` VARCHAR(128) NULL DEFAULT NULL,
  `db` varchar(64) DEFAULT NULL,
  `command` varchar(16) DEFAULT NULL,
  `state` varchar(64) DEFAULT NULL,
  `info` longtext NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

