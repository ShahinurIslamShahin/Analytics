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
SELECT VPART||','||SPART||','||DPART||','||RPART||','||DATE_KEY
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
--WHENEVER SQLERROR EXIT SQL.SQLCODE
------------------------------------------------------
-------------INSER LAST_ACTIVITY_FCT_LD-------------
INSERT INTO LAST_ACTIVITY_FCT_LD (MSISDN,SNAPSHOT_DATE_KEY,SUBSCRIPTION_KEY)
SELECT /* + PARALLEL (A,16) */
SERVICE_NUMBER, 
'$v5', 
SUBSCRIPTION_KEY
FROM SUBSCRIPTION_DIM A, DATE_DIM B
WHERE B.DATE_KEY = (SELECT DATE_KEY FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD'))
AND SERVICE_NUMBER NOT IN (SELECT MSISDN FROM LAST_ACTIVITY_FCT_LD) ;
COMMIT; 

---##======MOC===========##
---==LU_MOC_DATE_KEY,LU_MOC_TIME_KEY==============---
MERGE INTO /* + PARALLEL (A,16) */ LAST_ACTIVITY_FCT_LD A
    USING (SELECT K.V372_CALLINGPARTYNUMBER  AS MSISDN ,K.V387_CHARGINGTIME_KEY AS CHARGINGTIME_KEY,K.V387_CHARGINGTIME_HOUR AS CHARGINGTIME_HOUR
            FROM (SELECT A.V372_CALLINGPARTYNUMBER,A.V387_CHARGINGTIME_KEY, A.V387_CHARGINGTIME_HOUR, RANK() OVER (PARTITION BY A.V372_CALLINGPARTYNUMBER ORDER BY A.V387_CHARGINGTIME_KEY DESC,A.V387_CHARGINGTIME_HOUR DESC) AS LAST_KEY
                   FROM
                    (SELECT  /* + PARALLEL (V,16) */ V.V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY, V387_CHARGINGTIME_HOUR
                        FROM L3_VOICE PARTITION ($v1) V
                        WHERE V378_SERVICEFLOW =1
                        AND V.V387_CHARGINGTIME_KEY=(SELECT DATE_KEY FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD'))
                        GROUP BY V372_CALLINGPARTYNUMBER,V387_CHARGINGTIME_KEY,V387_CHARGINGTIME_HOUR)A
                        ) K 
    WHERE LAST_KEY=1)V 
    ON (A.MSISDN = V.MSISDN) 
    WHEN MATCHED THEN
    UPDATE SET A.LU_MOC_DATE_KEY=V.CHARGINGTIME_KEY,
               A.LU_MOC_TIME_KEY=V.CHARGINGTIME_HOUR;
COMMIT;


---==============LU_MOC_PRODUCT_KEY=------------
MERGE INTO /* + PARALLEL (A,16) */ LAST_ACTIVITY_FCT_LD A
    USING (SELECT K.V372_CALLINGPARTYNUMBER AS MSISDN ,K.V397_MAINOFFERINGID AS MAINOFFERINGID
        FROM 
            (SELECT A.V372_CALLINGPARTYNUMBER, A.V387_CHARGINGTIME_KEY,V397_MAINOFFERINGID, RANK() OVER (PARTITION BY A.V372_CALLINGPARTYNUMBER ORDER BY A.V387_CHARGINGTIME_KEY DESC, A.V397_MAINOFFERINGID DESC) AS LAST_KEY
                FROM
                (SELECT  /* + PARALLEL (V,16) */ V.V372_CALLINGPARTYNUMBER,V. V387_CHARGINGTIME_KEY,V397_MAINOFFERINGID
                FROM L3_VOICE PARTITION ($v1) V
                WHERE V378_SERVICEFLOW =1
                AND V.V387_CHARGINGTIME_KEY=(SELECT DATE_KEY FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD'))  
                GROUP BY V372_CALLINGPARTYNUMBER,V387_CHARGINGTIME_KEY,V397_MAINOFFERINGID)A
            ) K 
        WHERE LAST_KEY=1)V 
    ON (A.MSISDN = V.MSISDN) 
    WHEN MATCHED THEN
    UPDATE SET A.LU_MOC_PRODUCT_KEY=V.MAINOFFERINGID;
COMMIT;

-------------------------LU_MOC_GEOGRAPHY_KEY-------------------
MERGE INTO /* + PARALLEL (A,16) */ LAST_ACTIVITY_FCT_LD A
    USING (SELECT K.V372_CALLINGPARTYNUMBER AS MSISDN,K.V381_CALLINGCELLID  AS CALLINGCELLID 
        FROM 
            (SELECT A.V372_CALLINGPARTYNUMBER, A.V387_CHARGINGTIME_KEY, A.V381_CALLINGCELLID, RANK() OVER (PARTITION BY A.V372_CALLINGPARTYNUMBER ORDER BY A.V387_CHARGINGTIME_KEY DESC, V381_CALLINGCELLID DESC) AS LAST_KEY
                FROM
                (SELECT  /* + PARALLEL (V,16) */ V.V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY, V.V381_CALLINGCELLID
                FROM L3_VOICE PARTITION ($v1) V
                WHERE V378_SERVICEFLOW =1
                AND V.V387_CHARGINGTIME_KEY=(SELECT DATE_KEY FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD'))   
                GROUP BY V.V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY,V.V381_CALLINGCELLID)A
            ) K 
        WHERE LAST_KEY=1)V
    ON (A.MSISDN = V.MSISDN) 
    WHEN MATCHED THEN
    UPDATE SET A.LU_MOC_GEOGRAPHY_KEY=V.CALLINGCELLID;
COMMIT;
        

---------------------LU_MOC_ACTUAL_DURATION----------------------
MERGE INTO /* + PARALLEL (A,16) */ LAST_ACTIVITY_FCT_LD A
    USING(SELECT K.V372_CALLINGPARTYNUMBER AS MSISDN,K.V35_RATE_USAGE
        FROM 
            (SELECT A.V372_CALLINGPARTYNUMBER, A.V35_RATE_USAGE, RANK() OVER (PARTITION BY A.V372_CALLINGPARTYNUMBER ORDER BY A.V387_CHARGINGTIME_KEY DESC) AS LAST_KEY
                FROM
                (SELECT /* + PARALLEL (V,16) */ V.V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY,SUM(V.V35_RATE_USAGE) AS V35_RATE_USAGE
                FROM L3_VOICE PARTITION ($v1) V
                WHERE V378_SERVICEFLOW =1
                AND V.V387_CHARGINGTIME_KEY=(SELECT DATE_KEY FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD')) 
                GROUP BY V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY)A
            ) K 
        WHERE LAST_KEY=1)V
        ON (A.MSISDN = V.MSISDN) 
        WHEN MATCHED THEN
        UPDATE SET A.LU_MOC_ACTUAL_DURATION=V.V35_RATE_USAGE;
COMMIT;
        
----====LU_MOC_AIR_CHARGE================---
MERGE INTO /* + PARALLEL (A,16) */ LAST_ACTIVITY_FCT_LD A
USING (SELECT K.V372_CALLINGPARTYNUMBER AS MSISDN, K.V41_DEBIT_AMOUNT AS DEBIT_AMOUNT
        FROM 
            (SELECT A.V372_CALLINGPARTYNUMBER, A.V41_DEBIT_AMOUNT, RANK() OVER (PARTITION BY A.V372_CALLINGPARTYNUMBER ORDER BY A.V387_CHARGINGTIME_KEY DESC) AS LAST_KEY
                FROM
                (SELECT  /* + PARALLEL (V,16) */ V.V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY,SUM(V.V41_DEBIT_AMOUNT) AS V41_DEBIT_AMOUNT
                FROM L3_VOICE PARTITION ($v1) V
                WHERE V378_SERVICEFLOW =1
                AND V.V387_CHARGINGTIME_KEY=(SELECT DATE_KEY FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD')) 
                GROUP BY V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY)A
            ) K 
        WHERE LAST_KEY=1)V
        ON (A.MSISDN = V.MSISDN)
        WHEN MATCHED THEN
        UPDATE SET A.LU_MOC_AIR_CHARGE=V.DEBIT_AMOUNT;
COMMIT;


--##======MTC=====From MSC And CBS======##---

---==LU_MTC_DATE_KEY, LU_MTC_TIME_KEY======From MSC========---
MERGE INTO /* + PARALLEL (A,16) */ LAST_ACTIVITY_FCT_LD A
    USING (SELECT M04_MSISDNAPARTY MSISDN, M09_LOCATION, M08_CALLDUR,DATE_KEY,TIME_KEY
        FROM
        (SELECT DATE_KEY, M04_MSISDNAPARTY, M09_LOCATION, M08_CALLDUR,TIME_KEY,ROW_NUMBER() OVER (PARTITION BY M04_MSISDNAPARTY ORDER BY TIME_KEY DESC) AS LAST_KEY
        FROM  MTC_CALL_DURATION@DWH05TODWH03
        WHERE DATE_KEY=$5
        )
        WHERE LAST_KEY=1)V
    ON (A.MSISDN = V.MSISDN)
    WHEN MATCHED THEN
    UPDATE SET A.LU_MTC_DATE_KEY=V.DATE_KEY,
               A.LU_MTC_TIME_KEY=V.TIME_KEY,
               A.LU_MTC_GEOGRAPHY_KEY=V.M09_LOCATION,
               A.LU_MTC_ACTUAL_DURATION=V.M08_CALLDUR;
COMMIT;


---==============LU_MTC_PRODUCT_KEY=------------
MERGE INTO /* + PARALLEL (A,16) */ LAST_ACTIVITY_FCT_LD A
    USING (SELECT K.V373_CALLEDPARTYNUMBER AS MSISDN ,K.V397_MAINOFFERINGID AS MAINOFFERINGID
        FROM 
            (SELECT A.V373_CALLEDPARTYNUMBER, A.V387_CHARGINGTIME_KEY,V397_MAINOFFERINGID, RANK() OVER (PARTITION BY A.V373_CALLEDPARTYNUMBER ORDER BY A.V387_CHARGINGTIME_KEY DESC, A.V397_MAINOFFERINGID DESC) AS LAST_KEY
                FROM
                (SELECT /* + PARALLEL (V,16) */  V.V373_CALLEDPARTYNUMBER,V. V387_CHARGINGTIME_KEY,V397_MAINOFFERINGID
                FROM L3_VOICE PARTITION ($v1) V
                WHERE V378_SERVICEFLOW =2
                AND V.V387_CHARGINGTIME_KEY=(SELECT DATE_KEY FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD')) 
                GROUP BY V373_CALLEDPARTYNUMBER,V387_CHARGINGTIME_KEY,V397_MAINOFFERINGID)A
            ) K 
        WHERE LAST_KEY=1)V 
    ON (A.MSISDN = V.MSISDN) 
    WHEN MATCHED THEN
    UPDATE SET A.LU_MTC_PRODUCT_KEY=V.MAINOFFERINGID;
COMMIT;
------=LU_ON_NET_MOC_DATE_KEY============---

MERGE INTO /* + PARALLEL (A,16) */ LAST_ACTIVITY_FCT_LD A
    USING (SELECT K.V372_CALLINGPARTYNUMBER  AS MSISDN ,K.V387_CHARGINGTIME_KEY AS CHARGINGTIME_KEY,K.V387_CHARGINGTIME_HOUR AS CHARGINGTIME_HOUR
            FROM (SELECT A.V372_CALLINGPARTYNUMBER,A.V387_CHARGINGTIME_KEY, A.V387_CHARGINGTIME_HOUR, RANK() OVER (PARTITION BY A.V372_CALLINGPARTYNUMBER ORDER BY A.V387_CHARGINGTIME_KEY DESC,A.V387_CHARGINGTIME_HOUR DESC) AS LAST_KEY
                   FROM
                    (SELECT /* + PARALLEL (V,16) */  V.V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY, V387_CHARGINGTIME_HOUR
                        FROM L3_VOICE PARTITION ($v1) V
                        WHERE V378_SERVICEFLOW =1
                        AND V25_USAGE_SERVICE_TYPE=10
                        AND V.V387_CHARGINGTIME_KEY=(SELECT DATE_KEY FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD'))
                        GROUP BY V372_CALLINGPARTYNUMBER,V387_CHARGINGTIME_KEY,V387_CHARGINGTIME_HOUR)A
                        ) K 
    WHERE LAST_KEY=1)V 
    ON (A.MSISDN = V.MSISDN) 
    WHEN MATCHED THEN
    UPDATE SET A.LU_ON_NET_MOC_DATE_KEY=V.CHARGINGTIME_KEY,
               A.LU_ON_NET_MOC_TIME_KEY=V.CHARGINGTIME_HOUR;
COMMIT;

------=======LU_ON_NET_MOC_PRODUCT_KEY====---
MERGE INTO /* + PARALLEL (A,16) */ LAST_ACTIVITY_FCT_LD A
    USING (SELECT K.V372_CALLINGPARTYNUMBER AS MSISDN ,K.V397_MAINOFFERINGID AS MAINOFFERINGID
        FROM 
            (SELECT A.V372_CALLINGPARTYNUMBER, A.V387_CHARGINGTIME_KEY,V397_MAINOFFERINGID, RANK() OVER (PARTITION BY A.V372_CALLINGPARTYNUMBER ORDER BY A.V387_CHARGINGTIME_KEY DESC, A.V397_MAINOFFERINGID DESC) AS LAST_KEY
                FROM
                (SELECT /* + PARALLEL (V,16) */  V.V372_CALLINGPARTYNUMBER,V. V387_CHARGINGTIME_KEY,V397_MAINOFFERINGID
                FROM L3_VOICE PARTITION ($v1) V
                WHERE V378_SERVICEFLOW =1
                AND V25_USAGE_SERVICE_TYPE=10
                AND V.V387_CHARGINGTIME_KEY=(SELECT DATE_KEY FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD'))    
                GROUP BY V372_CALLINGPARTYNUMBER,V387_CHARGINGTIME_KEY,V397_MAINOFFERINGID)A
            ) K 
        WHERE LAST_KEY=1)V 
    ON (A.MSISDN = V.MSISDN) 
    WHEN MATCHED THEN
    UPDATE SET A.LU_ON_NET_MOC_PRODUCT_KEY=V.MAINOFFERINGID;
COMMIT;


------===============LU_ON_NET_MOC_ACTUAL_DURATION===============---
MERGE INTO /* + PARALLEL (A,16) */ LAST_ACTIVITY_FCT_LD A
    USING(SELECT K.V372_CALLINGPARTYNUMBER AS MSISDN,K.V35_RATE_USAGE
        FROM 
            (SELECT A.V372_CALLINGPARTYNUMBER, A.V35_RATE_USAGE, RANK() OVER (PARTITION BY A.V372_CALLINGPARTYNUMBER ORDER BY A.V387_CHARGINGTIME_KEY DESC) AS LAST_KEY
                FROM
                (SELECT /* + PARALLEL (V,16) */  V.V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY,COUNT(V.V35_RATE_USAGE) AS V35_RATE_USAGE
                FROM L3_VOICE PARTITION ($v1) V
                WHERE V378_SERVICEFLOW =1
                AND V25_USAGE_SERVICE_TYPE=10
                AND V.V387_CHARGINGTIME_KEY=(SELECT DATE_KEY FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD'))    
                GROUP BY V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY)A
            ) K 
        WHERE LAST_KEY=1)V
        ON (A.MSISDN = V.MSISDN) 
        WHEN MATCHED THEN
        UPDATE SET A.LU_ON_NET_MOC_ACTUAL_DURATION=V.V35_RATE_USAGE;
COMMIT;

------============LU_ON_NET_MOC_AIR_CHARGE===---

MERGE INTO /* + PARALLEL (A,16) */ LAST_ACTIVITY_FCT_LD A
USING (SELECT K.V372_CALLINGPARTYNUMBER AS MSISDN, K.V41_DEBIT_AMOUNT AS DEBIT_AMOUNT
        FROM 
            (SELECT A.V372_CALLINGPARTYNUMBER, A.V41_DEBIT_AMOUNT, RANK() OVER (PARTITION BY A.V372_CALLINGPARTYNUMBER ORDER BY A.V387_CHARGINGTIME_KEY DESC) AS LAST_KEY
                FROM
                (SELECT  /* + PARALLEL (V,16) */ V.V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY,SUM(V.V41_DEBIT_AMOUNT) AS V41_DEBIT_AMOUNT
                FROM L3_VOICE PARTITION ($v1) V
                WHERE V378_SERVICEFLOW =1
                AND V25_USAGE_SERVICE_TYPE=10
                AND V.V387_CHARGINGTIME_KEY=(SELECT DATE_KEY FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD'))  
                GROUP BY V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY)A
            ) K 
        WHERE LAST_KEY=1)V
        ON (A.MSISDN = V.MSISDN)
        WHEN MATCHED THEN
        UPDATE SET A.LU_ON_NET_MOC_AIR_CHARGE=V.DEBIT_AMOUNT;
COMMIT;

------=======LU_OFF_NET_MOC_DATE_KEY====---
MERGE INTO /* + PARALLEL (A,16) */ LAST_ACTIVITY_FCT_LD A
    USING (SELECT K.V372_CALLINGPARTYNUMBER  AS MSISDN ,K.V387_CHARGINGTIME_KEY AS CHARGINGTIME_KEY,K.V387_CHARGINGTIME_HOUR AS CHARGINGTIME_HOUR
            FROM (SELECT A.V372_CALLINGPARTYNUMBER,A.V387_CHARGINGTIME_KEY, A.V387_CHARGINGTIME_HOUR, RANK() OVER (PARTITION BY A.V372_CALLINGPARTYNUMBER ORDER BY A.V387_CHARGINGTIME_KEY DESC,A.V387_CHARGINGTIME_HOUR DESC) AS LAST_KEY
                   FROM
                    (SELECT  /* + PARALLEL (V,16) */ V.V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY, V387_CHARGINGTIME_HOUR
                        FROM L3_VOICE PARTITION ($v1) V
                        WHERE V378_SERVICEFLOW =1
                        AND V25_USAGE_SERVICE_TYPE=11
                        AND V.V387_CHARGINGTIME_KEY=(SELECT DATE_KEY FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD'))   
                        GROUP BY V372_CALLINGPARTYNUMBER,V387_CHARGINGTIME_KEY,V387_CHARGINGTIME_HOUR)A
                        ) K 
    WHERE LAST_KEY=1)V 
    ON (A.MSISDN = V.MSISDN) 
    WHEN MATCHED THEN
    UPDATE SET A.LU_OFF_NET_MOC_DATE_KEY=V.CHARGINGTIME_KEY,
               A.LU_OFF_NET_MOC_TIME_KEY=V.CHARGINGTIME_HOUR;
COMMIT;

------=======LU_OFF_NET_MOC_PRODUCT_KEY====---
MERGE INTO /* + PARALLEL (A,16) */ LAST_ACTIVITY_FCT_LD A
    USING (SELECT K.V372_CALLINGPARTYNUMBER AS MSISDN ,K.V397_MAINOFFERINGID AS MAINOFFERINGID
        FROM 
            (SELECT A.V372_CALLINGPARTYNUMBER, A.V387_CHARGINGTIME_KEY,V397_MAINOFFERINGID, RANK() OVER (PARTITION BY A.V372_CALLINGPARTYNUMBER ORDER BY A.V387_CHARGINGTIME_KEY DESC, A.V397_MAINOFFERINGID DESC) AS LAST_KEY
                FROM
                (SELECT  /* + PARALLEL (V,16) */ V.V372_CALLINGPARTYNUMBER,V. V387_CHARGINGTIME_KEY,V397_MAINOFFERINGID
                FROM L3_VOICE PARTITION ($v1) V
                WHERE V378_SERVICEFLOW =1
                AND V25_USAGE_SERVICE_TYPE=11
                AND V.V387_CHARGINGTIME_KEY=(SELECT DATE_KEY FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD'))    
                GROUP BY V372_CALLINGPARTYNUMBER,V387_CHARGINGTIME_KEY,V397_MAINOFFERINGID)A
            ) K 
        WHERE LAST_KEY=1)V 
    ON (A.MSISDN = V.MSISDN) 
    WHEN MATCHED THEN
    UPDATE SET A.LU_OFF_NET_MOC_PRODUCT_KEY=V.MAINOFFERINGID;
COMMIT;


------=========LU_OFF_NET_MOC_LOCATION_KEY==============---
MERGE INTO /* + PARALLEL (A,16) */ LAST_ACTIVITY_FCT_LD A
    USING (SELECT K.V372_CALLINGPARTYNUMBER AS MSISDN,K.V381_CALLINGCELLID  AS CALLINGCELLID 
        FROM 
            (SELECT A.V372_CALLINGPARTYNUMBER, A.V387_CHARGINGTIME_KEY, A.V381_CALLINGCELLID, RANK() OVER (PARTITION BY A.V372_CALLINGPARTYNUMBER ORDER BY A.V387_CHARGINGTIME_KEY DESC, V381_CALLINGCELLID DESC) AS LAST_KEY
                FROM
                (SELECT  /* + PARALLEL (V,16) */ V.V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY, V.V381_CALLINGCELLID
                FROM L3_VOICE PARTITION ($v1) V
                WHERE V378_SERVICEFLOW =1
                AND V25_USAGE_SERVICE_TYPE=11
                AND V.V387_CHARGINGTIME_KEY=(SELECT DATE_KEY FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD'))    
                GROUP BY V.V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY,V.V381_CALLINGCELLID)A
            ) K 
        WHERE LAST_KEY=1)V
    ON (A.MSISDN = V.MSISDN) 
    WHEN MATCHED THEN
    UPDATE SET A.LU_OFF_NET_MOC_LOCATION_KEY=V.CALLINGCELLID;
COMMIT;

---========LU_OFF_NET_MOC_ACTUAL_DURATION=========---

MERGE INTO /* + PARALLEL (A,16) */ LAST_ACTIVITY_FCT_LD A
    USING(SELECT K.V372_CALLINGPARTYNUMBER AS MSISDN,K.V35_RATE_USAGE
        FROM 
            (SELECT A.V372_CALLINGPARTYNUMBER, A.V35_RATE_USAGE, RANK() OVER (PARTITION BY A.V372_CALLINGPARTYNUMBER ORDER BY A.V387_CHARGINGTIME_KEY DESC) AS LAST_KEY
                FROM
                (SELECT /* + PARALLEL (V,16) */  V.V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY,COUNT(V.V35_RATE_USAGE) AS V35_RATE_USAGE
                FROM L3_VOICE PARTITION ($v1) V
                WHERE V378_SERVICEFLOW =1
                AND V25_USAGE_SERVICE_TYPE=11
                AND V.V387_CHARGINGTIME_KEY=(SELECT DATE_KEY FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD')) 
                GROUP BY V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY)A
            ) K 
        WHERE LAST_KEY=1)V
        ON (A.MSISDN = V.MSISDN) 
        WHEN MATCHED THEN
        UPDATE SET A.LU_OFF_NET_MOC_ACTUAL_DURATION=V.V35_RATE_USAGE;
COMMIT;


---==LU_OFF_NET_MOC_AIR_CHARGE==============-------
MERGE INTO /* + PARALLEL (A,16) */ LAST_ACTIVITY_FCT_LD A
USING (SELECT K.V372_CALLINGPARTYNUMBER AS MSISDN, K.V41_DEBIT_AMOUNT AS DEBIT_AMOUNT
        FROM 
            (SELECT A.V372_CALLINGPARTYNUMBER, A.V41_DEBIT_AMOUNT, RANK() OVER (PARTITION BY A.V372_CALLINGPARTYNUMBER ORDER BY A.V387_CHARGINGTIME_KEY DESC) AS LAST_KEY
                FROM
                (SELECT /* + PARALLEL (V,16) */  V.V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY,SUM(V.V41_DEBIT_AMOUNT) AS V41_DEBIT_AMOUNT
                FROM L3_VOICE PARTITION ($v1) V
                WHERE V378_SERVICEFLOW =1
                AND V25_USAGE_SERVICE_TYPE=11
                AND V.V387_CHARGINGTIME_KEY=(SELECT DATE_KEY FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD'))  
                GROUP BY V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY)A
            ) K 
        WHERE LAST_KEY=1)V
        ON (A.MSISDN = V.MSISDN)
        WHEN MATCHED THEN
        UPDATE SET A.LU_OFF_NET_MOC_AIR_CHARGE=V.DEBIT_AMOUNT;
COMMIT;

---##============SMS====##
---==========LU_MOSMS_DATE_KEY,LU_MOSMS_TIME_KEY============---
MERGE INTO /* + PARALLEL (A,16) */ LAST_ACTIVITY_FCT_LD A
    USING (SELECT K.S372_CALLINGPARTYNUMBER  AS MSISDN ,K.S387_CHARGINGTIME_KEY AS CHARGINGTIME_KEY,K.S387_CHARGINGTIME_HOUR AS CHARGINGTIME_HOUR
            FROM (SELECT A.S372_CALLINGPARTYNUMBER,A.S387_CHARGINGTIME_KEY, A.S387_CHARGINGTIME_HOUR, RANK() OVER (PARTITION BY A.S372_CALLINGPARTYNUMBER ORDER BY A.S387_CHARGINGTIME_KEY DESC,A.S387_CHARGINGTIME_HOUR DESC) AS LAST_KEY
                   FROM
                    (SELECT  /* + PARALLEL (V,16) */ V.S372_CALLINGPARTYNUMBER,V.S387_CHARGINGTIME_KEY, S387_CHARGINGTIME_HOUR
                        FROM L3_SMS PARTITION ($v2) V
                        WHERE S378_SERVICEFLOW =1
                        AND V.S387_CHARGINGTIME_KEY=(SELECT DATE_KEY FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD')) 
                        GROUP BY S372_CALLINGPARTYNUMBER,S387_CHARGINGTIME_KEY,S387_CHARGINGTIME_HOUR)A
                        ) K 
    WHERE LAST_KEY=1)V 
    ON (A.MSISDN = V.MSISDN) 
    WHEN MATCHED THEN
    UPDATE SET A.LU_MOSMS_DATE_KEY=V.CHARGINGTIME_KEY,
               A.LU_MOSMS_TIME_KEY=V.CHARGINGTIME_HOUR;
COMMIT;


---======LU_MOSMS_PRODUCT_KEY========---

MERGE INTO /* + PARALLEL (A,16) */ LAST_ACTIVITY_FCT_LD A
    USING (SELECT K.S372_CALLINGPARTYNUMBER AS MSISDN ,K.S395_MAINOFFERINGID AS MAINOFFERINGID
        FROM 
            (SELECT A.S372_CALLINGPARTYNUMBER, A.S387_CHARGINGTIME_KEY,S395_MAINOFFERINGID, RANK() OVER (PARTITION BY A.S372_CALLINGPARTYNUMBER ORDER BY A.S387_CHARGINGTIME_KEY DESC, A.S395_MAINOFFERINGID DESC) AS LAST_KEY
                FROM
                (SELECT /* + PARALLEL (V,16) */  V.S372_CALLINGPARTYNUMBER,V.S387_CHARGINGTIME_KEY,S395_MAINOFFERINGID
                FROM L3_SMS PARTITION ($v2) V
                WHERE S378_SERVICEFLOW =1
                AND V.S372_CALLINGPARTYNUMBER=(SELECT DATE_KEY FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD'))   
                GROUP BY S372_CALLINGPARTYNUMBER,S387_CHARGINGTIME_KEY,S395_MAINOFFERINGID)A
            ) K 
        WHERE LAST_KEY=1)V 
    ON (A.MSISDN = V.MSISDN) 
    WHEN MATCHED THEN
    UPDATE SET A.LU_MOSMS_PRODUCT_KEY=V.MAINOFFERINGID;
COMMIT;


---=LU_MOSMS_GEOGRAPHY_KEY====---

MERGE INTO /* + PARALLEL (A,16) */ LAST_ACTIVITY_FCT_LD A
    USING (SELECT K.S372_CALLINGPARTYNUMBER AS MSISDN,K.S381_CALLINGCELLID  AS CALLINGCELLID 
        FROM 
            (SELECT A.S372_CALLINGPARTYNUMBER, A.S387_CHARGINGTIME_KEY, A.S381_CALLINGCELLID, RANK() OVER (PARTITION BY A.S372_CALLINGPARTYNUMBER ORDER BY A.S387_CHARGINGTIME_KEY DESC, S381_CALLINGCELLID DESC) AS LAST_KEY
                FROM
                (SELECT  /* + PARALLEL (V,16) */ V.S372_CALLINGPARTYNUMBER,V.S387_CHARGINGTIME_KEY, V.S381_CALLINGCELLID
                FROM L3_SMS PARTITION ($v2) V
                WHERE S378_SERVICEFLOW =1
                AND V.S372_CALLINGPARTYNUMBER=(SELECT DATE_KEY FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD'))  
                GROUP BY V.S372_CALLINGPARTYNUMBER,V.S387_CHARGINGTIME_KEY,V.S381_CALLINGCELLID)A
            ) K 
        WHERE LAST_KEY=1)V
    ON (A.MSISDN = V.MSISDN) 
    WHEN MATCHED THEN
    UPDATE SET A.LU_MOSMS_GEOGRAPHY_KEY=V.CALLINGCELLID;
COMMIT;


---========LU_MOSMS_AIR_CHARGE=================---

MERGE INTO /* + PARALLEL (A,16) */ LAST_ACTIVITY_FCT_LD A
USING (SELECT K.S372_CALLINGPARTYNUMBER AS MSISDN, K.S41_DEBIT_AMOUNT AS DEBIT_AMOUNT
        FROM 
            (SELECT A.S372_CALLINGPARTYNUMBER, A.S41_DEBIT_AMOUNT, RANK() OVER (PARTITION BY A.S372_CALLINGPARTYNUMBER ORDER BY A.S387_CHARGINGTIME_KEY DESC) AS LAST_KEY
                FROM
                (SELECT /* + PARALLEL (V,16) */  V.S372_CALLINGPARTYNUMBER,V.S387_CHARGINGTIME_KEY,SUM(V.S41_DEBIT_AMOUNT) AS S41_DEBIT_AMOUNT
                FROM L3_SMS PARTITION ($v2) V
                WHERE S378_SERVICEFLOW =1
                AND V.S372_CALLINGPARTYNUMBER=(SELECT DATE_KEY FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD'))
                GROUP BY S372_CALLINGPARTYNUMBER,V.S387_CHARGINGTIME_KEY)A
            ) K 
        WHERE LAST_KEY=1)V
        ON (A.MSISDN = V.MSISDN)
        WHEN MATCHED THEN
        UPDATE SET A.LU_MOSMS_AIR_CHARGE=V.DEBIT_AMOUNT;
COMMIT;
--==##========SMSMT from MSC==========##==--

---==LU_MTSMS_DATE_KEY, LU_MTSMS_TIME_KEY, LU_MTSMS_GEOGRAPHY_KEY==============---
MERGE INTO /* + PARALLEL (A,16) */ LAST_ACTIVITY_FCT_LD A
    USING (SELECT  M04_MSISDNAPARTY as MSISDN, M09_LOCATION, COUNT,DATE_KEY, TIME_KEY
        FROM
        (SELECT DATE_KEY, TIME_KEY, M04_MSISDNAPARTY, M09_LOCATION, COUNT,ROW_NUMBER() OVER (PARTITION BY M04_MSISDNAPARTY ORDER BY TIME_KEY DESC) AS LAST_KEY
        FROM  MTSMS_COUNT@DWH05TODWH03
        WHERE DATE_KEY=$5
        )
        WHERE LAST_KEY=1)V
    ON (A.MSISDN = V.MSISDN)
    WHEN MATCHED THEN
    UPDATE SET A.LU_MTSMS_DATE_KEY=V.DATE_KEY,
               A.LU_MTSMS_TIME_KEY=V.TIME_KEY,
               A.LU_MTSMS_GEOGRAPHY_KEY=V.M09_LOCATION;
COMMIT;


---================LU_GPRS_DATE_KEY,LU_GPRS_TIME_KEY===========-

MERGE INTO /* + PARALLEL (A,16) */ LAST_ACTIVITY_FCT_LD A
    USING (SELECT K.G372_CALLINGPARTYNUMBER  AS MSISDN ,K.G383_CHARGINGTIME_KEY AS CHARGINGTIME_KEY,K.G383_CHARGINGTIME_HOUR AS CHARGINGTIME_HOUR
            FROM (SELECT A.G372_CALLINGPARTYNUMBER,A.G383_CHARGINGTIME_KEY, A.G383_CHARGINGTIME_HOUR, RANK() OVER (PARTITION BY A.G372_CALLINGPARTYNUMBER ORDER BY A.G383_CHARGINGTIME_KEY DESC,A.G383_CHARGINGTIME_HOUR DESC) AS LAST_KEY
                   FROM
                    (SELECT /* + PARALLEL (V,16) */  V.G372_CALLINGPARTYNUMBER,V.G383_CHARGINGTIME_KEY, V.G383_CHARGINGTIME_HOUR
                        FROM L3_DATA  PARTITION ($v3) V
                        WHERE V.G383_CHARGINGTIME_KEY=(SELECT DATE_KEY FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD'))
                        GROUP BY G372_CALLINGPARTYNUMBER,G383_CHARGINGTIME_KEY,G383_CHARGINGTIME_HOUR)A
                        ) K 
    WHERE LAST_KEY=1)V 
    ON (A.MSISDN = V.MSISDN) 
    WHEN MATCHED THEN
    UPDATE SET A.LU_GPRS_DATE_KEY=V.CHARGINGTIME_KEY,
               A.LU_GPRS_TIME_KEY=V.CHARGINGTIME_HOUR;
COMMIT;

---==============LU_GPRS_GEOGRAPHY_KEY====---

MERGE INTO /* + PARALLEL (A,16) */ LAST_ACTIVITY_FCT_LD A
    USING (SELECT K.G372_CALLINGPARTYNUMBER AS MSISDN,K.G379_CALLINGCELLID  AS CALLINGCELLID 
        FROM 
            (SELECT A.G372_CALLINGPARTYNUMBER, A.G383_CHARGINGTIME_KEY, A.G379_CALLINGCELLID, RANK() OVER (PARTITION BY A.G372_CALLINGPARTYNUMBER ORDER BY A.G383_CHARGINGTIME_KEY DESC, G379_CALLINGCELLID DESC) AS LAST_KEY
                FROM
                (SELECT  /* + PARALLEL (V,16) */ V.G372_CALLINGPARTYNUMBER,V.G383_CHARGINGTIME_KEY, V.G379_CALLINGCELLID
                FROM L3_DATA  PARTITION ($v3) V
                WHERE V.G383_CHARGINGTIME_KEY=(SELECT DATE_KEY FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD'))   
                GROUP BY V.G372_CALLINGPARTYNUMBER,V.G383_CHARGINGTIME_KEY,V.G379_CALLINGCELLID)A
            ) K 
        WHERE LAST_KEY=1)V
    ON (A.MSISDN = V.MSISDN) 
    WHEN MATCHED THEN
    UPDATE SET A.LU_GPRS_GEOGRAPHY_KEY=V.CALLINGCELLID;
COMMIT;

---===========LU_GPRS_PRODUCT_KEY===---

MERGE INTO /* + PARALLEL (A,16) */ LAST_ACTIVITY_FCT_LD A
    USING (SELECT K.G372_CALLINGPARTYNUMBER AS MSISDN ,K.G401_MAINOFFERINGID AS MAINOFFERINGID
        FROM 
            (SELECT A.G372_CALLINGPARTYNUMBER, A.G383_CHARGINGTIME_KEY,G401_MAINOFFERINGID, RANK() OVER (PARTITION BY A.G372_CALLINGPARTYNUMBER ORDER BY A.G383_CHARGINGTIME_KEY DESC, A.G401_MAINOFFERINGID DESC) AS LAST_KEY
                FROM
                (SELECT /* + PARALLEL (V,16) */  V.G372_CALLINGPARTYNUMBER,V.G383_CHARGINGTIME_KEY,G401_MAINOFFERINGID
                FROM L3_DATA  PARTITION ($v3) V
                WHERE V.G383_CHARGINGTIME_KEY=(SELECT DATE_KEY FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD'))
                GROUP BY G372_CALLINGPARTYNUMBER,G383_CHARGINGTIME_KEY,G401_MAINOFFERINGID)A
            ) K 
        WHERE LAST_KEY=1)V 
    ON (A.MSISDN = V.MSISDN) 
    WHEN MATCHED THEN
    UPDATE SET A.LU_GPRS_PRODUCT_KEY=V.MAINOFFERINGID;
COMMIT;

---============LU_GPRS_DATA_SIZE====---

MERGE INTO /* + PARALLEL (A,16) */ LAST_ACTIVITY_FCT_LD A
    USING (SELECT K.G372_CALLINGPARTYNUMBER AS MSISDN,K.G384_TOTALFLUX  AS TOTALFLUX 
        FROM 
            (SELECT A.G372_CALLINGPARTYNUMBER, A.G383_CHARGINGTIME_KEY,A.G383_CHARGINGTIME_HOUR, A.G384_TOTALFLUX, RANK() OVER (PARTITION BY A.G372_CALLINGPARTYNUMBER ORDER BY A.G383_CHARGINGTIME_KEY DESC,A.G383_CHARGINGTIME_HOUR DESC, A.G384_TOTALFLUX DESC) AS LAST_KEY
                FROM
                (SELECT /* + PARALLEL (V,16) */  V.G372_CALLINGPARTYNUMBER,V.G383_CHARGINGTIME_KEY, G383_CHARGINGTIME_HOUR, SUM(NVL(V.G384_TOTALFLUX,0)) / 1048576 AS G384_TOTALFLUX
                FROM L3_DATA  PARTITION ($v3) V
                WHERE V.G383_CHARGINGTIME_KEY=(SELECT DATE_KEY FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD'))   
                GROUP BY V.G372_CALLINGPARTYNUMBER,V.G383_CHARGINGTIME_KEY,V.G384_TOTALFLUX, G383_CHARGINGTIME_HOUR)A
            ) K 
        WHERE LAST_KEY=1)V
    ON (A.MSISDN = V.MSISDN) 
    WHEN MATCHED THEN
    UPDATE SET A.LU_GPRS_DATA_SIZE=V.TOTALFLUX;
COMMIT;

---====LR_DATE_KEY,LR_TIME_KEY,LR_PRODUCT_KEY,LR_RECHARGE_TYPE_KEY---

MERGE INTO /* + PARALLEL (A,16) */ LAST_ACTIVITY_FCT_LD A
    USING (SELECT K.RE6_PRI_IDENTITY  AS MSISDN ,K.RE30_ENTRY_DATE_KEY AS CHARGINGTIME_KEY,K.RE30_ENTRY_HOUR AS CHARGINGTIME_HOUR, K.RE21_RECHARGE_TYPE AS RECHARGE_TYPE, K.RE489_MAINOFFERINGID AS MAINOFFERINGID
            FROM (SELECT A.RE6_PRI_IDENTITY,A.RE30_ENTRY_DATE_KEY, A.RE30_ENTRY_HOUR, A.RE21_RECHARGE_TYPE, A.RE489_MAINOFFERINGID,
                    RANK() OVER (PARTITION BY A.RE6_PRI_IDENTITY ORDER BY A.RE30_ENTRY_DATE_KEY DESC,A.RE30_ENTRY_HOUR DESC, A.RE21_RECHARGE_TYPE DESC,A.RE489_MAINOFFERINGID DESC) AS LAST_KEY
                   FROM
                    (SELECT /* + PARALLEL (V,16) */  V.RE6_PRI_IDENTITY,V.RE30_ENTRY_DATE_KEY, V.RE30_ENTRY_HOUR, V.RE21_RECHARGE_TYPE, RE489_MAINOFFERINGID
                        FROM L3_RECHARGE  PARTITION ($v4) V
                        WHERE V.RE30_ENTRY_DATE_KEY=(SELECT DATE_KEY FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD'))
                        GROUP BY RE6_PRI_IDENTITY,RE30_ENTRY_DATE_KEY,RE30_ENTRY_HOUR, RE21_RECHARGE_TYPE, RE489_MAINOFFERINGID)A
                        ) K 
    WHERE LAST_KEY=1)V 
    ON (A.MSISDN = V.MSISDN) 
    WHEN MATCHED THEN
    UPDATE SET A.LR_DATE_KEY=V.CHARGINGTIME_KEY,
               A.LR_TIME_KEY=V.CHARGINGTIME_HOUR,
               A.LR_PRODUCT_KEY=MAINOFFERINGID,
               A.LR_RECHARGE_TYPE_KEY=RECHARGE_TYPE;
COMMIT;

    MERGE INTO /* + PARALLEL (A,16) */ LAST_ACTIVITY_FCT_LD A
        USING (SELECT K.RE6_PRI_IDENTITY  AS MSISDN ,K.RE30_ENTRY_DATE_KEY AS CHARGINGTIME_KEY,K.RE30_ENTRY_HOUR AS CHARGINGTIME_HOUR
                FROM (SELECT A.RE6_PRI_IDENTITY,A.RE30_ENTRY_DATE_KEY, A.RE30_ENTRY_HOUR,
                        RANK() OVER (PARTITION BY A.RE6_PRI_IDENTITY ORDER BY A.RE30_ENTRY_DATE_KEY DESC,A.RE30_ENTRY_HOUR DESC) AS LAST_KEY
                       FROM
                        (SELECT /* + PARALLEL (V,16) */  V.RE6_PRI_IDENTITY,V.RE30_ENTRY_DATE_KEY, V.RE30_ENTRY_HOUR
                            FROM L3_RECHARGE  PARTITION ($v4) V
                            WHERE V.RE30_ENTRY_DATE_KEY=(SELECT DATE_KEY FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD'))
                            GROUP BY RE6_PRI_IDENTITY,RE30_ENTRY_DATE_KEY,RE30_ENTRY_HOUR)A
                            ) K 
        WHERE LAST_KEY=1)V 
        ON (A.MSISDN = V.MSISDN) 
        WHEN MATCHED THEN
        UPDATE SET A.LR_DATE_KEY=V.CHARGINGTIME_KEY,
                   A.LR_TIME_KEY=V.CHARGINGTIME_HOUR;
                   COMMIT;
---===============LU_DATE_KEY,LU_TIME_KEY===============-
MERGE INTO /*+ PARALLEL (A,16) */  LAST_ACTIVITY_FCT_LD A
USING (SELECT /*+ PARALLEL (X,16) */ X.MSISDN, X.DATE_KEY, X.TIME_KEY,X.PRODUCT_KEY,X.GEOGRAPHY_KEY
FROM
(SELECT /*+ PARALLEL (Z,16) */  Z.MSISDN, Z.DATE_KEY,Z.TIME_KEY,Z.PRODUCT_KEY,Z.GEOGRAPHY_KEY,RANK() OVER (PARTITION BY Z.MSISDN ORDER BY Z.DATE_KEY DESC,Z.TIME_KEY DESC) LAST_KEY
FROM
(SELECT /*+ PARALLEL (A,16) */  A.MSISDN, MAX(A.DATE_KEY) AS DATE_KEY ,MAX(A.TIME_KEY) AS TIME_KEY,MAX(A.PRODUCT_KEY) AS PRODUCT_KEY,MAX(A.GEOGRAPHY_KEY) AS GEOGRAPHY_KEY
FROM
(SELECT/*+ PARALLEL (LAST_ACTIVITY_FCT_LD,16) */ MSISDN,
NVL(LU_MOC_DATE_KEY,0) AS DATE_KEY ,
NVL(LU_MOC_TIME_KEY,0) AS TIME_KEY,
NVL(LU_MOC_PRODUCT_KEY,0) AS PRODUCT_KEY,
NVL(LU_MOC_GEOGRAPHY_KEY,0) AS GEOGRAPHY_KEY
FROM 
LAST_ACTIVITY_FCT_LD
UNION ALL
SELECT/*+ PARALLEL (LAST_ACTIVITY_FCT_LD,16) */ MSISDN,
NVL(LU_MTC_DATE_KEY,0) AS DATE_KEY ,
NVL(LU_MTC_TIME_KEY,0) AS TIME_KEY,
NVL(LU_MTC_PRODUCT_KEY,0) AS PRODUCT_KEY,
NVL(LU_MTC_GEOGRAPHY_KEY,0) AS GEOGRAPHY_KEY
FROM 
LAST_ACTIVITY_FCT_LD
UNION ALL
SELECT/*+ PARALLEL (LAST_ACTIVITY_FCT_LD,16) */ MSISDN,
NVL(LU_ON_NET_MOC_DATE_KEY,0) AS DATE_KEY ,
NVL(LU_ON_NET_MOC_TIME_KEY,0) AS TIME_KEY,
NVL(LU_ON_NET_MOC_PRODUCT_KEY,0) AS PRODUCT_KEY,
NULL AS GEOGRAPHY_KEY
FROM 
LAST_ACTIVITY_FCT_LD
UNION ALL
SELECT/*+ PARALLEL (LAST_ACTIVITY_FCT_LD,16) */ MSISDN,
NVL(LU_OFF_NET_MOC_DATE_KEY,0) AS DATE_KEY ,
NVL(LU_OFF_NET_MOC_TIME_KEY,0) AS TIME_KEY,
NVL(LU_OFF_NET_MOC_PRODUCT_KEY,0) AS PRODUCT_KEY,
NVL(LU_OFF_NET_MOC_LOCATION_KEY,0) AS GEOGRAPHY_KEY    
FROM 
LAST_ACTIVITY_FCT_LD
UNION ALL
SELECT/*+ PARALLEL (LAST_ACTIVITY_FCT_LD,16) */ MSISDN,
NVL(LU_MOSMS_DATE_KEY,0) AS DATE_KEY ,
NVL(LU_MOSMS_TIME_KEY,0) AS TIME_KEY,
NVL(LU_MOSMS_PRODUCT_KEY,0) AS PRODUCT_KEY,
NULL AS GEOGRAPHY_KEY
FROM 
LAST_ACTIVITY_FCT_LD
UNION ALL
SELECT/*+ PARALLEL (LAST_ACTIVITY_FCT_LD,16) */ MSISDN,
NVL(LU_GPRS_DATE_KEY,0) AS DATE_KEY ,
NVL(LU_GPRS_TIME_KEY,0) AS TIME_KEY,
NVL(LU_GPRS_PRODUCT_KEY,0) AS PRODUCT_KEY,
NVL(LU_GPRS_GEOGRAPHY_KEY,0) AS GEOGRAPHY_KEY
FROM 
LAST_ACTIVITY_FCT_LD
UNION ALL
SELECT/*+ PARALLEL (LAST_ACTIVITY_FCT_LD,16) */ MSISDN,
NVL(LR_DATE_KEY,0) AS DATE_KEY ,
NVL(LR_TIME_KEY,0) AS TIME_KEY,
NULL AS PRODUCT_KEY,
NULL AS GEOGRAPHY_KEY
FROM 
LAST_ACTIVITY_FCT_LD)A
GROUP BY A.MSISDN
)Z
)X
WHERE X.LAST_KEY=1
)T
ON (A.MSISDN = T.MSISDN) 
WHEN MATCHED THEN
UPDATE SET A.LU_DATE_KEY=T.DATE_KEY,
   A.LU_TIME_KEY =T.TIME_KEY,
   A.LU_PRODUCT_KEY=T.PRODUCT_KEY,
   A.LU_LOCATION_KEY=T.GEOGRAPHY_KEY;
COMMIT;
EXIT
EOF
}

# ======= SMSC SECTION =====.

lock=/data02/scripts/process/bin/last_activity_fct_ld  export lock

if [ -f $lock ] ; then
exit 2

else
touch $lock

fileList=`get_partition`

for fil in $fileList
do

v1=`echo ${fil}|sed s/,/\ /g|awk '{print $1}'`   ###VOICE partition
v2=`echo ${fil}|sed s/,/\ /g|awk '{print $2}'`   ###SMS partition
v3=`echo ${fil}|sed s/,/\ /g|awk '{print $3}'`   ###DATA partition
v4=`echo ${fil}|sed s/,/\ /g|awk '{print $4}'`   ###RECHARGE partition
v5=`echo ${fil}|sed s/,/\ /g|awk '{print $5}'`   ###date_key

insert_script $v1 $v2 $v3 $v4 $v5

done

rm -f $lock

fi

