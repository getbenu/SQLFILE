set lines 300 
set pages 300 
col HOST_NAME for a30 
select distinct host_name,name "DB_NAME",db_unique_name,instance_name from gv$instance,gv$database; 

col HOST_NAME format a15
set lines 10000
SELECT host_name, instance_name, TO_CHAR(startup_time, 'DD-MM-YYYY HH24:MI:SS') startup_time, FLOOR(sysdate-startup_time) days FROM sys.gv_$instance;
