-- 
-- SCRIPT BY EDWARD STOEVER, RUN ON SLAVE TO RECORD MOMENTS OF LAG
-- 

SET SESSION sql_log_bin = 0;

use rep_hist;

truncate table `replica_history`;
truncate table `processlist_history`;

