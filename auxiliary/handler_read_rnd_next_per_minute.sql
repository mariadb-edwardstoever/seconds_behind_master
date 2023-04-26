-- QUERY BY EDWARD STOEVER FOR MARIADB SUPPORT

SELECT id,
tick,
hostname,
mariadbd_cpu_pct,
seconds_behind_master, 
SUBSTR(slave_sql_running_state,1,40) AS slave_running_state,
handler_read_rnd_next,
handler_read_rnd_next - (LAG(handler_read_rnd_next,1) over (ORDER BY id)) AS rnd_reads_per_1m,
handler_read_rnd_next - (LAG(handler_read_rnd_next,5) over (ORDER BY id)) AS rnd_reads_per_5m 
FROM replica_history WHERE tick > NOW()-INTERVAL 12 minute;

