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
SELECT VPART||','||DPART||','||DATE_KEY
FROM
(SELECT 'VOICE_'||A.DATE_KEY VPART,'SMS_'||A.DATE_KEY SPART,'DATA_'||A.DATE_KEY DPART, 'RECHARGE_'||A.DATE_KEY RPART,B.DATE_KEY
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
----------------------------------
INSERT INTO LOCATION_FCT(DATE_KEY,MSISDN,CALLINGCELLID)
SELECT /*+ parallel (F,16)*/ '$3' as DATE_KEY, MSISDN,CALLINGCELLID
FROM
(
select /*+ parallel (MM,16)*/ distinct MSISDN,CALLINGCELLID,max(lcount) as lcount
from
(
select /*+ parallel (VV,16)*/ MSISDN,CALLINGCELLID,lcount
from
(select /*+ parallel (V,16)*/ distinct MSISDN,V381_CALLINGCELLID as CALLINGCELLID,max(lcount) as lcount
from(
SELECT V372_CALLINGPARTYNUMBER AS MSISDN,V381_CALLINGCELLID,V387_CHARGINGTIME_KEY,count(V372_CALLINGPARTYNUMBER) as lcount
FROM L3_voice partition($1)
WHERE V387_CHARGINGTIME_KEY = (SELECT DATE_KEY FROM DATE_DIM WHERE TRUNC(DATE_VALUE)=TRUNC(SYSDATE-1))
and V378_SERVICEFLOW=1
GROUP BY V372_CALLINGPARTYNUMBER,V381_CALLINGCELLID,V387_CHARGINGTIME_KEY
)V
group by MSISDN,V381_CALLINGCELLID
)VV
union all
select /*+ parallel (DD,16)*/ MSISDN,CALLINGCELLID,lcount
from
(select /*+ parallel (D,16)*/ distinct MSISDN,substr(G379_CALLINGCELLID,16,30) as CALLINGCELLID,max(lcount) as lcount
from
    (select MSISDN,lpad(G379_CALLINGCELLID,30,0) as G379_CALLINGCELLID,G383_CHARGINGTIME_KEY,lcount
    from
        (
        SELECT G372_CALLINGPARTYNUMBER AS MSISDN,G379_CALLINGCELLID,G383_CHARGINGTIME_KEY,count(G372_CALLINGPARTYNUMBER) as lcount
        FROM L3_DATA partition($2)
        WHERE G383_CHARGINGTIME_KEY = (SELECT DATE_KEY FROM DATE_DIM WHERE TRUNC(DATE_VALUE)=TRUNC(SYSDATE-1))
        GROUP BY G372_CALLINGPARTYNUMBER,G379_CALLINGCELLID,G383_CHARGINGTIME_KEY
        )
    group by MSISDN,lpad(G379_CALLINGCELLID,30,0),G383_CHARGINGTIME_KEY,lcount
    )D
group by MSISDN,substr(G379_CALLINGCELLID,16,30)
)DD
)MM
group by MSISDN,CALLINGCELLID
)F;

COMMIT;

EXIT
EOF
}

# ======= SMSC SECTION =====.

lock=/data02/scripts/process/bin/location_fct/location_fct_log  export lock

if [ -f $lock ] ; then
exit 2

else
touch $lock

fileList=`get_partition`

for fil in $fileList
do

v1=`echo ${fil}|sed s/,/\ /g|awk '{print $1}'`   ###VOICE partition
v2=`echo ${fil}|sed s/,/\ /g|awk '{print $2}'`   ###DATA partition
v3=`echo ${fil}|sed s/,/\ /g|awk '{print $3}'`   ###date_key


insert_script $v1 $v2 $v3

done

rm -f $lock

fi

