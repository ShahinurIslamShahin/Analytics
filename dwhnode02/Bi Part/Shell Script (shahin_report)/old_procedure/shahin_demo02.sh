
export ORACLE_UNQNAME=DWH05
export ORACLE_BASE=/data01/app/oracle
export ORACLE_HOME=/data01/app/oracle/product/12.2.0/db_1
export ORACLE_SID=DWH05

PATH=/usr/sbin:$PATH:$ORACLE_HOME/bin

export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib;
export CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib;


get_partition()
{
sqlplus  -s <<EOF
dwh_user/dwh_user_123
SET echo off
SET head off
SET feedback off
REM "WHENEVER SQLERROR EXIT SQL.SQLCODE"
SELECT RPART||','||DATE_KEY
FROM
(SELECT 'VOICE_'||A.DATE_KEY RPART,B.DATE_KEY
FROM DATE_DIM A, DATE_DIM B
WHERE A.DATE_KEY = (SELECT A.DATE_KEY FROM DATE_DIM A WHERE A.DATE_VALUE = TO_DATE (SYSDATE,'dd/mm/rrrr'))
AND B.DATE_KEY = (SELECT A.DATE_KEY FROM DATE_DIM A WHERE A.DATE_VALUE = TO_DATE (SYSDATE-1,'dd/mm/rrrr'))
);
EXIT
EOF
}



insert_script()
{
sqlplus  -s <<EOF
dwh_user/dwh_user_123
SET echo on
SET head off
SET feedback off
WHENEVER SQLERROR EXIT SQL.SQLCODE
------------------------------------------------------




INSERT INTO SHAHIN_DEMO02

SELECT /*+PARALLEL(P,8)*/ V387_CHARGINGTIME_KEY DATE_KEY,SUM (V41_DEBIT_AMOUNT) VOICE_REVENUE FROM L3_VOICE PARTITION($v1) P
WHERE V387_CHARGINGTIME_KEY  = (SELECT DATE_KEY FROM DATE_DIM WHERE DATE_VALUE = TRUNC(TO_DATE(sysdate-1,'DD/MM/RRRR')))
GROUP BY V387_CHARGINGTIME_KEY
;
COMMIT;
EXIT
EOF
}

# ======= SMSC SECTION =====.

lock=/data02/scripts/process/bin/shahin_demo02  export lock

if [ -f $lock ] ; then
exit 2

else
touch $lock

fileList=`get_partition`

for fil in $fileList
do

v1=`echo ${fil}|sed s/,/\ /g|awk '{print $1}'`   ###VOICE partition

v2=`echo ${fil}|sed s/,/\ /g|awk '{print $2}'`   ###date_key

insert_script $v1 $v2 

done

rm -f $lock

fi

