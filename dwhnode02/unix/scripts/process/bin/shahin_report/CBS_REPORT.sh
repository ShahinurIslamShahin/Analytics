PATH=$PATH:$HOME/.local/bin:$HOME/bin

export PATH

export TMP=/tmp
export TMPDIR=$TMP

export ORACLE_HOSTNAME=dwhnode02
export ORACLE_UNQNAME=dwhdb02
export ORACLE_BASE=/data01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/19.0.0/dbhome_1
export ORA_INVENTORY=/data01/app/oraInventory
export ORACLE_SID=dwhdb02
export DATA_DIR=/data01/oradata

export PATH=/usr/sbin:/usr/local/bin:$PATH
export PATH=$ORACLE_HOME/bin:$PATH

export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib


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
(SELECT 'RECHARGE_'||A.DATE_KEY RPART,B.DATE_KEY
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

DELETE shahin_demo1 WHERE PDR_DATE_KEY='$v2';
COMMIT;


INSERT INTO shahin_demo1

SELECT /*+PARALLEL(P,8)*/ RE30_ENTRY_DATE_KEY ,SUM(RE3_RECHARGE_AMT) RECHARGE_AMOUNT,'$V2'
FROM L3_RECHARGE PARTITION($v1) P
WHERE RE30_ENTRY_DATE_KEY = (SELECT DATE_KEY FROM DATE_DIM  WHERE DATE_VALUE = TO_DATE(sysdate-1,'DD/MM/RRRR'))
GROUP BY RE30_ENTRY_DATE_KEY;
COMMIT;
EXIT
EOF
}

# ======= SMSC SECTION =====.

lock=/data02/scripts/process/bin/shahin_demo1  export lock

if [ -f $lock ] ; then
exit 2

else
touch $lock

fileList=`get_partition`

for fil in $fileList
do

v1=`echo ${fil}|sed s/,/\ /g|awk '{print $1}'`   ###RECHARGE  partition

v2=`echo ${fil}|sed s/,/\ /g|awk '{print $2}'`   ###date_key

insert_script $v1 $v2 

done

rm -f $lock

fi

