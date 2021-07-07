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
SELECT PART||','||DATE_KEY
FROM
(SELECT 'DATA_'||A.DATE_KEY PART,B.DATE_KEY
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
    INSERT INTO MSISDN_DATA_FOR_SYSDATE_1_LD
    SELECT '$2',MSISDN,G379_CALLINGCELLID,MAX(LCOUNT) AS LCOUNT
    FROM
    (SELECT G372_CALLINGPARTYNUMBER AS MSISDN,G379_CALLINGCELLID, COUNT(G372_CALLINGPARTYNUMBER) LCOUNT
    FROM L3_DATA PARTITION ($1)
    WHERE G383_CHARGINGTIME_KEY = $2
    GROUP BY G372_CALLINGPARTYNUMBER,G379_CALLINGCELLID
    )
    GROUP BY MSISDN,G379_CALLINGCELLID;
    COMMIT;
EXIT
EOF
}
# ======= SMSC SECTION =====

lock=/data02/scripts/process/bin/msisdn_compare_4  export lock

if [ -f $lock ] ; then
exit 2

else
touch $lock

fileList=`get_partition`

for fil in $fileList
do

v1=`echo ${fil}|sed s/,/\ /g|awk '{print $1}'`   ###partition
v2=`echo ${fil}|sed s/,/\ /g|awk '{print $2}'`   ### date_key

insert_script $v1 $v2

done

rm -f $lock

fi

