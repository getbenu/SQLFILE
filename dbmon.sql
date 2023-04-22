alter session set nls_date_format='dd/mm/yyyy hh24:mi:ss';
set serveroutput on size 100000;
set lines 1000;
set pages 1000;
set linesize 1000;
sho user;

declare

  dat date;
  cdate varchar2(11);
  ctime varchar2(10);
  dummy char(20);

  pval v$sysstat.value%type;
   cval v$sysstat.value%type;
   dval v$sysstat.value%type;
   chitdbbuff varchar2(100);
   cpval varchar2(100);
   ccval varchar2(100);
   cdval varchar2(100);
   hitdbbuff number;

  cursor c1 is select b.file_id,b.tablespace_name,
  b.bytes/1024/1024,
  (b.bytes-sum(nvl(a.bytes,0)))/1024/1024,
  sum(nvl(a.bytes,0))/1024/1024,(sum(nvl(a.bytes,0))/(b.bytes))*100
  from sys.dba_free_space a, sys.dba_data_files b
  where b.file_id=a.file_id(+)
  group by b.tablespace_name,b.file_id,b.bytes
  order by b.tablespace_name;




  file_no dba_data_files.file_id%type;
  tablespace dba_data_files.tablespace_name%type;
  siz dba_data_files.bytes%type;
  used dba_data_files.bytes%type;
  free dba_data_files.bytes%type;
  pfree dba_data_files.bytes%type;


  sumgets number;
  summisses number;
  permiss number;

  csumgets varchar2(15);
  csummisses varchar2(15);
  cpermiss varchar2(15);


  sumpins number;
  sumreloads number;
  perpins number;

  csumpins varchar2(15);
  csumreloads varchar2(15);
  cperpins varchar2(15);


  otablespace dba_data_files.tablespace_name%type;
  osiz dba_data_files.bytes%type;
  oused dba_data_files.bytes%type;
  ofree dba_data_files.bytes%type;


  totsiz dba_data_files.bytes%type;
  totused dba_data_files.bytes%type;
  totfree dba_data_files.bytes%type;
  totpfree dba_data_files.bytes%type;

  cfile_no varchar2(2);
  csiz varchar2(20);
  cused varchar2(20);
  cfree varchar2(20);
  cpfree varchar2(20);


  gtotsiz dba_data_files.bytes%type;
  gtotused dba_data_files.bytes%type;
  gtotfree dba_data_files.bytes%type;
  gtotpfree dba_data_files.bytes%type;


  numfrext dba_free_space.blocks%type;
  maxfrext dba_free_space.blocks%type;
  maxfrext_tmp number; /* Used for conversion from Blocks to MB */
  pmaxfrext dba_free_space.blocks%type;


  cnumfrext dba_free_space.blocks%type;
  cmaxfrext dba_free_space.blocks%type;
  cpmaxfrext dba_free_space.blocks%type;

begin

   dummy:='.';
   dbms_output.enable;


   select sysdate into dat from dual;
   cdate:=to_char(dat,'DD-MON-YY');
   ctime:=to_char(dat,'HH:MI');

   dbms_output.put_line('Report Date : '||cdate);
   dbms_output.put_line('Report Time : '||ctime);

   dbms_output.put_line(dummy);


   select sum(pins),sum(reloads),
	  sum(pins)*100/(sum(pins)+sum(reloads))
   into sumpins,sumreloads,perpins
   from v$librarycache;

   csumpins:=to_char(sumpins);
   csumreloads:=to_char(sumreloads);
   cperpins:=to_char(round(perpins,2),999.99);

   dbms_output.put_line(' Pins    '||' '||'     Reloads '||' '||'% Library Cache Hits');
   dbms_output.put_line(rpad(csumpins,15,' ')||' '||rpad(csumreloads,8,' ')||' '||rpad(cperpins,7,' '));

   dbms_output.put_line(dummy);


   select sum(gets),sum(getmisses),
	  100-(sum(getmisses)*100/(sum(gets)+sum(getmisses)))
   into sumgets,summisses,permiss
   from v$rowcache
   where gets+getmisses<>0;


   csumgets:=to_char(sumgets);
   csummisses:=to_char(summisses);
   cpermiss:=to_char(round(permiss,2),999.99);

   dbms_output.put_line(' Gets    '||' '||'       Misses '||' '||'% Dictionary cache Hits');
   dbms_output.put_line(rpad(csumgets,15,' ')||' '||rpad(csummisses,8,' ')||' '||rpad(cpermiSS,7,' '));

   dbms_output.put_line(dummy);


  select value into pval from v$sysstat where name='physical reads';
  select value into dval from v$sysstat where name='db block gets';
  select value into cval from v$sysstat where name='consistent gets';

  cpval:=to_char(round(pval,2));
  cdval:=to_char(round(dval,2));
  ccval:=to_char(round(cval,2));

  hitdbbuff:=(1-(pval/(dval+cval)))*100;
  chitdbbuff:=to_char(round(hitdbbuff,2));

  dbms_output.put_line('DB Buffer Hit Ratio = '||chitdbbuff);

  dbms_output.put_line(dummy);



   open c1;

   otablespace:=' ';
   osiz:=0;
   oused:=0;
   ofree:=0;

   totsiz:=0;
   totused:=0;
   totfree:=0;

   gtotsiz:=0;
   gtotused:=0;
   gtotfree:=0;
   gtotpfree:=0;

dbms_output.put_line('----------------------------------------------------------------------------------------');
dbms_output.put_line('| Tablespace              |Size(MB)|Used(MB)| Free(MB)| %Free | Ext  | Max (MB)| %Frag |');
dbms_output.put_line('|-------------------------|--------|--------|---------|-------|------|---------|-------|');

  loop

    fetch c1 into file_no,tablespace,siz,used,free,pfree;
  exit when c1%notfound;

    if tablespace=otablespace then
        totsiz:=totsiz+siz;
-- dbms_output.put_line(totsiz);
totused:=totused+used;
	totfree:=totfree+free;
	totused:=round(totused,2);
	totfree:=round(totfree,2);
	totpfree:=round((totfree/totsiz)*100,2);
  else

	gtotsiz:=gtotsiz+totsiz;
	gtotused:=round(gtotused+totused,2);
	gtotfree:=round(gtotfree+totfree,2);

	csiz:=to_char(totsiz);
	cused:=to_char(round(totused,2));
	cfree:=to_char(round(totfree,2));
	cpfree:=to_char(round(totpfree,2));

	if totsiz<>0 then
	   select count(blocks),max(blocks) into numfrext,maxfrext
	   from dba_free_space where tablespace_name=otablespace;

           maxfrext_tmp:=(maxfrext*1024)/(1024*1024);
	   pmaxfrext:=100 - round(maxfrext_tmp/totfree*100,2);

           cnumfrext:=to_char(numfrext);
           cmaxfrext:=to_char(round(maxfrext_tmp,2));
           cpmaxfrext:=to_char(round(pmaxfrext,2));


dbms_output.put_line('| '||rpad(otablespace,23,' ')||' | '||rpad(csiz,6,' ')||' | '||rpad(cused,6,' ')||' | '||rpad(cfree,7,' ')||' | '||rpad(cpfree,5,' ')||' | '||rpad(cnumfrext,4,' ')||' | '||rpad(cmaxfrext,7,' ')||' | '||rpad(cpmaxfrext,6,' ')||'|');

	 end if;

	totsiz:=siz;
	totused:=used;
	totfree:=free;
	totpfree:=round(free/siz*100,2);
	otablespace:=tablespace;
	osiz:=siz;
	oused:=used;
	ofree:=free;

    end if;

  end loop;


	gtotsiz:=gtotsiz+totsiz;
	gtotused:=round(gtotused+totused,2);
	gtotfree:=round(gtotfree+totfree,2);

	csiz:=to_char(totsiz);
	cused:=to_char(round(totused,2));
	cfree:=to_char(round(totfree,2));
	cpfree:=to_char(round(totpfree,2));

	select count(blocks),max(blocks) into numfrext,maxfrext
	from dba_free_space where tablespace_name=otablespace;

           maxfrext_tmp:=(maxfrext*8192)/(1024*1024);
	   pmaxfrext:= 100 - round(maxfrext_tmp/totfree*100,2);

           cnumfrext:=to_char(numfrext);
           cmaxfrext:=to_char(round(maxfrext_tmp,2));
           cpmaxfrext:=to_char(round(pmaxfrext,2));


dbms_output.put_line('| '||rpad(otablespace,23,' ')||' | '||rpad(csiz,6,' ')||' | '||rpad(cused,6,' ')||' | '||rpad(cfree,7,' ')||' | '||rpad(cpfree,5,' ')||' | '||rpad(cnumfrext,4,' ')||' | '||rpad(cmaxfrext,7,' ')||' | '||rpad(cpmaxfrext,6,' ')||'|');

dbms_output.put_line('----------------------------------------------------------------------------------------');

close c1;


dbms_output.put_line('starting check');
gtotpfree:=round(gtotfree/gtotsiz*100,2);

csiz:=to_char(gtotsiz);
cused:=to_char(gtotused);
cfree:=to_char(gtotfree);
cpfree:=to_char(gtotpfree);


dbms_output.put_line('Total Database Size     = '||gtotsiz||' MB');
dbms_output.put_line('Total Data Size         = '||gtotused||' MB');
dbms_output.put_line('Total Free Space        = '||gtotfree||' MB');
dbms_output.put_line('Percentage Free Space   = '||gtotpfree);

dbms_output.put_line('no error upto this');
end;
/
select name from v$database;
/
!du -s * |sort -n