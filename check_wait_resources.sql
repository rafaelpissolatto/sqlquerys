DECLARE @Wait_Types_Excluded TABLE([wait_type] nvarchar(60) PRIMARY KEY);

INSERT INTO @Wait_Types_Excluded([wait_type]) VALUES

 (N'BROKER_EVENTHANDLER'), (N'BROKER_RECEIVE_WAITFOR'), (N'BROKER_TASK_STOP'), (N'BROKER_TO_FLUSH'), (N'BROKER_TRANSMITTER')
,(N'CHECKPOINT_QUEUE'), (N'CHKPT'), (N'CLR_AUTO_EVENT'), (N'CLR_MANUAL_EVENT'), (N'CLR_SEMAPHORE') ,(N'DIRTY_PAGE_POLL')
,(N'DISPATCHER_QUEUE_SEMAPHORE'), (N'EXECSYNC'), (N'FSAGENT'), (N'FT_IFTS_SCHEDULER_IDLE_WAIT'), (N'FT_IFTSHC_MUTEX')
,(N'KSOURCE_WAKEUP'), (N'LAZYWRITER_SLEEP'), (N'LOGMGR_QUEUE'), (N'MEMORY_ALLOCATION_EXT'), (N'ONDEMAND_TASK_QUEUE')
,(N'PREEMPTIVE_XE_GETTARGETSTATE'), (N'PWAIT_ALL_COMPONENTS_INITIALIZED'), (N'PWAIT_DIRECTLOGCONSUMER_GETNEXT')
,(N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP'), (N'QDS_ASYNC_QUEUE'), (N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP')
,(N'QDS_SHUTDOWN_QUEUE'), (N'REDO_THREAD_PENDING_WORK'), (N'REQUEST_FOR_DEADLOCK_SEARCH'), (N'RESOURCE_QUEUE')
,(N'SERVER_IDLE_CHECK'), (N'SLEEP_BPOOL_FLUSH'), (N'SLEEP_DBSTARTUP'), (N'SLEEP_DCOMSTARTUP'), (N'SLEEP_MASTERDBREADY')
,(N'SLEEP_MASTERMDREADY'), (N'SLEEP_MASTERUPGRADED'), (N'SLEEP_MSDBSTARTUP'), (N'SLEEP_SYSTEMTASK'), (N'SLEEP_TASK')
,(N'SLEEP_TEMPDBSTARTUP'), (N'SNI_HTTP_ACCEPT'), (N'SP_SERVER_DIAGNOSTICS_SLEEP'), (N'SQLTRACE_BUFFER_FLUSH')
,(N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP'), (N'SQLTRACE_WAIT_ENTRIES'), (N'WAIT_FOR_RESULTS'), (N'WAITFOR')
,(N'WAITFOR_TASKSHUTDOWN'), (N'WAIT_XTP_RECOVERY'), (N'WAIT_XTP_HOST_WAIT'), (N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG')
,(N'WAIT_XTP_CKPT_CLOSE'), (N'XE_DISPATCHER_JOIN'), (N'XE_DISPATCHER_WAIT'), (N'XE_TIMER_EVENT')
,(N'DBMIRROR_DBM_EVENT'), (N'DBMIRROR_EVENTS_QUEUE'), (N'DBMIRROR_WORKER_QUEUE'), (N'DBMIRRORING_CMD'),
(N'HADR_CLUSAPI_CALL'), (N'HADR_FILESTREAM_IOMGR_IOCOMPLETION'), (N'HADR_LOGCAPTURE_WAIT'),
(N'HADR_NOTIFICATION_DEQUEUE'), (N'HADR_TIMER_TASK'), (N'HADR_WORK_QUEUE');

SELECT
 [Approx_Wait_Stats_Restart_Date] = CAST(DATEADD(minute, -CAST((CAST(ws.[wait_time_ms] as decimal(38,18)) / 60000.0) as int), SYSDATETIME()) as smalldatetime)
,[SQL_Server_Last_Restart_Date] = CAST(si.[sqlserver_start_time] as smalldatetime)
FROM sys.dm_os_wait_stats ws, sys.dm_os_sys_info si
WHERE ws.[wait_type] = N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP';

SELECT TOP 25
 ws.[wait_type]
,[Total_Wait_(s)]         = CAST(SUM(ws.[wait_time_ms]) OVER (PARTITION BY ws.[wait_type]) / 1000.0 as decimal(19,3))
,[Resource_(s)]           = CAST(SUM([wait_time_ms] - [signal_wait_time_ms]) OVER (PARTITION BY ws.[wait_type]) / 1000.0 as decimal(19,3))
,[Signal_(s)]             = CAST(SUM(ws.[signal_wait_time_ms]) OVER (PARTITION BY ws.[wait_type]) / 1000.0 as decimal(19,3))
,[Avg_Total_Wait_(ms)]    = CASE WHEN SUM(ws.[waiting_tasks_count]) OVER (PARTITION BY ws.[wait_type]) > 0 THEN SUM(ws.[wait_time_ms]) OVER (PARTITION BY ws.[wait_type])/ SUM(ws.[waiting_tasks_count])OVER (PARTITION BY ws.[wait_type]) END
,[Avg_Resource_Wait_(ms)  = CASE WHEN SUM(ws.[waiting_tasks_count]) OVER (PARTITION BY ws.[wait_type]) > 0 THEN SUM(ws.[wait_time_ms] - ws.[signal_wait_time_ms]) OVER (PARTITION BY ws.[wait_type])/ SUM(ws.[waiting_tasks_count]) OVER (PARTITION BY ws.[wait_type])END
,[Avg_Signal_Wait_(ms)]   = CASE WHEN SUM(ws.[waiting_tasks_count]) OVER (PARTITION BY ws.[wait_type])> 0 THEN SUM(ws.[signal_wait_time_ms]) OVER (PARTITION BY ws.[wait_type])/ SUM(ws.[waiting_tasks_count]) OVER (PARTITION BY ws.[wait_type])END
,[Waiting_Tasks_QTY]      = SUM(ws.[waiting_tasks_count]) OVER (PARTITION BY ws.[wait_type])
,[Percent_of_Total_Waits_Time]  = CAST(CAST(SUM(ws.[wait_time_ms]) OVER (PARTITION BY ws.[wait_type]) as decimal) / CAST(SUM(ws.[wait_time_ms]) OVER() as decimal) * 100.0 as decimal(5,2))
,[Percent_of_Total_Waits_QTY]     = CAST(CAST(SUM(ws.[waiting_tasks_count]) OVER (PARTITION BY ws.[wait_type]) as decimal)/ CAST(SUM(ws.[waiting_tasks_count]) OVER() as decimal) * 100.0 as decimal(5,2))
FROM sys.dm_os_wait_stats ws
LEFT JOIN @Wait_Types_Excluded wte ON ws.[wait_type] = wte.[wait_type]
WHERE   wte.[wait_type] IS NULL
AND    ws.[waiting_tasks_count] > 0
ORDER BY [Total_Wait_(s)] DESC; 
