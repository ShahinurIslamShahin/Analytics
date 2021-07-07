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
SELECT VPART||','||DPART||','||RPART||','||DATE_KEY
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
INSERT INTO RECHARGE_LOCATION_FCT
SELECT '$4',MSISDN,CALLINGCELLID,CHARGINGTIME
FROM
(
SELECT MSISDN,CALLINGCELLID,CHARGINGTIME,RANK ()OVER(PARTITION BY MSISDN ORDER BY CHARGINGTIME)FS
FROM
(SELECT MSISDN,CALLINGCELLID, TO_NUMBER(TRIM(LEADING '-' FROM ACHARGINGTIME)) CHARGINGTIME
FROM
(SELECT A.MSISDN,A.CALLINGCELLID,A.CHARGINGTIME-B.CHARGINGTIME ACHARGINGTIME
FROM
(SELECT MSISDN ,CALLINGCELLID,CHARGINGTIME
FROM
(SELECT V372_CALLINGPARTYNUMBER AS MSISDN ,V381_CALLINGCELLID AS CALLINGCELLID,V387_CHARGINGTIME_HOUR AS CHARGINGTIME
FROM L3_VOICE PARTITION ($1)
WHERE V387_CHARGINGTIME_KEY=(SELECT DATE_KEY FROM DATE_DIM WHERE TRUNC(DATE_VALUE)=TRUNC(SYSDATE-1))
AND V378_SERVICEFLOW=1
UNION ALL 
SELECT V373_CALLEDPARTYNUMBER AS MSISDN,V383_CALLEDCELLID AS CALLINGCELLID ,V387_CHARGINGTIME_HOUR AS CHARGINGTIME
FROM L3_VOICE PARTITION ($1)
WHERE V387_CHARGINGTIME_KEY=(SELECT DATE_KEY FROM DATE_DIM WHERE TRUNC(DATE_VALUE)=TRUNC(SYSDATE-1))
AND V378_SERVICEFLOW=2
UNION ALL 
SELECT MSISDN, SUBSTR(G379_CALLINGCELLID,16,30) CALLINGCELLID,CHARGINGTIME
FROM
(SELECT G372_CALLINGPARTYNUMBER MSISDN, LPAD(G379_CALLINGCELLID,30,0) G379_CALLINGCELLID,G383_CHARGINGTIME_HOUR AS CHARGINGTIME
FROM L3_DATA  PARTITION ($2)
WHERE G383_CHARGINGTIME_KEY=(SELECT DATE_KEY FROM DATE_DIM WHERE TRUNC(DATE_VALUE)=TRUNC(SYSDATE-1))
)
)
GROUP BY MSISDN ,CALLINGCELLID,CHARGINGTIME
)A,
(SELECT RE6_PRI_IDENTITY AS MSISDN,RE30_ENTRY_HOUR AS CHARGINGTIME
FROM L3_RECHARGE PARTITION ($3)
WHERE RE30_ENTRY_DATE_KEY=(SELECT DATE_KEY FROM DATE_DIM WHERE TRUNC(DATE_VALUE)=TRUNC(SYSDATE-1))
GROUP BY RE6_PRI_IDENTITY,RE30_ENTRY_HOUR)B
WHERE B.MSISDN=A.MSISDN
--AND A.CHARGINGTIME=B.CHARGINGTIME
)
GROUP BY MSISDN,CALLINGCELLID,ACHARGINGTIME
UNION ALL
SELECT MSISDN,CALLINGCELLID,TO_NUMBER(TRIM(LEADING '-' FROM BCHARGINGTIME))CHARGINGTIME
FROM
(SELECT A.MSISDN,A.CALLINGCELLID,B.CHARGINGTIME-A.CHARGINGTIME BCHARGINGTIME
FROM
(SELECT MSISDN ,CALLINGCELLID,CHARGINGTIME
FROM
(SELECT V372_CALLINGPARTYNUMBER AS MSISDN ,V381_CALLINGCELLID AS CALLINGCELLID,V387_CHARGINGTIME_HOUR AS CHARGINGTIME
FROM L3_VOICE PARTITION ($1)
WHERE V378_SERVICEFLOW=1
UNION ALL 
SELECT V373_CALLEDPARTYNUMBER AS MSISDN,V383_CALLEDCELLID AS CALLINGCELLID ,V387_CHARGINGTIME_HOUR AS CHARGINGTIME
FROM L3_VOICE PARTITION ($1)
WHERE V378_SERVICEFLOW=2
UNION ALL 
SELECT MSISDN, SUBSTR(G379_CALLINGCELLID,16,30) CALLINGCELLID,CHARGINGTIME
FROM
(SELECT G372_CALLINGPARTYNUMBER MSISDN, LPAD(G379_CALLINGCELLID,30,0) G379_CALLINGCELLID,G383_CHARGINGTIME_HOUR AS CHARGINGTIME
FROM L3_DATA  PARTITION ($2)
WHERE G383_CHARGINGTIME_KEY=(SELECT DATE_KEY FROM DATE_DIM WHERE TRUNC(DATE_VALUE)=TRUNC(SYSDATE-1))
)
)
GROUP BY MSISDN ,CALLINGCELLID,CHARGINGTIME
)A,
(SELECT RE6_PRI_IDENTITY AS MSISDN,RE30_ENTRY_HOUR AS CHARGINGTIME
FROM L3_RECHARGE PARTITION ($3)
GROUP BY RE6_PRI_IDENTITY,RE30_ENTRY_HOUR)B
WHERE B.MSISDN=A.MSISDN
--AND A.CHARGINGTIME=B.CHARGINGTIME
)
GROUP BY MSISDN,CALLINGCELLID,BCHARGINGTIME
)
GROUP BY MSISDN,CALLINGCELLID,CHARGINGTIME
)
WHERE FS =1;
COMMIT;
EXIT
EOF
}


# ======= SMSC SECTION =====.

lock=/data02/scripts/process/bin/location_fct/recharge_location_fct_log  export lock

if [ -f $lock ] ; then
exit 2

else
touch $lock

fileList=`get_partition`

for fil in $fileList
do

v1=`echo ${fil}|sed s/,/\ /g|awk '{print $1}'`   ###VOICE partition
v2=`echo ${fil}|sed s/,/\ /g|awk '{print $2}'`   ###DATA partition
v3=`echo ${fil}|sed s/,/\ /g|awk '{print $3}'`   ###RECHARGE partition
v4=`echo ${fil}|sed s/,/\ /g|awk '{print $4}'`   ###date_key


insert_script $v1 $v2 $v3 $v4

done

rm -f $lock

fi

