--
-- P_LAST_ACTIVITY_FCT_LD  (Procedure) 
--
CREATE OR REPLACE PROCEDURE DWH_USER.P_LAST_ACTIVITY_FCT_LD IS
    VDATE_KEY               NUMBER;
    VDATE DATE :=TO_DATE(TO_DATE( SYSDATE-1),'DD/MM/RRRR');
BEGIN
    SELECT DATE_KEY INTO VDATE_KEY 
    FROM DATE_DIM
    WHERE DATE_KEY = (SELECT A.DATE_KEY FROM DATE_DIM A WHERE A.DATE_VALUE = VDATE);
    
    ---------INSER LAST_ACTIVITY_FCT_LD---------
    INSERT INTO LAST_ACTIVITY_FCT_LD (MSISDN,SNAPSHOT_DATE_KEY,SUBSCRIPTION_KEY)
    SELECT SERVICE_NUMBER, 
    B.DATE_KEY, 
    SUBSCRIPTION_KEY
    FROM SUBSCRIPTION_DIM A, DATE_DIM B
    WHERE B.DATE_KEY = VDATE_KEY
    AND SERVICE_NUMBER NOT IN (SELECT MSISDN FROM LAST_ACTIVITY_FCT_LD) ;
    COMMIT; 
--##========================MTC=============================##
--====================LU_MOC_DATE_KEY,LU_MOC_TIME_KEY==============--

MERGE INTO LAST_ACTIVITY_FCT_LD A
    USING (SELECT K.V372_CALLINGPARTYNUMBER  AS MSISDN ,K.V387_CHARGINGTIME_KEY AS CHARGINGTIME_KEY,K.V387_CHARGINGTIME_HOUR AS CHARGINGTIME_HOUR
            FROM (SELECT A.V372_CALLINGPARTYNUMBER,A.V387_CHARGINGTIME_KEY, A.V387_CHARGINGTIME_HOUR, RANK() OVER (PARTITION BY A.V372_CALLINGPARTYNUMBER ORDER BY A.V387_CHARGINGTIME_KEY DESC,A.V387_CHARGINGTIME_HOUR DESC) AS LAST_KEY
                   FROM
                    (SELECT   V.V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY, V387_CHARGINGTIME_HOUR
                        FROM L3_VOICE V, DATE_DIM D
                        WHERE V378_SERVICEFLOW =1
                        AND V.V387_CHARGINGTIME_KEY=D.DATE_KEY
                        AND D.DATE_VALUE BETWEEN SYSDATE-2 AND SYSDATE-1  
                        GROUP BY V372_CALLINGPARTYNUMBER,V387_CHARGINGTIME_KEY,V387_CHARGINGTIME_HOUR)A
                        ) K 
    WHERE LAST_KEY=1)V 
    ON (A.MSISDN = V.MSISDN) 
    WHEN MATCHED THEN
    UPDATE SET A.LU_MOC_DATE_KEY=V.CHARGINGTIME_KEY,
               A.LU_MOC_TIME_KEY=V.CHARGINGTIME_HOUR;
COMMIT;


--==============LU_MOC_PRODUCT_KEY===================--------
MERGE INTO LAST_ACTIVITY_FCT_LD A
    USING (SELECT K.V372_CALLINGPARTYNUMBER AS MSISDN ,K.V397_MAINOFFERINGID AS MAINOFFERINGID
        FROM 
            (SELECT A.V372_CALLINGPARTYNUMBER, A.V387_CHARGINGTIME_KEY,V397_MAINOFFERINGID, RANK() OVER (PARTITION BY A.V372_CALLINGPARTYNUMBER ORDER BY A.V387_CHARGINGTIME_KEY DESC, A.V397_MAINOFFERINGID DESC) AS LAST_KEY
                FROM
                (SELECT   V.V372_CALLINGPARTYNUMBER,V. V387_CHARGINGTIME_KEY,V397_MAINOFFERINGID
                FROM L3_VOICE V, DATE_DIM D
                WHERE V378_SERVICEFLOW =1
                AND V.V387_CHARGINGTIME_KEY=D.DATE_KEY
                AND D.DATE_VALUE BETWEEN SYSDATE-2 AND SYSDATE-1    
                GROUP BY V372_CALLINGPARTYNUMBER,V387_CHARGINGTIME_KEY,V397_MAINOFFERINGID)A
            ) K 
        WHERE LAST_KEY=1)V 
    ON (A.MSISDN = V.MSISDN) 
    WHEN MATCHED THEN
    UPDATE SET A.LU_MOC_PRODUCT_KEY=V.MAINOFFERINGID;
COMMIT;

-----------------LU_MOC_GEOGRAPHY_KEY-------------

MERGE INTO LAST_ACTIVITY_FCT_LD A
    USING (SELECT K.V372_CALLINGPARTYNUMBER AS MSISDN,K.V381_CALLINGCELLID  AS CALLINGCELLID 
        FROM 
            (SELECT A.V372_CALLINGPARTYNUMBER, A.V387_CHARGINGTIME_KEY, A.V381_CALLINGCELLID, RANK() OVER (PARTITION BY A.V372_CALLINGPARTYNUMBER ORDER BY A.V387_CHARGINGTIME_KEY DESC, V381_CALLINGCELLID DESC) AS LAST_KEY
                FROM
                (SELECT   V.V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY, V.V381_CALLINGCELLID
                FROM L3_VOICE V, DATE_DIM D
                WHERE V378_SERVICEFLOW =1
                AND V.V387_CHARGINGTIME_KEY=D.DATE_KEY
                AND D.DATE_VALUE BETWEEN SYSDATE-2 AND SYSDATE-1     
                GROUP BY V.V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY,V.V381_CALLINGCELLID)A
            ) K 
        WHERE LAST_KEY=1)V
    ON (A.MSISDN = V.MSISDN) 
    WHEN MATCHED THEN
    UPDATE SET A.LU_MOC_GEOGRAPHY_KEY=V.CALLINGCELLID;
COMMIT;
        

--------------LU_MOC_ACTUAL_DURATION---------------


MERGE INTO LAST_ACTIVITY_FCT_LD A
    USING(SELECT K.V372_CALLINGPARTYNUMBER AS MSISDN,K.V35_RATE_USAGE
        FROM 
            (SELECT A.V372_CALLINGPARTYNUMBER, A.V35_RATE_USAGE, RANK() OVER (PARTITION BY A.V372_CALLINGPARTYNUMBER ORDER BY A.V387_CHARGINGTIME_KEY DESC) AS LAST_KEY
                FROM
                (SELECT   V.V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY,COUNT(V.V35_RATE_USAGE) AS V35_RATE_USAGE
                FROM L3_VOICE V, DATE_DIM D
                WHERE V378_SERVICEFLOW =1
                AND V.V387_CHARGINGTIME_KEY=D.DATE_KEY
                AND D.DATE_VALUE BETWEEN SYSDATE-2 AND SYSDATE-1     
                GROUP BY V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY)A
            ) K 
        WHERE LAST_KEY=1)V
        ON (A.MSISDN = V.MSISDN) 
        WHEN MATCHED THEN
        UPDATE SET A.LU_MOC_ACTUAL_DURATION=V.V35_RATE_USAGE;
COMMIT;
        
---======================LU_MOC_AIR_CHARGE================--


MERGE INTO LAST_ACTIVITY_FCT_LD A
USING (SELECT K.V372_CALLINGPARTYNUMBER AS MSISDN, K.V41_DEBIT_AMOUNT AS DEBIT_AMOUNT
        FROM 
            (SELECT A.V372_CALLINGPARTYNUMBER, A.V41_DEBIT_AMOUNT, RANK() OVER (PARTITION BY A.V372_CALLINGPARTYNUMBER ORDER BY A.V387_CHARGINGTIME_KEY DESC) AS LAST_KEY
                FROM
                (SELECT   V.V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY,SUM(V.V41_DEBIT_AMOUNT) AS V41_DEBIT_AMOUNT
                FROM L3_VOICE V, DATE_DIM D
                WHERE V378_SERVICEFLOW =1
                AND V.V387_CHARGINGTIME_KEY=D.DATE_KEY
                AND D.DATE_VALUE BETWEEN SYSDATE-2 AND SYSDATE-1     
                GROUP BY V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY)A
            ) K 
        WHERE LAST_KEY=1)V
        ON (A.MSISDN = V.MSISDN)
        WHEN MATCHED THEN
        UPDATE SET A.LU_MOC_AIR_CHARGE=V.DEBIT_AMOUNT;
COMMIT;


--##========================MTC=============================##
--##========================================================##
--====================LU_MTC_DATE_KEY, LU_MTC_TIME_KEY==============--
MERGE INTO LAST_ACTIVITY_FCT_LD A
    USING (SELECT K.V372_CALLINGPARTYNUMBER  AS MSISDN ,K.V387_CHARGINGTIME_KEY AS CHARGINGTIME_KEY,K.V387_CHARGINGTIME_HOUR AS CHARGINGTIME_HOUR
            FROM (SELECT A.V372_CALLINGPARTYNUMBER,A.V387_CHARGINGTIME_KEY, A.V387_CHARGINGTIME_HOUR, RANK() OVER (PARTITION BY A.V372_CALLINGPARTYNUMBER ORDER BY A.V387_CHARGINGTIME_KEY DESC,A.V387_CHARGINGTIME_HOUR DESC) AS LAST_KEY
                   FROM
                    (SELECT   V.V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY, V387_CHARGINGTIME_HOUR
                        FROM L3_VOICE V, DATE_DIM D
                        WHERE V378_SERVICEFLOW =2
                        AND V.V387_CHARGINGTIME_KEY=D.DATE_KEY
                        AND D.DATE_VALUE BETWEEN SYSDATE-2 AND SYSDATE-1 
                        GROUP BY V372_CALLINGPARTYNUMBER,V387_CHARGINGTIME_KEY,V387_CHARGINGTIME_HOUR)A
                        ) K 
    WHERE LAST_KEY=1)V 
    ON (A.MSISDN = V.MSISDN) 
    WHEN MATCHED THEN
    UPDATE SET A.LU_MTC_DATE_KEY=V.CHARGINGTIME_KEY,
               A.LU_MTC_TIME_KEY=V.CHARGINGTIME_HOUR;
COMMIT;

--==============LU_MTC_PRODUCT_KEY===================--------
MERGE INTO LAST_ACTIVITY_FCT_LD A
    USING (SELECT K.V372_CALLINGPARTYNUMBER AS MSISDN ,K.V397_MAINOFFERINGID AS MAINOFFERINGID
        FROM 
            (SELECT A.V372_CALLINGPARTYNUMBER, A.V387_CHARGINGTIME_KEY,V397_MAINOFFERINGID, RANK() OVER (PARTITION BY A.V372_CALLINGPARTYNUMBER ORDER BY A.V387_CHARGINGTIME_KEY DESC, A.V397_MAINOFFERINGID DESC) AS LAST_KEY
                FROM
                (SELECT   V.V372_CALLINGPARTYNUMBER,V. V387_CHARGINGTIME_KEY,V397_MAINOFFERINGID
                FROM L3_VOICE V, DATE_DIM D
                WHERE V378_SERVICEFLOW =2
                AND V.V387_CHARGINGTIME_KEY=D.DATE_KEY
                AND D.DATE_VALUE BETWEEN SYSDATE-2 AND SYSDATE-1    
                GROUP BY V372_CALLINGPARTYNUMBER,V387_CHARGINGTIME_KEY,V397_MAINOFFERINGID)A
            ) K 
        WHERE LAST_KEY=1)V 
    ON (A.MSISDN = V.MSISDN) 
    WHEN MATCHED THEN
    UPDATE SET A.LU_MTC_PRODUCT_KEY=V.MAINOFFERINGID;
COMMIT;

--==================LU_MTC_GEOGRAPHY_KEY=======================-----------------
MERGE INTO LAST_ACTIVITY_FCT_LD A
    USING (SELECT K.V372_CALLINGPARTYNUMBER AS MSISDN,K.V383_CALLEDCELLID  AS CALLINGCELLID 
        FROM 
            (SELECT A.V372_CALLINGPARTYNUMBER, A.V387_CHARGINGTIME_KEY, A.V383_CALLEDCELLID, RANK() OVER (PARTITION BY A.V372_CALLINGPARTYNUMBER ORDER BY A.V387_CHARGINGTIME_KEY DESC, V383_CALLEDCELLID DESC) AS LAST_KEY
                FROM
                (SELECT   V.V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY, V.V383_CALLEDCELLID
                FROM L3_VOICE V, DATE_DIM D
                WHERE V378_SERVICEFLOW =2
                AND V.V387_CHARGINGTIME_KEY=D.DATE_KEY
                AND D.DATE_VALUE BETWEEN SYSDATE-2 AND SYSDATE-1     
                GROUP BY V.V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY,V.V383_CALLEDCELLID)A
            ) K 
        WHERE LAST_KEY=1)V
    ON (A.MSISDN = V.MSISDN) 
    WHEN MATCHED THEN
    UPDATE SET A.LU_MTC_GEOGRAPHY_KEY=V.CALLINGCELLID;
COMMIT;
        
--------------LU_MTC_ACTUAL_DURATION---------------


MERGE INTO LAST_ACTIVITY_FCT_LD A
    USING(SELECT K.V372_CALLINGPARTYNUMBER AS MSISDN,K.V35_RATE_USAGE
        FROM 
            (SELECT A.V372_CALLINGPARTYNUMBER, A.V35_RATE_USAGE, RANK() OVER (PARTITION BY A.V372_CALLINGPARTYNUMBER ORDER BY A.V387_CHARGINGTIME_KEY DESC) AS LAST_KEY
                FROM
                (SELECT   V.V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY,COUNT(V.V35_RATE_USAGE) AS V35_RATE_USAGE
                FROM L3_VOICE V, DATE_DIM D
                WHERE V378_SERVICEFLOW =2
                AND V.V387_CHARGINGTIME_KEY=D.DATE_KEY
                AND D.DATE_VALUE BETWEEN SYSDATE-2 AND SYSDATE-1     
                GROUP BY V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY)A
            ) K 
        WHERE LAST_KEY=1)V
        ON (A.MSISDN = V.MSISDN) 
        WHEN MATCHED THEN
        UPDATE SET A.LU_MTC_ACTUAL_DURATION=V.V35_RATE_USAGE;
COMMIT;
        
--===================LU_ON_NET_MOC_DATE_KEY============--

MERGE INTO LAST_ACTIVITY_FCT_LD A
    USING (SELECT K.V372_CALLINGPARTYNUMBER  AS MSISDN ,K.V387_CHARGINGTIME_KEY AS CHARGINGTIME_KEY,K.V387_CHARGINGTIME_HOUR AS CHARGINGTIME_HOUR
            FROM (SELECT A.V372_CALLINGPARTYNUMBER,A.V387_CHARGINGTIME_KEY, A.V387_CHARGINGTIME_HOUR, RANK() OVER (PARTITION BY A.V372_CALLINGPARTYNUMBER ORDER BY A.V387_CHARGINGTIME_KEY DESC,A.V387_CHARGINGTIME_HOUR DESC) AS LAST_KEY
                   FROM
                    (SELECT   V.V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY, V387_CHARGINGTIME_HOUR
                        FROM L3_VOICE V, DATE_DIM D
                        WHERE V378_SERVICEFLOW =1
                        AND V25_USAGE_SERVICE_TYPE=10
                        AND V.V387_CHARGINGTIME_KEY=D.DATE_KEY
                        AND D.DATE_VALUE BETWEEN SYSDATE-2 AND SYSDATE-1 
                        GROUP BY V372_CALLINGPARTYNUMBER,V387_CHARGINGTIME_KEY,V387_CHARGINGTIME_HOUR)A
                        ) K 
    WHERE LAST_KEY=1)V 
    ON (A.MSISDN = V.MSISDN) 
    WHEN MATCHED THEN
    UPDATE SET A.LU_ON_NET_MOC_DATE_KEY=V.CHARGINGTIME_KEY,
               A.LU_ON_NET_MOC_TIME_KEY=V.CHARGINGTIME_HOUR;
COMMIT;

--=========================LU_ON_NET_MOC_PRODUCT_KEY======================--
MERGE INTO LAST_ACTIVITY_FCT_LD A
    USING (SELECT K.V372_CALLINGPARTYNUMBER AS MSISDN ,K.V397_MAINOFFERINGID AS MAINOFFERINGID
        FROM 
            (SELECT A.V372_CALLINGPARTYNUMBER, A.V387_CHARGINGTIME_KEY,V397_MAINOFFERINGID, RANK() OVER (PARTITION BY A.V372_CALLINGPARTYNUMBER ORDER BY A.V387_CHARGINGTIME_KEY DESC, A.V397_MAINOFFERINGID DESC) AS LAST_KEY
                FROM
                (SELECT   V.V372_CALLINGPARTYNUMBER,V. V387_CHARGINGTIME_KEY,V397_MAINOFFERINGID
                FROM L3_VOICE V, DATE_DIM D
                WHERE V378_SERVICEFLOW =1
                AND V25_USAGE_SERVICE_TYPE=10
                AND V.V387_CHARGINGTIME_KEY=D.DATE_KEY
                AND D.DATE_VALUE BETWEEN SYSDATE-2 AND SYSDATE-1     
                GROUP BY V372_CALLINGPARTYNUMBER,V387_CHARGINGTIME_KEY,V397_MAINOFFERINGID)A
            ) K 
        WHERE LAST_KEY=1)V 
    ON (A.MSISDN = V.MSISDN) 
    WHEN MATCHED THEN
    UPDATE SET A.LU_ON_NET_MOC_PRODUCT_KEY=V.MAINOFFERINGID;
COMMIT;


--===============LU_ON_NET_MOC_ACTUAL_DURATION===============--
MERGE INTO LAST_ACTIVITY_FCT_LD A
    USING(SELECT K.V372_CALLINGPARTYNUMBER AS MSISDN,K.V35_RATE_USAGE
        FROM 
            (SELECT A.V372_CALLINGPARTYNUMBER, A.V35_RATE_USAGE, RANK() OVER (PARTITION BY A.V372_CALLINGPARTYNUMBER ORDER BY A.V387_CHARGINGTIME_KEY DESC) AS LAST_KEY
                FROM
                (SELECT   V.V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY,COUNT(V.V35_RATE_USAGE) AS V35_RATE_USAGE
                FROM L3_VOICE V, DATE_DIM D
                WHERE V378_SERVICEFLOW =1
                AND V25_USAGE_SERVICE_TYPE=10
                AND V.V387_CHARGINGTIME_KEY=D.DATE_KEY
                AND D.DATE_VALUE BETWEEN SYSDATE-2 AND SYSDATE-1    
                GROUP BY V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY)A
            ) K 
        WHERE LAST_KEY=1)V
        ON (A.MSISDN = V.MSISDN) 
        WHEN MATCHED THEN
        UPDATE SET A.LU_ON_NET_MOC_ACTUAL_DURATION=V.V35_RATE_USAGE;
COMMIT;

--==============================LU_ON_NET_MOC_AIR_CHARGE=====================--

MERGE INTO LAST_ACTIVITY_FCT_LD A
USING (SELECT K.V372_CALLINGPARTYNUMBER AS MSISDN, K.V41_DEBIT_AMOUNT AS DEBIT_AMOUNT
        FROM 
            (SELECT A.V372_CALLINGPARTYNUMBER, A.V41_DEBIT_AMOUNT, RANK() OVER (PARTITION BY A.V372_CALLINGPARTYNUMBER ORDER BY A.V387_CHARGINGTIME_KEY DESC) AS LAST_KEY
                FROM
                (SELECT   V.V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY,SUM(V.V41_DEBIT_AMOUNT) AS V41_DEBIT_AMOUNT
                FROM L3_VOICE V, DATE_DIM D
                WHERE V378_SERVICEFLOW =1
                AND V25_USAGE_SERVICE_TYPE=10
                AND V.V387_CHARGINGTIME_KEY=D.DATE_KEY
                AND D.DATE_VALUE BETWEEN SYSDATE-2 AND SYSDATE-1    
                GROUP BY V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY)A
            ) K 
        WHERE LAST_KEY=1)V
        ON (A.MSISDN = V.MSISDN)
        WHEN MATCHED THEN
        UPDATE SET A.LU_ON_NET_MOC_AIR_CHARGE=V.DEBIT_AMOUNT;
COMMIT;

--=========================LU_OFF_NET_MOC_DATE_KEY======================--
MERGE INTO LAST_ACTIVITY_FCT_LD A
    USING (SELECT K.V372_CALLINGPARTYNUMBER  AS MSISDN ,K.V387_CHARGINGTIME_KEY AS CHARGINGTIME_KEY,K.V387_CHARGINGTIME_HOUR AS CHARGINGTIME_HOUR
            FROM (SELECT A.V372_CALLINGPARTYNUMBER,A.V387_CHARGINGTIME_KEY, A.V387_CHARGINGTIME_HOUR, RANK() OVER (PARTITION BY A.V372_CALLINGPARTYNUMBER ORDER BY A.V387_CHARGINGTIME_KEY DESC,A.V387_CHARGINGTIME_HOUR DESC) AS LAST_KEY
                   FROM
                    (SELECT   V.V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY, V387_CHARGINGTIME_HOUR
                        FROM L3_VOICE V, DATE_DIM D
                        WHERE V378_SERVICEFLOW =1
                        AND V25_USAGE_SERVICE_TYPE=11
                        AND V.V387_CHARGINGTIME_KEY=D.DATE_KEY
                        AND D.DATE_VALUE BETWEEN SYSDATE-2 AND SYSDATE-1   
                        GROUP BY V372_CALLINGPARTYNUMBER,V387_CHARGINGTIME_KEY,V387_CHARGINGTIME_HOUR)A
                        ) K 
    WHERE LAST_KEY=1)V 
    ON (A.MSISDN = V.MSISDN) 
    WHEN MATCHED THEN
    UPDATE SET A.LU_OFF_NET_MOC_DATE_KEY=V.CHARGINGTIME_KEY,
               A.LU_OFF_NET_MOC_TIME_KEY=V.CHARGINGTIME_HOUR;
COMMIT;

/*
--=========================LU_OFF_NET_MOC_PRODUCT_KEY======================--
MERGE INTO LAST_ACTIVITY_FCT_LD A
    USING (SELECT K.V372_CALLINGPARTYNUMBER AS MSISDN ,K.V397_MAINOFFERINGID AS MAINOFFERINGID
        FROM 
            (SELECT A.V372_CALLINGPARTYNUMBER, A.V387_CHARGINGTIME_KEY,V397_MAINOFFERINGID, RANK() OVER (PARTITION BY A.V372_CALLINGPARTYNUMBER ORDER BY A.V387_CHARGINGTIME_KEY DESC, A.V397_MAINOFFERINGID DESC) AS LAST_KEY
                FROM
                (SELECT   V.V372_CALLINGPARTYNUMBER,V. V387_CHARGINGTIME_KEY,V397_MAINOFFERINGID
                FROM L3_VOICE V, DATE_DIM D
                WHERE V378_SERVICEFLOW =1
                AND V25_USAGE_SERVICE_TYPE=11
                AND V.V387_CHARGINGTIME_KEY=D.DATE_KEY
                AND D.DATE_VALUE BETWEEN SYSDATE-2 AND SYSDATE-1     
                GROUP BY V372_CALLINGPARTYNUMBER,V387_CHARGINGTIME_KEY,V397_MAINOFFERINGID)A
            ) K 
        WHERE LAST_KEY=1)V 
    ON (A.MSISDN = V.MSISDN) 
    WHEN MATCHED THEN
    UPDATE SET A.LU_OFF_NET_MOC_PRODUCT_KEY=V.MAINOFFERINGID;
COMMIT;

*/
--===========================LU_OFF_NET_MOC_LOCATION_KEY==============--
MERGE INTO LAST_ACTIVITY_FCT_LD A
    USING (SELECT K.V372_CALLINGPARTYNUMBER AS MSISDN,K.V381_CALLINGCELLID  AS CALLINGCELLID 
        FROM 
            (SELECT A.V372_CALLINGPARTYNUMBER, A.V387_CHARGINGTIME_KEY, A.V381_CALLINGCELLID, RANK() OVER (PARTITION BY A.V372_CALLINGPARTYNUMBER ORDER BY A.V387_CHARGINGTIME_KEY DESC, V381_CALLINGCELLID DESC) AS LAST_KEY
                FROM
                (SELECT   V.V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY, V.V381_CALLINGCELLID
                FROM L3_VOICE V, DATE_DIM D
                WHERE V378_SERVICEFLOW =1
                AND V25_USAGE_SERVICE_TYPE=11
                AND V.V387_CHARGINGTIME_KEY=D.DATE_KEY
               AND D.DATE_VALUE BETWEEN SYSDATE-2 AND SYSDATE-1     
                GROUP BY V.V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY,V.V381_CALLINGCELLID)A
            ) K 
        WHERE LAST_KEY=1)V
    ON (A.MSISDN = V.MSISDN) 
    WHEN MATCHED THEN
    UPDATE SET A.LU_OFF_NET_MOC_LOCATION_KEY=V.CALLINGCELLID;
COMMIT;

--========LU_OFF_NET_MOC_ACTUAL_DURATION=========--

MERGE INTO LAST_ACTIVITY_FCT_LD A
    USING(SELECT K.V372_CALLINGPARTYNUMBER AS MSISDN,K.V35_RATE_USAGE
        FROM 
            (SELECT A.V372_CALLINGPARTYNUMBER, A.V35_RATE_USAGE, RANK() OVER (PARTITION BY A.V372_CALLINGPARTYNUMBER ORDER BY A.V387_CHARGINGTIME_KEY DESC) AS LAST_KEY
                FROM
                (SELECT   V.V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY,COUNT(V.V35_RATE_USAGE) AS V35_RATE_USAGE
                FROM L3_VOICE V, DATE_DIM D
                WHERE V378_SERVICEFLOW =1
                AND V25_USAGE_SERVICE_TYPE=11
                AND V.V387_CHARGINGTIME_KEY=D.DATE_KEY
                AND D.DATE_VALUE BETWEEN SYSDATE-2 AND SYSDATE-1   
                GROUP BY V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY)A
            ) K 
        WHERE LAST_KEY=1)V
        ON (A.MSISDN = V.MSISDN) 
        WHEN MATCHED THEN
        UPDATE SET A.LU_OFF_NET_MOC_ACTUAL_DURATION=V.V35_RATE_USAGE;
COMMIT;


--====================LU_OFF_NET_MOC_AIR_CHARGE==============-----
MERGE INTO LAST_ACTIVITY_FCT_LD A
USING (SELECT K.V372_CALLINGPARTYNUMBER AS MSISDN, K.V41_DEBIT_AMOUNT AS DEBIT_AMOUNT
        FROM 
            (SELECT A.V372_CALLINGPARTYNUMBER, A.V41_DEBIT_AMOUNT, RANK() OVER (PARTITION BY A.V372_CALLINGPARTYNUMBER ORDER BY A.V387_CHARGINGTIME_KEY DESC) AS LAST_KEY
                FROM
                (SELECT   V.V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY,SUM(V.V41_DEBIT_AMOUNT) AS V41_DEBIT_AMOUNT
                FROM L3_VOICE V, DATE_DIM D
                WHERE V378_SERVICEFLOW =1
                AND V25_USAGE_SERVICE_TYPE=11
                AND V.V387_CHARGINGTIME_KEY=D.DATE_KEY
                AND D.DATE_VALUE BETWEEN SYSDATE-2 AND SYSDATE-1    
                GROUP BY V372_CALLINGPARTYNUMBER,V.V387_CHARGINGTIME_KEY)A
            ) K 
        WHERE LAST_KEY=1)V
        ON (A.MSISDN = V.MSISDN)
        WHEN MATCHED THEN
        UPDATE SET A.LU_OFF_NET_MOC_AIR_CHARGE=V.DEBIT_AMOUNT;
COMMIT;




--##==============================SMS========================================##
--##=========================================================================##


--============================LU_MOSMS_DATE_KEY,LU_MOSMS_TIME_KEY============--
MERGE INTO LAST_ACTIVITY_FCT_LD A
    USING (SELECT K.S372_CALLINGPARTYNUMBER  AS MSISDN ,K.S387_CHARGINGTIME_KEY AS CHARGINGTIME_KEY,K.S387_CHARGINGTIME_HOUR AS CHARGINGTIME_HOUR
            FROM (SELECT A.S372_CALLINGPARTYNUMBER,A.S387_CHARGINGTIME_KEY, A.S387_CHARGINGTIME_HOUR, RANK() OVER (PARTITION BY A.S372_CALLINGPARTYNUMBER ORDER BY A.S387_CHARGINGTIME_KEY DESC,A.S387_CHARGINGTIME_HOUR DESC) AS LAST_KEY
                   FROM
                    (SELECT   V.S372_CALLINGPARTYNUMBER,V.S387_CHARGINGTIME_KEY, S387_CHARGINGTIME_HOUR
                        FROM L3_SMS V, DATE_DIM D
                        WHERE S378_SERVICEFLOW =1
                        AND V.S387_CHARGINGTIME_KEY=D.DATE_KEY
                        AND D.DATE_VALUE BETWEEN SYSDATE-2 AND SYSDATE-1    
                        GROUP BY S372_CALLINGPARTYNUMBER,S387_CHARGINGTIME_KEY,S387_CHARGINGTIME_HOUR)A
                        ) K 
    WHERE LAST_KEY=1)V 
    ON (A.MSISDN = V.MSISDN) 
    WHEN MATCHED THEN
    UPDATE SET A.LU_MOSMS_DATE_KEY=V.CHARGINGTIME_KEY,
               A.LU_MOSMS_TIME_KEY=V.CHARGINGTIME_HOUR;
COMMIT;


--========================LU_MOSMS_PRODUCT_KEY==========================--

MERGE INTO LAST_ACTIVITY_FCT_LD A
    USING (SELECT K.S372_CALLINGPARTYNUMBER AS MSISDN ,K.S395_MAINOFFERINGID AS MAINOFFERINGID
        FROM 
            (SELECT A.S372_CALLINGPARTYNUMBER, A.S387_CHARGINGTIME_KEY,S395_MAINOFFERINGID, RANK() OVER (PARTITION BY A.S372_CALLINGPARTYNUMBER ORDER BY A.S387_CHARGINGTIME_KEY DESC, A.S395_MAINOFFERINGID DESC) AS LAST_KEY
                FROM
                (SELECT   V.S372_CALLINGPARTYNUMBER,V.S387_CHARGINGTIME_KEY,S395_MAINOFFERINGID
                FROM L3_SMS V, DATE_DIM D
                WHERE S378_SERVICEFLOW =1
                AND V.S372_CALLINGPARTYNUMBER=D.DATE_KEY
                AND D.DATE_VALUE BETWEEN SYSDATE-2 AND SYSDATE-1    
                GROUP BY S372_CALLINGPARTYNUMBER,S387_CHARGINGTIME_KEY,S395_MAINOFFERINGID)A
            ) K 
        WHERE LAST_KEY=1)V 
    ON (A.MSISDN = V.MSISDN) 
    WHEN MATCHED THEN
    UPDATE SET A.LU_MOSMS_PRODUCT_KEY=V.MAINOFFERINGID;
COMMIT;


--===================LU_MOSMS_GEOGRAPHY_KEY======================--

MERGE INTO LAST_ACTIVITY_FCT_LD A
    USING (SELECT K.S372_CALLINGPARTYNUMBER AS MSISDN,K.S381_CALLINGCELLID  AS CALLINGCELLID 
        FROM 
            (SELECT A.S372_CALLINGPARTYNUMBER, A.S387_CHARGINGTIME_KEY, A.S381_CALLINGCELLID, RANK() OVER (PARTITION BY A.S372_CALLINGPARTYNUMBER ORDER BY A.S387_CHARGINGTIME_KEY DESC, S381_CALLINGCELLID DESC) AS LAST_KEY
                FROM
                (SELECT   V.S372_CALLINGPARTYNUMBER,V.S387_CHARGINGTIME_KEY, V.S381_CALLINGCELLID
                FROM L3_SMS V, DATE_DIM D
                WHERE S378_SERVICEFLOW =1
                AND V.S372_CALLINGPARTYNUMBER=D.DATE_KEY
                AND D.DATE_VALUE BETWEEN SYSDATE-2 AND SYSDATE-1     
                GROUP BY V.S372_CALLINGPARTYNUMBER,V.S387_CHARGINGTIME_KEY,V.S381_CALLINGCELLID)A
            ) K 
        WHERE LAST_KEY=1)V
    ON (A.MSISDN = V.MSISDN) 
    WHEN MATCHED THEN
    UPDATE SET A.LU_MOSMS_GEOGRAPHY_KEY=V.CALLINGCELLID;
COMMIT;


--==========================LU_MOSMS_AIR_CHARGE=================--

MERGE INTO LAST_ACTIVITY_FCT_LD A
USING (SELECT K.S372_CALLINGPARTYNUMBER AS MSISDN, K.S41_DEBIT_AMOUNT AS DEBIT_AMOUNT
        FROM 
            (SELECT A.S372_CALLINGPARTYNUMBER, A.S41_DEBIT_AMOUNT, RANK() OVER (PARTITION BY A.S372_CALLINGPARTYNUMBER ORDER BY A.S387_CHARGINGTIME_KEY DESC) AS LAST_KEY
                FROM
                (SELECT   V.S372_CALLINGPARTYNUMBER,V.S387_CHARGINGTIME_KEY,SUM(V.S41_DEBIT_AMOUNT) AS S41_DEBIT_AMOUNT
                FROM L3_SMS V, DATE_DIM D
                WHERE S378_SERVICEFLOW =1
                AND V.S372_CALLINGPARTYNUMBER=D.DATE_KEY
                AND D.DATE_VALUE BETWEEN SYSDATE-2 AND SYSDATE-1   
                GROUP BY S372_CALLINGPARTYNUMBER,V.S387_CHARGINGTIME_KEY)A
            ) K 
        WHERE LAST_KEY=1)V
        ON (A.MSISDN = V.MSISDN)
        WHEN MATCHED THEN
        UPDATE SET A.LU_MOSMS_AIR_CHARGE=V.DEBIT_AMOUNT;
COMMIT;

--==================================LU_GPRS_DATE_KEY,LU_GPRS_TIME_KEY===========-

MERGE INTO LAST_ACTIVITY_FCT_LD A
    USING (SELECT K.G372_CALLINGPARTYNUMBER  AS MSISDN ,K.G383_CHARGINGTIME_KEY AS CHARGINGTIME_KEY,K.G383_CHARGINGTIME_HOUR AS CHARGINGTIME_HOUR
            FROM (SELECT A.G372_CALLINGPARTYNUMBER,A.G383_CHARGINGTIME_KEY, A.G383_CHARGINGTIME_HOUR, RANK() OVER (PARTITION BY A.G372_CALLINGPARTYNUMBER ORDER BY A.G383_CHARGINGTIME_KEY DESC,A.G383_CHARGINGTIME_HOUR DESC) AS LAST_KEY
                   FROM
                    (SELECT   V.G372_CALLINGPARTYNUMBER,V.G383_CHARGINGTIME_KEY, v.G383_CHARGINGTIME_HOUR
                        FROM L3_DATA V, DATE_DIM D
                        WHERE V.G383_CHARGINGTIME_KEY=D.DATE_KEY
                        AND D.DATE_VALUE BETWEEN SYSDATE-2 AND SYSDATE-1    
                        GROUP BY G372_CALLINGPARTYNUMBER,G383_CHARGINGTIME_KEY,G383_CHARGINGTIME_HOUR)A
                        ) K 
    WHERE LAST_KEY=1)V 
    ON (A.MSISDN = V.MSISDN) 
    WHEN MATCHED THEN
    UPDATE SET A.LU_GPRS_DATE_KEY=V.CHARGINGTIME_KEY,
               A.LU_GPRS_TIME_KEY=V.CHARGINGTIME_HOUR;
COMMIT;

--================================LU_GPRS_GEOGRAPHY_KEY======================--

MERGE INTO LAST_ACTIVITY_FCT_LD A
    USING (SELECT K.G372_CALLINGPARTYNUMBER AS MSISDN,K.G379_CALLINGCELLID  AS CALLINGCELLID 
        FROM 
            (SELECT A.G372_CALLINGPARTYNUMBER, A.G383_CHARGINGTIME_KEY, A.G379_CALLINGCELLID, RANK() OVER (PARTITION BY A.G372_CALLINGPARTYNUMBER ORDER BY A.G383_CHARGINGTIME_KEY DESC, G379_CALLINGCELLID DESC) AS LAST_KEY
                FROM
                (SELECT   V.G372_CALLINGPARTYNUMBER,V.G383_CHARGINGTIME_KEY, V.G379_CALLINGCELLID
                FROM L3_DATA V, DATE_DIM D
                WHERE V.G383_CHARGINGTIME_KEY=D.DATE_KEY
                AND D.DATE_VALUE BETWEEN SYSDATE-2 AND SYSDATE-1     
                GROUP BY V.G372_CALLINGPARTYNUMBER,V.G383_CHARGINGTIME_KEY,V.G379_CALLINGCELLID)A
            ) K 
        WHERE LAST_KEY=1)V
    ON (A.MSISDN = V.MSISDN) 
    WHEN MATCHED THEN
    UPDATE SET A.LU_GPRS_GEOGRAPHY_KEY=V.CALLINGCELLID;
COMMIT;

--=============================LU_GPRS_PRODUCT_KEY=====================--

MERGE INTO LAST_ACTIVITY_FCT_LD A
    USING (SELECT K.G372_CALLINGPARTYNUMBER AS MSISDN ,K.G401_MAINOFFERINGID AS MAINOFFERINGID
        FROM 
            (SELECT A.G372_CALLINGPARTYNUMBER, A.G383_CHARGINGTIME_KEY,G401_MAINOFFERINGID, RANK() OVER (PARTITION BY A.G372_CALLINGPARTYNUMBER ORDER BY A.G383_CHARGINGTIME_KEY DESC, A.G401_MAINOFFERINGID DESC) AS LAST_KEY
                FROM
                (SELECT   V.G372_CALLINGPARTYNUMBER,V.G383_CHARGINGTIME_KEY,G401_MAINOFFERINGID
                FROM L3_data V, DATE_DIM D
                WHERE V.G383_CHARGINGTIME_KEY=D.DATE_KEY
                AND D.DATE_VALUE BETWEEN SYSDATE-2 AND SYSDATE-1    
                GROUP BY G372_CALLINGPARTYNUMBER,G383_CHARGINGTIME_KEY,G401_MAINOFFERINGID)A
            ) K 
        WHERE LAST_KEY=1)V 
    ON (A.MSISDN = V.MSISDN) 
    WHEN MATCHED THEN
    UPDATE SET A.LU_GPRS_PRODUCT_KEY=V.MAINOFFERINGID;
COMMIT;

--==============================LU_GPRS_DATA_SIZE======================--

MERGE INTO LAST_ACTIVITY_FCT_LD A
    USING (SELECT K.G372_CALLINGPARTYNUMBER AS MSISDN,K.G384_TOTALFLUX  AS TOTALFLUX 
        FROM 
            (SELECT A.G372_CALLINGPARTYNUMBER, A.G383_CHARGINGTIME_KEY,A.G383_CHARGINGTIME_HOUR, A.G384_TOTALFLUX, RANK() OVER (PARTITION BY A.G372_CALLINGPARTYNUMBER ORDER BY A.G383_CHARGINGTIME_KEY DESC,A.G383_CHARGINGTIME_HOUR DESC, A.G384_TOTALFLUX DESC) AS LAST_KEY
                FROM
                (SELECT   V.G372_CALLINGPARTYNUMBER,V.G383_CHARGINGTIME_KEY, G383_CHARGINGTIME_HOUR, SUM(NVL(V.G384_TOTALFLUX,0)) / 1048576 AS G384_TOTALFLUX
                FROM L3_DATA V, DATE_DIM D
                WHERE V.G383_CHARGINGTIME_KEY=D.DATE_KEY
                AND D.DATE_VALUE BETWEEN SYSDATE-2 AND SYSDATE-1    
                GROUP BY V.G372_CALLINGPARTYNUMBER,V.G383_CHARGINGTIME_KEY,V.G384_TOTALFLUX, G383_CHARGINGTIME_HOUR)A
            ) K 
        WHERE LAST_KEY=1)V
    ON (A.MSISDN = V.MSISDN) 
    WHEN MATCHED THEN
    UPDATE SET A.LU_GPRS_DATA_SIZE=V.TOTALFLUX;
COMMIT;

--======================LR_DATE_KEY,LR_TIME_KEY,LR_PRODUCT_KEY,LR_RECHARGE_TYPE_KEY==================--

MERGE INTO LAST_ACTIVITY_FCT_LD A
    USING (SELECT K.RE6_PRI_IDENTITY  AS MSISDN ,K.RE30_ENTRY_DATE_KEY AS CHARGINGTIME_KEY,K.RE30_ENTRY_HOUR AS CHARGINGTIME_HOUR, K.RE21_RECHARGE_TYPE AS RECHARGE_TYPE, k.RE489_MAINOFFERINGID as MAINOFFERINGID
            FROM (SELECT A.RE6_PRI_IDENTITY,A.RE30_ENTRY_DATE_KEY, A.RE30_ENTRY_HOUR, A.RE21_RECHARGE_TYPE, A.RE489_MAINOFFERINGID,
                    RANK() OVER (PARTITION BY A.RE6_PRI_IDENTITY ORDER BY A.RE30_ENTRY_DATE_KEY DESC,A.RE30_ENTRY_HOUR DESC, A.RE21_RECHARGE_TYPE DESC,A.RE489_MAINOFFERINGID DESC) AS LAST_KEY
                   FROM
                    (SELECT   V.RE6_PRI_IDENTITY,V.RE30_ENTRY_DATE_KEY, V.RE30_ENTRY_HOUR, V.RE21_RECHARGE_TYPE, RE489_MAINOFFERINGID
                        FROM L3_RECHARGE V, DATE_DIM D
                        WHERE V.RE30_ENTRY_DATE_KEY=D.DATE_KEY
                        AND D.DATE_VALUE BETWEEN SYSDATE-2 AND SYSDATE-1   
                        GROUP BY RE6_PRI_IDENTITY,RE30_ENTRY_DATE_KEY,RE30_ENTRY_HOUR, RE21_RECHARGE_TYPE, RE489_MAINOFFERINGID)A
                        ) K 
    WHERE LAST_KEY=1)V 
    ON (A.MSISDN = V.MSISDN) 
    WHEN MATCHED THEN
    UPDATE SET A.LR_DATE_KEY=V.CHARGINGTIME_KEY,
               A.LR_TIME_KEY=V.CHARGINGTIME_HOUR,
               a.LR_PRODUCT_KEY=MAINOFFERINGID,
               A.LR_RECHARGE_TYPE_KEY=RECHARGE_TYPE;
COMMIT;

    MERGE INTO LAST_ACTIVITY_FCT_LD A
        USING (SELECT K.RE6_PRI_IDENTITY  AS MSISDN ,K.RE30_ENTRY_DATE_KEY AS CHARGINGTIME_KEY,K.RE30_ENTRY_HOUR AS CHARGINGTIME_HOUR
                FROM (SELECT A.RE6_PRI_IDENTITY,A.RE30_ENTRY_DATE_KEY, A.RE30_ENTRY_HOUR,
                        RANK() OVER (PARTITION BY A.RE6_PRI_IDENTITY ORDER BY A.RE30_ENTRY_DATE_KEY DESC,A.RE30_ENTRY_HOUR DESC) AS LAST_KEY
                       FROM
                        (SELECT   V.RE6_PRI_IDENTITY,V.RE30_ENTRY_DATE_KEY, V.RE30_ENTRY_HOUR
                            FROM L3_RECHARGE V, DATE_DIM D
                            where V.RE30_ENTRY_DATE_KEY=D.DATE_KEY
                            AND D.DATE_VALUE BETWEEN SYSDATE-2 AND SYSDATE-1   
                            GROUP BY RE6_PRI_IDENTITY,RE30_ENTRY_DATE_KEY,RE30_ENTRY_HOUR)A
                            ) K 
        WHERE LAST_KEY=1)V 
        ON (A.MSISDN = V.MSISDN) 
        WHEN MATCHED THEN
        UPDATE SET A.LR_DATE_KEY=V.CHARGINGTIME_KEY,
                   A.LR_TIME_KEY=V.CHARGINGTIME_HOUR;
                   COMMIT;

--=================================LU_DATE_KEY,LU_TIME_KEY===============--
/*
    MERGE INTO LAST_ACTIVITY_FCT_LD A
    USING (SELECT X.MSISDN AS MSISDN, X.DATE_KEY AS DATE_KEY, X.TIME_KEY AS TIME_KEY 
    FROM
    (SELECT Z.MSISDN, Z.DATE_KEY,Z.TIME_KEY,RANK() OVER (PARTITION BY Z.MSISDN ORDER BY Z.DATE_KEY DESC,Z.TIME_KEY DESC) LAST_KEY
    FROM
    (SELECT A.MSISDN, A.DATE_KEY,A.TIME_KEY
    FROM
    (SELECT MSISDN,
    NVL(LU_MOC_DATE_KEY,0) AS DATE_KEY ,
    NVL(LU_MOC_TIME_KEY,0) AS TIME_KEY
    FROM 
    LAST_ACTIVITY_FCT_LD
    UNION ALL
    SELECT MSISDN,
    NVL(LU_ON_NET_MOC_DATE_KEY,0) AS DATE_KEY ,
    NVL(LU_ON_NET_MOC_TIME_KEY,0) AS TIME_KEY
    FROM 
    LAST_ACTIVITY_FCT_LD
    UNION ALL
    SELECT MSISDN,
    NVL(LU_OFF_NET_MOC_DATE_KEY,0) AS DATE_KEY ,
    NVL(LU_OFF_NET_MOC_TIME_KEY,0) AS TIME_KEY
    FROM 
    LAST_ACTIVITY_FCT_LD
    UNION ALL
    SELECT MSISDN,
    NVL(LU_MOSMS_DATE_KEY,0) AS DATE_KEY ,
    NVL(LU_MOSMS_TIME_KEY,0) AS TIME_KEY
    FROM 
    LAST_ACTIVITY_FCT_LD
    UNION ALL
    SELECT MSISDN,
    NVL(LU_GPRS_DATE_KEY,0) AS DATE_KEY ,
    NVL(LU_GPRS_TIME_KEY,0) AS TIME_KEY
    FROM 
    LAST_ACTIVITY_FCT_LD
    UNION ALL
    SELECT MSISDN,
    NVL(LR_DATE_KEY,0) AS DATE_KEY ,
    NVL(LR_TIME_KEY,0) AS TIME_KEY
    FROM 
    LAST_ACTIVITY_FCT_LD)A
    GROUP BY A.MSISDN, A.DATE_KEY,A.TIME_KEY
    ORDER BY A.MSISDN DESC, A.DATE_KEY DESC, A.TIME_KEY DESC)Z
    )X
    WHERE X.LAST_KEY=1)T
    ON (A.MSISDN = T.MSISDN) 
    WHEN MATCHED THEN
    UPDATE SET A.LU_DATE_KEY=T.DATE_KEY,
           A.LU_TIME_KEY =T.TIME_KEY;
COMMIT;
*/
END;
/

