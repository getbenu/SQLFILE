col file_name format a60
set linesize 200
select file_name,file_id, bytes/1024/1024 "MB", tablespace_name from dba_temp_files;

cd /goldengate/gg19c/dump

srvctl add service -d dp9a -s dp9a1.eng -r dp9a1,dp9a2 -l PRIMARY -m BASIC -e SELECT -w 1 -z 180 -y AUTOMATIC
srvctl add service -d dp9a -s dp9a1.eng -r dp9a1,dp9a2 -l PRIMARY -m BASIC -e SELECT -w 1 -z 180 -y AUTOMATIC
