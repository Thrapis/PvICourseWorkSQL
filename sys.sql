create tablespace TS_BAA_PDB
datafile 'C:\app\Tablespaces\TS_BAA_PDB.dbf'
size 10 m
autoextend on next 100 m
maxsize UNLIMITED
extent management local;

create temporary tablespace TS_BAA_PDB_TEMP
tempfile 'C:\app\Tablespaces\TS_BAA_PDB_TEMP.dbf'
size 5 m
autoextend on next 3 m
maxsize 500 m
extent management local;

alter session set "_ORACLE_SCRIPT"=true;

CREATE USER BAA IDENTIFIED BY 12345
DEFAULT TABLESPACE TS_BAA_PDB QUOTA UNLIMITED ON TS_BAA_PDB
TEMPORARY TABLESPACE TS_BAA_PDB_TEMP
ACCOUNT UNLOCK;

grant create session to BAA;
grant all privileges to BAA;

select * from dba_sys_privs where grantee = 'BAA';

ALTER PLUGGABLE DATABASE ORCLPDB OPEN;


