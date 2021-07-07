--
-- R_SUPER_INTERMEDIATE_TBALE_MANUAL_2  (Procedure) 
--
CREATE OR REPLACE PROCEDURE DWH_USER.R_SUPER_INTERMEDIATE_TBALE_MANUAL_2 IS
    VDATE_KEY       NUMBER;
BEGIN

SELECT DATE_KEY INTO VDATE_KEY
FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE,'RRRRMMDD');

    
INSERT INTO SUBSCRIBER_USAGE_ANALYSIS


SELECT /*+PARALLEL(P,15)*/ V372_CALLINGPARTYNUMBER MSISDN, V397_MAINOFFERINGID PRODUCT_ID, V387_CHARGINGTIME_KEY DATE_KEY,NVL(VOICE_PAYG_REVENUE,0)VOICE_PAYG_REVENUE,
       NVL(VOICE_RECURRING_REVENUE,0)VOICE_RECURRING_REVENUE,NVL(VOICE_PAYG_REVENUE,0) + NVL(VOICE_RECURRING_REVENUE,0) VOICE_REVENUE,
       NVL(MO_DURATION_MINS,0)MO_DURATION_MINS,NVL(MT_DURATION_MINS,0)MT_DURATION_MINS,NVL(MO_CALL_COUNT,0)MO_CALL_COUNT,
       NVL(MT_CALL_COUNT,0)MT_CALL_COUNT,NVL(DATA_PAYG_REVENUE,0)DATA_PAYG_REVENUE,NVL(DATA_BUNDLE_REVENUE,0)DATA_BUNDLE_REVENUE,
       NVL(DATA_PAYG_REVENUE,0)+NVL(DATA_BUNDLE_REVENUE,0) DATA_REVENUE,NVL(DATA_USAGE_MB,0)DATA_USAGE_MB,
       NVL(SMS_PAYG_REVENUE,0)SMS_PAYG_REVENUE,NVL(SMS_BUNDLE_REVENUE,0)SMS_BUNDLE_REVENUE,NVL(SMS_PAYG_REVENUE,0)+NVL(SMS_BUNDLE_REVENUE,0)SMS_REVENUE,
       NVL(MO_SMS_COUNT,0)MO_SMS_COUNT,NVL(MT_SMS_COUNT,0)MT_SMS_COUNT,NVL(COMBO_BUNDLE_REVENUE,0)COMBO_BUNDLE_REVENUE,NVL(RECHARGE_AMOUNT,0)RECHARGE_AMOUNT,VDATE_KEY

        
FROM 
(SELECT/*+PARALLEL(P,15)*/ V372_CALLINGPARTYNUMBER,V397_MAINOFFERINGID,V387_CHARGINGTIME_KEY, SUM(VOICE_PAYG_REVENUE)VOICE_PAYG_REVENUE,
         SUM(VOICE_RECURRING_REVENUE)VOICE_RECURRING_REVENUE, SUM(MO_DURATION_MINS)MO_DURATION_MINS ,
         SUM(MT_DURATION_MINS)MT_DURATION_MINS,SUM(MO_CALL_COUNT)MO_CALL_COUNT,SUM(MT_CALL_COUNT)MT_CALL_COUNT,
         SUM(DATA_PAYG_REVENUE)DATA_PAYG_REVENUE,SUM(DATA_BUNDLE_REVENUE)DATA_BUNDLE_REVENUE,SUM(DATA_USAGE_MB)DATA_USAGE_MB,
         SUM(SMS_PAYG_REVENUE)SMS_PAYG_REVENUE,SUM(SMS_BUNDLE_REVENUE)SMS_BUNDLE_REVENUE,SUM(MO_SMS_COUNT)MO_SMS_COUNT,
         SUM(MT_SMS_COUNT)MT_SMS_COUNT,SUM(COMBO_BUNDLE_REVENUE) COMBO_BUNDLE_REVENUE,SUM(RECHARGE_AMOUNT)RECHARGE_AMOUNT
FROM
(
-------------------------------VOICE_PAYG_REVENUE,MO_DURATION_MINS------------------------

(SELECT  /*+PARALLEL(P,15)*/ V372_CALLINGPARTYNUMBER,V397_MAINOFFERINGID,V387_CHARGINGTIME_KEY, SUM(V41_DEBIT_AMOUNT) VOICE_PAYG_REVENUE,NULL AS VOICE_RECURRING_REVENUE, SUM(V35_RATE_USAGE)/60 MO_DURATION_MINS ,
         NULL AS MT_DURATION_MINS,COUNT(V372_CALLINGPARTYNUMBER) MO_CALL_COUNT,NULL AS MT_CALL_COUNT,NULL AS DATA_PAYG_REVENUE,NULL AS DATA_BUNDLE_REVENUE,NULL AS DATA_USAGE_MB,
         NULL AS SMS_PAYG_REVENUE,NULL AS SMS_BUNDLE_REVENUE,NULL AS MO_SMS_COUNT,NULL AS MT_SMS_COUNT,NULL AS COMBO_BUNDLE_REVENUE,NULL AS RECHARGE_AMOUNT
FROM L3_VOICE P
WHERE   (V387_CHARGINGTIME_KEY BETWEEN (SELECT DATE_KEY FROM DATE_DIM  WHERE DATE_VALUE = TO_DATE('12/12/2020','DD/MM/RRRR'))
                                                       AND  (SELECT DATE_KEY FROM DATE_DIM  WHERE DATE_VALUE = TO_DATE('19/12/2020','DD/MM/RRRR')))
       AND V378_SERVICEFLOW=1                                                    

GROUP BY V372_CALLINGPARTYNUMBER,V397_MAINOFFERINGID,V387_CHARGINGTIME_KEY
)

UNION ALL
----------------------------------- VOICE_RECURRING_REVENUE--------------------------------

(SELECT  /*+PARALLEL(P,15)*/ R375_CHARGINGPARTYNUMBER,R373_MAINOFFERINGID,R377_CYCLEBEGINTIME_KEY,NULL AS VOICE_PAYG_REVENUE,SUM(R41_DEBIT_AMOUNT) VOICE_RECURRING_REVENUE, NULL AS MO_DURATION_MINS ,
         NULL AS MT_DURATION_MINS,NULL AS MO_CALL_COUNT,NULL AS MT_CALL_COUNT,NULL AS DATA_PAYG_REVENUE,NULL AS DATA_BUNDLE_REVENUE,NULL AS DATA_USAGE_MB,
         NULL AS SMS_PAYG_REVENUE,NULL AS SMS_BUNDLE_REVENUE,NULL AS MO_SMS_COUNT,NULL AS MT_SMS_COUNT,NULL AS COMBO_BUNDLE_REVENUE,NULL AS RECHARGE_AMOUNT
FROM L3_RECURRING P
WHERE  (R377_CYCLEBEGINTIME_KEY BETWEEN (SELECT DATE_KEY FROM DATE_DIM  WHERE DATE_VALUE = TO_DATE('12/12/2020','DD/MM/RRRR'))
                                                       AND  (SELECT DATE_KEY FROM DATE_DIM  WHERE DATE_VALUE = TO_DATE('19/12/2020','DD/MM/RRRR')))
                                         
      AND R385_OFFERINGID IN ( SELECT OFFERING_ID FROM OFFER_DIM WHERE OFFER_TYPE='Voice')
GROUP BY R375_CHARGINGPARTYNUMBER,R373_MAINOFFERINGID,R377_CYCLEBEGINTIME_KEY
)

UNION ALL

---------------------------------MT_DURATION_MINS,MT_CALL_COUNT----------------------

(SELECT M04_MSISDNAPARTY,TO_NUMBER(LU_PRODUCT_KEY)LU_PRODUCT_KEY ,DATE_KEY,NULL AS VOICE_PAYG_REVENUE,NULL VOICE_RECURRING_REVENUE, NULL AS MO_DURATION_MINS ,
         MT_DURATION_MINS,NULL AS MO_CALL_COUNT,MT_CALL_COUNT,NULL AS DATA_PAYG_REVENUE,NULL AS DATA_BUNDLE_REVENUE,NULL AS DATA_USAGE_MB,
         NULL AS SMS_PAYG_REVENUE,NULL AS SMS_BUNDLE_REVENUE,NULL AS MO_SMS_COUNT,NULL AS MT_SMS_COUNT,NULL AS COMBO_BUNDLE_REVENUE,NULL AS RECHARGE_AMOUNT
FROM LAST_ACTIVITY_FCT_LD,
(SELECT /*+PARALLEL(P,15)*/ M04_MSISDNAPARTY,DATE_KEY,
       SUM(M08_CALLDUR)/60 MT_DURATION_MINS, COUNT(*) MT_CALL_COUNT
FROM L1_MSC@DWH05TODWH03 P,DATE_DIM Q
WHERE (PROCESSED_DATE BETWEEN  TO_DATE('12/DEC/2020','DD/MONTH/RRRR') AND TO_DATE(SYSDATE-4,'DD/MONTH/RRRR'))
AND SUBSTR(M07_ANSWERTIMESTAMP,1,6) IN ('202006','202007','202008','202009','202010','202011','202012')
AND   ((TO_DATE(SUBSTR(M07_ANSWERTIMESTAMP,1,8),'RRRRMMDD')) BETWEEN (TO_DATE('12/12/2020','DD/MM/RRRR'))
                                                       AND  (TO_DATE('19/12/2020','DD/MM/RRRR')))
AND M01_CALLTYPE='MTC'
AND TO_DATE(SUBSTR(M07_ANSWERTIMESTAMP,1,8),'RRRRMMDD')=DATE_VALUE
GROUP BY M04_MSISDNAPARTY,DATE_KEY
)
WHERE M04_MSISDNAPARTY=MSISDN 
)

UNION ALL

--------------------------------DATA_PAYG_REVENUE,DATA_USAGE_MB---------------

(SELECT  /*+PARALLEL(P,8)*/ G372_CALLINGPARTYNUMBER,G401_MAINOFFERINGID,G383_CHARGINGTIME_KEY,NULL AS VOICE_PAYG_REVENUE,NULL AS VOICE_RECURRING_REVENUE, NULL AS MO_DURATION_MINS ,
         NULL AS MT_DURATION_MINS,NULL AS MO_CALL_COUNT,NULL AS MT_CALL_COUNT,SUM(G41_DEBIT_AMOUNT) DATA_PAYG_REVENUE,NULL AS DATA_BUNDLE_REVENUE,SUM(G384_TOTALFLUX)/1048576 DATA_USAGE_MB,
         NULL AS SMS_PAYG_REVENUE,NULL AS SMS_BUNDLE_REVENUE,NULL AS MO_SMS_COUNT,NULL AS MT_SMS_COUNT,NULL AS COMBO_BUNDLE_REVENUE,NULL AS RECHARGE_AMOUNT
FROM L3_DATA P
WHERE  (G383_CHARGINGTIME_KEY BETWEEN (SELECT DATE_KEY FROM DATE_DIM  WHERE DATE_VALUE = TO_DATE('12/12/2020','DD/MM/RRRR'))
                                                       AND  (SELECT DATE_KEY FROM DATE_DIM  WHERE DATE_VALUE = TO_DATE('19/12/2020','DD/MM/RRRR')))                                                  

GROUP BY G372_CALLINGPARTYNUMBER,G401_MAINOFFERINGID,G383_CHARGINGTIME_KEY
)


UNION ALL
-----------------------------------DATA_BUNDLE_REVENUE---------------------------

(SELECT  /*+PARALLEL(P,8)*/ R375_CHARGINGPARTYNUMBER,R373_MAINOFFERINGID,R377_CYCLEBEGINTIME_KEY,NULL AS VOICE_PAYG_REVENUE,NULL AS  VOICE_RECURRING_REVENUE, NULL AS MO_DURATION_MINS ,
         NULL AS MT_DURATION_MINS,NULL AS MO_CALL_COUNT,NULL AS MT_CALL_COUNT,NULL AS DATA_PAYG_REVENUE,SUM(R41_DEBIT_AMOUNT) DATA_BUNDLE_REVENUE,NULL AS DATA_USAGE_MB,
         NULL AS SMS_PAYG_REVENUE,NULL AS SMS_BUNDLE_REVENUE,NULL AS MO_SMS_COUNT,NULL AS MT_SMS_COUNT,NULL AS COMBO_BUNDLE_REVENUE,NULL AS RECHARGE_AMOUNT
FROM L3_RECURRING P
WHERE  (R377_CYCLEBEGINTIME_KEY BETWEEN (SELECT DATE_KEY FROM DATE_DIM  WHERE DATE_VALUE = TO_DATE('12/12/2020','DD/MM/RRRR'))
                                                       AND  (SELECT DATE_KEY FROM DATE_DIM  WHERE DATE_VALUE = TO_DATE('19/12/2020','DD/MM/RRRR')))                                       
      AND R385_OFFERINGID IN ( SELECT OFFERING_ID FROM OFFER_DIM WHERE OFFER_TYPE='Data')
GROUP BY R375_CHARGINGPARTYNUMBER,R373_MAINOFFERINGID,R377_CYCLEBEGINTIME_KEY
)

UNION ALL
-------------------------SMS_PAYG_REVENUE,MO_SMS_COUNT-----------------

(SELECT  /*+PARALLEL(P,15)*/ S22_PRI_IDENTITY,S395_MAINOFFERINGID,S387_CHARGINGTIME_KEY, NULL AS VOICE_PAYG_REVENUE,NULL AS VOICE_RECURRING_REVENUE, NULL AS MO_DURATION_MINS ,
         NULL AS MT_DURATION_MINS,NULL AS MO_CALL_COUNT,NULL AS MT_CALL_COUNT,NULL AS DATA_PAYG_REVENUE,NULL AS DATA_BUNDLE_REVENUE,NULL AS DATA_USAGE_MB,
         SUM( S41_DEBIT_AMOUNT)SMS_PAYG_REVENUE ,NULL AS SMS_BUNDLE_REVENUE,COUNT(S22_PRI_IDENTITY) MO_SMS_COUNT,NULL AS MT_SMS_COUNT,NULL AS COMBO_BUNDLE_REVENUE,NULL AS RECHARGE_AMOUNT
FROM L3_SMS P
WHERE   (S387_CHARGINGTIME_KEY BETWEEN (SELECT DATE_KEY FROM DATE_DIM  WHERE DATE_VALUE = TO_DATE('12/12/2020','DD/MM/RRRR'))
                                                       AND  (SELECT DATE_KEY FROM DATE_DIM  WHERE DATE_VALUE = TO_DATE('19/12/2020','DD/MM/RRRR')))
  AND S378_SERVICEFLOW=1                                                    

GROUP BY S22_PRI_IDENTITY,S395_MAINOFFERINGID,S387_CHARGINGTIME_KEY
)


UNION ALL
--------------------SMS_BUNDLE_REVENUE--------------------


(SELECT  /*+PARALLEL(P,15)*/ R375_CHARGINGPARTYNUMBER,R373_MAINOFFERINGID,R377_CYCLEBEGINTIME_KEY,NULL AS VOICE_PAYG_REVENUE,NULL AS VOICE_RECURRING_REVENUE, NULL AS MO_DURATION_MINS ,
         NULL AS MT_DURATION_MINS,NULL AS MO_CALL_COUNT,NULL AS MT_CALL_COUNT,NULL AS DATA_PAYG_REVENUE,NULL AS DATA_BUNDLE_REVENUE,NULL AS DATA_USAGE_MB,
         NULL AS SMS_PAYG_REVENUE,SUM(R41_DEBIT_AMOUNT) SMS_BUNDLE_REVENUE,NULL AS MO_SMS_COUNT,NULL AS MT_SMS_COUNT,NULL AS COMBO_BUNDLE_REVENUE,NULL AS RECHARGE_AMOUNT
FROM L3_RECURRING P
WHERE  (R377_CYCLEBEGINTIME_KEY BETWEEN (SELECT DATE_KEY FROM DATE_DIM  WHERE DATE_VALUE = TO_DATE('12/12/2020','DD/MM/RRRR'))
                                                       AND  (SELECT DATE_KEY FROM DATE_DIM  WHERE DATE_VALUE = TO_DATE('19/12/2020','DD/MM/RRRR')))
                                         
      AND R385_OFFERINGID IN ( SELECT OFFERING_ID FROM OFFER_DIM WHERE OFFER_TYPE='SMS')
GROUP BY R375_CHARGINGPARTYNUMBER,R373_MAINOFFERINGID,R377_CYCLEBEGINTIME_KEY
)


UNION ALL
--------------------------MT_SMS_COUNT-----------------------


(SELECT M04_MSISDNAPARTY,TO_NUMBER(LU_PRODUCT_KEY)LU_PRODUCT_KEY,DATE_KEY,NULL AS VOICE_PAYG_REVENUE,NULL VOICE_RECURRING_REVENUE, NULL AS MO_DURATION_MINS ,
         NULL AS MT_DURATION_MINS,NULL AS MO_CALL_COUNT,NULL MT_CALL_COUNT,NULL AS DATA_PAYG_REVENUE,NULL AS DATA_BUNDLE_REVENUE,NULL AS DATA_USAGE_MB,
         NULL AS SMS_PAYG_REVENUE,NULL AS SMS_BUNDLE_REVENUE,NULL AS MO_SMS_COUNT,MT_SMS_COUNT,NULL AS COMBO_BUNDLE_REVENUE,NULL AS RECHARGE_AMOUNT
FROM LAST_ACTIVITY_FCT_LD,
(SELECT /*+PARALLEL(P,15)*/ M04_MSISDNAPARTY,DATE_KEY,COUNT(*) MT_SMS_COUNT
FROM L1_MSC@DWH05TODWH03 P,DATE_DIM Q
WHERE (PROCESSED_DATE BETWEEN  TO_DATE('12/DEC/2020','DD/MONTH/RRRR') AND TO_DATE(SYSDATE-4,'DD/MONTH/RRRR'))
AND SUBSTR(M07_ANSWERTIMESTAMP,1,6) IN ('202006','202007','202008','202009','202010','202011','202012')
AND ((TO_DATE(SUBSTR(M07_ANSWERTIMESTAMP,1,8),'RRRRMMDD')) BETWEEN (TO_DATE('12/12/2020','DD/MM/RRRR'))
                                                       AND  (TO_DATE('19/12/2020','DD/MM/RRRR')))
AND M01_CALLTYPE='SMSMT'
AND TO_DATE(SUBSTR(M07_ANSWERTIMESTAMP,1,8),'RRRRMMDD')=DATE_VALUE
GROUP BY M04_MSISDNAPARTY,DATE_KEY
)
WHERE M04_MSISDNAPARTY=MSISDN 
)


UNION ALL

------------------------COMBO_BUNDLE_REVENUE---------------------

(SELECT  /*+PARALLEL(P,15)*/ R375_CHARGINGPARTYNUMBER,R373_MAINOFFERINGID,R377_CYCLEBEGINTIME_KEY,NULL AS VOICE_PAYG_REVENUE,NULL AS VOICE_RECURRING_REVENUE, NULL AS MO_DURATION_MINS ,
         NULL AS MT_DURATION_MINS,NULL AS MO_CALL_COUNT,NULL AS MT_CALL_COUNT,NULL AS DATA_PAYG_REVENUE,NULL AS DATA_BUNDLE_REVENUE,NULL AS DATA_USAGE_MB,
         NULL AS SMS_PAYG_REVENUE,NULL AS SMS_BUNDLE_REVENUE,NULL AS MO_SMS_COUNT,NULL AS MT_SMS_COUNT,SUM(R41_DEBIT_AMOUNT)  COMBO_BUNDLE_REVENUE,NULL AS RECHARGE_AMOUNT
FROM L3_RECURRING P
WHERE  (R377_CYCLEBEGINTIME_KEY BETWEEN (SELECT DATE_KEY FROM DATE_DIM  WHERE DATE_VALUE = TO_DATE('12/12/2020','DD/MM/RRRR'))
                                                       AND  (SELECT DATE_KEY FROM DATE_DIM  WHERE DATE_VALUE = TO_DATE('19/12/2020','DD/MM/RRRR')))
                                         
      AND R385_OFFERINGID IN ( SELECT OFFERING_ID FROM OFFER_DIM WHERE OFFER_TYPE='Combo')
GROUP BY R375_CHARGINGPARTYNUMBER,R373_MAINOFFERINGID,R377_CYCLEBEGINTIME_KEY
)

UNION ALL

-----------------------RECHARGE_AMOUNT------

(SELECT  /*+PARALLEL(P,15)*/ RE6_PRI_IDENTITY,RE489_MAINOFFERINGID,RE30_ENTRY_DATE_KEY,NULL AS VOICE_PAYG_REVENUE,NULL AS  VOICE_RECURRING_REVENUE, NULL AS MO_DURATION_MINS ,
         NULL AS MT_DURATION_MINS,NULL AS MO_CALL_COUNT,NULL AS MT_CALL_COUNT,NULL AS DATA_PAYG_REVENUE,NULL AS DATA_BUNDLE_REVENUE,NULL AS DATA_USAGE_MB,
         NULL AS SMS_PAYG_REVENUE,NULL AS SMS_BUNDLE_REVENUE,NULL AS MO_SMS_COUNT,NULL AS MT_SMS_COUNT,NULL AS COMBO_BUNDLE_REVENUE,SUM(RE3_RECHARGE_AMT) RECHARGE_AMOUNT 
FROM L3_RECHARGE P
WHERE  (RE30_ENTRY_DATE_KEY BETWEEN (SELECT DATE_KEY FROM DATE_DIM  WHERE DATE_VALUE = TO_DATE('12/12/2020','DD/MM/RRRR'))
                                                       AND  (SELECT DATE_KEY FROM DATE_DIM  WHERE DATE_VALUE = TO_DATE('19/12/2020','DD/MM/RRRR')))                                                  

GROUP BY RE6_PRI_IDENTITY,RE489_MAINOFFERINGID,RE30_ENTRY_DATE_KEY
)
)P
GROUP BY V372_CALLINGPARTYNUMBER,V397_MAINOFFERINGID,V387_CHARGINGTIME_KEY
)P
;
    COMMIT;
END;
/

