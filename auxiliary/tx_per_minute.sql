-- QUERY BY EDWARD STOEVER FOR MARIABD SUPPORT
-- ADJUST SUBSTR OF gtid_slave_pos ACCORDINGLY

WITH INNER_Q AS (SELECT id, tick, seconds_behind_master, 
   SUBSTR(gtid_slave_pos,41,10) AS seq_no FROM replica_history)
SELECT id, tick, seconds_behind_master, seq_no, 
seq_no - (LAG(seq_no,1) over (ORDER BY id)) AS tx_per_1_minute, 
seq_no - (LAG(seq_no,5) over (ORDER BY id)) AS tx_per_5_minute,
seq_no - (LAG(seq_no,10) over (ORDER BY id)) AS tx_per_10_minute 
FROM INNER_Q;

